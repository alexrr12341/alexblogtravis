+++
date = "2020-03-03"
title = "Proxy, Proxy inverso y balanceadores de carga"
math = "true"

+++

## Proxy, Proxy inverso y balanceadores de carga

Vamos a realizar un ejercicio donde vamos a hacer proxys, proxys inversos y balanceadores de carga.

Vamos a utilizar el siguiente Vagrantfile
```
# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|
config.vm.define :proxy do |proxy|
    proxy.vm.box = "debian/buster64"
    proxy.vm.hostname = "proxy"
    proxy.vm.network :private_network, ip: "10.0.0.10", virtualbox__intnet: "red_privada1"
    proxy.vm.network :private_network, ip: "192.168.200.10"
  end
  config.vm.define :cliente_int do |cliente_int|
    cliente_int.vm.box = "debian/buster64"
    cliente_int.vm.network :private_network, ip: "10.0.0.11",virtualbox__intnet: "red_privada1"
  end
  
end

```

## Máquina proxy

Vamos a instalar squid en dicha máquina, por lo que realizamos
```
apt install squid3
```

Y en /etc/squid3/squid.conf ponemos las siguientes líneas:
```
acl redlocal src 192.168.200.0/24
http_access allow redlocal
```

Y reiniciamos squid
```
systemctl restart squid
```

Ahora vamos a probar distintos métodos del proxy.

### Directamente desde el navegador

Vamos al navegador y hacemos click en preferencias --> Configuracion de red y se nos abrira la siguiente ventana que debe de quedar asi:

![](/images/Proxy.png)

Accedemos a hola.com y miramos los logs en /var/log/squid/access.log

![](/images/Proxy2.png)

```
1583221323.149    473 192.168.200.1 TCP_TUNNEL/200 7109 CONNECT www.himgs.com:443 - HIER_DIRECT/184.27.3.218 -
1583221323.154    392 192.168.200.1 TCP_TUNNEL/200 5939 CONNECT www.himgs.com:443 - HIER_DIRECT/184.27.3.218 -
1583221323.162    401 192.168.200.1 TCP_TUNNEL/200 8793 CONNECT www.himgs.com:443 - HIER_DIRECT/184.27.3.218 -
1583221323.184    508 192.168.200.1 TCP_TUNNEL/200 39589 CONNECT www.himgs.com:443 - HIER_DIRECT/184.27.3.218 -
1583221323.202    440 192.168.200.1 TCP_TUNNEL/200 6199 CONNECT www.himgs.com:443 - HIER_DIRECT/184.27.3.218 -
1583221323.642     99 192.168.200.1 TCP_MISS/200 1135 POST http://ocsp.digicert.com/ - HIER_DIRECT/93.184.220.29 application/ocsp-response

```

### Configuración proxy del sistema
Ahora en el navegador ponemos que use la configuración proxy del sistema

![](/images/Proxy4.png)


Y en nuestro entorno gráfico, vamos a la configuración de red->Proxy de la red y seleccionamos manual y escribimos nuestra IP

![](/images/Proxy5.png)

Y entramos en marca.com

![](/images/Proxy6.png)

Miramos los logs
```
1583221704.401   3882 192.168.200.1 TCP_TUNNEL/200 3911 CONNECT pixelcounter.marca.com:443 - HIER_DIRECT/193.110.128.197 -
1583221709.076    251 192.168.200.1 TCP_TUNNEL/200 5289 CONNECT shb.richaudience.com:443 - HIER_DIRECT/116.202.128.60 -
1583221709.078    253 192.168.200.1 TCP_TUNNEL/200 5289 CONNECT shb.richaudience.com:443 - HIER_DIRECT/116.202.128.60 -
1583221709.091    267 192.168.200.1 TCP_TUNNEL/200 5289 CONNECT shb.richaudience.com:443 - HIER_DIRECT/116.202.128.60 -
1583221709.092    268 192.168.200.1 TCP_TUNNEL/200 5289 CONNECT shb.richaudience.com:443 - HIER_DIRECT/116.202.128.60 -
1583221709.094    270 192.168.200.1 TCP_TUNNEL/200 5289 CONNECT shb.richaudience.com:443 - HIER_DIRECT/116.202.128.60 -
1583221710.048   8824 192.168.200.1 TCP_TUNNEL/200 5754 CONNECT smetrics.el-mundo.net:443 - HIER_DIRECT/52.49.100.189 -
1583221712.356    247 192.168.200.1 TCP_TUNNEL/200 4910 CONNECT sync.richaudience.com:443 - HIER_DIRECT/94.130.216.200 -

```

### Configuración de Squid para cliente interno

Ahora vamos a configurar nuestro cliente interno para que utilice nuestro proxy, para ello vamos a /etc/squid/squid.conf y realizamos lo siguiente
```
acl redinterna src 10.0.0.0/24
http_access allow redinterna
```

Recargamos la configuración
```
systemctl reload squid
```

En nuestro cliente interno instalaremos w3m
```
apt install w3m
```

Configuramos las variables de entorno:

```
root@buster:/home/vagrant# export https_proxy=http://10.0.0.10:3128/
root@buster:/home/vagrant# export http_proxy=http://10.0.0.10:3128/
```

Y accedemos a leagueoflegends.com en w3m
```

w3m leagueoflegends.com
```

Y miramos los logs del proxy
```
1583222100.528    458 10.0.0.11 TCP_MISS/302 742 GET http://leagueoflegends.com/ - HIER_DIRECT/35.156.88.172 text/html
1583222100.856    324 10.0.0.11 TCP_TUNNEL/200 4919 CONNECT www.leagueoflegends.com:443 - HIER_DIRECT/35.156.88.172 -
1583222101.282    423 10.0.0.11 TCP_TUNNEL/200 5514 CONNECT euw.leagueoflegends.com:443 - HIER_DIRECT/23.214.220.216 -
1583222101.514    230 10.0.0.11 TCP_MISS/301 558 GET http://euw.leagueoflegends.com/en-gb/ - HIER_DIRECT/23.214.220.216 -
1583222101.662    145 10.0.0.11 TCP_TUNNEL/200 67604 CONNECT euw.leagueoflegends.com:443 - HIER_DIRECT/23.214.220.216 -

```

### Filtro de listas negras

Vamos a crear el fichero /etc/squid/webs con las web o dominios que no queremos que entren nuestros usuarios del proxy:
```
www.alexrrinformatico.com
```

Y en /etc/squid/squid.conf añadimos la acl necesaria (muy importante que esté arriba de todas las reglas anteriores, sino leerá que puede entrar, funciona como las iptables):
```
acl webs url_regex "/etc/squid/webs"
http_access deny webs
```

Reiniciamos el servicio y miramos si podemos entrar a www.alexrrinformatico.com

![](/images/Proxy8.png)

![](/images/Proxy9.png)

Y miramos los logs
```
1583223971.901 116456 192.168.200.1 TCP_TUNNEL/200 46558 CONNECT www.alexrrinformatico.com:443 - HIER_DIRECT/185.199.109.153 -
1583223971.904      0 192.168.200.1 TCP_DENIED/403 3995 CONNECT www.alexrrinformatico.com:443 - HIER_NONE/- text/html

```

### Filtro de listas blancas

Ahora vamos a realizar justo lo contrario, vamos a aprovechar nuestro /etc/squid/webs pero vamos a realizar justo lo contrario, solo podremos acceder a nuestro blog.

En /etc/squid/squid.conf realizamos la siguiente configuración
```
acl whitelist url_regex "/etc/squid/webs

http_access allow whitelist
http_access deny all
```

![](/images/Proxy10.png)

![](/images/Proxy11.png)

Miramos los logs
```
1583223971.901 116456 192.168.200.1 TCP_TUNNEL/200 46558 CONNECT www.alexrrinformatico.com:443 - HIER_DIRECT/185.199.109.153 -
1583223971.904      0 192.168.200.1 TCP_DENIED/403 3995 CONNECT www.alexrrinformatico.com:443 - HIER_NONE/- text/html

1583224192.666      0 192.168.200.1 NONE/000 0 NONE error:transaction-end-before-headers - HIER_NONE/- -
1583224192.666      0 192.168.200.1 NONE/000 0 NONE error:transaction-end-before-headers - HIER_NONE/- -
1583224192.882      0 192.168.200.1 NONE/000 0 NONE error:transaction-end-before-headers - HIER_NONE/- -
1583224192.882      0 192.168.200.1 NONE/000 0 NONE error:transaction-end-before-headers - HIER_NONE/- -
1583224215.210      0 192.168.200.1 TCP_DENIED/403 3956 CONNECT www.hola.com:443 - HIER_NONE/- text/html
1583224216.688      0 192.168.200.1 NONE/000 0 NONE error:transaction-end-before-headers - HIER_NONE/- -
1583224216.919      0 192.168.200.1 NONE/000 0 NONE error:transaction-end-before-headers - HIER_NONE/- -
1583224216.919      0 192.168.200.1 NONE/000 0 NONE error:transaction-end-before-headers - HIER_NONE/- -

```

## Balanceador de carga


Vamos a realizar el siguiente [escenario](https://fp.josedomingo.org/serviciosgs/u08/doc/haproxy/vagrant.zip) para balanceadores de carga


Realizamos el escenario
```
alexrr@pc-alex:~/vagrant/escenarioBalanceador$ ls
index1.html  index2.html  sesion.php  Vagrantfile  vagrant.zip
alexrr@pc-alex:~/vagrant/escenarioBalanceador$ vagrant up
```

En la máquina balanceador vamos a instalar haproxy
```
apt install haproxy
```

Vamos ahora a /etc/haproxy/haproxy.cfg y realizamos la siguiente configuración
```

global
    daemon
    maxconn 256
    user    haproxy
    group   haproxy
    log     127.0.0.1       local0
    log     127.0.0.1       local1  notice

defaults
    mode    http
    log     global
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms

listen granja_cda
    bind 172.22.5.106:80 #aquí pon la dirección ip del balanceador
    mode http
    stats enable
    stats auth  cda:cda
    balance roundrobin
    server uno 10.10.10.11:80 maxconn 128
    server dos 10.10.10.22:80 maxconn 128

```

Antes de arrancar el servicio, vamos a /etc/default/haproxy y ponemos lo siguiente
```
ENABLED=1
```

Y arrancamos el servicio
```
systemctl restart haproxy
```
![](/images/Balanceador.png)

![](/images/Balanceador2.png)

Vamos al navegador y vamos a observar las estadísticas del proxy en la url http://{ip}/haproxy?stats (la contraseña es cda/cda)

![](/images/Balanceador3.png)


Vamos a observar ahora los logs de apache1
```
root@apache1:/home/vagrant# cat /var/log/apache2/access.log 
10.10.10.1 - - [03/Mar/2020:08:46:27 +0000] "GET / HTTP/1.1" 200 436 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0"
10.10.10.1 - - [03/Mar/2020:08:47:10 +0000] "GET / HTTP/1.1" 200 436 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0"
10.10.10.1 - - [03/Mar/2020:08:47:10 +0000] "GET / HTTP/1.1" 200 436 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0"
10.10.10.1 - - [03/Mar/2020:08:48:34 +0000] "GET /favicon.ico HTTP/1.1" 404 435 "-" "Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0"

```

Aparece la ip interna del balanceador  ya que nosotros accedemos a la ip externa del navegador y este es el que se encarga de preguntar a los servidores web que estan en su red interna cual va a ser el que va a responder a la petición.



Ahora vamos a realizar una configuración con las sesiones php intercambiadas con el fichero sessions.php
```
<?php
     header('Content-Type: text/plain');
     session_start();
     if(!isset($_SESSION['visit']))
     {
             echo "This is the first time you're visiting this server";
             $_SESSION['visit'] = 0;
     }
     else
             echo "Your number of visits: ".$_SESSION['visit'];             

     $_SESSION['visit']++;              

     echo "\nServer IP: ".$_SERVER['SERVER_ADDR'];
     echo "\nClient IP: ".$_SERVER['REMOTE_ADDR'];
     echo "\nX-Forwarded-for: ".$_SERVER['HTTP_X_FORWARDED_FOR']."\n";
     print_r($_COOKIE);
?>

```

Vamos a incluir las siguientes líneas en el balanceador en /etc/haproxy/haproxy.cfg
```
    cookie PHPSESSID prefix                               # <- aquí
    server uno 10.10.10.11:80 cookie EL_UNO maxconn 128   # <- aquí
    server dos 10.10.10.22:80 cookie EL_DOS maxconn 128   # <- aquí

```

Reiniciamos el servicio
```
systemctl restart haproxy
```

Y entramos a la ip http://{ip}/sesion.php
![](/images/Balanceador4.png)


Vemos que el parametro cookie es:
```
Cookie:PHPSESSID=EL_DOS~ms69547s57g990vmk8gppvcieu
```

Si recargamos varias veces la página, vemos que el parámetro no ha cambiado, pero si el número de veces que hemos entrado a la página.

![](/images/Balanceador5.png)

Si entramos en modo incognito, detecta que es una nueva sesión y la cookie cambia.

![](/images/Balanceador7.png)

Vemos que el parametro cookie ahora es:
```
Cookie:PHPSESSID=EL_UNO~98pm9cphn1i3ui30lundf6dar4
```
