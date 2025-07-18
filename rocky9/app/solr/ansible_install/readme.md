
## Single 포트 단일 노드

### 실행 환경
```
ansible hosts 파일 경로 : /home/qubit/ansible/hosts
실행 경로 : /opt/solr

파일 종류
single-port.yml - ansible을 통해 solr 를 다운로드, 설치, 실행하는 yml(단일 프로세스 단일 노드)
```

### 설치 방법
```
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/single-port.yml
```

### 서비스 전체 종료
```
ansible -i /home/qubit/ansible/hosts solr -m command -a "/opt/solr/bin/solr stop -all"
```

### 서비스 전체 설치 파일 삭제
```
ansible -i /home/qubit/ansible/hosts solr -m shell -a "sudo rm -rf /opt/solr*"
```
### 구조
```mermaid
graph LR;

    %% Define layout direction and spacing
   %% style Ansible_Server fill:#f9f,stroke:#333,stroke-width:2px,height:200px;
   %% style Zookeeper fill:#cfc,stroke:#333,stroke-width:2px;
   %% style Plug_Zookeeper fill:#fff,stroke:#000,stroke-width:2px;

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

    %% Solr Subgraph
    subgraph Solr[Solr Group]
        direction TB
        SolrServer1[SolrServer1:8983]
        SolrServer2[SolrServer2:8983]
    end
hosts -->|설치| Solr

SolrServer1 --> Zookeeper1
SolrServer1 --> Zookeeper2
SolrServer1 --> Zookeeper3
SolrServer2 --> Zookeeper1
SolrServer2 --> Zookeeper2
SolrServer2 --> Zookeeper3
```

## baremetal 다중 포트
### 실행 환경
```
ansible hosts 파일 경로 : /home/qubit/ansible/hosts
실행 경로 : /opt/solr

파일 종류
solr.yml - ansible을 통해 solr 를 다운로드, 설치, 실행하는 yml
```

### 설치 방법
```
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/multi-port.yml
```

### 서비스 전체 종료
```
ansible -i /home/qubit/ansible/hosts solr -m command -a "sudo /opt/solr/bin/solr stop -all*"
```

### 서비스 전체 설치 파일 삭제
```
ansible -i /home/qubit/ansible/hosts solr -m shell -a "sudo rm -rf /opt/solr*"
```

### 구조
```mermaid
graph LR;

    %% Define layout direction and spacing
   %% style Ansible_Server fill:#f9f,stroke:#333,stroke-width:2px,height:200px;
   %% style Zookeeper fill:#cfc,stroke:#333,stroke-width:2px;
   %% style Plug_Zookeeper fill:#fff,stroke:#000,stroke-width:2px;

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

    %% Solr Subgraph
    subgraph Solr[Solr Single]
        direction TB
        SolrProcesses[SolrProcesses<br>Single_Node:8983<br>Single_Node:8984<br>Single_Node:8985<br>...]
    end
hosts -->|설치| Solr

SolrProcesses --> Zookeeper1
SolrProcesses --> Zookeeper2
SolrProcesses --> Zookeeper3
```
