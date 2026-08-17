@echo off
setlocal

set "MODE="
if /I "%~1"=="--deep" set "MODE=-Deep"
if /I "%~1"=="--dry-run" set "MODE=-DryRun"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0clean-project.ps1" %MODE%
exit /b %ERRORLEVEL%