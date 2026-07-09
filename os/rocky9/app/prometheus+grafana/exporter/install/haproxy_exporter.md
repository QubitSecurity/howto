## Kafka Exporter
haproxy exporter를 설치하는 2가지 방법
1. haproxy exporter 일반 설치
2. haproxy 자체 지원 exporter 설치

### 1. haproxy exporter 일반 설치
#### 1.1 haporxy Exporter 다운로드 및 저장
```
wget https://github.com/prometheus/haproxy_exporter/releases/download/v0.15.0/haproxy_exporter-0.15.0.linux-amd64.tar.gz

tar xvf /opt/haproxy_exporter-0.15.0.linux-amd64.tar.gz

ln -s /opt/haproxy_exporter-0.15.0.linux-amd64.tar.gz /opt/haproxy_exporter

sudo chcon -t bin_t /opt/kafka_exporter/haproxy_exporter
```

### 1.2 /opt/kafka_expoter 내부 필요 파일 설정
```

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
