TaiShan 2280 V2 서버(Kunpeng 920 프로세서)는 ARM 아키텍처 기반의 장비이므로, 반드시 **AArch64(ARM64) 버전의 Rocky Linux**를 사용해야 합니다. 설치는 Huawei 서버의 원격 관리 도구인 iBMC를 통한 가상 미디어(Virtual Media) 설치 방식이 가장 일반적이고 효율적입니다.

1. **iBMC 접속 및 KVM 콘솔 실행:** 원격 제어 준비.
웹 브라우저에서 서버의 iBMC IP 주소로 접속하여 관리자 계정으로 로그인한 뒤, 메인 화면 또는 상단 메뉴에서 **Remote Control** > **HTML5 Integrated Remote Console**(또는 Java 콘솔)을 실행합니다.


2. **가상 미디어(ISO) 마운트:** 설치 파일 연결.
KVM 콘솔 상단 툴바에서 **디스크 아이콘(Virtual Media)**을 클릭하고 'Image File'을 선택한 뒤, 다운로드해 둔 Rocky Linux 9 AArch64 ISO 파일을 찾아 **Connect(연결)**를 클릭합니다.
*Verification:* KVM 툴바의 디스크 아이콘 상태가 연결됨(Connected)으로 변경되어야 합니다.


3. **Boot Manager 진입 및 부팅:** 부팅 순서 변경.
서버 전원을 켜거나 재부팅합니다. 화면에 Huawei 로고가 나타날 때 **F11** 키를 눌러 Boot Manager로 진입한 후, 부팅 장치 목록에서 **Virtual DVD-ROM**을 선택하여 부팅합니다.
*Verification:* 화면에 `Install Rocky Linux 9.x`라는 AArch64용 GRUB 부트 메뉴가 나타납니다.


4. **RAID 설정 확인 및 설치 목적지 선택:** 디스크 마운트.
Anaconda 설치 GUI가 뜨면 언어를 선택합니다. **Installation Destination(설치 목적지)** 메뉴에 진입하여 OS를 설치할 가상 드라이브(RAID 볼륨)를 선택합니다.
*Verification:* 디스크 목록에 물리 디스크가 전혀 보이지 않는다면 설치를 종료하고 재부팅하여 시스템 시작 시 RAID 설정 화면(LSI WebBIOS 등)에서 논리 볼륨(Virtual Drive)을 먼저 생성해야 합니다.


5. **네트워크 및 패키지 설정 후 설치:** Anaconda 설정.
**Software Selection(소프트웨어 선택)**에서 'Minimal Install' 또는 'Server with GUI'를 선택하고, **Network & Hostname**에서 사용할 네트워크 인터페이스를 켜고 IP를 할당합니다. 이후 Root 비밀번호 설정과 사용자 생성을 마치고 **Begin Installation(설치 시작)**을 누릅니다.


6. **가상 미디어 해제 및 재부팅:** 설치 완료.
설치가 100% 완료되면 우측 하단의 'Reboot System'을 누르기 전에, KVM 콘솔 상단의 디스크 아이콘을 다시 눌러 **Disconnect(연결 해제)**를 클릭하여 ISO 마운트를 해제한 후 재부팅합니다.
*Verification:* 장비가 재부팅된 후 서버 하드디스크로 정상 부팅되어 Rocky Linux 9 로그인 프롬프트가 나타납니다.
