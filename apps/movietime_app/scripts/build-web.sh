#!/usr/bin/env sh
set -eu

API_URL="${1:-}"

if [ -z "$API_URL" ]; then
  flutter build web
else
  flutter build web --dart-define="MOVIETIME_API_BASE_URL=$API_URL"
fi
