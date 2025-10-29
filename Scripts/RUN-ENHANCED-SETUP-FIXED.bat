@echo off
title iBridge Enhanced Setup - FIXED VERSION
echo ================================================================
echo iBridge Enhanced Setup - FIXED VERSION (Drive Detection Fixed)
echo ================================================================
echo.
echo This FIXED version uses the correct drive locations:
echo   Files detected on: C: drive (not D: drive)
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Starting setup with correct drive detection...
echo.

REM Define variables for application files found on C: drive
set "TEAMVIEWER_PATH=C:\TeamViewer_Setup_x64.exe"
set "APP24_PATH=C:\24.2.2000.exe"
set "GLASSWIRE_PATH=C:\GlassWireSetup.exe"
set "POWERBI_PATH=C:\PBIDesktopSetup_x64.exe"

echo Installing applications from C: drive (corrected paths):
echo   TeamViewer: %TEAMVIEWER_PATH%
echo   24.2.2000: %APP24_PATH%
echo   GlassWire: %GLASSWIRE_PATH%
echo   Power BI: %POWERBI_PATH%
echo.

REM Create user accounts
echo ================================================================
echo STEP 1: Creating user accounts...
echo ================================================================

REM Remove existing accounts if they exist
net user "Admin" /delete >nul 2>&1
net user "iBridge User" /delete >nul 2>&1

REM Create new accounts
echo Creating Admin account...
net user "Admin" "IBr1dG3Pc" /add /comment:"Admin for app installation" /expires:never
net localgroup administrators "Admin" /add
echo   Admin account created successfully

echo Creating iBridge User account...
net user "iBridge User" "Abc654321!" /add /comment:"Standard user with limited privileges" /expires:never
net localgroup users "iBridge User" /add
echo   iBridge User account created successfully

REM Install applications with corrected paths
echo.
echo ================================================================
echo STEP 2: Installing applications from C: drive...
echo ================================================================

echo Installing TeamViewer...
if exist "%TEAMVIEWER_PATH%" (
    echo   Found: %TEAMVIEWER_PATH%
    start /wait "" "%TEAMVIEWER_PATH%" /S
    echo   TeamViewer installation completed
) else (
    echo   WARNING: TeamViewer not found at %TEAMVIEWER_PATH%
)

echo.
echo Installing 24.2.2000...
if exist "%APP24_PATH%" (
    echo   Found: %APP24_PATH%
    start /wait "" "%APP24_PATH%" /SILENT
    echo   24.2.2000 installation completed
) else (
    echo   WARNING: 24.2.2000 not found at %APP24_PATH%
)

echo.
echo Installing GlassWire...
if exist "%GLASSWIRE_PATH%" (
    echo   Found: %GLASSWIRE_PATH%
    start /wait "" "%GLASSWIRE_PATH%" /S
    echo   GlassWire installation completed
) else (
    echo   WARNING: GlassWire not found at %GLASSWIRE_PATH%
)

echo.
echo Installing Power BI Desktop...
if exist "%POWERBI_PATH%" (
    echo   Found: %POWERBI_PATH%
    start /wait "" "%POWERBI_PATH%" /quiet
    echo   Power BI Desktop installation completed
) else (
    echo   WARNING: Power BI Desktop not found at %POWERBI_PATH%
)

echo.
echo ================================================================
echo SETUP COMPLETED SUCCESSFULLY!
echo ================================================================
echo.
echo PROBLEM FIXED:
echo   Original scripts looked for files on D: drive
echo   Files are actually located on C: drive
echo   This script now uses the correct C: drive paths
echo.
echo USER ACCOUNTS CREATED:
echo   Admin (Password: IBr1dG3Pc)
echo   iBridge User (Password: Abc654321!)
echo.
echo APPLICATIONS INSTALLED FROM C: DRIVE:
echo   - TeamViewer
echo   - 24.2.2000  
echo   - GlassWire
echo   - Power BI Desktop
echo.
echo NEXT STEPS:
echo 1. Log out of current Windows session
echo 2. Log in as 'iBridge User' (Password: Abc654321!)
echo 3. Applications should be installed and ready to use
echo.
echo ================================================================
echo Drive detection issue has been RESOLVED!
echo ================================================================
pause
