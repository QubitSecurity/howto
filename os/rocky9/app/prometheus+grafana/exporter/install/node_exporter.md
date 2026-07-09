## Node Exporter
모든 서버에 설치
### 1. Node Exporter 다운로드 및 저장
```
wget -P /opt https://github.com/prometheus/node_exporter/releases/download/v1.11.1/node_exporter-1.11.1.linux-amd64.tar.gz

tar xvf /opt/node_exporter-1.11.1.linux-amd64.tar.gz

ln -s /opt/node_exporter-1.11.1.linux-amd64 /opt/node_exporter


```
### 2. 서비스 파일 생성
```
vi /etc/systemd/system/node_exporter.service

[Unit]
Description=Node Exporter
After=network.target

[Service]
User=root
ExecStart=/opt/node_exporter/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target

sudo systemctl enable --now node_exporter
```
