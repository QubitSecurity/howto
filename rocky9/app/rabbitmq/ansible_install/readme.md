### 0. 실행 환경
```
ansible hosts 파일 경로 : /home/qubit/ansible/hosts
실행 경로 : (/usr/lib/systemd/system/mysqld.service)

파일 종류
rabbitmq.yml - ansible을 통해 rabbitmq 를 다운로드, 설치, 실행(노드 추가 시 중복 실행으로 스케일 아웃 가능)

```

### 1. 설치 방법
```
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/rabbitmq.yml
```

### 2. 서비스 전체 종료
```
ansible -i /home/qubit/ansible/hosts rabbitmq -m command -a "sudo systemctl stop rabbitmq-server*"
```

### 3. 서비스 전체 설치 파일 삭제
```
ansible -i /home/sysadmin/ansible/hosts rabbitmq-master -m shell -a "sudo rm -rf /etc/rabbitmq"
ansible -i /home/sysadmin/ansible/hosts rabbitmq-master -m shell -a "sudo rm -rf /var/lib/rabbitmq"
ansible -i /home/sysadmin/ansible/hosts rabbitmq-master  -m command -a "sudo dnf -y remove rabbit*"
ansible -i /home/sysadmin/ansible/hosts rabbitmq-master  -m command -a "sudo dnf -y remove erlang"
```


### 5. 구조
```mermaid
graph LR;

    %% Define layout direction and spacing
    %% style Ansible_Server fill:#f9f,stroke:#333,stroke-width:2px,height:200px;
    %% style Zookeeper fill:#cfc,stroke:#333,stroke-width:2px;


    %% Ansible Server Section
    subgraph Ansible_Server[Ansible Server]
        direction TB
        Ansible1[Ansible]
        hosts[hosts]
        
        Ansible1 --> hosts
    end


    subgraph Rabbitmq Clustering
        direction TB
        Node1[Node #1]
        Node2[Node #2]
        Node3[Node #3]
        Node4[Node #4]
        Node5[Node #5]
		
	end

   hosts --|설치|--> Rabbitmq Clustering


```
