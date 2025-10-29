@echo off
:: iBridge Setup Menu - Simplified and Fixed

setlocal enabledelayedexpansion

:: Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

echo.
echo ================================================================================
echo                             iBridge Setup Menu
echo ================================================================================
echo.
echo Choose your setup option:
echo.
echo [1] Check Required Files   - Verify all files exist before setup
echo [2] Run Enhanced Setup     - Complete setup with 6 specific applications
echo [3] View Documentation     - Read about features and files
echo [4] Exit
echo.

:menu
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto checkfiles
if "%choice%"=="2" goto enhanced  
if "%choice%"=="3" goto readme
if "%choice%"=="4" goto exit
echo Invalid choice. Please enter 1, 2, 3, or 4.
goto menu

:checkfiles
echo.
echo Checking Required Files...
echo ================================================================================
echo Running from: %SCRIPT_DIR%
if exist "%SCRIPT_DIR%Check-Required-Files.ps1" (
    cd /d "%SCRIPT_DIR%"
    powershell -ExecutionPolicy Bypass -File "Check-Required-Files.ps1"
    echo.
    echo Press any key to return to menu...
    pause >nul
) else (
    echo ERROR: Check-Required-Files.ps1 not found!
    echo Expected location: %SCRIPT_DIR%Check-Required-Files.ps1
    pause
)
goto menu

:enhanced
echo.
echo Starting Enhanced iBridge Setup...
echo ================================================================================
echo Running from: %SCRIPT_DIR%
if exist "%SCRIPT_DIR%RUN-ENHANCED-SETUP.bat" (
    cd /d "%SCRIPT_DIR%"
    call "RUN-ENHANCED-SETUP.bat"
) else (
    echo ERROR: RUN-ENHANCED-SETUP.bat not found!
    echo Expected location: %SCRIPT_DIR%RUN-ENHANCED-SETUP.bat
    echo.
    echo Files in directory:
    dir "%SCRIPT_DIR%*.bat"
    echo.
    pause
)
goto end

:readme
echo.
echo ================================================================================
echo                               Documentation
echo ================================================================================
echo.
echo Opening documentation files in Notepad...
if exist "%SCRIPT_DIR%README.md" start notepad "%SCRIPT_DIR%README.md"
if exist "%SCRIPT_DIR%SPECIFIC-FILES-README.md" start notepad "%SCRIPT_DIR%SPECIFIC-FILES-README.md"
if exist "%SCRIPT_DIR%ENHANCED-README.md" start notepad "%SCRIPT_DIR%ENHANCED-README.md"
echo.
echo Documentation files opened. Close them and press any key to return to menu...
pause >nul
goto menu

:exit
echo.
echo Goodbye!
goto end

:end
echo.
echo Press any key to exit...
pause >nul
