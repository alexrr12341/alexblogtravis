+++
date = "2020-01-16"
title = "Integración Continua estática y Django"
math = "true"

+++

## Despliegue de una página web estática

Vamos a realizar una integración continua de este mismo blog en githubpages con travis, nuestra aplicación es de Hugo.
Para ello crearemos un repositorio en github que solo contenga los ficheros markdown.

<pre>
alexrr@pc-alex:~/Hugo$ git@github.com:alexrr12341/alexblogcontinuo.git
alexrr@pc-alex:~/Hugo$ cp -r alexblog alexblogcontinuo/
</pre>

Vamos ahora a borrar la carpeta public que es la que contiene los htmls
<pre>
alexrr@pc-alex:~/Hugo/alexblogcontinuo$ rm -r public/
</pre>

Ahora vamos a hacer nuestro fichero travis y vamos a modificarlo para que instale hugo y ejecute el comando (.travis.yml).

