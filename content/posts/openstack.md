+++
date = "2020-02-28"
title = "Instalación de Openstack con Kolla-Ansible"
math = "true"

+++

## Instalación de Openstack con Kolla-Ansible

Vamos a preparar un escenario que se basará en 3 máquinas, 1 máquina será el instalador, otra será el controlador y otra será el computador, por lo que vamos a empezar a realizar las siguientes configuraciones:




### Configuración inicial

Vamos primero a hacer nuestras dos máquinas master y compute para la instalación (ambas máquinas tienen que tener instaladas python-dev, también añadirle contraseña a root y editar el fichero /etc/ssh/sshd_config)
```
Vagrant.configure("2") do |config|
  config.vm.define :instalador do |instalador|
    instalador.vm.box = "ubuntu/bionic64"
    instalador.vm.hostname = "instalador"
    instalador.vm.network :public_network, :bridge=>"enp7s0"
  end
  config.vm.define :master do |master|
    master.vm.box = "ubuntu/bionic64"
    master.vm.hostname = "master"
    master.vm.network :public_network, :bridge=>"enp7s0"
    master.vm.network :private_network, ip: "10.10.1.2", virtualbox__intnet: "redinterna"
    master.vm.network :public_network, :bridge=>"enp7s0"
    master.vm.provider "virtualbox" do |mv|
      mv.customize ["modifyvm", :id, "--memory", "5120"]
    end
  end
  config.vm.define :compute do |compute|
    compute.vm.box = "ubuntu/bionic64"
    compute.vm.hostname = "compute"
    compute.vm.network :public_network, :bridge=>"enp7s0"
    compute.vm.network :private_network, ip: "10.10.1.3", virtualbox__intnet: "redinterna"
    compute.vm.provider "virtualbox" do |mv|
      mv.customize ["modifyvm", :id, "--memory", "3072"]
    end
  end
end


```
s
Máquina master:
```
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:fd:cc:1f brd ff:ff:ff:ff:ff:ff
    inet 172.22.0.142/16 brd 172.22.255.255 scope global dynamic enp0s8
       valid_lft 1715sec preferred_lft 1715sec
    inet6 fe80::a00:27ff:fefd:cc1f/64 scope link 
       valid_lft forever preferred_lft forever
4: enp0s9: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:13:c3:6f brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.3/24 scope global enp0s9
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe13:c36f/64 scope link 
       valid_lft forever preferred_lft forever
5: enp0s10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:7f:25:b9 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::a00:27ff:fe7f:25b9/64 scope link tentative 
       valid_lft forever preferred_lft forever

```

Máquina compute:
```
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:6c:32:58 brd ff:ff:ff:ff:ff:ff
    inet 172.22.7.111/16 brd 172.22.255.255 scope global dynamic enp0s8
       valid_lft 1771sec preferred_lft 1771sec
    inet6 fe80::a00:27ff:fe6c:3258/64 scope link 
       valid_lft forever preferred_lft forever
4: enp0s9: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:d1:69:af brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.4/24 scope global enp0s9
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fed1:69af/64 scope link 
       valid_lft forever preferred_lft forever

```

Fichero /etc/ssh/sshd_config
```
PermitRootLogin yes
PasswordAuthentication yes
```

En nuestro /etc/hosts añadimos la siguiente información
```
172.22.0.142    master
172.22.7.111    compute 
```

### Nodo instalador

Todas las máquinas se basarán en ubuntu 18.04 por lo que nuestro instalador también será de dicha distribución

```
ubuntu@instalador:~$ source pythonvirtual/openstack/bin/activate
(openstack) ubuntu@instalador:~$ pip install -U pip
apt install python-dev libffi-dev gcc libssl-dev python-selinux sshpass python3-dev build-essential libssl-dev libffi-dev libxml2-dev libxslt1-dev zlib1g-dev
(openstack) ubuntu@instalador:~$ pip install -U ansible
``` 

Ahora instalamos kolla-ansible
```
(openstack) ubuntu@instalador:~$ pip install -U kolla-ansible
```

Creamos el directorio /etc/kolla
```
sudo mkdir -p /etc/kolla
sudo chown $USER:$USER /etc/kolla
```

Copiamos los ficheros necesarios para el despliegue de openstack

```
(openstack) ubuntu@instalador:~$ cp -r pythonvirtual/openstack/share/kolla-ansible/etc_examples/kolla/* /etc/kolla/
```

Y también el directorio desde el que vamos a trabajar el inventario para el multinodo
```
(openstack) ubuntu@instalador:~$ mkdir openstack

(openstack) ubuntu@instalador:~/openstack$ cp ~/pythonvirtual/openstack/share/kolla-ansible/ansible/inventory/* .
```

### Ansible

Ahora vamos a crear el fichero /etc/ansible/ansible.cfg

```
sudo mkdir /etc/ansible
sudo nano /etc/ansible/ansible.cfg

[defaults]
host_key_checking=False
pipelining=True
forks=100

sudo chown -R $USER:$USER /etc/ansible
```

Ahora vamos a nuestra carpeta de openstack y vamos al fichero multinode y realizamos lo siguiente
```
[control]
master ansible_user=root ansible_password=password

[network:children]
control

[compute]
compute ansible_user=root ansible_password=password

[monitoring:children]
control

[storage:children]
control

[deployment]
localhost ansible_connection=local
```


Miramos si podemos hacerle ping
```
(openstack) alexrr@pc-alex:~/openstack$ ansible -i multinode all -m ping
localhost | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
master | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
compute | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"}



```


Ahora vamos a instalarle a todas las máquinas python-dev con el siguiente comando
```
ansible -i multinode all -m raw -a "apt-get -y install python3-dev"
```


### Kolla Passwords

Para que kolla tenga contraseñas,vamos a generar las contraseñas con el siguiente comando
```
kolla-genpwd
```


### Kolla Globals.yml

Editamos el siguiente fichero, kolla recomienda usar Ubuntu o centos, por lo que en este caso vamos a utilizar ubuntu

```
kolla_base_distro: "ubuntu" # Base de ubuntu

kolla_install_type: "binary" # Para repositorios apt

openstack_release: "train" # Version de openstack
network_interface: "enp0s9" # Interfaz interna
neutron_external_interface: "enp0s10" # Interfaz externa que está conectada a br0 sin ip
kolla_internal_vip_address: "10.10.10.254" # Ip para gestionar interfaz interna
kolla_external_vip_address: "172.22.153.1" # Ip para gestionar interfaz externa
enable_cinder: "yes"


```



Y vamos a preparar el deploy, para ello primero preparamos las dependencias en los nodos
```
kolla-ansible -i multinode bootstrap-servers
```

Comprobamos que todo está listo:
```
kolla-ansible -i multinode prechecks
```

Continuará.
