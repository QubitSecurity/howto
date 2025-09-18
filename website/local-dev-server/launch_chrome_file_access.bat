@echo off
setlocal enabledelayedexpansion

REM =========================
REM Launch Chrome with --allow-file-access-from-files
REM Usage: double-click this file, or drag & drop an HTML file onto it.
REM =========================

REM 1) Try to find Chrome in common locations
set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME=%LocalAppData%\Google\Chrome\Application\chrome.exe"

if not defined CHROME (
  echo [ERROR] Chrome not found in standard locations.
  echo Please install Google Chrome or edit this script to point to chrome.exe.
  pause
  exit /b 1
)

REM 2) Determine target file. If an argument is passed, use it. Otherwise use your default page.
if "%~1"=="" (
  set "TARGET_FILE=C:\Users\eliot\Desktop\plura-index-6.0\ko\customer.html"
) else (
  set "TARGET_FILE=%~1"
)

if not exist "%TARGET_FILE%" (
  echo [ERROR] Target file not found:
  echo   %TARGET_FILE%
  echo Edit this script or drag&drop a valid HTML file onto it.
  pause
  exit /b 1
)

REM Convert to file:// URL form by letting Chrome handle the path directly.
REM 3) Launch Chrome with a dedicated temp profile so your main browser stays untouched.
set "TMP_PROFILE=%TEMP%\chrome-file-access-profile"

echo Launching:
echo   "!CHROME!" --allow-file-access-from-files --user-data-dir="!TMP_PROFILE!" "file:///%TARGET_FILE%"
start "" "!CHROME!" --allow-file-access-from-files --user-data-dir="!TMP_PROFILE!" "file:///%TARGET_FILE%"

endlocal
