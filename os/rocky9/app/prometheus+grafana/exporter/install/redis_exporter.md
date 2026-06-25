## Redis Exporter
### 1. Redis Exporter 다운로드 및 저장
```
wget https://github.com/oliver006/redis_exporter/releases/download/v1.86.0/redis_exporter-v1.86.0.linux-amd64.tar.gz

tar xvf /opt/redis_exporter-v1.86.0.linux-amd64.tar.gz

ln -s /opt/redis_exporter-v1.86.0.linux-amd64.tar.gz /opt/redis_exporter

sudo chcon -t bin_t /opt/redis_exporter/redis_exporter

```

### 2. systemd 서비스 파일 생성
```
sudo vi /etc/systemd/system/redis_exporter.service

[Unit]
Description=Redis Exporter
After=network.target

[Service]
User=root
ExecStart=/home/sysadmin/redis_exporter --redis.addr=redis://127.0.0.1:6379 #--redis.password=비밀번호

Restart=always

[Install]
WantedBy=multi-user.target

sudo systemctl enable --now redis_exporter 

```

### 3. prometheus target 설정 및 적용
```
mkdir -p /opt/prometheus/targets

vi /opt/prometheus/prometheus.yml

  - job_name: 'redis_exporter'
    file_sd_configs:
      - files:
          - "/opt/prometheus/targets/redis_exporter_targets.yml"
※ yml 파일로 들여/내어쓰기 반드시 확인

vi /opt/prometheus/targets/mysqld_exporter_targets.yml

[root@192010252-prometheus prometheus]# cat targets/redis_exporter_targets.yml
- targets:
  - aaa.aaa.aaa.aaa:9121
  - bbb.bbb.bbb.bbb:9121
  labels:
    cluster_name: cluster1

- targets:
  - ccc.ccc.ccc.ccc:9121
  - ddd.ddd.ddd.ddd:9121
  labels:
    cluster_name: cluster2
※ redis 서버 ip

설정 검사
promtool check config /opt/prometheus/prometheus.yml

적용(재시작 없이)
sudo curl -X POST http://localhost:9090/-/reload
```
