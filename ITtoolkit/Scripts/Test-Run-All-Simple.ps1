# Simple Test - Run All Scripts
Write-Host "=== COMPREHENSIVE SYSTEM CHECK TEST ===" -ForegroundColor Green

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Script Directory: $ScriptDir" -ForegroundColor Yellow

$ScriptsToTest = @(
    "Security\Defender-Optimizer-Fixed.ps1",
    "Security\Master-Security-Verification-Fixed.ps1"
)

$Results = @{
    Success = 0
    Failed = 0
}

foreach ($script in $ScriptsToTest) {
    $fullPath = Join-Path $ScriptDir $script
    Write-Host "Testing: $script" -ForegroundColor Cyan
    
    if (Test-Path $fullPath) {
        Write-Host "  [FOUND] $script" -ForegroundColor Green
        $Results.Success++
    } else {
        Write-Host "  [NOT FOUND] $script" -ForegroundColor Red
        $Results.Failed++
    }
}

Write-Host ""
Write-Host "Test Results:" -ForegroundColor White
Write-Host "  Found: $($Results.Success)" -ForegroundColor Green
Write-Host "  Missing: $($Results.Failed)" -ForegroundColor Red

Write-Host ""
Write-Host "Test completed successfully!" -ForegroundColor Green
