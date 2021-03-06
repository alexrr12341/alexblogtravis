+++
date = "2020-02-20"
title = "Implantación de aplicaciones web PHP en Docker"
math = "true"

+++

## Implantación de aplicaciones web PHP en Docker


### Ejecución de una aplicación web PHP en docke

Vamos a implantar una aplicación web basada en citas médicas, escrita en php.

Primero vamos a realizar la instalación de docker

```
apt install docker.io
```

Luego vamos a clonarnos el repositorio en nuestra máquina

```
git clone https://github.com/evilnapsis/bookmedik
```

Nuestro esquema será el siguiente:

2 contenedores->
	1-Base de datos mariadb
	2-Apache con módulo PHP

Vamos a borrar la línea en schema.sql de creación de la base de datos
```
create database bookmedik;
```

Vamos a crear primero una red para poder enlazar la base de datos y el apache
```
docker network create bookmedik
```

Primero de todo vamos a realizar el contenedor con los datos cargados de sql.

```
docker run -d --name servidor_mysql --network bookmedik -e MYSQL_DATABASE=bookmedik -e MYSQL_USER=bookmedik -e MYSQL_PASSWORD=bookmedik -e MYSQL_ROOT_PASSWORD=asdasd mariadb
```


Ahora vamos a cargar los datos en la base de datos

```
root@docker:~/practica/bookmedik# cat schema.sql | docker exec -i servidor_mysql /usr/bin/mysql -u root --password=asdasd bookmedik
```

Ahora vamos a crear el dockerfile para el contenedor que tendrá el apache con el modulo php

```
FROM debian
RUN apt-get update && apt-get install -y apache2 libapache2-mod-php7.3 php7.3 php7.3-mysql && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm /var/www/html/index.html
ENV APACHE_SERVER_NAME www.citasalexrr.com
ENV MARIADB_USER bookmedik
ENV MARIADB_PASS bookmedik
ENV MARIADB_HOST servidor_mysql

EXPOSE 80

COPY ./bookmedik /var/www/html
ADD script.sh /usr/local/bin/script.sh

RUN chmod +x /usr/local/bin/script.sh

CMD ["/usr/local/bin/script.sh"]


```

Ahora vamos a realizar script.sh

```
#!/bin/bash
sed -i 's/$this->user="root";/$this->user="'${MARIADB_USER}'";/g' /var/www/html/core/controller/Database.php
sed -i 's/$this->pass="";/$this->pass="'${MARIADB_PASS}'";/g' /var/www/html/core/controller/Database.php
sed -i 's/$this->host="localhost";/$this->host="'${MARIADB_HOST}'";/g' /var/www/html/core/controller/Database.php
apache2ctl -D FOREGROUND


```

Ahora hacemos la imagen
```
root@docker:~/practica# docker build -t alexrr12341/bookmedik:v1 .
```

Y hacemos ahora el contenedor

```
docker run -d --name bookmedik --network bookmedik -p 80:80 alexrr12341/bookmedik:v1
```

Miramos si podemos acceder al servicio

![](/images/Bookmedik1.png)


Ahora vamos a hacer un volumen en nuestro contenedor para los logs de apache2 y otro para los logs de apache2.

mariadb
```
docker run -d --name servidor_mysql --network bookmedik -v /opt/bbdd_mariadb:/var/lib/mysql -e MYSQL_DATABASE=bookmedik -e MYSQL_USER=bookmedik -e MYSQL_PASSWORD=bookmedik -e MYSQL_ROOT_PASSWORD=asdasd mariadb
```

logs apache2
```
docker run -d --name bookmedik --network bookmedik -v /opt/logs_apache2:/var/log/apache2 -p 80:80 alexrr12341/bookmedik:v1
```

Ejecutamos de vuelta el script de mariadb

```
cat schema.sql | docker exec -i servidor_mysql /usr/bin/mysql -u root --password=asdasd bookmedik
```

Vamos a observar el interior de las carpetas.

```
root@docker:~/practica# ls /opt/bbdd_mariadb/
aria_log.00000001  aria_log_control  bookmedik	ib_buffer_pool	ibdata1  ib_logfile0  ib_logfile1  ibtmp1  multi-master.info  mysql  performance_schema
  
root@docker:~/practica# ls /opt/logs_apache2/
access.log  error.log  other_vhosts_access.log

```

![](/images/Bookmedik2.png)

Ahora borramos los contenedores y volvemos a cargarlos
```
root@docker:~/practica/bookmedik# docker rm -f servidor_mysql
servidor_mysql
root@docker:~/practica/bookmedik# docker rm -f bookmedik
bookmedik
root@docker:~/practica/bookmedik# docker run -d --name servidor_mysql --network bookmedik -v /opt/bbdd_mariadb:/var/lib/mysql -e MYSQL_DATABASE=bookmedik -e MYSQL_USER=bookmedik -e MYSQL_PASSWORD=bookmedik -e MYSQL_ROOT_PASSWORD=asdasd mariadb
21c58a6514d347f14bffe7b1c4016e58a24b557ed630dc83380d0165fbf45548
root@docker:~/practica/bookmedik# docker run -d --name bookmedik --network bookmedik -v /opt/logs_apache2:/var/log/apache2 -p 80:80 alexrr12341/bookmedik:v1
bf36aa451fd4e168b32cd8fdaeb24067cf2606b3189b74c6555c7f9e0c71b56f

```

![](/images/Bookmedik3.png)

### Ejecución de una aplicación web PHP en docker

Ahora vamos a realizar el mismo ejercicio pero con una imagen de Php oficial

Nuestro Dockerfile será el siguiente:
```
FROM php:7.4.3-apache
ENV MARIADB_USER bookmedik
ENV MARIADB_PASS bookmedik
ENV MARIADB_HOST servidor_mysql2
RUN docker-php-ext-install pdo pdo_mysql mysqli json
RUN a2enmod rewrite
EXPOSE 80
WORKDIR /var/www/html
COPY ./bookmedik /var/www/html
ADD script.sh /usr/local/bin/script.sh

RUN chmod +x /usr/local/bin/script.sh

CMD ["/usr/local/bin/script.sh"]

```

El script que ejecutaremos en este caso sería el mismo que el anterior.

Vamos a realizar la imagen
```
docker build -t alexrr12341/bookmedikphp:v1 .
```

Y vamos a realizar la creación de los contenedores

```
docker run -d --name servidor_mysql2 --network bookmedik -v /opt/bbdd_mariadb:/var/lib/mysql -e MYSQL_DATABASE=bookmedik -e MYSQL_USER=bookmedik -e MYSQL_PASSWORD=bookmedik -e MYSQL_ROOT_PASSWORD=asdasd mariadb

docker run -d --name bookmedikphp --network bookmedik -v /opt/logs_apache2:/var/log/apache2 -p 80:80 alexrr12341/bookmedikphp:v1
```

Vemos que podemos acceder a la página.

![](/images/Bookmedik4.png)

Si queremos guardar la imagen en DockerHub realizamos el siguiente comando:

```
docker push alexrr12341/bookmedikphp:v1
```

La sintaxis sería:
```
docker push {usuarioDocker}/{NombreImagen}:{Version}
```

La imagen [Docker](https://hub.docker.com/repository/docker/alexrr12341/bookmedikphp) ya estaría subida.

Si queremos hacerlo con docker-compose, primero deberíamos instalarlo

```
apt install docker-compose
```

Y hacemos el fichero docker-compose.yml

```
version: '3.1'

services:
  bookmedikphp:
    container_name: bookmedikphp
    image: php:7.4.3-apache
    restart: always
    environment:
      MARIADB_USER: bookmedik
      MARIADB_PASS: bookmedik
      MARIADB_HOST: servidor_mysql2
    ports:
      - 80:80
    volumes:
      - /opt/logs_apache2:/var/log/apache2
      - ./script.sh:/usr/local/bin/script.sh
      - ./bookmedik:/var/www/html
    command: >
      bash /usr/local/bin/script.sh
  servidor_mysql2:
    container_name: servidor_mysql2
    image: mariadb
    restart: always
    environment:
      MYSQL_DATABASE: bookmedik
      MYSQL_USER: bookmedik
      MYSQL_PASSWORD: bookmedik
      MYSQL_ROOT_PASSWORD: asdasd
    volumes:
      - /opt/bbdd_mariadb:/var/lib/mysql

```

El script que ejecutaré en este caso será el siguiente:

```
#!/bin/bash
sed -i 's/$this->user="root";/$this->user="'${MARIADB_USER}'";/g' /var/www/html/core/controller/Database.php
sed -i 's/$this->pass="";/$this->pass="'${MARIADB_PASS}'";/g' /var/www/html/core/controller/Database.php
sed -i 's/$this->host="localhost";/$this->host="'${MARIADB_HOST}'";/g' /var/www/html/core/controller/Database.php
docker-php-ext-install pdo pdo_mysql mysqli json
apache2ctl -D FOREGROUND

```

Para ejecutarlos hacemos
```
docker-compose up -d
```

Y vemos que se están ejecutando los procesos y podemos entrar a la página
```

root@docker:~/practica2# docker-compose ps
     Name                    Command               State         Ports       
-----------------------------------------------------------------------------
bookmedikphp      docker-php-entrypoint bash ...   Up      0.0.0.0:80->80/tcp
servidor_mysql2   docker-entrypoint.sh mysqld      Up      3306/tcp     

```

![](/images/Bookmedik5.png)

### Ejecución de una aplicación PHP en docker

Ahora vamos a crear un escenario con nginx(bookmedik)+php-fpm+mariadb, por lo que cada uno tendrá su propio contenedor, y compartirán información para que puedan conectarse entre ellos.
Para ello vamos a crear un docker-compose que contenga toda la información:

```
version: '3.1'
services:
  bookmedik:
    image: nginx:latest
    container_name: bookmedik
    restart: always
    ports:
      - 80:80
    volumes:
      - ./bookmedik:/var/www/html
      - ./default.conf:/etc/nginx/conf.d/default.conf
  php:
    image: php:7.4.3-fpm-buster
    container_name: php-fpm
    restart: always
    environment:
      MARIADB_USER: bookmedik
      MARIADB_PASS: bookmedik
      MARIADB_HOST: servidor_mysql2
    volumes:
      - ./bookmedik:/var/www/html
      - ./script.sh:/usr/local/bin/script.sh
    command: bash /usr/local/bin/script.sh
  servidor_mysql2:
    image: mariadb
    container_name: servidor_mysql2
    restart: always
    environment:
      MYSQL_DATABASE: bookmedik
      MYSQL_USER: bookmedik
      MYSQL_PASSWORD: bookmedik
      MYSQL_ROOT_PASSWORD: asdasd
    volumes:
      - /opt/bbdd_mariadb:/var/lib/mysql
```

Y el script que ejecutaremos en php-fpm será el siguiente:

```
#!/bin/bash
sed -i 's/$this->user="root";/$this->user="'${MARIADB_USER}'";/g' /var/www/html/core/controller/Database.php
sed -i 's/$this->pass="";/$this->pass="'${MARIADB_PASS}'";/g' /var/www/html/core/controller/Database.php
sed -i 's/$this->host="localhost";/$this->host="'${MARIADB_HOST}'";/g' /var/www/html/core/controller/Database.php
docker-php-ext-install pdo pdo_mysql mysqli json
php-fpm
```

El default.conf que copiaremos será el siguiente:
```
server {
    index index.php index.html;
    server_name php-docker.local;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/html;

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php-fpm:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

Ejecutamos docker-compose
```
root@docker:~/practica3# docker-compose up -d
Starting php-fpm         ... done
Starting servidor_mysql2 ... done
Starting bookmedik       ... done

```

Vemos que todos están escuchando en los puertos correspondientes
```
root@docker:~/practica3# docker-compose ps
     Name                    Command               State         Ports       
-----------------------------------------------------------------------------
bookmedik         nginx -g daemon off;             Up      0.0.0.0:80->80/tcp
php-fpm           docker-php-entrypoint bash ...   Up      9000/tcp          
servidor_mysql2   docker-entrypoint.sh mysqld      Up      3306/tcp   
```

Y que podemos acceder.

![](/images/Bookmedikfpm.png)


### Ejecución de un CMS en docker

Ahora vamos a realizar un contenedor que contenga Drupal, que estará en una imagen base de debian y otro contenedor que contenga la base de datos mariadb

Primero de todo nos descargamos drupal en nuestro ordenador.

```
wget https://www.drupal.org/download-latest/zip
```

```
unzip zip
```

Tendremos una carpeta drupal
```
root@docker:~/practica4# ls
Dockerfile  drupal-8.8.2  zip
```

Y para crear el contenedor crearemos un dockerfile con la siguiente información:

```
FROM debian
RUN apt-get update && apt-get install -y apache2 libapache2-mod-php7.3 php7.3 php7.3-mysql php-dom php-xml php-gd php-mbstring && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm /var/www/html/index.html
EXPOSE 80
COPY ./drupal-8.8.2 /var/www/html
ADD script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh
RUN chmod a+w /var/www/html/sites/default/files
RUN cp /var/www/html/sites/default/default.settings.php /var/www/html/sites/default/settings.php
RUN chmod a+w /var/www/html/sites/default/settings.php
RUN a2enmod rewrite 
CMD ["/usr/local/bin/script.sh"]

```

El script que ejecutaremos será el siguiente
```
#!/bin/bash
sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf
apache2ctl -D FOREGROUND
```

Ahora creamos una red para conectar la base de datos con drupal
```
root@docker:~/practica4# docker network create drupal
```

Creamos la imagen:

```
docker build -t alexrr12341/drupal:v1 .
```

Vamos a lanzar la base de datos
```
docker run -d --name servidor_mysql4 --network drupal -v /opt/bbdd_drupal2:/var/lib/mysql -e MYSQL_DATABASE=drupal -e MYSQL_USER=drupal -e MYSQL_PASSWORD=drupal -e MYSQL_ROOT_PASSWORD=asdasd mariadb
```

Y lanzamos la aplicación drupal
```
docker run -d --name drupal --network drupal -v drupal1:/var/www/html -p 80:80 alexrr12341/drupal:v1
```

Vamos ahora a instalar drupal mediante el panel web

![](/images/Drupal.png)
![](/images/Drupal2.png)

Vamos a borrar los contenedores y vamos a comprobar que drupal sigue con la información:

```
docker rm -f servidor_mysql4
docker rm -f drupal
```

Y iniciamos los servicios
```
docker run -d --name servidor_mysql4 --network drupal -v /opt/bbdd_drupal2:/var/lib/mysql -e MYSQL_DATABASE=drupal -e MYSQL_USER=drupal -e MYSQL_PASSWORD=drupal -e MYSQL_ROOT_PASSWORD=asdasd mariadb
docker run -d --name drupal --network drupal -v drupal1:/var/www/html -p 80:80 alexrr12341/drupal:v1
```
![](/images/Drupal3.png)


### Ejecución de un CMS en docker(Imágen oficial)

Vamos ahora a instalar un nextcloud mediante la imagen oficial

Para ello instalamos nextcloud
```
docker pull nextcloud
```

Creamos el docker-compose para ambos contenedores
```
version: '3.1'
services:
  nextcloud:
    image: nextcloud
    container_name: nextcloud
    restart: always
    ports:
      - 80:80
    environment:
      POSTGRES_DB: nextcloud
      POSTGRES_USER: nextcloud
      POSTGRES_PASSWORD: nextcloud
      POSTGRES_HOST: postgres_next
    volumes:
      - /opt/nextcloud:/var/www/html
  postgres_next:
    image: postgres
    container_name: postgres_next
    restart: always
    environment:
      POSTGRES_USER: nextcloud
      POSTGRES_DB: nextcloud
      POSTGRES_PASSWORD: nextcloud
    volumes:
      - /opt/bbdd_nextcloud:/var/lib/postgresql


```

Y activamos el docker-compose
```
root@docker:~/practica5# docker-compose up -d


root@docker:~/practica5# docker-compose ps
    Name                   Command               State         Ports       
---------------------------------------------------------------------------
nextcloud       /entrypoint.sh apache2-for ...   Up      0.0.0.0:80->80/tcp
postgres_next   docker-entrypoint.sh postgres    Up      5432/tcp 
```


Como tenemos las variables de entorno configuradas solo tenemos que introducir el usuario con privilegios para nextcloud y su contraseña

![](/images/Nextcloud.png)

![](/images/Nextcloud2.png)

![](/images/Nextcloud3.png)

