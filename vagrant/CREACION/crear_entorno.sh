#!/usr/bin/env bash
echo -e "\n--------------------------------------------------------------------------------------"
echo "Script para crear una configuracion basica del entorno oracle para DBAs comodones :-)"
echo -e "--------------------------------------------------------------------------------------\n"

# VARIABLES DE ESTE SCRIPT
export WD=$HOME/configuracion       # WD = WorkDir
export TD=${WD}/tmp                 # TD = TempDir
export EF=${WD}/entorno.cfg         # EF = EnvFile

[[ ! -d ${WD} ]] && mkdir -p ${WD}
[[ ! -d ${TD} ]] && mkdir -p ${TD}
# Inicialmente hice este script para ejecutar bajo demanda. Dejo este bloque para esos casos 
# aunque es un caso que dificilmente se producira en un despliegue.
[[ -r ${EF} ]] && {
    echo -e "\nOUCH!!\nParece que el fichero de entorno ya existe en este usuario:\n\t${EF}\n"
    while true; do
        read -p "Quieres sobreescribirlo o cancelar??[S]obreescribir o [C]ancelar"
        case $SC in
            [YySs]* ) cp ${EF} ${EF}.backup ; echo "[v] Backup hecho: ${EF}.backup. Se continua la configuracion...";;
            [Cc]* ) exit;;
            * ) echo "Las respuestas validas son 'S' para sobreescribir o 'C' para cancelar...";;
        esac
    done

}

# Si no estaba ya configurado, configuramos el .screenrc
[[ ! -r ${HOME}/.screenrc ]] && {
    cat << EOF > $HOME/.screenrc
# #####################################################
# Configuracion de Cap databases para screen
# Hacer detach automaticamente si cerramos la terminal
autodetach on
# Encoding por defecto en utf-8
defutf8 on
# Desactivar el mensaje de inicio
startup_message off
# ------------------------------------------------------------------------------------------
term xterm-256color
# ------------------------------------------------------------------------------------------
# Para que funcione el scroll con el raton
termcapinfo xterm|xterm*|xs|rxvt|vt100|scree*|rxvt-cygwin-native ti@:te@
# Largo de scroll
defscrollback 10000
# ------------------------------------------------------------------------------------------
# Ejemplo:
# C a + space lista de ventanas seleccionable extra
# bind ' ' windowlist -b
# ------------------------------------------------------------------------------------------
# Habilitar la lista de ventanas abajo y con hora
hardstatus on
hardstatus alwayslastline
# Version con el nombre del screen delante de los tabs (la parte en azul)
hardstatus string "%{= wk}%S: %{.bW}%-w%{.rW}%n %t%{-}%+w %=%{..G} %H %{..Y} %d/%m %c "
# hardstatus string "%{.bW}%-w%{.rW}%n %t%{-}%+w %=%{..G} %H %{..Y} %d/%m %c "
# ------------------------------------------------------------------------------------------

attrcolor b ".I"
termcapinfo xterm 'Co#256:AB=\E[48;5;%dm:AF=\E[38;5;%dm'
defbce "on"    
EOF
}


cat << 'EOF' > ${EF}
# ######################################################################
#        FICHERO DE CONFIGURACION DE ENTORNO PENSADO PARA DBAs
# ######################################################################

# ZONA DE FUNCIONES
# ----------------------------------------------------------------------

function verpmon()
{
    export lasInstancias=`ps -efa | grep ora_pmon|grep -v grep |awk '{split($0,a,"ora_pmon_"); print a[2]}' | grep -v print`
    echo -e "Estos son los pmon activos en la maquina...: \n"
    ps -efa | grep _pmon | grep -v grep
    echo -e "\n\nLineas para cambio rapido de SID mediante copy/paste:\n"
    for instancia in $lasInstancias
    do
    echo "export ORACLE_SID=$instancia"
    done
    echo -e "\n\n"
}


function entorno()
{
    echo -e "\n========================================================================================"    
    echo "                          DATOS DEL ENTORNO CARGADO EN MEMORIA"    
    echo "========================================================================================"    
    echo -e "         Este script SOLO MUESTRA el entorno cargado, NO LO CAMBIA!!!!!!!!\n\n"    
    echo "            ORACLE_SID.......: $ORACLE_SID"    
    echo "            ORACLE_UNQNAME...: $ORACLE_UNQNAME"    
    echo "            ORACLE_BASE......: $ORACLE_BASE"    
    echo "            ORACLE_HOME......: $ORACLE_HOME"    
    echo "            LD_LIBRARY_PATH..: $LD_LIBRARY_PATH"    
    echo "            TNS_ADMIN........: $TNS_ADMIN"    
    echo "            ------------- PATH -------------"    
    OIFS=$IFS    
    IFS=':'    
    for ruta in $PATH    
    do    
    echo "            $ruta"    
    done    
    IFS=$OIFS    
    echo -e "\n\n"    
    echo "========================================================================================="    
    echo
}



# ZONA DE ALIAS GENERALES
# ----------------------------------------------------------------------
alias ll='ls -larth --color=auto'
alias grep='grep --color=auto'
alias duu='du -scBM *|sort -nr'
alias duuu='du -amx|sort -n|head -20'
alias sc='screen -DRS'
alias scl='screen -ls'
alias getdbsize='/home/oracle/configuracion/dba/getdbsize/getdbsize.sh'


# ZONA DE VARIABLES GENERALES
# ----------------------------------------------------------------------
export DBA=${HOME}/configuracion/DBA    # Ruta de scripts .sql
export dba=${HOME}/configuracion/dba    # Ruta de scripts .sh



# ZONA DEL ENTORNO ORACLE EXCLUSIVO
# ----------------------------------------------------------------------

# Cargamos un entorno por defecto
[[ -r $HOME/configuracion/entorno1903.cfg ]] && . $HOME/configuracion/entorno1903.cfg

# Ejemplos de ficheros para cargar entornos de oracle distintos
alias entorno1903='. $HOME/configuracion/entorno1903.cfg'
# alias entorno1919='. $HOME/configuracion/entorno1919.cfg'
alias orclcdb='. $HOME/configuracion/orclcdb.cfg'
alias dbone='. $HOME/configuracion/dbone.cfg'

# Alias del wrapper de readline ;-)
alias sqlplus='rlwrap sqlplus'
alias rman='rlwrap rman'
alias dgmgrl='rlwrap dgmgrl'


export OH=$ORACLE_HOME
alias sq='sqlplus / as sysdba'

EOF

# Aqui creamos el fichero de configuracion del entorno 1903
cat <<EOF >> $HOME/configuracion/entorno1903.cfg
# Entorno oracle por defecto
# ----------------------------------------------------------
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export TNS_ADMIN=$ORACLE_HOME/network/admin
export ORACLE_SID=ORCLCDB
export OH=$ORACLE_HOME
export PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/oracle/.local/bin:/home/oracle/bin:$ORACLE_HOME/bin
EOF

# Aqui creamos el fichero de entorno para el contenedor 
# OJO OJO OJO OJO OJO OJO
# Se crea con el nombre por defecto del fichero vagrant
# si se ha cambiado, habra que cambiar el nombre de este fichero y del alias asociado
cat <<EOF >> $HOME/configuracion/orclcdb.cfg
# Cargamos el entorno ORACLE 19
. /home/oracle/configuracion/entorno1903.cfg

# Y AHORA Cargamos el entorno de la CDB ORCLCDB
export ORACLE_SID=ORCLCDB
export trazas=/opt/oracle/diag/rdbms/orclcdb/ORCLCDB/trace
EOF

cat <<EOF >> $HOME/configuracion/dbone.cfg
# Cargamos el entorno ORACLE 19
. /home/oracle/configuracion/entorno1903.cfg

# Y AHORA Cargamos el entorno de la bbdd DBONE
export ORACLE_SID=DBONE
export trazas=/opt/oracle/diag/rdbms/dbone/DBONE/trace
EOF

# Actualizamos el glogin.sql
cp /vagrant/DBA_SCRIPTS/glogin.sql /opt/oracle/product/19c/dbhome_1/sqlplus/admin

grep -P '^\.\s\$HOME/configuracion/entorno\.cfg' $HOME/.bashrc > /dev/null 2>&1
[[ $? -ne 0 ]] && echo -e "\n# Cargamos el entorno de DBA\n. $HOME/configuracion/entorno.cfg" >> $HOME/.bashrc

