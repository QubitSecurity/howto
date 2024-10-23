### 0. 실행 환경
```
ansible hosts 파일 경로 : /home/sysadmin/ansible/hosts
kafka 실행 경로 : /opt
```

### 1. 실행 방법
```
ansible-playbook -i /home/sysadmin/ansible/hosts /home/sysadmin/ansible/kafka.yml
ansible-playbook -i /home/sysadmin/ansible/hosts /home/sysadmin/ansible/cmak.yml
```

### 2. 실행 종료
```
ansible -i /home/sysadmin/ansible/hosts zk -m command -a "sudo systemctl stop kafka"
ansible -i /home/sysadmin/ansible/hosts zk -m command -a "sudo systemctl stop cmak"
ansible -i /home/sysadmin/ansible/hosts zk -m command -a "sudo systemctl stop akhq"
```

### 3. 설치 파일 삭제
```
ansible -i /home/sysadmin/ansible/hosts zk -m shell -a "sudo rm -rf /opt/kafka"
ansible -i /home/sysadmin/ansible/hosts zk -m shell -a "sudo rm -rf /opt/cmak"
ansible -i /home/sysadmin/ansible/hosts zk -m shell -a "sudo rm -rf /opt/akhq"
```

