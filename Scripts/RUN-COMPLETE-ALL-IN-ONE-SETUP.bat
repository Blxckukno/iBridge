@echo off
title iBridge COMPLETE All-in-One Setup
echo ================================================================
echo iBridge COMPLETE ALL-IN-ONE SETUP SYSTEM
echo ================================================================
echo.
echo This is the ULTIMATE iBridge setup script that does EVERYTHING:
echo.
echo ✅ Installs .NET Core 8.0 Desktop Runtime (fixes Citrix error)
echo ✅ Creates Admin and iBridge User accounts with correct passwords
echo ✅ Installs ALL applications automatically with error handling
echo ✅ Sets up user profiles correctly and completely
echo ✅ Deploys desktop shortcuts to iBridge User
echo ✅ Organizes all files and creates comprehensive backups
echo ✅ Provides verification and troubleshooting information
echo.
echo FIXES ALL KNOWN ISSUES:
echo   • Drive detection problem (D: vs C: drive) - RESOLVED
echo   • Citrix "Unable to install prerequisites" error - RESOLVED
echo   • .NET Core 8.0 requirement for Citrix - RESOLVED
echo   • User account creation and profile setup - RESOLVED
echo   • Desktop shortcuts deployment - RESOLVED
echo.
echo ONE SCRIPT TO RULE THEM ALL!
echo.
pause

REM Check for admin privileges and elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ⚠️  REQUESTING ADMINISTRATOR PRIVILEGES...
    echo This script requires Administrator rights to:
    echo   - Create user accounts
    echo   - Install applications
    echo   - Modify system settings
    echo   - Set up user profiles
    echo.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ================================================================
echo LAUNCHING COMPLETE ALL-IN-ONE SETUP...
echo ================================================================
echo.

REM Run the PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0COMPLETE-ALL-IN-ONE-SETUP.ps1"

echo.
echo ================================================================
echo COMPLETE SETUP LAUNCHER FINISHED
echo ================================================================
echo.
echo If the setup completed successfully:
echo   1. Log out of Windows
echo   2. Log in as 'iBridge User' (Password: Abc654321!)
echo   3. Install Citrix Workspace App (should work now!)
echo   4. Enjoy your fully configured system!
echo.
pause
