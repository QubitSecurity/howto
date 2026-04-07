# HAPROXY
haproxy-2.8.7.tar.gz

## 1. Download

### 1.1 lua

    curl -R -O https://www.lua.org/ftp/lua-5.4.6.tar.gz

### 1.2 haproxy

    curl -R -O https://www.haproxy.org/download/2.8/src/haproxy-2.8.7.tar.gz

## 2. Install

### 2.1 lua

    dnf -y install tar make gcc gcc-c++ pcre-devel openssl-devel readline-devel systemd-devel zlib-devel
    
    tar xvzf lua-5.4.6.tar.gz
    cd lua-5.4.6
    
    make all test
    make install

### 2.2 haproxy

    tar xvzf haproxy-2.8.7.tar.gz
    cd haproxy-2.8.7
    
    make USE_NS=1 USE_TFO=1 USE_OPENSSL=1 USE_ZLIB=1 USE_LUA=1 USE_PCRE=1 USE_SYSTEMD=1 USE_LIBCRYPT=1 USE_THREAD=1 TARGET=linux-glibc
    make install
            
### 2.3.1 Set up haproxy

    useradd -M -r -s /sbin/nologin haproxy
    
    mkdir -p /etc/haproxy/SSL
    
    mkdir /var/lib/haproxy
    
    touch /var/lib/haproxy/stats
    

### 2.3.2 Config check haproxy

    /usr/local/sbin/haproxy -f /etc/haproxy/haproxy.cfg -c

### 2.3.3 Register service
    
    vi /usr/lib/systemd/system/haproxy.service
    
    systemctl daemon-reload
    
    systemctl enable --now haproxy
    
### 2.4 keepalived

```
dnf -y install keepalived

vi /etc/keepalived/keepalived.conf

systemctl enable --now keepalived
```

<hr/>

## 3. X-Forwarded-For Header Validation

### 3.1 set-header
 
```
#---------------------------------------------------------------------
# for security : http-request add-header X-Forwarded-For %[src]
#---------------------------------------------------------------------
    http-request set-header X-Forwarded-For %[src],%[req.hdr(X-Forwarded-For)] if { req.hdr(X-Forwarded-For) -m found }
```

<hr/>

## 4. Redirect for Backend http or https

### 4.1 Connect to unsecure backend server

```
server mybackendserver 127.0.0.1:433 ssl verify none
```

### 4.2 Redirect all HTTP sites to HTTPS

```
acl http_www_qubitsec_com hdr_dom(host) -i qubitsec.com
redirect prefix https://www.qubitsec.com if http_www_qubitsec_com
```
```
systemctl restart haproxy
```

<hr/>

## 9. Setting rules to firewalld

### 9.1 vi /etc/firewalld/zones/trusted.xml
    
    <rule>
    <protocol value="vrrp"/>
    <accept/>
    </rule>

### 9.2 vi /etc/firewalld/zones/public.xml
    
    <rule>
    <protocol value="vrrp"/>
    <accept/>
    </rule>
 
 ### 9.3 Restart
    
    systemctl restart firewalld
  
 ### 9.4 TESTING
    
    systemctl status systemd-tmpfiles-setup.service
    
    
## X. Useful Links

    - https://www.haproxy.com/blog/redirect-http-to-https-with-haproxy
