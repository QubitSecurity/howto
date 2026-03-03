# 1. 환경 설정
$targetPath = "D:\temp\edr\windows"
$outputFile = "windows.lang.txt"
# 기준 언어 (JSON 키와 정확히 일치해야 함)
$requiredKeys = @("zh-Hans", "de", "ko", "ja", "en", "fr", "es")

if (Test-Path $targetPath) {
    # 2. JSON 파일 목록 가져오기 (Zone.Identifier 제외)
    $files = Get-ChildItem -Path $targetPath -Filter "*.json" | Where-Object { $_.Name -notlike "*.json_Zone.Identifier" }

    $resultList = New-Object System.Collections.Generic.List[string]

    foreach ($file in $files) {
        try {
            # 인코딩 문제를 방지하기 위해 UTF8로 강제 로드
            $rawText = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
            $jsonContent = $rawText | ConvertFrom-Json
            
            # filterName 객체의 속성 이름(언어 키)들 가져오기
            $presentKeys = $jsonContent.filterName.PSObject.Properties.Name
            
            # 누락된 키 확인
            $missingKeys = $requiredKeys | Where-Object { $_ -notin $presentKeys }

            # 3. 7개 언어가 모두 있지 않은 경우만 리스트에 추가
            if ($missingKeys.Count -gt 0) {
                $resultList.Add("-----------------------------------------")
                $resultList.Add("File Name : $($file.Name)")
                $resultList.Add("Status    : MISSING ($(7 - $missingKeys.Count)/7)")
                $resultList.Add("Missing   : $($missingKeys -join ', ')")
            }
        }
        catch {
            # 파싱 에러 발생 시 로그 (인코딩 문제 해결용)
            $resultList.Add("-----------------------------------------")
            $resultList.Add("File Name : $($file.Name)")
            $resultList.Add("Error     : Parse Failed (Check file encoding or JSON format)")
        }
    }

    # 4. 결과 저장 (BOM이 있는 UTF8로 저장하여 한글 깨짐 방지)
    if ($resultList.Count -gt 0) {
        $resultList | Out-File -FilePath $outputFile -Encoding utf8
        Write-Host "Done! Check '$outputFile' for missing language sets." -ForegroundColor Yellow
    } else {
        "All files contain 7 languages." | Out-File -FilePath $outputFile -Encoding utf8
        Write-Host "Success! No issues found." -ForegroundColor Green
    }
} else {
    Write-Host "Path not found: $targetPath" -ForegroundColor Red
}
