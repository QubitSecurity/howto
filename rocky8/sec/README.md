# Selinux

## 1. Application

### 1.1 ssh add port

    semanage port -l | grep ssh
    
    semanage port -a -t ssh_port_t -p tcp 22000
            
### 1.2 

    vi /etc/selinux/config
    
    SELINUX=enforcing
    
## X Useful Links

- https://www.server-world.info/en/note?os=CentOS_7&p=selinux&f=6
