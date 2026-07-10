## Node Exporter
모든 서버에 설치
### 1. Node Exporter 다운로드 및 저장
```
sudo wget -P /opt https://github.com/prometheus/node_exporter/releases/download/v1.11.1/node_exporter-1.11.1.linux-amd64.tar.gz

sudo tar xvf /opt/node_exporter-1.11.1.linux-amd64.tar.gz -C /opt

sudo ln -s /opt/node_exporter-1.11.1.linux-amd64 /opt/node_exporter

```
### 2. 서비스 파일 생성
```
sudo vi /etc/systemd/system/node_exporter.service

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
### 3. 방화벽 오픈
```
sudo firewall-cmd --permanent --add-port=9100/tcp
sudo firewall-cmd --reload
```
### 4. prometheus target 설정 및 적용
```
vi /opt/prometheus/targets/node_exporter_targets.json

ex.
[
  {
    "targets": [
      "aaa.aaa.aaa.aaa:9100"
    ],
    "labels": {
      "env": "production",
      "role": "node_exporter"
    }
  },
  {
    "targets": [
      "aaa.aaa.aaa.bbb:9100"
    ],
    "labels": {
      "env": "production",
      "role": "node_exporter"
    }
  }
]
※ node 서버 ip



설정 검사
promtool check config /opt/prometheus/prometheus.yml

적용(재시작 없이)
sudo curl -X POST http://localhost:9090/-/reload

```
