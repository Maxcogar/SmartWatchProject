# Story 1.1 Quality Alert System
# Enhanced notification framework for quality threshold breaches
# Supports multiple notification channels: Email, Slack, Teams, File, Console

param(
    [string]$AlertMode = "monitor", # monitor, test, configure
    [string[]]$NotificationChannels = @("console", "file"),
    [string]$ConfigFile = "alert-config.json",
    [string]$LogPath = "logs\alerts",
    [int]$MonitoringIntervalSeconds = 60
)

class Story11AlertSystem {
    [hashtable]$Config
    [hashtable]$NotificationChannels
    [hashtable]$AlertHistory
    [string]$LogPath
    [bool]$IsInitialized

    Story11AlertSystem([string]$configPath, [string]$logPath) {
        $this.LogPath = $logPath
        $this.AlertHistory = @{}
        $this.NotificationChannels = @{}
        $this.IsInitialized = $false
        
        try {
            $this.InitializeConfig($configPath)
            $this.InitializeNotificationChannels()
            $this.InitializeLogging()
            $this.IsInitialized = $true
            Write-Host "✅ Story 1.1 Alert System initialized successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Alert System initialization failed: $($_.Exception.Message)" -ForegroundColor Red
            $this.IsInitialized = $false
        }
    }

    [void]InitializeConfig([string]$configPath) {
        if (-not (Test-Path $configPath)) {
            $this.CreateDefaultConfig($configPath)
        }
        
        $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
        $this.Config = @{
            AlertThresholds = @{
                boot_time_ms = @{
                    warning = 4000
                    critical = 5000
                    failure = 7000
                }
                memory_usage_percent = @{
                    warning = 70
                    critical = 85
                    failure = 95
                }
                display_init_ms = @{
                    warning = 800
                    critical = 1000
                    failure = 1500
                }
                touch_response_ms = @{
                    warning = 80
                    critical = 100
                    failure = 150
                }
                error_rate_percent = @{
                    warning = 2
                    critical = 5
                    failure = 10
                }
                quality_gate_failures = @{
                    warning = 1
                    critical = 2
                    failure = 3
                }
            }
            NotificationConfig = @{
                email = @{
                    enabled = $configContent.notifications.email.enabled
                    smtp_server = $configContent.notifications.email.smtp_server
                    smtp_port = $configContent.notifications.email.smtp_port
                    username = $configContent.notifications.email.username
                    recipients = $configContent.notifications.email.recipients
                }
                slack = @{
                    enabled = $configContent.notifications.slack.enabled
                    webhook_url = $configContent.notifications.slack.webhook_url
                    channel = $configContent.notifications.slack.channel
                }
                teams = @{
                    enabled = $configContent.notifications.teams.enabled
                    webhook_url = $configContent.notifications.teams.webhook_url
                }
                console = @{
                    enabled = $true
                    use_colors = $true
                }
                file = @{
                    enabled = $true
                    log_file = "$($this.LogPath)\story-1-1-alerts.log"
                }
            }
            AlertPolicies = @{
                suppress_duration_minutes = 15
                escalation_after_failures = 3
                auto_recovery_notification = $true
                batch_similar_alerts = $true
            }
        }
    }

    [void]CreateDefaultConfig([string]$configPath) {
        $defaultConfig = @{
            notifications = @{
                email = @{
                    enabled = $false
                    smtp_server = "smtp.company.com"
                    smtp_port = 587
                    username = "alerts@company.com"
                    recipients = @("devops@company.com", "team-lead@company.com")
                }
                slack = @{
                    enabled = $false
                    webhook_url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
                    channel = "#smartwatch-alerts"
                }
                teams = @{
                    enabled = $false
                    webhook_url = "https://company.webhook.office.com/webhookb2/YOUR-WEBHOOK-URL"
                }
            }
            alert_policies = @{
                suppress_duration_minutes = 15
                escalation_after_failures = 3
                auto_recovery_notification = $true
                batch_similar_alerts = $true
            }
        }
        
        $configDir = Split-Path $configPath -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $defaultConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $configPath -Encoding UTF8
        Write-Host "📝 Created default alert configuration at: $configPath" -ForegroundColor Yellow
    }

    [void]InitializeNotificationChannels() {
        # Console notification channel
        $this.NotificationChannels["console"] = @{
            enabled = $true
            send = {
                param($alert)
                $color = switch ($alert.severity) {
                    "warning" { "Yellow" }
                    "critical" { "Red" }
                    "failure" { "DarkRed" }
                    "recovery" { "Green" }
                    default { "White" }
                }
                Write-Host "🚨 [$($alert.severity.ToUpper())] $($alert.title)" -ForegroundColor $color
                Write-Host "   📍 $($alert.message)" -ForegroundColor Gray
                Write-Host "   ⏰ $($alert.timestamp)" -ForegroundColor Gray
            }
        }

        # File notification channel
        $this.NotificationChannels["file"] = @{
            enabled = $true
            send = {
                param($alert)
                $logEntry = "[$($alert.timestamp)] [$($alert.severity.ToUpper())] $($alert.title) - $($alert.message)"
                $logFile = $this.Config.NotificationConfig.file.log_file
                Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
            }
        }

        # Email notification channel
        if ($this.Config.NotificationConfig.email.enabled) {
            $this.NotificationChannels["email"] = @{
                enabled = $true
                send = {
                    param($alert)
                    $this.SendEmailAlert($alert)
                }
            }
        }

        # Slack notification channel
        if ($this.Config.NotificationConfig.slack.enabled) {
            $this.NotificationChannels["slack"] = @{
                enabled = $true
                send = {
                    param($alert)
                    $this.SendSlackAlert($alert)
                }
            }
        }

        # Teams notification channel
        if ($this.Config.NotificationConfig.teams.enabled) {
            $this.NotificationChannels["teams"] = @{
                enabled = $true
                send = {
                    param($alert)
                    $this.SendTeamsAlert($alert)
                }
            }
        }
    }

    [void]InitializeLogging() {
        if (-not (Test-Path $this.LogPath)) {
            New-Item -ItemType Directory -Path $this.LogPath -Force | Out-Null
        }
        
        $logFile = $this.Config.NotificationConfig.file.log_file
        $logDir = Split-Path $logFile -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
    }

    [hashtable]EvaluateMetrics([hashtable]$metrics) {
        $alerts = @()
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        foreach ($metricName in $metrics.Keys) {
            $metricValue = $metrics[$metricName]
            
            if ($this.Config.AlertThresholds.ContainsKey($metricName)) {
                $thresholds = $this.Config.AlertThresholds[$metricName]
                $severity = $this.DetermineSeverity($metricValue, $thresholds)
                
                if ($severity -ne "normal") {
                    $alert = @{
                        id = "$metricName-$timestamp"
                        title = "Story 1.1 Quality Threshold Breach"
                        message = "$metricName exceeded $severity threshold: $metricValue"
                        severity = $severity
                        metric = $metricName
                        value = $metricValue
                        thresholds = $thresholds
                        timestamp = $timestamp
                        story = "1.1"
                        component = "SmartWatch"
                    }
                    $alerts += $alert
                }
            }
        }

        return @{
            alerts = $alerts
            evaluation_timestamp = $timestamp
            metrics_evaluated = $metrics.Keys.Count
            alerts_generated = $alerts.Count
        }
    }

    [string]DetermineSeverity([object]$value, [hashtable]$thresholds) {
        $numValue = [double]$value
        
        if ($numValue -ge $thresholds.failure) {
            return "failure"
        }
        elseif ($numValue -ge $thresholds.critical) {
            return "critical"
        }
        elseif ($numValue -ge $thresholds.warning) {
            return "warning"
        }
        else {
            return "normal"
        }
    }

    [void]ProcessAlerts([hashtable[]]$alerts) {
        foreach ($alert in $alerts) {
            if ($this.ShouldSendAlert($alert)) {
                $this.SendAlert($alert)
                $this.RecordAlert($alert)
            }
        }
    }

    [bool]ShouldSendAlert([hashtable]$alert) {
        $suppressDuration = $this.Config.AlertPolicies.suppress_duration_minutes
        $alertKey = "$($alert.metric)-$($alert.severity)"
        
        if ($this.AlertHistory.ContainsKey($alertKey)) {
            $lastAlert = $this.AlertHistory[$alertKey]
            $timeDiff = (Get-Date) - [datetime]$lastAlert.timestamp
            
            if ($timeDiff.TotalMinutes -lt $suppressDuration) {
                return $false # Suppress duplicate alerts
            }
        }
        
        return $true
    }

    [void]SendAlert([hashtable]$alert) {
        foreach ($channelName in $this.NotificationChannels.Keys) {
            $channel = $this.NotificationChannels[$channelName]
            
            if ($channel.enabled) {
                try {
                    & $channel.send $alert
                }
                catch {
                    Write-Warning "Failed to send alert via $channelName: $($_.Exception.Message)"
                }
            }
        }
    }

    [void]RecordAlert([hashtable]$alert) {
        $alertKey = "$($alert.metric)-$($alert.severity)"
        $this.AlertHistory[$alertKey] = $alert
    }

    [void]SendEmailAlert([hashtable]$alert) {
        $emailConfig = $this.Config.NotificationConfig.email
        
        $subject = "🚨 Story 1.1 Alert: $($alert.title)"
        $body = @"
SmartWatch Story 1.1 Quality Alert

Severity: $($alert.severity.ToUpper())
Metric: $($alert.metric)
Current Value: $($alert.value)
Thresholds: Warning=$($alert.thresholds.warning), Critical=$($alert.thresholds.critical), Failure=$($alert.thresholds.failure)
Timestamp: $($alert.timestamp)

Message: $($alert.message)

This is an automated alert from the SmartWatch Story 1.1 Quality Monitoring System.
"@

        try {
            Send-MailMessage -To $emailConfig.recipients -Subject $subject -Body $body -SmtpServer $emailConfig.smtp_server -Port $emailConfig.smtp_port -UseSsl
        }
        catch {
            Write-Warning "Failed to send email alert: $($_.Exception.Message)"
        }
    }

    [void]SendSlackAlert([hashtable]$alert) {
        $slackConfig = $this.Config.NotificationConfig.slack
        
        $color = switch ($alert.severity) {
            "warning" { "warning" }
            "critical" { "danger" }
            "failure" { "danger" }
            default { "good" }
        }

        $payload = @{
            channel = $slackConfig.channel
            username = "SmartWatch QA Bot"
            icon_emoji = ":warning:"
            attachments = @(
                @{
                    color = $color
                    title = "Story 1.1 Quality Alert"
                    text = $alert.message
                    fields = @(
                        @{ title = "Severity"; value = $alert.severity.ToUpper(); short = $true }
                        @{ title = "Metric"; value = $alert.metric; short = $true }
                        @{ title = "Value"; value = $alert.value; short = $true }
                        @{ title = "Timestamp"; value = $alert.timestamp; short = $true }
                    )
                }
            )
        }

        try {
            $jsonPayload = $payload | ConvertTo-Json -Depth 4
            Invoke-RestMethod -Uri $slackConfig.webhook_url -Method Post -Body $jsonPayload -ContentType "application/json"
        }
        catch {
            Write-Warning "Failed to send Slack alert: $($_.Exception.Message)"
        }
    }

    [void]SendTeamsAlert([hashtable]$alert) {
        $teamsConfig = $this.Config.NotificationConfig.teams
        
        $color = switch ($alert.severity) {
            "warning" { "FF9900"  }
            "critical" { "FF0000" }
            "failure" { "8B0000"  }
            default { "00FF00" }
        }

        $payload = @{
            "@type" = "MessageCard"
            "@context" = "https://schema.org/extensions"
            summary = "Story 1.1 Quality Alert"
            themeColor = $color
            title = "🚨 SmartWatch Story 1.1 Alert"
            text = $alert.message
            sections = @(
                @{
                    facts = @(
                        @{ name = "Severity"; value = $alert.severity.ToUpper() }
                        @{ name = "Metric"; value = $alert.metric }
                        @{ name = "Current Value"; value = $alert.value }
                        @{ name = "Timestamp"; value = $alert.timestamp }
                    )
                }
            )
        }

        try {
            $jsonPayload = $payload | ConvertTo-Json -Depth 4
            Invoke-RestMethod -Uri $teamsConfig.webhook_url -Method Post -Body $jsonPayload -ContentType "application/json"
        }
        catch {
            Write-Warning "Failed to send Teams alert: $($_.Exception.Message)"
        }
    }

    [hashtable]GetAlertStatus() {
        return @{
            system_initialized = $this.IsInitialized
            active_channels = ($this.NotificationChannels.Values | Where-Object { $_.enabled }).Count
            alert_history_count = $this.AlertHistory.Keys.Count
            last_evaluation = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            configuration_loaded = $this.Config -ne $null
        }
    }
}

# Monitoring function that integrates with Story 1.1 monitoring
function Start-Story11AlertMonitoring {
    param(
        [int]$IntervalSeconds = 60,
        [string]$MonitoringScriptPath = ".\story-1-1-monitoring.ps1",
        [string]$AlertConfigPath = ".\alert-config.json",
        [string]$LogPath = ".\logs\alerts"
    )

    Write-Host "🚀 Starting Story 1.1 Alert Monitoring System" -ForegroundColor Cyan
    
    # Initialize alert system
    $alertSystem = [Story11AlertSystem]::new($AlertConfigPath, $LogPath)
    
    if (-not $alertSystem.IsInitialized) {
        Write-Host "❌ Failed to initialize alert system" -ForegroundColor Red
        return
    }

    # Monitor loop
    while ($true) {
        try {
            # Get current metrics from monitoring system
            if (Test-Path $MonitoringScriptPath) {
                $metricsResult = & $MonitoringScriptPath -Action "collect-metrics" -Quiet
                
                if ($metricsResult -and $metricsResult.success) {
                    # Evaluate metrics for alerts
                    $alertEvaluation = $alertSystem.EvaluateMetrics($metricsResult.metrics)
                    
                    if ($alertEvaluation.alerts.Count -gt 0) {
                        Write-Host "⚠️  Processing $($alertEvaluation.alerts.Count) alerts..." -ForegroundColor Yellow
                        $alertSystem.ProcessAlerts($alertEvaluation.alerts)
                    }
                }
            }
            else {
                Write-Warning "Monitoring script not found: $MonitoringScriptPath"
            }
            
            Start-Sleep -Seconds $IntervalSeconds
        }
        catch {
            Write-Host "❌ Error in monitoring loop: $($_.Exception.Message)" -ForegroundColor Red
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
}

# Test alert functionality
function Test-Story11AlertSystem {
    param(
        [string]$AlertConfigPath = ".\alert-config.json",
        [string]$LogPath = ".\logs\alerts"
    )

    Write-Host "🧪 Testing Story 1.1 Alert System" -ForegroundColor Cyan
    
    $alertSystem = [Story11AlertSystem]::new($AlertConfigPath, $LogPath)
    
    if (-not $alertSystem.IsInitialized) {
        Write-Host "❌ Alert system not initialized" -ForegroundColor Red
        return
    }

    # Test metrics that should trigger alerts
    $testMetrics = @{
        boot_time_ms = 6000        # Should trigger failure alert
        memory_usage_percent = 88  # Should trigger critical alert
        display_init_ms = 900      # Should trigger warning alert
        touch_response_ms = 50     # Should be normal
        error_rate_percent = 1.5   # Should be normal
    }

    Write-Host "📊 Testing with metrics:" -ForegroundColor Yellow
    $testMetrics.GetEnumerator() | ForEach-Object {
        Write-Host "   $($_.Key): $($_.Value)" -ForegroundColor Gray
    }

    $alertEvaluation = $alertSystem.EvaluateMetrics($testMetrics)
    
    Write-Host "📈 Alert Evaluation Results:" -ForegroundColor Green
    Write-Host "   Alerts Generated: $($alertEvaluation.alerts_generated)" -ForegroundColor Gray
    Write-Host "   Metrics Evaluated: $($alertEvaluation.metrics_evaluated)" -ForegroundColor Gray
    
    if ($alertEvaluation.alerts.Count -gt 0) {
        Write-Host "🚨 Processing test alerts..." -ForegroundColor Yellow
        $alertSystem.ProcessAlerts($alertEvaluation.alerts)
    }

    $status = $alertSystem.GetAlertStatus()
    Write-Host "📊 Alert System Status:" -ForegroundColor Green
    $status.GetEnumerator() | ForEach-Object {
        Write-Host "   $($_.Key): $($_.Value)" -ForegroundColor Gray
    }
}

# Main execution logic
switch ($AlertMode) {
    "monitor" {
        Start-Story11AlertMonitoring -IntervalSeconds $MonitoringIntervalSeconds
    }
    "test" {
        Test-Story11AlertSystem
    }
    "configure" {
        Write-Host "📝 Configuration mode - check alert-config.json for settings" -ForegroundColor Cyan
    }
    default {
        Write-Host "Usage: .\story-1-1-alerts.ps1 -AlertMode [monitor|test|configure]" -ForegroundColor Yellow
    }
}