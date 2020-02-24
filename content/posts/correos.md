+++
date = "2020-02-17"
title = "Servidor de correos(Postfix)"
math = "true"

+++

## Servidor de correos Postfix

Primero de todo tenemos que tener instalado postfix
```
apt install postfix
```

Y en /etc/postfix/main.cf editamos las siguientes líneas
```
myhostname = alejandro.gonzalonazareno.org
relayhost = babuino-smtp.gonzalonazareno.org
```

Y en /etc/hosts tendremos la siguiente configuración
```
127.0.1.1 alejandro.gonzalonazareno.org croqueta.alejandro.gonzalonazareno.org croqueta
```

Y nuestro hostname será el siguiente:
```
root@croqueta:/home/debian# hostname -f
alejandro.gonzalonazareno.org
```

Reiniciamos postfix
```
systemctl restart postfix
```

Y enviamos un correo desde telnet a alexrodriguezrojas98@gmail.com

```
root@croqueta:/home/debian# telnet localhost 25
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
220 alejandro.gonzalonazareno.org ESMTP Postfix (Debian/GNU)
HELO correo.alejandro.gonzalonazareno.org
250 alejandro.gonzalonazareno.org
mail from: debian@alejandro.gonzalonazareno.org
250 2.1.0 Ok
rcpt to: alexrodriguezrojas98@gmail.com
250 2.1.5 Ok
data
354 End data with <CR><LF>.<CR><LF>
from: debian@alejandro.gonzalonazareno.org
to: alexrodriguezrojas98@gmail.com
subject: Prueba telnet

Hola, esto es una prueba para el ejercicio 1

.
250 2.0.0 Ok: queued as 32CA9218D3
quit
221 2.0.0 Bye
Connection closed by foreign host.
```

![](/images/telnet1.png)

Los logs del envio serían los siguientes
```
Feb 13 16:24:37 alejandro postfix/smtpd[4317]: disconnect from unknown[172.22.200.164] ehlo=2 starttls=1 mail=1 rcpt=0/1 quit=1 commands=5/6
Feb 13 16:24:49 alejandro postfix/smtpd[2409]: 32CA9218D3: client=localhost[127.0.0.1]
Feb 13 16:25:25 alejandro postfix/cleanup[4332]: 32CA9218D3: message-id=<20200213162449.32CA9218D3@alejandro.gonzalonazareno.org>
Feb 13 16:25:25 alejandro postfix/qmgr[7481]: 32CA9218D3: from=<debian@alejandro.gonzalonazareno.org>, size=494, nrcpt=1 (queue active)
Feb 13 16:25:25 alejandro postfix/smtp[4357]: 32CA9218D3: to=<alexrodriguezrojas98@gmail.com>, relay=babuino-smtp.gonzalonazareno.org[192.168.203.3]:25, delay=49, delays=49/0.04/0.06/0.04, dsn=2.0.0, status=sent (250 2.0.0 Ok: queued as A8465C9D5A)
```


Vamos a responder al correo anteriormente mandado y vamos a ver los logs  y el mensaje enviado.

Primero en nuestro servidor dns debemos añadir un registro MX para que pueda recibir el correo
```
@       IN      MX      10      correo.alejandro.gonzalonazareno.org.

$ORIGIN alejandro.gonzalonazareno.org.
....
correo          IN      CNAME   croqueta
....
```


Vamos a gmail y vamos a responder dicho email, ya que babuino tiene añadido nuestro dominio a su relay, dicho correo nos llegará.

![](/images/gmail.png)

Vamos a ver los logs:
```
Feb 13 17:08:24 alejandro postfix/smtpd[5125]: connect from babuino-smtp.gonzalonazareno.org[192.168.203.3]
Feb 13 17:08:24 alejandro postfix/smtpd[5125]: 6CA29218D4: client=babuino-smtp.gonzalonazareno.org[192.168.203.3]
Feb 13 17:08:24 alejandro postfix/cleanup[5129]: 6CA29218D4: message-id=<CAPN2xJRTNQoLS6WqUVCGMpQHyC=6Hbg9BAUCMgiL+pB8m-q01w@mail.gmail.com>
Feb 13 17:08:24 alejandro postfix/qmgr[5070]: 6CA29218D4: from=<alexrodriguezrojas98@gmail.com>, size=3834, nrcpt=1 (queue active)
Feb 13 17:08:24 alejandro postfix/smtpd[5125]: disconnect from babuino-smtp.gonzalonazareno.org[192.168.203.3] ehlo=1 mail=1 rcpt=1 data=1 quit=1 commands=5
Feb 13 17:08:24 alejandro postfix/local[6594]: 6CA29218D4: to=<debian@alejandro.gonzalonazareno.org>, relay=local, delay=0.16, delays=0.06/0.06/0/0.04, dsn=2.0.0, status=sent (delivered to mailbox)
Feb 13 17:08:24 alejandro postfix/qmgr[5070]: 6CA29218D4: removed

```

Vemos que se conecta a babuino, y este delega el mensaje hacia mi dominio, y nos lo envia, estará en nuestro mailbox

debian@croqueta:~$ mail
```
From: Alejandro Rodriguez Rojas <alexrodriguezrojas98@gmail.com>
Date: Thu, 13 Feb 2020 18:08:09 +0100
Message-ID: <CAPN2xJRTNQoLS6WqUVCGMpQHyC=6Hbg9BAUCMgiL+pB8m-q01w@mail.gmail.com>
Subject: Re: Prueba telnet
To: Debian <debian@alejandro.gonzalonazareno.org>
Content-Type: multipart/alternative; boundary="000000000000cff3b1059e7822a2"

--000000000000cff3b1059e7822a2
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

Hola, te respondo de vuelta, gracias.

```



Ahora vamos a instalar tanto POP como IMAP en nuestro servidor de correos

```
apt install dovecot-imapd dovecot-pop3d dovecot-core
```

Ahora en /etc/postfix/main.cf editamos la siguiente línea

```
home_mailbox = Maildir/
mailbox_command =


mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 10.0.0.0/24 172.22.0.0/16

```

En /etc/dovecot/conf.d/10-auth.conf editamos la siguiente linea
```
disable_plaintext_auth = no
```

En /etc/dovecot/conf.d/10-mail.conf editamos esta línea
```
mail_location = maildir:~/Maildir
```

Ahora en nuestro DNS añadimos tanto pop como imap.

```
pop IN CNAME croqueta
imap IN CNAME croqueta
```

*Muy importante tener habilitados los puertos IMAP y POP3*

Ahora vamos a Evolution y vamos a Archivo->Nuevo->Cuenta de Correo.

![](/images/Evolution1.png)

![](/images/Evolution2.png)

![](/images/Evolution3.png)

Si enviamos un mensaje al exterior vemos que podemos realizarlo

![](/images/Evolution4.png)

![](/images/Evolution5.png)


Como ya hemos configurado POP vamos a observar como funciona este método, para ello vamos a enviarnos desde gmail un correo a debian.
![](/images/POP1.png)
![](/images/POP2.png)

*Muy importante tener una contraseña en el usuario debian*


Vemos que se borran los mensajes en el servidor, esto es propio del método POP

```
root@croqueta:/home/debian# ls Maildir/new/
root@croqueta:/home/debian# 
root@croqueta:/home/debian# ls Maildir/cur/
root@croqueta:/home/debian# 

```

Vamos ahora a configurar Evolution con IMAP, en el servidor ya lo tenemos instalado

![](/images/Evolution1.png)

![](/images/Evolution6.png)
![](/images/Evolution7.png)

Vamos a enviarnos un correo desde gmail a nuestro servidor.
![](/images/IMAP1.png)

Lo recibimos en evolution y miramos el servidor.

![](/images/Evolution8.png)


Vemos que en el servidor se nos guarda el mensaje, esto es propio del método IMAP

```
root@croqueta:/home/debian# ls Maildir/cur/
1582017293.Vfe01I21c06M329057.croqueta:2,S
```

### Crontab

Ahora vamos a configurar una tarea cron que envie ciertos correos a root para informar de su estado.

Vamos a ejecutar una tarea crontab
```
crontab -e
```

Y ponemos la línea:
```
MAILTO = root

* * * * * /root/scriptls.sh
```

Dicho script solo hace un ls en /root.

Vamos a probar que está funcionando y le llegan mensajes a root

```
root@croqueta:~/Maildir/new# cat 1582099141.Vfe01I218d5M780676.croqueta 
Return-Path: <root@alejandro.gonzalonazareno.org>
X-Original-To: root
Delivered-To: root@alejandro.gonzalonazareno.org
Received: by alejandro.gonzalonazareno.org (Postfix, from userid 0)
	id A957A218D7; Wed, 19 Feb 2020 07:59:01 +0000 (UTC)
From: root@alejandro.gonzalonazareno.org (Cron Daemon)
To: root@alejandro.gonzalonazareno.org
Subject: Cron <root@croqueta> /root/scriptls.sh
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
X-Cron-Env: <MAILTO=root>
X-Cron-Env: <SHELL=/bin/sh>
X-Cron-Env: <HOME=/root>
X-Cron-Env: <PATH=/usr/bin:/bin>
X-Cron-Env: <LOGNAME=root>
Message-Id: <20200219075901.A957A218D7@alejandro.gonzalonazareno.org>
Date: Wed, 19 Feb 2020 07:59:01 +0000 (UTC)

certs
dead.letter
IESGonzaloNazareno.crt
ldapsecure.ldif
ldapssl.ldif
ldapSSL.ldif
ldapusers
Mail
Maildir
newcerts.ldif
salmorejo.alejandro.gonzalonazareno.org.crt
salmorejo.alejandro.gonzalonazareno.org.key
scriptls.sh
sent
```


Ahora vamos a realizar una redirección para que dichos correos se envien a debian, para ello vamos a /etc/aliases y ponemos

```
root: debian

```

Y ejecutamos la siguiente instrucción
```
newaliases
```

Ahora vamos a comprobar que están llegando dichos correos a debian.

```
debian@croqueta:~/Maildir/new$ cat 1582099262.Vfe01I21bf0M338379.croqueta 
Return-Path: <root@alejandro.gonzalonazareno.org>
X-Original-To: root
Delivered-To: root@alejandro.gonzalonazareno.org
Received: by alejandro.gonzalonazareno.org (Postfix, from userid 0)
	id 05D5221C03; Wed, 19 Feb 2020 08:01:01 +0000 (UTC)
From: root@alejandro.gonzalonazareno.org (Cron Daemon)
To: root@alejandro.gonzalonazareno.org
Subject: Cron <root@croqueta> /root/scriptls.sh
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
X-Cron-Env: <MAILTO=root>
X-Cron-Env: <SHELL=/bin/sh>
X-Cron-Env: <HOME=/root>
X-Cron-Env: <PATH=/usr/bin:/bin>
X-Cron-Env: <LOGNAME=root>
Message-Id: <20200219080102.05D5221C03@alejandro.gonzalonazareno.org>
Date: Wed, 19 Feb 2020 08:01:01 +0000 (UTC)

certs
dead.letter
IESGonzaloNazareno.crt
ldapsecure.ldif
ldapssl.ldif
ldapSSL.ldif
ldapusers
Mail
Maildir
newcerts.ldif
salmorejo.alejandro.gonzalonazareno.org.crt
salmorejo.alejandro.gonzalonazareno.org.key
scriptls.sh
sent

```

Y vamos a crear ahora un fichero que estará en /home/debian/.forward que contendrá lo siguiente para que se envien los correos a nuestro correo de gmail
```
debian@croqueta:~$ cat .forward 
alexrodriguezrojas98@gmail.com
```

![](/images/crontab.png)


Ahora vamos a instalar un webmail para nuestro servidor de correos, para ello, instalaremos roundcube.

```
apt install roundcube
```

En las opciones le damos a:

```
1-No
2-Yes
3-imap.alejandro.gonzalonazareno.org
4-Ok
5-Yes
6-Native
7-Slight
8-Automatic
9-No
```

Y creamos su base de datos
```
MariaDB [(none)]> create database roundcube;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> create user roundcube identified by 'roundcube';
Query OK, 0 rows affected (0.07 sec)

MariaDB [(none)]> grant all privileges on roundcube.* to roundcube;
Query OK, 0 rows affected (0.02 sec)

MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.06 sec)

```

Ahora vamos a instalar roundcube-mysql para que podamos enviar la información a nuestra base de datos en tortilla
```
apt install roundcube-mysql
```

Y configuramos la base de datos en /etc/dbconfig-common/roundcube.conf
```
dbc_dbuser='roundcube'
dbc_dbpass='roundcube'
dbc_dbserver='tortillaint.alejandro.gonzalonazareno.org'
dbc_dbport='3306'
dbc_dbname='roundcube'
dbc_dbadmin='root'

```

Y en /etc/roundcube/config.inc.php realizamos la siguiente configuración
```
$config['default_host'] = array("imap.alejandro.gonzalonazareno.org");
$config['smtp_server'] = 'correo.alejandro.gonzalonazareno.org';
$config['smtp_port'] = 25;
$config['smtp_user'] = '';
$config['smtp_pass'] = '';
$config['product_name'] = 'Roundcube Webmail';
$config['default_port'] = 143;
$config['smtp_auth_type'] = 'LOGIN';
$config['smtp_helo_host'] = 'correo.alejandro.gonzalonazareno.org';
$config['mail_domain'] = 'alejandro.gonzalonazareno.org';
$config['useragent'] = 'Server World Webmail';

$config['imap_conn_options'] = array(
  'ssl'         => array(
    'verify_peer' => true,
    'CN_match' => 'alejandro.gonzalonazareno.org',
    'allow_self_signed' => true,
    'ciphers' => 'HIGH:!SSLv2:!SSLv3',
  ),
);
$config['smtp_conn_options'] = array(
  'ssl'         => array(
    'verify_peer' => true,
    'CN_match' => 'alejandro.gonzalonazareno.org',
    'allow_self_signed' => true,
    'ciphers' => 'HIGH:!SSLv2:!SSLv3',
  ),
);
```

Y en /etc/apache2/conf-enabled/roundcube.conf hacemos
```
    Alias /roundcube /var/lib/roundcube

```

Y reiniciamos apache2
```
systemctl restart apache2
```

Insertamos también los datos de la base de datos roundcube

```
mysql -u roundcube -p roundcube -h tortillaint.alejandro.gonzalonazareno.org < /usr/share/roundcube/SQL/mysql.initial.sql 

MariaDB [roundcube]> show tables;
+---------------------+
| Tables_in_roundcube |
+---------------------+
| cache               |
| cache_index         |
| cache_messages      |
| cache_shared        |
| cache_thread        |
| contactgroupmembers |
| contactgroups       |
| contacts            |
| dictionary          |
| identities          |
| searches            |
| session             |
| system              |
| users               |
+---------------------+

```

Y ponemos la base de datos en configuracion en /etc/roundcube/defaults.inc.php
```
$config['db_dsnw'] = 'mysql://roundcube:roundcube@tortillaint/roundcube';
```

Ahora vamos a configurar el instalador, para ello hacemos:

```
cp -r /usr/share/roundcube/installer/ /var/lib/roundcube/
```

Y en /etc/roundcube/config.inc.php añadimos la linea
```
$config['enable_installer'] = true;
```

![](/images/Roundcube.png)

Como podemos observar hay una línea que no está, por lo que vamos a instalarla

```
apt install php-net-idna2
```

![](/images/Roundcube2.png)


![](/images/Roundcube3.png)
![](/images/Roundcube4.png)

Ahora borramos el instalador y entramos en http://{servidor}/roundcube y ponemos usuario debian/debian
```
rm -r /var/lib/roundcube/installer
```
![](/images/Roundcube5.png)

Vamos a realizar una prueba, para ello vamos a enviarnos un correo para ver si nos llega a roundcube.
![](/images/Roundcube6.png)

![](/images/Roundcube9.png)

Y probamos el envio
![](/images/Roundcube7.png)

![](/images/Roundcube8.png)


Ahora vamos a configurar un servicio de antispam en nuestro correo postfix, para ello instalamos:

```
apt install amavisd-new spamassassin clamav clamav-daemon
```

Escogemos la opción de Spain
Las demás opciones las dejamos por defecto.

Agregamos a los usuarios a los grupos de cada uno para que se puedan enviar información
```
adduser clamav amavis
adduser amavis clamav
```

Ahora en /etc/default/spamassassin añadimos:

```
CRON=1
ENABLED=1

```
Y reiniciamos el sistema
```
systemctl restart spamassassin
```

En /etc/amavis/conf.d/15-content_filter_mode hacemos:

```
use strict;
 
# You can modify this file to re-enable SPAM checking through spamassassin
# and to re-enable antivirus checking.
 
#
# Default antivirus checking mode
# Please note, that anti-virus checking is DISABLED by
# default.
# If You wish to enable it, please uncomment the following lines:
 
 
@bypass_virus_checks_maps = (
   \%bypass_virus_checks, \@bypass_virus_checks_acl, \$bypass_virus_checks_re);
 
 
#
# Default SPAM checking mode
# Please note, that anti-spam checking is DISABLED by
# default.
# If You wish to enable it, please uncomment the following lines:
 
 
@bypass_spam_checks_maps = (
   \%bypass_spam_checks, \@bypass_spam_checks_acl, \$bypass_spam_checks_re);
 
1;  # ensure a defined return
```

Reiniciamos el servicio
```
systemctl restart amavis
```

Ahora vamos a configurar postfix, para ello vamos a /etc/postfix/main.cf y configuramos

```
postconf -e "content_filter = smtp-amavis:[127.0.0.1]:10024"
postconf -e 'receive_override_options = no_address_mappings'
```

Y en /etc/postfix/master.cf añadimos las siguientes lineas
```
amavis unix - - - - 2 smtp
        -o smtp_data_done_timeout=1200
        -o smtp_send_xforward_command=yes

127.0.0.1:10025 inet n - - - - smtpd
        -o content_filter=
        -o local_recipient_maps=
        -o relay_recipient_maps=
        -o smtpd_restriction_classes=
        -o smtpd_client_restrictions=
        -o smtpd_helo_restrictions=
        -o smtpd_sender_restrictions=
        -o smtpd_recipient_restrictions=permit_mynetworks,reject
        -o mynetworks=127.0.0.0/8
        -o strict_rfc821_envelopes=yes
        -o receive_override_options=no_unknown_recipient_checks,no_header_body_checks
        -o smtpd_bind_address=127.0.0.1
```

Y reiniciamos postfix y clamav
```
systemctl restart postfix
systemctl restart clamav-daemon
```


