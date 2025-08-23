# Quick Test Script for Quality Gate System
# SmartWatch Project - Verify System Functionality
# Created: 2025-08-19

Write-Host "🧪 QUALITY GATE SYSTEM QUICK TEST" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan

$testResults = @{
    ScriptsExist = $true
    DocumentsExist = $true
    BasicValidation = $false
}

# Test 1: Check if scripts exist
Write-Host "`n📜 Testing Script Availability..." -ForegroundColor Yellow

$requiredScripts = @(
    "validate-documents.ps1",
    "quality-gate-workflow.ps1", 
    "self-assessment-tool.ps1",
    "quality-metrics-collector.ps1",
    "deploy-quality-system.ps1"
)

foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path "scripts" $script
    if (Test-Path $scriptPath) {
        Write-Host "  ✅ $script" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $script" -ForegroundColor Red
        $testResults.ScriptsExist = $false
    }
}

# Test 2: Check if test documents exist
Write-Host "`n📄 Testing Document Availability..." -ForegroundColor Yellow

$testDocs = @("docs\architecture.md", "docs\prd.md")
foreach ($doc in $testDocs) {
    if (Test-Path $doc) {
        Write-Host "  ✅ $doc" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $doc" -ForegroundColor Red
        $testResults.DocumentsExist = $false
    }
}

# Test 3: Basic validation test (syntax check)
Write-Host "`n🔍 Testing Basic Script Syntax..." -ForegroundColor Yellow

try {
    # Test PowerShell syntax by parsing the main validation script
    $validationScript = Get-Content "scripts\validate-documents.ps1" -Raw
    [System.Management.Automation.PSParser]::Tokenize($validationScript, [ref]$null) | Out-Null
    Write-Host "  ✅ PowerShell syntax validation passed" -ForegroundColor Green
    $testResults.BasicValidation = $true
} catch {
    Write-Host "  ❌ PowerShell syntax issues detected" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
}

# Summary
Write-Host "`n📊 TEST RESULTS SUMMARY:" -ForegroundColor Cyan
$allTestsPassed = $testResults.ScriptsExist -and $testResults.DocumentsExist -and $testResults.BasicValidation

if ($allTestsPassed) {
    Write-Host "🎉 ALL TESTS PASSED - System is ready for use!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some tests failed - System may have limited functionality" -ForegroundColor Yellow
}

Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run document validation: .\scripts\validate-documents.ps1 -DocumentPath 'docs\architecture.md'" -ForegroundColor White
Write-Host "2. Start quality gate process: .\scripts\quality-gate-workflow.ps1 -DocumentPath 'docs\architecture.md' -Action status" -ForegroundColor White
Write-Host "3. Generate quality dashboard: .\scripts\quality-metrics-collector.ps1 -Action dashboard" -ForegroundColor White
Write-Host "4. See full documentation: README-QUALITY-AUTOMATION.md" -ForegroundColor White

exit $(if ($allTestsPassed) { 0 } else { 1 })