Legacy BIOS 모드와 UEFI(UEFI BIOS) 모드는 컴퓨터가 부팅 시 사용하는 **펌웨어 인터페이스**입니다. 둘의 차이는 시스템 초기화, 부트로더 로딩 방식, 파티션 방식, 보안 기능 등에서 나타납니다.

---

## 🧾 1. **Legacy BIOS 모드**

### ✅ 장점

* **오래된 시스템과의 호환성**이 매우 뛰어남
  → 10년 이상 된 시스템에서도 사용 가능
* 구성 및 설정이 간단함
* 많은 OS와 툴이 기본적으로 지원함

### ❌ 단점

* \*\*MBR(Master Boot Record)\*\*만 사용 가능
  → 최대 **2TB 이하 디스크만 인식**
  → 최대 4개의 주 파티션만 허용
* 멀티 부팅 설정이 번거롭고 유연하지 않음
* Secure Boot, Fast Boot 등의 **보안/속도 향상 기능 없음**
* 그래픽 인터페이스 없이 텍스트 기반 설정 화면

---

## 🧾 2. **UEFI 모드 (Unified Extensible Firmware Interface)**

### ✅ 장점

* **GPT(GUID Partition Table)** 지원
  → **2TB 이상 디스크 사용 가능**
  → 수십 개 파티션 설정 가능
* 부팅 속도 향상 (Fast Boot)
* **Secure Boot** 기능으로 루트킷 방지 가능
* 그래픽 GUI 환경의 BIOS 설정 가능 (제조사에 따라 다름)
* EFI Shell 및 드라이버 모듈화 가능

### ❌ 단점

* 구형 OS (예: Windows XP, CentOS 6, 일부 리눅스 Rescue ISO 등) 와 호환성 낮음
* 복잡한 설정 (특히 PXE, dual boot 등에서)
* Secure Boot로 인해 부트로더나 커널 서명 요구되는 경우 있음

---

## 🔁 비교 요약표

| 항목             | Legacy BIOS    | UEFI                     |
| -------------- | -------------- | ------------------------ |
| 디스크 파티션 형식     | MBR            | GPT                      |
| 디스크 용량 제한      | 2TB 이하         | 2TB 초과 가능                |
| 파티션 수 제한       | 최대 4개          | 수십 개 가능                  |
| 부트로더 위치        | 부트 섹터 (MBR)    | EFI 시스템 파티션 (ESP)        |
| 부팅 속도          | 느림             | 빠름 (Fast Boot 지원)        |
| Secure Boot 지원 | ❌ 없음           | ✅ 가능                     |
| 설정 화면          | 텍스트 기반         | GUI 기반 (일부 제조사)          |
| PXE 부팅 지원      | PXE 가능 (bios용) | PXE 가능 (EFI용)            |
| OS 호환성         | 오래된 OS 호환      | 최신 OS 권장 (Win8+, RHEL7+) |
| 스크립트/툴 호환성     | PXELINUX 잘 작동  | GRUB2 또는 shim 필요         |

---

## 🔍 결론

* **UEFI 권장**: 새 하드웨어, 2TB 이상 디스크, 최신 OS, 보안이 중요한 경우
* **Legacy 유지 가능**: 구형 시스템, 구형 OS, 단순 PXE 구조 유지 시

---

💡 **팁**: 대부분의 현대 서버/PC는 \*\*UEFI + Legacy 지원(BIOS Compatibility Mode, CSM)\*\*을 동시에 지원하므로 상황에 따라 둘 다 설정 가능하게 유지하면 유연한 운영이 가능합니다.
