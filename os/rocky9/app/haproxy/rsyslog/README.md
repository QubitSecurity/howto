# 01. HAProxy 설치 & 전체 설정 — Active-Active

대상: Rocky Linux 9/10. **HAProxy 3.2 이상**을 이 구성의 기준으로 합니다.
두 Gateway 모두 일반 Active 서버이고 `backup`은 없습니다. Go Sender 버전은 0.4.1-ha입니다.

## 1. 포함 파일

| 파일 | 용도 |
|---|---|
| `conf/haproxy.cfg.in` | **신규 전용 LB용 전체 설정**. global/defaults/frontend/backend 포함 |
| `conf/plura-syslog.fragment.in` | 기존 메일·웹 HAProxy에 병합할 Syslog 전용 frontend/backend |
| `conf/plura-haproxy.service.in` | 전용 LB 실행용 systemd unit |
| `deployment.example.json` | 실제 IP 입력 파일 |
| `scripts/render.py` | 실제 IP로 전체 설정·병합용 설정 생성 |
| `scripts/install-packages.sh` | 배포판 패키지 설치 및 HAProxy 버전 확인 |
| `scripts/build-source-3.2.sh` | 배포판 버전이 낮을 때 명시적으로 사용하는 소스 빌드 |
| `scripts/install-dedicated.sh` | 신규 전용 LB 설정·unit 설치. 자동 기동 없음 |
| `scripts/firewall.py` | 좁은 출발지 허용 규칙 미리보기/명시적 적용 |
| `scripts/check-health.sh` | 두 Gateway의 `/ready` 조회 |
| `scripts/syslog-test.sh` | MSA에서 실행할 Bash 테스트 송신기 |

`.in` 파일을 그대로 설치하지 마십시오. 아래 생성 단계로 실제 `haproxy.cfg`를 만듭니다.

## 2. 포트와 역할

| 경로 | 포트·프로토콜 |
|---|---|
| MSA → HAProxy | TCP/514: 표준 Syslog 바이트 스트림 |
| HAProxy → Gateway | TCP/514: 같은 Syslog 바이트 스트림 |
| HAProxy → Gateway 상태 서비스 | TCP/18081: HTTP `/ready` |
| Gateway → 고객 | TCP 또는 UDP, 고객 지정 포트 |

HTTP/514가 아닙니다. HAProxy는 고객 목적지를 해석하거나 Syslog 원문을 변환하지 않습니다.
이번 내부 경로는 TCP만 사용하며 UDP/514 frontend는 만들지 않습니다.

## 3. 설치 전 확인

```bash
cat /etc/rocky-release
command -v haproxy && haproxy -v
systemctl status haproxy --no-pager || true
ss -lntup '( sport = :514 )'
ip -4 address
```

기존 메일용 HAProxy가 있다면 **새 전용 서비스 설치가 아니라 7-B의 병합 경로**를 선택합니다.
실제 실행 중인 바이너리는 `systemctl cat haproxy`와 프로세스 경로로 확인하십시오.
기존 패키지 업그레이드는 메일 LB 운영에도 영향을 줄 수 있어 별도의 변경 작업으로 진행해야 합니다.

## 4. HAProxy 설치

### A. 저장소 패키지 우선

```bash
# 기존 중요 서비스가 있는 호스트라면 변경 계획 수립 후 실행
bash scripts/install-packages.sh
```

실제 명령은 다음과 같습니다.

```bash
dnf install -y haproxy python3 curl socat policycoreutils-python-utils audit
haproxy -v
```

배포판 제공 버전이 3.2 미만이면 스크립트는 버전 검사에서 중단합니다.
**설치가 되었다는 사실과 이번 설정이 호환된다는 사실을 구분**해야 합니다.
`init-state fully-down` 등 필요한 옵션을 삭제하여 우회하지 마십시오.
기존에 승인된 3.2 이상 RPM 저장소가 있다면 그 저장소를 사용해도 됩니다.

### B. 신규 전용 서버: 3.2 소스 설치 대안

```bash
bash scripts/build-source-3.2.sh
```

공식 배포본 **3.2.26**과 문서 작성 시 확인한 SHA256을 고정해 사용합니다.
다운로드·해시 검사·컴파일 후 아래 경로에만 설치합니다.

```text
/opt/plura/haproxy/3.2.26/sbin/haproxy
```

기존 `/usr/sbin/haproxy`, 설정 파일, 메일 서비스는 교체하지 않습니다.
이는 자동 업데이트 서비스가 아니므로 이후 보안 패치 적용은 운영 책임자가 관리해야 합니다.
다른 승인된 3.2.x를 빌드하려면 `HAPROXY_VERSION`과 공식 자료로 확인한 `EXPECTED_SHA256`을 함께 지정합니다.
SDK·RPM·소스 tarball을 포함한 오프라인 설치 번들은 아닙니다. 인터넷이 없는 서버에서는 조직의 승인된 패키지 배포 경로가 필요합니다.

## 5. 실제 IP 입력·전체 설정 생성

```bash
cp deployment.example.json deployment.json
vi deployment.json
```

필수 입력: `lbListenIp`, `lbSourceIp`, `gateways`의 `gw2.ip`.
MSA는 `192.168.1.15`, gw1은 `192.168.200.200`, 시험 고객은 `172.16.12.212/32`로 채워져 있습니다.
두 Gateway 설치에도 **이 파일과 같은 값**을 사용합니다.
HAProxy가 Gateway로 연결할 때 사용할 `lbSourceIp`는 HAProxy 호스트에 할당된 주소여야 합니다.

```bash
python3 scripts/render.py --settings deployment.json --out rendered
```

```text
rendered/haproxy.cfg                  # 전체 설정
rendered/plura-syslog.fragment.cfg    # 기존 HAProxy 병합용
rendered/deployment.json              # 사용한 실제 값 기록
```

주요 설정은 이미 파일에 포함되어 있습니다.

```haproxy
balance leastconn
# 실제 파일에는 생성된 IP가 들어갑니다.
server gw1 <Gateway1-IP>:514 check weight 1
server gw2 <Gateway2-IP>:514 check weight 1
```

`backup` 없음, 두 서버 동일 가중치입니다.
TCP/514 연결 검사와 HTTP/18081 `/ready`를 모두 수행합니다.
상태 검사는 기본 inter 2초·fall 2·rise 2이며 **정확히 4초 이내 전환을 보장하는 설정은 아닙니다**.
로컬 큐 정체, 타임아웃과 스케줄링에 따라 더 걸릴 수 있습니다.

## 6. 방화벽과 상태 확인

```bash
firewall-cmd --get-active-zones
# public은 예시입니다. HAProxy 수신 인터페이스의 실제 zone으로 변경합니다.
python3 scripts/firewall.py --settings deployment.json --zone public --node haproxy
# 출력된 명령과 기존 정책을 검토한 후에만 실행
python3 scripts/firewall.py --settings deployment.json --zone public --node haproxy --apply
```

MSA IP만 TCP/514 접근을 허용합니다. 이 스크립트는 허용 규칙을 추가할 뿐 기존의 광범위 허용을 제거하지 않습니다.
기존 `514/tcp` 전체 허용, trusted zone, 보안 그룹도 별도로 확인합니다. 현재 방화벽이 firewalld가 아니라면 해당 정책 도구로 동일하게 반영합니다.
HAProxy의 Gateway 방향 TCP/514·18081 출력도 허용해야 합니다. 사내 SNAT가 끼면 수신자가 보는 IP가 달라질 수 있으므로 `source` 설정과 ACL을 함께 확인합니다.

```bash
# Gateway 설치·기동·방화벽 설정이 끝난 뒤 실행
bash scripts/check-health.sh deployment.json
```

두 노드 모두 HTTP 200과 `"ready":true`가 나와야 합니다.
이 검사는 Go Sender까지의 내부 경로 상태이며 고객 서버의 실제 수신 확인은 아닙니다.
SELinux Enforcing 관련 점검은 `docs/SELINUX.md`를 참고하십시오.

## 7-A. 신규 전용 HAProxy 서버에 적용

실제 사용할 바이너리를 선택합니다.

```bash
# RPM을 사용할 경우
HAPROXY_BIN=/usr/sbin/haproxy
# 소스 설치를 사용할 경우 위 대신 아래 값 사용
# HAPROXY_BIN=/opt/plura/haproxy/3.2.26/sbin/haproxy

bash scripts/install-dedicated.sh rendered/haproxy.cfg "$HAPROXY_BIN"
```

설치 위치:

```text
/etc/haproxy/plura-syslog.cfg
/etc/systemd/system/plura-haproxy.service
/run/plura-haproxy/admin.sock          # 실행 시 생성
```

설정 검사 후 백업·설치까지만 수행합니다. 동일 TCP/514에 다른 프로세스가 있으면 중단합니다.
기존 `/etc/haproxy/haproxy.cfg`는 덮어쓰지 않습니다.
방화벽·SELinux를 확인한 뒤 명시적으로 기동합니다.

```bash
systemctl daemon-reload
systemctl enable --now plura-haproxy
systemctl status plura-haproxy --no-pager -l
ss -lntp '( sport = :514 )'
journalctl -u plura-haproxy -n 100 --no-pager
```

변경 적용:

```bash
"$HAPROXY_BIN" -c -f /etc/haproxy/plura-syslog.cfg
# 검사 성공 후에만
systemctl reload plura-haproxy
```

설정 변경 전 별도 백업은 계속 남기십시오. 정상 동작 중 설정을 바꿀 때 기존 TCP 연결은 새 노드로 재배치되지 않습니다.

## 7-B. 기존 메일용 HAProxy에 병합

**`install-dedicated.sh`를 실행하지 않습니다.** 기존 실행파일·서비스·global/defaults를 보존합니다.

```bash
STAMP=$(date +%Y%m%d-%H%M%S)
cp -a /etc/haproxy/haproxy.cfg "/root/haproxy.cfg.$STAMP.bak"
cp -a /etc/haproxy/haproxy.cfg /root/haproxy.cfg.candidate
# editor에서 rendered/plura-syslog.fragment.cfg를 candidate에 한 번만 병합
vi /root/haproxy.cfg.candidate
```

HTTP 전용 defaults의 옵션, 같은 이름의 frontend/backend, 기존 TCP/514 bind가 겹치지 않게 검토합니다.
기존에 `source`, PROXY protocol, health-check 기본값을 강제한 곳도 확인하십시오.
병합 파일에는 Syslog backend의 모드·타임아웃·상태 검사가 명시되어 있으나, 모든 기존 설정의 상속을 자동 정리하지는 않습니다.

```bash
# 실제 서비스가 사용하는 3.2+ 바이너리로 검사
/usr/sbin/haproxy -c -f /root/haproxy.cfg.candidate
# 검사 성공 후에만 복사하고 재검사
install -m 0640 /root/haproxy.cfg.candidate /etc/haproxy/haproxy.cfg
restorecon -v /etc/haproxy/haproxy.cfg
/usr/sbin/haproxy -c -f /etc/haproxy/haproxy.cfg
systemctl reload haproxy
```

상태 조회용 runtime socket은 기존 HAProxy socket을 사용합니다.
필요하면 기존 global에 아래 한 줄을 **중복 없이** 추가하고 해당 경로 디렉터리를 준비합니다.

```haproxy
stats socket /run/plura-haproxy/admin.sock mode 600 level admin
```

이 경로를 새로 쓸 경우 `/etc/tmpfiles.d/plura-haproxy.conf`에 `d /run/plura-haproxy 0750 root root -`를 등록하고
`systemd-tmpfiles --create /etc/tmpfiles.d/plura-haproxy.conf`로 생성합니다.
기존 서비스는 전용 `plura-haproxy.service`가 아니므로 로그·reload 명령도 기존 서비스명을 사용합니다.

## 8. MSA에서 송신 시험

192.168.1.15에 `scripts/syslog-test.sh`를 복사한 후 실제 HAProxy 주소로 실행합니다.

```bash
read -r -p 'HAProxy 수신 IP: ' LB_IP
bash scripts/syslog-test.sh tcp "PLURA Active-Active TEST 001" "$LB_IP" 172.16.12.212 514 udp
```

첫 `tcp`는 내부 전송이고 마지막 `udp`는 고객 서버로의 전송입니다.
한 번의 테스트는 Gateway 한 대만 사용하는 것이 정상입니다.
두 서버 동시 처리 확인에는 여러 TCP 연결을 **동시에 유지**해야 합니다.

```bash
# 전용 설치에서 노드 UP/DOWN 및 연결 수 확인 (root)
printf 'show stat\n' | socat - UNIX-CONNECT:/run/plura-haproxy/admin.sock
```

장애·복구·양쪽 DOWN 시험은 `docs/ACCEPTANCE.md`를 참고하십시오.
`on-marked-down shutdown-sessions`가 기존 연결을 종료하므로 MSA는 HAProxy로 재연결해야 합니다.

## 9. 운영 범위

단일 HAProxy 자체 장애는 이번 두 Gateway 구성으로 해결되지 않습니다.
HAProxy는 수신 LB이며 고객에게 보이는 송신 IP를 통일하지 않습니다.
두 Gateway의 외부 공인 IP 통일은 기존 방화벽의 공통 SNAT 경로로 설계해야 합니다.
설치 테스트 결과는 `docs/VALIDATION.md`, 공식 근거는 `docs/SOURCES.md`에 있습니다.
