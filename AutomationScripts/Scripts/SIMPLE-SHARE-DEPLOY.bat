@echo off
echo ================================================================
echo iBridge Simple Network Share Deployment
echo Manual deployment via network share
echo ================================================================
echo.
echo This approach focuses on creating a reliable network share
echo that your iBridge devices can access manually for deployment.
echo.
echo What this will do:
echo   1. Create network share: \\%COMPUTERNAME%\iBridgeSetup
echo   2. Copy all setup files to the share
echo   3. Create device-specific setup files
echo   4. Enable network discovery and file sharing
echo   5. Provide detailed manual deployment instructions
echo.
echo MUCH MORE RELIABLE than remote deployment attempts!
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
echo CREATING NETWORK SHARE FOR MANUAL DEPLOYMENT...
echo ================================================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0SIMPLE-NETWORK-SHARE.ps1"

echo.
echo ================================================================
echo NETWORK SHARE DEPLOYMENT READY!
echo ================================================================
echo.
echo Now go to each iBridge device and access the network share
echo for manual deployment. Much more reliable!
echo.
echo Opening deployment instructions...
start notepad "C:\iBridge_NetworkShare\DEPLOYMENT-INSTRUCTIONS.txt"
pause
