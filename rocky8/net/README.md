# Network


## 1. Change IP Addresss

### 1.1 restart networkmanager

    nmtui
    
    systemctl restart NetworkManager
            
### 1.2 restart the interface to reload settings

    nmcli connection down ens192; nmcli connection up ens192
    
    nmcli connection down ens224; nmcli connection up ens224 nmcli connection modify br0 ipv6.method "disabled"

## 2. Disable IPv6

### 2.1 set   

    nmcli connection modify br0 ipv6.method "disabled"
    
## 3. Change Promisc

### 3.1 promisc on and off

    ifconfig eno4 promisc
    
    ifconfig eno4 -promisc
            
### 3.2 promisc on after reboot

    vi ifcfg-brm
    
    PROMISC=yes

## 4. Port mirror

### 4.1 go to network-scripts

    cd /etc/sysconfig/network-scripts/

### 4.2 config for mirror from bridge brm0 to vm network vnet1 and vnet3

    tc qdisc add dev brm0 ingress
    
    tc filter add dev brm0 parent ffff: \
    protocol ip u32 match u8 0 0 \
    action mirred egress mirror dev vnet1 pipe \
    action mirred egress mirror dev vnet3

    tc qdisc replace dev brm0 parent root prio

### 4.3 if prio == 8005 then

    tc qdisc show dev brm0

    tc filter add dev brm0 parent 8005: \
    protocol ip u32 match u8 0 0 \
    action mirred egress mirror dev vnet1 pipe \
    action mirred egress mirror dev vnet3
    
## 5. Commands

### 5.1 restart the interface to reload settings

    nmcli connection down ens192; nmcli connection up ens192
    
    nmcli connection down ens224; nmcli connection up ens224 nmcli connection modify br0 ipv6.method "disabled"

## X. Useful Links
- http://geertj.blogspot.com/2010/12/network-security-monitoring-with-kvm.html
- https://www.golinuxcloud.com/nmcli-command-examples-cheatsheet-centos-rhel/
- https://www.server-world.info/en/note?os=Rocky_Linux_8&p=initial_conf&f=3
- https://www.server-world.info/en/note?os=CentOS_Stream_8&p=bonding
- https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/assembly_port-mirroring_configuring-and-managing-networking
