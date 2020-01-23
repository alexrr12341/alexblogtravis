+++
date = "2020-01-23"
title = "Despliegue de CMS Java (Apache Guacamole)"
math = "true"

+++

## Guacamole

En este caso vamos a elegir el CMS Java Apache Guacamole, que lo desplegaremos utilizando tomcat 9, esta aplicación nos permitirá acceder a servidores remotamente utilizando solo un navegador web.
No necesita plugins de clientes ni softwares de clientes y además es de software libre.


## Tomcat 9

Para instalar tomcat necesitaremos primero de todo instalar el siguiente paquete

```
apt install tomcat9
```


## Dependencias de Apache Guacamole

También para poder instalar el CMS necesitaremos instalar varias dependencias, algunas son requeridas y otras opcionales, en este caso vamos a instalar todas


Dependencias Obligatorias:

```
apt install libcairo2-dev libjpeg62-turbo-dev libpng-dev libossp-uuid-dev libtool
```

Dependencias Opcionales:

```
apt install libavcodec-dev libavutil-dev libswscale-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev libfreerpd2-2
```


## Instalación de Guacamole Server

Ahora vamos a instalar guacamole server, que nos lo descargaremos en la página web, con la última versión estable (1.0.0)

https://guacamole.apache.org/releases/1.0.0/

Ya lo tenemos descargado en nuestro sistema:

```
root@java:/home/vagrant# ls
guacamole-client-1.0.0.war
```

Ahora vamos a copiarlo en /var/lib/tomcat9/webapps

```
cp guacamole-1.0.0.war /var/lib/tomcat9/webapps
```

Y miramos que ocurre cuando accedemos a la url
![](/images/Guacamole.png)

 


