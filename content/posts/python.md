+++
date = "2019-12-10"
title = "Instalación de Python3 Makefile"
math = "true"

+++

h2. Instalación de Python

https://www.python.org/downloads/

```
tar -xf Python-3.8.0.tar.xz
```

Y ejecutamos el configure
```
mkdir /opt/python3
./configure --prefix=/opt/python3
```

```
make
```

Nos saltará una dependencia
```
 zipimport.ZipImportError: can't decompress data; zlib not available
```
El paquete de esta dependencia es zlib1g-dev

```
apt install zlib1g-dev
```

Y ahora lo instalamos
```
make
make install
```
