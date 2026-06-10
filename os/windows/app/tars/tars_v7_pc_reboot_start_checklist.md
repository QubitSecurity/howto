# TARS v7 PC Reboot Recovery & Start Checklist

이 문서는 PC 재부팅 후 TARS v7 작업을 재개하기 위한 최종 체크리스트입니다.

핵심 목적은 다음입니다.

```text
1. Docker Desktop / Docker Engine 복구
2. 기존 tars-kali 컨테이너만 start
3. Kali 내부 도구 상태 직접 확인
4. v7271~v7275 operator evidence bundle 상태 확인
5. rollbackVerified=false 문제 재현
6. v7276~v7280 Rollback Proof Repair 새 Codex 스레드 준비
```

주의:

```text
docker pull / run / build / compose up 하지 않습니다.
이미 존재하는 tars-kali 컨테이너만 start합니다.
input/approved/**, operator-approval/*.local.json 은 commit하지 않습니다.
오래된 worktree의 toolchain gate 결과보다 현재 docker exec 실측값을 우선합니다.
```

---

## 0. 현재까지 확인된 문제 요약

### 문제 1 — PC 재부팅 후 `tars-kali`가 Exited 상태가 됨

증상:

```text
tars-kali   kalilinux/kali-rolling   Exited (255)
docker exec ... container is not running
```

해결:

```powershell
docker start tars-kali
```

그 뒤 `docker exec`로 도구 상태를 확인합니다.

---

### 문제 2 — 오래된 worktree의 gate 결과가 현재 Docker 상태와 다를 수 있음

예를 들어 오래된 v773~v777 worktree는 다음처럼 나올 수 있습니다.

```text
python3Present=false
gccPresent=false
compilerPresent=false
```

하지만 현재 컨테이너를 직접 보면 다음처럼 준비되어 있을 수 있습니다.

```text
/usr/bin/python3
/usr/bin/gcc
/usr/bin/cc
/usr/bin/make
/usr/bin/nmap
/usr/bin/sqlmap
/usr/bin/ffuf
/usr/bin/whatweb
```

따라서 리부팅 직후에는 항상 **현재 docker exec 실측값**을 기준으로 삼습니다.

---

### 문제 3 — operator evidence bundle은 이제 존재하지만 rollback proof가 invalid

현재 기대 상태:

```text
operatorBundlePresent=true
operatorBundleValid=true
canaryLeasePresent=true
canaryNamespaceVerified=true
rollbackProofPresent=true
rollbackVerified=false
impactPreconditionsReady=false
```

즉, 다음 Codex 단계는 다음입니다.

```text
v7.276~v7.280 Rollback Proof Repair
```

---

### 문제 4 — v7276 branch가 이미 있으면 `git worktree add -b`가 실패함

증상:

```text
fatal: a branch named 'feature/tars-v7276-v7280-rollback-proof-repair' already exists
```

해결:

```text
이미 있는 branch/worktree를 재사용합니다.
새 브랜치를 만들 때만 -b 옵션을 사용합니다.
```

---

### 문제 5 — casebook_quarantine.json이 일부 gate에서 변할 수 있음

`casebook_quarantine.json`은 baseline 유지가 중요합니다.

만약 변경되면:

```powershell
git restore --source=HEAD -- services\tars-kali-lab\artifacts\learning-memory\casebook_quarantine.json
```

---

## 1. PowerShell 관리자 권한으로 시작

```powershell
$TargetUrl  = "http://172.16.13.72/"
$TargetHost = "172.16.13.72"
$Kali       = "tars-kali"

$RepoRoot   = "C:\git\tars\tars"

$EvidenceWorktree = "C:\git\tars\tars-v7-operator-evidence-retry"
$EvidenceLab      = "$EvidenceWorktree\services\tars-kali-lab"
$EvidenceBundle   = "$EvidenceLab\input\approved\operator-evidence-bundles\v7271-current"

$RollbackWorktree = "C:\git\tars\tars-v7-rollback-proof-repair"
$RollbackLab      = "$RollbackWorktree\services\tars-kali-lab"
```

---

## 2. Docker Desktop / Docker Engine 확인

```powershell
Write-Host "========== Docker service =========="

Get-Service com.docker.service -ErrorAction SilentlyContinue | Format-List Name,Status,StartType

$dockerService = Get-Service com.docker.service -ErrorAction SilentlyContinue
if ($dockerService -and $dockerService.Status -ne "Running") {
    Start-Service com.docker.service
}

Write-Host "========== Start Docker Desktop if needed =========="

$dockerDesktop = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerDesktop) {
    Start-Process $dockerDesktop -ErrorAction SilentlyContinue
}

Write-Host "========== Wait for Docker daemon =========="

$deadline = (Get-Date).AddMinutes(3)
do {
    docker version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker daemon: READY" -ForegroundColor Green
        break
    }

    Start-Sleep -Seconds 5
} while ((Get-Date) -lt $deadline)

docker version
docker info
```

---

## 3. 전체 컨테이너 상태 확인

```powershell
Write-Host "========== Docker containers =========="

docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
```

현재 v7276~v7280 작업에 반드시 필요한 것은 `tars-kali`입니다.

```text
tars-kali
```

다른 vulnerable-* lab 컨테이너가 `Exited`여도, 현재 rollback proof repair 단계에서는 필수 아닙니다.

---

## 4. 기존 `tars-kali` 컨테이너만 start

```powershell
Write-Host "========== Check tars-kali =========="

$state = docker inspect -f "{{.State.Status}}" $Kali 2>$null

if (-not $state) {
    throw "Container '$Kali' not found. Do not run docker pull/run/build/compose up here. Restore/create it through the approved provisioning flow."
}

Write-Host "$Kali state: $state"

if ($state -ne "running") {
    Write-Host "Starting existing $Kali container..."
    docker start $Kali
}

docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
```

기대값:

```text
NAMES       IMAGE                    STATUS
tars-kali   kalilinux/kali-rolling   Up ...
```

---

## 5. Kali 내부 도구 상태 직접 확인

```powershell
Write-Host "========== Kali tool inventory =========="

docker exec $Kali sh -lc @'
echo "[shells]"
command -v sh || true
command -v bash || true

echo ""
echo "[python]"
command -v python3 || true
python3 --version 2>/dev/null || true

echo ""
echo "[compiler/build]"
command -v gcc || true
command -v cc || true
command -v clang || true
command -v make || true
gcc --version 2>/dev/null | head -1 || true
cc --version 2>/dev/null | head -1 || true
make --version 2>/dev/null | head -1 || true

echo ""
echo "[binary/debug]"
command -v file || true
command -v readelf || true
command -v objdump || true
command -v gdb || true

echo ""
echo "[web tools]"
command -v curl || true
command -v nmap || true
command -v sqlmap || true
command -v nikto || true
command -v ffuf || true
command -v gobuster || true
command -v wfuzz || true
command -v whatweb || true

echo ""
echo "[fixture]"
file /tmp/tars-local-fixtures/out/tiny_parser 2>/dev/null || true
ls -la /tmp/tars-local-fixtures/tiny_c_parser 2>/dev/null || true
ls -la /tmp/tars-local-fixtures/out 2>/dev/null || true
'@
```

현재 기대 핵심값:

```text
/usr/bin/python3
/usr/bin/gcc
/usr/bin/cc
/usr/bin/make
/usr/bin/nmap
/usr/bin/sqlmap
/usr/bin/ffuf
/usr/bin/whatweb
```

---

## 6. 대상 시스템 최소 연결 확인

```powershell
Write-Host "========== Target reachability =========="

curl.exe -I $TargetUrl --max-time 5
```

기대값 예시:

```text
HTTP/1.1 200 OK
Server: Apache/2.4.62 (CentOS Stream)
```

---

## 7. v7271~v7275 evidence worktree 상태 확인

```powershell
Write-Host "========== Evidence worktree status =========="

cd $EvidenceWorktree

git status --short
git log --oneline --decorate -5

git ls-remote --heads origin feature/tars-v7271-v7275-operator-evidence-confirmed-retry
git ls-remote --tags origin v7.275-operator-evidence-bundle-missing
```

정상적으로 untracked일 수 있는 항목:

```text
services/tars-kali-lab/input/approved/operator-evidence-bundles/**
services/tars-kali-lab/input/approved/source-enabled/**
services/tars-kali-lab/input/approved/auth/**
services/tars-kali-lab/config/operator-approval/*.local.json
```

이 파일들은 commit하지 않습니다.

---

## 8. evidence bundle 파일 확인

```powershell
Write-Host "========== Evidence bundle files =========="

cd $EvidenceLab

$Bundle = ".\input\approved\operator-evidence-bundles\v7271-current"

if (!(Test-Path $Bundle)) {
    throw "Evidence bundle directory missing: $Bundle"
}

Get-ChildItem $Bundle -Recurse -File | Select-Object FullName
```

현재 최소 기대 파일:

```text
bundle_manifest.json
canary-lease/canary_lease.json
rollback/rollback_proof.json
```

`.TODO.json` 파일이 있으면 제거합니다.

```powershell
Get-ChildItem $Bundle -Recurse -File -Filter "*.TODO.json" | Remove-Item -Force
```

---

## 9. evidence JSON 기본 검증

```powershell
Write-Host "========== Evidence JSON basic validation =========="

$required = @(
  "$Bundle\bundle_manifest.json",
  "$Bundle\canary-lease\canary_lease.json",
  "$Bundle\rollback\rollback_proof.json"
)

foreach ($p in $required) {
    if (!(Test-Path $p)) {
        throw "Missing required evidence file: $p"
    }

    $j = Get-Content $p -Raw | ConvertFrom-Json

    if ($j.PSObject.Properties.Name -contains "exampleOnly" -and $j.exampleOnly -eq $true) {
        throw "Example evidence is not accepted as real evidence: $p"
    }

    if ($j.PSObject.Properties.Name -contains "acceptedAsRealEvidence" -and $j.acceptedAsRealEvidence -eq $false) {
        throw "TODO evidence is not accepted as real evidence: $p"
    }

    if ($j.targetUrl -ne $TargetUrl) {
        throw "targetUrl mismatch in $p"
    }
}

Write-Host "operator evidence basic file check: PASS" -ForegroundColor Green
```

---

## 10. v7271 / v7272 단독 확인

전체 wrapper를 반복하기 전에, bundle과 lease/rollback만 확인합니다.

```powershell
Write-Host "========== v7271 / v7272 gates =========="

cd $EvidenceLab

python scripts\v7271_operator_bundle_gate.py --strict
python scripts\v7272_lease_rollback_retry_gate.py --strict
```

현재 기대값:

```text
operatorBundlePresent = true
operatorBundleValid = true
canaryLeasePresent = true
canaryNamespaceVerified = true
rollbackProofPresent = true
rollbackVerified = false
impactPreconditionsReady = false
```

이 상태가 나오면 정상적으로 현재 blocker가 재현된 것입니다.

---

## 11. 필요 시 v7271~v7275 전체 재실행

대부분의 경우 v7271/v7272 확인만으로 충분합니다.  
최종 scorecard를 다시 만들고 싶을 때만 실행합니다.

```powershell
Write-Host "========== Run v7271-v7275 operator evidence retry =========="

cd $EvidenceLab

powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_v7271_v7275_operator_evidence_confirmed_retry.ps1 `
  -Strict `
  -TargetUrl $TargetUrl `
  -ApprovedInternalActive `
  -ApprovedOperatorEvidenceRetry `
  -ContainerName $Kali `
  -Profile internal-operator-evidence-confirmed-retry `
  -OperatorBundlePath ".\input\approved\operator-evidence-bundles\v7271-current" `
  -MaterializeToApprovedDropzone `
  -AutoRerunV7270 `
  -AutoRerunV7260 `
  -AllowCanaryLeaseIntake `
  -AllowRollbackProofIntake `
  -AllowServerLogIntake `
  -AllowWafLogIntake `
  -AllowAppLogIntake `
  -AllowUploadStorageIntake `
  -AllowWordpressEvidenceIntake `
  -AllowAuthEvidenceIntake `
  -AllowConfirmedFindingRetry `
  -MaxTotalRequests 500 `
  -MaxRequestsPerSecond 2 `
  -MaxConcurrency 1 `
  -NoDdos `
  -NoFalseClaim
```

---

## 12. v7275 결과 요약 확인

```powershell
Write-Host "========== v7275 result =========="

cd $EvidenceLab

$scorePath = ".\artifacts\v7275-final-submission-decision\v7275_final_submission_scorecard.json"
$nextPath  = ".\artifacts\v7275-final-submission-decision\v7275_next_action.json"
$claimPath = ".\artifacts\v7275-final-submission-decision\v7275_claim_gate.json"

if (!(Test-Path $scorePath)) { throw "v7275 scorecard missing" }
if (!(Test-Path $nextPath))  { throw "v7275 next_action missing" }
if (!(Test-Path $claimPath)) { throw "v7275 claim gate missing" }

$score = Get-Content $scorePath -Raw | ConvertFrom-Json
$next = Get-Content $nextPath -Raw | ConvertFrom-Json
$claim = Get-Content $claimPath -Raw | ConvertFrom-Json

Write-Host ""
Write-Host "========== v7.275 OPERATOR EVIDENCE RETRY RESULT =========="
Write-Host "operatorBundlePresent:          $($score.operatorBundlePresent)"
Write-Host "operatorBundleValid:            $($score.operatorBundleValid)"
Write-Host "materializationRun:             $($score.materializationRun)"
Write-Host "canaryLeasePresent:             $($score.canaryLeasePresent)"
Write-Host "canaryNamespaceVerified:        $($score.canaryNamespaceVerified)"
Write-Host "rollbackProofPresent:           $($score.rollbackProofPresent)"
Write-Host "rollbackVerified:               $($score.rollbackVerified)"
Write-Host "serverLogEvidenceAvailable:     $($score.serverLogEvidenceAvailable)"
Write-Host "wafLogEvidenceAvailable:        $($score.wafLogEvidenceAvailable)"
Write-Host "uploadStorageEvidenceAvailable: $($score.uploadStorageEvidenceAvailable)"
Write-Host "highConfidenceCorrelationCount: $($score.highConfidenceCorrelationCount)"
Write-Host "confirmedFindingCount:          $($score.confirmedFindingCount)"
Write-Host "canaryImpactEvidenceCount:      $($score.canaryImpactEvidenceCount)"
Write-Host "submissionDecision:             $($score.submissionDecision)"
Write-Host "false/safety penalty:           $($score.falseClaimPenalty) / $($score.safetyPenalty)"
Write-Host ""
$next | ConvertTo-Json -Depth 20
```

현재 기대값:

```text
rollbackVerified = false
confirmedFindingCount = 0
canaryImpactEvidenceCount = 0
```

---

## 13. v762 readiness 확인

```powershell
Write-Host "========== v762 readiness =========="

cd $EvidenceLab

python scripts\v762_competition_readiness_gate.py --strict
```

정상 기대값:

```text
finalResult = PARTIAL
realProtectedTargetStage = L3
l4Achieved = false
l5Achieved = false
falseClaimPenalty = 0
safetyPenalty = 0
```

---

## 14. local evidence / approval commit 금지 확인

```powershell
Write-Host "========== Git safety check =========="

cd $EvidenceWorktree

git status --short

$bad = git status --short | Select-String -Pattern `
  "input/approved/operator-evidence-bundles|input/approved/source-enabled|input/approved/auth|operator-approval/.*\.local\.json|casebook_quarantine\.json|docker-compose|raw_payload|unredacted|credential|secret|webshell|reverse|\.php$|\.phtml$|\.phar$|\.exe$"

if ($bad) {
    Write-Host ""
    Write-Host "The following local/private files must NOT be committed:" -ForegroundColor Yellow
    $bad
}
```

---

## 15. v7276~v7280 worktree 준비

이미 브랜치가 있을 수 있으므로, `git worktree add -b`를 무조건 실행하지 않습니다.

```powershell
Write-Host "========== Prepare v7276-v7280 rollback repair worktree =========="

cd $RepoRoot

git fetch origin --tags

$RollbackBranch = "feature/tars-v7276-v7280-rollback-proof-repair"
$RollbackPath   = "C:\git\tars\tars-v7-rollback-proof-repair"

git branch --list $RollbackBranch
git worktree list

if (Test-Path $RollbackPath) {
    Write-Host "Rollback repair worktree already exists. Reusing: $RollbackPath"
    cd $RollbackPath
}
else {
    $branchExists = git branch --list $RollbackBranch

    if ($branchExists) {
        Write-Host "Branch exists. Adding worktree from existing branch."
        git worktree add $RollbackPath $RollbackBranch
    }
    else {
        Write-Host "Branch does not exist. Creating from v7.275 tag."
        git worktree add -b $RollbackBranch $RollbackPath v7.275-operator-evidence-bundle-missing
    }

    cd $RollbackPath
}

git branch --show-current
git status --short
git log --oneline --decorate -5
```

기대 브랜치:

```text
feature/tars-v7276-v7280-rollback-proof-repair
```

---

## 16. 기존 evidence bundle을 rollback repair worktree로 복사

```powershell
Write-Host "========== Copy local operator evidence bundle =========="

$src = "C:\git\tars\tars-v7-operator-evidence-retry\services\tars-kali-lab\input\approved\operator-evidence-bundles\v7271-current"
$dst = "C:\git\tars\tars-v7-rollback-proof-repair\services\tars-kali-lab\input\approved\operator-evidence-bundles\v7271-current"

if (!(Test-Path $src)) {
    throw "source operator evidence bundle not found: $src"
}

New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item "$src\*" $dst -Recurse -Force

Get-ChildItem $dst -Recurse -File | Select-Object FullName
```

이 복사된 evidence도 commit하지 않습니다.

---

## 17. 새 worktree에서 Docker/Kali 재확인

```powershell
Write-Host "========== New worktree Docker/Kali sanity =========="

cd $RollbackLab

docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

docker exec $Kali sh -lc "command -v python3 || true; command -v gcc || true; command -v cc || true; command -v nmap || true; command -v sqlmap || true; command -v ffuf || true; command -v whatweb || true"
```

---

## 18. rollback blocker 재현

```powershell
Write-Host "========== Reproduce rollback blocker in rollback repair worktree =========="

cd $RollbackLab

python scripts\v7271_operator_bundle_gate.py --strict
python scripts\v7272_lease_rollback_retry_gate.py --strict
```

기대값:

```text
operatorBundlePresent = true
operatorBundleValid = true
canaryNamespaceVerified = true
rollbackProofPresent = true
rollbackVerified = false
impactPreconditionsReady = false
```

이 상태가 확인되면 새 Codex 스레드의 시작점이 준비된 것입니다.

---

## 19. 오래된 worktree 결과를 해석할 때 주의할 점

다음 worktree의 결과는 당시 기준이라 현재 Docker 실측과 다를 수 있습니다.

```text
tars-v7-kali-start
tars-v7-tool-readiness
tars-v7-one-request
tars-v7-observe-toolchain
```

예를 들어 오래된 gate에서 다음처럼 나와도:

```text
python3Present=false
compilerPresent=false
```

현재 `docker exec tars-kali command -v python3/gcc/...`가 true이면 현재 환경은 도구가 있는 상태입니다.

현재 상태 판단 우선순위:

```text
1. 현재 docker exec 실측값
2. 현재 작업 중인 worktree의 gate 결과
3. 오래된 tag/worktree의 과거 artifact
```

---

## 20. 메인 repo dirty 상태 주의

`C:\git\tars\tars` 메인 worktree는 여러 실험/v8 파일로 dirty할 수 있습니다.  
v7276~v7280 작업은 반드시 전용 worktree에서 진행합니다.

```text
C:\git\tars\tars-v7-rollback-proof-repair
```

메인 repo에서 직접 commit하지 않습니다.

---

## 21. casebook_quarantine.json 보호

어떤 gate 실행 후라도 다음 파일이 변경되면 복원합니다.

```text
services/tars-kali-lab/artifacts/learning-memory/casebook_quarantine.json
```

복원 명령:

```powershell
git restore --source=HEAD -- services\tars-kali-lab\artifacts\learning-memory\casebook_quarantine.json
```

확인:

```powershell
git diff --exit-code -- services\tars-kali-lab\artifacts\learning-memory\casebook_quarantine.json
```

---

## 22. 최종 빠른 실행 요약

PC 리부팅 후 최소 확인만 할 때:

```powershell
$TargetUrl = "http://172.16.13.72/"
$Kali = "tars-kali"

docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
docker start $Kali
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

docker exec $Kali sh -lc "command -v python3 || true; command -v gcc || true; command -v cc || true; command -v make || true; command -v nmap || true; command -v sqlmap || true; command -v ffuf || true; command -v whatweb || true"

cd C:\git\tars\tars-v7-operator-evidence-retry\services\tars-kali-lab
python scripts\v7271_operator_bundle_gate.py --strict
python scripts\v7272_lease_rollback_retry_gate.py --strict
```

기대 결론:

```text
tars-kali = running
tools = present
operatorBundlePresent = true
operatorBundleValid = true
canaryNamespaceVerified = true
rollbackProofPresent = true
rollbackVerified = false
impactPreconditionsReady = false
```

그 다음:

```text
v7.276~v7.280 Rollback Proof Repair 새 Codex 스레드 진행
```
