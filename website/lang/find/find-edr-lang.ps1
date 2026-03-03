# 1. Configuration
$targetPath = "D:\temp\edr\windows"
$outputFile = "windows.lang.txt"
# Standard 7 Language Keys (Exact Match)
$requiredKeys = @("zh-Hans", "de", "ko", "ja", "en", "fr", "es")

if (Test-Path $targetPath) {
    # 2. Get JSON files (Exclude Zone.Identifier)
    $files = Get-ChildItem -Path $targetPath -Filter "*.json" | Where-Object { $_.Name -notlike "*.json_Zone.Identifier" }

    $resultList = New-Object System.Collections.Generic.List[string]

    foreach ($file in $files) {
        try {
            # Force Read as UTF8
            $rawText = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
            $jsonContent = $rawText | ConvertFrom-Json
            
            # Identify the target property (filterName, webFilterName, or name)
            $targetProperty = $null
            $allProps = $jsonContent.PSObject.Properties.Name
            
            if ($allProps -contains "filterName") { $targetProperty = $jsonContent.filterName }
            elseif ($allProps -contains "webFilterName") { $targetProperty = $jsonContent.webFilterName }
            elseif ($allProps -contains "name") { $targetProperty = $jsonContent.name }

            # If a translation object is found
            if ($null -ne $targetProperty) {
                # [FIX] Get keys as a clean string array for reliable comparison
                $presentKeys = $targetProperty.PSObject.Properties.Name | ForEach-Object { $_.ToString().Trim() }
                
                # Check for missing keys
                $missingKeys = New-Object System.Collections.Generic.List[string]
                foreach ($key in $requiredKeys) {
                    if ($presentKeys -notcontains $key) {
                        $missingKeys.Add($key)
                    }
                }

                # Add to result only if there are actually missing keys
                if ($missingKeys.Count -gt 0) {
                    $resultList.Add("-----------------------------------------")
                    $resultList.Add("FILE      : $($file.Name)")
                    $resultList.Add("STATUS    : MISSING ($($requiredKeys.Count - $missingKeys.Count)/7)")
                    $resultList.Add("MISSING   : $($missingKeys -join ', ')")
                    $resultList.Add("PRESENT   : $($presentKeys -join ', ')")
                }
            }
        }
        catch {
            $resultList.Add("-----------------------------------------")
            $resultList.Add("FILE      : $($file.Name)")
            $resultList.Add("ERROR     : JSON Parse Failed")
        }
    }

    # 3. Save result (UTF8 with BOM)
    if ($resultList.Count -gt 0) {
        $resultList | Out-File -FilePath $outputFile -Encoding utf8
        Write-Host "Scan completed. Issues found. Check '$outputFile'." -ForegroundColor Yellow
    } else {
        "All relevant files contain all 7 languages." | Out-File -FilePath $outputFile -Encoding utf8
        Write-Host "Success! No missing translations found." -ForegroundColor Green
    }
} else {
    Write-Host "Error: Path not found - $targetPath" -ForegroundColor Red
}
