## 1. kafka
### 1.0. 실행 환경
```
HOME 경로 : /opt/kafka/kafka_X.XX-X.X.X
실행 파일 경로 : /etc/systemd/system/kafka.service
설정 파일 :/opt/kafka/config/server.propertise
DATA 경로 : /opt/kafka/kafka-data/kafka-logs
```

### 1.1. 실행
```
sudo systemctl start kakka
```

### 1.2. 종료
```
sudo systemctl stop kakka
```
### 1.3. 구조
```mermaid
graph LR;

    %% Define layout direction and spacing
    style Ansible_Server fill:#f9f,stroke:#333,stroke-width:2px,height:200px;
    style Zookeeper fill:#cfc,stroke:#333,stroke-width:2px;


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
        Zookeeper1[Zookeeper1<br>Zookeeper_IP1:2888:3888:2181]
        Zookeeper2[Zookeeper2<br>Zookeeper_IP2:2888:3888:2181]
        Zookeeper3[Zookeeper3<br>Zookeeper_IP3:2888:3888:2181]
        
    end

    %% Combined Kafka and Solr Section
        %% Kafka Subgraph
    subgraph Kafka[Kafka]
        direction TB
        Kafka1[Kafka1<br>192.168.200.160:9092]
        Kafka2[Kafka2<br>192.168.200.161:9092]
        Kafka3[Kafka3<br>192.168.200.162:9092]
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


## 2. CMAK
### 2.0. 실행 환경
```
HOME 경로 : /opt/cmak
실행 파일 경로 : /etc/systemd/system/cmak.service
설정 파일 : /opt/cmak/cmak-X.X.X.X/conf/application.conf
```
### 2.1. 실행
```
sudo systemctl start cmak
```
### 2.2. 종료
```
sudo systemctl stop cmak
```
## 3. AKHQ
### 3.0. 실행 환경
```
HOME 경로 : /opt/akhq
실행 파일 경로 : /etc/systemd/system/akhq.service
설정 파일 : /opt/akhq/akhq-X.XX.X/config/application.yml
```
### 3.1. 실행
```
sudo systemctl start cmak
```
### 3.2. 종료
```
sudo systemctl stop cmak
```
