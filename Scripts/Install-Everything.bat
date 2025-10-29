@echo off
echo.
echo ============================================================
echo     iBridge Application Installation System
echo ============================================================
echo.
echo This will install applications and create shortcuts for both user accounts.
echo.
echo IMPORTANT: Make sure all source files are accessible on D: drive
echo.
pause

:: Check if running as Administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with Administrator privileges...
    echo.
    echo Step 1: Validating source files...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0Validate-Files.ps1"
    echo.
    echo Step 2: Installing applications and creating shortcuts...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0Install-Apps-And-Shortcuts.ps1"
) else (
    echo Requesting Administrator privileges...
    powershell.exe -Command "Start-Process cmd.exe -ArgumentList '/c ""%~f0""' -Verb RunAs"
)

echo.
pause
