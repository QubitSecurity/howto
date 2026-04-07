# Ansible


## 1. Begin

### 1.1 command

    ansible all --list-hosts
    
    ansible target_servers --list-hosts
            
### 1.2 

    ansible -i ansible/hosts target_servers -m ping
    
    ansible -i ansible/hosts target_servers -k -m command -a "uptime"
    
    ansible -i ansible/hosts target_servers -k -m command -a "cat /etc/shadow" -b --ask-become-pass
    
    ansible -i ansible/hosts all -m shell -a "service cwpsrv status" -b --ask-become-pass
    
    
## X References

    https://
    
    https://
