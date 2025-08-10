<# 
.SYNOPSIS
  Automated Sysmon installer/updater for PLURA EDR (SYSTEM context expected).

.DESCRIPTION
  - Installs Sysmon with the provided configuration if not present.
  - If Sysmon is already installed, updates configuration.
  - Logs all major steps to Windows Event Log (Application) with source "PLURA-Sysmon-Installer".
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
$EventSource = 'PLURA-Sysmon-Installer'

# Event IDs (informational taxonomy)
$EID_Started       = 1000
$EID_Installed     = 1001
$EID_Updated       = 1002
$EID_Skipped       = 1003
$EID_Error         = 1100
$EID_PrereqError   = 1101

# ----- Helpers -----
function Ensure-EventSource {
    <#
      .SYNOPSIS
        Ensures custom event source exists on Application log.
    #>
    try {
        if (-not [System.Diagnostics.EventLog]::SourceExists($EventSource)) {
            New-EventLog -LogName $EventLog -Source $EventSource
        }
    } catch {
        # If we cannot create a source (rare on locked systems), fallback to "Application" built-in source.
        $script:EventSource = 'Application'
    }
}

function Write-AppLog {
    param(
        [ValidateSet('Information','Warning','Error')]
        [string]$Level = 'Information',
        [string]$Message,
        [int]$EventId = 1000
    )
    Write-EventLog -LogName $EventLog -Source $EventSource -EventId $EventId -EntryType $Level -Message $Message
}

function Get-PreferredSysmonPath {
    <#
      .SYNOPSIS
        Returns best sysmon executable path (prefers 64-bit on 64-bit OS).
    #>
    if ([Environment]::Is64BitOperatingSystem -and (Test-Path $SysmonX64)) { return $SysmonX64 }
    elseif (Test-Path $SysmonX86) { return $SysmonX86 }
    else { return $null }
}

function Get-SysmonServiceName {
    <#
      .SYNOPSIS
        Returns existing Sysmon service name if installed (Sysmon64 or Sysmon), else $null.
    #>
    foreach ($name in @('Sysmon64','Sysmon')) {
        try {
            $svc = Get-Service -Name $name -ErrorAction Stop
            if ($null -ne $svc) { return $name }
        } catch { }
    }
    return $null
}

function Get-SysmonInstalledExePath {
    <#
      .SYNOPSIS
        Reads the ImagePath from the Sysmon service to locate the installed exe.
    #>
    param([string]$ServiceName)
    if (-not $ServiceName) { return $null }
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
    try {
        $imagePath = (Get-ItemProperty -Path $regPath -Name ImagePath -ErrorAction Stop).ImagePath
        # ImagePath may contain quotes and arguments. Extract the first quoted or first token.
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
    <#
      .SYNOPSIS
        Runs Sysmon with arguments and returns a PSCustomObject with ExitCode, StdOut, StdErr.
    #>
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
    Ensure-EventSource
    Write-AppLog -Level Information -EventId $EID_Started -Message "Sysmon setup started. BaseDir='$BaseDir'. User='$(whoami)'."

    # Prerequisite checks
    $sysmonExe = Get-PreferredSysmonPath
    if (-not $sysmonExe) {
        Write-AppLog -Level Error -EventId $EID_PrereqError -Message "Sysmon executable not found. Looked for '$SysmonX64' and '$SysmonX86'."
        throw "Sysmon executable not found."
    }
    if (-not (Test-Path $ConfigPath)) {
        Write-AppLog -Level Error -EventId $EID_PrereqError -Message "Configuration file not found at '$ConfigPath'."
        throw "Sysmon configuration file missing."
    }

    $existingSvcName = Get-SysmonServiceName
    $installed = $false

    if ($null -eq $existingSvcName) {
        # --- Install Sysmon ---
        $args = @(
            '-accepteula',
            '-i', ('"' + $ConfigPath + '"')
        )
        $result = Invoke-Sysmon -Exe $sysmonExe -Arguments $args

        # Validate outcome (Sysmon typically returns 0 on success and creates a service)
        $existingSvcName = Get-SysmonServiceName
        if ($result.ExitCode -eq 0 -and $existingSvcName) {
            $installed = $true
            $installedExe = Get-SysmonInstalledExePath -ServiceName $existingSvcName
            $ver = Get-FileVersionString -Path $installedExe
            $msg = "Sysmon has been installed successfully. Service='$existingSvcName'. Version='${ver}'. Command='$($result.Command)'. Output='$($result.StdOut)'."
            Write-AppLog -Level Information -EventId $EID_Installed -Message $msg
        } else {
            $err = "Sysmon installation failed. ExitCode=$($result.ExitCode). StdErr='$($result.StdErr)'. StdOut='$($result.StdOut)'. Command='$($result.Command)'."
            Write-AppLog -Level Error -EventId $EID_Error -Message $err
            throw $err
        }
    } else {
        # --- Already installed: Update configuration ---
        $args = @(
            '-accepteula',
            '-c', ('"' + $ConfigPath + '"')
        )
        $result = Invoke-Sysmon -Exe $sysmonExe -Arguments $args

        if ($result.ExitCode -eq 0) {
            $installedExe = Get-SysmonInstalledExePath -ServiceName $existingSvcName
            $ver = Get-FileVersionString -Path $installedExe
            $msg = "Sysmon already installed. Configuration updated successfully. Service='$existingSvcName'. Version='${ver}'. Command='$($result.Command)'. Output='$($result.StdOut)'."
            Write-AppLog -Level Information -EventId $EID_Updated -Message $msg
        } else {
            $err = "Sysmon configuration update failed. ExitCode=$($result.ExitCode). StdErr='$($result.StdErr)'. StdOut='$($result.StdOut)'. Command='$($result.Command)'."
            Write-AppLog -Level Error -EventId $EID_Error -Message $err
            throw $err
        }
    }

    # Optional: ensure service is running
    $svcName = Get-SysmonServiceName
    if ($svcName) {
        try {
            $svc = Get-Service -Name $svcName -ErrorAction Stop
            if ($svc.Status -ne 'Running') {
                Start-Service -Name $svcName -ErrorAction Stop
            }
        } catch {
            Write-AppLog -Level Warning -EventId $EID_Skipped -Message "Sysmon service '$svcName' could not be started automatically. Error='$($_.Exception.Message)'."
        }
    }

} catch {
    # Top-level error handler
    $root = $_
    $msg = "Sysmon setup encountered an error: $($root.Exception.Message)"
    Write-AppLog -Level Error -EventId $EID_Error -Message $msg
    throw
}
