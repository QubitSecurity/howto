$targetPath = "\\wsl$\Ubuntu-24.04\home\joo\filter\meta\mitre"
$searchString = "시스템 소유자/사용자 검색"

Write-Host "Search Start..." -ForegroundColor Cyan

$jsonFiles = Get-ChildItem -Path $targetPath -Filter "*.json"
$foundFiles = @()

foreach ($file in $jsonFiles) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $json = $content | ConvertFrom-Json
        
        if ($null -ne $json.ko) {
            $koString = $json.ko | ConvertTo-Json -Depth 10 -Compress
            
            if ($koString -match $searchString) {
                $foundFiles += $file.Name
            }
        }
    }
    catch {
        Write-Warning "Error reading file: $($file.Name)"
    }
}

if ($foundFiles.Count -gt 0) {
    Write-Host "Found files:" -ForegroundColor Green
    $foundFiles
} else {
    Write-Host "Not found." -ForegroundColor Yellow
}
