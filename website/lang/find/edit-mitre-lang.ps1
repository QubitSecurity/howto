# 1. Configuration
$targetPath = "D:\temp\mitre"
$outputFile = "edit-log.txt"

# Target change: "zh-cn": -> "zh-Hans":
$oldKeyPattern = '"zh-cn"\s*:'
$newKeyReplacement = '"zh-Hans":'

if (Test-Path $targetPath) {
    $files = Get-ChildItem -Path $targetPath -Filter "*.json" | Where-Object { $_.Name -notlike "*.json_Zone.Identifier" }
    $updateCount = 0
    $logList = New-Object System.Collections.Generic.List[string]

    foreach ($file in $files) {
        try {
            # Read content exactly as it is (Preserving encoding and spacing)
            $rawText = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

            # Check if "zh-cn": exists in the text
            if ($rawText -match $oldKeyPattern) {
                # Replace only the key string using Regex
                $updatedText = [regex]::Replace($rawText, $oldKeyPattern, $newKeyReplacement)

                # Write back immediately with UTF8 (Preserving original formatting)
                [System.IO.File]::WriteAllText($file.FullName, $updatedText, [System.Text.Encoding]::UTF8)
                
                Write-Host "[FIXED] $($file.Name)" -ForegroundColor Cyan
                $logList.Add("Fixed: $($file.Name)")
                $updateCount++
            }
        }
        catch {
            Write-Host "[ERROR] Failed: $($file.Name)" -ForegroundColor Red
        }
    }

    Write-Host "`nSummary: $updateCount files updated without formatting changes." -ForegroundColor Green
} else {
    Write-Host "Error: Path not found - $targetPath" -ForegroundColor Red
}