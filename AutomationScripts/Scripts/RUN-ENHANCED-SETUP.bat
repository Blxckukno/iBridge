@echo off
:: iBridge Enhanced Setup Launcher
:: Enhanced version with progress tracking and profile setup

setlocal enabledelayedexpansion

echo.
echo ================================================================================
echo                      iBridge ENHANCED Setup - One Click Installation
echo ================================================================================
echo.
echo This ENHANCED script will:
echo   1. Clean up and organize everything into C:\iBridge_Setup
echo   2. Create user accounts with FORCED profile creation
echo   3. Install all applications with progress tracking
echo   4. Create and VERIFY shortcuts on both desktops
echo   5. Generate detailed logs and summary
echo   6. Organize all scripts and files in one location
echo.
echo ENHANCEMENTS:
echo   ✓ Forces user profile creation to ensure shortcuts work
echo   ✓ Detailed progress tracking and logging
echo   ✓ Verifies shortcuts actually appear on desktops
echo   ✓ Organizes everything into a single folder structure
echo   ✓ Creates comprehensive setup summary
echo.
echo REQUIREMENTS:
echo   - Run as Administrator
echo   - Application files accessible on D: or E: drives
echo.

:: Check if running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires Administrator privileges.
    echo.
    echo Please right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [SUCCESS] Running with Administrator privileges
echo.

:: Check for PowerShell script
set "PS_SCRIPT=%~dp0iBridge-Enhanced-Setup.ps1"

if not exist "%PS_SCRIPT%" (
    echo [ERROR] Could not find iBridge-Enhanced-Setup.ps1
    echo Expected location: %PS_SCRIPT%
    echo.
    pause
    exit /b 1
)

echo [SUCCESS] Found PowerShell script
echo.

:: Prompt user for confirmation
echo Press any key to start the ENHANCED setup process...
echo (This will create detailed logs and ensure shortcuts work properly)
pause >nul

echo.
echo ================================================================================
echo                            Starting Enhanced Setup
echo ================================================================================
echo.

:: Execute the enhanced PowerShell script
powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -NoProfile

:: Check result
if %errorlevel% equ 0 (
    echo.
    echo ================================================================================
    echo                           ENHANCED Setup Completed!
    echo ================================================================================
    echo.
    echo ✓ All files organized in C:\iBridge_Setup
    echo ✓ User profiles created and verified
    echo ✓ Shortcuts verified on both user desktops
    echo ✓ Detailed logs generated
    echo.
    echo NEXT STEPS:
    echo 1. Log out of Windows
    echo 2. Log in as 'iBridge User' (Password: Abc654321!)
    echo 3. Check desktop for shortcuts
    echo 4. Browse C:\iBridge_Setup for all resources
    echo.
) else (
    echo.
    echo ================================================================================
    echo                              Enhanced Setup Failed!
    echo ================================================================================
    echo.
    echo Error code: %errorlevel%
    echo Check the log files in C:\iBridge_Setup\Logs\
    echo.
)

echo Press any key to exit...
pause >nul
