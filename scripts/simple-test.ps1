# Simple System Test
Write-Host "Quality Gate System Test" -ForegroundColor Cyan

$scripts = @("validate-documents.ps1", "quality-gate-workflow.ps1", "self-assessment-tool.ps1", "quality-metrics-collector.ps1")
$allPresent = $true

foreach ($script in $scripts) {
    if (Test-Path "scripts\$script") {
        Write-Host "✅ $script found" -ForegroundColor Green
    } else {
        Write-Host "❌ $script missing" -ForegroundColor Red
        $allPresent = $false
    }
}

if ($allPresent) {
    Write-Host "🎉 All scripts present - System ready!" -ForegroundColor Green
} else {
    Write-Host "⚠️ Some scripts missing" -ForegroundColor Yellow
}