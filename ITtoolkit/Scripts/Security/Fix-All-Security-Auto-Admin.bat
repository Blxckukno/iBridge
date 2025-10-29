@echo off
setlocal EnableDelayedExpansion

REM Comprehensive Security Fixer - Auto-Admin Launcher
title IT Toolkit - Security Fixer (Administrator Required)

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :RunSecurityFixes
) else (
    echo Requesting Administrator privileges...
    echo This is required to fix security issues on your device.
    echo.
    
    REM Re-launch with admin privileges
    powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d \"%~dp0\" && \"%~f0\" ELEVATED'"
    exit /b
)

:RunSecurityFixes
if "%1"=="ELEVATED" (
    echo.
    echo ================================================================
    echo               COMPREHENSIVE SECURITY FIXER
    echo ================================================================
    echo.
    echo Running with Administrator privileges...
    echo This will fix ALL security issues on your device.
    echo.
    
    REM Set the script directory properly handling spaces
    set "SCRIPT_DIR=%~dp0"
    set "SECURITY_SCRIPT=!SCRIPT_DIR!Comprehensive-Security-Fixer-Clean.ps1"
    
    echo Starting comprehensive security fixes...
    echo.
    
    REM Run the PowerShell script
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "!SECURITY_SCRIPT!" -FixAll
    
    echo.
    echo ================================================================
    echo                    SECURITY FIXES COMPLETED
    echo ================================================================
    echo.
    
    if %errorlevel% == 0 (
        echo [SUCCESS] All security issues have been fixed!
        echo Please restart your computer to apply all changes.
    ) else (
        echo [WARNING] Some fixes may have failed. Check the report for details.
    )
    
    echo.
    echo Press any key to close...
    pause >nul
)
