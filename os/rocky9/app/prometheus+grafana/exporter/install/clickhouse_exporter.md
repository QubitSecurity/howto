## clickhouse Exporter
- clickhouse server 설치 시, 내장 exporer  사용 가능
- 모든 서버에 설치 필요

### 1. clickhouse Exporter 설정
```
sudo vi /etc/clickhouse-server/config.d/prometheus.yml

<clickhouse>
  <prometheus>
    <endpoint>/metrics</endpoint>
    <port>9363</port>
    <metrics>true</metrics>
    <events>true</events>
    <asynchronous_metrics>true</asynchronous_metrics>
    <errors>true</errors>
  </prometheus>
</clickhouse>
```

### 2. clickhouse server 재시작
```
sudo systemctl restart clickhouse-server

9363 포트 활성화 확인
sudo netstat -natp | grep LISTEN| grep 9363
```

### 3. prometheus target 설정 및 적용
```
mkdir -p /opt/prometheus/targets

vi /opt/prometheus/prometheus.yml

  - job_name: 'clickhouse_exporter'
    file_sd_configs:
      - files:
          - "/opt/prometheus/targets/clickhouse_exporter_targets.yml"
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
      - source_labels: [cluster_name]
        target_label: cluster
        action: replace

※ yml 파일로 들여/내어쓰기 반드시 확인

vi /opt/prometheus/targets/clickhouse_exporter_targets.yml

- targets:
  - xxx.xxx.xxx.xx0:9363
  - xxx.xxx.xxx.xx1:9363
  - xxx.xxx.xxx.xx2:9363
  - xxx.xxx.xxx.xx3:9363
  labels:
    cluster_name: clickhouse
※ clickhouse서버 ip

설정 검사
promtool check config /opt/prometheus/prometheus.yml

적용(재시작 없이)
sudo curl -X POST http://localhost:9090/-/reload
```
