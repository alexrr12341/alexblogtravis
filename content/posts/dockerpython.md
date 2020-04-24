+++
date = "2020-04-24"
title = "Implantación de Aplicaciones Web Python en Docker"
math = "true"

+++

## Implantación de Aplicaciones Web Python en Docker

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


