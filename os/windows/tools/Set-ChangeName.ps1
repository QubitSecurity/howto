# 대상 폴더
$Path = 'D:\plura\res\images\customer'

# 접두어 제거 대상만 선택하여 처리
Get-ChildItem -Path $Path -File |
  Where-Object { $_.Name -like 'c_logo_*' } |
  ForEach-Object {
    $newName = $_.Name -replace '^c_logo_', ''     # 접두어 제거
    $target  = Join-Path $_.DirectoryName $newName

    if (Test-Path -LiteralPath $target) {
      Write-Warning "건너뜀: '$($_.Name)' → '$newName' (이미 같은 이름이 존재)"
    } else {
      Rename-Item -LiteralPath $_.FullName -NewName $newName
      Write-Host "변경됨: '$($_.Name)' → '$newName'"
    }
  }
