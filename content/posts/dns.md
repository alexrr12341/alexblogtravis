+++
date = "2019-12-10"
title = "Servidores DNS"
math = "true"

+++

*Tarea 1 (2 punto)(Obligatorio): Modifica los clientes para que utilicen el nuevo servidor dns. Realiza una consulta a www.iesgn.org, y a www.josedomingo.org. Realiza una prueba de funcionamiento para comprobar que el servidor dnsmasq funciona como cache dns. Muestra el fichero hosts del cliente para demostrar que no estás utilizando resolución estática. Realiza una consulta directa al servidor dnsmasq. ¿Se puede realizar resolución inversa?. Documenta la tarea en redmine.*

Primero instalamos dnsmasq.
```
apt install dnsmasq
```

Ahora montamos el escenario con el servidor web para ello instalamos apache2 y creamos dos virtual hosts
```
apt install apache2
```

iesgn.conf:
```

<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName www.iesgn.org
        DocumentRoot /var/www/iesgn
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
```

departamentos.conf:
```

<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName departamentos.iesgn.org
        DocumentRoot /var/www/departamentos
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
```

```
a2ensite iesgn
a2ensite departamentos
systemctl restart apache2
```

Ahora en el servidor DNS editamos en /etc/dnsmasq.conf:
```
strict-order
interface=eth1
```

Ahora añadimos en el servidor DNS los DNS de las ips seleccionadas en el /etc/hosts
```
192.168.1.2     alejandro.iesgn.org       alejandro
192.168.1.201   www.iesgn.org
192.168.1.201   departamentos.iesgn.org
```

Ahora modificamos el /etc/resolv.conf del cliente para que pregunte siempre por el servidor DNS
```
domain gonzalonazareno.org
search gonzalonazareno.org
nameserver 192.168.1.2
```

/etc/host del cliente:
![](/images/host.png)

Consulta a www.iesgn.org
```
vagrant@cliente:~$ dig www.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> www.iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 59451
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.iesgn.org.			IN	A

;; ANSWER SECTION:
www.iesgn.org.		0	IN	A	192.168.1.201

;; Query time: 0 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Wed Nov 13 07:57:14 GMT 2019
;; MSG SIZE  rcvd: 58

```

Consulta a www.josedomingo.org
```
dig www.josedomingo.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> www.josedomingo.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 37907
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 5, ADDITIONAL: 6

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: d58369ba509079306edd325c5dcbb80dc391a2672d451c10 (good)
;; QUESTION SECTION:
;www.josedomingo.org.		IN	A

;; ANSWER SECTION:
www.josedomingo.org.	157	IN	CNAME	playerone.josedomingo.org.
playerone.josedomingo.org. 18	IN	A	137.74.161.90

;; AUTHORITY SECTION:
josedomingo.org.	49138	IN	NS	ns4.cdmondns-01.org.
josedomingo.org.	49138	IN	NS	ns2.cdmon.net.
josedomingo.org.	49138	IN	NS	ns5.cdmondns-01.com.
josedomingo.org.	49138	IN	NS	ns1.cdmon.net.
josedomingo.org.	49138	IN	NS	ns3.cdmon.net.

;; ADDITIONAL SECTION:
ns1.cdmon.net.		135538	IN	A	35.189.106.232
ns2.cdmon.net.		135538	IN	A	35.195.57.29
ns3.cdmon.net.		135538	IN	A	35.157.47.125
ns4.cdmondns-01.org.	49138	IN	A	52.58.66.183
ns5.cdmondns-01.com.	135538	IN	A	52.59.146.62

;; Query time: 7 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Wed Nov 13 08:00:13 GMT 2019
;; MSG SIZE  rcvd: 322

```

Para comprobar que funciona como servidor caché hacemos de vuelta la consulta a josedomingo
```
dig www.josedomingo.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> www.josedomingo.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 30945
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.josedomingo.org.		IN	A

;; ANSWER SECTION:
www.josedomingo.org.	93	IN	CNAME	playerone.josedomingo.org.
playerone.josedomingo.org. 866	IN	A	137.74.161.90

;; Query time: 0 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Wed Nov 13 08:01:17 GMT 2019
;; MSG SIZE  rcvd: 103

```


Ahora probamos la resolución inversa:

www.iesgn.org
```
dig -x 192.168.1.201

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> -x 192.168.1.201
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 1229
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;201.1.168.192.in-addr.arpa.	IN	PTR

;; ANSWER SECTION:
201.1.168.192.in-addr.arpa. 0	IN	PTR	www.iesgn.org.

;; Query time: 1 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Wed Nov 13 08:08:35 GMT 2019
;; MSG SIZE  rcvd: 82
```

*Tarea 2 (2 puntos)(Obligatorio): Realiza la instalación y configuración del servidor bind9 con las características anteriomente señaladas. Entrega las zonas que has definido. Muestra al profesor su funcionamiento.*

Primero desistalamos el dnsmaq
```
apt purge dnsmasq
```
Y instalamos bind9
```
apt install bind9
```

Ahora vamos a /etc/bind/named.conf.local y configuramos las zonas
```
zone "iesgn.org" {

type master;

file "/var/cache/bind/db.iesgn.org";

};

zone "1.168.192.in-addr.arpa" {

type master;

file "/var/cache/bind/db.192.168.1";

};
```

```
root@servidor:/etc/bind# cp db.local /var/cache/bind/db.iesgn.org
root@servidor:/etc/bind# cp db.127 /var/cache/bind/db.192.168.1
```

db.iesgn.org
```
;
; BIND data file for local loopback interface
;
$TTL	604800
@	IN	SOA	alejandro.iesgn.org. root.iesgn.org. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	      alejandro.iesgn.org.
@    IN    MX  10 correo.iesgn.org.
$ORIGIN iesgn.org.
servidor	IN	A	192.168.1.2
apache		IN	A	192.168.1.201
correo		IN	A	192.168.1.200
ftp		IN	A	192.168.1.202
cliente		IN	A	192.168.1.205
www		IN	CNAME	apache
departamentos	IN	CNAME	apache
```

db.192.168.1

```
;
; BIND reverse data file for local loopback interface
;
$TTL	604800
@	IN	SOA	alejandro.iesgn.org. root.iesgn.org. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	        alejandro.iesgn.org.
@	IN    MX	10   correo.iesgn.org.
$ORIGIN	1.168.192.in-addr.arpa.
2	        IN	PTR	alejandro.iesgn.org.
201	IN	PTR	apache.iesgn.org.
205	IN	PTR	cliente.iesgn.org.
200	IN	PTR	correo.iesgn.org.
202	IN	PTR	ftp.iesgn.org.
```

IPv6:
Vamos a nombrar la zona DNS inversa de IPv6, para ello primero vamos a hacer que la zona inversa de ipv6 coja la zona directa de ipv4
```
apt-get install ipv6calc
ipv6calc --out revnibbles.arpa 2001:abcd::/64
```
Ahora vamos a /etc/bind/named.conf.local y ponemos la zona inversa
```
zone "0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa" {

type master;

file "/var/cache/bind/db.0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa";

};
```

Ahora vamos a /var/cache/bind y creamos el fichero db.0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa
```
$TTL 86400
@ IN SOA alejandro.iesgn.org. admin.email. (
 5 ; Serial
 604800 ; Refresh
 86400 ; Retry
 2419200 ; Expire
 86400 ) ; Negative Cache TTL
;
@ IN NS alejandro.iesgn.org.
@ IN MX 10 correo.iesgn.org.
$ORIGIN 0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa.
1 IN PTR alejandro.iesgn.org.
2 IN PTR apache.iesgn.org.
3 IN PTR cliente.iesgn.org.
4 IN PTR correo.iesgn.org.
5 IN PTR ftp.iesgn.org.
```


Zona directa:
En nuestro fichero db.iesgn.org editamos las siguientes líneas si queremos que resuelva la zona directa por IPv6
```
$ORIGIN iesgn.org.
....

alejandro	IN	AAAA	2001:abcd::1
apache		IN	AAAA	2001:abcd::2
cliente		IN	AAAA	2001:abcd::3
correo		IN	AAAA	2001:abcd::4
ftp		IN	AAAA	2001:abcd::5

```

*Tarea 3 (2 puntos)(Obligatorio): Realiza las consultas dig/nslookup desde los clientes preguntando por los siguientes:*

    Dirección de pandora.iesgn.org, www.iesgn.org, ftp.iesgn.org
```
dig alejandro.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> alejandro.iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 15980
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: f3e65651ac55d528eae080085dd2621076d1f00e2a68f98f (good)
;; QUESTION SECTION:
;alejandro.iesgn.org.		IN	A

;; ANSWER SECTION:
alejandro.iesgn.org.	604800	IN	A	192.168.1.2

;; AUTHORITY SECTION:
iesgn.org.		604800	IN	NS	alejandro.iesgn.org.

;; ADDITIONAL SECTION:
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1

;; Query time: 1 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Mon Nov 18 09:19:12 GMT 2019
;; MSG SIZE  rcvd: 134


dig www.iesgn.org.

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> www.iesgn.org.
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 56199
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 1, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 19a949ded740a48e90bf6cb45dd2622cf4d2040a00c04b5a (good)
;; QUESTION SECTION:
;www.iesgn.org.			IN	A

;; ANSWER SECTION:
www.iesgn.org.		604800	IN	CNAME	apache.iesgn.org.
apache.iesgn.org.	604800	IN	A	192.168.1.201

;; AUTHORITY SECTION:
iesgn.org.		604800	IN	NS	alejandro.iesgn.org.

;; ADDITIONAL SECTION:
alejandro.iesgn.org.	604800	IN	A	192.168.1.2
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1

;; Query time: 0 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Mon Nov 18 09:19:40 GMT 2019
;; MSG SIZE  rcvd: 175


dig ftp.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> ftp.iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 22228
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 41610980fbac03b319d63d035dd262419ee2768b7e6235ab (good)
;; QUESTION SECTION:
;ftp.iesgn.org.			IN	A

;; ANSWER SECTION:
ftp.iesgn.org.		604800	IN	A	192.168.1.202

;; AUTHORITY SECTION:
iesgn.org.		604800	IN	NS	alejandro.iesgn.org.

;; ADDITIONAL SECTION:
alejandro.iesgn.org.	604800	IN	A	192.168.1.2
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1

;; Query time: 1 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Mon Nov 18 09:20:01 GMT 2019
;; MSG SIZE  rcvd: 154

```

    El servidor DNS con autoridad sobre la zona del dominio iesgn.org
```
dig ns iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> ns iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 5549
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 7cb535ef28c890fb70542aa75dd28e1999ad7b3e45804c2d (good)
;; QUESTION SECTION:
;iesgn.org.			IN	NS

;; ANSWER SECTION:
iesgn.org.		604800	IN	NS	alejandro.iesgn.org.

;; ADDITIONAL SECTION:
alejandro.iesgn.org.	604800	IN	A	192.168.1.2
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1

;; Query time: 0 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Mon Nov 18 12:27:05 GMT 2019
;; MSG SIZE  rcvd: 134

```

    El servidor de correo configurado para iesgn.org
```
dig mx iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> mx iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 593
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 5

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: d57bf8c39a2e2ee48b4340025dd28e39275ad780256b17e9 (good)
;; QUESTION SECTION:
;iesgn.org.			IN	MX

;; ANSWER SECTION:
iesgn.org.		604800	IN	MX	10 correo.iesgn.org.

;; AUTHORITY SECTION:
iesgn.org.		604800	IN	NS	alejandro.iesgn.org.

;; ADDITIONAL SECTION:
correo.iesgn.org.	604800	IN	A	192.168.1.200
alejandro.iesgn.org.	604800	IN	A	192.168.1.2
correo.iesgn.org.	604800	IN	AAAA	2001:abcd::4
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1

;; Query time: 0 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Mon Nov 18 12:27:37 GMT 2019
;; MSG SIZE  rcvd: 201

```

    La dirección IP de www.josedomingo.org
```
dig -x 137.74.161.90

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> -x 137.74.161.90
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 40303
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: ecd4f7d67b558ee2e08659d35dd28e63de1e44264a8d6f34 (good)
;; QUESTION SECTION:
;90.161.74.137.in-addr.arpa.	IN	PTR

;; ANSWER SECTION:
90.161.74.137.in-addr.arpa. 86400 IN	PTR	playerone.josedomingo.org.

;; AUTHORITY SECTION:
161.74.137.in-addr.arpa. 172797	IN	NS	dns16.ovh.net.
161.74.137.in-addr.arpa. 172797	IN	NS	ns16.ovh.net.

;; Query time: 3511 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Mon Nov 18 12:28:19 GMT 2019
;; MSG SIZE  rcvd: 168

```

    Una resolución inversa
```
dig -x 192.168.1.201

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> -x 192.168.1.201
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 23310
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 49bf9603cb26c2fb8fadd56b5dd28e84e50f2ddec90b6ce5 (good)
;; QUESTION SECTION:
;201.1.168.192.in-addr.arpa.	IN	PTR

;; ANSWER SECTION:
201.1.168.192.in-addr.arpa. 604800 IN	PTR	apache.iesgn.org.

;; AUTHORITY SECTION:
1.168.192.in-addr.arpa.	604800	IN	NS	alejandro.iesgn.org.

;; ADDITIONAL SECTION:
alejandro.iesgn.org.	604800	IN	A	192.168.1.2
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1

;; Query time: 0 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Mon Nov 18 12:28:52 GMT 2019
;; MSG SIZE  rcvd: 181

```

    La dirección ipv6 de pandora.iesgn.org
```
dig AAAA alejandro.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> AAAA alejandro.iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 22286
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 32271fd86745104962311d015dd28e9642cfc706560e60ba (good)
;; QUESTION SECTION:
;alejandro.iesgn.org.		IN	AAAA

;; ANSWER SECTION:
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1

;; AUTHORITY SECTION:
iesgn.org.		604800	IN	NS	alejandro.iesgn.org.

;; ADDITIONAL SECTION:
alejandro.iesgn.org.	604800	IN	A	192.168.1.2

;; Query time: 0 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Mon Nov 18 12:29:10 GMT 2019
;; MSG SIZE  rcvd: 134

```


*Tarea 4 (3 puntos): Realiza la instalación del servidor DNS esclavo. Documenta los siguientes apartados:*

    Entrega la configuración de las zonas del maestro y del esclavo.

Primero instalamos el bind9 en el nuevo servidor dns esclavo
```
apt install bind9
```

Maestro:
Por seguridad no permitimos la transferencia del servidor dns por defecto en /etc/bind/named-conf.options
```
allow-transfer { none; };
```
```
zone "iesgn.org" {
	type master;
	file "/var/cache/bind/db.iesgn.org";
	allow-transfer { 192.168.1.230; };
	notify yes;
};

zone "1.168.192.in-addr.arpa" {
	type master;
	file "/var/cache/bind/db.192.168.1";
	allow-transfer { 192.168.1.230; };
        notify yes;
};

zone "0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa" {

type master;

file "/var/cache/bind/db.0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa";
allow-transfer { 192.168.1.230; };
        notify yes;
};


```
Y en todas las zonas del maestro poner:
```
@       IN      NS              afrodita.iesgn.org.
$ORIGIN
...

afrodita        IN      A       192.168.1.230 
```

Esclavo:
```
zone "iesgn.org" {
	type slave;
	file "/var/cache/bind/db.iesgn.org";
	masters { 192.168.1.2; };
};

zone "1.168.192.in-addr.arpa" {
	type slave;
	file "/var/cache/bind/db.192.168.1";
	masters { 192.168.1.2; };
};

zone "0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa" {
	type slave;
	file "/var/cache/bind/db.0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa";
	masters { 192.168.1.2; };
};

```

    Comprueba si las zonas definidas en el maestro tienen algún error con el comando adecuado.
```
root@servidor:/etc/bind# named-checkzone iesgn.org /var/cache/bind/db.iesgn.org 
zone iesgn.org/IN: loaded serial 2
OK

root@servidor:/etc/bind# named-checkzone 1.168.192.in-addr.arpa /var/cache/bind/db.192.168.1 
zone 1.168.192.in-addr.arpa/IN: loaded serial 1
OK

root@servidor:/etc/bind# named-checkzone 0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa /var/cache/bind/db.0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa 
zone 0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN: loaded serial 5
OK
```
    Comprueba si la configuración de named.conf tiene algún error con el comando adecuado.
```
root@servidor:/etc/bind# named-checkconf
root@servidor:/etc/bind# 
```
    Reinicia los servidores y comprueba en los logs si hay algún error. No olvides incrementar el número de serie en el registro SOA si has modificado la zona en el maestro.
```
root@servidor:/etc/bind# rndc reload
server reload successful

cat /var/log/syslog
Nov 18 18:23:47 servidor named[3703]: received control channel command 'reload iesgn.org' 
Nov 18 18:23:47 servidor named[3703]: zone iesgn.org/IN: loaded serial 2 
Nov 18 18:23:47 servidor named[3703]: zone iesgn.org/IN: sending notifies (serial 2
```
    Muestra la salida del log donde se demuestra que se ha realizado la transferencia de zona.
```

cat /var/log/syslog
Nov 18 18:23:47 servidor3 named[962]: transfer of '1.168.192.in-addr.arpa/IN' from 192.168.1.2#53: connected using 192.168.1.230#51177
Nov 18 18:23:47 servidor3 named[962]: zone 1.168.192.in-addr.arpa/IN: transferred serial 3
Nov 18 18:23:47 servidor3 named[962]: transfer of '1.168.192.in-addr.arpa/IN' from 192.168.1.2#53: Transfer status: success
Nov 18 18:23:47 servidor3 named[962]: transfer of '1.168.192.in-addr.arpa/IN' from 192.168.1.2#53: Transfer completed: 1 messages, 11 records, 321 bytes, 0.001 secs (321000 bytes/sec)
Nov 18 18:23:47 servidor3 named[962]: zone 1.168.192.in-addr.arpa/IN: sending notifies (serial 3)
Nov 18 18:23:47 servidor3 named[962]: zone iesgn.org/IN: Transfer started.
Nov 18 18:23:47 servidor3 named[962]: client @0x7fcd004faf80 192.168.1.2#35675: received notify for zone '0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa'
Nov 18 18:23:47 servidor3 named[962]: zone 0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN: notify from 192.168.1.2#35675: serial 7
Nov 18 18:23:47 servidor3 named[962]: transfer of 'iesgn.org/IN' from 192.168.1.2#53: connected using 192.168.1.230#41235
Nov 18 18:23:47 servidor3 named[962]: zone 0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN: Transfer started.
Nov 18 18:23:47 servidor3 named[962]: transfer of '0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN' from 192.168.1.2#53: connected using 192.168.1.230#36871
Nov 18 18:23:47 servidor3 named[962]: zone iesgn.org/IN: transferred serial 5
Nov 18 18:23:47 servidor3 named[962]: transfer of 'iesgn.org/IN' from 192.168.1.2#53: Transfer status: success
Nov 18 18:23:47 servidor3 named[962]: transfer of 'iesgn.org/IN' from 192.168.1.2#53: Transfer completed: 1 messages, 18 records, 485 bytes, 0.002 secs (242500 bytes/sec)
Nov 18 18:23:47 servidor3 named[962]: zone iesgn.org/IN: sending notifies (serial 5)
Nov 18 18:23:47 servidor3 named[962]: zone 0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN: transferred serial 7
Nov 18 18:23:47 servidor3 named[962]: transfer of '0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN' from 192.168.1.2#53: Transfer status: success
Nov 18 18:23:47 servidor3 named[962]: transfer of '0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN' from 192.168.1.2#53: Transfer completed: 1 messages, 11 records, 375 bytes, 0.001 secs (375000 bytes/sec)
Nov 18 18:23:47 servidor3 named[962]: zone 0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN: sending notifies (serial 7)
Nov 18 18:25:17 servidor3 named[962]: client @0x7fcd004faf80 192.168.1.2#50994: received notify for zone '1.168.192.in-addr.arpa'
Nov 18 18:25:17 servidor3 named[962]: zone 1.168.192.in-addr.arpa/IN: notify from 192.168.1.2#50994: serial 4
Nov 18 18:25:17 servidor3 named[962]: zone 1.168.192.in-addr.arpa/IN: Transfer started.
Nov 18 18:25:17 servidor3 named[962]: transfer of '1.168.192.in-addr.arpa/IN' from 192.168.1.2#53: connected using 192.168.1.230#45037
Nov 18 18:25:17 servidor3 named[962]: zone 1.168.192.in-addr.arpa/IN: transferred serial 4
Nov 18 18:25:17 servidor3 named[962]: transfer of '1.168.192.in-addr.arpa/IN' from 192.168.1.2#53: Transfer status: success
Nov 18 18:25:17 servidor3 named[962]: transfer of '1.168.192.in-addr.arpa/IN' from 192.168.1.2#53: Transfer completed: 1 messages, 11 records, 321 bytes, 0.001 secs (321000 bytes/sec)
Nov 18 18:25:17 servidor3 named[962]: zone 1.168.192.in-addr.arpa/IN: sending notifies (serial 4)
Nov 18 18:25:17 servidor3 named[962]: client @0x7fcd004faf80 192.168.1.2#58914: received notify for zone 'iesgn.org'
Nov 18 18:25:17 servidor3 named[962]: zone iesgn.org/IN: notify from 192.168.1.2#58914: serial 6
Nov 18 18:25:17 servidor3 named[962]: client @0x7fcd004faf80 192.168.1.2#58914: received notify for zone '0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa'
Nov 18 18:25:17 servidor3 named[962]: zone 0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN: notify from 192.168.1.2#58914: serial 8
Nov 18 18:25:17 servidor3 named[962]: zone iesgn.org/IN: Transfer started.
Nov 18 18:25:17 servidor3 named[962]: transfer of 'iesgn.org/IN' from 192.168.1.2#53: connected using 192.168.1.230#38749
Nov 18 18:25:17 servidor3 named[962]: zone iesgn.org/IN: transferred serial 6
Nov 18 18:25:17 servidor3 named[962]: transfer of 'iesgn.org/IN' from 192.168.1.2#53: Transfer status: success
Nov 18 18:25:17 servidor3 named[962]: transfer of 'iesgn.org/IN' from 192.168.1.2#53: Transfer completed: 1 messages, 18 records, 475 bytes, 0.002 secs (237500 bytes/sec)
Nov 18 18:25:17 servidor3 named[962]: zone iesgn.org/IN: sending notifies (serial 6)
Nov 18 18:25:18 servidor3 named[962]: zone 0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN: Transfer started.
Nov 18 18:25:18 servidor3 named[962]: transfer of '0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN' from 192.168.1.2#53: connected using 192.168.1.230#35161
Nov 18 18:25:18 servidor3 named[962]: zone 0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN: transferred serial 8
Nov 18 18:25:18 servidor3 named[962]: transfer of '0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN' from 192.168.1.2#53: Transfer status: success
Nov 18 18:25:18 servidor3 named[962]: transfer of '0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN' from 192.168.1.2#53: Transfer completed: 1 messages, 11 records, 365 bytes, 0.001 secs (365000 bytes/sec)
Nov 18 18:25:18 servidor3 named[962]: zone 0.0.0.0.0.0.0.0.d.c.b.a.1.0.0.2.ip6.arpa/IN: sending notifies (serial 8)


```

*Tarea 5 (1 punto): Documenta los siguientes apartados:*

    Configura un cliente para que utilice los dos servidores como servidores DNS.

Ponemos en el /etc/resolv.conf del cliente
```
nameserver 192.168.1.2 #Servidor Principal
nameserver 192.168.1.230 #Servidor Esclavo

```
    Realiza una consulta con dig tanto al maestro como al esclavo para comprobar que las respuestas son autorizadas. ¿En qué te tienes que fijar?
```
dig @192.168.1.2 apache.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> @192.168.1.2 apache.iesgn.org
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 64529
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 4

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: e2ee643cabd2e1f64548d5795dd3ac853cd956a552d15cc9 (good)
;; QUESTION SECTION:
;apache.iesgn.org.		IN	A

;; ANSWER SECTION:
apache.iesgn.org.	604800	IN	A	192.168.1.201

;; AUTHORITY SECTION:
iesgn.org.		604800	IN	NS	alejandro.iesgn.org.
iesgn.org.		604800	IN	NS	afrodita.iesgn.org.

;; ADDITIONAL SECTION:
afrodita.iesgn.org.	604800	IN	A	192.168.1.230
alejandro.iesgn.org.	604800	IN	A	192.168.1.2
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1

;; Query time: 0 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Tue Nov 19 08:49:09 GMT 2019
;; MSG SIZE  rcvd: 196

dig @192.168.1.230 apache.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> @192.168.1.230 apache.iesgn.org
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 31645
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 4

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 19c37714d787cce5955de5fb5dd3ac96b83e1db1e796aabc (good)
;; QUESTION SECTION:
;apache.iesgn.org.		IN	A

;; ANSWER SECTION:
apache.iesgn.org.	604800	IN	A	192.168.1.201

;; AUTHORITY SECTION:
iesgn.org.		604800	IN	NS	afrodita.iesgn.org.
iesgn.org.		604800	IN	NS	alejandro.iesgn.org.

;; ADDITIONAL SECTION:
afrodita.iesgn.org.	604800	IN	A	192.168.1.230
alejandro.iesgn.org.	604800	IN	A	192.168.1.2
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1

;; Query time: 0 msec
;; SERVER: 192.168.1.230#53(192.168.1.230)
;; WHEN: Tue Nov 19 08:49:26 GMT 2019
;; MSG SIZE  rcvd: 196

```

Te tienes que fijar en el servidor que responde SERVER: ...


    Solicita una copia completa de la zona desde el cliente ¿qué tiene que ocurrir?. Solicita una copia completa desde el esclavo ¿qué tiene que ocurrir?

Cliente:
```
vagrant@cliente:~$ dig @192.168.1.2 iesgn.org. axfr

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> @192.168.1.2 iesgn.org. axfr
; (1 server found)
;; global options: +cmd
; Transfer failed.
```

La transferencia del cliente no está permitida ya que pusimos la opción en named.conf.options para que nadie pueda transferir

Esclavo:
```
root@servidor3:/home/vagrant# dig @192.168.1.2 iesgn.org. axfr

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> @192.168.1.2 iesgn.org. axfr
; (1 server found)
;; global options: +cmd
iesgn.org.		604800	IN	SOA	alejandro.iesgn.org. root.iesgn.org. 19111901 604800 86400 2419200 604800
iesgn.org.		604800	IN	NS	afrodita.iesgn.org.
iesgn.org.		604800	IN	NS	alejandro.iesgn.org.
iesgn.org.		604800	IN	MX	10 correo.iesgn.org.
afrodita.iesgn.org.	604800	IN	A	192.168.1.230
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1
alejandro.iesgn.org.	604800	IN	A	192.168.1.2
apache.iesgn.org.	604800	IN	AAAA	2001:abcd::2
apache.iesgn.org.	604800	IN	A	192.168.1.201
cliente.iesgn.org.	604800	IN	AAAA	2001:abcd::3
cliente.iesgn.org.	604800	IN	A	192.168.1.205
correo.iesgn.org.	604800	IN	AAAA	2001:abcd::4
correo.iesgn.org.	604800	IN	A	192.168.1.200
departamentos.iesgn.org. 604800	IN	CNAME	apache.iesgn.org.
ftp.iesgn.org.		604800	IN	AAAA	2001:abcd::5
ftp.iesgn.org.		604800	IN	A	192.168.1.202
www.iesgn.org.		604800	IN	CNAME	apache.iesgn.org.
iesgn.org.		604800	IN	SOA	alejandro.iesgn.org. root.iesgn.org. 19111901 604800 86400 2419200 604800
;; Query time: 1 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Tue Nov 19 08:52:48 GMT 2019
;; XFR size: 18 records (messages 1, bytes 514)

```
Y aqui el esclavo si puede ya que el maestro lo tiene permitido

*Tarea 6 (1 punto): Muestra al profesor el funcionamiento del DNS esclavo:*

    Realiza una consulta desde el cliente y comprueba que servidor está respondiendo.
dig apache.iesgn.org
```
; <<>> DiG 9.11.5-P4-5.1-Debian <<>> apache.iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 23628
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 4

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: d58e9e5c2b720b5f19c491a15dd3add2524fbca8b0fe6a99 (good)
;; QUESTION SECTION:
;apache.iesgn.org.		IN	A

;; ANSWER SECTION:
apache.iesgn.org.	604800	IN	A	192.168.1.201

;; AUTHORITY SECTION:
iesgn.org.		604800	IN	NS	afrodita.iesgn.org.
iesgn.org.		604800	IN	NS	alejandro.iesgn.org.

;; ADDITIONAL SECTION:
afrodita.iesgn.org.	604800	IN	A	192.168.1.230
alejandro.iesgn.org.	604800	IN	A	192.168.1.2
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1

;; Query time: 0 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Tue Nov 19 08:54:42 GMT 2019
;; MSG SIZE  rcvd: 196
```
Responde el servidor que va en primer lugar en el /etc/resolv.conf

    Posteriormente apaga el servidor maestro y vuelve a realizar una consulta desde el cliente ¿quién responde?
```
systemctl stop bind9

dig apache.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> apache.iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 57955
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 4

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: d0156d36294f6979a234b74b5dd3ae04f7e9244d8d60a4d8 (good)
;; QUESTION SECTION:
;apache.iesgn.org.		IN	A

;; ANSWER SECTION:
apache.iesgn.org.	604800	IN	A	192.168.1.201

;; AUTHORITY SECTION:
iesgn.org.		604800	IN	NS	afrodita.iesgn.org.
iesgn.org.		604800	IN	NS	alejandro.iesgn.org.

;; ADDITIONAL SECTION:
afrodita.iesgn.org.	604800	IN	A	192.168.1.230
alejandro.iesgn.org.	604800	IN	A	192.168.1.2
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1

;; Query time: 1 msec
;; SERVER: 192.168.1.230#53(192.168.1.230)
;; WHEN: Tue Nov 19 08:55:32 GMT 2019
;; MSG SIZE  rcvd: 196


```

*Tarea 7 (3 puntos): Realiza la instalación y configuración del nuevo servidor dns con las características anteriormente señaladas. Muestra el resultado al profesor.*
Hacemos una nueva máquina Vagrant
```
config.vm.define :servidor4 do |servidor4|
         servidor4.vm.box = "debian/buster64"
         servidor4.vm.hostname = "servidor4"
         servidor4.vm.network :private_network, ip: "192.168.1.240", virtualbox__intnet: "dns1"
  end
```

En nuestro dominio principal añadimos las siguientes líneas:
```
@      IN      NS      ns.informatica.iesgn.org.
$ORIGIN informatica.iesgn.org.
ns     IN      A       192.168.1.240
```

Ahora vamos al dominio delegado y instalamos el bind9
```
apt install bind9
```

Ahora vamos a la configuración de zonas y ponemos:
```
zone "informatica.iesgn.org" {
        type master;
        file "/var/cache/bind/db.informatica.iesgn.org";
};
```

Ahora crearemos el fichero /var/cache/bind/db.informatica.iesgn.org
```
@       IN      NS      ns.informatica.iesgn.org.
@       IN      MX      10      correo.informatica.iesgn.org.
$ORIGIN informatica.iesgn.org.
ns      IN      A       192.168.1.240
web     IN      A       192.168.1.241
WWW     IN      CNAME   web
ftp     IN      CNAME   web
correo  IN      A       192.168.1.242

```




*Tarea 8 (1 punto): Realiza las consultas dig/neslookup desde los clientes preguntando por los siguientes:*

    Dirección de www.informatica.iesgn.org, ftp.informatica.iesgn.org

```
dig www.informatica.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> www.informatica.iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 27432
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: d24102717b1e00389e22144c5dd4f8b962e20cc031ef4780 (good)
;; QUESTION SECTION:
;www.informatica.iesgn.org.	IN	A

;; ANSWER SECTION:
WWW.informatica.iesgn.org. 86348 IN	CNAME	web.informatica.iesgn.org.
web.informatica.iesgn.org. 86348 IN	A	192.168.1.241

;; AUTHORITY SECTION:
informatica.iesgn.org.	604800	IN	NS	ns.informatica.iesgn.org.

;; Query time: 1 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Wed Nov 20 08:26:33 GMT 2019
;; MSG SIZE  rcvd: 137

dig ftp.informatica.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> ftp.informatica.iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 13900
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 49b7967be5a5da9867fe5e085dd4f8cad911b5482c10fbd8 (good)
;; QUESTION SECTION:
;ftp.informatica.iesgn.org.	IN	A

;; ANSWER SECTION:
ftp.informatica.iesgn.org. 86400 IN	CNAME	web.informatica.iesgn.org.
web.informatica.iesgn.org. 86331 IN	A	192.168.1.241

;; AUTHORITY SECTION:
informatica.iesgn.org.	604800	IN	NS	ns.informatica.iesgn.org.

;; Query time: 4 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Wed Nov 20 08:26:50 GMT 2019
;; MSG SIZE  rcvd: 133

```
    El servidor DNS que tiene configurado la zona del dominio informatica.iesgn.org. ¿Es el mismo que el servidor DNS con autoridad para la zona iesgn.org?
```
dig ns informatica.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> ns informatica.iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29136
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: a0644849e99a4b46f57d3c1f5dd4f8ebaec29b1feb781450 (good)
;; QUESTION SECTION:
;informatica.iesgn.org.		IN	NS

;; ANSWER SECTION:
informatica.iesgn.org.	86400	IN	NS	ns.informatica.iesgn.org.

;; Query time: 3 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Wed Nov 20 08:27:23 GMT 2019
;; MSG SIZE  rcvd: 95

dig ns iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> ns iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 15103
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 4

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: ce96835237e8b16442c6c1d45dd4f8f511a4fb0fefe228b1 (good)
;; QUESTION SECTION:
;iesgn.org.			IN	NS

;; ANSWER SECTION:
iesgn.org.		604800	IN	NS	alejandro.iesgn.org.
iesgn.org.		604800	IN	NS	afrodita.iesgn.org.

;; ADDITIONAL SECTION:
afrodita.iesgn.org.	604800	IN	A	192.168.1.230
alejandro.iesgn.org.	604800	IN	A	192.168.1.2
alejandro.iesgn.org.	604800	IN	AAAA	2001:abcd::1

;; Query time: 1 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Wed Nov 20 08:27:33 GMT 2019
;; MSG SIZE  rcvd: 173

```
    El servidor de correo configurado para informatica.iesgn.org
```
dig mx informatica.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> mx informatica.iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 19567
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 2923590b6ce3c1b56331747a5dd4f9033553bb9e886528dd (good)
;; QUESTION SECTION:
;informatica.iesgn.org.		IN	MX

;; ANSWER SECTION:
informatica.iesgn.org.	86290	IN	MX	10 correo.informatica.iesgn.org.

;; AUTHORITY SECTION:
informatica.iesgn.org.	86376	IN	NS	ns.informatica.iesgn.org.

;; Query time: 2 msec
;; SERVER: 192.168.1.2#53(192.168.1.2)
;; WHEN: Wed Nov 20 08:27:47 GMT 2019
;; MSG SIZE  rcvd: 118

```

*Tarea 9 (5 puntos): Documenta en redmine el proceso que has realizado para configurar un DNS dinámico. Muestra un aprueba de funcionamiento.*
Vamos a hacer una nueva máquina para que veamos el servidor dns dinámico
```
config.vm.define :servidor4 do |servidor4|
         dinamico.vm.box = "debian/buster64"
         dinamico.vm.hostname = "dinamico"
         dinamico.vm.network :private_network, ip: "192.168.1.220", virtualbox__intnet: "dns1"
  end
```

Instalamos bind9
```
apt install bind9
```
En named.conf ponemos las siguientes líneas
```
include "/etc/bind/rndc.key";

controls {
inet 127.0.0.1 port 953
allow { 127.0.0.1; } keys { "rndc-key"; };
};
```

Ahora vamos a crear las zonas, directas e inversas
```
zone "iesgn.org" {
type master;
file "/var/cache/bind/db.iesgn.org";
allow-update { key "rndc-key"; };
notify yes;
};

zone "1.168.192.in-addr.arpa" {
type master;
file "/var/cache/bind/db.192.168.1";
allow-update { key "rndc-key"; };
notify yes;
};
```

Ahora creamos db.iesgn.org
```
@       IN      NS      dinamico.iesgn.org.

$ORIGIN iesgn.org.
dinamico        IN      A       192.168.1.220

```

Y db.192.168.1
```
@       IN      NS      dinamico.iesgn.org.

$ORIGIN 1.168.192.in-addr.arpa.
220     IN      PTR     dinamico.iesgn.org.

```

Vemos que funciona
```
dig @192.168.1.220 dinamico.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> @192.168.1.220 dinamico.iesgn.org
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 64298
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: e0aa92f666e8b731916673645dd504ddae5727e7121ccba6 (good)
;; QUESTION SECTION:
;dinamico.iesgn.org.		IN	A

;; ANSWER SECTION:
dinamico.iesgn.org.	86400	IN	A	192.168.1.220

;; AUTHORITY SECTION:
iesgn.org.		86400	IN	NS	dinamico.iesgn.org.

;; Query time: 0 msec
;; SERVER: 192.168.1.220#53(192.168.1.220)
;; WHEN: Wed Nov 20 09:18:21 GMT 2019
;; MSG SIZE  rcvd: 105
```

Ahora vamos a instalar el servidor dhcp
```
apt install isc-dhcp-server
```

Ahora en /etc/default/isc-dhcp-server metemos
```
INTERFACESv4="eth1"
```

Ahora lo que quedaría es definir las zonas DNS en /etc/dhcp/dhcpd.conf
```

server-identifier    dinamico.iesgn.org;
ddns-updates        on;
ddns-update-style   interim;
ddns-domainname     "iesgn.org.";
ddns-rev-domainname "in-addr.arpa.";
deny                client-updates;
include             "/etc/bind/rndc.key";

zone iesgn.org. {
  primary  127.0.0.1;
  key rndc-key;
}

zone 1.168.192.in-addr.arpa. {
   primary  127.0.0.1;
   key  rndc-key;
}

subnet 192.168.1.0 netmask 255.255.255.0 {
  range 192.168.1.20 192.168.1.100;
  option routers 192.168.1.220;
  option domain-name "iesgn.org.";
}
```

Ahora ponemos en marcha ambos servicios, para ello vaciamos primero los ficheros de peticiones y volvemos a arrancar los servicios
```
systemctl stop bind9
systemctl stop isc-dhcp-server
echo "" > /var/lib/dhcp/dhcpd.leases
echo "" > /var/lib/dhcp/dhcpd.leases~
```

Ahora volvemos a iniciar los servicios
```
root@dinamico:/home/vagrant# systemctl restart bind9
root@dinamico:/home/vagrant# systemctl restart isc-dhcp-server
```

Ahora vamos a hacer que un cliente pida dhcp y vemos si consigue DNS
```
config.vm.define :cliente1 do |cliente1|
         cliente1.vm.box = "debian/buster64"
         cliente1.vm.hostname = "cliente1"
         cliente1.vm.network :private_network, virtualbox__intnet: "dns1"
  end
```

Vamos a activar el dhcp en /etc/network/interfaces
```
auto eth1
iface eth1 inet dhcp 
```

```
root@cliente1:/home/vagrant# ifup eth1
Internet Systems Consortium DHCP Client 4.4.1
Copyright 2004-2018 Internet Systems Consortium.
All rights reserved.
For info, please visit https://www.isc.org/software/dhcp/

Listening on LPF/eth1/08:00:27:43:2b:5a
Sending on   LPF/eth1/08:00:27:43:2b:5a
Sending on   Socket/fallback
Created duid "\000\001\000\001%hG\256\010\000'C+Z".
DHCPDISCOVER on eth1 to 255.255.255.255 port 67 interval 4
DHCPOFFER of 192.168.1.20 from 192.168.1.220
DHCPREQUEST for 192.168.1.20 on eth1 to 255.255.255.255 port 67
DHCPACK of 192.168.1.20 from 192.168.1.220
bound to 192.168.1.20 -- renewal in 18046 seconds.
```

Ahora veamos en /var/log/syslog si le ha dado el servidor el dns
```
Nov 20 18:47:10 dinamico systemd[1]: Started LSB: DHCP server.
Nov 20 18:49:30 dinamico systemd[1]: session-6.scope: Succeeded.
Nov 20 18:51:26 dinamico dhcpd[1149]: dinamico.iesgn.org: host unknown.
Nov 20 18:51:26 dinamico dhcpd[1149]: DHCPDISCOVER from 08:00:27:43:2b:5a via eth1
Nov 20 18:51:27 dinamico dhcpd[1149]: DHCPOFFER on 192.168.1.20 to 08:00:27:43:2b:5a (cliente1) via eth1
Nov 20 18:51:27 dinamico dhcpd[1149]: DHCPREQUEST for 192.168.1.20 (192.168.1.220) from 08:00:27:43:2b:5a (cliente1) via eth1
Nov 20 18:51:27 dinamico dhcpd[1149]: DHCPACK on 192.168.1.20 to 08:00:27:43:2b:5a (cliente1) via eth1
Nov 20 18:51:27 dinamico named[1130]: client @0x7f6fc40b8f00 127.0.0.1#35207/key rndc-key: signer "rndc-key" approved
Nov 20 18:51:27 dinamico named[1130]: client @0x7f6fc40b8f00 127.0.0.1#35207/key rndc-key: updating zone 'iesgn.org/IN': adding an RR at 'cliente1.iesgn.org' A 192.168.1.20
Nov 20 18:51:27 dinamico named[1130]: client @0x7f6fc40b8f00 127.0.0.1#35207/key rndc-key: updating zone 'iesgn.org/IN': adding an RR at 'cliente1.iesgn.org' TXT "310046d6152875d5b276f5519ed10ae535"
Nov 20 18:51:27 dinamico dhcpd[1149]: Added new forward map from cliente1.iesgn.org. to 192.168.1.20
Nov 20 18:51:27 dinamico named[1130]: client @0x7f6fc4055090 127.0.0.1#36495/key rndc-key: signer "rndc-key" approved
Nov 20 18:51:27 dinamico named[1130]: client @0x7f6fc4055090 127.0.0.1#36495/key rndc-key: updating zone '1.168.192.in-addr.arpa/IN': deleting rrset at '20.1.168.192.in-addr.arpa' PTR
Nov 20 18:51:27 dinamico named[1130]: client @0x7f6fc4055090 127.0.0.1#36495/key rndc-key: updating zone '1.168.192.in-addr.arpa/IN': adding an RR at '20.1.168.192.in-addr.arpa' PTR cliente1.iesgn.org.
Nov 20 18:51:27 dinamico dhcpd[1149]: Added reverse map from 20.1.168.192.in-addr.arpa. to cliente1.iesgn.org.
```

Y finalmente hacemos una consulta para ver si está funcionando el DNS
```
dig cliente1.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> cliente1.iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 62670
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: a3f491ae10a4c94bfd5db6085dd58baa8fb96143a9ed474e (good)
;; QUESTION SECTION:
;cliente1.iesgn.org.		IN	A

;; ANSWER SECTION:
cliente1.iesgn.org.	3600	IN	A	192.168.1.20

;; AUTHORITY SECTION:
iesgn.org.		86400	IN	NS	dinamico.iesgn.org.

;; ADDITIONAL SECTION:
dinamico.iesgn.org.	86400	IN	A	192.168.1.220

;; Query time: 1 msec
;; SERVER: 192.168.1.220#53(192.168.1.220)
;; WHEN: Wed Nov 20 18:53:30 GMT 2019
;; MSG SIZE  rcvd: 130

```

*Tarea 9 (5 puntos): Documenta en redmine el proceso que has realizado para configurar un DNS dinámico. Muestra un aprueba de funcionamiento.*
Vamos a hacer una nueva máquina para que veamos el servidor dns dinámico
```
config.vm.define :servidor4 do |servidor4|
         dinamico.vm.box = "debian/buster64"
         dinamico.vm.hostname = "dinamico"
         dinamico.vm.network :private_network, ip: "192.168.1.220", virtualbox__intnet: "dns1"
  end
```

Instalamos bind9
```
apt install bind9
```
En named.conf ponemos las siguientes líneas
```
include "/etc/bind/rndc.key";

controls {
inet 127.0.0.1 port 953
allow { 127.0.0.1; } keys { "rndc-key"; };
};
```

Ahora vamos a crear las zonas, directas e inversas
```
zone "iesgn.org" {
type master;
file "/var/cache/bind/db.iesgn.org";
allow-update { key "rndc-key"; };
notify yes;
};

zone "1.168.192.in-addr.arpa" {
type master;
file "/var/cache/bind/db.192.168.1";
allow-update { key "rndc-key"; };
notify yes;
};
```

Ahora creamos db.iesgn.org
```
@       IN      NS      dinamico.iesgn.org.

$ORIGIN iesgn.org.
dinamico        IN      A       192.168.1.220

```

Y db.192.168.1
```
@       IN      NS      dinamico.iesgn.org.

$ORIGIN 1.168.192.in-addr.arpa.
220     IN      PTR     dinamico.iesgn.org.

```

Vemos que funciona
```
dig @192.168.1.220 dinamico.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> @192.168.1.220 dinamico.iesgn.org
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 64298
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: e0aa92f666e8b731916673645dd504ddae5727e7121ccba6 (good)
;; QUESTION SECTION:
;dinamico.iesgn.org.		IN	A

;; ANSWER SECTION:
dinamico.iesgn.org.	86400	IN	A	192.168.1.220

;; AUTHORITY SECTION:
iesgn.org.		86400	IN	NS	dinamico.iesgn.org.

;; Query time: 0 msec
;; SERVER: 192.168.1.220#53(192.168.1.220)
;; WHEN: Wed Nov 20 09:18:21 GMT 2019
;; MSG SIZE  rcvd: 105
```

Ahora vamos a instalar el servidor dhcp
```
apt install isc-dhcp-server
```

Ahora en /etc/default/isc-dhcp-server metemos
```
INTERFACESv4="eth1"
```

Ahora lo que quedaría es definir las zonas DNS en /etc/dhcp/dhcpd.conf
```

server-identifier    dinamico.iesgn.org;
ddns-updates        on;
ddns-update-style   interim;
ddns-domainname     "iesgn.org.";
ddns-rev-domainname "in-addr.arpa.";
deny                client-updates;
include             "/etc/bind/rndc.key";

zone iesgn.org. {
  primary  127.0.0.1;
  key rndc-key;
}

zone 1.168.192.in-addr.arpa. {
   primary  127.0.0.1;
   key  rndc-key;
}

subnet 192.168.1.0 netmask 255.255.255.0 {
  range 192.168.1.20 192.168.1.100;
  option routers 192.168.1.220;
  option domain-name "iesgn.org.";
}
```

Ahora ponemos en marcha ambos servicios, para ello vaciamos primero los ficheros de peticiones y volvemos a arrancar los servicios
```
systemctl stop bind9
systemctl stop isc-dhcp-server
echo "" > /var/lib/dhcp/dhcpd.leases
echo "" > /var/lib/dhcp/dhcpd.leases~
```

Ahora volvemos a iniciar los servicios
```
root@dinamico:/home/vagrant# systemctl restart bind9
root@dinamico:/home/vagrant# systemctl restart isc-dhcp-server
```

Ahora vamos a hacer que un cliente pida dhcp y vemos si consigue DNS
```
config.vm.define :cliente1 do |cliente1|
         cliente1.vm.box = "debian/buster64"
         cliente1.vm.hostname = "cliente1"
         cliente1.vm.network :private_network, virtualbox__intnet: "dns1"
  end
```

Vamos a activar el dhcp en /etc/network/interfaces
```
auto eth1
iface eth1 inet dhcp 
```

```
root@cliente1:/home/vagrant# ifup eth1
Internet Systems Consortium DHCP Client 4.4.1
Copyright 2004-2018 Internet Systems Consortium.
All rights reserved.
For info, please visit https://www.isc.org/software/dhcp/

Listening on LPF/eth1/08:00:27:43:2b:5a
Sending on   LPF/eth1/08:00:27:43:2b:5a
Sending on   Socket/fallback
Created duid "\000\001\000\001%hG\256\010\000'C+Z".
DHCPDISCOVER on eth1 to 255.255.255.255 port 67 interval 4
DHCPOFFER of 192.168.1.20 from 192.168.1.220
DHCPREQUEST for 192.168.1.20 on eth1 to 255.255.255.255 port 67
DHCPACK of 192.168.1.20 from 192.168.1.220
bound to 192.168.1.20 -- renewal in 18046 seconds.
```

Ahora veamos en /var/log/syslog si le ha dado el servidor el dns
```
Nov 20 18:47:10 dinamico systemd[1]: Started LSB: DHCP server.
Nov 20 18:49:30 dinamico systemd[1]: session-6.scope: Succeeded.
Nov 20 18:51:26 dinamico dhcpd[1149]: dinamico.iesgn.org: host unknown.
Nov 20 18:51:26 dinamico dhcpd[1149]: DHCPDISCOVER from 08:00:27:43:2b:5a via eth1
Nov 20 18:51:27 dinamico dhcpd[1149]: DHCPOFFER on 192.168.1.20 to 08:00:27:43:2b:5a (cliente1) via eth1
Nov 20 18:51:27 dinamico dhcpd[1149]: DHCPREQUEST for 192.168.1.20 (192.168.1.220) from 08:00:27:43:2b:5a (cliente1) via eth1
Nov 20 18:51:27 dinamico dhcpd[1149]: DHCPACK on 192.168.1.20 to 08:00:27:43:2b:5a (cliente1) via eth1
Nov 20 18:51:27 dinamico named[1130]: client @0x7f6fc40b8f00 127.0.0.1#35207/key rndc-key: signer "rndc-key" approved
Nov 20 18:51:27 dinamico named[1130]: client @0x7f6fc40b8f00 127.0.0.1#35207/key rndc-key: updating zone 'iesgn.org/IN': adding an RR at 'cliente1.iesgn.org' A 192.168.1.20
Nov 20 18:51:27 dinamico named[1130]: client @0x7f6fc40b8f00 127.0.0.1#35207/key rndc-key: updating zone 'iesgn.org/IN': adding an RR at 'cliente1.iesgn.org' TXT "310046d6152875d5b276f5519ed10ae535"
Nov 20 18:51:27 dinamico dhcpd[1149]: Added new forward map from cliente1.iesgn.org. to 192.168.1.20
Nov 20 18:51:27 dinamico named[1130]: client @0x7f6fc4055090 127.0.0.1#36495/key rndc-key: signer "rndc-key" approved
Nov 20 18:51:27 dinamico named[1130]: client @0x7f6fc4055090 127.0.0.1#36495/key rndc-key: updating zone '1.168.192.in-addr.arpa/IN': deleting rrset at '20.1.168.192.in-addr.arpa' PTR
Nov 20 18:51:27 dinamico named[1130]: client @0x7f6fc4055090 127.0.0.1#36495/key rndc-key: updating zone '1.168.192.in-addr.arpa/IN': adding an RR at '20.1.168.192.in-addr.arpa' PTR cliente1.iesgn.org.
Nov 20 18:51:27 dinamico dhcpd[1149]: Added reverse map from 20.1.168.192.in-addr.arpa. to cliente1.iesgn.org.
```

Y finalmente hacemos una consulta para ver si está funcionando el DNS
```
dig cliente1.iesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> cliente1.iesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 62670
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: a3f491ae10a4c94bfd5db6085dd58baa8fb96143a9ed474e (good)
;; QUESTION SECTION:
;cliente1.iesgn.org.		IN	A

;; ANSWER SECTION:
cliente1.iesgn.org.	3600	IN	A	192.168.1.20

;; AUTHORITY SECTION:
iesgn.org.		86400	IN	NS	dinamico.iesgn.org.

;; ADDITIONAL SECTION:
dinamico.iesgn.org.	86400	IN	A	192.168.1.220

;; Query time: 1 msec
;; SERVER: 192.168.1.220#53(192.168.1.220)
;; WHEN: Wed Nov 20 18:53:30 GMT 2019
;; MSG SIZE  rcvd: 130

```

*Tarea 13 (1 punto): Instala un WebFrontend para manejar PowerDns. WebFrontends*
Vamos a instalar  Opera's LDAP-authenticated PowerDNS user interface 
Para ello vamos a instalar un apache
```
apt install apache2
a2enmod rewrite
```

Ahora vamos a instalar git para clonar el repositorio
```
apt install git
```

Vamos a configurar un virtualhost para la web
```
<VirtualHost *:80>
    ServerAdmin webmaster@localhost

    ServerName pdns.iesgn.com

    DocumentRoot /var/www/pdnsmanager/frontend

    RewriteEngine On
    RewriteRule ^index\.html$ - [L]
    RewriteCond %{DOCUMENT_ROOT}%{REQUEST_FILENAME} !-f
    RewriteCond %{DOCUMENT_ROOT}%{REQUEST_FILENAME} !-d
    RewriteRule !^/api/\.* /index.html [L]

    Alias /api /var/www/pdnsmanager/backend/public
    <Directory /var/www/pdnsmanager/backend/public>
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^ index.php [QSA,L]
    </Directory>

</VirtualHost>

```

```
a2ensite nsedit
systemctl restart apache2
```

Ahora instalamos los modulos necesarios de php
```
apt install php libapache2-mod-php php-mysql php-apcu
```

Clonamos el repositorio
```
root@servidorpdns:/var/www# git clone https://github.com/loewexy/pdnsmanager.git
```

Ahora entramos a la página y ponemos /setup
![](/images/powerdnsmanager.png)

En dicha página, no podremos usar la base de datos antigüa ya que esta web tiene un diseño de la base de datos distinto al que hemos creado, por lo que vamos a probarlo con una nueva base de datos
```
create database pdnsmanager
grant all privileges on pdnsmanager.* to pdns;
flush privileges;
```

![](/images/powerdnsmanager2.png)

Para añadir nuevos registros añadimos un nuevo master y seguimos haciendo los registros NS y A respectivamente
![](/images/powerdnsmanager3.png)

Vamos a probar ahora que en dichos registros podemos consultar al servidor, para que funcione deberemos cambiar la base de datos en el fichero /etc/powerdns/pdns.conf y tener abierto el puerto 53 para pdns
```
launch=gmysql
gmysql-host=127.0.0.1
gmysql-user=pdns
gmysql-dbname=pdnsmanager
gmysql-password=pdns
```

Y probamos su funcionamiento
```
vagrant@cliente:~$ dig cliente.alexiesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> cliente.alexiesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 64198
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1680
;; QUESTION SECTION:
;cliente.alexiesgn.org.		IN	A

;; ANSWER SECTION:
cliente.alexiesgn.org.	86400	IN	A	192.168.3.41

;; Query time: 2 msec
;; SERVER: 192.168.1.3#53(192.168.1.3)
;; WHEN: Thu Nov 28 07:49:06 GMT 2019
;; MSG SIZE  rcvd: 66


vagrant@cliente:~$ dig ns alexiesgn.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> ns alexiesgn.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 35146
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1680
;; QUESTION SECTION:
;alexiesgn.org.			IN	NS

;; ANSWER SECTION:
alexiesgn.org.		86400	IN	NS	ns.alexiesgn.org.

;; Query time: 2 msec
;; SERVER: 192.168.1.3#53(192.168.1.3)
;; WHEN: Thu Nov 28 07:49:16 GMT 2019
;; MSG SIZE  rcvd: 59

```
