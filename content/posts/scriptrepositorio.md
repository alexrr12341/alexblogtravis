+++ 
date = "2019-10-02"
title = "Script para seleccionar paquetes por repositorio"
+++

## Script para seleccionar paquetes por repositorio
```
#!/bin/sh

echo "¿Que repositorio quieres buscar?(Debe estar en /etc/apt/sources.list)"

read repositorio

reposistema=`cat /etc/apt/sources.list | grep -o $repositorio | head -1`

#Aqui hacemos que si el repositorio está en el sistema avance el programa, sino simplemente finalice

if [ $repositorio = $reposistema ];

then

	echo "Repositorio encontrado"

	#Aqui encuentra los paquetes que estan instalados en el sistema

	for paquetes in $(dpkg -l | grep '^ii'| awk '{print $2}');

	do

		#Aqui está diciendo que si el repositorio se encuentra en el apt policy, entonces que mande por la terminal el paquete

		if [ $repositorio = $(apt policy $paquetes 2>/dev/null | egrep '\*\*\*' -A1 | tail -1 | awk '{print $2}') ];then

			echo $paquetes

		fi

	done

else

	echo "Este repositorio no existe"

fi
```
