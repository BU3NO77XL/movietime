@echo off
setlocal

set "API_URL=%~1"

if "%API_URL%"=="" (
  flutter run
) else (
  flutter run --dart-define=MOVIETIME_API_BASE_URL=%API_URL%
)
