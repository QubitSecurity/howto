## Ubuntu Setting 

### 1. Ubuntu OS 설치 과정 (USB)

```text
①. USB 부팅 설정
USB 드라이브를 연결하고 부팅 → F2 등으로 BIOS 진입 → Boot 순서를 USB로 설정 후 저장 및 재부팅

②. Ubuntu OS 설치
언어 선택 화면에서 원하는 언어 선택 후 Next 클릭

③. 네트워크 연결
네트워크 연결은 선택 사항으로 생략 가능

④. 설치 방식 설정
전체 디스크 삭제 설치 또는 파티션 직접 지정

⑤. 시간대 설정
지역/시간대 수동 또는 자동 설정 (NTP 동기화 권장)

⑥. 사용자 계정 설정
사용자 이름, 컴퓨터 이름, 비밀번호 설정 (최초 계정은 root 권한 포함)

⑦. 설치 시작
"Install Now" 클릭하여 설치 시작

⑧. 시스템 재부팅
설치 완료 후 USB 제거 → "Restart Now" 클릭

⑨. Ubuntu 초기 설정 완료
계정 로그인 후 기본 설정 완료
```
##


### 2. Ubuntu root password 설정

* 바탕화면에서 우클릭 → "Open in Terminal"

```bash
sudo passwd root
```

```text
sudo passwd → 계정 암호 입력 후, root 비밀번호 설정
```
##


### 3. 네트워크 설정 (Proxy)

### GUI 설정

```text
Settings → Network → Proxy → Manual 설정
http_proxy=(프록시 IP)
https_proxy=(프록시 IP)
```

### 환경 변수 설정

```bash
sudo vi /etc/profile.d/pproxy.sh
```

```bash
export http_proxy=http://(프록시 IP:PORT)
export https_proxy=http://(프록시 IP:PORT)
export no_proxy=localhost,127.0.0.1,172.16.*.*
```

```bash
source /etc/profile.d/pproxy.sh
```
##


### 4. Ubuntu 한국어 패치 및 입력기 설정

* 한국어 언어팩 설치

```bash
sudo apt update
sudo apt install language-pack-ko
```

```text
설치 후 재부팅 필수
```

* 한국어 키보드 설정

```text
Settings → Keyboard → Input Sources → + → Korean (Hangul) 추가
한영 전환 키 설정: Preferences → 원하는 키 지정
```
