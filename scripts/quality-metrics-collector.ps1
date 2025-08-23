# Quality Metrics Collection System
# SmartWatch Project - Process Monitoring Dashboard Data Collection
# Created: 2025-08-19

param(
    [string]$Action = "collect",  # collect, report, dashboard, export
    [string]$OutputPath = "quality-metrics.json",
    [string]$ReportPath = "quality-dashboard.html", 
    [string]$ExportPath = "quality-metrics-export.csv",
    [int]$DaysBack = 30,
    [switch]$Verbose = $false
)

$Script:MetricsConfig = @{
    DataDirectory = "docs\.quality-gates"
    MetricsFile = "quality-metrics.json"
    Documents = @("architecture.md", "prd.md")
    QualityThresholds = @{
        PassRateTarget = 95
        CycleTimeTarget = 7  # business days
        FirstPassTarget = 80
        ReviewerSatisfactionTarget = 4.5
    }
}

function Write-MetricsLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "ERROR" = "Red"
        "WARNING" = "Yellow" 
        "SUCCESS" = "Green"
        "INFO" = "Cyan"
        "METRIC" = "Magenta"
    }
    if ($Verbose -or $Level -eq "ERROR" -or $Level -eq "METRIC") {
        Write-Host "[$timestamp] $Level`: $Message" -ForegroundColor $colorMap[$Level]
    }
}

function Get-AllQualityStateFiles {
    $stateDir = $Script:MetricsConfig.DataDirectory
    if (-not (Test-Path $stateDir)) {
        Write-MetricsLog "Quality gates directory not found: $stateDir" "WARNING"
        return @()
    }
    
    $stateFiles = Get-ChildItem -Path $stateDir -Filter "*-quality-state.json" -ErrorAction SilentlyContinue
    Write-MetricsLog "Found $($stateFiles.Count) quality state files" "INFO"
    return $stateFiles
}

function Load-QualityStateData {
    param([System.IO.FileInfo]$StateFile)
    
    try {
        $data = Get-Content $StateFile.FullName -Raw | ConvertFrom-Json -AsHashtable
        Write-MetricsLog "Loaded state data for: $($data.DocumentName)" "INFO"
        return $data
    } catch {
        Write-MetricsLog "Failed to load state file $($StateFile.Name): $_" "ERROR"
        return $null
    }
}

function Calculate-QualityMetrics {
    param([array]$StateDataList)
    
    Write-MetricsLog "Calculating quality metrics from $($StateDataList.Count) documents..." "METRIC"
    
    $metrics = @{
        CollectionTime = Get-Date
        PeriodDays = $DaysBack
        DocumentsAnalyzed = $StateDataList.Count
        
        # Gate-specific metrics
        GateMetrics = @{
            1 = @{ TotalProcessed = 0; PassCount = 0; FailCount = 0; AvgCycleTime = 0 }
            2 = @{ TotalProcessed = 0; PassCount = 0; FailCount = 0; AvgCycleTime = 0 }
            3 = @{ TotalProcessed = 0; PassCount = 0; FailCount = 0; AvgCycleTime = 0 }
            4 = @{ TotalProcessed = 0; PassCount = 0; FailCount = 0; AvgCycleTime = 0 }
        }
        
        # Overall process metrics
        OverallMetrics = @{
            TotalDocuments = 0
            CompletedDocuments = 0
            ApprovedForDevelopment = 0
            AverageCycleTime = 0
            FirstPassSuccessRate = 0
            DocumentsInProgress = 0
            DocumentsBlocked = 0
        }
        
        # Trend data
        TrendData = @{
            DailySubmissions = @{}
            DailyApprovals = @{}
            WeeklyPassRates = @{}
        }
        
        # Quality indicators
        QualityIndicators = @{
            MostCommonFailureReasons = @{}
            ReviewerWorkloadDistribution = @{}
            DocumentTypePerformance = @{}
            TimeToResolutionTrends = @{}
        }
    }
    
    foreach ($stateData in $StateDataList) {
        if (-not $stateData) { continue }
        
        $metrics.OverallMetrics.TotalDocuments++
        
        # Analyze each gate
        foreach ($gateNum in 1..4) {
            $gate = $stateData.Gates[$gateNum]
            if (-not $gate) { continue }
            
            # Only count gates that have been started
            if ($gate.StartTime) {
                $metrics.GateMetrics[$gateNum].TotalProcessed++
                
                if ($gate.Status -eq "Approved") {
                    $metrics.GateMetrics[$gateNum].PassCount++
                    
                    if ($gate.EndTime -and $gate.StartTime) {
                        $cycleTime = (([DateTime]$gate.EndTime) - ([DateTime]$gate.StartTime)).TotalDays
                        $metrics.GateMetrics[$gateNum].AvgCycleTime += $cycleTime
                    }
                } elseif ($gate.Status -eq "Rejected" -or $gate.Status -eq "Failed Auto-Validation") {
                    $metrics.GateMetrics[$gateNum].FailCount++
                }
            }
        }
        
        # Overall document status analysis
        switch ($stateData.OverallStatus) {
            { $_ -match "APPROVED FOR DEVELOPMENT" } { 
                $metrics.OverallMetrics.CompletedDocuments++
                $metrics.OverallMetrics.ApprovedForDevelopment++
            }
            { $_ -match "In Progress" } { 
                $metrics.OverallMetrics.DocumentsInProgress++
            }
            { $_ -match "Rejected|Failed" } { 
                $metrics.OverallMetrics.DocumentsBlocked++
            }
        }
        
        # Trend analysis
        if ($stateData.Created) {
            $createDate = ([DateTime]$stateData.Created).ToString("yyyy-MM-dd")
            if (-not $metrics.TrendData.DailySubmissions.ContainsKey($createDate)) {
                $metrics.TrendData.DailySubmissions[$createDate] = 0
            }
            $metrics.TrendData.DailySubmissions[$createDate]++
        }
        
        # Document type performance
        $docType = if ($stateData.DocumentName -like "*architecture*") { "Architecture" } 
                  elseif ($stateData.DocumentName -like "*prd*") { "PRD" } 
                  else { "Other" }
        
        if (-not $metrics.QualityIndicators.DocumentTypePerformance.ContainsKey($docType)) {
            $metrics.QualityIndicators.DocumentTypePerformance[$docType] = @{
                Total = 0; Approved = 0; InProgress = 0; Failed = 0
            }
        }
        
        $metrics.QualityIndicators.DocumentTypePerformance[$docType].Total++
        
        switch ($stateData.OverallStatus) {
            { $_ -match "APPROVED" } { $metrics.QualityIndicators.DocumentTypePerformance[$docType].Approved++ }
            { $_ -match "In Progress" } { $metrics.QualityIndicators.DocumentTypePerformance[$docType].InProgress++ }
            { $_ -match "Rejected|Failed" } { $metrics.QualityIndicators.DocumentTypePerformance[$docType].Failed++ }
        }
        
        # Reviewer workload
        foreach ($gateNum in 1..4) {
            $gate = $stateData.Gates[$gateNum]
            if ($gate.Reviewers) {
                foreach ($reviewer in $gate.Reviewers) {
                    $reviewerName = $reviewer.Reviewer
                    if (-not $metrics.QualityIndicators.ReviewerWorkloadDistribution.ContainsKey($reviewerName)) {
                        $metrics.QualityIndicators.ReviewerWorkloadDistribution[$reviewerName] = @{
                            ReviewsCompleted = 0; ApprovalsGiven = 0; RejectionsGiven = 0
                        }
                    }
                    
                    $metrics.QualityIndicators.ReviewerWorkloadDistribution[$reviewerName].ReviewsCompleted++
                    
                    if ($reviewer.Action -eq "Approved") {
                        $metrics.QualityIndicators.ReviewerWorkloadDistribution[$reviewerName].ApprovalsGiven++
                    } else {
                        $metrics.QualityIndicators.ReviewerWorkloadDistribution[$reviewerName].RejectionsGiven++
                    }
                }
            }
        }
    }
    
    # Calculate averages and rates
    foreach ($gateNum in 1..4) {
        $gate = $metrics.GateMetrics[$gateNum]
        if ($gate.TotalProcessed -gt 0) {
            $gate.PassRate = [math]::Round(($gate.PassCount / $gate.TotalProcessed) * 100, 1)
            if ($gate.PassCount -gt 0) {
                $gate.AvgCycleTime = [math]::Round($gate.AvgCycleTime / $gate.PassCount, 1)
            }
        } else {
            $gate.PassRate = 0
        }
    }
    
    # Overall metrics calculations
    if ($metrics.OverallMetrics.TotalDocuments -gt 0) {
        $metrics.OverallMetrics.CompletionRate = [math]::Round(($metrics.OverallMetrics.CompletedDocuments / $metrics.OverallMetrics.TotalDocuments) * 100, 1)
        $metrics.OverallMetrics.BlockedRate = [math]::Round(($metrics.OverallMetrics.DocumentsBlocked / $metrics.OverallMetrics.TotalDocuments) * 100, 1)
    }
    
    # Calculate first-pass success rate (Gate 1 auto-validation pass rate)
    $gate1 = $metrics.GateMetrics[1]
    if ($gate1.TotalProcessed -gt 0) {
        $metrics.OverallMetrics.FirstPassSuccessRate = $gate1.PassRate
    }
    
    return $metrics
}

function Generate-QualityDashboard {
    param([hashtable]$Metrics)
    
    $thresholds = $Script:MetricsConfig.QualityThresholds
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>SmartWatch Project - Quality Gates Dashboard</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            margin: 0; padding: 20px; background-color: #f5f7fa; 
        }
        .header { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; 
        }
        .header h1 { margin: 0; font-size: 2.2em; }
        .header p { margin: 10px 0 0 0; opacity: 0.9; }
        
        .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric-card { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .metric-card h3 { margin: 0 0 15px 0; color: #333; font-size: 1.1em; }
        .metric-value { font-size: 2.5em; font-weight: bold; margin: 10px 0; }
        .metric-label { color: #666; font-size: 0.9em; }
        
        .status-excellent { color: #27ae60; }
        .status-good { color: #2980b9; }
        .status-warning { color: #f39c12; }
        .status-critical { color: #e74c3c; }
        
        .gate-summary { background: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 20px; overflow: hidden; }
        .gate-summary h2 { background: #34495e; color: white; margin: 0; padding: 20px; }
        .gate-table { width: 100%; border-collapse: collapse; }
        .gate-table th, .gate-table td { padding: 12px; text-align: left; border-bottom: 1px solid #ecf0f1; }
        .gate-table th { background-color: #f8f9fa; font-weight: 600; }
        .gate-table tr:hover { background-color: #f8f9fa; }
        
        .charts-section { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 20px; margin: 20px 0; }
        .chart-card { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        
        .progress-bar { background: #ecf0f1; height: 8px; border-radius: 4px; overflow: hidden; margin: 10px 0; }
        .progress-fill { height: 100%; background: #3498db; transition: width 0.3s ease; }
        
        .footer { text-align: center; margin-top: 40px; color: #7f8c8d; font-size: 0.9em; }
        
        @media (max-width: 768px) {
            .metrics-grid { grid-template-columns: 1fr; }
            .charts-section { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 Quality Gates Dashboard</h1>
        <p>SmartWatch Project Document Quality Monitoring</p>
        <p>Generated: $($Metrics.CollectionTime.ToString('yyyy-MM-dd HH:mm:ss')) | Period: Last $($Metrics.PeriodDays) days</p>
    </div>

    <div class="metrics-grid">
        <div class="metric-card">
            <h3>📋 Documents Processed</h3>
            <div class="metric-value">$($Metrics.OverallMetrics.TotalDocuments)</div>
            <div class="metric-label">Total documents in system</div>
        </div>
        
        <div class="metric-card">
            <h3>✅ Development Ready</h3>
            <div class="metric-value status-$(if($Metrics.OverallMetrics.CompletionRate -ge 80){'excellent'}elseif($Metrics.OverallMetrics.CompletionRate -ge 60){'good'}elseif($Metrics.OverallMetrics.CompletionRate -ge 40){'warning'}else{'critical'})">
                $($Metrics.OverallMetrics.ApprovedForDevelopment)
            </div>
            <div class="metric-label">Approved for development ($($Metrics.OverallMetrics.CompletionRate)%)</div>
            <div class="progress-bar">
                <div class="progress-fill" style="width: $($Metrics.OverallMetrics.CompletionRate)%"></div>
            </div>
        </div>
        
        <div class="metric-card">
            <h3>🚀 First-Pass Success</h3>
            <div class="metric-value status-$(if($Metrics.OverallMetrics.FirstPassSuccessRate -ge 80){'excellent'}elseif($Metrics.OverallMetrics.FirstPassSuccessRate -ge 60){'good'}elseif($Metrics.OverallMetrics.FirstPassSuccessRate -ge 40){'warning'}else{'critical'})">
                $($Metrics.OverallMetrics.FirstPassSuccessRate)%
            </div>
            <div class="metric-label">Gate 1 auto-validation pass rate</div>
            <div class="progress-bar">
                <div class="progress-fill" style="width: $($Metrics.OverallMetrics.FirstPassSuccessRate)%"></div>
            </div>
        </div>
        
        <div class="metric-card">
            <h3>⚠️ Blocked Documents</h3>
            <div class="metric-value status-$(if($Metrics.OverallMetrics.BlockedRate -le 10){'excellent'}elseif($Metrics.OverallMetrics.BlockedRate -le 25){'good'}elseif($Metrics.OverallMetrics.BlockedRate -le 40){'warning'}else{'critical'})">
                $($Metrics.OverallMetrics.DocumentsBlocked)
            </div>
            <div class="metric-label">Documents requiring revision ($($Metrics.OverallMetrics.BlockedRate)%)</div>
        </div>
    </div>

    <div class="gate-summary">
        <h2>🏗️ Quality Gate Performance</h2>
        <table class="gate-table">
            <thead>
                <tr>
                    <th>Gate</th>
                    <th>Name</th>
                    <th>Processed</th>
                    <th>Pass Rate</th>
                    <th>Avg Cycle Time</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
"@

    foreach ($gateNum in 1..4) {
        $gate = $Metrics.GateMetrics[$gateNum]
        $gateConfig = @{
            1 = "Document Completeness"
            2 = "Technical Review"  
            3 = "Stakeholder Alignment"
            4 = "Development Readiness"
        }
        
        $statusClass = if ($gate.PassRate -ge 90) { "status-excellent" } 
                      elseif ($gate.PassRate -ge 70) { "status-good" }
                      elseif ($gate.PassRate -ge 50) { "status-warning" }
                      else { "status-critical" }
        
        $cycleTimeClass = if ($gate.AvgCycleTime -le 1) { "status-excellent" }
                         elseif ($gate.AvgCycleTime -le 3) { "status-good" } 
                         elseif ($gate.AvgCycleTime -le 7) { "status-warning" }
                         else { "status-critical" }
        
        $html += @"
                <tr>
                    <td><strong>Gate $gateNum</strong></td>
                    <td>$($gateConfig[$gateNum])</td>
                    <td>$($gate.TotalProcessed)</td>
                    <td><span class="$statusClass">$($gate.PassRate)%</span></td>
                    <td><span class="$cycleTimeClass">${($gate.AvgCycleTime)} days</span></td>
                    <td>$(if($gate.PassRate -ge 80){'🟢 Healthy'}elseif($gate.PassRate -ge 60){'🟡 Needs Attention'}else{'🔴 Critical'})</td>
                </tr>
"@
    }

    $html += @"
            </tbody>
        </table>
    </div>

    <div class="charts-section">
        <div class="chart-card">
            <h3>📈 Document Type Performance</h3>
            <table class="gate-table">
                <thead>
                    <tr>
                        <th>Type</th>
                        <th>Total</th>
                        <th>Approved</th>
                        <th>In Progress</th>
                        <th>Failed</th>
                        <th>Success Rate</th>
                    </tr>
                </thead>
                <tbody>
"@

    foreach ($docType in $Metrics.QualityIndicators.DocumentTypePerformance.Keys) {
        $perf = $Metrics.QualityIndicators.DocumentTypePerformance[$docType]
        $successRate = if ($perf.Total -gt 0) { [math]::Round(($perf.Approved / $perf.Total) * 100, 1) } else { 0 }
        
        $html += @"
                    <tr>
                        <td><strong>$docType</strong></td>
                        <td>$($perf.Total)</td>
                        <td class="status-excellent">$($perf.Approved)</td>
                        <td class="status-warning">$($perf.InProgress)</td>
                        <td class="status-critical">$($perf.Failed)</td>
                        <td><span class="$(if($successRate -ge 80){'status-excellent'}elseif($successRate -ge 60){'status-good'}else{'status-warning'})">$successRate%</span></td>
                    </tr>
"@
    }

    $html += @"
                </tbody>
            </table>
        </div>

        <div class="chart-card">
            <h3>👥 Reviewer Workload Distribution</h3>
            <table class="gate-table">
                <thead>
                    <tr>
                        <th>Reviewer</th>
                        <th>Reviews</th>
                        <th>Approvals</th>
                        <th>Rejections</th>
                        <th>Approval Rate</th>
                    </tr>
                </thead>
                <tbody>
"@

    foreach ($reviewer in $Metrics.QualityIndicators.ReviewerWorkloadDistribution.Keys) {
        $workload = $Metrics.QualityIndicators.ReviewerWorkloadDistribution[$reviewer]
        $approvalRate = if ($workload.ReviewsCompleted -gt 0) { 
            [math]::Round(($workload.ApprovalsGiven / $workload.ReviewsCompleted) * 100, 1) 
        } else { 0 }
        
        $html += @"
                    <tr>
                        <td><strong>$reviewer</strong></td>
                        <td>$($workload.ReviewsCompleted)</td>
                        <td class="status-excellent">$($workload.ApprovalsGiven)</td>
                        <td class="status-critical">$($workload.RejectionsGiven)</td>
                        <td><span class="$(if($approvalRate -ge 70){'status-excellent'}elseif($approvalRate -ge 50){'status-good'}else{'status-warning'})">$approvalRate%</span></td>
                    </tr>
"@
    }

    $html += @"
                </tbody>
            </table>
        </div>
    </div>

    <div class="gate-summary">
        <h2>🎯 Quality Targets vs Actuals</h2>
        <table class="gate-table">
            <thead>
                <tr>
                    <th>Metric</th>
                    <th>Target</th>
                    <th>Actual</th>
                    <th>Status</th>
                    <th>Variance</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>Overall Pass Rate</td>
                    <td>$($thresholds.PassRateTarget)%</td>
                    <td>$($Metrics.OverallMetrics.FirstPassSuccessRate)%</td>
                    <td>$(if($Metrics.OverallMetrics.FirstPassSuccessRate -ge $thresholds.PassRateTarget){'🟢 On Target'}else{'🔴 Below Target'})</td>
                    <td>$(if($Metrics.OverallMetrics.FirstPassSuccessRate -ge $thresholds.PassRateTarget){'+'}else{''})$($Metrics.OverallMetrics.FirstPassSuccessRate - $thresholds.PassRateTarget)%</td>
                </tr>
                <tr>
                    <td>First Pass Success</td>
                    <td>$($thresholds.FirstPassTarget)%</td>
                    <td>$($Metrics.OverallMetrics.FirstPassSuccessRate)%</td>
                    <td>$(if($Metrics.OverallMetrics.FirstPassSuccessRate -ge $thresholds.FirstPassTarget){'🟢 On Target'}else{'🔴 Below Target'})</td>
                    <td>$(if($Metrics.OverallMetrics.FirstPassSuccessRate -ge $thresholds.FirstPassTarget){'+'}else{''})$($Metrics.OverallMetrics.FirstPassSuccessRate - $thresholds.FirstPassTarget)%</td>
                </tr>
            </tbody>
        </table>
    </div>

    <div class="footer">
        <p>📊 SmartWatch Project Quality Gates Dashboard | Last Updated: $($Metrics.CollectionTime.ToString('yyyy-MM-dd HH:mm:ss'))</p>
        <p>Quality gate automation powered by PowerShell validation scripts</p>
    </div>
</body>
</html>
"@

    return $html
}

function Export-MetricsToCSV {
    param([hashtable]$Metrics, [string]$ExportPath)
    
    $csvData = @()
    
    # Add overall metrics
    $csvData += [PSCustomObject]@{
        Category = "Overall"
        Metric = "Total Documents"
        Value = $Metrics.OverallMetrics.TotalDocuments
        Target = ""
        Status = ""
        Date = $Metrics.CollectionTime.ToString('yyyy-MM-dd')
    }
    
    $csvData += [PSCustomObject]@{
        Category = "Overall"  
        Metric = "Approved Documents"
        Value = $Metrics.OverallMetrics.ApprovedForDevelopment
        Target = ""
        Status = ""
        Date = $Metrics.CollectionTime.ToString('yyyy-MM-dd')
    }
    
    $csvData += [PSCustomObject]@{
        Category = "Overall"
        Metric = "First Pass Success Rate (%)"
        Value = $Metrics.OverallMetrics.FirstPassSuccessRate
        Target = $Script:MetricsConfig.QualityThresholds.FirstPassTarget
        Status = if ($Metrics.OverallMetrics.FirstPassSuccessRate -ge $Script:MetricsConfig.QualityThresholds.FirstPassTarget) { "On Target" } else { "Below Target" }
        Date = $Metrics.CollectionTime.ToString('yyyy-MM-dd')
    }
    
    # Add gate-specific metrics
    foreach ($gateNum in 1..4) {
        $gate = $Metrics.GateMetrics[$gateNum]
        
        $csvData += [PSCustomObject]@{
            Category = "Gate $gateNum"
            Metric = "Documents Processed"
            Value = $gate.TotalProcessed
            Target = ""
            Status = ""
            Date = $Metrics.CollectionTime.ToString('yyyy-MM-dd')
        }
        
        $csvData += [PSCustomObject]@{
            Category = "Gate $gateNum"
            Metric = "Pass Rate (%)"
            Value = $gate.PassRate
            Target = $Script:MetricsConfig.QualityThresholds.PassRateTarget
            Status = if ($gate.PassRate -ge $Script:MetricsConfig.QualityThresholds.PassRateTarget) { "On Target" } else { "Below Target" }
            Date = $Metrics.CollectionTime.ToString('yyyy-MM-dd')
        }
        
        $csvData += [PSCustomObject]@{
            Category = "Gate $gateNum"
            Metric = "Avg Cycle Time (days)"
            Value = $gate.AvgCycleTime
            Target = $Script:MetricsConfig.QualityThresholds.CycleTimeTarget
            Status = if ($gate.AvgCycleTime -le $Script:MetricsConfig.QualityThresholds.CycleTimeTarget) { "On Target" } else { "Above Target" }
            Date = $Metrics.CollectionTime.ToString('yyyy-MM-dd')
        }
    }
    
    try {
        $csvData | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-MetricsLog "Metrics exported to CSV: $ExportPath" "SUCCESS"
        return $true
    } catch {
        Write-MetricsLog "Failed to export CSV: $_" "ERROR"
        return $false
    }
}

function Save-MetricsData {
    param([hashtable]$Metrics, [string]$OutputPath)
    
    try {
        $Metrics | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-MetricsLog "Metrics data saved: $OutputPath" "SUCCESS"
        return $true
    } catch {
        Write-MetricsLog "Failed to save metrics data: $_" "ERROR"
        return $false
    }
}

function Invoke-MetricsCollection {
    Write-MetricsLog "Starting quality metrics collection..." "METRIC"
    
    # Get all quality state files
    $stateFiles = Get-AllQualityStateFiles
    if ($stateFiles.Count -eq 0) {
        Write-MetricsLog "No quality state files found. Run quality gate processes first." "WARNING"
        return $null
    }
    
    # Load all state data
    $stateDataList = @()
    foreach ($stateFile in $stateFiles) {
        $stateData = Load-QualityStateData $stateFile
        if ($stateData) {
            # Filter by date range if specified
            if ($DaysBack -gt 0) {
                $cutoffDate = (Get-Date).AddDays(-$DaysBack)
                if ($stateData.Created -and ([DateTime]$stateData.Created) -ge $cutoffDate) {
                    $stateDataList += $stateData
                }
            } else {
                $stateDataList += $stateData
            }
        }
    }
    
    if ($stateDataList.Count -eq 0) {
        Write-MetricsLog "No state data found within the specified time range" "WARNING"
        return $null
    }
    
    # Calculate metrics
    $metrics = Calculate-QualityMetrics $stateDataList
    
    Write-MetricsLog "Metrics calculation complete" "SUCCESS"
    Write-MetricsLog "Documents analyzed: $($metrics.DocumentsAnalyzed)" "METRIC"
    Write-MetricsLog "Overall completion rate: $($metrics.OverallMetrics.CompletionRate)%" "METRIC"
    Write-MetricsLog "First-pass success rate: $($metrics.OverallMetrics.FirstPassSuccessRate)%" "METRIC"
    
    return $metrics
}

# Main execution logic
function Invoke-QualityMetricsSystem {
    switch ($Action.ToLower()) {
        "collect" {
            $metrics = Invoke-MetricsCollection
            if ($metrics) {
                Save-MetricsData $metrics $OutputPath
                Write-Host "Quality metrics collected and saved to: $OutputPath" -ForegroundColor Green
            }
        }
        "report" {
            $metrics = Invoke-MetricsCollection
            if ($metrics) {
                $html = Generate-QualityDashboard $metrics
                $html | Out-File -FilePath $ReportPath -Encoding UTF8
                Write-Host "Quality dashboard generated: $ReportPath" -ForegroundColor Green
                
                # Try to open the dashboard
                try {
                    Start-Process $ReportPath
                } catch {
                    Write-MetricsLog "Dashboard saved, but couldn't auto-open: $_" "WARNING"
                }
            }
        }
        "dashboard" {
            # Same as report, but explicitly for dashboard generation
            $metrics = Invoke-MetricsCollection
            if ($metrics) {
                Save-MetricsData $metrics $OutputPath
                $html = Generate-QualityDashboard $metrics
                $html | Out-File -FilePath $ReportPath -Encoding UTF8
                Write-Host "Quality dashboard updated: $ReportPath" -ForegroundColor Green
            }
        }
        "export" {
            $metrics = Invoke-MetricsCollection
            if ($metrics) {
                Export-MetricsToCSV $metrics $ExportPath
                Write-Host "Quality metrics exported to CSV: $ExportPath" -ForegroundColor Green
            }
        }
        default {
            Write-Host "Usage: .\quality-metrics-collector.ps1 -Action <collect|report|dashboard|export>"
            Write-Host ""
            Write-Host "Examples:"
            Write-Host "  .\quality-metrics-collector.ps1 -Action collect -Verbose"
            Write-Host "  .\quality-metrics-collector.ps1 -Action dashboard -ReportPath quality-dashboard.html"
            Write-Host "  .\quality-metrics-collector.ps1 -Action export -ExportPath metrics.csv -DaysBack 7"
            exit 1
        }
    }
}

# Execute main function
try {
    Invoke-QualityMetricsSystem
    exit 0
} catch {
    Write-MetricsLog "Metrics system execution failed: $_" "ERROR"
    exit 1
}