# Go Sender v0.5 설치 방법

Rocky Linux 9/10 · root 실행 · Go Sender **0.5.0** · 두 Gateway에 각각 설치.

기존에 제공한 **`PLURA_XDR_Go_Sender_v0.5.zip`**을 사용합니다. 이 문서는 설치 안내만 제공하며, 소스와 설정 파일은 해당 ZIP에 있습니다.

**선행 조건:** 앞서 제공한 rsyslog 설치와 `/etc/rsyslog.d/30-plura-gateway.conf` 적용이 완료되어 있어야 합니다. 아래 설치는 HAProxy·rsyslog 설정을 변경하지 않습니다. 명령에 오류가 나오면 다음 단계로 진행하지 마십시오.

## 1. 다운로드 및 빌드

기존 Go Sender v0.5 소스 ZIP을 다운로드하여 Gateway의 `/home/sysadmin`에 올린 뒤 실행합니다. 현재 설치된 Go 1.26.7은 그대로 사용합니다.

```bash
(
set -e
# 이미 설치된 Go는 재설치하지 않습니다.
command -v go >/dev/null || dnf install -y golang
command -v unzip >/dev/null || dnf install -y unzip
go version

cd /home/sysadmin
unzip PLURA_XDR_Go_Sender_v0.5.zip
cd plura-syslog-sender-v0.5
bash scripts/build.sh
bin/plura-syslog-sender -version
)
```

마지막 버전 출력이 **`0.5.0`**이면 빌드가 완료된 것입니다. 이미 압축을 해제했다면 `unzip`은 생략합니다.

## 2. 설정 확인 및 설치

```bash
cd /home/sysadmin/plura-syslog-sender-v0.5
```

**아래 A와 B 중 해당하는 한 가지만 실행합니다.**

### A. 기존 HA용 설정이 정상 설치되어 있는 경우

`/etc/plura-syslog/sender.json`과 `health.json`을 그대로 사용할 때입니다.

```bash
bash scripts/install-sender-v05.sh
```

기존 설정을 검증하여 보존하고, 실행파일과 상태 점검 서비스 파일을 백업 후 교체합니다.

### B. 최초 설치 또는 직접 수신용 v0.4에서 HA 구성으로 전환하는 경우

소스 ZIP에 포함된 두 설정 파일을 수정합니다.

```bash
vi conf/sender.json
vi conf/health.json
```

| 설정에 있는 값 | 변경할 내용 |
|---|---|
| `<HAPROXY_SOURCE_IP>` | HAProxy가 Gateway로 연결할 때 사용하는 실제 송신 IP. **MSA IP가 아닙니다.** |
| `192.168.200.200` | Gateway 1은 유지. Gateway 2에서는 해당 서버의 내부 IP로 모두 변경 |
| `172.16.18.200/32` | Gateway 1의 다른 NIC 주소를 목적지에서 제외하는 값. Gateway 2는 자신의 주소로 변경 |
| `"nodeId": "gw1"` | Gateway 2는 `"gw2"`로 변경 |
| `172.16.12.212/32` | 시험 고객 수신 서버. 해당 서버로 시험할 때는 유지 |

수정한 설정을 함께 설치합니다.

```bash
bash scripts/install-sender-v05.sh --replace-config
```

기존 설정이 있으면 백업 후 교체합니다. `<HAPROXY_SOURCE_IP>`를 수정하지 않으면 설치가 중단됩니다. 백업은 `/var/backups/plura-syslog/` 아래에 저장됩니다.

## 3. 설정 검사 및 기동

설치된 실행파일과 설정을 확인합니다.

```bash
/usr/libexec/rsyslog/plura-syslog-sender -version

/usr/libexec/rsyslog/plura-syslog-sender \
  -config /etc/plura-syslog/sender.json \
  -check-pair /etc/plura-syslog/health.json && \
rsyslogd -N1
```

**두 설정 검사가 모두 성공했을 때만** 다음 명령을 실행합니다. 이미 운영 중이면 다른 Gateway의 정상 여부를 확인하고, 작업 서버의 신규 유입을 중단한 뒤 큐가 비워진 상태에서 **한 대씩** 적용하십시오. 메모리 큐에 로그가 남아 있으면 재시작 시 유실될 수 있습니다.

```bash
systemctl daemon-reload && \
systemctl restart rsyslog && \
systemctl enable plura-syslog-health && \
systemctl restart plura-syslog-health
```

**Go Sender는 rsyslog가 실행하므로 별도의 Sender 서비스 등록이나 수동 실행이 필요 없습니다.** `plura-syslog-health` 서비스 파일은 설치 스크립트가 등록하며, HAProxy의 상태 확인에 사용합니다.

## 4. 설치 확인

```bash
systemctl status rsyslog plura-syslog-health --no-pager
ss -lntp '( sport = :514 or sport = :18081 )'

# Gateway 1 기준. Gateway 2에서는 자신의 내부 IP로 변경합니다.
curl --noproxy '*' -i http://192.168.200.200:18081/ready
```

확인할 결과는 **두 서비스 `active (running)`, TCP/514·18081 수신, `/ready`의 HTTP 200**입니다. `curl`이 없으면 확인 도구만 추가합니다: `dnf install -y curl`.

오류가 있으면 다음 로그를 확인합니다.

```bash
journalctl -u rsyslog -u plura-syslog-health -n 100 --no-pager
tail -n 50 /var/log/plura/sender.log
```

방화벽에서는 **HAProxy 송신 IP → Gateway TCP/514·18081**이 허용되어 있어야 합니다. SELinux는 Enforcing을 유지하며, 접근이 거부되면 `ausearch -m AVC,USER_AVC -ts recent`로 확인합니다. `/ready`의 정상 응답은 내부 처리 경로 확인이며, 고객 서버의 실제 로그 저장까지 확인하는 것은 아닙니다.

---

정리 기준: Go Sender v0.5 배포본의 `README.md`, `scripts/build.sh`, `scripts/install-sender-v05.sh`, `conf/sender.json`, `conf/health.json`. 설치 명령의 Bash 문법을 검사했으며, 대상 서버에서 설치를 대신 실행한 것은 아닙니다.
