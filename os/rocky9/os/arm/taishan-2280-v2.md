# TaiShan 2280 V2 (Kunpeng 920) 서버 Rocky Linux 9 설치 가이드

본 문서는 Huawei TaiShan 2280 V2 (Kunpeng 920-4826) ARM 서버에 최신 Rocky Linux 9를 설치하기 위한 전체 과정을 안내합니다. 2019년 빌드된 구형 BIOS(버전 1.05 등)에서는 최신 OS 부팅에 문제가 발생할 수 있으므로, **펌웨어 업데이트를 먼저 진행**한 후 OS를 설치합니다.

---

## 🚨 사전 주의 사항 (매우 중요)
이 장비는 ARM 아키텍처(Kunpeng 920) 기반입니다. 일반적인 Intel/AMD용 ISO 파일은 부팅되지 않습니다.
* 반드시 Rocky Linux 공식 홈페이지에서 **AArch64 (ARM64)** 아키텍처용 ISO 파일(Minimal 또는 DVD)을 다운로드해야 합니다.

---

## 1단계: BIOS 및 iBMC 펌웨어 업데이트

기존 BIOS 버전(예: 1.05, 2019/09/18)을 Rocky Linux 9 커널과 호환되는 최신 버전으로 업데이트합니다.

### 1.1 펌웨어 다운로드
1. Huawei Enterprise 지원 웹사이트에 접속합니다.
2. `TaiShan 2280 V2` 모델을 검색합니다.
3. 최신 버전의 **iBMC 펌웨어**와 **BIOS 펌웨어** 업그레이드 패키지(`.hpm` 파일)를 각각 다운로드합니다.

### 1.2 펌웨어 적용 (iBMC 웹 인터페이스)
1. 브라우저를 열고 서버의 iBMC IP 주소로 접속하여 관리자 계정으로 로그인합니다.
2. 상단 메뉴에서 **System** > **Firmware Upgrade**로 이동합니다.
3. **iBMC 펌웨어 업데이트**:
   * 다운로드한 iBMC `.hpm` 파일을 업로드하고 업데이트를 진행합니다. (안정성을 위해 iBMC를 먼저 업데이트합니다.)
   * 진행률이 100%가 되고 성공(Success) 메시지가 뜰 때까지 대기합니다.
4. **BIOS 펌웨어 업데이트**:
   * 동일한 메뉴에서 BIOS `.hpm` 파일을 업로드하고 업데이트를 진행합니다.
   * 완료 후 성공 메시지를 확인합니다.

### 1.3 서버 재시작 및 버전 확인
1. 서버 전원을 껐다가 켭니다 (Power Cycle).
2. 초기 부팅 화면에서 BIOS 빌드 날짜가 최신으로 변경되었는지 확인합니다.

---

## 2단계: Rocky Linux 9 (AArch64) 설치

펌웨어 업데이트가 완료되면 가상 미디어를 통해 OS 설치를 진행합니다.

### 2.1 KVM 콘솔 실행 및 가상 미디어 마운트
1. iBMC 웹 메인 화면 또는 상단 메뉴에서 **Remote Control** > **HTML5 Integrated Remote Console**(또는 Java 콘솔)을 실행합니다.
2. KVM 콘솔 상단 툴바에서 **디스크 아이콘(Virtual Media)**을 클릭합니다.
3. `Image File`을 선택한 뒤, 사전에 준비한 **Rocky Linux 9 AArch64 ISO** 파일을 찾아 **Connect(연결)**를 클릭합니다.

### 2.2 Boot Manager 진입 및 부팅
1. 서버를 재부팅합니다.
2. 화면에 Huawei 로고가 나타날 때 **F11** 키를 반복해서 눌러 **Boot Manager**로 진입합니다.
3. 부팅 장치 목록에서 **Virtual DVD-ROM**을 선택하여 부팅합니다.
4. 화면에 `Install Rocky Linux 9.x`라는 AArch64용 GRUB 메뉴가 나타나면 Enter를 누릅니다.

### 2.3 OS 설치 설정 (Anaconda GUI)
설치 화면이 나타나면 다음 항목들을 설정합니다.

1. **언어 선택**: 한국어 또는 English 선택 후 진행합니다.
2. **Installation Destination (설치 목적지)**:
   * OS를 설치할 드라이브(RAID 볼륨)를 선택합니다.
   * *참고: 디스크가 보이지 않는다면, 설치 전 서버 부팅 시 LSI WebBIOS 등 RAID 설정 유틸리티에 진입하여 Logical Drive를 먼저 구성해야 합니다.*
3. **Software Selection (소프트웨어 선택)**: 
   * 서버 용도에 맞게 `Minimal Install` 또는 `Server with GUI`를 선택합니다.
4. **Network & Hostname (네트워크 설정)**:
   * 사용할 네트워크 인터페이스(Ethernet)를 `ON`으로 변경하고 고정 IP 등 네트워크 정보를 입력합니다.
5. **사용자 설정**: Root 비밀번호를 설정하고, 필요시 일반 사용자를 생성합니다.
6. 우측 하단의 **Begin Installation (설치 시작)**을 클릭합니다.

### 2.4 설치 완료 및 재부팅
1. 설치 진행률이 100%에 도달하고 완료 메시지가 뜨면, 우측 하단의 **Reboot System** 버튼이 활성화됩니다.
2. **주의:** 재부팅 버튼을 누르기 **전**에, KVM 콘솔 상단의 디스크 아이콘을 다시 클릭하여 **Disconnect(연결 해제)**를 선택합니다. (ISO 마운트 해제)
3. 서버가 재부팅되면 물리 하드디스크로 정상 부팅되며, Rocky Linux 9 로그인 프롬프트를 확인할 수 있습니다.
