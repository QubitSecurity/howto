## Kafka Exporter
클러스터링 메타데이터를 가져오기 때문에 각 클러스터된 노드들 중 하나에서만 설치.
### 1. Kafka Exporter 다운로드 및 저장
```
wget https://github.com/danielqsj/kafka_exporter/releases/download/v1.9.0/kafka_exporter-1.9.0.linux-amd64.tar.gz

tar xvf /opt/kafka_exporter-1.9.0.linux-amd64.tar.gz

ln -s /opt/kafka_exporter-1.9.0.linux-amd64.tar.gz /opt/kafka_exporter

sudo chcon -t bin_t /opt/kafka_exporter/kafka_exporter

```

### 2. /opt/kafka_expoter 내부 필요 파일 설정
```
내부 파일 목록
- brokers.conf
- kafa_exporter
- start-kafka-exporter.sh

sudo vi /opt/kafka_exporter/start-kafka-exporter.sh

#!/bin/bash
ARGS=""
while read broker
do
    [ -z "$broker" ] && continue
    ARGS="$ARGS --kafka.server=$broker"
done < /opt/kafka_exporter/brokers.conf
exec /opt/kafka_exporter/kafka_exporter $ARGS
sudo systemctl enable --now blackbox_exporter 


sudo vi /opt/kafka_exporter/brokers.conf (클러스터링된 노드 정보 설정 파일)

aaa.aaa.aaa.aa1:9092
aaa.aaa.aaa.aa2:9092
aaa.aaa.aaa.aa3:9092

chcon -t bin_t /home/sysadmin/start-kafka-exporter.sh

sudo vi /etc/systemd/system/kafka_exporter.service
[Unit]
Description=Kafka Exporter
After=network.target

[Service]
Type=simple
ExecStart=/opt/kafka_exporter/start-kafka-exporter.sh

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target

sudo systemctl enable --now kafka_exporter 

```

### 3. prometheus target 설정 및 적용
```
mkdir -p /opt/prometheus/targets

vi /opt/prometheus/prometheus.yml

  - job_name: 'kafka_exporter'
    file_sd_configs:
      - files:
          - "/opt/prometheus/targets/kafka_exporter_targets.yml"
※ yml 파일로 들여/내어쓰기 반드시 확인

vi /opt/prometheus/targets/kafka_exporter_targets.yml
- targets: ['aaa.aaa.aaa.aa1:9308']
  labels:
    cluster_name: res
- targets: ['bbb.bbb.bbb.bb1:9308']
  labels:
    cluster_name: sys
- targets: ['ccc.ccc.ccc.cc1:9308']
  labels:
    cluster_name: web
※ kafka exporter 설치 서버 ip
※ yml 파일로 들여/내어쓰기 반드시 확인

설정 검사
promtool check config /opt/prometheus/prometheus.yml

적용(재시작 없이)
sudo curl -X POST http://localhost:9090/-/reload
```
