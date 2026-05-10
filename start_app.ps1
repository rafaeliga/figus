# Start the Figus app in Chrome (web mode, no Android SDK required).
# Run from C:\Dani_Dev\figus

$ErrorActionPreference = 'Stop'

$flutter = 'C:\flutter\bin'
if (-not ($env:Path -like "*$flutter*")) {
  $env:Path = "$flutter;" + $env:Path
}

Write-Host "Iniciando Figus em Chrome..." -ForegroundColor Cyan
Write-Host "(primeira execucao demora ~30s pra compilar)" -ForegroundColor DarkGray
Write-Host ""

flutter run -d chrome --web-port=8080
