PowerShell을 사용하면 GUI에서 수십 번 클릭해야 하는 과정을 단 한 줄의 명령어로 끝낼 수 있습니다. 이 스크립트는 지정된 경로에 대해 **'Everyone'** 그룹이 수행하는 **'쓰기, 삭제'** 등의 활동을 감시하도록 설정합니다.

스크립트를 작성하기 전, 반드시 **PowerShell을 관리자 권한으로 실행**해야 한다는 점을 기억해 주세요.

---

## 1. PowerShell 감사 규칙 설정 스크립트 (audit.ps1)

아래 코드를 복사하여 `audit.ps1` 파일로 저장하세요.

```powershell
# audit.ps1
param (
    [Parameter(Mandatory=$true)]
    [string]$Path
)

# 1. 경로 존재 여부 확인
if (-not (Test-Path $Path)) {
    Write-Host "오류: 경로 '$Path'를 찾을 수 없습니다." -ForegroundColor Red
    exit
}

# 2. 현재 폴더의 보안 설정(ACL) 가져오기
$Acl = Get-Acl -Path $Path -Audit

# 3. 감사 규칙 정의
# 대상: Everyone (모든 사용자)
# 권한: Write, Delete, DeleteSubdirectoriesAndFiles (쓰기 및 삭제 관련)
# 상속: ContainerInherit, ObjectInherit (하위 폴더 및 파일 모두 포함)
# 유형: Success, Failure (성공과 실패 모두 기록)
$TargetUser = "Everyone"
$AuditRights = "Write, Delete, DeleteSubdirectoriesAndFiles"
$InheritanceFlag = "ContainerInherit, ObjectInherit"
$PropagationFlag = "None"
$AuditType = "Success, Failure"

$AuditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
    $TargetUser, 
    $AuditRights, 
    $InheritanceFlag, 
    $PropagationFlag, 
    $AuditType
)

# 4. ACL에 감사 규칙 추가
$Acl.SetAuditRule($AuditRule)

# 5. 변경된 ACL 적용
Set-Acl -Path $Path -AclObject $Acl

Write-Host "'$Path' 경로에 대한 감사 규칙이 성공적으로 적용되었습니다." -ForegroundColor Green
Write-Host "이제 이벤트 뷰어(ID 4663)에서 로그를 확인할 수 있습니다." -ForegroundColor Cyan
```

---

## 2. 사용 방법

1.  **관리자 권한**으로 PowerShell 터미널을 엽니다.
2.  스크립트가 있는 폴더로 이동합니다.
3.  다음과 같이 실행합니다 (경로에 공백이 있을 수 있으므로 따옴표를 권장합니다).

```powershell
.\audit.ps1 "C:\ImportantProjects"
```

---

## 3. 스크립트 동작 원리 설명

* **`Get-Acl -Audit`**: 일반적인 접근 권한이 아닌 '감사(Audit)' 항목을 가져옵니다.
* **`FileSystemAuditRule` 객체**: 윈도우 보안 엔진에 "누구를(Everyone), 어떤 행위를(Write/Delete), 하위까지 포함해서(Inherit), 성공/실패 여부(All)"를 기록하라고 정의하는 핵심 객체입니다.
* **`Set-Acl`**: 정의된 규칙을 실제 파일 시스템에 물리적으로 적용합니다.

---

## 4. 실행 전 체크리스트

이 스크립트가 효과를 발휘하려면 **이전 답변에서 설정한 '시스템 감사 정책'이 켜져 있어야 합니다.** 만약 명령어로 한 번에 해결하고 싶다면, 스크립트 실행 전 PowerShell에서 다음 명령어를 한 번 더 실행해 주세요.

```powershell
# 시스템의 파일 감사 정책을 '성공 및 실패'로 활성화 (관리자 권한 필요)
auditpol /set /subcategory:"파일 시스템" /success:enable /failure:enable
```

이제 특정 폴더에서 파일이 수정되거나 삭제될 때마다 **이벤트 뷰어 > Windows 로그 > 보안 > 이벤트 ID 4663**에서 범인(?)의 프로세스 이름과 계정명을 확인할 수 있습니다.

스크립트 적용 후 실제로 테스트 삼아 파일을 하나 생성했다가 지워보시겠어요? 로그가 잘 남는지 확인해 드릴까요?
