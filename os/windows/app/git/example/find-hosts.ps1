$targetPath = "\\wsl$\Ubuntu-24.04\home\joo\filter\forensic\windows"
$searchString = "wd-hosts-file-check"

Write-Host "Starting JSON parsing search..." -ForegroundColor Cyan

$jsonFiles = Get-ChildItem -Path $targetPath -Filter "*.json"
$foundFiles = @()

foreach ($file in $jsonFiles) {
    try {
        $json = Get-Content -Path $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        
        $isMatch = $false

        foreach ($variant in $json.forensicOsVariants) {
            foreach ($value in $variant.forensicValues) {
                if ($value.forensicId -eq $searchString) {
                    $isMatch = $true
                    break
                }
            }
            if ($isMatch) { break }
        }

        if ($isMatch) {
            $foundFiles += $file.Name
        }
    }
    catch {
        Write-Warning "Error parsing file: $($file.Name)"
    }
}

if ($foundFiles.Count -gt 0) {
    Write-Host "`nFound files containing [$searchString]:" -ForegroundColor Green
    $foundFiles
} else {
    Write-Host "`nNo files found containing the specified value." -ForegroundColor Yellow
}
