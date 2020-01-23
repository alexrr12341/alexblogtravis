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
apt install tomcat8
```


## Dependencias de Apache Guacamole

También para poder instalar el CMS necesitaremos instalar varias dependencias, algunas son requeridas y otras opcionales, en este caso vamos a instalar todas


Dependencias Obligatorias:

```
apt install libcairo2-dev libjpeg62-turbo-dev libpng-dev libossp-uuid-dev libtool
```

Dependencias Opcionales:

```
apt install libavcodec-dev libavutil-dev libswscale-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev libfreerdp-dev
```


## Instalación de Guacamole Server



Vamos a descargar ahora la version de guacamole-server y guacamole-client para poder utilizar guacamole, por lo que lo descargamos de la página https://guacamole.apache.org/releases/1.0.0/ y compilaremos

```
tar -xvf guacamole-server-1.0.0.tar.gz
root@java2:/home/vagrant/guacamole-server-1.0.0# ./configure --with-init-dir=/etc/init.d
```

Y compilamos y instalamos
```
root@java2:/home/vagrant/guacamole-server-1.0.0# make
root@java2:/home/vagrant/guacamole-server-1.0.0# make install
root@java2:/home/vagrant/guacamole-server-1.0.0# ldconfig
```

## Guacamole Client (Guacamole.war)

Ahora vamos a instalar guacamole para la web, que nos lo descargaremos en la página web, con la última versión estable (1.0.0)

https://guacamole.apache.org/releases/1.0.0/

Ya lo tenemos descargado en nuestro sistema:

```
root@java2:/home/vagrant# ls
guacamole-client-1.0.0.war
```

Ahora vamos a copiarlo en /var/lib/tomcat9/webapps

```
cp guacamole-1.0.0.war /var/lib/tomcat9/webapps
```

Y miramos que ocurre cuando accedemos a la url
![](/images/Guacamole.png)


## Configuración de Guacamole server

Vamos ahora a realizar una pequeña configuración de guacamole server, para ello hacemos
```
mkdir /etc/guacamole /usr/share/tomcat8/.guacamole
```

Hacemos ahora el fichero /etc/guacamole/guacamole.properties y ponemos
```
guacd-hostname: localhost
guacd-port: 4822
user-mapping: /etc/guacamole/user-mapping.xml
auth-provider: net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
basic-user-mapping: /etc/guacamole/user-mapping.xml
```

Hacemos el enlace simbólico
```
ln -s guacamole.properties /usr/share/tomcat8/.guacamole/
```

Y hacemos el mapeado de usuarios en /etc/guacamole/user-mapping.xml
```
<user-mapping>
        <authorize 
         username="vagrant" 
         password="63623900c8bbf21c706c45dcb7a2c083" 
         encoding="md5">
                <connection name="SSH">
                        <protocol>ssh</protocol>
                        <param name="hostname">192.168.1.129</param>
                        <param name="port">22</param>
                        <param name="username">alexrr</param>
                </connection>
                <connection name="Remote Desktop">
                        <protocol>rdp</protocol>
                        <param name="hostname">192.168.1.1</param>
                        <param name="port">3389</param>
                </connection>
        </authorize>
</user-mapping>

```
Y le damos los permisos a tomcat
```
chmod 600 user-mapping.xml
chown tomcat8:tomcat8 user-mapping.xml
```

Ahora vamos a proporcionar el proxy inverso para apache2, y apache será el que gestione guacamole, por lo que primero debemos instalarlo
```
apt install apache2
```

Según la página web de guacamole, esta no soporta apache2 con AJP, por lo que vamos a hacer que guacamole pase hacia el puerto http, primero debemos configurar el conector que debería estar así en el fichero /var/lib/tomcat8/conf/server.xml
```
<Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               URIEncoding="UTF-8"
               redirectPort="8443" />

```

Ahora vamos a configurar la ip remota, ya que lo necesitamos para que funcione Tomcat y Guacamole, vamos a /var/lib/tomcat8/conf/server.xml y ponemos
```
<Valve className="org.apache.catalina.valves.RemoteIpValve"
               internalProxies="127.0.0.1"
               remoteIpHeader="x-forwarded-for"
               remoteIpProxiesHeader="x-forwarded-by"
               protocolHeader="x-forwarded-proto" />
```

## Mod_proxy de apache2

Vamos a habilitar mod_proxy de apache2 con los siguientes comandos, así podremos habilitar el proxy inverso para guacamole
```
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_balancer
a2enmod lbmethod_byrequests
a2enmod proxy_wstunnel
```

Ahora vamos a realizar el virtualhost para configurar el proxy inverso.
```
<VirtualHost *:80>
    ProxyPreserveHost On
    ProxyRequests Off
    ServerName guacamole.alejandro.gonzalonazareno.org
    ProxyPass / http://localhost:8080/guacamole-1.0.0
    ProxyPassReverse / http://localhost:8080/guacamole-1.0.0
</VirtualHost>
```

Vamos a ver si podemos acceder al virtual host y entramos al panel para poder realizar una conexión SSH.
![](/images/Guacamole2.png)

![](/images/Guacamole3.png)


Ahora no podremos hacer login ya que necesitamos logearnos por una base de datos, por lo que tendremos que crear dicha base de datos, que la haremos en mariadb
```
apt install mariadb-server
```

Ahora debemos instalar en la página oficial https://guacamole.apache.org/releases/1.0.0/ el guacamole-auth-jdbc-1.0.0.tar.gz

Extraemos y entramos al apartado mysql y realizamos lo siguiente
```

```
	


