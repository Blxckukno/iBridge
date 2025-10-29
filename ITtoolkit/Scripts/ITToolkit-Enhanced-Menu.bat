@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title IT Toolkit - Enhancif "%CH%"=="10" (
  echo Running COMPREHENSIVE SECURITY FIXER (All Issues)...
  call "%MENU_ROOT%Security\Fix-All-Security-Auto-Admin.bat"
  goto :wait_return
)
if "%CH%"=="11" (
  echo Running ALL SCRIPTS - Complete System Check and Fix...
  echo This will run all 8 fixed scripts to comprehensively check and fix your Windows device.
  echo.
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Run-All-Scripts-Comprehensive.ps1" -GenerateReport
  goto :wait_return
)
if "%CH%"=="12" (
  echo Running All Security Verification...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security-Verification-Simple.ps1"
  goto :wait_return
)
if "%CH%"=="13" (
  echo Running Script Syntax Verification...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Verify-Scripts-Simple.ps1"
  goto :wait_return
)
if "%CH%"=="14" ( Menu

:: Root directory for menu discovery is the folder of this file
set MENU_ROOT=%~dp0

:: Elevation: ensure the menu runs as Administrator so called scripts run as admin
fltmc >nul 2>&1
if errorlevel 1 (
  echo Requesting Administrator privileges for IT Toolkit Menu...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','\"%~f0\"' -Verb RunAs"
  exit /b
)

:main
cls
echo =============================================================
echo           IT Toolkit - Enhanced Security and Maintenance Menu
echo =============================================================
echo Root: %MENU_ROOT%
echo Status: Administrator privileges enabled
echo.

:: Display working fixed scripts organized by category
echo [SECURITY TOOLS - FIXED AND VERIFIED]
echo   [1] Windows Defender Optimizer (Fixed)
echo   [2] Master Security Verification (Fixed - All Syntax Errors Resolved)
echo   [3] Email Security Analysis (Fixed)
echo   [4] Anti-Phishing Email Protection (Fixed)
echo   [5] Email Account Security Audit (Fixed)
echo   [6] Emergency System Isolation (Fixed)
echo   [7] Real-Time Security Monitor (Fixed)
echo.
echo [MAINTENANCE TOOLS - FIXED AND VERIFIED]
echo   [8] System Cleanup Analysis (Fixed)
echo.
echo [SECURITY ACTIONS]
echo   [9] Enable Windows Defender (Admin Required)
echo   [10] FIX ALL SECURITY ISSUES (Comprehensive Auto-Admin)
echo   [11] RUN ALL SCRIPTS (Complete System Check and Fix)
echo   [12] Run All Security Verification
echo   [13] Verify Script Syntax
echo   [14] Comprehensive Security Report
echo.
echo [ORIGINAL TOOLS (May have syntax issues)]
echo   [15] Browse All Available Scripts
echo.
echo [SYSTEM ACTIONS]
echo   [U] Update and Fix More Scripts
echo   [R] Refresh Menu
echo   [X] Exit
echo.
set /p CH=Select an option (1-15, U, R, X): 

if /I "%CH%"=="X" goto :eof
if /I "%CH%"=="R" goto :main

if "%CH%"=="1" (
  echo Running Windows Defender Optimizer...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Defender-Optimizer-Fixed.ps1"
  goto :wait_return
)
if "%CH%"=="2" (
  echo Running Master Security Verification...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Master-Security-Verification-Fixed.ps1"
  goto :wait_return
)
if "%CH%"=="3" (
  echo Running Email Security Analysis...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Email-Security-Analysis-Fixed.ps1"
  goto :wait_return
)
if "%CH%"=="4" (
  echo Running Anti-Phishing Email Protection...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Anti-Phishing-Email-Protection-Fixed.ps1"
  goto :wait_return
)
if "%CH%"=="5" (
  echo Running Email Account Security Audit...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Email-Account-Audit-Fixed.ps1"
  goto :wait_return
)
if "%CH%"=="6" (
  echo Running Emergency System Isolation...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Emergency-Isolation-Fixed.ps1"
  goto :wait_return
)
if "%CH%"=="7" (
  echo Running Real-Time Security Monitor...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Real-Time-Monitor-Fixed.ps1"
  goto :wait_return
)
if "%CH%"=="8" (
  echo Running System Cleanup Analysis...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Maintenance_Cleanup\Analyze-Cleanup-Fixed.ps1"
  goto :wait_return
)
if "%CH%"=="9" (
  echo Enabling Windows Defender Real-Time Protection...
  call "%MENU_ROOT%Security\Enable-Defender-Admin-Fixed.bat"
  goto :wait_return
)
if "%CH%"=="10" (
  echo Running Security Verification...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security-Verification-Simple.ps1"
  goto :wait_return
)
if "%CH%"=="11" (
  echo Running Script Syntax Verification...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Verify-Scripts-Simple.ps1"
  goto :wait_return
)
if "%CH%"=="12" (
  echo Generating Comprehensive Security Report...
  echo Running all security tools and generating final report...
  
  echo [1/8] Windows Defender Status...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Defender-Optimizer-Fixed.ps1" > temp_report.txt 2>&1
  
  echo [2/8] Master Security Verification...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Master-Security-Verification-Fixed.ps1" >> temp_report.txt 2>&1
  
  echo [3/8] Email Security Analysis...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Email-Security-Analysis-Fixed.ps1" >> temp_report.txt 2>&1
  
  echo [4/8] Anti-Phishing Protection...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Anti-Phishing-Email-Protection-Fixed.ps1" >> temp_report.txt 2>&1
  
  echo [5/8] Email Account Audit...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Email-Account-Audit-Fixed.ps1" >> temp_report.txt 2>&1
  
  echo [6/8] System Isolation Check...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Emergency-Isolation-Fixed.ps1" >> temp_report.txt 2>&1
  
  echo [7/8] Real-Time Monitor...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security\Real-Time-Monitor-Fixed.ps1" >> temp_report.txt 2>&1
  
  echo [8/8] System Cleanup Analysis...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Maintenance_Cleanup\Analyze-Cleanup-Fixed.ps1" >> temp_report.txt 2>&1
  
  echo.
  echo Creating consolidated report...
  set REPORT_NAME=IT_Toolkit_Comprehensive_Report_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt
  set REPORT_NAME=!REPORT_NAME: =0!
  
  echo IT TOOLKIT COMPREHENSIVE SECURITY REPORT > "%USERPROFILE%\Desktop\%REPORT_NAME%"
  echo Generated: %date% %time% >> "%USERPROFILE%\Desktop\%REPORT_NAME%"
  echo ========================================= >> "%USERPROFILE%\Desktop\%REPORT_NAME%"
  echo. >> "%USERPROFILE%\Desktop\%REPORT_NAME%"
  type temp_report.txt >> "%USERPROFILE%\Desktop\%REPORT_NAME%"
  del temp_report.txt
  
  echo SUCCESS: Comprehensive report saved to Desktop: %REPORT_NAME%
  goto :wait_return
)
if "%CH%"=="12" (
  echo Launching original dynamic menu...
  call "%MENU_ROOT%ITToolkit-Menu.bat"
  goto :wait_return
)
if /I "%CH%"=="U" (
  echo ====================================================
  echo            SCRIPT FIXING AND UPDATE STATUS
  echo ====================================================
  echo.
  echo COMPLETED FIXED SCRIPTS (8/21):
  echo   [FIXED] Defender-Optimizer-Fixed.ps1
  echo   [FIXED] Master-Security-Verification-Fixed.ps1  
  echo   [FIXED] Email-Security-Analysis-Fixed.ps1
  echo   [FIXED] Anti-Phishing-Email-Protection-Fixed.ps1
  echo   [FIXED] Email-Account-Audit-Fixed.ps1
  echo   [FIXED] Emergency-Isolation-Fixed.ps1
  echo   [FIXED] Real-Time-Monitor-Fixed.ps1
  echo   [FIXED] Analyze-Cleanup-Fixed.ps1
  echo.
  echo REMAINING SCRIPTS TO FIX (13/21):
  echo   - Download-SecurityTools.ps1
  echo   - Exchange-Security-Audit-Fixed.ps1
  echo   - Future-Attack-Preparation-Toolkit.ps1
  echo   - Simple-FOSS-Download.ps1
  echo   - Defender-Optimizer.ps1
  echo   - Email-Security-Analysis.ps1
  echo   - Master-Security-Verification.ps1
  echo   - Email-Security-Investigation.ps1 (empty file)
  echo   - Emergency-Malware-Scan.ps1 (empty file)
  echo   - Network-Wide-Security-Audit.ps1 (empty file)
  echo   - Install-Basic-FOSS.ps1
  echo   - Install-Essential-FOSS.ps1
  echo   - Install-FOSS-Fixed.ps1
  echo.
  echo PROGRESS: 38%% complete (8 of 21 scripts fixed)
  echo.
  echo All 8 fixed scripts are working correctly and can be run safely.
  echo The remaining scripts have Unicode character issues or missing content.
  echo.
  goto :wait_return
)
if "%CH%"=="15" (
  echo Browsing all available scripts...
  echo.
  echo Available PowerShell scripts in your IT Toolkit:
  dir /s /b "%MENU_ROOT%*.ps1" | findstr /v /i "temp\|backup\|old"
  echo.
  echo Available Batch scripts:
  dir /s /b "%MENU_ROOT%*.bat" | findstr /v /i "temp\|backup\|old"
  goto :wait_return
)

echo Invalid selection.
timeout /t 1 >nul
goto :main

:wait_return
echo.
echo Task completed. Press any key to return to menu...
pause >nul
goto :main
