$targetPath = "\\wsl$\Ubuntu-24.04\home\joo\filter\rules"
$searchFileName = "*M6223qougkjhldon*"

Write-Host "Starting search... (Including subdirectories)" -ForegroundColor Cyan

$foundFiles = Get-ChildItem -Path $targetPath -Filter $searchFileName -Recurse -ErrorAction SilentlyContinue

if ($foundFiles) {
    Write-Host "File found! Exact path(s):" -ForegroundColor Green
    foreach ($file in $foundFiles) {
        Write-Host "▶ $($file.FullName)" -ForegroundColor Yellow
    }
} else {
    Write-Host "Cannot find 'M35601gglcnl4apw'. Please check the target path ($targetPath)." -ForegroundColor Red
}

Write-Host "Search completed." -ForegroundColor Cyan