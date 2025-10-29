@echo off
echo ================================================================
echo iBridge Auto-Deploy - Target iBridge-JHB-* and GoRent PC
echo Automatically finds and deploys to your iBridge devices
echo ================================================================
echo.
echo This will:
echo   1. Create network share instantly
echo   2. Scan network for iBridge-JHB-* devices
echo   3. Scan network for GoRent PC devices
echo   4. Auto-deploy setup to ALL found devices
echo   5. Show deployment results
echo.
echo TARGET DEVICE PATTERNS:
echo   - iBridge-JHB-1, iBridge-JHB-2, etc.
echo   - GoRent PC
echo.
echo Make sure all target devices are connected to your mobile hotspot!
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
echo SCANNING NETWORK FOR iBridge DEVICES...
echo ================================================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0NETWORK-DEPLOYMENT.ps1" -CreateShare -DeployToiBridgeDevices

echo.
echo ================================================================
echo iBridge AUTO-DEPLOYMENT COMPLETED!
echo ================================================================
echo.
echo Check the output above for:
echo   - Number of devices found
echo   - Deployment results for each device
echo   - Any error messages
echo.
echo All iBridge-JHB-* and GoRent PC devices should now have:
echo   - Admin account: Admin (Password: IBr1dG3Pc)
echo   - iBridge User: iBridge User (Password: Abc654321!)
echo   - All applications installed
echo   - Desktop shortcuts ready
echo.
pause
