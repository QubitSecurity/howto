# HAProxy 설치 방법

Rocky Linux 9/10 · root 실행 · HAProxy **3.2.26** · 두 Gateway **Active-Active**.

`MSA → HAProxy TCP/514 → rsyslog + Go Sender 2대 → 고객 Syslog`

이 ZIP은 **이 안내문과 `haproxy.cfg` 두 파일**입니다. 별도 설정 생성기나 설치 스크립트는 없습니다.
아래는 **신규 전용 HAProxy 서비스** 설치 절차입니다. 기존 메일 LB에 적용할 때는 재설치하거나 전체 설정을 덮어쓰지 말고, 3.2 이상인지 확인한 뒤 `frontend`·`backend`만 기존 설정에 병합하십시오.

## 1. 다운로드 및 설치

ZIP을 해제한 디렉터리에서 실행합니다. 아래 괄호 안 작업은 원래 작업 디렉터리를 변경하지 않습니다. 오류가 나면 다음 단계로 진행하지 마십시오.

```bash
(
set -e
dnf install -y gcc make openssl-devel pcre2-devel systemd-devel curl tar gzip
mkdir -p /usr/local/src/plura-haproxy
cd /usr/local/src/plura-haproxy

curl --fail --location --proto '=https' --tlsv1.2 \
  https://www.haproxy.org/download/3.2/src/haproxy-3.2.26.tar.gz \
  -o haproxy-3.2.26.tar.gz
printf '%s\n' '760ef35fafc1e05844e73ad07e138e9e96fddbf5de02f606249c027f754827da  haproxy-3.2.26.tar.gz' | sha256sum -c -
tar -xzf haproxy-3.2.26.tar.gz
cd haproxy-3.2.26
make -j2 TARGET=linux-glibc USE_OPENSSL=1 USE_PCRE2=1 USE_SYSTEMD=1
install -d /opt/plura/haproxy/3.2.26/sbin /etc/haproxy
install -m 0755 haproxy /opt/plura/haproxy/3.2.26/sbin/haproxy

getent group haproxy >/dev/null || groupadd --system haproxy
id haproxy >/dev/null 2>&1 || useradd --system --gid haproxy --no-create-home --shell /sbin/nologin haproxy
/opt/plura/haproxy/3.2.26/sbin/haproxy -v
)
```

기존 `/usr/sbin/haproxy`는 변경하지 않습니다. 공식 배포본과 SHA256을 확인한 고정 버전이며, 이후 보안 패치는 별도로 관리합니다.

## 2. haproxy.cfg 수정 및 설치

함께 받은 `haproxy.cfg`를 열고 **세 가지 값을 실제 IP로 직접 교체**합니다.

| config의 표시 | 입력할 값 |
|---|---|
| `<HAPROXY_LISTEN_IP>` | MSA가 접속할 HAProxy 내부 IP |
| `<HAPROXY_SOURCE_IP>` | HAProxy가 Gateway로 연결할 때 사용할, HAProxy 서버에 할당된 IP |
| `<GATEWAY2_IP>` | 두 번째 rsyslog Gateway 내부 IP |

HAProxy 수신·송신 IP가 같으면 같은 값을 입력합니다. MSA `192.168.1.15`, Gateway 1 `192.168.200.200`은 반영되어 있습니다. 다른 MSA도 사용하면 `acl plura_msa src`에 해당 IP를 추가합니다.

```bash
vi haproxy.cfg

# 설정 검사 성공 시에만 복사
/opt/plura/haproxy/3.2.26/sbin/haproxy -c -f ./haproxy.cfg && \
install -m 0640 haproxy.cfg /etc/haproxy/plura-syslog.cfg
```

`/etc/haproxy/plura-syslog.cfg`가 이미 존재하면 복사 전에 백업합니다.

**Gateway 쪽 선행 조건:** 두 서버에 기존 **v0.4.1-ha의 `/ready` 상태 서비스(TCP/18081)**가 실행 중이어야 합니다. 없으면 HAProxy는 해당 서버를 DOWN으로 처리합니다. rsyslog와 Go Sender의 허용 송신 IP도 MSA IP가 아닌 `<HAPROXY_SOURCE_IP>`로 맞춥니다. 이번 ZIP은 Gateway를 설치·수정하지 않습니다.

## 3. 서비스 등록 및 시작

아래 명령이 systemd 서비스 파일을 생성합니다. 별도의 다운로드 파일은 필요하지 않습니다.

```bash
cat > /etc/systemd/system/plura-haproxy.service <<'UNIT'
[Unit]
Description=PLURA Syslog HAProxy Active-Active
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
RuntimeDirectory=plura-haproxy
RuntimeDirectoryMode=0750
RuntimeDirectoryPreserve=yes
ExecStartPre=/opt/plura/haproxy/3.2.26/sbin/haproxy -c -q -f /etc/haproxy/plura-syslog.cfg
ExecStart=/opt/plura/haproxy/3.2.26/sbin/haproxy -Ws -f /etc/haproxy/plura-syslog.cfg -p /run/plura-haproxy/haproxy.pid
ExecReload=/opt/plura/haproxy/3.2.26/sbin/haproxy -c -q -f /etc/haproxy/plura-syslog.cfg
ExecReload=/bin/kill -USR2 $MAINPID
KillMode=mixed
Restart=on-failure
RestartSec=2
LimitNOFILE=65536
StandardOutput=journal
StandardError=journal
SyslogIdentifier=plura-haproxy

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now plura-haproxy
systemctl status plura-haproxy --no-pager -l
```

**네트워크 허용:** `192.168.1.15 → HAProxy TCP/514`, `HAProxy 송신 IP → 두 Gateway TCP/514·18081`을 방화벽·보안 그룹에서 허용합니다. 기존 TCP/514 리스너가 같은 IP를 점유하면 먼저 충돌을 해소합니다. UDP/514 수신은 이번 구성에 없습니다.

SELinux는 Enforcing을 유지합니다. 기동·연결이 거부되면 `journalctl -u plura-haproxy -n 100 --no-pager`와 `ausearch -m AVC -ts recent`로 원인을 확인하고 필요한 최소 정책을 적용합니다. 소스 설치 경로의 SELinux 레이블·권한은 실제 서버에서 확인해야 합니다.

## 4. 확인 및 이후 설정 적용

```bash
ss -lntp '( sport = :514 )'
journalctl -u plura-haproxy -n 100 --no-pager

# 이후 config를 수정한 경우: 검사 성공 시에만 reload
/opt/plura/haproxy/3.2.26/sbin/haproxy -c -f /etc/haproxy/plura-syslog.cfg && \
systemctl reload plura-haproxy
```

두 Gateway는 동일 가중치로 **TCP 연결 단위** 분산됩니다. MSA가 연결 하나만 유지하면 해당 연결은 한 Gateway만 사용합니다. 장애 시 MSA의 재연결이 필요하며, HAProxy는 영속 큐나 로그 무손실을 보장하지 않습니다.

**검증 범위:** 기존 설정에서 구성 요소를 유지하고 IP 직접 편집 방식으로 정리했습니다. 설치 명령의 Bash 문법을 검사했습니다. 실제 Rocky Linux 설치, HAProxy 설정 검사·장애 전환은 대상 서버에서 수행해야 합니다.

공식 확인 자료: [배포본](https://www.haproxy.org/download/3.2/src/) · [SHA256](https://www.haproxy.org/download/3.2/src/haproxy-3.2.26.tar.gz.sha256) · [설정 매뉴얼](https://docs.haproxy.org/3.2/configuration.html)
