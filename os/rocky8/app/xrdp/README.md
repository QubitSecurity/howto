# Xrdp
xrdp from EPEL and with using tigervnc

## 1. Install

### 1.1 Install

    dnf -y install epel-release
    dnf --enablerepo=epel -y install xrdp
    
### 1.2 Config

    vi /etc/xrdp/xrdp.ini
    
    [Xvnc]
    name=Xvnc
    lib=libvnc.so
    username=ask
    password=ask
    ip=127.0.0.1
    #port=-1
    port=5999

### 1.3 Run

    systemctl enable --now xrdp
    
    systemctl restart xrdp
    
### 1.4 Setting rules to firewalld

    firewall-cmd --add-port=3389/tcp
    
    firewall-cmd --runtime-to-permanent

### 1.5 Check

    netstat -tnlp
    
    netstat -tnlp | grep -e 3389 -e 5999

## 2. Troubleshooting

### 2.1 error after update xrdp

    "error loading libvnc.so specified in xrdp.ini, please add a valid entry like lib=libxrdp-vnc.so or similar"

### 2.2 just copy from previous version

    find / -name libvnc.so
    cp /usr/lib64/xrdp/libvnc.so to destination

## X. Useful Links

    https://github.com/QubitSecurity/doc/tree/main/rocky8/app/tigervnc
