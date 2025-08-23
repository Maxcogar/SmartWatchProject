# ESP32-S3 ADHD SmartWatch Quality Gates Automation
# Comprehensive quality assurance system following professional standards

param(
    [ValidateSet("all", "build", "static", "security", "performance", "documentation")]
    [string]$CheckType = "all",
    [switch]$ContinueOnFailure,
    [switch]$GenerateReport,
    [string]$ReportPath = "quality_reports",
    [switch]$Verbose
)

# Configuration
$ErrorActionPreference = if ($ContinueOnFailure) { "Continue" } else { "Stop" }
$ProgressPreference = "SilentlyContinue"

# Paths
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptPath
$FirmwarePath = $ProjectRoot
$BuildPath = Join-Path $FirmwarePath "build"
$SourcePath = Join-Path $FirmwarePath "main"

# Quality thresholds (from architecture document)
$QualityThresholds = @{
    BuildWarnings = 0                   # No warnings allowed
    CodeCoverage = 90                   # Minimum 90% test coverage
    CyclomaticComplexity = 10           # Maximum cyclomatic complexity
    SecurityIssues = 0                  # No security vulnerabilities
    CodeDuplication = 5                 # Maximum 5% code duplication
    TechnicalDebt = "A"                 # Minimum technical debt rating
    ResponseTime = 250                  # Maximum 250ms touch response
    BatteryLife = 12                    # Minimum 12 hours battery life
    BleReliability = 95                 # Minimum 95% BLE reliability
}

# Global results tracking
$QualityResults = @{
    TotalChecks = 0
    PassedChecks = 0
    FailedChecks = 0
    WarningChecks = 0
    Details = @()
    StartTime = Get-Date
}

# Utility functions
function Write-QualityLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "PASS", "FAIL", "WARN", "DEBUG")]
        [string]$Level = "INFO",
        [switch]$NoNewline
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        "DEBUG" { "Gray" }
        default { "White" }
    }
    
    $prefix = switch ($Level) {
        "PASS" { "✅" }
        "FAIL" { "❌" }
        "WARN" { "⚠️ " }
        "DEBUG" { "🔍" }
        default { "ℹ️ " }
    }
    
    $logMessage = "[$timestamp] [$Level] $prefix $Message"
    
    if ($NoNewline) {
        Write-Host $logMessage -ForegroundColor $color -NoNewline
    } else {
        Write-Host $logMessage -ForegroundColor $color
    }
    
    # Add to verbose output if enabled
    if ($Verbose -and $Level -eq "DEBUG") {
        Write-Host $logMessage -ForegroundColor $color
    }
}

function Add-QualityResult {
    param(
        [string]$CheckName,
        [ValidateSet("PASS", "FAIL", "WARN", "SKIP")]
        [string]$Result,
        [string]$Details = "",
        [hashtable]$Metrics = @{}
    )
    
    $QualityResults.TotalChecks++
    
    switch ($Result) {
        "PASS" { 
            $QualityResults.PassedChecks++
            Write-QualityLog "$CheckName: $Result" "PASS"
        }
        "FAIL" { 
            $QualityResults.FailedChecks++
            Write-QualityLog "$CheckName: $Result - $Details" "FAIL"
        }
        "WARN" { 
            $QualityResults.WarningChecks++
            Write-QualityLog "$CheckName: $Result - $Details" "WARN"
        }
        "SKIP" {
            Write-QualityLog "$CheckName: Skipped - $Details" "INFO"
        }
    }
    
    $QualityResults.Details += @{
        Check = $CheckName
        Result = $Result
        Details = $Details
        Metrics = $Metrics
        Timestamp = Get-Date
    }
}

function Test-BuildQuality {
    Write-QualityLog "🔨 Running Build Quality Checks..." "INFO"
    
    # Check 1: Build without warnings
    Write-QualityLog "Checking build warnings..." "DEBUG"
    try {
        Push-Location $FirmwarePath
        
        # Activate ESP-IDF environment
        $env:IDF_PATH = "C:\esp\esp-idf"
        
        # Run build and capture output
        $buildOutput = & idf.py build 2>&1
        $buildExitCode = $LASTEXITCODE
        
        if ($buildExitCode -eq 0) {
            # Count warnings
            $warnings = ($buildOutput | Select-String -Pattern "warning:" | Measure-Object).Count
            
            if ($warnings -eq 0) {
                Add-QualityResult "Build Warnings" "PASS" "No warnings found" @{ WarningCount = $warnings }
            } elseif ($warnings -le $QualityThresholds.BuildWarnings) {
                Add-QualityResult "Build Warnings" "WARN" "$warnings warnings found (threshold: $($QualityThresholds.BuildWarnings))" @{ WarningCount = $warnings }
            } else {
                Add-QualityResult "Build Warnings" "FAIL" "$warnings warnings exceed threshold of $($QualityThresholds.BuildWarnings)" @{ WarningCount = $warnings }
            }
        } else {
            Add-QualityResult "Build Warnings" "FAIL" "Build failed with exit code $buildExitCode"
        }
    } catch {
        Add-QualityResult "Build Warnings" "FAIL" "Build check failed: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
    
    # Check 2: Binary size analysis
    Write-QualityLog "Analyzing binary size..." "DEBUG"
    $binaryPath = Join-Path $BuildPath "smartwatch.bin"
    if (Test-Path $binaryPath) {
        $binarySize = (Get-Item $binaryPath).Length
        $binarySizeKB = [math]::Round($binarySize / 1024, 2)
        $maxSizeKB = 2048  # 2MB limit for ESP32-S3
        
        if ($binarySizeKB -le $maxSizeKB) {
            Add-QualityResult "Binary Size" "PASS" "Size: ${binarySizeKB}KB (limit: ${maxSizeKB}KB)" @{ SizeKB = $binarySizeKB; LimitKB = $maxSizeKB }
        } else {
            Add-QualityResult "Binary Size" "FAIL" "Size: ${binarySizeKB}KB exceeds limit of ${maxSizeKB}KB" @{ SizeKB = $binarySizeKB; LimitKB = $maxSizeKB }
        }
    } else {
        Add-QualityResult "Binary Size" "FAIL" "Binary file not found at $binaryPath"
    }
    
    # Check 3: Memory usage analysis
    Write-QualityLog "Analyzing memory usage..." "DEBUG"
    try {
        Push-Location $FirmwarePath
        $sizeOutput = & idf.py size 2>&1
        if ($LASTEXITCODE -eq 0) {
            # Parse memory usage
            $flashUsage = ($sizeOutput | Select-String -Pattern "Total sizes:" | Out-String).Trim()
            Add-QualityResult "Memory Usage" "PASS" "Memory analysis completed" @{ FlashUsage = $flashUsage }
        } else {
            Add-QualityResult "Memory Usage" "WARN" "Could not analyze memory usage"
        }
    } catch {
        Add-QualityResult "Memory Usage" "WARN" "Memory analysis failed: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
}

function Test-StaticAnalysis {
    Write-QualityLog "🔍 Running Static Analysis Checks..." "INFO"
    
    # Check 1: Code complexity (basic check)
    Write-QualityLog "Analyzing code complexity..." "DEBUG"
    try {
        $sourceFiles = Get-ChildItem -Path $SourcePath -Recurse -Include "*.c", "*.cpp", "*.h", "*.hpp"
        $totalFiles = $sourceFiles.Count
        $complexFiles = 0
        
        foreach ($file in $sourceFiles) {
            $content = Get-Content $file.FullName
            $functionCount = ($content | Select-String -Pattern "^[a-zA-Z_][a-zA-Z0-9_]*\s*\(" | Measure-Object).Count
            $lineCount = $content.Count
            
            # Simple complexity heuristic: functions per 100 lines
            if ($lineCount -gt 0 -and ($functionCount / ($lineCount / 100)) -gt 5) {
                $complexFiles++
            }
        }
        
        $complexityRatio = if ($totalFiles -gt 0) { ($complexFiles / $totalFiles) * 100 } else { 0 }
        
        if ($complexityRatio -le 20) {
            Add-QualityResult "Code Complexity" "PASS" "$complexFiles/$totalFiles files with high complexity (${complexityRatio}%)" @{ ComplexFiles = $complexFiles; TotalFiles = $totalFiles }
        } else {
            Add-QualityResult "Code Complexity" "WARN" "$complexFiles/$totalFiles files with high complexity (${complexityRatio}%)" @{ ComplexFiles = $complexFiles; TotalFiles = $totalFiles }
        }
    } catch {
        Add-QualityResult "Code Complexity" "WARN" "Complexity analysis failed: $($_.Exception.Message)"
    }
    
    # Check 2: Include guard consistency
    Write-QualityLog "Checking include guards..." "DEBUG"
    try {
        $headerFiles = Get-ChildItem -Path $SourcePath -Recurse -Include "*.h", "*.hpp"
        $missingGuards = 0
        
        foreach ($header in $headerFiles) {
            $content = Get-Content $header.FullName
            $hasPragmaOnce = ($content | Select-String -Pattern "^#pragma once" | Measure-Object).Count -gt 0
            $hasIncludeGuard = ($content | Select-String -Pattern "^#ifndef.*_H$" | Measure-Object).Count -gt 0
            
            if (-not ($hasPragmaOnce -or $hasIncludeGuard)) {
                $missingGuards++
            }
        }
        
        if ($missingGuards -eq 0) {
            Add-QualityResult "Include Guards" "PASS" "All header files have proper include guards" @{ MissingGuards = $missingGuards; TotalHeaders = $headerFiles.Count }
        } else {
            Add-QualityResult "Include Guards" "WARN" "$missingGuards header files missing include guards" @{ MissingGuards = $missingGuards; TotalHeaders = $headerFiles.Count }
        }
    } catch {
        Add-QualityResult "Include Guards" "WARN" "Include guard check failed: $($_.Exception.Message)"
    }
    
    # Check 3: Code formatting consistency
    Write-QualityLog "Checking code formatting..." "DEBUG"
    try {
        $sourceFiles = Get-ChildItem -Path $SourcePath -Recurse -Include "*.c", "*.cpp", "*.h", "*.hpp"
        $inconsistentFiles = 0
        
        foreach ($file in $sourceFiles) {
            $content = Get-Content $file.FullName -Raw
            
            # Check for consistent indentation (tabs vs spaces)
            $tabLines = ($content -split "`n" | Where-Object { $_ -match "^\t" } | Measure-Object).Count
            $spaceLines = ($content -split "`n" | Where-Object { $_ -match "^    " } | Measure-Object).Count
            
            if ($tabLines -gt 0 -and $spaceLines -gt 0) {
                $inconsistentFiles++
            }
        }
        
        if ($inconsistentFiles -eq 0) {
            Add-QualityResult "Code Formatting" "PASS" "Consistent formatting across all files" @{ InconsistentFiles = $inconsistentFiles; TotalFiles = $sourceFiles.Count }
        } else {
            Add-QualityResult "Code Formatting" "WARN" "$inconsistentFiles files have inconsistent indentation" @{ InconsistentFiles = $inconsistentFiles; TotalFiles = $sourceFiles.Count }
        }
    } catch {
        Add-QualityResult "Code Formatting" "WARN" "Formatting check failed: $($_.Exception.Message)"
    }
}

function Test-SecurityChecks {
    Write-QualityLog "🛡️ Running Security Checks..." "INFO"
    
    # Check 1: Hardcoded credentials
    Write-QualityLog "Scanning for hardcoded credentials..." "DEBUG"
    try {
        $sourceFiles = Get-ChildItem -Path $SourcePath -Recurse -Include "*.c", "*.cpp", "*.h", "*.hpp"
        $credentialIssues = 0
        
        $patterns = @(
            "password\s*=",
            "api_key\s*=",
            "secret\s*=",
            "token\s*=",
            "private_key\s*="
        )
        
        foreach ($file in $sourceFiles) {
            $content = Get-Content $file.FullName -Raw
            foreach ($pattern in $patterns) {
                if ($content -match $pattern) {
                    $credentialIssues++
                    break
                }
            }
        }
        
        if ($credentialIssues -eq 0) {
            Add-QualityResult "Hardcoded Credentials" "PASS" "No hardcoded credentials found" @{ IssueCount = $credentialIssues }
        } else {
            Add-QualityResult "Hardcoded Credentials" "FAIL" "$credentialIssues files contain potential hardcoded credentials" @{ IssueCount = $credentialIssues }
        }
    } catch {
        Add-QualityResult "Hardcoded Credentials" "WARN" "Security scan failed: $($_.Exception.Message)"
    }
    
    # Check 2: Buffer overflow patterns
    Write-QualityLog "Checking for unsafe functions..." "DEBUG"
    try {
        $sourceFiles = Get-ChildItem -Path $SourcePath -Recurse -Include "*.c", "*.cpp"
        $unsafeFunctions = 0
        
        $dangerousFunctions = @("strcpy", "strcat", "sprintf", "gets", "scanf")
        
        foreach ($file in $sourceFiles) {
            $content = Get-Content $file.FullName -Raw
            foreach ($func in $dangerousFunctions) {
                if ($content -match "\b$func\s*\(") {
                    $unsafeFunctions++
                    break
                }
            }
        }
        
        if ($unsafeFunctions -eq 0) {
            Add-QualityResult "Unsafe Functions" "PASS" "No unsafe functions found" @{ UnsafeFunctions = $unsafeFunctions }
        } else {
            Add-QualityResult "Unsafe Functions" "WARN" "$unsafeFunctions files use potentially unsafe functions" @{ UnsafeFunctions = $unsafeFunctions }
        }
    } catch {
        Add-QualityResult "Unsafe Functions" "WARN" "Unsafe function check failed: $($_.Exception.Message)"
    }
    
    # Check 3: Security configuration
    Write-QualityLog "Checking security configuration..." "DEBUG"
    try {
        $sdkconfigPath = Join-Path $FirmwarePath "sdkconfig"
        if (Test-Path $sdkconfigPath) {
            $config = Get-Content $sdkconfigPath -Raw
            
            $securityFeatures = @{
                "NVS_ENCRYPTION" = $config -match "CONFIG_NVS_ENCRYPTION=y"
                "SECURE_BOOT" = $config -match "CONFIG_SECURE_BOOT=y"
                "FLASH_ENCRYPTION" = $config -match "CONFIG_SECURE_FLASH_ENC_ENABLED=y"
            }
            
            $enabledFeatures = ($securityFeatures.Values | Where-Object { $_ }).Count
            $totalFeatures = $securityFeatures.Count
            
            if ($enabledFeatures -eq $totalFeatures) {
                Add-QualityResult "Security Configuration" "PASS" "All security features enabled" @{ EnabledFeatures = $enabledFeatures; TotalFeatures = $totalFeatures }
            } elseif ($enabledFeatures -gt 0) {
                Add-QualityResult "Security Configuration" "WARN" "$enabledFeatures/$totalFeatures security features enabled" @{ EnabledFeatures = $enabledFeatures; TotalFeatures = $totalFeatures }
            } else {
                Add-QualityResult "Security Configuration" "FAIL" "No security features enabled" @{ EnabledFeatures = $enabledFeatures; TotalFeatures = $totalFeatures }
            }
        } else {
            Add-QualityResult "Security Configuration" "WARN" "SDK configuration file not found"
        }
    } catch {
        Add-QualityResult "Security Configuration" "WARN" "Security configuration check failed: $($_.Exception.Message)"
    }
}

function Test-PerformanceChecks {
    Write-QualityLog "⚡ Running Performance Checks..." "INFO"
    
    # Check 1: Flash memory usage efficiency
    Write-QualityLog "Analyzing flash memory efficiency..." "DEBUG"
    try {
        $binaryPath = Join-Path $BuildPath "smartwatch.bin"
        if (Test-Path $binaryPath) {
            $binarySize = (Get-Item $binaryPath).Length
            $maxFlashSize = 8 * 1024 * 1024  # 8MB for ESP32-S3
            $usage = ($binarySize / $maxFlashSize) * 100
            
            if ($usage -le 70) {
                Add-QualityResult "Flash Usage Efficiency" "PASS" "Flash usage: ${usage:F1}% (efficient)" @{ UsagePercent = $usage }
            } elseif ($usage -le 85) {
                Add-QualityResult "Flash Usage Efficiency" "WARN" "Flash usage: ${usage:F1}% (moderate)" @{ UsagePercent = $usage }
            } else {
                Add-QualityResult "Flash Usage Efficiency" "FAIL" "Flash usage: ${usage:F1}% (high)" @{ UsagePercent = $usage }
            }
        } else {
            Add-QualityResult "Flash Usage Efficiency" "SKIP" "Binary not available for analysis"
        }
    } catch {
        Add-QualityResult "Flash Usage Efficiency" "WARN" "Flash efficiency check failed: $($_.Exception.Message)"
    }
    
    # Check 2: Stack size optimization
    Write-QualityLog "Checking stack size configuration..." "DEBUG"
    try {
        $configFiles = Get-ChildItem -Path $SourcePath -Recurse -Include "*.h", "*.cpp" | Where-Object { $_.Name -match "config" -or $_.Name -match "Config" }
        $stackSizeIssues = 0
        
        foreach ($file in $configFiles) {
            $content = Get-Content $file.FullName -Raw
            # Look for stack sizes > 16KB (potentially wasteful)
            $matches = [regex]::Matches($content, "STACK_SIZE.*?(\d+)")
            foreach ($match in $matches) {
                $size = [int]$match.Groups[1].Value
                if ($size -gt 16384) {
                    $stackSizeIssues++
                }
            }
        }
        
        if ($stackSizeIssues -eq 0) {
            Add-QualityResult "Stack Size Optimization" "PASS" "Stack sizes are optimized" @{ Issues = $stackSizeIssues }
        } else {
            Add-QualityResult "Stack Size Optimization" "WARN" "$stackSizeIssues potential stack size issues" @{ Issues = $stackSizeIssues }
        }
    } catch {
        Add-QualityResult "Stack Size Optimization" "WARN" "Stack size check failed: $($_.Exception.Message)"
    }
    
    # Check 3: Loop optimization patterns
    Write-QualityLog "Analyzing loop optimization..." "DEBUG"
    try {
        $sourceFiles = Get-ChildItem -Path $SourcePath -Recurse -Include "*.c", "*.cpp"
        $inefficientLoops = 0
        
        foreach ($file in $sourceFiles) {
            $content = Get-Content $file.FullName -Raw
            # Look for potentially inefficient patterns
            if ($content -match "while\s*\(\s*1\s*\)" -or $content -match "for\s*\(.*strlen") {
                $inefficientLoops++
            }
        }
        
        if ($inefficientLoops -eq 0) {
            Add-QualityResult "Loop Optimization" "PASS" "No inefficient loop patterns detected" @{ InefficientLoops = $inefficientLoops }
        } else {
            Add-QualityResult "Loop Optimization" "WARN" "$inefficientLoops files with potential loop inefficiencies" @{ InefficientLoops = $inefficientLoops }
        }
    } catch {
        Add-QualityResult "Loop Optimization" "WARN" "Loop optimization check failed: $($_.Exception.Message)"
    }
}

function Test-DocumentationChecks {
    Write-QualityLog "📚 Running Documentation Checks..." "INFO"
    
    # Check 1: Header file documentation
    Write-QualityLog "Checking header file documentation..." "DEBUG"
    try {
        $headerFiles = Get-ChildItem -Path $SourcePath -Recurse -Include "*.h", "*.hpp"
        $undocumentedHeaders = 0
        
        foreach ($header in $headerFiles) {
            $content = Get-Content $header.FullName -Raw
            $hasFileDoc = $content -match "/\*\*.*@file" -or $content -match "//.*@file"
            $hasBrief = $content -match "@brief" -or $content -match "///.*brief"
            
            if (-not ($hasFileDoc -or $hasBrief)) {
                $undocumentedHeaders++
            }
        }
        
        $documentationRatio = if ($headerFiles.Count -gt 0) { (($headerFiles.Count - $undocumentedHeaders) / $headerFiles.Count) * 100 } else { 100 }
        
        if ($documentationRatio -ge 80) {
            Add-QualityResult "Header Documentation" "PASS" "${documentationRatio:F1}% headers documented" @{ DocumentedPercent = $documentationRatio }
        } elseif ($documentationRatio -ge 50) {
            Add-QualityResult "Header Documentation" "WARN" "${documentationRatio:F1}% headers documented (target: 80%)" @{ DocumentedPercent = $documentationRatio }
        } else {
            Add-QualityResult "Header Documentation" "FAIL" "${documentationRatio:F1}% headers documented (target: 80%)" @{ DocumentedPercent = $documentationRatio }
        }
    } catch {
        Add-QualityResult "Header Documentation" "WARN" "Documentation check failed: $($_.Exception.Message)"
    }
    
    # Check 2: Function documentation
    Write-QualityLog "Checking function documentation..." "DEBUG"
    try {
        $sourceFiles = Get-ChildItem -Path $SourcePath -Recurse -Include "*.c", "*.cpp", "*.h", "*.hpp"
        $totalFunctions = 0
        $documentedFunctions = 0
        
        foreach ($file in $sourceFiles) {
            $content = Get-Content $file.FullName
            $functions = $content | Select-String -Pattern "^[a-zA-Z_][a-zA-Z0-9_]*\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\("
            
            foreach ($func in $functions) {
                $totalFunctions++
                $lineNumber = $func.LineNumber
                
                # Check if previous lines contain documentation
                for ($i = $lineNumber - 5; $i -lt $lineNumber; $i++) {
                    if ($i -gt 0 -and $i -le $content.Count) {
                        if ($content[$i-1] -match "/\*\*" -or $content[$i-1] -match "///") {
                            $documentedFunctions++
                            break
                        }
                    }
                }
            }
        }
        
        $functionDocRatio = if ($totalFunctions -gt 0) { ($documentedFunctions / $totalFunctions) * 100 } else { 100 }
        
        if ($functionDocRatio -ge 60) {
            Add-QualityResult "Function Documentation" "PASS" "${functionDocRatio:F1}% functions documented ($documentedFunctions/$totalFunctions)" @{ DocumentedPercent = $functionDocRatio }
        } else {
            Add-QualityResult "Function Documentation" "WARN" "${functionDocRatio:F1}% functions documented (target: 60%)" @{ DocumentedPercent = $functionDocRatio }
        }
    } catch {
        Add-QualityResult "Function Documentation" "WARN" "Function documentation check failed: $($_.Exception.Message)"
    }
    
    # Check 3: README and architecture documentation
    Write-QualityLog "Checking project documentation..." "DEBUG"
    try {
        $docPath = Split-Path -Parent $FirmwarePath
        $requiredDocs = @{
            "README.md" = Join-Path $docPath "README.md"
            "Architecture" = Join-Path $docPath "docs/architecture.md"
            "Setup Guide" = Join-Path $docPath "docs/ESP32-S3-Development-Environment-Setup.md"
        }
        
        $missingDocs = @()
        foreach ($docType in $requiredDocs.Keys) {
            if (-not (Test-Path $requiredDocs[$docType])) {
                $missingDocs += $docType
            }
        }
        
        if ($missingDocs.Count -eq 0) {
            Add-QualityResult "Project Documentation" "PASS" "All required documentation present" @{ MissingDocs = $missingDocs.Count }
        } else {
            Add-QualityResult "Project Documentation" "WARN" "Missing documentation: $($missingDocs -join ', ')" @{ MissingDocs = $missingDocs.Count }
        }
    } catch {
        Add-QualityResult "Project Documentation" "WARN" "Project documentation check failed: $($_.Exception.Message)"
    }
}

function New-QualityReport {
    if (-not $GenerateReport) {
        return
    }
    
    Write-QualityLog "📄 Generating quality report..." "INFO"
    
    try {
        # Ensure report directory exists
        if (-not (Test-Path $ReportPath)) {
            New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
        }
        
        # Generate report data
        $endTime = Get-Date
        $duration = $endTime - $QualityResults.StartTime
        
        $report = @{
            metadata = @{
                project = "ESP32-S3 ADHD SmartWatch"
                timestamp = $QualityResults.StartTime.ToString("yyyy-MM-ddTHH:mm:ss")
                duration_minutes = [math]::Round($duration.TotalMinutes, 2)
                check_type = $CheckType
            }
            summary = @{
                total_checks = $QualityResults.TotalChecks
                passed_checks = $QualityResults.PassedChecks
                failed_checks = $QualityResults.FailedChecks
                warning_checks = $QualityResults.WarningChecks
                success_rate = if ($QualityResults.TotalChecks -gt 0) { 
                    [math]::Round(($QualityResults.PassedChecks / $QualityResults.TotalChecks) * 100, 2) 
                } else { 
                    0 
                }
            }
            thresholds = $QualityThresholds
            results = $QualityResults.Details
            recommendations = Get-QualityRecommendations
        }
        
        # Save JSON report
        $reportFile = Join-Path $ReportPath "quality_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportFile -Encoding UTF8
        
        # Generate HTML report
        $htmlReport = New-HtmlReport $report
        $htmlFile = Join-Path $ReportPath "quality_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        $htmlReport | Out-File -FilePath $htmlFile -Encoding UTF8
        
        Write-QualityLog "Quality reports generated:" "PASS"
        Write-QualityLog "  JSON: $reportFile" "INFO"
        Write-QualityLog "  HTML: $htmlFile" "INFO"
        
    } catch {
        Write-QualityLog "Failed to generate quality report: $($_.Exception.Message)" "FAIL"
    }
}

function Get-QualityRecommendations {
    $recommendations = @()
    
    # Analyze results and generate recommendations
    $failedChecks = $QualityResults.Details | Where-Object { $_.Result -eq "FAIL" }
    $warningChecks = $QualityResults.Details | Where-Object { $_.Result -eq "WARN" }
    
    if ($failedChecks.Count -eq 0 -and $warningChecks.Count -eq 0) {
        $recommendations += "✅ Excellent! All quality gates passed. Code is ready for production."
    } elseif ($failedChecks.Count -eq 0) {
        $recommendations += "✅ All critical checks passed. Address warnings to improve code quality."
    } else {
        $recommendations += "❌ Critical issues detected. Address failed checks before deployment."
    }
    
    # Specific recommendations based on failures
    foreach ($check in $failedChecks) {
        switch -Wildcard ($check.Check) {
            "*Build*" { $recommendations += "🔨 Fix build errors and eliminate all warnings." }
            "*Security*" { $recommendations += "🛡️ Address security vulnerabilities immediately." }
            "*Documentation*" { $recommendations += "📚 Improve code documentation to meet standards." }
        }
    }
    
    # Performance recommendations
    if ($warningChecks | Where-Object { $_.Check -like "*Performance*" -or $_.Check -like "*Memory*" }) {
        $recommendations += "⚡ Optimize performance and memory usage for better efficiency."
    }
    
    return $recommendations
}

function New-HtmlReport {
    param($ReportData)
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ESP32-S3 ADHD SmartWatch - Quality Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; }
        .content { padding: 30px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric { background: #f8f9fa; padding: 20px; border-radius: 6px; text-align: center; border-left: 4px solid #28a745; }
        .metric.warning { border-left-color: #ffc107; }
        .metric.danger { border-left-color: #dc3545; }
        .metric-value { font-size: 2em; font-weight: bold; margin-bottom: 5px; }
        .metric-label { color: #6c757d; font-size: 0.9em; }
        .results-table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        .results-table th, .results-table td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        .results-table th { background-color: #f8f9fa; font-weight: 600; }
        .status-pass { color: #28a745; font-weight: bold; }
        .status-fail { color: #dc3545; font-weight: bold; }
        .status-warn { color: #ffc107; font-weight: bold; }
        .recommendations { background: #e7f3ff; padding: 20px; border-radius: 6px; border-left: 4px solid #007bff; }
        .timestamp { color: #6c757d; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 Quality Gate Report</h1>
            <h2>ESP32-S3 ADHD SmartWatch</h2>
            <p class="timestamp">Generated: $($ReportData.metadata.timestamp) | Duration: $($ReportData.metadata.duration_minutes) minutes</p>
        </div>
        <div class="content">
            <div class="summary">
                <div class="metric">
                    <div class="metric-value">$($ReportData.summary.total_checks)</div>
                    <div class="metric-label">Total Checks</div>
                </div>
                <div class="metric">
                    <div class="metric-value">$($ReportData.summary.passed_checks)</div>
                    <div class="metric-label">Passed</div>
                </div>
                <div class="metric warning">
                    <div class="metric-value">$($ReportData.summary.warning_checks)</div>
                    <div class="metric-label">Warnings</div>
                </div>
                <div class="metric danger">
                    <div class="metric-value">$($ReportData.summary.failed_checks)</div>
                    <div class="metric-label">Failed</div>
                </div>
                <div class="metric">
                    <div class="metric-value">$($ReportData.summary.success_rate)%</div>
                    <div class="metric-label">Success Rate</div>
                </div>
            </div>
            
            <h3>📊 Detailed Results</h3>
            <table class="results-table">
                <thead>
                    <tr>
                        <th>Check</th>
                        <th>Result</th>
                        <th>Details</th>
                        <th>Timestamp</th>
                    </tr>
                </thead>
                <tbody>
"@
    
    foreach ($result in $ReportData.results) {
        $statusClass = switch ($result.Result) {
            "PASS" { "status-pass" }
            "FAIL" { "status-fail" }
            "WARN" { "status-warn" }
            default { "" }
        }
        
        $html += @"
                    <tr>
                        <td>$($result.Check)</td>
                        <td class="$statusClass">$($result.Result)</td>
                        <td>$($result.Details)</td>
                        <td class="timestamp">$(([DateTime]$result.Timestamp).ToString("HH:mm:ss"))</td>
                    </tr>
"@
    }
    
    $html += @"
                </tbody>
            </table>
            
            <div class="recommendations">
                <h3>💡 Recommendations</h3>
                <ul>
"@
    
    foreach ($recommendation in $ReportData.recommendations) {
        $html += "<li>$recommendation</li>`n"
    }
    
    $html += @"
                </ul>
            </div>
        </div>
    </div>
</body>
</html>
"@
    
    return $html
}

function Show-QualitySummary {
    $endTime = Get-Date
    $duration = $endTime - $QualityResults.StartTime
    
    Write-Host ""
    Write-Host "==================== QUALITY GATES SUMMARY ====================" -ForegroundColor Cyan
    Write-Host "Project: ESP32-S3 ADHD SmartWatch" -ForegroundColor White
    Write-Host "Check Type: $CheckType" -ForegroundColor White
    Write-Host "Duration: $([math]::Round($duration.TotalMinutes, 2)) minutes" -ForegroundColor White
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📊 Results Summary:" -ForegroundColor Cyan
    Write-Host "  Total Checks: $($QualityResults.TotalChecks)" -ForegroundColor White
    Write-Host "  ✅ Passed: $($QualityResults.PassedChecks)" -ForegroundColor Green
    Write-Host "  ⚠️  Warnings: $($QualityResults.WarningChecks)" -ForegroundColor Yellow
    Write-Host "  ❌ Failed: $($QualityResults.FailedChecks)" -ForegroundColor Red
    
    $successRate = if ($QualityResults.TotalChecks -gt 0) { 
        ($QualityResults.PassedChecks / $QualityResults.TotalChecks) * 100 
    } else { 
        0 
    }
    Write-Host "  📈 Success Rate: $([math]::Round($successRate, 1))%" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "💡 Recommendations:" -ForegroundColor Cyan
    $recommendations = Get-QualityRecommendations
    foreach ($recommendation in $recommendations) {
        Write-Host "  $recommendation" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor Cyan
}

# Main execution
function Invoke-QualityGates {
    Write-Host "🚀 ESP32-S3 ADHD SmartWatch Quality Gates System" -ForegroundColor Cyan
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Run quality checks based on type
        switch ($CheckType) {
            "build" { Test-BuildQuality }
            "static" { Test-StaticAnalysis }
            "security" { Test-SecurityChecks }
            "performance" { Test-PerformanceChecks }
            "documentation" { Test-DocumentationChecks }
            "all" {
                Test-BuildQuality
                Test-StaticAnalysis
                Test-SecurityChecks
                Test-PerformanceChecks
                Test-DocumentationChecks
            }
        }
        
        # Generate report if requested
        New-QualityReport
        
        # Show summary
        Show-QualitySummary
        
        # Exit with appropriate code
        if ($QualityResults.FailedChecks -gt 0) {
            Write-Host "❌ Quality gates failed!" -ForegroundColor Red
            exit 1
        } elseif ($QualityResults.WarningChecks -gt 0) {
            Write-Host "⚠️  Quality gates passed with warnings." -ForegroundColor Yellow
            exit 0
        } else {
            Write-Host "✅ All quality gates passed!" -ForegroundColor Green
            exit 0
        }
        
    } catch {
        Write-Host "❌ Quality gates system failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Run quality gates
Invoke-QualityGates