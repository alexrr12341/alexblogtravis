+++
date = "2020-01-16"
title = "Integración Continua estática y Django"
math = "true"

+++

## Despliegue de una página web estática

Vamos a realizar una integración continua de este mismo blog en githubpages con travis, nuestra aplicación es de Hugo.
Para ello crearemos un repositorio en github que solo contenga los ficheros markdown.

```
alexrr@pc-alex:~/Hugo$ git@github.com:alexrr12341/alexblogtravis.git
alexrr@pc-alex:~/Hugo$ cp -r alexblog/* alexblogtravis/
```

Vamos ahora a borrar la carpeta public que es la que contiene los htmls
```
alexrr@pc-alex:~/Hugo/alexblogtravis$ rm -r public/
```

Ahora vamos a hacer nuestro fichero travis y vamos a modificarlo para que instale hugo y ejecute el comando (.travis.yml), luego meterá la carpeta public en gh-pages, esta integración será la utilizada para el blog www.alexrrinformatico.com

```
dist: xenial
language: python
python:
  - "3.7"

before_install:
  - sudo apt-get update -qq
  - sudo apt-get -yq install apt-transport-https tor curl

# install - install any dependencies required
install:
    # install latest release version
    # Github may forbid request from travis container, so use tor proxy
    - sudo systemctl start tor
    # - curl -fsL --socks5-hostname 127.0.0.1:9050 https://api.github.com/repos/gohugoio/hugo/releases/latest | sed -r -n '/browser_download_url/{/Linux-64bit.deb/{s@[^:]*:[[:space:]]*"([^"]*)".*@\1@g;p;q}}' | xargs wget
    - download_command='curl -fsSL -x socks5h://127.0.0.1:9050' # --socks5-hostname
    - $download_command -O $($download_command https://api.github.com/repos/gohugoio/hugo/releases/latest | sed -r -n '/browser_download_url/{/Linux-64bit.deb/{s@[^:]*:[[:space:]]*"([^"]*)".*@\1@g;p;q}}')
    - sudo dpkg -i hugo*.deb
    - rm -rf public 2> /dev/null

# script - run the build script
script:
    - hugo --theme=hugo-coder-portfolio
    - echo "$CNAME_URL" > public/CNAME
# Deploy to GitHub pages
deploy:
  provider: pages
  skip_cleanup: true
  local_dir: public
  github_token: $GITHUB_TOKEN # Set in travis-ci.org dashboard
  on:
    branch: master
```

Este fichero lo que hará será instalar apt-transfport-https para que podamos descargar la última versión de hugo, instalarla, lanzar el comando hugo y subirlo a githubpages en nuestro repositorio https://github.com/alexrr12341/alexblogtravis

Después, debemos modificar una pequeña parte de github para que la página de github pages tenga el dominio www.alexrrinformatico.com y su branch sea gh-pages

![](/images/gh-pages.png)

En nuestro repositorio, vamos a Settings, vamos al apartado de GitHub Pages(está mas abajo), en source ponemos la rama gh-pages y el custom domain, en caso de tenerlo.


Ahora vamos a comprobar la integración continua con este mismo post, sacaremos antes de una actualización una foto sin estos contenidos y luego haremos:

```
alexrr@pc-alex:~/Hugo/alexblogtravis$ git add *
alexrr@pc-alex:~/Hugo/alexblogtravis$ git commit -am "Prueba Travis"
[master 17683d4] Prueba Travis
 3 files changed, 61 insertions(+), 8 deletions(-)
 create mode 100644 themes/hugo-coder-portfolio/static/images/gh-pages.png
 create mode 100644 themes/hugo-coder-portfolio/static/images/ic-travis.png
alexrr@pc-alex:~/Hugo/alexblogtravis$ git push
X11 forwarding request failed on channel 0
Enumerando objetos: 19, listo.
Contando objetos: 100% (19/19), listo.
Compresión delta usando hasta 8 hilos
Comprimiendo objetos: 100% (10/10), listo.
Escribiendo objetos: 100% (11/11), 109.47 KiB | 903.00 KiB/s, listo.
Total 11 (delta 5), reusado 0 (delta 0)
remote: Resolving deltas: 100% (5/5), completed with 5 local objects.
To github.com:alexrr12341/alexblogtravis.git
   a318731..17683d4  master -> master
```

![](/images/ic-travis.png)

La información llega a Travis:
![](/images/ic-travis2.png)
![](/images/ic-travis3.png)

Y efectivamente está actualizado nuestro blog:
![](/images/ic-travis4.png)
