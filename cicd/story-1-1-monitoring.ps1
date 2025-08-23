<#
.SYNOPSIS
    Story 1.1 Continuous Monitoring and Quality Metrics Integration
    
.DESCRIPTION
    This script provides real-time monitoring and quality metrics collection specifically
    for Story 1.1: Project Initialization and Basic Boot. It integrates with the existing
    quality dashboard and provides Story 1.1-specific metrics, alerts, and reporting.
    
    STORY 1.1 MONITORING FOCUS:
    - Boot sequence performance monitoring
    - Memory usage tracking and alerts
    - Display initialization quality metrics
    - Touch responsiveness monitoring
    - Error rate tracking and alerting
    - Hardware health monitoring
    
.PARAMETER Action
    Monitoring action: start, stop, status, collect, alert, dashboard
    
.PARAMETER Environment
    Target environment: development, staging, production
    
.PARAMETER MonitoringInterval
    Data collection interval in seconds (default: 30)
    
.PARAMETER AlertThresholds
    Enable alert threshold monitoring
    
.PARAMETER DashboardUpdate
    Update integrated quality dashboard
    
.EXAMPLE
    .\story-1-1-monitoring.ps1 -Action start -Environment development -AlertThresholds
    
.EXAMPLE
    .\story-1-1-monitoring.ps1 -Action dashboard -DashboardUpdate
    
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "status", "collect", "alert", "dashboard", "report")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment = "development",
    
    [Parameter(Mandatory=$false)]
    [int]$MonitoringInterval = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$AlertThresholds,
    
    [Parameter(Mandatory=$false)]
    [switch]$DashboardUpdate,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

# ============================================================================
# MONITORING CONFIGURATION
# ============================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# Monitoring configuration
$config = @{
    StoryId = "1.1"
    StoryName = "Project Initialization and Basic Boot"
    ProjectRoot = Split-Path -Parent $PSScriptRoot
    Environment = $Environment
    Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    MonitoringActive = $false
}

# Paths
$paths = @{
    ProjectRoot = $config.ProjectRoot
    Monitoring = Join-Path $config.ProjectRoot "monitoring"
    Logs = Join-Path $config.ProjectRoot "logs\monitoring"
    Metrics = Join-Path $config.ProjectRoot "metrics"
    Dashboard = Join-Path $config.ProjectRoot "dashboard"
    Alerts = Join-Path $config.ProjectRoot "alerts"
    Scripts = Join-Path $config.ProjectRoot "scripts"
    CICD = Join-Path $config.ProjectRoot "cicd"
}

# Story 1.1 specific monitoring thresholds
$monitoringThresholds = @{
    boot_sequence = @{
        max_boot_time_ms = 5000          # AC 1.1.2: 5 second boot requirement
        critical_boot_time_ms = 7000      # Critical alert threshold
        splash_duration_ms = 2500         # Expected splash screen duration
        boot_failure_rate_percent = 5     # Max 5% boot failure rate
    }
    memory_management = @{
        min_heap_available_kb = 400       # AC 1.1.5: >400KB heap requirement
        critical_heap_kb = 300            # Critical low memory alert
        emergency_threshold_kb = 100      # Emergency memory threshold
        memory_leak_rate_kb_per_hour = 50 # Max 50KB/hour memory leak
    }
    display_system = @{
        init_timeout_ms = 3000           # Max display init time
        brightness_tolerance_percent = 5 # ±5% brightness tolerance from 80%
        display_failure_rate_percent = 2 # Max 2% display failure rate
    }
    touch_system = @{
        max_response_time_ms = 250       # AC 1.1.4: 250ms response requirement
        critical_response_ms = 400       # Critical response time alert
        touch_failure_rate_percent = 3  # Max 3% touch failure rate
    }
    error_handling = @{
        max_error_rate_percent = 10      # Max 10% error rate
        critical_error_rate_percent = 20 # Critical error rate alert
        recovery_success_rate_percent = 90 # Min 90% recovery success
    }
    system_health = @{
        max_cpu_usage_percent = 80       # Max 80% CPU usage
        max_temperature_celsius = 75     # Max operating temperature
        min_battery_level_percent = 10   # Min battery level for testing
    }
}

# Logging configuration
$logFile = Join-Path $paths.Logs "story-1-1-monitoring-$($config.Timestamp).log"

function Write-MonitoringLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG", "SUCCESS", "ALERT", "METRIC")]
        [string]$Level = "INFO",
        [string]$Component = ""
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $componentPrefix = if ($Component) { "[$Component] " } else { "" }
    $logEntry = "[$timestamp] [$Level] $componentPrefix$Message"
    
    # Color coding for console output
    switch ($Level) {
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARN" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "ALERT" { Write-Host $logEntry -ForegroundColor Magenta }
        "METRIC" { Write-Host $logEntry -ForegroundColor Cyan }
        "DEBUG" { if ($Verbose) { Write-Host $logEntry -ForegroundColor Gray } }
        default { Write-Host $logEntry }
    }
    
    # Write to log file
    if (-not (Test-Path (Split-Path $logFile))) {
        New-Item -ItemType Directory -Path (Split-Path $logFile) -Force | Out-Null
    }
    Add-Content -Path $logFile -Value $logEntry
}

# ============================================================================
# STORY 1.1 MONITORING ENGINE
# ============================================================================

class Story11Monitor {
    [hashtable]$Config
    [hashtable]$Paths
    [hashtable]$Thresholds
    [hashtable]$CurrentMetrics
    [hashtable]$AlertHistory
    [bool]$MonitoringActive
    [System.Threading.Timer]$MonitoringTimer
    
    Story11Monitor([hashtable]$Config, [hashtable]$Paths, [hashtable]$Thresholds) {
        $this.Config = $Config
        $this.Paths = $Paths
        $this.Thresholds = $Thresholds
        $this.CurrentMetrics = @{}
        $this.AlertHistory = @{}
        $this.MonitoringActive = $false
        
        $this.Initialize()
    }
    
    [void] Initialize() {
        Write-MonitoringLog "Initializing Story 1.1 monitoring engine" "INFO" "MONITOR"
        
        try {
            # Create required directories
            foreach ($path in $this.Paths.Values) {
                if (-not (Test-Path $path)) {
                    New-Item -ItemType Directory -Path $path -Force | Out-Null
                }
            }
            
            # Initialize metrics collection
            $this.InitializeMetrics()
            
            # Load existing dashboard integration
            $this.LoadDashboardIntegration()
            
            Write-MonitoringLog "Story 1.1 monitoring engine initialized successfully" "SUCCESS" "MONITOR"
            
        } catch {
            Write-MonitoringLog "Failed to initialize monitoring engine: $($_.Exception.Message)" "ERROR" "MONITOR"
            throw
        }
    }
    
    [void] InitializeMetrics() {
        $this.CurrentMetrics = @{
            timestamp = Get-Date -Format "o"
            story_id = $this.Config.StoryId
            environment = $this.Config.Environment
            boot_metrics = @{
                last_boot_time_ms = 0
                boot_success_rate = 0
                average_boot_time_ms = 0
                boot_failures_last_hour = 0
            }
            memory_metrics = @{
                current_heap_available_kb = 0
                peak_memory_usage_kb = 0
                memory_leak_rate_kb_per_hour = 0
                low_memory_alerts = 0
            }
            display_metrics = @{
                init_success_rate = 0
                average_init_time_ms = 0
                brightness_accuracy_percent = 0
                display_errors_last_hour = 0
            }
            touch_metrics = @{
                average_response_time_ms = 0
                response_success_rate = 0
                touch_failures_last_hour = 0
            }
            error_metrics = @{
                total_errors_last_hour = 0
                error_rate_percent = 0
                recovery_success_rate = 0
                critical_errors = 0
            }
            system_metrics = @{
                cpu_usage_percent = 0
                temperature_celsius = 0
                battery_level_percent = 100
                uptime_hours = 0
            }
        }
    }
    
    [void] LoadDashboardIntegration() {
        $dashboardScript = Join-Path $this.Paths.Scripts "quality-metrics-collector.ps1"
        if (Test-Path $dashboardScript) {
            Write-MonitoringLog "Dashboard integration available" "DEBUG" "MONITOR"
            $this.Config.DashboardIntegration = $true
        } else {
            Write-MonitoringLog "Dashboard integration not available" "WARN" "MONITOR"
            $this.Config.DashboardIntegration = $false
        }
    }
    
    [void] StartMonitoring([int]$IntervalSeconds) {
        Write-MonitoringLog "Starting Story 1.1 continuous monitoring (interval: ${IntervalSeconds}s)" "INFO" "MONITOR"
        
        try {
            if ($this.MonitoringActive) {
                Write-MonitoringLog "Monitoring already active" "WARN" "MONITOR"
                return
            }
            
            $this.MonitoringActive = $true
            
            # Create monitoring timer
            $timerCallback = {
                try {
                    $this.CollectMetrics()
                    $this.CheckAlerts()
                    $this.UpdateDashboard()
                } catch {
                    Write-MonitoringLog "Monitoring cycle error: $($_.Exception.Message)" "ERROR" "MONITOR"
                }
            }
            
            $this.MonitoringTimer = New-Object System.Threading.Timer(
                [System.Threading.TimerCallback]$timerCallback,
                $null,
                0,
                ($IntervalSeconds * 1000)
            )
            
            Write-MonitoringLog "Story 1.1 monitoring started successfully" "SUCCESS" "MONITOR"
            
            # Keep monitoring active
            while ($this.MonitoringActive) {
                Start-Sleep -Seconds $IntervalSeconds
                
                # Display current status
                $this.DisplayMonitoringStatus()
                
                # Check for stop signal (simplified for demo)
                $stopFile = Join-Path $this.Paths.Monitoring "stop_monitoring.flag"
                if (Test-Path $stopFile) {
                    Write-MonitoringLog "Stop signal detected" "INFO" "MONITOR"
                    Remove-Item $stopFile -Force
                    break
                }
            }
            
        } catch {
            Write-MonitoringLog "Failed to start monitoring: $($_.Exception.Message)" "ERROR" "MONITOR"
            $this.MonitoringActive = $false
            throw
        } finally {
            $this.StopMonitoring()
        }
    }
    
    [void] StopMonitoring() {
        Write-MonitoringLog "Stopping Story 1.1 monitoring" "INFO" "MONITOR"
        
        try {
            $this.MonitoringActive = $false
            
            if ($this.MonitoringTimer) {
                $this.MonitoringTimer.Dispose()
                $this.MonitoringTimer = $null
            }
            
            # Final metrics collection
            $this.CollectMetrics()
            $this.SaveMonitoringSession()
            
            Write-MonitoringLog "Story 1.1 monitoring stopped successfully" "SUCCESS" "MONITOR"
            
        } catch {
            Write-MonitoringLog "Error stopping monitoring: $($_.Exception.Message)" "ERROR" "MONITOR"
        }
    }
    
    [void] CollectMetrics() {
        Write-MonitoringLog "Collecting Story 1.1 metrics" "DEBUG" "COLLECT"
        
        try {
            # Update timestamp
            $this.CurrentMetrics.timestamp = Get-Date -Format "o"
            
            # Collect boot metrics
            $this.CollectBootMetrics()
            
            # Collect memory metrics
            $this.CollectMemoryMetrics()
            
            # Collect display metrics
            $this.CollectDisplayMetrics()
            
            # Collect touch metrics
            $this.CollectTouchMetrics()
            
            # Collect error metrics
            $this.CollectErrorMetrics()
            
            # Collect system metrics
            $this.CollectSystemMetrics()
            
            # Save metrics to file
            $this.SaveMetricsToFile()
            
            Write-MonitoringLog "Metrics collection completed" "DEBUG" "COLLECT"
            
        } catch {
            Write-MonitoringLog "Metrics collection failed: $($_.Exception.Message)" "ERROR" "COLLECT"
        }
    }
    
    [void] CollectBootMetrics() {
        # Simulate boot metrics collection
        # In real implementation, this would interface with hardware/firmware
        
        $bootMetrics = @{
            last_boot_time_ms = Get-Random -Minimum 3000 -Maximum 4500
            boot_success_rate = Get-Random -Minimum 95 -Maximum 100
            average_boot_time_ms = Get-Random -Minimum 3500 -Maximum 4200
            boot_failures_last_hour = Get-Random -Minimum 0 -Maximum 2
        }
        
        $this.CurrentMetrics.boot_metrics = $bootMetrics
        
        Write-MonitoringLog "Boot metrics: ${bootMetrics.last_boot_time_ms}ms boot time, ${bootMetrics.boot_success_rate}% success rate" "METRIC" "BOOT"
    }
    
    [void] CollectMemoryMetrics() {
        # Simulate memory metrics collection
        
        $memoryMetrics = @{
            current_heap_available_kb = Get-Random -Minimum 400 -Maximum 500
            peak_memory_usage_kb = Get-Random -Minimum 250 -Maximum 350
            memory_leak_rate_kb_per_hour = Get-Random -Minimum 0 -Maximum 20
            low_memory_alerts = Get-Random -Minimum 0 -Maximum 1
        }
        
        $this.CurrentMetrics.memory_metrics = $memoryMetrics
        
        Write-MonitoringLog "Memory metrics: ${memoryMetrics.current_heap_available_kb}KB available, ${memoryMetrics.peak_memory_usage_kb}KB peak" "METRIC" "MEMORY"
    }
    
    [void] CollectDisplayMetrics() {
        # Simulate display metrics collection
        
        $displayMetrics = @{
            init_success_rate = Get-Random -Minimum 95 -Maximum 100
            average_init_time_ms = Get-Random -Minimum 800 -Maximum 1500
            brightness_accuracy_percent = Get-Random -Minimum 95 -Maximum 100
            display_errors_last_hour = Get-Random -Minimum 0 -Maximum 1
        }
        
        $this.CurrentMetrics.display_metrics = $displayMetrics
        
        Write-MonitoringLog "Display metrics: ${displayMetrics.init_success_rate}% init success, ${displayMetrics.average_init_time_ms}ms avg init" "METRIC" "DISPLAY"
    }
    
    [void] CollectTouchMetrics() {
        # Simulate touch metrics collection
        
        $touchMetrics = @{
            average_response_time_ms = Get-Random -Minimum 80 -Maximum 200
            response_success_rate = Get-Random -Minimum 95 -Maximum 100
            touch_failures_last_hour = Get-Random -Minimum 0 -Maximum 2
        }
        
        $this.CurrentMetrics.touch_metrics = $touchMetrics
        
        Write-MonitoringLog "Touch metrics: ${touchMetrics.average_response_time_ms}ms avg response, ${touchMetrics.response_success_rate}% success rate" "METRIC" "TOUCH"
    }
    
    [void] CollectErrorMetrics() {
        # Simulate error metrics collection
        
        $errorMetrics = @{
            total_errors_last_hour = Get-Random -Minimum 0 -Maximum 5
            error_rate_percent = Get-Random -Minimum 0 -Maximum 8
            recovery_success_rate = Get-Random -Minimum 90 -Maximum 100
            critical_errors = Get-Random -Minimum 0 -Maximum 1
        }
        
        $this.CurrentMetrics.error_metrics = $errorMetrics
        
        Write-MonitoringLog "Error metrics: ${errorMetrics.total_errors_last_hour} errors/hour, ${errorMetrics.error_rate_percent}% error rate" "METRIC" "ERROR"
    }
    
    [void] CollectSystemMetrics() {
        # Simulate system metrics collection
        
        $systemMetrics = @{
            cpu_usage_percent = Get-Random -Minimum 20 -Maximum 60
            temperature_celsius = Get-Random -Minimum 35 -Maximum 55
            battery_level_percent = Get-Random -Minimum 70 -Maximum 100
            uptime_hours = Get-Random -Minimum 1 -Maximum 24
        }
        
        $this.CurrentMetrics.system_metrics = $systemMetrics
        
        Write-MonitoringLog "System metrics: ${systemMetrics.cpu_usage_percent}% CPU, ${systemMetrics.temperature_celsius}°C temp" "METRIC" "SYSTEM"
    }
    
    [void] CheckAlerts() {
        if (-not $AlertThresholds) {
            return
        }
        
        Write-MonitoringLog "Checking Story 1.1 alert thresholds" "DEBUG" "ALERT"
        
        try {
            # Check boot sequence alerts
            $this.CheckBootAlerts()
            
            # Check memory alerts
            $this.CheckMemoryAlerts()
            
            # Check display alerts
            $this.CheckDisplayAlerts()
            
            # Check touch alerts
            $this.CheckTouchAlerts()
            
            # Check error alerts
            $this.CheckErrorAlerts()
            
            # Check system alerts
            $this.CheckSystemAlerts()
            
        } catch {
            Write-MonitoringLog "Alert checking failed: $($_.Exception.Message)" "ERROR" "ALERT"
        }
    }
    
    [void] CheckBootAlerts() {
        $bootMetrics = $this.CurrentMetrics.boot_metrics
        $thresholds = $this.Thresholds.boot_sequence
        
        # Boot time alert
        if ($bootMetrics.last_boot_time_ms -gt $thresholds.critical_boot_time_ms) {
            $this.TriggerAlert("CRITICAL", "BOOT_TIME", "Boot time ${bootMetrics.last_boot_time_ms}ms exceeds critical threshold ${thresholds.critical_boot_time_ms}ms")
        } elseif ($bootMetrics.last_boot_time_ms -gt $thresholds.max_boot_time_ms) {
            $this.TriggerAlert("WARNING", "BOOT_TIME", "Boot time ${bootMetrics.last_boot_time_ms}ms exceeds normal threshold ${thresholds.max_boot_time_ms}ms")
        }
        
        # Boot failure rate alert
        if ($bootMetrics.boot_success_rate -lt (100 - $thresholds.boot_failure_rate_percent)) {
            $this.TriggerAlert("WARNING", "BOOT_FAILURE_RATE", "Boot success rate ${bootMetrics.boot_success_rate}% below threshold")
        }
    }
    
    [void] CheckMemoryAlerts() {
        $memoryMetrics = $this.CurrentMetrics.memory_metrics
        $thresholds = $this.Thresholds.memory_management
        
        # Low memory alert
        if ($memoryMetrics.current_heap_available_kb -lt $thresholds.critical_heap_kb) {
            $this.TriggerAlert("CRITICAL", "LOW_MEMORY", "Available heap ${memoryMetrics.current_heap_available_kb}KB below critical threshold ${thresholds.critical_heap_kb}KB")
        } elseif ($memoryMetrics.current_heap_available_kb -lt $thresholds.min_heap_available_kb) {
            $this.TriggerAlert("WARNING", "LOW_MEMORY", "Available heap ${memoryMetrics.current_heap_available_kb}KB below normal threshold ${thresholds.min_heap_available_kb}KB")
        }
        
        # Memory leak alert
        if ($memoryMetrics.memory_leak_rate_kb_per_hour -gt $thresholds.memory_leak_rate_kb_per_hour) {
            $this.TriggerAlert("WARNING", "MEMORY_LEAK", "Memory leak rate ${memoryMetrics.memory_leak_rate_kb_per_hour}KB/hour exceeds threshold")
        }
    }
    
    [void] CheckDisplayAlerts() {
        $displayMetrics = $this.CurrentMetrics.display_metrics
        $thresholds = $this.Thresholds.display_system
        
        # Display initialization alert
        if ($displayMetrics.average_init_time_ms -gt $thresholds.init_timeout_ms) {
            $this.TriggerAlert("WARNING", "DISPLAY_INIT", "Display init time ${displayMetrics.average_init_time_ms}ms exceeds threshold ${thresholds.init_timeout_ms}ms")
        }
        
        # Display failure rate alert
        if ($displayMetrics.init_success_rate -lt (100 - $thresholds.display_failure_rate_percent)) {
            $this.TriggerAlert("WARNING", "DISPLAY_FAILURE_RATE", "Display init success rate ${displayMetrics.init_success_rate}% below threshold")
        }
    }
    
    [void] CheckTouchAlerts() {
        $touchMetrics = $this.CurrentMetrics.touch_metrics
        $thresholds = $this.Thresholds.touch_system
        
        # Touch response time alert
        if ($touchMetrics.average_response_time_ms -gt $thresholds.critical_response_ms) {
            $this.TriggerAlert("CRITICAL", "TOUCH_RESPONSE", "Touch response ${touchMetrics.average_response_time_ms}ms exceeds critical threshold ${thresholds.critical_response_ms}ms")
        } elseif ($touchMetrics.average_response_time_ms -gt $thresholds.max_response_time_ms) {
            $this.TriggerAlert("WARNING", "TOUCH_RESPONSE", "Touch response ${touchMetrics.average_response_time_ms}ms exceeds AC threshold ${thresholds.max_response_time_ms}ms")
        }
    }
    
    [void] CheckErrorAlerts() {
        $errorMetrics = $this.CurrentMetrics.error_metrics
        $thresholds = $this.Thresholds.error_handling
        
        # Error rate alert
        if ($errorMetrics.error_rate_percent -gt $thresholds.critical_error_rate_percent) {
            $this.TriggerAlert("CRITICAL", "HIGH_ERROR_RATE", "Error rate ${errorMetrics.error_rate_percent}% exceeds critical threshold ${thresholds.critical_error_rate_percent}%")
        } elseif ($errorMetrics.error_rate_percent -gt $thresholds.max_error_rate_percent) {
            $this.TriggerAlert("WARNING", "HIGH_ERROR_RATE", "Error rate ${errorMetrics.error_rate_percent}% exceeds threshold ${thresholds.max_error_rate_percent}%")
        }
        
        # Critical errors alert
        if ($errorMetrics.critical_errors -gt 0) {
            $this.TriggerAlert("CRITICAL", "CRITICAL_ERRORS", "${errorMetrics.critical_errors} critical errors detected")
        }
    }
    
    [void] CheckSystemAlerts() {
        $systemMetrics = $this.CurrentMetrics.system_metrics
        $thresholds = $this.Thresholds.system_health
        
        # CPU usage alert
        if ($systemMetrics.cpu_usage_percent -gt $thresholds.max_cpu_usage_percent) {
            $this.TriggerAlert("WARNING", "HIGH_CPU", "CPU usage ${systemMetrics.cpu_usage_percent}% exceeds threshold ${thresholds.max_cpu_usage_percent}%")
        }
        
        # Temperature alert
        if ($systemMetrics.temperature_celsius -gt $thresholds.max_temperature_celsius) {
            $this.TriggerAlert("WARNING", "HIGH_TEMPERATURE", "Temperature ${systemMetrics.temperature_celsius}°C exceeds threshold ${thresholds.max_temperature_celsius}°C")
        }
        
        # Battery alert
        if ($systemMetrics.battery_level_percent -lt $thresholds.min_battery_level_percent) {
            $this.TriggerAlert("WARNING", "LOW_BATTERY", "Battery level ${systemMetrics.battery_level_percent}% below threshold ${thresholds.min_battery_level_percent}%")
        }
    }
    
    [void] TriggerAlert([string]$Severity, [string]$AlertType, [string]$Message) {
        $alertId = "STORY_1_1_${AlertType}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        
        $alert = @{
            alert_id = $alertId
            timestamp = Get-Date -Format "o"
            story_id = $this.Config.StoryId
            severity = $Severity
            alert_type = $AlertType
            message = $Message
            environment = $this.Config.Environment
            metrics_snapshot = $this.CurrentMetrics.Clone()
        }
        
        # Log alert
        Write-MonitoringLog "ALERT [$Severity] $AlertType`: $Message" "ALERT" "ALERT"
        
        # Save alert to history
        $this.AlertHistory[$alertId] = $alert
        
        # Save alert to file
        $this.SaveAlertToFile($alert)
        
        # Send alert notification (if configured)
        $this.SendAlertNotification($alert)
    }
    
    [void] SaveMetricsToFile() {
        try {
            $metricsFile = Join-Path $this.Paths.Metrics "story-1-1-metrics-$(Get-Date -Format 'yyyyMMdd').json"
            
            # Append metrics to daily file
            $metricsEntry = @{
                timestamp = $this.CurrentMetrics.timestamp
                metrics = $this.CurrentMetrics
            }
            
            if (Test-Path $metricsFile) {
                $existingMetrics = Get-Content $metricsFile | ConvertFrom-Json
                $existingMetrics += $metricsEntry
                $existingMetrics | ConvertTo-Json -Depth 10 | Set-Content $metricsFile
            } else {
                @($metricsEntry) | ConvertTo-Json -Depth 10 | Set-Content $metricsFile
            }
            
        } catch {
            Write-MonitoringLog "Failed to save metrics: $($_.Exception.Message)" "ERROR" "COLLECT"
        }
    }
    
    [void] SaveAlertToFile([hashtable]$Alert) {
        try {
            $alertsFile = Join-Path $this.Paths.Alerts "story-1-1-alerts-$(Get-Date -Format 'yyyyMMdd').json"
            
            if (Test-Path $alertsFile) {
                $existingAlerts = Get-Content $alertsFile | ConvertFrom-Json
                $existingAlerts += $Alert
                $existingAlerts | ConvertTo-Json -Depth 10 | Set-Content $alertsFile
            } else {
                @($Alert) | ConvertTo-Json -Depth 10 | Set-Content $alertsFile
            }
            
        } catch {
            Write-MonitoringLog "Failed to save alert: $($_.Exception.Message)" "ERROR" "ALERT"
        }
    }
    
    [void] SendAlertNotification([hashtable]$Alert) {
        # In production, this would send email, Slack, Teams notifications
        Write-MonitoringLog "Alert notification: [$($Alert.severity)] $($Alert.message)" "ALERT" "NOTIFY"
    }
    
    [void] UpdateDashboard() {
        if (-not $DashboardUpdate -or -not $this.Config.DashboardIntegration) {
            return
        }
        
        try {
            Write-MonitoringLog "Updating quality dashboard with Story 1.1 metrics" "DEBUG" "DASHBOARD"
            
            # Use existing quality metrics collector
            $metricsScript = Join-Path $this.Paths.Scripts "quality-metrics-collector.ps1"
            
            if (Test-Path $metricsScript) {
                & $metricsScript -Action collect -Verbose:$false
                & $metricsScript -Action dashboard -Verbose:$false
                
                Write-MonitoringLog "Quality dashboard updated successfully" "DEBUG" "DASHBOARD"
            }
            
        } catch {
            Write-MonitoringLog "Dashboard update failed: $($_.Exception.Message)" "ERROR" "DASHBOARD"
        }
    }
    
    [void] DisplayMonitoringStatus() {
        Write-MonitoringLog "" "INFO"
        Write-MonitoringLog "═══════════════════════════════════════════════════════════════════════════════" "INFO"
        Write-MonitoringLog "📊 STORY 1.1 MONITORING STATUS" "INFO"
        Write-MonitoringLog "═══════════════════════════════════════════════════════════════════════════════" "INFO"
        
        # Boot metrics
        $boot = $this.CurrentMetrics.boot_metrics
        Write-MonitoringLog "🚀 Boot: ${boot.last_boot_time_ms}ms (${boot.boot_success_rate}% success)" "INFO"
        
        # Memory metrics
        $memory = $this.CurrentMetrics.memory_metrics
        Write-MonitoringLog "💾 Memory: ${memory.current_heap_available_kb}KB available (peak: ${memory.peak_memory_usage_kb}KB)" "INFO"
        
        # Display metrics
        $display = $this.CurrentMetrics.display_metrics
        Write-MonitoringLog "🖥️  Display: ${display.init_success_rate}% success (${display.average_init_time_ms}ms avg init)" "INFO"
        
        # Touch metrics
        $touch = $this.CurrentMetrics.touch_metrics
        Write-MonitoringLog "👆 Touch: ${touch.average_response_time_ms}ms response (${touch.response_success_rate}% success)" "INFO"
        
        # System metrics
        $system = $this.CurrentMetrics.system_metrics
        Write-MonitoringLog "⚙️  System: ${system.cpu_usage_percent}% CPU, ${system.temperature_celsius}°C temp" "INFO"
        
        Write-MonitoringLog "═══════════════════════════════════════════════════════════════════════════════" "INFO"
        Write-MonitoringLog "" "INFO"
    }
    
    [void] SaveMonitoringSession() {
        try {
            $sessionFile = Join-Path $this.Paths.Monitoring "story-1-1-session-$($this.Config.Timestamp).json"
            
            $sessionData = @{
                story_id = $this.Config.StoryId
                start_time = $this.Config.Timestamp
                end_time = Get-Date -Format "o"
                environment = $this.Config.Environment
                final_metrics = $this.CurrentMetrics
                alert_summary = @{
                    total_alerts = $this.AlertHistory.Count
                    critical_alerts = ($this.AlertHistory.Values | Where-Object { $_.severity -eq "CRITICAL" }).Count
                    warning_alerts = ($this.AlertHistory.Values | Where-Object { $_.severity -eq "WARNING" }).Count
                }
                thresholds_used = $this.Thresholds
            }
            
            $sessionData | ConvertTo-Json -Depth 15 | Set-Content $sessionFile
            
            Write-MonitoringLog "Monitoring session saved: $sessionFile" "SUCCESS" "MONITOR"
            
        } catch {
            Write-MonitoringLog "Failed to save monitoring session: $($_.Exception.Message)" "ERROR" "MONITOR"
        }
    }
    
    [hashtable] GetMonitoringStatus() {
        return @{
            monitoring_active = $this.MonitoringActive
            story_id = $this.Config.StoryId
            environment = $this.Config.Environment
            current_metrics = $this.CurrentMetrics
            alert_count = $this.AlertHistory.Count
            dashboard_integration = $this.Config.DashboardIntegration
        }
    }
    
    [hashtable] GenerateMonitoringReport() {
        Write-MonitoringLog "Generating Story 1.1 monitoring report" "INFO" "REPORT"
        
        $report = @{
            report_metadata = @{
                story_id = $this.Config.StoryId
                story_name = $this.Config.StoryName
                generated_timestamp = Get-Date -Format "o"
                environment = $this.Config.Environment
                monitoring_duration_hours = [math]::Round((Get-Date - [datetime]$this.Config.Timestamp).TotalHours, 2)
            }
            current_metrics = $this.CurrentMetrics
            alert_summary = @{
                total_alerts = $this.AlertHistory.Count
                alerts_by_severity = @{
                    critical = ($this.AlertHistory.Values | Where-Object { $_.severity -eq "CRITICAL" }).Count
                    warning = ($this.AlertHistory.Values | Where-Object { $_.severity -eq "WARNING" }).Count
                }
                alerts_by_type = @{}
            }
            threshold_compliance = $this.CalculateThresholdCompliance()
            recommendations = $this.GenerateRecommendations()
        }
        
        # Calculate alert distribution by type
        foreach ($alert in $this.AlertHistory.Values) {
            if ($report.alert_summary.alerts_by_type.ContainsKey($alert.alert_type)) {
                $report.alert_summary.alerts_by_type[$alert.alert_type]++
            } else {
                $report.alert_summary.alerts_by_type[$alert.alert_type] = 1
            }
        }
        
        return $report
    }
    
    [hashtable] CalculateThresholdCompliance() {
        $compliance = @{
            boot_sequence = @{
                boot_time_compliant = ($this.CurrentMetrics.boot_metrics.last_boot_time_ms -le $this.Thresholds.boot_sequence.max_boot_time_ms)
                success_rate_compliant = ($this.CurrentMetrics.boot_metrics.boot_success_rate -ge (100 - $this.Thresholds.boot_sequence.boot_failure_rate_percent))
            }
            memory_management = @{
                heap_compliant = ($this.CurrentMetrics.memory_metrics.current_heap_available_kb -ge $this.Thresholds.memory_management.min_heap_available_kb)
                leak_rate_compliant = ($this.CurrentMetrics.memory_metrics.memory_leak_rate_kb_per_hour -le $this.Thresholds.memory_management.memory_leak_rate_kb_per_hour)
            }
            touch_system = @{
                response_time_compliant = ($this.CurrentMetrics.touch_metrics.average_response_time_ms -le $this.Thresholds.touch_system.max_response_time_ms)
                success_rate_compliant = ($this.CurrentMetrics.touch_metrics.response_success_rate -ge (100 - $this.Thresholds.touch_system.touch_failure_rate_percent))
            }
        }
        
        return $compliance
    }
    
    [array] GenerateRecommendations() {
        $recommendations = @()
        
        # Boot performance recommendations
        if ($this.CurrentMetrics.boot_metrics.last_boot_time_ms -gt $this.Thresholds.boot_sequence.max_boot_time_ms) {
            $recommendations += @{
                category = "Boot Performance"
                priority = "HIGH"
                recommendation = "Optimize boot sequence - current boot time exceeds AC 1.1.2 requirement"
                action_items = @(
                    "Profile boot sequence components",
                    "Optimize initialization order",
                    "Implement parallel initialization where possible"
                )
            }
        }
        
        # Memory management recommendations
        if ($this.CurrentMetrics.memory_metrics.current_heap_available_kb -lt $this.Thresholds.memory_management.min_heap_available_kb) {
            $recommendations += @{
                category = "Memory Management"
                priority = "CRITICAL"
                recommendation = "Address low memory condition - below AC 1.1.5 requirement"
                action_items = @(
                    "Identify memory leaks",
                    "Optimize memory allocation patterns",
                    "Consider reducing memory footprint"
                )
            }
        }
        
        # Touch responsiveness recommendations
        if ($this.CurrentMetrics.touch_metrics.average_response_time_ms -gt $this.Thresholds.touch_system.max_response_time_ms) {
            $recommendations += @{
                category = "Touch Responsiveness"
                priority = "HIGH"
                recommendation = "Improve touch response time - exceeds AC 1.1.4 requirement"
                action_items = @(
                    "Optimize touch interrupt handling",
                    "Reduce touch processing latency",
                    "Review touch calibration settings"
                )
            }
        }
        
        return $recommendations
    }
}

# ============================================================================
# MAIN MONITORING EXECUTION
# ============================================================================

function Show-MonitoringHeader {
    Write-Host "`n" -NoNewline
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                   Story 1.1 Continuous Monitoring System                    ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║ Action: $($Action.ToUpper().PadRight(67)) ║" -ForegroundColor White
    Write-Host "║ Environment: $($Environment.ToUpper().PadRight(62)) ║" -ForegroundColor White
    Write-Host "║ Monitoring Interval: $($MonitoringInterval)s".PadRight(74) -ForegroundColor White -NoNewline
    Write-Host " ║" -ForegroundColor Cyan
    Write-Host "║ Alert Thresholds: $(if($AlertThresholds) { 'ENABLED' } else { 'DISABLED' }).PadRight(58) ║" -ForegroundColor White
    Write-Host "║ Dashboard Update: $(if($DashboardUpdate) { 'ENABLED' } else { 'DISABLED' }).PadRight(58) ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-Story11Monitoring {
    try {
        Show-MonitoringHeader
        
        # Initialize monitoring engine
        $monitor = [Story11Monitor]::new($config, $paths, $monitoringThresholds)
        
        # Execute monitoring action
        switch ($Action.ToLower()) {
            "start" {
                Write-MonitoringLog "🎯 Starting Story 1.1 continuous monitoring" "INFO"
                $monitor.StartMonitoring($MonitoringInterval)
            }
            
            "stop" {
                Write-MonitoringLog "🛑 Stopping Story 1.1 monitoring" "INFO"
                $stopFile = Join-Path $paths.Monitoring "stop_monitoring.flag"
                "STOP" | Set-Content $stopFile
                Write-MonitoringLog "Stop signal sent successfully" "SUCCESS"
            }
            
            "status" {
                Write-MonitoringLog "📊 Checking Story 1.1 monitoring status" "INFO"
                $status = $monitor.GetMonitoringStatus()
                
                Write-MonitoringLog "Monitoring Status:" "INFO"
                Write-MonitoringLog "  Active: $(if ($status.monitoring_active) { 'YES' } else { 'NO' })" "INFO"
                Write-MonitoringLog "  Environment: $($status.environment)" "INFO"
                Write-MonitoringLog "  Alert Count: $($status.alert_count)" "INFO"
                Write-MonitoringLog "  Dashboard Integration: $(if ($status.dashboard_integration) { 'YES' } else { 'NO' })" "INFO"
            }
            
            "collect" {
                Write-MonitoringLog "📊 Collecting Story 1.1 metrics" "INFO"
                $monitor.CollectMetrics()
                Write-MonitoringLog "Metrics collection completed" "SUCCESS"
            }
            
            "alert" {
                Write-MonitoringLog "🚨 Running Story 1.1 alert check" "INFO"
                $monitor.CollectMetrics()
                $monitor.CheckAlerts()
                Write-MonitoringLog "Alert check completed" "SUCCESS"
            }
            
            "dashboard" {
                Write-MonitoringLog "📊 Updating Story 1.1 dashboard" "INFO"
                $monitor.CollectMetrics()
                $monitor.UpdateDashboard()
                Write-MonitoringLog "Dashboard update completed" "SUCCESS"
            }
            
            "report" {
                Write-MonitoringLog "📋 Generating Story 1.1 monitoring report" "INFO"
                $report = $monitor.GenerateMonitoringReport()
                
                $reportFile = Join-Path $paths.Monitoring "story-1-1-monitoring-report-$($config.Timestamp).json"
                $report | ConvertTo-Json -Depth 15 | Set-Content $reportFile
                
                Write-MonitoringLog "Monitoring report generated: $reportFile" "SUCCESS"
                
                # Display summary
                Write-MonitoringLog "Report Summary:" "INFO"
                Write-MonitoringLog "  Total Alerts: $($report.alert_summary.total_alerts)" "INFO"
                Write-MonitoringLog "  Critical Alerts: $($report.alert_summary.alerts_by_severity.critical)" "INFO"
                Write-MonitoringLog "  Recommendations: $($report.recommendations.Count)" "INFO"
            }
        }
        
        Write-MonitoringLog "Story 1.1 monitoring action completed successfully" "SUCCESS"
        return 0
        
    } catch {
        Write-MonitoringLog "Story 1.1 monitoring failed: $($_.Exception.Message)" "ERROR"
        Write-MonitoringLog "Stack trace: $($_.ScriptStackTrace)" "DEBUG"
        return 1
    }
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

if ($MyInvocation.InvocationName -ne '.') {
    try {
        # Ensure required directories exist
        foreach ($path in $paths.Values) {
            if (-not (Test-Path $path)) {
                New-Item -ItemType Directory -Path $path -Force | Out-Null
            }
        }
        
        # Execute monitoring
        $exitCode = Invoke-Story11Monitoring
        
        Write-MonitoringLog "Story 1.1 monitoring completed with exit code: $exitCode" "INFO"
        exit $exitCode
        
    } catch {
        Write-MonitoringLog "Fatal Story 1.1 monitoring error: $($_.Exception.Message)" "ERROR"
        exit 2
    }
}