#!/usr/bin/env bash
set -euo pipefail

# Setup script for SmartWatchProject
# Installs PowerShell, ESP-IDF, and Python packages.

ESP_ROOT="${ESP_ROOT:-$HOME/esp}"
export IDF_PATH="${IDF_PATH:-$ESP_ROOT/esp-idf}"
export IDF_TOOLS_PATH="${IDF_TOOLS_PATH:-$ESP_ROOT/idf-tools}"
PYTHON="${PYTHON:-python3}"

install_powershell() {
  if ! command -v pwsh >/dev/null 2>&1; then
    echo "Installing PowerShell..."
    sudo apt-get update
    sudo apt-get install -y wget apt-transport-https software-properties-common
    wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt-get update
    sudo apt-get install -y powershell
    rm packages-microsoft-prod.deb
  else
    echo "PowerShell already installed."
  fi
}

install_esp_idf() {
  if [ ! -d "$IDF_PATH" ]; then
    echo "Cloning ESP-IDF into $IDF_PATH..."
    mkdir -p "$(dirname "$IDF_PATH")"
    git clone --recursive https://github.com/espressif/esp-idf.git "$IDF_PATH"
  fi
  echo "Installing ESP-IDF tools..."
  bash "$IDF_PATH/install.sh" esp32s3
}

install_python_packages() {
  if [ -f requirements.txt ]; then
    echo "Installing Python packages..."
    "$PYTHON" -m pip install --upgrade pip
    "$PYTHON" -m pip install --no-cache-dir -r requirements.txt
  fi
}

install_powershell
install_esp_idf
install_python_packages

echo "\nInstallation complete."
echo "To activate the ESP-IDF environment run:"
echo "  source \"$IDF_PATH/export.sh\""
echo "\nEnvironment variables:"
echo "  export IDF_PATH=$IDF_PATH"
echo "  export IDF_TOOLS_PATH=$IDF_TOOLS_PATH"
