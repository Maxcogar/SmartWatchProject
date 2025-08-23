# Document Self-Assessment Tool
# SmartWatch Project - Author Quality Pre-Check
# Created: 2025-08-19

param(
    [Parameter(Mandatory=$true)]
    [string]$DocumentPath,
    [string]$DocumentType = "",  # auto-detect if not specified
    [switch]$Interactive = $false,
    [switch]$GenerateChecklist = $false,
    [string]$OutputPath = "self-assessment-checklist.md",
    [switch]$Verbose = $false
)

# Self-assessment checklists for each document type
$Script:AssessmentChecklists = @{
    architecture = @{
        Name = "Architecture Document Self-Assessment"
        Sections = @{
            "Component Specifications" = @(
                "All HAL interfaces defined with complete method signatures",
                "All Service classes have dependency injection specifications", 
                "All Application Logic components have state management details",
                "All UI components have prop interfaces and event handling"
            )
            "API Contracts" = @(
                "BLE GATT service UUIDs defined",
                "All characteristics have Properties, Max Size, Data Format",
                "JSON schemas complete with all required fields",
                "Data validation rules specified"
            )
            "Security Implementation" = @(
                "Encryption algorithms specified (AES-128, AES-256, etc.)",
                "Key management strategy documented",
                "Authentication methods defined",
                "Secure storage approach specified"
            )
            "Build Procedures" = @(
                "Step-by-step build commands provided",
                "Prerequisites and dependencies listed",
                "Environment setup instructions complete",
                "Production build process documented"
            )
            "Testing Strategy" = @(
                "Unit test framework specified",
                "Coverage targets defined (90%+)",
                "Integration test scenarios described",
                "Test automation approach documented"
            )
            "Performance & Monitoring" = @(
                "Performance targets specified (battery life, response time)",
                "Memory usage constraints defined",
                "Logging framework and levels specified",
                "Health monitoring metrics identified"
            )
        }
    }
    prd = @{
        Name = "PRD Document Self-Assessment"
        Sections = @{
            "ADHD-Friendly Design" = @(
                "All 5 ADHD design principles defined with examples",
                "Specific accessibility features described",
                "Cognitive load considerations documented",
                "User interface simplicity guidelines provided"
            )
            "User Research" = @(
                "3 user personas covering ADHD-I, ADHD-H, ADHD-C presentations",
                "User pain points clearly mapped to features",
                "User journey maps complete for key scenarios", 
                "User research data or assumptions documented"
            )
            "Success Metrics" = @(
                "Quantifiable KPIs defined with specific targets",
                "Measurement methods specified",
                "Success criteria aligned with business objectives",
                "User engagement metrics defined"
            )
            "Requirements & Scope" = @(
                "All acceptance criteria are testable with specific parameters",
                "Technical constraints clearly documented",
                "Non-functional requirements specified",
                "Scope boundaries clearly defined"
            )
            "Planning & Estimation" = @(
                "Story points assigned with confidence levels",
                "Dependencies mapped between stories/epics",
                "Risk factors identified with mitigation strategies",
                "Priority rationale provided for all features"
            )
        }
    }
}

function Write-AssessmentLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $colorMap = @{
        "ERROR" = "Red"
        "WARNING" = "Yellow" 
        "SUCCESS" = "Green"
        "INFO" = "Cyan"
        "QUESTION" = "Magenta"
    }
    if ($Verbose -or $Level -eq "ERROR" -or $Level -eq "QUESTION") {
        Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
        Write-Host "$Message" -ForegroundColor $colorMap[$Level]
    }
}

function Get-YesNoInput {
    param([string]$Question)
    
    do {
        Write-Host "$Question " -NoNewline -ForegroundColor Yellow
        Write-Host "(Y/N): " -NoNewline -ForegroundColor Gray
        $response = Read-Host
        $response = $response.Trim().ToLower()
    } while ($response -ne "y" -and $response -ne "n" -and $response -ne "yes" -and $response -ne "no")
    
    return ($response -eq "y" -or $response -eq "yes")
}

function Get-TextInput {
    param([string]$Question, [bool]$Required = $false)
    
    do {
        Write-Host "$Question" -ForegroundColor Yellow
        if ($Required) {
            Write-Host "(Required): " -NoNewline -ForegroundColor Red
        } else {
            Write-Host "(Optional, press Enter to skip): " -NoNewline -ForegroundColor Gray
        }
        $response = Read-Host
        $response = $response.Trim()
    } while ($Required -and [string]::IsNullOrWhiteSpace($response))
    
    return $response
}

function Invoke-InteractiveAssessment {
    param([hashtable]$Checklist, [string]$DocumentPath)
    
    Write-Host "`n🔍 INTERACTIVE SELF-ASSESSMENT" -ForegroundColor Cyan
    Write-Host "Document: $DocumentPath" -ForegroundColor Gray
    Write-Host "Assessment: $($Checklist.Name)" -ForegroundColor Gray
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    $results = @{
        DocumentPath = $DocumentPath
        AssessmentName = $Checklist.Name
        Timestamp = Get-Date
        SectionResults = @{}
        OverallPass = $true
        TotalChecks = 0
        PassedChecks = 0
        Issues = @()
        Notes = @()
    }
    
    foreach ($sectionName in $Checklist.Sections.Keys) {
        Write-Host "`n📋 Section: $sectionName" -ForegroundColor Yellow
        Write-Host "-" * 40 -ForegroundColor Yellow
        
        $sectionChecks = $Checklist.Sections[$sectionName]
        $sectionPassed = 0
        $sectionIssues = @()
        
        foreach ($check in $sectionChecks) {
            $results.TotalChecks++
            
            $passed = Get-YesNoInput "✓ $check"
            
            if ($passed) {
                $results.PassedChecks++
                $sectionPassed++
                Write-AssessmentLog "  ✅ PASS" "SUCCESS"
            } else {
                $reason = Get-TextInput "  ❌ Why is this missing or incomplete?"
                $sectionIssues += @{
                    Check = $check
                    Reason = $reason
                }
                $results.Issues += "[$sectionName] $check - $reason"
                Write-AssessmentLog "  ❌ FAIL: $reason" "ERROR"
            }
        }
        
        $sectionPassRate = ($sectionPassed / $sectionChecks.Count) * 100
        $results.SectionResults[$sectionName] = @{
            TotalChecks = $sectionChecks.Count
            PassedChecks = $sectionPassed
            PassRate = $sectionPassRate
            Issues = $sectionIssues
        }
        
        Write-Host "`nSection Result: " -NoNewline
        if ($sectionPassRate -ge 80) {
            Write-Host "PASS ($sectionPassRate%)" -ForegroundColor Green
        } elseif ($sectionPassRate -ge 60) {
            Write-Host "MARGINAL ($sectionPassRate%)" -ForegroundColor Yellow
        } else {
            Write-Host "FAIL ($sectionPassRate%)" -ForegroundColor Red
            $results.OverallPass = $false
        }
    }
    
    # Overall assessment notes
    Write-Host "`n💭 Final Assessment Notes" -ForegroundColor Cyan
    $overallNotes = Get-TextInput "Any additional notes about the document quality or readiness?"
    if ($overallNotes) {
        $results.Notes += $overallNotes
    }
    
    return $results
}

function Invoke-QuickAssessment {
    param([hashtable]$Checklist, [string]$DocumentPath)
    
    Write-Host "`n📊 QUICK ASSESSMENT MODE" -ForegroundColor Cyan
    Write-Host "Document: $DocumentPath" -ForegroundColor Gray
    Write-Host "Assessment: $($Checklist.Name)" -ForegroundColor Gray
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    $content = Get-Content $DocumentPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        Write-AssessmentLog "Cannot read document for quick assessment" "ERROR"
        return $null
    }
    
    $results = @{
        DocumentPath = $DocumentPath
        AssessmentName = $Checklist.Name
        Timestamp = Get-Date
        SectionResults = @{}
        OverallPass = $true
        TotalChecks = 0
        PassedChecks = 0
        Issues = @()
        AutomaticAnalysis = $true
    }
    
    foreach ($sectionName in $Checklist.Sections.Keys) {
        Write-Host "`n📋 Analyzing: $sectionName" -ForegroundColor Yellow
        
        $sectionChecks = $Checklist.Sections[$sectionName]
        $sectionPassed = 0
        $sectionIssues = @()
        
        foreach ($check in $sectionChecks) {
            $results.TotalChecks++
            
            # Simple heuristic analysis based on keywords
            $passed = Test-ChecklistItemInContent $check $content
            
            if ($passed) {
                $results.PassedChecks++
                $sectionPassed++
                Write-Host "  ✅ $check" -ForegroundColor Green
            } else {
                $sectionIssues += @{
                    Check = $check
                    Reason = "Content analysis suggests this may be missing or incomplete"
                }
                $results.Issues += "[$sectionName] $check"
                Write-Host "  ❌ $check" -ForegroundColor Red
            }
        }
        
        $sectionPassRate = ($sectionPassed / $sectionChecks.Count) * 100
        $results.SectionResults[$sectionName] = @{
            TotalChecks = $sectionChecks.Count
            PassedChecks = $sectionPassed
            PassRate = $sectionPassRate
            Issues = $sectionIssues
        }
        
        if ($sectionPassRate -lt 60) {
            $results.OverallPass = $false
        }
    }
    
    return $results
}

function Test-ChecklistItemInContent {
    param([string]$CheckItem, [string]$Content)
    
    # Simple keyword-based heuristics for content analysis
    $keywords = @{
        "HAL interfaces" = @("class.*HAL", "HAL.*{", "esp_err_t.*init")
        "Service classes" = @("class.*Service", "Service.*{", "dependency.*inject")
        "UUIDs defined" = @("UUID.*:", "12345678-", "[0-9a-f]{8}-[0-9a-f]{4}")
        "JSON schemas" = @("\{", "json", "string.*:", "integer.*:", "boolean.*:")
        "encryption" = @("AES-", "encryption", "encrypt", "cipher", "key.*management")
        "build commands" = @("idf\.py", "build", "cmake", "make", "gcc")
        "test framework" = @("TEST_CASE", "unity", "test.*framework", "coverage")
        "performance targets" = @("battery.*hour", "MHz", "memory", "performance", "target")
        "ADHD.*principles" = @("ADHD", "attention", "focus", "distraction", "cognitive")
        "user personas" = @("persona", "ADHD-I", "ADHD-H", "ADHD-C", "user.*story")
        "KPIs" = @("KPI", "metric", "success.*criteria", "measurable", "%")
        "acceptance criteria" = @("acceptance.*criteria", "given.*when.*then", "testable")
        "story points" = @("story.*point", "estimate", "effort", "velocity")
    }
    
    # Find matching keyword patterns
    foreach ($pattern in $keywords.Keys) {
        if ($CheckItem -match $pattern) {
            $patternKeywords = $keywords[$pattern]
            foreach ($keyword in $patternKeywords) {
                if ($Content -match $keyword) {
                    return $true
                }
            }
            break
        }
    }
    
    # Fallback: look for any significant keyword from the check item
    $checkWords = $CheckItem -split '\s+' | Where-Object { $_.Length -gt 3 }
    foreach ($word in $checkWords) {
        if ($Content -match [regex]::Escape($word)) {
            return $true
        }
    }
    
    return $false
}

function Generate-AssessmentReport {
    param([hashtable]$Results)
    
    $overallPassRate = if ($Results.TotalChecks -gt 0) { 
        [math]::Round(($Results.PassedChecks / $Results.TotalChecks) * 100, 1) 
    } else { 0 }
    
    Write-Host "`n" -NoNewline
    Write-Host "📊 SELF-ASSESSMENT SUMMARY" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "Document: $($Results.DocumentPath)" -ForegroundColor White
    Write-Host "Assessment: $($Results.AssessmentName)" -ForegroundColor White
    Write-Host "Completed: $($Results.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    
    if ($Results.AutomaticAnalysis) {
        Write-Host "Mode: Automatic Content Analysis" -ForegroundColor Yellow
        Write-Host "Note: This is a preliminary analysis. Manual review is recommended." -ForegroundColor Yellow
    } else {
        Write-Host "Mode: Interactive Self-Assessment" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Overall Pass Rate: " -NoNewline
    $passColor = if ($overallPassRate -ge 80) { "Green" } elseif ($overallPassRate -ge 60) { "Yellow" } else { "Red" }
    Write-Host "${overallPassRate}%" -ForegroundColor $passColor
    Write-Host "Total Checks: $($Results.TotalChecks)" -ForegroundColor White
    Write-Host "Passed: $($Results.PassedChecks)" -ForegroundColor Green
    Write-Host "Failed: $($Results.TotalChecks - $Results.PassedChecks)" -ForegroundColor Red
    Write-Host ""
    
    # Section breakdown
    Write-Host "📋 SECTION BREAKDOWN:" -ForegroundColor Cyan
    foreach ($sectionName in $Results.SectionResults.Keys) {
        $section = $Results.SectionResults[$sectionName]
        $sectionColor = if ($section.PassRate -ge 80) { "Green" } elseif ($section.PassRate -ge 60) { "Yellow" } else { "Red" }
        
        Write-Host "  $sectionName`: " -NoNewline -ForegroundColor White
        Write-Host "$([math]::Round($section.PassRate, 1))% " -NoNewline -ForegroundColor $sectionColor
        Write-Host "($($section.PassedChecks)/$($section.TotalChecks))" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Issues that need attention
    if ($Results.Issues.Count -gt 0) {
        Write-Host "⚠️  ITEMS NEEDING ATTENTION:" -ForegroundColor Yellow
        foreach ($issue in $Results.Issues) {
            Write-Host "  • $issue" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    # Notes
    if ($Results.Notes.Count -gt 0) {
        Write-Host "💭 NOTES:" -ForegroundColor Cyan
        foreach ($note in $Results.Notes) {
            Write-Host "  • $note" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # Recommendations
    Write-Host "🎯 RECOMMENDATIONS:" -ForegroundColor Cyan
    if ($Results.OverallPass) {
        if ($overallPassRate -ge 90) {
            Write-Host "  ✅ Document appears ready for Gate 1 submission!" -ForegroundColor Green
            Write-Host "  • Run formal validation: .\validate-documents.ps1 -DocumentPath '$($Results.DocumentPath)'" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Document mostly ready, but consider addressing failed items" -ForegroundColor Yellow
            Write-Host "  • Address the $($Results.Issues.Count) identified issues" -ForegroundColor Yellow
            Write-Host "  • Run formal validation when improvements complete" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ❌ Document needs significant work before Gate 1 submission" -ForegroundColor Red
        Write-Host "  • Address all failed sections (especially <60% pass rate)" -ForegroundColor Red
        Write-Host "  • Consider running self-assessment again after revisions" -ForegroundColor Red
    }
    
    Write-Host ""
}

function Generate-ChecklistDocument {
    param([hashtable]$Checklist, [string]$OutputPath)
    
    $markdown = @"
# $($Checklist.Name)
**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Instructions
Use this checklist to validate your document before submitting it for Quality Gate 1 review.

**How to use:**
1. Review each section and check off items as you verify them
2. For any unchecked items, address them in your document
3. Aim for 80%+ completion before formal submission
4. Use the interactive assessment tool for guided review

---

"@
    
    foreach ($sectionName in $Checklist.Sections.Keys) {
        $markdown += @"
## $sectionName

"@
        foreach ($check in $Checklist.Sections[$sectionName]) {
            $markdown += "- [ ] $check`n"
        }
        $markdown += "`n"
    }
    
    $markdown += @"
---

## Quality Gate Readiness Assessment

**Overall Readiness:** [ ] Ready for Gate 1 Submission

**Items Still Needed:**
- 
- 
- 

**Additional Notes:**
- 
- 
- 

**Next Steps:**
1. [ ] Complete all checklist items
2. [ ] Run automated validation: ``.\validate-documents.ps1 -DocumentPath <path>``
3. [ ] Submit for Gate 1: ``.\quality-gate-workflow.ps1 -DocumentPath <path> -Action start -Gate 1``
"@

    try {
        $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-AssessmentLog "Checklist generated: $OutputPath" "SUCCESS"
        return $true
    } catch {
        Write-AssessmentLog "Failed to generate checklist: $_" "ERROR"
        return $false
    }
}

function Invoke-DocumentSelfAssessment {
    param([string]$DocumentPath, [string]$DocumentType)
    
    # Validate document exists
    if (-not (Test-Path $DocumentPath)) {
        Write-AssessmentLog "Document not found: $DocumentPath" "ERROR"
        return $false
    }
    
    # Auto-detect document type if not specified
    if (-not $DocumentType) {
        if ($DocumentPath -like "*architecture*") {
            $DocumentType = "architecture"
        } elseif ($DocumentPath -like "*prd*") {
            $DocumentType = "prd"
        } else {
            Write-AssessmentLog "Cannot auto-detect document type. Please specify -DocumentType parameter." "ERROR"
            return $false
        }
        Write-AssessmentLog "Auto-detected document type: $DocumentType" "INFO"
    }
    
    # Get appropriate checklist
    $checklist = $Script:AssessmentChecklists[$DocumentType.ToLower()]
    if (-not $checklist) {
        Write-AssessmentLog "No assessment checklist available for document type: $DocumentType" "ERROR"
        return $false
    }
    
    # Generate static checklist if requested
    if ($GenerateChecklist) {
        $checklistSuccess = Generate-ChecklistDocument $checklist $OutputPath
        if (-not $checklistSuccess) {
            return $false
        }
        
        if (-not $Interactive) {
            Write-Host "Checklist generated successfully: $OutputPath" -ForegroundColor Green
            Write-Host "Use -Interactive flag for guided assessment, or review the checklist manually." -ForegroundColor Yellow
            return $true
        }
    }
    
    # Run assessment
    if ($Interactive) {
        $results = Invoke-InteractiveAssessment $checklist $DocumentPath
    } else {
        $results = Invoke-QuickAssessment $checklist $DocumentPath
    }
    
    if ($results) {
        Generate-AssessmentReport $results
        return $results.OverallPass
    }
    
    return $false
}

# Main execution
try {
    $success = Invoke-DocumentSelfAssessment $DocumentPath $DocumentType
    
    if ($success) {
        exit 0
    } else {
        exit 1
    }
} catch {
    Write-AssessmentLog "Self-assessment failed: $_" "ERROR"
    exit 1
}