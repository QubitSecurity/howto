# PLURA-XDR rsyslog Gateway 설치 방법 — Go Sender v0.5 (HAProxy Active-Active)

대상 OS: **Rocky Linux 9/10** · 실행 권한: **root** · rsyslog: **8.2510.0 이상 호환 버전** · Go Sender: **0.5.0**

> **현재 검증된 Gateway 1의 환경을 기준으로 작성했습니다.** Gateway 2 역시 항상 Active로 운영하지만, 아직 제공되지 않은 Gateway 2 IP는 임의로 지정하지 않습니다.

```text
MSA (192.168.1.15)
      │ RFC5424 Structured Data / TCP 514
      ▼
HAProxy (192.168.10.25:514) ─── Active-Active 연결 분산
      ├── Gateway 1 (192.168.200.200:514)
      │     rsyslog → 메모리 큐 → omprog → Go Sender v0.5
      └── Gateway 2 (<GATEWAY2_IP>:514)
            rsyslog → 메모리 큐 → omprog → Go Sender v0.5
                                    │ TCP/UDP, 고객 지정 포트
                                    ▼
                          고객 Syslog (시험: 172.16.12.212:514/UDP)

각 Gateway: TCP/18081 /ready (HAProxy 상태 확인)
```

## 현재 확정된 IP 및 적용 경로

| 구분 | 값 | 용도 |
|---|---|---|
| MSA | `192.168.1.15` | HAProxy로 전송하는 애플리케이션 서버 |
| HAProxy | **`192.168.10.25`** | 수신 IP = Gateway 방향 송신 IP (실제 `ip route get` 결과 확인) |
| Gateway 1 | **`192.168.200.200`** | rsyslog 수신 및 자체 health probe |
| Gateway 2 | **`<GATEWAY2_IP>`** | 실제 서버 IP 입력 필요 |
| 시험 고객 서버 | `172.16.12.212:514/UDP` | 최종 Syslog 수신 서버 |

**파일 위치**

| 용도 | 경로 |
|---|---|
| Go 소스 작업 | `/home/sysadmin/plura-syslog-sender-v0.5/` |
| Go 실행파일 | `/usr/libexec/rsyslog/plura-syslog-sender` |
| Go 설정 | `/etc/plura-syslog/sender.json`, `/etc/plura-syslog/health.json` |
| rsyslog 설정 작업 | `/home/sysadmin/plura-rsyslog-config/` (예시 작업 폴더) |
| rsyslog 운영 설정 | `/etc/rsyslog.d/30-plura-gateway.conf` |
| Health 서비스 | `plura-syslog-health.service` · TCP/18081 |

**중요:** `/etc/rsyslog.conf`는 교체하지 않습니다. 제공된 `30-plura-gateway.conf`를 `/etc/rsyslog.d/`에 설치합니다. **고객별 rsyslog 설정 파일은 만들지 않습니다.** 고객 목적지 IP·포트·프로토콜은 MSA의 RFC5424 Structured Data에서 Go Sender가 읽습니다.

---

## 1. rsyslog 다운로드 및 설치

이미 Gateway 1에 `rsyslog 8.2510.0-2.el9_8.2` 및 필요한 모듈이 설치된 것을 확인했습니다. **Gateway 1은 재설치하지 않아도 됩니다.** 새 Gateway를 준비할 때만 아래 설치 명령을 실행합니다.

```bash
# 신규 서버에서만
# dnf install -y rsyslog logrotate curl

rsyslogd -v
rpm -ql rsyslog | grep -E '/(imtcp|omprog|impstats)\.so$'
rsyslogd -N1
```

필요 모듈은 `imtcp`(TCP/514 수신), `omprog`(Go 실행), `impstats`(큐 통계)입니다. 내부 경로는 **TCP/514**이며, 이번 HA 구성에는 Gateway의 `imudp` 수신이 필요하지 않습니다. 고객 방향 UDP 송신은 Go Sender가 처리합니다.

## 2. Go Sender v0.5 빌드 및 설치

### 2-1. Go 소스 디렉터리에서 빌드

**현재 Gateway 1에서는 빌드와 설치가 이미 완료되었습니다.** 새 Gateway 또는 재설치할 때만 실행합니다.

```bash
cd /home/sysadmin/plura-syslog-sender-v0.5
pwd
ls -l scripts/build.sh scripts/install-sender-v05.sh
go version
bash scripts/build.sh
bin/plura-syslog-sender -version
```

기대 버전: `0.5.0`. 기존 Gateway 1의 Go 버전은 `go1.26.7`이며, 새 서버에 Go가 없다면 `dnf install -y golang` 후 빌드합니다.

### 2-2. 고객별 설정이 아닌 공통 보안·상태 설정

최초 설치라면 아래 두 파일에서 실제 IP를 확인합니다.

```bash
cd /home/sysadmin/plura-syslog-sender-v0.5
vi conf/sender.json
vi conf/health.json
```

Gateway 1에서 중요한 값:

| 파일·항목 | 값 | 설명 |
|---|---|---|
| `sender.json` → `allowedSourceIps` | `["192.168.10.25"]` | 고객 Syslog는 HAProxy에서 전달 |
| `sender.json` → `healthProbeSourceIp` | `"192.168.200.200"` | Gateway 내부 자체 검사 |
| `sender.json` → `allowedDestinationCidrs` | `["172.16.12.212/32"]` | 시험 고객 수신 IP만 허용 |
| `health.json` → `nodeId` | `"gw1"` | Gateway 식별 |
| `health.json` → `listenAddress` | `"192.168.200.200:18081"` | 상태 검사 HTTP 포트 |
| `health.json` → `probeAddress` | `"192.168.200.200:514"` | 실제 rsyslog 처리 경로 검사 |
| `health.json` → `probeSourceIp` | `"192.168.200.200"` | 자체 probe의 송신 IP |
| `health.json` → `allowedPeerIps` | `["192.168.10.25", "192.168.200.200", "127.0.0.1"]` | health 접근 허용 IP |

**이전에 발생했던 `invalid allowedPeerIps`는 `<HAPROXY_SOURCE_IP>`가 실제 IP로 교체되지 않아 발생한 오류였습니다.** 더 이상 자리표시자를 그대로 사용하지 않습니다.

`sender.json`의 `denyCidrs`에는 Gateway 및 HAProxy로 재전송되는 루프를 차단할 IP를 유지하고, `healthAckSocket` / `ackSocket`은 모두 `/run/plura-syslog/health.sock`으로 일치시킵니다. Gateway 2는 자신의 IP를 사용하고 `nodeId`를 `gw2`로 변경합니다. 목적지 허용 범위는 고객 운영 정책에 맞춰 별도로 관리합니다.

### 2-3. 설정 검사 후 설치

```bash
cd /home/sysadmin/plura-syslog-sender-v0.5

# 소스 디렉터리의 두 JSON 사이 호환 검사
bin/plura-syslog-sender \
  -config conf/sender.json -check-pair conf/health.json

# 최초 설치 / 기존 설정을 새 파일로 교체할 때만
bash scripts/install-sender-v05.sh --replace-config

# 운영 경로에 설치된 실행파일 및 설정 검사
/usr/libexec/rsyslog/plura-syslog-sender -version
/usr/libexec/rsyslog/plura-syslog-sender \
  -config /etc/plura-syslog/sender.json \
  -check-pair /etc/plura-syslog/health.json
```

정상 출력 예: `config_pair_ok`, `Installed Go Sender 0.5.0`. Gateway 1은 **2026-10-22 10:45 KST에 이 단계가 완료**되어 있으므로 재실행할 필요가 없습니다. 기존 설정을 보존하며 실행파일만 업데이트할 경우에는 `--replace-config` 없이 설치 스크립트를 사용합니다.

**설치 스크립트는 rsyslog 설정을 교체하거나 서비스를 재시작하지 않습니다.**

---

## 3. rsyslog v0.5 설정 수정 및 설치

이번 ZIP에 포함된 **`30-plura-gateway.conf`는 실제 Gateway 1에서 `/ready`가 HTTP 200으로 회복된 규칙**을 반영했습니다. **옛 v0.4 직접 수신 설정을 다시 설치하지 마십시오.**

### 3-1. 설정 파일을 준비하는 위치

```bash
mkdir -p /home/sysadmin/plura-rsyslog-config
cd /home/sysadmin/plura-rsyslog-config

# 이 문서와 함께 제공한 30-plura-gateway.conf를 이 디렉터리에 둡니다.
ls -l 30-plura-gateway.conf
vi 30-plura-gateway.conf
```

### 3-2. 핵심 허용 규칙

```conf
# 정상 고객 로그: HAProxy 192.168.10.25에서 전달
# Gateway 자체 상태 검사: 192.168.200.200에서 생성
if (($fromhost-ip == "192.168.10.25" and $app-name == "plura-relay") or
    ($fromhost-ip == "192.168.200.200" and $app-name == "plura-health")) then {
    # 동일한 omprog action → Go Sender v0.5로 전달
}
```

고객 로그와 자체 health 메시지는 **동일한 `omprog`와 메모리 큐**를 거쳐 처리됩니다. 그 밖의 입력은 `rejected.log`에 **메타데이터만** 기록하고 거부합니다.

실제로 발생했던 오류는 다음과 같았습니다.

```text
HTTP 503 /ready: pipeline_probe_failed
rejected.log: source=192.168.200.200, app=plura-health
```

원인은 옛 설정에서 `192.168.1.15` 송신자 및 `plura-relay`만 허용했기 때문입니다. 위 조건으로 수정한 이후 **2026-10-22 11:06 KST에 `/ready` 200, `ready:true`를 확인했습니다.**

설정은 `192.168.200.200:514/TCP`에 바인딩하며, Go 실행 경로는 다음과 같습니다.

```text
/usr/libexec/rsyslog/plura-syslog-sender -config /etc/plura-syslog/sender.json
```

**Gateway 2에는** `30-plura-gateway.conf`의 `192.168.200.200`을 Gateway 2 내부 IP로 교체하고, 동일한 HAProxy IP `192.168.10.25`는 유지합니다. 서버 간 rsyslog 메모리 큐 복제는 제공되지 않습니다.

### 3-3. 기존 설정 백업 후 적용

작업 중인 Gateway의 로그 유입을 중단하고 큐 상태를 확인합니다. 정상 운영 중에는 **다른 Gateway가 UP일 때만** 한 대씩 교체하십시오. 현재처럼 한 대만 UP이면 일시 중단 시간을 정해 적용해야 합니다.

```bash
cd /home/sysadmin/plura-rsyslog-config

# 미변경 자리표시자가 있는지 확인 (출력이 없어야 정상)
grep -n '<HAPROXY_SOURCE_IP>\|<GATEWAY2_IP>' 30-plura-gateway.conf || true

# 백업은 /etc/rsyslog.d/ 밖에 보관
BACKUP="/root/plura-rsyslog-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -a /etc/rsyslog.conf "$BACKUP/rsyslog.conf"
if [ -f /etc/rsyslog.d/30-plura-gateway.conf ]; then
  cp -a /etc/rsyslog.d/30-plura-gateway.conf "$BACKUP/30-plura-gateway.conf"
fi

# 모듈·수신 포트 충돌 검사
grep -R -nE 'imtcp|omprog|impstats|port="514"' \
  /etc/rsyslog.conf /etc/rsyslog.d/
ss -lntp '( sport = :514 )'

# 설정 배치
install -d -m 0755 /etc/rsyslog.d
install -d -m 0750 /var/log/plura
install -m 0644 30-plura-gateway.conf \
  /etc/rsyslog.d/30-plura-gateway.conf
if command -v restorecon >/dev/null 2>&1; then
  restorecon -Rv /etc/rsyslog.d/30-plura-gateway.conf /var/log/plura
fi

# 재시작 전에 반드시 검사
rsyslogd -N1
echo $?
```

`rsyslogd -N1` 종료 코드가 **`0`인 경우에만** 다음 단계를 수행합니다. 실패하면 재시작하지 말고 백업 파일을 복원하고 원인을 수정합니다. `rsyslogd -N1`은 구문 검사이지 실제 로그 전달까지 보장하는 시험은 아닙니다.

---

## 4. 서비스 시작 및 적용

```bash
systemctl daemon-reload
systemctl enable rsyslog plura-syslog-health
systemctl restart rsyslog
systemctl restart plura-syslog-health
systemctl status rsyslog plura-syslog-health --no-pager -l
```

Go Sender는 `rsyslog`의 `omprog` 자식 프로그램이므로 **Go Sender 자체 systemd 서비스는 없습니다.** `plura-syslog-health`가 `/ready` 서비스를 제공합니다. 전체 rsyslog 설정 변경은 `restart`로 적용하며, SIGHUP만으로 전체 설정이 다시 읽힌다고 가정하지 않습니다.

## 5. 방화벽 설정과 주의사항

Gateway의 인바운드는 **HAProxy `192.168.10.25` → TCP/514 및 TCP/18081**만 허용합니다. Gateway 자신의 health probe(자기 IP → TCP/514)도 정상 처리되어야 합니다. 고객 서버로 나가는 TCP/UDP 포트는 네트워크 정책상 허용해야 합니다.

Gateway에서 `firewalld`가 활성화된 경우, 먼저 실제 수신 인터페이스의 zone을 확인합니다.

```bash
firewall-cmd --get-active-zones
```

아래는 해당 인터페이스의 zone이 `public`인 경우의 예시입니다. **실제 zone으로 바꿔 적용**하고, 기존 광범위 허용 규칙·SSH 관리 접근도 함께 점검합니다.

```bash
ZONE=public
for PORT in 514 18081; do
  firewall-cmd --permanent --zone="$ZONE" \
    --add-rich-rule="rule family=\"ipv4\" source address=\"192.168.10.25/32\" port port=\"$PORT\" protocol=\"tcp\" accept"
done
firewall-cmd --reload
```

**별도로 확인된 HAProxy 쪽 문제:** MSA `192.168.1.15`가 HAProxy `192.168.10.25:514`로 연결할 때 `No route to host`가 발생했으며, HAProxy 서버의 `firewalld`를 중지한 뒤 전송 명령이 성공했습니다. 이는 **HAProxy 인바운드 TCP/514 정책을 수정하고 `firewalld`를 다시 시작해야 하는 별도 작업**입니다. 운영 상태에서 방화벽을 계속 중지하지 마십시오. HAProxy의 SSH 허용·실제 zone을 먼저 확인하고, **MSA IP `192.168.1.15/32`만 TCP/514에 허용**한 뒤 재시험합니다.

## 6. 동작 확인

Gateway 1 `192.168.200.200`에서:

```bash
ss -lntp '( sport = :514 or sport = :18081 )'
curl --noproxy '*' --max-time 4 -i \
  http://192.168.200.200:18081/ready
journalctl -u rsyslog -u plura-syslog-health -n 80 --no-pager
tail -n 30 /var/log/plura/sender.log
```

**실제 확인된 상태:**

```text
HTTP/1.1 200 OK
{"node":"gw1","ready":true,"reason":"ready","customerDeliveryChecked":false}
```

- `ready:true`: rsyslog → omprog → Go Sender의 **내부 파이프라인 정상**.
- `customerDeliveryChecked:false`: **최종 고객 서버의 수신 여부는 이 응답으로 확인되지 않음**.
- HAProxy에서도 Gateway 1이 `UP`, `1 active and 0 backup`으로 표시된 것을 확인했습니다. 이는 **Gateway 2가 아직 UP으로 검증되지 않았다는 뜻**입니다.

**MSA 테스트 서버 `192.168.1.15`에서** (Bash 테스트 스크립트 보유 경로에서 실행):

```bash
bash ./syslog-test.sh \
  tcp \
  "PLURA HAProxy TEST 001" \
  192.168.10.25 \
  172.16.12.212 \
  514 \
  udp
```

실제 확인한 메시지 `Written to 192.168.10.25:514 TCP ...`는 **MSA → HAProxy의 소켓 쓰기 성공**을 나타냅니다. **새 HAProxy 경유 경로의 최종 고객 로그 수신까지 완료된 증거는 아직 제공되지 않았습니다.** 고객 서버 `172.16.12.212`의 실제 수신 로그에서 `PLURA HAProxy TEST 001`을 확인해야 End-to-End가 완료됩니다.

필요한 진단 로그:

```text
/var/log/plura/sender.log             Go Sender 처리 결과·오류
/var/log/plura/rejected.log           rsyslog가 거부한 입력의 메타데이터
/var/log/plura/rsyslog-stats.jsonl    큐·처리량 통계
```

## 7. Gateway 2와 Active-Active 운영 시 유의사항

- Gateway 2를 준비할 때는 **자신의 실제 IP**를 `sender.json`, `health.json`, `30-plura-gateway.conf`에 일관되게 반영합니다.
- 두 Gateway 모두 `UP`이면 HAProxy가 **TCP 연결 단위**로 분산합니다. `backup` 옵션은 사용하지 않습니다.
- 연결 하나를 오랫동안 유지하는 MSA는 그 연결이 배정된 **한 Gateway만 사용**합니다. 여러 재사용 연결을 사용하는 방법은 BE 설계에서 다룹니다.
- 특정 Gateway가 DOWN이면 HAProxy는 신규 연결을 정상 Gateway로 연결합니다. **기존 연결은 자동 이전되지 않으므로 MSA 재연결 처리가 필요**합니다.
- 메모리 큐 기반으로 **장애·재시작 시 미전송 로그 유실 가능성**이 있습니다. `ready:true`도 무손실 또는 고객 SIEM 저장을 보장하지 않습니다.
- CEF·RFC3164 출력은 Go v0.5에서 지원하지만, **TLS/RFC5425는 아직 미구현**입니다.

**적용 범위 요약:** 기존에 첨부된 rsyslog 설치 안내의 구조를 유지하면서, 현재 사용 중인 `plura-syslog-sender-v0.5`와 실제 성공한 IP·Health 허용 규칙·방화벽 원인·송신 시험 범위를 반영했습니다.
