# 1. 대상 경로 및 검색어 설정
$targetPath = "\\wsl$\Ubuntu-24.04\home\joo\filter\meta\mitre"
$searchString = "시스템 소유자/사용자 검색"

Write-Host "Searching for '$searchString' within 'ko' property..." -ForegroundColor Cyan

# 2. 경로 내 모든 JSON 파일 가져오기 (T*.json 형식 대응)
$jsonFiles = Get-ChildItem -Path $targetPath -Filter "*.json"
$foundFiles = @()

# 3. 파일 순회 및 JSON 구조 분석
foreach ($file in $jsonFiles) {
    try {
        # 파일을 UTF-8로 읽고 JSON으로 파싱
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $json = $content | ConvertFrom-Json
        
        # 'ko' 속성이 존재하는지 확인
        if ($null -ne $json.ko) {
            # 'ko' 하위 구조가 어떤 형태이든 검색할 수 있도록 문자열로 변환하여 확인
            $koString = $json.ko | ConvertTo-Json -Depth 10 -Compress
            
            if ($koString -match $searchString) {
                $foundFiles += $file.Name
            }
        }
    }
    catch {
        Write-Warning "Error reading or parsing file: $($file.Name)"
    }
}

# 4. 결과 출력
if ($foundFiles.Count -gt 0) {
    Write-Host "`nFound $($foundFiles.Count) file(s):" -ForegroundColor Green
    $foundFiles
} else {
    Write-Host "`nNo files found matching the criteria." -ForegroundColor Yellow
}
