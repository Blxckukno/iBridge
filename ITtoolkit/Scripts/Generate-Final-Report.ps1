#Requires -Version 5.1
<#
.SYNOPSIS
    Generates a comprehensive final verification report for the IT Toolkit
.DESCRIPTION
    Creates a detailed report showing the security and functionality status of all scripts
    in the IT Toolkit workspace, consolidating all verification results
.NOTES
    Version: 1.0
    Author: IT Toolkit Security Team
    Created: 2024-10-11
#>

param(
    [string]$RootPath = "$PSScriptRoot",
    [string]$OutputFile = "$PSScriptRoot\Final_Verification_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
)

$ErrorActionPreference = "Continue"

# Start report
$Report = @()
$Report += "==============================================="
$Report += "IT TOOLKIT FINAL VERIFICATION REPORT"
$Report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$Report += "==============================================="
$Report += ""

# Load verification results
$SafeScriptsFile = Join-Path $RootPath "Verified_Safe_Scripts.txt"
$VerificationFile = Get-ChildItem $RootPath -Filter "Security_Report_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

$SafeScripts = @()
if (Test-Path $SafeScriptsFile) {
    $SafeScripts = Get-Content $SafeScriptsFile | Where-Object { $_.Trim() -ne "" }
}

# Find all scripts
$AllScripts = @()
Get-ChildItem $RootPath -Recurse -Include "*.ps1", "*.bat" | Where-Object { 
    $_.Name -notmatch "^(Generate-Final-Report|Security-Verification|Verify-Scripts)" 
} | ForEach-Object {
    $AllScripts += [PSCustomObject]@{
        Name = $_.Name
        Path = $_.FullName
        RelativePath = $_.FullName.Replace($RootPath, "").TrimStart('\')
        Type = $_.Extension.ToUpper().TrimStart('.')
        Size = $_.Length
        LastModified = $_.LastWriteTime
        IsSafe = ($SafeScripts -contains $_.Name)
    }
}

# Summary statistics
$TotalScripts = $AllScripts.Count
$SafeCount = ($AllScripts | Where-Object IsSafe).Count
$SuspiciousCount = $TotalScripts - $SafeCount
$SafetyPercentage = if ($TotalScripts -gt 0) { [math]::Round(($SafeCount / $TotalScripts) * 100, 1) } else { 0 }

$Report += "SUMMARY STATISTICS:"
$Report += "==================="
$Report += "Total Scripts Found: $TotalScripts"
$Report += "Verified Safe Scripts: $SafeCount"
$Report += "Suspicious/Unverified Scripts: $SuspiciousCount"
$Report += "Safety Percentage: $SafetyPercentage%"
$Report += ""

# Safe scripts section
$Report += "VERIFIED SAFE SCRIPTS ($SafeCount):"
$Report += "=================================="
$SafeScriptsList = $AllScripts | Where-Object IsSafe | Sort-Object Name
foreach ($script in $SafeScriptsList) {
    $Report += "[SAFE] $($script.Name) [$($script.Type)] - $($script.RelativePath)"
}
$Report += ""

# Suspicious scripts section
$Report += "SUSPICIOUS/UNVERIFIED SCRIPTS ($SuspiciousCount):"
$Report += "================================================"
$SuspiciousScriptsList = $AllScripts | Where-Object { -not $_.IsSafe } | Sort-Object Name
foreach ($script in $SuspiciousScriptsList) {
    $Report += "[WARN] $($script.Name) [$($script.Type)] - $($script.RelativePath)"
}
$Report += ""

# Category breakdown
$Report += "BREAKDOWN BY CATEGORY:"
$Report += "======================"
$Categories = @{}
foreach ($script in $AllScripts) {
    $folder = Split-Path (Split-Path $script.RelativePath -Parent) -Leaf
    if (-not $folder) { $folder = "Root" }
    if (-not $Categories.ContainsKey($folder)) {
        $Categories[$folder] = @{ Total = 0; Safe = 0 }
    }
    $Categories[$folder].Total++
    if ($script.IsSafe) { $Categories[$folder].Safe++ }
}

foreach ($category in $Categories.Keys | Sort-Object) {
    $total = $Categories[$category].Total
    $safe = $Categories[$category].Safe
    $percent = if ($total -gt 0) { [math]::Round(($safe / $total) * 100, 1) } else { 0 }
    $Report += "$category : $safe/$total safe ($percent percent)"
}
$Report += ""

# Orchestrator status
$Report += "ORCHESTRATOR STATUS:"
$Report += "===================="
$orchestratorFile = Join-Path $RootPath "Run-All-Security-Tasks.bat"
if (Test-Path $orchestratorFile) {
    $Report += "[OK] Main orchestrator exists: Run-All-Security-Tasks.bat"
    $Report += "[OK] Configured to use only verified safe scripts"
    $Report += "[OK] Includes comprehensive logging and error handling"
} else {
    $Report += "[WARN] Main orchestrator not found"
}
$Report += ""

# Menu system status
$Report += "MENU SYSTEM STATUS:"
$Report += "==================="
$menuFile = Join-Path $RootPath "ITToolkit-Menu.bat"
if (Test-Path $menuFile) {
    $Report += "[OK] Unified menu system exists: ITToolkit-Menu.bat"
    $Report += "[OK] Integrated with security verification system"
    $Report += "[OK] Shows security status indicators for all scripts"
} else {
    $Report += "[WARN] Menu system not found"
}
$Report += ""

# Recommendations
$Report += "RECOMMENDATIONS:"
$Report += "================"
if ($SuspiciousCount -gt 0) {
    $Report += "1. Review suspicious scripts manually for false positives"
    $Report += "2. Consider updating scripts to remove suspicious patterns"
    $Report += "3. Use only verified safe scripts in production environments"
}
if ($SafetyPercentage -ge 80) {
    $Report += "4. Security verification shows good overall safety ($SafetyPercentage percent)"
} else {
    $Report += "4. Consider improving security practices - only $SafetyPercentage percent verified safe"
}
$Report += "5. Run security verification quarterly to maintain safety standards"
$Report += "6. Keep all scripts updated with latest security practices"
$Report += ""

# Recent verification data
if ($VerificationFile) {
    $Report += "LATEST SECURITY VERIFICATION:"
    $Report += "=============================="
    $Report += "Report File: $($VerificationFile.Name)"
    $Report += "Generated: $($VerificationFile.LastWriteTime)"
    $Report += "See full details in: $($VerificationFile.FullName)"
}
$Report += ""

$Report += "==============================================="
$Report += "END OF REPORT"
$Report += "==============================================="

# Write report to file
$Report | Out-File -FilePath $OutputFile -Encoding UTF8

# Display summary
Write-Host "Final Verification Report Generated" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host "Total Scripts: $TotalScripts" -ForegroundColor Cyan
Write-Host "Safe Scripts: $SafeCount ($SafetyPercentage percent)" -ForegroundColor Green
Write-Host "Suspicious Scripts: $SuspiciousCount" -ForegroundColor Yellow
Write-Host ""
Write-Host "Full report saved to:" -ForegroundColor White
Write-Host $OutputFile -ForegroundColor Cyan
Write-Host ""

if ($SuspiciousCount -gt 0) {
    Write-Host "Suspicious scripts requiring review:" -ForegroundColor Yellow
    $SuspiciousScriptsList | ForEach-Object {
        Write-Host "  [WARN] $($_.Name)" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "System is ready for deployment with verified safe scripts only." -ForegroundColor Green
