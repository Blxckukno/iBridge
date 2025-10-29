@echo off
echo ================================================================
echo iBridge Interactive Device Selection
echo Select individual devices or groups for deployment
echo ================================================================
echo.
echo This will:
echo   1. Scan network for ALL connected devices
echo   2. Show numbered list of devices
echo   3. Let you select individual devices (1,3,5)
echo   4. Or select groups (all, ibridge)
echo   5. Deploy setup to selected devices
echo.
echo SELECTION OPTIONS:
echo   - Individual: 1,3,5 (deploy to devices 1, 3, and 5)
echo   - All devices: all
echo   - iBridge only: ibridge
echo   - Cancel: quit
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
echo SCANNING NETWORK AND PREPARING DEVICE SELECTION...
echo ================================================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0NETWORK-DEPLOYMENT.ps1" -CreateShare -InteractiveSelection

echo.
echo ================================================================
echo INTERACTIVE DEPLOYMENT COMPLETED!
echo ================================================================
echo.
echo Check the output above for deployment results.
echo.
pause
