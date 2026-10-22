# PLURA-XDR Syslog Gateway v0.6.0 — 구축 및 RFC5425/TLS 시험 최종 정리

> **문서 기준:** 2026-10-23 · Rocky Linux 9 · Go Sender v0.6.0  
> **문서 목적:** 현재 확인된 구축 결과와 재현 가능한 설치·시험 절차를 한 문서에 보존한다. **코드가 제공하는 기능**과 **실제 운영 서버에서 검증한 기능**은 구분한다.  
> **판정:** Gateway 1을 통한 기존 Syslog 전송 및 **사설 CA + IP 인증서 기반 TLS 실제 수신 검증 완료**. 4종 TLS 인증서 전체, Gateway 2 및 장애·부하 검증은 아직 완료하지 않았다.

## 1. 아키텍처와 서버 역할

```text
MSA / 시험 송신기                  192.168.1.15
    │ 내부 RFC5424 + 라우팅 Structured Data
    │ TCP/514, octet-counting
    ▼
HAProxy Active-Active LB          192.168.10.25:514
    │ 정상 Gateway로 TCP 연결 단위 분산
    ├────────── Gateway 1         192.168.200.200:514  [실제 검증]
    │            rsyslog → 메모리 큐 → omprog → Go Sender v0.6.0
    │                                              │
    └────────── Gateway 2         [IP·실제 시험 미확정]
                 rsyslog → 메모리 큐 → omprog → Go Sender v0.6.0
                                                   │
                        고객 설정에 따라 UDP/TCP/TLS 송신
                                                   ▼
고객 Syslog 시험 수신 서버        172.16.12.212:514(UDP/TCP), :6514(TLS)
```

| 구성 요소 | 주소·경로 | 담당 기능 |
|---|---|---|
| MSA | `192.168.1.15` | 고객 목적지/출력 포맷을 RFC5424 Structured Data에 포함하여 HAProxy로 송신 |
| HAProxy | `192.168.10.25:514/TCP` | 가용 Gateway에 **연결 단위**로 분산, `/ready` 헬스체크 |
| Gateway 1 수신 | `192.168.200.200:514/TCP` | `rsyslog` 입력, 메모리 큐, `omprog` |
| Gateway 1 상태 | `192.168.200.200:18081/TCP` | Go Health `/ready`, `/live` |
| Gateway 1 외부망 NIC | `172.16.18.200` | 고객 로그 파일명으로 관찰된 송신 주소; 정확한 패킷 출발지 IP는 캡처로 재확인 |
| 고객 테스트 서버 | `172.16.12.212` | UDP/514·TCP/514 및 TLS/6514 수신·로그 보관 |
| Gateway 2 | 미확정 | Gateway 1과 동등한 **Active**, 대기 서버 아님. 현재 설치·분산 결과 미제출 |

**중요:** 내부 MSA → HAProxy → rsyslog 구간은 이번 설계에서 **암호화되지 않은 TCP/514**이다. **Go Sender → 고객 TLS 수신기** 구간만 TLS로 암호화한다. HAProxy/rsyslog에 TLS/6514 수신 포트를 추가할 필요는 없다.

## 2. 현재까지 실제 검증 결과

### 2.1 실제 고객 수신 로그로 확인한 항목

| 번호 | 전송 포맷 | Go Sender → 고객 | 실제 고객 로그 | 판정 |
|---|---|---|---|---|
| 1 | RFC5424 | UDP/514 | `PLURA Go Sender v0.6 TEST 001` | **PASS** |
| 2 | RFC5424 | TCP/514 | `PLURA RFC5424 TCP TEST 001` | **PASS** |
| 3-1 | RFC3164 | TCP/514 | `PLURA RFC3164 TCP TEST 001` | **PASS — 수신** |
| 3-2 | RFC3164 | UDP/514 | `PLURA RFC3164 UDP TEST 001` | **PASS — 수신** |
| 4 | CEF + RFC5424 | TCP/514 | `CEF:0\|QubitSecurity\|PLURA-XDR...` | **PASS — 본문 수신** |
| 5-1 | CEF + RFC3164 | TCP/514 | `CEF RFC3164 TCP TEST 001` | **PASS — 수신, TAG 파싱 주의** |
| 5-2 | CEF + RFC3164 | UDP/514 | `CEF RFC3164 UDP TEST 001` | **PASS — 수신, TAG 파싱 주의** |
| **6-D** | **RFC5425, 사설 CA + IP SAN** | **TLS/6514** | **`PLURA TLS PRIVATE-CA IP TEST 001`** | **PASS — 실제 TLS 수신·저장** |

**6-D 실제 고객 로그 증거** (`/var/log/plura/tls-6514.log`):

```text
2026-10-22T23:35:54Z www\.plura.io plura-relay PLURA TLS PRIVATE-CA IP TEST 001
```

`2026-10-22T23:35:54Z`는 UTC로 기록된 시각이다(한국 시각 2026-10-23 08:35:54). MSA의 `Written to ...`만으로 PASS 처리한 것이 아니라 **고객 서버의 실제 로그 파일에서 동일 메시지를 확인**했다.

**CEF+RFC3164 파싱 주의:** 고객 rsyslog는 `CEF:`를 `syslogtag="CEF:"`·`programname="CEF"`로 추출하여 `msg`에는 `0|...`을 남겼다. **전송 자체는 성공**했지만, SIEM이 `msg`만 CEF 파서에 전달한다면 `syslogtag + msg` 복원 또는 수신 설정 조정이 필요하다. 고객 SIEM의 CEF 필드별 파서 호환성은 아직 검증하지 않았다.

### 2.2 아직 완료되지 않은 시험

| 항목 | 현재 상태 | 완료 조건 |
|---|---|---|
| **6-C 사설 CA + DNS SAN** | **미실행** | `tlsServerName` 지정 후 고객 TLS 수신 로그 확인 |
| **6-A 공인 CA + DNS SAN** | **미실행** | 실소유 DNS 인증서·공인 체인 준비 후 인증 및 수신 확인 |
| **6-B 공인 CA + IP SAN** | **미실행** | 공인 IP에 유효한 IP SAN 인증서와 수신기 준비 후 확인 |
| TLS 실패 차단 | 현장 미검증 | 잘못된 이름/미신뢰 CA에 대해 전송 실패, 평문 자동 전환 없음 증명 |
| TLS 실제 패킷 보안 확인 | 별도 기록 없음 | tcpdump에서 TLS 흐름 확인, 평문 메시지 노출 없음 확인 |
| Gateway 2 Active-Active | 미검증 | 두 Gateway UP, 신규 TCP 연결 양쪽 분산 |
| 장애 제외·복구, 대량 부하 | 미검증 | 장애 시 라우팅, 큐 처리, 속도, 유실·중복 영향 측정 |

Go v0.6.0 소스의 **로컬 TLS 1.2/1.3, 인증서 실패, 소켓 전송 단위·통합 시험 PASS**는 이미 제공된 코드 테스트 보고서에 기록되어 있으나, **위 현장 미검증 항목을 대신하지 않는다.**

## 3. 네 가지 TLS 인증서 지원 정책

| ID | 고객 수신기 서버 인증서 | Go Sender 접속 및 검증 | Gateway에 고객 CA 파일 등록 | 실제 현장 검증 |
|---|---|---|---|---|
| **A** | 공인 CA + DNS SAN | `dst=고객 IP`, `tlsServerName=인증서 DNS 이름` | 보통 불필요 (`useSystemRoots=true`) | 미실행 |
| **B** | 공인 CA + IP SAN | `dst=인증서 대상 공인 IP`, `tlsServerName` 생략 | 보통 불필요 | 미실행 |
| **C** | 사설 CA + DNS SAN | `dst=172.16.12.212`, `tlsServerName=syslog-test.example.com` | **필요** | 미실행 (인증서 자체 검증 PASS) |
| **D** | 사설 CA + IP SAN | `dst=172.16.12.212`, `tlsServerName` 생략 | **필요** | **현장 TLS 수신 PASS** |

- 공인 CA란 HTTPS에 쓰는 것과 같은 **신뢰되는 X.509/TLS 서버 인증서 발급 체계**를 말한다. `www.plura.io`의 인증서가 별도 `syslog.plura.io`에도 적용되는 것은 아니며 **SAN에 그 이름이 있어야 한다**.
- 현재 `172.16.12.212`는 사설 IP이므로 **B 공인 CA + 공인 IP SAN의 발급·수신을 입증할 수 없다**. 별도 공인 IP 환경이 필요하다.
- TLS DNS 검증 시 **접속은 계속 `dst`의 IP**로 하며, `tlsServerName`은 SNI/인증서 검증 이름이다. Go Sender는 이 값만으로 DNS 조회 후 목적지를 바꾸지 않는다.
- Go Sender는 TLS 1.2 이상을 사용하며, **인증서 검증 건너뛰기·TLS 실패 시 평문 TCP 자동 전환을 제공하지 않는다**. 클라이언트 인증서 기반 mTLS는 v0.6.0 범위 밖이다.

## 4. 고객 서버(`172.16.12.212`) — TLS 수신기 준비 및 실제 오류 해결

### 4.1 패키지 및 디렉터리

고객 서버는 최초 `rsyslog 8.2310.0`이었고, `rsyslog-gnutls` 미설치로 TLS/6514가 열리지 않았다. 이후 아래 패키지가 동일 버전으로 설치된 것을 확인했다.

```text
rsyslog-8.2510.0-2.el9_8.2.x86_64
rsyslog-gnutls-8.2510.0-2.el9_8.2.x86_64
/usr/lib64/rsyslog/lmnsd_gtls.so
```

신규 수신 서버에서만 설치한다. **이미 설치·실행된 현재 고객 서버에서 인증서와 CA를 다시 생성할 필요는 없다.**

```bash
# 고객 서버 172.16.12.212 (root)
dnf install -y rsyslog-gnutls openssl
mkdir -p /root/plura-test-ca /etc/rsyslog.d/tls /var/log/plura
chmod 700 /etc/rsyslog.d/tls
cd /root/plura-test-ca
umask 077
```

**현장에서 발생한 오류:** `/etc/rsyslog.d/tls/` 생성 전에 `openssl req ... -keyout .../server.key`를 실행하여 `No such file or directory`가 발생했다. 디렉터리 생성 후 재실행하여 해결했다.

### 4.2 시험용 사설 CA와 서버 인증서 생성(신규 수신기에서만)

현재 서버에서는 **다음 명령을 이미 성공적으로 수행**했다. 재현용 절차이다.

```bash
cd /root/plura-test-ca
umask 077

# 시험용 사설 CA: 유효기간 3650일 (운영 기본 권고 아님)
openssl req -x509 -newkey rsa:3072 -nodes -sha256 -days 3650 \
  -keyout ca.key -out ca.pem \
  -subj '/CN=PLURA-TLS-Test-CA' \
  -addext 'basicConstraints=critical,CA:TRUE' \
  -addext 'keyUsage=critical,keyCertSign,cRLSign'

openssl req -new -newkey rsa:3072 -nodes \
  -keyout /etc/rsyslog.d/tls/server.key \
  -out server.csr -subj '/CN=syslog-test.example.com'

cat > server.ext <<'EXT'
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:syslog-test.example.com,IP:172.16.12.212
EXT

openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key \
  -CAcreateserial -out /etc/rsyslog.d/tls/server.pem \
  -days 3650 -sha256 -extfile server.ext

cat /etc/rsyslog.d/tls/server.pem ca.pem \
  > /etc/rsyslog.d/tls/server-fullchain.pem
install -m 0644 ca.pem /etc/rsyslog.d/tls/ca.pem
chmod 600 /etc/rsyslog.d/tls/server.key
chmod 644 /etc/rsyslog.d/tls/*.pem
```

**실제 검증 완료:**

```bash
openssl verify -CAfile ca.pem -verify_ip 172.16.12.212 \
  /etc/rsyslog.d/tls/server.pem
openssl verify -CAfile ca.pem -verify_hostname syslog-test.example.com \
  /etc/rsyslog.d/tls/server.pem
```

두 명령 모두 `/etc/rsyslog.d/tls/server.pem: OK`를 반환했다. 이 결과는 인증서 파일의 CA 체인과 SAN을 검증한 것이며, DNS 이름으로 **실제 TLS 전송이 완료되었다는 의미는 아니다**.

파일 구분:

```text
고객 서버 /root/plura-test-ca/ca.key           : 사설 CA 개인키 (복사 금지)
고객 서버 /etc/rsyslog.d/tls/server.key      : 서버 개인키 (복사 금지)
고객 서버 /etc/rsyslog.d/tls/server.pem      : 서버 인증서
고객 서버 /etc/rsyslog.d/tls/server-fullchain.pem : 서버 인증서와 체인
고객 서버 /etc/rsyslog.d/tls/ca.pem          : CA 공개 인증서 (Gateway 배포 대상)
```

### 4.3 TLS 수신 설정

기존 TCP/514·UDP/514 수신을 유지한다. `imtcp` 모듈은 기존 `/etc/rsyslog.d/50-plura-tcp.conf`에서 이미 로드되므로 이 파일에서 **중복 로드하지 않는다**.

`/etc/rsyslog.d/51-plura-tls.conf`:

```conf
ruleset(name="plura_tls_receiver") {
    action(
        type="omfile"
        file="/var/log/plura/tls-6514.log"
        template="RSYSLOG_FileFormat"
        fileCreateMode="0640"
    )
    stop
}

input(
    type="imtcp"
    address="172.16.12.212"
    port="6514"
    ruleset="plura_tls_receiver"
    streamDriver.name="gtls"
    streamDriver.mode="1"
    streamDriver.authMode="anon"
    streamDriver.certFile="/etc/rsyslog.d/tls/server-fullchain.pem"
    streamDriver.keyFile="/etc/rsyslog.d/tls/server.key"
)
```

`authMode="anon"`은 **수신기가 Go 클라이언트 인증서를 요구하지 않는 단방향 서버 인증 TLS 시험 방식**이다. 이는 Go Sender의 서버 인증서 검증을 무효화하지 않는다. 수신 포트는 Gateway의 승인된 송신 주소로만 방화벽에서 허용한다.

### 4.4 TLS/6514 활성화 과정에서 해결한 문제

**문제 1 — `rsyslog-gnutls` 누락:** 모듈이 없을 때 TLS 포트를 열지 못했다. `dnf install -y rsyslog-gnutls` 후 `lmnsd_gtls.so` 존재를 확인했다.

**문제 2 — `rsyslogd -N1` 종료 코드 1:** 다음 경고가 표시되었다.

```text
imfile: no files configured to be monitored - no input will be gathered
```

확인 결과 `/etc/rsyslog.d/00-imfile.conf`에 `$ModLoad imfile`이 있으나 감시할 파일 입력이 없었다. **해당 서버에서 다른 imfile 입력이 사용되지 않는 것을 확인한 뒤** 모듈 선언을 주석 처리했다.

```bash
cp -a /etc/rsyslog.d/00-imfile.conf /root/00-imfile.conf.bak
sed -i 's/^\$ModLoad imfile$/#\$ModLoad imfile/' /etc/rsyslog.d/00-imfile.conf
rsyslogd -N1
echo "EXIT_CODE=$?"
# EXIT_CODE=0이어야 적용 가능
```

고객 서버에서는 주석 처리 후 TLS 메시지 실제 수신이 확인되었다. 다만 **최종 `rsyslogd -N1` 종료 코드 0의 별도 콘솔 출력은 제출되지 않았으므로**, 운영 점검에서 다시 확인한다.

**공통 적용 명령:**

```bash
# 고객 서버에서, 점검 트래픽 중단 및 설정 검증 성공 후
rsyslogd -N1 && systemctl restart rsyslog
ss -lntp | grep ':6514'
# 오류 시
journalctl -u rsyslog -b -n 100 --no-pager -l
```

TLS 메시지가 실제 파일에 기록되었으므로 **실제 시험 시점에 TLS 수신 경로가 동작했다**는 점은 확인되었다. 다만 고객의 인증서 수신기 설정·다른 포트·firewalld 정책은 별도 점검 대상이다.

## 5. Go Sender Gateway — 사설 CA 배포 및 TLS 설정

### 5.1 어디서 실행하나?

- **고객 서버 `172.16.12.212`:** `ca.pem` 공개 인증서 생성·보관 및 복사 준비.
- **Gateway 1 `192.168.200.200`:** CA 파일을 수신하고 `/etc/plura-syslog/ca/customer-test/`에 등록; `sender.json` 수정.
- **Gateway 2:** Gateway 1과 동일한 CA 신뢰 설정 필요. IP·실제 설치 여부 미확정.
- **HAProxy `192.168.10.25`:** TLS 인증서 등록 **불필요**.

원격 복사 준비(고객 서버 `172.16.12.212`에서):

```bash
# 해당 고객 서버에는 /home/sysadmin 이 없었던 점을 반영
mkdir -p /var/tmp/plura-ca-share
chmod 755 /var/tmp/plura-ca-share
install -m 0644 /etc/rsyslog.d/tls/ca.pem \
  /var/tmp/plura-ca-share/customer-test-ca.pem
sha256sum /var/tmp/plura-ca-share/customer-test-ca.pem
```

**Gateway 1 `192.168.200.200`에서** 승인된 SSH 계정으로 파일을 가져온다. SSH가 허용되지 않으면 승인된 전송 수단을 사용한다.

```bash
# 아래 <고객_SSH계정>은 실제 계정으로 교체
scp <고객_SSH계정>@172.16.12.212:/var/tmp/plura-ca-share/customer-test-ca.pem \
  /root/customer-test-ca.pem

install -d -m 0750 /etc/plura-syslog/ca/customer-test
install -m 0644 /root/customer-test-ca.pem \
  /etc/plura-syslog/ca/customer-test/ca.pem
sha256sum /etc/plura-syslog/ca/customer-test/ca.pem
```

양측 SHA-256이 일치해야 한다. **CA 개인키 `ca.key`와 서버 개인키 `server.key`는 어떠한 경우에도 Gateway로 복사하지 않는다.** 고객 서버의 `/var/tmp/plura-ca-share/` 임시 파일은 배포 검증 후 정리한다.

### 5.2 Go Sender TLS 공통 설정

설정 파일: `/etc/plura-syslog/sender.json` (Gateway 1 기준). 기존 출발지 제한 및 목적지 CIDR은 유지한다. 적용된/검증된 설정의 핵심은 아래와 같다.

```json
{
  "allowedSourceIps": ["192.168.10.25"],
  "allowedDestinationCidrs": ["172.16.12.212/32"],
  "denyCidrs": ["192.168.200.200/32", "172.16.18.200/32", "192.168.10.25/32"],
  "allowTestLoopback": false,
  "dialTimeoutMs": 2000,
  "writeTimeoutMs": 2000,
  "maxConnections": 128,
  "connectionIdleSeconds": 30,
  "maxMessageBytes": 8192,
  "maxUdpBytes": 8192,
  "legacyTimezone": "Asia/Seoul",
  "legacyMaxMessageBytes": 1024,
  "debug": false,
  "healthProbeSourceIp": "192.168.200.200",
  "healthAckSocket": "/run/plura-syslog/health.sock",
  "tls": {
    "useSystemRoots": true,
    "caFiles": ["/etc/plura-syslog/ca/customer-test/ca.pem"],
    "minVersion": "1.2",
    "handshakeTimeoutMs": 3000,
    "connectionMaxAgeSeconds": 300
  }
}
```

- **공인 CA 인증서 고객:** OS가 신뢰하는 공인 CA 체인이면 별도 `caFiles` 등록 없이 `useSystemRoots=true` 사용 가능.
- **사설 CA 인증서 고객:** `caFiles`에 승인된 CA 공개 인증서를 지정.
- **현재 v0.6.0의 `caFiles`는 모든 고객에 대한 공통 신뢰 풀**이다. 디렉터리를 고객별로 나눠도 TLS 신뢰가 고객별로 격리되는 것은 아니다.

CA 추가·교체·삭제는 두 Active Gateway에 동등하게 적용해야 하며, **Go Sender를 실행하는 rsyslog의 재시작이 필요**하다. 설정 실패나 미전송 메모리 큐 적체가 있을 때는 재시작하지 않는다.

### 5.3 적용·인증서 검증

```bash
# Gateway 1 (root), 기존 서비스 처리량/큐 상태 확인 후 수행
cp -a /etc/plura-syslog/sender.json \
  "/root/sender.json.pre-tls.$(date +%Y%m%d-%H%M%S)"

/usr/libexec/rsyslog/plura-syslog-sender \
  -config /etc/plura-syslog/sender.json \
  -check-pair /etc/plura-syslog/health.json

rsyslogd -N1
# 위 검증 통과, 시험 트래픽 일시 중단 및 큐 확인 후
systemctl restart rsyslog

# Gateway 내부 준비 상태
curl --noproxy '*' --max-time 4 -i \
  http://192.168.200.200:18081/ready
```

실제 설정 검증에서 `"msg":"config_pair_ok","node":"gw1"`가 확인되었다. **`/ready:200`은 내부 파이프라인 준비 확인**이며 고객 인증서 검증·실제 고객 수신을 대신하지 않는다.

TLS 연결 자체의 인증서 검증을 독립적으로 확인하려면:

```bash
# D: 사설 CA + IP SAN
openssl s_client -connect 172.16.12.212:6514 \
  -verify_ip 172.16.12.212 \
  -CAfile /etc/plura-syslog/ca/customer-test/ca.pem \
  -verify_return_error -brief < /dev/null

# C: 사설 CA + DNS SAN
openssl s_client -connect 172.16.12.212:6514 \
  -servername syslog-test.example.com \
  -verify_hostname syslog-test.example.com \
  -CAfile /etc/plura-syslog/ca/customer-test/ca.pem \
  -verify_return_error -brief < /dev/null
```

**주의:** 실제 `openssl s_client` 콘솔 결과는 아직 이 대화에 제출되지 않았다. D의 실제 TLS 수신은 확인되었지만, 별도의 네트워크 인증서 검증 출력은 최종 감사 증거로 추가 확보할 필요가 있다.

## 6. MSA → HAProxy → Go Sender → 고객 시험

### 6.1 D — 사설 CA + IP SAN: **실제 성공한 명령**

MSA `192.168.1.15`에서:

```bash
unset TLS_SERVER_NAME
bash ./syslog-test.sh \
  tcp \
  "PLURA TLS PRIVATE-CA IP TEST 001" \
  192.168.10.25 \
  172.16.12.212 \
  6514 \
  tls
```

MSA 측 출력:

```text
Written to 192.168.10.25:514 TCP; requested customer 172.16.12.212:6514 tls, format=rfc5424
This is local socket-write completion, NOT customer delivery confirmation.
```

고객 서버 `172.16.12.212`에서:

```bash
grep -F "PLURA TLS PRIVATE-CA IP TEST 001" /var/log/plura/tls-6514.log
```

**실제 수신 확인:**

```text
2026-10-22T23:35:54Z www\.plura.io plura-relay PLURA TLS PRIVATE-CA IP TEST 001
```

**판정:** **E2E 전송·TLS 수신·저장 PASS**. 단, 미신뢰 CA·SAN 불일치 차단 시험과 `tcpdump` 기반 암호화 세션 확인은 미실행.

### 6.2 C — 사설 CA + DNS SAN: **다음 시험**

**현재 시험 인증서에 DNS SAN이 이미 포함되어 있어 인증서를 다시 만들 필요가 없다.** MSA에서 실행한다.

```bash
TLS_SERVER_NAME='syslog-test.example.com' \
  bash ./syslog-test.sh tcp \
    'PLURA TLS PRIVATE-CA DNS TEST 001' \
    192.168.10.25 172.16.12.212 6514 tls
```

고객 서버:

```bash
grep -F 'PLURA TLS PRIVATE-CA DNS TEST 001' \
  /var/log/plura/tls-6514.log
```

명령 출력만으로 PASS 판정하지 않고 고객 로그 저장을 확인해야 한다.

### 6.3 A — 공인 CA + DNS SAN: **미실행**

실소유 도메인의 공인 TLS 인증서가 고객 서버에 준비되어 있어야 한다. 사설 CA 시험용 `syslog-test.example.com`은 공인 CA 시험 결과로 인정하지 않는다. 공인 CA 인증서의 SAN에 해당 DNS 이름이 포함되어야 한다.

```bash
TLS_SERVER_NAME='<실제_공인_인증서_DNS>' \
  bash ./syslog-test.sh tcp \
    'PLURA TLS PUBLIC-CA DNS TEST 001' \
    192.168.10.25 172.16.12.212 6514 tls
```

고객 서버가 공인 CA와 중간 인증서 체인을 정상 제공하고, Gateway의 `useSystemRoots=true` 상태에서 검증 및 수신에 성공해야 PASS이다.

### 6.4 B — 공인 CA + 공인 IP SAN: **미실행**

현재 `172.16.12.212`는 사설 IP라 이 유형의 공인 인증서 시험에는 사용할 수 없다. 별도로 승인된 공인 IP와 해당 IP SAN을 포함한 공인 CA 서버 인증서가 필요하다.

```bash
unset TLS_SERVER_NAME
bash ./syslog-test.sh tcp \
  'PLURA TLS PUBLIC-CA IP TEST 001' \
  192.168.10.25 <실제_공인_IP> 6514 tls
```

이 시험에는 Gateway의 `allowedDestinationCidrs`에 승인 목적지를 허용하고, 네트워크 라우팅·방화벽 설정을 갖춰야 한다. 임의의 외부 공인 IP를 시험 대상으로 지정하지 않는다.

## 7. 보안·장애·부하 운영 점검

### 7.1 보안상 추가 확인할 사항

- 인증서 이름이 틀린 경우(예: 잘못된 `TLS_SERVER_NAME`) 고객 메시지가 수신되지 않고 Go Sender가 인증 실패를 보고하는지 **음성 시험** 수행.
- 미신뢰 사설 CA·만료된 서버 인증서에 대한 차단 시험 수행. TLS 실패 시 **평문 TCP fallback이 없어야 한다**.
- 패킷 캡처에서 고객 방향 TCP/6514에 TLS가 사용되고 Syslog 메시지 전문이 평문으로 노출되지 않는지 확인.
- Gateway → 고객 TCP/6514만 열고 고객 서버에서 승인된 Gateway 송신 IP만 허용. 테스트 당시 HAProxy `firewalld`가 임시 중지되었던 이력이 있으므로 **방화벽 재활성화 및 MSA TCP/514 허용 규칙도 재확인**.
- 고객의 `server.key`/`ca.key`를 외부로 복사하지 말 것. CA 복사 후 임시 전달 파일 정리.

### 7.2 HA 및 큐 제한

- 두 Gateway는 **항상 Active-Active**이며, HAProxy는 **TCP 연결 단위**로 분산한다. MSA가 TCP 연결 하나만 유지하면 Gateway 한 대에만 배정된다.
- HAProxy `/ready` 200은 **Gateway 내부 경로 준비**만 뜻한다. 고객 수신/인증서 검증·저장 완료 ACK가 아니다.
- 현재 rsyslog는 **단일 메모리 큐** 기반이며 Gateway 간 큐 복제·무손실 보장을 제공하지 않는다. 장애/재시작 시 미전송 로그 유실과 재시도에 따른 중복 가능성이 있다.
- 특정 고객의 장시간 TLS 연결 실패가 공통 큐와 Health를 지연할 수 있으므로 **고객별 장애 격리**가 향후 운영 개선 과제이다.

### 7.3 CA 운영 관리와 한계

```text
고객 수신 서버: /etc/rsyslog.d/tls/{ca.pem,server.pem,server-fullchain.pem,server.key}
PLURA Gateway: /etc/plura-syslog/ca/<고객ID>/ca.pem
```

사설 CA 고객 추가/삭제/갱신 시 두 Gateway에 동일 CA를 설치·등록하고, `sender.json`의 `tls.caFiles` 배열을 수정·검증한 뒤 **Gateway 한 대씩** Go Sender 재시작(현재 `omprog` 실행 방식에서는 rsyslog 재시작)해야 한다.

**v0.6.0에서는 `caFiles`가 고객별로 격리된 신뢰 저장소가 아니라 단일 공통 풀**이다. 디렉터리를 나눠 두는 것만으로 고객별 인증서 발급 권한이 제한되지 않으므로, 멀티테넌트 상용 운영 전 고객별 CA 신뢰 프로필 설계를 권고한다.

## 8. 다음 시험 진행 순서

1. **6-C 사설 CA + DNS SAN**: `TLS_SERVER_NAME='syslog-test.example.com'`으로 재전송 후 고객 수신 확인.
2. **TLS 인증 실패 차단**: 틀린 `TLS_SERVER_NAME`·미신뢰 CA에 대해 메시지 미도착/Go 오류/평문 fallback 없음 확인.
3. **TLS 네트워크 인증서 검증 증거**: Gateway의 `openssl s_client -verify_ip`, `-verify_hostname` 결과 및 필요 시 `tcpdump` 캡처 기록.
4. **6-A/6-B 공인 CA**: 실제 인증서·IP 환경 준비 시 별도 실행.
5. **Gateway 2 Active-Active / 장애·복구 / 대량 전송** 검증 후 운영 승인.

## 참고 문서

- RFC5425: https://www.rfc-editor.org/rfc/rfc5425.html
- rsyslog imtcp: https://docs.rsyslog.com/doc/configuration/modules/imtcp.html
- rsyslog GnuTLS: https://docs.rsyslog.com/doc/concepts/ns_gtls.html
- Go Sender v0.6.0 배포본: `PLURA_XDR_Go_Sender_v0.6.0.zip`, `docs/MSA_HANDOFF.md`, `docs/TEST_REPORT.md`

---

**최종 판정(2026-10-23):** **RFC5425 + TLS (사설 CA + IP SAN) 실제 수신 PASS.** 나머지 인증서 조합과 HA·부하/보안 음성 시험이 남아 있으므로 TLS 전체 조합 또는 상용 운영 검증 **완료**로 표기하지 않는다.
