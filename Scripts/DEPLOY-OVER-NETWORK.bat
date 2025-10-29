@echo off
echo ================================================================
echo iBridge Network Deployment - Mobile Hotspot Ready
echo Automated sharing and deployment across network devices
echo ================================================================
echo.
echo Select deployment option:
echo.
echo 1) Create Network Share (run first)
echo 2) Interactive Device Selection
echo 3) Auto-Deploy to ALL Network Devices
echo 4) Auto-Deploy to iBridge/GoRent Devices Only
echo 5) Auto-Deploy to Specific Devices  
echo 6) Just Show Network Discovery
echo 7) Create Share + Show Instructions
echo.
set /p choice="Enter choice (1-7): "

:: Check for admin privileges and elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

if "%choice%"=="1" (
    echo Creating network share...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0NETWORK-DEPLOYMENT.ps1" -CreateShare
) else if "%choice%"=="2" (
    echo Interactive device selection...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0NETWORK-DEPLOYMENT.ps1" -CreateShare -InteractiveSelection
) else if "%choice%"=="3" (
    echo Auto-deploying to ALL network devices...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0NETWORK-DEPLOYMENT.ps1" -CreateShare -DeployToAllDevices
) else if "%choice%"=="4" (
    echo Auto-deploying to iBridge/GoRent devices...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0NETWORK-DEPLOYMENT.ps1" -CreateShare -DeployToiBridgeDevices
) else if "%choice%"=="5" (
    set /p devices="Enter device names/IPs (comma separated): "
    echo Deploying to devices: %devices%
    powershell.exe -ExecutionPolicy Bypass -Command "& '%~dp0NETWORK-DEPLOYMENT.ps1' -DeployToDevices -TargetDevices @('%devices%'.Split(',').Trim())"
) else if "%choice%"=="6" (
    echo Discovering network devices...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0NETWORK-DEPLOYMENT.ps1"
) else if "%choice%"=="7" (
    echo Creating share and showing instructions...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0NETWORK-DEPLOYMENT.ps1" -CreateShare
    pause
    echo.
    echo Opening instructions file...
    start notepad "C:\iBridge_NetworkShare\DEPLOYMENT-INSTRUCTIONS.txt"
) else (
    echo Invalid choice. Please run again.
)

echo.
echo ================================================================
echo Network deployment operation completed!
echo ================================================================
pause
