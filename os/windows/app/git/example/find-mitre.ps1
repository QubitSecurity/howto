# 1. 대상 경로 및 검색어 설정
$targetPath = "\\wsl$\Ubuntu-24.04\home\joo\filter\meta\mitre"
$searchString = "시스템 소유자/사용자 검색"

Write-Host "검색을 시작합니다..." -ForegroundColor Cyan

# 2. 경로 내 모든 JSON 파일을 가져와서 검색
Get-ChildItem -Path $targetPath -Filter "*.json" | ForEach-Object {
    # 파일을 UTF-8 형식으로 읽기
    $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8
    
    # 내용에 검색어가 포함되어 있는지 확인
    if ($content -match $searchString) {
        # 조건에 맞으면 파일 이름 출력
        Write-Host $_.Name -ForegroundColor Green
    }
}

Write-Host "검색이 완료되었습니다." -ForegroundColor Cyan
