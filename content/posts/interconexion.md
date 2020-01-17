+++
date = "2020-01-17"
title = "Interconexión de bases de datos"
math = "true"

+++

## Conexion Oracle a Oracle

Vamos a configurar dos máquinas Debian con un Oracle instalado en cada una de ellas.

Para configurar la interconexión primero debemos configurar el listener.ora de Oracle que está ubicado en /opt/oracle/product/12.2.0.1/dbhome_1/network/admin.
Ip de la máquina:
![](/images/Interconexion1.png)

Ip de la máquina 2:
![](/images/Interconexion6.png)

listener.ora:
![](/images/Interconexion2.png)

tnsnames.ora:
![](/images/Interconexion3.png)

```
lsnrctl stop
lsnrctl start
```

### Comprobar interconexión

Para que podamos hacer un database link en oracle primero tendremos que darle permisos a nuestro usuario alexrr
![](/images/Interconexion4.png)

Ahora entramos al usuario alexrr
![](/images/Interconexion5.png)

Ahora creamos el link:
![](/images/Interconexion7.png)

Y probamos un join de nuestras tablas con la base de datos remota
![](/images/Interconexion8.png)

## Conexion PostgreSQL a PostgreSQL

Vamos a configurar dos máquinas Debian con un PostgreSQL instalado en cada uno de ellas.

Ip de la maquina:
![](/images/Interconexion9.png)

Ip de la maquina 2:
![](/images/Interconexion10.png)

Entramos al postgresql de la máquina 1 y le crearemos un usuario y contraseña para hacer la interconexion
![](/images/Interconexion11.png)

Entramos al usuario
![](/images/Interconexion12.png)

Y creamos las tablas
```
Create table Viveros
(
Codigo Varchar(10),
Direccion Varchar(150),
Telefono Varchar(9),
CONSTRAINT pk_Codigo_Vivero PRIMARY KEY (Codigo),
CONSTRAINT direccionvivero_correcta check(Direccion like '%(Dos Hermanas)%' or Direccion like '%(Alcala)%' or Direccion like '%(Gelves)%')
);

insert into Viveros(Codigo,Direccion,Telefono)
values('12345','Ctra. Dos Hermanas Utrera km, 3, 41702 Sevilla (Dos Hermanas)','954720244');
insert into Viveros(Codigo,Direccion,Telefono)
values('12114','Carretera Montequinto a Dos Hermanas, Km 2.5, 41089 Sevilla (Dos Hermanas)','854537288');
insert into Viveros(Codigo,Direccion,Telefono)
values('11567','Calle Mar Báltico, 3, 41927 Mairena del Aljarafe, Sevilla(Gelves)','955600977');
insert into Viveros(Codigo,Direccion,Telefono)
values('64443','Viveros Molina, Autovia A—376 Km, 10,5 Frente a, 41500, Sevilla(Alcala)','615033716');
```

Ahora desde el usuario postgres le damos el permiso de crear links de bases de datos a la base de datos pruebin
![](/images/Interconexion13.png)

Entramos al usuario pruebin y hacemos la interconexion
![](/images/Interconexion14.png)

## Conexion Oracle a PostgreSQL

Máquina Oracle

Ip oracle:
![](/images/Interconexion15.png)

Ip postgres:
![](/images/Interconexion16.png)

En nuestra máquina Oracle vamos a instalar el paquete odbc que es el que permitirá el acceso a postgres desde cualquier gestor de base de datos
```
apt install odbc-postgresql unixodbc
```

Se nos creará un fichero /etc/odbcinst.ini y debemos configurarlo de la siguiente manera
![](/images/Interconexion17.png)

Para comprobarlo ejecutamos
```
root@debian:/home/oracle# odbcinst -q -d
[PostgreSQL ANSI]
[PostgreSQL Unicode]
```

Ahora configuramos /etc/odbc.ini de la siguiente manera:
![](/images/Interconexion18.png)

Hacemos ahora
```
root@debian:/home/oracle# odbcinst -q -s
[PSQLA]
[PSQLU]
[Default]
```

Y comprobamos la conexión
![](/images/Interconexion19.png)

Ahora vamos a crear el fichero $ORACLE_HOME/hs/admin/initPSQLU.ora
![](/images/Interconexion20.png)

Configuraremos el listener para que escuche a psqlu
![](/images/Interconexion21.png)

Y el tnsnames.ora 
![](/images/Interconexion22.png)

Creamos el link ahora y miramos si podemos acceder a la base de datos pruebin.
![](/images/Interconexion23.png)

![](/images/Interconexion24.png)


create public database link enlaceapostgresql2
connect to "pruebin" identified by "pruebin"
using 'PSQLU';
