많은 분들이 Windows를 그냥 “운영체제”로만 쓰지만, 실제로는 Windows 안에 이미 **안티바이러스, 랜섬웨어 방어, 실행 통제, 격리 실행, 백업, 디스크 암호화, 자격증명 보호, 고급 방화벽, 상세 로그**까지 들어 있습니다. Microsoft Defender Antivirus는 Windows에 기본 내장되어 있고, Windows 보안 체계에는 ASR, Controlled Folder Access, BitLocker, Windows Firewall, Credential Guard, Sandbox 같은 기능들이 포함됩니다. ([Microsoft Learn][1])

핵심은 이것입니다.
**일반 사용자는 “백신이 켜져 있나”까지만 보지만, 파워 유저는 “무엇을 막고, 무엇을 기록하고, 무엇을 복구할 수 있는가”까지 관리합니다.**
아래 기능들을 그 기준으로 보시면 좋습니다. ([Microsoft Learn][2])

## 1. Microsoft Defender Antivirus

가장 기본이지만 가장 과소평가되는 기능입니다. Windows 10/11의 핵심 구성요소로 설치되어 있으며, 악성코드 실시간 탐지와 업데이트를 제공합니다. 다른 백신을 설치하면 Defender가 자동으로 비활성화되거나 상태가 바뀔 수 있다는 점도 알아둘 필요가 있습니다. 즉, “무료 기본 백신” 정도로 볼 것이 아니라, **현재 내 PC에서 실제 활성 보호 엔진이 무엇인지** 확인하는 습관이 중요합니다. ([Microsoft Learn][2])

파워 유저 관점에서는 다음을 봐야 합니다.
실시간 보호, 클라우드 제공 보호, 자동 샘플 제출, 보호 기록, 오프라인 검사입니다. 특히 Defender Offline Scan은 부팅 전 또는 일반 실행 상태에서 제거가 어려운 위협을 점검할 때 유용합니다. ([Microsoft Learn][3])

## 2. ASR(Attack Surface Reduction)

ASR은 “악성 파일을 잡는다”보다 한 단계 앞선 기능입니다. 공격자가 자주 쓰는 **위험한 행위 자체**를 줄이는 기능입니다. 예를 들어 Office 매크로, 스크립트 남용, 자격 증명 탈취와 연결되는 행위, LOLBAS류 악용 같은 흐름을 줄이는 데 강합니다. Microsoft도 ASR 규칙은 바로 차단 전에 **Audit mode로 먼저 평가**하라고 권장합니다. ([Microsoft Learn][4])

이 기능이 중요한 이유는, 파워 유저가 되려면 “파일이 악성인지”만 보는 것이 아니라 **공격면 자체를 줄이는 습관**을 가져야 하기 때문입니다.
즉, Defender는 잡는 기능이고, ASR은 애초에 위험한 실행 경로를 좁히는 기능입니다. ([Microsoft Learn][4])

## 3. Controlled Folder Access

이것은 랜섬웨어 대응 관점에서 매우 실용적입니다. 보호된 폴더에 대해 신뢰되지 않거나 의심스러운 앱이 파일을 변경하지 못하게 막아 줍니다. Microsoft 문서도 이 기능을 **랜섬웨어로부터 중요한 데이터를 보호**하는 기능으로 설명합니다. ([Microsoft Learn][5])

일반 사용자는 이 기능을 잘 모르고 지나가지만, 파워 유저는 여기서 한 단계 더 갑니다.
문서, 바탕화면, 프로젝트 폴더, 소스 저장 폴더처럼 중요한 경로를 보호 대상으로 보고, 차단된 앱이 있다면 무조건 끄는 것이 아니라 **정상 업무 앱인지 검토한 후 허용 목록을 관리**합니다. 이것만 해도 랜섬웨어 피해 확률을 크게 낮출 수 있습니다. ([Microsoft Learn][5])

## 4. Sysmon

이건 기본 Windows 보안 UI에서 잘 보이지 않지만, 파워 유저로 가는 데 매우 중요한 도구입니다. Sysmon은 시스템 서비스와 드라이버로 동작하면서 프로세스 생성, 네트워크 연결, 파일 생성 시간 변경 등 상세 활동을 Windows 이벤트 로그에 남깁니다. ([Microsoft Learn][6])

특히 말씀하신 **Sysmon Event ID 27은 FileBlockExecutable**로, 실행 파일(PE 형식) 생성 차단과 관련된 이벤트입니다. 2026년 2월 기준 문서에서는 Sysmon이 Windows 11의 기본 선택 기능으로도 제공되기 시작했다고 안내하고 있습니다. ([Microsoft Learn][6])

다만 Sysmon은 백신처럼 “알아서 다 막아주는 제품”이 아닙니다.
**기록과 가시성의 도구**에 가깝습니다. 그래서 일반 사용자는 잘 안 쓰지만, 파워 유저는 Sysmon을 통해 “무슨 실행이 있었는지, 누가 만들었는지, 어디와 통신했는지”를 더 깊게 봅니다. ([Microsoft Learn][7])

## 5. VSS(Volume Shadow Copy Service)

VSS는 Windows 백업·복원 쪽에서 아주 중요합니다. VSS는 특정 시점의 일관된 스냅샷을 만들기 위해 requester, writer, provider가 협력하도록 조정합니다. 백업, 복구, 시스템 상태 보존에 활용됩니다. ([Microsoft Learn][8])

많은 사용자가 “백업 프로그램이 따로 해야 하는 것”으로만 생각하지만, Windows는 이미 이런 스냅샷 기반 구조를 갖고 있습니다. 파워 유저라면 단순히 VSS가 있는지 아는 데서 끝나지 말고,
**복원 지점이 실제로 생성되는지, Shadow Copy가 가능한 볼륨이 무엇인지, 랜섬웨어 이후 복구 관점에서 어떤 한계가 있는지**까지 이해해야 합니다. VSS는 복구에 매우 유용하지만, 이것만으로 완전한 백업 전략이 되지는 않습니다. ([Microsoft Learn][8])

## 6. Windows Sandbox

이건 정말 “파워 유저용 기본기”라고 봐도 됩니다. Windows Sandbox는 하이퍼바이저 기반 가상화로 호스트와 격리된 가벼운 임시 데스크톱 환경을 제공합니다. 의심스러운 실행 파일, 설치 프로그램, 스크립트, 문서를 본 시스템에서 바로 열지 않고 먼저 시험해볼 수 있습니다. 닫으면 상태가 사라지는 일회용 VM 성격도 큽니다. ([Microsoft Learn][9])

이 기능을 아는 사람과 모르는 사람의 차이는 큽니다.
일반 사용자는 “다운로드했으니 그냥 실행”하지만, 파워 유저는 “출처가 애매하면 Sandbox에서 먼저 본다”로 바뀝니다. 이것만 실천해도 사고 확률이 크게 줄어듭니다. ([Microsoft Learn][9])

## 7. AppLocker / WDAC

이건 한 단계 더 높은 실행 통제입니다. AppLocker는 실행 파일, 스크립트, MSI, DLL, 패키지 앱 등 **무엇을 실행할 수 있는지** 통제하는 기능입니다. ([Microsoft Learn][10])

일반 사용자는 악성코드를 “탐지”하려고만 하지만, 파워 유저는 아예 **허용된 것만 실행되게 하는 방향**으로 생각합니다.
특히 업무용 PC, 키오스크, 관리자용 워크스테이션, 서버 운영 환경에서는 이런 실행 통제가 백신보다 더 강력한 방어선이 될 수 있습니다. ASR이 위험 행위를 줄이는 것이라면, AppLocker/WDAC는 **실행 자체를 통제**하는 쪽입니다. ([Microsoft Learn][10])

## 8. BitLocker

BitLocker는 디스크 암호화입니다. 노트북 분실, 저장장치 도난, 오프라인 디스크 탈취 상황에서 데이터를 보호하는 데 매우 중요합니다. Windows 보안 문서와 Microsoft 학습 자료에서도 핵심 보안 기능으로 다룹니다. ([Microsoft Learn][11])

많은 사람이 악성코드만 보안이라고 생각하지만, 실제로는 **장비 분실**도 큰 사고입니다.
파워 유저는 “백신 설치”만이 아니라 “디스크를 뽑아도 읽을 수 없게 하는가”까지 챙깁니다. 특히 노트북 사용자라면 BitLocker는 거의 필수에 가깝습니다. ([Microsoft Learn][11])

## 9. Credential Guard

Credential Guard는 NTLM 해시, Kerberos TGT 등 중요한 인증 비밀을 VBS(가상화 기반 보안)로 격리해 자격 증명 탈취 공격을 어렵게 만듭니다. Microsoft는 pass-the-hash, pass-the-ticket 같은 공격을 막는 방향으로 설명합니다. ([Microsoft Learn][12])

이건 일반 사용자보다, 관리자 계정이나 원격 접속을 자주 쓰는 사람에게 더 중요합니다.
파워 유저는 “로그인만 되면 됐다”가 아니라, **내 자격 증명이 메모리에서 쉽게 털릴 수 있는 구조인가**를 봐야 합니다. ([Microsoft Learn][12])

## 10. Windows Firewall with Advanced Security

대부분은 방화벽을 켜고 끄는 정도만 생각하지만, 고급 방화벽은 **인바운드/아웃바운드 규칙, 포트, 프로토콜, 프로그램 단위 제어**까지 가능합니다. Microsoft 보안 문서도 Windows Firewall을 핵심 보안 기능군에 포함합니다. ([Microsoft Learn][13])

파워 유저는 여기서 달라집니다.
“필요한 프로그램만 통신 허용”, “원치 않는 아웃바운드 차단”, “테스트용 툴의 외부 통신 제한” 같은 식으로 씁니다. 백신은 감염 후 탐지일 수 있지만, 방화벽은 **통신 단계에서 끊는 힘**이 있습니다. ([Microsoft Learn][13])

## 11. SmartScreen

SmartScreen은 다운로드 파일, 웹사이트, 앱 실행 시 평판 기반 경고를 제공하는 보안 기능입니다. Windows 보안 기능 인덱스에도 주요 기능으로 포함되어 있습니다. ([Microsoft Learn][14])

이 기능은 종종 “귀찮은 경고창”으로 오해받지만, 실제로는 사용자 실수를 줄여주는 마지막 안전장치입니다.
파워 유저는 경고를 무조건 끄지 않고, **왜 경고가 떴는지**를 보는 습관을 갖습니다. ([Microsoft Learn][14])

## 12. Windows LAPS

Windows LAPS는 각 PC의 로컬 관리자 암호를 랜덤하게 다르게 만들고 주기적으로 회전시키는 기능입니다. Microsoft는 공통 로컬 관리자 계정을 동일 암호로 운영하는 문제를 해결하는 기능으로 설명합니다. ([Microsoft Learn][15])

이건 개인 PC보다 조직 환경에서 특히 중요합니다.
여러 대의 PC가 동일한 로컬 관리자 암호를 쓰면 한 대가 털렸을 때 횡적으로 번지기 쉽습니다. 파워 유저, 특히 운영자라면 꼭 알아야 할 기능입니다. ([Microsoft Learn][15])

---

## 일반 사용자가 파워 유저로 올라갈 때의 추천 순서

가장 현실적인 순서는 이렇습니다.

1. **Defender 상태 확인**
   실시간 보호, 업데이트, 보호 기록부터 제대로 보는 습관을 들입니다. ([Microsoft Learn][2])

2. **Controlled Folder Access 사용**
   중요 문서 폴더를 보호 대상으로 보고, 업무 앱 예외를 관리합니다. ([Microsoft Learn][5])

3. **Windows Sandbox 익히기**
   출처가 애매한 파일은 본 시스템이 아니라 Sandbox에서 먼저 실행합니다. ([Microsoft Learn][9])

4. **BitLocker 켜기**
   노트북이나 이동식 업무 장비라면 우선순위가 높습니다. ([Microsoft Learn][11])

5. **ASR과 방화벽 고급 규칙 이해**
   단순 탐지가 아니라 공격면 축소와 통신 통제 관점으로 넘어갑니다. ([Microsoft Learn][4])

6. **Sysmon과 감사 로그 보기 시작**
   여기서부터는 “사용자”에서 “운영자”로 넘어갑니다. ([Microsoft Learn][7])

7. **AppLocker/WDAC, Credential Guard, LAPS**
   이 단계는 고급 사용자나 관리자 수준입니다. ([Microsoft Learn][10])

---

## 한 문장으로 정리하면

Windows는 이미 많은 보안 기능을 무료 또는 기본 포함 형태로 제공합니다.
문제는 기능이 없는 것이 아니라, **대부분이 켜져 있는지, 어떻게 동작하는지, 어디까지 관리해야 하는지 잘 모른다는 점**입니다. Defender는 시작점이고, ASR·CFA·Sandbox·BitLocker·Sysmon·VSS·Credential Guard·AppLocker까지 이해하면 일반 사용자를 넘어 꽤 강한 파워 유저 수준으로 올라갈 수 있습니다. ([Microsoft Learn][1])

원하시면 다음 답변에서
**“Windows 파워 유저 필수 기능 12개”** 형식으로 블로그용 문체로 다시 정리해 드리겠습니다.

[1]: https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-antivirus-windows?utm_source=chatgpt.com "Microsoft Defender Antivirus in Windows Overview"
[2]: https://learn.microsoft.com/en-us/defender-endpoint/deploy-manage-report-microsoft-defender-antivirus?utm_source=chatgpt.com "Deploy, manage, and report on Microsoft Defender Antivirus"
[3]: https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-offline?utm_source=chatgpt.com "Microsoft Defender Offline scan in Windows"
[4]: https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction?utm_source=chatgpt.com "Attack surface reduction rules overview"
[5]: https://learn.microsoft.com/en-us/defender-endpoint/controlled-folders?utm_source=chatgpt.com "Protect important folders with controlled folder access"
[6]: https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon?utm_source=chatgpt.com "Sysmon - Sysinternals"
[7]: https://learn.microsoft.com/ko-kr/sysinternals/downloads/sysmon?utm_source=chatgpt.com "Sysmon - Sysinternals"
[8]: https://learn.microsoft.com/en-us/windows-server/storage/file-server/volume-shadow-copy-service?utm_source=chatgpt.com "Volume Shadow Copy Service (VSS)"
[9]: https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/?utm_source=chatgpt.com "Windows Sandbox"
[10]: https://learn.microsoft.com/en-us/windows/security/application-security/application-control/app-control-for-business/applocker/applocker-overview?utm_source=chatgpt.com "AppLocker"
[11]: https://learn.microsoft.com/id-id/windows/security/?view=azurermps-4.4.0&utm_source=chatgpt.com "Windows security documentation"
[12]: https://learn.microsoft.com/en-us/windows/security/identity-protection/credential-guard/?utm_source=chatgpt.com "Credential Guard overview"
[13]: https://learn.microsoft.com/en-us/windows/security/?utm_source=chatgpt.com "Windows security documentation"
[14]: https://learn.microsoft.com/en-us/windows/security/book/features-index?utm_source=chatgpt.com "Windows 11 security book - Features index"
[15]: https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-overview?utm_source=chatgpt.com "Windows LAPS overview"
