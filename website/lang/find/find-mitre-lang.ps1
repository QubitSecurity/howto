# 1. Configuration
$targetPath = "D:\temp\mitre"
$outputFile = "mitre.lang.txt"

# Standard 7 Language Keys
$requiredKeys = @("zh-Hans", "de", "ko", "ja", "en", "fr", "es")

if (Test-Path $targetPath) {
    # 2. Get JSON files (Exclude Zone.Identifier)
    $files = Get-ChildItem -Path $targetPath -Filter "*.json" | Where-Object { $_.Name -notlike "*.json_Zone.Identifier" }

    $resultList = New-Object System.Collections.Generic.List[string]

    foreach ($file in $files) {
        try {
            # Force Read as UTF8 to prevent encoding issues
            $rawText = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
            $jsonContent = $rawText | ConvertFrom-Json
            
            # Identify the target property (filterName or name)
            $targetProperty = $null
            $propNames = $jsonContent.PSObject.Properties.Name
            
            if ($propNames -contains "filterName") {
                $targetProperty = $jsonContent.filterName
            } elseif ($propNames -contains "name") {
                $targetProperty = $jsonContent.name
            }

            # If a translation object is found, validate languages
            if ($null -ne $targetProperty) {
                $presentKeys = $targetProperty.PSObject.Properties.Name
                $missingKeys = $requiredKeys | Where-Object { $_ -notin $presentKeys }

                # Add to list only if languages are missing (< 7)
                if ($missingKeys.Count -gt 0) {
                    $resultList.Add("-----------------------------------------")
                    $resultList.Add("FILE      : $($file.Name)")
                    $resultList.Add("STATUS    : MISSING ($(7 - $missingKeys.Count)/7)")
                    $resultList.Add("MISSING   : $($missingKeys -join ', ')")
                    $resultList.Add("PRESENT   : $($presentKeys -join ', ')")
                }
            }
        }
        catch {
            # Log files that have actual syntax errors
            $resultList.Add("-----------------------------------------")
            $resultList.Add("FILE      : $($file.Name)")
            $resultList.Add("ERROR     : JSON Parse Failed")
        }
    }

    # 3. Save result as UTF8 with BOM (Best for Korean Windows)
    if ($resultList.Count -gt 0) {
        $resultList | Out-File -FilePath $outputFile -Encoding utf8
        Write-Host "Done! Missing translations found. Check '$outputFile'." -ForegroundColor Yellow
    } else {
        "All relevant files contain all 7 languages." | Out-File -FilePath $outputFile -Encoding utf8
        Write-Host "Success! All files are complete." -ForegroundColor Green
    }
} else {
    Write-Host "Error: Path not found - $targetPath" -ForegroundColor Red
}
