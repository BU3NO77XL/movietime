@echo off
setlocal

set "API_URL=%~1"
if "%API_URL%"=="" set "API_URL=https://movietimeweb.vercel.app"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-release.ps1" -ApiUrl "%API_URL%"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo.
  echo O build release falhou. A versao nao foi alterada.
)

exit /b %EXIT_CODE%