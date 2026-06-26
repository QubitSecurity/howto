# 탐색할 대상 경로들을 배열로 선언합니다.
$targetPaths = @(
    "\\wsl$\Ubuntu-24.04\home\joo\filter\forensic\rhel",
    "\\wsl$\Ubuntu-24.04\home\joo\filter\forensic\ubuntu"
)
$searchType = "8"

Write-Host "Starting JSON parsing search for forensicType '$searchType'..." -ForegroundColor Cyan

# 결과를 담을 빈 배열을 초기화합니다.
$foundFiles = @()

# 각 경로를 순회하며 탐색을 시작합니다.
foreach ($targetPath in $targetPaths) {
    Write-Host "`n[Target Path]: $targetPath" -ForegroundColor Magenta

    # 1. 경로 접근 가능 여부 사전 확인
    if (-not (Test-Path -Path $targetPath)) {
        Write-Warning "Path not found or inaccessible: $targetPath"
        continue # 경로가 없으면 다음 경로로 넘어갑니다.
    }

    $jsonFiles = Get-ChildItem -Path $targetPath -Filter "*.json" -File
    
    # 2. 찾은 파일 개수 출력
    Write-Host "Found $($jsonFiles.Count) JSON files. Starting analysis..." -ForegroundColor Cyan

    foreach ($file in $jsonFiles) {
        try {
            $json = Get-Content -Path $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            $isFileMatched = $false
            
            # 3. JSON 구조 순회: forensicOsVariants 배열 안의 forensicValues 배열 확인
            if ($null -ne $json.forensicOsVariants) {
                foreach ($variant in $json.forensicOsVariants) {
                    if ($null -ne $variant.forensicValues) {
                        foreach ($value in $variant.forensicValues) {
                            # forensicType 값이 "8"과 정확히 일치하는지 확인
                            if ($null -ne $value.forensicType -and [string]$value.forensicType -eq $searchType) {
                                $isFileMatched = $true
                                break # 매칭되는 값을 찾았으면 현재 파일 내 forensicValues 순회 중지
                            }
                        }
                    }
                    if ($isFileMatched) { 
                        break # 이미 파일이 조건에 부합하므로 forensicOsVariants 순회 중지
                    }
                }
            }
            
            # 조건에 맞는 파일이면 결과 배열에 추가 (어느 경로에서 찾았는지 알기 위해 커스텀 객체 사용)
            if ($isFileMatched) {
                $foundFiles += [PSCustomObject]@{
                    FileName = $file.Name
                    Directory = $targetPath.Split('\')[-1] # rhel 또는 ubuntu 등 상위 폴더명만 추출
                }
            }
        }
        catch {
            Write-Warning "Error parsing file: $($file.Name)"
        }
    }
}

# 4. 최종 결과 출력
if ($foundFiles.Count -gt 0) {
    Write-Host "`nFound files containing forensicType '$searchType':" -ForegroundColor Green
    $foundFiles | Format-Table -AutoSize
} else {
    Write-Host "`nNo files found containing forensicType '$searchType'." -ForegroundColor Yellow
}
