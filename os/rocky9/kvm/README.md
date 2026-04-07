# KVM
libvirtd

## 1. Install

### 1.1 Install

```
dnf -y install qemu-kvm libvirt virt-install
```
            
### 1.2 Directory

```
lsmod | grep kvm

systemctl enable --now libvirtd
```

### 1.3 Install kvm manager packages

```
dnf -y install virt-manager
    
systemctl restart libvirtd
```

### 1.4 Install cockpit packages

    dnf -y install cockpit-machines

    dnf -y install virt-viewer
    
    systemctl restart libvirtd

### 1.5 Basic command

    virsh --help
    
    virsh list
    
    virsh list --all
    
    virsh start rocky8
    
    virsh console rocky8
    
    virsh shutdown rocky8
       
    virsh autostart rocky8
    
    virsh autostart --disable rocky8
    
    virsh undefine rocky8
    rm -rf /var/lib/libvirt/images/rocky8.qcow2

## 2. Clone

### 2.1 clone

    virt-clone --original rocky8 --name rocky8-zabbix --file /var/lib/libvirt/images/rocky8-zabbix.qcow2
    
### 2.2 copy

    scp /etc/libvirt/qemu/rocky8.xml root@10.10.10.11:/etc/libvirt/qemu/
    
    scp /var/lib/libvirt/images/rocky8.qcow2 root@10.10.10.11:/var/lib/libvirt/images/
    
    systemctl restart libvirtd

### 2.3 copy all

    scp /var/lib/libvirt/images/*.qcow2 root@10.10.10.11:/var/lib/libvirt/images/
    
    scp /etc/libvirt/qemu/*.xml root@10.10.10.11:/etc/libvirt/qemu/

## 3. Resize

### 3.1 resize

    qemu-img resize /var/lib/libvirt/images/rocky8.qcow2 +100G


## X. Useful Links

- https://www.server-world.info/en/note?os=CentOS_Stream_9&p=kvm&f=1
