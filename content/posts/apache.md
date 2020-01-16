+++
date = "2019-12-10"
title = "Servidor Apache2"
math = "true"

+++

*Tarea 1 (1 punto)(Obligatorio): Crea un escenario Vagrant con una máquina con una red pública o utiliza una máquina del cloud. Instala el servidor web Apache2 en la máquina. Modifica la página index.html que viene por defecto y accede a ella desde un navegador. Entrega una captura de pantalla accediendo a ella.*
```
apt install apache2
```
En /var/www/html editamos el fichero index.html y accedemos a la IP de la máquina en nuestro navegador
![](/images/Apache.png)

*Tarea 2 (2 puntos)(Obligatorio): Configura la resolución estática en los clientes y muestra el acceso a cada una de las páginas.*

Primero de todo creamos el escenario con las carpetas
```
mkdir /srv/www
mkdir /srv/www/iesgn
mkdir /srv/www/departamentos
chown -R www-data:www-data /srv/www
```

En /etc/apache2/apache2.conf ponemos la siguiente linea
```
<Directory /srv/www/>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
</Directory>
```

Y en /etc/apache2/sites-available hacemos
```
cp 000-default.conf iesgn.conf
cp 000-default.conf departamentos.conf
```

iesgn.conf:

```
<VirtualHost *:80>
        ServerName www.iesgn.org

        ServerAdmin webmaster@localhost
        DocumentRoot /srv/www/iesgn


        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>

```

departamentos.conf:
```
<VirtualHost *:80>
        ServerName www.departamentos.iesgn.org

        ServerAdmin webmaster@localhost
        DocumentRoot /srv/www/departamentos


        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>

```

Ahora habilitamos los sitios
```
a2ensite iesgn
a2ensite departamentos
systemctl restart apache2
```

Para acceder a los virtual host debemos poner el DNS en nuestra máquina en /etc/hosts


![](/images/iesgn.png)

![](/images/departamentos.png)

*Tarea 3 (1 punto)(Obligatorio): Cuando se entre a la dirección www.iesgn.org se redireccionará automáticamente a www.iesgn.org/principal, donde se mostrará el mensaje de bienvenida. En el directorio principal no se permite ver la lista de los ficheros, no se permite que se siga los enlaces simbólicos y no se permite negociación de contenido. Muestra al profesor el funcionamiento.*

Creamos la carpeta principal
```
root@mongo:/srv/www/iesgn# mkdir principal
root@mongo:/srv/www/iesgn# mv index.html principal/
```

Y vamos a nuestro fichero de configuración del virtualhost y añadimos la siguiente linea
```
        RedirectMatch ^/$ /principal
```

Y reiniciamos el servicio
```
systemctl restart apache2
```

En el fichero iesgn.conf añadimos las siguientes líneas
```
<Directory /srv/www/iesgn/principal>
                Options -Indexes -FollowSymLinks -Multiviews
</Directory>
```

*Tarea 4 (1 punto)(Obligatorio): Si accedes a la página www.iesgn.org/principal/documentos se visualizarán los documentos que hay en /srv/doc. Por lo tanto se permitirá el listado de fichero y el seguimiento de enlaces simbólicos siempre que sean a ficheros o directorios cuyo dueño sea el usuario. Muestra al profesor el funcionamiento.*

Hacemos el directorio /srv/doc y añadimos algun fichero de prueba
```
mkdir /srv/doc
echo "hola" > prueba.txt
```

Editamos ahora /etc/apache2/sites-available/iesgn.conf y añadimos las siguientes lineas
```
     Alias "/principal/documentos" "/srv/doc"
        <Directory /srv/doc>
                Options +Indexes +SymLinksIfOwnerMatch
                Require all granted
        </Directory>
```


*Tarea 5 (1 punto): En todo el host virtual se debe redefinir los mensajes de error de objeto no encontrado y no permitido. Para el ello se crearan dos ficheros html dentro del directorio error. Entrega las modificaciones necesarias en la configuración y una comprobación del buen funcionamiento.*

Añadimos las siguientes líneas de código para añadir los errores en nuestro virtual host
```
     <Directory /srv/error>
                Options +Indexes +FollowSymLinks
                AllowOverride All
                Require all granted
        </Directory>
        Alias /error /srv/error
```

El error 404 lo añadimos así
```
        ErrorDocument 404 /error/404.html
```
El error 403 lo añadimos así
```
        ErrorDocument 403 /error/403.html
```

![](/images/nopermitido.png)
![](/images/noencontrado.png)
*Tarea 6 (1 punto)(Obligatorio): Añade al escenario Vagrant otra máquina conectada por una red interna al servidor. A la URL departamentos.iesgn.org/intranet sólo se debe tener acceso desde el cliente de la red local, y no se pueda acceder desde la anfitriona por la red pública. A la URL departamentos.iesgn.org/internet, sin embargo, sólo se debe tener acceso desde la anfitriona por la red pública, y no desde la red local.*

Para la intranet añadimos la siguiente línea en departamentos.conf
```
<Directory /srv/www/departamentos/intranet>
                Require ip 10.1.1.0/24
</Directory>
```

Maquina de fuera:

![](/images/intranet1.png)

Maquina local:

![](/images/intranet2.png)
Para el internet añadimos la siguiente linea en departamentos.conf
```
<Directory /srv/www/departamentos/internet>
                Require ip 172.22.0.1/16
</Directory>
```

Maquina de fuera:

![](/images/internet1.png)

Maquina local:

![](/images/internet2.png)

*Tarea 7 (1 punto): Autentificación básica. Limita el acceso a la URL departamentos.iesgn.org/secreto. Comprueba las cabeceras de los mensajes HTTP que se intercambian entre el servidor y el cliente. ¿Cómo se manda la contraseña entre el cliente y el servidor?. Entrega una breve explicación del ejercicio.*

Añadimos las siguientes líneas a departamentos.conf
```
  <Directory /srv/www/departamentos/secreto>
                AuthUserFile "/etc/apache2/claves/contra.txt"
                AuthName "Autentificacion"
                AuthType Basic
                Require valid-user
  </Directory>
```

Y ahora añadimos al usuario
```
htpasswd -c /etc/apache2/claves/contra.txt usuario
```

![](/images/autentificacion.png)
![](/images/autentificacion2.png)

```
	GET /secreto/ HTTP/1.1
	Host: www.departamentos.iesgn.org
	User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0
	Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
	Accept-Language: es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3
	Accept-Encoding: gzip, deflate
	DNT: 1
	Authorization: Basic dXN1YXJpbzp1c3Vhcmlv
	Connection: keep-alive
	Upgrade-Insecure-Requests: 1

```

En Authorization: Basic dXN1YXJpbzp1c3Vhcmlv está en base64 con el siguiente formado "usuario:contraseña"


*Tarea 8 (1 punto)(Obligatorio): Cómo hemos visto la autentificación básica no es segura, modifica la autentificación para que sea del tipo digest, y sólo sea accesible a los usuarios pertenecientes al grupo directivos. Comprueba las cabeceras de los mensajes HTTP que se intercambian entre el servidor y el cliente. ¿Cómo funciona esta autentificación?*

Modificamos las siguientes lineas en nuestro departamentos.conf
```
   <Directory /srv/www/departamentos/secreto>
                AuthUserFile "/etc/apache2/claves/contradigest.txt"
                AuthName "directivos"
                AuthType Digest
                Require valid-user
    </Directory>
```

Para crear el usuario:
```
htdigest -c /etc/apache2/claves/contradigest.txt directivo usuario1
```

Activamos el digest:
```
a2enmod auth_digest
systemctl restart apache2
```

```
	GET /secreto/ HTTP/1.1
	Host: www.departamentos.iesgn.org
	User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0
	Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
	Accept-Language: es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3
	Accept-Encoding: gzip, deflate
	DNT: 1
	Authorization: Digest username="usuario1", realm="directivo", nonce="n/gSwY6VBQA=7ea52093aac3fe6487a975be80cbaefc2f872259", uri="/secreto/", algorithm=MD5, response="8bdb27a0cb2b23cc5540deeb4ccde4d3", qop=auth, nc=00000002, cnonce="ca7e728e2422d275"
	Connection: keep-alive
	Upgrade-Insecure-Requests: 1
```

Podemos observar que aqui el envio del hash es muchisimo más seguro ya que presenta un algoritmo md5


*Tarea 9 (1 punto): Vamos a combinar el control de acceso (tarea 6) y la autentificación (tareas 7 y 8), y vamos a configurar el virtual host para que se comporte de la siguiente manera: el acceso a la URL departamentos.iesgn.org/secreto se hace forma directa desde la intranet, desde la red pública te pide la autentificación. Muestra el resultado al profesor.*

Para la realización de este ejercicio simplemente vamos a añadir las siguientes líneas a nuestro fichero departamentos.conf
Estas líneas harán que si entran por la red local accedan directamente y sino pida autorización si se accede fuera de la red local

```
 <Directory /srv/www/departamentos/secreto>
                AuthUserFile "/etc/apache2/claves/contradigest.txt"
                AuthName "directivo"
                AuthType Digest
                Require ip 10.1.1.0/24
                Require valid-user
 </Directory>
```


Local:

![](/images/pruebalocal.png)

Fuera:

![](/images/pruebafuera.png)
Añadiremos la Ip de la Intranet para que puedan acceder directamente, sino accederán mediante la contraseña.


*Tarea 10 (1 punto)(Obligatorio): Habilita el listado de ficheros en la URL http://host.dominio/nas.*
Para habilitar el listado de ficheros creamos un .htacess en la carpeta nas y ponemos la siguiente linea
```
Options +Indexes
```
![](/images/hosting1.png)

*Tarea 11 (1 punto): Crea una redirección permanente: cuando entremos en ttp://host.dominio/google salte a www.google.es.*
Para hacer la redirección simplemente creamos un .htacess en la raiz de la página y ponemos la siguiente línea
```
Redirect 301 /google https://www.google.es
```

*Tarea 12 (1 punto): Pedir autentificación para entrar en la URL http://host.dominio/prohibido. (No la hagas si has elegido como proveedor CDMON, en la plataforma de prueba no funciona.)*

Para realizar este ejercicio simplemente crearmos una carpeta claves, dentro de nuestro hosting junto al contra.txt que teniamos en el servidor antigüo (usuario:usuario).
Luego crearemos un .htaccess en la carpeta prohibido y pondremos las siguientes líneas
```
AuthUserFile "/storage/ssd1/069/11383069/public_html/claves/contra.txt" 
AuthName "Autentificacion" 
AuthType Basic
Require valid-user
```

![](/images/pruebaweb1.png)
![](/images/pruebaweb2.png)

*Tarea 13 (2 puntos)(Obligatorio): Módulo userdir: Activa y configura el módulo userdir, que permite que cada usuario del sistema tenga la posibilidad de tener un directorio (por defecto se llama public_html) donde alojar su página web. Publica una página de un usuario, y accede a la misma. Esta tarea la tienes que hacer en tu servidor.*

Activamos el módulo userdir
```
a2enmod userdir
systemctl restart apache2
```

Ahora si queremos que todos los usuarios tengan la carpeta public_html automáticamente, en /etc/skel/.bashrc realizamos los siguientes comandos:
```
mkdir public_html
chmod 755 public_html
```

Creamos un usuario alex y vemos si contiene la carpeta public_html
```
alex@apache:~$ ls
public_html
```

Ahora dentro de la carpeta creamos un index.html y probamos que funcione (se le pone ~alex en la url para que funcione)

![](/images/userdirprueba.png)

*Tarea 14 (2 puntos): En tu servidor crea una carpeta php donde vamos a tener un fichero index.php con el siguiente contenido:*
```
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml">
  <head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>Conversor de Monedas</title>
  </head>

  <body>
  <form action="index.php" method="get">
     	<input type="text" size="30" name="monto" /><br/>
      <select name="pais">
          <option name="Dolar">Dolar</option>
          <option name="Libra">Libra</option>
          <option name="Yen">Yen</option>
      </select>
      <input type="submit" value="convertir" />
     </form>
  <?php
      // averiguamos si se ha introducido un dinero
      if (isset($_GET['monto'])) {
        define ("cantidad", $_GET['monto']);
      } else {
   	  define ("cantidad", 0);
      }
      if($_GET){
      // definimos los países
      $tasacambios = array ("Libra"=>0.86,"Dolar"=>1.34,"Yen"=>103.56);
      // imprimimos el monto ingresado
      echo "<b>".cantidad." euros</b><br/> ".$_GET["pais"]." = ".cantidad*$tasacambios[$_GET["pais"]]." <br><br>";
      // por cada país imprimimos el cambio
      }
     ?>

  </body>
  </html>
```
Prueba la página utilizando parámetros en la URL (parámetros GET), por ejemplo: http://nombre_página/php/index.php?monto=100&pais=Libra

Configura mediante un fichero .htaccess, la posibilidad de acceder a la URL http://nombre_página/php/moneda/cantidad, donde moneda indica el nombre de la moneda a la que queremos convertir (Dolar,Libra,Yen) y cantidad indica los euros que queremos convertir.


Primero activamos el modulo rewrite
```
a2enmod rewrite
systemctl restart apache2
```

Creamos la carpeta
```
mkdir php
```

Creamos el index.php y observamos lo que nos devuelve
!pruebaphp.png!

Ahora queremos que la URL cambie, para eso creamos un .htaccess
```
RewriteEngine On
RewriteBase /php/
RewriteRule ^([a-zA-Z]+)/([0-9]+)$ index.php?pais=$1&monto=$2
```

Y ahora añadimos las siguientes lineas a nuestro iesgn.conf

```
<Directory /srv/www/iesgn/php>
                Options Indexes FollowSymLinks
                AllowOverride All
                Require all granted
</Directory>
```

![](/images/pruebarewrite.png)

