@echo off
:: Master Script Runner - Executes all working scripts safely
:: Handles admin privileges and error recovery

title Master IT Toolkit Script Orchestrator

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ============================================================
    echo   REQUESTING ADMINISTRATOR PRIVILEGES
    echo ============================================================
    echo This will run ALL working scripts in the IT Toolkit.
    echo Administrator privileges are required for full functionality.
    echo.
    echo Press any key to continue with elevated privileges...
    pause >nul
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ================================================================
echo   🚀 MASTER IT TOOLKIT SCRIPT ORCHESTRATOR
echo ================================================================
echo   Running all verified working scripts safely
echo ================================================================
echo.

cd /d "%~dp0"

:: Set execution policy for this session
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force"

:: Display menu for execution mode
echo Select execution mode:
echo.
echo [1] Full Execution - Run all working scripts (Recommended)
echo [2] Security Only - Run security and verification scripts
echo [3] Email Only - Run email security scripts
echo [4] Quick Scan - Run essential security checks only
echo [5] Diagnostic Mode - Skip syntax checking
echo [6] Exit
echo.
set /p choice="Enter your choice (1-6): "

set "mode_params="

if "%choice%"=="1" (
    echo.
    echo ⚡ Running FULL EXECUTION mode...
    set "mode_params="
) else if "%choice%"=="2" (
    echo.
    echo 🛡️ Running SECURITY ONLY mode...
    set "mode_params=-SecurityOnly"
) else if "%choice%"=="3" (
    echo.
    echo 📧 Running EMAIL SECURITY mode...
    set "mode_params=-EmailOnly"
) else if "%choice%"=="4" (
    echo.
    echo ⚡ Running QUICK SCAN mode...
    set "mode_params=-QuickScan"
) else if "%choice%"=="5" (
    echo.
    echo 🔧 Running DIAGNOSTIC mode (skip syntax check)...
    set "mode_params=-SkipSyntaxCheck"
) else if "%choice%"=="6" (
    echo.
    echo Exiting...
    exit /b 0
) else (
    echo.
    echo Invalid choice. Running full execution...
    set "mode_params="
)

echo.
echo ================================================================
echo   🔧 STARTING SCRIPT ORCHESTRATION
echo ================================================================

:: Record start time
echo Started at: %date% %time%
echo.

:: Run the master orchestrator
echo Executing: Master-Script-Orchestrator.ps1 %mode_params%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "Master-Script-Orchestrator.ps1" %mode_params%

set orchestrator_exit=%errorlevel%

echo.
echo ================================================================
echo   📊 ORCHESTRATOR RESULTS
echo ================================================================

if %orchestrator_exit% equ 0 (
    echo ✅ Master orchestrator completed successfully
) else (
    echo ⚠️ Master orchestrator completed with warnings ^(Exit: %orchestrator_exit%^)
)

echo.
echo Completed at: %date% %time%

:: Show recent reports
echo.
echo ================================================================
echo   📄 GENERATED REPORTS
echo ================================================================
echo.
echo Checking for reports on Desktop...

:: Use PowerShell to list recent reports
powershell -Command "Get-ChildItem '$env:USERPROFILE\Desktop' -Filter '*Report*.txt' | Sort-Object CreationTime -Descending | Select-Object -First 5 | ForEach-Object { Write-Host '  📄 ' $_.Name -ForegroundColor Cyan }"

echo.
echo ================================================================
echo   💡 NEXT STEPS
echo ================================================================
echo.
echo 1. Review execution report on Desktop
echo 2. Check for any failed scripts that need manual fixing
echo 3. Run specific scripts manually if needed
echo 4. Monitor system for improved security posture
echo.

if %orchestrator_exit% neq 0 (
    echo ⚠️ ATTENTION: Some scripts may have failed
    echo Check the execution report for details
    echo.
)

echo ================================================================
echo   🔧 QUICK ACTIONS
echo ================================================================
echo.
echo [1] Open Desktop to view reports
echo [2] Run security verification only
echo [3] Run email security check
echo [4] Exit
echo.
set /p action="Choose an action (1-4): "

if "%action%"=="1" (
    echo Opening Desktop...
    start "" "%USERPROFILE%\Desktop"
) else if "%action%"=="2" (
    echo Running security verification...
    powershell -NoProfile -ExecutionPolicy Bypass -File "Security-Verification-Simple.ps1"
) else if "%action%"=="3" (
    echo Running email security check...
    powershell -NoProfile -ExecutionPolicy Bypass -File "Emergency_Response\Quick-Email-Security-Check.ps1"
)

echo.
echo ⚡ Master script execution completed!
echo.
echo Press any key to exit...
pause >nul

:: Log completion
echo Script execution completed at %date% %time% >> "%~dp0\Master_Execution_Log.txt"
