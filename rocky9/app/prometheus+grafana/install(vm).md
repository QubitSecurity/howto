## 설치 전 참고 사항
```
노드(vm) 대상으로 모니터링하기 위한 설치
(쿠버네티스 환경을 위한 설치 방법 X)
```

## Prometheus
### 1. Prometheus 다운로드 및 저장
```
다운로드
wget https://github.com/prometheus/prometheus/releases/download/v3.0.1/prometheus-3.0.1.linux-386.tar.gz

압축해제
sudo tar -xzvf /tmp/prometheus-3.0.1.linux-386.tar.gz  -C /opt

심볼릭 링크 생성
ln -s /opt/prometheus-3.0.1.linux-386/ /opt/prometheus

실행파일 복사
sudo cp /opt/prometheus-3.0.1.linux-386/prometheus /sbin
sudo cp /opt/prometheus-3.0.1.linux-386/promtool /sbin
```

### 2. 서비스 파일 등록
```
vi /etc/systemd/system/prometheus.service

[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=prometheus --config.file=/opt/prometheus/prometheus.yml --storage.tsdb.path=/opt/prometheus/ --web.enable-lifecycle --web.enable-admin-api --storage.tsdb.retention.time=1s

[Install]
WantedBy=multi-user.target
```

### 3. 서비스 로드 및 실행
```
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
```

### 4. 프로메테우스 웹 UI
```
http://IP:9090
```

## Grafana
### 1. grafana 설치
```
sudo dnf install -y https://dl.grafana.com/enterprise/release/grafana-enterprise-11.4.0-1.x86_64.rpm
※ 참고 - 설치 방법
https://grafana.com/grafana/download?pg=oss-graf&plcmt=hero-btn-1

서비스 활성화
sudo systemctl enable --now grafana-server

```
### 2. 접속(default)
```
http://IP:3000

기본 계정
admin / admin

```




