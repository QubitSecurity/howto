# named
named.conf

## 1. Install

### 1.1 Install

    dnf -y install bind bind-utils
            
### 1.2 Edit for named.conf

    vi /etc/named.conf
    
### 1.3 Edit for named

    vi /etc/sysconfig/named
    
    # add to the end
    OPTIONS="-4"

### 1.4 Config for logging
    
    touch /var/log/named.log
    chmod a+w /var/log/named.log
    chown -R named.named /var/log/named.log
    
    chcon -u system_u /var/log/named.log
    restorecon -v /var/log/named.log
    
    systemctl enable --now named
    systemctl restart named
    systemctl status named

### 1.5 Checking

    ls -Z /var/log/named.log
    
    > system_u:object_r:named_log_t:s0 /var/log/named.log


### 1.6 Testing

    tail -f /var/log/named.log
    
    dig www.naver.com
    
### 1.7 setting rules to firewalld

    firewall-cmd --add-service=dns
    
    firewall-cmd --runtime-to-permanent

## X. Useful Links

    https://www.server-world.info/en/note?os=Rocky_Linux_8&p=dns&f=1
    https://www.server-world.info/en/note?os=CentOS_7&p=selinux&f=5
    https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/selinux_users_and_administrators_guide/sect-managing_confined_services-bind-types
