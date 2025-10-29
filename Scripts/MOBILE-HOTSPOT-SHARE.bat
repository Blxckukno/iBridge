@echo off
echo ================================================================
echo iBridge Mobile Hotspot Deployment - ONE CLICK SETUP
echo Creates network share instantly for mobile hotspot deployment
echo ================================================================
echo.
echo This will:
echo   1. Create network share \\%COMPUTERNAME%\iBridgeSetup
echo   2. Copy all setup files to share
echo   3. Configure firewall for sharing
echo   4. Show connection instructions for other devices
echo.
echo Make sure your mobile hotspot is active and other devices are connected!
echo.
pause

:: Check for admin privileges and elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Creating mobile hotspot deployment...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0NETWORK-DEPLOYMENT.ps1" -CreateShare

echo.
echo ================================================================
echo MOBILE HOTSPOT DEPLOYMENT READY!
echo ================================================================
echo.
echo SHARE LOCATION: \\%COMPUTERNAME%\iBridgeSetup
echo.
echo INSTRUCTIONS FOR OTHER DEVICES:
echo 1. Connect to your mobile hotspot
echo 2. Open File Explorer
echo 3. Type in address bar: \\%COMPUTERNAME%\iBridgeSetup
echo 4. Copy UNIVERSAL-USB-SETUP.bat to their desktop
echo 5. Right-click and "Run as administrator"
echo.
echo OR tell them to run this command:
echo \\%COMPUTERNAME%\iBridgeSetup\UNIVERSAL-USB-SETUP.bat
echo.
echo Opening instructions file...
start notepad "C:\iBridge_NetworkShare\DEPLOYMENT-INSTRUCTIONS.txt"

echo.
pause
