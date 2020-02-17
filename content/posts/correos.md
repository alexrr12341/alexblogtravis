+++
date = "2019-09-30"
title = "Servidor de correos(Postfix)"
math = "true"

+++

## Servidor de correos Postfix

Primero de todo tenemos que tener instalado postfix
```
apt install postfix
```

Y en /etc/postfix/main.cf editamos las siguientes líneas
```
myhostname = alejandro.gonzalonazareno.org
relayhost = babuino-smtp.gonzalonazareno.org
```

Y en /etc/hosts tendremos la siguiente configuración
```
127.0.1.1 alejandro.gonzalonazareno.org croqueta.alejandro.gonzalonazareno.org croqueta
```

Y nuestro hostname será el siguiente:
```
root@croqueta:/home/debian# hostname -f
alejandro.gonzalonazareno.org
```

Reiniciamos postfix
```
systemctl restart postfix
```

Y enviamos un correo desde telnet a alexrodriguezrojas98@gmail.com

```
root@croqueta:/home/debian# telnet localhost 25
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
220 alejandro.gonzalonazareno.org ESMTP Postfix (Debian/GNU)
HELO correo.alejandro.gonzalonazareno.org
250 alejandro.gonzalonazareno.org
mail from: debian@alejandro.gonzalonazareno.org
250 2.1.0 Ok
rcpt to: alexrodriguezrojas98@gmail.com
250 2.1.5 Ok
data
354 End data with <CR><LF>.<CR><LF>
from: debian@alejandro.gonzalonazareno.org
to: alexrodriguezrojas98@gmail.com
subject: Prueba telnet

Hola, esto es una prueba para el ejercicio 1

.
250 2.0.0 Ok: queued as 32CA9218D3
quit
221 2.0.0 Bye
Connection closed by foreign host.
```

![](/images/telnet1.png)

Los logs del envio serían los siguientes
```
Feb 13 16:24:37 alejandro postfix/smtpd[4317]: disconnect from unknown[172.22.200.164] ehlo=2 starttls=1 mail=1 rcpt=0/1 quit=1 commands=5/6
Feb 13 16:24:49 alejandro postfix/smtpd[2409]: 32CA9218D3: client=localhost[127.0.0.1]
Feb 13 16:25:25 alejandro postfix/cleanup[4332]: 32CA9218D3: message-id=<20200213162449.32CA9218D3@alejandro.gonzalonazareno.org>
Feb 13 16:25:25 alejandro postfix/qmgr[7481]: 32CA9218D3: from=<debian@alejandro.gonzalonazareno.org>, size=494, nrcpt=1 (queue active)
Feb 13 16:25:25 alejandro postfix/smtp[4357]: 32CA9218D3: to=<alexrodriguezrojas98@gmail.com>, relay=babuino-smtp.gonzalonazareno.org[192.168.203.3]:25, delay=49, delays=49/0.04/0.06/0.04, dsn=2.0.0, status=sent (250 2.0.0 Ok: queued as A8465C9D5A)
```


Vamos a responder al correo anteriormente mandado y vamos a ver los logs  y el mensaje enviado.

Primero en nuestro servidor dns debemos añadir un registro MX para que pueda recibir el correo
```
@       IN      MX      10      correo.alejandro.gonzalonazareno.org.

$ORIGIN alejandro.gonzalonazareno.org.
....
correo          IN      CNAME   croqueta
....
```


Vamos a gmail y vamos a responder dicho email, ya que babuino tiene añadido nuestro dominio a su relay, dicho correo nos llegará.

![](/images/gmail.png)

Vamos a ver los logs:
```
Feb 13 17:08:24 alejandro postfix/smtpd[5125]: connect from babuino-smtp.gonzalonazareno.org[192.168.203.3]
Feb 13 17:08:24 alejandro postfix/smtpd[5125]: 6CA29218D4: client=babuino-smtp.gonzalonazareno.org[192.168.203.3]
Feb 13 17:08:24 alejandro postfix/cleanup[5129]: 6CA29218D4: message-id=<CAPN2xJRTNQoLS6WqUVCGMpQHyC=6Hbg9BAUCMgiL+pB8m-q01w@mail.gmail.com>
Feb 13 17:08:24 alejandro postfix/qmgr[5070]: 6CA29218D4: from=<alexrodriguezrojas98@gmail.com>, size=3834, nrcpt=1 (queue active)
Feb 13 17:08:24 alejandro postfix/smtpd[5125]: disconnect from babuino-smtp.gonzalonazareno.org[192.168.203.3] ehlo=1 mail=1 rcpt=1 data=1 quit=1 commands=5
Feb 13 17:08:24 alejandro postfix/local[6594]: 6CA29218D4: to=<debian@alejandro.gonzalonazareno.org>, relay=local, delay=0.16, delays=0.06/0.06/0/0.04, dsn=2.0.0, status=sent (delivered to mailbox)
Feb 13 17:08:24 alejandro postfix/qmgr[5070]: 6CA29218D4: removed

```

Vemos que se conecta a babuino, y este delega el mensaje hacia mi dominio, ynos lo envia, estará en nuestro mailbox

debian@croqueta:~$ mail
```
From: Alejandro Rodriguez Rojas <alexrodriguezrojas98@gmail.com>
Date: Thu, 13 Feb 2020 18:08:09 +0100
Message-ID: <CAPN2xJRTNQoLS6WqUVCGMpQHyC=6Hbg9BAUCMgiL+pB8m-q01w@mail.gmail.com>
Subject: Re: Prueba telnet
To: Debian <debian@alejandro.gonzalonazareno.org>
Content-Type: multipart/alternative; boundary="000000000000cff3b1059e7822a2"

--000000000000cff3b1059e7822a2
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

Hola, te respondo de vuelta, gracias.

```
