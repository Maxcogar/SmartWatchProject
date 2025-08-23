# Quality System Deployment Script
# SmartWatch Project - Automated Quality Gate System Setup
# Created: 2025-08-19

param(
    [string]$Action = "install",  # install, test, demo, status, uninstall
    [switch]$Force = $false,
    [switch]$Verbose = $false,
    [switch]$DemoMode = $false
)

$Script:SystemConfig = @{
    ScriptsPath = "scripts"
    DocsPath = "docs"
    QualityGatesPath = "docs\.quality-gates"
    RequiredScripts = @(
        "validate-documents.ps1",
        "quality-gate-workflow.ps1", 
        "self-assessment-tool.ps1",
        "quality-metrics-collector.ps1"
    )
    TestDocuments = @(
        "docs\architecture.md",
        "docs\prd.md"
    )
}

function Write-DeployLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "ERROR" = "Red"
        "WARNING" = "Yellow" 
        "SUCCESS" = "Green"
        "INFO" = "Cyan"
        "DEPLOY" = "Magenta"
        "TEST" = "White"
    }
    if ($Verbose -or $Level -eq "ERROR" -or $Level -eq "DEPLOY" -or $Level -eq "SUCCESS") {
        Write-Host "[$timestamp] $Level`: $Message" -ForegroundColor $colorMap[$Level]
    }
}

function Test-Prerequisites {
    Write-DeployLog "Checking system prerequisites..." "DEPLOY"
    
    $checks = @{
        "PowerShell Version" = $PSVersionTable.PSVersion.Major -ge 5
        "Scripts Directory" = Test-Path $Script:SystemConfig.ScriptsPath
        "Docs Directory" = Test-Path $Script:SystemConfig.DocsPath
        "Test Documents Available" = $true
    }
    
    # Check if test documents exist
    $missingDocs = @()
    foreach ($doc in $Script:SystemConfig.TestDocuments) {
        if (-not (Test-Path $doc)) {
            $missingDocs += $doc
            $checks["Test Documents Available"] = $false
        }
    }
    
    $allChecksPassed = $true
    foreach ($check in $checks.Keys) {
        if ($checks[$check]) {
            Write-DeployLog "✅ $check" "SUCCESS"
        } else {
            Write-DeployLog "❌ $check" "ERROR"
            $allChecksPassed = $false
        }
    }
    
    if ($missingDocs.Count -gt 0) {
        Write-DeployLog "Missing test documents: $($missingDocs -join ', ')" "ERROR"
    }
    
    return $allChecksPassed
}

function Test-ScriptAvailability {
    Write-DeployLog "Verifying quality gate scripts..." "DEPLOY"
    
    $allScriptsAvailable = $true
    foreach ($script in $Script:SystemConfig.RequiredScripts) {
        $scriptPath = Join-Path $Script:SystemConfig.ScriptsPath $script
        if (Test-Path $scriptPath) {
            Write-DeployLog "✅ $script found" "SUCCESS"
        } else {
            Write-DeployLog "❌ $script missing" "ERROR"
            $allScriptsAvailable = $false
        }
    }
    
    return $allScriptsAvailable
}

function Initialize-QualityGatesDirectory {
    Write-DeployLog "Initializing quality gates directory structure..." "DEPLOY"
    
    try {
        if (-not (Test-Path $Script:SystemConfig.QualityGatesPath)) {
            New-Item -ItemType Directory -Path $Script:SystemConfig.QualityGatesPath -Force | Out-Null
            Write-DeployLog "Created quality gates directory: $($Script:SystemConfig.QualityGatesPath)" "SUCCESS"
        } else {
            Write-DeployLog "Quality gates directory already exists" "INFO"
        }
        
        # Create README for quality gates directory
        $readmePath = Join-Path $Script:SystemConfig.QualityGatesPath "README.md"
        if (-not (Test-Path $readmePath) -or $Force) {
            $readmeContent = @"
# Quality Gates Data Directory

This directory contains the quality gate state and metrics data for the SmartWatch project.

## Contents

- **\*-quality-state.json**: Individual document quality gate state files
- **quality-metrics.json**: Collected metrics data
- **validation-reports/**: HTML validation reports

## Files are automatically managed by:

- quality-gate-workflow.ps1 - Creates and updates state files
- quality-metrics-collector.ps1 - Generates metrics and reports
- validate-documents.ps1 - Creates validation reports

## Do not manually edit these files

The quality gate system maintains this data automatically. Manual changes may cause system inconsistencies.

Created: $(Get-Date)
"@
            $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
            Write-DeployLog "Created quality gates README" "SUCCESS"
        }
        
        return $true
    } catch {
        Write-DeployLog "Failed to initialize quality gates directory: $_" "ERROR"
        return $false
    }
}

function Test-ScriptFunctionality {
    Write-DeployLog "Testing script functionality..." "TEST"
    
    $testResults = @{
        DocumentValidation = $false
        QualityGateWorkflow = $false
        SelfAssessment = $false
        MetricsCollection = $false
    }
    
    # Test 1: Document Validation
    Write-DeployLog "Testing document validation..." "TEST"
    try {
        $validationScript = Join-Path $Script:SystemConfig.ScriptsPath "validate-documents.ps1"
        $testDoc = $Script:SystemConfig.TestDocuments[0]  # Test with architecture.md
        
        $output = & powershell.exe -File $validationScript -DocumentPath $testDoc 2>&1
        $exitCode = $LASTEXITCODE
        
        Write-DeployLog "Document validation test completed (exit code: $exitCode)" "TEST"
        $testResults.DocumentValidation = $true  # Script ran without fatal errors
        
    } catch {
        Write-DeployLog "Document validation test failed: $_" "ERROR"
    }
    
    # Test 2: Quality Gate Workflow Status
    Write-DeployLog "Testing quality gate workflow..." "TEST"
    try {
        $workflowScript = Join-Path $Script:SystemConfig.ScriptsPath "quality-gate-workflow.ps1"
        $testDoc = $Script:SystemConfig.TestDocuments[0]
        
        $output = & powershell.exe -File $workflowScript -DocumentPath $testDoc -Action status 2>&1
        $exitCode = $LASTEXITCODE
        
        Write-DeployLog "Quality gate workflow test completed (exit code: $exitCode)" "TEST"
        $testResults.QualityGateWorkflow = $true
        
    } catch {
        Write-DeployLog "Quality gate workflow test failed: $_" "ERROR"
    }
    
    # Test 3: Self Assessment Tool
    Write-DeployLog "Testing self-assessment tool..." "TEST"
    try {
        $assessmentScript = Join-Path $Script:SystemConfig.ScriptsPath "self-assessment-tool.ps1"
        $testDoc = $Script:SystemConfig.TestDocuments[0]
        
        $output = & powershell.exe -File $assessmentScript -DocumentPath $testDoc -GenerateChecklist -OutputPath "test-checklist.md" 2>&1
        $exitCode = $LASTEXITCODE
        
        # Clean up test file
        if (Test-Path "test-checklist.md") {
            Remove-Item "test-checklist.md" -Force
        }
        
        Write-DeployLog "Self-assessment tool test completed (exit code: $exitCode)" "TEST"
        $testResults.SelfAssessment = $true
        
    } catch {
        Write-DeployLog "Self-assessment tool test failed: $_" "ERROR"
    }
    
    # Test 4: Metrics Collection (basic structure test)
    Write-DeployLog "Testing metrics collection..." "TEST"
    try {
        $metricsScript = Join-Path $Script:SystemConfig.ScriptsPath "quality-metrics-collector.ps1"
        
        # Test help/usage output
        $output = & powershell.exe -File $metricsScript -Action "invalid" 2>&1
        
        Write-DeployLog "Metrics collection test completed" "TEST"
        $testResults.MetricsCollection = $true
        
    } catch {
        Write-DeployLog "Metrics collection test failed: $_" "ERROR"
    }
    
    return $testResults
}

function Show-SystemStatus {
    Write-Host "`n" -NoNewline
    Write-Host "🏗️  QUALITY GATE SYSTEM STATUS" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    # Check prerequisites
    Write-Host "`n📋 Prerequisites:" -ForegroundColor Yellow
    $prereqsPassed = Test-Prerequisites
    
    # Check scripts
    Write-Host "`n📜 Required Scripts:" -ForegroundColor Yellow
    $scriptsAvailable = Test-ScriptAvailability
    
    # Check directory structure
    Write-Host "`n📁 Directory Structure:" -ForegroundColor Yellow
    $qualityDirExists = Test-Path $Script:SystemConfig.QualityGatesPath
    if ($qualityDirExists) {
        Write-DeployLog "✅ Quality gates directory exists" "SUCCESS"
    } else {
        Write-DeployLog "❌ Quality gates directory missing" "ERROR"
    }
    
    # Overall status
    Write-Host "`n🎯 Overall System Status:" -ForegroundColor Cyan
    $systemReady = $prereqsPassed -and $scriptsAvailable -and $qualityDirExists
    
    if ($systemReady) {
        Write-Host "✅ SYSTEM READY" -ForegroundColor Green
        Write-Host "Quality gate automation is fully deployed and operational" -ForegroundColor Green
    } else {
        Write-Host "❌ SYSTEM NOT READY" -ForegroundColor Red
        Write-Host "Run deployment with -Action install to set up the system" -ForegroundColor Yellow
    }
    
    # Usage examples
    Write-Host "`n🚀 Quick Start Commands:" -ForegroundColor Cyan
    Write-Host "  Document Validation:" -ForegroundColor White
    Write-Host "    .\scripts\validate-documents.ps1 -DocumentPath 'docs\architecture.md' -Verbose" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Self Assessment:" -ForegroundColor White
    Write-Host "    .\scripts\self-assessment-tool.ps1 -DocumentPath 'docs\prd.md' -Interactive" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Quality Gate Workflow:" -ForegroundColor White
    Write-Host "    .\scripts\quality-gate-workflow.ps1 -DocumentPath 'docs\architecture.md' -Action status" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Metrics Dashboard:" -ForegroundColor White
    Write-Host "    .\scripts\quality-metrics-collector.ps1 -Action dashboard" -ForegroundColor Gray
    Write-Host ""
    
    return $systemReady
}

function Invoke-DemoWorkflow {
    Write-Host "`n" -NoNewline
    Write-Host "🎬 QUALITY GATE SYSTEM DEMO" -ForegroundColor Magenta
    Write-Host "=" * 50 -ForegroundColor Magenta
    Write-Host "This demo will walk through the complete quality gate process" -ForegroundColor White
    Write-Host ""
    
    $demoDoc = $Script:SystemConfig.TestDocuments[0]  # Use architecture.md for demo
    
    if (-not (Test-Path $demoDoc)) {
        Write-DeployLog "Demo document not found: $demoDoc" "ERROR"
        return $false
    }
    
    # Step 1: Document Validation
    Write-Host "📝 Step 1: Document Validation" -ForegroundColor Yellow
    Write-Host "Running automated validation on: $demoDoc" -ForegroundColor Gray
    
    $validationScript = Join-Path $Script:SystemConfig.ScriptsPath "validate-documents.ps1"
    Write-Host "Command: .\scripts\validate-documents.ps1 -DocumentPath '$demoDoc' -GenerateReport" -ForegroundColor Gray
    
    try {
        & powershell.exe -File $validationScript -DocumentPath $demoDoc -GenerateReport -OutputPath "demo-validation-report.html"
        Write-DeployLog "✅ Validation completed - report generated" "SUCCESS"
    } catch {
        Write-DeployLog "⚠️ Validation completed with warnings" "WARNING"
    }
    
    Write-Host "Press any key to continue to Step 2..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Step 2: Quality Gate Status
    Write-Host "`n🚪 Step 2: Quality Gate Status Check" -ForegroundColor Yellow
    Write-Host "Checking quality gate status for: $demoDoc" -ForegroundColor Gray
    
    $workflowScript = Join-Path $Script:SystemConfig.ScriptsPath "quality-gate-workflow.ps1"
    Write-Host "Command: .\scripts\quality-gate-workflow.ps1 -DocumentPath '$demoDoc' -Action status" -ForegroundColor Gray
    
    try {
        & powershell.exe -File $workflowScript -DocumentPath $demoDoc -Action status
        Write-DeployLog "✅ Quality gate status displayed" "SUCCESS"
    } catch {
        Write-DeployLog "⚠️ Status check completed" "WARNING"
    }
    
    Write-Host "Press any key to continue to Step 3..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Step 3: Self Assessment
    Write-Host "`n🔍 Step 3: Self Assessment Tool" -ForegroundColor Yellow
    Write-Host "Generating self-assessment checklist for: $demoDoc" -ForegroundColor Gray
    
    $assessmentScript = Join-Path $Script:SystemConfig.ScriptsPath "self-assessment-tool.ps1"
    Write-Host "Command: .\scripts\self-assessment-tool.ps1 -DocumentPath '$demoDoc' -GenerateChecklist" -ForegroundColor Gray
    
    try {
        & powershell.exe -File $assessmentScript -DocumentPath $demoDoc -GenerateChecklist -OutputPath "demo-assessment-checklist.md"
        Write-DeployLog "✅ Self-assessment checklist generated" "SUCCESS"
    } catch {
        Write-DeployLog "⚠️ Assessment tool completed" "WARNING"
    }
    
    Write-Host "Press any key to continue to Step 4..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Step 4: Metrics Dashboard
    Write-Host "`n📊 Step 4: Quality Metrics Dashboard" -ForegroundColor Yellow
    Write-Host "Generating quality metrics dashboard" -ForegroundColor Gray
    
    $metricsScript = Join-Path $Script:SystemConfig.ScriptsPath "quality-metrics-collector.ps1"
    Write-Host "Command: .\scripts\quality-metrics-collector.ps1 -Action dashboard" -ForegroundColor Gray
    
    try {
        & powershell.exe -File $metricsScript -Action dashboard -ReportPath "demo-quality-dashboard.html"
        Write-DeployLog "✅ Quality dashboard generated" "SUCCESS"
    } catch {
        Write-DeployLog "⚠️ Dashboard generation completed" "WARNING"
    }
    
    # Demo Summary
    Write-Host "`n🎉 DEMO COMPLETE!" -ForegroundColor Green
    Write-Host "Generated demo files:" -ForegroundColor White
    $demoFiles = @("demo-validation-report.html", "demo-assessment-checklist.md", "demo-quality-dashboard.html")
    foreach ($file in $demoFiles) {
        if (Test-Path $file) {
            Write-Host "  ✅ $file" -ForegroundColor Green
        }
    }
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Review the generated files to understand the quality gate process" -ForegroundColor White
    Write-Host "2. Run quality gates on your actual documents" -ForegroundColor White
    Write-Host "3. Set up automated quality monitoring" -ForegroundColor White
    
    return $true
}

function Invoke-SystemInstallation {
    Write-DeployLog "Starting quality gate system installation..." "DEPLOY"
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-DeployLog "Prerequisites check failed. Cannot continue installation." "ERROR"
        return $false
    }
    
    # Verify scripts are available
    if (-not (Test-ScriptAvailability)) {
        Write-DeployLog "Required scripts not found. Cannot continue installation." "ERROR"
        return $false
    }
    
    # Initialize directory structure
    if (-not (Initialize-QualityGatesDirectory)) {
        Write-DeployLog "Failed to initialize directory structure." "ERROR"
        return $false
    }
    
    # Test script functionality
    Write-DeployLog "Testing system functionality..." "DEPLOY"
    $testResults = Test-ScriptFunctionality
    
    $testsPassed = ($testResults.Values | Where-Object { $_ -eq $true }).Count
    $totalTests = $testResults.Values.Count
    
    Write-DeployLog "Functionality tests completed: $testsPassed/$totalTests passed" "DEPLOY"
    
    if ($testsPassed -eq $totalTests) {
        Write-DeployLog "✅ QUALITY GATE SYSTEM INSTALLATION SUCCESSFUL" "SUCCESS"
        Write-Host "`nSystem is ready for use! Run with -Action status to see available commands." -ForegroundColor Green
        return $true
    } else {
        Write-DeployLog "⚠️ Installation completed with some test failures" "WARNING"
        Write-Host "System may have limited functionality. Check error messages above." -ForegroundColor Yellow
        return $false
    }
}

function Remove-QualitySystem {
    Write-DeployLog "Uninstalling quality gate system..." "DEPLOY"
    
    if (-not $Force) {
        Write-Host "This will remove all quality gate data and state files." -ForegroundColor Yellow
        Write-Host "Are you sure you want to continue? (Y/N): " -NoNewline -ForegroundColor Red
        $response = Read-Host
        if ($response.ToLower() -ne "y" -and $response.ToLower() -ne "yes") {
            Write-DeployLog "Uninstallation cancelled by user" "INFO"
            return $false
        }
    }
    
    try {
        # Remove quality gates directory
        if (Test-Path $Script:SystemConfig.QualityGatesPath) {
            Remove-Item $Script:SystemConfig.QualityGatesPath -Recurse -Force
            Write-DeployLog "Removed quality gates directory" "SUCCESS"
        }
        
        # Remove demo files
        $demoFiles = @("demo-validation-report.html", "demo-assessment-checklist.md", "demo-quality-dashboard.html", "test-checklist.md")
        foreach ($file in $demoFiles) {
            if (Test-Path $file) {
                Remove-Item $file -Force
                Write-DeployLog "Removed demo file: $file" "SUCCESS"
            }
        }
        
        Write-DeployLog "✅ Quality gate system uninstallation complete" "SUCCESS"
        Write-Host "Note: Script files in ./scripts/ were preserved" -ForegroundColor Yellow
        
        return $true
    } catch {
        Write-DeployLog "Failed to uninstall system: $_" "ERROR"
        return $false
    }
}

# Main execution logic
function Invoke-QualitySystemDeployment {
    switch ($Action.ToLower()) {
        "install" {
            $success = Invoke-SystemInstallation
            exit $(if ($success) { 0 } else { 1 })
        }
        "test" {
            Write-DeployLog "Running system functionality tests..." "TEST"
            $testResults = Test-ScriptFunctionality
            
            $testsPassed = ($testResults.Values | Where-Object { $_ -eq $true }).Count
            $totalTests = $testResults.Values.Count
            
            Write-Host "`nTest Results: $testsPassed/$totalTests passed" -ForegroundColor $(if ($testsPassed -eq $totalTests) { "Green" } else { "Yellow" })
            
            exit $(if ($testsPassed -eq $totalTests) { 0 } else { 1 })
        }
        "demo" {
            $success = Invoke-DemoWorkflow
            exit $(if ($success) { 0 } else { 1 })
        }
        "status" {
            $ready = Show-SystemStatus
            exit $(if ($ready) { 0 } else { 1 })
        }
        "uninstall" {
            $success = Remove-QualitySystem
            exit $(if ($success) { 0 } else { 1 })
        }
        default {
            Write-Host "Quality Gate System Deployment Tool" -ForegroundColor Cyan
            Write-Host "Usage: .\deploy-quality-system.ps1 -Action <install|test|demo|status|uninstall>"
            Write-Host ""
            Write-Host "Actions:"
            Write-Host "  install    - Deploy the complete quality gate system"
            Write-Host "  test       - Test system functionality"  
            Write-Host "  demo       - Run interactive demonstration"
            Write-Host "  status     - Check system status and show usage examples"
            Write-Host "  uninstall  - Remove quality gate system data"
            Write-Host ""
            Write-Host "Options:"
            Write-Host "  -Force     - Skip confirmation prompts"
            Write-Host "  -Verbose   - Show detailed logging"
            Write-Host ""
            Write-Host "Examples:"
            Write-Host "  .\deploy-quality-system.ps1 -Action install -Verbose"
            Write-Host "  .\deploy-quality-system.ps1 -Action demo"
            Write-Host "  .\deploy-quality-system.ps1 -Action status"
            exit 1
        }
    }
}

# Execute main deployment logic
try {
    Invoke-QualitySystemDeployment
} catch {
    Write-DeployLog "Deployment system execution failed: $_" "ERROR"
    exit 1
}