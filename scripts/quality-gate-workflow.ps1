# Quality Gate Workflow Automation
# SmartWatch Project - 4-Gate Review Process Enforcement
# Created: 2025-08-19

param(
    [Parameter(Mandatory=$true)]
    [string]$DocumentPath,
    [string]$Action = "status",  # status, start, approve, reject, reset
    [string]$Gate = "",          # 1, 2, 3, 4 or auto-detect
    [string]$ReviewerName = $env:USERNAME,
    [string]$Comments = "",
    [switch]$Force = $false,
    [switch]$Verbose = $false
)

# Quality Gate Configuration
$Script:QualityGateConfig = @{
    Gates = @{
        1 = @{
            Name = "Document Completeness Validation"
            Description = "Automated + peer review for completeness"
            TimeLimit = 1
            RequiredReviewers = @("Author", "Peer-Reviewer")
            AutoValidation = $true
            Criteria = @(
                "All sections present per template",
                "No placeholder content (TBD, TODO)", 
                "Adequate detail level",
                "Version control information"
            )
        }
        2 = @{
            Name = "Technical Validation Review"
            Description = "Technical content accuracy and feasibility"
            TimeLimit = 3
            RequiredReviewers = @("Senior-Developer", "Architect", "QA-Lead", "Security-Specialist")
            AutoValidation = $false
            Criteria = @(
                "Technical specifications implementable",
                "Dependencies identified",
                "Performance requirements realistic", 
                "Security measures adequate"
            )
        }
        3 = @{
            Name = "Stakeholder Alignment Checkpoint"
            Description = "Business and user alignment validation"
            TimeLimit = 2
            RequiredReviewers = @("Product-Owner", "UX-Designer", "Project-Manager", "SME")
            AutoValidation = $false
            Criteria = @(
                "User personas accurate",
                "Success metrics aligned", 
                "Design principles supported",
                "Scope achievable"
            )
        }
        4 = @{
            Name = "Development Readiness Assessment"
            Description = "Final development team handoff approval"
            TimeLimit = 1
            RequiredReviewers = @("Technical-Lead", "Development-Team")
            AutoValidation = $false
            Criteria = @(
                "Acceptance criteria testable",
                "Implementation detail sufficient",
                "Dependencies mapped",
                "Quality standards defined"
            )
        }
    }
}

function Write-QualityLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "ERROR" = "Red"
        "WARNING" = "Yellow" 
        "SUCCESS" = "Green"
        "INFO" = "Cyan"
        "GATE" = "Magenta"
    }
    if ($Verbose -or $Level -eq "ERROR" -or $Level -eq "GATE") {
        Write-Host "[$timestamp] $Level`: $Message" -ForegroundColor $colorMap[$Level]
    }
}

function Get-DocumentStateFilePath {
    param([string]$DocumentPath)
    $docName = [System.IO.Path]::GetFileNameWithoutExtension($DocumentPath)
    $stateDir = Join-Path (Split-Path $DocumentPath -Parent) ".quality-gates"
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
    return Join-Path $stateDir "${docName}-quality-state.json"
}

function Initialize-DocumentQualityState {
    param([string]$DocumentPath)
    
    $docInfo = Get-Item $DocumentPath
    $initialState = @{
        DocumentPath = $DocumentPath
        DocumentName = $docInfo.Name
        Created = Get-Date
        LastModified = $docInfo.LastWriteTime
        CurrentGate = 0
        OverallStatus = "Not Started"
        Gates = @{
            1 = @{ Status = "Pending"; StartTime = $null; EndTime = $null; Reviewers = @(); Comments = @(); AutoValidationPassed = $false }
            2 = @{ Status = "Not Ready"; StartTime = $null; EndTime = $null; Reviewers = @(); Comments = @(); AutoValidationPassed = $false }
            3 = @{ Status = "Not Ready"; StartTime = $null; EndTime = $null; Reviewers = @(); Comments = @(); AutoValidationPassed = $false }
            4 = @{ Status = "Not Ready"; StartTime = $null; EndTime = $null; Reviewers = @(); Comments = @(); AutoValidationPassed = $false }
        }
        History = @()
    }
    
    return $initialState
}

function Load-DocumentQualityState {
    param([string]$DocumentPath)
    
    $stateFilePath = Get-DocumentStateFilePath $DocumentPath
    
    if (Test-Path $stateFilePath) {
        try {
            $state = Get-Content $stateFilePath -Raw | ConvertFrom-Json -AsHashtable
            Write-QualityLog "Loaded existing quality state for document" "INFO"
            return $state
        } catch {
            Write-QualityLog "Failed to load quality state, initializing new state: $_" "WARNING"
        }
    }
    
    Write-QualityLog "Initializing new quality gate state" "INFO"
    return Initialize-DocumentQualityState $DocumentPath
}

function Save-DocumentQualityState {
    param([hashtable]$State)
    
    $stateFilePath = Get-DocumentStateFilePath $State.DocumentPath
    
    try {
        # Add history entry
        $historyEntry = @{
            Timestamp = Get-Date
            Action = $Action
            Gate = $Gate
            Reviewer = $ReviewerName
            Comments = $Comments
        }
        $State.History += $historyEntry
        
        # Save state
        $State | ConvertTo-Json -Depth 10 | Out-File -FilePath $stateFilePath -Encoding UTF8
        Write-QualityLog "Quality state saved successfully" "SUCCESS"
        return $true
    } catch {
        Write-QualityLog "Failed to save quality state: $_" "ERROR"
        return $false
    }
}

function Invoke-AutoValidation {
    param([string]$DocumentPath, [int]$GateNumber)
    
    if ($GateNumber -eq 1) {
        Write-QualityLog "Running automated validation for Gate 1..." "INFO"
        
        # Run document validation script
        $validationScript = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "validate-documents.ps1"
        $validationResult = & powershell.exe -File $validationScript -DocumentPath $DocumentPath -Verbose:$Verbose
        
        return $LASTEXITCODE -eq 0
    }
    
    # Other gates don't have auto-validation
    return $null
}

function Test-GatePrerequisites {
    param([hashtable]$State, [int]$GateNumber)
    
    # Gate 1 can always start
    if ($GateNumber -eq 1) {
        return $true
    }
    
    # Other gates require previous gate completion
    $previousGate = $GateNumber - 1
    $previousStatus = $State.Gates[$previousGate].Status
    
    if ($previousStatus -ne "Approved") {
        Write-QualityLog "Gate $GateNumber cannot start: Gate $previousGate status is '$previousStatus' (must be 'Approved')" "ERROR"
        return $false
    }
    
    return $true
}

function Start-QualityGate {
    param([hashtable]$State, [int]$GateNumber)
    
    $gateInfo = $Script:QualityGateConfig.Gates[$GateNumber]
    
    # Check prerequisites
    if (-not (Test-GatePrerequisites $State $GateNumber)) {
        return $false
    }
    
    Write-QualityLog "Starting Gate $GateNumber`: $($gateInfo.Name)" "GATE"
    
    # Update gate status
    $State.Gates[$GateNumber].Status = "In Review"
    $State.Gates[$GateNumber].StartTime = Get-Date
    $State.CurrentGate = $GateNumber
    $State.OverallStatus = "Gate $GateNumber In Progress"
    
    # Run auto-validation if applicable
    if ($gateInfo.AutoValidation) {
        $autoResult = Invoke-AutoValidation $State.DocumentPath $GateNumber
        $State.Gates[$GateNumber].AutoValidationPassed = $autoResult
        
        if ($autoResult) {
            Write-QualityLog "Auto-validation PASSED for Gate $GateNumber" "SUCCESS"
        } else {
            Write-QualityLog "Auto-validation FAILED for Gate $GateNumber" "ERROR"
            $State.Gates[$GateNumber].Status = "Failed Auto-Validation"
            $State.OverallStatus = "Gate $GateNumber Failed"
            return $false
        }
    }
    
    Write-QualityLog "Gate $GateNumber started successfully. Required reviewers: $($gateInfo.RequiredReviewers -join ', ')" "SUCCESS"
    Write-QualityLog "Time limit: $($gateInfo.TimeLimit) business days" "INFO"
    
    return $true
}

function Approve-QualityGate {
    param([hashtable]$State, [int]$GateNumber, [string]$ReviewerName, [string]$Comments)
    
    $gateInfo = $Script:QualityGateConfig.Gates[$GateNumber]
    
    # Validate gate is in review
    if ($State.Gates[$GateNumber].Status -ne "In Review") {
        Write-QualityLog "Cannot approve Gate $GateNumber`: Status is '$($State.Gates[$GateNumber].Status)' (must be 'In Review')" "ERROR"
        return $false
    }
    
    # Add reviewer approval
    $approval = @{
        Reviewer = $ReviewerName
        Timestamp = Get-Date
        Comments = $Comments
        Action = "Approved"
    }
    $State.Gates[$GateNumber].Reviewers += $approval
    
    Write-QualityLog "Gate $GateNumber approved by $ReviewerName" "SUCCESS"
    
    # Check if all required reviewers have approved
    $approvedReviewers = ($State.Gates[$GateNumber].Reviewers | Where-Object { $_.Action -eq "Approved" }).Count
    $requiredCount = $gateInfo.RequiredReviewers.Count
    
    if ($Force -or $approvedReviewers -ge $requiredCount) {
        $State.Gates[$GateNumber].Status = "Approved"
        $State.Gates[$GateNumber].EndTime = Get-Date
        
        # Check if this was the final gate
        if ($GateNumber -eq 4) {
            $State.OverallStatus = "APPROVED FOR DEVELOPMENT"
            Write-QualityLog "🎉 ALL QUALITY GATES PASSED - Document approved for development!" "GATE"
        } else {
            $nextGate = $GateNumber + 1
            $State.Gates[$nextGate].Status = "Pending"
            Write-QualityLog "Gate $GateNumber APPROVED - Gate $nextGate is now available" "GATE"
        }
    } else {
        Write-QualityLog "Gate $GateNumber partially approved ($approvedReviewers/$requiredCount reviewers)" "INFO"
    }
    
    return $true
}

function Reject-QualityGate {
    param([hashtable]$State, [int]$GateNumber, [string]$ReviewerName, [string]$Comments)
    
    # Validate gate is in review
    if ($State.Gates[$GateNumber].Status -ne "In Review") {
        Write-QualityLog "Cannot reject Gate $GateNumber`: Status is '$($State.Gates[$GateNumber].Status)' (must be 'In Review')" "ERROR"
        return $false
    }
    
    # Add reviewer rejection
    $rejection = @{
        Reviewer = $ReviewerName
        Timestamp = Get-Date
        Comments = $Comments
        Action = "Rejected"
    }
    $State.Gates[$GateNumber].Reviewers += $rejection
    
    # Set gate status to rejected
    $State.Gates[$GateNumber].Status = "Rejected"
    $State.Gates[$GateNumber].EndTime = Get-Date
    $State.OverallStatus = "Gate $GateNumber Rejected"
    
    Write-QualityLog "Gate $GateNumber REJECTED by $ReviewerName`: $Comments" "ERROR"
    Write-QualityLog "Document must be revised and resubmitted for Gate $GateNumber" "WARNING"
    
    return $true
}

function Show-QualityGateStatus {
    param([hashtable]$State)
    
    Write-Host "`n" -NoNewline
    Write-Host "🏗️  QUALITY GATE STATUS DASHBOARD" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "Document: " -NoNewline; Write-Host $State.DocumentName -ForegroundColor Yellow
    Write-Host "Path: " -NoNewline; Write-Host $State.DocumentPath -ForegroundColor Gray
    Write-Host "Overall Status: " -NoNewline
    
    $statusColor = switch ($State.OverallStatus) {
        { $_ -match "APPROVED FOR DEVELOPMENT" } { "Green" }
        { $_ -match "Rejected" -or $_ -match "Failed" } { "Red" }
        { $_ -match "In Progress" } { "Yellow" }
        default { "White" }
    }
    Write-Host $State.OverallStatus -ForegroundColor $statusColor
    Write-Host "Current Gate: " -NoNewline; Write-Host $State.CurrentGate -ForegroundColor Magenta
    Write-Host ""
    
    # Show each gate status
    foreach ($gateNum in 1..4) {
        $gate = $State.Gates[$gateNum]
        $gateConfig = $Script:QualityGateConfig.Gates[$gateNum]
        
        $statusIcon = switch ($gate.Status) {
            "Approved" { "✅" }
            "In Review" { "🔄" }
            "Rejected" { "❌" }
            "Failed Auto-Validation" { "💥" }
            "Pending" { "⏳" }
            "Not Ready" { "⏸️" }
            default { "❓" }
        }
        
        Write-Host "Gate $gateNum $statusIcon " -NoNewline
        Write-Host $gateConfig.Name -ForegroundColor White -NoNewline
        Write-Host " (" -NoNewline
        Write-Host $gate.Status -ForegroundColor $statusColor -NoNewline
        Write-Host ")"
        
        if ($gate.StartTime) {
            Write-Host "  Started: " -NoNewline -ForegroundColor Gray
            Write-Host $gate.StartTime.ToString("yyyy-MM-dd HH:mm") -ForegroundColor Gray
            
            if ($gate.Status -eq "In Review") {
                $elapsed = (Get-Date) - $gate.StartTime
                $timeLimit = [TimeSpan]::FromDays($gateConfig.TimeLimit)
                $remaining = $timeLimit - $elapsed
                
                Write-Host "  Time Remaining: " -NoNewline -ForegroundColor Gray
                if ($remaining.TotalHours -gt 0) {
                    Write-Host "$([math]::Round($remaining.TotalHours, 1)) hours" -ForegroundColor $(if ($remaining.TotalDays -lt 0.5) { "Red" } else { "Yellow" })
                } else {
                    Write-Host "OVERDUE" -ForegroundColor Red
                }
            }
            
            if ($gate.EndTime) {
                Write-Host "  Completed: " -NoNewline -ForegroundColor Gray
                Write-Host $gate.EndTime.ToString("yyyy-MM-dd HH:mm") -ForegroundColor Gray
            }
        }
        
        if ($gate.AutoValidationPassed -ne $null) {
            $autoStatus = if ($gate.AutoValidationPassed) { "PASS" } else { "FAIL" }
            $autoColor = if ($gate.AutoValidationPassed) { "Green" } else { "Red" }
            Write-Host "  Auto-Validation: " -NoNewline -ForegroundColor Gray
            Write-Host $autoStatus -ForegroundColor $autoColor
        }
        
        if ($gate.Reviewers.Count -gt 0) {
            Write-Host "  Reviewers:" -ForegroundColor Gray
            foreach ($reviewer in $gate.Reviewers) {
                $actionColor = if ($reviewer.Action -eq "Approved") { "Green" } else { "Red" }
                Write-Host "    • $($reviewer.Reviewer) - " -NoNewline -ForegroundColor Gray
                Write-Host $reviewer.Action -NoNewline -ForegroundColor $actionColor
                if ($reviewer.Comments) {
                    Write-Host " - $($reviewer.Comments)" -ForegroundColor Gray
                } else {
                    Write-Host "" 
                }
            }
        }
        
        Write-Host ""
    }
    
    # Show next steps
    Write-Host "📋 NEXT STEPS:" -ForegroundColor Cyan
    
    switch ($State.OverallStatus) {
        { $_ -match "Not Started" } {
            Write-Host "  • Run: .\quality-gate-workflow.ps1 -DocumentPath '$($State.DocumentPath)' -Action start -Gate 1" -ForegroundColor Yellow
        }
        { $_ -match "Gate 1 In Progress" } {
            Write-Host "  • Waiting for Gate 1 auto-validation and peer review" -ForegroundColor Yellow
            Write-Host "  • To approve: .\quality-gate-workflow.ps1 -DocumentPath '$($State.DocumentPath)' -Action approve -Gate 1 -ReviewerName 'YourName' -Comments 'Review notes'" -ForegroundColor Yellow
        }
        { $_ -match "Gate \d+ In Progress" } {
            $currentGate = $State.CurrentGate
            $requiredReviewers = $Script:QualityGateConfig.Gates[$currentGate].RequiredReviewers
            Write-Host "  • Waiting for Gate $currentGate review from: $($requiredReviewers -join ', ')" -ForegroundColor Yellow
            Write-Host "  • To approve: .\quality-gate-workflow.ps1 -DocumentPath '$($State.DocumentPath)' -Action approve -Gate $currentGate -ReviewerName 'YourName' -Comments 'Review notes'" -ForegroundColor Yellow
        }
        { $_ -match "Rejected|Failed" } {
            $rejectedGate = $State.CurrentGate
            Write-Host "  • Address rejection feedback and resubmit for Gate $rejectedGate" -ForegroundColor Red
            Write-Host "  • To restart: .\quality-gate-workflow.ps1 -DocumentPath '$($State.DocumentPath)' -Action start -Gate $rejectedGate" -ForegroundColor Yellow
        }
        { $_ -match "APPROVED FOR DEVELOPMENT" } {
            Write-Host "  • 🎉 Document ready for development handoff!" -ForegroundColor Green
            Write-Host "  • No further quality gate actions required" -ForegroundColor Green
        }
    }
    
    Write-Host ""
}

# Main execution logic
function Invoke-QualityGateWorkflow {
    param([string]$DocumentPath, [string]$Action, [string]$Gate, [string]$ReviewerName, [string]$Comments)
    
    # Validate document exists
    if (-not (Test-Path $DocumentPath)) {
        Write-QualityLog "Document not found: $DocumentPath" "ERROR"
        return $false
    }
    
    # Load or initialize document state
    $state = Load-DocumentQualityState $DocumentPath
    
    # Auto-detect gate if not specified
    if (-not $Gate -and $Action -ne "status" -and $Action -ne "reset") {
        $Gate = $state.CurrentGate
        if ($Gate -eq 0) { $Gate = 1 }
        Write-QualityLog "Auto-detected gate: $Gate" "INFO"
    }
    
    $success = $true
    
    switch ($Action.ToLower()) {
        "status" {
            Show-QualityGateStatus $state
        }
        "start" {
            $gateNum = [int]$Gate
            $success = Start-QualityGate $state $gateNum
            if ($success) {
                Save-DocumentQualityState $state
                Show-QualityGateStatus $state
            }
        }
        "approve" {
            $gateNum = [int]$Gate
            if (-not $ReviewerName) {
                Write-QualityLog "ReviewerName is required for approval" "ERROR"
                return $false
            }
            $success = Approve-QualityGate $state $gateNum $ReviewerName $Comments
            if ($success) {
                Save-DocumentQualityState $state
                Show-QualityGateStatus $state
            }
        }
        "reject" {
            $gateNum = [int]$Gate
            if (-not $ReviewerName) {
                Write-QualityLog "ReviewerName is required for rejection" "ERROR"
                return $false
            }
            if (-not $Comments) {
                Write-QualityLog "Comments are required for rejection" "ERROR"
                return $false
            }
            $success = Reject-QualityGate $state $gateNum $ReviewerName $Comments
            if ($success) {
                Save-DocumentQualityState $state
                Show-QualityGateStatus $state
            }
        }
        "reset" {
            Write-QualityLog "Resetting quality gate state for document" "WARNING"
            $stateFilePath = Get-DocumentStateFilePath $DocumentPath
            if (Test-Path $stateFilePath) {
                Remove-Item $stateFilePath -Force
                Write-QualityLog "Quality state reset successfully" "SUCCESS"
            }
            $state = Initialize-DocumentQualityState $DocumentPath
            Save-DocumentQualityState $state
            Show-QualityGateStatus $state
        }
        default {
            Write-QualityLog "Unknown action: $Action" "ERROR"
            $success = $false
        }
    }
    
    return $success
}

# Execute main workflow
try {
    $result = Invoke-QualityGateWorkflow $DocumentPath $Action $Gate $ReviewerName $Comments
    
    if ($result) {
        exit 0
    } else {
        exit 1
    }
} catch {
    Write-QualityLog "Workflow execution failed: $_" "ERROR"
    exit 1
}