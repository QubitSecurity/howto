# firewall-cmd

## 1. Basic
### 1.1 basic

    firewall-cmd --get-default-zone
    
    firewall-cmd --get-active-zones

### 1.2 basic

    firewall-cmd --get-default-zone
    
    firewall-cmd --get-active-zones

### 1.3 specific public to add interface

    firewall-cmd --zone=public --list-all
    
    firewall-cmd --permanent --zone=public --add-interface=ens224
    
    firewall-cmd --reload

### 1.4 add service and port

    firewall-cmd --add-service=snmp --permanent
    
    firewall-cmd --add-port=10050/tcp --permanent
    
    firewall-cmd --reload
    
### 1.5 add source ip address

    firewall-cmd --zone=public --permanent --add-source=1.1.1.1/32
    
    firewall-cmd --reload

<hr/>

## 2. remove services

### 2.1 remove

```
firewall-cmd --zone=public --permanent --remove-service=ssh
firewall-cmd --zone=public --permanent --remove-service=dhcpv6-client
firewall-cmd --zone=public --permanent --remove-service=cockpit

firewall-cmd --reload
```

<hr/>

## 3. Rich rules

### 3.3.1 add rich rule

    firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="1.1.1.1/32" port protocol="tcp" port="3389" accept'
    
    firewall-cmd --reload


### 3.3.1 remove rich rule

    firewall-cmd --permanent --zone=public --remove-rich-rule='rule family="ipv4" source address="1.1.1.1/32" port protocol="tcp" port="3389" accept'
    
    firewall-cmd --reload


### 3.4 specific trusted zone

    firewall-cmd --zone=trusted --list-all
    
    firewall-cmd --permanent --zone=trusted --add-interface=ens192
    
    firewall-cmd --permanent --zone=trusted --add-service=ssh
    firewall-cmd --permanent --zone=trusted --add-service=smtp
    firewall-cmd --permanent --zone=trusted --add-service=cockpit
    firewall-cmd --permanent --zone=trusted --add-port=10050/tcp
    
    firewall-cmd --reload

### 3.5 block

    firewall-cmd --zone=block --permanent --add-rich-rule='rule family="ipv4" source address="10.10.10.0/23" accept'

    firewall-cmd --reload

### 3.6 Rich rules

    firewall-cmd --zone=trusted --permanent --add-rich-rule='rule family="ipv4" source address="10.10.10.0/23" accept'
    
    firewall-cmd --reload

### 9.1 Rich rules

    firewall-cmd --zone=trusted --permanent --add-rich-rule='rule family="ipv4" source address="10.10.10.0/23" accept'
    
    firewall-cmd --reload


## References

- https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/sec-using_firewalls

- https://www.golinuxcloud.com/firewalld-cheat-sheet/
- https://www.golinuxcloud.com/firewalld-cheat-sheet/#Working_with_firewalld_Rich_Rules
