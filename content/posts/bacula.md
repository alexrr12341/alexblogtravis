+++
date = "2020-01-30"
title = "Sistema de Copias de Seguridad(Bacula)"
math = "true"

+++

Vamos a utilizar bacula como sistema de copia de seguridad, y vamos a utilizar una instancia de ubuntu que la llamaremos choco(172.22.200.164)


## Instalación de bacula

Primero de todo vamos a empezar instalando los servidores necesarios para poder ejecutar bacula
```
apt install apache2 mariadb-server mariadb-client php
```

Ahora instalaremos bacula completamente
```
apt install bacula bacula-client bacula-common-mysql bacula-director-mysql bacula-server
```

## Instalcaión de webmin

Para instalarnos webmin, que sirve para monitorizar las copias de seguridad, debemos descargarnoslo de la página https://sourceforge.net/projects/webadmin/files/webmin/

```
dpkg -i webmin_1.940_all.deb
```

Nos saltará error de dependencias por lo que debemos hacer:
```
apt install libauthen-pam-perl libio-pty-perl apt-show-versions
apt -f install
```
Vamos a comprobar que funcione:

![](/images/Copias1.png)

## Configuración de Bacula Director

El fichero estará en /etc/bacula/bacula-dir.conf y ahí es donde configuraremos como haremos nuestras copias de seguridad

```
Director {                            # define myself
  Name = choco-dir
  DIRport = 9101                # where we listen for UA connections
  QueryFile = "/etc/bacula/scripts/query.sql"
  WorkingDirectory = "/var/lib/bacula"
  PidDirectory = "/run/bacula"
  Maximum Concurrent Jobs = 20
  Password = "bacula"         # Console password
  Messages = Daemon
  DirAddress = 10.0.0.10
}

```

También vamos a configurar la tarea que se realizará a las copias de seguridad, en este caso semanalmente se hará una copia completa.

```
JobDefs {
 Name = "Backups"
 Type = Backup
 Level = Incremental
 Client = choco-fd
 FileSet = "Full Set"
 Schedule = "semanal"
 Storage = File
 Messages = Standard
 Pool = File
 SpoolAttributes = yes
 Priority = 10
 Write Bootstrap = "/var/lib/bacula/%c.bsr"
}

JobDefs {
 Name = "BackupsCroqueta"
 Type = Backup
 Level = Incremental
 Client = choco-fd
 FileSet = "Croqueta Set"
 Schedule = "semanal"
 Storage = File
 Messages = Standard
 Pool = File
 SpoolAttributes = yes
 Priority = 10
 Write Bootstrap = "/var/lib/bacula/%c.bsr"
}

```

Ahora vamos a configurar las tareas de los clientes

```
Job {
 Name = "choco"
 JobDefs = "Backups"
 Client = "choco-fd"
}

Job {
 Name = "croqueta"
 JobDefs = "Backups"
 Client = "croqueta-fd"
}

Job {
 Name = "salmorejo"
 JobDefs = "Backups"
 Client = "salmorejo-fd"
}

Job {
 Name = "tortilla"
 JobDefs = "Backups"
 Client = "tortilla-fd"
}
```

Ahora vamos a configurar el Backup de todas las máquinas
```
Job {
 Name = "RestoreChoco"
 Type = Restore
 Client=choco-fd
 FileSet="Full Set"
 Storage = File
 Pool = File
 Messages = Standard
}

Job {
 Name = "RestoreCroqueta"
 Type = Restore
 Client=croqueta-fd
 FileSet="Croqueta Set"
 Storage = File
 Pool = File
 Messages = Standard
}

Job {
 Name = "RestoreSalmorejo"
 Type = Restore
 Client=salmorejo-fd
 FileSet="Full Set"
 Storage = File
 Pool = File
 Messages = Standard
}

Job {
 Name = "RestoreTortilla"
 Type = Restore
 Client=tortilla-fd
 FileSet="Full Set"
 Storage = File
 Pool = File
 Messages = Standard
}
```

Ahora vamos a definir los ficheros que guardaran cada una de las máquinas en su copia de seguridad
```
FileSet {
 Name = "Croqueta Set"
 Include {
 Options {
 signature = MD5
 compression = GZIP
 }
 File = /home
 File = /etc
 File = /var
 }
 Exclude {
 File = /var/lib/bacula
 File = /nonexistant/path/to/file/archive/dir
 File = /proc
 File = /var/tmp
 File = /tmp
 File = /sys
 File = /.journal
 File = /.fsck
 }
}

FileSet {
 Name = "Full Set"
 Include {
 Options {
 signature = MD5
 compression = GZIP
 }
 File = /home
 File = /etc
 File = /var
 }
 Exclude {
 File = /var/lib/bacula
 File = /nonexistant/path/to/file/archive/dir
 File = /proc
 File = /var/cache
 File = /var/tmp
 File = /tmp
 File = /sys
 File = /.journal
 File = /.fsck
 }
}
```

Ahora vamos a configurar nuestro ciclo, para que sea semanal

```
Schedule {
 Name = semanal
 Run = Level=Full sun at 23:05
 Run = Level=Incremental mon-sat at 23:05
}
```

Ahora debemos configurar a nuestros clientes de bacula

```
Client {
 Name = choco-fd
 Address = 10.0.0.10
 FDPort = 9102
 Catalog = MyCatalog
 Password = "bacula" # password for FileDaemon
 File Retention = 60 days # 60 days
 Job Retention = 6 months # six months
 AutoPrune = yes # Prune expired Jobs/Files
}

Client {
 Name = croqueta-fd
 Address = 10.0.0.15
 FDPort = 9102
 Catalog = MyCatalog
 Password = "bacula" # password for FileDaemon 2
 File Retention = 60 days # 60 days
 Job Retention = 6 months # six months
 AutoPrune = yes # Prune expired Jobs/Files
}

Client {
 Name = salmorejo-fd
 Address = 10.0.0.11
 FDPort = 9102
 Catalog = MyCatalog
 Password = "bacula" # password for FileDaemon 2
 File Retention = 60 days # 60 days
 Job Retention = 6 months # six months
 AutoPrune = yes # Prune expired Jobs/Files
}

Client {
 Name = tortilla-fd
 Address = 10.0.0.7
 FDPort = 9102
 Catalog = MyCatalog
 Password = "bacula" # password for FileDaemon 2
 File Retention = 60 days # 60 days
 Job Retention = 6 months # six months
 AutoPrune = yes # Prune expired Jobs/Files
}
```

Ahora vamos a configurar nuestro almacenamiento
```
Storage {
 Name = File
# Do not use "localhost" here
 Address = 10.0.0.10 # N.B. Use a fully qualified name here
 SDPort = 9103
 Password = "bacula"
 Device = FileChgr1
 Media Type = File
 Maximum Concurrent Jobs = 10 # run up to 10 jobs a the same time
}
```

Y en teoría el acceso a la base de datos tendríamos que tenerlo así
```
Catalog {
  Name = MyCatalog
  dbname = "bacula"; DB Address = "localhost"; dbuser = "bacula"; dbpassword = "bacula"
}

```

También definiremos el Pool, solo tendremos que añadirle unas cuantas cosas
```
Pool {
 Name = File
 Pool Type = Backup
 Recycle = yes # Bacula can automatically recycle Volumes
 AutoPrune = yes # Prune expired volumes
 Volume Retention = 365 days # one year
 Maximum Volume Bytes = 50G # Limit Volume size to something reasonable
 Maximum Volumes = 100 # Limit number of Volumes in Pool
 Label Format = "Remoto" # Auto label
}
```

Añadiremos en mi caso, una configuración anual, para que haya copias de seguridad en cada año, con plan de futuro.

```
#anual
JobDefs {
 Name = "Backups-anual"
 Type = Backup
 Level = Full
 Client = choco-fd
 FileSet = "Full Set"
 Schedule = "anual"
 Storage = File
 Messages = Standard
 Pool = File
 SpoolAttributes = yes
 Priority = 10
 Write Bootstrap = "/var/lib/bacula/%c.bsr"
}

#anual
Job {
 Name = "choco-anual"
 JobDefs = "Backups-anual"
 Client = "choco-fd-anual"
}

Job {
 Name = "croqueta-anual"
 JobDefs = "Backups-anual"
 Client = "croqueta-fd-anual"
}

Job {
 Name = "salmorejo-anual"
 JobDefs = "Backups-anual"
 Client = "salmorejo-fd-anual"
}

Job {
 Name = "tortilla-anual"
 JobDefs = "Backups-anual"
 Client = "tortilla-fd-anual"
}

#Restore anual
Job {
 Name = "RestoreChoco-anual"
 Type = Restore
 Client=choco-fd-anual
 FileSet="Full Set"
 Storage = File
 Pool = File
 Messages = Standard
}

Job {
 Name = "RestoreCroqueta-anual"
 Type = Restore
 Client=croqueta-fd-anual
 FileSet="Croqueta Set"
 Storage = File
 Pool = File
 Messages = Standard
}

Job {
 Name = "RestoreSalmorejo-anual"
 Type = Restore
 Client=salmorejo-fd-anual
 FileSet="Full Set"
 Storage = File
 Pool = File
 Messages = Standard
}

Job {
 Name = "RestoreTortilla-anual"
 Type = Restore
 Client=tortilla-fd-anual
 FileSet="Full Set"
 Storage = File
 Pool = File
 Messages = Standard
}

#schedule anual
Schedule {
 Name = anual
 Run = Full on 31 Dec at 23:50
}

#Clientes anual

Client {
 Name = choco-fd-anual
 Address = 10.0.0.10
 FDPort = 9102
 Catalog = MyCatalog
 Password = "bacula" # password for FileDaemon
 File Retention = 15 years # 60 days
 Job Retention = 15 years # six months
 AutoPrune = yes # Prune expired Jobs/Files
}

Client {
 Name = croqueta-fd-anual
 Address = 10.0.0.15
 FDPort = 9102
 Catalog = MyCatalog
 Password = "bacula" # password for FileDaemon 2
 File Retention = 15 years # 60 days
 Job Retention = 15 years # six months
 AutoPrune = yes # Prune expired Jobs/Files
}

Client {
 Name = salmorejo-fd-anual
 Address = 10.0.0.11
 FDPort = 9102
 Catalog = MyCatalog
 Password = "bacula" # password for FileDaemon 2
 File Retention = 15 years # 60 days
 Job Retention = 15 years # six months
 AutoPrune = yes # Prune expired Jobs/Files
}

Client {
 Name = tortilla-fd-anual
 Address = 10.0.0.7
 FDPort = 9102
 Catalog = MyCatalog
 Password = "bacula" # password for FileDaemon 2
 File Retention = 15 years # 60 days
 Job Retention = 15 years # six months
 AutoPrune = yes # Prune expired Jobs/Files
}
```

Si queremos comprobar que tengamos la sintaxis correcta, haremos un
```
root@choco:/home/ubuntu# bacula-dir -tc /etc/bacula/bacula-dir.conf
root@choco:/home/ubuntu# 
```

## Configuración del dispositivo de almacenamiento

Tenemos un volumen de 20gb para las particiones, debemos hacer que la particion ocupe los 20gb y que su sistema de ficheros sea ext4
```
root@choco:/home/ubuntu# mkdir /bacula
root@choco:/home/ubuntu# mkfs.ext4 /dev/vdb 
root@choco:/home/ubuntu# mount /dev/vdb /bacula
root@choco:/home/ubuntu# lsblk -f
NAME    FSTYPE LABEL           UUID                                 MOUNTPOINT
vda                                                                 
├─vda1  ext4   cloudimg-rootfs 15993e31-3f38-4b9f-bdeb-74e0541498d0 /
├─vda14                                                             
└─vda15 vfat   UEFI            323C-AF60                            /boot/efi
vdb     ext4                   930e6bb2-ccde-4dcb-a023-fa4d25aa0b55 /bacula

root@choco:/bacula# mkdir backups
root@choco:/bacula# chown bacula:bacula /bacula/backups/ -R
root@choco:/bacula# chmod 755 /bacula/backups/ -R
```

También queremos que se monte el volumen ante reinicios por lo que lo meteremos en el /etc/fstab
```
UUID=930e6bb2-ccde-4dcb-a023-fa4d25aa0b55       /bacula ext4    defaults        0       1
```

## Modificación de bacula-sd

El fichero está localizado en /etc/bacula/bacula-sd.conf y es ahí donde configuraremos el storage de nuestra copia de seguridad

```
Storage { # definition of myself
 Name = choco-sd
 SDPort = 9103 # Director's port
 WorkingDirectory = "/var/lib/bacula"
 Pid Directory = "/run/bacula"
 Maximum Concurrent Jobs = 20
 SDAddress = 10.0.0.10
}


Director {
  Name = choco-dir
  Password = "bacula"
}

Director {
  Name = choco-mon
  Password = "bacula"
  Monitor = yes
}

Autochanger {
 Name = FileChgr1
 Device = FileStorage
 Changer Command = ""
 Changer Device = /dev/null
}

Device {
 Name = FileStorage
 Media Type = File
 Archive Device = /bacula/backups
 LabelMedia = yes; # lets Bacula label unlabeled media
 Random Access = Yes;
 AutomaticMount = yes; # when device opened, read it
 RemovableMedia = no;
 AlwaysOpen = no;
 Maximum Concurrent Jobs = 5
}

```

Como siempre, para comprobar que funcione hacemos
```
root@choco:/bacula# bacula-sd -tc /etc/bacula/bacula-sd.conf
root@choco:/bacula# 
```

Y reiniciamos los servicios
```
root@choco:/bacula# systemctl restart bacula-sd.service
root@choco:/bacula# systemctl restart bacula-director.service
```

## Configuración del fichero bconsole

Este fichero solo lo configuraremos para acceder a la consola de bacula y estará en /etc/bacula/bconsole.conf

```
Director {
 Name = choco-dir
 DIRport = 9101
 address = 10.0.0.10
 Password = bacula
}
```

## Configuración de los clientes

Como es obvio, debemos configurar los clientes para que podamos realizarle una copia de seguridad, por lo que iremos uno a uno configurandolos

### Cliente Choco

Para configurar este cliente, que ya está instalado ya que lo instalamos anteriormente, debemos ir a /etc/bacula/bacula-fd.conf y realizar la siguiente configuración
```
Director {
  Name = choco-dir
  Password = "bacula"
}

Director {
  Name = choco-mon
  Password = "bacula"
  Monitor = yes
}

FileDaemon {                          # this is me
  Name = choco-fd
  FDport = 9102                  # where we listen for the director
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /run/bacula
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib/bacula
  FDAddress = 10.0.0.10
}

Messages {
 Name = Standard
 director = choco-dir = all, !skipped, !restored
}
```

Y reiniciamos el servicio
```
systemctl restart bacula-fd.service
```

### Cliente Croqueta

Primero, debemos instalar el cliente de bacula
```
apt install bacula-client
```

Y como anteriormente, debemos configurar /etc/bacula/bacula-fd.conf
```
Director {
  Name = choco-dir
  Password = "bacula"
}

Director {
  Name = choco-mon
  Password = "bacula"
  Monitor = yes
}

FileDaemon {                          # this is me
  Name = croqueta-fd
  FDport = 9102                  # where we listen for the director
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /run/bacula
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib/bacula
  FDAddress = 10.0.0.10
}

Messages {
 Name = Standard
 director = choco-dir = all, !skipped, !restored
}
```

Y reiniciamos el servicio
```
systemctl restart bacula-fd.service
```

### Cliente Salmorejo

Ya que salmorejo está en un Centos 8, simplemente cambiará la forma donde instalarlo

```
dnf install bacula-client
```

La configuración se deberá hacer también en /etc/bacula/bacula-fd.conf
```
Director {
  Name = choco-dir
  Password = "bacula"
}

Director {
  Name = choco-mon
  Password = "bacula"
  Monitor = yes
}

FileDaemon { # this is me
 Name = salmorejo-fd
 FDport = 9102 # where we listen for the director
 WorkingDirectory = /var/spool/bacula
 Pid Directory = /var/run
 Maximum Concurrent Jobs = 20
}

Messages {
 Name = Standard
 director = choco-dir = all, !skipped, !restored
}
```

Y reiniciamos el servicio
```
systemctl restart bacula-fd.service
```

### Cliente Tortilla

Primero, debemos instalar el cliente de bacula
```
apt install bacula-client
```

Y como anteriormente, debemos configurar /etc/bacula/bacula-fd.conf
```
Director {
  Name = choco-dir
  Password = "bacula"
}

Director {
  Name = choco-mon
  Password = "bacula"
  Monitor = yes
}

FileDaemon {                          # this is me
  Name = tortilla-fd
  FDport = 9102                  # where we listen for the director
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /run/bacula
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib/bacula
  FDAddress = 10.0.0.7
}

Messages {
 Name = Standard
 director = choco-dir = all, !skipped, !restored
}
```

Y reiniciamos el servicio
```
systemctl restart bacula-fd.service
```


Cuando tengamos los 3 clientes configurados, debemos reiniciar los servicios en choco

```
systemctl restart bacula-fd.service
systemctl restart bacula-sd.service
systemctl restart bacula-director.service
```

Vamos a acceder a la consola de bacula a ver si están los 3 clientes
```
root@choco:/bacula# bconsole
Connecting to Director 10.0.0.10:9101
1000 OK: 103 choco-dir Version: 9.0.6 (20 November 2017)
Enter a period to cancel a command.
*status client
The defined Client resources are:
     1: choco-fd
     2: croqueta-fd
     3: salmorejo-fd
     4: tortilla-fd
     5: choco-fd-anual
     6: croqueta-fd-anual
     7: salmorejo-fd-anual
     8: tortilla-fd-anual

```

## Configuración y gestión a través de la consola bacula


### Añadir volumen

```
root@choco:/bacula# bconsole
Connecting to Director 10.0.0.10:9101
1000 OK: 103 choco-dir Version: 9.0.6 (20 November 2017)
Enter a period to cancel a command.
*label
Automatically selected Catalog: MyCatalog
Using Catalog "MyCatalog"
The defined Storage resources are:
     1: File
     2: File1
     3: File2
Select Storage resource (1-3): 1
Enter new Volume name: bacula
Defined Pools:
     1: Default
     2: File
     3: Scratch
Select the Pool (1-3): 2
Connecting to Storage daemon File at 10.0.0.10:9103 ...
Sending label command for Volume "bacula" Slot 0 ...
3000 OK label. VolBytes=211 VolABytes=0 VolType=1 Volume="bacula" Device="FileStorage" (/bacula/backups)
Catalog record for Volume "bacula", Slot 0  successfully created.
Requesting to mount FileChgr1 ...
3906 File device ""FileStorage" (/bacula/backups)" is always mounted.
```

### Realización de copias de seguridad

```
root@choco:/home/ubuntu# bconsole
Connecting to Director 10.0.0.10:9101
1000 OK: 103 choco-dir Version: 9.0.6 (20 November 2017)
Enter a period to cancel a command.
*status
Status available for:
     1: Director
     2: Storage
     3: Client
     4: Scheduled
     5: Network
     6: All
Select daemon type for status (1-6): 6
choco-dir Version: 9.0.6 (20 November 2017) x86_64-pc-linux-gnu ubuntu 18.04
Daemon started 18-Jan-20 14:01, conf reloaded 18-Jan-2020 14:01:34
 Jobs: run=0, running=0 mode=0,0
 Heap: heap=270,336 smbytes=87,479 max_bytes=90,710 bufs=373 max_bufs=388
 Res: njobs=16 nclients=8 nstores=3 npools=3 ncats=1 nfsets=3 nscheds=4

Scheduled Jobs:
Level          Type     Pri  Scheduled          Job Name           Volume
===================================================================================
Incremental    Backup    10  18-Jan-20 23:05    choco              bacula
Incremental    Backup    10  18-Jan-20 23:05    croqueta           bacula
Incremental    Backup    10  18-Jan-20 23:05    salmorejo          bacula
Incremental    Backup    10  18-Jan-20 23:05    tortilla           bacula
====

```
