#!/bin/bash

# Agregamos el repo de EPEL
yum -y install oracle-epel-release-el7
# Una vez instalado, instalamos el wrapper, glances y GNU Screen
yum -y install rlwrap glances screen neovim

# Metemos a oracle en el grupo wheel
usermod -a -G wheel oracle

# Damos permisos y ejecutamos el script de config de entorno
# Copio antes para evitar problemas con FS tipo windows y permisos.
cp /vagrant/vagrant/CREACION/crear_entorno.sh /tmp
chmod ugo+x /tmp/crear_entorno.sh
su -l oracle -c /tmp/crear_entorno.sh

# Lo mismo con el script de creacion de DBONE
# Copio antes para evitar problemas con FS tipo windows y permisos.
cp /vagrant/vagrant/CREACION/crea_dbone.sh /tmp
chmod ugo+x /tmp/crea_dbone.sh
su -l oracle -c /tmp/crea_dbone.sh

# Configuramos las rutas para sql y shellscripts
export CFGDIR=/home/oracle/configuracion
[[ ! -d $CFGDIR/DBA ]] && mkdir -p $CFGDIR/DBA
[[ ! -d $CFGDIR/dba ]] && mkdir -p $CFGDIR/dba
cp /vagrant/vagrant/DBA_SCRIPTS/*.sql $CFGDIR/DBA
cp -R /vagrant/vagrant/DBA_SHELL/* $CFGDIR/dba

# Por si acaso, todo pertenecera a oracle
chown -R oracle $CFGDIR

# Eliminamos restos
rm -rf /tmp/crear_entorno.sh
rm -rf /tmp/crea_dbone.sh

