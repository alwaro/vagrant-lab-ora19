#!/bin/bash
# ####################################################################################
#   SCRIPT PARA MOSTRAR INFO SOBRE LOS OBJETOS FRAGMENTADOS A NIVEL DE TABLESPACE
# ####################################################################################
#
# Este script hace uso del SEGMENT.ADVISOR para mostrar la info sobre todos los 
# objetos con fragmentacion (incluidas tablas particionadas) dentro del tablespace
# que se le pase como argumento.
# Tambien muestra el posible espacio que se puede recuperar al compactar dicho objeto.
#
# El SEGMENT.ADVISOR no es rapido precisamente y si el TS tiene bastantes datos, el
# script puede tardar bastante, que es el algo a tener en cuenta.
#
#
# QUIEN    CUANDO     QUE
# -------- ---------  ----------------------------------------------------------------
# aanayama  10-07-19  Version inicial del script
#
# ####################################################################################

# Cargamos el entorno basico
# ------------------------------------------------------------------------------------
[[ -r $HOME/.bash_profile ]] && . $HOME/.bash_profile
[[ -r $HOME/.bashrc ]] && . $HOME/.bashrc

# ZONA DE VARIABLES
# =====================================================================================
export workDir=$(dirname $0)
export logDir=${workDir}/logs
export tmpDir=${workDir}/tmp
export reportDir=${workDir}/resultados
export fechaCorta=$(date +"%Y%m%d_%H%M%S")
export timeStamp=$(date +"%Y%m%d%H%M%S")
export fechaLarga=$(date +"%d de %b de %Y a las %H%M%S")
export appName=$(basename $0)
export database=$1
export database_minor=$(echo ${database} | awk '{ print tolower($0) }')
export database_mayor=$(echo ${database} | awk '{ print toupper($0) }')
export tablespace=$(echo ${2} | awk '{ print toupper($0) }')
export logFile=${logDir}/fragmentados_${database}_${tablespace}_${fechaCorta}.log

# FLAG DEBUG para el script (VALORES 0 Y 1)
export modoDebug=0

# Antes de seguir, creamos los directorios auxiliares.
[[ ! -d $logDir ]] && mkdir -p $logDir
[[ ! -d $tmpDir ]] && mkdir -p $tmpDir
[[ ! -d $reportDir ]] && mkdir -p $reportDir

# ZONA DE FUNCIONES
# =====================================================================================

function msgQueue()
{

  # --------------------------------------------------------------------------------------
  # Funcion para gestionar la mensajeria dentro del script
  # --------------------------------------------------------------------------------------
  lvl="${1}"    # Nivel de mensajes (DEBUG, NORMAL, WARNING, CRITICAL)
  msg="${2}"    # Mensaje a mostrar
  msgTime=$(date +%Y-%m-%d_%H:%M:%S)
  failMsg="${msgTime} CRITICAL:\n FATAL error enviando msg a messageQueue"
  [[ -z "${1}" ]] || [[ -z "${2}" ]] && echo -e "ops: ${failMsg}\n"| tee -a ${logFile} && exit 2
  if [[ "${lvl}" == "DEBUG" ]]; then
    if [[ $modoDebug -eq 1 ]]; then
      echo -e "${msgTime} ${lvl}:\n   ${msg}\n"| tee -a ${logFile}
    fi
  else
    echo -e "${msgTime} ${lvl}:\n   ${msg}\n"| tee -a ${logFile}
  fi
}


function get_db_data()
{
    # --------------------------------------------------------------
    # Funcion para converir el resultado de una sentencia en un valor
    # utilizable para almacenar en variables :)
    #
    # La funcion usa el sqlplus, por lo que es necesario tener todas
    # las variables de entorno definidas.
    #
    # * Es necesario escapar el simbolo del dolar. P.E: v\$instance"
    #
    # USO:       get_db_data  "select instance_name from v\$instance;"
    #
    # ---------------------------------------------------------------
    if [ -z "$1" ]; then
        msgQueue "CRITICAL" "La funcion get_db_data necesita 1 argumento"
        show_help
        exit 2
    fi

    export sql2value_tmp=$(sqlplus -S / as sysdba <<EOF
SET HEADING OFF;
SET FEEDBACK OFF;
$1;
EXIT;
EOF
)
    # MOSTRAMOS EL RESULTADO
    echo $sql2value_tmp
}

function info_uso()
{
    cat << EOF

INFORMACION:

    El ejecutable  '${appName}'  es un script que, haciendo  uso del  SEGMENT_ADVISOR,  permite  sacar  la  lista de todos los objetos
    framentados en un Tablespace, incluso los  objetos particionados. Tambien muestra la cantidad de espacio que podria ser recuperada
    
USO del Script:

    El script debe invocarse con 2 argumentos obligatorios: 

        ./${appName} ORACLE_SID TABLESPACE_NAME

    Donde:

        ORACLE_SID:     Es el ORACLE_SID de la bbdd a la que queremos conectar localmente. Dado que esta pensado para conexiones 
                        locales unicamente, el script debe ejecutarse en la misma maquina donde este la db.

        TABLESPACE:     Es el nombre del tablespace que se quiere analizar.

    Ejemplos:

        ./${appName} PREBID1 DATOS_APP
        ./${appName} BIGDB USERS
    
.
EOF
}

if [ $# -ne 2 ]; then
    msgQueue "CRITICAL" "Numero de argumentos incorrectos."
    info_uso
    exit 2;
fi


# ZONA DE CARGA DE ENTORNO DINAMICAMENTE Y CHECK DE BBDD Y TS
# =====================================================================================
# comprobamos que la bbdd esta corriendo
ps -ef|grep -v grep|grep -w "ora_pmon_$database" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    msgQueue "CRITICAL" "La BBDD $database no esta corriendo en este host"
    exit 2
else
    # Si esta corriendo, verificamos que tenga fichero de variables de entorno
    if [[ "$HOSTNAME" == "ex4-db01" ]] || [[ "$HOSTNAME" == "ex4-db02" ]]; then
        export ruta_entorno="/scripts/oracle/entorno/exadata-x4"
    else
        export ruta_entorno="/scripts/oracle/entorno/exadata-x2"
    fi

    # En base a la anterior comprobacion, definimos el fichero de entorno
    export db_env_file=${ruta_entorno}/${database_minor}
    if [ ! -r $db_env_file ]; then
        msgQueue "CRITICAL" "No puedo leer el fichero de variables de entorno para $database: ${db_env_file}\n"
        exit 2
    fi

    # Si llega a este punto, ya se puede cargar el fichero de entorno de la bbdd indicada.
    echo "Cargando el entorno para la bbdd $database"
    msgQueue "DEBUG" "Fichero a cargar con el entorno:\n    $db_env_file\n"
    . $db_env_file
fi


# sleep 3
# En este punto la bbdd existe. Comprobemos el TS
export existeTS=$(get_db_data "select tablespace_name from dba_tablespaces where tablespace_name='${tablespace}'")
echo ${existeTS} | grep "$tablespace" > /dev/null

if [[ $? -ne 0 ]]; then
    msgQueue "CRITICAL" "El tablespace indicado NO exsite --> $tablespace"
    exit 2;
else
    msgQueue "DEBUG" "Tablespace '${tablespace}' detectado en la bbdd"
fi

# Ahora si, hechas todas las comprobaciones, pasamos al CORE del SCRIPT

# ZONA DE CONFIGURACION Y EJECUCION DEL SEGMENT ADVISOR
# =====================================================================================

# Activamos el reloj para controlar cuanto tarda el proceso
BUILD_START=$(date +"%s")

# Preparamos el script del segment advisor y la extraccion de datos para el informe
cat << EOF > $tmpDir/informe.tmp
set lines 200;
spoo ${reportDir}/lista_detallado_${database}_${tablespace}.txt
set serveroutput ON;
variable id number;
begin
  declare
  name varchar2(100);
  descr varchar2(500);
  obj_id number;
  begin
  name:='${tablespace}${timeStamp}';
  descr:='seg.adv ${tablespace} en ${fechaCorta}';

  dbms_advisor.create_task (
    advisor_name     => 'Segment Advisor',
    task_id          => :id,
    task_name        => name,
    task_desc        => descr);

  dbms_advisor.create_object (
    task_name        => name,
    object_type      => 'TABLESPACE',
    attr1            => '${tablespace}',
    attr2            => NULL,
    attr3            => NULL,
    attr4            => NULL,
    attr5            => NULL,
    object_id        => obj_id);

  dbms_advisor.set_task_parameter(
    task_name        => name,
    parameter        => 'recommend_all',
    value            => 'TRUE');

  dbms_advisor.reset_task(name);
  dbms_advisor.execute_task(name);

  exception when others then
    dbms_output.put_line('Exception: ' || SQLERRM);
  end;

  -- Output findings.
  dbms_output.put_line(chr(10));
  dbms_output.put_line('Informe del Segment advisor para el TS ${tablespace} de ${database_mayor} el ${fechaLarga}');
  dbms_output.put_line('------------------------------------------------------------------------------------------------------');

  for r in (select segment_owner, segment_name, segment_type, partition_name,
                    tablespace_name, allocated_space, used_space,
                    reclaimable_space
            from table(dbms_space.asa_recommendations('TRUE', 'TRUE', 'FALSE'))
            where tablespace_name='${tablespace}'
            order by reclaimable_space desc)
  loop
    dbms_output.put_line('');
    dbms_output.put_line('Owner              : ' || r.segment_owner);
    dbms_output.put_line('Objeto             : ' || r.segment_name);
    dbms_output.put_line('Tipo de objeto     : ' || r.segment_type);
    dbms_output.put_line('Nombre particion   : ' || r.partition_name);
    dbms_output.put_line('Tablespace         : ' || r.tablespace_name);
    dbms_output.put_line('Mb totales         : ' || trunc(r.allocated_space/1024/1024,1));
    dbms_output.put_line('Mb usados          : ' || trunc(r.used_space/1024/1024,1));
    dbms_output.put_line('Mb Reclamables     : ' || trunc(r.reclaimable_space/1024/1024,1));
    dbms_output.put_line('--------------------------------------------------------------------------------');
  end loop;

  -- Remove Segment Advisor task.
  -- dbms_advisor.delete_task(name);
end;
/
spoo off;
exit;
EOF

# Ahora preparamos el script para sacar la lista de objetos ordenados por fragmentacion para nosotros
cat << EOF > ${tmpDir}/lista_ordenada.tmp
spoo ${reportDir}/informe_ordenado_${database}_${tablespace}.txt
set lines 200;
col segment_owner for a15;
col tablespace_name for a16;
col Mb_reservados for 999999999
col Mb_usados for 999999999
col Mb_reclamables for 999999999
select segment_owner, segment_name, segment_type, partition_name, tablespace_name, trunc(allocated_space/1024/1024,1) Mb_reservados, trunc(used_space/1024/1024,1) Mb_usados, trunc(reclaimable_space/1024/1024,1) Mb_reclamables
from table(dbms_space.asa_recommendations('TRUE', 'TRUE', 'FALSE'))
where tablespace_name='${tablespace}'
order by 8 asc;
--order by reclaimable_space desc)
spoo off;
exit;
EOF

sqlplus -S / as sysdba @${tmpDir}/informe.tmp
sqlplus -S / as sysdba @${tmpDir}/lista_ordenada.tmp

BUILD_END=$(date +"%s")
BUILD_ELAPSED=$(expr $BUILD_END - $BUILD_START)
echo -e "\n\n El proceso de extraccion de datos se ha completado en ${BUILD_ELAPSED} segundos!!!.\n"
echo -e "Se han creado 2 ficheros:\n"
echo -e " - Una lista con los datos de cada objeto, a modo de informe:"
echo -e "      ${reportDir}/lista_detallado_${database}_${tablespace}.txt"
echo -e "\n - Una lista ordenada por fragmentacion:"
echo -e "      ${reportDir}/informe_ordenado_${database}_${tablespace}.txt"
echo -e "\n"
