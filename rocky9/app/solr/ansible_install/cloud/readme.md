### 0. 실행 환경
```
ansible hosts 파일 경로 : /home/qubit/ansible/hosts
실행 경로 : /opt/solr

파일 종류
solr-single.yml - ansible을 통해 solr 를 다운로드, 설치, 실행하는 yml(단일 프로세스 단일 노드)
```

### 1. 설치 방법
```
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/solr-singgle.yml
```

### 2. 서비스 전체 종료
```
ansible -i /home/qubit/ansible/hosts solr -m command -a "sudo systemctl stop solr"
```

### 3. 서비스 전체 설치 파일 삭제
```
ansible -i /home/qubit/ansible/hosts solr -m shell -a "sudo rm -rf /opt/solr*"
```

### 4. 구조
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
        Zookeeper4[ZookeeperN<br>Zookeeper_NodeN:2888:3888:2181]
        
    end

    %% Solr Subgraph
    subgraph Solr[Solr Single]
        direction TB
        SolrProcesses1[SolrProcesses1<br>Single_Node:8983<br>Single_Node:8984<br>Single_Node:8985<br>...]
        SolrProcesses1[SolrProcesses1<br>Single_Node:8983<br>Single_Node:8984<br>Single_Node:8985<br>...]
    end
hosts -->|설치| Solr

SolrProcesses1 --> Zookeeper1
SolrProcesses1 --> Zookeeper2
SolrProcesses1 --> Zookeeper3
SolrProcesses2 --> Zookeeper1
SolrProcesses2 --> Zookeeper2
SolrProcesses2 --> Zookeeper3
```

