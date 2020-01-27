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


Hacemos el fichero diffie hellman
```
openssl dhparam -out /root/private/dh.pem 2048
```

Hacemos la CA
```
mkdir /etc/openvpn/claves
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

![](/images/Networkmanager3.png)

```
10: tun1: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/none 
    inet 10.99.99.6 peer 10.99.99.5/32 brd 10.99.99.6 scope global noprefixroute tun1
       valid_lft forever preferred_lft forever
    inet6 fe80::c9b5:78e5:f191:53ec/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```
