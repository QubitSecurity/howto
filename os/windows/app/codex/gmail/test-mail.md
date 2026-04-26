# PLURA-XDR AI Agent SMTP 메일 발송 테스트 가이드

## 1. 목적

이 문서는 PLURA-XDR AI Agent에서 생성한 Gmail 보고서를 실제 메일로 발송하기 전에, SMTP 설정이 정상 동작하는지 PowerShell 테스트 스크립트로 검증하는 절차를 정리한 문서입니다.

현재 자동화 흐름은 다음 단계로 구성됩니다.

```text
PLURA-XDR 탐지 수집
→ AI 분석 결과 생성
→ Gmail 보고서 제목/본문/payload 생성
→ SMTP 설정 검증
→ dry-run 또는 실제 메일 발송
````

메일이 실제로 발송되려면 다음 조건이 필요합니다.

```text
GMAIL_ENABLED=true
GMAIL_DRY_RUN=false
GMAIL_TO=수신자 이메일
SMTP_HOST 설정
SMTP_PORT 설정
SMTP_SECURE 설정
SMTP_USER 설정
SMTP_PASS 설정
SMTP_FROM 설정
```

---

## 2. `.env` 설정

프로젝트 루트의 `.env` 파일에 Gmail 보고서 설정과 SMTP 설정을 추가합니다.

파일 위치:

```text
C:\git\quark\quark\.env
```

예시:

```env
# Gmail report
GMAIL_ENABLED=true
GMAIL_DRY_RUN=false
GMAIL_TO=joo@qubitsec.com
GMAIL_CC=
GMAIL_BCC=
GMAIL_SUBJECT_PREFIX=[PLURA-XDR]
GMAIL_FROM_NAME=PLURA-XDR AI Agent
GMAIL_SEND_ON_RISK=높음
GMAIL_INCLUDE_JSON_ATTACHMENT=true
GMAIL_INCLUDE_SCREENSHOT_PATHS=true

# SMTP settings
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=true
SMTP_USER=qubitsec@gmail.com
SMTP_PASS=google-app-password
SMTP_FROM=qubitsec@gmail.com
```

> 주의
> `SMTP_PASS`에는 Gmail 웹 로그인 비밀번호를 넣으면 안 됩니다.
> Gmail SMTP를 사용할 경우 Google 계정에서 발급한 **앱 비밀번호(App Password)** 를 넣어야 합니다.

---

## 3. Gmail 앱 비밀번호 준비

Gmail SMTP 인증에는 일반 로그인 비밀번호가 아니라 앱 비밀번호가 필요합니다.

### 3.1 앱 비밀번호 생성 경로

Google 계정에서 다음 경로로 이동합니다.

```text
Google 계정 관리
→ 보안
→ Google에 로그인하는 방법
→ 2단계 인증
→ 앱 비밀번호
```

### 3.2 생성 방법

1. SMTP 발송 계정으로 Google 계정에 로그인합니다.
2. 2단계 인증이 꺼져 있으면 먼저 활성화합니다.
3. `앱 비밀번호` 메뉴로 이동합니다.
4. 앱 이름을 입력합니다.

예:

```text
PLURA-XDR SMTP
```

5. 생성된 16자리 앱 비밀번호를 복사합니다.
6. `.env`의 `SMTP_PASS`에 입력합니다.

앱 비밀번호가 다음처럼 공백 포함 형태로 표시될 수 있습니다.

```text
abcd efgh ijkl mnop
```

`.env`에는 공백 없이 넣는 것을 권장합니다.

```env
SMTP_PASS=abcdefghijklmnop
```

또는 공백을 유지하려면 따옴표로 감쌉니다.

```env
SMTP_PASS="abcd efgh ijkl mnop"
```

---

## 4. SMTP 테스트 PowerShell 스크립트

프로젝트 루트에 다음 파일을 생성합니다.

```text
C:\git\quark\quark\test-smtp-mail.ps1
```

스크립트 내용:

```powershell
# test-smtp-mail.ps1
# Purpose: Test real SMTP mail sending using .env settings
# Recommended for Gmail: SMTP_PORT=587, SMTP_SECURE=true

param(
    [string]$EnvPath = ".env",
    [string]$To = "",
    [switch]$ForcePort465
)

$ErrorActionPreference = "Stop"

# Force TLS 1.2 for older Windows PowerShell environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Read-DotEnv {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw ".env file not found: $Path"
    }

    $map = @{}

    Get-Content $Path -Encoding UTF8 | ForEach-Object {
        $line = $_.Trim()

        if ([string]::IsNullOrWhiteSpace($line)) {
            return
        }

        if ($line.StartsWith("#")) {
            return
        }

        $idx = $line.IndexOf("=")
        if ($idx -lt 1) {
            return
        }

        $key = $line.Substring(0, $idx).Trim()
        $value = $line.Substring($idx + 1).Trim()

        # Remove surrounding quotes if present
        if (
            ($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))
        ) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        $map[$key] = $value
    }

    return $map
}

function Require-Value {
    param(
        [hashtable]$Config,
        [string]$Name
    )

    if (-not $Config.ContainsKey($Name) -or [string]::IsNullOrWhiteSpace($Config[$Name])) {
        throw "Missing required .env value: $Name"
    }

    return $Config[$Name]
}

$config = Read-DotEnv -Path $EnvPath

$smtpHost = Require-Value $config "SMTP_HOST"
$smtpPort = [int](Require-Value $config "SMTP_PORT")
$smtpSecureRaw = Require-Value $config "SMTP_SECURE"
$smtpUser = Require-Value $config "SMTP_USER"
$smtpPass = Require-Value $config "SMTP_PASS"
$smtpFrom = Require-Value $config "SMTP_FROM"

# Gmail + Send-MailMessage compatibility note:
# Send-MailMessage works more reliably with Gmail on 587 + STARTTLS.
# Port 465 is implicit SSL and may fail with "net_io_connectionclosed".
if ($smtpHost -eq "smtp.gmail.com" -and $smtpPort -eq 465 -and -not $ForcePort465) {
    Write-Host "WARNING: smtp.gmail.com:465 may fail with Send-MailMessage."
    Write-Host "Switching test port to 587 with TLS for this test."
    Write-Host "To force 465 anyway, run with -ForcePort465."
    $smtpPort = 587
    $smtpSecureRaw = "true"
}

if ([string]::IsNullOrWhiteSpace($To)) {
    if ($config.ContainsKey("GMAIL_TO") -and -not [string]::IsNullOrWhiteSpace($config["GMAIL_TO"])) {
        $To = ($config["GMAIL_TO"].Split(",") | Select-Object -First 1).Trim()
    }
}

if ([string]::IsNullOrWhiteSpace($To)) {
    throw "Recipient is empty. Set GMAIL_TO in .env or run with -To someone@example.com"
}

$enableSsl = $false
if ($smtpSecureRaw.ToLower() -eq "true") {
    $enableSsl = $true
}

$subject = "[PLURA-XDR] SMTP mail test - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

$body = @"
PLURA-XDR SMTP mail test

This is a test email from test-smtp-mail.ps1.

SMTP_HOST: $smtpHost
SMTP_PORT: $smtpPort
SMTP_SECURE: $smtpSecureRaw
SMTP_USER: $smtpUser
SMTP_FROM: $smtpFrom
TO: $To

SentAt: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

Write-Host "SMTP test mail sending..."
Write-Host "HOST: $smtpHost"
Write-Host "PORT: $smtpPort"
Write-Host "SSL : $enableSsl"
Write-Host "FROM: $smtpFrom"
Write-Host "TO  : $To"

$securePassword = ConvertTo-SecureString $smtpPass -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($smtpUser, $securePassword)

try {
    Send-MailMessage `
        -SmtpServer $smtpHost `
        -Port $smtpPort `
        -UseSsl:$enableSsl `
        -Credential $credential `
        -From $smtpFrom `
        -To $To `
        -Subject $subject `
        -Body $body `
        -Encoding UTF8

    Write-Host "SMTP test mail sent successfully."
}
catch {
    Write-Host "SMTP test mail failed."
    Write-Host "Error:"
    Write-Host $_.Exception.Message

    if ($smtpHost -eq "smtp.gmail.com") {
        Write-Host ""
        Write-Host "Gmail SMTP checklist:"
        Write-Host "1. Use SMTP_PORT=587 and SMTP_SECURE=true for this PowerShell test."
        Write-Host "2. SMTP_USER must be the full Gmail address."
        Write-Host "3. SMTP_PASS must be a Google App Password, not the normal Gmail login password."
        Write-Host "4. The Gmail account must have 2-Step Verification enabled to create an App Password."
    }

    throw
}
```

---

## 5. SMTP 테스트 실행

프로젝트 루트로 이동합니다.

```powershell
cd C:\git\quark\quark
```

테스트 메일을 발송합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\test-smtp-mail.ps1
```

수신자를 직접 지정하려면 다음처럼 실행합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\test-smtp-mail.ps1 -To joo@qubitsec.com
```

성공 시 다음 메시지가 출력됩니다.

```text
SMTP test mail sent successfully.
```

---

## 6. 주요 오류와 해결 방법

### 6.1 465 포트 연결 오류

오류 예시:

```text
전송 연결 net_io_connectionclosed에서 데이터를 읽을 수 없습니다.
```

원인:

```text
PowerShell Send-MailMessage가 Gmail 465 implicit SSL 방식과 호환되지 않는 경우 발생할 수 있습니다.
```

해결:

```env
SMTP_PORT=587
SMTP_SECURE=true
```

Gmail 테스트에서는 587 + TLS를 우선 사용합니다.

---

### 6.2 Authentication Required 오류

오류 예시:

```text
5.7.0 Authentication Required
```

원인:

```text
SMTP_USER 또는 SMTP_PASS 인증 실패
```

확인 항목:

```text
1. SMTP_USER가 전체 Gmail 주소인지 확인
2. SMTP_PASS가 Gmail 웹 로그인 비밀번호가 아니라 앱 비밀번호인지 확인
3. Google 계정에 2단계 인증이 켜져 있는지 확인
4. 앱 비밀번호를 새로 발급했는지 확인
```

정상 예시:

```env
SMTP_USER=qubitsec@gmail.com
SMTP_PASS=앱비밀번호16자리
SMTP_FROM=qubitsec@gmail.com
```

---

### 6.3 Dry Run 때문에 실제 발송되지 않는 경우

`GMAIL_DRY_RUN=true`이면 실제 발송하지 않습니다.

```env
GMAIL_DRY_RUN=true
```

이 경우 결과 파일에는 다음처럼 기록됩니다.

```json
{
  "attempted": true,
  "sent": false,
  "skippedReason": "GMAIL_DRY_RUN=true 이므로 실제 전송하지 않았습니다."
}
```

실제 발송하려면 다음처럼 변경합니다.

```env
GMAIL_DRY_RUN=false
```

PowerShell로 변경할 경우:

```powershell
$envPath = "C:\git\quark\quark\.env"

$content = Get-Content $envPath -Raw -Encoding UTF8
$content = $content -replace '(?m)^GMAIL_DRY_RUN\s*=\s*true\s*$', 'GMAIL_DRY_RUN=false'

[System.IO.File]::WriteAllText(
  $envPath,
  $content,
  [System.Text.UTF8Encoding]::new($true)
)
```

확인:

```powershell
Get-Content .env -Encoding UTF8 | Select-String "GMAIL_DRY_RUN"
```

기대 출력:

```env
GMAIL_DRY_RUN=false
```

---

## 7. PLURA-XDR AI Agent 메일 발송 확인

SMTP 테스트가 성공하면 PLURA-XDR AI Agent 자동화를 실행합니다.

```powershell
npm run plura:mitre
```

실행 후 최종 결과 파일을 확인합니다.

```text
C:\git\quark\quark\artifacts\result.json
```

PowerShell 확인 명령:

```powershell
Get-Content .\artifacts\result.json -Encoding UTF8 | Select-String '"gmail"' -Context 0,120
```

또는 메일 발송 결과만 확인합니다.

```powershell
Get-Content .\artifacts\result.json -Encoding UTF8 | Select-String '"result"' -Context 0,40
```

성공 기준:

```json
{
  "enabled": true,
  "dryRun": false,
  "attempted": true,
  "sent": true
}
```

---

## 8. 생성되는 보고서 파일

자동화 실행 후 다음 파일이 생성됩니다.

```text
artifacts/result.json
artifacts/reports/gmail-payload.json
artifacts/reports/gmail-preview.md
artifacts/reports/mitre-summary.json
artifacts/reports/mitre-summary.md
```

각 파일의 역할은 다음과 같습니다.

| 파일                                     | 설명                       |
| -------------------------------------- | ------------------------ |
| `artifacts/result.json`                | 전체 실행 결과, Gmail 발송 결과 포함 |
| `artifacts/reports/gmail-payload.json` | Gmail 전송 payload         |
| `artifacts/reports/gmail-preview.md`   | Gmail 본문 미리보기            |
| `artifacts/reports/mitre-summary.json` | MITRE 분석 요약 JSON         |
| `artifacts/reports/mitre-summary.md`   | MITRE 분석 요약 Markdown     |

---

## 9. Git 보관 시 주의사항

`.env`에는 계정, 비밀번호, 앱 비밀번호가 포함되므로 Git에 커밋하면 안 됩니다.

`.gitignore`에 다음 항목이 포함되어 있어야 합니다.

```gitignore
.env
```

대신 `.env.example`에는 실제 비밀번호 없이 예시값만 보관합니다.

`.env.example` 예시:

```env
# Gmail report
GMAIL_ENABLED=false
GMAIL_DRY_RUN=true
GMAIL_TO=
GMAIL_CC=
GMAIL_BCC=
GMAIL_SUBJECT_PREFIX=[PLURA-XDR]
GMAIL_FROM_NAME=PLURA-XDR AI Agent
GMAIL_SEND_ON_RISK=높음
GMAIL_INCLUDE_JSON_ATTACHMENT=true
GMAIL_INCLUDE_SCREENSHOT_PATHS=true

# SMTP settings
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=true
SMTP_USER=
SMTP_PASS=
SMTP_FROM=
```

---

## 10. 최종 운영 기준

운영 전 점검 기준은 다음과 같습니다.

```text
1. test-smtp-mail.ps1 테스트 성공
2. GMAIL_ENABLED=true
3. GMAIL_DRY_RUN=false
4. GMAIL_TO 설정 완료
5. SMTP_HOST / SMTP_PORT / SMTP_SECURE 설정 완료
6. SMTP_USER / SMTP_PASS / SMTP_FROM 설정 완료
7. npm run check 통과
8. npm run plura:mitre 실행 성공
9. artifacts/result.json에서 gmail.result.sent=true 확인
10. 실제 수신자 메일함에서 보고서 수신 확인
```

운영 중 문제가 발생하면 먼저 다음 파일을 확인합니다.

```powershell
Get-Content .\artifacts\result.json -Encoding UTF8 | Select-String '"gmail"' -Context 0,120
Get-Content .\artifacts\reports\gmail-payload.json -Encoding UTF8
Get-Content .\artifacts\reports\gmail-preview.md -Encoding UTF8
```

---

## 11. 보안 주의

* `.env` 파일은 절대 Git에 커밋하지 않습니다.
* `SMTP_PASS`는 Google 앱 비밀번호를 사용합니다.
* 앱 비밀번호가 노출되면 즉시 폐기하고 새로 발급합니다.
* 운영 계정 비밀번호가 대화, 로그, 문서에 노출되었다면 즉시 변경합니다.
* 가능하면 운영용 발송 계정은 별도 계정으로 분리합니다.

````

추가로 Git에 넣을 때는 반드시 `.env`가 제외되어 있는지 확인하세요.

```powershell
git status --ignored
````

`.env`가 추적 중이라면 제거해야 합니다.

```powershell
git rm --cached .env
```

그리고 `.gitignore`에 아래가 있어야 합니다.

```gitignore
.env
```
