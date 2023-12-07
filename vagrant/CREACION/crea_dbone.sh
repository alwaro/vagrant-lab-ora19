#!/bin/bash
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export TNS_ADMIN=$ORACLE_HOME/network/admin
export PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/oracle/.local/bin:/home/oracle/bin:/home/oracle/.local/bin:/home/oracle/bin:$ORACLE_HOME/bin
dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbName DBONE -sid DBONE -sysPassword oracle -systemPassword oracle -emConfiguration NONE -datafileDestination /opt/oracle/oradata -storageType FS -characterSet AL32UTF8 -totalmemory 1536 -listeners LISTENER

echo -e "\n\n--------------------------------------------------------"
echo "BASE DE DATOS DBONE CREADA... INICIANDO CREACION OBJETOS"
echo -e "--------------------------------------------------------"
sqlplus / as sysdba @/vagrant/vagrant/CREACION/dbone_estructura.sql
