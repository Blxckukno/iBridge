@echo off
echo ================================================================
echo iBridge Enhanced Setup - FIXED Office Installation
echo Works across all devices with proper Office handling
echo ================================================================
echo.
echo This script will:
echo   1. Auto-detect USB drive location (D:, E:, F:, etc.)
echo   2. Create Admin and iBridge User accounts  
echo   3. Install main applications PERMANENTLY to local system
echo   4. Handle Office tools installation CORRECTLY
echo   5. Copy ALL installers to C:\iBridge_Setup for backup
echo   6. Create shortcuts ONLY on iBridge User desktop
echo   7. Enable standalone operation (USB not required after setup)
echo.
echo OFFICE INSTALLATION FIXED:
echo   - Correctly locates setup.exe in Config Files subfolder
echo   - Tries multiple installation methods (setup.exe, start.cmd)
echo   - Copies to local storage for manual installation if needed
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

echo Running Enhanced Setup with Fixed Office Installation...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0iBridge-Fixed-Office.ps1"

echo.
echo ================================================================
echo Setup completed! 
echo.
echo OFFICE INSTALLATION:
echo If Office didn't install automatically, check:
echo C:\iBridge_Setup\Office\Tools for Office2019 TechXander\Config Files\
echo.
echo You can now safely remove the USB drive.
echo Applications will work independently on this computer.
echo ================================================================
pause
