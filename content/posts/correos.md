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

Instalamos los descompresores y utilidades
```
apt install unrar-free unzip bzip2 libnet-ph-perl libnet-snpp-perl libnet-telnet-perl nomarch lzop
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
Y en /etc/amavis/conf.d/20-debian_defaults ponemos
```
$final_spam_destiny = D_DISCARD;
```

Reiniciamos el servicio
```
systemctl restart amavis
```

Ahora vamos a configurar postfix, para ello ejecutamos en la terminal:

```
postconf -e 'content_filter = amavis:[127.0.0.1]:10024'
postconf -e 'receive_override_options = no_address_mappings'

```

Esto lo que hará es añadir dichas líneas de amavis en /etc/postfix/main.cf

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

Y reiniciamos postfix
```
systemctl restart postfix
```

Y vamos a actualizar el antivirus
```
systemctl stop clamav-freshclam
freshclam
systemctl stop clamav-daemon
clamd
systemctl start clamav-daemon
systemctl start clamav-freshclam
```

Ahora vamos a comprobar el ejemplo de anti spam con el siguiente [ejemplo](https://spamassassin.apache.org/gtube/gtube.txt)

Nos enviamos un correo con spam
![](/images/AntiSpam.png)


Vamos a comprobar los logs de emails
```
Feb 26 09:04:44 croqueta postfix/qmgr[2641]: E52312222F: from=<alexrodriguezrojas98@gmail.com>, size=2997, nrcpt=1 (queue active)
Feb 26 09:04:44 croqueta postfix/smtpd[3558]: disconnect from babuino-smtp.gonzalonazareno.org[192.168.203.3] ehlo=1 mail=1 rcpt=1 data=1 quit=1 commands=5
Feb 26 09:04:46 croqueta amavis[3491]: (03491-01) Blocked SPAM {DiscardedInbound,Quarantined}, [192.168.203.3]:47508 [209.85.166.194] <alexrodriguezrojas98@gmail.com> -> <debian@alejandro.gonzalonazareno.org>, quarantine: W/spam-WK3LMJCskwci.gz, Queue-ID: E52312222F, Message-ID: <CAPN2xJTcpDLpWPjvhtGsWeSuWFWtj+Tfv2cuevh4VKUh2+TNEw@mail.gmail.com>, mail_id: WK3LMJCskwci, Hits: 1000.053, size: 2997, 1093 ms
Feb 26 09:04:46 croqueta postfix/smtp[3562]: E52312222F: to=<debian@alejandro.gonzalonazareno.org>, relay=127.0.0.1[127.0.0.1]:10024, delay=1.1, delays=0.03/0.01/0.01/1.1, dsn=2.7.0, status=sent (250 2.7.0 Ok, discarded, id=03491-01 - spam)
Feb 26 09:04:46 croqueta postfix/qmgr[2641]: E52312222F: removed

```


### Usuarios Virtuales con LDAP

Primero de todo vamos a configurar un usuario ldap para que contenga la información del correo


Para ello primero vamos a instalar:
```
apt install postfix-ldap
```

Vamos a crear la unidad organizativa para postfix

```
dn:ou=postfix,dc=alejandro,dc=gonzalonazareno,dc=org
ou: postfix
objectClass: organizationalUnit

```

La añadimos a ldap
```
root@croqueta:~# ldapadd -f postfix.ldif -x -D "cn=admin,dc=alejandro,dc=gonzalonazareno,dc=org" -W
Enter LDAP Password: 
adding new entry "ou=postfix,dc=alejandro,dc=gonzalonazareno,dc=org"
```

La estructura de correos estará bajo el directorio /home/vmail/{usuario} por lo que vamos a crearlo


Primero creamos el grupo

grouppostfix.ldif
```
dn:cn=vmail,ou=Group,dc=alejandro,dc=gonzalonazareno,dc=org
cn: vmail
gidNumber: 10004
objectClass: top
objectClass: posixGroup
```


Añadimos el grupo
```
root@croqueta:~# ldapadd -f grouppostfix.ldif -x -D "cn=admin,dc=alejandro,dc=gonzalonazareno,dc=org" -W
Enter LDAP Password: 
adding new entry "cn=vmail,ou=Group,dc=alejandro,dc=gonzalonazareno,dc=org"
```

Hacemos la carpeta
```
mkdir -p /home/vmail/alexrr
chown 10001:10004 /home/vmail/alexrr
chmod 2755 /home/vmail/alexrr
```	


Instalamos el paquete courier-authlib-ldap
```
apt install courier-authlib-ldap
```

Y añadimos el esquema
```
cp /usr/share/doc/courier-authlib-ldap/authldap.schema /etc/ldap/schema/authldap.schema
```

Añadimos el esquema a ldap

```
mkdir /tmp/borrame.d
```

```
nano /tmp/borrame.conf
```
include /etc/ldap/schema/core.schema
include /etc/ldap/schema/cosine.schema
include /etc/ldap/schema/nis.schema
include /etc/ldap/schema/inetorgperson.schema
include /etc/ldap/schema/authldap.schema
```
Hacemos el esquema
```
slaptest -f /tmp/borrame.conf -F /tmp/borrame.d
```


Añadimos el esquema a slapd
```
root@croqueta:~# cp /tmp/borrame.d/cn\=config/cn\=schema/cn\=\{4\}authldap.ldif /etc/ldap/slapd.d/cn\=config/cn\=schema/
root@croqueta:~# chown openldap:openldap /etc/ldap/slapd.d/cn\=config/cn\=schema/cn\=\{4\}authldap.ldif 
root@croqueta:~# systemctl restart slapd

```

Añadimos al usuario ahora
```
dn:uid=alexrr,ou=People,dc=alejandro,dc=gonzalonazareno,dc=org
uid: alexrr
cn: Alejandro
sn: Rodríguez Rojas
userPassword:{CRYPT}mdkQsdBAQepDU
uidNumber: 10001
gidNumber: 10004
homeDirectory: /home/vmail/alexrr
objectClass: top
objectClass: person
objectClass: posixAccount
objectClass: CourierMailAccount
mail: alexrr@alejandro.gonzalonazareno.org
mailbox: alexrr/
quota: 0
```

```
root@croqueta:~# ldapadd -f alexrr.ldif -x -D "cn=admin,dc=alejandro,dc=gonzalonazareno,dc=org" -W
Enter LDAP Password: 
adding new entry "uid=alexrr,ou=People,dc=alejandro,dc=gonzalonazareno,dc=org"
```


Ahora vamos a /etc/postfix/main.cf y añadimos las siguientes líneas
```
virtual_mailbox_domains = alejandro.gonzalonazareno.org
virtual_mailbox_base = /home/vmail
virtual_minimum_uid = 100

#Virtual User

virtual_mailbox_maps = ldap:vuser

vuser_server_host = 127.0.0.1
vuser_search_base = ou=People,dc=alejandro,dc=gonzalonazareno,dc=org
vuser_query_filter = (&(mail=%s)(!(quota=-1))(objectClass=CourierMailAccount))
vuser_result_attribute = mailbox
vuser_bind = no

#Virtual User uid

virtual_uid_maps = ldap:uidldap

uidldap_server_host = 127.0.0.1
uidldap_search_base = ou=People,dc=alejandro,dc=gonzalonazareno,dc=org
uidldap_query_filter = (&(mail=%s)(!(quota=-1))(objectClass=CourierMailAccount))
uidldap_result_attribute = uidNumber
uidldap_bind = no

#Virtual User gid

virtual_gid_maps = ldap:gidldap

gidldap_server_host = 127.0.0.1
gidldap_search_base = ou=People,dc=alejandro,dc=gonzalonazareno,dc=org
gidldap_query_filter = (&(mail=%s)(!(quota=-1))(objectClass=CourierMailAccount))
gidldap_result_attribute = gidNumber
gidldap_bind = no
```

Vamos a enviar un email

![](/images/postfixLDAP.png)



Y vemos que llega la información y es enviada al usuario ldap.

```
Feb 26 11:15:00 croqueta postfix/qmgr[11640]: D64C32381F: from=<alexrodriguezrojas98@gmail.com>, size=2888, nrcpt=1 (queue active)
Feb 26 11:15:00 croqueta postfix/smtpd[11676]: disconnect from babuino-smtp.gonzalonazareno.org[192.168.203.3] ehlo=1 mail=1 rcpt=1 data=1 quit=1 commands=5
Feb 26 11:15:03 croqueta postfix/smtpd[11697]: connect from localhost[127.0.0.1]
Feb 26 11:15:03 croqueta postfix/trivial-rewrite[11680]: warning: do not list domain alejandro.gonzalonazareno.org in BOTH mydestination and virtual_mailbox_domains
Feb 26 11:15:03 croqueta postfix/smtpd[11697]: 37ABA23820: client=localhost[127.0.0.1]
Feb 26 11:15:03 croqueta postfix/cleanup[11681]: 37ABA23820: message-id=<CAPN2xJR1aEUe_5CnPUreobuAxFfwdzsq9ym_u=iA9hqxsGMXsg@mail.gmail.com>
Feb 26 11:15:03 croqueta postfix/qmgr[11640]: 37ABA23820: from=<alexrodriguezrojas98@gmail.com>, size=3420, nrcpt=1 (queue active)
Feb 26 11:15:03 croqueta postfix/trivial-rewrite[11680]: warning: do not list domain alejandro.gonzalonazareno.org in BOTH mydestination and virtual_mailbox_domains
Feb 26 11:15:03 croqueta postfix/smtpd[11697]: disconnect from localhost[127.0.0.1] ehlo=1 mail=1 rcpt=1 data=1 quit=1 commands=5
Feb 26 11:15:03 croqueta amavis[3492]: (03492-02) Passed CLEAN {RelayedInbound}, [192.168.203.3]:55548 [209.85.166.42] <alexrodriguezrojas98@gmail.com> -> <alexrr@alejandro.gonzalonazareno.org>, Queue-ID: D64C32381F, Message-ID: <CAPN2xJR1aEUe_5CnPUreobuAxFfwdzsq9ym_u=iA9hqxsGMXsg@mail.gmail.com>, mail_id: y56hSa8ZL3DA, Hits: 0.052, size: 2888, queued_as: 37ABA23820, 2342 ms
Feb 26 11:15:03 croqueta postfix/smtp[11682]: D64C32381F: to=<alexrr@alejandro.gonzalonazareno.org>, relay=127.0.0.1[127.0.0.1]:10024, delay=2.4, delays=0.04/0.01/0/2.3, dsn=2.0.0, status=sent (250 2.0.0 from MTA(smtp:[127.0.0.1]:10025): 250 2.0.0 Ok: queued as 37ABA23820)
Feb 26 11:15:03 croqueta postfix/qmgr[11640]: D64C32381F: removed
Feb 26 11:15:03 croqueta postfix/local[11698]: 37ABA23820: to=<alexrr@alejandro.gonzalonazareno.org>, relay=local, delay=0.05, delays=0.01/0.03/0/0.01, dsn=2.0.0, status=sent (delivered to maildir)
```


Vemos que el correo ha llegado
```
root@croqueta:/home/vmail/alexrr/Maildir/new# ls
1582715703.Vfe01I60105M268039.croqueta.alejandro.gonzalonazareno.org
root@croqueta:/home/vmail/alexrr/Maildir/new# cat 1582715703.Vfe01I60105M268039.croqueta.alejandro.gonzalonazareno.org 
Return-Path: <alexrodriguezrojas98@gmail.com>
X-Original-To: alexrr@alejandro.gonzalonazareno.org
Delivered-To: alexrr@alejandro.gonzalonazareno.org
Received: from localhost (localhost [127.0.0.1])
	by alejandro.gonzalonazareno.org (Postfix) with ESMTP id 37ABA23820
	for <alexrr@alejandro.gonzalonazareno.org>; Wed, 26 Feb 2020 11:15:03 +0000 (UTC)
X-Virus-Scanned: Debian amavisd-new at alejandro.gonzalonazareno.org
Received: from alejandro.gonzalonazareno.org ([127.0.0.1])
	by localhost (alejandro.gonzalonazareno.org [127.0.0.1]) (amavisd-new, port 10024)
	with ESMTP id y56hSa8ZL3DA for <alexrr@alejandro.gonzalonazareno.org>;
	Wed, 26 Feb 2020 11:15:00 +0000 (UTC)
Received: from babuino-smtp.gonzalonazareno.org (babuino-smtp.gonzalonazareno.org [192.168.203.3])
	by alejandro.gonzalonazareno.org (Postfix) with ESMTP id D64C32381F
	for <alexrr@alejandro.gonzalonazareno.org>; Wed, 26 Feb 2020 11:15:00 +0000 (UTC)
Received: from mail-io1-f42.google.com (mail-io1-f42.google.com [209.85.166.42])
	by babuino-smtp.gonzalonazareno.org (Postfix) with ESMTPS id 9CC63C9D58
	for <alexrr@alejandro.gonzalonazareno.org>; Wed, 26 Feb 2020 11:15:00 +0000 (UTC)
Received: by mail-io1-f42.google.com with SMTP id m25so2891673ioo.8
        for <alexrr@alejandro.gonzalonazareno.org>; Wed, 26 Feb 2020 03:15:00 -0800 (PST)
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;
        d=gmail.com; s=20161025;
        h=mime-version:from:date:message-id:subject:to;
        bh=14DaWJPDIvc1Labl5BH74k7de9aCaM2tSI6nfSeboVk=;
        b=gqd/pUli6lJ7FA6SFUT3YTc4YAJh5vSAZbPAcBoYL4pRJrRtAJb2+EwIevZsRbcxl0
         tGtTsljFE8uSwy6xGCDZtZ3rkEpmbtssFadt6bQAKTZWUoQ39gY2zmglX/U3j6Fpyftr
         Y6PLN8jGeskHdIrHZM50RJaHbu/WwzjE+nK+rM3mTf/75GJEr95HIpllOrGcrywX3Lom
         IenoDnTc8qgcDkm1t/YRbfb7tXoIIx4n/7+WsSCJS6nH2dSfuZhuNTco+LrVfXQ7sXAO
         MAFPnnnnvLkG/JBi1GDjct9cxD/+iS2U16oR/RWuLxXQ2LXTqlBBZiwHGvc71MVUD46O
         nbaw==
X-Google-DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;
        d=1e100.net; s=20161025;
        h=x-gm-message-state:mime-version:from:date:message-id:subject:to;
        bh=14DaWJPDIvc1Labl5BH74k7de9aCaM2tSI6nfSeboVk=;
        b=RcEk4YXrX0pvejaJB9o4AZOrO3SVF0r4MakohjBmutc0SCDNfr8sKdH0hz/xxmBizk
         M0OzdqRFyNb/PPwU4Tfa66wwlg5ADSoDoslZ9NE5gGaPVZCa97Iuu/b4XznDmlDgb+Pg
         30OsPuZvLcv2d2yShIBti/dPkKazRSQqbUkDAhkeRfts1/JEPjGcciylruP/YFiofkZS
         xrIBpDcGUN0c+6zcNSmZ7IKkJjJLcxpIY2KgN6WdvP0tvTrQ4nFUaj9wnwL+MTKI43LD
         FlRYdo8QkbtrRRu+TeLmYT80rL6hj8t2qj3BS9XzUvWGXM0QFLHa4EKPzB+aq1ki0Sgb
         vwQA==
X-Gm-Message-State: APjAAAWDQgr0IIBupFfUCWc5U42t3Q8qit9LT5UBruI0gnu0Jn6dbGgZ
	/3mJjOd3e3zEOCSv125rHuTDp1MunayPQQ/2FPnyDA==
X-Google-Smtp-Source: APXvYqyujYh+9EBR/opZ/uBVeks4vc2u85MU9AehD0kF9qaP9F9ciuf4r18BBfuUc2YXVbdWBYGkPgyyIAy9OOF9ino=
X-Received: by 2002:a6b:ea05:: with SMTP id m5mr1935606ioc.191.1582715698378;
 Wed, 26 Feb 2020 03:14:58 -0800 (PST)
MIME-Version: 1.0
From: Alejandro Rodriguez Rojas <alexrodriguezrojas98@gmail.com>
Date: Wed, 26 Feb 2020 12:14:46 +0100
Message-ID: <CAPN2xJR1aEUe_5CnPUreobuAxFfwdzsq9ym_u=iA9hqxsGMXsg@mail.gmail.com>
Subject: Prueba ldap
To: alexrr@alejandro.gonzalonazareno.org
Content-Type: multipart/alternative; boundary="000000000000fb7ccb059f78b629"

--000000000000fb7ccb059f78b629
Content-Type: text/plain; charset="UTF-8"

Hola esto es una prueba

--000000000000fb7ccb059f78b629
Content-Type: text/html; charset="UTF-8"

<div dir="ltr">Hola esto es una prueba<br></div>

--000000000000fb7ccb059f78b629--

```
