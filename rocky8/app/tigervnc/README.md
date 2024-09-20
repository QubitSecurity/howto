# Tigervnc
with xrdp

## 1. Install

### 1.1 Install

    dnf -y install tigervnc-server
            
### 1.2 set VNC password

    vncpasswd
    
    Password:
    Verify:
    Would you like to enter a view-only password (y/n)? n
    
    vi ~/.vnc/config
    
    session=gnome
    securitytypes=vncauth,tlsvnc
    geometry=1920x1080
            
### 1.3 Config

    vi /etc/tigervnc/vncserver.users
    
    :99=root

### 1.4 Run

    systemctl enable --now vncserver@:99

    systemctl restart vncserver@:99

### 1.5 Check

    netstat -tnlp

    netstat -tnlp | grep -e 3389 -e 5999

## X. Useful Links

    https://github.com/QubitSecurity/doc/tree/main/rocky8/app/xrdp
