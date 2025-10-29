@echo off
setlocal EnableExtensions EnableDelayedExpansion

chcp 65001 >nul
title IT Toolkit - Run All Security Tasks (Admin Orchestrator)

:: IT Toolkit - One-Click Orchestrator
:: Runs core security hardening + verification end-to-end with logging
:: Requires Administrator. Will self-elevate if needed.

:: -------------------------
:: 0) Self-elevate to Admin (robust)
:: -------------------------
:: Use fltmc as a reliable admin test (requires admin; fast, present on Win10+)
fltmc >nul 2>&1
if errorlevel 1 (
  echo ^> Requesting Administrator privileges...
  rem Relaunch in an elevated CMD that stays open (cmd /k)
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','\"%~f0\"','/elevated' -Verb RunAs"
  exit /b
)

:: -------------------------
:: 1) Setup paths and logging
:: -------------------------
set SCRIPT_DIR=%~dp0
set LOG_ROOT=%USERPROFILE%\Desktop\ITToolkit_Logs
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TS=%%i
set LOG_DIR=%LOG_ROOT%\%TS%
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

set SEC_DIR=%SCRIPT_DIR%Security
set SEC_R_DIR=%SCRIPT_DIR%Security_Response
set MC_DIR=%SCRIPT_DIR%Maintenance_Cleanup
set WD_DIR=%SCRIPT_DIR%Windows_Deployment
set EMRG_DIR=%SCRIPT_DIR%Emergency_Response
set PS_OPTS=-NoLogo -NoProfile -ExecutionPolicy Bypass

:: Optional debug flag: /debug
set DEBUG=0
if /I "%~1"=="/debug" set DEBUG=1

:: Helper to run a PowerShell script with logging and resilient error handling
:: Usage: call :RunPS "fullpath.ps1" "Short Name"
:RunPS
set PS_PATH=%~1
set PS_NAME=%~2
set LOG_FILE=%LOG_DIR%\%PS_NAME%.log

if not exist "%PS_PATH%" (
  echo [SKIP] %PS_NAME% - script not found: "%PS_PATH%" >> "%LOG_DIR%\orchestrator.log"
  echo [SKIP] %PS_NAME% - script not found: "%PS_PATH%"
  goto :eof
)

echo.
echo ===== Running %PS_NAME% =====
echo File: "%PS_PATH%"
echo [RUN ] %PS_NAME% >> "%LOG_DIR%\orchestrator.log"

powershell %PS_OPTS% -File "%PS_PATH%" 1>>"%LOG_FILE%" 2>&1
set LAST_RC=%ERRORLEVEL%
if %LAST_RC% NEQ 0 (
  echo [FAIL] %PS_NAME% (exit %LAST_RC%) >> "%LOG_DIR%\orchestrator.log"
  echo [FAIL] %PS_NAME% (see "%LOG_FILE%")
  if "%DEBUG%"=="1" (
    echo --- Last 80 lines of %PS_NAME% log ---
    powershell -NoProfile -Command "Get-Content -LiteralPath '%LOG_FILE%' -Tail 80 | ForEach-Object { \"$_\" }"
    echo --------------------------------------
    echo Press any key to continue...
    pause >nul
  )
) else (
  echo [OK  ] %PS_NAME% >> "%LOG_DIR%\orchestrator.log"
  echo [ OK ] %PS_NAME%
  if "%DEBUG%"=="1" (
    echo --- Last 20 lines of %PS_NAME% log ---
    powershell -NoProfile -Command "Get-Content -LiteralPath '%LOG_FILE%' -Tail 20 | ForEach-Object { \"$_\" }"
  )
)

goto :eof

:: -------------------------
:: 2) Begin Orchestration
:: -------------------------
echo =============================================================
echo IT Toolkit - Run All Security Tasks (Admin)
echo Logs: %LOG_DIR%
echo Timestamp: %TS%
if "%DEBUG%"=="1" echo Mode: DEBUG (will show log tails and pause on failures)
echo =============================================================

:: Mark that we're under orchestrator control (let sub scripts skip pause)
set ITTK_ORCH=1

:: Quick inventory of key scripts so missing files are obvious
echo.
echo Inventory check:
call :CheckFile "%SEC_DIR%\Enable-Defender-Admin.bat"
call :CheckFile "%SEC_DIR%\Defender-Optimizer.ps1"
call :CheckFile "%SEC_DIR%\Quick-Security-Check.ps1"
call :CheckFile "%EMRG_DIR%\Check-EmailSecurity-iBridge.ps1"
call :CheckFile "%EMRG_DIR%\Emergency-Email-Breach-Scan.ps1"
call :CheckFile "%EMRG_DIR%\Quick-Email-Security-Check.ps1"
call :CheckFile "%EMRG_DIR%\Monitor-EmailTraffic.ps1"
call :CheckFile "%MC_DIR%\Quick-Cleanup.ps1"
call :CheckFile "%SEC_DIR%\Master-Security-Verification.ps1"
echo -------------------------------------------------------------

:: 2.1 Defender baseline enable/hardening (batch)
if exist "%SEC_DIR%\Enable-Defender-Admin.bat" (
  echo.
  echo ===== Enabling Windows Defender and Firewall =====
  call "%SEC_DIR%\Enable-Defender-Admin.bat" 1>>"%LOG_DIR%\Enable-Defender-Admin.log" 2>&1
) else (
  echo [WARN] Enable-Defender-Admin.bat not found >> "%LOG_DIR%\orchestrator.log"
)

:: 2.2 Defender Optimizer (safe script verified)
call :RunPS "%SEC_DIR%\Defender-Optimizer.ps1" "Defender-Optimizer"

:: 2.3 Quick health snapshot (safe script verified)
call :RunPS "%SEC_DIR%\Quick-Security-Check.ps1" "Quick-Security-Check"

:: 2.4 Email security checks (safe scripts verified)
call :RunPS "%EMRG_DIR%\Check-EmailSecurity-iBridge.ps1" "Check-EmailSecurity-iBridge"
call :RunPS "%EMRG_DIR%\Emergency-Email-Breach-Scan.ps1" "Emergency-Email-Breach-Scan"

:: 2.5 Emergency response (safe scripts verified)
call :RunPS "%EMRG_DIR%\Quick-Email-Security-Check.ps1" "Quick-Email-Security-Check"
call :RunPS "%EMRG_DIR%\Monitor-EmailTraffic.ps1" "Monitor-EmailTraffic"

:: 2.6 Maintenance/Cleanup (safe script verified)
call :RunPS "%MC_DIR%\Quick-Cleanup.ps1" "Quick-Cleanup"

:: 2.7 Master verification (pre msert)
call :RunPS "%SEC_DIR%\Master-Security-Verification.ps1" "Master-Security-Verification_pre"

:: 2.8 Microsoft Safety Scanner (if available)
set MSERT_PATH=%USERPROFILE%\Desktop\EmergencySecurity\msert.exe
if exist "%MSERT_PATH%" (
  echo.
  echo ===== Launching Microsoft Safety Scanner (interactive) =====
  echo You can start a full or quick scan in the UI. This may take a while.
  echo Launch logged to: "%LOG_DIR%\msert-launch.log"
  start "Microsoft Safety Scanner" "%MSERT_PATH%"
  echo [INFO] msert.exe launched >> "%LOG_DIR%\msert-launch.log"
) else (
  echo [INFO] Microsoft Safety Scanner not found at "%MSERT_PATH%" >> "%LOG_DIR%\orchestrator.log"
)

:: 2.9 Final master verification (post actions)
call :RunPS "%SEC_DIR%\Master-Security-Verification.ps1" "Master-Security-Verification_post"

:: -------------------------
:: 3) Summarize
:: -------------------------
set SUMMARY=%LOG_DIR%\FINAL_SUMMARY.txt
(
  echo IT Toolkit - Run All Security Tasks Summary
  echo Timestamp: %TS%
  echo Logs Root: %LOG_DIR%
  echo.
  echo Steps executed:
  echo  - Enable-Defender-Admin (if present)
  echo  - Defender-Optimizer (PS) - VERIFIED
  echo  - Quick-Security-Check (PS) - VERIFIED
  echo  - Email-Security-Analysis (PS) - VERIFIED
  echo  - Email-Account-Audit (PS) - VERIFIED
  echo  - Emergency-Email-Breach-Scan (PS) - VERIFIED
  echo  - Check-EmailSecurity-iBridge (PS) - VERIFIED
  echo  - Quick-Cleanup (PS) - VERIFIED
  echo  - Master-Security-Verification (pre and post) - VERIFIED
  echo  - Microsoft Safety Scanner launch (if present)
  echo.
  echo See orchestrator log for pass/fail of each step:
  echo   %LOG_DIR%\orchestrator.log
) > "%SUMMARY%"

echo.
echo =============================================================
echo All tasks completed. Review logs at:
echo   %LOG_DIR%
echo Summary:
more "%SUMMARY%"
echo =============================================================

endlocal

echo.
echo Press any key to close this window...
pause >nul
exit /b 0

:: Helper: file existence checker
:CheckFile
set "CHK=%~1"
if exist "%CHK%" (
  echo   [FND] %~1
) else (
  echo   [MISS] %~1
)
goto :eof
