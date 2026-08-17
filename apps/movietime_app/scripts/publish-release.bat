@echo off
setlocal

set "API_URL=%~1"
if "%API_URL%"=="" set "API_URL=https://movietimeweb.vercel.app"

call "%~dp0build-release.bat" "%API_URL%"
if errorlevel 1 exit /b %ERRORLEVEL%

node "%~dp0..\..\movietime_web\scripts\publish-release.mjs"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo.
  echo O upload da release falhou. O APK foi gerado, mas nao foi publicado.
)

exit /b %EXIT_CODE%
