# Network

## 1. Port mirror

### 1.1 go to network-scripts

    cd /etc/sysconfig/network-scripts/

### 1.2 config for mirror from bridge brm0 to vm network vnet1 and vnet3

    tc qdisc add dev brm0 ingress
    
    tc filter add dev brm0 parent ffff: \
    protocol ip u32 match u8 0 0 \
    action mirred egress mirror dev vnet1 pipe \
    action mirred egress mirror dev vnet3

    tc qdisc replace dev brm0 parent root prio

### 1.3 if prio == 8005 then

    tc qdisc show dev brm0

    tc filter add dev brm0 parent 8005: \
    protocol ip u32 match u8 0 0 \
    action mirred egress mirror dev vnet1 pipe \
    action mirred egress mirror dev vnet3
    
## 2. Check

### 2.1 brm0 interface is promisc

    ifconfig brm0 promisc
    
    ifconfig brm0 -promisc

### 2.2 brm0 interface error

    tc -s qdisc show dev brm0

    tc -s qdisc show dev vnet1

## 3. Commands

### 3.1 restart the interface to reload settings

    nmcli connection down ens192; nmcli connection up ens192
    
    nmcli connection down ens224; nmcli connection up ens224 nmcli connection modify br0 ipv6.method "disabled"

## X. Useful Links
- http://geertj.blogspot.com/2010/12/network-security-monitoring-with-kvm.html
- https://www.golinuxcloud.com/nmcli-command-examples-cheatsheet-centos-rhel/

- https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/linux-traffic-control_configuring-and-managing-networking
