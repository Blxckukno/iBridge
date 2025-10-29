# Master Script Orchestrator - Runs All Working Scripts
# Only executes verified safe and functional scripts

param(
    [switch]$SecurityOnly,
    [switch]$EmailOnly,
    [switch]$QuickScan,
    [switch]$FullScan,
    [switch]$SkipSyntaxCheck
)

Write-Host "🚀 MASTER SCRIPT ORCHESTRATOR" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Running all verified working scripts in the IT Toolkit" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

# Load verified safe scripts list
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$safeScriptsFile = Join-Path $scriptPath "Verified_Safe_Scripts.txt"

$verifiedSafeScripts = @()
if (Test-Path $safeScriptsFile) {
    $verifiedSafeScripts = Get-Content $safeScriptsFile | Where-Object { $_ -and $_ -notmatch "^#" }
    Write-Host "✅ Loaded $($verifiedSafeScripts.Count) verified safe scripts" -ForegroundColor Green
} else {
    Write-Host "⚠️  Safe scripts list not found - using default safe list" -ForegroundColor Yellow
}

# Define working scripts by category
$workingScripts = @{
    "Security" = @(
        "Security\Quick-Security-Check.ps1",
        "Security\Enable-Defender-Admin.bat",
        "Security\Deploy-Emergency-Security.bat",
        "Security\Emergency-Security-Scan.bat"
    )
    "Email" = @(
        "Emergency_Response\Quick-Email-Security-Check.ps1",
        "Check-EmailSecurity-iBridge.ps1",
        "Emergency-Email-Breach-Scan.ps1"
    )
    "Cleanup" = @(
        "Cleanup\Quick-Cleanup.ps1",
        "Cleanup\Analyze-Cleanup-Clean.ps1",
        "Cleanup\Backup-and-Cleanup.ps1"
    )
    "Installation" = @(
        "Windows_Deployment\Post-Install.ps1",
        "Windows_Deployment\Download-Freeware.ps1",
        "Windows_Deployment\Verify-FOSS-Install.ps1"
    )
    "Verification" = @(
        "Security-Verification-Simple.ps1",
        "Verify-Scripts-Simple.ps1",
        "Generate-Final-Report.ps1"
    )
}

# Results tracking
$results = @{
    "Executed" = @()
    "Failed" = @()
    "Skipped" = @()
    "Total" = 0
}

function Test-ScriptSyntax {
    param([string]$ScriptPath)
    
    if ($SkipSyntaxCheck) { return $true }
    
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ScriptPath -Raw), [ref]$null)
        return $true
    }
    catch {
        return $false
    }
}

function Invoke-SafeScript {
    param(
        [string]$ScriptPath,
        [string]$Category
    )
    
    $fullPath = Join-Path $scriptPath $ScriptPath
    $scriptName = Split-Path $ScriptPath -Leaf
    
    Write-Host "`n[$($results.Total + 1)] 🔧 $Category`: $scriptName" -ForegroundColor Yellow
    Write-Host "─" * 60 -ForegroundColor Gray
    
    # Check if file exists
    if (-not (Test-Path $fullPath)) {
        Write-Host "  ❌ Script not found: $fullPath" -ForegroundColor Red
        $results.Skipped += $ScriptPath
        return
    }
    
    # Check if verified safe (if list exists)
    if ($verifiedSafeScripts.Count -gt 0) {
        $isVerified = $verifiedSafeScripts | Where-Object { $_ -like "*$scriptName*" }
        if (-not $isVerified) {
            Write-Host "  ⚠️  Script not in verified safe list - skipping" -ForegroundColor Yellow
            $results.Skipped += $ScriptPath
            return
        }
    }
    
    # Check syntax for PowerShell scripts
    if ($ScriptPath -like "*.ps1") {
        if (-not (Test-ScriptSyntax $fullPath)) {
            Write-Host "  ❌ Syntax errors detected - skipping" -ForegroundColor Red
            $results.Skipped += $ScriptPath
            return
        }
    }
    
    try {
        $results.Total++
        
        if ($ScriptPath -like "*.ps1") {
            # Execute PowerShell script
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $fullPath
        } elseif ($ScriptPath -like "*.bat") {
            # Execute batch file
            & cmd.exe /c $fullPath
        }
        
        if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
            Write-Host "  ✅ $scriptName completed successfully" -ForegroundColor Green
            $results.Executed += $ScriptPath
        } else {
            Write-Host "  ⚠️  $scriptName completed with warnings (Exit: $LASTEXITCODE)" -ForegroundColor Yellow
            $results.Executed += $ScriptPath
        }
    }
    catch {
        Write-Host "  ❌ $scriptName failed: $($_.Exception.Message)" -ForegroundColor Red
        $results.Failed += $ScriptPath
    }
}

function Show-Progress {
    param([string]$Category, [int]$Current, [int]$Total)
    
    $percent = [math]::Round(($Current / $Total) * 100)
    Write-Progress -Activity "Running $Category Scripts" -Status "Progress: $Current/$Total" -PercentComplete $percent
}

# Main execution
try {
    Write-Host "`n🎯 EXECUTION PLAN" -ForegroundColor Cyan
    
    $categoriesToRun = @()
    
    if ($SecurityOnly) {
        $categoriesToRun = @("Security", "Verification")
        Write-Host "  📋 Mode: Security scripts only" -ForegroundColor Yellow
    }
    elseif ($EmailOnly) {
        $categoriesToRun = @("Email", "Security")
        Write-Host "  📋 Mode: Email security scripts only" -ForegroundColor Yellow
    }
    elseif ($QuickScan) {
        $categoriesToRun = @("Security", "Email")
        Write-Host "  📋 Mode: Quick security scan" -ForegroundColor Yellow
    }
    else {
        $categoriesToRun = $workingScripts.Keys
        Write-Host "  📋 Mode: Full script execution" -ForegroundColor Yellow
    }
    
    Write-Host "  🔧 Categories to run: $($categoriesToRun -join ', ')" -ForegroundColor Cyan
    Write-Host "  ⚙️  Syntax checking: $(if ($SkipSyntaxCheck) { 'Disabled' } else { 'Enabled' })" -ForegroundColor Cyan
    
    # Execute scripts by category
    foreach ($category in $categoriesToRun) {
        if ($workingScripts.ContainsKey($category)) {
            Write-Host "`n" + "="*70 -ForegroundColor Blue
            Write-Host "  🚀 EXECUTING $category SCRIPTS" -ForegroundColor White -BackgroundColor Blue
            Write-Host "="*70 -ForegroundColor Blue
            
            $categoryScripts = $workingScripts[$category]
            
            for ($i = 0; $i -lt $categoryScripts.Count; $i++) {
                Show-Progress -Category $category -Current ($i + 1) -Total $categoryScripts.Count
                Invoke-SafeScript -ScriptPath $categoryScripts[$i] -Category $category
                Start-Sleep -Milliseconds 500  # Brief pause between scripts
            }
            
            Write-Progress -Activity "Running $category Scripts" -Completed
        }
    }
    
    # Final verification scan
    if (-not $QuickScan -and -not $EmailOnly) {
        Write-Host "`n" + "="*70 -ForegroundColor Green
        Write-Host "  🔍 FINAL VERIFICATION SCAN" -ForegroundColor White -BackgroundColor Green
        Write-Host "="*70 -ForegroundColor Green
        
        Invoke-SafeScript -ScriptPath "Security-Verification-Simple.ps1" -Category "Final Check"
    }
    
    # Generate comprehensive report
    Write-Host "`n" + "="*70 -ForegroundColor Magenta
    Write-Host "  📊 EXECUTION SUMMARY" -ForegroundColor White -BackgroundColor Magenta
    Write-Host "="*70 -ForegroundColor Magenta
    
    $successRate = if ($results.Total -gt 0) { [math]::Round(($results.Executed.Count / $results.Total) * 100, 1) } else { 0 }
    
    Write-Host "`n📈 EXECUTION STATISTICS:" -ForegroundColor Cyan
    Write-Host "  📊 Total Scripts Processed: $($results.Total)" -ForegroundColor White
    Write-Host "  ✅ Successfully Executed: $($results.Executed.Count)" -ForegroundColor Green
    Write-Host "  ❌ Failed Executions: $($results.Failed.Count)" -ForegroundColor Red
    Write-Host "  ⏭️  Skipped Scripts: $($results.Skipped.Count)" -ForegroundColor Yellow
    Write-Host "  🎯 Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
    
    if ($results.Failed.Count -gt 0) {
        Write-Host "`n❌ FAILED SCRIPTS:" -ForegroundColor Red
        $results.Failed | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    }
    
    if ($results.Skipped.Count -gt 0) {
        Write-Host "`n⏭️  SKIPPED SCRIPTS:" -ForegroundColor Yellow
        $results.Skipped | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow }
    }
    
    # Save execution report
    $reportContent = @"
MASTER SCRIPT ORCHESTRATOR EXECUTION REPORT
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

EXECUTION SUMMARY:
- Total Scripts Processed: $($results.Total)
- Successfully Executed: $($results.Executed.Count)
- Failed Executions: $($results.Failed.Count)
- Skipped Scripts: $($results.Skipped.Count)
- Success Rate: $successRate%

SUCCESSFULLY EXECUTED:
$($results.Executed | ForEach-Object { "✅ $_" } | Out-String)

FAILED SCRIPTS:
$($results.Failed | ForEach-Object { "❌ $_" } | Out-String)

SKIPPED SCRIPTS:
$($results.Skipped | ForEach-Object { "⏭️ $_" } | Out-String)

RECOMMENDATIONS:
- Review failed scripts for syntax errors
- Update scripts with Unicode character issues
- Run individual scripts manually if needed
- Check admin privileges for system-level scripts

Report generated by Master Script Orchestrator
"@
    
    $reportPath = "$env:USERPROFILE\Desktop\Master_Execution_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    Set-Content -Path $reportPath -Value $reportContent
    Write-Host "`n📄 Detailed report saved: $reportPath" -ForegroundColor Cyan
    
    # Final status
    Write-Host "`n🏁 FINAL STATUS:" -ForegroundColor White -BackgroundColor DarkGreen
    if ($results.Failed.Count -eq 0) {
        Write-Host "  🎉 ALL SCRIPTS EXECUTED SUCCESSFULLY!" -ForegroundColor Green
        Write-Host "  🛡️  Your system is fully protected and optimized" -ForegroundColor Green
    } elseif ($successRate -ge 80) {
        Write-Host "  ✅ MOSTLY SUCCESSFUL EXECUTION" -ForegroundColor Yellow
        Write-Host "  🔧 Minor issues detected - review failed scripts" -ForegroundColor Yellow
    } else {
        Write-Host "  ⚠️  MULTIPLE SCRIPT FAILURES DETECTED" -ForegroundColor Red
        Write-Host "  🔧 Manual intervention required for failed scripts" -ForegroundColor Red
    }
    
}
catch {
    Write-Host "`n❌ CRITICAL ERROR in Master Orchestrator: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Gray
}
finally {
    Write-Host "`n⚡ Master Script Orchestrator completed!" -ForegroundColor Green
    Write-Host "🕒 Execution time: $((Get-Date) - $startTime)" -ForegroundColor Gray
}
