네, 맞습니다. **스크린샷의 “랜섬웨어 방지 → 제어된 폴더 액세스 → 보호된 폴더” 화면을 `Set-RansomwareFolderProtection.ps1`로 PowerShell에서 관리하는 구조**라고 이해하시면 됩니다.

다만 한 가지 짚고 넘어가야 합니다. 첫 번째 캡처에서는 **“제어된 폴더 액세스: 끔”**으로 보입니다. 즉, 두 번째 화면에 `Documents`, `Pictures`, `Videos` 같은 **보호된 폴더 목록이 표시되는 것**과, 실제 차단 기능이 **켜져 있는 것**은 다릅니다. 실제 차단은 제어된 폴더 액세스가 **켬** 상태이거나 PowerShell에서 `Enabled`로 설정되어야 동작합니다.

정리하면 이렇게 매핑됩니다.

| Windows 보안 화면           | PowerShell / 스크립트 역할                                                            |
| ----------------------- | ------------------------------------------------------------------------------- |
| **제어된 폴더 액세스 켬/끔**      | `Set-MpPreference -EnableControlledFolderAccess Enabled / Disabled / AuditMode` |
| **보호된 폴더 추가**           | `Add-MpPreference -ControlledFolderAccessProtectedFolders "<경로>"`               |
| **제어된 폴더 액세스를 통해 앱 허용** | `Add-MpPreference -ControlledFolderAccessAllowedApplications "<exe 경로>"`        |
| **차단 이벤트 확인**           | Defender Operational 로그, 이벤트 ID 1123                                            |
| **감사 이벤트 확인**           | Defender Operational 로그, 이벤트 ID 1124                                            |
| **설정 변경 확인**            | Defender Operational 로그, 이벤트 ID 5007                                            |

Microsoft 문서에서도 CFA는 의심스럽거나 악성으로 판단된 앱이 보호된 폴더의 파일을 변경하지 못하게 하는 기능이며, PowerShell에서는 `Set-MpPreference -EnableControlledFolderAccess Enabled` 또는 `AuditMode`로 설정한다고 설명합니다. 또한 이벤트 로그는 1123, 1124, 5007을 기준으로 확인합니다. ([Microsoft Learn][1])

따라서 사용자가 경로를 입력했을 때 차단 모드를 제공하려면 아래처럼 이해하면 됩니다.

```powershell
.\Set-RansomwareFolderProtection.ps1 `
  -Path "C:\ImportantProjects" `
  -Mode Block
```

이 명령은 내부적으로 이런 동작을 하는 것입니다.

```powershell
Set-MpPreference -EnableControlledFolderAccess Enabled
Add-MpPreference -ControlledFolderAccessProtectedFolders "C:\ImportantProjects"
```

실행 후 Windows 보안 UI에서는 다음처럼 보이는 것이 정상입니다.

```text
랜섬웨어 방지
 └─ 제어된 폴더 액세스: 켬

보호된 폴더
 ├─ Documents
 ├─ Pictures
 ├─ Videos
 └─ C:\ImportantProjects
```

보호 폴더 추가는 Windows 보안 앱에서도 할 수 있고, PowerShell에서는 `Add-MpPreference -ControlledFolderAccessProtectedFolders`를 사용합니다. Microsoft 문서도 기본 보호 폴더 외에 추가 폴더를 보호할 수 있으며, PowerShell로 추가한 보호 폴더는 Windows 보안 앱에 표시된다고 설명합니다. 특히 목록 추가 시에는 기존 목록을 덮어쓰지 않도록 `Set-MpPreference`가 아니라 `Add-MpPreference`를 사용하라고 안내합니다. ([Microsoft Learn][2])

감사 모드는 두 가지로 구분해서 보셔야 합니다.

첫 번째는 **CFA AuditMode**입니다.

```powershell
.\Set-RansomwareFolderProtection.ps1 `
  -Path "C:\ImportantProjects" `
  -Mode Audit `
  -AuditProvider CFA
```

이 경우 내부적으로는 다음과 같습니다.

```powershell
Set-MpPreference -EnableControlledFolderAccess AuditMode
Add-MpPreference -ControlledFolderAccessProtectedFolders "C:\ImportantProjects"
```

이 방식은 **“CFA가 켜져 있었다면 차단했을 의심 앱의 변경 시도”**를 기록하는 방식입니다. 즉, 모든 파일 수정 행위를 감시하는 기능은 아닙니다.

두 번째는 **파일 시스템 감사, 즉 SACL Audit**입니다.

```powershell
.\Set-RansomwareFolderProtection.ps1 `
  -Path "C:\ImportantProjects" `
  -Mode Audit `
  -AuditProvider FileSystem
```

이 방식은 스크린샷의 Windows 보안 CFA 화면에는 표시되지 않습니다. 대신 지정 경로에 감사 규칙을 걸고, 파일 쓰기/삭제 같은 행위를 **Security 로그의 이벤트 ID 4663**으로 감시합니다. 첨부 문서의 `audit.ps1` 방식이 바로 이쪽이며, `Get-Acl -Audit`, `FileSystemAuditRule`, `Set-Acl`, `auditpol /set /subcategory:"파일 시스템"`을 사용해 파일 변경 감사를 설정하는 구조입니다. 

그래서 제품 기능으로는 이렇게 나누는 것이 가장 정확합니다.

```text
1. 차단 모드
   - 이름: 랜섬웨어 보호 - 제어된 폴더 액세스 차단
   - 구현: CFA Enabled + 보호 폴더 추가
   - UI 반영: Windows 보안 > 보호된 폴더 목록에 표시됨

2. CFA 감사 모드
   - 이름: 랜섬웨어 보호 - 제어된 폴더 액세스 감사
   - 구현: CFA AuditMode + 보호 폴더 추가
   - 목적: 차단 전 영향 평가
   - 로그: Defender Operational 1124

3. 파일 변경 감사 모드
   - 이름: 파일 시스템 변경 감사
   - 구현: auditpol + SACL
   - 목적: 지정 경로의 쓰기/삭제 행위 감시
   - 로그: Security 4663
   - UI 반영: Windows 보안 CFA 화면에는 표시되지 않음
```

중요한 제약도 있습니다. **CFA의 Enabled / AuditMode는 경로별 설정이 아니라 전체 CFA 기능의 동작 모드**입니다. 즉, `C:\A`는 차단, `D:\B`는 CFA 감사처럼 경로별로 CFA 모드를 다르게 주기는 어렵습니다. 그런 요구가 있으면 `C:\A`는 CFA 차단으로 관리하고, `D:\B`는 SACL 기반 파일 시스템 감사로 관리하는 구조가 더 맞습니다.

현재 스크린샷 기준으로 보면, `Set-RansomwareFolderProtection.ps1`은 아래 두 영역을 관리하는 코드입니다.

```text
관리 대상:
- 제어된 폴더 액세스 켬/끔/감사 모드
- 보호된 폴더 목록
- 허용 앱 목록

관리 대상 아님:
- OneDrive 랜섬웨어 데이터 복구 설정
- 일반 Windows 파일 권한 ACL
- 모든 파일 변경 이벤트 수집
```

설정 확인은 아래 명령으로 할 수 있습니다.

```powershell
# CFA 상태 확인
(Get-MpPreference).EnableControlledFolderAccess

# 보호된 폴더 목록 확인
(Get-MpPreference).ControlledFolderAccessProtectedFolders

# CFA 허용 앱 목록 확인
(Get-MpPreference).ControlledFolderAccessAllowedApplications
```

운영 관점의 최종 이해는 이렇게 보시면 됩니다.

```text
사용자에게 경로 입력 받음
        ↓
Block 선택
        ↓
CFA를 켜고 해당 경로를 “보호된 폴더”에 추가
        ↓
Windows 보안 UI의 보호된 폴더 목록에서 확인 가능
        ↓
의심 앱의 변경 시도는 차단되고 1123 이벤트 발생
```

그리고 Audit 선택 시에는 목적에 따라 나눕니다.

```text
CFA 차단 전 영향 평가 목적
→ AuditProvider CFA

실제 파일 쓰기/삭제 행위 감시 목적
→ AuditProvider FileSystem
```

따라서 질문하신 이해는 맞습니다. **단, “보호된 폴더 목록 관리 = CFA 관리”는 맞지만, “모든 파일 변경 감시”까지 CFA 하나로 처리된다고 보면 안 됩니다.** CFA는 랜섬웨어 차단/차단 전 평가용이고, 파일 변경 행위 감시는 별도의 SACL 감사 기능으로 분리하는 것이 맞습니다.

[1]: https://learn.microsoft.com/en-us/defender-endpoint/evaluate-controlled-folder-access?utm_source=chatgpt.com "Evaluate controlled folder access"
[2]: https://learn.microsoft.com/ko-kr/defender-endpoint/customize-controlled-folders?utm_source=chatgpt.com "제어된 폴더 액세스 사용자 지정"
