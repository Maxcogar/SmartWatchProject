<#
  Setup script for SmartWatchProject (Windows)
  Installs PowerShell 7, ESP-IDF, and Python packages.
#>
$ErrorActionPreference = 'Stop'

if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing PowerShell 7...'
    winget install --id Microsoft.PowerShell --source winget -e
}

$espRoot = if ($env:ESP_ROOT) { $env:ESP_ROOT } else { Join-Path $env:USERPROFILE 'esp' }
$env:IDF_PATH = if ($env:IDF_PATH) { $env:IDF_PATH } else { Join-Path $espRoot 'esp-idf' }
$env:IDF_TOOLS_PATH = if ($env:IDF_TOOLS_PATH) { $env:IDF_TOOLS_PATH } else { Join-Path $espRoot 'idf-tools' }

if (-not (Test-Path $env:IDF_PATH)) {
    Write-Host "Cloning ESP-IDF into $env:IDF_PATH..."
    git clone --recursive https://github.com/espressif/esp-idf.git $env:IDF_PATH
}

Write-Host 'Installing ESP-IDF tools...'
& "$env:IDF_PATH/install.ps1" esp32s3

if (Test-Path 'requirements.txt') {
    Write-Host 'Installing Python packages...'
    python -m pip install --upgrade pip
    python -m pip install -r requirements.txt
}

Write-Host "`nInstallation complete."
Write-Host 'To activate the ESP-IDF environment run:'
Write-Host "  & `"$env:IDF_PATH/export.ps1`""
Write-Host "`nEnvironment variables:"
Write-Host "  setx IDF_PATH `"$env:IDF_PATH`""
Write-Host "  setx IDF_TOOLS_PATH `"$env:IDF_TOOLS_PATH`""
