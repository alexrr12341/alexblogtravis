+++
date = "2020-04-24"
title = "Implantación de Aplicaciones Web Python en Docker"
math = "true"

+++

## Implantación de Aplicaciones Web Python en Docker

## Ejecución de una aplicación web Python en docker

### Parte 1

Vamos a implantar la aplicación web escrita en python gestion IESGN.

Para ello nos vamos a clonar el repositorio

```
root@docker:~/escenario1/gestion# git clone https://github.com/jd-iesgn/iaw_gestionGN


```

También debemos instalar docker, para ello

```
apt install docker.io
```


Vamos a editar el fichero settings.py para que pueda observar la base de datos
```
ALLOWED_HOSTS = ['192.168.1.38']
...
...
DATABASES = {
      'default': {
          'ENGINE': 'mysql.connector.django',
          'NAME': 'iesgn',
          'USER': 'iesgn',
          'PASSWORD': 'iesgn',
          'HOST': 'mariadb',
          'PORT': '',
      }
  }
```


Nuestro Dockerfile tendrá el siguiente contenido:

```

FROM debian
RUN apt-get update && apt-get install -y apache2 libapache2-mod-wsgi-py3 python3-pip python3-mysqldb zlib1g-dev libjpeg62-turbo-dev && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip3 install mysql-connector-python
RUN rm /var/www/html/index.html
EXPOSE 80

COPY ./iaw_gestionGN /var/www/html
COPY ./000-default.conf /etc/apache2/sites-available
RUN pip3 install -r /var/www/html/iaw_gestionGN/requirements.txt
RUN cp -r /usr/local/lib/python3.7/dist-packages/django/contrib/admin/static/admin/ /var/www/html/iaw_gestionGN/static
RUN chown -R www-data: /var/www/html/iaw_gestionGN
ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
```

El fichero 000-default.conf será el siguiente:
```
<VirtualHost *:80>
    DocumentRoot /var/www/html/iaw_gestionGN
    WSGIDaemonProcess iaw_gestionGN user=www-data group=www-data processes=1 threads=5 python-path=/var/www/html/iaw_gestionGN
    WSGIScriptAlias / /var/www/html/iaw_gestionGN/gestion/wsgi.py

    <Directory /var/www/html/iaw_gestionGN>
            WSGIProcessGroup iaw_gestionGN
            WSGIApplicationGroup %{GLOBAL}
            Require all granted
    </Directory>
    Alias "/static/" "/var/www/html/iaw_gestionGN/static/"
</VirtualHost>
```

Vamos a crear una network para que ambos se puedan ver

```
docker network create iesgn
```	

Vamos a lanzar una base de datos mariadb

```
docker run -d --name mariadb --network iesgn -v /opt/bbdd_mariadb:/var/lib/mysql -e MYSQL_DATABASE=iesgn -e MYSQL_USER=iesgn -e MYSQL_PASSWORD=iesgn -e MYSQL_ROOT_PASSWORD=asdasd mariadb
```


Vamos a montar la imagen

```
docker build -t alexrr12341/iaw_gestion:v1 .

```


Ahora corremos el contenedor

```
docker run -d --name iesgn --network iesgn -p 80:80 alexrr12341/iaw_gestion:v1
```

Ahora simplemente tendremos que ejecutar el comando para la migración

```
docker exec iesgn python3 /var/www/html/iaw_gestionGN/manage.py migrate
```


Y entramos a la página

![](/images/dockerpython1.png)
![](/images/dockerpython2.png)



### Parte 2

Ahora vamos a realizar la imagen desde la oficial de python.


Partiendo del escenario anterior, vamos a realizar el Dockerfile para la imagen que ejecutaremos para el compose.

```
FROM python:3
WORKDIR /usr/src/app
RUN pip3 install mysql-connector-python
COPY ./gestion/iaw_gestionGN/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY ./gestion/iaw_gestionGN .
EXPOSE 8000
CMD ["python", "manage.py", "collectstatic"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

Hacemos la imagen

```
docker build -t alexrr12341/iaw_gestion:v2 .
```

Ahora como necesitamos docker-compose hacemos la instalación

```
apt install docker-compose
```

Nuestro docker-compose.yml tendrá el siguiente contenido
```
version: '3.1'

services:
  mariadb:
    container_name: mariadb
    image: mariadb
    restart: always
    environment:
      MYSQL_DATABASE: iesgn
      MYSQL_USER: iesgn
      MYSQL_PASSWORD: iesgn
      MYSQL_ROOT_PASSWORD: asdasd
    volumes:
      - /opt/bbdd_mariadb:/var/lib/mysql
  iesgn:
    container_name: iesgn
    image: alexrr12341/iaw_gestion:v2
    restart: always
    depends_on:
      - mariadb
    ports:
      - 8000:8000

```

Y lo ejecutamos con el siguiente comando

```
docker-compose up -d
```

Para hacer la migración, realizamos el comando que hicimos en el escenario anterior

```
docker exec iesgn python3 /usr/src/app/manage.py migrate
```

Observamos que esté funcionando correctamente.

```
 Name                Command               State           Ports         
-------------------------------------------------------------------------
iesgn     python manage.py runserver ...   Up      0.0.0.0:8000->8000/tcp
mariadb   docker-entrypoint.sh mysqld      Up      3306/tcp     
```

![](/images/dockerpython3.png)

![](/images/dockerpython4.png)


### Parte 3

Ahora vamos a hacer un docker compose que contenga:
- La imagen Nginx con nuestra aplicación
- Una imagen con uwsgi 
- Una imagen con la base de datos mariadb


Primero de todo vamos a crear la imagen de iesgn con la imagen oficial de nginx, para eso hacemos el siguiente Dockerfile:

```
FROM nginx
WORKDIR /var/www/html
RUN apt-get update && apt-get install -y python3-pip python3-mysqldb zlib1g-dev libjpeg62-turbo-dev && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN pip3 install mysql-connector-python
COPY ./gestion/iaw_gestionGN/requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt
EXPOSE 80
CMD ["python3", "manage.py", "collectstatic"]
CMD ["nginx", "-g", "daemon off;"]

```

Haremos la imagen de iesgn con el siguiente comando:

```
docker build -t alexrr12341/iaw_gestion:v3 .
```


Tambien vamos a crear una imagen  para la instalación de gunicorn
```
FROM debian
WORKDIR /var/www/html
RUN apt-get update && apt-get install -y uwsgi uwsgi-plugin-python3 python3-pip python3-mysqldb zlib1g-dev libjpeg62-turbo-dev && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN pip3 install mysql-connector-python
COPY ./gestion/iaw_gestionGN/requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt
EXPOSE 8080


```
Y la hacemos con el siguiente comando:

```
docker build -t alexrr12341/uwsgi:v1 .
```

Y hacemos el docker-compose para el despliegue:

```
version: '3.1'

services:
  mariadb:
    container_name: mariadb
    image: mariadb
    restart: always
    environment:
      MYSQL_DATABASE: iesgn
      MYSQL_USER: iesgn
      MYSQL_PASSWORD: iesgn
      MYSQL_ROOT_PASSWORD: asdasd
    volumes:
      - /opt/bbdd_mariadb:/var/lib/mysql
  iesgn:
    container_name: iesgn
    image: alexrr12341/iaw_gestion:v3
    restart: always
    depends_on:
      - mariadb
      - uwsgi
    ports:
      - 80:80
    volumes:
    - ./gestion/iaw_gestionGN:/var/www/html
    - ./default.conf:/etc/nginx/conf.d/default.conf
  uwsgi:
    container_name: uwsgi
    image: alexrr12341/uwsgi:v1
    restart: always
    volumes:
    - ./gestion/iaw_gestionGN:/var/www/html
    command: uwsgi --http-socket :8080 --plugin python37 --chdir /var/www/html --wsgi-file gestion/wsgi.py --process 4 --threads 2 --master 
```

Y observamos que va correctamente la página.

```
 Name                Command               State         Ports       
---------------------------------------------------------------------
iesgn     nginx -g daemon off;             Up      0.0.0.0:80->80/tcp
mariadb   docker-entrypoint.sh mysqld      Up      3306/tcp          
uwsgi     uwsgi --http-socket :8080  ...   Up      8080/tcp  
```

![](/images/dockerpython5.png)

![](/images/dockerpython6.png)




### Parte 4

Ahora vamos a crear una imagen con el CMS "django CMS", ejecutaremos el contenedor y observaremos si funciona correctamente.

Vamos primero a instalarnos el cms django en nuestro ordenador para copiarlo en el nuevo contenedor, para ello hacemos:


Para ello haremos el siguiente Dockerfile:

```
FROM python:3
WORKDIR /usr/src/app
RUN apt-get update && apt-get install -y python3-mysqldb zlib1g-dev libjpeg62-turbo-dev && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN pip3 install mysql-connector-python
RUN pip3 install djangocms-installer
EXPOSE 8000
RUN djangocms mysite
RUN pip3 install -r /usr/src/app/mysite/requirements.txt
COPY ./script.sh /tmp
RUN chmod +x /tmp/script.sh
RUN /tmp/script.sh
CMD ["python3", "/usr/src/app/mysite/manage.py", "migrate"]
CMD ["python3", "/usr/src/app/mysite/manage.py", "runserver", "0.0.0.0:8000"]
``` 

El script que ejecutaremos en este caso será el siguiente:

```
#!/bin/bash
sed -i 's/project.db/mysite\/project.db/g' /usr/src/app/mysite/mysite/settings.py
sed -i 's/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \["192.168.1.38"\]/g' /usr/src/app/mysite/mysite/settings.py

```

Comprobamos el funcionamiento de la página:

![](/images/dockerpython7.png)
![](/images/dockerpython8.png)
