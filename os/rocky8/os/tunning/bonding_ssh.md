10대 서버 중 한 대를 제외하고 SSH 접속이 안 된다면 아래 순서대로 접근하면 효율적으로 원인을 파악할 수 있습니다.

---

## 1단계. 문제 범위 파악하기

먼저, 문제가 발생하지 않은 1대의 서버를 기준으로 차이점을 찾아야 합니다.

**확인할 사항**:

- SSH 접속이 정상적인 서버의 IP, 네트워크 설정, 방화벽 상태 등을 기록합니다.
- SSH 접속이 안 되는 서버들의 네트워크 환경, OS, 방화벽 설정을 비교합니다.

```bash
# 정상 접속 서버에서 확인
ip addr
route -n
firewall-cmd --list-all # CentOS/Rocky 기준
iptables -L -n
```

---

## 2단계. 네트워크 문제인지 확인

### (1) Ping 테스트

정상 서버에서 SSH 불가 서버로 Ping 테스트 수행:

```bash
ping <SSH불가 서버 IP>
```

- Ping이 안된다면 네트워크 또는 방화벽 문제일 가능성이 큽니다.

### (2) 포트 연결 확인 (22번 포트)

```bash
nc -vz <SSH불가 서버 IP> 22
# 또는
telnet <SSH불가 서버 IP> 22
```

- 접속이 안 된다면 SSH 서비스 문제이거나 방화벽 문제입니다.

---

## 3단계. SSH 서비스 상태 점검

서버 콘솔(VM Console 등 직접 접근) 또는 클라우드 콘솔을 이용하여 SSH 불가 서버에 접근하여 SSH 서비스 확인:

```bash
# SSH 서비스 상태 확인
systemctl status sshd

# SSH 서비스 재시작
systemctl restart sshd

# 서비스 상태 확인 (포트가 LISTEN 상태인지)
ss -tnlp | grep :22
```

---

## 4단계. 방화벽(Firewall) 및 보안그룹 점검

방화벽 설정에서 SSH 포트(22번)가 허용되었는지 확인합니다.

- **CentOS/Rocky (firewalld)** 기준:

```bash
firewall-cmd --list-all
# 필요하면 추가 허용
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload
```

- **Ubuntu (UFW)** 기준:

```bash
ufw status verbose
# 필요하면 추가 허용
ufw allow ssh
ufw reload
```

- 보안그룹이 있는 클라우드 환경인 경우 보안그룹에서 22번 포트 허용 여부도 점검합니다.

---

## 5단계. 서버의 네트워크 설정 점검

서버의 네트워크 인터페이스가 정상 작동하는지 점검합니다.

```bash
ip addr
ip link show
```

- IP 할당이 정상적인지, 인터페이스가 DOWN 상태는 아닌지 확인합니다.
- 필요 시 네트워크 재시작:
```bash
systemctl restart network   # Rocky/CentOS
systemctl restart networking  # Debian/Ubuntu
```

---

## 6단계. 접속 허용 목록(AllowUsers, AllowGroups 등) 확인

SSH 설정 파일(`/etc/ssh/sshd_config`)을 점검하여 특정 사용자나 IP가 제한되어 있지 않은지 확인합니다.

```bash
vi /etc/ssh/sshd_config
# AllowUsers, DenyUsers 등 설정 확인

# 설정 변경 후에는 반드시 SSH 재시작
systemctl restart sshd
```

---

## 7단계. SELinux 점검 (RHEL/CentOS/Rocky 등)

SELinux 상태를 확인합니다.

```bash
getenforce
```

SELinux가 **Enforcing** 상태라면 audit 로그를 확인해보세요.

```bash
ausearch -m AVC,USER_AVC -ts recent
```

일시적으로 Permissive로 변경하여 테스트도 가능합니다:

```bash
setenforce 0
# 테스트 후 다시 활성화 권장
setenforce 1
```

---

## 8단계. SSH 로그 점검

로그 파일 확인:

```bash
tail -f /var/log/secure      # CentOS/Rocky
tail -f /var/log/auth.log    # Ubuntu/Debian
```

SSH 접속 시도를 하며 로그를 모니터링하면 거절 이유가 표시됩니다.

---

## 요약 (권장 점검 순서)

- [ ] Ping 테스트 및 포트(22번) 테스트
- [ ] SSH 서비스 상태 및 재시작
- [ ] 방화벽 및 보안그룹 점검
- [ ] 네트워크 인터페이스 상태 확인
- [ ] SSH 설정파일 확인 (`sshd_config`)
- [ ] SELinux 확인
- [ ] SSH 접속 로그 점검

위 순서대로 점검하면 SSH 접근 문제를 빠르고 정확하게 파악할 수 있습니다.
