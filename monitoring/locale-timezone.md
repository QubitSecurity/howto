윈도우와 리눅스에서 공통으로 동작할 수 있는 방식으로 **현재 시스템 언어**와 **시스템 시간**(UTC Offset 포함)을 JSON 형태로 출력합니다:

---

## **Windows (PowerShell)**

```powershell
$language = (Get-Culture).Name
$now = Get-Date
$offset = $now.ToString("zzz")  # UTC Offset (+09:00 형태)

$result = @{
    language    = $language
    datetime    = $now.ToString("yyyy-MM-ddTHH:mm:ss")
    utc_offset  = $offset
}

$result | ConvertTo-Json -Compress
```

**예시 출력**

```json
{"language":"ko-KR","datetime":"2025-08-10T20:15:32","utc_offset":"+09:00"}
```

---

## **Linux (Bash)**

```bash
#!/bin/bash

LANGUAGE=$(locale | grep LANG= | cut -d= -f2)
DATETIME=$(date +"%Y-%m-%dT%H:%M:%S")
UTC_OFFSET=$(date +"%:z")

echo "{\"language\":\"$LANGUAGE\",\"datetime\":\"$DATETIME\",\"utc_offset\":\"$UTC_OFFSET\"}"
```

**예시 출력**

```json
{"language":"ko_KR.UTF-8","datetime":"2025-08-10T20:15:32","utc_offset":"+09:00"}
```

---
