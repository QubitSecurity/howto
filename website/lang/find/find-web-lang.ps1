# 1. Configuration
$targetPath = "D:\temp\web"
$outputFile = "web.lang.txt"
# Standard 7 Language Keys to Check
$requiredKeys = @("zh-Hans", "de", "ko", "ja", "en", "fr", "es")

if (Test-Path $targetPath) {
    # 2. Get JSON files (Exclude Zone.Identifier)
    $files = Get-ChildItem -Path $targetPath -Filter "*.json" | Where-Object { $_.Name -notlike "*.json_Zone.Identifier" }

    $resultList = New-Object System.Collections.Generic.List[string]

    foreach ($file in $files) {
        try {
            # Read as UTF8 to ensure Korean/Japanese characters are preserved
            $rawText = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
            $jsonContent = $rawText | ConvertFrom-Json
            
            # Identify the target property among various possible keys
            $targetProperty = $null
            $propNames = $jsonContent.PSObject.Properties.Name
            
            # Check for known translation keys in order of priority
            if ($propNames -contains "webFilterName") {
                $targetProperty = $jsonContent.webFilterName
            } elseif ($propNames -contains "filterName") {
                $targetProperty = $jsonContent.filterName
            } elseif ($propNames -contains "name") {
                $targetProperty = $jsonContent.name
            }

            # If a translation target is found, validate 7 languages
            if ($null -ne $targetProperty) {
                $presentKeys = $targetProperty.PSObject.Properties.Name
                $missingKeys = $requiredKeys | Where-Object { $_ -notin $presentKeys }

                # Add to result ONLY if any of the 7 languages are missing
                if ($missingKeys.Count -gt 0) {
                    $resultList.Add("-----------------------------------------")
                    $resultList.Add("FILE      : $($file.Name)")
                    $resultList.Add("TYPE      : Translation Data Found")
                    $resultList.Add("STATUS    : MISSING ($(7 - $missingKeys.Count)/7)")
                    $resultList.Add("MISSING   : $($missingKeys -join ', ')")
                    $resultList.Add("PRESENT   : $($presentKeys -join ', ')")
                }
            }
        }
        catch {
            # Log files with structural errors (e.g., empty or broken JSON)
            $resultList.Add("-----------------------------------------")
            $resultList.Add("FILE      : $($file.Name)")
            $resultList.Add("ERROR     : JSON Parse Failed")
        }
    }

    # 3. Save result (UTF8 with BOM for better Windows compatibility)
    if ($resultList.Count -gt 0) {
        $resultList | Out-File -FilePath $outputFile -Encoding utf8
        Write-Host "Done! Scan complete. Check '$outputFile' for results." -ForegroundColor Yellow
    } else {
        "All relevant policy files contain all 7 languages." | Out-File -FilePath $outputFile -Encoding utf8
        Write-Host "Success! No missing translations found." -ForegroundColor Green
    }
} else {
    Write-Host "Error: Target path not found - $targetPath" -ForegroundColor Red
}
