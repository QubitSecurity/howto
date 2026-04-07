# Ansible
chrony conf

## 1. Create user

### 1.1 Install

    dnf -y install chrony
            

## 2. Copy

### 2.1 private key

    ssh-copy-id -i .ssh/authorized_keys root@10.100.10.10.
    

## 3. Basic commands

### 3.1 ping

    ansible -i ~/ansible/hosts all-hosts -m ping   

### 3.2 Copy for NTP

    vi ~ansible/pb_copy_chrony.yml
    
    - hosts: all-hosts
      become: true
      become_user: root
      tasks:
        - copy:
            src=/home/admin/ansible/dl/chrony.conf
            dest=/etc/chrony.conf
            remote_src: no
            mode: 0644

### 3.3 Run

    ansible-playbook -i ~/ansible/hosts pb_copy_chrony.yml

### 3.4 Check

    ansible -i ~/ansible/hosts all-hosts -m shell -a "sudo systemctl restart chronyd"
