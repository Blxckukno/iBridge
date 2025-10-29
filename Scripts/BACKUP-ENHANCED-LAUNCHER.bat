@echo off
:: Backup Enhanced Setup Launcher
:: This launcher includes additional error handling

title iBridge Enhanced Setup - Backup Launcher
color 0A

echo ===============================================================================
echo                        iBridge Enhanced Setup - Backup Launcher
echo ===============================================================================
echo.
echo This backup launcher will attempt to run the enhanced setup with
echo additional error handling and diagnostics.
echo.
echo Press any key to start the enhanced setup...
pause > nul

echo.
echo Starting Enhanced Setup...
echo ===============================================================================

:: Set the script path
set "SCRIPT_PATH=%~dp0iBridge-Enhanced-Setup.ps1"

:: Check if script exists
if not exist "%SCRIPT_PATH%" (
    echo ERROR: Script not found at %SCRIPT_PATH%
    echo.
    pause
    exit /b 1
)

:: Run with error handling
echo Running PowerShell script...
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "& { try { & '%SCRIPT_PATH%' } catch { Write-Host 'Script Error:' -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red; Write-Host $_.ScriptStackTrace -ForegroundColor Yellow; pause } }"

:: Check exit code
if %ERRORLEVEL% neq 0 (
    echo.
    echo ===============================================================================
    echo                             Setup Failed
    echo ===============================================================================
    echo.
    echo Error code: %ERRORLEVEL%
    echo Check the error messages above for details.
    echo.
) else (
    echo.
    echo ===============================================================================
    echo                          Setup Completed Successfully
    echo ===============================================================================
    echo.
)

echo Press any key to exit...
pause > nul
