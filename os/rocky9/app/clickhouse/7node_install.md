
## 구성. clickhouse-server 4노드 / keeper 3노드
```mermaid
graph LR
    %% ----------------------------------------------------
    %% [구조 핵심] 서버 레이어와 키퍼 레이어를 가로축으로 분리하여 
    %% 배치 엔진이 꼬이는 현상을 근본적으로 차단합니다.
    %% ----------------------------------------------------
    
    %% 스타일 정의
    classDef serverStyle fill:#E1F5FE,stroke:#03A9F4,stroke-width:1.5px,color:#01579B;
    
    %% 핫핑크/진보라 테두리와 노란색 배경으로 키퍼 스타일 구성
    classDef keeperStyle fill:#FFFDE7,stroke:#E91E63,stroke-width:3px,color:#880E4F,font-weight:bold;

    %% 1. ClickHouse Servers (좌측 정렬 - 파란색 레이어)
    subgraph ClickHouse_Cluster [ClickHouse Server Nodes]
        direction TB
        S1["[Node 1] clickhouse-server1:9000"]:::serverStyle
        S2["[Node 2] clickhouse-server2:9000"]:::serverStyle
        S3["[Node 3] clickhouse-server3:9000"]:::serverStyle
        S4["[Node 4] clickhouse-server4:9000"]:::serverStyle
    end

    %% 2. Keeper Quorum (우측 정렬 - 핑크 레이어 및 밑줄 유지)
    subgraph Keeper_Cluster [ClickHouse Keeper Quorum]
        direction TB
        K1["<b><u>[Node 5]</u></b> keeper1:2181"]:::keeperStyle
        K2["<b><u>[Node 6]</u></b> keeper2:2181"]:::keeperStyle
        K3["<b><u>[Node 7]</u></b> keeper3:2181"]:::keeperStyle
    end

    %% Keeper 서브그래프 박스 자체를 연한 핑크 배경과 붉은색 실선 테두리로 강조
    style Keeper_Cluster fill:#FCE4EC,stroke:#C2185B,stroke-width:2.5px;

    %% 3. Keeper 간의 상호 동기화 지시선
    K1 <--> K2 <--> K3

    %% 4. 모든 Server에서 Keeper Cluster 전체로 가는 지시선
    S1 --> Keeper_Cluster
    S2 --> Keeper_Cluster
    S3 --> Keeper_Cluster
    S4 --> Keeper_Cluster

    %% 서버 간 싱크 라인
    S1 <-- sync --> S2
    S3 <-- sync --> S4
```


## 1. Clickhouse-keeper 설치
### 1.0 방화벽 종료
```
방화벽 중지
systemctl stop firewalld
방화벽 비활성화
systemctl disable firewalld
```

### 1.1 레포지토리 설정 및 다운로드 설치
```
sudo dnf install -y yum-utils 
sudo yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo
sudo dnf install -y clickhouse-keeper
```

### 1.2 Keeper 전용 설정 작성
```
sudo cp /etc/clickhouse-keeper/keeper_config.xml /etc/clickhouse-keeper/keeper_config.xml_orig
sudo vi /etc/clickhouse-keeper/keeper_config.xml

<clickhouse>
    <listen_host>0.0.0.0</listen_host>
    <logger>
        <level>information</level>
        <log>/var/log/clickhouse-keeper/clickhouse-keeper.log</log>
        <errorlog>/var/log/clickhouse-keeper/clickhouse-keeper.err.log</errorlog>
    </logger>

    <keeper_server>
        <tcp_port>2181</tcp_port>
        <!-- 노드별 수정: keeper_node_1->1, keeper_node_2->2, keeper_node_3->3 -->
        <server_id>1</server_id>
        <log_storage_path>/var/lib/clickhouse/coordination/log</log_storage_path>
        <snapshot_storage_path>/var/lib/clickhouse/coordination/snapshots</snapshot_storage_path>

        <coordination_settings>
            <operation_timeout_ms>10000</operation_timeout_ms>
            <session_timeout_ms>30000</session_timeout_ms>
        </coordination_settings>

        <raft_configuration>
            <server>
                <id>1</id>
                <hostname>xxx.xxx.xxx.5</hostname>
                <port>9234</port>
            </server>
            <server>
                <id>2</id>
                <hostname>xxx.xxx.xxx.6</hostname>
                <port>9234</port>
            </server>
            <server>
                <id>3</id>
                <hostname>xxx.xxx.xxx.7</hostname>
                <port>9234</port>
            </server>
        </raft_configuration>
    </keeper_server>
</clickhouse>
```
### 1.3 서비스 시작 및 활성화
```
sudo systemctl enable --now clickhouse-keeper
```

## 2. Clickhouse-server 설치

### 2.0 사전작업
#### 2.0.1 hosts 등록
```
cat <<EOF | sudo tee -a /etc/hosts
xxx.xxx.xxx.1 node1-clickhouse
xxx.xxx.xxx.2 node2-clickhouse
xxx.xxx.xxx.3 node3-clickhouse
xxx.xxx.xxx.4 node4-clickhouse
EOF
```

#### 2.0.2 방화벽 종료
```
방화벽 중지
systemctl stop firewalld
방화벽 비활성화
systemctl disable firewalld
```

#### 2.0.3 THP 비활성화
```
sudo sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
sudo sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'
```

#### 2.0.4 커널 파라미터 적용 (Delay Accounting 및 최대 스레드 증대)
```
cat <<EOF | sudo tee -a /etc/sysctl.conf
kernel.task_delayacct = 1
kernel.threads-max = 2097152
vm.max_map_count = 1600000
EOF

sysctl 적용
sudo sysctl -p
```

### 2.1 설치
#### 2.1.1 레포지토리 설정 및 다운로드 설치
```
sudo dnf install -y yum-utils --setopt=proxy=http://10.100.21.180:3128 
sudo yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo --setopt=proxy=http://10.100.21.180:3128
sudo dnf install -y clickhouse-server clickhouse-client --setopt=proxy=http://10.100.21.180:3128
```

#### 2.1.2 로그 설정
```
sudo vi /etc/clickhouse-server/config.d/system_logs.xml

<clickhouse>
    <!-- text_log 보존 기간을 2일로 설정 (기본값: 보통 30일) -->
    <text_log>
        <ttl>event_date + INTERVAL 2 DAY</ttl>
    </text_log>

    <!-- 추적 로그(trace_log)도 2일로 단축 -->
    <trace_log>
        <ttl>event_date + INTERVAL 2 DAY</ttl>
    </trace_log>

    <!-- Keeper 통신 로그(aggregated_zookeeper_log)도 2일로 단축 -->
    <aggregated_zookeeper_log>
        <ttl>event_date + INTERVAL 2 DAY</ttl>
    </aggregated_zookeeper_log>

    <!-- 프로세서 프로파일 로그도 2일로 단축 -->
    <processors_profile_log>
        <ttl>event_date + INTERVAL 2 DAY</ttl>
    </processors_profile_log>
</clickhouse>
```

#### 2.1.3 매크로 설정(각 노드별 적용)
```
sudo vi /etc/clickhouse-server/config.d/macros.xml

<clickhouse>
    <macros>
        <shard>01</shard>
        <replica>node1</replica>
	</macros>
</clickhouse>
2번 서버
<clickhouse>
    <macros>
        <shard>01</shard>
        <replica>node2</replica>
    </macros>
</clickhouse>
3번 서버
<clickhouse>
    <macros>
        <shard>02</shard>
        <replica>node3</replica>
    </macros>
</clickhouse>
4번 서버
<clickhouse>
    <macros>
        <shard>02</shard>
        <replica>node4</replica>
    </macros>
</clickhouse>
```

#### 2.1.4 클러스터 및 keeper 설정 (4대 서버 공통)
```
sudo vi /etc/clickhouse-server/config.d/cluster.xml

<clickhouse>
    <!-- 외부 및 다른 서버 통신 허용 -->
    <listen_host>0.0.0.0</listen_host>

    <!-- 2개 샤드, 각 샤드별 2개 복제본 구성 -->
    <remote_servers>
        <stats_cluster>
            <!-- Shard 1 -->
            <shard>
                <internal_replication>true</internal_replication>
                <replica>
                    <host>xxx.xxx.xxx.1</host>
                    <port>9000</port>
                </replica>
                <replica>
                    <host>xxx.xxx.xxx.2</host>
                    <port>9000</port>
                </replica>
            </shard>
            <!-- Shard 2 -->
            <shard>
                <internal_replication>true</internal_replication>
                <replica>
                    <host>xxx.xxx.xxx.3</host>
                    <port>9000</port>
                </replica>
                <replica>
                    <host>xxx.xxx.xxx.4</host>
                    <port>9000</port>
                </replica>
            </shard>
        </stats_cluster>
    </remote_servers>

    <!-- Keeper 연결 설정 (모든 서버가 3대의 Keeper를 바라봄) -->
    <zookeeper>
        <node>
            <host>xxx.xxx.xxx.1</host>
            <port>2181</port>
        </node>
        <node>
            <host>xxx.xxx.xxx.2</host>
            <port>2181</port>
        </node>
        <node>
            <host>xxx.xxx.xxx.3</host>
            <port>2181</port>
        </node>
    </zookeeper>
</clickhouse>
```

#### 2.1.5 LimitNPROC 및 LimitNOFILE 설정 추가
```
sudo mkdir -p /etc/systemd/system/clickhouse-server.service.d/

cat <<EOF | sudo tee /etc/systemd/system/clickhouse-server.service.d/override.conf
[Service]
LimitNPROC=500000
LimitNOFILE=500000
EOF
```

#### 2.1.6 clickhouse-server 재시작
```
systemctl restart clickhouse-server
```
