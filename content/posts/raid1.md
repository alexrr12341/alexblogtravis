+++
date = "2019-09-28"
title = "Ejercicio Raid 1"
slug = "raid1"
tags = [
    "go",
    "golang",
    "templates",
    "themes",
    "development",
]
categories = [
    "Development",
    "golang",
]
+++

## *Ejercicio RAID 1*


* *Tarea* 1: Entrega un fichero Vagranfile donde definimos la máquina con los discos necesarios para hacer el ejercicio. Además al crear la máquina con vagrant se debe instalar el programa mdadm que nos permite la construcción del RAID.
```
Vagrant.configure("2") do |config|

  config.vm.define :raid1 do |raid1|

    disco = '.vagrant/discoraid1.vdi'

    disco2 = '.vagrant/discoraid2.vdi'

    raid1.vm.box = "debian/buster64"

    raid1.vm.hostname = "EscenarioRaid"

    raid1.vm.network :public_network,:bridge=> "wlp0s20f3"

    raid1.vm.provision "shell",run: "always",inline: "apt-get update"

    raid1.vm.provision "shell",run: "always",inline: "apt-get -y upgrade"

    raid1.vm.provision "shell",run: "always",inline: "apt-get -y install mdadm"

    raid1.vm.provider :virtualbox do |v|

	if not File.exist?(disco)

                 v.customize ["createhd", "--filename", disco, "--size", 1024]

	end

                 v.customize ["storageattach", :id, "--storagectl", "SATA Controller",

                              "--port", 1, "--device", 0, "--type", "hdd",

                              "--medium", disco]

       

     end

     raid1.vm.provider :virtualbox do |v|

             if not File.exist?(disco2)

                 v.customize ["createhd", "--filename", disco2, "--size", 1024]

	     end

                 v.customize ["storageattach", :id, "--storagectl", "SATA Controller",

                              "--port", 2, "--device", 0, "--type", "hdd",

                              "--medium", disco2]

     end

  end

end

```
* *Tarea* 2: Crea una raid llamado md1 con los dos discos que hemos conectado a la máquina.
Para hacer el raid 1 sólo debemos ejecutar el siguiente comando:
```
mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/sdb /dev/sdc
```
Salida de lsblk -f
```
NAME   FSTYPE            LABEL           UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                                          
├─sda1 ext4                              b9ffc3d1-86b2-4a2c-a8be-f2b2f4aa4cb5   16.3G     6% /
├─sda2                                                                                       
└─sda5 swap                              f8f6d279-1b63-4310-a668-cb468c9091d8                [SWAP]
sdb    linux_raid_member EscenarioRaid:1 30ea5d9b-3dd5-d647-ab99-ca08b46e3a30                
└─md1                                                                                        
sdc    linux_raid_member EscenarioRaid:1 30ea5d9b-3dd5-d647-ab99-ca08b46e3a30                
└─md1                      

```
* *Tarea* 3: Comprueba las características del RAID. Comprueba el estado del RAID. ¿Qué capacidad tiene el RAID que hemos creado?
Para comprobar las caracteristicas del RAID ejecutamos el comando
```
mdadm --detail /dev/md1
```

```
/dev/md1:
           Version : 1.2
     Creation Time : Mon Sep 30 08:47:02 2019
        Raid Level : raid1
        Array Size : 1046528 (1022.00 MiB 1071.64 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Mon Sep 30 08:47:07 2019
             State : clean 
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : EscenarioRaid:1  (local to host EscenarioRaid)
              UUID : 30ea5d9b:3dd5d647:ab99ca08:b46e3a30
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc


```

Para mirar el estado del RAID
```
cat /proc/mdstat
```
```
Personalities : [raid1] 
md1 : active raid1 sdc[1] sdb[0]
      1046528 blocks super 1.2 [2/2] [UU]
      
unused devices: <none>
```

Podemos ver que la RAID está activa y ocupa 1GB de espacio

* *Tarea* 4: Crea una partición primaria de 500Mb en el raid1.

```
fdisk /dev/md1

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1): 
First sector (2048-2093055, default 2048): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-2093055, default 2093055): +500M

Created a new partition 1 of type 'Linux' and of size 500 MiB.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.

```

* *Tarea* 5: Formatea esa partición con un sistema de archivo ext3.

```
mkfs.ext3 /dev/md1p1 -L "Raid Particion 1"

mke2fs 1.44.5 (15-Dec-2018)
Creating filesystem with 512000 1k blocks and 128016 inodes
Filesystem UUID: a5048d2d-571f-4957-932d-e0de57b7a473
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729, 204801, 221185, 401409

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
``` 



* *Tarea* 6: Monta la partición en el directorio /mnt/raid0 y crea un fichero. ¿Qué tendríamos que hacer para que este punto de montaje sea permanente?
```
mkdir /mnt/raid1
mount /dev/md1p1 /mnt/raid1
```

```
lsblk -f

NAME      FSTYPE            LABEL            UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                                              
├─sda1    ext4                               b9ffc3d1-86b2-4a2c-a8be-f2b2f4aa4cb5   16.3G     6% /
├─sda2                                                                                           
└─sda5    swap                               f8f6d279-1b63-4310-a668-cb468c9091d8                [SWAP]
sdb       linux_raid_member EscenarioRaid:1  30ea5d9b-3dd5-d647-ab99-ca08b46e3a30                
└─md1                                                                                            
  └─md1p1 ext3              Raid Particion 1 53ebbd0f-90d5-4856-9505-f6297db0b7b3  448.9M     0% /mnt/raid1
sdc       linux_raid_member EscenarioRaid:1  30ea5d9b-3dd5-d647-ab99-ca08b46e3a30                
└─md1                                                                                            
  └─md1p1 ext3              Raid Particion 1 53ebbd0f-90d5-4856-9505-f6297db0b7b3  448.9M     0% /mnt/raid1
```

Para que el punto de montaje sea permanente debemos poner la siguiente linea en /etc/fstab

```
/dev/md1p1      /mnt/raid1      ext3    defaults        0       2
```

Para crear el fichero solo hacemos dentro de /mnt/raid1:
```
root@EscenarioRaid:/mnt/raid1# echo "Hola" > prueba.txt
```

* *Tarea* 7: Simula que un disco se estropea. Muestra el estado del raid para comprobar que un disco falla. ¿Podemos acceder al fichero?

Para simular que un disco se estropea usamos el comando:

```
mdadm -f /dev/md1 /dev/sdc
```

Mostramos que el disco está fallando:
```
/dev/md1:
           Version : 1.2
     Creation Time : Mon Sep 30 08:47:02 2019
        Raid Level : raid1
        Array Size : 1046528 (1022.00 MiB 1071.64 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Mon Sep 30 08:52:03 2019
             State : clean, degraded 
    Active Devices : 1
   Working Devices : 1
    Failed Devices : 1
     Spare Devices : 0

Consistency Policy : resync

              Name : EscenarioRaid:1  (local to host EscenarioRaid)
              UUID : 30ea5d9b:3dd5d647:ab99ca08:b46e3a30
            Events : 21

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       -       0        0        1      removed

       1       8       32        -      faulty   /dev/sdc
```

Comprobamos si podemos acceder al fichero
```
root@EscenarioRaid:/mnt/raid1# cat prueba.txt 
Hola
```

Esto es debido a que la propiedad del raid1 es que en ambos discos se clona toda la informacin

* *Tarea* 8: Recupera el estado del raid y comprueba si podemos acceder al fichero.

Para recuperar el estado del raid hacemos el siguiente comando:
```
mdadm --re-add /dev/md1 /dev/sdc
```

Y comprobamos que está añadido

```
/dev/md1:
           Version : 1.2
     Creation Time : Mon Sep 30 08:47:02 2019
        Raid Level : raid1
        Array Size : 1046528 (1022.00 MiB 1071.64 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Mon Sep 30 09:04:12 2019
             State : clean 
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : EscenarioRaid:1  (local to host EscenarioRaid)
              UUID : 30ea5d9b:3dd5d647:ab99ca08:b46e3a30
            Events : 25

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
```

Y comprobamos que la información del fichero sigue activa
```
root@EscenarioRaid:/mnt/raid1# cat prueba.txt 
Hola
```
* *Tarea* 9: ¿Se puede añadir un nuevo disco al raid 0?. Compruebalo.

Añadimos un nuevo disco de 1gb y lo añadimos a la raid md1.
```
mdadm --add /dev/md1 /dev/sdd 
```

```
/dev/md1:
           Version : 1.2
     Creation Time : Mon Sep 30 10:22:03 2019
        Raid Level : raid1
        Array Size : 1046528 (1022.00 MiB 1071.64 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 2
     Total Devices : 3
       Persistence : Superblock is persistent

       Update Time : Mon Sep 30 10:24:46 2019
             State : clean 
    Active Devices : 2
   Working Devices : 3
    Failed Devices : 0
     Spare Devices : 1

Consistency Policy : resync

              Name : EscenarioRaid:1  (local to host EscenarioRaid)
              UUID : 32fa2884:af75e4ca:bbeda0d1:3a4edc7d
            Events : 18

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc

       2       8       48        -      spare   /dev/sdd
```

Lo que pasa es que al añadir un disco, se nos pone de reserva, ya que al crear el raid hemos puesto que solo hayan 2 dispositivos activos, en cuanto uno de los discos falle, este se sustituirá automáticamente
```
mdadm -f /dev/md1 /dev/sdc
```

```
/dev/md1:
           Version : 1.2
     Creation Time : Mon Sep 30 10:22:03 2019
        Raid Level : raid1
        Array Size : 1046528 (1022.00 MiB 1071.64 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 2
     Total Devices : 3
       Persistence : Superblock is persistent

       Update Time : Mon Sep 30 10:31:40 2019
             State : clean 
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 1
     Spare Devices : 0

Consistency Policy : resync

              Name : EscenarioRaid:1  (local to host EscenarioRaid)
              UUID : 32fa2884:af75e4ca:bbeda0d1:3a4edc7d
            Events : 37

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       2       8       48        1      active sync   /dev/sdd

       1       8       32        -      faulty   /dev/sdc

```


* *Tarea* 10: Redimensiona la partición y el sistema de archivo de 500Mb al tamaño del raid.
* 
Hacemos un nuevo fdisk del raid para poner la partición al máximo

```
root@EscenarioRaid:/mnt/raid1# fdisk /dev/md1

Welcome to fdisk (util-linux 2.33.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.


Command (m for help): n
Partition type
   p   primary (1 primary, 0 extended, 3 free)
   e   extended (container for logical partitions)
Select (default p): 

Using default response p.
Partition number (2-4, default 2): ^C
Command (m for help): d

Selected partition 1
Partition 1 has been deleted.

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): 

Using default response p.
Partition number (1-4, default 1): 
First sector (2048-2093055, default 2048): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-2093055, default 2093055): 

Created a new partition 1 of type 'Linux' and of size 1021 MiB.
Partition #1 contains a ext3 signature.

Do you want to remove the signature? [Y]es/[N]o: n

Command (m for help): w

The partition table has been altered.
Syncing disks.

```

Y para modificar el sistema de ficheros usamos el comando
```
umount /mnt/raid1

e2fsck -f /dev/md1p1
resize2fs /dev/md1p1
```

Lo montamos y observamos que ha cambiado el sistema de ficheros
```
NAME      FSTYPE            LABEL            UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                                              
├─sda1    ext4                               b9ffc3d1-86b2-4a2c-a8be-f2b2f4aa4cb5   16.3G     6% /
├─sda2                                                                                           
└─sda5    swap                               f8f6d279-1b63-4310-a668-cb468c9091d8                [SWAP]
sdb       linux_raid_member EscenarioRaid:1  32fa2884-af75-e4ca-bbed-a0d13a4edc7d                
└─md1                                                                                            
  └─md1p1 ext3              Raid Particion 1 6e7793b3-a379-4988-836e-c2d43b29d5be  927.1M     0% /mnt/raid1
sdc       linux_raid_member EscenarioRaid:1  32fa2884-af75-e4ca-bbed-a0d13a4edc7d                
└─md1                                                                                            
  └─md1p1 ext3              Raid Particion 1 6e7793b3-a379-4988-836e-c2d43b29d5be  927.1M     0% /mnt/raid1
sdd       linux_raid_member EscenarioRaid:1  32fa2884-af75-e4ca-bbed-a0d13a4edc7d                
└─md1                                                                                            
  └─md1p1 ext3              Raid Particion 1 6e7793b3-a379-4988-836e-c2d43b29d5be  927.1M     0% /mnt/raid1

root@EscenarioRaid:/mnt/raid1# ls
lost+found  prueba.txt
```
