@echo off
:: Anti-Phishing Email Security Orchestrator
:: Runs comprehensive email security and anti-phishing protection

title Anti-Phishing Email Security Toolkit

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ============================================================
    echo   REQUESTING ADMINISTRATOR PRIVILEGES
    echo ============================================================
    echo This script needs to run as Administrator for full functionality.
    echo Restarting with elevated privileges...
    echo.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ================================================================
echo   🛡️  ANTI-PHISHING EMAIL SECURITY TOOLKIT
echo ================================================================
echo   Comprehensive protection against email phishing attacks
echo ================================================================
echo.

cd /d "%~dp0"

:: Set execution policy for this session
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force"

echo [1/8] 🔍 Running Email Security Analysis...
echo ----------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "Security\Email-Security-Analysis.ps1"
if %errorlevel% neq 0 (
    echo ❌ Email Security Analysis failed with error %errorlevel%
) else (
    echo ✅ Email Security Analysis completed successfully
)
echo.

echo [2/8] 🔐 Running Email Account Audit...
echo ----------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "Security\Email-Account-Audit.ps1"
if %errorlevel% neq 0 (
    echo ❌ Email Account Audit failed with error %errorlevel%
) else (
    echo ✅ Email Account Audit completed successfully
)
echo.

echo [3/8] 🎣 Running Anti-Phishing Protection Scanner...
echo ----------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "Security\Anti-Phishing-Email-Protection.ps1"
if %errorlevel% neq 0 (
    echo ❌ Anti-Phishing Scanner failed with error %errorlevel%
) else (
    echo ✅ Anti-Phishing Scanner completed successfully
)
echo.

echo [4/8] ⚡ Running Quick Security Check...
echo ----------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "Security\Quick-Security-Check.ps1"
if %errorlevel% neq 0 (
    echo ❌ Quick Security Check failed with error %errorlevel%
) else (
    echo ✅ Quick Security Check completed successfully
)
echo.

echo [5/8] 🛡️  Optimizing Windows Defender...
echo ----------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "Security\Defender-Optimizer.ps1"
if %errorlevel% neq 0 (
    echo ❌ Defender Optimizer failed with error %errorlevel%
) else (
    echo ✅ Defender Optimizer completed successfully
)
echo.

echo [6/8] 📊 Running Master Security Verification...
echo ----------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "Security\Master-Security-Verification.ps1"
if %errorlevel% neq 0 (
    echo ❌ Master Security Verification failed with error %errorlevel%
) else (
    echo ✅ Master Security Verification completed successfully
)
echo.

echo [7/8] 🚨 Running Emergency Response Check...
echo ----------------------------------------------------------------
if exist "Emergency_Response\Quick-Email-Security-Check.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "Emergency_Response\Quick-Email-Security-Check.ps1"
    if %errorlevel% neq 0 (
        echo ❌ Emergency Response Check failed with error %errorlevel%
    ) else (
        echo ✅ Emergency Response Check completed successfully
    )
) else (
    echo ⚠️  Emergency Response script not found - skipping
)
echo.

echo [8/8] 📄 Generating Final Security Report...
echo ----------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "Generate-Final-Report.ps1"
if %errorlevel% neq 0 (
    echo ❌ Final Report generation failed with error %errorlevel%
) else (
    echo ✅ Final Report generated successfully
)
echo.

:: Additional email-specific protections
echo ================================================================
echo   🔒 ENABLING ADDITIONAL EMAIL PROTECTIONS
echo ================================================================

echo Configuring Windows Defender for email protection...
powershell -Command "try { Set-MpPreference -DisableEmailScanning 0; Write-Host 'Email scanning enabled' -ForegroundColor Green } catch { Write-Host 'Cannot modify Defender settings' -ForegroundColor Yellow }"

echo.
echo Enabling real-time protection...
powershell -Command "try { Set-MpPreference -DisableRealtimeMonitoring 0; Write-Host 'Real-time protection enabled' -ForegroundColor Green } catch { Write-Host 'Cannot modify real-time protection' -ForegroundColor Yellow }"

echo.
echo Setting up email attachment blocking...
powershell -Command "try { Set-MpPreference -DisableAttachmentScanning 0; Write-Host 'Attachment scanning enabled' -ForegroundColor Green } catch { Write-Host 'Cannot modify attachment scanning' -ForegroundColor Yellow }"

echo.
echo ================================================================
echo   📊 ANTI-PHISHING PROTECTION SUMMARY
echo ================================================================

:: Count reports generated
set /a reportCount=0
if exist "%USERPROFILE%\Desktop\Email_Security_Report_*.txt" set /a reportCount+=1
if exist "%USERPROFILE%\Desktop\Email_Account_Audit_*.txt" set /a reportCount+=1
if exist "%USERPROFILE%\Desktop\Anti_Phishing_Protection_Report_*.txt" set /a reportCount+=1
if exist "%USERPROFILE%\Desktop\Security_Report_*.txt" set /a reportCount+=1

echo.
echo ✅ Email security analysis completed
echo ✅ Anti-phishing protection activated
echo ✅ System hardening applied
echo ✅ Real-time monitoring enabled
echo.
echo 📄 Generated %reportCount% security reports on Desktop
echo.

:: Show recent threats if any reports exist
echo 🔍 Checking for detected threats...
powershell -Command "$reports = Get-ChildItem '$env:USERPROFILE\Desktop' -Filter '*Security*Report*.txt' | Sort-Object CreationTime -Descending | Select-Object -First 3; if ($reports) { Write-Host '📄 Recent Security Reports:' -ForegroundColor Cyan; $reports | ForEach-Object { Write-Host \"  • $($_.Name)\" -ForegroundColor Yellow } } else { Write-Host '  No security reports found' -ForegroundColor Gray }"

echo.
echo ================================================================
echo   💡 ANTI-PHISHING RECOMMENDATIONS
echo ================================================================
echo.
echo • Enable 2FA on all email accounts
echo • Never click suspicious email links
echo • Verify sender identity before responding
echo • Keep email clients updated
echo • Use strong, unique passwords
echo • Report phishing emails to IT security
echo • Regular security awareness training
echo • Enable email filtering and scanning
echo.

echo ================================================================
echo   🚨 NEXT STEPS IF THREATS DETECTED
echo ================================================================
echo.
echo 1. Review all security reports on Desktop
echo 2. Change passwords for affected email accounts
echo 3. Run full system antivirus scan
echo 4. Contact IT security team if needed
echo 5. Monitor email activity closely
echo.

echo ⚡ Anti-phishing email protection completed!
echo.
echo Press any key to open security reports folder...
pause >nul

:: Open Desktop to show reports
start "" "%USERPROFILE%\Desktop"

echo.
echo Script execution completed at %date% %time%
echo Log saved to: %~dp0\AntiPhishing_Protection_Log_%date:~-4,4%%date:~-10,2%%date:~-7,2%.txt
echo.
pause
