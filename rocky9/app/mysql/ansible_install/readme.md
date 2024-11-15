### 0. 실행 환경
```
ansible hosts 파일 경로 : /home/qubit/ansible/hosts
실행 경로 : (/usr/lib/systemd/system/mysqld.service)

파일 종류
mysql(master).yml - ansible을 통해 mysql 를 다운로드, 설치, 실행 - master 역할 노드 생성 yml
mysql(replica).yml - ansible을 통해 redis 를 다운로드, 설치, 실행 - replica 역할 노드 생성 yml
```

### 1. 설치 방법
```
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/mysql(master).yml
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/mysql(replica).yml
※ 반드시 master 먼저 생성 후 replica 생성 필요
```

### 2. 서비스 전체 종료
```
ansible -i /home/qubit/ansible/hosts mysql-master,mysql-slave -m command -a "sudo systemctl stop mysqld*"
```

### 3. 서비스 전체 설치 파일 삭제
```
ansible -i /home/qubit/ansible/hosts mysql-master,mysql-slave  -m shell -a "sudo rm -rf /etc/my.cnf*"
ansible -i /home/qubit/ansible/hosts mysql-master,mysql-slave  -m shell -a "sudo systemctl remove mysqld*"
```


### 5. 구조
```mermaid
graph TD;

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
    subgraph Mysql-Master
        direction TB
        Master1[Master #1 Node]
		Master2[Master #2 Node]
		MasterN[Master #N Node]
		
	end
	    
	subgraph Mysql-Replica
        Replica1[Replica #1 Node]      
        Replica2[Replica #2 Node]
        ReplicaN[Replica #N Node]
    end


    hosts --|설치|--> Mysql-Master
	hosts --|설치|--> Mysql-Replica

    Master1 --> Replica1
    Master2 --> Replica2
    MasterN --> ReplicaN
```
