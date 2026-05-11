@echo off
REM ========================================
REM iBridge Server Startup with PowerShell Fix
REM ========================================
REM This script fixes the OneDrive PowerShell issue permanently
REM and then starts the local server

echo.
echo =========================================
echo iBridge - Startup & System Fix
echo =========================================
echo.

REM Set the problematic OneDrive PowerShell config path
set POWERSHELL_CONFIG=C:\Users\Lwandile Gasela\OneDrive - iBridge Contact Solutions (Pty) Ltd\Documents\PowerShell\powershell.config.json
set BACKUP_PATH=C:\Users\Lwandile Gasela\OneDrive - iBridge Contact Solutions (Pty) Ltd\Documents\PowerShell\powershell.config.json.disabled

echo Step 1: Checking for PowerShell OneDrive configuration issue...
echo.

REM Check if the problematic file exists
if exist "%POWERSHELL_CONFIG%" (
    echo ⚠️  Found problematic PowerShell config file
    echo 📍 Location: %POWERSHELL_CONFIG%
    echo.
    echo Disabling the file by renaming to .disabled...
    
    REM Check if backup already exists
    if exist "%BACKUP_PATH%" (
        echo   (Already disabled)
    ) else (
        REM Rename the file to disable it
        ren "%POWERSHELL_CONFIG%" "powershell.config.json.disabled"
        if %errorlevel% equ 0 (
            echo ✅ Successfully disabled problematic config file
        ) else (
            echo ⚠️  Could not rename file (may require admin rights)
        )
    )
    echo.
) else (
    echo ✅ No problematic PowerShell config file found
    echo.
)

REM Step 2: Start the server
echo Step 2: Starting iBridge Local Server...
echo.

cd /d "%~dp0"

REM Try Python first (more reliable)
if exist ".venv\Scripts\python.exe" (
    echo Starting Python HTTP Server on port 8080...
    ".venv\Scripts\python.exe" serve.py
    goto end
)

REM Fallback to Node.js
if exist "node_modules\*" (
    echo Starting Node.js HTTP Server on port 8080...
    node run-server.js
    goto end
)

REM If neither works, show error
echo ❌ Error: Could not start server (Python or Node.js required)
echo.
pause

:end
pause
