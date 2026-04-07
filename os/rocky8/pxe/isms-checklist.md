## ✅ ISMS 요구사항 기반 Linux 서버 보안 설정 항목 (자동화 적용 가능 항목 중심)

### 📌 1. 계정 및 인증 보안

* [ ] root 외 관리자 계정 추가
* [ ] 일반 사용자 계정 최소 권한 부여
* [ ] `/etc/login.defs` 설정:

  * `PASS_MAX_DAYS` (비밀번호 최대 사용기간, 예: 90일)
  * `PASS_MIN_DAYS`, `PASS_WARN_AGE`
* [ ] `/etc/security/pwquality.conf`:

  * 최소 길이, 대소문자/숫자 포함 등 복잡성 설정
* [ ] 패스워드 변경 강제 (`chage`, `passwd -e`)
* [ ] 계정 잠금 정책 (`pam_tally2`, `faillock`)
* [ ] root 계정 직접 로그인 금지 (`PermitRootLogin no`)
* [ ] sudo 사용 기록 로깅 (`sudoers` + `Defaults log_output`)

---

### 📌 2. SSH 및 원격 접속 보안

* [ ] SSH 포트 변경 (`22` → 비표준 포트)
* [ ] root 로그인 제한
* [ ] 패스워드 인증 비활성화 및 공개키 인증 강제
* [ ] idle timeout 설정 (`ClientAliveInterval`, `ClientAliveCountMax`)
* [ ] `AllowUsers` 또는 `AllowGroups`로 제한
* [ ] 불필요한 서비스 제거 (telnet, vsftpd, etc.)

---

### 📌 3. 접근 통제 및 방화벽

* [ ] firewalld 정책 제한 (허용 포트만 등록)
* [ ] iptables 또는 nftables 백업 및 적용
* [ ] selinux enforcing 모드 유지 (`getenforce`, `setenforce`)
* [ ] cron 접근 제어 (`/etc/cron.allow`, `/etc/at.allow`)
* [ ] root 외 사용자 `su` 금지 (`/etc/pam.d/su` 설정)
* [ ] 홈 디렉토리 접근 제한 (`chmod 700 /home/*`)

---

### 📌 4. 로그 관리 및 감사

* [ ] auditd 설정 및 활성화
* [ ] `audit.rules`로 주요 디렉토리 감시 (`/etc`, `/var/log`, `/home`, etc.)
* [ ] history 로그 타임스탬프 저장 (`HISTTIMEFORMAT`)
* [ ] `/var/log` 디스크 공간 확인 및 로테이션 설정 (`logrotate`)
* [ ] 중요한 로그 파일 권한 제한 (`/var/log/secure`, `/var/log/messages`)

---

### 📌 5. 무결성 검사 및 취약점 점검

* [ ] AIDE 무결성 검사 도입 및 초기화
* [ ] OpenSCAP 또는 Lynis 설치 및 주기적 스캔
* [ ] 정기 보안 점검 스크립트 cron 등록

---

### 📌 6. 시간 동기화

* [ ] chrony 또는 ntpd 설정
* [ ] 신뢰할 수 있는 내부/외부 NTP 서버 지정
* [ ] 서비스 자동 시작 등록

---

### 📌 7. 보안 패치 및 업데이트

* [ ] 보안 업데이트 자동화 (dnf-automatic, yum-cron)
* [ ] yum repository 재정의 (내부 리포 사용 시 baseurl 설정)
* [ ] 사용하지 않는 repo 비활성화

---

### 📌 8. 시스템 설정 및 커널 보안

* [ ] 커널 파라미터 보안 설정 (`/etc/sysctl.conf` 또는 `sysctl.d`)

  * `net.ipv4.conf.all.rp_filter = 1`
  * `net.ipv4.tcp_syncookies = 1`
  * `net.ipv4.conf.all.accept_source_route = 0`
  * `kernel.randomize_va_space = 2`
* [ ] core dump 비활성화 (`ulimit -c 0`, `/etc/security/limits.conf`)
* [ ] IPv6 비활성화 (사용하지 않을 경우)
* [ ] USB, Bluetooth 비활성화 (`modprobe -r usb_storage` 등)

---

### 📌 9. 불필요한 서비스 제거 및 제한

* [ ] avahi-daemon, cups, bluetooth, kdump 등 제거 또는 비활성화
* [ ] 시스템 서비스 목록 확인 후 최소화 (`systemctl list-unit-files --type=service`)
* [ ] runlevel 또는 systemd target 설정 검토

---

### 📌 10. 기타 보안 설정

* [ ] banner 설정 (`/etc/issue`, `/etc/issue.net`) – 접근 경고 문구
* [ ] 계정 사용 이력 (`last`, `lastlog`) 관리 및 주기적 확인
* [ ] 시스템 자동 재부팅 방지 설정 (`/etc/crontab`, watchdog 설정 등)
* [ ] 스크립트 실행 경로 제한 (`PATH` 설정 보안)

---

## 🧩 정리: Kickstart 자동화로 적용 가능한 항목 분류

| 분류            | 자동화 가능     | 수동 필요                  |
| ------------- | ---------- | ---------------------- |
| 기본 계정 및 인증    | ✅          | 일부 암호 정책 점검 필요         |
| SSH 설정        | ✅          | 키 배포는 수동 또는 Ansible 필요 |
| SELinux 및 방화벽 | ✅          | -                      |
| 로그 및 감사       | ✅          | 분석은 별도 도구 필요           |
| NTP/업데이트/패키지  | ✅          | 리포지터리 내부 구성 여부에 따라     |
| AIDE/OpenSCAP | ✅ (설치/초기화) | 점검 결과 해석은 수동           |
| 커널 파라미터       | ✅          | -                      |
| 불필요 서비스 제거    | ✅          | 업무에 따라 조정 필요           |

---
