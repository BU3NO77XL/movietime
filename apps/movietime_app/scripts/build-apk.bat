@echo off
setlocal

set "API_URL=%~1"

if "%API_URL%"=="" (
  flutter build apk
) else (
  flutter build apk --dart-define=MOVIETIME_API_BASE_URL=%API_URL%
)
