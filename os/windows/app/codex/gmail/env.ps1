$envPath = "C:\git\quark\quark\.env"

$content = @"
GMAIL_ENABLED=true
GMAIL_DRY_RUN=true
GMAIL_TO=joo@qubitsec.com
GMAIL_CC=
GMAIL_BCC=
GMAIL_SUBJECT_PREFIX=[PLURA-XDR]
GMAIL_FROM_NAME=PLURA-XDR AI Agent
GMAIL_SEND_ON_RISK=높음
GMAIL_INCLUDE_JSON_ATTACHMENT=true
GMAIL_INCLUDE_SCREENSHOT_PATHS=true
"@

[System.IO.File]::WriteAllText($envPath, $content, [System.Text.UTF8Encoding]::new($true))
