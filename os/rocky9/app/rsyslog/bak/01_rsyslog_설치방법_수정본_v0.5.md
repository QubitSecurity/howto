# rsyslog 설치 방법 — Go Sender v0.5 기준

Rocky Linux 9/10 · `root` 권한 · **Gateway 2대 모두 Active-Active**.

```text
MSA → HAProxy TCP/514 → rsyslog TCP/514 → omprog → Go Sender v0.5 → 고객 Syslog 서버(TCP/UDP)
                                                  └─ 상태 확인: TCP/18081 /ready
```

이 문서는 **기존 `01_rsyslog_설치방법.md`를 수정한 설치 안내**입니다. 실제 사용 중인 Go Sender 소스 디렉터리는 **`/home/sysadmin/plura-syslog-sender-v0.5`**입니다. `v0.4.1-ha` 파일을 새로 받거나 설치할 필요가 없습니다.

- **Go 소스·빌드 작업 경로:** `/home/sysadmin/plura-syslog-sender-v0.5`
- **설치된 Go 실행파일:** `/usr/libexec/rsyslog/plura-syslog-sender`
- **Go 설정:** `/etc/plura-syslog/sender.json`, `/etc/plura-syslog/health.json`
- **rsyslog 설정 작업 경로:** 함께 제공된 `30-plura-gateway.conf`가 있는 디렉터리 (예: `/home/sysadmin/plura-rsyslog-config`)
- **rsyslog 운영 설정:** `/etc/rsyslog.d/30-plura-gateway.conf`
- **Go 상태 확인 서비스:** `plura-syslog-health.service` (TCP/18081 `/ready`)

**소스 디렉터리, 설정 작업 디렉터리, 운영 설정 경로는 서로 다릅니다.** `/etc/rsyslog.conf`는 덮어쓰지 않습니다. 두 Gateway에 각각 적용하되, Gateway 2는 자신의 IP를 사용합니다.

## 1. rsyslog 다운로드 및 설치

rsyslog는 Rocky Linux 저장소에서 DNF로 설치합니다. 이미 설치되어 있으면 재설치할 필요는 없으며, `dnf install`을 다시 실행하면 저장소 버전에 따라 업그레이드될 수 있습니다.

```bash
# 설치되지 않은 서버에서만 실행
# dnf install -y rsyslog logrotate curl

# 버전·모듈 확인
rsyslogd -v
rpm -ql rsyslog | grep -E '/(imtcp|omprog|impstats)\.so$'

# 현재 설정 검사
rsyslogd -N1
```

기존에 확인한 **rsyslog 8.2510.0**과 `imtcp`, `omprog`, `impstats` 모듈이면 이번 구성에 적합합니다. 내부 전송은 **TCP/514만 사용**합니다. 고객 방향의 UDP/TCP 송신은 Go Sender가 담당하며, Gateway의 UDP/514 수신 설정은 필요하지 않습니다.

## 2. Go Sender v0.5 빌드 및 설치

**여기부터는 rsyslog 설정 디렉터리가 아니라 Go Sender 소스 디렉터리에서 작업**합니다.

### 2-1. 소스 디렉터리로 이동 및 빌드

이미 압축을 해제하여 `plura-syslog-sender-v0.5` 디렉터리가 있다면 ZIP을 다시 풀지 않습니다.

```bash
cd /home/sysadmin/plura-syslog-sender-v0.5
pwd
ls -l scripts/build.sh scripts/install-sender-v05.sh

# 설치된 Go 활용 (기존 서버는 Go 1.26.7 확인됨)
go version
bash scripts/build.sh
bin/plura-syslog-sender -version
```

마지막 출력이 **`0.5.0`**이면 빌드 성공입니다. Go가 없는 다른 Gateway에서만 `dnf install -y golang`을 실행합니다.

### 2-2. 최초 설치인지, 기존 HA 설정이 있는지 구분

**A. 기존 HA용 `sender.json`·`health.json`이 있으며, 내용이 올바른 경우:**

```bash
cd /home/sysadmin/plura-syslog-sender-v0.5
bash scripts/install-sender-v05.sh
```

기존 설정을 검증·보존하면서 Go 실행파일과 상태 점검 서비스 파일을 백업·교체합니다.

**B. 최초 설치 또는 직접 수신용 v0.4에서 HAProxy 경유 구조로 전환하는 경우:**

```bash
cd /home/sysadmin/plura-syslog-sender-v0.5
vi conf/sender.json
vi conf/health.json
```

| 수정할 항목 | Gateway 1 기준 | Gateway 2 |
|---|---|---|
| `<HAPROXY_SOURCE_IP>` | **HAProxy 서버 IP**로 변경 | 동일한 HAProxy 서버 IP |
| `sender.json` → `allowedSourceIps` | HAProxy 송신 IP 포함 (MSA IP 아님) | 동일 |
| `sender.json` → `healthProbeSourceIp` | `192.168.200.200` | Gateway 2의 내부 IP |
| `health.json` → `nodeId` | `gw1` | `gw2` |
| `health.json` → `listenAddress` | `192.168.200.200:18081` | Gateway 2 IP`:18081` |
| `health.json` → `probeAddress` | `192.168.200.200:514` | Gateway 2 IP`:514` |
| `health.json` → `probeSourceIp` | `192.168.200.200` | Gateway 2의 내부 IP |
| `health.json` → `allowedPeerIps` | HAProxy IP 및 Gateway 자체 IP | HAProxy IP 및 Gateway 2 자체 IP |
| `allowedDestinationCidrs` | 테스트용 `172.16.12.212/32` 허용 | 동일 정책 |

**HAProxy의 수신 IP와 송신 IP가 같은 현재 구성에서는 `<HAPROXY_SOURCE_IP>`에 HAProxy 서버 IP 하나를 동일하게 입력**하면 됩니다. 단, Gateway에서 실제로 관측되는 송신 IP가 그 주소인지 네트워크 환경을 확인하십시오.

`sender.json`의 `denyCidrs`에는 자기 Gateway·HAProxy 등으로 돌아가는 주소가 포함되어야 합니다. Gateway 2에서는 Gateway 1의 다른 NIC인 `172.16.18.200/32`를 무작정 복사하지 말고 자신의 인터페이스·차단 대상 IP에 맞춰 검토하십시오. `healthAckSocket` 및 `ackSocket`은 동일하게 `/run/plura-syslog/health.sock`을 사용합니다.

설정 검증 후 설치합니다.

```bash
# 편집한 신규 설정을 적용하는 최초 설치/전환에만 사용
bash scripts/install-sender-v05.sh --replace-config
```

`--replace-config`는 기존 설정이 있더라도 편집한 `conf/*.json`으로 교체합니다. 반대로 **기존 운영 설정을 유지해야 한다면 `--replace-config` 없이** 설치하십시오. 설치 스크립트는 rsyslog·HAProxy 설정을 수정하거나 서비스를 재시작하지 않습니다. 기존 파일 백업은 `/var/backups/plura-syslog/`에 남깁니다.

### 2-3. Go 설치 결과 확인

```bash
/usr/libexec/rsyslog/plura-syslog-sender -version
/usr/libexec/rsyslog/plura-syslog-sender \
  -config /etc/plura-syslog/sender.json \
  -check-pair /etc/plura-syslog/health.json

ls -l /etc/plura-syslog/sender.json /etc/plura-syslog/health.json
systemctl cat plura-syslog-health
```

**버전 `0.5.0` 및 설정 검증 성공**을 확인한 뒤 3번으로 진행합니다. `plura-syslog-health`는 rsyslog 설치만으로 생기는 서비스가 아니라 Go v0.5 설치 스크립트가 등록하는 서비스입니다.

## 3. rsyslog `30-plura-gateway.conf` 수정 및 설치

**다시 rsyslog 설정 파일이 있는 디렉터리로 이동합니다.** Go 소스 디렉터리에서 `vi 30-plura-gateway.conf`를 실행하는 것이 아닙니다. 설정 파일을 `/home/sysadmin/plura-rsyslog-config`에 두었다면 아래처럼 진행합니다.

```bash
mkdir -p /home/sysadmin/plura-rsyslog-config
cd /home/sysadmin/plura-rsyslog-config
# 기존에 제공된 rsyslog ZIP이 있다면 이 위치에서 압축 해제합니다.
# unzip /home/sysadmin/PLURA_XDR_Rsyslog_2files.zip
# 이미 파일을 준비했다면 압축 해제는 생략합니다.
ls -l 30-plura-gateway.conf
vi 30-plura-gateway.conf
```

`30-plura-gateway.conf` 자체는 **앞서 별도로 제공된 rsyslog 설정 파일**을 사용합니다. `plura-syslog-sender-v0.5` 소스 폴더에는 이 rsyslog 설정 파일이 없습니다.

| 설정 파일 안의 값 | 변경 방법 |
|---|---|
| `<HAPROXY_SOURCE_IP>` | HAProxy 서버 IP로 교체 (현재는 수신·송신 IP 동일) |
| `192.168.200.200` | Gateway 1은 그대로 사용; Gateway 2에서는 자신의 내부 IP로 교체 |
| `binary=...plura-syslog-sender` | `/usr/libexec/rsyslog/plura-syslog-sender -config /etc/plura-syslog/sender.json` 유지 |

설정 파일 상단 주석에 옛 버전명 `v0.4.1-ha`가 남아 있다면 **문서 표기만 `v0.5`로 고치면 됩니다.** `omprog`가 참조하는 실행파일 경로·입력 JSON 템플릿·`plura-relay` 필터는 v0.5에서도 그대로 사용합니다. 고객 목적지는 이 파일에 넣지 않습니다. MSA가 RFC5424 Structured Data로 전달합니다.

기존 TCP/514 리스너 및 모듈 중복을 확인합니다.

```bash
grep -R -nE 'imtcp|omprog|impstats|port="514"' /etc/rsyslog.conf /etc/rsyslog.d/
ss -lntp '( sport = :514 )'
```

다음은 **검증 → 백업 → 파일 설치 → 검증** 순서입니다. 메모리 큐에 미전송 로그가 남아 있는 서비스에서는 작업 전 신규 송신을 중단하고 큐 상태를 확인하십시오.

```bash
cd /home/sysadmin/plura-rsyslog-config

# 편집이 누락된 IP 자리표시자가 없어야 함
grep -n '<HAPROXY_SOURCE_IP>' 30-plura-gateway.conf || true
# 출력이 있으면 반드시 실제 HAProxy IP로 바꾼 뒤 진행

# 기존 설정 백업 (include 경로 밖)
BACKUP="/root/plura-rsyslog-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -a /etc/rsyslog.conf "$BACKUP/rsyslog.conf"
if [ -f /etc/rsyslog.d/30-plura-gateway.conf ]; then
  cp -a /etc/rsyslog.d/30-plura-gateway.conf "$BACKUP/30-plura-gateway.conf"
fi

# 운영 설정 경로에 복사
install -d -m 0755 /etc/rsyslog.d
install -d -m 0750 /var/log/plura
install -m 0644 30-plura-gateway.conf /etc/rsyslog.d/30-plura-gateway.conf

# SELinux 기본 레이블 복구 (명령이 존재하는 경우)
if command -v restorecon >/dev/null 2>&1; then
  restorecon -Rv /etc/rsyslog.d/30-plura-gateway.conf /var/log/plura
fi

# 전체 설정 검사
rsyslogd -N1
echo $?
```

**`echo $?`가 `0`인 경우에만** 4번으로 진행합니다. 설정 검사에 실패하면 서비스를 재시작하지 말고 백업한 `30-plura-gateway.conf`를 복원한 뒤 원인을 수정하십시오.

## 4. 서비스 등록 및 시작

운영 설정 검사에 성공하면 다음을 실행합니다. **Go Sender는 rsyslog가 `omprog`로 직접 실행**하므로 `plura-syslog-sender.service`는 없습니다. 별도 서비스는 상태 확인용 `plura-syslog-health`뿐입니다.

```bash
systemctl daemon-reload
systemctl enable rsyslog plura-syslog-health
systemctl restart rsyslog
systemctl restart plura-syslog-health
systemctl status rsyslog plura-syslog-health --no-pager -l
```

기존 운영 중이라면 **Gateway 한 대씩** 진행하고, 작업 대상 Gateway의 `/ready`를 503 상태로 드레인한 뒤 큐가 비었는지 확인하십시오. 메모리 큐이므로 재시작 시 미전송 데이터 유실 가능성이 있습니다. `reload`만으로 전체 rsyslog 설정을 다시 읽는다고 가정하지 마십시오.

**네트워크 허용:** HAProxy 송신 IP → Gateway TCP/514 및 TCP/18081; Gateway → 고객 서버는 고객이 선택한 TCP/UDP 포트를 허용합니다. SELinux Enforcing은 유지하고 차단이 발생하면 감사 로그에서 원인을 확인합니다.

## 5. 정상 동작 확인

Gateway 1 (`192.168.200.200`)에서 실행합니다. Gateway 2는 각자의 IP로 변경합니다.

```bash
# 두 포트의 LISTEN 확인: rsyslog TCP/514, health TCP/18081
ss -lntp '( sport = :514 or sport = :18081 )'

# rsyslog → Go Sender의 실제 경로 점검
curl --noproxy '*' --max-time 4 -i \
  http://192.168.200.200:18081/ready

# 기동·오류 확인
journalctl -u rsyslog -u plura-syslog-health -n 100 --no-pager
tail -n 30 /var/log/plura/sender.log
```

기대 결과: 두 서비스 `active (running)`, TCP/514·18081 LISTEN, `/ready`의 **HTTP 200 및 `"ready":true`**. 단, 이는 Gateway 내부 처리 경로 확인이지 고객 Syslog 서버의 저장 완료 ACK는 아닙니다.

디버깅 로그 경로:

```text
/var/log/plura/sender.log            Go Sender 처리·오류
/var/log/plura/rejected.log          허용되지 않은 입력의 메타데이터
/var/log/plura/rsyslog-stats.jsonl   rsyslog 처리·큐 통계
```

**최종 MSA 연결 목적지는 각 Gateway가 아니라 HAProxy의 TCP/514입니다.** 두 Gateway는 상시 Active로 처리하며 HAProxy가 TCP **연결 단위**로 분산합니다. 고객별 rsyslog 설정 파일 및 목적지 조회 API는 필요하지 않습니다.

---

**문서 적용 범위:** 첨부된 rsyslog 설치 안내의 기능·설치 구조는 유지하고, 실제 보유한 `plura-syslog-sender-v0.5` 소스·설치 스크립트·설정 파일을 기준으로 경로와 명령을 정정했습니다. 실제 서버의 rsyslog 설정 검사 및 고객 수신까지의 통합 검증은 설치 서버에서 수행해야 합니다.
