# Install-Sysmon.ps1
# Sysmon 설치 자동화 스크립트 (PLURA EDR 에이전트용)

$SysmonPath = "C:\Program Files\PLURA\sysmon.exe"
$ConfigPath = "C:\Program Files\PLURA\sysmon-plura.xml"

Write-Host "[*] Sysmon 자동 설치 시작..."

# Sysmon 실행 파일 확인
if (-Not (Test-Path $SysmonPath)) {
    Write-Error "Sysmon 실행 파일을 찾을 수 없습니다: $SysmonPath"
    exit 1
}

# 설정 파일 확인
if (-Not (Test-Path $ConfigPath)) {
    Write-Error "Sysmon 설정 파일을 찾을 수 없습니다: $ConfigPath"
    exit 1
}

# 기존 Sysmon 설치 여부 확인
$service = Get-Service -Name "Sysmon64" -ErrorAction SilentlyContinue
if ($null -ne $service) {
    Write-Host "[*] 기존 Sysmon 제거 중..."
    & $SysmonPath -u
    Start-Sleep -Seconds 2
}

# Sysmon 설치
Write-Host "[*] Sysmon 설치 중..."
& $SysmonPath -accepteula -i $ConfigPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] Sysmon 설치 완료!"
} else {
    Write-Error "[-] Sysmon 설치 실패. 종료 코드: $LASTEXITCODE"
    exit 1
}

# 서비스 상태 확인
$service = Get-Service -Name "Sysmon64" -ErrorAction SilentlyContinue
if ($null -ne $service -and $service.Status -eq 'Running') {
    Write-Host "[+] Sysmon 서비스 실행 중."
} else {
    Write-Warning "[!] Sysmon 서비스가 실행되지 않았습니다. 수동 확인 필요."
}
