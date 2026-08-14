@echo off
setlocal

set "API_URL=%~1"

if "%API_URL%"=="" (
  flutter build web
) else (
  flutter build web --dart-define=MOVIETIME_API_BASE_URL=%API_URL%
)
