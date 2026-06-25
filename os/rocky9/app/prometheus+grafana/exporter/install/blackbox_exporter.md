## Blackbox Exporter
모든 서버에 설치
### 1. Blackbox Exporter 다운로드 및 저장
```
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.28.0/blackbox_exporter-0.28.0.linux-amd64.tar.gz

tar xvf /opt/blackbox_exporter-0.28.0.linux-amd64.tar.gz

ln -s /opt/blackbox_exporter-0.28.0.linux-amd64.tar.gz /opt/blackbox_exporter

sudo chcon -t bin_t /opt/blackbox_exporter/blackbox_exporter

```

### 2. systemd 서비스 파일 생성
```
sudo vi /etc/systemd/system/blackbox_exporter.service

[Unit]
Description=Blackbox Exporter
After=network.target

[Service]
User=root
ExecStart=blackbox_exporter  --config.file=/home/sysadmin/blackbox_exporter/blackbox.yml

Restart=always

[Install]
WantedBy=multi-user.target

sudo systemctl enable --now blackbox_exporter 

```

### 3. prometheus target 설정 및 적용
```
mkdir -p /opt/prometheus/targets

vi /opt/prometheus/prometheus.yml

  - job_name: 'backing_check'
    metrics_path: /probe
    params:
      module: [tcp_connect]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9115
    file_sd_configs:
      - files:
          - "/opt/prometheus/targets/backing_targets.yml"
※ yml 파일로 들여/내어쓰기 반드시 확인

vi /opt/prometheus/targets/backing_targets.yml

- targets:
  - aaa.aaa.aaa.aaa:9092
  - bbb.bbb.bbb.bbb:9092
  labels:
    backing_name: backing-1

- targets:
  - ccc.ccc.ccc.ccc:9092
  - ddd.ddd.ddd.ddd:9092
  labels:
    backing_name: backing-1
※ backing 서버 ip(ex, redis, kafka 등)
※ yml 파일로 들여/내어쓰기 반드시 확인

설정 검사
promtool check config /opt/prometheus/prometheus.yml

적용(재시작 없이)
sudo curl -X POST http://localhost:9090/-/reload
```
