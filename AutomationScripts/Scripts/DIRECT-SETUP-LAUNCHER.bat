@echo off
:: Direct Enhanced Setup Launcher - Simple and Reliable

echo.
echo ================================================================================
echo                        iBridge Enhanced Setup - Direct Launch
echo ================================================================================
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

:: Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
echo Script directory: %SCRIPT_DIR%

:: Check for PowerShell script
set "PS_SCRIPT=%SCRIPT_DIR%iBridge-Enhanced-Setup.ps1"

if not exist "%PS_SCRIPT%" (
    echo [ERROR] Could not find iBridge-Enhanced-Setup.ps1
    echo Expected location: %PS_SCRIPT%
    echo.
    echo Current directory contents:
    dir "%SCRIPT_DIR%*.ps1"
    echo.
    pause
    exit /b 1
)

echo [SUCCESS] Found PowerShell script: %PS_SCRIPT%
echo.

echo Starting Enhanced Setup...
echo ================================================================================
echo.

:: Change to script directory and execute
cd /d "%SCRIPT_DIR%"
powershell -ExecutionPolicy Bypass -File "iBridge-Enhanced-Setup.ps1" -NoProfile

:: Check result
if %errorlevel% equ 0 (
    echo.
    echo ================================================================================
    echo                           Setup Completed Successfully!
    echo ================================================================================
    echo.
) else (
    echo.
    echo ================================================================================
    echo                              Setup Failed!
    echo ================================================================================
    echo.
    echo Error code: %errorlevel%
    echo Check the log files in C:\iBridge_Setup\Logs\
    echo.
)

echo Press any key to exit...
pause >nul
