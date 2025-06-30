### 0. 실행 환경
```
ansible hosts 파일 경로 : /home/qubit/ansible/hosts
zookeeper 실행 경로 : /opt

파일 종류
zookeeper.yml - ansible을 통해 zookeeper를 다운로드, 설치, 실행하는 yml
```

### 1. 설치 방법
```
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/zookeeper.yml
```

### 2. 서비스 전체 종료
```
ansible -i /home/qubit/ansible/hosts zk -m command -a "sudo /opt/zk/bin/zkServer.sh stop"
```

### 3. 서비스 전체 설치 파일 삭제
```
ansible -i /home/qubit/ansible/hosts zk -m shell -a "sudo rm -rf /opt/apache-zookeeper-X.X.X-bin"
```
### 4. 구조
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

    %% Zookeeper Section
    subgraph Zookeeper[Zookeeper]
        direction TB
        Zookeeper1[Zookeeper1<br>Zookeeper_Node1:2888:3888:2181]
        Zookeeper2[Zookeeper2<br>Zookeeper_Node2:2888:3888:2181]
        Zookeeper3[Zookeeper3<br>Zookeeper_Node3:2888:3888:2181]
        Zookeeper4[ZookeeperN<br>Zookeeper_NodeN:2888:3888:2181]
    end
hosts -->|설치| Zookeeper
```
