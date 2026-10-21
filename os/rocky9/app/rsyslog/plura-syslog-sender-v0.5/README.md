# PLURA-XDR Go Sender v0.5.0 — 설치 및 사용

**기존 HAProxy / rsyslog `2files.zip` 구성에 연결하는 Go Sender 전체 소스입니다.**
두 Gateway 모두 같은 프로그램으로 운영하는 Active-Active 구성입니다.

```text
MSA ── TCP/514 ── HAProxy ── 정상 Gateway 중 한 곳
                            ├─ rsyslog → 메모리 큐 → Go Sender v0.5
                            └─ rsyslog → 메모리 큐 → Go Sender v0.5
                                                    ↓ TCP/UDP
                                             고객 Syslog 서버
```

고객별 `.conf`, `routes.json`, 고객 목적지 조회 API는 사용하지 않습니다.
고객 목적지는 MSA가 RFC5424 Structured Data에 넣습니다. 공통 보안 허용 정책은 유지합니다.

## 1. 설치 파일과 실행 경로

| 파일 | 역할 |
|---|---|
| `*.go`, `go.mod` | Go Sender 및 상태 점검 프로그램의 전체 소스·단위 테스트 |
| `conf/sender.json` | 송신자·목적지 허용 정책, 타임아웃, 출력 설정 |
| `conf/health.json` | 이 Gateway의 IP와 HAProxy `/ready` 검사 설정 |
| `conf/plura-syslog-health.service` | 상태 점검용 systemd 서비스 |
| `scripts/build.sh` | 테스트·정적 검사·빌드 |
| `scripts/install-sender-v05.sh` | 설치·백업, 기존 설정 보존 |
| `scripts/syslog-test.sh` | 추가 패키지 없는 Bash 송신 테스트 |
| `docs/MSA_HANDOFF.md` | MSA 메시지 규격과 CEF 생성 책임 |
| `docs/TEST_REPORT.md` | 실행한 시험과 미검증 범위 |

설치 결과:

```text
/usr/libexec/rsyslog/plura-syslog-sender
/etc/plura-syslog/sender.json
/etc/plura-syslog/health.json
/etc/systemd/system/plura-syslog-health.service
```

Go Sender는 **rsyslog가 실행하는 자식 프로세스**입니다. `plura-syslog-sender.service`는 없습니다.
`plura-syslog-health`만 별도 서비스이며 같은 바이너리를 `-health` 옵션으로 실행합니다.
이 서비스는 상태 검사 전용이고 고객 로그 수신 서버가 아닙니다.

## 2. 다운로드한 소스 빌드

현재 확인된 사용자 서버의 Go 1.26.7을 사용하십시오. 이미 설치되어 있으면 다시 설치하지 않습니다.
Go가 없는 다른 Gateway / 빌드 서버에만 다음을 실행합니다.

```bash
dnf install -y golang
# Python은 선택적 smoke 테스트용입니다. Go Sender 실행에는 필요하지 않습니다.
dnf install -y python3

go version
```

소스의 언어 기준은 Go 1.22 이상입니다. 배포용 빌드에는 조직에서 승인한 최신 보안 패치 컴파일러를 사용하십시오.
이 ZIP은 **전체 소스 배포본**이며 사전 빌드 실행파일은 포함하지 않습니다. 서버의 Go로 빌드합니다.
외부 Go 모듈을 사용하지 않아, 설치된 Go가 있으면 빌드 중 인터넷 다운로드가 필요 없습니다.

```bash
cd /home/sysadmin
unzip PLURA_XDR_Go_Sender_v0.5.zip
cd plura-syslog-sender-v0.5

bash scripts/build.sh
python3 scripts/smoke_test.py
```

정상 출력:

```text
0.5.0
Built: /home/sysadmin/plura-syslog-sender-v0.5/bin/plura-syslog-sender
```

실행파일만 다른 Linux amd64 Gateway에 복사해 사용할 수도 있습니다. 해당 서버의 Go 컴파일러는 실행에 필요하지 않습니다.
플랫폼이 다른 경우 그 플랫폼에서 다시 빌드하십시오.

## 3. 설치 — 둘 중 해당하는 한 가지

### A. HA용 v0.4.1 설정이 이미 정상 설치된 경우

```bash
bash scripts/install-sender-v05.sh
```

기존 `/etc/plura-syslog/sender.json`과 `health.json`을 검증한 뒤 **그대로 보존**합니다.
기존 HAProxy·rsyslog 설정을 덮어쓰지 않습니다. 기존 실행파일과 unit은 백업 후 교체합니다.
추가된 `legacyTimezone`, `legacyMaxMessageBytes`가 기존 JSON에 없으면 각각 `Asia/Seoul`, `1024`를 적용합니다.

**기존 직접 수신용 v0.4에 `health.json`이 없다면 A가 아니라 B를 사용합니다.**

### B. 최초 설치 / 직접 수신 v0.4에서 HA 구조로 전환

두 파일의 IP를 편집합니다.

```bash
vi conf/sender.json
vi conf/health.json
```

| 값 | 편집 내용 |
|---|---|
| `<HAPROXY_SOURCE_IP>` | HAProxy가 Gateway로 접속할 때 사용하는 실제 송신 IP. MSA IP가 아닙니다. |
| `192.168.200.200` | Gateway 1은 유지. Gateway 2에서는 해당 Gateway 내부 IP로 모두 변경 |
| `172.16.18.200/32` | Gateway 1의 다른 NIC를 목적지에서 제외하는 값. Gateway 2에서는 자신의 주소로 변경 |
| `nodeId: gw1` | Gateway 2는 `gw2` |
| `172.16.12.212/32` | 허용할 고객 Syslog 서버. 고객 추가 시 허용 정책을 검토하여 확장 |

두 Gateway의 주소·HAProxy 주소·관리망 등으로 재전송 루프가 생기지 않도록 `denyCidrs`를 유지합니다.
목적지 허용 정책은 고객별 라우팅 DB와 다릅니다. 넓은 사설망 전체 허용으로 우회하지 않습니다.

수정한 JSON을 **명시적으로 적용**합니다. 기존 값은 타임스탬프 백업 후 교체됩니다.

```bash
bash scripts/install-sender-v05.sh --replace-config
```

편집하지 않은 `<HAPROXY_SOURCE_IP>`가 남으면 설치는 실패하며 기존 실행파일을 교체하지 않습니다.
설치 스크립트는 서비스 시작/재시작, 방화벽 변경, SELinux 해제를 하지 않습니다.

## 4. 기동 / 업데이트 적용

앞서 제공한 rsyslog `30-plura-gateway.conf`와 HAProxy 설정이 설치되어 있어야 합니다.
이번 Go 패키지에 같은 데몬 설정을 다시 포함하지 않았습니다.

```bash
/usr/libexec/rsyslog/plura-syslog-sender -version
/usr/libexec/rsyslog/plura-syslog-sender \
  -config /etc/plura-syslog/sender.json \
  -check-pair /etc/plura-syslog/health.json

rsyslogd -N1
```

오류가 없을 때 **Gateway 한 대씩** 적용합니다. 아직 서비스 중이 아닌 첫 설치에서는 아래 명령을 사용합니다.

```bash
systemctl daemon-reload
systemctl restart rsyslog
systemctl enable plura-syslog-health
systemctl restart plura-syslog-health

systemctl status rsyslog plura-syslog-health --no-pager
ss -lntp '( sport = :514 or sport = :18081 )'
```

이미 로그를 처리 중인 서버라면 먼저 다른 Gateway가 정상인지 확인합니다.
`/run/plura-syslog/drain` 파일을 만들면 해당 서버의 `/ready`가 503으로 바뀝니다.
HAProxy에서 DOWN 판정과 새 유입 중단을 확인하고, rsyslog 큐가 비워진 뒤 위 재시작을 수행합니다.
복구 준비가 끝나면 drain 파일을 제거합니다.

```bash
# 업데이트 전: 해당 Gateway의 신규 유입을 중단
mkdir -p /run/plura-syslog
touch /run/plura-syslog/drain
# HAProxy DOWN 및 로컬 큐 비움 확인 → 위 재시작 명령 수행
# 처리 복구 후:
rm -f /run/plura-syslog/drain
```

이것은 무손실 보장 절차가 아닙니다. 메모리 큐가 남은 상태에서 rsyslog를 재시작하면 유실될 수 있습니다.
HAProxy는 이미 열린 연결을 다른 서버로 옮기지 않으므로 MSA의 재연결 처리가 필요합니다.

Gateway 1에서 확인:

```bash
curl --noproxy '*' -i http://192.168.200.200:18081/ready
tail -F /var/log/plura/sender.log
journalctl -u plura-syslog-health -n 50 --no-pager
```

`curl`은 점검 도구일 뿐 실행 의존성은 아닙니다. `/ready`는 실제 `rsyslog → 동일 큐 → Go Sender`를 통과한 시험 메시지의 응답으로 판단합니다.
고객 서버의 최종 수신/저장까지 확인하는 것은 아닙니다. `/live`는 상태 점검 프로세스 생존만 확인합니다.
TCP/18081 접근은 HAProxy 송신 IP 및 설정된 점검 주소로 제한합니다.

### SELinux 및 실행 사용자

기존 Rocky Linux root 실행 rsyslog를 기준으로 합니다. root로 실행하는 health 서비스와 Go Sender가
`/run/plura-syslog/health.sock`을 공유합니다. rsyslog를 다른 사용자로 낮춰 실행한다면 소켓·디렉터리 권한을 함께 설계해야 합니다.

```bash
getenforce
ausearch -m AVC,USER_AVC -ts recent
journalctl -u rsyslog -u plura-syslog-health -n 100 --no-pager
```

SELinux는 Enforcing을 유지합니다. 설치 스크립트의 `restorecon`은 레이블 복구만 하며
사용자 정의 Go 실행·소켓 접근·외부 연결 권한을 모두 추가하지는 않습니다.
거부가 있으면 실제 AVC를 바탕으로 운영 담당자가 필요한 최소 정책을 적용해야 합니다.

## 5. MSA / Bash 송신 테스트

**192.168.1.15에서 실행**합니다. 수신 대상은 Gateway IP가 아니라 **HAProxy 수신 IP**입니다.

```bash
read -r -p 'HAProxy 수신 IP: ' LB_IP

# 기존 RFC5424 → 고객 UDP/514
bash scripts/syslog-test.sh \
  tcp 'PLURA v0.5 TEST' "$LB_IP" 172.16.12.212 514 udp

# RFC3164 헤더로 출력
bash scripts/syslog-test.sh \
  tcp 'PLURA legacy TEST' "$LB_IP" 172.16.12.212 514 udp rfc3164

# CEF 본문 + RFC3164 헤더로 출력
bash scripts/syslog-test.sh \
  tcp 'CEF:0|QubitSecurity|PLURA-XDR|0.5|TEST|Relay test|5|src=203.0.113.10 act=detected' \
  "$LB_IP" 172.16.12.212 514 udp cef rfc3164

# CEF 본문 + RFC5424 헤더로 출력
bash scripts/syslog-test.sh \
  tcp 'CEF:0|QubitSecurity|PLURA-XDR|0.5|TEST|Relay test|5|src=203.0.113.10 act=detected' \
  "$LB_IP" 172.16.12.212 514 tcp cef rfc5424
```

첫 `tcp`는 내부 전송입니다. 뒤의 `udp`/`tcp`는 고객이 선택한 전송 방식입니다.
TCP 고객 전송은 기본 Octet-counting이며 LF 수신기라면 `FRAMING=lf bash ...`를 사용합니다.
Bash 테스트는 한 번 전송하는 진단 도구로 큐·재연결·송신 결과 확인을 구현한 MSA 운영 클라이언트가 아닙니다.
Bash `/dev/tcp` 연결 타임아웃은 OS 설정의 영향을 받습니다.

## 6. v0.5에서 추가된 출력 선택

내부 메시지 형식과 APP-NAME은 그대로 유지합니다.

```text
<134>1 2026-10-22T09:00:00+09:00 msa plura-relay - - [pluraRelay@32473 dst="172.16.12.212" port="514" proto="udp" framing="none" format="cef" header="rfc3164"] CEF:0|QubitSecurity|PLURA-XDR|0.5|TEST|Relay test|5|src=203.0.113.10
```

| 메타데이터 | 고객에게 전송할 결과 |
|---|---|
| `format` 없음 | 기존 v0.4와 같은 RFC5424 출력 |
| `format="rfc5424"` | RFC5424 헤더·본문. 라우팅 SD만 제거 |
| `format="rfc3164"` | RFC3164 헤더 + `plura: ` + 본문 |
| `format="cef"` | CEF 본문 + RFC3164 헤더 (기본) |
| `format="cef" header="rfc5424"` | CEF 본문 + RFC5424 헤더 |

**CEF 본문은 MSA가 생성**합니다. Go는 일반 텍스트를 임의의 CEF 필드로 변환하지 않습니다.
CEF 헤더의 구조·기본 이스케이프를 검사하지만 모든 CEF 확장 필드의 자료형/사전을 검증하거나 특정 SIEM 인증을 대체하지 않습니다.
CEF 본문의 `dst`는 공격 대상 IP이며, 라우팅 SD의 `dst`인 고객 Syslog 서버 IP와 별개입니다.

RFC3164 변환 시 기본 시간대는 `Asia/Seoul`입니다. 이벤트의 RFC5424 시각을 이 시간대로 변환합니다.
RFC3164는 연도·시간대·STRUCTURED-DATA를 표현하지 않으므로 해당 정보와 PROCID/MSGID는 출력에서 제외됩니다.
필요한 이벤트 정보는 MSA가 본문/CEF 확장 필드에 포함해야 합니다. 시각이나 호스트가 `-`이면 임의로 채우지 않고 거부합니다.
CEF+RFC3164는 `plura:` 접두어 없이 헤더 뒤에 `CEF:0|...` 또는 `CEF:1|...`이 바로 이어집니다.

기본 RFC3164 계열 출력 한도는 **1024바이트**입니다. 초과 시 자르지 않고 사유를 기록해 폐기합니다.
수신기가 더 긴 legacy 메시지를 명시적으로 지원할 때만 `legacyMaxMessageBytes`를 올릴 수 있으며,
이는 엄격한 RFC3164 한도를 벗어난 수신기별 확장입니다. 긴 CEF는 RFC5424 헤더를 우선 검토합니다.
RFC5424 내부 전체 메시지 한도는 기존대로 8192바이트이며 라우팅 SD 크기도 포함합니다.

**TLS / RFC5425는 이번 버전에 포함하지 않았습니다.** `proto="tls"`, `format="rfc5425"`는 거부합니다.
UI에서 RFC5425를 일반 TCP로 잘못 보내지 않도록 미지원 처리해야 합니다.

## 7. 로그·재시도와 제한

기본 `debug:false`에서는 기동, 오류, 폐기, 누적 통계를 기록합니다.
`debug:true`로 변경하고 Sender를 재시작하면 개별 `socket_write_ok`를 확인할 수 있습니다.
원문과 CEF 본문은 진단 로그에 기록하지 않습니다. eventHash는 추적 보조 값이며 원문 저장소가 아닙니다.

| 처리 결과 | omprog 응답 / 동작 |
|---|---|
| 로컬 소켓 쓰기 성공 | `OK`; 고객 저장 확인과는 다름 |
| 연결/쓰기 일시 오류 | `ERR`; rsyslog action queue가 재시도 |
| 잘못된 형식·금지 목적지·크기 초과 | 사유 기록 후 `OK`; 잘못된 로그가 큐 전체를 영구 차단하지 않도록 폐기 |

UDP 대형 메시지는 IP 단편화로 유실될 수 있으므로 긴 메시지는 TCP 수신기와 시험하십시오.
UDP 수신 확인, TCP의 최종 SIEM 저장 확인, exactly-once, 서버 간 큐 복제는 제공하지 않습니다.
부분 TCP 쓰기 후 재시도는 중복을 만들 수 있습니다. 영속 큐 서버와 디스크 스풀도 추가하지 않았습니다.
현재 단일 omprog 큐에서는 특정 고객의 TCP 장애가 다른 고객 및 health probe까지 지연시킬 수 있습니다.
그 결과 정상 OS/rsyslog의 Gateway도 `/ready`가 503이 되어 제외될 수 있습니다.
고객 장애 격리와 대량 부하 성능은 별도 운영 전 검증 대상입니다.

HAProxy는 TCP **연결 단위**로 분산합니다. 두 Gateway에 같은 로그를 복제하지 않습니다.
MSA의 재사용 연결이 하나이면 한 Gateway만 처리할 수 있습니다. 다중 연결·재연결을 MSA에 구현합니다.
두 Gateway의 외부 공인 IP를 통일하려면 기존 네트워크에서 공통 SNAT가 필요합니다.

## 8. 복구

백업 위치: `/var/backups/plura-syslog/<설치시각-PID>/`
기존 파일이 있었던 항목만 저장합니다. rsyslog / HAProxy conf는 변경하지 않았으므로 백업 대상이 아닙니다.

적용 중 문제가 있으면 해당 노드의 신규 유입을 중지하고, 선택한 백업 실행파일·설정·unit을 복구한 후 설정 검사와 서비스 재시작을 수행합니다.
실행 중인 바이너리에 직접 `cp`하지 말고 임시 이름으로 설치 후 `mv`하십시오.
이전 버전 Sender는 신규 `format` / `header` 메타데이터를 지원하지 않으므로 **MSA 신규 출력 기능도 함께 되돌려야 합니다.**
새로운 옵션은 두 Gateway 모두 v0.5 설치·검증을 끝낸 다음 MSA에서 활성화합니다.

## 9. 시험 결과 및 근거

`docs/TEST_REPORT.md`의 실제 실행 기록을 확인하십시오.
Go 코드·로컬 소켓 시험과 실제 Rocky Linux / HAProxy / rsyslog 통합 검증은 별개입니다.
규격 참고 문서는 `docs/SOURCES.md`에 있습니다.
