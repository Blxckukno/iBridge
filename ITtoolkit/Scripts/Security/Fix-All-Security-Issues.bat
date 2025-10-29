@echo off
title IT Toolkit - Comprehensive Security Fixer
color 0B

echo.
echo ================================================================
echo                  COMPREHENSIVE SECURITY FIXER
echo ================================================================
echo.
echo This will fix all major security issues on your device:
echo   - Enable Windows Defender Real-Time Protection
echo   - Update Defender signatures
echo   - Enable Windows Firewall
echo   - Configure User Account Control (UAC)
echo   - Disable unnecessary services
echo   - Configure Windows Updates
echo   - Secure password policies
echo   - Enable security audit logging
echo   - Disable Guest account
echo   - Configure automatic screen lock
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] Running with Administrator privileges...
    echo.
) else (
    echo [ERROR] Administrator privileges required!
    echo.
    echo Please right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Set the script directory properly handling spaces
set "SCRIPT_DIR=%~dp0"
set "SECURITY_SCRIPT=%SCRIPT_DIR%Comprehensive-Security-Fixer.ps1"

echo [INFO] Starting comprehensive security fixes...
echo.

REM Run the PowerShell script with proper path handling
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "& '%SECURITY_SCRIPT%' -FixAll"

if %errorlevel% == 0 (
    echo.
    echo ================================================================
    echo                    SECURITY FIXES COMPLETED!
    echo ================================================================
    echo All security issues have been addressed successfully.
    echo Please restart your computer to apply all changes.
) else (
    echo.
    echo ================================================================
    echo                  SOME FIXES FAILED OR INCOMPLETE
    echo ================================================================
    echo Check the report file for details on what needs attention.
)

echo.
echo Press any key to continue...
pause >nul
