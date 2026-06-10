아래 순서대로 실행하세요. 핵심은 **Docker Desktop/Engine 확인 → 기존 `tars-kali` 컨테이너만 start → Kali 도구 상태 확인 → v7271~v7275 evidence bundle 상태 확인 → 필요 시 wrapper 재실행**입니다. 이전 기록에서도 PC 재시작 후 `tars-kali`가 `Exited` 상태였고 `docker start tars-kali`로 복구한 뒤 도구/게이트를 다시 확인한 흐름이 있었습니다. 

---

# 0. PowerShell 관리자 권한으로 시작

가능하면 **관리자 PowerShell**에서 실행하세요.

```powershell
$TargetUrl  = "http://172.16.13.72/"
$TargetHost = "172.16.13.72"
$Kali       = "tars-kali"

$RepoRoot   = "C:\git\tars\tars"
$Worktree   = "C:\git\tars\tars-v7-operator-evidence-retry"
$Lab        = "$Worktree\services\tars-kali-lab"
$Bundle     = "$Lab\input\approved\operator-evidence-bundles\v7271-current"
```

---

# 1. Docker Desktop / Docker Engine 확인

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

Docker가 여기서 실패하면 Docker Desktop이 완전히 올라올 때까지 기다렸다가 다시 실행하세요.

---

# 2. 전체 컨테이너 상태 확인

```powershell
Write-Host "========== Docker containers =========="

docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
```

` tars-kali`가 `Exited`이면 아래에서 start합니다.
여기서는 **docker pull/run/build/compose up 하지 않습니다.**

---

# 3. 기존 `tars-kali` 컨테이너만 start

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

# 4. Kali 내부 도구 상태 확인

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

현재 최신 흐름에서는 이후 단계에서 `python3`, `nmap`, `sqlmap`, `nikto`, `ffuf`, `gobuster`, `wfuzz`, `whatweb`이 준비된 상태였지만, PC 재시작 후 컨테이너가 유지되었는지 꼭 다시 확인해야 합니다.

---

# 5. 대상 시스템 최소 연결 확인

이건 단순 reachability 확인입니다.

```powershell
Write-Host "========== Target reachability =========="

curl.exe -I $TargetUrl --max-time 5
```

기대값:

```text
HTTP/1.1 200 OK
Server: Apache/2.4.62 ...
```

---

# 6. 현재 worktree 상태 확인

```powershell
Write-Host "========== Worktree status =========="

cd $Worktree

git status --short
git log --oneline --decorate -5

git ls-remote --heads origin feature/tars-v7271-v7275-operator-evidence-confirmed-retry
git ls-remote --tags origin v7.275-operator-evidence-bundle-missing
```

`input/approved/**`나 local approval 파일은 untracked로 남아도 정상입니다.

정상적으로 untracked일 수 있는 항목:

```text
services/tars-kali-lab/input/approved/operator-evidence-bundles/**
services/tars-kali-lab/input/approved/source-enabled/**
services/tars-kali-lab/input/approved/auth/**
services/tars-kali-lab/config/operator-approval/*.local.json
```

---

# 7. evidence bundle 파일 확인

```powershell
Write-Host "========== Evidence bundle files =========="

cd $Lab

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

`.TODO.json` 파일이 있으면 제거하세요.

```powershell
Get-ChildItem $Bundle -Recurse -File -Filter "*.TODO.json" | Remove-Item -Force
```

---

# 8. evidence JSON 기본 검증

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

# 9. v7271 / v7272 단독 확인

먼저 전체 wrapper를 돌리지 말고, bundle과 lease/rollback만 확인하세요.

```powershell
Write-Host "========== v7271 / v7272 gates =========="

cd $Lab

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
```

현재 남아 있는 문제는 보통:

```text
rollbackVerified = false
impactPreconditionsReady = false
```

입니다.

이 경우 다음 단계는 v7276~v7280 rollback proof diagnostics / repair입니다.

---

# 10. v7271~v7275 전체 재실행

v7271/v7272 기본 확인 후 실행하세요.

```powershell
Write-Host "========== Run v7271-v7275 operator evidence retry =========="

cd $Lab

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

# 11. v7275 결과 요약 확인

```powershell
Write-Host "========== v7275 result =========="

cd $Lab

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

---

# 12. v762 readiness 확인

```powershell
Write-Host "========== v762 readiness =========="

cd $Lab

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

# 13. local evidence / approval commit 금지 확인

```powershell
Write-Host "========== Git safety check =========="

cd $Worktree

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

# 14. 새 Codex 스레드용 worktree 준비: v7276~v7280

이제 rollback proof 진단/수정 단계로 넘어가려면 새 worktree를 만듭니다.

```powershell
Write-Host "========== Create v7276-v7280 worktree =========="

cd $RepoRoot

git fetch origin --tags

if (!(Test-Path "C:\git\tars\tars-v7-rollback-proof-repair")) {
    git worktree add -b feature/tars-v7276-v7280-rollback-proof-repair `
      C:\git\tars\tars-v7-rollback-proof-repair `
      v7.275-operator-evidence-bundle-missing
}

cd C:\git\tars\tars-v7-rollback-proof-repair

git branch --show-current
git status --short
git describe --tags --exact-match
git log --oneline --decorate -5
```

---

# 15. 기존 evidence bundle을 새 worktree로 복사

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

# 16. 새 worktree에서 Docker/Kali 재확인

```powershell
Write-Host "========== New worktree Docker/Kali sanity =========="

cd C:\git\tars\tars-v7-rollback-proof-repair\services\tars-kali-lab

docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

docker exec $Kali sh -lc "command -v python3 || true; command -v gcc || true; command -v cc || true; command -v nmap || true; command -v sqlmap || true; command -v ffuf || true; command -v whatweb || true"
```

---

# 17. 새 worktree에서 현재 문제 재현

```powershell
Write-Host "========== Reproduce rollback blocker in new worktree =========="

cd C:\git\tars\tars-v7-rollback-proof-repair\services\tars-kali-lab

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

이 결과가 새 Codex 스레드의 시작점입니다.

---

# 18. 전체 한 번에 실행용 요약

위 내용을 순서대로 다 실행하기 어렵다면 최소 순서는 이것입니다.

```powershell
# 1. Docker/Kali 복구
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
docker start tars-kali
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

# 2. Kali 도구 확인
docker exec tars-kali sh -lc "command -v python3 || true; command -v gcc || true; command -v cc || true; command -v nmap || true; command -v sqlmap || true; command -v ffuf || true; command -v whatweb || true"

# 3. 기존 v7275 evidence retry 확인
cd C:\git\tars\tars-v7-operator-evidence-retry\services\tars-kali-lab
python scripts\v7271_operator_bundle_gate.py --strict
python scripts\v7272_lease_rollback_retry_gate.py --strict

# 4. 전체 v7271~v7275 재실행
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_v7271_v7275_operator_evidence_confirmed_retry.ps1 `
  -Strict `
  -TargetUrl "http://172.16.13.72/" `
  -ApprovedInternalActive `
  -ApprovedOperatorEvidenceRetry `
  -ContainerName tars-kali `
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

## 현재 기대 결론

지금 환경 복구 후 가장 중요한 확인값은 이것입니다.

```text
tars-kali = running
operatorBundlePresent = true
operatorBundleValid = true
canaryNamespaceVerified = true
rollbackProofPresent = true
rollbackVerified = false
impactPreconditionsReady = false
```

이 상태가 확인되면 다음 Codex 새 스레드는 바로:

```text
v7.276~v7.280 Rollback Proof Repair
```

로 진행하면 됩니다.
