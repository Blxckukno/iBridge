@echo off
title iBridge USB Deployment Package
echo ================================================================
echo iBridge USB Deployment Package - Complete Setup Solution
echo ================================================================
echo.
echo This USB contains multiple setup options:
echo.
echo 1. LOCAL DISK SETUP (Copy to local drive for USB independence)
echo    - Run: SETUP-LOCAL-DISK.ps1
echo    - Copies all files to C:\iBridge_Local_Setup\
echo    - Allows USB to be used for other purposes
echo.
echo 2. ENHANCED SETUP - FIXED VERSION (Direct installation)
echo    - Run: RUN-ENHANCED-SETUP-FIXED.bat
echo    - Uses correct drive detection (C: drive paths)
echo    - Installs applications and creates user accounts
echo.
echo 3. NETWORK DEPLOYMENT (For multiple devices via hotspot)
echo    - Run: DEPLOY-TO-NETWORK.ps1
echo    - Deploys to devices connected to iBridge-JHB-* hotspot
echo.
echo ================================================================
echo RECOMMENDED WORKFLOW:
echo ================================================================
echo.
echo STEP 1: Copy to local disk (for USB independence)
echo    powershell.exe -ExecutionPolicy Bypass -File SETUP-LOCAL-DISK.ps1
echo.
echo STEP 2: Run the fixed enhanced setup
echo    RUN-ENHANCED-SETUP-FIXED.bat
echo.
echo STEP 3: For multiple devices, use network deployment
echo    powershell.exe -ExecutionPolicy Bypass -File DEPLOY-TO-NETWORK.ps1
echo.
echo ================================================================
echo Choose your deployment method:
echo ================================================================
echo [1] Local Disk Setup (Recommended first)
echo [2] Enhanced Setup - Fixed Version
echo [3] Network Deployment
echo [4] Exit
echo.
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto local_setup
if "%choice%"=="2" goto enhanced_setup
if "%choice%"=="3" goto network_setup
if "%choice%"=="4" goto exit
goto menu

:local_setup
echo.
echo Running Local Disk Setup...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0SETUP-LOCAL-DISK.ps1"
pause
goto exit

:enhanced_setup
echo.
echo Running Enhanced Setup - Fixed Version...
call "%~dp0RUN-ENHANCED-SETUP-FIXED.bat"
pause
goto exit

:network_setup
echo.
echo Running Network Deployment...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0DEPLOY-TO-NETWORK.ps1"
pause
goto exit

:exit
echo.
echo ================================================================
echo iBridge USB Deployment Package
echo Thank you for using iBridge setup tools!
echo ================================================================
pause
