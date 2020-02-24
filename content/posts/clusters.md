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
