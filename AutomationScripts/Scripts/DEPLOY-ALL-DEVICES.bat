@echo off
echo ================================================================
echo iBridge Deploy to ALL Network Devices
echo Automatically deploys to EVERY device on the network
echo ================================================================
echo.
echo WARNING: This will deploy iBridge setup to ALL devices found on your network!
echo.
echo This will:
echo   1. Scan network for ALL connected devices
echo   2. Deploy iBridge setup to EVERY device found
echo   3. Create Admin and iBridge User accounts on each
echo   4. Install applications on each device
echo   5. Show deployment results
echo.
echo Make sure you want to deploy to ALL devices before continuing!
echo.
set /p confirm="Are you sure you want to deploy to ALL network devices? (yes/no): "

if /i not "%confirm%"=="yes" (
    echo Deployment cancelled.
    pause
    exit /b
)

:: Check for admin privileges and elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ================================================================
echo DEPLOYING TO ALL NETWORK DEVICES...
echo ================================================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0NETWORK-DEPLOYMENT.ps1" -CreateShare -DeployToAllDevices

echo.
echo ================================================================
echo ALL DEVICES DEPLOYMENT COMPLETED!
echo ================================================================
echo.
echo Check the output above for deployment results for each device.
echo All devices should now have iBridge setup installed.
echo.
pause
