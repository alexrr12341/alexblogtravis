+++
date = "2019-12-10"
title = "Como instalar un CMS de Python en Centos 8 con Gunicorn/Nginx"
math = "true"

+++


Vamos primero a hacer nuestro entorno virtual
```
python3 -m venv mezzanine
alexrr@pc-alex:~/pythonvirtual$ source mezzanine/bin/activate
(mezzanine) alexrr@pc-alex:~/pythonvirtual$ 
```

Ahora vamos a instalar mezzanine con pip
```
pip install mezzanine
```

Ahora vamos a movernos a una carpeta, por ejemplo mezzanine y nos vamos a hacer un requirements.txt
```
pip freeze > requirements.txt
```
Y borramos la línea del requirements.txt de pkg-resources:
```
pkg-resources==0.0.0
```

Y ahora vamos a hacer el proyecto de mezzanine
```
mezzanine-project pythoncms
```

Y vamos a crear la base de datos
```
(mezzanine) alexrr@pc-alex:~/mezzanine/pythoncms$ python3 manage.py migrate
Operations to perform:
  Apply all migrations: admin, auth, blog, conf, contenttypes, core, django_comments, forms, galleries, generic, pages, redirects, sessions, sites, twitter
...
```

Y creamos el super user
```
(mezzanine) alexrr@pc-alex:~/mezzanine/pythoncms$ python3 manage.py createsuperuser

Creating default account ...

Username (leave blank to use 'alexrr'): 
Email address: alexrodriguezrojas98@gmail.com
Password: 
Password (again): 
Superuser created successfully.
```


Y ahora abrimos el servidor
```
(mezzanine) alexrr@pc-alex:~/mezzanine/pythoncms$ python3 manage.py runserver
```

Y miramos la página:

![](/images/mezzanine.png)

Cambiamos el nombre de la página:

![](/images/mezzanine2.png)


Vamos ahora a cambiar el tema de la página.
```
git clone https://github.com/thecodinghouse/mezzanine-themes
```

Y en el settings.py ponemos
```
INSTALLED_APPS = (
	"flat",
	...
)
```

*Importante poner la carpeta flat,nova,etc dentro de nuestra carpeta de desarrollo*

![](/images/mezzanine3.png)

Ahora vamos a trasladarlo a nuestro entorno de producción.

Vamos a guardar los archivos en un fichero .json
```
(mezzanine) alexrr@pc-alex:~/mezzanine/pythoncms$ python3 manage.py dumpdata > db.json
```

Ahora lo vamos a subir a github
```
git init
git add *
git commit -m "Añadir pythoncms"
git remote add origin git@github.com:alexrr12341/pythoncms.git
git push -u origin master
```

-Realiza el despliegue de la aplicación en tu entorno de producción (servidor web y servidor de base de datos en el cloud). Utiliza un entorno virtual. Como servidor de aplicación puedes usar gunicorn o uwsgi (crea una unidad systemd para gestionar este servicio). La aplicación será accesible en la url python.tunombre.gonzalonazareno.org.

Primero de todo vamos a clonar nuestro repositorio de pythoncms en nuestro /var/www
```
[root@salmorejo www]# git clone https://github.com/alexrr12341/pythoncms
```

Ahora en la máquina croqueta vamos a añadir el registro DNS para python (/var/cache/bind/db.gonzalonazareno.org)
```
python          IN      CNAME   salmorejo
```

Volvemos a salmorejo, necesitamos gunicorn para que funcione nuestro cms ya que estamos utilizando nginx, por lo que vamos a instalarlo.

Primero necesitamos instalar python36
```
dnf install python36 python36-devel
```

Y ponemos nuestro entorno virtual
```
[root@salmorejo ~]# python3.6 -m venv entorno

[root@salmorejo ~]# source entorno/bin/activate
(entorno) [root@salmorejo ~]# 
```

Y instalamos los requirements.txt
```
(entorno) [root@salmorejo pythoncms]# pip install -r requirements.txt 
```

Ahora vamos a crear la base de datos en nuestra máquina tortilla y un usuario para que tenga privilegios sobre dicha base de datos
```
MariaDB [(none)]> CREATE DATABASE pythoncms;
MariaDB [(none)]> CREATE USER python identified by 'python';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON pythoncms.* to python;
MariaDB [(none)]> flush privileges;
```

*Importante:*
Si te salta un error de max size a la hora de hacer el migrate ponemos esto en la base de datos
```
MariaDB [pythoncms]> SET @@global.innodb_large_prefix = 1;
MariaDB [pythoncms]> set global innodb_default_row_format = DYNAMIC;
```

Ahora tenemos que modificar el settings.py para que coja nuestra base de datos mysql

Metemos los datos de la base de datos en settings.py
```
DATABASES = {
      'default': {
          'ENGINE': 'mysql.connector.django',
          'NAME': 'pythoncms',
          'USER': 'python',
          'PASSWORD': 'python',
          'HOST': 'tortillaint.alejandro.gonzalonazareno.org',
          'PORT': '',
      }
  }
```

Vamos a configurar el host para que podamos acceder mediante el dns en settings.py
```
ALLOWED_HOSTS = ['python.alejandro.gonzalonazareno.org']
```

Vamos a instalar también el conector de mysql para python
```
pip install mysql-connector-python
```

Vamos ahora a realizar la migración
```
python3 manage.py migrate
```

Ahora vamos a cargar los datos en manage.py
```
python36 manage.py loaddata db.json
Installed 157 object(s) from 1 fixture(s)
```

Ahora vamos a instalar guicorn en pip
```
pip install gunicorn
```

Vamos a crear el socket de gunicorn para poder ejecutarlo en nginx en /etc/systemd/system/gunicorn.socket
```
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target

```

Ahora vamos a crear la unidad systemd para guincorn en /etc/systemd/system/gunicorn.service
```
sudo nano /etc/systemd/system/gunicorn.service

[Unit]
Description=gunicorn daemon
After=network.target

[Service]
WorkingDirectory=/var/www/pythoncms
ExecStart=/bin/bash /var/www/pythoncms/gunicorn_start
ExecReload=/bin/bash /var/www/pythoncms/gunicorn_start
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

```

Y el script que ejecutará será el siguiente
```
#!/bin/bash

NAME="pythoncms"
DJANGODIR=/var/www/pythoncms
USER=nginx
GROUP=nginx
WORKERS=3
BIND=unix:/run/gunicorn.sock
DJANGO_SETTINGS_MODULE=pythoncms.settings
DJANGO_WSGI_MODULE=pythoncms.wsgi
LOGLEVEL=error

cd $DJANGODIR
source /var/www/pythoncms/paquetes/bin/activate

export DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE
export PYTHONPATH=$DJANGODIR:$PYTHONPATH

exec /var/www/pythoncms/paquetes/bin/gunicorn ${DJANGO_WSGI_MODULE}:application \
  --name $NAME \
  --workers $WORKERS \
  --user=$USER \
  --group=$GROUP \
  --bind=$BIND \
  --log-level=$LOGLEVEL \
  --log-file=-
```

Vamos a habilitar las reglas de SELinux para la página
```
chcon -t httpd_sys_rw_content_t /var/www/pythoncms -R
```


El virtual host de mezzanine sería el siguiente
```
server {
        listen 80;
        server_name python.alejandro.gonzalonazareno.org;
        return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    ssl_certificate /etc/nginx/cert/salmorejo.alejandro.gonzalonazareno.org.crt;
    ssl_certificate_key /etc/nginx/cert/salmorejo.alejandro.gonzalonazareno.org.key;
    server_name python.alejandro.gonzalonazareno.org;
    root /var/www/pythoncms;
    location / {
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header Host $http_host;
      # we don't want nginx trying to do something clever with
      # redirects, we set the Host: header above already.
      proxy_redirect off;
      proxy_pass http://unix:/run/gunicorn.sock;
    }
    location /static {
        alias /var/www/pythoncms/static;
    }
}
```

Para que salga los static debemos hacer:

```
chown -R centos:centos /var/www/pythoncms
python3 manage.py collectstatic
chown -R nginx:nginx /var/www/pythoncms
```

Y si tenemos un theme, meterlo dentro de la carpeta /static creada

![](/images/mezzaninecloud.png)
![](/images/mezzaninecloud1.png)
![](/images/mezzaninecloud3.png)
