$targetPath = "\\wsl$\Ubuntu-24.04\home\joo\filter\rules\mitre\windows"
$searchString = "windows"

Write-Host "Starting JSON parsing search for lowercase 'windows' in osType..." -ForegroundColor Cyan

$jsonFiles = Get-ChildItem -Path $targetPath -Filter "*.json"
$foundFiles = @()

foreach ($file in $jsonFiles) {
    try {
        # JSON 파일을 읽어 객체로 변환
        $json = Get-Content -Path $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        
        # osType 속성이 존재하고, 그 값이 소문자 "windows"와 정확히 일치하는지 확인 (-creq 사용)
        if ($null -ne $json.osType -and $json.osType -creq $searchString) {
            $foundFiles += $file.Name
        }
    }
    catch {
        Write-Warning "Error parsing file: $($file.Name)"
    }
}

# 결과 출력
if ($foundFiles.Count -gt 0) {
    Write-Host "`nFound files containing lowercase osType 'windows':" -ForegroundColor Green
    $foundFiles
} else {
    Write-Host "`nNo files found containing lowercase osType 'windows'." -ForegroundColor Yellow
}
