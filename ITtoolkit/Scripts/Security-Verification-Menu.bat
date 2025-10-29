@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title IT Toolkit - Security Verification System

:: Ensure admin privileges for comprehensive security scanning
fltmc >nul 2>&1
if errorlevel 1 (
  echo ^> Requesting Administrator privileges for comprehensive security verification...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','\"%~f0\"' -Verb RunAs"
  exit /b
)

set SCRIPT_DIR=%~dp0

echo =============================================================
echo      IT Toolkit Comprehensive Security Verification
echo =============================================================
echo.
echo This tool will perform a comprehensive security analysis of
echo all scripts in the IT Toolkit to ensure they are:
echo   1. Free of malware and suspicious code
echo   2. Syntactically correct and functional
echo   3. Using only trusted download sources
echo   4. Safe for enterprise deployment
echo.

:menu
echo Select verification level:
echo   [1] Quick Safety Check (syntax + basic security)
echo   [2] Standard Security Scan (comprehensive security analysis)
echo   [3] Deep Security Scan (includes download link validation)
echo   [4] Full Verification (all checks + file integrity)
echo   [5] View Previous Report
echo   [Q] Quit
echo.
set /p choice=Enter your choice [1-5, Q]: 

if /I "%choice%"=="Q" goto :eof
if "%choice%"=="5" goto :viewreport

set PS_ARGS=
if "%choice%"=="1" set PS_ARGS=
if "%choice%"=="2" set PS_ARGS=
if "%choice%"=="3" set PS_ARGS=-ValidateDownloads
if "%choice%"=="4" set PS_ARGS=-ValidateDownloads -DeepScan -CheckSignatures

if not defined PS_ARGS (
  echo Invalid choice. Please try again.
  timeout /t 2 >nul
  goto :menu
)

cls
echo =============================================================
echo Running Security Verification...
echo =============================================================

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Security-Verification-System.ps1" %PS_ARGS%
set SCAN_RESULT=%ERRORLEVEL%

echo.
echo =============================================================
echo Verification completed with exit code: %SCAN_RESULT%
echo.

if %SCAN_RESULT%==0 (
  echo ✅ RESULT: All scripts passed security verification
  echo    Your IT Toolkit is SAFE for deployment
) else if %SCAN_RESULT%==1 (
  echo ⚠️ RESULT: Some scripts flagged for review
  echo    Manual review recommended before deployment
) else if %SCAN_RESULT%==2 (
  echo ❌ RESULT: Potential malware detected
  echo    DO NOT USE flagged scripts until verified safe
) else (
  echo ❓ RESULT: Verification encountered errors
  echo    Check the detailed report for more information
)

echo.
echo Press any key to return to menu...
pause >nul
goto :menu

:viewreport
cls
echo =============================================================
echo Latest Security Verification Report
echo =============================================================

for /f "delims=" %%f in ('dir /b /o-d "%SCRIPT_DIR%Security_Verification_Report_*.txt" 2^>nul') do (
  echo Report: %%f
  echo.
  type "%SCRIPT_DIR%%%f"
  goto :reportshown
)

echo No verification reports found.
echo Run a security scan first to generate a report.

:reportshown
echo.
echo Press any key to return to menu...
pause >nul
goto :menu
