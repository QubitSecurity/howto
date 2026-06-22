$targetPath = "\\wsl$\Ubuntu-24.04\home\joo\filter\rules\mitre\windows"
$searchString = "windows"

Write-Host "Starting JSON parsing search for lowercase '$searchString' in osType..." -ForegroundColor Cyan

# 1. 경로 접근 가능 여부 사전 확인
if (-not (Test-Path -Path $targetPath)) {
    Write-Warning "Path not found or inaccessible: $targetPath"
    Write-Warning "Please check if WSL is running and the path is correct."
    exit
}

$jsonFiles = Get-ChildItem -Path $targetPath -Filter "*.json" -File
$foundFiles = @()

# 2. 찾은 파일 개수 출력 (한글 깨짐 방지를 위해 영문으로 수정)
Write-Host "Found $($jsonFiles.Count) JSON files. Starting analysis..." -ForegroundColor Cyan

foreach ($file in $jsonFiles) {
    try {
        $json = Get-Content -Path $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        
        # 3. [string] 캐스팅과 -ceq 연산자로 대소문자 정확히 일치하는지 확인
        if ($null -ne $json.osType -and [string]$json.osType -ceq $searchString) {
            $foundFiles += $file.Name
        }
    }
    catch {
        Write-Warning "Error parsing file: $($file.Name)"
    }
}

# 4. 결과 출력
if ($foundFiles.Count -gt 0) {
    Write-Host "`nFound files containing lowercase osType '$searchString':" -ForegroundColor Green
    $foundFiles
} else {
    Write-Host "`nNo files found containing lowercase osType '$searchString'." -ForegroundColor Yellow
}
