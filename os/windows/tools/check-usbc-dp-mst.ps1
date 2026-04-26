<#
.SYNOPSIS
  Check whether a laptop appears to support:
  - USB 3.2 Gen2 / 10Gbps
  - USB-C / Type-C related controller
  - DP Alt Mode possibility
  - MST / multiple monitor output possibility

.DESCRIPTION
  This script performs a best-effort inspection using Windows PnP, WMI/CIM,
  display adapter, monitor, USB controller, Thunderbolt and USB4 related devices.

.NOTES
  DP Alt Mode and MST support cannot always be confirmed only by PowerShell.
  They depend on hardware design, BIOS/firmware, GPU driver, cable, dock, and monitor.
#>

[CmdletBinding()]
param(
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

function Normalize-Text {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    return ($Text -replace '\s+', ' ').Trim()
}

function Get-PnpSafe {
    param(
        [string[]]$Class,
        [string]$FriendlyNameLike
    )

    $items = @()

    if ($Class -and $Class.Count -gt 0) {
        foreach ($c in $Class) {
            $items += Get-PnpDevice -Class $c -ErrorAction SilentlyContinue
        }
    }
    else {
        $items += Get-PnpDevice -ErrorAction SilentlyContinue
    }

    if ($FriendlyNameLike) {
        $items = $items | Where-Object {
            $_.FriendlyName -match $FriendlyNameLike -or
            $_.Name -match $FriendlyNameLike -or
            $_.InstanceId -match $FriendlyNameLike
        }
    }

    return @($items)
}

function Test-MatchAny {
    param(
        [string[]]$Texts,
        [string[]]$Patterns
    )

    foreach ($t in $Texts) {
        foreach ($p in $Patterns) {
            if ($t -match $p) {
                return $true
            }
        }
    }

    return $false
}

function Get-MatchedLines {
    param(
        [object[]]$Items,
        [string[]]$Patterns
    )

    $result = @()

    foreach ($item in $Items) {
        $text = Normalize-Text (@(
            $item.FriendlyName
            $item.Name
            $item.Description
            $item.Caption
            $item.DeviceID
            $item.InstanceId
            $item.PNPDeviceID
        ) -join " ")

        foreach ($p in $Patterns) {
            if ($text -match $p) {
                $result += $text
                break
            }
        }
    }

    return @($result | Sort-Object -Unique)
}

function To-OnOff {
    param([bool]$Value)
    if ($Value) { return "ON" }
    return "OFF"
}

function To-Status {
    param(
        [bool]$Value,
        [string]$WhenTrue = "SupportedOrDetected",
        [string]$WhenFalse = "NotDetected"
    )

    if ($Value) { return $WhenTrue }
    return $WhenFalse
}

# ------------------------------------------------------------
# 1. Collect devices
# ------------------------------------------------------------

$allPnp = @(Get-PnpDevice -ErrorAction SilentlyContinue)

$usbDevices = @(
    Get-PnpDevice -Class USB -ErrorAction SilentlyContinue
)

$usbControllerCim = @(
    Get-CimInstance Win32_USBController -ErrorAction SilentlyContinue
)

$displayAdapters = @(
    Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
)

$desktopMonitors = @(
    Get-CimInstance Win32_DesktopMonitor -ErrorAction SilentlyContinue
)

$pnpMonitors = @(
    Get-PnpDevice -Class Monitor -ErrorAction SilentlyContinue
)

# WMI monitor info usually works better than Win32_DesktopMonitor
$wmiMonitors = @(
    Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue
)

# ------------------------------------------------------------
# 2. Pattern definitions
# ------------------------------------------------------------

$usb10Patterns = @(
    'USB\s*3\.2',
    'USB\s*3\.1',
    'eXtensible Host Controller',
    'xHCI',
    'SuperSpeedPlus',
    'SuperSpeed\s*Plus',
    '10\s*Gbps',
    '10G',
    'Gen\s*2'
)

$typeCPatterns = @(
    'Type[-\s]?C',
    'USB[-\s]?C',
    'UCSI',
    'USB Connector Manager',
    'USB Type-C',
    'Billboard',
    'USB4',
    'Thunderbolt',
    'TBT'
)

$dpAltPatterns = @(
    'DisplayPort',
    'DP Alt',
    'Alt Mode',
    'Billboard',
    'UCSI',
    'USB4',
    'Thunderbolt',
    'TBT'
)

$mstPatterns = @(
    'MST',
    'Multi-Stream',
    'DisplayPort',
    'Thunderbolt',
    'USB4',
    'Dock',
    'Hub'
)

# ------------------------------------------------------------
# 3. USB 3.2 Gen2 / 10Gbps detection
# ------------------------------------------------------------

$usbTexts = @()

foreach ($d in $usbDevices) {
    $usbTexts += Normalize-Text (@($d.FriendlyName, $d.Name, $d.InstanceId) -join " ")
}

foreach ($c in $usbControllerCim) {
    $usbTexts += Normalize-Text (@($c.Name, $c.Caption, $c.Description, $c.DeviceID, $c.PNPDeviceID) -join " ")
}

$usb10Detected = Test-MatchAny -Texts $usbTexts -Patterns $usb10Patterns
$usb10Matches = Get-MatchedLines -Items (@($usbDevices) + @($usbControllerCim)) -Patterns $usb10Patterns

# More conservative Gen2 hint
$gen2Detected = Test-MatchAny -Texts $usbTexts -Patterns @(
    'USB\s*3\.2',
    'USB\s*3\.1',
    'SuperSpeedPlus',
    'SuperSpeed\s*Plus',
    '10\s*Gbps',
    'Gen\s*2'
)

# ------------------------------------------------------------
# 4. USB-C / Type-C detection
# ------------------------------------------------------------

$typeCMatches = Get-MatchedLines -Items $allPnp -Patterns $typeCPatterns
$typeCDetected = ($typeCMatches.Count -gt 0)

# ------------------------------------------------------------
# 5. DP Alt Mode possibility detection
# ------------------------------------------------------------

$dpAltMatches = Get-MatchedLines -Items $allPnp -Patterns $dpAltPatterns
$dpAltPossible = $false

# Practical rule:
# USB-C/USB4/Thunderbolt/UCSI + DisplayPort/Alt/Billboard evidence
# or Thunderbolt/USB4 alone gives strong possibility.
if ($typeCDetected -and ($dpAltMatches.Count -gt 0)) {
    $dpAltPossible = $true
}

if (Test-MatchAny -Texts $typeCMatches -Patterns @('Thunderbolt', 'USB4')) {
    $dpAltPossible = $true
}

# ------------------------------------------------------------
# 6. MST / multi-monitor detection
# ------------------------------------------------------------

$activeMonitorCount = 0

if ($wmiMonitors.Count -gt 0) {
    $activeMonitorCount = @($wmiMonitors | Where-Object { $_.Active -eq $true }).Count
}
elseif ($pnpMonitors.Count -gt 0) {
    $activeMonitorCount = @($pnpMonitors | Where-Object { $_.Status -eq "OK" }).Count
}
elseif ($desktopMonitors.Count -gt 0) {
    $activeMonitorCount = @($desktopMonitors).Count
}

$multiMonitorDetected = ($activeMonitorCount -ge 2)

$mstMatches = Get-MatchedLines -Items $allPnp -Patterns $mstPatterns
$mstPossible = ($multiMonitorDetected -or ($mstMatches.Count -gt 0))

# ------------------------------------------------------------
# 7. Display adapter summary
# ------------------------------------------------------------

$gpuList = @()
foreach ($gpu in $displayAdapters) {
    $gpuList += [PSCustomObject]@{
        Name            = $gpu.Name
        DriverVersion   = $gpu.DriverVersion
        VideoProcessor  = $gpu.VideoProcessor
        AdapterRAM_MB   = if ($gpu.AdapterRAM) { [math]::Round($gpu.AdapterRAM / 1MB, 0) } else { "-" }
    }
}

# ------------------------------------------------------------
# 8. Final result
# ------------------------------------------------------------

$result = [ordered]@{
    "CheckName" = "USB-C DP Alt MST Capability Check"

    "USB3_2_Gen2" = if ($gen2Detected) { "DetectedOrLikely" } else { "NotConfirmed" }
    "TransferSpeed_10Gbps" = if ($usb10Detected) { "DetectedOrLikely" } else { "NotConfirmed" }

    "TypeC_Port" = if ($typeCDetected) { "DetectedOrLikely" } else { "NotConfirmed" }
    "DP_Alt_Mode" = if ($dpAltPossible) { "PossibleOrDetected" } else { "NotConfirmed" }

    "MST" = if ($mstPossible) { "PossibleOrDetected" } else { "NotConfirmed" }
    "CurrentActiveMonitorCount" = "$activeMonitorCount"
    "MultiMonitorCurrentlyDetected" = To-OnOff $multiMonitorDetected

    "UsbEvidence" = if ($usb10Matches.Count -gt 0) { $usb10Matches } else { @("-") }
    "TypeCEvidence" = if ($typeCMatches.Count -gt 0) { $typeCMatches } else { @("-") }
    "DpAltEvidence" = if ($dpAltMatches.Count -gt 0) { $dpAltMatches } else { @("-") }
    "MstEvidence" = if ($mstMatches.Count -gt 0) { $mstMatches } else { @("-") }

    "DisplayAdapters" = if ($gpuList.Count -gt 0) { $gpuList } else { @("-") }

    "Note" = "DP Alt Mode and MST cannot always be conclusively verified by PowerShell only. Check vendor specification, BIOS, GPU driver, cable, dock, and monitor capability."
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
}
else {
    Write-Host ""
    Write-Host "# USB-C / DP Alt / MST Capability Check" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "USB 3.2 Gen2        : $($result.USB3_2_Gen2)"
    Write-Host "10Gbps              : $($result.TransferSpeed_10Gbps)"
    Write-Host "C Type / USB-C      : $($result.TypeC_Port)"
    Write-Host "DP Alt Mode         : $($result.DP_Alt_Mode)"
    Write-Host "MST                 : $($result.MST)"
    Write-Host "Active Monitors     : $($result.CurrentActiveMonitorCount)"
    Write-Host "Multi Monitor Now   : $($result.MultiMonitorCurrentlyDetected)"
    Write-Host ""

    Write-Host "## USB Evidence" -ForegroundColor Yellow
    $result.UsbEvidence | ForEach-Object { Write-Host "- $_" }

    Write-Host ""
    Write-Host "## Type-C Evidence" -ForegroundColor Yellow
    $result.TypeCEvidence | ForEach-Object { Write-Host "- $_" }

    Write-Host ""
    Write-Host "## DP Alt Evidence" -ForegroundColor Yellow
    $result.DpAltEvidence | ForEach-Object { Write-Host "- $_" }

    Write-Host ""
    Write-Host "## MST Evidence" -ForegroundColor Yellow
    $result.MstEvidence | ForEach-Object { Write-Host "- $_" }

    Write-Host ""
    Write-Host "## Display Adapters" -ForegroundColor Yellow
    $result.DisplayAdapters | Format-Table -AutoSize

    Write-Host ""
    Write-Host "Note: $($result.Note)" -ForegroundColor DarkGray
}