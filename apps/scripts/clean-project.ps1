param(
  [switch]$Deep,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Remove-GeneratedPath([string]$RelativePath) {
  $path = Join-Path $root $RelativePath
  if (-not (Test-Path -LiteralPath $path)) { return }
  if ($DryRun) {
    Write-Host "[dry-run] removeria $RelativePath"
    return
  }
  Remove-Item -LiteralPath $path -Recurse -Force
  Write-Host "removido $RelativePath"
}

$appRoot = Join-Path $root 'movietime_app'
if (-not $DryRun -and (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Push-Location $appRoot
  try { & flutter clean | Out-Host } finally { Pop-Location }
}

@(
  'movietime_app/build',
  'movietime_app/.dart_tool',
  'movietime_app/android/.gradle',
  'movietime_app/android/.kotlin',
  'movietime_web/.next',
  'movietime_web/coverage',
  'movietime_web/dist',
  'movietime_web/tsconfig.tsbuildinfo'
) | ForEach-Object { Remove-GeneratedPath $_ }

if ($Deep) {
  @(
    'movietime_web/node_modules',
    'movietime_app/ios/Pods'
  ) | ForEach-Object { Remove-GeneratedPath $_ }
}

Write-Host ''
Write-Host 'Limpeza concluida. Codigo-fonte, chaves, banco e arquivos de lock foram preservados.' -ForegroundColor Green