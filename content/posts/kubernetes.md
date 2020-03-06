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

Antes de la instalación, debemos cambiar las reglas de iptables a iptables legacy, para ello hacemos:
```
sudo apt-get install -y iptables arptables ebtables

sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy
```

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


## Creación del namespace

Vamos a trabajar con un namespace que se llamará wordpress.

Para ello crearemos el siguiente fichero:

wordpress-name.yml
```
apiVersion: v1
kind: Namespace
metadata:
  name: wordpress
```

Y lo ejecutaremos con kubectl
```
kubectl create -f wordpress-name.yml 
namespace/wordpress created

```


## Uso de secretos 

Los secretos sirven para que las variables no se envien de forma clara, aunque el método de encriptación es de base64, sirve para ciertas páginas web de gestión de versiones donde no podemos enviar la contraseña en claro.
Para ello hacemos el fichero con el siguiente comando

```
kubectl create secret generic mariadb-secret --namespace=wordpress \
                            --from-literal=dbuser=wordpress \
                            --from-literal=dbname=wordpress \
                            --from-literal=dbpassword=wordpress \
                            --from-literal=dbrootpassword=root \
                            -o yaml --dry-run > maria-secreto.yaml
```

Vamos a añadir el secreto:
```
kubectl create -f maria-secreto.yaml 
```

Vamos a crear ahora el servicio de clusterIP para que las máquinas se puedan comunicar, para ello hacemos un fichero mariadb-service.yml
```
apiVersion: v1
kind: Service
metadata:
  name: mariadb-service
  namespace: wordpress
  labels:
    app: wordpress
    type: database
spec:
  selector:
    app: wordpress
    type: database
  ports:
  - port: 3306
    targetPort: db-port
  type: ClusterIP 
```

Y lo añadimos a kubectl
```
kubectl create -f mariadb-service.yml 
```

Ahora vamos a realizar el deploy de mariadb, para ello hacemos un fichero mariadb-deploy.yml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-deployment
  namespace: wordpress
  labels:
    app: wordpress
    type: database
spec:
  selector:
    matchLabels:
      app: wordpress
  replicas: 1
  template:
    metadata:
      labels:
        app: wordpress
        type: database
    spec:
      containers:
        - name: mariadb
          image: mariadb
          ports:
            - containerPort: 3306
              name: db-port
          env:
            - name: MYSQL_USER
              valueFrom:
                secretKeyRef:
                  name: mariadb-secret
                  key: dbuser
            - name: MYSQL_DATABASE
              valueFrom:
                secretKeyRef:
                  name: mariadb-secret
                  key: dbname
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mariadb-secret
                  key: dbpassword
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mariadb-secret
                  key: dbrootpassword
```

Vamos ahora a hacer el deploy de mariadb, para ello
```
kubectl create -f mariadb-deploy.yml 
```

Miramos que están correctamente creados
```
debian@kubeadm:~$ kubectl get deploy,service,pods -n wordpress
NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mariadb-deployment   0/1     1            0           19s

NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/mariadb-service   ClusterIP   10.103.114.107   <none>        3306/TCP   5m20s

NAME                                      READY   STATUS              RESTARTS   AGE
pod/mariadb-deployment-7bdff7c967-w4hmw   0/1     ContainerCreating   0          19s
```


Ahora vamos a realizar el wordpress, por lo que como antes, vamos a realizar el servicio de Nodeport, que hará que podamos conectarnos a él desde el exterior.

wordpress-service.yml
```
apiVersion: v1
kind: Service
metadata:
  name: wordpress-service
  namespace: wordpress
  labels:
    app: wordpress
    type: frontend
spec:
  selector:
    app: wordpress
    type: frontend
  ports:
  - name: http-sv-port 
    port: 80
    targetPort: http-port
  - name: https-sv-port
    port: 443
    targetPort: https-port
  type: NodePort 
```

Ahora lanzamos el wordpreess.
```
kubectl create -f wordpress-service.yml
```

Ahora vamos a realizar el deploy de wordpress, para ello:

wordpress-deploy.yml
```

apiVersion: apps/v1     
kind: Deployment
metadata:
  name: wordpress-deployment
  namespace: wordpress
  labels:
    app: wordpress
    type: frontend
spec:
  selector:
    matchLabels:
      app: wordpress
  replicas: 1      
  template:
    metadata:
      labels:
        app: wordpress
        type: frontend
    spec:
      containers:
        - name: wordpress
          image: wordpress
          ports:
            - containerPort: 80
              name: http-port
            - containerPort: 443
              name: https-port
          env:
            - name: WORDPRESS_DB_HOST
              value: mariadb-service
            - name: WORDPRESS_DB_USER
              valueFrom:
                secretKeyRef:
                  name: mariadb-secret
                  key: dbuser
            - name: WORDPRESS_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mariadb-secret
                  key: dbpassword
            - name: WORDPRESS_DB_NAME
              valueFrom:
                secretKeyRef:
                  name: mariadb-secret
                  key: dbname


```

Y ahora realizamos el deploy en kubernetes
```
kubectl create -f wordpress-deploy.yml
```


