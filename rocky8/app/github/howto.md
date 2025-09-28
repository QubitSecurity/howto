`qubitsec/home` 리포지터리를 Rocky Linux 8 서버와 안전하게 동기화하는 “표준 운영” 방법을 아래처럼 정리했습니다.
핵심은 **서버=읽기 전용 배포 키(Deploy Key, SSH)** + **systemd 타이머로 주기적 `git pull`** 입니다.

---

# 1) Rocky Linux 8 서버 설정

## 1-1. 기본 패키지 설치 및 전용 계정

```bash
sudo dnf -y install git openssh-clients
sudo useradd -r -m -s /bin/bash gitpull   # 동기화 전용 시스템 계정
sudo passwd -l gitpull                    # 직접 로그인 막기(옵션)
```

## 1-2. SSH 배포키 생성(비밀번호 없이)

```bash
sudo -u gitpull bash -lc '
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "rocky8-deploy@qubitsec-home" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub
'
```

* 출력되는 `ssh-ed25519 ...` **공개키**를 복사해 두세요. (→ GitHub 설정에 붙여넣음)

## 1-3. GitHub 호스트 키 고정(보안 강화)

```bash
sudo -u gitpull bash -lc '
ssh-keyscan github.com >> ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts
'
```

## 1-4. 리포지터리 클론(원하는 경로에)

```bash
sudo -u gitpull bash -lc '
mkdir -p ~/repos && cd ~/repos
git clone git@github.com:qubitsec/home.git
cd home
git config pull.rebase false
git config --global --add safe.directory /home/gitpull/repos/home
'
```

> **프라이빗 리포**라면 위의 Deploy Key가 추가된 뒤에야 `clone`이 됩니다.

## 1-5. 수동 동기화 테스트

```bash
sudo -u gitpull bash -lc '
cd ~/repos/home
git pull
'
```

## 1-6. systemd 타이머로 자동 동기화(예: 5분마다)

서비스 유닛:

```bash
sudo tee /etc/systemd/system/home-sync.service >/dev/null <<'UNIT'
[Unit]
Description=Sync qubitsec/home repo

[Service]
Type=oneshot
User=gitpull
WorkingDirectory=/home/gitpull/repos/home
ExecStart=/usr/bin/git reset --hard
ExecStart=/usr/bin/git clean -fd
ExecStart=/usr/bin/git pull --ff-only
UNIT
```

타이머 유닛:

```bash
sudo tee /etc/systemd/system/home-sync.timer >/dev/null <<'TIMER'
[Unit]
Description=Run qubitsec/home sync every 5 minutes

[Timer]
OnBootSec=30s
OnUnitActiveSec=5min
Unit=home-sync.service

[Install]
WantedBy=timers.target
TIMER
```

활성화:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now home-sync.timer
sudo systemctl list-timers | grep home-sync
```

> **SELinux** 기본 설정에서는 문제 없지만, 리포를 웹루트(`/var/www/...`)로 쓰는 등 컨텍스트가 필요할 땐 `restorecon -Rv /경로`를 참고하세요.

---

# 2) GitHub 쪽 설정(qubitsec/home)

## 2-1. 리포지터리의 **Deploy Key** 등록(권장)

1. GitHub → `qubitsec/home` → **Settings** → **Deploy keys** → **Add deploy key**
2. Title: `rocky8-deploy`
3. Key: (서버에서 복사한 `id_ed25519.pub` 내용 붙여넣기)
4. **Allow write access**는 해제(읽기 전용)
5. **Add key**

> 여러 서버에서 쓰려면 서버마다 키를 만들고 각각 Deploy Key로 추가하면 됩니다.

## 2-2. (선택) Organization 레벨의 **Deploy Key/SSH 인증**

여러 리포를 같은 서버에서 읽어야 하면 Org 단의 **machine user** + **read-only 팀 권한**도 방법입니다. 다만 단일 리포만 동기화라면 Deploy Key가 가장 간단하고 안전합니다.

## 2-3. (선택) Webhook으로 “푸시 즉시” 갱신

폴링(5분) 대신 즉시 반영이 필요하면:

* `qubitsec/home` → **Settings** → **Webhooks** → **Add webhook**
* Payload URL: 서버의 수신 엔드포인트(예: `https://your-domain/hooks/github`)
* Content type: `application/json`
* 이벤트: `Just the push event`
* 서버에서는 간단한 수신 스크립트가 `git pull`을 트리거(예: systemd `PathExists`/`socket`/`curl`→`systemctl start home-sync.service`).
  이 방식은 추가 개발/운영이 필요해 **초기엔 타이머 방식**을 추천합니다.

## 2-4. (대안) HTTPS + Personal Access Token(토큰 보관 필요)

방화벽 정책상 SSH가 불가하면 **fine-grained PAT(읽기 전용)** 를 만들고 아래처럼 원격을 바꿉니다.

```bash
# 서버에서(예: gitpull 계정)
cd ~/repos/home
git remote set-url origin https://github.com/qubitsec/home.git
# 최초 pull 시 사용자/토큰 입력(자격증명 캐시는 OS별 보안 저장소 사용 권장)
```

> 토큰은 노출 위험이 있어 서버 저장 시 권한/보안에 각별히 주의하세요.

---

## 운영 팁

* **브랜치 고정:** 운영은 `main`만 쓰고, 필요 시 `git config --global init.defaultBranch main`.
* **LFS 사용 여부:** 대용량 파일이 있다면 서버에 `git lfs install` 필요.
* **충돌 방지:** 서버에서는 **수정 금지(정적 배포 전용)** 를 원칙으로 하고, 서비스 유닛의 `reset --hard`/`clean -fd`로 깨끗한 워킹트리를 유지.
* **로그 확인:** `journalctl -u home-sync.service --no-pager -n 100`.

이대로 진행하시면 Rocky8 서버가 `qubitsec/home`을 안전하게 주기 동기화합니다. 필요하시면 **웹루트 배포(nginx/httpd) 연동**이나 **서브디렉터리만 받아오는 sparse-checkout** 구성도 바로 드릴게요.
