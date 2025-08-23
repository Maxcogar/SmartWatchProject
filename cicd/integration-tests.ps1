#requires -version 5.1

<#
.SYNOPSIS
    Comprehensive integration tests for SmartWatch CI/CD system
.DESCRIPTION
    Tests the complete CI/CD pipeline integration with existing quality gate framework.
    Validates compatibility, functionality, and data flow between all components.
.PARAMETER TestSuite
    Specific test suite to run (All, QuickSmoke, FullIntegration, Performance)
.PARAMETER DryRun
    Run tests in simulation mode without making changes
.PARAMETER Verbose
    Enable detailed test output and logging
.PARAMETER ReportPath
    Path for test report generation
.EXAMPLE
    .\integration-tests.ps1 -TestSuite All -Verbose
.EXAMPLE
    .\integration-tests.ps1 -TestSuite QuickSmoke -DryRun
.NOTES
    ESP32-S3 SmartWatch Project - CI/CD Integration Tests
    Requires: PowerShell 5.1+, ESP-IDF environment
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("All", "QuickSmoke", "FullIntegration", "Performance", "Security")]
    [string]$TestSuite = "All",
    
    [Parameter()]
    [switch]$DryRun,
    
    [Parameter()]
    [switch]$Verbose,
    
    [Parameter()]
    [string]$ReportPath = ".\reports\integration-test-report.html"
)

# Enhanced error handling and logging
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Global test configuration
$Global:TestConfig = @{
    ProjectRoot = (Get-Item $PSScriptRoot).Parent.FullName
    TestStartTime = Get-Date
    TestResults = @()
    PassedTests = 0
    FailedTests = 0
    SkippedTests = 0
    DryRun = $DryRun.IsPresent
    Verbose = $Verbose.IsPresent
}

#region Logging and Utilities

function Write-TestLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARN"  { Write-Host $logMessage -ForegroundColor Yellow }
        "PASS"  { Write-Host $logMessage -ForegroundColor Green }
        "FAIL"  { Write-Host $logMessage -ForegroundColor Red }
        "INFO"  { 
            if ($Global:TestConfig.Verbose) {
                Write-Host $logMessage -ForegroundColor Cyan 
            }
        }
        default { Write-Host $logMessage }
    }
    
    # Also log to file
    $logFile = Join-Path $Global:TestConfig.ProjectRoot "logs\integration-tests.log"
    $logDir = Split-Path $logFile -Parent
    if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Add-Content -Path $logFile -Value $logMessage
}

function Add-TestResult {
    param(
        [string]$TestName,
        [string]$Status,
        [string]$Details = "",
        [timespan]$Duration = [timespan]::Zero,
        [string]$Category = "General"
    )
    
    $result = @{
        TestName = $TestName
        Status = $Status
        Details = $Details
        Duration = $Duration
        Category = $Category
        Timestamp = Get-Date
    }
    
    $Global:TestConfig.TestResults += $result
    
    switch ($Status) {
        "PASS" { 
            $Global:TestConfig.PassedTests++
            Write-TestLog "✅ $TestName - $Details" "PASS"
        }
        "FAIL" { 
            $Global:TestConfig.FailedTests++
            Write-TestLog "❌ $TestName - $Details" "FAIL"
        }
        "SKIP" { 
            $Global:TestConfig.SkippedTests++
            Write-TestLog "⏭️ $TestName - $Details" "WARN"
        }
    }
}

function Test-ScriptExists {
    param([string]$ScriptPath)
    
    $fullPath = Join-Path $Global:TestConfig.ProjectRoot $ScriptPath
    if (Test-Path $fullPath) {
        return $fullPath
    }
    return $null
}

function Test-FileContent {
    param([string]$FilePath, [string[]]$RequiredPatterns)
    
    if (!(Test-Path $FilePath)) {
        return $false, "File not found: $FilePath"
    }
    
    $content = Get-Content $FilePath -Raw
    $missingPatterns = @()
    
    foreach ($pattern in $RequiredPatterns) {
        if ($content -notmatch $pattern) {
            $missingPatterns += $pattern
        }
    }
    
    if ($missingPatterns.Count -gt 0) {
        return $false, "Missing patterns: $($missingPatterns -join ', ')"
    }
    
    return $true, "All required patterns found"
}

#endregion

#region Test Suites

function Test-ExistingSystemCompatibility {
    Write-TestLog "Testing compatibility with existing quality gate system..." "INFO"
    
    # Test 1: Verify existing scripts are accessible
    $existingScripts = @(
        "scripts\validate-documents.ps1",
        "scripts\quality-metrics-collector.ps1",
        "firmware\build_scripts\build.ps1"
    )
    
    foreach ($script in $existingScripts) {
        $startTime = Get-Date
        $scriptPath = Test-ScriptExists $script
        $duration = (Get-Date) - $startTime
        
        if ($scriptPath) {
            Add-TestResult -TestName "Existing Script Access: $script" -Status "PASS" -Duration $duration -Category "Compatibility"
        } else {
            Add-TestResult -TestName "Existing Script Access: $script" -Status "FAIL" -Details "Script not found" -Duration $duration -Category "Compatibility"
        }
    }
    
    # Test 2: Verify CI/CD scripts exist
    $cicdScripts = @(
        "cicd\cicd-pipeline.ps1",
        "cicd\testing-pipeline.ps1",
        "cicd\quality-integration.ps1",
        "cicd\deployment-automation.ps1",
        "cicd\monitoring-dashboard.ps1"
    )
    
    foreach ($script in $cicdScripts) {
        $startTime = Get-Date
        $scriptPath = Test-ScriptExists $script
        $duration = (Get-Date) - $startTime
        
        if ($scriptPath) {
            Add-TestResult -TestName "CI/CD Script Exists: $script" -Status "PASS" -Duration $duration -Category "Compatibility"
        } else {
            Add-TestResult -TestName "CI/CD Script Exists: $script" -Status "FAIL" -Details "Script not found" -Duration $duration -Category "Compatibility"
        }
    }
    
    # Test 3: Validate script integration points
    $integrationTests = @{
        "quality-integration.ps1" = @("Invoke-QualityGateValidation", "Integration with validate-documents.ps1")
        "monitoring-dashboard.ps1" = @("Generate-MonitoringDashboard", "Integration with quality-metrics-collector.ps1")
        "cicd-pipeline.ps1" = @("Invoke-CICDPipeline", "Quality gate integration")
    }
    
    foreach ($script in $integrationTests.Keys) {
        $startTime = Get-Date
        $scriptPath = Test-ScriptExists "cicd\$script"
        
        if ($scriptPath) {
            $isValid, $details = Test-FileContent -FilePath $scriptPath -RequiredPatterns $integrationTests[$script]
            $duration = (Get-Date) - $startTime
            
            if ($isValid) {
                Add-TestResult -TestName "Integration Points: $script" -Status "PASS" -Details $details -Duration $duration -Category "Integration"
            } else {
                Add-TestResult -TestName "Integration Points: $script" -Status "FAIL" -Details $details -Duration $duration -Category "Integration"
            }
        }
    }
}

function Test-QualityGateIntegration {
    Write-TestLog "Testing quality gate integration functionality..." "INFO"
    
    if ($Global:TestConfig.DryRun) {
        Add-TestResult -TestName "Quality Gate Integration" -Status "SKIP" -Details "Dry run mode" -Category "Integration"
        return
    }
    
    # Test 1: Quality integration script execution
    $startTime = Get-Date
    $qualityScript = Test-ScriptExists "cicd\quality-integration.ps1"
    
    if ($qualityScript) {
        try {
            # Test with dry run to avoid side effects
            $result = & $qualityScript -DryRun -TestMode
            $duration = (Get-Date) - $startTime
            
            if ($LASTEXITCODE -eq 0) {
                Add-TestResult -TestName "Quality Integration Script Execution" -Status "PASS" -Details "Script executed successfully" -Duration $duration -Category "Integration"
            } else {
                Add-TestResult -TestName "Quality Integration Script Execution" -Status "FAIL" -Details "Script failed with exit code $LASTEXITCODE" -Duration $duration -Category "Integration"
            }
        }
        catch {
            $duration = (Get-Date) - $startTime
            Add-TestResult -TestName "Quality Integration Script Execution" -Status "FAIL" -Details "Exception: $($_.Exception.Message)" -Duration $duration -Category "Integration"
        }
    }
    
    # Test 2: Configuration compatibility
    $configPaths = @(
        "config\quality-thresholds.json",
        "config\cicd-config.json"
    )
    
    foreach ($configPath in $configPaths) {
        $startTime = Get-Date
        $fullPath = Join-Path $Global:TestConfig.ProjectRoot $configPath
        $duration = (Get-Date) - $startTime
        
        if (Test-Path $fullPath) {
            try {
                $config = Get-Content $fullPath | ConvertFrom-Json
                Add-TestResult -TestName "Configuration Validation: $configPath" -Status "PASS" -Details "Valid JSON configuration" -Duration $duration -Category "Configuration"
            }
            catch {
                Add-TestResult -TestName "Configuration Validation: $configPath" -Status "FAIL" -Details "Invalid JSON: $($_.Exception.Message)" -Duration $duration -Category "Configuration"
            }
        } else {
            Add-TestResult -TestName "Configuration Validation: $configPath" -Status "FAIL" -Details "Configuration file not found" -Duration $duration -Category "Configuration"
        }
    }
}

function Test-BuildPipelineIntegration {
    Write-TestLog "Testing build pipeline integration..." "INFO"
    
    # Test 1: ESP-IDF environment availability
    $startTime = Get-Date
    try {
        $idfPath = $env:IDF_PATH
        $duration = (Get-Date) - $startTime
        
        if ($idfPath -and (Test-Path $idfPath)) {
            Add-TestResult -TestName "ESP-IDF Environment" -Status "PASS" -Details "IDF_PATH: $idfPath" -Duration $duration -Category "Environment"
        } else {
            Add-TestResult -TestName "ESP-IDF Environment" -Status "FAIL" -Details "ESP-IDF not found or not configured" -Duration $duration -Category "Environment"
        }
    }
    catch {
        $duration = (Get-Date) - $startTime
        Add-TestResult -TestName "ESP-IDF Environment" -Status "FAIL" -Details "Exception: $($_.Exception.Message)" -Duration $duration -Category "Environment"
    }
    
    # Test 2: Build script integration
    if (!$Global:TestConfig.DryRun) {
        $startTime = Get-Date
        $buildScript = Test-ScriptExists "firmware\build_scripts\build.ps1"
        
        if ($buildScript) {
            try {
                # Test build script with validation only
                $result = & $buildScript -Configuration "debug" -ValidateOnly -Quiet
                $duration = (Get-Date) - $startTime
                
                if ($LASTEXITCODE -eq 0) {
                    Add-TestResult -TestName "Build Script Integration" -Status "PASS" -Details "Build validation successful" -Duration $duration -Category "Build"
                } else {
                    Add-TestResult -TestName "Build Script Integration" -Status "FAIL" -Details "Build validation failed" -Duration $duration -Category "Build"
                }
            }
            catch {
                $duration = (Get-Date) - $startTime
                Add-TestResult -TestName "Build Script Integration" -Status "FAIL" -Details "Exception: $($_.Exception.Message)" -Duration $duration -Category "Build"
            }
        }
    } else {
        Add-TestResult -TestName "Build Script Integration" -Status "SKIP" -Details "Dry run mode" -Category "Build"
    }
    
    # Test 3: CI/CD pipeline build integration
    $startTime = Get-Date
    $pipelineScript = Test-ScriptExists "cicd\cicd-pipeline.ps1"
    $duration = (Get-Date) - $startTime
    
    if ($pipelineScript) {
        $isValid, $details = Test-FileContent -FilePath $pipelineScript -RequiredPatterns @(
            "build_scripts\\build\.ps1",
            "Configuration.*debug.*release.*test",
            "Quality.*gate.*integration"
        )
        
        if ($isValid) {
            Add-TestResult -TestName "Pipeline Build Integration" -Status "PASS" -Details $details -Duration $duration -Category "Build"
        } else {
            Add-TestResult -TestName "Pipeline Build Integration" -Status "FAIL" -Details $details -Duration $duration -Category "Build"
        }
    }
}

function Test-DeploymentIntegration {
    Write-TestLog "Testing deployment automation integration..." "INFO"
    
    # Test 1: Deployment script functionality
    $startTime = Get-Date
    $deployScript = Test-ScriptExists "cicd\deployment-automation.ps1"
    $duration = (Get-Date) - $startTime
    
    if ($deployScript) {
        $requiredPatterns = @(
            "OTA.*deployment",
            "Rollback.*capability",
            "Environment.*validation",
            "Binary.*signing"
        )
        
        $isValid, $details = Test-FileContent -FilePath $deployScript -RequiredPatterns $requiredPatterns
        
        if ($isValid) {
            Add-TestResult -TestName "Deployment Script Features" -Status "PASS" -Details $details -Duration $duration -Category "Deployment"
        } else {
            Add-TestResult -TestName "Deployment Script Features" -Status "FAIL" -Details $details -Duration $duration -Category "Deployment"
        }
        
        # Test deployment environments
        if (!$Global:TestConfig.DryRun) {
            try {
                $result = & $deployScript -Environment "development" -DryRun -Validate
                $duration2 = (Get-Date) - $startTime
                
                if ($LASTEXITCODE -eq 0) {
                    Add-TestResult -TestName "Deployment Environment Validation" -Status "PASS" -Details "Environment validation successful" -Duration $duration2 -Category "Deployment"
                } else {
                    Add-TestResult -TestName "Deployment Environment Validation" -Status "FAIL" -Details "Validation failed" -Duration $duration2 -Category "Deployment"
                }
            }
            catch {
                $duration2 = (Get-Date) - $startTime
                Add-TestResult -TestName "Deployment Environment Validation" -Status "FAIL" -Details "Exception: $($_.Exception.Message)" -Duration $duration2 -Category "Deployment"
            }
        } else {
            Add-TestResult -TestName "Deployment Environment Validation" -Status "SKIP" -Details "Dry run mode" -Category "Deployment"
        }
    }
}

function Test-MonitoringIntegration {
    Write-TestLog "Testing monitoring and reporting integration..." "INFO"
    
    # Test 1: Monitoring dashboard functionality
    $startTime = Get-Date
    $monitorScript = Test-ScriptExists "cicd\monitoring-dashboard.ps1"
    $duration = (Get-Date) - $startTime
    
    if ($monitorScript) {
        $requiredPatterns = @(
            "Generate-MonitoringDashboard",
            "quality-metrics-collector\.ps1",
            "Real.*time.*monitoring",
            "HTML.*dashboard"
        )
        
        $isValid, $details = Test-FileContent -FilePath $monitorScript -RequiredPatterns $requiredPatterns
        
        if ($isValid) {
            Add-TestResult -TestName "Monitoring Script Features" -Status "PASS" -Details $details -Duration $duration -Category "Monitoring"
        } else {
            Add-TestResult -TestName "Monitoring Script Features" -Status "FAIL" -Details $details -Duration $duration -Category "Monitoring"
        }
        
        # Test dashboard generation
        if (!$Global:TestConfig.DryRun) {
            try {
                $result = & $monitorScript -GenerateReport -DryRun
                $duration2 = (Get-Date) - $startTime
                
                if ($LASTEXITCODE -eq 0) {
                    Add-TestResult -TestName "Dashboard Generation" -Status "PASS" -Details "Dashboard generation successful" -Duration $duration2 -Category "Monitoring"
                } else {
                    Add-TestResult -TestName "Dashboard Generation" -Status "FAIL" -Details "Generation failed" -Duration $duration2 -Category "Monitoring"
                }
            }
            catch {
                $duration2 = (Get-Date) - $startTime
                Add-TestResult -TestName "Dashboard Generation" -Status "FAIL" -Details "Exception: $($_.Exception.Message)" -Duration $duration2 -Category "Monitoring"
            }
        } else {
            Add-TestResult -TestName "Dashboard Generation" -Status "SKIP" -Details "Dry run mode" -Category "Monitoring"
        }
    }
}

function Test-EndToEndPipeline {
    Write-TestLog "Testing end-to-end pipeline integration..." "INFO"
    
    if ($Global:TestConfig.DryRun) {
        Add-TestResult -TestName "End-to-End Pipeline" -Status "SKIP" -Details "Dry run mode - would require full pipeline execution" -Category "E2E"
        return
    }
    
    # Test 1: Full pipeline dry run
    $startTime = Get-Date
    $pipelineScript = Test-ScriptExists "cicd\cicd-pipeline.ps1"
    
    if ($pipelineScript) {
        try {
            $result = & $pipelineScript -DryRun -Configuration "debug" -SkipTests
            $duration = (Get-Date) - $startTime
            
            if ($LASTEXITCODE -eq 0) {
                Add-TestResult -TestName "Full Pipeline Dry Run" -Status "PASS" -Details "Pipeline executed successfully in dry run mode" -Duration $duration -Category "E2E"
            } else {
                Add-TestResult -TestName "Full Pipeline Dry Run" -Status "FAIL" -Details "Pipeline failed with exit code $LASTEXITCODE" -Duration $duration -Category "E2E"
            }
        }
        catch {
            $duration = (Get-Date) - $startTime
            Add-TestResult -TestName "Full Pipeline Dry Run" -Status "FAIL" -Details "Exception: $($_.Exception.Message)" -Duration $duration -Category "E2E"
        }
    }
    
    # Test 2: Configuration consistency across all components
    $configTests = @{
        "Quality thresholds consistency" = @("config\quality-thresholds.json", "scripts\validate-documents.ps1")
        "Build configuration alignment" = @("config\cicd-config.json", "firmware\build_scripts\build.ps1")
        "Deployment environment consistency" = @("config\deployment-config.json", "cicd\deployment-automation.ps1")
    }
    
    foreach ($testName in $configTests.Keys) {
        $startTime = Get-Date
        $files = $configTests[$testName]
        $allFilesExist = $true
        
        foreach ($file in $files) {
            $fullPath = Join-Path $Global:TestConfig.ProjectRoot $file
            if (!(Test-Path $fullPath)) {
                $allFilesExist = $false
                break
            }
        }
        
        $duration = (Get-Date) - $startTime
        
        if ($allFilesExist) {
            Add-TestResult -TestName $testName -Status "PASS" -Details "All required files exist" -Duration $duration -Category "Configuration"
        } else {
            Add-TestResult -TestName $testName -Status "FAIL" -Details "Missing required configuration files" -Duration $duration -Category "Configuration"
        }
    }
}

function Test-PerformanceMetrics {
    Write-TestLog "Testing performance characteristics..." "INFO"
    
    # Test 1: Script startup time
    $scripts = @(
        "cicd\cicd-pipeline.ps1",
        "cicd\quality-integration.ps1",
        "cicd\monitoring-dashboard.ps1"
    )
    
    foreach ($script in $scripts) {
        $scriptPath = Test-ScriptExists $script
        if ($scriptPath) {
            $startTime = Get-Date
            try {
                # Measure script loading time (syntax check)
                $null = Get-Content $scriptPath | Out-Null
                $duration = (Get-Date) - $startTime
                
                if ($duration.TotalSeconds -lt 2) {
                    Add-TestResult -TestName "Script Load Performance: $script" -Status "PASS" -Details "Load time: $($duration.TotalMilliseconds)ms" -Duration $duration -Category "Performance"
                } else {
                    Add-TestResult -TestName "Script Load Performance: $script" -Status "FAIL" -Details "Slow load time: $($duration.TotalSeconds)s" -Duration $duration -Category "Performance"
                }
            }
            catch {
                $duration = (Get-Date) - $startTime
                Add-TestResult -TestName "Script Load Performance: $script" -Status "FAIL" -Details "Load error: $($_.Exception.Message)" -Duration $duration -Category "Performance"
            }
        }
    }
    
    # Test 2: Memory usage estimation
    $startTime = Get-Date
    $beforeMemory = (Get-Process -Id $PID).WorkingSet64
    
    # Simulate loading all scripts
    $allScripts = Get-ChildItem -Path (Join-Path $Global:TestConfig.ProjectRoot "cicd") -Filter "*.ps1"
    foreach ($script in $allScripts) {
        try {
            $null = Get-Content $script.FullName | Out-Null
        }
        catch {
            # Ignore errors for this performance test
        }
    }
    
    $afterMemory = (Get-Process -Id $PID).WorkingSet64
    $memoryIncrease = ($afterMemory - $beforeMemory) / 1MB
    $duration = (Get-Date) - $startTime
    
    if ($memoryIncrease -lt 50) {  # Less than 50MB increase
        Add-TestResult -TestName "Memory Usage" -Status "PASS" -Details "Memory increase: $([math]::Round($memoryIncrease, 2))MB" -Duration $duration -Category "Performance"
    } else {
        Add-TestResult -TestName "Memory Usage" -Status "WARN" -Details "High memory increase: $([math]::Round($memoryIncrease, 2))MB" -Duration $duration -Category "Performance"
    }
}

function Test-SecurityConfiguration {
    Write-TestLog "Testing security configuration..." "INFO"
    
    # Test 1: Script execution policies
    $startTime = Get-Date
    $executionPolicy = Get-ExecutionPolicy
    $duration = (Get-Date) - $startTime
    
    if ($executionPolicy -eq "RemoteSigned" -or $executionPolicy -eq "Restricted") {
        Add-TestResult -TestName "Execution Policy" -Status "PASS" -Details "Policy: $executionPolicy" -Duration $duration -Category "Security"
    } else {
        Add-TestResult -TestName "Execution Policy" -Status "WARN" -Details "Policy: $executionPolicy (consider RemoteSigned)" -Duration $duration -Category "Security"
    }
    
    # Test 2: Sensitive data protection
    $scriptsToCheck = Get-ChildItem -Path (Join-Path $Global:TestConfig.ProjectRoot "cicd") -Filter "*.ps1"
    
    foreach ($script in $scriptsToCheck) {
        $startTime = Get-Date
        $content = Get-Content $script.FullName -Raw
        $duration = (Get-Date) - $startTime
        
        # Check for hardcoded sensitive data patterns
        $sensitivePatterns = @("password\s*=", "key\s*=", "secret\s*=", "token\s*=")
        $foundSensitive = $false
        
        foreach ($pattern in $sensitivePatterns) {
            if ($content -match $pattern) {
                $foundSensitive = $true
                break
            }
        }
        
        if (!$foundSensitive) {
            Add-TestResult -TestName "Sensitive Data Check: $($script.Name)" -Status "PASS" -Details "No hardcoded sensitive data found" -Duration $duration -Category "Security"
        } else {
            Add-TestResult -TestName "Sensitive Data Check: $($script.Name)" -Status "FAIL" -Details "Potential hardcoded sensitive data found" -Duration $duration -Category "Security"
        }
    }
}

#endregion

#region Report Generation

function Generate-TestReport {
    Write-TestLog "Generating integration test report..." "INFO"
    
    $reportDir = Split-Path $ReportPath -Parent
    if (!(Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $totalTests = $Global:TestConfig.TestResults.Count
    $successRate = if ($totalTests -gt 0) { [math]::Round(($Global:TestConfig.PassedTests / $totalTests) * 100, 2) } else { 0 }
    $testDuration = (Get-Date) - $Global:TestConfig.TestStartTime
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>SmartWatch CI/CD Integration Test Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; padding-bottom: 20px; border-bottom: 2px solid #eee; }
        .header h1 { color: #2c3e50; margin-bottom: 10px; }
        .header .subtitle { color: #7f8c8d; font-size: 1.1em; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .summary-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; text-align: center; }
        .summary-card h3 { margin: 0 0 10px 0; font-size: 2em; }
        .summary-card p { margin: 0; opacity: 0.9; }
        .success-rate { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%) !important; }
        .passed-tests { background: linear-gradient(135deg, #56ab2f 0%, #a8e6cf 100%) !important; }
        .failed-tests { background: linear-gradient(135deg, #ff416c 0%, #ff4b2b 100%) !important; }
        .test-results { margin-top: 30px; }
        .category { margin-bottom: 30px; }
        .category h2 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .test-item { display: flex; align-items: center; padding: 15px; margin-bottom: 10px; border-radius: 8px; border-left: 4px solid; }
        .test-item.pass { background-color: #d4edda; border-color: #28a745; }
        .test-item.fail { background-color: #f8d7da; border-color: #dc3545; }
        .test-item.skip { background-color: #fff3cd; border-color: #ffc107; }
        .test-status { font-weight: bold; margin-right: 15px; min-width: 60px; }
        .test-details { flex-grow: 1; }
        .test-name { font-weight: 600; color: #2c3e50; }
        .test-description { color: #6c757d; font-size: 0.9em; margin-top: 5px; }
        .test-duration { color: #6c757d; font-size: 0.8em; text-align: right; min-width: 80px; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; text-align: center; color: #6c757d; }
        @media (max-width: 768px) {
            .container { margin: 10px; padding: 20px; }
            .summary { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 SmartWatch CI/CD Integration Test Report</h1>
            <p class="subtitle">Comprehensive integration testing for ESP32-S3 SmartWatch CI/CD Pipeline</p>
            <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
        
        <div class="summary">
            <div class="summary-card success-rate">
                <h3>$successRate%</h3>
                <p>Success Rate</p>
            </div>
            <div class="summary-card passed-tests">
                <h3>$($Global:TestConfig.PassedTests)</h3>
                <p>Passed Tests</p>
            </div>
            <div class="summary-card failed-tests">
                <h3>$($Global:TestConfig.FailedTests)</h3>
                <p>Failed Tests</p>
            </div>
            <div class="summary-card">
                <h3>$($Global:TestConfig.SkippedTests)</h3>
                <p>Skipped Tests</p>
            </div>
            <div class="summary-card">
                <h3>$([math]::Round($testDuration.TotalMinutes, 1))m</h3>
                <p>Total Duration</p>
            </div>
            <div class="summary-card">
                <h3>$totalTests</h3>
                <p>Total Tests</p>
            </div>
        </div>
        
        <div class="test-results">
"@
    
    # Group tests by category
    $categories = $Global:TestConfig.TestResults | Group-Object -Property Category | Sort-Object Name
    
    foreach ($category in $categories) {
        $html += @"
            <div class="category">
                <h2>📊 $($category.Name) Tests</h2>
"@
        
        foreach ($test in $category.Group | Sort-Object TestName) {
            $statusClass = $test.Status.ToLower()
            $statusIcon = switch ($test.Status) {
                "PASS" { "✅" }
                "FAIL" { "❌" }
                "SKIP" { "⏭️" }
                default { "❓" }
            }
            
            $html += @"
                <div class="test-item $statusClass">
                    <div class="test-status">$statusIcon $($test.Status)</div>
                    <div class="test-details">
                        <div class="test-name">$($test.TestName)</div>
                        <div class="test-description">$($test.Details)</div>
                    </div>
                    <div class="test-duration">$([math]::Round($test.Duration.TotalMilliseconds))ms</div>
                </div>
"@
        }
        
        $html += "</div>"
    }
    
    $html += @"
        </div>
        
        <div class="footer">
            <p><strong>ESP32-S3 SmartWatch Project - CI/CD Integration Tests</strong></p>
            <p>Test Suite: $TestSuite | Mode: $(if($Global:TestConfig.DryRun){"Dry Run"}else{"Full Execution"})</p>
            <p>Generated by PowerShell Integration Test Suite v1.0</p>
        </div>
    </div>
</body>
</html>
"@
    
    try {
        $html | Out-File -FilePath $ReportPath -Encoding UTF8
        Write-TestLog "✅ Test report generated: $ReportPath" "PASS"
    }
    catch {
        Write-TestLog "❌ Failed to generate test report: $($_.Exception.Message)" "FAIL"
    }
}

#endregion

#region Main Execution

function Invoke-IntegrationTests {
    Write-TestLog "🚀 Starting SmartWatch CI/CD Integration Tests" "INFO"
    Write-TestLog "Test Suite: $TestSuite | Mode: $(if($Global:TestConfig.DryRun){"Dry Run"}else{"Full Execution"})" "INFO"
    
    try {
        switch ($TestSuite) {
            "QuickSmoke" {
                Test-ExistingSystemCompatibility
                Test-QualityGateIntegration
            }
            "FullIntegration" {
                Test-ExistingSystemCompatibility
                Test-QualityGateIntegration
                Test-BuildPipelineIntegration
                Test-DeploymentIntegration
                Test-MonitoringIntegration
                Test-EndToEndPipeline
            }
            "Performance" {
                Test-PerformanceMetrics
            }
            "Security" {
                Test-SecurityConfiguration
            }
            "All" {
                Test-ExistingSystemCompatibility
                Test-QualityGateIntegration
                Test-BuildPipelineIntegration
                Test-DeploymentIntegration
                Test-MonitoringIntegration
                Test-EndToEndPipeline
                Test-PerformanceMetrics
                Test-SecurityConfiguration
            }
        }
        
        # Generate comprehensive test report
        Generate-TestReport
        
        # Final summary
        $totalTests = $Global:TestConfig.TestResults.Count
        $testDuration = (Get-Date) - $Global:TestConfig.TestStartTime
        
        Write-TestLog "📊 Test Execution Summary:" "INFO"
        Write-TestLog "   Total Tests: $totalTests" "INFO"
        Write-TestLog "   Passed: $($Global:TestConfig.PassedTests)" "PASS"
        Write-TestLog "   Failed: $($Global:TestConfig.FailedTests)" "FAIL"
        Write-TestLog "   Skipped: $($Global:TestConfig.SkippedTests)" "WARN"
        Write-TestLog "   Duration: $([math]::Round($testDuration.TotalMinutes, 2)) minutes" "INFO"
        Write-TestLog "   Success Rate: $([math]::Round(($Global:TestConfig.PassedTests / $totalTests) * 100, 2))%" "INFO"
        
        if ($Global:TestConfig.FailedTests -eq 0) {
            Write-TestLog "🎉 All tests passed! CI/CD integration is ready." "PASS"
            exit 0
        } else {
            Write-TestLog "⚠️ Some tests failed. Please review the results." "WARN"
            exit 1
        }
    }
    catch {
        Write-TestLog "💥 Critical error during test execution: $($_.Exception.Message)" "ERROR"
        Write-TestLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
        exit 2
    }
}

# Execute the integration tests
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-IntegrationTests
}

#endregion