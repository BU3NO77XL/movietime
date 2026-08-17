param(
  [string]$ApiUrl = 'https://movietimeweb.vercel.app'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'
$apkSource = Join-Path $projectRoot 'build/app/outputs/flutter-apk/app-release.apk'
$releaseDir = Join-Path $projectRoot 'build/releases'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter nao foi encontrado no PATH.'
}

$pubspec = [IO.File]::ReadAllText($pubspecPath)
$versionMatch = [regex]::Match($pubspec, '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$')
if (-not $versionMatch.Success) {
  throw 'Nao foi possivel localizar uma versao no pubspec.yaml.'
}

$major = [int]$versionMatch.Groups[1].Value
$minor = [int]$versionMatch.Groups[2].Value
$patch = [int]$versionMatch.Groups[3].Value + 1
$buildNumber = [int]$versionMatch.Groups[4].Value + 1
$nextVersion = "$major.$minor.$patch"
$nextVersionLine = "version: $nextVersion+$buildNumber"

Write-Host "Build final MovieTime $nextVersion+$buildNumber" -ForegroundColor Cyan
Write-Host "API: $ApiUrl"
Write-Host 'A versao do pubspec so sera atualizada se o build terminar com sucesso.'

Push-Location $projectRoot
try {
  & flutter build apk --release `
    "--build-name=$nextVersion" `
    "--build-number=$buildNumber" `
    "--dart-define=MOVIETIME_API_BASE_URL=$ApiUrl"
  if ($LASTEXITCODE -ne 0) {
    throw "Build release falhou com codigo $LASTEXITCODE. A versao nao foi alterada."
  }

  $updatedPubspec = [regex]::Replace(
    $pubspec,
    '(?m)^version:\s*\d+\.\d+\.\d+\+\d+\s*$',
    $nextVersionLine,
    1
  )
  [IO.File]::WriteAllText($pubspecPath, $updatedPubspec)

  New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
  $apkName = "movietime-v$nextVersion.apk"
  $apkTarget = Join-Path $releaseDir $apkName
  Copy-Item -LiteralPath $apkSource -Destination $apkTarget -Force
  $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $apkTarget).Hash.ToLowerInvariant()
  [IO.File]::WriteAllText(
    (Join-Path $releaseDir "$apkName.sha256"),
    "$hash  $apkName"
  )

  Write-Host ''
  Write-Host 'Build final concluido.' -ForegroundColor Green
  Write-Host "APK: $apkTarget"
  Write-Host "SHA256: $hash"
  Write-Host "Versao gravada no pubspec.yaml: $nextVersion+$buildNumber"
} finally {
  Pop-Location
}