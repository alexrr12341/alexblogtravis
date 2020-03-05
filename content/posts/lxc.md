+++
date = "2020-03-04"
title = "Vagrant con LXC"
math = "true"

+++

## Vagrant con LXC

Vamos a instalar vagrant con LXC, esto es un plugin de vagrant.

Vamos a realizar estas pruebas en una máquina virtual que crearemos con vagrant con el siguiente Vagranfile:
```
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

  config.vm.define :lxc do |lxc|
    lxc.vm.box = "debian/buster64"
    lxc.vm.hostname = "lxc"
    lxc.vm.synced_folder '.', '/vagrant', :disabled => true
    lxc.vm.network :public_network, :bridge => 'enp7s0'
    lxc.vm.provider :virtualbox do |v|
                    v.customize ["modifyvm", :id, "--memory", 2048]
            end
  end
end

```

Entramos a la máquina y realizamos la instalación de lxc
```
root@lxc:/home/vagrant/lxc# apt install lxc lxc-templates redir

```

Y también vamos a instalar vagrant-lxc en dicha máquina
```
root@lxc:/home/vagrant/lxc# apt install vagrant-lxc

```

Para configurar los parámetros de red vamos a /etc/lxc/default.conf y cambiamos las lineas que estaban por estas:
```
lxc.net.0.type = veth
lxc.net.0.link = virbr0
lxc.net.0.flags = up
lxc.apparmor.profile = generated
lxc.apparmor.allow_nesting = 1
```

Y instalamos las redes libvirt
```
apt-get install -qy libvirt-clients libvirt-daemon-system iptables ebtables dnsmasq-base

virsh net-start default

virsh net-autostart default
```

Ahora vamos a realizar el siguiente Vagrantfile para levantar dos máquinas, una que contendrá mariadb y otra que contendrá wordpress.

```

```
