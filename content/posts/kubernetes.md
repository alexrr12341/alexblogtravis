+++
date = "2020-03-04"
title = "Instalación de Kubernetes (Kubeadm)"
math = "true"

+++

## Instalación de Kubernetes

Disponemos de 3 máquinas para realizar la configuración de un cluster de Kubernetes, para ejecutar las máquinas podemos usar 3 instancias de openstack o usando el siguiente script de vagrant para libvirt:
```
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
  config.vm.define :kubeadm do |kubeadm|
    kubeadm.vm.box = "debian/buster64"
    kubeadm.vm.hostname = "kubeadm"
    kubeadm.vm.provider :libvirt do |libvirt|
      libvirt.cpus = 2
      libvirt.memory = 2048
      libvirt.qemu_use_session = true
      libvirt.uri = 'qemu:///session'
      libvirt.system_uri = 'qemu:///system'
    end
  end
  config.vm.define :nodo1 do |nodo1|
    nodo1.vm.box = "debian/buster64"
    nodo1.vm.hostname = "nodo1"
    nodo1.vm.provider :libvirt do |libvirt1|
      libvirt1.cpus = 2
      libvirt1.memory = 2048
      libvirt1.qemu_use_session = true
      libvirt1.uri = 'qemu:///session'
      libvirt1.system_uri = 'qemu:///system'
    end
  end
 config.vm.define :nodo2 do |nodo2|
    nodo2.vm.box = "debian/buster64"
    nodo2.vm.hostname = "nodo2"
    nodo2.vm.provider :libvirt do |libvirt2|
      libvirt2.cpus = 2
      libvirt2.memory = 2048
      libvirt2.qemu_use_session = true
      libvirt2.uri = 'qemu:///session'
      libvirt2.system_uri = 'qemu:///system'
    end
  end
end

```

En mi caso voy a usar las instancias de openstack debido a que mi ordenador no soporta el peso de instalación de kubeadm, por lo que tendremos una máquina kubeadm, que es la master y nodo1 y nodo2 que serán los slaves, en mi caso las máquinas serán Debian Buster 10.3.


Vamos a instalar docker.io en todas las máquinas
```
root@kubeadm:/home/debian# apt install docker.io
root@nodo2:/home/debian# apt install docker.io
root@nodo1:/home/debian# apt install docker.io

```


En la máquina Kubeadm instalamos los requisitos necesarios para instalar kubeadm

```
sudo apt-get update && sudo apt-get install -y apt-transport-https curl gnupg2
```

Importamos la clave de kubernetes
```
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
```

Y hacemos el repositorio de kubernetes
```
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
```

Actualizamos y instalamos kubeadm y kubectl
```
root@kubeadm:/home/debian# apt update
root@kubeadm:/home/debian# apt install -y kubelet kubeadm kubectl
```

Retenemos kubelet, kubeadm y kubectl para que no se actualice de forma automatica
```
debian@kubeadm:/home/debian# apt-mark hold kubelet kubeadm kubectl
```

Apagamos la swap
```
root@kubeadm:/home/debian# swapoff -a
```

Vamos a iniciar kubeadm
```
root@kubeadm:/home/debian# kubeadm init --pod-network-cidr=192.168.100.0/24 --apiserver-cert-extra-sans=172.22.201.144
```

Vamos a ejecutar los comandos que nos indican a la hora de iniciar kubeadm
```
debian@kubeadm:~$ mkdir -p $HOME/.kube
debian@kubeadm:~$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
debian@kubeadm:~$ sudo chown $(id -u):$(id -g) $HOME/.kube/config

```

Ahora con Calico vamos a permitir la comunicación de kubernetes con otros nodos, por lo que vamos a instalarlo para configurar todos los nodos
```
debian@kubeadm:~$ kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

```


## Configuración Multinodo

El token para conectarnos hacia la máquina nos la da al instalar kubeadm en la máquina kubeadm, por lo que en el nodo1 y nodo2 realizaremos lo siguiente para conectarnos (para poder realizar dicha accion vamos a instalar también kubeadm en los nodos como hemos realizado arriba)
```

debian@nodo1:/home/debian# kubeadm join 10.0.0.16:6443 --token 5tir3z.7brpoop4876rlcn4 --discovery-token-ca-cert-hash sha256:ab9e0dc778410b230d8d03c69167117e27392880f4e2a7d09bea78bf84fd0914
debian@nodo2:/home/debian# kubeadm join 10.0.0.16:6443 --token 5tir3z.7brpoop4876rlcn4 --discovery-token-ca-cert-hash sha256:ab9e0dc778410b230d8d03c69167117e27392880f4e2a7d09bea78bf84fd0914
```

Miramos que están conectadas al cluster

```
debian@kubeadm:~$ kubectl get nodes
NAME      STATUS   ROLES    AGE   VERSION
kubeadm   Ready    master   3m    v1.17.3
nodo1     Ready    <none>   89s   v1.17.3
nodo2     Ready    <none>   65s   v1.17.3


```



## Aplicación web con Kubernetes

Ahora que tenemos ya kubeadm configurado, vamos a instalar un wordpress en un pod, y un mariadb en otro, por lo que vamos a hacer la configuración necesaria para instalarlo


## Creación de volúmenes persistentes para mariadb y wordpress

Vamos a crear la carpeta para guardar los volúmenes
```
root@kubeadm:~# mkdir -p /kubernetes/vol
```

Vamos a crear el fichero vols.yaml de la siguiente manera
```
apiVersion: v1
kind: PersistentVolume
metadata:
    name: wordpress-vol
    labels:
      type: local
spec:
   capacity:
     storage: 2Gi
   accessModes:
     - ReadWriteMany
   hostPath:
     path: /kubernetes/vol/wordpress-vol
---
apiVersion: v1
kind: PersistentVolume
metadata:
   name: mariadb-vol
   labels:
     type: local
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: /kubernetes/vol/mariadb-vol
```

Vamos a crear los volumenes
```
debian@kubeadm:~$ kubectl apply -f vols.yaml
persistentvolume/wordpress-vol created
persistentvolume/mariadb-vol created


```

## Creación de la base de datos Mariadb

Vamos ahora a crear un objeto secreto, que sirve para que no podamos enviar la contraseña de mariadb en claro a otros usuarios, y poder utilizarla con kubernetes, para ello realizamos lo siguiente:
```
kubectl create secret generic mysql-pass --from-literal=password="{contraseña}"
secret/mysql-pass created

```
