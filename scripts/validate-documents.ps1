# Document Quality Gate Validation Suite
# SmartWatch Project - Automated Quality Enforcement
# Created: 2025-08-19

param(
    [string]$DocumentPath = "",
    [string]$DocumentType = "",
    [switch]$Verbose = $false,
    [switch]$GenerateReport = $false,
    [string]$OutputPath = "validation-report.html"
)

# Initialize validation results
$Script:ValidationResults = @{
    DocumentPath = $DocumentPath
    DocumentType = $DocumentType
    Timestamp = Get-Date
    TotalChecks = 0
    PassedChecks = 0
    FailedChecks = 0
    WarningCount = 0
    CriticalIssues = @()
    Warnings = @()
    PassedItems = @()
    OverallStatus = ""
}

function Write-ValidationLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "ERROR" = "Red"
        "WARNING" = "Yellow" 
        "SUCCESS" = "Green"
        "INFO" = "White"
    }
    if ($Verbose -or $Level -eq "ERROR") {
        Write-Host "[$timestamp] $Level`: $Message" -ForegroundColor $colorMap[$Level]
    }
}

function Test-FileExists {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) {
        Write-ValidationLog "Document not found: $FilePath" "ERROR"
        $Script:ValidationResults.CriticalIssues += "Document file does not exist"
        return $false
    }
    return $true
}

function Get-DocumentContent {
    param([string]$FilePath)
    try {
        return Get-Content $FilePath -Raw -Encoding UTF8
    } catch {
        Write-ValidationLog "Failed to read document: $_" "ERROR"
        $Script:ValidationResults.CriticalIssues += "Cannot read document content"
        return $null
    }
}

function Test-ArchitectureDocumentCompleteness {
    param([string]$Content)
    
    Write-ValidationLog "Validating Architecture Document Completeness..." "INFO"
    
    $requiredSections = @{
        "Component Interfaces" = @(
            "class.*HAL.*{",
            "class.*Service.*{", 
            "class.*Manager.*{",
            "esp_err_t.*init\(",
            "public:",
            "private:"
        )
        "API Specifications" = @(
            "UUID.*:",
            "Properties.*:",
            "Max Size.*:",
            "Data Format:",
            "json"
        )
        "Security Implementation" = @(
            "BLE.*Security",
            "encryption",
            "AES-",
            "authentication",
            "pairing"
        )
        "Build Procedures" = @(
            "idf\.py",
            "build",
            "flash",
            "Prerequisites:",
            "bash"
        )
        "Testing Strategy" = @(
            "TEST_CASE",
            "coverage.*%",
            "Unit Testing",
            "Integration Testing",
            "Unity test framework"
        )
        "Performance Specifications" = @(
            "battery.*hour",
            "MHz",
            "memory",
            "performance",
            "Power Management"
        )
        "Error Handling" = @(
            "esp_err_t",
            "exception",
            "error handling",
            "ESP_LOG[EWI]"
        )
        "Logging Framework" = @(
            "ESP_LOG",
            "logging",
            "TAG",
            "log level"
        )
        "Data Models" = @(
            "struct.*_t.*{",
            "std::string",
            "uint.*_t",
            "bool"
        )
        "Deployment Pipeline" = @(
            "espsecure\.py",
            "signing.*key",
            "OTA",
            "production.*build"
        )
    }

    $sectionResults = @{}
    
    foreach ($section in $requiredSections.Keys) {
        $Script:ValidationResults.TotalChecks++
        $patterns = $requiredSections[$section]
        $matchCount = 0
        
        foreach ($pattern in $patterns) {
            if ($Content -match $pattern) {
                $matchCount++
            }
        }
        
        $completionPercentage = ($matchCount / $patterns.Count) * 100
        $sectionResults[$section] = @{
            "MatchCount" = $matchCount
            "TotalPatterns" = $patterns.Count
            "CompletionPercentage" = $completionPercentage
            "Status" = if ($completionPercentage -ge 70) { "PASS" } else { "FAIL" }
        }
        
        if ($completionPercentage -ge 70) {
            $Script:ValidationResults.PassedChecks++
            $Script:ValidationResults.PassedItems += "$section (${completionPercentage}%)"
            Write-ValidationLog "$section`: PASS (${completionPercentage}% coverage)" "SUCCESS"
        } else {
            $Script:ValidationResults.FailedChecks++
            $Script:ValidationResults.CriticalIssues += "$section incomplete (${completionPercentage}% coverage)"
            Write-ValidationLog "$section`: FAIL (${completionPercentage}% coverage)" "ERROR"
        }
    }
    
    return $sectionResults
}

function Test-PRDDocumentCompleteness {
    param([string]$Content)
    
    Write-ValidationLog "Validating PRD Document Completeness..." "INFO"
    
    $requiredSections = @{
        "ADHD Design Principles" = @(
            "ADHD.*Friendly",
            "design.*principle",
            "attention",
            "focus",
            "distraction"
        )
        "User Personas" = @(
            "persona",
            "ADHD-I",
            "ADHD-H", 
            "ADHD-C",
            "user.*story"
        )
        "Success Metrics" = @(
            "KPI",
            "metric",
            "success.*criteria",
            "measurable",
            "%|\d+.*hour|\d+.*minute"
        )
        "Technical Constraints" = @(
            "constraint",
            "limitation",
            "ESP32",
            "hardware",
            "battery"
        )
        "Acceptance Criteria" = @(
            "acceptance.*criteria",
            "testable",
            "given.*when.*then",
            "criteria",
            "requirement"
        )
        "Effort Estimates" = @(
            "story.*point",
            "estimate",
            "effort",
            "hours?|\d+.*day",
            "complexity"
        )
        "Dependency Mapping" = @(
            "depend",
            "prerequisite",
            "blocked.*by",
            "requires",
            "integration"
        )
        "Risk Assessment" = @(
            "risk",
            "mitigation",
            "contingency",
            "probability",
            "impact"
        )
        "Priority Matrix" = @(
            "priority",
            "high|medium|low",
            "critical",
            "must.*have",
            "nice.*to.*have"
        )
    }

    $sectionResults = @{}
    
    foreach ($section in $requiredSections.Keys) {
        $Script:ValidationResults.TotalChecks++
        $patterns = $requiredSections[$section]
        $matchCount = 0
        
        foreach ($pattern in $patterns) {
            if ($Content -match $pattern) {
                $matchCount++
            }
        }
        
        $completionPercentage = ($matchCount / $patterns.Count) * 100
        $sectionResults[$section] = @{
            "MatchCount" = $matchCount
            "TotalPatterns" = $patterns.Count
            "CompletionPercentage" = $completionPercentage
            "Status" = if ($completionPercentage -ge 60) { "PASS" } else { "FAIL" }
        }
        
        if ($completionPercentage -ge 60) {
            $Script:ValidationResults.PassedChecks++
            $Script:ValidationResults.PassedItems += "$section (${completionPercentage}%)"
            Write-ValidationLog "$section`: PASS (${completionPercentage}% coverage)" "SUCCESS"
        } else {
            $Script:ValidationResults.FailedChecks++
            $Script:ValidationResults.CriticalIssues += "$section incomplete (${completionPercentage}% coverage)"
            Write-ValidationLog "$section`: FAIL (${completionPercentage}% coverage)" "ERROR"
        }
    }
    
    return $sectionResults
}

function Test-GeneralDocumentQuality {
    param([string]$Content, [string]$FilePath)
    
    Write-ValidationLog "Validating General Document Quality..." "INFO"
    
    # Check for placeholder content
    $Script:ValidationResults.TotalChecks++
    $placeholders = @("TBD", "TODO", "FIXME", "\[placeholder\]", "XXX")
    $placeholderFound = $false
    foreach ($placeholder in $placeholders) {
        if ($Content -match $placeholder) {
            $placeholderFound = $true
            break
        }
    }
    
    if (-not $placeholderFound) {
        $Script:ValidationResults.PassedChecks++
        $Script:ValidationResults.PassedItems += "No placeholder content found"
        Write-ValidationLog "Placeholder content check: PASS" "SUCCESS"
    } else {
        $Script:ValidationResults.FailedChecks++
        $Script:ValidationResults.CriticalIssues += "Document contains placeholder content (TBD, TODO, etc.)"
        Write-ValidationLog "Placeholder content check: FAIL" "ERROR"
    }
    
    # Check document length (minimum content requirement)
    $Script:ValidationResults.TotalChecks++
    $contentLength = $Content.Length
    if ($contentLength -gt 5000) {
        $Script:ValidationResults.PassedChecks++
        $Script:ValidationResults.PassedItems += "Document length adequate ($contentLength chars)"
        Write-ValidationLog "Document length check: PASS ($contentLength characters)" "SUCCESS"
    } else {
        $Script:ValidationResults.FailedChecks++
        $Script:ValidationResults.CriticalIssues += "Document too short ($contentLength characters, minimum 5000 expected)"
        Write-ValidationLog "Document length check: FAIL ($contentLength characters)" "ERROR"
    }
    
    # Check for version control information
    $Script:ValidationResults.TotalChecks++
    if ($Content -match "Version|Date.*\d{4}-\d{2}-\d{2}|Author|Change.*Log") {
        $Script:ValidationResults.PassedChecks++
        $Script:ValidationResults.PassedItems += "Version control information present"
        Write-ValidationLog "Version control check: PASS" "SUCCESS"
    } else {
        $Script:ValidationResults.FailedChecks++
        $Script:ValidationResults.Warnings += "Missing version control information (Version, Date, Author, Change Log)"
        Write-ValidationLog "Version control check: WARNING" "WARNING"
    }
}

function Generate-ValidationReport {
    param([hashtable]$Results, [string]$OutputPath)
    
    $passRate = if ($Results.TotalChecks -gt 0) { 
        [math]::Round(($Results.PassedChecks / $Results.TotalChecks) * 100, 2) 
    } else { 0 }
    
    $Results.OverallStatus = if ($passRate -ge 80) { "PASS" } elseif ($passRate -ge 60) { "WARNING" } else { "FAIL" }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Document Quality Gate Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background-color: #f4f4f4; padding: 20px; border-radius: 5px; }
        .status-pass { color: #28a745; font-weight: bold; }
        .status-fail { color: #dc3545; font-weight: bold; }
        .status-warning { color: #ffc107; font-weight: bold; }
        .section { margin: 20px 0; }
        .critical-issues { background-color: #f8d7da; padding: 15px; border-radius: 5px; }
        .warnings { background-color: #fff3cd; padding: 15px; border-radius: 5px; }
        .passed-items { background-color: #d4edda; padding: 15px; border-radius: 5px; }
        ul { margin: 10px 0; }
        li { margin: 5px 0; }
        .metrics { display: flex; justify-content: space-between; margin: 20px 0; }
        .metric-box { text-align: center; padding: 15px; background-color: #e9ecef; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Document Quality Gate Validation Report</h1>
        <p><strong>Document:</strong> $($Results.DocumentPath)</p>
        <p><strong>Type:</strong> $($Results.DocumentType)</p>
        <p><strong>Generated:</strong> $($Results.Timestamp)</p>
        <p><strong>Overall Status:</strong> <span class="status-$($Results.OverallStatus.ToLower())">$($Results.OverallStatus)</span></p>
    </div>
    
    <div class="metrics">
        <div class="metric-box">
            <h3>$($Results.TotalChecks)</h3>
            <p>Total Checks</p>
        </div>
        <div class="metric-box">
            <h3>$($Results.PassedChecks)</h3>
            <p>Passed</p>
        </div>
        <div class="metric-box">
            <h3>$($Results.FailedChecks)</h3>
            <p>Failed</p>
        </div>
        <div class="metric-box">
            <h3>${passRate}%</h3>
            <p>Pass Rate</p>
        </div>
    </div>
    
    $(if ($Results.CriticalIssues.Count -gt 0) {
        "<div class='section critical-issues'>
            <h2>🚨 Critical Issues (Blocks Gate Approval)</h2>
            <ul>
                $(($Results.CriticalIssues | ForEach-Object { "<li>$_</li>" }) -join '')
            </ul>
        </div>"
    })
    
    $(if ($Results.Warnings.Count -gt 0) {
        "<div class='section warnings'>
            <h2>⚠️ Warnings</h2>
            <ul>
                $(($Results.Warnings | ForEach-Object { "<li>$_</li>" }) -join '')
            </ul>
        </div>"
    })
    
    $(if ($Results.PassedItems.Count -gt 0) {
        "<div class='section passed-items'>
            <h2>✅ Passed Validations</h2>
            <ul>
                $(($Results.PassedItems | ForEach-Object { "<li>$_</li>" }) -join '')
            </ul>
        </div>"
    })
    
    <div class="section">
        <h2>Quality Gate Assessment</h2>
        <p><strong>Gate 1 (Document Completeness):</strong> $(if ($Results.OverallStatus -eq "PASS") { '<span class="status-pass">APPROVED</span>' } else { '<span class="status-fail">REJECTED</span>' })</p>
        <p><strong>Next Steps:</strong> 
            $(if ($Results.OverallStatus -eq "PASS") { 
                "Document may proceed to Gate 2 (Technical Review)" 
            } else { 
                "Address critical issues and resubmit for validation" 
            })
        </p>
    </div>
</body>
</html>
"@

    try {
        $html | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-ValidationLog "Validation report generated: $OutputPath" "SUCCESS"
    } catch {
        Write-ValidationLog "Failed to generate report: $_" "ERROR"
    }
}

# Main validation logic
function Invoke-DocumentValidation {
    param([string]$DocumentPath, [string]$DocumentType)
    
    Write-ValidationLog "Starting document validation for: $DocumentPath" "INFO"
    
    # Validate file exists
    if (-not (Test-FileExists $DocumentPath)) {
        return $false
    }
    
    # Read document content
    $content = Get-DocumentContent $DocumentPath
    if (-not $content) {
        return $false
    }
    
    # Determine document type if not specified
    if (-not $DocumentType) {
        if ($DocumentPath -like "*architecture*") {
            $DocumentType = "architecture"
        } elseif ($DocumentPath -like "*prd*") {
            $DocumentType = "prd"
        } else {
            $DocumentType = "general"
        }
        Write-ValidationLog "Auto-detected document type: $DocumentType" "INFO"
    }
    
    # Run appropriate validation tests
    switch ($DocumentType.ToLower()) {
        "architecture" {
            $sectionResults = Test-ArchitectureDocumentCompleteness $content
        }
        "prd" {
            $sectionResults = Test-PRDDocumentCompleteness $content
        }
        default {
            Write-ValidationLog "Unknown document type: $DocumentType. Running general validation only." "WARNING"
        }
    }
    
    # Run general quality checks
    Test-GeneralDocumentQuality $content $DocumentPath
    
    # Generate report if requested
    if ($GenerateReport) {
        Generate-ValidationReport $Script:ValidationResults $OutputPath
    }
    
    # Output final results
    $passRate = if ($Script:ValidationResults.TotalChecks -gt 0) { 
        [math]::Round(($Script:ValidationResults.PassedChecks / $Script:ValidationResults.TotalChecks) * 100, 2) 
    } else { 0 }
    
    Write-Host "`n=== VALIDATION SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Document: $DocumentPath" -ForegroundColor White
    Write-Host "Type: $DocumentType" -ForegroundColor White
    Write-Host "Total Checks: $($Script:ValidationResults.TotalChecks)" -ForegroundColor White
    Write-Host "Passed: $($Script:ValidationResults.PassedChecks)" -ForegroundColor Green
    Write-Host "Failed: $($Script:ValidationResults.FailedChecks)" -ForegroundColor Red
    Write-Host "Pass Rate: ${passRate}%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 60) { "Yellow" } else { "Red" })
    
    $overallStatus = if ($passRate -ge 80) { "PASS" } elseif ($passRate -ge 60) { "WARNING" } else { "FAIL" }
    Write-Host "Overall Status: $overallStatus" -ForegroundColor $(if ($overallStatus -eq "PASS") { "Green" } elseif ($overallStatus -eq "WARNING") { "Yellow" } else { "Red" })
    
    if ($Script:ValidationResults.CriticalIssues.Count -gt 0) {
        Write-Host "`nCritical Issues:" -ForegroundColor Red
        foreach ($issue in $Script:ValidationResults.CriticalIssues) {
            Write-Host "  • $issue" -ForegroundColor Red
        }
    }
    
    return $overallStatus -eq "PASS"
}

# Script execution
if ($DocumentPath) {
    $success = Invoke-DocumentValidation $DocumentPath $DocumentType
    exit $(if ($success) { 0 } else { 1 })
} else {
    Write-Host "Usage: .\validate-documents.ps1 -DocumentPath <path> [-DocumentType <type>] [-Verbose] [-GenerateReport] [-OutputPath <report-path>]"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\validate-documents.ps1 -DocumentPath 'docs\architecture.md' -Verbose -GenerateReport"
    Write-Host "  .\validate-documents.ps1 -DocumentPath 'docs\prd.md' -DocumentType 'prd' -GenerateReport"
    exit 1
}