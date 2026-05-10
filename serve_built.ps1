# Alternative: serve the already-built web bundle (no Flutter needed).
# Faster than start_app.ps1 if you just want to look at the UI.

$ErrorActionPreference = 'Stop'
$dist = Join-Path $PSScriptRoot 'build\web'
if (-not (Test-Path $dist)) {
  Write-Host "Build nao encontrada. Rode antes:" -ForegroundColor Yellow
  Write-Host "  C:\flutter\bin\flutter.bat build web --release" -ForegroundColor Yellow
  exit 1
}

# Try Python (most Windows installs have it)
$python = Get-Command python -ErrorAction SilentlyContinue
if ($python) {
  Write-Host "Servindo $dist em http://localhost:8080 ..." -ForegroundColor Cyan
  Set-Location $dist
  python -m http.server 8080
  exit 0
}

Write-Host "Python nao encontrado. Instale Python ou rode start_app.ps1." -ForegroundColor Yellow
