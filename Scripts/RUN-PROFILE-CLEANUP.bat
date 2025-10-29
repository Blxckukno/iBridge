@echo off
echo ============================================
echo iBridge Profile Isolation Tool
echo ============================================
echo.
echo This will remove unwanted shortcuts from:
echo - Admin profile
echo - iBridge User profile  
echo.
echo Your Lwandile Gasela profile will be untouched.
echo.
pause

PowerShell -Command "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0Profile-Isolation.ps1\"' -Verb RunAs"

echo.
echo Script launched with Administrator privileges.
echo Check the PowerShell window for results.
pause
