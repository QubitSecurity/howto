<#
.SYNOPSIS
  Automated Sysmon installer/updater for PLURA EDR (SYSTEM context expected).

.DESCRIPTION
  - Installs Sysmon with the provided configuration if not present.
  - If Sysmon is already installed, updates configuration.
  - Logs all major steps to Windows Event Log (Application) with source "Application".
  - Uses PLURA-reserved EventID range (50000+).
  - Reports installed version or error reasons.

.NOTES
  - Expected locations:
      C:\Program Files\PLURA\sysmon.exe or sysmon64.exe
      C:\Program Files\PLURA\sysmon-plura.xml
  - Run with SYSTEM or elevated admin (PLURA EDR agent provides SYSTEM).
#>

# ----- Safety & Defaults -----
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ----- Settings -----
$BaseDir     = 'C:\Program Files\PLURA'
$SysmonX64   = Join-Path $BaseDir 'sysmon64.exe'
$SysmonX86   = Join-Path $BaseDir 'sysmon.exe'
$ConfigPath  = Join-Path $BaseDir 'sysmon-plura.xml'

$EventLog    = 'Application'
$EventSource = 'Application'  # Built-in Application source

# Event IDs (PLURA reserved: 50000+)
$EID_Started       = 50000
$EID_Installed     = 50001
$EID_Updated       = 50002
$EID_Skipped       = 50003
$EID_Error         = 50100
$EID_PrereqError   = 50101

# ----- Helpers -----
function Write-AppLog {
    param(
        [ValidateSet('Information','Warning','Error')]
        [string]$Level = 'Information',
        [string]$Message,
        [int]$EventId = 50000
    )
    Write-EventLog -LogName $EventLog -Source $EventSource -EventId $EventId -EntryType $Level -Message $Message
}

function Get-PreferredSysmonPath {
    if ([Environment]::Is64BitOperatingSystem -and (Test-Path $SysmonX64)) { return $SysmonX64 }
    elseif (Test-Path $SysmonX86) { return $SysmonX86 }
    else { return $null }
}

function Get-SysmonServiceName {
    foreach ($name in @('Sysmon64','Sysmon')) {
        try {
            $svc = Get-Service -Name $name -ErrorAction Stop
            if ($null -ne $svc) { return $name }
        } catch { }
    }
    return $null
}

function Get-SysmonInstalledExePath {
    param([string]$ServiceName)
    if (-not $ServiceName) { return $null }
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
    try {
        $imagePath = (Get-ItemProperty -Path $regPath -Name ImagePath -ErrorAction Stop).ImagePath
        if ($imagePath -match '^\s*"(.*?)"') { return $Matches[1] }
        else { return ($imagePath -split '\s+')[0] }
    } catch { return $null }
}

function Get-FileVersionString {
    param([string]$Path)
    try {
        if ($Path -and (Test-Path $Path)) {
            $vi = (Get-Item $Path).VersionInfo
            if ($vi) { return $vi.FileVersion }
        }
    } catch { }
    return $null
}

function Invoke-Sysmon {
    param(
        [Parameter(Mandatory=$true)][string]$Exe,
        [Parameter(Mandatory=$true)][string[]]$Arguments
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Exe
    $psi.Arguments = ($Arguments -join ' ')
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    $stdOut = $p.StandardOutput.ReadToEnd()
    $stdErr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()

    [PSCustomObject]@{
        ExitCode = $p.ExitCode
        StdOut   = $stdOut.Trim()
        StdErr   = $stdErr.Trim()
        Command  = "$Exe $($Arguments -join ' ')"
    }
}

# ----- Main -----
try {
    Write-AppLog -Level Information -EventId $EID_Started -Message "PLURA-Sysmon: Setup started. BaseDir='$BaseDir'. User='$(whoami)'."

    $sysmonExe = Get-PreferredSysmonPath
    if (-not $sysmonExe) {
        Write-AppLog -Level Error -EventId $EID_PrereqError -Message "PLURA-Sysmon: Sysmon executable not found. Looked for '$SysmonX64' and '$SysmonX86'."
        throw "Sysmon executable not found."
    }
    if (-not (Test-Path $ConfigPath)) {
        Write-AppLog -Level Error -EventId $EID_PrereqError -Message "PLURA-Sysmon: Configuration file not found at '$ConfigPath'."
        throw "Sysmon configuration file missing."
    }

    $existingSvcName = Get-SysmonServiceName
    if ($null -eq $existingSvcName) {
        # Install
        $args = @('-accepteula', '-i', ('"' + $ConfigPath + '"'))
        $result = Invoke-Sysmon -Exe $sysmonExe -Arguments $args
        $existingSvcName = Get-SysmonServiceName

        if ($result.ExitCode -eq 0 -and $existingSvcName) {
            $ver = Get-FileVersionString -Path (Get-SysmonInstalledExePath -ServiceName $existingSvcName)
            Write-AppLog -Level Information -EventId $EID_Installed -Message "PLURA-Sysmon: Installed successfully. Service='$existingSvcName'. Version='$ver'. Command='$($result.Command)'. Output='$($result.StdOut)'."
        } else {
            $err = "PLURA-Sysmon: Installation failed. ExitCode=$($result.ExitCode). StdErr='$($result.StdErr)'. StdOut='$($result.StdOut)'. Command='$($result.Command)'."
            Write-AppLog -Level Error -EventId $EID_Error -Message $err
            throw $err
        }
    } else {
        # Update config
        $args = @('-accepteula', '-c', ('"' + $ConfigPath + '"'))
        $result = Invoke-Sysmon -Exe $sysmonExe -Arguments $args

        if ($result.ExitCode -eq 0) {
            $ver = Get-FileVersionString -Path (Get-SysmonInstalledExePath -ServiceName $existingSvcName)
            Write-AppLog -Level Information -EventId $EID_Updated -Message "PLURA-Sysmon: Config updated successfully. Service='$existingSvcName'. Version='$ver'. Command='$($result.Command)'. Output='$($result.StdOut)'."
        } else {
            $err = "PLURA-Sysmon: Config update failed. ExitCode=$($result.ExitCode). StdErr='$($result.StdErr)'. StdOut='$($result.StdOut)'. Command='$($result.Command)'."
            Write-AppLog -Level Error -EventId $EID_Error -Message $err
            throw $err
        }
    }

    # Ensure service running
    $svcName = Get-SysmonServiceName
    if ($svcName) {
        try {
            $svc = Get-Service -Name $svcName -ErrorAction Stop
            if ($svc.Status -ne 'Running') {
                Start-Service -Name $svcName -ErrorAction Stop
            }
        } catch {
            Write-AppLog -Level Warning -EventId $EID_Skipped -Message "PLURA-Sysmon: Service '$svcName' could not be started automatically. Error='$($_.Exception.Message)'."
        }
    }

} catch {
    $msg = "PLURA-Sysmon: Setup encountered an error: $($_.Exception.Message)"
    Write-AppLog -Level Error -EventId $EID_Error -Message $msg
    throw
}
