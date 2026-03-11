# 1. Configuration
$baseDir = "D:\temp\filter"  # 실제 필터 루트 경로로 수정하세요
$outputFile = "filter_check_report.txt"

# 언어 설정
$EDR_LANGS = @("ko", "en", "ja", "de", "fr", "es", "zh-Hans")
$MITRE_LANGS = @("ko", "en", "ja")
$WEB_LANGS = @("ko", "en", "ja")

# 패턴 정의 (정규식)
$OS_PAT = "(rhel|ubuntu|windows)"
$FID_PAT = "(M[a-z0-9]{15})"
$WFID_PAT = "(8\d{5})"
$TID_PAT = "(T\d{4}(?:\.\d{3})?)"

# 검사 제외 파일
$ROOT_SKIP_FILES = @(
    "CredentialFilterType.json", "DefenseCmdTemplate.json", "FilterCategory.json",
    "FilterElementReferenceGlobal.json", "IpDefenseOwaspCategory.json",
    "WebExtendsFilterField.json", "WebFilter.json"
)

$report = New-Object System.Collections.Generic.List[string]
$stats = @{ Total = 0; PatternErr = 0; JsonErr = 0; LinkErr = 0; Warn = 0 }

function Write-Log { param($msg) $report.Add($msg); Write-Host $msg }

if (-not (Test-Path $baseDir)) { Write-Error "Path not found: $baseDir"; exit }

# 모든 JSON 파일 수집
$files = Get-ChildItem -Path $baseDir -Filter "*.json" -Recurse | Where-Object { $_.FullName -notmatch "\\\.git\\" }
$stats.Total = $files.Count

Write-Host "Checking $stats.Total files..." -ForegroundColor Cyan

foreach ($file in $files) {
    # 상대 경로 정규화 (POSIX 스타일)
    $relPath = $file.FullName.Replace($baseDir, "filter").Replace("\", "/")
    
    # --- 1. 파일명 패턴 검사 ---
    $isPatternValid = $false
    if ($relPath -match "^filter/($($ROOT_SKIP_FILES -join '|'))$") {
        $isPatternValid = $true
    } elseif ($relPath -match "^filter/rules/edr/$OS_PAT/$FID_PAT-$OS_PAT\.json$") {
        if ($Matches[1] -eq $Matches[3]) { $isPatternValid = $true }
    } elseif ($relPath -match "^filter/rules/mitre/$OS_PAT/$TID_PAT-$OS_PAT-$FID_PAT\.json$") {
        if ($Matches[1] -eq $Matches[3]) { $isPatternValid = $true }
    } elseif ($relPath -match "^filter/rules/web/$WFID_PAT\.json$") {
        $isPatternValid = $true
    } elseif ($relPath -match "^filter/meta/edr/$OS_PAT/$FID_PAT-$OS_PAT-description\.json$") {
        if ($Matches[1] -eq $Matches[3]) { $isPatternValid = $true }
    } elseif ($relPath -match "^filter/meta/mitre/(MITRE-version|Tactics|$TID_PAT|$TID_PAT-description)\.json$") {
        $isPatternValid = $true
    } elseif ($relPath -match "^filter/meta/web/$WFID_PAT-description\.json$") {
        $isPatternValid = $true
    }

    if (-not $isPatternValid) {
        Write-Log "[PATTERN ERROR] $relPath"
        $stats.PatternErr++
    }

    # --- 2. JSON 문법 및 연계 검사 ---
    try {
        $rawText = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        $json = $rawText | ConvertFrom-Json -ErrorAction Stop
        
        # EDR 연계 검사
        if ($relPath -match "rules/edr/$OS_PAT/($FID_PAT)-$OS_PAT\.json$") {
            $os = $Matches[1]; $fid = $Matches[2]
            $metaPath = Join-Path $baseDir "meta\edr\$os\$fid-$os-description.json"
            if (Test-Path $metaPath) {
                $metaJson = Get-Content $metaPath -Raw | ConvertFrom-Json
                foreach ($fld in @("filterName", "filterDescription")) {
                    foreach ($lang in $EDR_LANGS) {
                        if (-not $metaJson.$fld.$lang) { Write-Log "[LANG EMPTY] $metaPath -> $fld.$lang"; $stats.LinkErr++ }
                    }
                }
            } else { Write-Log "[META MISSING] $metaPath <- $relPath"; $stats.LinkErr++ }
        }

        # MITRE 연계 검사
        if ($relPath -match "rules/mitre/$OS_PAT/($TID_PAT)-$OS_PAT-$FID_PAT\.json$") {
            $tid = $Matches[2]
            # Description 검사
            $descPath = Join-Path $baseDir "meta\mitre\$tid-description.json"
            if (Test-Path $descPath) {
                $descJson = Get-Content $descPath -Raw | ConvertFrom-Json
                foreach ($fld in @("name", "description")) {
                    foreach ($lang in $MITRE_LANGS) {
                        if (-not $descJson.$fld.$lang) { Write-Log "[LANG EMPTY] $descPath -> $fld.$lang"; $stats.LinkErr++ }
                    }
                    if ($descJson.$fld."zh-cn") { Write-Log "[ZH-CN WARN] $descPath -> $fld.zh-cn (Use zh-Hans)"; $stats.Warn++ }
                }
            }
            # Tech 검사
            $techPath = Join-Path $baseDir "meta\mitre\$tid.json"
            if (Test-Path $techPath) {
                $techJson = Get-Content $techPath -Raw | ConvertFrom-Json
                if ($techJson.techniqueId -ne $tid) { Write-Log "[TID MISMATCH] $techPath (Got: $($techJson.techniqueId))"; $stats.LinkErr++ }
            }
        }

        # Web 연계 검사
        if ($relPath -match "rules/web/($WFID_PAT)\.json$") {
            $wfid = $Matches[1]
            $metaPath = Join-Path $baseDir "meta\web\$wfid-description.json"
            if (Test-Path $metaPath) {
                $metaJson = Get-Content $metaPath -Raw | ConvertFrom-Json
                foreach ($lang in $WEB_LANGS) {
                    if (-not $metaJson.webFilterName.$lang) { Write-Log "[LANG EMPTY] $metaPath -> webFilterName.$lang"; $stats.LinkErr++ }
                }
            }
        }
    } catch {
        Write-Log "[JSON ERROR] $relPath : $($_.Exception.Message)"
        $stats.JsonErr++
    }
}

# 요약 보고서 출력
$summary = @"

============================================================
검사 결과 요약
============================================================
검사 대상 파일  : $($stats.Total) 건
패턴 오류       : $($stats.PatternErr) 건
JSON 문법 오류  : $($stats.JsonErr) 건
연계/언어 오류  : $($stats.LinkErr) 건
경고 (zh-cn)    : $($stats.Warn) 건
============================================================
"@
$report.Add($summary)
$report | Out-File -FilePath $outputFile -Encoding utf8
Write-Host $summary -ForegroundColor Green
