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


## Integración continua de aplicación Django

Clonamos el repositorio de django_tutorial

```
git clone git@github.com:alexrr12341/django_tutorial.git
```

Vamos a ejecutar las pruebas haciendo el siguiente comando

```
(pythonreqs) alexrr@pc-alex:~/django_tutorial$ python3 manage.py test
Creating test database for alias 'default'...
System check identified no issues (0 silenced).
..........
----------------------------------------------------------------------
Ran 10 tests in 0.046s

OK
Destroying test database for alias 'default'...
```



Observamos tests.py y vemos el siguiente código

```
def test_future_question(self):
        """
        Questions with a pub_date in the future aren't displayed on
        the index page.
        """
        create_question(question_text="Future question.", days=30)
        response = self.client.get(reverse('polls:index'))
        self.assertContains(response, "No polls are available.")
        self.assertQuerysetEqual(response.context['latest_question_list'], []
```

Ahora nos vamos a dirigir a django_tutorial/polls/templates/polls/index.html y modificamos la siguiente línea

```
{% else %}
    <p>No encuestas están permitidas.</p>
```

Vamos a ejecutar el test a ver que ocurre.

```
(pythonreqs) alexrr@pc-alex:~/django_tutorial$ python3 manage.py test
Creating test database for alias 'default'...
System check identified no issues (0 silenced).
..F.F.....
======================================================================
FAIL: test_future_question (polls.tests.QuestionIndexViewTests)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/alexrr/django_tutorial/polls/tests.py", line 79, in test_future_question
    self.assertContains(response, "No polls are available.")
  File "/home/alexrr/django_tutorial/pythonreqs/lib/python3.7/site-packages/django/test/testcases.py", line 454, in assertContains
    self.assertTrue(real_count != 0, msg_prefix + "Couldn't find %s in response" % text_repr)
AssertionError: False is not true : Couldn't find 'No polls are available.' in response

======================================================================
FAIL: test_no_questions (polls.tests.QuestionIndexViewTests)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/alexrr/django_tutorial/polls/tests.py", line 57, in test_no_questions
    self.assertContains(response, "No polls are available.")
  File "/home/alexrr/django_tutorial/pythonreqs/lib/python3.7/site-packages/django/test/testcases.py", line 454, in assertContains
    self.assertTrue(real_count != 0, msg_prefix + "Couldn't find %s in response" % text_repr)
AssertionError: False is not true : Couldn't find 'No polls are available.' in response

----------------------------------------------------------------------
Ran 10 tests in 0.034s

FAILED (failures=2)
Destroying test database for alias 'default'...
```

Efectivamente nos salta un error, ya que tiene que poner "No Polls are available."


Ahora vamos a realizar un .travis.yml para que podamos hacer la integración continua, dicho fichero será:

```
language: python
python:
  - "3.8"
# command to install dependencies
install:
  - pip3 install -r requirements.txt
# command to run tests
script: python3 manage.py test
```

Este script lo que hará es ejecutar el test, si da error travis lo mostrará y si no, no lo mostrará.

Vamos a modificar django_tutorial/polls/templates/polls/index.html y pondremos

```
{% else %}
    <p>No polls are available.</p>

```

![](/images/travisdjango.png)

Y ahora vamos a forzar el error poniendo en el mismo fichero

```
{% else %}
    <p>No encuestas están disponibles</p>   
```

![](/images/travisdjangoerror.png)


Ahora vamos a realizar la integración continua en PythonAnywhere.


Vamos a acceder a la consola de pythonanywhere y vamos a poner lo siguiente

```
git clone https://github.com/alexrr12341/django_tutorial.git
python3 -m venv envi
10:13 ~ $ source envi/bin/activate                                                                                                                                                                                
(envi) 10:14 ~ $ pip3 install -r django_tutorial/requirements.txt 
```

A la hora de darle a la pestaña de Web, le daremos a la opción de Manual Configuration y seleccionaremos la opción de Python3.7


En el apartado Virtual Env ponemos
```
/home/Alexrr/envi (El nombre de nuestro entorno virtual)
```

En el apartado Code ponemos

```
WSGI configuration file: /var/www/alexrr_pythonanywhere_com_wsg

# +++++++++++ DJANGO +++++++++++
# To use your own Django app use code like this:
import os
import sys

# assuming your Django settings file is at '/home/myusername/mysite/mysite/settings.py'
path = '/home/Alexrr/django_tutorial'
if path not in sys.path:
    sys.path.insert(0, path)

os.environ['DJANGO_SETTINGS_MODULE'] = 'django_tutorial.settings'

## Uncomment the lines below depending on your Django version
###### then, for Django >=1.5:
from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()
###### or, for older Django <=1.4
#import django.core.handlers.wsgi
#application = django.core.handlers.wsgi.WSGIHandler()
```

También vamos a entrar a la consola y haremos el migrate

```
(envi) 11:08 ~/django_tutorial (master)$ python3 manage.py migrate                                                                                                                                                
```

Como último debemos añadir nuestro allowed_host en el settings.py

```
ALLOWED_HOSTS = ['alexrr.pythonanywhere.com']
```

![](/images/pythonanywheredeploy.png)


Vamos a preparar nuestro entorno de produccion haciendo los siguientes comandos:

```
(envi) 11:33 ~/django_tutorial (master)$ mkdir .travis                                                                                                                                                            
(envi) 11:34 ~/django_tutorial (master)$ cd .travis/                                                                                                                                                              
(envi) 11:34 ~/django_tutorial/.travis (master)$ ssh-keygen -t rsa -b 4096 -C 'hallo@example.com' -f deploy_key    

```
