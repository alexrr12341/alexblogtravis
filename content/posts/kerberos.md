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
...
_kerberos IN TXT "ALEJANDRO.GONZALONAZARENO.ORG"
_kerberos._udp IN      SRV     0       0       88      croqueta.alejandro.gonzalonazareno.org.
_kerberos_adm._tcp     IN      SRV     0       0       749     croqueta.alejandro.gonzalonazareno.org.
_ldap._tcp      IN      SRV     0       0       389     croqueta.alejandro.gonzalonazareno.org.
...

$ORIGIN alejandro.gonzalonazareno.org.
...
kerberos IN CNAME croqueta
ldap IN CNAME croqueta
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
Primero de todo tenemos que tener el servidor y el cliente en la misma hora, para ello vamos a llamar a instalar nuestro servidor de hora en nuestra máquina

```
apt install ntp
```

Y añadimos el servidor de horas, en este caso papion
```
root@croqueta:/var/cache/bind# ntpd -u papion.gonzalonazareno.org
root@tortilla:/home/ubuntu# ntpd -u papion.gonzalonazareno.org
```

## Uso de OpenLDAP

Como ya tenemos un servidor de LDAP funcionando, con la estructura Group y People, vamos a crear un usuario llamado pruebau y otro pruebag en inicio.ldif

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

adding new entry "uid=pruebauser1,ou=People,dc=alejandro,dc=gonzalonazareno,dc=org"



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
drwxr-xr-x 2 2100 2010 4096 Feb 19 18:40 .
drwxr-xr-x 3 root root 4096 Feb 19 18:39 ..
-rw-r--r-- 1 2100 2010  220 Feb 19 18:40 .bash_logout
-rw-r--r-- 1 2100 2010 3526 Feb 19 18:40 .bashrc
-rw-r--r-- 1 2100 2010  807 Feb 19 18:40 .profile

```

## Configuración de Name Service Switch (nss)

Para que podamos realizar la autentificación en kerberos, primero debemos instalar la siguiente configuración para ldap

```
apt install --no-install-recommends libnss-ldap
```

Identificador del servidor: ldaps://ldap.alejandro.gonzalonazareno.org
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
        #supported_enctypes = aes256-cts:normal aes128-cts:normal
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
....

[realms]
ALEJANDRO.GONZALONAZARENO.ORG = {
                kdc = kerberos.alejandro.gonzalonazareno.org   
                admin_server = kerberos.alejandro.gonzalonazareno.org
                }
....

[ domain_realm ]
	.alejandro.gonzalonazareno.org = ALEJANDRO.GONZALONAZARENO.ORG
        alejandro.gonzalonazareno.org = ALEJANDRO.GONZALONAZARENO.ORG
....

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
WARNING: no policy specified for pruebauser1@alejandro.gonzalonazareno.org; defaulting to no policy
Enter password for principal "pruebauser1@alejandro.gonzalonazareno.org": 
Re-enter password for principal "pruebauser1@alejandro.gonzalonazareno.org": 
Principal "pruebauser1@alejandro.gonzalonazareno.org" created.

kadmin.local:  add_principal -randkey host/croqueta.alejandro.gonzalonazareno.org
WARNING: no policy specified for host/croqueta.alejandro.gonzalonazareno.org@alejandro.gonzalonazareno.org; defaulting to no policy
Principal "host/croqueta.alejandro.gonzalonazareno.org@alejandro.gonzalonazareno.org" created.

kadmin.local:  add_principal -randkey host/tortilla.alejandro.gonzalonazareno.org
WARNING: no policy specified for host/tortilla.alejandro.gonzalonazareno.org@alejandro.gonzalonazareno.org; defaulting to no policy
Principal "host/tortilla.alejandro.gonzalonazareno.org@alejandro.gonzalonazareno.org" created.

kadmin.local:  add_principal -randkey ldap/croqueta.alejandro.gonzalonazareno.org
WARNING: no policy specified for ldap/croqueta.alejandro.gonzalonazareno.org@alejandro.gonzalonazareno.org; defaulting to no policy
Principal "ldap/croqueta.alejandro.gonzalonazareno.org@alejandro.gonzalonazareno.org" created.

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

```
