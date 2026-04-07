# Squid

## 1. Install

### 1.1 Install

    dnf -y install squid
    
### 1.2 Config

    vi /etc/squid/squid.conf
    
    # line 29
    acl my_localnet src 10.10.10.0/23
    
    # line 46 : uncomment
    http_access deny to_localhost
    
    # line 55 : comment out
    #http_access allow localnet
    # line 57 : add (allow defined ACL above)
    http_access allow my_localnet
    
    # add to the end
    request_header_access Referer deny all
    request_header_access X-Forwarded-For deny all
    request_header_access Via deny all
    request_header_access Cache-Control deny all
    
    # add (do not display IP address)
    forwarded_for off

### 1.3 Run

    systemctl enable --now squid
    
### 1.4 Setting rules to firewalld

    firewall-cmd --add-service=squid
    
    firewall-cmd --runtime-to-permanent

### 1.5 Check the configuration file

    squid -k parse

### 1.6 Check the configuration file in a specific directory

    squid -f /etc/squid/history/squid.conf

### 1.7 Check process

    netstat -tnlp

## 2. PLURA-SQUID

### 2.1 make web.log

    touch /var/log/plura/weblog.log
    
    chown squid.root /var/log/plura/weblog.log
    chmod -R 766 /var/log/plura/weblog.log

    chcon -t squid_log_t /var/log/plura/weblog.log

## 3. Selinux

### 3.1 check selinx permission

    getenforce
    
    grep squid /var/log/audit/audit.log | audit2why
    
    ps -eZ | grep squid
    semanage port -l | grep -w -i squid_port_t

### 3.2 setting selinx
    semanage port -a -t squid_port_t -p tcp 58080
    semanage fcontext -a -t squid_log_t "/var/log/plura/weblog.log"
    restorecon -Rv /var/log/plura/weblog.log

### 3.3 setting selinx with regexpress
    semanage fcontext -a -t squid_log_t "/var/log/plura(/.*)?"

<hr/>

## 4. PLURA-SQUID

### 4.1 add info

    echo "ModPlura-squid" > /etc/modplura
    echo "0.0.1" >> /etc/modplura
    touch /etc/.modplura

### 4.2 restart

    systemctl restart squid
    systemctl status squid

    netstat -tunlp

<hr/>

## 5. X-Forwarded-For Header Validation

### 5.1 to only trust the directly connected client's IP in the XFF header, without trusting any upstream proxy's XFF headers

```
forwarded_for delete
```
<hr/>

## X. Useful Links

    https://www.server-world.info/en/note?os=Rocky_Linux_8&p=squid&f=1
    https://jfearn.fedorapeople.org/fdocs/en-US/Fedora/20/html/Security_Guide/sect-Managing_Confined_Services-Squid_Caching_Proxy.html
