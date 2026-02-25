@echo off
echo ================================================================
echo iBridge Enhanced Setup - Standalone Operation
echo Ensures applications work WITHOUT USB drive
echo ================================================================
echo.
echo This script will:
echo   1. Create Admin and iBridge User accounts
echo   2. Install applications PERMANENTLY to local system  
echo   3. Copy ALL installers to C:\iBridge_Setup\Installers
echo   4. Create shortcuts ONLY on iBridge User desktop
echo   5. Enable standalone operation (USB not required)
echo.
echo IMPORTANT: After setup, USB drive will NOT be needed!
echo.
pause

:: Check for admin privileges and elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running Enhanced Standalone Setup...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0iBridge-Simple-Standalone.ps1"

echo.
echo ================================================================
echo Setup completed! Check output above for results.
echo You can now safely remove the USB drive.
echo ================================================================
pause
