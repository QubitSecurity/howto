# rsyslog 설치 방법

Rocky Linux 9/10 · root 실행 · **두 Gateway 모두 Active-Active**.

`MSA → HAProxy TCP/514 → rsyslog → 메모리 큐 → Go Sender → 고객 Syslog`

이 ZIP은 **이 안내문과 `30-plura-gateway.conf` 두 파일**입니다. 설정 생성기나 보조 스크립트는 없습니다.
기존 `/etc/rsyslog.conf`는 유지하고, PLURA 설정만 `/etc/rsyslog.d/`에 설치합니다.
Gateway 1·2에서 같은 절차를 실행하되, 각 서버의 내부 IP를 사용하십시오.

## 1. 다운로드 및 설치

rsyslog는 소스 tar.gz를 따로 받지 않고 **Rocky Linux 저장소에서 DNF로 다운로드·설치**합니다.
기존에 확인한 `8.2510.0-2.el9_8.2`는 그대로 사용하며, 아래 명령은 저장소 상태에 따라 패키지를 갱신할 수 있습니다.

```bash
dnf install -y rsyslog logrotate curl
rsyslogd -v
rpm -ql rsyslog | grep -E '/(imtcp|omprog|impstats)\.so$'
```

`imtcp.so`, `omprog.so`, `impstats.so`를 확인합니다. 모듈이 없다면 `dnf provides '*/omprog.so'`처럼 제공 패키지를 조회합니다.
이번 내부 경로에는 UDP 수신 모듈 `imudp`가 필요 없습니다. 고객으로 UDP를 보내는 기능은 Go Sender가 처리합니다.

## 2. Go Sender 선행 조건 확인

**이 ZIP은 rsyslog 전용이며 Go 소스·실행파일·Go 설정을 새로 설치하지 않습니다.**
앞서 제공한 **v0.4.1-ha의 Go Sender와 상태 점검 서비스**가 두 Gateway에 설치되어 있어야 합니다.
현재 v0.4만 설치되어 있다면 먼저 기존 v0.4.1-ha 자료로 업그레이드하십시오.

```bash
/usr/libexec/rsyslog/plura-syslog-sender -version
ls -l /etc/plura-syslog/sender.json /etc/plura-syslog/health.json
systemctl cat plura-syslog-health
```

버전 `0.4.1-ha`, 두 JSON 파일, 상태 점검 서비스가 있어야 합니다.
없다면 여기서 멈춥니다. **rsyslog 설치만으로 HTTP/18081 `/ready`가 생기지 않으며, 이 서비스가 없으면 앞서 받은 HAProxy 설정은 Gateway를 DOWN 처리합니다.**

## 3. config의 IP 수정

ZIP을 푼 디렉터리에서 함께 받은 파일을 편집합니다.

```bash
vi 30-plura-gateway.conf
```

| 파일 안의 값 | 수정 방법 |
|---|---|
| `<HAPROXY_SOURCE_IP>` | HAProxy config의 `source`에 지정한 실제 IP로 교체 |
| `192.168.200.200` | Gateway 1은 유지. Gateway 2에서는 **파일 안의 모든 해당 주소**를 Gateway 2 내부 IP로 교체 |

HAProxy 수신 IP와 Gateway 방향 송신 IP는 다를 수 있습니다. 중간 SNAT가 있다면 Gateway에서 실제로 관측되는 송신 IP와 맞춰야 합니다.
고객 목적지 IP는 이 conf에 적지 않습니다. MSA가 RFC5424 Structured Data로 전달합니다.

**기존 Go 설정도 아래 값과 일치하는지 확인합니다.** 이미 HA 구성으로 설치했다면 변경할 필요 없습니다.

| 기존 Go 설정 | 맞출 값 |
|---|---|
| `sender.json` → `allowedSourceIps` | HAProxy 송신 IP 배열. 예전 MSA IP가 아님 |
| `sender.json` → `healthProbeSourceIp` | 해당 Gateway 내부 IP |
| `health.json` → `listenAddress` | 해당 Gateway 내부 IP + `:18081` |
| `health.json` → `probeAddress`, `probeSourceIp` | 해당 Gateway 내부 IP + `:514`, 해당 Gateway 내부 IP |
| `health.json` → `allowedPeerIps` | HAProxy 송신 IP와 해당 Gateway 내부 IP |

`sender.json`의 `healthAckSocket`과 `health.json`의 `ackSocket`은 기존 동일 값 `/run/plura-syslog/health.sock`을 유지합니다.
고객 목적지 허용 정책 `allowedDestinationCidrs`도 유지합니다. 시험 고객 `172.16.12.212/32`가 허용되어 있어야 합니다.

## 4. 설정 설치 및 기동

**기존 모듈 선언·리스너 중복을 먼저 확인합니다.**
기존 v0.4의 `30-plura-gateway.conf`는 이번 파일로 교체합니다. 다른 파일에 같은 모듈·TCP/514 수신이 있다면 중복을 해소합니다.
기존 `/etc/rsyslog.conf`에서 `/etc/rsyslog.d/*.conf`를 읽는 설정도 유지해야 합니다.

```bash
grep -R -nE 'imtcp|imudp|omprog|impstats|port="514"' /etc/rsyslog.conf /etc/rsyslog.d/
ss -lntup '( sport = :514 )'
```

테스트 송신을 멈추고 진행합니다. 메모리 큐는 재시작·장애 시 미전송 로그가 유실될 수 있습니다.
아래 블록은 필수 설정 검증 후 설치합니다. 오류가 나면 다음 단계로 진행하지 마십시오.
기본 Rocky 구성과 기존 PLURA 패키지처럼 rsyslog 및 Go가 root로 실행되는 환경 기준입니다.

```bash
(
set -e
if grep -vE '^[[:space:]]*#' 30-plura-gateway.conf | grep -q '<HAPROXY_SOURCE_IP>'; then
    echo '먼저 config의 <HAPROXY_SOURCE_IP>를 실제 IP로 바꾸십시오.' >&2
    exit 1
fi

/usr/libexec/rsyslog/plura-syslog-sender -config /etc/plura-syslog/sender.json -check-config
/usr/libexec/rsyslog/plura-syslog-sender -health -config /etc/plura-syslog/health.json -check-config

# 백업은 rsyslog include 경로 밖에 보관
BACKUP="/root/plura-rsyslog-backup-$(date +%Y%m%d-%H%M%S)"
install -d -m 0700 "$BACKUP"
cp -a /etc/rsyslog.conf "$BACKUP/rsyslog.conf"
if [ -f /etc/rsyslog.d/30-plura-gateway.conf ]; then
    cp -a /etc/rsyslog.d/30-plura-gateway.conf "$BACKUP/30-plura-gateway.conf"
fi
printf 'Backup: %s\n' "$BACKUP"

install -d -m 0755 /etc/rsyslog.d
install -d -m 0750 /var/log/plura
install -m 0644 30-plura-gateway.conf /etc/rsyslog.d/30-plura-gateway.conf
restorecon -Rv /etc/rsyslog.d/30-plura-gateway.conf /var/log/plura

# 검증 실패 시 방금 설치한 설정 대신 이전 PLURA 설정을 복구
if ! rsyslogd -N1; then
    if [ -f "$BACKUP/30-plura-gateway.conf" ]; then
        cp -a "$BACKUP/30-plura-gateway.conf" /etc/rsyslog.d/30-plura-gateway.conf
    else
        rm -f /etc/rsyslog.d/30-plura-gateway.conf
    fi
    echo "설정 검증 실패: 재시작하지 않았습니다. 백업: $BACKUP" >&2
    exit 1
fi
)
```

**위 검사가 성공한 경우에만** 서비스를 시작·재시작합니다.

```bash
(
set -e
systemctl daemon-reload
systemctl enable rsyslog plura-syslog-health
systemctl restart rsyslog
systemctl restart plura-syslog-health
systemctl status rsyslog plura-syslog-health --no-pager -l
)
```

설정 변경은 전체 설정을 반영하도록 `restart`합니다. 단순 `reload`/SIGHUP으로 같은 동작을 가정하지 마십시오.

**네트워크 허용:** HAProxy 송신 IP에서 이 Gateway의 **TCP/514·TCP/18081**로 접근하도록 기존 방화벽·보안 그룹에 허용합니다.
Gateway 자신의 상태 시험 연결도 허용되어야 합니다. UDP/514를 외부에 열 필요는 없습니다.
Gateway에서 고객으로 나가는 트래픽은 고객이 선택한 TCP/UDP·포트에 따라 허용합니다.
전체 IP에 포트를 공개하거나 SELinux를 끄지 마십시오. SELinux 거부는 `journalctl -u rsyslog`와 `ausearch -m AVC -ts recent`로 확인합니다.

## 5. 정상 동작 확인

Gateway 1 기준입니다. Gateway 2에서는 주소를 해당 Gateway 내부 IP로 변경합니다.

```bash
ss -lntp '( sport = :514 or sport = :18081 )'
curl --noproxy '*' --interface 192.168.200.200 --max-time 4 -i \
  http://192.168.200.200:18081/ready
journalctl -u rsyslog -n 50 --no-pager
journalctl -u plura-syslog-health -n 50 --no-pager
tail -n 20 /var/log/plura/sender.log
```

TCP/514는 rsyslog가, TCP/18081은 상태 점검 서비스가 수신해야 합니다.
`/ready`는 첫 상태 시험 완료 후 **HTTP 200 + `"ready":true`**가 되어야 합니다.
이는 Gateway 내부 처리 경로 확인이며 고객 서버 저장 성공 확인은 아닙니다.
이후 MSA는 Gateway가 아니라 **HAProxy IP의 TCP/514**로 전송합니다.

최소 진단 로그는 아래 세 파일입니다. 고객 로그 원문은 진단 파일에 기록하지 않습니다.

```text
/var/log/plura/sender.log              Go Sender 동작·오류
/var/log/plura/rejected.log            허용되지 않은 입력의 메타데이터
/var/log/plura/rsyslog-stats.jsonl     큐·처리 통계
```

`rejected.log`는 첫 거부 이벤트 후 만들어질 수 있습니다. 기존 `/etc/logrotate.d/plura-syslog` 로그 순환 설정은 유지하십시오.
해당 설정이 없다면 기존 v0.4.1-ha 패키지의 로그 순환 설정을 적용해야 합니다.
두 Gateway 모두 같은 설정 역할을 사용하며 주 서버·대기 서버 구분은 없습니다. 각 서버의 메모리 큐는 서로 복제되지 않습니다.

**검증 범위:** 기존 Active-Active 패키지의 기능 설정은 유지하고, IP 직접 편집 방식으로 정리했습니다.
설치 명령의 Bash 문법과 원본 설정 대비 변경 사항을 검사했습니다. 실제 Rocky Linux 설치·`rsyslogd -N1`·HAProxy 연동은 대상 서버에서 확인해야 합니다.

공식 자료: [Rocky rsyslog 설치](https://docs.rockylinux.org/10/books/admin_guide/17-log/) · [TCP 수신](https://docs.rsyslog.com/doc/configuration/modules/imtcp.html) · [omprog](https://docs.rsyslog.com/doc/configuration/modules/omprog.html)
