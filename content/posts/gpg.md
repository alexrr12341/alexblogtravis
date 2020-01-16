+++
date = "2019-12-10"
title = "Cifrado Asimétrico (GPG/OpenSSL)"
math = "true"

+++

h2. Tarea 1: Generación de claves (1 punto)

*1. Genera un par de claves (pública y privada). ¿En que directorio se guarda las claves de un usuario?*

Para generar el par de claves utilizamos el siguiente comando:

```
gpg --gen-key
```

```
gpg (GnuPG) 2.2.17; Copyright (C) 2019 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Nota: Usa "gpg --full-generate-key" para el diálogo completo de generación de clave.

GnuPG debe construir un ID de usuario para identificar su clave.

Nombre y apellidos: Alejandro Rodríguez Rojas
Dirección de correo electrónico: alexrodriguezrojas98@gmail.com
Está usando el juego de caracteres 'utf-8'.
Ha seleccionado este ID de usuario:
    "Alejandro Rodríguez Rojas <alexrodriguezrojas98@gmail.com>"

¿Cambia (N)ombre, (D)irección o (V)ale/(S)alir? V
Es necesario generar muchos bytes aleatorios. Es una buena idea realizar
alguna otra tarea (trabajar en otra ventana/consola, mover el ratón, usar
la red y los discos) durante la generación de números primos. Esto da al
generador de números aleatorios mayor oportunidad de recoger suficiente
entropía.
Es necesario generar muchos bytes aleatorios. Es una buena idea realizar
alguna otra tarea (trabajar en otra ventana/consola, mover el ratón, usar
la red y los discos) durante la generación de números primos. Esto da al
generador de números aleatorios mayor oportunidad de recoger suficiente
entropía.
gpg: clave 1CA5259568627FEF marcada como de confianza absoluta
gpg: creado el directorio '/home/alexrr/.gnupg/openpgp-revocs.d'
gpg: certificado de revocación guardado como '/home/alexrr/.gnupg/openpgp-revocs.d/8EA1F9C7DB1DF4BED396BDF01CA5259568627FEF.rev'
claves pública y secreta creadas y firmadas.

pub   rsa3072 2019-10-07 [SC] [caduca: 2021-10-06]
      8EA1F9C7DB1DF4BED396BDF01CA5259568627FEF
uid                      Alejandro Rodríguez Rojas <alexrodriguezrojas98@gmail.com>
sub   rsa3072 2019-10-07 [E] [caduca: 2021-10-06]

```

Se guardan en /home/usuario/.gnupg

*2. Lista las claves públicas que tienes en tu almacén de claves. Explica los distintos datos que nos muestra. ¿Cómo deberías haber generado las claves para indicar, por ejemplo, que tenga un 1 mes de validez?*

Para listar las claves públicas:
```
gpg --list-keys

pub   rsa3072 2019-10-07 [SC] [caduca: 2021-10-06]
      07C2323FF578FA4339796C35037C4BC2B4F18FCA
uid        [  absoluta ] Alejandro Rodríguez Rojas <alexrodriguezrojas98@gmail.com>
sub   rsa3072 2019-10-07 [E] [caduca: 2021-10-06]
```


Nos muestra el protocolo con el que está hecho (rsa3072), tiene confianza absoluta, caduca en el 2021-10-06 y fue creada el 2019-10-07. También nos muestra el nombre del fichero y el nombre del propietario junto a su email


Con el comando gpg --full-generate-key  podemos especificar los meses de caducidad.
```
gpg (GnuPG) 2.2.17; Copyright (C) 2019 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Por favor seleccione tipo de clave deseado:
   (1) RSA y RSA (por defecto)
   (2) DSA y ElGamal
   (3) DSA (sólo firmar)
   (4) RSA (sólo firmar)
Su elección: 1
las claves RSA pueden tener entre 1024 y 4096 bits de longitud.
¿De qué tamaño quiere la clave? (3072) 
El tamaño requerido es de 3072 bits
Por favor, especifique el período de validez de la clave.
         0 = la clave nunca caduca
      <n>  = la clave caduca en n días
      <n>w = la clave caduca en n semanas
      <n>m = la clave caduca en n meses
      <n>y = la clave caduca en n años
¿Validez de la clave (0)? 1m
La clave caduca mié 06 nov 2019 10:03:24 CET
¿Es correcto? (s/n) 

```

*3. Lista las claves privadas de tu almacén de claves.*

Para listar las claves privadas:
```
gpg --list-secret-keys

sec   rsa3072 2019-10-07 [SC] [caduca: 2021-10-06]
      07C2323FF578FA4339796C35037C4BC2B4F18FCA
uid        [  absoluta ] Alejandro Rodríguez Rojas <alexrodriguezrojas98@gmail.com>
ssb   rsa3072 2019-10-07 [E] [caduca: 2021-10-06]
```

h2. Tarea 2: Importar / exportar clave pública (1 punto)

*1. Exporta tu clave pública en formato ASCII y guardalo en un archivo nombre_apellido.asc y envíalo al compañero con el que vas a hacer esta práctica.*

Para exportar mi clave privada ejecutaremos el siguiente comando y se la pasaremos a nuestro compañero Paco
```
gpg --export -a "Alejandro Rodríguez Rojas" > alejandro_rodriguez.asc
```

*2. Importa las claves públicas recibidas de vuestro compañero.*
```
gpg --import francisco_guillermo.asc

gpg: clave 733C176D1363BFF4: clave pública "Francisco Guillermo García <pakotoes@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1
```

*3. Comprueba que las claves se han incluido correctamente en vuestro keyring.*
```
gpg --list-keys

pub   rsa3072 2019-10-07 [SC] [caduca: 2021-10-06]
      DA21BD5A7231AF245B1BA986733C176D1363BFF4
uid        [desconocida] Francisco Guillermo García <pakotoes@gmail.com>
sub   rsa3072 2019-10-07 [E] [caduca: 2021-10-06]
```

h2. Tarea 3: Cifrado asimétrico con claves públicas (3 puntos)

*1. Cifraremos un archivo cualquiera y lo remitiremos por email a uno de nuestros compañeros que nos proporcionó su clave pública.*

Creamos el fichero
```
echo "Paco" > paco.txt
```

Y encriptamos el archivo para luego enviarselo
```
gpg -e -u "Alejandro Rodríguez Rojas" -r "Francisco Guillermo García" paco.txt 
```

*2. Nuestro compañero, a su vez, nos remitirá un archivo cifrado para que nosotros lo descifremos.*

Al enviarnos Paco su fichero solo tendremos que hacer el siguiente comando:
```
gpg -d alex.txt.gpg
 
gpg: cifrado con clave de 3072 bits RSA, ID 2EB053ECFD3FFD7F, creada el 2019-10-07
      "Alejandro Rodríguez Rojas <alexrodriguezrojas98@gmail.com>"
hola alex

```

*3. Tanto nosotros como nuestro compañero comprobaremos que hemos podido descifrar los mensajes recibidos respectivamente.*

```
gpg -d alex.txt.gpg > alexdesencriptado.txt
```

```
alexrr@pc-alex:~/gpg$ cat alexdesencriptado.txt 
hola alex
```

*4. Por último, enviaremos el documento cifrado a alguien que no estaba en la lista de destinatarios y comprobaremos que este usuario no podrá descifrar este archivo.*

Enviamos el archivo a Luis y vemos lo que le ocurre

```
luis@kutulu:~/Descargas$ gpg -d paco.txt.gpg 
gpg: cifrado con clave RSA, ID E623CEEF4E0E9E3A
gpg: descifrado fallido: No tenemos la clave secreta
```

*5. Para terminar, indica los comandos necesarios para borrar las claves públicas y privadas que posees.*
Para borrar las claves simplemente ejecutamos el siguiente comando
```
gpg --delete-secret-and-public-keys "Alejandro Rodríguez Rojas"
```

h2. Tarea 4: Exportar clave a un servidor público de claves PGP (2 puntos)

*1. Genera la clave de revocación de tu clave pública para utilizarla en caso de que haya problemas.*
```
gpg --gen-revoke "Alejandro Rodríguez Rojas" > claverevo.key

sec  rsa3072/037C4BC2B4F18FCA 2019-10-07 Alejandro Rodríguez Rojas <alexrodriguezrojas98@gmail.com>

¿Crear un certificado de revocación para esta clave? (s/N) s
Por favor elija una razón para la revocación:
  0 = No se dio ninguna razón
  1 = La clave ha sido comprometida
  2 = La clave ha sido reemplazada
  3 = La clave ya no está en uso
  Q = Cancelar
(Probablemente quería seleccionar 1 aquí)
¿Su decisión? 0
Introduzca una descripción opcional; acábela con una línea vacía:
> Revoco la clave
> 
Razón para la revocación: No se dio ninguna razón
Revoco la clave
¿Es correcto? (s/N) s
se fuerza salida con armadura ASCII.
Certificado de revocación creado.

Por favor consérvelo en un medio que pueda esconder; si alguien consigue
acceso a este certificado puede usarlo para inutilizar su clave.
Es inteligente imprimir este certificado y guardarlo en otro lugar, por
si acaso su medio resulta imposible de leer. Pero precaución: ¡el sistema
de impresión de su máquina podría almacenar los datos y hacerlos accesibles
a otras personas!
```

*2. Exporta tu clave pública al servidor pgp.rediris.es*
Usamos el siguiente comando para exportarla en rediris
```
gpg --keyserver pgp.rediris.es --send-keys 07C2323FF578FA4339796C35037C4BC2B4F18FCA
gpg: enviando clave 037C4BC2B4F18FCA a hkp://pgp.rediris.es
```

*3. Borra la clave pública de alguno de tus compañeros de clase e impórtala ahora del servidor público de rediris.*
Borramos la clave de Paco
```
gpg --delete-keys "Francisco Guillermo García"
```

Y importamos las claves
```
gpg --keyserver pgp.rediris.es --recv-keys 733C176D1363BFF4

gpg: clave 733C176D1363BFF4: clave pública "Francisco Guillermo García <pakotoes@gmail.com>" importada
gpg: Cantidad total procesada: 1
gpg:               importadas: 1

```

*1. Genera un par de claves (pública y privada).*
Para crear la clave privada hacemos el comando:
```
openssl genrsa -out clave.pem 2048
```
Para conseguir la clave pública hacemos el comando:
```
openssl rsa -in clave.pem -pubout -out clavepub.pem
```


*2. Envía tu clave pública a un compañero.*
He enviado la clave pública a Paco con scp
```
scp clavepub.pem paco@ip
```
*3. Utilizando la clave pública cifra un fichero de texto y envíalo a tu compañero.*
Primero creamos el fichero con el contenido
```
echo "Pakitso" > paco.txt
```

Y luego encriptamos el archivo
```
openssl rsautl -pubin -encrypt -in paco.txt -out paco.enc -inkey pacossl.pub 
```

Y enviamos el fichero por scp

*4. Tu compañero te ha mandado un fichero cifrado, muestra el proceso para el descifrado.*

Para desencriptar el archivo simplemente ejecutamos el comando:
```
openssl rsautl -decrypt -inkey clave.pem -in alex.enc -out alex.txt

alexrr@pc-alex:~/openssl$ cat alex.txt 
hola alejandro
```


