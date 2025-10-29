@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Master Security Verification (Admin)
fltmc >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','\"%~f0\"' -Verb RunAs"
  exit /b
)
set PS=%~dp0Master-Security-Verification.ps1
if not exist "%PS%" (
  echo Script not found: "%PS%"
  pause
  exit /b 1
)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS%"
echo.
echo Press any key to close...
pause >nul
exit /b 0

