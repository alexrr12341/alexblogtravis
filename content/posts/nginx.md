+++
date = "2019-12-10"
title = "Servidor Nginx"
math = "true"

+++

*Tarea 1 (1 punto)(Obligatorio): Crea un escenario Vagrant o utiliza una máquina del cloud con una red pública. Instala el servidor web nginx en la máquina. Modifica la página index.html que viene por defecto y accede a ella desde un navegador. Entrega una captura de pantalla accediendo a ella.*

```
Vagrant.configure("2") do |config|
  config.vm.define :nginx do |nginx|
        nginx.vm.box = "debian/buster64"
        nginx.vm.hostname = "local"
        nginx.vm.network :public_network,:bridge=>"wlp0s20f3"
        nginx.vm.network :private_network, ip: "10.1.1.103", virtualbox__intnet: "apache"
  end
end
```
```
apt install nginx
```
![](/images/capturanginx.png)


*Tarea 2 (1 punto)(Obligatorio): Configura la resolución estática en los clientes y muestra el acceso a cada una de las páginas.*

Configuramos el virtualhost iesgn y departamentos en /etc/nginx/sites-available

iesgn:
```
server {
        listen 80 default_server;

        root /srv/www/iesgn;

        index index.html index.htm index.nginx-debian.html;

        server_name www.iesgn.org;

        location / {
                try_files $uri $uri/ =404;
        }

}
```

departamentos:

```
server {
        listen 80;


        root /srv/www/departamentos;

        index index.html index.htm index.nginx-debian.html;

        server_name www.departamentos.iesgn.org;

        location / {
                try_files $uri $uri/ =404;
        }

}
```

```
sudo ln -s /etc/nginx/sites-available/iesgn /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/departamentos /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

Ya simplemente crearemos las carpetas
```
mkdir /srv/www
mkdir /srv/www/iesgn
mkdir /srv/www/departamentos
```

![](/images/iesgnnginx.png)
![](/images/departamentosnginx.png)

*Tarea 3 (1 punto)(Obligatorio): Cuando se entre a la dirección www.iesgn.org se redireccionará automáticamente a www.iesgn.org/principal, donde se mostrará el mensaje de bienvenida. En el directorio principal no se permite ver la lista de los ficheros, no se permite que se siga los enlaces s en imbólicos y no se permite negociación de contenido. Muestra al profesor el funcionamiento.*

Creamos la carpeta principal
```
vagrant@local:/srv/www/iesgn$ sudo mkdir principal
vagrant@local:/srv/www/iesgn/principal$ sudo mv ../index.nginx-debian.html .
```


Y en nuestro virtualhost añadimos la siguiente línea
```
rewrite ^/$ /principal;
```
Reiniciamos el servicio
```
systemctl restart nginx
```

En el fichero iesgn añadimos las siguientes líneas:
```
location /principal {
                autoindex off;
                disable_symlinks on;
                try_files $uri $uri/ =404;
        }
```

*Tarea 4 (1 punto)(Obligatorio): Si accedes a la página www.iesgn.org/principal/documentos se visualizarán los documentos que hay en /srv/doc. Por lo tanto se permitirá el listado de fichero y el seguimiento de enlaces simbólicos siempre que sean a ficheros o directorios cuyo dueño sea el usuario. Muestra al profesor el funcionamiento.*

Primero creamos la carpeta
```
mkdir /srv/doc
```
También crearemos ficheros de prueba.

Y para hacer que se permita el listado de ficheros,seguimientos de enlaces simbólicos del dueño  y el alias, añadimos las siguientes líneas en nuestro iesgn.
```
location /principal/documentos {
                alias   /srv/doc;
                autoindex on;
                disable_symlinks if_not_owner;
        }
```

*Tarea 5 (1 punto): En todo el host virtual se debe redefinir los mensajes de error de objeto no encontrado y no permitido. Para el ello se crearan dos ficheros html dentro del directorio error. Entrega las modificaciones necesarias en la configuración y una comprobación del buen funcionamiento.*

Creamos la carpeta error
```
mkdir /srv/error
```

En nuestro virtualhost añadimos la localización en nuestro virtualhost y el error

```
 error_page 404 /404.html;
        location = /404.html {
                root /srv/error;
                internal;
        }
        error_page 403 /403.html;
        location = /403.html {
                root /srv/error;
                internal;
        }
```

![](/images/error404.png)
![](/images/error403.png)

*Tarea 6 (1 punto)(Obligatorio): Añade al escenario Vagrant otra máquina conectada por una red interna al servidor. A la URL departamentos.iesgn.org/intranet sólo se debe tener acceso desde el cliente de la red local, y no se pueda acceder desde la anfitriona por la red pública. A la URL departamentos.iesgn.org/internet, sin embargo, sólo se debe tener acceso desde la anfitriona por la red pública, y no desde la red local.*

Crearemos la carpeta intranet e internet
```
mkdir /srv/www/departamentos/intranet
mkdir /srv/www/departamentos/internet
```

Y en nuestro virtualhost de departamentos añadimos las siguientes lineas:

```
location /intranet {
                allow 10.1.1.0/24;
                deny all;
        }
location /internet {
                allow 172.22.0.1/16;
                deny all;
        }
```


Internet:
![](/images/pruebainternetfuera.png)
![](/images/pruebainternetdentro.png)
Intranet:
![](/images/pruebaintranetfuera.png)
![](/images/pruebaintranetdentro.png)


*Tarea 7 (1 punto): Autentificación básica. Limita el acceso a la URL departamentos.iesgn.org/secreto. Comprueba las cabeceras de los mensajes HTTP que se intercambian entre el servidor y el cliente. ¿Cómo se manda la contraseña entre el cliente y el servidor?. Entrega una breve explicación del ejercicio.*

Creamos la carpeta secreto en departamentos
```
mkdir /srv/www/departamentos/secreto
```

Vamos a la configuración de departamento y añadimos las siguientes líneas:

```
location /secreto {
                auth_basic      "Acceso restringido";
                auth_basic_user_file    "/etc/nginx/claves/htpasswd";
        }
```

Y hacemos el fichero htpassword

```
mkdir /etc/nginx/claves

sudo sh -c "echo -n 'usuario:' >> /etc/nginx/claves/htpasswd"
sudo sh -c "openssl passwd -apr1 >> /etc/nginx/claves/htpasswd"
```

Y ya debería funcionar:

![](/images/imagenht.png)
![](/images/imagenht2.png)


![](/images/cabeceras.png)


En Authorization: Basic dXN1YXJpbzp1c3Vhcmlv está en base64 con el siguiente formado "usuario:contraseña"


*Tarea 9 (1 punto): Vamos a combinar el control de acceso (tarea 6) y la autentificación (tareas 7 y 8), y vamos a configurar el virtual host para que se comporte de la siguiente manera: el acceso a la URL departamentos.iesgn.org/secreto se hace forma directa desde la intranet, desde la red pública te pide la autentificación. Muestra el resultado al profesor.*
Para hacer esta tarea, debemos entrar en nuestro virtual host y poner las siguientes líneas
```
location /secreto {
		satisfy any;
		allow 10.1.1.0/24;
		deny all;
                auth_basic      "Acceso restringido";
                auth_basic_user_file    "/etc/nginx/claves/htpasswd";
        }
```
Ahora comprobaremos si está funcionando

local:
![](/images/localnginx.png)
Internet:
![](/images/internetnginx.png)

