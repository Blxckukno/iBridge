@echo off
echo ================================================================
echo iBridge Setup - Copy to Local Disk for USB Independence
echo ================================================================
echo.
echo This will copy ALL setup files to your local disk so you can:
echo   - Remove the USB drive and use it for other things
echo   - Run installations completely from local drive
echo   - Deploy to network devices without USB dependency
echo   - Have all files permanently available on this computer
echo.
echo WHAT GETS COPIED TO LOCAL DRIVE:
echo   - All application installers (4 main apps)
echo   - Office tools folder
echo   - All shortcut folders
echo   - All deployment scripts
echo   - Network deployment capabilities
echo.
echo DESTINATION: C:\iBridge_Local_Setup\
echo.
echo After this, you can remove your USB and use it for anything else!
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
echo COPYING USB CONTENT TO LOCAL DISK...
echo ================================================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0SETUP-LOCAL-DISK.ps1"

echo.
echo ================================================================
echo LOCAL DISK SETUP COMPLETED!
echo ================================================================
echo.
echo Your USB drive can now be safely removed!
echo All installation and deployment capabilities are now on local drive.
echo.
echo NEXT STEPS:
echo 1. Remove USB drive (it's no longer needed)
echo 2. Use local installation: C:\iBridge_Local_Setup\RUN-LOCAL-INSTALL.bat
echo 3. Use network deployment: C:\iBridge_Local_Setup\RUN-NETWORK-DEPLOY.bat
echo.
pause
