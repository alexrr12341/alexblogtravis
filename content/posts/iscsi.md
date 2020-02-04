+++
date = "2020-02-02"
title = "iSCSI"
math = "true"

+++

Primero de todo, para trabajar con iSCSI debemos hacer un escenario vagrant, que contendrá un cliente Linux y un servidor que proporcionará los targets.


El escenario vagrant será el siguiente:
```ruby
Vagrant.configure("2") do |config|
  config.vm.define :iscsi do |iscsi|
    disco = '.vagrant/discoiscsi1.vdi'
    disco2 = '.vagrant/discoiscsi2.vdi'
    disco3 = '.vagrant/discoiscsi3.vdi'
    disco4 = '.vagrant/discoiscsi4.vdi'
    iscsi.vm.box = "debian/buster64"
    iscsi.vm.hostname = "EscenarioRaid"
    iscsi.vm.network :public_network,:bridge=> "wlp0s20f3"
    iscsi.vm.provider :virtualbox do |v|
	if not File.exist?(disco)
                 v.customize ["createhd", "--filename", disco, "--size", 1024]
	end
                 v.customize ["storageattach", :id, "--storagectl", "SATA Controller",
                              "--port", 1, "--device", 0, "--type", "hdd",
                              "--medium", disco]
     end
     iscsi.vm.provider :virtualbox do |v|
             if not File.exist?(disco2)
                 v.customize ["createhd", "--filename", disco2, "--size", 1024]
	     end
                 v.customize ["storageattach", :id, "--storagectl", "SATA Controller",
                              "--port", 2, "--device", 0, "--type", "hdd",
                              "--medium", disco2]
     end
     iscsi.vm.provider :virtualbox do |v|
             if not File.exist?(disco3)
                 v.customize ["createhd", "--filename", disco3, "--size", 1024]
             end
                 v.customize ["storageattach", :id, "--storagectl", "SATA Controller",
                              "--port", 3, "--device", 0, "--type", "hdd",
                              "--medium", disco3]
     end
  end
  config.vm.define :cliente do |cliente|
    cliente.vm.box = "debian/buster64"
    cliente.vm.hostname = "cliente"
    cliente.vm.synced_folder '.', '/vagrant'
    cliente.vm.network :public_network, :bridge => 'wlp0s20f3'
  end
end
```

Después de entrar en la maquina iscsi, debemos instalar los paquetes necesarios para el funcionamiento de iscsi
```
apt install tgt lvm2
```

Ahora para que podamos trabajar, debemos crear un volumen del disco sdb por ejemplo.


Primero de todo creamos el volúmen físico.
```
pvcreate /dev/sdb
```

Creamos ahora el grupo de volúmenes, que en este caso contendrá el volúmen creado anteriormente
```
vgcreate iscsi /dev/sdb
```

Y creamos ahora el volumen lógico de dicho grupo de volúmenes.
```
lvcreate -L 950M -n logiscsi iscsi
```

Ahora queremos hacer que el target se detecte, por lo que vamos a /etc/tgt/targets.conf y ponemos:
```
<target iqn.2020-02.com:tgiscsi>
        backing-store /dev/iscsi/logiscsi
</target>
```

Reiniciamos el servicio y miramos si está hecho el target

```
systemctl restart tgt


root@EscenarioRaid:/home/vagrant# tgtadm --mode target --op show
Target 1: iqn.2020-02.com:tgiscsi
    System information:
        Driver: iscsi
        State: ready
    I_T nexus information:
    LUN information:
        LUN: 0
            Type: controller
            SCSI ID: IET     00010000
            SCSI SN: beaf10
            Size: 0 MB, Block size: 1
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: null
            Backing store path: None
            Backing store flags: 
        LUN: 1
            Type: disk
            SCSI ID: IET     00010001
            SCSI SN: beaf11
            Size: 998 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/iscsi/logiscsi
            Backing store flags: 
    Account information:
    ACL information:
        ALL
```


Ahora vamos a ir al cliente que hemos creado anteriormente y instalamos el cliente de iscsi

```
apt install open-iscsi
```

Para que el propio programa compruebe los dispositivos activos y que puedan acceder, debemos entrar a /etc/iscsi/iscsid.conf y realizar la siguiente configuración
```
iscsid.startup = automatic
```

Reiniciamos el servicio y buscamos los servicios disponibles dentro de la red

```
systemctl restart open-iscsi

root@cliente:/home/vagrant# iscsiadm -m discovery -t sendtargets -p 192.168.1.77
192.168.1.77:3260,1 iqn.2020-02.com:tgiscsi

```

Ahora debemos hacer un login con dicho target que nos ha mostrado por pantalla
```
iscsiadm -m node --targetname "iqn.2020-02.com:tgiscsi" -p "192.168.1.77:3260" --login

Logging in to [iface: default, target: iqn.2020-02.com:tgiscsi, portal: 192.168.1.77,3260] (multiple)
Login to [iface: default, target: iqn.2020-02.com:tgiscsi, portal: 192.168.1.77,3260] successful.
```

Al hacer login, podemos observar que el cliente tiene el disco del target
```
root@cliente:/home/vagrant# lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                     
├─sda1 ext4         b9ffc3d1-86b2-4a2c-a8be-f2b2f4aa4cb5   16.4G     5% /
├─sda2                                                                  
└─sda5 swap         f8f6d279-1b63-4310-a668-cb468c9091d8                [SWAP]
sdb      
```

Podemos ahora hacer un formateo del disco para que podamos escribir en él

```
mkfs.ext4 /dev/sdb

mkdir /mnt/iscsi

mount /dev/sdb /mnt/iscsi

```

Y comprobamos si podemos escribir en dicho volúmen

```
root@cliente:/mnt/iscsi# echo "Hola" > iscsi.txt

```

Si queremos ver si dicho fichero se ha creado bien, vamos a montar el login de iscsi en el servidor

```
root@EscenarioRaid:/mnt# mount /dev/iscsi/logiscsi iscsi/

root@EscenarioRaid:/mnt/iscsi# cat iscsi.txt 
Hola

```

Podemos comprobar que dicho fichero ha sido creado correctamente por el cliente de iscsi.


## Automontaje

Para hacer una unidad de systemd en el cliente de iscsi, primero debemos hacer que el login del cliente iscsi sea automático.

```
iscsiadm -m node --targetname "iqn.2020-02.com:tgiscsi" -p "192.168.1.77:3260" -o update -n node.startup -v automatic
```

Y ahora vamos a crear el automontaje en /etc/systemd/system/mnt-iscsi.mount
```
[Unit]
Description=ISCSI
[Mount]
What=/dev/sdb
Where=/mnt/iscsi
Type=ext4
Options=_netdev
[Install]
WantedBy=multi-user.target
```

Recargamos el los daemons y hacemos un enable del montaje
```
systemctl daemon-reload
systemctl enable mnt-iscsi.mount
```

Reiniciamos y observamos si se ha automontado

```
root@cliente:/etc/systemd/system# reboot
root@cliente:/etc/systemd/system# Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
vagrant@cliente:~$ sudo su
root@cliente:/etc/systemd/system# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0 19.8G  0 disk 
├─sda1   8:1    0 18.8G  0 part /
├─sda2   8:2    0    1K  0 part 
└─sda5   8:5    0 1021M  0 part [SWAP]
sdb      8:16   0  952M  0 disk /mnt/iscsi
root@cliente:/etc/systemd/system# cd
root@cliente:~# cd /mnt/iscsi/
root@cliente:/mnt/iscsi# ls
iscsi.txt  lost+found
```


## Windows

Para windows en este caso vamos a utilizar 2 Luns, que serán los dos discos restantes que hemos creado, sdc y sdd.

Creamos los dos volúmenes lógicos.

```
root@EscenarioRaid:~# pvcreate /dev/sdc 
  Physical volume "/dev/sdc" successfully created.
root@EscenarioRaid:~# vgcreate windows1 /dev/sdc 
  Volume group "windows1" successfully created
root@EscenarioRaid:~# lvcreate -L 950M -n logwindows1 windows1
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "logwindows1" created.


root@EscenarioRaid:~# pvcreate /dev/sdd 
  Physical volume "/dev/sdd" successfully created.
root@EscenarioRaid:~# vgcreate windows2 /dev/sdd
  Volume group "windows2" successfully created
root@EscenarioRaid:~# lvcreate -L 950M -n logwindows2 windows2
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "logwindows2" created.
```


Ahora en /etc/tgt/targets.conf creamos los dos LUN, junto a la autentificación CHAP, que en windows tiene que tener un usuario y una contraseña entre 12 y 15 caracteres.

```
<target iqn.2020-02.com:tgwindows>
        backing-store /dev/windows1/logwindows1
        backing-store /dev/windows2/logwindows2
        incominguser alexrr 123123123123123
</target>

```

Reiniciamos el servicio y comprobamos que se haya creado
```
systemctl restart tgt


root@EscenarioRaid:~# tgtadm --mode target --op show
Target 2: iqn.2020-02.com:tgwindows
    System information:
        Driver: iscsi
        State: ready
    I_T nexus information:
    LUN information:
        LUN: 0
            Type: controller
            SCSI ID: IET     00020000
            SCSI SN: beaf20
            Size: 0 MB, Block size: 1
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: null
            Backing store path: None
            Backing store flags: 
        LUN: 1
            Type: disk
            SCSI ID: IET     00020001
            SCSI SN: beaf21
            Size: 998 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/windows1/logwindows1
            Backing store flags: 
        LUN: 2
            Type: disk
            SCSI ID: IET     00020002
            SCSI SN: beaf22
            Size: 998 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/windows2/logwindows2
            Backing store flags: 
    Account information:
        alexrr
    ACL information:
        ALL

```

Ahora nos dirigiremos al cliente de windows 10 y conectaremos el iscsi en él.


Vamos a Panel de control->Herramientas administrativas.
![](/images/iscsi.png)

Y vamos a iniciador iSCSI
![](/images/iscsi2.png)

Vamos al apartado Detección y le damos a detectar portal.
![](/images/iscsi3.png)

Ponemos nuestra ip del servidor y nos saldrá los targets en la pestaña Destinos.
![](/images/iscsi4.png)

Le damos a Conectar y vamos a las opciones avanzadas, y habilitamos el inicio de sesión CHAP donde ponemos la contraseña y el usuario que hemos puesto.
![](/images/iscsi5.png)

Aceptamos y el iscsi estará ya conectado a nuestro cliente windows.
![](/images/iscsi6.png)

Ahora vamos al administrador de discos y vemos que los discos están ahí

![](/images/iscsi7.png)

Si queremos podemos formatearlos con NTFS para poder escribir en ellos.

![](/images/iscsi8.png)

Y vamos a escribir algo en ellos para comprobar su funcionamiento.

![](/images/iscsi9.png)

![](/images/iscsi10.png)
