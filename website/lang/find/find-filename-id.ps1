# 1. 파라미터 설정 (스크립트 실행 시 파일 ID 입력 받음)
param(
    [Parameter(Mandatory=$true)]
    [string]$FileId
)

# 2. 기준 경로 설정
$basePath = "D:\temp"

# 3. 조사 대상 6개 하위 디렉토리 정의 (이미지 및 요청 사항 기반)
# 규칙 및 메타데이터 디렉토리를 모두 포함합니다.
$targetSubDirs = @(
    "rules\edr",
    "rules\mitre",
    "rules\web",
    "meta\edr",
    "meta\mitre",
    "meta\web"
)

Write-Host "Searching for ID: '$FileId' in $basePath..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------"

$foundAny = $false

# 4. 각 대상 디렉토리 순회
foreach ($subDir in $targetSubDirs) {
    $fullSearchPath = Join-Path $basePath $subDir
    
    # 디렉토리가 존재하는 경우에만 검색 실시
    if (Test-Path $fullSearchPath) {
        # -Filter 대신 -Include와 와일드카드를 사용하여 파일 이름에 포함된 경우 검색
        # 하위 디렉토리까지 모두 검색하기 위해 -Recurse 사용
        $matchedFiles = Get-ChildItem -Path $fullSearchPath -File -Recurse | Where-Object { $_.Name -like "*$FileId*" }
        
        foreach ($file in $matchedFiles) {
            Write-Host "[FOUND] $($file.FullName)" -ForegroundColor Green
            $foundAny = $true
        }
    }
}

# 5. 검색 결과가 없는 경우 알림
if (-not $foundAny) {
    Write-Host "No files found matching '$FileId' in the specified directories." -ForegroundColor Yellow
}

Write-Host "--------------------------------------------------------"
Write-Host "Search Completed."
