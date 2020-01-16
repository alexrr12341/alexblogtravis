+++
date = "2019-10-01"
title = "Ejercicio Raid 5"
tags = [
    "go",
    "golang",
    "hugo",
    "development",
]
categories = [
    "Development",
    "golang",
]
+++

## Ejercicio Raid 5

*Fichero de Configuración*
```
Vagrant.configure("2") do |config|

  config.vm.define :raid5 do |raid5|

    disco = '.vagrant/discoraid1.vdi'

    disco2 = '.vagrant/discoraid2.vdi'

    disco3 = '.vagrant/discoraid3.vdi'

    raid5.vm.box = "debian/buster64"

    raid5.vm.hostname = "EscenarioRaid"

    raid5.vm.provision "shell",run: "always",inline: "apt-get update"

    raid5.vm.provision "shell",run: "always",inline: "apt-get -y upgrade"

    raid5.vm.provision "shell",run: "always",inline: "apt-get -y install mdadm"

    raid5.vm.provision "shell",run: "always",inline: "apt-get -y install lvm2"

    raid5.vm.provider :virtualbox do |v|

	if not File.exist?(disco)

                 v.customize ["createhd", "--filename", disco, "--size", 1024]

	end

                 v.customize ["storageattach", :id, "--storagectl", "SATA Controller",

                              "--port", 1, "--device", 0, "--type", "hdd",

                              "--medium", disco]

       

     end

     raid5.vm.provider :virtualbox do |v|

             if not File.exist?(disco2)

                 v.customize ["createhd", "--filename", disco2, "--size", 1024]

	     end

                 v.customize ["storageattach", :id, "--storagectl", "SATA Controller",

                              "--port", 2, "--device", 0, "--type", "hdd",

                              "--medium", disco2]

     end

     raid5.vm.provider :virtualbox do |v|

             if not File.exist?(disco3)

                 v.customize ["createhd", "--filename", disco3, "--size", 1024]

	     end

                 v.customize ["storageattach", :id, "--storagectl", "SATA Controller",

                              "--port", 3, "--device", 0, "--type", "hdd",

                              "--medium", disco3]

     end

  end

end

```

*Tarea 1: Crea una raid llamado md5 con los discos que hemos conectado a la máquina.*

Para hacer un raid 5 necesitamos 3 discos como mínimo y ejecutar el siguiente comando:
```
mdadm --create /dev/md5 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd
```
*Tarea 2: Comprueba las características del RAID. Comprueba el estado del RAID. ¿Qué capacidad tiene el RAID que hemos creado?*

Para comprobar las características realizamos el comando:
```
mdadm --detail /dev/md5

/dev/md5:
           Version : 1.2
     Creation Time : Tue Oct  1 20:23:01 2019
        Raid Level : raid5
        Array Size : 2093056 (2044.00 MiB 2143.29 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 3
     Total Devices : 3
       Persistence : Superblock is persistent

       Update Time : Tue Oct  1 20:23:13 2019
             State : clean 
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : EscenarioRaid:5  (local to host EscenarioRaid)
              UUID : 8cf8c1b5:aa709441:ea11eacf:b0de25f6
            Events : 18

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       3       8       48        2      active sync   /dev/sdd

```

Para ver el estado usamos el comando:
```
cat /proc/mdstat

Personalities : [raid6] [raid5] [raid4] 
md5 : active raid5 sdd[3] sdc[1] sdb[0]
      2093056 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]
      
unused devices: <none>
```

La capacidad de esta raid será de 2GB.

*Tarea 3: Crea un volumen lógico de 500Mb en el raid 5.*

Para crear un volúmen lógico primero definimos el raid.
```
pvcreate /dev/md5
``` 

Luego lo metermos en un grupo de volumenes
```
vgcreate raid /dev/md5
```

Y creamos el volumen lógico
```
lvcreate --size 500M -n raid-lv raid
```
*Tarea 4: Formatea ese volumen con un sistema de archivo xfs.*
Primero de todo instalados el paquete para poder formatear con xfs
```
apt-get install xfsprogs
```
Luego realizamos el formateo del volumen
```
mkfs.xfs /dev/mapper/raid-raid--lv -L "Raid 5"
```

Salida del comando lsblk -f
```
NAME FSTYPE LABEL UUID                                   FSAVAIL FSUSE% MOUNTPOINT
sda                                                                     
├─sda1
│    ext4         b9ffc3d1-86b2-4a2c-a8be-f2b2f4aa4cb5     16.2G     7% /
├─sda2
│                                                                       
└─sda5
     swap         f8f6d279-1b63-4310-a668-cb468c9091d8                  [SWAP]
sdb  linux_ EscenarioRaid:5
│                 8cf8c1b5-aa70-9441-ea11-eacfb0de25f6                  
└─md5
     LVM2_m       rzgN4Q-zYNz-hDHf-woWf-mK3j-Q72Z-X5t13s                
  └─raid-raid--lv
     xfs    Raid 5
                  a40e2225-d1f3-4eed-a7c7-e6e9b8a89283                  
sdc  linux_ EscenarioRaid:5
│                 8cf8c1b5-aa70-9441-ea11-eacfb0de25f6                  
└─md5
     LVM2_m       rzgN4Q-zYNz-hDHf-woWf-mK3j-Q72Z-X5t13s                
  └─raid-raid--lv
     xfs    Raid 5
                  a40e2225-d1f3-4eed-a7c7-e6e9b8a89283                  
sdd  linux_ EscenarioRaid:5
│                 8cf8c1b5-aa70-9441-ea11-eacfb0de25f6                  
└─md5
     LVM2_m       rzgN4Q-zYNz-hDHf-woWf-mK3j-Q72Z-X5t13s                
  └─raid-raid--lv
     xfs    Raid 5
                  a40e2225-d1f3-4eed-a7c7-e6e9b8a89283   
```

*Tarea 5: Monta el volumen en el directorio /mnt/raid5 y crea un fichero. ¿Qué tendríamos que hacer para que este punto de montaje sea permanente?*
Para montar el volumen realizamos el siguiente comando
```
mkdir /mnt/raid5

mount /dev/mapper/raid-raid--lv /mnt/raid5


lsblk -f
NAME              FSTYPE            LABEL           UUID                                   FSAVAIL FSUSE% MOUNTPOINT
sda                                                                                                       
├─sda1            ext4                              b9ffc3d1-86b2-4a2c-a8be-f2b2f4aa4cb5     16.2G     7% /
├─sda2                                                                                                    
└─sda5            swap                              f8f6d279-1b63-4310-a668-cb468c9091d8                  [SWAP]
sdb               linux_raid_member EscenarioRaid:5 8cf8c1b5-aa70-9441-ea11-eacfb0de25f6                  
└─md5             LVM2_member                       rzgN4Q-zYNz-hDHf-woWf-mK3j-Q72Z-X5t13s                
  └─raid-raid--lv xfs               Raid 5          a40e2225-d1f3-4eed-a7c7-e6e9b8a89283    470.6M     5% /mnt/raid5
sdc               linux_raid_member EscenarioRaid:5 8cf8c1b5-aa70-9441-ea11-eacfb0de25f6                  
└─md5             LVM2_member                       rzgN4Q-zYNz-hDHf-woWf-mK3j-Q72Z-X5t13s                
  └─raid-raid--lv xfs               Raid 5          a40e2225-d1f3-4eed-a7c7-e6e9b8a89283    470.6M     5% /mnt/raid5
sdd               linux_raid_member EscenarioRaid:5 8cf8c1b5-aa70-9441-ea11-eacfb0de25f6                  
└─md5             LVM2_member                       rzgN4Q-zYNz-hDHf-woWf-mK3j-Q72Z-X5t13s                
  └─raid-raid--lv xfs               Raid 5          a40e2225-d1f3-4eed-a7c7-e6e9b8a89283    470.6M     5% /mnt/raid5
```

Si queremos hacerlo permanente editaremos el fichero /etc/fstab y pondremos la siguiente linea
```
/dev/mapper/raid-raid--lv      /mnt/raid5      xfs    defaults        0       2
```

Y creamos el fichero
```
root@EscenarioRaid:/mnt/raid5# echo "Hola" > fichero.txt
```
*Tarea 6: Marca un disco como estropeado. Muestra el estado del raid para comprobar que un disco falla. ¿Podemos acceder al fichero?*
Para marcar un disco como estropeado realizamos el siguiente comando
```
mdadm -f /dev/md5 /dev/sdd
```

Mostramos que el disco esta fallando
```
/dev/md5:
           Version : 1.2
     Creation Time : Tue Oct  1 20:23:01 2019
        Raid Level : raid5
        Array Size : 2093056 (2044.00 MiB 2143.29 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 3
     Total Devices : 3
       Persistence : Superblock is persistent

       Update Time : Tue Oct  1 20:40:39 2019
             State : clean, degraded 
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 1
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : EscenarioRaid:5  (local to host EscenarioRaid)
              UUID : 8cf8c1b5:aa709441:ea11eacf:b0de25f6
            Events : 20

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       -       0        0        2      removed

       3       8       48        -      faulty   /dev/sdd
```

Intentamos acceder al fichero
```
root@EscenarioRaid:/mnt/raid5# cat fichero.txt 
Hola
```
Esto es debido a que sólo ha fallado un disco y las propiedades del raid 5 es que si falla uno de los discos se puede recuperar la información ya que se guarda la paridad en los otros dos

*Tarea 7: Una vez marcado como estropeado, lo tenemos que retirar del raid.*
Para retirarlo del raid ejecutamos el siguiente comando
```
mdadm --remove /dev/md5 /dev/sdd
```
Mostramos que esta quitado del raid
```
/dev/md5:
           Version : 1.2
     Creation Time : Tue Oct  1 20:23:01 2019
        Raid Level : raid5
        Array Size : 2093056 (2044.00 MiB 2143.29 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 3
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Tue Oct  1 20:44:13 2019
             State : clean, degraded 
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : EscenarioRaid:5  (local to host EscenarioRaid)
              UUID : 8cf8c1b5:aa709441:ea11eacf:b0de25f6
            Events : 23

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       -       0        0        2      removed

```
*Tarea 8: Imaginemos que lo cambiamos por un nuevo disco nuevo (el dispositivo de bloque se llama igual), añádelo al array y comprueba como se sincroniza con el anterior.*
Para añadir el disco nuevo al raid simplemente ejecutamos el comando
```
mdadm --add /dev/md5 /dev/sdd
```

Y observamos que se ha sincronizado con los demás
```
/dev/md5:
           Version : 1.2
     Creation Time : Tue Oct  1 20:23:01 2019
        Raid Level : raid5
        Array Size : 2093056 (2044.00 MiB 2143.29 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 3
     Total Devices : 3
       Persistence : Superblock is persistent

       Update Time : Tue Oct  1 20:47:01 2019
             State : clean 
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : EscenarioRaid:5  (local to host EscenarioRaid)
              UUID : 8cf8c1b5:aa709441:ea11eacf:b0de25f6
            Events : 42

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       3       8       48        2      active sync   /dev/sdd
```

*Tarea 9: Añade otro disco como reserva. Vuelve a simular el fallo de un disco y comprueba como automática se realiza la sincronización con el disco de reserva.*
Para añadir otro disco como reserva usaremos el comando
```
mdadm --add /dev/md5 /dev/sde
```

Y podemos observar que esta en el estado spare
```
/dev/md5:
           Version : 1.2
     Creation Time : Tue Oct  1 21:02:13 2019
        Raid Level : raid5
        Array Size : 2093056 (2044.00 MiB 2143.29 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 3
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Tue Oct  1 21:04:35 2019
             State : clean 
    Active Devices : 3
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 1

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : EscenarioRaid:5  (local to host EscenarioRaid)
              UUID : 49295e89:8424ad45:0d715367:5587e7d9
            Events : 21

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       3       8       48        2      active sync   /dev/sdd

       4       8       64        -      spare   /dev/sde

```

Ahora vamos a simular el fallo en el disco sdd con el comando
```
mdadm -f /dev/md5 /dev/sdd
```

Y podemos observar que se sincroniza con los demás
```
/dev/md5:
           Version : 1.2
     Creation Time : Tue Oct  1 21:02:13 2019
        Raid Level : raid5
        Array Size : 2093056 (2044.00 MiB 2143.29 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 3
     Total Devices : 4
       Persistence : Superblock is persistent
xfs_growfs /home
       Update Time : Tue Oct  1 21:05:28 2019
             State : clean 
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 1
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : EscenarioRaid:5  (local to host EscenarioRaid)
              UUID : 49295e89:8424ad45:0d715367:5587e7d9
            Events : 40

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       4       8       64        2      active sync   /dev/sde

       3       8       48        -      faulty   /dev/sdd

```

*Tarea 10: Redimensiona el volumen y el sistema de archivo de 500Mb al tamaño del raid.*
Para extender el tamaño del volumen debemos usar el siguiente comando
```
lvextend -L 1.99GiB /dev/mapper/raid-raid--lv

Rounding size to boundary between physical extents: 1.99 GiB.
  Size of logical volume raid/raid-lv changed from 1.90 GiB (487 extents) to 1.99 GiB (510 extents).
  Logical volume raid/raid-lv successfully resized.
```

Para redimensionar el sistema de archivos usaremos el comando(debe estar montado al ser xfs)
```
xfs_growfs /mnt/raid5
```

```
root@EscenarioRaid:/mnt# lsblk -f
NAME FSTYPE LABEL UUID                                   FSAVAIL FSUSE% MOUNTPOINT
sda                                                                     
├─sda1
│    ext4         b9ffc3d1-86b2-4a2c-a8be-f2b2f4aa4cb5     16.3G     6% /
├─sda2
│                                                                       
└─sda5
     swap         f8f6d279-1b63-4310-a668-cb468c9091d8                  [SWAP]
sdb  linux_ EscenarioRaid:5
│                 49295e89-8424-ad45-0d71-53675587e7d9                  
└─md5
     LVM2_m       RDaJU8-howU-rGD0-auty-Y49f-t0lz-x8djFH                
  └─raid-raid--lv
     xfs    Raid 5
                  71abc232-2100-4812-85fd-c5888e815960        2G     1% /mnt/raid5
sdc  linux_ EscenarioRaid:5
│                 49295e89-8424-ad45-0d71-53675587e7d9                  
└─md5
     LVM2_m       RDaJU8-howU-rGD0-auty-Y49f-t0lz-x8djFH                
  └─raid-raid--lv
     xfs    Raid 5
                  71abc232-2100-4812-85fd-c5888e815960        2G     1% /mnt/raid5
sdd  linux_ EscenarioRaid:5
│                 49295e89-8424-ad45-0d71-53675587e7d9                  
└─md5
     LVM2_m       RDaJU8-howU-rGD0-auty-Y49f-t0lz-x8djFH                
  └─raid-raid--lv
     xfs    Raid 5
                  71abc232-2100-4812-85fd-c5888e815960        2G     1% /mnt/raid5
sde  linux_ EscenarioRaid:5
│                 49295e89-8424-ad45-0d71-53675587e7d9                  
└─md5
     LVM2_m       RDaJU8-howU-rGD0-auty-Y49f-t0lz-x8djFH                
  └─raid-raid--lv
     xfs    Raid 5
                  71abc232-2100-4812-85fd-c5888e815960        2G     1% /mnt/raid5

```

