# USB Script Validation Test
# Tests the USB version of the master script for syntax errors

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "USB Script Validation Test" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$usbScript = "D:\iBridge Set Up\iBridge-Complete-Setup.ps1"

if (Test-Path $usbScript) {
    Write-Host "[OK] USB script found: $usbScript" -ForegroundColor Green
    
    # Test syntax by parsing the script
    Write-Host "[INFO] Testing script syntax..." -ForegroundColor Blue
    
    try {
        $errors = $null
        $tokens = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($usbScript, [ref]$tokens, [ref]$errors)
        
        if ($errors.Count -eq 0) {
            Write-Host "[SUCCESS] Script syntax is valid!" -ForegroundColor Green
            Write-Host "[INFO] Script is ready to run from USB" -ForegroundColor Blue
        } else {
            Write-Host "[ERROR] Script has syntax errors:" -ForegroundColor Red
            foreach ($error in $errors) {
                Write-Host "  - Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "[ERROR] Could not validate script: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[ERROR] USB script not found: $usbScript" -ForegroundColor Red
}

Write-Host ""
Write-Host "To run the USB setup:" -ForegroundColor Yellow
Write-Host "  Double-click: D:\iBridge Set Up\RUN-COMPLETE-SETUP.bat" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to continue..."
Read-Host
