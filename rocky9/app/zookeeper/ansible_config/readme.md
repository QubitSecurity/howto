### 0. 실행 환경
```
ansible hosts 파일 경로 : /home/qubit/ansible/hosts
zookeeper 실행 경로 : /opt
```

### 1. 실행 방법
```
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/zookeeper.yml
```

### 2. 실행 종료
```
ansible -i /home/qubit/ansible/hosts zk -m command -a "sudo pkill -9 -f 'zookeeper'"
```

### 3. 설치 파일 삭제
```
ansible -i /home/qubit/ansible/hosts zk -m shell -a "sudo rm -rf /opt/apache-zookeeper-3.8.4-bin"
```
