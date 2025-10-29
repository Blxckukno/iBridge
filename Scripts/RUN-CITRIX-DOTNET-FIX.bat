@echo off
title iBridge Citrix .NET Core 8.0 Fix
echo ================================================================
echo iBridge Citrix .NET Core 8.0 Prerequisite Fix
echo ================================================================
echo.
echo This script will:
echo   - Download and install .NET Core 8.0 Desktop Runtime
echo   - Fix the Citrix Workspace App prerequisite error
echo   - Complete the iBridge setup with all applications
echo   - Set up user accounts and shortcuts
echo.
echo The error you saw:
echo   "Unable to install prerequisites. Install them manually"
echo   ".Net Core 8.0 or later"
echo.
echo This will be AUTOMATICALLY RESOLVED!
echo.
pause

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running Citrix .NET Core 8.0 fix...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0CITRIX-DOTNET-FIX.ps1"

echo.
echo ================================================================
echo CITRIX .NET CORE 8.0 FIX COMPLETED!
echo ================================================================
echo.
echo NEXT STEPS:
echo   1. Log out of current Windows session
echo   2. Log in as 'iBridge User' (Password: Abc654321!)
echo   3. Install Citrix Workspace App - error should be resolved
echo   4. .NET Core 8.0 Desktop Runtime is now installed
echo.
echo The prerequisite error should no longer appear!
echo.
pause
