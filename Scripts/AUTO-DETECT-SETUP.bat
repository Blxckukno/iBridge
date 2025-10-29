@echo off
echo ================================================================
echo iBridge Auto-Detecting Setup - Smart File Detection
echo Automatically finds files on local disk or USB drives
echo ================================================================
echo.
echo This smart setup will:
echo   1. Auto-detect application files (local disk first, then USB)
echo   2. Auto-detect shortcut folders
echo   3. Use the best available file sources
echo   4. Install everything properly regardless of source
echo.
echo SEARCH ORDER:
echo   1. C:\iBridge_Local_Setup\Installers (LOCAL DISK - fastest)
echo   2. E:\ F:\ D:\ G:\ (USB DRIVES)
echo.
echo This fixes the "application not found" errors by automatically
echo finding files wherever they are located!
echo.
pause

:: Check for admin privileges and elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ================================================================
echo RUNNING AUTO-DETECTING SETUP...
echo ================================================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0AUTO-DETECT-SETUP.ps1"

echo.
echo ================================================================
echo AUTO-DETECTING SETUP COMPLETED!
echo ================================================================
echo.
echo Setup automatically found and used the best file sources.
echo Check the output above for detection results.
echo.
pause
