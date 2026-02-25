@echo off
:: iBridge Setup Menu - Choose Your Version

setlocal enabledelayedexpansion

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
if exist "%~dp0Check-Required-Files.ps1" (
    powershell -ExecutionPolicy Bypass -File "%~dp0Check-Required-Files.ps1"
) else (
    echo ERROR: Check-Required-Files.ps1 not found!
    echo Expected location: %~dp0Check-Required-Files.ps1
    pause
)
goto menu

:enhanced
echo.
echo Starting Enhanced iBridge Setup...
echo ================================================================================
echo Current directory: %CD%
echo Looking for: %~dp0RUN-ENHANCED-SETUP.bat
if exist "%~dp0RUN-ENHANCED-SETUP.bat" (
    call "%~dp0RUN-ENHANCED-SETUP.bat"
) else (
    echo ERROR: RUN-ENHANCED-SETUP.bat not found!
    echo Expected location: %~dp0RUN-ENHANCED-SETUP.bat
    dir "%~dp0*.bat"
    pause
)
goto end

:readme
echo.
echo ================================================================================
echo                               README Files
echo ================================================================================
echo.
echo Opening documentation files in Notepad...
if exist "README.md" start notepad "README.md"
if exist "SPECIFIC-FILES-README.md" start notepad "SPECIFIC-FILES-README.md"
if exist "ENHANCED-README.md" start notepad "ENHANCED-README.md"
echo.
echo README files opened. Close them and press any key to return to menu...
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
