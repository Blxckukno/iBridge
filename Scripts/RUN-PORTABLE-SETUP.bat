@echo off
:: iBridge Portable Setup Launcher
:: This batch file can be run from any location and will automatically
:: find and execute the PowerShell setup script

setlocal enabledelayedexpansion

:: Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo.
echo ================================================================================
echo                          iBridge Portable Setup Launcher
echo ================================================================================
echo.
echo Script Location: %SCRIPT_DIR%
echo.

:: Check if running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] This script requires Administrator privileges.
    echo.
    echo Please right-click this file and select "Run as administrator"
    echo OR
    echo The script will attempt to restart with elevated privileges...
    echo.
    pause
    
    :: Try to restart with elevated privileges
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo [SUCCESS] Running with Administrator privileges
echo.

:: Look for the PowerShell script in the same directory
set "PS_SCRIPT=%SCRIPT_DIR%\iBridge-Portable-Setup.ps1"

if not exist "%PS_SCRIPT%" (
    echo [ERROR] Could not find iBridge-Portable-Setup.ps1 in the same directory
    echo.
    echo Expected location: %PS_SCRIPT%
    echo.
    echo Please ensure the PowerShell script is in the same folder as this batch file.
    echo.
    pause
    exit /b 1
)

echo [SUCCESS] Found PowerShell script: %PS_SCRIPT%
echo.

:: Check PowerShell execution policy
echo Checking PowerShell execution policy...
powershell -Command "Get-ExecutionPolicy" > temp_policy.txt
set /p CURRENT_POLICY=<temp_policy.txt
del temp_policy.txt

echo Current PowerShell execution policy: %CURRENT_POLICY%

if /i "%CURRENT_POLICY%"=="Restricted" (
    echo.
    echo [WARNING] PowerShell execution policy is Restricted.
    echo This will prevent the script from running.
    echo.
    echo Do you want to temporarily change the execution policy to RemoteSigned? (Y/N)
    set /p CHANGE_POLICY=
    
    if /i "!CHANGE_POLICY!"=="Y" (
        echo Changing execution policy...
        powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope Process -Force"
        echo [SUCCESS] Execution policy changed for this session
    ) else (
        echo [ERROR] Cannot proceed without changing execution policy
        pause
        exit /b 1
    )
)

echo.
echo ================================================================================
echo                            Starting Setup Process
echo ================================================================================
echo.

:: Execute the PowerShell script
powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -NoProfile

:: Check if the script completed successfully
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
    echo Please check the error messages above and try again.
    echo.
)

echo Press any key to exit...
pause >nul
