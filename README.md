# vagrant-lab-ora19

Proyecto Vagrant para desplegar una VM Linux y practicar con oracle Multitenant

Partiendo del trabajo original de Oracle (https://github.com/oracle/vagrant-projects) he preparado un despliegue un poco mas completo para practicar con el multitenant.

La maquina se crea con 6Gb de RAM y ocupa 17Gb una vez creada.
Se ha utilizado oracle 19.03 porque es la versión disponible para instalar desde la web.
Además una de las practicas es realizar parcheos :)

Estos son los datos del despliegue.

- Maquina Oracle Linux 7.9
- Software de Oracle database 19.03
- Una bbdd contenedor llamada `ORCLCDB`
- Una bbdd PDB llamada `ORCLPDB1`
- Una bbdd no multitenant llamada `DBONE`
- Tanto en `ORCLPDB1` como en `DBONE` se han creado usuarios distintos, con sus propios TS y algunas tablas
- El SO esta completamente configurado con alias, scripts y funciones que facilitan el trabajo.
	- Alias `orclpdb` que carga el entorno de dicha bbdd y define $trazas como la ruta al alert.log
	- Alias `dbone`, carga el entorno de dicha bbdd y define $trazas como la ruta al alert.log
	- Función `entorno` que permite ver las variables de oracle definidas asi como el PATH
	- Función `verpmon` para listar las bbdd arrancadas
	- Todas las bbdd estan definidas en el tnsnames.ora
	- Variable `$DBA` que apunta a la ruta de los scripts .sql
	- Variable `$dba` que apunta a la ruta de los Shell scripts
	- Muchos scripts .sql para listar tablespaces, usuarios, objetos...etc
- Tiene instalado el `rlwrap` y los binarios de Oracle como `sqlplus`, `rman` o incluso `dgmgrl` pasan por el .
- El paquete `screen` también está configurado para mostrar la barra de estado con el nombre de las pestañas.
- Hay una carpeta compartida entre la maquina virtual (`/vagrant`) y la maquina física para facilitar el intercambio de ficheros.


# REQUISITOS

- Virtualbox
- Vagrant
- Vagrant-env (Plugin de vagrant)
- Ram bastante (VM con 6Gb)
- Disco (Ocupa 17Gb)
- git (opcional, ya que este repo puede bajarse a mano en formato zip)

# INSTRUCCIONES

- Tener el software instalado (Vagrant, vagrant-env, Virtualbox)
- Bajar o clonar el repositorio
- Bajar el .zip del software de oracle 19 ([LINUX.X64_193000_db_home.zip](https://www.oracle.com/database/technologies/oracle19c-linux-downloads.html#license-lightbox))
- Ubicar el .zip *sin descomprimir* en la carpeta raiz del repo clonado
- Abrimos una terminal, vamos a la raiz del repo descargado y ejecutamos: `vagrant up`

