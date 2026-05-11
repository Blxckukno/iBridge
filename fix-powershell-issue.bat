@echo off
REM ========================================
REM iBridge - PowerShell OneDrive Fix
REM ========================================
REM This script permanently fixes the PowerShell OneDrive configuration issue
REM Run this once to resolve the "cloud file provider" error

echo.
echo =========================================
echo iBridge - PowerShell OneDrive Fix
echo =========================================
echo.
echo This script will fix the PowerShell OneDrive configuration issue
echo that causes "The cloud file provider is not running" error.
echo.

setlocal enabledelayedexpansion

REM Define the paths
set ONEDRIVE_CONFIG=C:\Users\Lwandile Gasela\OneDrive - iBridge Contact Solutions (Pty) Ltd\Documents\PowerShell
set CONFIG_FILE=%ONEDRIVE_CONFIG%\powershell.config.json
set BACKUP_FILE=%ONEDRIVE_CONFIG%\powershell.config.json.backup
set DISABLED_FILE=%ONEDRIVE_CONFIG%\powershell.config.json.disabled

echo Checking system configuration...
echo.

REM Check if the problematic directory exists
if not exist "%ONEDRIVE_CONFIG%" (
    echo ✅ PowerShell OneDrive folder not found - no issue to fix
    echo.
    pause
    exit /b 0
)

REM Check if the problematic file exists
if not exist "%CONFIG_FILE%" (
    echo ✅ PowerShell config file not found - no issue to fix
    echo.
    pause
    exit /b 0
)

echo ⚠️  Found problematic PowerShell configuration file
echo 📍 File: %CONFIG_FILE%
echo.

REM Check if already fixed
if exist "%DISABLED_FILE%" (
    echo ✅ File is already disabled/fixed
    echo.
    echo The issue has already been resolved. PowerShell should work normally now.
    echo.
    pause
    exit /b 0
)

REM Check if backup exists
if exist "%BACKUP_FILE%" (
    echo 📝 Backup file already exists
    echo.
) else (
    echo Creating backup of original file...
    copy "%CONFIG_FILE%" "%BACKUP_FILE%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✅ Backup created: powershell.config.json.backup
    ) else (
        echo ⚠️  Warning: Could not create backup (might need admin rights)
    )
    echo.
)

REM Rename the file to disable it
echo Disabling problematic configuration...
ren "%CONFIG_FILE%" "powershell.config.json.disabled" >nul 2>&1

if !errorlevel! equ 0 (
    echo ✅ Successfully disabled problematic file!
    echo   Renamed to: powershell.config.json.disabled
    echo.
    echo 🎉 Fix Complete! Your system should now work normally.
    echo.
    echo What was fixed:
    echo   - PowerShell will no longer try to load the OneDrive config
    echo   - Terminal commands should execute without errors
    echo   - Your development environment is ready
    echo.
    echo If you need to restore the original file, rename:
    echo   powershell.config.json.disabled ^-^> powershell.config.json
    echo.
) else (
    echo ❌ Error: Could not rename file
    echo.
    echo This might be due to:
    echo   1. File is in use by OneDrive sync
    echo   2. Requires administrator privileges
    echo   3. File permissions are restricted
    echo.
    echo Solution:
    echo   - Close OneDrive or pause syncing
    echo   - Run this script as Administrator
    echo   - Or manually rename the file using File Explorer
    echo.
    echo To manually fix:
    echo   1. Open File Explorer
    echo   2. Navigate to: %ONEDRIVE_CONFIG%
    echo   3. Right-click on "powershell.config.json"
    echo   4. Rename to "powershell.config.json.disabled"
    echo   5. Restart your terminal
    echo.
    pause
    exit /b 1
)

pause
