+++
date = "2020-02-19"
title = "Gestión de usuarios con Kerberos5, Ldap y NFS4"
math = "true"

+++

## Gestión de usuarios con Kerberos5, Ldap y NFS4

## Ajustes previos

### Configuración del DNS con bind9

Para ello vamos a ir a /var/cache/bind/db.gonzalonazareno.org que es el fichero donde tenemos nuestras configuraciones de DNS y añadimos las siguientes líneas
```
$ORIGIN alejandro.gonzalonazareno.org.
...
kerberos IN CNAME croqueta
ldap IN CNAME croqueta
_kerberos               IN      TXT     "ALEJANDRO.GONZALONAZARENO.ORG"
_kerberos._udp          IN      SRV     0 0 88   kerberos.alejandro.gonzalonazareno.org.
_kerberos_adm._tcp      IN      SRV     0 0 749  kerberos.alejandro.gonzalonazareno.org.
_ldap._tcp              IN      SRV     0 0 389  ldap.alejandro.gonzalonazareno.org.

```

Vemos que se ha realizado bien el dns
```
root@croqueta:/var/cache/bind# dig ldap.alejandro.gonzalonazareno.org

; <<>> DiG 9.11.5-P4-5.1-Debian <<>> ldap.alejandro.gonzalonazareno.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 49194
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 11d1364b4a8ef42c8f575f5e5e4d7cf5ceb2ee7c0d15db92 (good)
;; QUESTION SECTION:
;ldap.alejandro.gonzalonazareno.org. IN	A

;; ANSWER SECTION:
ldap.alejandro.gonzalonazareno.org. 86400 IN CNAME croqueta.alejandro.gonzalonazareno.org.
croqueta.alejandro.gonzalonazareno.org.	42136 IN A 172.22.200.96
```

## Configuracion de ntp (servidor de hora)
Primero de todo tenemos que tener el servidor y el cliente en la misma hora, para ello vamos a llamar a instalar en ambas máquinas ntp

```
apt install ntp
```

Y en /etc/ntpd.conf del cliente tortilla añadimos
```
server croqueta.alejandro.gonzalonazareno.org
```


```

root@tortilla:/home/ubuntu# ntpq -np

 172.22.200.96   .INIT.          16 u    -   64    0    0.000    0.000   0.000

```

## Uso de OpenLDAP

Como ya tenemos un servidor de LDAP funcionando, con la estructura Group y People, vamos a crear un usuario llamado pruebauser1 y un grupo llamado pruebagroup en inicio.ldif

```
dn: cn=pruebagroup,ou=Group,dc=alejandro,dc=gonzalonazareno,dc=org
objectClass: posixGroup
objectClass: top
cn: pruebagroup
gidNumber: 2010

dn: uid=pruebauser1,ou=People,dc=alejandro,dc=gonzalonazareno,dc=org
objectClass: account
objectClass: posixAccount
objectClass: top
cn: pruebauser1
uid: pruebauser1
loginShell: /bin/bash
uidNumber: 2101
gidNumber: 2010
homeDirectory: /home/users/pruebauser1
```

Añadimos los usuarios con ldapadd

```
root@croqueta:~# ldapadd -f inicio.ldif -x -D "cn=admin,dc=alejandro,dc=gonzalonazareno,dc=org" -W

adding new entry "cn=pruebagroup1,ou=Group,dc=alejandro,dc=gonzalonazareno,dc=org"

adding new entry "uid=pruebauser1,ou=People,dc=alejandro,dcdocker-compose loop=gonzalonazareno,dc=org"
```

En /etc/ldap/ldap.conf editamos:

```
BASE    dc=alejandro,dc=gonzalonazareno,dc=org
URI     ldap://ldap.alejandro.gonzalonazareno.org
```

Como no tenemos el directorio de pruebau, vamos a crear su directorio

```
mkdir -p /home/users/pruebauser1
cp /etc/skel/.* /home/users/pruebauser1
chown -R 2100:2010 /home/users/pruebauser1/
```

Vemos los permisos

```
root@croqueta:/home/users/pruebau# ls -la
total 20
drwxr-xr-x 2 2101 2010 4096 Feb 19 18:40 .
drwxr-xr-x 3 root root 4096 Feb 19 18:39 ..
-rw-r--r-- 1 2101 2010  220 Feb 19 18:40 .bash_logout
-rw-r--r-- 1 2101 2010 3526 Feb 19 18:40 .bashrc
-rw-r--r-- 1 2101 2010  807 Feb 19 18:40 .profile

```

## Configuración de Name Service Switch (nss)

Para que podamos realizar la autentificación en kerberos, primero debemos instalar la siguiente configuración para ldap

```
apt install --no-install-recommends libnss-ldap
```

Identificador del servidor: ldap://ldap.alejandro.gonzalonazareno.org/
DN base: dc=alejandro,dc=gonzalonazareno,dc=org
Versión LDAP: 3
Ignorar
Ignorar

Ahora vamos a /etc/libnss-ldap.conf y comentamos la siguiente línea
```
#rootbinddn cn=manager,dc=example,dc=net
```

Y borramos la contraseña del administrador si la creamos.
```
rm -f /etc/libnss-ldap.secret
```

Y en /etc/nsswitch.conf ponemos las siguientes líneas
```
passwd:         files ldap
group:          files ldap

```

Vamos a probar su funcionamiento.

```
root@croqueta:~# ls -al /home/users/pruebauser1/
total 20
drwxr-xr-x 2 pruebauser1 pruebagroup 4096 Feb 19 19:31 .
drwxr-xr-x 5 root        root        4096 Feb 19 19:31 ..
-rw-r--r-- 1 pruebauser1 pruebagroup  220 Feb 19 19:31 .bash_logout
-rw-r--r-- 1 pruebauser1 pruebagroup 3526 Feb 19 19:31 .bashrc
-rw-r--r-- 1 pruebauser1 pruebagroup  807 Feb 19 19:31 .profile
```

```
root@croqueta:~# getent passwd pruebauser1
pruebauser1:*:2101:2010:pruebauser1:/home/users/pruebauser1:/bin/bash
```

Si queremos que se cacheen las consultas de ldap hacemos

```
apt install nscd
```
## Instalación y configuración de Kerberos5

Primero vamos a descargarnos los paquetes de kerberos y su administración
```
apt install krb5-kdc krb5-admin-server
```

Como no tenemos el reino/realm creado, nos saltará un error en la instalación de kerberos5 a la hora de ejecutar el systemctl start, por lo que vamos a observar el realm en /etc/krb5kdc/kdc.conf

```
[kdcdefaults]
    kdc_ports = 750,88

[realms]
    ALEJANDRO.GONZALONAZARENO.ORG = {
        database_name = /var/lib/krb5kdc/principal
        admin_keytab = FILE:/etc/krb5kdc/kadm5.keytab
        acl_file = /etc/krb5kdc/kadm5.acl
        key_stash_file = /etc/krb5kdc/stash
        kdc_ports = 750,88
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        master_key_type = des3-hmac-sha1
        #supported_enctypes = aes256-cts:normal aes128-cts:normal
        default_principal_flags = +preauth
    }

```


Como vemos, debemos desactivar el puerto 750 y desactivar kerberos4
```
[kdcdefaults]
    kdc_ports = 88

[realms]
    ALEJANDRO.GONZALONAZARENO.ORG = {
        database_name = /var/lib/krb5kdc/principal
        admin_keytab = FILE:/etc/krb5kdc/kadm5.keytab
        acl_file = /etc/krb5kdc/kadm5.acl
        key_stash_file = /etc/krb5kdc/stash
        kdc_ports = 88
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        master_key_type = des3-hmac-sha1
        supported_enctypes = aes256-cts:normal aes128-cts:normal
        default_principal_flags = +preauth
    }



```
Y en /etc/default/krb5-kdc desactivamos kerberos 4

```
KRB4_MODE = disable
RUN_KRB524D = false
```

Y en /etc/krb5.conf añadimos las siguientes líneas
```
[libdefaults]
	default_realm = ALEJANDRO.GONZALONAZARENO.ORG
[realms]
	ALEJANDRO.GONZALONAZARENO.ORG = {
		kdc = kerberos.alejandro.gonzalonazareno.org
		admin_server = kerberos.alejandro.gonzalonazareno.org
		}
[domain_realm]
	.alejandro.gonzalonazareno.org = ALEJANDRO.GONZALONAZARENO.ORG
	alejandro.gonzalonazareno.org = ALEJANDRO.GONZALONAZARENO.ORG

```

Para definir nuestro realm, debemos realizar el siguiente comando

```
krb5_newrealm
```

Nos pedirá una contraseña que será quien controle todo kerberos.

Reiniciamos kerberos
```
root@croqueta:~# systemctl restart krb5-kdc
root@croqueta:~# systemctl restart krb5-admin-server
```

Comprobamos que está escuchando kerberos en el puerto asignado
```
netstat -putan |grep " krb5kdc \| kadmind "

tcp        0      0 0.0.0.0:88              0.0.0.0:*               LISTEN      30918/krb5kdc       
tcp6       0      0 :::88                   :::*                    LISTEN      30918/krb5kdc
```

## kadmin.local 

Ahora vamos a entrar a kadmin.local y vamos a listar los participantes de kerberos

```
root@croqueta:~# kadmin.local
Authenticating as principal root/admin@ALEJANDRO.GONZALONAZARENO.ORG with password.
kadmin.local:  list_principals
K/M@ALEJANDRO.GONZALONAZARENO.ORG
alexrr/admin@ALEJANDRO.GONZALONAZARENO.ORG
host/croqueta.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG
host/tortilla.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG
kadmin/admin@ALEJANDRO.GONZALONAZARENO.ORG
kadmin/alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG
kadmin/changepw@ALEJANDRO.GONZALONAZARENO.ORG
kiprop/alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG
krbtgt/ALEJANDRO.GONZALONAZARENO.ORG@ALEJANDRO.GONZALONAZARENO.ORG
ldap/croqueta.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG
pruebauser1@ALEJANDRO.GONZALONAZARENO.ORG


```

Llegados a este punto, debemos crear un principal para pruebauser1 por lo que en kadmin.local realizamos lo siguiente
```
kadmin.local:  add_principal pruebauser1
WARNING: no policy specified for pruebauser1@ALEJANDRO.GONZALONAZARENO.ORG; defaulting to no policy
Enter password for principal "pruebauser1@ALEJANDRO.GONZALONAZARENO.ORG": 
Re-enter password for principal "pruebauser1@ALEJANDRO.GONZALONAZARENO.ORG": 
Principal "pruebauser1@ALEJANDRO.GONZALONAZARENO.ORG" created.

kadmin.local:  add_principal -randkey host/croqueta.alejandro.gonzalonazareno.org
WARNING: no policy specified for host/croqueta.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG; defaulting to no policy
Principal "host/croqueta.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG" created.

kadmin.local:  add_principal -randkey host/tortilla.alejandro.gonzalonazareno.org
WARNING: no policy specified for host/tortilla.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG; defaulting to no policy
Principal "host/tortilla.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG" created.

kadmin.local:  add_principal -randkey ldap/croqueta.alejandro.gonzalonazareno.org
WARNING: no policy specified for ldap/croqueta.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG; defaulting to no policy
Principal "ldap/croqueta.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG" created.

```

## Ficheros Keytab

Para que las claves cifradas se identifiquen de forma no interactiva, debemos controlar los archivos de los keytab de los servidores, por lo que realizamos lo siguiente:

```
kadmin.local:  ktadd host/croqueta.alejandro.gonzalonazareno.org
Entry for principal host/croqueta.alejandro.gonzalonazareno.org with kvno 2, encryption type aes256-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
Entry for principal host/croqueta.alejandro.gonzalonazareno.org with kvno 2, encryption type aes128-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.

kadmin.local:  ktadd ldap/croqueta.alejandro.gonzalonazareno.org
Entry for principal ldap/croqueta.alejandro.gonzalonazareno.org with kvno 2, encryption type aes256-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
Entry for principal ldap/croqueta.alejandro.gonzalonazareno.org with kvno 2, encryption type aes128-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.

```

La información quedará almacenada en /etc/krb5.keytab

### Usuarios administradores de kerberos

También podemos crear ciertos usuarios para administrar kerberos, para ello hacemos editamos el fichero /etc/krb5kdc/kdadm5.acl:
```
*/admin *
```

Accedemos a kadmin.local y añadimos un usuario.
```
kadmin.local:  add_principal alexrr/admin
WARNING: no policy specified for alexrr/admin@alejandro.gonzalonazareno.org; defaulting to no policy
Enter password for principal "alexrr/admin@alejandro.gonzalonazareno.org": 
Re-enter password for principal "alexrr/admin@alejandro.gonzalonazareno.org": 
Principal "alexrr/admin@alejandro.gonzalonazareno.org" created.



```


## Cliente de Kerberos

Vamos ahora a instalar el cliente de kerberos en tortilla, para ello hacemos
```
apt install krb5-config krb5-user
```

Debemos configurar /etc/krb5.conf igual que en el servidor

### Klist

Si queremos ver los tickets de session de usuario usamos
```
root@tortilla:/home/ubuntu# klist -5
klist: No credentials cache found (filename: /tmp/krb5cc_0)

```
Esto sale ya que no hemos logeado aún.

### Kinit

Si queremos logearnos a nuestro usuario, debemos realizar lo siguiente

```
root@tortilla:/home/ubuntu# kinit pruebauser1
Password for pruebauser1@ALEJANDRO.GONZALONAZARENO.ORG: 
root@tortilla:/home/ubuntu# klist -5
Ticket cache: FILE:/tmp/krb5cc_0
Default principal: pruebauser1@ALEJANDRO.GONZALONAZARENO.ORG

Valid starting     Expires            Service principal
02/21/20 08:20:57  02/21/20 18:20:57  krbtgt/ALEJANDRO.GONZALONAZARENO.ORG@ALEJANDRO.GONZALONAZARENO.ORG
	renew until 02/22/20 08:20:51

```

(Tenemos que tener abiertos los puertos 749 tcp, 464 tcp, 464 udp y 88 udp)

## SASL/GSSAPI

Ahora vamos a autentificar con LDAP mediante una autentificación simple y segura, para ello hacemos

```
apt install libsasl2-modules-gssapi-mit
```

Para que ldap pueda acceder al fichero de configuración de kerberos vamos a editar los permisos de /etc/krb5.keytab
```
chmod 640 /etc/krb5.keytab
chgrp openldap /etc/krb5.keytab
```

Y creamos el fichero /etc/ldap/sasl2/slapd.conf y le añadimos

```
mech_list: GSSAPI
```

Y en /etc/ldap/ldap.conf realizamos:

```
SASL_MECH GSSAPI
SASL_REALM ALEJANDRO.GONZALONAZARENO.ORG
```

Y reiniciamos slapd
```
systemctl restart slapd
```

Y miramos si está funcionando
```
root@croqueta:~# ldapsearch -x -b "" -s base -LLL supportedSASLMechanisms
dn:
supportedSASLMechanisms: GSSAPI

```

Observamos en el cliente
```
ubuntu@tortilla:~$ ldapsearch "uidNumber=2101"
SASL/GSSAPI authentication started
SASL username: pruebauser1@ALEJANDRO.GONZALONAZARENO.ORG
SASL SSF: 56
SASL data security layer installed.
# extended LDIF
#
# LDAPv3
# base <dc=alejandro,dc=gonzalonazareno,dc=org> (default) with scope subtree
# filter: uidNumber=2101
# requesting: ALL
#

# pruebauser1, People, alejandro.gonzalonazareno.org
dn: uid=pruebauser1,ou=People,dc=alejandro,dc=gonzalonazareno,dc=org
objectClass: account
objectClass: posixAccount
objectClass: top
cn: pruebauser1
uid: pruebauser1
loginShell: /bin/bash
uidNumber: 2101
gidNumber: 2010
homeDirectory: /home/users/pruebauser1

# search result
search: 4
result: 0 Success

# numResponses: 2
# numEntries: 1
```

```
root@croqueta:/etc/ldap# ldapwhoami
SASL/GSSAPI authentication started
SASL username: pruebauser1@ALEJANDRO.GONZALONAZARENO.ORG
SASL SSF: 256
SASL data security layer installed.
dn:uid=pruebauser1,cn=gssapi,cn=auth

```

## PAM

Ahora vamos a hacer que pam pueda acceder mediante kerberos, por lo que vamos a instalar:
```
root@tortilla:~# apt install libpam-krb5
root@croqueta:~# apt install libpam-krb5

```

Como vamos a tocar el PAM, vamos a guardar una copia:

```
cp -r /etc/pam.d /etc/pam.d.old
```

Ahora vamos a configurar los ficheros common-*

common-auth
```
auth	sufficient	pam_krb5.so	minimum_uid=2000	
auth	required	pam_unix.so	try_first_pass	nullok_secure

```
common-session
```
session	optional	pam_krb5.so	minimum_uid=2000
session	required	pam_unix.so

```

common-account
```
account	sufficient	pam_krb5.so	minimum_uid=2000
account	required	pam_unix.so

```
common-password
```
password  sufficient  pam_krb5.so minimum_uid=2000
password  required    pam_unix.so nullok obscure min=4 max=8 md5 sha512

```

Ahora vamos a comprobar el login

```
root@croqueta:~# login pruebauser1
Password: 
Last login: Wed Feb 26 18:38:51 UTC 2020 on pts/0
Linux croqueta.alejandro.gonzalonazareno.org 4.19.0-8-cloud-amd64 #1 SMP Debian 4.19.98-1 (2020-01-26) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
pruebauser1@croqueta:~$ 

```

## Network File System 4 (NFS4)

Como croqueta funcionará como servidor NFS, tenemos que instalar el paquete correspondiente
```
apt install nfs-kernel-server
```

Ahora vamos a configurarlo para que utilice el GSSAPI de kerberos

/etc/default/nfs-common
```
NEED IDMAPD=yes

NEED_GSSD=yes

```


/etc/default/nfs-kernel-server
```
NEED_SVCGSSD="yes"
```

/etc/idmapd.conf
```
Domain = alejandro.gonzalonazareno.org

```

Ahora crearemos los principales en kerberos, siendo el principal de tortilla en un directorio temporal para pasarselo acto seguido.
```
root@croqueta:~# kadmin.local

Authenticating as principal pruebauser1/admin@ALEJANDRO.GONZALONAZARENO.ORG with password.
kadmin.local:  add_principal -randkey nfs/croqueta.alejandro.gonzalonazareno.org
WARNING: no policy specified for nfs/croqueta.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG; defaulting to no policy
Principal "nfs/croqueta.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG" created.

kadmin.local:  add_principal -randkey nfs/tortilla.alejandro.gonzalonazareno.org
WARNING: no policy specified for nfs/tortilla.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG; defaulting to no policy
Principal "nfs/tortilla.alejandro.gonzalonazareno.org@ALEJANDRO.GONZALONAZARENO.ORG" created.

kadmin.local:  ktadd nfs/croqueta.alejandro.gonzalonazareno.org
Entry for principal nfs/croqueta.alejandro.gonzalonazareno.org with kvno 2, encryption type aes256-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
Entry for principal nfs/croqueta.alejandro.gonzalonazareno.org with kvno 2, encryption type aes128-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.

kadmin.local:  ktadd -k /tmp/krb5.keytab nfs/tortilla.alejandro.gonzalonazareno.org
Entry for principal nfs/tortilla.alejandro.gonzalonazareno.org with kvno 2, encryption type aes256-cts-hmac-sha1-96 added to keytab WRFILE:/tmp/krb5.keytab.
Entry for principal nfs/tortilla.alejandro.gonzalonazareno.org with kvno 2, encryption type aes128-cts-hmac-sha1-96 added to keytab WRFILE:/tmp/krb5.keytab.

```

Pasamos los ficheros a tortilla con scp
```
root@croqueta:~/.ssh# scp /tmp/krb5.keytab root@tortilla.alejandro.gonzalonazareno.org:/etc/krb5.keytab
krb5.keytab                                                           100%  248   136.3KB/s   00:00  
root@croqueta:~/.ssh# rm /tmp/krb5.keytab 

```


Para definir las exportaciones iremos al fichero /etc/exports y haremos lo siguiente:

```
/srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
/srv/nfs4/homes/users  gss/krb5i(rw,sync,no_subtree_check,no_root_squash)
```

Y reiniciamos los servicios
```
root@croqueta:/srv/nfs4/homes# systemctl restart nfs-kernel-server
root@croqueta:/srv/nfs4/homes# systemctl restart nfs-common

```

Si no podemos reiniciar nfs-common, es debido a que está enmascarado, para ello hacemos:
```
rm /lib/systemd/system/nfs-common.service
systemctl daemon-reload
```

Miramos si están montados
```
root@croqueta:~# showmount -e
Export list for croqueta.alejandro.gonzalonazareno.org:
/srv/nfs4/homes gss/krb5i
/srv/nfs4       gss/krb5i

```


En tortilla ahora vamos a configurar el cliente, por lo que vamos a instalar el paquete nfs-common
```
root@tortilla:~# apt install nfs-common

```

Lo configuramos->

/etc/default/nfs-common
```
NEED_GSSD=yes
NEED_IDMAPD=yes

```

/etc/idmapd.conf
```
Domain = alejandro.gonzalonazareno.org

```

Y reiniciamos el servicio
```
systemctl restart nfs-common
```

Montamos y comprobamos(tenemos que activar el puerto 2049 udp y tcp)


Para ello editaremos el fstab de ambos:

Croqueta(Servidor):

```
/home	/srv/nfs4/homes	none	rw,bind	0	0

```

Tortilla(Cliente):

```
croqueta.alejandro.gonzalonazareno.org:/homes/users     /home/users   nfs4    rw,sec=krb5i 0 0

```


Aqui podemos demostrar que se ha montado
```
root@tortilla:/home/nfs4/users/pruebauser1# ls -al
total 28
drwxr-xr-x 3 nobody 4294967294 4096 Feb 26 18:35 .
drwxr-xr-x 5 root   root       4096 Mar  5 08:56 ..
-rw------- 1 nobody 4294967294  308 Mar  4 12:22 .bash_history
-rw-r--r-- 1 nobody 4294967294  220 Feb 19 19:31 .bash_logout
-rw-r--r-- 1 nobody 4294967294 3526 Feb 19 19:31 .bashrc
drwx------ 3 nobody 4294967294 4096 Feb 26 18:35 .gnupg
-rw-r--r-- 1 nobody 4294967294  807 Feb 19 19:31 .profile
root@tortilla:/home/nfs4/users/pruebauser1# 

```

Por último, vamos a instalar libnss en tortilla
```
apt install --no-install-recommends libnss-ldap
```


Y comprobamos que hay login en croqueta y tortilla

```
root@tortilla:~# login pruebauser1
Password: 
Last login: Thu Mar  5 13:06:57 UTC 2020 from 172.22.200.96 on pts/1
Welcome to Ubuntu 18.04.4 LTS (GNU/Linux 4.15.0-88-generic x86_64)

pruebauser1@tortilla:~$ pwd
/home/users/pruebauser1
pruebauser1@tortilla:~$ ssh croqueta
pruebauser1@croqueta's password: 
Linux croqueta.alejandro.gonzalonazareno.org 4.19.0-8-cloud-amd64 #1 SMP Debian 4.19.98-1 (2020-01-26) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Thu Mar  5 13:06:52 2020 from 172.22.200.110
pruebauser1@croqueta:~$ pwd
/home/users/pruebauser1

pruebauser1@croqueta:~$ ssh tortilla
pruebauser1@tortilla's password: 
Welcome to Ubuntu 18.04.4 LTS (GNU/Linux 4.15.0-88-generic x86_64)
pruebauser1@tortilla:~$ 

```

Si queremos que en ssh no se nos pida contraseña, vamos a /etc/ssh/sshd_config y ponemos
```
GSSAPIAuthentication yes

```
