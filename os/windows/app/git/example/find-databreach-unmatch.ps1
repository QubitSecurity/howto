# 비교할 두 대상 경로를 선언합니다.
$rulesPath = "\\wsl$\Ubuntu-24.04\home\joo\filter\rules\databreach"
$metaPath  = "\\wsl$\Ubuntu-24.04\home\joo\filter\meta\databreach"

Write-Host "Starting comparison between 'rules' and 'meta' directories..." -ForegroundColor Cyan

# 1. 경로 접근 가능 여부 사전 확인
$pathsValid = $true
if (-not (Test-Path -Path $rulesPath)) {
    Write-Warning "Rules path not found or inaccessible: $rulesPath"
    $pathsValid = $false
}
if (-not (Test-Path -Path $metaPath)) {
    Write-Warning "Meta path not found or inaccessible: $metaPath"
    $pathsValid = $false
}

# 경로가 유효하지 않으면 스크립트 종료
if (-not $pathsValid) {
    return
}

# 2. rules 경로에서 모든 JSON 파일 가져오기
$ruleFiles = Get-ChildItem -Path $rulesPath -Filter "*.json" -File
Write-Host "Found $($ruleFiles.Count) rule files. Checking for missing meta files..." -ForegroundColor Cyan

# 누락된 파일을 담을 빈 배열을 초기화합니다.
$missingMetaFiles = @()

# 3. rules 파일 순회 및 meta 파일 존재 여부 확인
foreach ($file in $ruleFiles) {
    # BaseName 속성은 확장자(.json)를 제외한 파일명만 가져옵니다 (예: M0143d9k2soz3mr6)
    $baseName = $file.BaseName
    
    # meta 폴더에 존재해야 할 예상 파일명 조합 (예: M0143d9k2soz3mr6-description.json)
    $expectedMetaFileName = "$baseName-description.json"
    $expectedMetaFilePath = Join-Path -Path $metaPath -ChildPath $expectedMetaFileName
    
    # 해당 meta 파일이 존재하지 않는 경우
    if (-not (Test-Path -Path $expectedMetaFilePath)) {
        # 결과 배열에 커스텀 객체로 추가
        $missingMetaFiles += [PSCustomObject]@{
            RulesFile_Found = $file.Name
            MetaFile_Missing = $expectedMetaFileName
        }
    }
}

# 4. 최종 결과 출력
if ($missingMetaFiles.Count -gt 0) {
    Write-Host "`nFound $($missingMetaFiles.Count) files in 'rules' without a corresponding file in 'meta':" -ForegroundColor Red
    $missingMetaFiles | Format-Table -AutoSize
} else {
    Write-Host "`nPerfect match! All rule files have a corresponding meta file." -ForegroundColor Green
}