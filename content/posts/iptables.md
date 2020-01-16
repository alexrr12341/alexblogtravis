+++
date = "2020-01-10"
title = "Cortafuegos perimetral con DMZ"
math = "true"

+++

La máquina router-fw tiene un servidor ssh escuchando por el puerto 22, pero al acceder desde el exterior habrá que conectar al puerto 2222.
```
iptables -A INPUT -s 172.22.0.0/16 -p tcp -m tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -d 172.22.0.0/16 -p tcp -m tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -s 172.23.0.0/16 -p tcp -m tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -d 172.23.0.0/16 -p tcp -m tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
```

Prueba de funcionamiento:
```
alexrr@pc-alex:~$ ssh debian@172.22.201.65
Warning: No xauth data; using fake authentication data for X11 forwarding.
X11 forwarding request failed on channel 0
Linux router-fw 4.19.0-6-cloud-amd64 #1 SMP Debian 4.19.67-2+deb10u1 (2019-09-20) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Tue Dec 17 09:36:59 2019 from 172.22.1.22
debian@router-fw:~$ 
```

Vamos ahora a realizar una unidad de systemd para que se guarden las iptables
```
[Unit]
Description=Packet Filtering Framework

[Service]
Type=oneshot
ExecStart=sh /home/debian/script-iptables.sh
ExecReload=sh /home/debian/script-iptables.sh
ExecStop=/usr/lib/systemd/scripts/iptables-flush
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target


```

script:
```
#!/bin/sh
iptables-restore < /home/debian/firewall.txt
```


Y activamos para que al reiniciar funcione
```
systemctl enable iprestore
systemctl start iprestore
```

```
root@router-fw:/home/debian# systemctl status iprestore
● iprestore.service - Packet Filtering Framework
   Loaded: loaded (/etc/systemd/system/iprestore.service; disabled; vendor preset: enabled)
   Active: active (exited) since Sat 2020-01-11 13:09:27 UTC; 3s ago
  Process: 697 ExecStart=/usr/bin/sh /home/debian/script-iptables.sh (code=exited, status=0/SUCCESS)
 Main PID: 697 (code=exited, status=0/SUCCESS)

Jan 11 13:09:27 router-fw systemd[1]: Starting Packet Filtering Framework...
Jan 11 13:09:27 router-fw systemd[1]: Started Packet Filtering Framework.

```

Activamos también el bit de forward
```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

*La máquina router-fw tiene un servidor ssh escuchando por el puerto 22, pero al acceder desde el exterior habrá que conectar al puerto 2222.*

Vamos a redirigir las peticiones del puerto 22 al puerto 2222
```
iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport 2222 -j REDIRECT --to-ports 22
```

Y vamos a bloquear el puerto 22 para que nadie pueda acceder por él
```
iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport 22 -j DNAT --to-destination 127.0.0.1:22
```


Prueba de funcionamiento:

```
alexrr@pc-alex:~/ic-travis-html5$ ssh debian@172.22.201.65
ssh: connect to host 172.22.201.65 port 22: Connection timed out

alexrr@pc-alex:~/ic-travis-html5$ ssh -p2222 debian@172.22.201.65
Warning: No xauth data; using fake authentication data for X11 forwarding.
X11 forwarding request failed on channel 0
Linux router-fw 4.19.0-6-cloud-amd64 #1 SMP Debian 4.19.67-2+deb10u1 (2019-09-20) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Thu Jan  9 08:45:13 2020 from 172.22.0.9
debian@router-fw:~$ 
```


*Desde la LAN y la DMZ se debe permitir la conexión ssh por el puerto 22 al la máquina router-fw.*

LAN:

```
iptables -A INPUT -s 192.168.100.0/24 -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -d 192.168.100.0/24 -p tcp --sport 22 -j ACCEPT
```
![](/images/LAN.png)

DMZ:

```
iptables -A INPUT -s 192.168.200.0/24 -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -d 192.168.200.0/24 -p tcp --sport 22 -j ACCEPT
```
![](/images/DMZ.png)


*La máquina router-fw debe tener permitido el tráfico para la interfaz loopback.*

Prueba antes de poner las reglas
```
root@router-fw:/home/debian# ping 127.0.0.1
PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
ping: sendmsg: Operation not permitted
ping: sendmsg: Operation not permitted
```

Ponemos la regla:
```
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
```

Prueba despues de poner la regla:
```
root@router-fw:/home/debian# ping 127.0.0.1
PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.059 ms
64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.078 ms
```

*A la máquina router-fw se le puede hacer ping desde la DMZ, pero desde la LAN se le debe rechazar la conexión (REJECT).*


Para que podamos realizar ping desde la DMZ al router, realizamos la siguiente regla
```
iptables -A INPUT -i eth2 -s 192.168.200.0/24 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -o eth2 -d 192.168.200.0/24 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

![](/images/pingDMZ.png)

Para que podamos rechazar la conexión realizamos la siguiente regla
```
iptables -A INPUT -i eth1 -s 192.168.100.0/24 -p icmp -m icmp --icmp-type echo-request -j REJECT --reject-with icmp-port-unreachable
iptables -A OUTPUT -o eth1 -d 192.168.100.0/24 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
iptables -A OUTPUT -o eth1 -d 192.168.100.0/24 -p icmp -m state --state RELATED -j ACCEPT
```

![](/images/pingLAN.png)

*La máquina router-fw puede hacer ping a la LAN, la DMZ y al exterior.*

LAN:
```
iptables -A OUTPUT -o eth1 -d 192.168.100.0/24 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i eth1 -s 192.168.100.0/24 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

Prueba:
```
root@router-fw:/home/debian# ping 192.168.100.10
PING 192.168.100.10 (192.168.100.10) 56(84) bytes of data.
64 bytes from 192.168.100.10: icmp_seq=1 ttl=64 time=1.75 ms
64 bytes from 192.168.100.10: icmp_seq=2 ttl=64 time=1.38 ms
```

DMZ:
```
iptables -A OUTPUT -o eth2 -d 192.168.200.0/24 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i eth2 -s 192.168.200.0/24 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

Prueba:
```
iptables -A OUTPUT -o eth2 -d 192.168.200.0/24 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i eth2 -s 192.168.200.0/24 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

Exterior:
```
iptables -A OUTPUT -o eth0 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i eth0 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

Prueba:
```
root@router-fw:/home/debian# ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=51 time=43.2 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=51 time=43.2 ms
```

*Desde la máquina DMZ se puede hacer ping y conexión ssh a la máquina LAN.*


Habilitaremos el ssh hacia la máquina LAN:

```
iptables -A FORWARD -i eth2 -o eth1 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth2 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
```

![](/images/sshDMZLAN.png)

Habilitaremos el ping hacia la máquina LAN:

```
iptables -A FORWARD -i eth2 -o eth1 -s 192.168.200.0/24 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -i eth1 -o eth2 -d 192.168.200.0/24 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

![](/images/pingDMZLAN.png)

*Desde la máquina LAN no se puede hacer ping, pero si se puede conectar por ssh a la máquina DMZ.*

Vamos a habilitar el ssh hacia DMZ
```
iptables -A FORWARD -i eth1 -o eth2 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
```

![](/images/sshLANDMZ.png)
![](/images/pingLANDMZ.png)


*Configura la máquina router-fw para que las máquinas LAN y DMZ puedan acceder al exterior.*
```
iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.200.0/24 -o eth0 -j MASQUERADE
```

*La máquina LAN se le permite hacer ping al exterior.*

```
iptables -A FORWARD -i eth1 -o eth0 -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

![](/images/pingLANExt.png)

*La máquina LAN puede navegar.*

Habilitamos http y https:
```
iptables -A FORWARD -i eth1 -o eth0 -p tcp -m multiport --dports 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp -m multiport --sports 80,443 -m state --state ESTABLISHED -j ACCEPT
```

Habilitamos el dns:
```
iptables -A FORWARD -i eth1 -o eth0 -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
```

![](/images/updateLAN.png)


*La máquina DMZ puede navegar. Instala un servidor web, un servidor ftp y un servidor de correos.*

Vamos a realizar lo anterior con DMZ esta vez:

Habilitamos http y https:
```
iptables -A FORWARD -i eth2 -o eth0 -p tcp -m multiport --dports 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -p tcp -m multiport --sports 80,443 -m state --state ESTABLISHED -j ACCEPT
```

Habilitamos el dns:
```
iptables -A FORWARD -i eth2 -o eth0 -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
```

Ahora instalaremos los servicios que se nos pide:
```
apt install apache2
apt install postfix
apt install proftpd
```

*Configura la máquina router-fw para que los servicios web y ftp sean accesibles desde el exterior.*

```
iptables -t nat -A PREROUTING -i eth0 -p tcp -m multiport --dports 80,443 -j DNAT --to 192.168.200.10
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 21 -j DNAT --to 192.168.200.10:21
iptables -t nat -A POSTROUTING -o eth2 -p tcp --dport 21 -d 192.168.200.10 -j SNAT --to 192.168.200.2
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 20 -j DNAT --to 192.168.200.10:21
iptables -t nat -A POSTROUTING -o eth2 -p tcp --dport 20 -d 192.168.200.10 -j SNAT --to 192.168.200.2
iptables -A FORWARD -i eth0 -o eth2 -p tcp -m multiport --dports 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -p tcp -m multiport --sports 80,443 -m state --state ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -p tcp --syn --dport 21 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -p tcp --syn --dport 20 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

Accesibilidad a apache:
![](/images/apacheDMZ.png)

Accesibilidad a ftp:
```
alexrr@pc-alex:~$ ftp 172.22.200.218
Connected to 172.22.200.218.
220 ProFTPD Server (Debian) [::ffff:192.168.200.10]
Name (172.22.200.218:alexrr): ftp
331 Anonymous login ok, send your complete email address as your password
Password:
230-Welcome, archive user ftp@192.168.200.2 !
230-
230-The local time is: Thu Jan 09 18:27:58 2020
230-
230-This is an experimental FTP server.  If you have any unusual problems,
230-please report them via e-mail to <root@dmz.novalocal>.
230-
230 Anonymous access granted, restrictions apply
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> 
```

*El servidor web y el servidor ftp deben ser accesible desde la LAN y desde el exterior.*


```
iptables -A FORWARD -i eth1 -o eth2 -p tcp -m multiport --dports 80,443 -d 192.168.200.10 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p tcp -m multiport --sports 80,443 -s 192.168.200.10 -m state --state ESTABLISHED -j ACCEPT

iptables -A FORWARD -i eth1 -o eth2 -p tcp --syn --dport 21 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i eth1 -o eth2 -p tcp --syn --dport 20 -m conntrack --ctstate NEW -j ACCEPT

iptables -A FORWARD -i eth1 -o eth2  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

* Prueba acceso servidor *FTP* desde la *LAN*
![](/images/ftpLANDMZ.png)


* Prueba acceso servidor *WEB* desde la *LAN*
![](/images/apacheLANDMZ.png)

h3. El servidor de correos sólo debe ser accesible desde la LAN.

Elegimos internet site y modificamos en /etc/postfix/main.cf la siguiente línea

```
mynetworks = 127.0.0.0/8 192.168.100.0/24
```

Y añadimos las reglas

```
iptables -A FORWARD -i eth1 -o eth2 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT
```

![](/images/postfixLANDMZ.png)

*En la máquina LAN instala un servidor mysql. A este servidor sólo se puede acceder desde la DMZ.*

Instalaremos un mariadb 

```
apt install mariadb-server
```
Y crearemos la base de datos

```
create database prueba;
create user dmz identified by "dmz";
grant all privileges on prueba.* to dmz;
flush privileges;
```

Fichero /etc/mysql/mariadb.conf.d/50-server.cnf:
```
bind-address            = 0.0.0.0
```

Reglas:

```
iptables -A FORWARD -i eth2 -o eth1 -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth2 -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT
```

![](/images/mariadbLANDMZ.png)


*MEJORA: Utiliza nuevas cadenas para clasificar el tráfico.*

```
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -t nat -F
iptables -Z
iptables -t nat -Z
```

Vamos ahora a realizar las mejoras poniendo las nuevas cadenas:

Router a dmz->
```
iptables -N router_dmz
iptables -A OUTPUT -o eth2 -d 192.168.200.0/24 -j router_dmz
```
Router a lan->
```
iptables -N router_lan
iptables -A OUTPUT -o eth1 -d 192.168.100.0/24 -j router_lan
```

Router al exterior->
```
iptables -N router_ext
iptables -A OUTPUT -o eth0 -j router_ext
```
Exterior al router->
```
iptables -N ext_router
iptables -A INPUT -i eth0 -j ext_router
```
Dmz a router->
```
iptables -N dmz_router
iptables -A INPUT -i eth2 -s 192.168.200.0/24 -j dmz_router
```
Dmz a exterior->
```
iptables -N dmz_ext
iptables -A FORWARD -i eth2 -o eth0 -s 192.168.200.0/24 -j dmz_ext
```
Dmz a lan->
```
iptables -N dmz_lan
iptables -A FORWARD -i eth2 -o eth1 -s 192.168.200.0/24 -j dmz_lan
```
Exterior a dmz->
```
iptables -N ext_dmz
iptables -A FORWARD -i eth0 -o eth2 -j ext_dmz
```
Lan a router->
```
iptables -N lan_router
iptables -A INPUT -i eth1 -s 192.168.100.0/24 -j lan_router
```
Lan a exterior->
```
iptables -N lan_ext
iptables -A FORWARD -i eth1 -o eth0 -s 192.168.100.0/24 -j lan_ext
```
Lan a dmz->
```
iptables -N lan_dmz
iptables -A FORWARD -i eth1 -o eth2 -s 192.168.100.0/24 -j lan_dmz
```
Exterior a lan->
```
iptables -N ext_lan
iptables -A FORWARD -i eth0 -o eth1 -j ext_lan
```


La máquina router-fw tiene un servidor ssh escuchando por el puerto 22, pero al acceder desde el exterior habrá que conectar al puerto 2222.
```
iptables -A INPUT -s 172.22.0.0/16 -p tcp -m tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -d 172.22.0.0/16 -p tcp -m tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -s 172.23.0.0/16 -p tcp -m tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -d 172.23.0.0/16 -p tcp -m tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
```

Bit de forward:
```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

Redirigir puerto 22 a 2222:
```
iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport 2222 -j REDIRECT --to-ports 22
```

Puerto 22 para inutilizarlo:
```
iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport 22 -j DNAT --to-destination 127.0.0.1:22
```

Ssh desde la LAN:
```
iptables -A lan_router -p tcp --dport 22 -j ACCEPT
iptables -A router_lan -p tcp --sport 22 -j ACCEPT
```

Ssh desde la dmz:
```
iptables -A dmz_router -p tcp --dport 22 -j ACCEPT
iptables -A router_dmz -p tcp --sport 22 -j ACCEPT
```


Permitir loopback:
```
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
```

Permitir ping desde la dmz:
```
iptables -A dmz_router -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A router_dmz -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

No Permitir ping desde la lan:
```
iptables -A lan_router -p icmp -m icmp --icmp-type echo-request -j REJECT --reject-with icmp-port-unreachable
```

Permitir ping a la LAN:
```
iptables -A router_lan -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
iptables -A router_lan -p icmp -m state --state RELATED -j ACCEPT
iptables -A router_lan -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A lan_router -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

Ping a Dmz:
```
iptables -A router_dmz -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A dmz_router -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

Ping al exterior:
```
iptables -A router_ext -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A ext_router -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

Ping y ssh desde la dmz a la lan
```
iptables -A dmz_lan -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A lan_dmz -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -A dmz_lan -p icmp -m icmp --icmp-type echo-request -j ACCEPT
iptables -A lan_dmz -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
```

Ssh desde la lan a dmz:
```
iptables -A lan_dmz -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A dmz_lan -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
```

Exterior a lan y dmz:
```
iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.200.0/24 -o eth0 -j MASQUERADE
```

ping desde la lan a exterior
```
iptables -A lan_ext -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ext_lan -p icmp -m state --state ESTABLISHED -j ACCEPT
```

Navegación desde la lan:
```
iptables -A lan_ext -p tcp -m multiport --dports 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ext_lan -p tcp -m multiport --sports 80,443 -m state --state ESTABLISHED -j ACCEPT
iptables -A lan_ext -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ext_lan -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
```

Navegacion desde la dmz:
```
iptables -A dmz_ext -p tcp -m multiport --dports 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ext_dmz -p tcp -m multiport --sports 80,443 -m state --state ESTABLISHED -j ACCEPT
iptables -A dmz_ext -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ext_dmz -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
```

Acceso a dmz para servidor web
```
iptables -A ext_dmz -p tcp -m multiport --dports 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A dmz_ext -p tcp -m multiport --sports 80,443 -m state --state ESTABLISHED -j ACCEPT
```

Acceso a ftp 
```
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 21 -j DNAT --to 192.168.200.10:21
iptables -t nat -A POSTROUTING -o eth2 -p tcp --dport 21 -d 192.168.200.10 -j SNAT --to 192.168.200.2
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 20 -j DNAT --to 192.168.200.10:21
iptables -t nat -A POSTROUTING -o eth2 -p tcp --dport 20 -d 192.168.200.10 -j SNAT --to 192.168.200.2
iptables -A ext_dmz -p tcp --syn --dport 21 -m conntrack --ctstate NEW -j ACCEPT
iptables -A ext_dmz -i eth0 -o eth2 -p tcp --syn --dport 20 -m conntrack --ctstate NEW -j ACCEPT
iptables -A ext_dmz -i eth0 -o eth2 -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A dmz_ext -i eth2 -o eth0 -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

Acceso al servidor web para dmz:
```
iptables -A lan_dmz -p tcp -m multiport --dports 80,443 -d 192.168.200.10 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A dmz_lan -p tcp -m multiport --sports 80,443 -s 192.168.200.10 -m state --state ESTABLISHED -j ACCEPT
```

Acceso al servidor ftp
```
iptables -A lan_dmz -p tcp --syn --dport 21 -m conntrack --ctstate NEW -j ACCEPT
iptables -A lan_dmz -p tcp --syn --dport 20 -m conntrack --ctstate NEW -j ACCEPT
iptables -A lan_dmz -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A dmz_lan -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

Acecso al servidor postfix:
```
iptables -A lan_dmz -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A dmz_lan -p tcp --sport 25 -m state --state ESTABLISHED -j ACCEPT
```

Acceso al servidor mysql:
```
iptables -A dmz_lan -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A lan_dmz -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT
```


*MEJORA: Consruye el cortafuego utilizando nftables.*

Utilizando la herramienta iptables-translate vamos a poder traducir línea a línea las iptables de nuestro cortafuegos y transformarlas, para ello podemos utilizar un script que automatice la transformación, el resultado será:
```
nft add chain inet filter router_dmz
nft add chain inet filter router_lan
nft add chain inet filter router_ext
nft add chain inet filter ext_router
nft add chain inet filter dmz_router
nft add chain inet filter dmz_ext
nft add chain inet filter dmz_lan
nft add chain inet filter ext_dmz
nft add chain inet filter lan_router
nft add chain inet filter lan_ext
nft add chain inet filter lan_dmz
nft add chain inet filter ext_lan
nft add rule inet filter input iifname "eth0" counter jump ext_router
nft add rule inet filter input iifname "eth2" inet saddr 192.168.200.0/24 counter jump dmz_router
nft add rule inet filter input iifname "eth1" inet saddr 192.168.100.0/24 counter jump lan_router
nft add rule inet filter input inet saddr 172.22.0.0/16 tcp dport 22 ct state new,established  counter accept
nft add rule inet filter input inet saddr 172.23.0.0/16 tcp dport 22 ct state new,established  counter accept
nft add rule inet filter input iifname "lo" counter accept
nft add rule inet filter forward iifname "eth2" oifname "eth0" inet saddr 192.168.200.0/24 counter jump dmz_ext
nft add rule inet filter forward iifname "eth2" oifname "eth1" inet saddr 192.168.200.0/24 counter jump dmz_lan
nft add rule inet filter forward iifname "eth0" oifname "eth2" counter jump ext_dmz
nft add rule inet filter forward iifname "eth1" oifname "eth0" inet saddr 192.168.100.0/24 counter jump lan_ext
nft add rule inet filter forward iifname "eth1" oifname "eth2" inet saddr 192.168.100.0/24 counter jump lan_dmz
nft add rule inet filter forward iifname "eth0" oifname "eth1" counter jump ext_lan
nft add rule inet filter output oifname "eth2" inet daddr 192.168.200.0/24 counter jump router_dmz
nft add rule inet filter output oifname "eth1" inet daddr 192.168.100.0/24 counter jump router_lan
nft add rule inet filter output oifname "eth0" counter jump router_ext
nft add rule inet filter output inet daddr 172.22.0.0/16 tcp sport 22 ct state established  counter accept
nft add rule inet filter output inet daddr 172.23.0.0/16 tcp sport 22 ct state established  counter accept
nft add rule inet filter output oifname "lo" counter accept
nft add rule inet filter router_dmz tcp sport 22 counter accept
nft add rule inet filter router_dmz icmp type echo-reply counter accept
nft add rule inet filter router_dmz icmp type echo-request counter accept
nft add rule inet filter router_lan tcp sport 22 counter accept
nft add rule inet filter router_lan icmp type echo-reply counter accept
nft add rule inet filter router_lan inet protocol icmp ct state related  counter accept
nft add rule inet filter router_lan icmp type echo-request counter accept
nft add rule inet filter router_ext icmp type echo-request counter accept
nft add rule inet filter ext_router icmp type echo-reply counter accept
nft add rule inet filter dmz_router tcp dport 22 counter accept
nft add rule inet filter dmz_router icmp type echo-request counter accept
nft add rule inet filter dmz_router icmp type echo-reply counter accept
nft add rule inet filter dmz_ext inet protocol tcp tcp dport { 80,443} ct state new,established  counter accept
nft add rule inet filter dmz_ext udp dport 53 ct state new,established  counter accept
nft add rule inet filter dmz_ext inet protocol tcp tcp sport { 80,443} ct state established  counter accept
nft add rule inet filter dmz_ext iifname "eth2" oifname "eth0" inet protocol tcp ct state related,established counter accept
nft add rule inet filter dmz_lan tcp dport 22 ct state new,established  counter accept
nft add rule inet filter dmz_lan icmp type echo-request counter accept
nft add rule inet filter dmz_lan tcp sport 22 ct state established  counter accept
nft add rule inet filter dmz_lan inet protocol tcp inet saddr 192.168.200.10 tcp sport { 80,443} ct state established  counter accept
nft add rule inet filter dmz_lan inet protocol tcp ct state related,established counter accept
nft add rule inet filter dmz_lan tcp sport 25 ct state established  counter accept
nft add rule inet filter dmz_lan tcp dport 3306 ct state new,established  counter accept
nft add rule inet filter ext_dmz inet protocol tcp tcp sport { 80,443} ct state established  counter accept
nft add rule inet filter ext_dmz udp sport 53 ct state established  counter accept
nft add rule inet filter ext_dmz inet protocol tcp tcp dport { 80,443} ct state new,established  counter accept
nft add rule inet filter ext_dmz tcp dport 21 tcp flags & (fin|syn|rst|ack) == syn ct state new counter accept
nft add rule inet filter ext_dmz iifname "eth0" oifname "eth2" tcp dport 20 tcp flags & (fin|syn|rst|ack) == syn ct state new counter accept
nft add rule inet filter ext_dmz iifname "eth0" oifname "eth2" inet protocol tcp ct state related,established counter accept
nft add rule inet filter lan_router tcp dport 22 counter accept
nft add rule inet filter lan_router icmp type echo-request counter reject
nft add rule inet filter lan_router icmp type echo-reply counter accept
nft add rule inet filter lan_ext inet protocol icmp ct state new,established  counter accept
nft add rule inet filter lan_ext inet protocol tcp tcp dport { 80,443} ct state new,established  counter accept
nft add rule inet filter lan_ext udp dport 53 ct state new,established  counter accept
nft add rule inet filter lan_dmz tcp sport 22 ct state established  counter accept
nft add rule inet filter lan_dmz icmp type echo-reply counter accept
nft add rule inet filter lan_dmz tcp dport 22 ct state new,established  counter accept
nft add rule inet filter lan_dmz inet protocol tcp inet daddr 192.168.200.10 tcp dport { 80,443} ct state new,established  counter accept
nft add rule inet filter lan_dmz tcp dport 21 tcp flags & (fin|syn|rst|ack) == syn ct state new counter accept
nft add rule inet filter lan_dmz tcp dport 20 tcp flags & (fin|syn|rst|ack) == syn ct state new counter accept
nft add rule inet filter lan_dmz inet protocol tcp ct state related,established counter accept
nft add rule inet filter lan_dmz tcp dport 25 ct state new,established  counter accept
nft add rule inet filter lan_dmz tcp sport 3306 ct state established  counter accept
nft add rule inet filter ext_lan inet protocol icmp ct state established  counter accept
nft add rule inet filter ext_lan inet protocol tcp tcp sport { 80,443} ct state established  counter accept
nft add rule inet filter ext_lan udp sport 53 ct state established  counter accept
nft add rule inet filter prerouting iifname "eth0" tcp dport 2222 counter redirect to :22
nft add rule inet filter prerouting iifname "eth0" tcp dport 22 counter dnat to 127.0.0.1:22
nft add rule inet filter prerouting iifname "eth0" tcp dport 21 counter dnat to 192.168.200.10:21
nft add rule inet filter prerouting iifname "eth0" tcp dport 20 counter dnat to 192.168.200.10:21
nft add rule inet filter postrouting oifname "eth0" inet saddr 192.168.100.0/24 counter masquerade 
nft add rule inet filter postrouting oifname "eth0" inet saddr 192.168.200.0/24 counter masquerade 
nft add rule inet filter postrouting oifname "eth2" inet daddr 192.168.200.10 tcp dport 21 counter snat to 192.168.200.2
nft add rule inet filter postrouting oifname "eth2" inet daddr 192.168.200.10 tcp dport 20 counter snat to 192.168.200.2
```
