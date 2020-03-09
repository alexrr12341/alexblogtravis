+++
date = "2020-03-04"
title = "Vagrant con LXC"
math = "true"

+++

## Vagrant con LXC

Vamos a instalar vagrant con LXC, esto es un plugin de vagrant.




Instalamos lxc
```
root@pc-alex:~# apt install lxc lxc-templates redir


```

Y también vamos a instalar vagrant-lxc en dicha máquina
```
root@pc-alex:~# apt install vagrant vagrant-lxc


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
apt-get install -y libvirt-clients libvirt-daemon-system iptables ebtables dnsmasq-base

virsh net-start default

virsh net-autostart default
```

Esto nos abrirá un bridge llamado virbr0
```
4: virbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 52:54:00:10:8c:63 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
       valid_lft forever preferred_lft forever

```

Ahora vamos a realizar el siguiente Vagrantfile para levantar dos máquinas, una que contendrá mariadb y otra que contendrá wordpress, debian stretch tiene su imagen oficial de lxc por lo que vamos a utilizar dicha imagen a la hora de crear las máquinas.

```
Vagrant.configure("2") do |config|
  config.vm.define "mariadb" do |node|
    node.vm.network "private_network", ip: "192.168.122.2", lxc__bridge_name: 'virbr0'
    node.vm.box= "debian/stretch64"
    node.vm.provider :lxc do |lxc|
      lxc.container_name = :machine # Sets the container name to 'db'
      lxc.container_name = 'mariadb'  # Sets the container name to 'mysql'
    end
  end
  config.vm.define "wordpress" do |node2|
    node2.vm.network "private_network", ip: "192.168.122.3", lxc__bridge_name: 'virbr0'
    node2.vm.box= "debian/stretch64"
    node2.vm.provider :lxc do |lxc|
      lxc.container_name = :machine # Sets the container name to 'db'
      lxc.container_name = 'wordpress'  # Sets the container name to 'mysql'
    end
  end
end

```


Ahora vamos a proceder a crear el ansible para aprovisionar la máquina wordpress con wordpress, y la de mariadb con mariadb.

Instalamos ansible
```
apt install ansible
```

Para eso hacemos el siguiente [ansible](https://github.com/alexrr12341/ansible_lxc)



Para aprovisionar ambas máquinas simplemente cambiamos un poco el vagrant file, y hacemos que ejecute el ansible justo cuando terminen de configurarse.
```
Vagrant.configure("2") do |config|
  config.vm.define "mariadb" do |node|
    node.vm.network "private_network", ip: "192.168.122.2", lxc__bridge_name: 'virbr0'
    node.vm.box= "debian/stretch64"
    node.vm.provider :lxc do |lxc|
      lxc.container_name = :machine # Sets the container name to 'db'
      lxc.container_name = 'mariadb'  # Sets the container name to 'mysql'
    end
  end
  config.vm.define "wordpress" do |node2|
    node2.vm.network "private_network", ip: "192.168.122.3", lxc__bridge_name: 'virbr0'
    node2.vm.box= "debian/stretch64"
    node2.vm.provider :lxc do |lxc|
      lxc.container_name = :machine # Sets the container name to 'db'
      lxc.container_name = 'wordpress'  # Sets the container name to 'mysql'
    end
  end
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "./ansible/site.yaml"
  end
end

```

Comprobamos que están hechas
```
root@pc-alex:~/linuxcontainer# lxc-ls
mariadb   wordpress 

root@pc-alex:~/linuxcontainer# lxc-info wordpress
Name:           wordpress
State:          RUNNING
PID:            24034
IP:             192.168.122.3
IP:             192.168.122.3
CPU use:        13.19 seconds
BlkIO use:      86.98 MiB
Memory use:     204.83 MiB
KMem use:       12.90 MiB
Link:           veth72PUQW
 TX bytes:      2.76 MiB
 RX bytes:      85.24 MiB
 Total bytes:   88.00 MiB
root@pc-alex :~/linuxcontainer# lxc-info mariadb
Name:           mariadb
State:          RUNNING
PID:            24049
IP:             192.168.122.187
IP:             192.168.122.2
CPU use:        77.24 seconds
BlkIO use:      791.64 MiB
Memory use:     748.18 MiB
KMem use:       52.07 MiB
Link:           vethWAQEW2
 TX bytes:      3.77 MiB
 RX bytes:      112.40 MiB
 Total bytes:   116.17 MiB

```


