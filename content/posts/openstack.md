+++
date = "2020-02-28"
title = "Instalación de Openstack con Kolla-Ansible"
math = "true"

+++

## Instalación de Openstack con Kolla-Ansible

Vamos a preparar un escenario que se basará en 3 máquinas, 1 máquina será el instalador, otra será el controlador y otra será el computador, por lo que vamos a empezar a realizar las siguientes configuraciones:

### Nodo instalador

Nuestro nodo instalador se basará en una máquina Debian Buster, por lo que vamos a empezar instalando las siguientes dependencias:

```
alexrr@pc-alex:~$ source pythonvirtual/openstack/bin/activate
(openstack) alexrr@pc-alex:~$ pip install -U pip
apt install python-dev libffi-dev gcc libssl-dev python-selinux sshpass python3-dev build-essential libssl-dev libffi-dev libxml2-dev libxslt1-dev zlib1g-dev
(openstack) alexrr@pc-alex:~$ pip install -U ansible
``` 

Ahora instalamos kolla-ansible
```
(openstack) alexrr@pc-alex:~$ pip install -U kolla-ansible
```

Creamos el directorio /etc/kolla
```
sudo mkdir -p /etc/kolla
sudo chown $USER:$USER /etc/kolla
```

Copiamos los ficheros necesarios para el despliegue de openstack

```
(openstack) alexrr@pc-alex:~$ cp -r pythonvirtual/openstack/share/kolla-ansible/etc_examples/kolla/* /etc/kolla/
```

Y también el directorio desde el que vamos a trabajar el inventario para el multinodo
```
(openstack) alexrr@pc-alex:~$ mkdir openstack

(openstack) alexrr@pc-alex:~/openstack$ cp ~/pythonvirtual/openstack/share/kolla-ansible/ansible/inventory/* .
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

## Bridges

En nuestro /etc/network/interfaces vamos a crear un bridge 1 y un bridge 0, por lo que el bridge 1 contendrá la ip interna de openstack y el bridge 0 tendrá la ip externa y estará conectada a nuestra red ethernet
```
auto br0
iface br0 inet dhcp
        bridge_ports enp7s0
	
```

Y hacemos el br1 con los siguientes comandos
```
brctl addbr br1
ip a add 10.10.10.1/24 dev br1
ip l set br1 up
ip addr add 10.10.10.1/24 brd + dev br1
```

### Configuración inicial

Vamos primero a hacer nuestras dos máquinas master y compute para la instalación (ambas máquinas tienen que tener instaladas python-dev, también añadirle contraseña a root y editar el fichero /etc/ssh/sshd_config)
```
Vagrant.configure("2") do |config|

  config.vm.define :master do |master|
    master.vm.box = "ubuntu/bionic64"
    master.vm.hostname = "master"
    master.vm.synced_folder '.', '/vagrant', :disabled => true
    master.vm.network :public_network, :bridge => 'enp7s0'
    master.vm.provider :virtualbox do |v|
                    v.customize ["modifyvm", :id, "--memory", 2048]
            end
  end
  config.vm.define :compute do |compute|
    compute.vm.box = "ubuntu/bionic64"
    compute.vm.hostname = "compute"
    compute.vm.synced_folder '.', '/vagrant', :disabled => true
    compute.vm.network :public_network, :bridge => 'enp7s0'
    compute.vm.provider :virtualbox do |v|
                    v.customize ["modifyvm", :id, "--memory", 2048]
            end
  end
end

```

Fichero /etc/ssh/sshd_config
```
PermitRootLogin yes
PasswordAuthentication yes
```

En nuestro /etc/hosts añadimos la siguiente información
```
192.168.1.64    master
192.168.1.39    compute 
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
[DEPRECATION WARNING]: Distribution Ubuntu 18.04 on host master should use /usr/bin/python3, but is using /usr/bin/python for backward compatibility with prior Ansible releases. A future Ansible release will 
default to using the discovered platform python for this host. See https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information. This feature will be removed in 
version 2.12. Deprecation warnings can be disabled by setting deprecation_warnings=False in ansible.cfg.
master | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
[DEPRECATION WARNING]: Distribution Ubuntu 18.04 on host compute should use /usr/bin/python3, but is using /usr/bin/python for backward compatibility with prior Ansible releases. A future Ansible release will 
default to using the discovered platform python for this host. See https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information. This feature will be removed in 
version 2.12. Deprecation warnings can be disabled by setting deprecation_warnings=False in ansible.cfg.
compute | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}


```

Si queremos quitarnos los warnings realizamos en ambas máquinas lo siguiente:

```
apt remove python
apt autoremove
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
network_interface: "enp0s3" # Interfaz propia de openstack
neutron_external_interface: "enp0s8" # Interfaz externa para internet
kolla_internal_vip_address: "10.10.10.254" # Ip para gestionar interfaz interna
enable_cinder: "yes"


```
