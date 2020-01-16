+++
date = "2019-12-10"
title = "Integridad, firmas y autentificación"
math = "true"

+++

h2. Tarea 1: Firmas electrónicas (3 puntos)

# *Manda un documento y la firma electrónica del mismo a un compañero. Verifica la firma que tu has recibido.*
Le mando el documento y la firma electrónica a Paco por scp.
```
alexrr@pc-alex:~/gpg$ echo "Hola amigos" > paco
alexrr@pc-alex:~/gpg$ gpg --output paco.sig --detach-sig paco
```
Ahora la verificamos
```
gpg --verify alex.sig alex
alexrr@pc-alex:~/gpg$ gpg --verify alex.sig alex
gpg: Firmado el mar 15 oct 2019 11:07:01 CEST
gpg:                usando RSA clave DA21BD5A7231AF245B1BA986733C176D1363BFF4
gpg: Firma correcta de "Francisco Guillermo García <pakotoes@gmail.com>" [desconocido]
gpg: ATENCIÓN: ¡Esta clave no está certificada por una firma de confianza!
gpg:          No hay indicios de que la firma pertenezca al propietario.
Huellas dactilares de la clave primaria: DA21 BD5A 7231 AF24 5B1B  A986 733C 176D 1363 BFF4
```
# *¿Qué significa el mensaje que aparece en el momento de verificar la firma?*
Significa que ese usuario no ha firmado tu firma, por lo que no es una firma de confianza, pero sabemos que la ha realizado Francisco Guillermo Garcia
# *Vamos a crear un anillo de confianza entre los miembros de nuestra clase, para ello.*
```
* Tu clave pública debe estar en un servidor de claves
* Escribe tu fingerprint en un papel y dárselo a tu compañero, para que puede descargarse tu clave pública.
* Te debes bajar al menos tres claves públicas de compañeros. Firma estas claves.
* Tu te debes asegurar que tu clave pública es firmada por al menos tres compañeros de la clase.
* Puedes seguir el esquema que se nos presenta en la siguiente página de Debian:
* Una vez que firmes una clave se la tendrás que devolver a su dueño, para que otra persona se la firme.
* Cuando tengas las tres firmas sube la clave al servidor de claves y rellena tus datos en la tabla Claves públicas PGP 2019-2020
* Asegurate que te vuelves a bajar las claves públicas de tus compañeros que tengan las tres firmas.
```
Subimos la clave a rediris
```
gpg --keyserver pgp.rediris.es --send-keys 07C2323FF578FA4339796C35037C4BC2B4F18FCA
```
Ahora para firmar otras claves debemos hacer:
```
gpg --key-edit {fingerprint}
sign
save
```
Así hasta 3 veces
# *Muestra las firmas que tiene tu clave pública.*

```
gpg --list-signatures

pub   rsa3072 2019-10-07 [SC] [caduca: 2021-10-06]
      07C2323FF578FA4339796C35037C4BC2B4F18FCA
uid        [  absoluta ] Alejandro Rodríguez Rojas <alexrodriguezrojas98@gmail.com>
sig 3        037C4BC2B4F18FCA 2019-10-07  Alejandro Rodríguez Rojas <alexrodriguezrojas98@gmail.com>
sig          733C176D1363BFF4 2019-10-15  Francisco Guillermo García <pakotoes@gmail.com>
sig          30B2CE7D46D49C6B 2019-10-15  Luis Vazquez Alejo <luisvazquezalejo@gmail.com>
sig          7705B1D5F1165BAC 2019-10-22  Manuel Lora Román <manuelloraroman@gmail.com>
sub   rsa3072 2019-10-07 [E] [caduca: 2021-10-06]
sig          037C4BC2B4F18FCA 2019-10-07  Alejandro Rodríguez Rojas <alexrodriguezrojas98@gmail.com>


```
5. *Comprueba que ya puedes verificar sin “problemas” una firma recibida por una persona en la que confías.*

```
gpg --verify alex.sig alex

gpg: Firmado el mar 15 oct 2019 11:07:01 CEST
gpg:                usando RSA clave DA21BD5A7231AF245B1BA986733C176D1363BFF4
gpg: Firma correcta de "Francisco Guillermo García <pakotoes@gmail.com>" [absoluta]

```
6. *Comprueba que puedes verificar sin “problemas” una firma recibida por una tercera problema en la que confía una persona en la que tu confías.*
Importamos la clave de Fernando Tirado que confia en Luis y yo confio en él y comprobamos si funciona correctamente
```
gpg --verify ftirado.sig ftiradohola.txt 
gpg: Firmado el mar 22 oct 2019 12:18:22 CEST
gpg:                usando RSA clave A615146E82E272C899A34100F405106DBBABFB72
gpg: Firma correcta de "Fernando Tirado <fernando.tb.95@gmail.com>" [total]

```


h2. *Tarea 2: Correo seguro con evolution/thunderbird (2 puntos)*

*1. Configura el cliente de correo evolution con tu cuenta de correo habitual*
Nuevo->Cuenta de Correo
Al configurar el correo google te pedirá una autentificación para que evolution pueda acceder a tu correo

![](/images/imagen.png)

*2. Añade a la cuenta las opciones de seguridad para poder enviar correos firmados con tu clave privada o cifrar los mensajes para otros destinatarios*
Vamos a propiedades->Seguridad 
En ID de clave OpenPGP ponemos nuestra clave de GPG y ponemos y ponemos las siguientes opciones:
-Firmar siempre
-Cifrar siempre
-Siempre cifrar a si mismo
*3. Envía y recibe varios mensajes con tus compañeros y comprueba el funcionamiento adecuado de GPG*

Enviamos un mensaje a Paco y él nos enviará uno, para ver que es lo que ocurre, nos pedirá la contraseña de la clave al enviar el email para poder autentificar la clave.
![](/images/imagen2.png)


h2. *Tarea 3: Integridad de ficheros (1 punto)*

*1. Para validar el contenido de la imagen CD, solo asegúrese de usar la herramienta apropiada para sumas de verificación. Para cada versión publicada existen archivos de suma de comprobación con algoritmos fuertes (SHA256 y SHA512); debería usar las herramientas sha256sum o sha512sum para trabajar con ellos.*

Nos descargamos la imagen de debian junto a su sha512sum.

Ahora simplemente ejecutamos el comando y vemos si la suma coincide
```
alexrr@pc-alex:~/Descargas$ sha512sum -c SHA512SUMS 2> /dev/null | grep netinst
debian-10.1.0-amd64-netinst.iso: La suma coincide
debian-edu-10.1.0-amd64-netinst.iso: FAILED open or read
debian-mac-10.1.0-amd64-netinst.iso: FAILED open or read
```

*2. Verifica que el contenido del hash que has utilizado no ha sido manipulado, usando la firma digital que encontrarás en el repositorio. Puedes encontrar una guía para realizarlo en este artículo: How to verify an authenticity of downloaded Debian ISO images*

Para verificar el contenido nos descargamos el SHA512SUM.sig y ejecutamos el siguiente comando:
```
alexrr@pc-alex:~/Descargas$ gpg --verify SHA512SUMS.sign SHA512SUMS
gpg: Firmado el dom 08 sep 2019 17:52:40 CEST
gpg:                usando RSA clave DF9B9C49EAA9298432589D76DA87E80D6294BE9B
gpg: Imposible comprobar la firma: No public key
```

Está firmado por la clave de Debian, entonces no ha sido manipulado

h2. *Tarea 4: Integridad y autenticidad (apt secure) (2 puntos)*


*1. ¿Qué software utiliza apt secure para realizar la criptografía asimétrica?*
Utiliza el software gpg
*2. ¿Para que sirve el comando apt-key? ¿Qué muestra el comando apt-key list?*
Es una herramienta para gestionar las claves de apt. Muestra todas las firmas de confianza de debian
*3. En que fichero se guarda el anillo de claves que guarda la herramienta apt-key?*
En /etc/apt/trusted.gpg
*4. ¿Qué contiene el archivo Release de un repositorio de paquetes?. ¿Y el archivo Release.gpg?. Puedes ver estos archivos en el repositorio http://ftp.debian.org/debian/dists/Debian10.1/. Estos archivos se descargan cuando hacemos un apt update.*

El archivo Release trae la versión de Debian que estamos utilizando junto a los hash de todos los contenidos que nos queramos instalar.
El archivo Release.gpg tiene la firma del archivo Release.

*5. Explica el proceso por el cual el sistema nos asegura que los ficheros que estamos descargando son legítimos.*


*6. Añade de forma correcta el repositorio de virtualbox añadiendo la clave pública de virtualbox como se indica en la documentación.*

Para añadir de forma correcta el repositorio primero vamos a la página https://www.virtualbox.org/wiki/Linux_Downloads , vamos al apartado de debian-based y ponemos en el /etc/apt/sources.list esto:
```
deb https://download.virtualbox.org/virtualbox/debian buster contrib
```

Y ahora nos descargaremos la clave y la insertaremos en nuestro ordenador
```
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
```

Y ya podremos utilizar el repositorio

h2. *Tarea 5: Autentificación: ejemplo SSH (2 puntos)*

*1. Explica los pasos que se producen entre el cliente y el servidor para que el protocolo cifre la información que se transmite? ¿Para qué se utiliza la criptografía simétrica? ¿Y la asimétrica?*
*2. Explica los dos métodos principales de autentificación: por contraseña y utilizando un par de claves públicas y privadas.*
Por contraseña: El cliente al conectarse le pedirá una contraseña de usuario para que este pueda acceder
Por claves públicas y privadas: El cliente crea su clave pública y privada,mete su clave pública en el servidor y este ya podrá entrar al instante sin necesidad de requerir de una contraseña

*3. En el cliente para que sirve el contenido que se guarda en el fichero ~/.ssh/know_hosts?*
Sirve para guardar las credenciales del servidor que queramos entrar, fingerprint, IP, etc.
*4. ¿Qué significa este mensaje que aparece la primera vez que nos conectamos a un servidor?*
```
     $ ssh debian@172.22.200.74
     The authenticity of host '172.22.200.74 (172.22.200.74)' can't be established.
     ECDSA key fingerprint is SHA256:7ZoNZPCbQTnDso1meVSNoKszn38ZwUI4i6saebbfL4M.
     Are you sure you want to continue connecting (yes/no)? 
```
Significa que estamos entrando a un servidor por primera vez, por lo que nos salta un mensaje de seguridad donde nos indica que entramos a ese servidor que tiene ese fingerprint y dicha IP, y si estamos seguros de si queremos entrar ahí o no
*5. En ocasiones cuando estamos trabajando en el cloud, y reutilizamos una ip flotante nos aparece este mensaje:*
```
     $ ssh debian@172.22.200.74
     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
     @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
     IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
     Someone could be eavesdropping on you right now (man-in-the-middle attack)!
     It is also possible that a host key has just been changed.
     The fingerprint for the ECDSA key sent by the remote host is
     SHA256:W05RrybmcnJxD3fbwJOgSNNWATkVftsQl7EzfeKJgNc.
     Please contact your system administrator.
     Add correct host key in /home/jose/.ssh/known_hosts to get rid of this message.
     Offending ECDSA key in /home/jose/.ssh/known_hosts:103
       remove with:
       ssh-keygen -f "/home/jose/.ssh/known_hosts" -R "172.22.200.74"
     ECDSA host key for 172.22.200.74 has changed and you have requested strict checking.
```
Esto es debido a que el fingerprint de la máquina a cambiado, es decir que es una máquina totalmente distinta a la anterior. Dicha información se guarda en el .ssh/known_hosts por lo que nos pedirá que borremos las credenciales del anterior servidor si queremos entrar a este nuevo.
*6. ¿Qué guardamos y para qué sirve el fichero en el servidor ~/.ssh/authorized_keys?*
Guardamos las claves públicas de los clientes que quieran acceder sin necesidad de contraseña

