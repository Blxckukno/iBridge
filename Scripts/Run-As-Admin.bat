@echo off
echo.
echo ============================================================
echo     Windows Local Account Creation Script
echo     Run as Administrator Helper
echo ============================================================
echo.
echo This batch file will run the PowerShell script with Administrator privileges.
echo.
pause

:: Check if running as Administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with Administrator privileges...
    echo.
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0Create-Accounts-Fixed.ps1"
) else (
    echo Requesting Administrator privileges...
    powershell.exe -Command "Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -File ""%~dp0Create-Accounts-Fixed.ps1""' -Verb RunAs"
)

echo.
pause
