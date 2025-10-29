@echo off
echo ================================================================
echo iBridge Quick Deploy - Using Mobile Hotspot Device List
echo No scanning needed - deploying to known connected devices
echo ================================================================
echo.
echo Based on your mobile hotspot, these devices are connected:
echo   - iBridge-JHB-70 (192.168.137.131)
echo   - iBridge-JHB-44 (192.168.137.31)
echo   - iBridge-JHB-33 (192.168.137.83)
echo   - iBridge-JHB-14 (192.168.137.240)
echo   - iBridge-JHB-18 (192.168.137.134)
echo   - Honor-x6a (192.168.137.195)
echo.
echo This will deploy iBridge setup to all iBridge-JHB-* devices only.
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
echo DEPLOYING TO KNOWN iBridge DEVICES...
echo ================================================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0QUICK-DEPLOY.ps1"

echo.
echo ================================================================
echo QUICK DEPLOYMENT COMPLETED!
echo ================================================================
pause
