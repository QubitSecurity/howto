## Mysqld Exporter
### 1. mysqld Exporter 다운로드 및 저장
```
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.19.0/mysqld_exporter-0.19.0.linux-amd64.tar.gz

tar xvf /opt/mysqld_exporter-0.19.0.linux-amd64.tar.gz

ln -s /opt/mysqld_exporter-0.19.0.linux-amd64.tar.gz /opt/mysqld_exporter

sudo chcon -t bin_t /opt/mysqld_exporter/mysqld_exporter

```
### 2. mysql 접근 계정 생성
```
CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'passwd';

GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';

FLUSH PRIVILEGES;

SELECT host, user FROM mysql.user;
```
### 3. 인증 파일 생성
```
vi /opt/mysqld_exporter/.mysqld_exporter.cnf

[client]
user=exporter
password=password

권한 설정
chmod 600 /opt/mysqld_exporter/.mysqld_exporter.cnf
```
### 4. systemd 서비스 파일 생성
```
vi /etc/systemd/system/mysqld_exporter.service

[Unit]
Description=Mysqld Exporter
After=network.target

[Service]
User=root
ExecStart=/opt/mysqld_exporter/mysqld_exporter  --config.my-cnf=/opt/mysqld_exporter/.mysqld_exporter.cnf

Restart=always

[Install]
WantedBy=multi-user.target
```

### 5. prometheus target 설정 및 적용
```
mkdir -p /opt/prometheus/targets

vi /opt/prometheus/prometheus.yml

  - job_name: 'mysqld_exporter'
    file_sd_configs:
      - files:
          - "/opt/prometheus/targets/mysqld_exporter_targets.yml"
※ yml 파일로 들여/내어쓰기 반드시 확인

vi /opt/prometheus/targets/mysqld_exporter_targets.yml

- targets:
  - xxx.xxx.xxx.xxx:9104
  - yyy.yyy.yyy.yyy:9104
※ mysql 서버 ip

설정 검사
promtool check config /opt/prometheus/prometheus.yml

적용(재시작 없이)
sudo curl -X POST http://localhost:9090/-/reload
```
