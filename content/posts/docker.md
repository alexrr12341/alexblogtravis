+++
date = "2020-02-20"
title = "Primeros pasos de Hugo"
math = "true"

+++

## Implantación de aplicaciones web PHP en Docker

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



