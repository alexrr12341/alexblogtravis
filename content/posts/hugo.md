+++
date = "2019-09-30"
title = "Primeros pasos de Hugo"
math = "true"

+++

## Instalación de Hugo

*Para instalar el generador Hugo simplemente debemos ejecutar el siguiente comando en la terminal*
```
apt-get install hugo
```

* Hugo utiliza el lenguaje de programación Go
* Hugo utiliza el sistema de plantillas Go

*Para crear un sitio web solo debemos ejecutar el siguiente comando en la terminal*
```
hugo new site {nombre}
```

## Configuración del theme

*Primero debemos elegir la plantilla Go que queramos y hacemos un git clone(debemos ponerla en la carpeta themes)*
```
alexrr@pc-alex:~/Hugo/MiWeb/themes$ git clone https://github.com/naro143/hugo-coder-portfolio
```


Y ahora para coger el markdown de prueba de la página realizamos el comando:
```
alexrr@pc-alex:~/Hugo/MiWeb/themes/hugo-coder-portfolio$ cp -r exampleSite/* ~/Hugo/MiWeb/
```

*Para cambiar el nombre de la página modificamos del fichero config.toml la linea:*
```
title = "Alexblog"
```

*El tema de la página tendremos que añadirlo en el config.toml*
```
theme = "hugo-coder-portfolio"
```
