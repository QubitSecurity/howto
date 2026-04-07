## 🛠️ 전체 Kickstart 파일 예시 (`/var/www/html/pxe/ks.cfg`)

```bash
#version=RHEL8
install
lang en_US.UTF-8
keyboard us
timezone Asia/Seoul --isUtc
rootpw --iscrypted [암호화된 root 패스워드]
auth --useshadow --passalgo=sha512
selinux --enforcing
firewall --enabled --service=ssh
bootloader --location=mbr
clearpart --all --initlabel
autopart

# 기본 패키지
%packages
@^minimal-environment
chrony
vim
bash-completion
aide
audit
openscap-scanner
policycoreutils
%end

# 설치 후 보안 설정
%post

# 1. SSH 보안 설정
echo "Port 54" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
echo "ClientAliveCountMax 0" >> /etc/ssh/sshd_config
firewall-cmd --permanent --remove-service=ssh
firewall-cmd --permanent --add-port=54/tcp
firewall-cmd --reload
systemctl restart sshd

# 2. 관리자 계정 추가
useradd secadmin
echo 'secadmin:Changeme123!' | chpasswd
usermod -aG wheel secadmin

# 3. 로그 및 감사 정책
systemctl enable --now auditd
sed -i 's/^.*max_log_file =.*/max_log_file = 50/' /etc/audit/auditd.conf
sed -i 's/^.*space_left_action =.*/space_left_action = email/' /etc/audit/auditd.conf

# 4. bash 기록 강화
echo "export HISTTIMEFORMAT='%F %T '" >> /etc/profile.d/history.sh
chmod +x /etc/profile.d/history.sh

# 5. 계정 잠금 정책 (5회 실패 시 10분 잠금)
echo "auth required pam_tally2.so deny=5 unlock_time=600 onerr=fail audit even_deny_root" >> /etc/pam.d/sshd

# 6. NTP 설정
sed -i 's/^server .*/server time.bora.net iburst/' /etc/chrony.conf
systemctl enable --now chronyd

# 7. 자동 업데이트 설정
dnf -y install dnf-automatic
systemctl enable --now dnf-automatic.timer

# 8. yum repo 구성
mkdir -p /etc/yum.repos.d/backup
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/

cat <<EOF > /etc/yum.repos.d/local.repo
[base]
name=Local Base
baseurl=http://[SERVER_IP]:8080/pxe/rockylinux8/BaseOS/
enabled=1
gpgcheck=0

[appstream]
name=Local AppStream
baseurl=http://[SERVER_IP]:8080/pxe/rockylinux8/AppStream/
enabled=1
gpgcheck=0
EOF

dnf clean all
dnf repolist

# 9. AIDE 무결성 검사 초기화
aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# 10. 불필요 서비스 제거
systemctl disable kdump
systemctl disable bluetooth
systemctl disable avahi-daemon

%end
```

---

## 📌 커스터마이징 포인트

| 항목            | 설명                                       |
| ------------- | ---------------------------------------- |
| `rootpw`      | `openssl passwd -6` 명령으로 암호화된 패스워드 생성 필요 |
| `[SERVER_IP]` | PXE 서버 IP 주소로 변경                         |
| `secadmin` 계정 | ISMS 대응용 관리자 계정 생성                       |
| PAM 설정        | 계정 잠금 정책 등 강화 적용                         |

---

## ✅ 추가 보안 도구 (선택 적용)

| 도구            | 용도         |
| ------------- | ---------- |
| AIDE          | 무결성 검증     |
| OpenSCAP      | 보안 취약점 스캔  |
| dnf-automatic | 자동 보안 업데이트 |

---
