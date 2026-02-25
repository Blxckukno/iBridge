@echo off
echo ================================================================
echo iBridge FULLY AUTOMATED Network Deployment
echo Multiple automated methods - NO MANUAL INTERVENTION REQUIRED
echo ================================================================
echo.
echo This script uses multiple automated deployment methods:
echo   1. WMI (Windows Management Instrumentation) - Most reliable
echo   2. PowerShell Remoting - Direct remote execution
echo   3. Scheduled Tasks - Remote task creation and execution
echo   4. Network Drive Mapping - Automated file copy and execution
echo.
echo TARGET DEVICES:
echo   - iBridge-JHB-70 (192.168.137.131)
echo   - iBridge-JHB-44 (192.168.137.31)
echo   - iBridge-JHB-33 (192.168.137.83)
echo   - iBridge-JHB-14 (192.168.137.240)
echo   - iBridge-JHB-18 (192.168.137.134)
echo.
echo COMPLETELY AUTOMATED - Just provide credentials once!
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
echo RUNNING FULLY AUTOMATED DEPLOYMENT...
echo ================================================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0FULLY-AUTOMATED-DEPLOY.ps1"

echo.
echo ================================================================
echo AUTOMATED DEPLOYMENT COMPLETED!
echo ================================================================
echo.
echo Check the results above to see which devices were successfully deployed.
echo All successful deployments are now ready with iBridge setup!
echo.
pause
