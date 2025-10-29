# Run All Security Scripts - Comprehensive System Check and Fix
# Executes all fixed scripts sequentially to check and fix Windows device issues

param(
    [switch]$Detailed,
    [switch]$GenerateReport
)

Write-Host "=" * 80
Write-Host "           COMPREHENSIVE SYSTEM CHECK AND FIX" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "=" * 80
Write-Host "Running ALL fixed security and maintenance scripts..." -ForegroundColor Cyan
Write-Host "This will check and fix all issues found on your Windows device." -ForegroundColor Yellow
Write-Host ""

$ExecutionResults = @{
    Successful = @()
    Failed = @()
    Warnings = @()
    TotalRun = 0
    StartTime = Get-Date
}

function Write-Progress {
    param([string]$ScriptName, [int]$Current, [int]$Total, [string]$Status = "Running")
    $percent = [math]::Round(($Current / $Total) * 100)
    Write-Host "[$Current/$Total] ($percent%) $Status : $ScriptName" -ForegroundColor $(if($Status -eq "SUCCESS") {"Green"} elseif($Status -eq "FAILED") {"Red"} else {"Yellow"})
}

function Run-SecurityScript {
    param([string]$ScriptPath, [string]$ScriptName)
    
    try {
        if (Test-Path $ScriptPath) {
            Write-Progress $ScriptName ($ExecutionResults.TotalRun + 1) 8 "Running"
            
            $result = & powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0 -or $exitCode -eq $null) {
                $ExecutionResults.Successful += $ScriptName
                Write-Progress $ScriptName ($ExecutionResults.TotalRun + 1) 8 "SUCCESS"
            } else {
                $ExecutionResults.Failed += "$ScriptName (Exit Code: $exitCode)"
                Write-Progress $ScriptName ($ExecutionResults.TotalRun + 1) 8 "FAILED"
            }
            
            $ExecutionResults.TotalRun++
            Start-Sleep -Seconds 2
            return $true
        } else {
            $ExecutionResults.Failed += "$ScriptName (File not found)"
            Write-Progress $ScriptName ($ExecutionResults.TotalRun + 1) 8 "FAILED"
            $ExecutionResults.TotalRun++
            return $false
        }
    } catch {
        $ExecutionResults.Failed += "$ScriptName (Error: $($_.Message))"
        Write-Progress $ScriptName ($ExecutionResults.TotalRun + 1) 8 "FAILED"
        $ExecutionResults.TotalRun++
        return $false
    }
}

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Starting comprehensive system analysis and fixes..." -ForegroundColor Green
Write-Host ""

# Define all fixed scripts to run in order
$ScriptsToRun = @(
    @{
        Path = "$ScriptDir\Security\Defender-Optimizer-Fixed.ps1"
        Name = "Windows Defender Optimizer"
        Description = "Optimizes Windows Defender settings and performance"
    },
    @{
        Path = "$ScriptDir\Security\Master-Security-Verification-Fixed.ps1"
        Name = "Master Security Verification"
        Description = "Comprehensive security assessment across all domains"
    },
    @{
        Path = "$ScriptDir\Security\Email-Security-Analysis-Fixed.ps1"
        Name = "Email Security Analysis"
        Description = "Analyzes email security configurations and threats"
    },
    @{
        Path = "$ScriptDir\Security\Anti-Phishing-Email-Protection-Fixed.ps1"
        Name = "Anti-Phishing Email Protection"
        Description = "Enables anti-phishing protection for email systems"
    },
    @{
        Path = "$ScriptDir\Security\Email-Account-Audit-Fixed.ps1"
        Name = "Email Account Security Audit"
        Description = "Audits email account security settings"
    },
    @{
        Path = "$ScriptDir\Security\Emergency-Isolation-Fixed.ps1"
        Name = "Emergency System Isolation"
        Description = "Checks and configures emergency isolation procedures"
    },
    @{
        Path = "$ScriptDir\Security\Real-Time-Monitor-Fixed.ps1"
        Name = "Real-Time Security Monitor"
        Description = "Monitors real-time security events and threats"
    },
    @{
        Path = "$ScriptDir\Maintenance_Cleanup\Analyze-Cleanup-Fixed.ps1"
        Name = "System Cleanup Analysis"
        Description = "Analyzes system for cleanup opportunities and optimizations"
    }
)

# Execute all scripts
foreach ($Script in $ScriptsToRun) {
    Write-Host ""
    Write-Host "EXECUTING: $($Script.Name)" -ForegroundColor White -BackgroundColor DarkGreen
    Write-Host "Purpose: $($Script.Description)" -ForegroundColor Gray
    Write-Host "-" * 60
    
    Run-SecurityScript -ScriptPath $Script.Path -ScriptName $Script.Name
    
    Write-Host ""
}

# Calculate execution time
$ExecutionResults.EndTime = Get-Date
$ExecutionTime = $ExecutionResults.EndTime - $ExecutionResults.StartTime

Write-Host ""
Write-Host "=" * 80
Write-Host "           COMPREHENSIVE SYSTEM CHECK COMPLETED" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "=" * 80

Write-Host ""
Write-Host "EXECUTION SUMMARY:" -ForegroundColor Cyan
Write-Host "Total Scripts Run: $($ExecutionResults.TotalRun)" -ForegroundColor White
Write-Host "Successful: $($ExecutionResults.Successful.Count)" -ForegroundColor Green
Write-Host "Failed: $($ExecutionResults.Failed.Count)" -ForegroundColor Red
Write-Host "Execution Time: $($ExecutionTime.ToString('mm\:ss'))" -ForegroundColor Yellow

$SuccessRate = if ($ExecutionResults.TotalRun -gt 0) { 
    [math]::Round(($ExecutionResults.Successful.Count / $ExecutionResults.TotalRun) * 100, 1) 
} else { 0 }

Write-Host "Success Rate: $SuccessRate%" -ForegroundColor $(if ($SuccessRate -ge 80) {"Green"} elseif ($SuccessRate -ge 60) {"Yellow"} else {"Red"})

if ($ExecutionResults.Successful.Count -gt 0) {
    Write-Host ""
    Write-Host "SUCCESSFULLY EXECUTED SCRIPTS:" -ForegroundColor Green
    foreach ($script in $ExecutionResults.Successful) {
        Write-Host "  [SUCCESS] $script" -ForegroundColor DarkGreen
    }
}

if ($ExecutionResults.Failed.Count -gt 0) {
    Write-Host ""
    Write-Host "FAILED SCRIPTS:" -ForegroundColor Red
    foreach ($script in $ExecutionResults.Failed) {
        Write-Host "  [FAILED] $script" -ForegroundColor DarkRed
    }
}

# Generate comprehensive report if requested
if ($GenerateReport -or $ExecutionResults.Failed.Count -gt 0) {
    $ReportPath = "Comprehensive_System_Check_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $Report = @"
COMPREHENSIVE SYSTEM CHECK AND FIX REPORT
Generated: $(Get-Date)
Execution Time: $($ExecutionTime.ToString('hh\:mm\:ss'))
Computer: $env:COMPUTERNAME
User: $env:USERNAME

SUMMARY:
========
Total Scripts Executed: $($ExecutionResults.TotalRun)
Successful Executions: $($ExecutionResults.Successful.Count)
Failed Executions: $($ExecutionResults.Failed.Count)
Success Rate: $SuccessRate%

SUCCESSFUL SCRIPTS:
==================
$(if ($ExecutionResults.Successful.Count -gt 0) {
    ($ExecutionResults.Successful | ForEach-Object { "[SUCCESS] $_" }) -join "`n"
} else {
    "None"
})

FAILED SCRIPTS:
==============
$(if ($ExecutionResults.Failed.Count -gt 0) {
    ($ExecutionResults.Failed | ForEach-Object { "[FAILED] $_" }) -join "`n"
} else {
    "None"
})

SCRIPTS EXECUTED IN ORDER:
=========================
$(($ScriptsToRun | ForEach-Object { 
    $status = if ($ExecutionResults.Successful -contains $_.Name) { "SUCCESS" } else { "FAILED" }
    "[$status] $($_.Name) - $($_.Description)"
}) -join "`n")

RECOMMENDATIONS:
===============
$(if ($ExecutionResults.Failed.Count -eq 0) {
    "✓ All security and maintenance scripts executed successfully
✓ Your system has been comprehensively checked and optimized
✓ Continue regular maintenance using individual scripts as needed
✓ Monitor system performance and security status regularly"
} else {
    "⚠ Some scripts failed to execute properly
⚠ Check failed scripts manually for specific issues
⚠ Ensure administrator privileges for security scripts
⚠ Review individual script logs for detailed error information
⚠ Consider running failed scripts individually to troubleshoot"
})

NEXT STEPS:
===========
1. Review any failed script executions above
2. Run individual scripts for detailed analysis if needed
3. Check Windows Updates and install pending updates
4. Restart system if security changes were applied
5. Schedule regular execution of this comprehensive check

Generated by IT Toolkit - Comprehensive System Check
"@

    $Report | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host ""
    Write-Host "Comprehensive report saved to: $ReportPath" -ForegroundColor Yellow
}

Write-Host ""
if ($SuccessRate -eq 100) {
    Write-Host "🎉 EXCELLENT! All system checks and fixes completed successfully!" -ForegroundColor Green
    Write-Host "Your Windows device has been comprehensively analyzed and optimized." -ForegroundColor Green
} elseif ($SuccessRate -ge 80) {
    Write-Host "✅ GOOD! Most system checks completed successfully." -ForegroundColor Yellow
    Write-Host "Review any failed scripts and run them individually if needed." -ForegroundColor Yellow
} else {
    Write-Host "⚠️ WARNING! Several scripts failed to execute." -ForegroundColor Red
    Write-Host "Check the report for details and run scripts individually." -ForegroundColor Red
}

Write-Host ""
Write-Host "System analysis and fixes completed. Press any key to continue..." -ForegroundColor Cyan

exit $(if ($SuccessRate -eq 100) { 0 } else { 1 })
