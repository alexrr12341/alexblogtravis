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
root@server:/home/vagrant# openssl x509 -req -in clientevpn.csr -CA /root/ca/certs/ca.cert.pem -CAkey /root/ca/private/ca.key.pem -CAcreateserial -out clientevpn.crt
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
