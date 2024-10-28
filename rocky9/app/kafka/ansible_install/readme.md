### 0. 설치 환경
```
ansible hosts 파일 경로 : /home/qubit/ansible/hosts
kafka 실행 경로 : /opt/kafka
cmak 실행 경로 : /opt/cmak
akhq 실행 경로 : /opt/akhq

파일 종류
kafka.yml - ansible을 통해 kafka 를 다운로드, 설치, 실행하는 yml
server.propertise.j2 - kafka 실행 설정 파일 생성을 위한 jinja2 파일
cmak.yml - ansible을 통해 cmak, akhq 를 다운로드, 설치, 실행하는 yml
application.conf.j2 - cmak 실행 설정 파일 생성을 위한 jinja2 파일
```

### 1. 설치 방법
```
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/kafka.yml
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/cmak.yml
```

### 2. 서비스 전체 종료
```
ansible -i /home/qubit/ansible/hosts zk -m command -a "sudo systemctl stop kafka"
ansible -i /home/qubit/ansible/hosts zk -m command -a "sudo systemctl stop cmak"
ansible -i /home/qubit/ansible/hosts zk -m command -a "sudo systemctl stop akhq"
```

### 3. 서비스 전체 설치 파일 삭제
```
ansible -i /home/qubit/ansible/hosts zk -m shell -a "sudo rm -rf /opt/kafka"
ansible -i /home/qubit/ansible/hosts zk -m shell -a "sudo rm -rf /opt/cmak"
ansible -i /home/qubit/ansible/hosts zk -m shell -a "sudo rm -rf /opt/akhq"
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
    subgraph Zookeeper[Installed_Zookeeper]
        direction TB
        Zookeeper1[Zookeeper1<br>Zookeeper_Node1:2888:3888:2181]
        Zookeeper2[Zookeeper2<br>Zookeeper_Node2:2888:3888:2181]
        Zookeeper3[Zookeeper3<br>Zookeeper_Node3:2888:3888:2181]
        
    end

    %% Combined Kafka and Solr Section
        %% Kafka Subgraph
    subgraph Kafka[Kafka]
        direction TB
        Kafka1[Kafka1<br>Kafka_Node1:9092]
        Kafka2[Kafka2<br>Kafka_Node2:9092]
        Kafka3[Kafka3<br>Kafka_Node3:9092]
    end

    hosts -->|설치| Kafka

    Kafka1 --> Zookeeper1
    Kafka1 --> Zookeeper2
    Kafka1 --> Zookeeper3
    Kafka2 --> Zookeeper1
    Kafka2 --> Zookeeper2
    Kafka2 --> Zookeeper3
    Kafka3 --> Zookeeper1
    Kafka3 --> Zookeeper2
    Kafka3 --> Zookeeper3
```
