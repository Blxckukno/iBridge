@echo off
echo ================================================================
echo iBridge Alternative Deployment - Multiple Connection Methods
echo Handles devices that don't respond to ping but are connected
echo ================================================================
echo.
echo This script will try multiple methods to deploy to your devices:
echo   1. Direct file copy (works even without ping response)
echo   2. PowerShell remoting (if credentials work)
echo   3. Manual execution setup (creates instructions)
echo   4. Network share access (for manual deployment)
echo.
echo TARGET DEVICES:
echo   - iBridge-JHB-70 (192.168.137.131)
echo   - iBridge-JHB-44 (192.168.137.31)
echo   - iBridge-JHB-33 (192.168.137.83)
echo   - iBridge-JHB-14 (192.168.137.240)
echo   - iBridge-JHB-18 (192.168.137.134)
echo.
echo Even if devices don't ping, files can still be copied!
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
echo RUNNING ALTERNATIVE DEPLOYMENT METHODS...
echo ================================================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0ALTERNATIVE-DEPLOY.ps1"

echo.
echo ================================================================
echo ALTERNATIVE DEPLOYMENT COMPLETED!
echo ================================================================
echo.
echo Check the output above for results.
echo Files should be copied even if remote execution failed.
echo Use network share for manual deployment if needed.
echo.
pause
