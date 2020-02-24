+++
date = "2020-02-24"
title = "Clusters de Alta Disponibilidad"
math = "true"

+++

## Clusters de Alta Disponibilidad

Vamos a realizar un cluster de alta disponibilidad donde instalaremos un CMS y comprobaremos que si se apaga un nodo la aplicación sigue funcionando.
Para ello necesitamos 2 nodos con la base de datos y el cms.

El escenario que tendremos será el siguiente:

```
git clone https://github.com/josedom24/escenarios-HA
```

Utilizaremos el escenario 05 en este caso.

Tenemos un entorno virtual con ansible y un vagrant

Si no sabemos instalar ansible, hacemos

```
pip install ansible
```

```
(ansible) alexrr@pc-alex:~/git/escenarios-HA/05-HA-IPFailover-Apache2+DRBD$ vagrant up
```

```
(ansible) alexrr@pc-alex:~/git/escenarios-HA/05-HA-IPFailover-Apache2+DRBD/ansible$ ansible-playbook -b site.yaml 

```

Tardará unos minutos en hacerlo, pero tendremos dos máquinas con drbd instalado.


Ahora nos metemos en el nodo 1

```
vagrant ssh nodo1
```

Vemos que nodo1 se puede comunicar con nodo2

```
root@nodo1:/home/vagrant# pcs status
Cluster name: mycluster
Stack: corosync
Current DC: nodo2 (version 2.0.1-9e909a5bdd) - partition with quorum
Last updated: Mon Feb 24 10:35:34 2020
Last change: Mon Feb 24 10:17:56 2020 by hacluster via crmd on nodo1

2 nodes configured
2 resources configured

Online: [ nodo1 nodo2 ]

Full list of resources:

 VirtualIP	(ocf::heartbeat:IPaddr2):	Started nodo1
 WebSite	(ocf::heartbeat:apache):	Started nodo1

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled

```

Tenemos dos discos disponibles en nodo1 y nodo2, por lo que vamos a utilizar drbd para compartir dicha información.

```
root@nodo1:/home/vagrant# apt install drbd-utils
root@nodo2:/home/vagrant# apt install drbd-utils
```


En ambos nodos en /etc/drbd.d/wwwdata.res de ambos nodos configuramos lo siguiente
```
resource wwwdata {
 protocol C;
 meta-disk internal;
 device /dev/drbd1;
 syncer {
  verify-alg sha1;
 }
 net {
  allow-two-primaries;
 }
 on nodo1 {
  disk   /dev/sdb;
  address  10.1.1.101:7789;
 }
 on nodo2 {
  disk   /dev/sdb;
  address  10.1.1.102:7789;
 }
}
```

Ahora vamos a crear los recursos y lo vamos a activar en ambos nodos
```
root@nodo1:/home/vagrant# drbdadm create-md wwwdata
initializing activity log
initializing bitmap (16 KB) to all zero
Writing meta data...
New drbd meta data block successfully created.

root@nodo2:/home/vagrant# drbdadm create-md wwwdata
initializing activity log
initializing bitmap (16 KB) to all zero
Writing meta data...
New drbd meta data block successfully created.

root@nodo1:/home/vagrant# drbdadm up wwwdata
root@nodo2:/home/vagrant# drbdadm up wwwdata
```

Como por defecto, los nodos están en modo secundario, vamos a añadir a nodo1 como primario.

```
root@nodo1:/home/vagrant# drbdadm primary --force wwwdata

```

Miramos el estado de la sincronizacion
```
root@nodo1:/home/vagrant# drbdadm status wwwdata
wwwdata role:Primary
  disk:UpToDate
  peer role:Secondary
    replication:Established peer-disk:UpToDate

root@nodo2:/home/vagrant# drbdadm status wwwdata
wwwdata role:Secondary
  disk:UpToDate
  peer role:Primary
    replication:Established peer-disk:UpToDate

```

Ahora vamos a formatear el disco de nodo1 con xfs por lo que hacemos

```
root@nodo1:/home/vagrant# apt install xfsprogs
mkfs.xfs /dev/drbd1

root@nodo1:/home/vagrant# mount /dev/drbd1 /var/www/html

```

Ahora vamos a configurar drbd en nuestro cluster en el nodo1 por lo que hacemos:
```
pcs cluster cib drbd_cfg
pcs -f drbd_cfg resource create WebData ocf:linbit:drbd drbd_resource=wwwdata op monitor interval=60s
pcs -f drbd_cfg resource promotable WebData promoted-max=1 promoted-node-max=1 clone-max=2  clone-node-max=1 notify=true
pcs cluster cib-push drbd_cfg --config
```

Y vamos a generar el recurso para que se monte en /var/www/html:
```
pcs cluster cib fs_cfg
pcs -f fs_cfg resource create WebFS Filesystem device="/dev/drbd1" directory="/var/www/html" fstype="xfs"
pcs -f fs_cfg constraint colocation add WebFS with WebData-clone INFINITY with-rsc-role=Master
pcs -f fs_cfg constraint order promote WebData-clone then start WebFS
pcs -f fs_cfg constraint colocation add WebSite with WebFS INFINITY
pcs -f fs_cfg constraint order WebFS then WebSite
pcs cluster cib-push fs_cfg --config
```

Ahora vamos a ver el estado del cluster:

```
root@nodo1:/var/www/html# pcs status
Cluster name: mycluster
Stack: corosync
Current DC: nodo2 (version 2.0.1-9e909a5bdd) - partition with quorum
Last updated: Mon Feb 24 10:58:39 2020
Last change: Mon Feb 24 10:58:17 2020 by root via cibadmin on nodo1

2 nodes configured
5 resources configured

Online: [ nodo1 nodo2 ]

Full list of resources:

 VirtualIP	(ocf::heartbeat:IPaddr2):	Started nodo1
 WebSite	(ocf::heartbeat:apache):	Started nodo1
 Clone Set: WebData-clone [WebData] (promotable)
     Masters: [ nodo1 ]
     Slaves: [ nodo2 ]
 WebFS	(ocf::heartbeat:Filesystem):	Started nodo1

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled

```

Vemos como el maestro es nodo1 y el esclavo es nodo2.

Ahora vamos a realizar la configuración para wordpress, para ello instalamos el modulo de php para apache
```
root@nodo1:/var/www/html# apt install libapache2-mod-php php-mysql
root@nodo2:/home/vagrant# apt install libapache2-mod-php php-mysql

```

Y en el nodo 1 descargamos wordpress en /var/www/html
```
root@nodo1:/var/www/html# wget https://es.wordpress.org/latest-es_ES.zip
root@nodo1:/var/www/html# unzip latest-es_ES.zip
root@nodo1:/var/www/html# cp -r wordpress/* .
root@nodo1:/var/www/html# rm -r wordpress/


```

![](/images/Wordpress1.png)


Ahora vamos a configurar la base de datos, para ello vamos a instalar mariadb en ambos servidores
```
root@nodo1:/var/www/html# apt install mariadb-server
root@nodo2:/home/vagrant# apt install mariadb-server

```

Cambiamos la contraseña al root de ambas mariadb
```
set password = password("root");

```

Ahora instalaremos rsync en ambos nodos
```
root@nodo1:/var/www/html# apt install rsync
root@nodo2:/home/vagrant# apt install rsync

```

*Como es vagrant ya lo tenemos instalado*


Ahora vamos a configurar galera en el primer nodo, para ello vamos creamos /etc/mysql/conf.d/galera.cnf y realizamos:
```
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="cluster_mariadb"
wsrep_cluster_address="gcomm://10.1.1.101,10.1.1.102"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="10.1.1.101"
wsrep_node_name="nodo1"

```

En el nodo2 haremos el mismo fichero pero con esta información
```
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="cluster_mariadb"
wsrep_cluster_address="gcomm://10.1.1.101,10.1.1.102"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="10.1.1.102"
wsrep_node_name="nodo2"
```

Ahora vamos a parar mariadb en ambos nodos
```
systemctl stop mysql
```

Ahora en el nodo1 lanzamos el cluster
```
root@nodo1:/var/www/html# galera_new_cluster

```

Ahora verificamos si está lanzado el cluster
```
root@nodo1:/var/www/html# mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
Enter password: 
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 1     |
+--------------------+-------+

```

Ahora iniciamos el segundo nodo y miramos de vuelta el comando

```
root@nodo2:/home/vagrant# systemctl restart mysql


root@nodo2:/home/vagrant# mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
Enter password: 
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 2     |
+--------------------+-------+

```

Vamos a comprobar la replicación para eso vamos a crear una base de datos llamada wordpress en el nodo1 y también un usuario igual, y vamos a observar que en nodo2 está realizada

```
root@nodo1:/var/www/html# mysql -u root -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 14
Server version: 10.3.22-MariaDB-0+deb10u1 Debian 10

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> create database wordpress;
Query OK, 1 row affected (0.020 sec)

MariaDB [(none)]> create user wordpress identified by 'wordpress';
Query OK, 0 rows affected (0.031 sec)

MariaDB [(none)]> grant all privileges on wordpress.* to wordpress;
Query OK, 0 rows affected (0.008 sec)

MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.009 sec)


root@nodo2:/home/vagrant# mysql -u wordpress -p wordpress
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 14
Server version: 10.3.22-MariaDB-0+deb10u1 Debian 10

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [wordpress]> 

```

Como ya tenemos la base de datos wordpress, vamos a acceder a wordpress y configurar el config.php
```
root@nodo1:/var/www/html# cp wp-config-sample.php wp-config.php
root@nodo1:/var/www/html# nano wp-config.php

define('DB_NAME', 'wordpress');
define('DB_USER', 'wordpress');
define('DB_PASSWORD', 'wordpress');


```

Ahora entramos a wordpress

![](/images/Wordpress2.png)

Vamos a añadir un post para que comprobemos que la base de datos se replica.

![](/images/Wordpress3.png)


Ahora vamos a tirar la maquina nodo1 y vamos a comprobar que se monta en nodo2 y sigue la base de datos funcionando

```
(ansible) alexrr@pc-alex:~/git/escenarios-HA/05-HA-IPFailover-Apache2+DRBD$ vagrant halt nodo1

```

Miramos el nodo2

```
root@nodo2:/home/vagrant# lsblk -f
NAME    FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                      
├─sda1  ext4         0355bc72-bb92-4894-90fa-d2ccd87e7dd6   15.4G    11% /
├─sda2                                                                   
└─sda5  swap         0147b768-52ec-4267-bf05-7a5aea8451a2                [SWAP]
sdb     drbd         cd2aa0fae1bdc02a                                    
└─drbd1                                                    432.4M    15% /var/www/html

```

![](/images/Wordpress4.png)
