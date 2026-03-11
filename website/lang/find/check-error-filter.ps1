param(
    [string]$BaseDir = "\\wsl$\Ubuntu-24.04\home\joo\filter",
    [string]$OutputFile = "filter_check_report.txt"
)

$OS_PAT = '(rhel|ubuntu|windows)'
$FID_PAT = '(M[a-z0-9]{15})'
$WFID_PAT = '(8\d{5})'
$TID_PAT = '(T\d{4}(?:\.\d{3})?)'

$EDR_LANGS = @('ko', 'en', 'ja', 'de', 'fr', 'es', 'zh-Hans')
$MITRE_LANGS = @('ko', 'en', 'ja')
$WEB_LANGS = @('ko', 'en', 'ja')

$ALLOWED_PREFIXES = @(
    'rules/edr',
    'rules/mitre',
    'rules/web',
    'meta/edr',
    'meta/mitre',
    'meta/web'
)

$PATTERNS = @(
    [pscustomobject]@{ Prefix = 'rules/edr';   Regex = "^filter/rules/edr/$OS_PAT/$FID_PAT-$OS_PAT\.json$";              OsGroups = @(1, 3) },
    [pscustomobject]@{ Prefix = 'rules/mitre'; Regex = "^filter/rules/mitre/$OS_PAT/$TID_PAT-$OS_PAT-$FID_PAT\.json$";  OsGroups = @(1, 3) },
    [pscustomobject]@{ Prefix = 'rules/web';   Regex = "^filter/rules/web/$WFID_PAT\.json$";                             OsGroups = $null },
    [pscustomobject]@{ Prefix = 'meta/edr';    Regex = "^filter/meta/edr/$OS_PAT/$FID_PAT-$OS_PAT-description\.json$";   OsGroups = @(1, 3) },
    [pscustomobject]@{ Prefix = 'meta/mitre';  Regex = '^filter/meta/mitre/MITRE-version\.json$';                         OsGroups = $null },
    [pscustomobject]@{ Prefix = 'meta/mitre';  Regex = '^filter/meta/mitre/Tactics\.json$';                               OsGroups = $null },
    [pscustomobject]@{ Prefix = 'meta/mitre';  Regex = "^filter/meta/mitre/$TID_PAT\.json$";                             OsGroups = $null },
    [pscustomobject]@{ Prefix = 'meta/mitre';  Regex = "^filter/meta/mitre/$TID_PAT-description\.json$";                 OsGroups = $null },
    [pscustomobject]@{ Prefix = 'meta/web';    Regex = "^filter/meta/web/$WFID_PAT-description\.json$";                  OsGroups = $null }
)

$EDR_RULES_RE = "^filter/rules/edr/$OS_PAT/$FID_PAT-$OS_PAT\.json$"
$MITRE_RULES_RE = "^filter/rules/mitre/$OS_PAT/$TID_PAT-$OS_PAT-$FID_PAT\.json$"
$WEB_RULES_RE = "^filter/rules/web/$WFID_PAT\.json$"

$script:JsonDocumentType = [type]::GetType('System.Text.Json.JsonDocument, System.Text.Json', $false)

function Normalize-Path {
    param([Parameter(Mandatory = $true)][object]$PathValue)
    return ([string]$PathValue -replace '\\', '/')
}

function New-StringList {
    return New-Object 'System.Collections.Generic.List[string]'
}

function Join-RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Base,
        [Parameter(Mandatory = $true)][string]$Relative
    )

    $path = $Base
    foreach ($part in ($Relative -split '/')) {
        $path = Join-Path $path $part
    }
    return $path
}

function Get-PropertyValue {
    param(
        [Parameter(Mandatory = $false)]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }

    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) {
            return $Object[$Name]
        }
        return $null
    }

    $prop = $Object.PSObject.Properties[$Name]
    if ($null -ne $prop) {
        return $prop.Value
    }

    return $null
}

function Test-PropertyExists {
    param(
        [Parameter(Mandatory = $false)]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Object) {
        return $false
    }

    if ($Object -is [System.Collections.IDictionary]) {
        return $Object.Contains($Name)
    }

    return ($null -ne $Object.PSObject.Properties[$Name])
}

function Test-IsFilterRoot {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (
        (Test-Path -LiteralPath (Join-Path $Path 'rules') -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $Path 'meta') -PathType Container)
    )
}

function Resolve-FilterRoot {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Directory not found: $Path"
    }

    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath

    if (Test-IsFilterRoot -Path $resolved) {
        return $resolved
    }

    $candidates = New-Object 'System.Collections.Generic.List[string]'
    foreach ($dir in (Get-ChildItem -LiteralPath $resolved -Directory -Recurse -ErrorAction Stop)) {
        if (Test-IsFilterRoot -Path $dir.FullName) {
            [void]$candidates.Add($dir.FullName)
        }
    }

    $uniqueCandidates = @($candidates | Sort-Object -Unique)

    if ($uniqueCandidates.Count -eq 1) {
        return $uniqueCandidates[0]
    }

    if ($uniqueCandidates.Count -eq 0) {
        throw "Could not find filter root under BaseDir. BaseDir must directly contain 'rules' and 'meta'."
    }

    $detail = ($uniqueCandidates | ForEach-Object { " - $_" }) -join "`n"
    throw "Multiple filter roots found. Please pass the exact root with -BaseDir:`n$detail"
}

function Get-AllowedJsonFiles {
    param([Parameter(Mandatory = $true)][string]$ResolvedBaseDir)

    $files = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'

    foreach ($prefix in $ALLOWED_PREFIXES) {
        $dir = Join-RelativePath -Base $ResolvedBaseDir -Relative $prefix
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
            continue
        }

        foreach ($file in (Get-ChildItem -LiteralPath $dir -Filter '*.json' -Recurse -File -ErrorAction Stop | Where-Object {
            $_.FullName -notmatch '(^|[\\/])\.git([\\/]|$)'
        })) {
            [void]$files.Add($file)
        }
    }

    return @($files | Sort-Object FullName -Unique)
}

function Get-RelativeFilterPath {
    param(
        [Parameter(Mandatory = $true)][System.IO.FileInfo]$File,
        [Parameter(Mandatory = $true)][string]$ResolvedBaseDir
    )

    $base = (Normalize-Path $ResolvedBaseDir).TrimEnd('/')
    $full = (Normalize-Path $File.FullName)

    if ($full.StartsWith($base + '/', [System.StringComparison]::OrdinalIgnoreCase)) {
        $tail = $full.Substring($base.Length).TrimStart('/')
        return ('filter/' + $tail)
    }

    throw "Failed to convert to relative path. BaseDir='$base', File='$full'"
}

function Get-JsonData {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ErrorLabel
    )

    try {
        $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    }
    catch {
        return [pscustomobject]@{
            Data  = $null
            Error = "[$ErrorLabel] $(Normalize-Path $Path) - $($_.Exception.Message)"
        }
    }

    if ($script:JsonDocumentType) {
        try {
            $null = [System.Text.Json.JsonDocument]::Parse($raw)
        }
        catch {
            $lineNo = $null
            if ($_.Exception.PSObject.Properties['LineNumber']) {
                $lineNo = [int]$_.Exception.LineNumber + 1
            }

            $msg = $_.Exception.Message
            if ($null -ne $lineNo) {
                return [pscustomobject]@{
                    Data  = $null
                    Error = "[$ErrorLabel] $(Normalize-Path $Path):$lineNo - $msg"
                }
            }

            return [pscustomobject]@{
                Data  = $null
                Error = "[$ErrorLabel] $(Normalize-Path $Path) - $msg"
            }
        }
    }

    try {
        $data = $raw | ConvertFrom-Json -ErrorAction Stop
        return [pscustomobject]@{
            Data  = $data
            Error = $null
        }
    }
    catch {
        return [pscustomobject]@{
            Data  = $null
            Error = "[$ErrorLabel] $(Normalize-Path $Path) - $($_.Exception.Message)"
        }
    }
}

function Load-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{
            Data  = $null
            Error = "[META MISSING] $(Normalize-Path $Path)"
        }
    }

    return Get-JsonData -Path $Path -ErrorLabel 'META JSON ERROR'
}

function Check-LangFields {
    param(
        [Parameter(Mandatory = $true)][string]$MetaPath,
        [Parameter(Mandatory = $false)]$Object,
        [Parameter(Mandatory = $true)][string]$Field,
        [Parameter(Mandatory = $true)][string[]]$Langs
    )

    $errors = New-StringList
    $fieldObj = Get-PropertyValue -Object $Object -Name $Field

    foreach ($lang in $Langs) {
        $val = Get-PropertyValue -Object $fieldObj -Name $lang
        if ($null -eq $val -or [string]::IsNullOrWhiteSpace([string]$val)) {
            [void]$errors.Add("[LANG EMPTY] $(Normalize-Path $MetaPath) -> $Field.$lang")
        }
    }

    return $errors
}

function Check-FilenamePattern {
    param([Parameter(Mandatory = $true)][string]$RelPath)

    $parts = $RelPath -split '/'
    if ($parts.Count -lt 3) {
        return $null
    }

    $prefix = "$($parts[1])/$($parts[2])"
    if ($ALLOWED_PREFIXES -notcontains $prefix) {
        return $null
    }

    $candidatePatterns = @($PATTERNS | Where-Object { $_.Prefix -eq $prefix })

    foreach ($entry in $candidatePatterns) {
        $match = [regex]::Match($RelPath, $entry.Regex)
        if ($match.Success) {
            if ($null -ne $entry.OsGroups) {
                $g1 = [int]$entry.OsGroups[0]
                $g2 = [int]$entry.OsGroups[1]
                if ($match.Groups[$g1].Value -ne $match.Groups[$g2].Value) {
                    return "[PATTERN ERROR] OS mismatch (path: $($match.Groups[$g1].Value), filename: $($match.Groups[$g2].Value)): $RelPath"
                }
            }
            return $null
        }
    }

    return "[PATTERN ERROR] $RelPath"
}

function Check-MetaLinkEdr {
    param(
        [Parameter(Mandatory = $true)][string]$RelPath,
        [Parameter(Mandatory = $true)][string]$ResolvedBaseDir
    )

    $match = [regex]::Match($RelPath, $EDR_RULES_RE)
    if (-not $match.Success) {
        return @()
    }

    $osVal = $match.Groups[1].Value
    $fid = $match.Groups[2].Value
    $metaPath = Join-RelativePath -Base $ResolvedBaseDir -Relative ("meta/edr/$osVal/$fid-$osVal-description.json")

    $result = Load-JsonFile -Path $metaPath
    if ($result.Error) {
        return @("$($result.Error) <- $RelPath")
    }

    $errors = New-StringList
    foreach ($field in @('filterName', 'filterDescription')) {
        foreach ($err in (Check-LangFields -MetaPath $metaPath -Object $result.Data -Field $field -Langs $EDR_LANGS)) {
            [void]$errors.Add($err)
        }
    }

    return $errors
}

function Check-MetaLinkMitre {
    param(
        [Parameter(Mandatory = $true)][string]$RelPath,
        [Parameter(Mandatory = $true)][string]$ResolvedBaseDir
    )

    $match = [regex]::Match($RelPath, $MITRE_RULES_RE)
    if (-not $match.Success) {
        return [pscustomobject]@{
            Errors   = @()
            Warnings = @()
        }
    }

    $tid = $match.Groups[2].Value
    $errors = New-StringList
    $warnings = New-StringList

    $descPath = Join-RelativePath -Base $ResolvedBaseDir -Relative ("meta/mitre/$tid-description.json")
    $descResult = Load-JsonFile -Path $descPath
    if ($descResult.Error) {
        [void]$errors.Add("$($descResult.Error) <- $RelPath")
    }
    else {
        foreach ($field in @('name', 'description')) {
            foreach ($err in (Check-LangFields -MetaPath $descPath -Object $descResult.Data -Field $field -Langs $MITRE_LANGS)) {
                [void]$errors.Add($err)
            }

            $fieldObj = Get-PropertyValue -Object $descResult.Data -Name $field
            if (Test-PropertyExists -Object $fieldObj -Name 'zh-cn') {
                [void]$warnings.Add("[ZH-CN WARN] $(Normalize-Path $descPath) -> $field.zh-cn (use zh-Hans)")
            }
        }
    }

    $techPath = Join-RelativePath -Base $ResolvedBaseDir -Relative ("meta/mitre/$tid.json")
    $techResult = Load-JsonFile -Path $techPath
    if ($techResult.Error) {
        [void]$errors.Add("$($techResult.Error) <- $RelPath")
    }
    else {
        $actualTid = Get-PropertyValue -Object $techResult.Data -Name 'techniqueId'
        if ($actualTid -ne $tid) {
            [void]$errors.Add("[TID MISMATCH] $(Normalize-Path $techPath) -> techniqueId: $actualTid (expected: $tid)")
        }
    }

    return [pscustomobject]@{
        Errors   = $errors
        Warnings = $warnings
    }
}

function Check-MetaLinkWeb {
    param(
        [Parameter(Mandatory = $true)][string]$RelPath,
        [Parameter(Mandatory = $true)][string]$ResolvedBaseDir
    )

    $match = [regex]::Match($RelPath, $WEB_RULES_RE)
    if (-not $match.Success) {
        return @()
    }

    $wfid = $match.Groups[1].Value
    $metaPath = Join-RelativePath -Base $ResolvedBaseDir -Relative ("meta/web/$wfid-description.json")

    $result = Load-JsonFile -Path $metaPath
    if ($result.Error) {
        return @("$($result.Error) <- $RelPath")
    }

    return (Check-LangFields -MetaPath $metaPath -Object $result.Data -Field 'webFilterName' -Langs $WEB_LANGS)
}

function Get-ElapsedString {
    param([Parameter(Mandatory = $true)][datetime]$StartTime)

    $elapsed = [datetime]::Now - $StartTime
    return '{0}:{1:00}:{2:00}' -f [int]$elapsed.TotalHours, $elapsed.Minutes, $elapsed.Seconds
}

try {
    $resolvedBaseDir = Resolve-FilterRoot -Path $BaseDir
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}

Write-Host "Using filter root: $resolvedBaseDir"
Write-Host "Scanning only: rules/edr, rules/mitre, rules/web, meta/edr, meta/mitre, meta/web"

$files = Get-AllowedJsonFiles -ResolvedBaseDir $resolvedBaseDir
$total = @($files).Count
$startTime = [datetime]::Now

$patternErrors = New-StringList
$jsonErrors = New-StringList
$metaErrors = New-StringList
$metaWarnings = New-StringList

for ($i = 0; $i -lt $total; $i++) {
    $file = $files[$i]

    Write-Host -NoNewline ("Elapsed: {0} | Processed: {1}/{2}`r" -f (Get-ElapsedString -StartTime $startTime), ($i + 1), $total)

    try {
        $relPath = Get-RelativeFilterPath -File $file -ResolvedBaseDir $resolvedBaseDir
    }
    catch {
        [void]$patternErrors.Add("[INTERNAL ERROR] $($_.Exception.Message)")
        continue
    }

    $patternError = Check-FilenamePattern -RelPath $relPath
    if ($null -ne $patternError) {
        [void]$patternErrors.Add($patternError)
    }

    $jsonResult = Get-JsonData -Path $file.FullName -ErrorLabel 'JSON ERROR'
    if ($jsonResult.Error) {
        [void]$jsonErrors.Add($jsonResult.Error)
    }

    foreach ($err in (Check-MetaLinkEdr -RelPath $relPath -ResolvedBaseDir $resolvedBaseDir)) {
        [void]$metaErrors.Add($err)
    }

    $mitreResult = Check-MetaLinkMitre -RelPath $relPath -ResolvedBaseDir $resolvedBaseDir
    foreach ($err in $mitreResult.Errors) {
        [void]$metaErrors.Add($err)
    }
    foreach ($warn in $mitreResult.Warnings) {
        [void]$metaWarnings.Add($warn)
    }

    foreach ($err in (Check-MetaLinkWeb -RelPath $relPath -ResolvedBaseDir $resolvedBaseDir)) {
        [void]$metaErrors.Add($err)
    }
}

Write-Host (((' ' * 100) + "`r")) -NoNewline

$report = New-StringList

[void]$report.Add(('=' * 60))
[void]$report.Add('Using filter root: ' + (Normalize-Path $resolvedBaseDir))
[void]$report.Add('Scanned paths only: rules/edr, rules/mitre, rules/web, meta/edr, meta/mitre, meta/web')
[void]$report.Add(('=' * 60))
[void]$report.Add('')

[void]$report.Add(('=' * 60))
[void]$report.Add('1. Filename pattern check')
[void]$report.Add(('=' * 60))
if ($patternErrors.Count -gt 0) {
    foreach ($item in $patternErrors) { [void]$report.Add($item) }
}
else {
    [void]$report.Add('No errors')
}

[void]$report.Add('')
[void]$report.Add(('=' * 60))
[void]$report.Add('2. JSON syntax check')
[void]$report.Add(('=' * 60))
if ($jsonErrors.Count -gt 0) {
    foreach ($item in $jsonErrors) { [void]$report.Add($item) }
}
else {
    [void]$report.Add('No errors')
}

[void]$report.Add('')
[void]$report.Add(('=' * 60))
[void]$report.Add('3. rules-meta linkage check')
[void]$report.Add(('=' * 60))
if ($metaErrors.Count -gt 0) {
    foreach ($item in $metaErrors) { [void]$report.Add($item) }
}
else {
    [void]$report.Add('No errors')
}

[void]$report.Add('')
[void]$report.Add(('=' * 60))
[void]$report.Add('3-1. Warnings (zh-cn field)')
[void]$report.Add(('=' * 60))
if ($metaWarnings.Count -gt 0) {
    foreach ($item in $metaWarnings) { [void]$report.Add($item) }
}
else {
    [void]$report.Add('No warnings')
}

[void]$report.Add('')
[void]$report.Add((
    "Completed: scanned {0} files | pattern errors {1} | JSON errors {2} | linkage errors {3} | warnings {4}" -f $total, $patternErrors.Count, $jsonErrors.Count, $metaErrors.Count, $metaWarnings.Count
))

$report | Set-Content -LiteralPath $OutputFile -Encoding utf8
$report | ForEach-Object { Write-Host $_ }
