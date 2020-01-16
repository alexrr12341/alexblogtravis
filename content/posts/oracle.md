+++
date = "2019-10-01"
title = "Instalación de Oracle 12c en Debian Jessie"
math = "true"

+++

## Instalación de Oracle 12c en Debian Jessie

Para instalar Oracle 12c debemos tener los siguientes requisitos mínimos:

* 30GB de disco duro 
* 2GB de RAM 
* 2 procesadores 
* Conexión a Internet 


### Configuración de Oracle

*Para la estructura de grupos y usuarios se recomienda la siguiente:*
```
addgroup --system oinstall
addgroup --system dba
adduser --system --ingroup oinstall -shell /bin/bash oracle
adduser oracle dba
passwd oracle
```

*Creación de directorios requeridos de Oracle:*
```
mkdir -p /opt/oracle/product/12.2.0.1
mkdir -p /opt/oraInventory
chown -R oracle:dba /opt/ora*
```

*Enlaces para la instalación de Oracle:*
```
ln -s /usr/bin/awk /bin/awk
ln -s /usr/bin/basename /bin/basename
ln -s /usr/bin/rpm /bin/rpm
ln -s /usr/lib/x86_64-linux-gnu /usr/lib64
```

*Limites en el sistema*

```
echo """
## Valor del número máximo de manejadores de archivos. ##
fs.file-max = 65536
fs.aio-max-nr = 1048576
## Valor de los parámetros de semáforo en el orden listado. ##
## semmsl, semmns, semopm, semmni ##
kernel.sem = 250 32000 100 128
## Valor de los tamaños de segmento de memoria compartida. ##
## (Oracle recomienda total de RAM -1 byte) 2GB ##
kernel.shmmax = 2107670527
kernel.shmall = 514567
kernel.shmmni = 4096
## Valor del rango de números de puerto. ##
net.ipv4.ip_local_port_range = 1024 65000
## Valor del número gid del grupo dba. ##
vm.hugetlb_shm_group = 121
## Valor del número de páginas de memoria. ##
vm.nr_hugepages = 64
""" > /etc/sysctl.d/local-oracle.conf
```

*Tras esto cargamos la configuración en el sistema:*
```
sysctl -p /etc/sysctl.d/local-oracle.conf
```

*Hacemos la siguiente configuración por seguridad:*
```
echo """
## Número máximo de procesos disponibles para un solo usuario. ##
oracle          soft    nproc           2047
oracle          hard    nproc           16384
## Número máximo de descriptores de archivo abiertos para un solo usuario. ##
oracle          soft    nofile          1024
oracle          hard    nofile          65536
## Cantidad de RAM para el uso de páginas de memoria. ##
oracle          soft    memlock         204800
oracle          hard    memlock         204800
""" > /etc/security/limits.d/local-oracle.conf
```

*Variables de entorno para Oracle:*
```
echo """
## Nombre del equipo ##
export ORACLE_HOSTNAME=localhost
## Usuario con permiso en archivos Oracle. ##
export ORACLE_OWNER=oracle
## Directorio que almacenará los distintos servicios de Oracle. ##
export ORACLE_BASE=/opt/oracle
## Directorio que almacenará la base de datos Oracle. ##
export ORACLE_HOME=/opt/oracle/product/12.2.0.1/dbhome_1
## Nombre único de la base de datos. ##
export ORACLE_UNQNAME=oraname
## Identificador de servicio de escucha. ##
export ORACLE_SID=orasid
## Ruta a archivos binarios. ##
export PATH=$PATH:/opt/oracle/product/12.2.0.1/dbhome_1/bin
## Ruta a la biblioteca. ##
export LD_LIBRARY_PATH=/opt/oracle/product/12.2.0.1/dbhome_1/lib
## Idioma
export NLS_LANG='SPANISH_SPAIN.AL32UTF8'
""" >> /etc/bash.bashrc
```

*Luego de esto cargamos las variables de entorno:*
```
source /etc/bash.bashrc
```

*Por último, descargamos los paquetes que vamos a necesitar para la instalación de Oracle:*
```
apt -y install build-essential binutils libcap-dev gcc g++ libc6-dev ksh libaio-dev make libxi-dev libxtst-dev libxau-dev libxcb1-dev sysstat rpm xauth xorg unzip
```

### Descarga de Oracle Database Software

Entramos a la página de descargas de [Oracle](https://www.oracle.com/database/technologies/database12c-linux-downloads.html)

Primero iniciamos sesión y aceptamos el "License Agreement". Luego elegimos el siguiente:

* Oracle Database 12c Release 2
* (12.2.0.1.0) Enterprise Edition
* linux x86-64 File 1 (3.2 GB) 

*Y descomprimimos el archivo*
```
unzip linuxx64_12201_database.zip
```

*Si tenemos una máquina virtual usamos scp para pasar la carpeta database y si no entramos en el usuario Oracle*
```
ssh -XC oracle@servidor
```

*Luego entramos y abrimos el instalador gráfico.*
```
database/runInstaller -IgnoreSysPreReqs -ignorePrereq
```

*Muy importante acceder con el usuario oracle


### Instalación gráfica de Oracle

*Seleccionamos la opción de no recibir actualizaciones de seguridad.*

![](/images/Oracle1.png)

*Elegimos la opción para "Crear y configurar base de datos" ya que vamos a crear una nueva base de datos.*

![](/images/Oracle2.png)

*Elegimos la clase Servidor*

![](/images/Oracle3.png)

*Elegimos "Instalación de Base de Datos de Instancia Única"*

![](/images/Oracle4.png)

*Elegimos Avanzada para configurar mas a fondo.*

![](/images/Oracle5.png)

*El idioma lo dejamos por defecto*

![](/images/Oracle6.png)

*Elegimos la opción de Entrepise Edition*

![](/images/Oracle7.png)

*Ahora nos dirá donde instalar Oracle*

*Si tenemos bien configurada las variables de Entorno nos saldrá bien la ruta

![](/images/Oracle8.png)

*El inventario si tenemos bien las variables se configurará automáticamente.*

![](/images/Oracle9.png)

*Seleccionamos el tipo de configuración General*

![](/images/Oracle10.png)

*En los identificadores dejamos todo por defecto*

![](/images/Oracle11.png)

*En las opciones de configuración vamos al apartado Juego de Caracteres y seleccionamos “Unicode”*

![](/images/Oracle12.png)

*Y marcamos en esquemas de ejemplo que cree la base de datos de ejemplo*

![](/images/Oracle13.png)

*En la almacenación dejamos por defecto*

![](/images/Oracle14.png)

*Y saltamos las opciones de gestión y las opciones de recuperación.*


*En la autentificación,para mayor comodidad usamos la misma contraseña para todas las cuentas.*

![](/images/Oracle15.png)

*En grupos del sistema operativo con privilegios dejamos por defecto.*

![](/images/Oracle16.png)

*Y ya pondremos a instalar nuestro Oracle 12c.*

![](/images/Oracle17.png)

*Nos pedirá en la instalación ejecutar unos comandos en modo root, lo ejecutaremos en nuestra terminal.

Si todo va correctamente la instalación finalizará sin errores*

![](/images/Oracle18.png)

![](/images/Oracle19.png)

*Para comprobar que funciona correctamente utilizamos el comando*

```
sqlplus sys/{PASS} as sysdba
```

![](/images/Oracle20.png)

## Instalación de la base de datos

*Por defecto oracle no arranca, asique la arrancaremos manualmente.*

*Arrancaremos primero el listener*

```
lsnrctl start
```

![](/images/Oracle21.png)


*Arrancamos la base de datos*

```
sqlplus / as sysdba

startup
```

![](/images/Oracle22.png)


## Configuración del Acceso remoto

*Si necesitamos acceder mediante la red simplemente debemos modificar el listener.*

*Ponemos estas lineas en $ORACLE_HOME/network/admin/listener.ora*

```
SID_LIST_LISTENER =
 (SID_LIST =
  (SID_DESC =
   (GLOBAL_DBNAME = orcl)
   (ORACLE_HOME = /opt/oracle/product/12.2.0.1/dbhome_1)
   (SID_NAME = orcl)
  )
 )

LISTENER=
 (DESCRIPTION_LIST =
  (DESCRIPTION =
   (ADDRESS_LIST =
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
   )
   (ADDRESS_LIST =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
   )
  )
 )
```

*Y reiniciamos el listener.*

```
lsnrctl stop
lsnrctl start
```

![](/images/Oracle23.png)

*Ahora vamos a crear un usuario para que puedan acceder remotamente por ese usuario.*

```
Create user usuario identified by usuario;
grant connect to usuario;
```

*Y ya si queremos le podremos dar los privilegios que escojamos.*
