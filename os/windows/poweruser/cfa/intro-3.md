영어 Windows OS에서는 **“랜섬웨어 방지” = “Ransomware protection”** 입니다.

화면 경로는 보통 이렇게 표시됩니다.

```text
Windows Security
→ Virus & threat protection
→ Ransomware protection
→ Manage ransomware protection
```

관련 항목의 영어 명칭은 아래처럼 매핑하시면 됩니다.

| 한국어 Windows UI      | 영어 Windows UI                                     |
| ------------------- | ------------------------------------------------- |
| Windows 보안          | **Windows Security**                              |
| 바이러스 및 위협 방지        | **Virus & threat protection**                     |
| 랜섬웨어 방지             | **Ransomware protection**                         |
| 랜섬웨어 보호 관리          | **Manage ransomware protection**                  |
| 제어된 폴더 액세스          | **Controlled folder access**                      |
| 보호된 폴더              | **Protected folders**                             |
| 보호된 폴더 추가           | **Add a protected folder**                        |
| 제어된 폴더 액세스를 통해 앱 허용 | **Allow an app through Controlled folder access** |
| 랜섬웨어 데이터 복구         | **Ransomware data recovery**                      |
| OneDrive 설정         | **Set up OneDrive**                               |

Microsoft의 Windows Security 문서에서도 **Ransomware protection** 섹션에서 **Controlled folder access**, **Protected folders**, **Allow an app through Controlled folder access**, **Ransomware data recovery**라는 명칭을 사용합니다. ([Microsoft 지원][1])

따라서 제품 UI 문구는 아래처럼 쓰면 됩니다.

```text
Ransomware Protection - Controlled Folder Access
```

또는 한글/영문 병기라면:

```text
랜섬웨어 방지(Ransomware protection) - 제어된 폴더 액세스(Controlled folder access)
```

PowerShell 코드에서는 UI 언어와 관계없이 아래 명령 이름은 동일합니다.

```powershell
Set-MpPreference -EnableControlledFolderAccess Enabled
Set-MpPreference -EnableControlledFolderAccess AuditMode
Add-MpPreference -ControlledFolderAccessProtectedFolders "C:\ImportantProjects"
```

Microsoft Learn도 PowerShell에서 `Set-MpPreference -EnableControlledFolderAccess Enabled`를 사용하고, 감사 모드는 `AuditMode` 값을 사용한다고 설명합니다. ([Microsoft Learn][2])

참고로 첨부 문서의 `audit.ps1` 방식은 Windows Security의 **Ransomware protection / Controlled folder access** UI 명칭이 아니라, Windows 파일 시스템 감사 정책과 SACL을 이용한 별도 감사 방식입니다. 

[1]: https://support.microsoft.com/en-us/windows/virus-and-threat-protection-in-the-windows-security-app-1362f4cd-d71a-b52a-0b66-c2820032b65e "Virus and Threat Protection in the Windows Security App - Microsoft Support"
[2]: https://learn.microsoft.com/en-us/defender-endpoint/enable-controlled-folders "Enable controlled folder access - Microsoft Defender for Endpoint | Microsoft Learn"
