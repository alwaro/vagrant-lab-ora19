#!/bin/bash
# ######################################################################################
#   SCRIPT DE COMPACTACION SEMI-AUTOMATICA DE TABLAS y RECONSTRUCCION DE INDICES
# ######################################################################################
# Script para realizar la compactacion de las tablas y reconstruccion de sus indices
#
#  La lista de tablas que se compactaran debe estar contenida en el fichero:
#
# lista_tablas_NOMBREBBDD.txt 
#       Que lleve el nombre es para poder tener varias versiones, una para cada BBDD
#
# El script saca datos de la tabla y los indices antes y despues del proceso.
#
# QUIEN        CUANDO     QUE
# ------------ ---------  ------------------------------------------------------------------
# Alvaro Anaya 24-06-2014 Creacion del script 
# Alvaro Anaya 28-06-2014 Formateo de log + añadido estadisticas a la tabla compactada.
# Alvaro Anaya 09-07-2015 Creacion de informes finales
# ######################################################################################

# CARGAMOS EN ENTORNO BASICO
[[ -r $HOME/.bash_profile ]] && . $HOME/.bash_profile
[[ -r $HOME/.bashrc ]] && . $HOME/.bashrc

#export workDir=$(dirname $0)
# Cambiamos la definicion del dir de trabajo porque ahora se invoca desde otro sitio.
export workDir=$HOME/configuracion/dba
export tablas_file=${workDir}/lista_tablas_NOMBREBBDD.txt
export logDir=${workDir}/logs
export tmpDir=${workDir}/tmp
export dataDir=${workDir}/data
export reportDir=${workDir}/resultados
export fechaCorta=$(date +"%Y%m%d_%H%M%S")
export logFile=${logDir}/compactacion_$1_${fechaCorta}.log
export database=$1
export database_minor=$(echo ${database} | awk '{ print tolower($0) }')
export database_mayor=$(echo ${database} | awk '{ print toupper($0) }')
export hostPrefix="${HOSTNAME:0:7}"
export appName=$(basename $0)
# FLAG DEBUG para el script
export modoDebug=0

# Antes de seguir, creamos los logDir, tmpDir y reportDir si no existen.
[[ ! -d $logDir ]] && mkdir -p $logDir
[[ ! -d $tmpDir ]] && mkdir -p $tmpDir
[[ ! -d $reportDir ]] && mkdir -p $reportDir

# Inicializamos el fichero con la lista de informes
echo > ${tmpDir}/lista_informes.txt

# ZONA DE FUNCIONES
# ==============================================

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


if [ $# -ne 1 ]; then
    msgQueue "CRITICAL" "Debe pasarse la bbdd como argumento. Es una conexion local, asi que debe pasarse el ORACLE_SID"
    exit 2;
fi

# ######################################################################################
#             BLOQUE CARGAR ENTORNO DE BBDD - CUSTOM PARA ESTE ENTORNO
# ######################################################################################
# comprobamos que la bbdd esta corriendo
ps -ef|grep -v grep|grep -w "ora_pmon_$database" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    msgQueue "CRITICAL" "La BBDD $database no esta corriendo en este host"
    exit 2
else
    export ruta_entorno="$HOME/configuracion"
    export db_env_file=${ruta_entorno}/${database_minor}.cfg
    if [ ! -r $db_env_file ]; then
        msgQueue "CRITICAL" "No puedo leer el fichero de variables de entorno para $database: ${db_env_file}\n"
        exit 2
    fi
    # Si llega a este punto, ya se puede cargar el fichero de entorno de la bbdd indicada.
    echo "Cargando el entorno para la bbdd $database"
    msgQueue "DEBUG" "Fichero a cargar con el entorno:\n    $db_env_file\n"
    . $db_env_file
fi


# ahora toca verificar el fichero de tablas.
if [ ! -r $tablas_file ]; then
    msgQueue "CRITICAL" "El fichero con la lista de tablas no esta accesible: \n    $tablas_file\n"
    exit 2;
fi

export lista_tablas_brute=$(cat $tablas_file)

# Tenemos todo disponible, comienza la magia :)

echo "Iniciando conexion..."
for tabla_full in $lista_tablas_brute;
do
    export owner=$(echo $tabla_full|cut -d"." -f1)
    export tabla=$(echo $tabla_full|cut -d"." -f2)
    sqlplus -S / as sysdba <<EOF
-- spoo ${logDir}/tablespaces_ANTES_${tabla_full}.log;
-- set lines 200
-- column total_space format 999,999,999,999
-- column free_space format 999,999,999,999
-- column pct_libre format 999.99
-- select a.tablespace_name,
-- total_space/1024/1024 espacio_total_MB,
-- free_space/1024/1024 espacio_libre_MB,
-- --free_space / total_space * 100 PCT_libre,
-- 100 - (free_space / total_space * 100) as PCT_ocupado
-- from (select tablespace_name, sum(bytes)
-- total_space from dba_data_files
-- group by tablespace_name) a,
-- (select tablespace_name, sum(bytes)
-- free_space from dba_free_space
-- group by tablespace_name) b
-- where a.tablespace_name = b.tablespace_name(+)
-- order by PCT_ocupado desc;
-- spoo off;
-- aqui metemos def_table_antes
-- ========================================
set lines 200
col owner format a15
col column_name format a25
col table_owner format a20
col UNIQUENESS format a4
SET ECHO OFF
SET FEEDBACK OFF
SET VERIFY OFF
set heading off
DEFINE Nombre_del_propiertario=${owner}
DEFINE Nombre_de_la_tabla=${tabla}
spoo ${logDir}/definicion_tabla_ANTES_${tabla_full}.log
PROMPT 
prompt #################################################
prompt ======================ANTES======================
prompt #################################################
prompt
PROMPT 
prompt ===============================================
PROMPT DATOS DE LA TABLA ${tabla_full}
prompt ===============================================
SELECT
    'PROPIETARIO..............: '||t.OWNER||chr(10)||
    'NOMBRE DE TABLA..........: '||t.TABLE_NAME||chr(10)||
    'SIZE EN MB...............: '||s.BYTES/1024/1024||chr(10)||
    'TABLESPACE...............: '||t.TABLESPACE_NAME||chr(10)||
    'PARARELISMO..............: '||t.DEGREE||chr(10)||
    'ESTADISTICAS.............: '||t.LAST_ANALYZED||chr(10)||
    'PARTICIONADA.............: '||t.PARTITIONED||chr(10)||
    'ROW_MOVEMENT.............: '||t.ROW_MOVEMENT||chr(10)||
    'COMPRESION...............: '||t.COMPRESSION
FROM DBA_TABLES t, DBA_SEGMENTS s WHERE
    t.OWNER=upper('&&Nombre_del_propiertario') AND
    t.TABLE_NAME=upper('&&Nombre_de_la_tabla') AND
    s.owner=upper('&&Nombre_del_propiertario') AND
    s.segment_name=upper('&&Nombre_de_la_tabla') AND
    s.SEGMENT_TYPE='TABLE';
prompt
prompt DATOS DE LOS INDICES
prompt ================================================
select
    'INDEX..................: '||i.INDEX_NAME||chr(10)||
    'SIZE EN MB.............: '||s.BYTES/1024/1024||chr(10)||
    'PROPIETARIO............: '||i.OWNER||chr(10)||
    'TABLE_OWNER............: '||i.TABLE_OWNER||chr(10)||
    'TABLE_NAME.............: '||i.TABLE_NAME||chr(10)||
    'UNIQUENESS.............: '||i.UNIQUENESS||chr(10)||
    'COMPRESSION............: '||i.COMPRESSION||chr(10)||
    'TABLESPACE_NAME........: '||i.TABLESPACE_NAME||chr(10)||
    'BLEVEL.................: '||i.BLEVEL||chr(10)||
    'STATUS.................: '||i.STATUS||chr(10)||
    'LAST_ANALYZED..........: '||i.LAST_ANALYZED||chr(10)||
    'DEGREE.................: '||i.DEGREE||chr(10)||
    'PARTITIONED............: '||i.PARTITIONED||chr(10)||
    'VISIBILITY.............: '||i.VISIBILITY
from dba_indexes i, dba_segments s where
    i.owner='&&Nombre_del_propiertario' AND
    i.table_name='&&Nombre_de_la_tabla' and
    s.owner='&&Nombre_del_propiertario' AND
    i.index_name=s.segment_name AND
    s.SEGMENT_TYPE='INDEX';
spoo off;
-- =============================== ZONA DE COMPACTACION =============================
prompt
prompt COMPACTANDO TABLA ${tabla_full}
prompt =========================================================================================
SET TIMING ON;
SET ECHO ON;
alter table ${tabla_full} MOVE;
SET ECHO ON;
SET VERIFY ON;
-- SET FEEDBACK ON;
SET TIMING OFF;
set heading on;
prompt
prompt reconstruyendo indices
prompt =========================================================================================
set echo off;
set verify off;
set heading off;
spoo ${tmpDir}/rebuild_index_${tabla_full}.sql
prompt set timing on;
select 'alter index ' ||owner || '.' || index_name  ||' rebuild online NOLOGGING parallel 16; ' from dba_indexes 
where INDEX_TYPE like '%ORMAL'
and table_owner=upper('$owner')
and table_name=UPPER('$tabla');

select 'alter index ' ||owner || '.' || index_name  ||' parallel '||degree||' logging;' from dba_indexes
where INDEX_TYPE='NORMAL'
and table_owner=upper('$owner')
and table_name=UPPER('$tabla');
set echo on;
set verify on;
set heading on;
spoo off;
-- Hasta aqui la parte de extraeer la lista de indices formando queries de rebuild
@@${tmpDir}/rebuild_index_${tabla_full}.sql
set timing off;
PROMPT =============== FIN DEL PROCESO DE COMPACTACION =======================
-- aqui metemos def_table_despues
-- =========================================================================================
prompt
prompt PASANDO ESTADISTICAS A LA TABLA ${tabla_full}
prompt
EXEC DBMS_STATS.GATHER_TABLE_STATS (ownname => '$owner' , tabname => '$tabla',cascade => true ,estimate_percent=>dbms_stats.auto_sample_size,method_opt=>'FOR ALL COLUMNS SIZE AUTO',granularity => 'ALL', degree => 24 );
prompt
prompt
set lines 200
col owner format a15
col column_name format a25
col table_owner format a20
col UNIQUENESS format a4
SET ECHO OFF
SET FEEDBACK OFF
SET VERIFY OFF
set heading off
-- DEFINE Nombre_del_propiertario=${owner}
-- DEFINE Nombre_de_la_tabla=${tabla}
spoo ${logDir}/definicion_tabla_DESPUES_${tabla_full}.log
prompt
prompt #################################################
prompt =====================DESPUES=====================
prompt #################################################
prompt
PROMPT 
prompt ===============================================
PROMPT DATOS DE LA TABLA ${tabla_full}
prompt ===============================================
SELECT
    'PROPIETARIO..............: '||t.OWNER||chr(10)||
    'NOMBRE DE TABLA..........: '||t.TABLE_NAME||chr(10)||
    'SIZE EN MB...............: '||s.BYTES/1024/1024||chr(10)||
    'TABLESPACE...............: '||t.TABLESPACE_NAME||chr(10)||
    'PARARELISMO..............: '||t.DEGREE||chr(10)||
    'ESTADISTICAS.............: '||t.LAST_ANALYZED||chr(10)||
    'PARTICIONADA.............: '||t.PARTITIONED||chr(10)||
    'ROW_MOVEMENT.............: '||t.ROW_MOVEMENT||chr(10)||
    'COMPRESION...............: '||t.COMPRESSION
FROM DBA_TABLES t, DBA_SEGMENTS s WHERE
    t.OWNER=upper('&&Nombre_del_propiertario') AND
    t.TABLE_NAME=upper('&&Nombre_de_la_tabla') AND
    s.owner=upper('&&Nombre_del_propiertario') AND
    s.segment_name=upper('&&Nombre_de_la_tabla') AND
    s.SEGMENT_TYPE='TABLE';
prompt
prompt DATOS DE LOS INDICES
prompt ================================================
select
    'INDEX..................: '||i.INDEX_NAME||chr(10)||
    'SIZE EN MB.............: '||s.BYTES/1024/1024||chr(10)||
    'PROPIETARIO............: '||i.OWNER||chr(10)||
    'TABLE_OWNER............: '||i.TABLE_OWNER||chr(10)||
    'TABLE_NAME.............: '||i.TABLE_NAME||chr(10)||
    'UNIQUENESS.............: '||i.UNIQUENESS||chr(10)||    
    'COMPRESSION............: '||i.COMPRESSION||chr(10)||
    'TABLESPACE_NAME........: '||i.TABLESPACE_NAME||chr(10)||
    'BLEVEL.................: '||i.BLEVEL||chr(10)||
    'STATUS.................: '||i.STATUS||chr(10)||
    'LAST_ANALYZED..........: '||i.LAST_ANALYZED||chr(10)||
    'DEGREE.................: '||i.DEGREE||chr(10)||
    'PARTITIONED............: '||i.PARTITIONED||chr(10)||
    'VISIBILITY.............: '||i.VISIBILITY
from dba_indexes i, dba_segments s where
    i.owner='&&Nombre_del_propiertario' AND
    i.table_name='&&Nombre_de_la_tabla' and
    s.owner='&&Nombre_del_propiertario' AND
    i.index_name=s.segment_name AND
    s.SEGMENT_TYPE='INDEX';
prompt
spoo off;
-- =========================================================================================
-- Sacando la info de los tablepaces antes
-- spoo ${logDir}/tablespaces_DESPUES_&&Nombre_del_propiertario..&&Nombre_de_la_tabla..log
SET HEADING ON;
-- column total_space format 999,999,999,999
-- column free_space format 999,999,999,999
-- column pct_libre format 999.99
-- select a.tablespace_name,
-- total_space/1024/1024 espacio_total_MB,
-- free_space/1024/1024 espacio_libre_MB,
-- --free_space / total_space * 100 PCT_libre,
-- 100 - (free_space / total_space * 100) as PCT_ocupado
-- from (select tablespace_name, sum(bytes)
-- total_space from dba_data_files
-- group by tablespace_name) a,
-- (select tablespace_name, sum(bytes)
-- free_space from dba_free_space
-- group by tablespace_name) b
-- where a.tablespace_name = b.tablespace_name(+)
-- order by PCT_ocupado desc;
-- spoo off;
undef Nombre_del_propiertario
undef Nombre_de_la_tabla
exit;
EOF
pr -w 110 -m -t ${logDir}/definicion_tabla_ANTES_${tabla_full}.log ${logDir}/definicion_tabla_DESPUES_${tabla_full}.log > ${reportDir}/INFORME_${tabla_full}.log
# echo -e "\n\n--========================================================================== INFORME DE TABLESPACES ==========================================================================--\n\n" >> ${reportDir}/INFORME_${tabla_full}.log
# pr -w 200 -m -t ${logDir}/tablespaces_ANTES_${tabla_full}.log ${logDir}/tablespaces_DESPUES_${tabla_full}.log >> ${reportDir}/INFORME_${tabla_full}.log
echo ${reportDir}/INFORME_${tabla_full}.log >> $tmpDir/lista_informes.txt
done;
echo -e "\nEl proceso ha finalizado!! Se han creado los siguientes informes:\n"
for x in $(cat $tmpDir/lista_informes.txt); do echo -e "  --> $x"; done
echo 
echo 

