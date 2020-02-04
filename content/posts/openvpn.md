+++
date = "2020-01-27"
title = "OpenVPN con TLS/SSL"
math = "true"

+++

## VPN de acceso remoto con OpenVPN y certificados x509

Práctica VPN
------------

Vamos a preparar el escenario vagrant
```
Vagrant.configure("2") do |config|

  config.vm.define :server do |server|
    server.vm.box = "debian/buster64"
    server.vm.hostname = "server"
    server.vm.synced_folder '.', '/vagrant'
    server.vm.network :public_network, :bridge => 'enp7s0'
    server.vm.network :private_network, ip: "192.168.1.1", virtualbox__intnet: "lolitofdez"

  end
  config.vm.define :cliente do |cliente|
    cliente.vm.box = "debian/buster64"
    cliente.vm.hostname = "local"
    cliente.vm.synced_folder '.', '/vagrant'
    cliente.vm.network :private_network, ip: "192.168.1.2", virtualbox__intnet: "lolitofdez"
  end
  config.vm.define :clientevpn do |clientevpn|
    clientevpn.vm.box = "debian/buster64"
    clientevpn.vm.hostname = "clientevpn"
    clientevpn.vm.synced_folder '.', '/vagrant'
    clientevpn.vm.network :public_network, :bridge => 'enp7s0'
  end
end
```


## Servidor

Primero vamos a activar el bit de forward
```
echo 1 > /proc/sys/net/ipv4/ip_forward
```




Hacemos la CA
```
mkdir /root/ca
DIR_CA="/root/ca" 
cd $DIR_CA
mkdir certs csr crl newcerts private
chmod 700 private
touch index.txt
touch index.txt.attr
echo 1000 > serial
```

Hacemos las variables
```
countryName_default="ES" 
stateOrProvinceName_default="Sevilla" 
localityName_default="Dos Hermanas" 
organizationName_default="Alejandro.org" 
organizationalUnitName_default="Alejandro" 
emailAddress_default="alexrodriguezrojas98@gmail.com" 
```

Hacemos el fichero de configuración
```
DIR_CA="./" 
cat <<EOF>$DIR_CA/openssl.conf
[ ca ]
# man ca
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = ${DIR_CA}
certs             = ${DIR_CA}certs
crl_dir           = ${DIR_CA}crl
new_certs_dir     = ${DIR_CA}newcerts
database          = ${DIR_CA}index.txt
serial            = ${DIR_CA}serial
RANDFILE          = ${DIR_CA}private/.rand

# The root key and root certificate.
private_key       = ${DIR_CA}private/ca.key.pem
certificate       = ${DIR_CA}certs/ca.cert.pem

# For certificate revocation lists.
crlnumber         = ${DIR_CA}crlnumber
crl               = ${DIR_CA}crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of man ca.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the ca man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the req tool (man req).
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only
# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256
# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca
# Extension for SANs
req_extensions      = v3_req

[ v3_req ]
# Extensions to add to a certificate request
# Before invoke openssl use: export SAN=DNS:value1,DNS:value2
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
xxxsubjectAltNamexxx =

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = $countryName_default
stateOrProvinceName_default     = $stateOrProvinceName_default
localityName_default            = $localityName_default
0.organizationName_default      = $organizationName_default
organizationalUnitName_default  = $organizationalUnitName_default
emailAddress_default            = $emailAddress_default

[ v3_ca ]
# Extensions for a typical CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates (man x509v3_config).
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate" 
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Extensions for server certificates (man x509v3_config).
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate" 
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
# Extension for CRLs (man x509v3_config).
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates (man ocsp).
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
```

Ahora creamos la clave privada
```
openssl genrsa -aes256 -out ${DIR_CA}private/ca.key.pem 4096
chmod 400 ${DIR_CA}private/ca.key.pem
```

Y hacemos el certificado para la unidad certificadora
```
openssl req -config openssl.conf \
-key private/ca.key.pem \
-new -x509 -days 7300 -sha256 -extensions v3_ca \
-out certs/ca.cert.pem
```
Hacemos el fichero diffie hellman
```
openssl dhparam -out /root/private/dh.pem 2048
```

El fichero diffie hellman es un protocolo criptográfico

Movemos ahora los certificados a /etc/openvpn
```
mv /root/ca /etc/openvpn
```

Ahora hacemos el archivo servidor.conf
```
#Dispositivo de túnel
dev tun
    
#Direcciones IP virtuales
server 10.99.99.0 255.255.255.0 

#subred local
push "route 192.168.1.0 255.255.255.0"

# Rol de servidor
tls-server

#Parámetros Diffie-Hellman
dh /etc/openvpn/ca/private/dh.pem

#Certificado de la CA
ca /etc/openvpn/ca/certs/ca.cert.pem

#Certificado local
cert /etc/openvpn/ca/certs/ca.cert.pem

#Clave privada local
key /etc/openvpn/ca/private/ca.key.pem

#Activar la compresión LZO
comp-lzo

#Detectar caídas de la conexión
keepalive 10 60

#Nivel de información
verb 3

```


Y ahora firmamos el certificado a nuestro cliente y le pasamos el crt y el certificado.
```
root@server:/home/vagrant# openssl x509 -req -in clientevpn.csr -CA /etc/openvpn/ca/certs/ca.cert.pem -CAkey /etc/openvpn/ca/private/ca.key.pem -CAcreateserial -out clientevpn.crt
```


Ahora vamos a hacer en /etc/openvpn un fichero llamado contra.txt que tendrá la contraseña de nuestra clave privada, y en servidor.conf añadimos
```
askpass contra.txt
```

Y iniciamos el servicio
```
systemctl start openvpn@servidor
```

*Muy importante que los clientes estén en default via de la red interna*


## Cliente

Ahora en este caso vamos a actuar como clientes de la VPN, por lo que vamos a crear una clave privada y un csr para la ocasión.

```
openssl genrsa -out clientito.key 4096
openssl req -new -key clientito.key -out clientito.csr
```
Le pasamos el csr y el servidor nos devolverá un clientito.crt y la CA.

Y hacemos el fichero de cliente.

```
dev tun
remote 172.22.0.56
ifconfig 10.99.99.0 255.255.255.0
pull
tls-client
ca /etc/openvpn/cert.crt
cert /etc/openvpn/clientito.crt
key /etc/openvpn/clientito.key
comp-lzo
keepalive 10 60
verb 3
```

Y iniciamos el servicio
```
systemctl start openvpn@paquito
```

Miramos si tenemos la interfaz tun
```
9: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/none 
    inet 10.99.99.6 peer 10.99.99.5/32 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::6c3b:e1e6:cb6c:e565/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```

Y intentamos hacer ping al cliente 192.168.1.2
```
root@pc-alex:/etc/openvpn# ping 192.168.1.2
PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
64 bytes from 192.168.1.2: icmp_seq=1 ttl=63 time=2.01 ms
64 bytes from 192.168.1.2: icmp_seq=2 ttl=63 time=1.72 ms
64 bytes from 192.168.1.2: icmp_seq=3 ttl=63 time=1.50 ms
64 bytes from 192.168.1.2: icmp_seq=4 ttl=63 time=1.48 ms
```

Si queremos que network-manager gestione la vpn, debemos primero instalar la extension
```
apt install network-manager-openvpn
```

Entramos en la configuración de Red de network-manager y nos saldrá una opción de VPN, le damos al +
![](/images/Networkmanager.png)

Y le damos a la opción de Añadir desde un fichero, y elegimos el fichero de configuración de antes y encendemos la VPN y volveremos a tener el tunel

![](/images/Networkmanager2.png)

![](/images/NetworkManager3.png)

```
10: tun1: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/none 
    inet 10.99.99.6 peer 10.99.99.5/32 brd 10.99.99.6 scope global noprefixroute tun1
       valid_lft forever preferred_lft forever
    inet6 fe80::c9b5:78e5:f191:53ec/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```


## OpenVPN Site to Site

Para realizar este ejercicio, necesitamos dos máquinas servidores , que actuarán a su vez como el cliente del otro.

Un servidor tendrá el direccionamiento 192.168.1.0/24 en su red interna y el otro con la 192.168.100.0/24 con sus respectivos clientes.

Ahora vamos a usar la herramienta easy-rsa para realizar este ejercicio

```
apt install openssl
```

Hacemos una carpeta easy-rsa en openvpn y copiamos el contenido de easy-rsa en ella
```
mkdir /etc/openvpn/easy-rsa

cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa
```

Ahora hacemos una copia del vars.example y debajo del todo ponemos esta configuración

```
cp vars.example vars
```

```
export EASY_RSA="`pwd`"
 
export OPENSSL="openssl"
export PKCS11TOOL="pkcs11-tool"
export GREP="grep"
 
export KEY_CONFIG=`$EASY_RSA/whichopensslcnf $EASY_RSA`
 
export KEY_DIR="$EASY_RSA/keys"
 
echo NOTE: If you run ./clean-all, I will be doing a rm -rf on $KEY_DIR
 
export PKCS11_MODULE_PATH="/usr/lib/changeme.so"
export PKCS11_PIN=vagrant
 
export KEY_SIZE=2048
export CA_EXPIRE=365
export KEY_EXPIRE=365
 
export KEY_COUNTRY="ES"
export KEY_PROVINCE="Sevilla"
export KEY_CITY="Dos Hermanas"
export KEY_ORG="alejandro.org"
export KEY_EMAIL="admin@alejandro.com"
export KEY_OU="OpenVPN"
 
export KEY_NAME=openVPN
 
export KEY_CN=alejandro.org
```

Hacemos un source para cargar las variables
```
source vars
```

Hacemos el diffie hellman y la unidad certificadora
```
root@server:/etc/openvpn/easy-rsa# ./easyrsa gen-dh
root@server:/etc/openvpn/easy-rsa# ./easyrsa build-ca
```

Creamos los parametros para el servidor

```
root@server:/etc/openvpn/easy-rsa# ./easyrsa build-server-full server
```


Y creamos los parametros para el host/cliente
```
root@server:/etc/openvpn/easy-rsa# ./easyrsa build-server-client-full host
```

Ahora hacemos el fichero servidor.conf
```
# nombre de la interfaz
dev tun
# Direcciones IP virtuales
ifconfig 10.99.99.1 10.99.99.2
# Subred eth1 de la maquina destino 
route 192.168.100.0 255.255.255.0
# Rol de Servidor
tls-server
# Parámetros Diffie-Hellman
dh /etc/openvpn/easy-rsa/pki/dh.pem
# #Certificado de la CA
ca /etc/openvpn/easy-rsa/pki/ca.crt
# Certificado Servidor
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
# Clave privada servidor
key /etc/openvpn/easy-rsa/pki/private/server.key
# Compresión LZO
comp-lzo
# Tiempo de vida
keepalive 10 60
# Fichero de log
log /var/log/server.log
# Nivel de Depuración
verb 6
askpass contra.txt
```


Ahora le pasamos al host/cliente los siguientes archivos

```
host.key
host.crt
ca.crt
```

Y el host/cliente tendrá la siguiente configuración
```
dev tun
ifconfig 10.99.99.2 10.99.99.1
#Ip eth0 servidor
remote 172.22.8.84
# Subred eth1 de la maquina destino 
route 192.168.1.0 255.255.255.0
tls-client
ca /etc/openvpn/ca.crt
cert /etc/openvpn/host.crt
key /etc/openvpn/host.key
comp-lzo
keepalive 10 60
log /var/log/host.log
verb 6
askpass pass.txt
```


Comprobamos que el cliente1 puede hacer ping al cliente 2

```
vagrant@local:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:8d:c0:4d brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 84128sec preferred_lft 84128sec
    inet6 fe80::a00:27ff:fe8d:c04d/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:ac:7e:28 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.2/24 brd 192.168.1.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:feac:7e28/64 scope link 
       valid_lft forever preferred_lft forever
vagrant@local:~$ ping 192.168.100.2
PING 192.168.100.2 (192.168.100.2) 56(84) bytes of data.
64 bytes from 192.168.100.2: icmp_seq=1 ttl=62 time=2.48 ms
64 bytes from 192.168.100.2: icmp_seq=2 ttl=62 time=2.73 ms
64 bytes from 192.168.100.2: icmp_seq=3 ttl=62 time=2.55 ms

```

Y que el cliente2 puede hacer ping al cliente1

```
root@cliente:~# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:8d:c0:4d brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 82285sec preferred_lft 82285sec
    inet6 fe80::a00:27ff:fe8d:c04d/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:ec:b7:25 brd ff:ff:ff:ff:ff:ff
    inet 192.168.100.2/24 brd 192.168.100.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:feec:b725/64 scope link 
       valid_lft forever preferred_lft forever
root@cliente:~# ping 192.168.1.2
PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
64 bytes from 192.168.1.2: icmp_seq=1 ttl=62 time=2.91 ms
64 bytes from 192.168.1.2: icmp_seq=2 ttl=62 time=2.85 ms
^C
--- 192.168.1.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 2.852/2.880/2.909/0.060 ms
```
