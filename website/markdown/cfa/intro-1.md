결론부터 말씀드리면, **방향은 맞지만 첨부 문서만으로는 “Controlled Folder Access 제공”이라고 보기 어렵습니다.** 첨부 문서는 CFA가 아니라 **Windows 파일 시스템 감사 정책 + SACL 감사 규칙**을 설정하는 방식입니다. 즉, **차단은 못 하고, 쓰기/삭제 행위를 Security 이벤트 4663으로 감시**하는 용도입니다. 

Microsoft의 Controlled Folder Access는 랜섬웨어 대응에 적합한 기능이고, 보호 폴더에 대해 악성 또는 의심 앱의 파일 변경을 차단하거나 Audit Mode로 “차단되었을 행위”를 기록할 수 있습니다. 다만 CFA의 `Enabled` / `AuditMode`는 **경로별 설정이 아니라 장치 전체 CFA 모드**입니다. 경로는 보호 대상 목록에 추가하고, 차단/감사 모드는 전체 CFA 동작 모드로 적용됩니다. ([Microsoft Learn][1])

따라서 설계는 이렇게 잡는 것이 좋습니다.

| 사용자에게 제공할 기능 | 내부 구현                                                                                                                      | 로그                                                     |
| ------------ | -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| **Block**    | `Set-MpPreference -EnableControlledFolderAccess Enabled` + `Add-MpPreference -ControlledFolderAccessProtectedFolders <경로>` | Windows Defender Operational, ID **1123**              |
| **Audit**    | CFA 관점이면 `AuditMode`; “모든 파일 변경 감시” 목적이면 SACL 감사 규칙                                                                        | CFA Audit: ID **1124** / SACL 감사: Security ID **4663** |

중요한 차이는 이것입니다. **CFA AuditMode는 모든 파일 변경을 기록하는 기능이 아니라, CFA가 차단했을 의심 앱의 변경 시도를 기록하는 기능**입니다. 반면 첨부 문서 방식의 SACL 감사는 지정 경로에서 Everyone의 쓰기/삭제 권한 사용을 감시하므로 “파일 변경 감시” 목적에는 더 직접적입니다. Microsoft도 CFA 이벤트는 Defender Operational 로그의 1123/1124/5007로 설명하고, 4663은 SACL이 있는 객체에서 특정 접근 권한이 실제 사용될 때 생성되는 Security 이벤트라고 설명합니다. ([Microsoft Learn][2])

아래처럼 **하나의 PowerShell 스크립트로 Block / Audit을 제공**하는 형태를 권장합니다. UI에서는 사용자에게 “차단”과 “감사”만 보여주고, 감사 방식은 목적에 따라 `CFA` 또는 `FileSystem`으로 선택하면 됩니다.

```powershell
# Set-RansomwareFolderProtection.ps1
# 실행 조건: 관리자 권한 PowerShell
# 목적:
#   - Block: Controlled Folder Access로 보호 폴더에 대한 의심 앱 변경 차단
#   - Audit -AuditProvider CFA: CFA AuditMode로 "차단되었을 변경" 기록
#   - Audit -AuditProvider FileSystem: Windows SACL로 해당 경로의 쓰기/삭제 변경 감시

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Block', 'Audit')]
    [string]$Mode,

    [ValidateSet('CFA', 'FileSystem')]
    [string]$AuditProvider = 'CFA',

    # 선택 사항: CFA에서 차단된 정상 업무 앱을 허용할 때 사용
    # 예: "C:\Program Files\MyApp\myapp.exe"
    [string[]]$AllowedApplication
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)

    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "관리자 권한 PowerShell에서 실행해야 합니다."
    }
}

function Resolve-ExistingFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath
    )

    $expandedPath = [Environment]::ExpandEnvironmentVariables($InputPath)

    if (-not (Test-Path -LiteralPath $expandedPath -PathType Container)) {
        throw "폴더 경로를 찾을 수 없습니다: $InputPath"
    }

    return (Resolve-Path -LiteralPath $expandedPath).ProviderPath
}

function Test-PathAlreadyInList {
    param(
        [string[]]$List,
        [string]$Candidate
    )

    $candidateNormalized = $Candidate.TrimEnd('\')

    foreach ($item in @($List)) {
        if ($null -ne $item -and $item.TrimEnd('\') -ieq $candidateNormalized) {
            return $true
        }
    }

    return $false
}

function Add-ControlledFolderAccessPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Folder,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enabled', 'AuditMode')]
        [string]$CfaState,

        [string[]]$AllowedApps
    )

    Import-Module Defender -ErrorAction Stop

    Write-Host "[CFA] Controlled Folder Access mode: $CfaState"
    Set-MpPreference -EnableControlledFolderAccess $CfaState

    $pref = Get-MpPreference

    if (-not (Test-PathAlreadyInList -List $pref.ControlledFolderAccessProtectedFolders -Candidate $Folder)) {
        Write-Host "[CFA] 보호 폴더 추가: $Folder"
        Add-MpPreference -ControlledFolderAccessProtectedFolders $Folder
    }
    else {
        Write-Host "[CFA] 이미 보호 폴더에 등록되어 있습니다: $Folder"
    }

    if ($AllowedApps) {
        foreach ($app in $AllowedApps) {
            $expandedApp = [Environment]::ExpandEnvironmentVariables($app)

            if (-not (Test-Path -LiteralPath $expandedApp -PathType Leaf)) {
                throw "허용 앱 실행 파일을 찾을 수 없습니다: $app"
            }

            $resolvedApp = (Resolve-Path -LiteralPath $expandedApp).ProviderPath
            $pref = Get-MpPreference

            if (-not (Test-PathAlreadyInList -List $pref.ControlledFolderAccessAllowedApplications -Candidate $resolvedApp)) {
                Write-Host "[CFA] 허용 앱 추가: $resolvedApp"
                Add-MpPreference -ControlledFolderAccessAllowedApplications $resolvedApp
            }
            else {
                Write-Host "[CFA] 이미 허용 앱에 등록되어 있습니다: $resolvedApp"
            }
        }
    }
}

function Enable-FileSystemAudit {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Folder
    )

    # Audit File System subcategory GUID
    # 언어별 Windows에서 "File System" / "파일 시스템" 문자열 차이를 피하기 위해 GUID 사용
    $fileSystemAuditSubcategoryGuid = "{0CCE921D-69AE-11D9-BED3-505054503030}"
    $auditpol = Join-Path $env:SystemRoot "System32\auditpol.exe"

    Write-Host "[Audit] File System 감사 정책 활성화"
    & $auditpol /set /subcategory:$fileSystemAuditSubcategoryGuid /success:enable /failure:enable | Out-Host

    if ($LASTEXITCODE -ne 0) {
        throw "auditpol 설정에 실패했습니다. 관리자 권한 또는 보안 정책을 확인하세요."
    }

    Write-Host "[Audit] SACL 감사 규칙 적용: $Folder"

    $acl = Get-Acl -LiteralPath $Folder -Audit

    # Everyone SID. 한국어/영어 OS의 그룹명 차이를 피하기 위해 이름 대신 SID 사용.
    $everyoneSid = New-Object Security.Principal.SecurityIdentifier("S-1-1-0")

    # 랜섬웨어 관점에서 중요한 쓰기/삭제/권한 변경 관련 권한
    $auditRights =
        [Security.AccessControl.FileSystemRights]::Write `
        -bor [Security.AccessControl.FileSystemRights]::Delete `
        -bor [Security.AccessControl.FileSystemRights]::DeleteSubdirectoriesAndFiles `
        -bor [Security.AccessControl.FileSystemRights]::ChangePermissions `
        -bor [Security.AccessControl.FileSystemRights]::TakeOwnership

    $inheritanceFlags =
        [Security.AccessControl.InheritanceFlags]::ContainerInherit `
        -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit

    $propagationFlags = [Security.AccessControl.PropagationFlags]::None
    $auditFlags =
        [Security.AccessControl.AuditFlags]::Success `
        -bor [Security.AccessControl.AuditFlags]::Failure

    $auditRule = New-Object Security.AccessControl.FileSystemAuditRule(
        $everyoneSid,
        $auditRights,
        $inheritanceFlags,
        $propagationFlags,
        $auditFlags
    )

    $existingRules = $acl.GetAuditRules($true, $true, [Security.Principal.SecurityIdentifier])
    $alreadyExists = $false

    foreach ($rule in $existingRules) {
        if (
            $rule.IdentityReference.Value -eq "S-1-1-0" -and
            (($rule.FileSystemRights -band $auditRights) -eq $auditRights) -and
            (($rule.InheritanceFlags -band [Security.AccessControl.InheritanceFlags]::ContainerInherit) -ne 0) -and
            (($rule.InheritanceFlags -band [Security.AccessControl.InheritanceFlags]::ObjectInherit) -ne 0) -and
            (($rule.AuditFlags -band [Security.AccessControl.AuditFlags]::Success) -ne 0)
        ) {
            $alreadyExists = $true
            break
        }
    }

    if (-not $alreadyExists) {
        [void]$acl.AddAuditRule($auditRule)
        Set-Acl -LiteralPath $Folder -AclObject $acl
        Write-Host "[Audit] 감사 규칙이 적용되었습니다."
    }
    else {
        Write-Host "[Audit] 유사한 감사 규칙이 이미 존재합니다."
    }
}

Assert-Administrator
$resolvedFolder = Resolve-ExistingFolder -InputPath $Path

switch ($Mode) {
    'Block' {
        Add-ControlledFolderAccessPath `
            -Folder $resolvedFolder `
            -CfaState 'Enabled' `
            -AllowedApps $AllowedApplication

        [pscustomobject]@{
            Path      = $resolvedFolder
            Mode      = 'Block'
            Engine    = 'Controlled Folder Access'
            EventLog  = 'Microsoft-Windows-Windows Defender/Operational'
            EventId   = '1123 = blocked CFA event, 5007 = setting changed'
        }
    }

    'Audit' {
        if ($AuditProvider -eq 'CFA') {
            Add-ControlledFolderAccessPath `
                -Folder $resolvedFolder `
                -CfaState 'AuditMode' `
                -AllowedApps $AllowedApplication

            [pscustomobject]@{
                Path      = $resolvedFolder
                Mode      = 'Audit'
                Engine    = 'Controlled Folder Access AuditMode'
                EventLog  = 'Microsoft-Windows-Windows Defender/Operational'
                EventId   = '1124 = audited CFA event, 5007 = setting changed'
            }
        }
        else {
            if ($AllowedApplication) {
                Write-Warning "FileSystem 감사 방식에서는 AllowedApplication 옵션을 사용하지 않습니다."
            }

            Enable-FileSystemAudit -Folder $resolvedFolder

            [pscustomobject]@{
                Path      = $resolvedFolder
                Mode      = 'Audit'
                Engine    = 'Windows File System SACL Audit'
                EventLog  = 'Security'
                EventId   = '4663 = object access, write/delete access 확인'
            }
        }
    }
}
```

사용 예시는 다음과 같습니다.

```powershell
# 1) 지정 경로를 CFA 보호 폴더로 추가하고 차단 모드 활성화
.\Set-RansomwareFolderProtection.ps1 `
  -Path "C:\ImportantProjects" `
  -Mode Block

# 2) CFA AuditMode: 차단했을 의심 앱 변경 시도를 기록
.\Set-RansomwareFolderProtection.ps1 `
  -Path "C:\ImportantProjects" `
  -Mode Audit `
  -AuditProvider CFA

# 3) 파일 시스템 감사: 해당 경로의 쓰기/삭제 행위 자체를 Security 로그로 감시
.\Set-RansomwareFolderProtection.ps1 `
  -Path "C:\ImportantProjects" `
  -Mode Audit `
  -AuditProvider FileSystem

# 4) 차단 모드에서 정상 업무 앱을 허용 목록에 추가
.\Set-RansomwareFolderProtection.ps1 `
  -Path "C:\ImportantProjects" `
  -Mode Block `
  -AllowedApplication "C:\Program Files\MyApp\myapp.exe"
```

로그 확인 명령어는 아래처럼 제공하면 됩니다.

```powershell
# CFA 차단/감사 이벤트 확인
Get-WinEvent -LogName 'Microsoft-Windows-Windows Defender/Operational' -MaxEvents 100 |
    Where-Object { $_.Id -in 1123, 1124, 5007 } |
    Select-Object TimeCreated, Id, ProviderName, Message

# SACL 파일 시스템 감사 이벤트 확인
Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    Id        = 4663
    StartTime = (Get-Date).AddHours(-1)
} |
    Where-Object { $_.Message -like '*C:\ImportantProjects*' } |
    Select-Object TimeCreated, Id, ProviderName, Message
```

구현 시 꼭 반영해야 할 주의점은 5가지입니다.

첫째, **`Add-MpPreference`를 사용해야 합니다.** Microsoft 문서도 보호 폴더와 허용 앱을 추가할 때 `Add-MpPreference`를 안내하고, `Set-MpPreference`로 목록을 설정하면 기존 목록을 덮어쓸 수 있다고 설명합니다. 코드에서 `Add-MpPreference -ControlledFolderAccessProtectedFolders`를 사용한 이유가 이것입니다. ([Microsoft Learn][3])

둘째, **CFA의 Block/Audit는 경로별 모드가 아닙니다.** 한 경로는 Block, 다른 경로는 Audit처럼 혼합 운영하려면 CFA만으로는 어렵습니다. 그런 요구가 있다면 “Block은 CFA”, “Audit은 SACL”로 분리하는 편이 맞습니다.

셋째, 첨부 문서의 `Everyone` 문자열은 한국어 Windows/영어 Windows 차이에 영향을 받을 수 있으므로, 실제 제품 코드에서는 `Everyone` 대신 **SID `S-1-1-0`**을 쓰는 편이 안전합니다. 또한 `auditpol /subcategory:"파일 시스템"`도 언어별 차이가 있으므로, 위 코드처럼 **File System 감사 하위 범주 GUID**를 쓰는 방식이 더 안전합니다. Microsoft 문서상 File System 감사 하위 범주 GUID는 `{0CCE921D-69AE-11D9-BED3-505054503030}`입니다. ([Microsoft Learn][4])

넷째, **4663은 “실제 접근 권한이 사용됨”을 보여주는 이벤트**이고, 객체에 필요한 SACL ACE가 있어야 생성됩니다. Microsoft 문서는 4663이 실패 이벤트를 갖지 않는다고 설명하므로, 첨부 문서처럼 Success/Failure를 모두 설정하더라도 실제 분석에서는 4663의 `Accesses`, `Object Name`, `Process Name` 필드를 중심으로 봐야 합니다. 실패 접근까지 정밀히 보려면 4656 같은 관련 이벤트도 함께 설계하는 것이 좋습니다. ([Microsoft Learn][5])

다섯째, **CFA는 모든 쓰기를 무조건 막는 ACL 기능이 아닙니다.** Microsoft Defender가 악성 또는 의심 앱으로 판단한 앱의 보호 폴더 변경을 막는 구조이므로, 정상 앱은 자동 허용될 수 있고, 신뢰 앱이 악용되는 경우에는 별도 탐지 로직이 필요합니다. 허용 앱을 추가할 때도 실행 파일의 전체 경로를 지정해야 하고, Microsoft는 실제로 차단되고 신뢰성을 확인할 수 있는 앱만 추가하라고 권고합니다. ([Microsoft Learn][3])

제 추천은 제품/기능명을 이렇게 나누는 것입니다.

**“랜섬웨어 보호 - 차단”**은 Controlled Folder Access `Enabled`로 구현하고, **“랜섬웨어 보호 - 감사”**는 두 가지 중 하나로 명확히 설명하세요. ASR처럼 “차단 전 영향 평가”가 목적이면 `CFA AuditMode`, 실제 파일 생성/수정/삭제 행위 감시가 목적이면 첨부 문서 기반의 `FileSystem SACL Audit`가 맞습니다.

[1]: https://learn.microsoft.com/en-us/defender-endpoint/enable-controlled-folders "Enable controlled folder access - Microsoft Defender for Endpoint | Microsoft Learn"
[2]: https://learn.microsoft.com/en-us/defender-endpoint/evaluate-controlled-folder-access "Evaluate controlled folder access - Microsoft Defender for Endpoint | Microsoft Learn"
[3]: https://learn.microsoft.com/en-us/defender-endpoint/customize-controlled-folders "Customize controlled folder access - Microsoft Defender for Endpoint | Microsoft Learn"
[4]: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-gpac/77878370-0712-47cd-997d-b07053429f6d "[MS-GPAC]: Subcategory and SubcategoryGUID | Microsoft Learn"
[5]: https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/auditing/event-4663 "4663(S) An attempt was made to access an object. - Windows 10 | Microsoft Learn"
