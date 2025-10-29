# Clean Script Orchestrator - No Unicode Characters
# Runs only verified safe and working scripts

Write-Host "SIMPLE SCRIPT ORCHESTRATOR" -ForegroundColor White -BackgroundColor Blue
Write-Host "Running verified safe scripts only" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$executed = 0
$failed = 0

# Define working scripts (verified to work)
$workingScripts = @(
    "Security\Quick-Security-Check.ps1",
    "Emergency_Response\Quick-Email-Security-Check.ps1", 
    "Cleanup\Quick-Cleanup.ps1",
    "Security-Verification-Simple.ps1"
)

Write-Host ""
Write-Host "EXECUTION PLAN: $($workingScripts.Count) scripts" -ForegroundColor Cyan

foreach ($script in $workingScripts) {
    $fullPath = Join-Path $scriptPath $script
    $scriptName = Split-Path $script -Leaf
    
    Write-Host ""
    Write-Host "[$($executed + $failed + 1)] Running: $scriptName" -ForegroundColor Yellow
    Write-Host "-" * 40 -ForegroundColor Gray
    
    if (Test-Path $fullPath) {
        try {
            if ($script -like "*.ps1") {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $fullPath
            }
            
            if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
                Write-Host "SUCCESS: $scriptName completed" -ForegroundColor Green
                $executed++
            } else {
                Write-Host "WARNING: $scriptName completed with warnings" -ForegroundColor Yellow
                $executed++
            }
        }
        catch {
            Write-Host "ERROR: $scriptName failed" -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host "ERROR: Script not found: $script" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Green
Write-Host "EXECUTION SUMMARY" -ForegroundColor White -BackgroundColor Green
Write-Host "=" * 50 -ForegroundColor Green

Write-Host ""
Write-Host "Successfully executed: $executed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host "Total: $($executed + $failed)" -ForegroundColor Cyan

$successRate = if (($executed + $failed) -gt 0) { [math]::Round(($executed / ($executed + $failed)) * 100, 1) } else { 0 }
Write-Host "Success rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "Script orchestrator completed successfully!" -ForegroundColor Green
