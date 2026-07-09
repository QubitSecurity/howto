## Kafka Exporter
haproxy exporter를 설치하는 2가지 방법
1. haproxy exporter 일반 설치
2. haproxy 자체 지원 exporter(PROMEX) 사용(haproxy v2.0 이상 가능)

### 1. haproxy exporter 일반 설치
#### 1.1 haporxy Exporter 다운로드 및 저장
```
wget https://github.com/prometheus/haproxy_exporter/releases/download/v0.15.0/haproxy_exporter-0.15.0.linux-amd64.tar.gz

tar xvf /opt/haproxy_exporter-0.15.0.linux-amd64.tar.gz

ln -s /opt/haproxy_exporter-0.15.0.linux-amd64.tar.gz /opt/haproxy_exporter

sudo chcon -t bin_t /opt/kafka_exporter/haproxy_exporter
```

#### 1.2. systemd 서비스 파일 생성
```
sudo vi /etc/systemd/system/haproxy_exporter.service

[Unit]
Description=Prometheus HAProxy Exporter
After=network.target

[Service]
User=root
ExecStart=/opt/haproxy_exporter/haproxy_exporter --haproxy.scrape-uri=unix://var/run/haproxy.sock

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target

sudo systemctl enable --now haproxy_exporter
```
#### 1.3 방화벽 포트 오픈
```
sudo firewall-cmd --permanent --add-port=9101/tcp
sudo firewall-cmd --reload
```


### 2. haproxy 자체 지원 exporter 설치
#### 2.1 지원 여부 확인
```
haproxy -vv | grep prometheus

ex.
Available services : prometheus-exporter
※패키지 설치가 아닌 source 설치의 경우 빌드 시, "USE_PROMEX=1" 옵션을 추가.
```
#### 2.2 haproxy frontend 설정
```
sudo vi /etc/haproxy/haproxy.cfg

frontend prometheus
        bind *:8405
        mode http
        http-request use-service prometheus-exporter if { path /metrics }
        no log
```
#### 2.3 방화벽 포트 오픈
```
sudo firewall-cmd --permanent --add-port=8405/tcp
sudo firewall-cmd --reload
```

### 3. prometheus target 설정 및 적용
```
mkdir -p /opt/prometheus/targets

vi /opt/prometheus/prometheus.yml

  - job_name: 'haproxy_exporter'
    file_sd_configs:
      - files:
          - "/opt/prometheus/targets/haproxy_exporter_targets.yml"
※ yml 파일로 들여/내어쓰기 반드시 확인

sudo vi /opt/prometheus/targets/haproxy_exporter_targets.yml
- targets:
  - aaa.aaa.aaa.aaa:PORT # 일반 설치: 9091 / 자체 제공: 8405
  - aaa.aaa.aaa.bbb:PORT # 일반 설치: 9091 / 자체 제공: 8405
  labels:
    cluster_name: cluster1

- targets:
  - ccc.ccc.ccc.ccc:PORT # 일반 설치: 9091 / 자체 제공: 8405
  - ccc.ccc.ccc.ddd:PORT # 일반 설치: 9091 / 자체 제공: 8405
  labels:
    cluster_name: cluster2
※ haproxy 서버 ip

설정 검사
promtool check config /opt/prometheus/prometheus.yml

적용(재시작 없이)
sudo curl -X POST http://localhost:9090/-/reload
```

