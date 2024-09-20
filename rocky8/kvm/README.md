# KVM
libvirtd

## 1. Install

### 1.1 Install

    dnf -y install qemu-kvm libvirt virt-install virt-manager
    
    systemctl enable --now libvirtd
    
    reboot
            
### 1.2 Directory

    cd /etc/libvirt/qemu/
    
    cd /var/lib/libvirt/images/

### 1.3 Install kvm manager packages

    dnf -y install virt-manager
    
    systemctl restart libvirtd

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


<hr/>

## 4. Snapshot

### 4.1 copy

```
cd /etc/libvirt/qemu/

cp ubuntu24.04.xml ubuntu24.04-snapshot.xml
```
    
### 4.2 make uuid

```
uuidgen
```

### 4.3 edit
- Change: `name`, `uuid`, and `disk source file`
```
vi ubuntu24.04-snapshot.xml
```

```
  <name>ubuntu24.04-snapshot</name>
  <uuid>f096bb20-0ebd-4597-9445-52df0e1850f1</uuid>

  <source file='/var/lib/libvirt/images/ubuntu24.04-snapshot.qcow2'/>
```

### 4.4 create file

```
qemu-img create -f qcow2 -b /var/lib/libvirt/images/ubuntu24.04.qcow2 -F qcow2 /var/lib/libvirt/images/ubuntu24.04-snapshot.qcow2
```

### 4.5 define

```
virsh define ubuntu24.04-snapshot.xml
```

### 4.6 run

```
virsh start ubuntu24.04-snapshot
```

<hr/>

## X. Useful Links

- https://www.cyberciti.biz/faq/howto-linux-delete-a-running-vm-guest-on-kvm/
- https://www.cyberciti.biz/faq/how-to-forcefully-shutdown-forcing-a-guest-to-stop-using-virsh-command/
- https://access.redhat.com/solutions/6967304
- https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/configuring_and_managing_virtualization/index#setting-up-the-rhel-web-console-to-manage-vms_managing-virtual-machines-in-the-web-console
