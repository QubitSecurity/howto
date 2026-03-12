# 1. Configuration
$targetPath = "\\wsl$\Ubuntu-24.04\home\joo\work\filter\meta\mitre\"
$outputFile = "tactics-fix-log.txt"

# [핵심] BOM 없는 UTF8 인코딩 객체 및 LF 설정
$Utf8NoBom = New-Object System.Text.UTF8Encoding($False)

if (Test-Path $targetPath) {
    # *-description.json은 제외하고 모든 .json 파일 수집
    $files = Get-ChildItem -Path $targetPath -Filter "*.json" | Where-Object { 
        $_.Name -notlike "*-description.json" -and $_.Name -notlike "*.json_Zone.Identifier" 
    }
    
    $updateCount = 0
    $logList = New-Object System.Collections.Generic.List[string]

    foreach ($file in $files) {
        try {
            # 원본 텍스트 읽기
            $rawText = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
            
            # 정규표현식 설명:
            # "tacticsId"\s*:\s*"([^"]+)"
            # -> tacticsId 키 뒤에 따옴표로 감싸진 단일 문자열 값만 매칭 (이미 [ ] 가 있다면 매칭 안됨)
            $pattern = '"tacticsId"\s*:\s*"([^"]+)"'
            $replacement = '"tacticsId": ["$1"]'

            if ($rawText -match $pattern) {
                # 2. 치환 및 포맷 정규화 (LF 적용)
                $updatedText = [regex]::Replace($rawText, $pattern, $replacement)
                $updatedText = $updatedText -replace "`r`n", "`n"

                # 3. 저장 (BOM 없음 + LF)
                [System.IO.File]::WriteAllText($file.FullName, $updatedText, $Utf8NoBom)
                
                Write-Host "[CONVERTED] $($file.Name)" -ForegroundColor Cyan
                $logList.Add("Converted tacticsId to array: $($file.Name)")
                $updateCount++
            }
        }
        catch {
            Write-Host "[ERROR] Failed: $($file.Name)" -ForegroundColor Red
        }
    }

    $logList | Out-File -FilePath $outputFile -Encoding utf8
    Write-Host "`nSummary: $updateCount files updated to array format (LF & No BOM)." -ForegroundColor Green
} else {
    Write-Host "Error: Path not found - $targetPath" -ForegroundColor Red
}