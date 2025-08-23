# ESP32-S3 ADHD SmartWatch Build Automation Script
# Professional-grade build system with quality gates and automation

param(
    [string]$Target = "esp32s3",
    [ValidateSet("debug", "production", "test")]
    [string]$Config = "debug",
    [switch]$Clean,
    [switch]$Flash,
    [switch]$Monitor,
    [switch]$QualityGates,
    [switch]$ShowSize,
    [string]$Port = "COM3",
    [int]$Baudrate = 115200
)

# Build configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Paths
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptPath
$FirmwarePath = $ProjectRoot
$QualityGatesPath = Join-Path $ProjectRoot "quality_gates"
$LogsPath = Join-Path $ProjectRoot "build_logs"

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    switch ($Color) {
        "Red" { Write-Host $Message -ForegroundColor Red }
        "Green" { Write-Host $Message -ForegroundColor Green }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Blue" { Write-Host $Message -ForegroundColor Blue }
        "Cyan" { Write-Host $Message -ForegroundColor Cyan }
        "Magenta" { Write-Host $Message -ForegroundColor Magenta }
        default { Write-Host $Message }
    }
}

# Header
function Show-BuildHeader {
    Write-ColorOutput "`n================== ESP32-S3 ADHD SmartWatch Build System ==================" "Cyan"
    Write-ColorOutput "Project: ESP32-S3 ADHD-Friendly SmartWatch" "White"
    Write-ColorOutput "Target: $Target" "White"
    Write-ColorOutput "Configuration: $Config" "White"
    Write-ColorOutput "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "White"
    Write-ColorOutput "=========================================================================`n" "Cyan"
}

# Initialize environment
function Initialize-Environment {
    Write-ColorOutput "🔧 Initializing build environment..." "Yellow"
    
    # Check if ESP-IDF is installed
    $espIdfPath = $env:IDF_PATH
    if (-not $espIdfPath -or -not (Test-Path $espIdfPath)) {
        Write-ColorOutput "❌ ESP-IDF not found. Please run ESP-IDF environment setup." "Red"
        exit 1
    }
    
    # Activate ESP-IDF environment
    Write-ColorOutput "Activating ESP-IDF environment..." "Blue"
    $activateScript = Join-Path $espIdfPath "export.ps1"
    if (Test-Path $activateScript) {
        & $activateScript
    } else {
        # Fallback to batch script
        $activateBat = Join-Path $espIdfPath "export.bat"
        if (Test-Path $activateBat) {
            $envOutput = cmd /c "`"$activateBat`" `& set" 
            $envOutput | ForEach-Object {
                if ($_ -match '^([^=]+)=(.*)$') {
                    Set-Item -Path "env:$($Matches[1])" -Value $Matches[2]
                }
            }
        }
    }
    
    # Verify idf.py is available
    try {
        $idfVersion = & idf.py --version 2>&1
        Write-ColorOutput "✅ ESP-IDF Version: $idfVersion" "Green"
    } catch {
        Write-ColorOutput "❌ Failed to run idf.py. ESP-IDF environment not properly set up." "Red"
        exit 1
    }
    
    # Create logs directory
    if (-not (Test-Path $LogsPath)) {
        New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null
    }
    
    # Change to firmware directory
    Push-Location $FirmwarePath
}

# Configure build
function Set-BuildConfiguration {
    Write-ColorOutput "⚙️  Configuring build for $Config mode..." "Yellow"
    
    # Set target
    Write-ColorOutput "Setting target to $Target..." "Blue"
    $targetResult = & idf.py set-target $Target 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Failed to set target: $targetResult" "Red"
        exit 1
    }
    
    # Configure based on build type
    switch ($Config) {
        "debug" {
            Write-ColorOutput "Applying debug configuration..." "Blue"
            $env:SDKCONFIG_DEFAULTS = "sdkconfig.defaults;sdkconfig.debug"
            # Enable debug features
            & idf.py menuconfig --non-interactive --config-file="sdkconfig.debug" 2>&1 | Out-Null
        }
        "production" {
            Write-ColorOutput "Applying production configuration..." "Blue"
            $env:SDKCONFIG_DEFAULTS = "sdkconfig.defaults;sdkconfig.production"
            # Enable production optimizations
            & idf.py menuconfig --non-interactive --config-file="sdkconfig.production" 2>&1 | Out-Null
        }
        "test" {
            Write-ColorOutput "Applying test configuration..." "Blue"
            $env:SDKCONFIG_DEFAULTS = "sdkconfig.defaults;sdkconfig.test"
            # Enable test features
            & idf.py menuconfig --non-interactive --config-file="sdkconfig.test" 2>&1 | Out-Null
        }
    }
    
    Write-ColorOutput "✅ Build configuration set successfully" "Green"
}

# Clean build
function Invoke-CleanBuild {
    if ($Clean) {
        Write-ColorOutput "🧹 Cleaning build artifacts..." "Yellow"
        
        $cleanResult = & idf.py fullclean 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Clean failed: $cleanResult" "Red"
            exit 1
        }
        
        # Remove additional build artifacts
        $artifactsToRemove = @("build", "sdkconfig", "sdkconfig.old", "dependencies.lock")
        foreach ($artifact in $artifactsToRemove) {
            if (Test-Path $artifact) {
                Remove-Item -Path $artifact -Recurse -Force
                Write-ColorOutput "Removed $artifact" "Blue"
            }
        }
        
        Write-ColorOutput "✅ Clean completed successfully" "Green"
    }
}

# Build project
function Invoke-Build {
    Write-ColorOutput "🔨 Building project..." "Yellow"
    
    $logFile = Join-Path $LogsPath "build_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    Write-ColorOutput "Build log: $logFile" "Blue"
    
    # Start build with timing
    $buildStartTime = Get-Date
    
    # Build command with progress and error handling
    $buildArgs = @("build", "-v")
    if ($Config -eq "production") {
        $buildArgs += "--cmake-warn-uninitialized"
    }
    
    Write-ColorOutput "Executing: idf.py $($buildArgs -join ' ')" "Blue"
    
    $buildProcess = Start-Process -FilePath "idf.py" -ArgumentList $buildArgs -RedirectStandardOutput $logFile -RedirectStandardError "$logFile.err" -NoNewWindow -PassThru
    $buildProcess.WaitForExit()
    
    $buildEndTime = Get-Date
    $buildDuration = $buildEndTime - $buildStartTime
    
    if ($buildProcess.ExitCode -eq 0) {
        Write-ColorOutput "✅ Build completed successfully in $($buildDuration.ToString('mm\:ss'))" "Green"
        
        # Show build summary
        if (Test-Path "build/smartwatch.bin") {
            $binarySize = (Get-Item "build/smartwatch.bin").Length
            $binaryKB = [math]::Round($binarySize / 1024, 2)
            Write-ColorOutput "📦 Binary size: $binaryKB KB" "Cyan"
        }
    } else {
        Write-ColorOutput "❌ Build failed with exit code $($buildProcess.ExitCode)" "Red"
        
        # Show error details
        if (Test-Path "$logFile.err") {
            Write-ColorOutput "❌ Build errors:" "Red"
            Get-Content "$logFile.err" | Select-Object -Last 10 | ForEach-Object { Write-ColorOutput $_ "Red" }
        }
        exit 1
    }
}

# Show size analysis
function Show-SizeAnalysis {
    if ($ShowSize) {
        Write-ColorOutput "📊 Size Analysis..." "Yellow"
        
        if (Test-Path "build/smartwatch.map") {
            Write-ColorOutput "Memory usage by component:" "Blue"
            & idf.py size 2>&1
            
            # Custom size analysis
            Write-ColorOutput "`nDetailed size breakdown:" "Blue"
            & idf.py size-components 2>&1
        }
    }
}

# Flash firmware
function Invoke-Flash {
    if ($Flash) {
        Write-ColorOutput "📱 Flashing firmware to device..." "Yellow"
        
        # Verify device connection
        Write-ColorOutput "Checking device on port $Port..." "Blue"
        
        $flashArgs = @("-p", $Port, "flash")
        if ($Baudrate -ne 115200) {
            $flashArgs = @("-p", $Port, "-b", $Baudrate, "flash")
        }
        
        Write-ColorOutput "Executing: idf.py $($flashArgs -join ' ')" "Blue"
        
        $flashResult = & idf.py @flashArgs 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Flash completed successfully" "Green"
        } else {
            Write-ColorOutput "❌ Flash failed: $flashResult" "Red"
            exit 1
        }
    }
}

# Monitor serial output
function Start-Monitor {
    if ($Monitor) {
        Write-ColorOutput "📺 Starting serial monitor..." "Yellow"
        Write-ColorOutput "Press Ctrl+] to exit monitor" "Blue"
        
        $monitorArgs = @("-p", $Port, "monitor")
        & idf.py @monitorArgs
    }
}

# Run quality gates
function Invoke-QualityGates {
    if ($QualityGates) {
        Write-ColorOutput "🛡️  Running quality gate checks..." "Yellow"
        
        $qualityScript = Join-Path $QualityGatesPath "run_quality_checks.ps1"
        if (Test-Path $qualityScript) {
            & $qualityScript
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "❌ Quality gates failed" "Red"
                exit 1
            }
        } else {
            Write-ColorOutput "⚠️  Quality gates script not found at $qualityScript" "Yellow"
        }
    }
}

# Generate build report
function New-BuildReport {
    Write-ColorOutput "📄 Generating build report..." "Yellow"
    
    $reportFile = Join-Path $LogsPath "build_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        target = $Target
        configuration = $Config
        success = $true
        duration = "N/A"
        binary_size = "N/A"
        flash_size = "N/A"
        ram_usage = "N/A"
        warnings = 0
        errors = 0
    }
    
    # Add size information if available
    if (Test-Path "build/smartwatch.bin") {
        $report.binary_size = (Get-Item "build/smartwatch.bin").Length
    }
    
    # Save report
    $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportFile -Encoding UTF8
    Write-ColorOutput "Build report saved to: $reportFile" "Blue"
}

# Cleanup
function Complete-Build {
    Pop-Location
    Write-ColorOutput "`n✅ Build process completed successfully!" "Green"
    Write-ColorOutput "Build logs available in: $LogsPath" "Blue"
}

# Error handling
function Handle-BuildError {
    param([string]$ErrorMessage)
    
    Write-ColorOutput "`n❌ Build process failed: $ErrorMessage" "Red"
    Pop-Location
    exit 1
}

# Main execution
try {
    Show-BuildHeader
    Initialize-Environment
    Set-BuildConfiguration
    Invoke-CleanBuild
    Invoke-Build
    Show-SizeAnalysis
    Invoke-QualityGates
    Invoke-Flash
    New-BuildReport
    Start-Monitor
    Complete-Build
    
} catch {
    Handle-BuildError $_.Exception.Message
}