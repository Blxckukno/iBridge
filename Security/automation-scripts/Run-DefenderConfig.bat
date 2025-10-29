@echo off
echo ===============================================
echo    Cybersecurity Setup - Administrator Mode
echo ===============================================
echo.
echo This will launch PowerShell as Administrator to configure Windows Defender.
echo Please click "Yes" when prompted for elevation.
echo.
pause

powershell -Command "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0Configure-WindowsDefender-Simple.ps1\" -MaxProtection' -Verb RunAs"

echo.
echo Configuration completed! Check the PowerShell window for results.
pause