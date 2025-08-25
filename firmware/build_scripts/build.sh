#!/usr/bin/env bash

# ESP32-S3 ADHD SmartWatch Build Automation Script (bash version)
# Mirrors build.ps1 logic for Unix-like environments

set -euo pipefail

# Default parameters
TARGET="esp32s3"
CONFIG="debug"
CLEAN=false
FLASH=false
MONITOR=false
QUALITY_GATES=false
SHOW_SIZE=false
PORT="/dev/ttyUSB0"
BAUDRATE=115200

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Options:
  --target <chip>            ESP-IDF target (default: esp32s3)
  --config <debug|production|test> Build configuration (default: debug)
  --clean                    Perform full clean
  --flash                    Flash firmware to device
  --monitor                  Start serial monitor after flash
  --quality-gates            Run quality gate checks
  --show-size                Display size information after build
  --port <PORT>              Serial port (default: /dev/ttyUSB0)
  --baudrate <RATE>          Serial baudrate (default: 115200)
  -h, --help                 Show this help message
USAGE
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --config) CONFIG="$2"; shift 2 ;;
    --clean) CLEAN=true; shift ;;
    --flash) FLASH=true; shift ;;
    --monitor) MONITOR=true; shift ;;
    --quality-gates) QUALITY_GATES=true; shift ;;
    --show-size) SHOW_SIZE=true; shift ;;
    --port) PORT="$2"; shift 2 ;;
    --baudrate) BAUDRATE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# Paths
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_PATH/.." && pwd)"
FIRMWARE_PATH="$PROJECT_ROOT"
QUALITY_GATES_PATH="$PROJECT_ROOT/quality_gates"
LOGS_PATH="$PROJECT_ROOT/build_logs"

# Color output
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
cyan='\033[0;36m'
magenta='\033[0;35m'
reset='\033[0m'

color_echo() {
  local color="$1"; shift
  case "$color" in
    red) printf "${red}%s${reset}\n" "$*" ;;
    green) printf "${green}%s${reset}\n" "$*" ;;
    yellow) printf "${yellow}%s${reset}\n" "$*" ;;
    blue) printf "${blue}%s${reset}\n" "$*" ;;
    cyan) printf "${cyan}%s${reset}\n" "$*" ;;
    magenta) printf "${magenta}%s${reset}\n" "$*" ;;
    *) printf "%s\n" "$*" ;;
  esac
}

show_build_header() {
  color_echo cyan "\n================== ESP32-S3 ADHD SmartWatch Build System =================="
  color_echo white "Project: ESP32-S3 ADHD-Friendly SmartWatch"
  color_echo white "Target: $TARGET"
  color_echo white "Configuration: $CONFIG"
  color_echo white "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
  color_echo cyan "========================================================================\n"
}

initialize_environment() {
  color_echo yellow "🔧 Initializing build environment..."

  if [[ -z "${IDF_PATH:-}" || ! -d "$IDF_PATH" ]]; then
    color_echo red "❌ ESP-IDF not found. Please run ESP-IDF environment setup."
    exit 1
  fi

  color_echo blue "Activating ESP-IDF environment..."
  if [[ -f "$IDF_PATH/export.sh" ]]; then
    # shellcheck disable=SC1090
    source "$IDF_PATH/export.sh"
  else
    color_echo red "❌ export.sh not found in $IDF_PATH"
    exit 1
  fi

  if idf.py --version >/tmp/idf_version 2>&1; then
    color_echo green "✅ ESP-IDF Version: $(cat /tmp/idf_version)"
  else
    color_echo red "❌ Failed to run idf.py. ESP-IDF environment not properly set up."
    exit 1
  fi

  mkdir -p "$LOGS_PATH"
  pushd "$FIRMWARE_PATH" >/dev/null
}

set_build_configuration() {
  color_echo yellow "⚙️  Configuring build for $CONFIG mode..."
  color_echo blue "Setting target to $TARGET..."
  if ! idf.py set-target "$TARGET" >/dev/null 2>&1; then
    color_echo red "❌ Failed to set target"
    exit 1
  fi

  case "$CONFIG" in
    debug)
      color_echo blue "Applying debug configuration..."
      export SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.debug"
      idf.py menuconfig --non-interactive --config-file="sdkconfig.debug" >/dev/null 2>&1
      ;;
    production)
      color_echo blue "Applying production configuration..."
      export SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.production"
      idf.py menuconfig --non-interactive --config-file="sdkconfig.production" >/dev/null 2>&1
      ;;
    test)
      color_echo blue "Applying test configuration..."
      export SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.test"
      idf.py menuconfig --non-interactive --config-file="sdkconfig.test" >/dev/null 2>&1
      ;;
    *)
      color_echo red "Invalid configuration: $CONFIG"
      exit 1
      ;;
  esac
  color_echo green "✅ Build configuration set successfully"
}

invoke_clean_build() {
  if $CLEAN; then
    color_echo yellow "🧹 Cleaning build artifacts..."
    idf.py fullclean >/dev/null 2>&1 || { color_echo red "❌ Clean failed"; exit 1; }
    rm -rf build sdkconfig sdkconfig.old dependencies.lock || true
    color_echo green "✅ Clean completed successfully"
  fi
}

invoke_build() {
  color_echo yellow "🔨 Building project..."
  local log_file="$LOGS_PATH/build_$(date +%Y%m%d_%H%M%S).log"
  color_echo blue "Build log: $log_file"
  local start_time=$(date +%s)
  local build_args=(build -v)
  [[ "$CONFIG" == "production" ]] && build_args+=("--cmake-warn-uninitialized")
  color_echo blue "Executing: idf.py ${build_args[*]}"
  if idf.py "${build_args[@]}" >"$log_file" 2>"$log_file.err"; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    color_echo green "✅ Build completed successfully in $(printf '%02d:%02d' $((duration/60)) $((duration%60)))"
    if [[ -f build/smartwatch.bin ]]; then
      local size=$(stat -c%s build/smartwatch.bin)
      local kb=$(awk "BEGIN {printf \"%.2f\", $size/1024}")
      color_echo cyan "📦 Binary size: $kb KB"
    fi
  else
    color_echo red "❌ Build failed"; tail -n 10 "$log_file.err"; exit 1
  fi
}

show_size_analysis() {
  if $SHOW_SIZE; then
    color_echo yellow "📊 Size Analysis..."
    if [[ -f build/smartwatch.map ]]; then
      color_echo blue "Memory usage by component:"; idf.py size
      color_echo blue "\nDetailed size breakdown:"; idf.py size-components
    fi
  fi
}

invoke_flash() {
  if $FLASH; then
    color_echo yellow "📱 Flashing firmware to device..."
    color_echo blue "Checking device on port $PORT..."
    local flash_args=("-p" "$PORT")
    [[ "$BAUDRATE" != 115200 ]] && flash_args+=("-b" "$BAUDRATE")
    flash_args+=(flash)
    color_echo blue "Executing: idf.py ${flash_args[*]}"
    if ! idf.py "${flash_args[@]}"; then
      color_echo red "❌ Flash failed"; exit 1
    fi
  fi
}

start_monitor() {
  if $MONITOR; then
    color_echo yellow "📺 Starting serial monitor..."
    color_echo blue "Press Ctrl+] to exit monitor"
    idf.py -p "$PORT" monitor
  fi
}

invoke_quality_gates() {
  if $QUALITY_GATES; then
    color_echo yellow "🛡️  Running quality gate checks..."
    local qscript="$QUALITY_GATES_PATH/run_quality_checks.ps1"
    if [[ -f "$qscript" ]]; then
      if command -v pwsh >/dev/null 2>&1; then
        if ! pwsh "$qscript"; then
          color_echo red "❌ Quality gates failed"; exit 1
        fi
      else
        color_echo yellow "⚠️  PowerShell not available to run quality gates"
      fi
    else
      color_echo yellow "⚠️  Quality gates script not found at $qscript"
    fi
  fi
}

new_build_report() {
  color_echo yellow "📄 Generating build report..."
  local report_file="$LOGS_PATH/build_report_$(date +%Y%m%d_%H%M%S).json"
  local binary_size="N/A"
  [[ -f build/smartwatch.bin ]] && binary_size=$(stat -c%s build/smartwatch.bin)
  cat <<REPORT >"$report_file"
{
  "timestamp": "$(date '+%Y-%m-%dT%H:%M:%S')",
  "target": "$TARGET",
  "configuration": "$CONFIG",
  "success": true,
  "duration": "N/A",
  "binary_size": "$binary_size",
  "flash_size": "N/A",
  "ram_usage": "N/A",
  "warnings": 0,
  "errors": 0
}
REPORT
  color_echo blue "Build report saved to: $report_file"
}

complete_build() {
  popd >/dev/null
  color_echo green "\n✅ Build process completed successfully!"
  color_echo blue "Build logs available in: $LOGS_PATH"
}

handle_build_error() {
  local exit_code=$?
  color_echo red "\n❌ Build process failed"; popd >/dev/null 2>&1 || true; exit $exit_code
}

trap handle_build_error ERR

show_build_header
initialize_environment
set_build_configuration
invoke_clean_build
invoke_build
show_size_analysis
invoke_quality_gates
invoke_flash
new_build_report
start_monitor
complete_build

