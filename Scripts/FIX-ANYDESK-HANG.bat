@echo off
title iBridge Offline Setup - AnyDesk Fix
color 0C

echo.
echo  ========================================
echo   iBridge Offline Setup - AnyDesk Issue
echo  ========================================
echo.
echo  If AnyDesk installation hangs or gets stuck:
echo.
echo  [1] Stop the current installation
echo  [2] Edit the script to disable AnyDesk
echo  [3] Run setup again without AnyDesk
echo.
echo  This will:
echo  - Copy AnyDesk.exe but not install it
echo  - Install all other applications normally
echo  - You can manually install AnyDesk later
echo.
echo  ========================================
echo.
set /p choice="Continue to disable AnyDesk? (Y/N): "

if /i "%choice%"=="Y" goto disable_anydesk
if /i "%choice%"=="N" goto exit
goto exit

:disable_anydesk
echo.
echo Modifying script to disable AnyDesk installation...

:: Create a modified version of the offline setup script
powershell -Command "(Get-Content 'iBridge-Offline-Setup.ps1') -replace '\$InstallAnyDesk = \$true', '$InstallAnyDesk = $false' | Set-Content 'iBridge-Offline-Setup-Fixed.ps1'"

echo AnyDesk installation disabled.
echo.
echo Now running offline setup without AnyDesk...
echo.
pause

PowerShell -ExecutionPolicy Bypass -File "iBridge-Offline-Setup-Fixed.ps1"

echo.
echo Setup completed! AnyDesk.exe is available in C:\iBridge_Setup\Installers
echo if you want to install it manually later.
pause
goto exit

:exit
echo.
echo Exiting...
timeout /t 2 >nul
