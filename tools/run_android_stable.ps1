$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$flutterSdk = Join-Path $projectRoot "tools\flutter\bin\flutter.bat"
$deviceId = "emulator-5554"

if (-not (Test-Path $flutterSdk)) {
  throw "Flutter SDK not found at $flutterSdk"
}

# Force project-local Flutter SDK first to avoid SDK mismatch.
$env:PATH = "$(Join-Path $projectRoot 'tools\flutter\bin');$env:PATH"

Write-Host "Using Flutter SDK: $flutterSdk"
Write-Host "Running on device: $deviceId"

& $flutterSdk pub get
& $flutterSdk run -d $deviceId --target lib/main.dart --device-timeout 120
