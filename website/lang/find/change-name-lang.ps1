# 1. Configuration
$targetPath = "\\wsl$\Ubuntu-24.04\home\joo\work\filter\meta\mitre"
$outputFile = "encoding-fix-log.txt"

# 치환 패턴 정의
$patterns = @{
    '"name"\s*:'        = '"filterName":'
    '"description"\s*:' = '"filterDescription":'
}

# [핵심] BOM 없는 UTF8 인코딩 객체 생성
$Utf8NoBom = New-Object System.Text.UTF8Encoding($False)

if (Test-Path $targetPath) {
    # 대상 파일 수집
    $files = Get-ChildItem -Path $targetPath -Filter "*-description.json" | Where-Object { $_.Name -notlike "*.json_Zone.Identifier" }
    $totalCount = 0
    $logList = New-Object System.Collections.Generic.List[string]

    foreach ($file in $files) {
        try {
            # 1. 원본 내용을 UTF8로 읽기 (기존에 BOM이 있든 없든 텍스트로 읽음)
            $rawText = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
            $updatedText = $rawText

            # 2. 치환 작업 수행 (필요한 경우)
            foreach ($oldKey in $patterns.Keys) {
                if ($updatedText -match $oldKey) {
                    $updatedText = [regex]::Replace($updatedText, $oldKey, $patterns[$oldKey])
                }
            }

            # 3. [반드시 실행] 변경 여부와 상관없이 BOM 없는 UTF-8로 다시 저장
            # 이 과정을 통해 기존 파일의 BOM이 제거되고 UTF-8(No BOM)으로 통일됩니다.
            [System.IO.File]::WriteAllText($file.FullName, $updatedText, $Utf8NoBom)
            
            Write-Host "[CONVERTED] $($file.Name)" -ForegroundColor Cyan
            $logList.Add("Converted to UTF-8 No BOM: $($file.Name)")
            $totalCount++
        }
        catch {
            Write-Host "[ERROR] Failed: $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 로그 저장
    $logList | Out-File -FilePath $outputFile -Encoding utf8
    Write-Host "`nSummary: $totalCount files processed and saved as UTF-8 (No BOM)." -ForegroundColor Green
} else {
    Write-Host "Error: Path not found - $targetPath" -ForegroundColor Red
}