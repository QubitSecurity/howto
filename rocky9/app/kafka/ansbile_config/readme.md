### 0. 실행 환경
```
ansible hosts 파일 경로 : /home/qubit/ansible/hosts
kafka 실행 경로 : /opt/kafka
cmak 실행 경로 : /opt/cmak
akhq 실행 경로 : /opt/akhq

파일 종류
zookeeper.yml - ansible을 통해 zookeeper를 다운로드, 설치, 실행하는 yml
zoo.cfg.j2 - zookeeper 실행 설정 파일 생성을 위한 동적 파일
```

### 1. 실행 방법
```
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/kafka.yml
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/cmak.yml
```

### 2. 실행 종료
```
ansible -i /home/qubit/ansible/hosts zk -m command -a "sudo systemctl stop kafka"
ansible -i /home/qubit/ansible/hosts zk -m command -a "sudo systemctl stop cmak"
ansible -i /home/qubit/ansible/hosts zk -m command -a "sudo systemctl stop akhq"
```

### 3. 설치 파일 삭제
```
ansible -i /home/qubit/ansible/hosts zk -m shell -a "sudo rm -rf /opt/kafka"
ansible -i /home/qubit/ansible/hosts zk -m shell -a "sudo rm -rf /opt/cmak"
ansible -i /home/qubit/ansible/hosts zk -m shell -a "sudo rm -rf /opt/akhq"
```

