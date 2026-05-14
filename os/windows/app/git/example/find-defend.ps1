# 1. Target directory and search criteria
$targetPath = "\\wsl$\Ubuntu-24.04\home\joo\filter\rules\databreach"
$targetValue = "defend"

Write-Host "Searching for JSON files where filterDetectType is '$targetValue'..." -ForegroundColor Cyan

# 2. Get all JSON files in the specified directory
$jsonFiles = Get-ChildItem -Path $targetPath -Filter "*.json"
$foundFiles = @()

# 3. Parse each file and check the value
foreach ($file in $jsonFiles) {
    try {
        # Read and parse JSON (UTF-8 encoding)
        $json = Get-Content -Path $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        
        # Check if 'filterDetectType' exists and equals 'defend'
        if ($null -ne $json.filterDetectType -and $json.filterDetectType -eq $targetValue) {
            $foundFiles += $file.Name
        }
    }
    catch {
        Write-Warning "Error reading or parsing file: $($file.Name)"
    }
}

# 4. Output the results
if ($foundFiles.Count -gt 0) {
    Write-Host "`nFound $($foundFiles.Count) file(s) with filterDetectType = 'defend':" -ForegroundColor Green
    $foundFiles
} else {
    Write-Host "`nNo files found with filterDetectType = 'defend'." -ForegroundColor Yellow
}