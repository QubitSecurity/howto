# Iptables
iptables command

## 1. Install

### 1.1 Disable firewalld if installed

    systemctl stop firewalld.service
    
    systemctl disable firewalld.service
    
    systemctl mask firewalld.service
            
### 1.2 Install iptables

    dnf -y install iptables-services
    
    systemctl enable --now iptables

## 2. iptables

### 2.1 postrouting

    iptables -t nat -A PREROUTING -p tcp --dport 30128 -j DNAT --to-destination 192.168.0.1
    
    iptables -t nat -A POSTROUTING -p tcp --dport 30128 -j SNAT --to-source 210.116.0.190

### 2.2 Save

    /sbin/iptables-save > /etc/sysconfig/iptables
    
    iptables -t nat -L
