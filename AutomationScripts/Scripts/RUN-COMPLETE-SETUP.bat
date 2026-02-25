@echo off
echo.
echo ============================================================
echo     iBridge Complete Setup - One Click Installation
echo ============================================================
echo.
echo This script will:
echo   1. Create user accounts (Admin and iBridge User)
echo   2. Install all applications to C:\iBridge_Apps
echo   3. Set up shortcuts for both users
echo   4. Configure proper permissions
echo.
echo REQUIREMENTS:
echo   - Run as Administrator
echo   - Source files accessible on D: drive
echo.
echo Press any key to start the complete setup...
pause >nul

:: Check if running as Administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo.
    echo Starting iBridge Complete Setup...
    echo.
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0iBridge-Complete-Setup.ps1"
) else (
    echo.
    echo Requesting Administrator privileges...
    powershell.exe -Command "Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -File ""%~dp0iBridge-Complete-Setup.ps1""' -Verb RunAs"
)

echo.
echo Setup completed. Check the PowerShell window for details.
pause
