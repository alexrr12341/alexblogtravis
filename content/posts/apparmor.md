+++
date = "2020-02-17"
title = "Configuración de perfiles AppArmor(mariadb,sensu,bacula)"
math = "true"

+++

## AppArmor

Vamos a habilitar apparmor en tortilla de forma estricta y segura, para ello instalamos los siguientes paquetes
```
apt install apparmor-utils apparmor-profiles
```

Ahora vamos a generar un perfil
```
aa-genprof mysqld
```


Y vamos a editar el fichero /etc/apparmor.d/usr.sbin/mysqld

*Para hacer este fichero debemos ir haciendo restart de mariadb, buscando los errores en journalctl -xe hasta que se active dicho programa.*
```
# Last Modified: Sat Feb 15 15:52:53 2020
#include <tunables/global>

/usr/sbin/mysqld {
  #include <abstractions/base>

  /lib/x86_64-linux-gnu/ld-*.so mr,
  /usr/sbin/mysqld mrwk,

#Acceso a fichero de configuracion
 /etc/mysql/** r,
#Permitimos los mensajes de error
 /usr/share/mysql/ r,
 /usr/share/mysql/** r,

#Permitimos escritura y lectura en las bases de datos
 /var/lib/mysql/ rwk,
 /var/lib/mysql/** rwk,
#Permitimos escribir archivos temporales
 /tmp/** rwk,
 /tmp/ r,
#Permitimos abrir mysql
 /run/mysqld/** w,

#Damos permisos de usuarios
 /etc/nsswitch.conf r,
 /etc/passwd r,

#Permitimos notificaciones de systemd
 /run/systemd/notify w,
 capability sys_resource,
 capability dac_override,
 capability setuid,
 capability setgid,
 /run/systemd/resolve/stub-resolv.conf r,

#Permitimos mensajes de error
 /var/log/mysql/** rwk,

#Permitimos el acceso a los sockets
 unix,
 /var/run/mysqld/mysqld.pid rw,
 /var/run/mysqld/mysqld.sock rw,
 /var/run/mysqld/mysqld.sock.lock rw,
 /run/mysqld/mysqld.pid rw,
 /run/mysqld/mysqld.sock rw,
 /run/mysqld/mysqld.sock.lock rw,

#Permitimos el acceso por red
 network inet stream,
 network inet6 stream,
 network inet dgram,
 network inet6 dgram,
#Permitimos acceso a los hosts de la maquina
 /etc/hosts r,
 /etc/host.conf r,

#Permitimos que coja informacion del sistema
 /proc/*/status r,
 /sys/devices/system/node/ r,
 /sys/devices/system/node/node0/meminfo r, 
}
```

Hacemos un start de mariadb
```
systemctl start mariadb

systemctl status mariadb
● mariadb.service - MariaDB 10.1.44 database server
   Loaded: loaded (/lib/systemd/system/mariadb.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2020-02-17 20:02:46 UTC; 2min 42s ago
     Docs: man:mysqld(8)
           https://mariadb.com/kb/en/library/systemd/
  Process: 25568 ExecStartPost=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
  Process: 25563 ExecStartPost=/etc/mysql/debian-start (code=exited, status=0/SUCCESS)
  Process: 25483 ExecStartPre=/bin/sh -c [ ! -e /usr/bin/galera_recovery ] && VAR= ||   VAR=`/usr/bin/galera_recovery`; [ $? -eq 0 ]   && systemctl set-environment _WSREP_START_POSITION=$VAR || exit 1 (code=exit
  Process: 25480 ExecStartPre=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
  Process: 25473 ExecStartPre=/usr/bin/install -m 755 -o mysql -g root -d /var/run/mysqld (code=exited, status=0/SUCCESS)
```

Observamos que nos podemos conectar remotamente desde croqueta:
```
root@croqueta:/home/debian# mysql -u wordpress -p wordpress -h 10.0.0.7
Enter password: 
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 4
Server version: 10.1.44-MariaDB-0ubuntu0.18.04.1 Ubuntu 18.04

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [wordpress]> 
```


Ahora vamos a hacer el perfil para bacula-fd, que es el cliente de bacula, para ello vamos a realizar:
```
aa-genprof bacula-fd
```

Ahora editamos el fichero /etc/apparmor.d/usr.sbin.bacula-fd y lo realizamos como hemos hecho anteriormente
```
# Last Modified: Mon Feb 17 20:18:06 2020
#include <tunables/global>

/usr/sbin/bacula-fd {
  #include <abstractions/base>

  /lib/x86_64-linux-gnu/ld-*.so mr,
  /usr/sbin/bacula-fd mr,

 #Permisos para fichero de configuracion
 /etc/bacula/bacula-fd.conf r,

 #Permisos para archivos temporales
 /tmp/ r,
 /tmp/** rwk,

 #Permisos especiales
 /usr/lib/bacula/bpipe-fd.so mr,

 #Permisos de red
 network inet stream,
 network inet6 stream,

 #Permisos de hosts
 /etc/hosts.allow r,
 /etc/hosts.deny r,

 #Permisos para realizar las copias
 /home/ r,
 /var/ r,
 /etc/ r,
 /home/** rwk,
 /var/** rwk,
 /etc/** rwk,

 #Permisos de creacion
 /var/lib/bacula/** rwk,
 /var/lib/bacula/ r,

}
```


Hacemos un start y vemos que está funcionando
```
systemctl status bacula-fd

● bacula-fd.service - Bacula File Daemon service
   Loaded: loaded (/lib/systemd/system/bacula-fd.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2020-02-17 20:27:12 UTC; 49s ago
     Docs: man:bacula-fd(8)
  Process: 29309 ExecStartPre=/usr/sbin/bacula-fd -t -c $CONFIG (code=exited, status=0/SUCCESS)
 Main PID: 29320 (bacula-fd)
    Tasks: 2 (limit: 546)
   CGroup: /system.slice/bacula-fd.service
           └─29320 /usr/sbin/bacula-fd -fP -c /etc/bacula/bacula-fd.conf

Feb 17 20:27:12 tortilla systemd[1]: Starting Bacula File Daemon service...
Feb 17 20:27:12 tortilla systemd[1]: Started Bacula File Daemon service.

```


Vamos a comprobar que funciona haciendo una copia incremental de tortilla como prueba
```
root@serranito:/home/ubuntu# bconsole
Connecting to Director 10.0.0.10:9101
1000 OK: 103 choco-dir Version: 9.0.6 (20 November 2017)
Enter a period to cancel a command.
*run
Automatically selected Catalog: MyCatalog
Using Catalog "MyCatalog"
A job name must be specified.
The defined Job resources are:
     1: choco
     2: croqueta
     3: salmorejo
     4: tortilla
     5: RestoreChoco
     6: RestoreCroqueta
     7: RestoreSalmorejo
     8: RestoreTortilla
     9: choco-anual
    10: croqueta-anual
    11: salmorejo-anual
    12: tortilla-anual
    13: RestoreChoco-anual
    14: RestoreCroqueta-anual
    15: RestoreSalmorejo-anual
    16: RestoreTortilla-anual
Select Job resource (1-16): 4
Run Backup job
JobName:  tortilla
Level:    Incremental
Client:   tortilla-fd
FileSet:  Full Set
Pool:     File (From Job resource)
Storage:  File (From Job resource)
When:     2020-02-17 20:39:11
Priority: 10
OK to run? (yes/mod/no): yes
Job queued. JobId=141
You have messages.

```

Como podemos observar, la copia se realiza correctamente
```
|   141 | tortilla         | 2020-02-17 20:39:18 | B    | I     |      179 |  27,241,199 | T         |

```


Ahora vamos a realizar el perfil para el cliente de sensu, para ello vamos a crear el perfil
```
aa-genprof /opt/sensu/bin/sensu-client
```

Y vamos a /etc/apparmor.d/opt.sensu.embedded.bin.sensu-client y editamos el fichero como hemos hecho anteriormente
```
# Last Modified: Mon Feb 17 22:07:21 2020
#include <tunables/global>

/opt/sensu/embedded/bin/sensu-client {
  include <abstractions/base>

  /lib/x86_64-linux-gnu/ld-*.so mr,
  /opt/sensu/embedded/bin/ruby ix,
  /opt/sensu/embedded/bin/sensu-client r,
  /opt/sensu/embedded/lib/lib*so* mr,
  #Permisos a las librerias de sensu
  /opt/sensu/embedded/lib/** mr,
  #Permisos a los certificados de sensu
  /opt/sensu/embedded/ssl/** r,
  #Permisos de logs
  /var/log/sensu/sensu-client.log rwk,
  #Permitimos conexiones de internet
  network netlink raw,
  network inet stream,
  network inet6 stream,
  network inet dgram,
  network inet6 dgram,
  #Acceso a ficheros de configuracion
  /etc/sensu/ r,
  /etc/sensu/** r,
  #Escritura de archivos temporales
  /tmp/ r,
  /tmp/** rwk,
  #Permitimos correr sensu
  /run/sensu/ r,
  /run/sensu/** rwk,
  #Permitimos la ejecucion de los eventos
  /bin/** rix,
  #Permitimos la ejecucion de las metricas
  /opt/sensu/embedded/bin/metrics-mysql-graphite.rb rix,
  /opt/sensu/embedded/bin/metrics-vmstat.rb rix,
  #Damos acceso a los stats de la maquina
  /usr/bin/vmstat rix,
  /usr/bin/tail rix,
  /proc/vmstat r,
  #Damos acceso a los hosts
  /etc/nsswitch.conf r,
  /etc/host.conf r,
  /etc/hosts r,
  #Damos acceso a systemd
  /run/systemd/resolve/stub-resolv.conf r,
  #Permitimos acceso del kernel
  /proc/sys/kernel/osrelease r,
  #Damos permisos a la monitorizacion
  /opt/sensu/embedded/bin/check-disk-usage.rb rix,
  /opt/sensu/embedded/bin/check-cpu.rb rix,
  #Damos permiso para que vea las particiones del sistema
  /proc/*/mounts r,       
}
```

Podemos observar que el servidor de sensu recoge las metricas y la monitorizacion correctamente.
![](/images/tortillaapparmor.png)
