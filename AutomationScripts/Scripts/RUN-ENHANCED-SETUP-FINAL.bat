@echo off
echo ================================================================
echo iBridge Enhanced Setup - FINAL VERSION
echo Ensures Standalone Operation Without USB Drive
echo ================================================================
echo.
echo This script will:
echo   1. Create Admin and iBridge User accounts
echo   2. Install applications PERMANENTLY to local system
echo   3. Copy all installers to C:\iBridge_Setup\Installers
echo   4. Create shortcuts for iBridge User (work without USB)
echo   5. Organize everything for standalone operation
echo.
echo IMPORTANT: USB drive will NOT be needed after installation!
echo.
pause

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Running Enhanced Setup Script...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0iBridge-Enhanced-Setup-FINAL.ps1"

echo.
echo ================================================================
echo Setup completed! Check the output above for results.
echo ================================================================
pause
