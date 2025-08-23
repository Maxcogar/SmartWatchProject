#requires -version 5.1

<#
.SYNOPSIS
    Final validation script for SmartWatch CI/CD system integration
.DESCRIPTION
    Performs comprehensive validation of the complete CI/CD system integration
    with existing quality gate framework. This is the master validation script.
.PARAMETER ValidationLevel
    Level of validation to perform (Quick, Standard, Comprehensive)
.PARAMETER GenerateReport
    Generate detailed validation report
.PARAMETER FixIssues
    Attempt to automatically fix discovered issues
.EXAMPLE
    .\validate-integration.ps1 -ValidationLevel Comprehensive -GenerateReport
.NOTES
    ESP32-S3 SmartWatch Project - Final CI/CD Integration Validation
    This script validates the complete integration and readiness of the CI/CD system
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Quick", "Standard", "Comprehensive")]
    [string]$ValidationLevel = "Standard",
    
    [Parameter()]
    [switch]$GenerateReport,
    
    [Parameter()]
    [switch]$FixIssues,
    
    [Parameter()]
    [string]$ReportPath = ".\reports\integration-validation-report.html"
)

# Enhanced error handling and logging
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Global validation state
$Global:ValidationState = @{
    ProjectRoot = (Get-Item $PSScriptRoot).Parent.FullName
    StartTime = Get-Date
    Results = @()
    PassedValidations = 0
    FailedValidations = 0
    WarningValidations = 0
    FixedIssues = 0
}

#region Core Validation Functions

function Write-ValidationLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARN"  { Write-Host $logMessage -ForegroundColor Yellow }
        "PASS"  { Write-Host $logMessage -ForegroundColor Green }
        "FAIL"  { Write-Host $logMessage -ForegroundColor Red }
        "FIX"   { Write-Host $logMessage -ForegroundColor Magenta }
        "INFO"  { Write-Host $logMessage -ForegroundColor Cyan }
        default { Write-Host $logMessage }
    }
}

function Add-ValidationResult {
    param(
        [string]$Component,
        [string]$Test,
        [string]$Status,
        [string]$Details = "",
        [string]$FixAction = "",
        [timespan]$Duration = [timespan]::Zero
    )
    
    $result = @{
        Component = $Component
        Test = $Test
        Status = $Status
        Details = $Details
        FixAction = $FixAction
        Duration = $Duration
        Timestamp = Get-Date
    }
    
    $Global:ValidationState.Results += $result
    
    switch ($Status) {
        "PASS" { 
            $Global:ValidationState.PassedValidations++
            Write-ValidationLog "✅ $Component - $Test: $Details" "PASS"
        }
        "FAIL" { 
            $Global:ValidationState.FailedValidations++
            Write-ValidationLog "❌ $Component - $Test: $Details" "FAIL"
            if ($FixAction) {
                Write-ValidationLog "🔧 Suggested fix: $FixAction" "INFO"
            }
        }
        "WARN" { 
            $Global:ValidationState.WarningValidations++
            Write-ValidationLog "⚠️ $Component - $Test: $Details" "WARN"
        }
    }
}

#endregion

#region Validation Tests

function Test-ProjectStructure {
    Write-ValidationLog "Validating project structure..." "INFO"
    
    $requiredPaths = @{
        "Core Scripts" = @(
            "scripts\validate-documents.ps1",
            "scripts\quality-metrics-collector.ps1",
            "firmware\build_scripts\build.ps1"
        )
        "CI/CD Scripts" = @(
            "cicd\cicd-pipeline.ps1",
            "cicd\testing-pipeline.ps1",
            "cicd\quality-integration.ps1",
            "cicd\deployment-automation.ps1",
            "cicd\monitoring-dashboard.ps1"
        )
        "Configuration" = @(
            "config\cicd-config.json",
            "config\quality-thresholds.json"
        )
        "Directories" = @(
            "logs",
            "reports",
            "temp"
        )
    }
    
    foreach ($category in $requiredPaths.Keys) {
        foreach ($path in $requiredPaths[$category]) {
            $startTime = Get-Date
            $fullPath = Join-Path $Global:ValidationState.ProjectRoot $path
            $duration = (Get-Date) - $startTime
            
            if (Test-Path $fullPath) {
                Add-ValidationResult -Component "Structure" -Test "$category - $path" -Status "PASS" -Details "Exists" -Duration $duration
            } else {
                $fixAction = if ($path -like "*\") { "Create directory: New-Item -ItemType Directory -Path '$fullPath'" } else { "Create missing file" }
                Add-ValidationResult -Component "Structure" -Test "$category - $path" -Status "FAIL" -Details "Missing" -FixAction $fixAction -Duration $duration
                
                if ($FixIssues -and ($path -like "*logs" -or $path -like "*reports" -or $path -like "*temp")) {
                    try {
                        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
                        Write-ValidationLog "🔧 Created directory: $fullPath" "FIX"
                        $Global:ValidationState.FixedIssues++
                    }
                    catch {
                        Write-ValidationLog "❌ Failed to create directory: $($_.Exception.Message)" "ERROR"
                    }
                }
            }
        }
    }
}

function Test-ScriptIntegrity {
    Write-ValidationLog "Validating script integrity..." "INFO"
    
    $scripts = @{
        "cicd\cicd-pipeline.ps1" = @("Invoke-CICDPipeline", "param.*Configuration", "Quality.*gate")
        "cicd\quality-integration.ps1" = @("Invoke-QualityGateValidation", "validate-documents\.ps1")
        "cicd\monitoring-dashboard.ps1" = @("Generate-MonitoringDashboard", "quality-metrics-collector\.ps1")
        "cicd\testing-pipeline.ps1" = @("Invoke-TestingPipeline", "Hardware.*test")
        "cicd\deployment-automation.ps1" = @("Invoke-Deployment", "OTA.*deployment")
    }
    
    foreach ($script in $scripts.Keys) {
        $startTime = Get-Date
        $scriptPath = Join-Path $Global:ValidationState.ProjectRoot $script
        
        if (Test-Path $scriptPath) {
            $content = Get-Content $scriptPath -Raw
            $missingPatterns = @()
            
            foreach ($pattern in $scripts[$script]) {
                if ($content -notmatch $pattern) {
                    $missingPatterns += $pattern
                }
            }
            
            $duration = (Get-Date) - $startTime
            
            if ($missingPatterns.Count -eq 0) {
                Add-ValidationResult -Component "Scripts" -Test "Integrity - $script" -Status "PASS" -Details "All required patterns found" -Duration $duration
            } else {
                Add-ValidationResult -Component "Scripts" -Test "Integrity - $script" -Status "FAIL" -Details "Missing: $($missingPatterns -join ', ')" -Duration $duration
            }
        } else {
            $duration = (Get-Date) - $startTime
            Add-ValidationResult -Component "Scripts" -Test "Integrity - $script" -Status "FAIL" -Details "Script file missing" -Duration $duration
        }
    }
}

function Test-ConfigurationValidity {
    Write-ValidationLog "Validating configuration files..." "INFO"
    
    $configFiles = @{
        "config\cicd-config.json" = @{
            "required_sections" = @("cicd", "pipeline", "build", "testing", "quality", "deployment", "monitoring")
            "type" = "json"
        }
        "config\quality-thresholds.json" = @{
            "required_sections" = @("thresholds", "validation")
            "type" = "json"
        }
    }
    
    foreach ($configFile in $configFiles.Keys) {
        $startTime = Get-Date
        $configPath = Join-Path $Global:ValidationState.ProjectRoot $configFile
        $config = $configFiles[$configFile]
        
        if (Test-Path $configPath) {
            try {
                $content = Get-Content $configPath -Raw | ConvertFrom-Json
                $missingSections = @()
                
                foreach ($section in $config.required_sections) {
                    if (-not ($content | Get-Member -Name $section -MemberType NoteProperty)) {
                        $missingSections += $section
                    }
                }
                
                $duration = (Get-Date) - $startTime
                
                if ($missingSections.Count -eq 0) {
                    Add-ValidationResult -Component "Configuration" -Test "Structure - $configFile" -Status "PASS" -Details "All required sections present" -Duration $duration
                } else {
                    Add-ValidationResult -Component "Configuration" -Test "Structure - $configFile" -Status "FAIL" -Details "Missing sections: $($missingSections -join ', ')" -Duration $duration
                }
            }
            catch {
                $duration = (Get-Date) - $startTime
                Add-ValidationResult -Component "Configuration" -Test "Syntax - $configFile" -Status "FAIL" -Details "Invalid JSON: $($_.Exception.Message)" -Duration $duration
            }
        } else {
            $duration = (Get-Date) - $startTime
            Add-ValidationResult -Component "Configuration" -Test "Existence - $configFile" -Status "FAIL" -Details "Configuration file missing" -Duration $duration
        }
    }
}

function Test-EnvironmentPrerequisites {
    Write-ValidationLog "Validating environment prerequisites..." "INFO"
    
    # Test PowerShell version
    $startTime = Get-Date
    $psVersion = $PSVersionTable.PSVersion
    $duration = (Get-Date) - $startTime
    
    if ($psVersion.Major -ge 5) {
        Add-ValidationResult -Component "Environment" -Test "PowerShell Version" -Status "PASS" -Details "Version $($psVersion.Major).$($psVersion.Minor)" -Duration $duration
    } else {
        Add-ValidationResult -Component "Environment" -Test "PowerShell Version" -Status "FAIL" -Details "Version $($psVersion.Major).$($psVersion.Minor) - Requires 5.1+" -FixAction "Upgrade PowerShell" -Duration $duration
    }
    
    # Test ESP-IDF environment
    $startTime = Get-Date
    $idfPath = $env:IDF_PATH
    $duration = (Get-Date) - $startTime
    
    if ($idfPath -and (Test-Path $idfPath)) {
        Add-ValidationResult -Component "Environment" -Test "ESP-IDF Environment" -Status "PASS" -Details "IDF_PATH: $idfPath" -Duration $duration
    } else {
        Add-ValidationResult -Component "Environment" -Test "ESP-IDF Environment" -Status "WARN" -Details "ESP-IDF not configured or not found" -FixAction "Configure ESP-IDF environment" -Duration $duration
    }
    
    # Test execution policy
    $startTime = Get-Date
    $executionPolicy = Get-ExecutionPolicy
    $duration = (Get-Date) - $startTime
    
    if ($executionPolicy -ne "Restricted") {
        Add-ValidationResult -Component "Environment" -Test "Execution Policy" -Status "PASS" -Details "Policy: $executionPolicy" -Duration $duration
    } else {
        Add-ValidationResult -Component "Environment" -Test "Execution Policy" -Status "FAIL" -Details "Restricted execution policy" -FixAction "Set-ExecutionPolicy RemoteSigned" -Duration $duration
    }
}

function Test-IntegrationPoints {
    Write-ValidationLog "Validating integration points..." "INFO"
    
    # Test existing script compatibility
    $integrations = @{
        "Quality Gate Integration" = @{
            "script" = "cicd\quality-integration.ps1"
            "target" = "scripts\validate-documents.ps1"
            "pattern" = "validate-documents\.ps1"
        }
        "Metrics Integration" = @{
            "script" = "cicd\monitoring-dashboard.ps1"
            "target" = "scripts\quality-metrics-collector.ps1"
            "pattern" = "quality-metrics-collector\.ps1"
        }
        "Build Integration" = @{
            "script" = "cicd\cicd-pipeline.ps1"
            "target" = "firmware\build_scripts\build.ps1"
            "pattern" = "build_scripts.*build\.ps1"
        }
    }
    
    foreach ($integration in $integrations.Keys) {
        $startTime = Get-Date
        $config = $integrations[$integration]
        
        $scriptPath = Join-Path $Global:ValidationState.ProjectRoot $config.script
        $targetPath = Join-Path $Global:ValidationState.ProjectRoot $config.target
        
        if ((Test-Path $scriptPath) -and (Test-Path $targetPath)) {
            $content = Get-Content $scriptPath -Raw
            $duration = (Get-Date) - $startTime
            
            if ($content -match $config.pattern) {
                Add-ValidationResult -Component "Integration" -Test $integration -Status "PASS" -Details "Integration pattern found" -Duration $duration
            } else {
                Add-ValidationResult -Component "Integration" -Test $integration -Status "FAIL" -Details "Integration pattern missing" -Duration $duration
            }
        } else {
            $duration = (Get-Date) - $startTime
            Add-ValidationResult -Component "Integration" -Test $integration -Status "FAIL" -Details "Required files missing" -Duration $duration
        }
    }
}

function Test-FunctionalityReadiness {
    Write-ValidationLog "Testing functionality readiness..." "INFO"
    
    if ($ValidationLevel -eq "Quick") {
        Add-ValidationResult -Component "Functionality" -Test "Readiness Test" -Status "PASS" -Details "Skipped for Quick validation"
        return
    }
    
    # Test script execution readiness (dry run)
    $coreScripts = @(
        "cicd\cicd-pipeline.ps1",
        "cicd\quality-integration.ps1",
        "cicd\monitoring-dashboard.ps1"
    )
    
    foreach ($script in $coreScripts) {
        $startTime = Get-Date
        $scriptPath = Join-Path $Global:ValidationState.ProjectRoot $script
        
        if (Test-Path $scriptPath) {
            try {
                # Attempt to dot-source the script to check for syntax errors
                $null = . $scriptPath -WhatIf 2>$null
                $duration = (Get-Date) - $startTime
                Add-ValidationResult -Component "Functionality" -Test "Script Readiness - $script" -Status "PASS" -Details "Script loads without syntax errors" -Duration $duration
            }
            catch {
                $duration = (Get-Date) - $startTime
                Add-ValidationResult -Component "Functionality" -Test "Script Readiness - $script" -Status "FAIL" -Details "Syntax error: $($_.Exception.Message)" -Duration $duration
            }
        } else {
            $duration = (Get-Date) - $startTime
            Add-ValidationResult -Component "Functionality" -Test "Script Readiness - $script" -Status "FAIL" -Details "Script missing" -Duration $duration
        }
    }
}

#endregion

#region Report Generation

function Generate-ValidationReport {
    Write-ValidationLog "Generating validation report..." "INFO"
    
    $reportDir = Split-Path $ReportPath -Parent
    if (!(Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $totalValidations = $Global:ValidationState.Results.Count
    $successRate = if ($totalValidations -gt 0) { [math]::Round(($Global:ValidationState.PassedValidations / $totalValidations) * 100, 2) } else { 0 }
    $validationDuration = (Get-Date) - $Global:ValidationState.StartTime
    
    $overallStatus = if ($Global:ValidationState.FailedValidations -eq 0) { 
        if ($Global:ValidationState.WarningValidations -eq 0) { "READY" } else { "READY_WITH_WARNINGS" }
    } else { 
        "NOT_READY" 
    }
    
    $statusColor = switch ($overallStatus) {
        "READY" { "#28a745" }
        "READY_WITH_WARNINGS" { "#ffc107" }
        "NOT_READY" { "#dc3545" }
    }
    
    $statusIcon = switch ($overallStatus) {
        "READY" { "🟢" }
        "READY_WITH_WARNINGS" { "🟡" }
        "NOT_READY" { "🔴" }
    }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>SmartWatch CI/CD Integration Validation Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f8f9fa; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; padding-bottom: 20px; border-bottom: 3px solid #e9ecef; }
        .header h1 { color: #2c3e50; margin-bottom: 15px; font-size: 2.5em; }
        .header .subtitle { color: #6c757d; font-size: 1.2em; margin-bottom: 10px; }
        .header .timestamp { color: #868e96; }
        .status-banner { text-align: center; padding: 20px; margin: 20px 0; border-radius: 10px; font-size: 1.5em; font-weight: bold; color: white; background-color: $statusColor; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .summary-card { padding: 25px; border-radius: 12px; text-align: center; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .summary-card h3 { margin: 0 0 10px 0; font-size: 2.2em; font-weight: bold; }
        .summary-card p { margin: 0; font-size: 1.1em; color: #6c757d; }
        .success-card { background: linear-gradient(135deg, #28a745, #20c997); color: white; }
        .fail-card { background: linear-gradient(135deg, #dc3545, #e74c3c); color: white; }
        .warn-card { background: linear-gradient(135deg, #ffc107, #fd7e14); color: white; }
        .info-card { background: linear-gradient(135deg, #17a2b8, #6f42c1); color: white; }
        .neutral-card { background: linear-gradient(135deg, #6c757d, #495057); color: white; }
        .results { margin-top: 30px; }
        .component-section { margin-bottom: 30px; }
        .component-header { background: linear-gradient(135deg, #343a40, #495057); color: white; padding: 15px 20px; border-radius: 8px 8px 0 0; font-size: 1.3em; font-weight: bold; }
        .test-item { display: flex; align-items: center; padding: 15px 20px; border-bottom: 1px solid #dee2e6; }
        .test-item:last-child { border-bottom: none; border-radius: 0 0 8px 8px; }
        .test-item.pass { background-color: #d1f2eb; border-left: 4px solid #28a745; }
        .test-item.fail { background-color: #f8d7da; border-left: 4px solid #dc3545; }
        .test-item.warn { background-color: #fff3cd; border-left: 4px solid #ffc107; }
        .test-status { font-weight: bold; margin-right: 20px; min-width: 70px; font-size: 0.9em; }
        .test-details { flex-grow: 1; }
        .test-name { font-weight: 600; color: #2c3e50; margin-bottom: 5px; }
        .test-description { color: #6c757d; font-size: 0.9em; }
        .test-fix { color: #6f42c1; font-size: 0.85em; font-style: italic; margin-top: 5px; }
        .test-duration { color: #868e96; font-size: 0.8em; text-align: right; min-width: 80px; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 2px solid #e9ecef; text-align: center; color: #6c757d; }
        .recommendations { margin-top: 30px; padding: 20px; background-color: #f8f9fa; border-radius: 8px; border-left: 4px solid #17a2b8; }
        .recommendations h3 { color: #2c3e50; margin-bottom: 15px; }
        .recommendations ul { margin: 0; padding-left: 20px; }
        .recommendations li { margin-bottom: 8px; color: #495057; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 SmartWatch CI/CD Integration Validation</h1>
            <p class="subtitle">Comprehensive validation of ESP32-S3 SmartWatch CI/CD System</p>
            <p class="timestamp">Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Level: $ValidationLevel</p>
        </div>
        
        <div class="status-banner">
            $statusIcon System Status: $(switch ($overallStatus) {
                "READY" { "READY FOR PRODUCTION" }
                "READY_WITH_WARNINGS" { "READY WITH WARNINGS" }
                "NOT_READY" { "NOT READY - ISSUES FOUND" }
            })
        </div>
        
        <div class="summary">
            <div class="summary-card success-card">
                <h3>$successRate%</h3>
                <p>Success Rate</p>
            </div>
            <div class="summary-card $(if($Global:ValidationState.PassedValidations -gt 0){"success-card"}else{"neutral-card"})">
                <h3>$($Global:ValidationState.PassedValidations)</h3>
                <p>Passed</p>
            </div>
            <div class="summary-card $(if($Global:ValidationState.FailedValidations -gt 0){"fail-card"}else{"neutral-card"})">
                <h3>$($Global:ValidationState.FailedValidations)</h3>
                <p>Failed</p>
            </div>
            <div class="summary-card $(if($Global:ValidationState.WarningValidations -gt 0){"warn-card"}else{"neutral-card"})">
                <h3>$($Global:ValidationState.WarningValidations)</h3>
                <p>Warnings</p>
            </div>
            <div class="summary-card info-card">
                <h3>$([math]::Round($validationDuration.TotalMinutes, 1))m</h3>
                <p>Duration</p>
            </div>
            <div class="summary-card $(if($Global:ValidationState.FixedIssues -gt 0){"info-card"}else{"neutral-card"})">
                <h3>$($Global:ValidationState.FixedIssues)</h3>
                <p>Fixed Issues</p>
            </div>
        </div>
        
        <div class="results">
"@
    
    # Group results by component
    $components = $Global:ValidationState.Results | Group-Object -Property Component | Sort-Object Name
    
    foreach ($component in $components) {
        $html += @"
            <div class="component-section">
                <div class="component-header">📊 $($component.Name) Validation Results</div>
"@
        
        foreach ($result in $component.Group | Sort-Object Test) {
            $statusClass = $result.Status.ToLower()
            $statusIcon = switch ($result.Status) {
                "PASS" { "✅" }
                "FAIL" { "❌" }
                "WARN" { "⚠️" }
                default { "❓" }
            }
            
            $html += @"
                <div class="test-item $statusClass">
                    <div class="test-status">$statusIcon $($result.Status)</div>
                    <div class="test-details">
                        <div class="test-name">$($result.Test)</div>
                        <div class="test-description">$($result.Details)</div>
"@
            
            if ($result.FixAction) {
                $html += @"
                        <div class="test-fix">💡 Recommended fix: $($result.FixAction)</div>
"@
            }
            
            $html += @"
                    </div>
                    <div class="test-duration">$([math]::Round($result.Duration.TotalMilliseconds))ms</div>
                </div>
"@
        }
        
        $html += "</div>"
    }
    
    # Add recommendations section
    $html += @"
        </div>
        
        <div class="recommendations">
            <h3>🎯 Recommendations</h3>
            <ul>
"@
    
    if ($overallStatus -eq "READY") {
        $html += "<li><strong>✅ System Ready:</strong> Your CI/CD system is fully integrated and ready for use.</li>"
        $html += "<li><strong>🚀 Next Steps:</strong> Run the full integration test suite to validate end-to-end functionality.</li>"
        $html += "<li><strong>📊 Monitoring:</strong> Enable monitoring dashboard to track system performance.</li>"
    } elseif ($overallStatus -eq "READY_WITH_WARNINGS") {
        $html += "<li><strong>⚠️ Address Warnings:</strong> Review warning items to optimize system performance.</li>"
        $html += "<li><strong>✅ Core Ready:</strong> Essential functionality is operational, warnings are non-critical.</li>"
        $html += "<li><strong>🔧 Optional Fixes:</strong> Consider implementing suggested fixes for warnings.</li>"
    } else {
        $html += "<li><strong>❌ Critical Issues:</strong> Address all failed validations before using the system.</li>"
        $html += "<li><strong>🔧 Auto-Fix:</strong> Run with -FixIssues flag to automatically resolve fixable issues.</li>"
        $html += "<li><strong>📖 Documentation:</strong> Review integration documentation for manual fixes.</li>"
    }
    
    $html += @"
            </ul>
        </div>
        
        <div class="footer">
            <p><strong>ESP32-S3 SmartWatch Project - CI/CD Integration Validation</strong></p>
            <p>Validation Level: $ValidationLevel | $(if($FixIssues){"Auto-fix enabled"}else{"Auto-fix disabled"})</p>
            <p>Generated by PowerShell Integration Validation Suite v1.0</p>
        </div>
    </div>
</body>
</html>
"@
    
    try {
        $html | Out-File -FilePath $ReportPath -Encoding UTF8
        Write-ValidationLog "✅ Validation report generated: $ReportPath" "PASS"
    }
    catch {
        Write-ValidationLog "❌ Failed to generate validation report: $($_.Exception.Message)" "FAIL"
    }
}

#endregion

#region Main Execution

function Invoke-ValidationSuite {
    Write-ValidationLog "🔍 Starting SmartWatch CI/CD Integration Validation" "INFO"
    Write-ValidationLog "Validation Level: $ValidationLevel | Auto-fix: $(if($FixIssues){"Enabled"}else{"Disabled"})" "INFO"
    
    try {
        # Core validation tests
        Test-ProjectStructure
        Test-ScriptIntegrity
        Test-ConfigurationValidity
        Test-EnvironmentPrerequisites
        Test-IntegrationPoints
        
        # Extended validation for Standard and Comprehensive levels
        if ($ValidationLevel -ne "Quick") {
            Test-FunctionalityReadiness
        }
        
        # Generate report if requested
        if ($GenerateReport) {
            Generate-ValidationReport
        }
        
        # Final summary
        $totalValidations = $Global:ValidationState.Results.Count
        $validationDuration = (Get-Date) - $Global:ValidationState.StartTime
        
        Write-ValidationLog "📋 Validation Summary:" "INFO"
        Write-ValidationLog "   Total Validations: $totalValidations" "INFO"
        Write-ValidationLog "   Passed: $($Global:ValidationState.PassedValidations)" "PASS"
        Write-ValidationLog "   Failed: $($Global:ValidationState.FailedValidations)" "FAIL"
        Write-ValidationLog "   Warnings: $($Global:ValidationState.WarningValidations)" "WARN"
        Write-ValidationLog "   Issues Fixed: $($Global:ValidationState.FixedIssues)" "FIX"
        Write-ValidationLog "   Duration: $([math]::Round($validationDuration.TotalMinutes, 2)) minutes" "INFO"
        
        $successRate = if ($totalValidations -gt 0) { [math]::Round(($Global:ValidationState.PassedValidations / $totalValidations) * 100, 2) } else { 0 }
        Write-ValidationLog "   Success Rate: $successRate%" "INFO"
        
        # Determine overall status
        if ($Global:ValidationState.FailedValidations -eq 0) {
            if ($Global:ValidationState.WarningValidations -eq 0) {
                Write-ValidationLog "🎉 System is READY for production use!" "PASS"
                exit 0
            } else {
                Write-ValidationLog "✅ System is READY with some warnings to consider." "PASS"
                exit 0
            }
        } else {
            Write-ValidationLog "⚠️ System is NOT READY - please address failed validations." "FAIL"
            exit 1
        }
    }
    catch {
        Write-ValidationLog "💥 Critical error during validation: $($_.Exception.Message)" "ERROR"
        Write-ValidationLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
        exit 2
    }
}

# Execute the validation suite
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-ValidationSuite
}

#endregion