@echo off
:: iBridge Enhanced Setup Menu v2.0
:: Updated with all latest features and fixes

setlocal enabledelayedexpansion

:: Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

:main_menu
cls
echo.
echo ================================================================================
echo                    iBridge Enhanced Setup Menu v2.1 (+ Offline)
echo ================================================================================
echo.
echo                          SETUP OPTIONS:
echo.
echo [1] Check Required Files      - Verify all 6 applications and shortcuts exist
echo [2] Run Enhanced Setup        - Complete setup with profile creation (RECOMMENDED)
echo [3] Run Offline Setup         - Complete offline installation with auto USB detection
echo [4] Run Dynamic Setup         - Creates fresh script on-the-fly (SYNTAX-SAFE)
echo [5] Check User Profiles       - Verify existing user accounts and profiles
echo.
echo                        DOCUMENTATION:
echo.
echo [6] View Setup Documentation  - Read about features and requirements
echo [7] View Version Info         - Version checking and upgrade documentation
echo [8] View Cleanup Summary      - What gets cleaned up during setup
echo.
echo                        TROUBLESHOOTING:
echo.
echo [9] Backup Enhanced Launcher  - Alternative launcher with error handling
echo [A] Clean Previous Setup      - Remove previous installation attempts
echo [0] Exit
echo.

:menu_input
set /p choice="Enter your choice (0-9, A): "

if "%choice%"=="1" goto checkfiles
if "%choice%"=="2" goto enhanced  
if "%choice%"=="3" goto offline
if "%choice%"=="4" goto dynamic
if "%choice%"=="5" goto checkprofiles
if "%choice%"=="6" goto documentation
if "%choice%"=="7" goto versioninfo
if "%choice%"=="8" goto cleanup
if "%choice%"=="9" goto backup
if /i "%choice%"=="A" goto cleansetup
if "%choice%"=="0" goto exit
echo.
echo ✗ Invalid choice. Please enter a number from 0-9 or A.
echo.
timeout /t 2 >nul
goto menu_input

:checkfiles
echo.
echo ================================================================================
echo                           Checking Required Files
echo ================================================================================
echo Running from: %SCRIPT_DIR%
echo.

if exist "%SCRIPT_DIR%Check-Required-Files.ps1" (
    cd /d "%SCRIPT_DIR%"
    powershell -ExecutionPolicy Bypass -File "Check-Required-Files.ps1"
) else (
    echo ✗ ERROR: Check-Required-Files.ps1 not found!
    echo Expected location: %SCRIPT_DIR%Check-Required-Files.ps1
    echo.
    echo Available files:
    dir "%SCRIPT_DIR%*.ps1" /b 2>nul
)
echo.
echo Press any key to return to menu...
pause >nul
goto main_menu

:enhanced
echo.
echo ================================================================================
echo                         Starting Enhanced Setup
echo ================================================================================
echo Running from: %SCRIPT_DIR%
echo.
echo This will run the main enhanced setup with:
echo ✓ User account creation (Admin and iBridge User)
echo ✓ Profile creation and verification
echo ✓ Application installation from D: drive
echo ✓ Comprehensive logging
echo.

if exist "%SCRIPT_DIR%RUN-ENHANCED-SETUP.bat" (
    cd /d "%SCRIPT_DIR%"
    call "RUN-ENHANCED-SETUP.bat"
) else if exist "%SCRIPT_DIR%iBridge-Enhanced-Setup.ps1" (
    cd /d "%SCRIPT_DIR%"
    echo Running PowerShell script directly...
    powershell -ExecutionPolicy Bypass -File "iBridge-Enhanced-Setup.ps1"
) else (
    echo ✗ ERROR: Enhanced setup files not found!
    echo.
    echo Looking for:
    echo - RUN-ENHANCED-SETUP.bat
    echo - iBridge-Enhanced-Setup.ps1
    echo.
    echo Available files:
    dir "%SCRIPT_DIR%*Setup*" /b 2>nul
    echo.
    pause
)
goto return_or_exit

:offline
echo.
echo ================================================================================
echo                         Starting Offline Setup
echo ================================================================================
echo Running from: %SCRIPT_DIR%
echo.
echo This will run the complete offline installation with:
echo ✓ Auto USB drive detection (D:, E:, F:, etc.)
echo ✓ User account creation (Admin and iBridge User)
echo ✓ Offline application installation
echo ✓ iBridge User gets Office shortcuts + Teams
echo ✓ Profile isolation (excludes unwanted files)
echo ✓ No internet connection required
echo.
echo Excluded files (not installed):
echo ✗ epi_win_live_installer_2.exe
echo ✗ ESET KEY.txt
echo ✗ Genesys Cloud login
echo ✗ prey-installer
echo.

if exist "%SCRIPT_DIR%RUN-OFFLINE-SETUP.bat" (
    cd /d "%SCRIPT_DIR%"
    call "RUN-OFFLINE-SETUP.bat"
) else if exist "%SCRIPT_DIR%iBridge-Offline-Setup.ps1" (
    cd /d "%SCRIPT_DIR%"
    echo Running PowerShell script directly...
    powershell -ExecutionPolicy Bypass -File "iBridge-Offline-Setup.ps1"
) else (
    echo ✗ ERROR: Offline setup files not found!
    echo.
    echo Looking for:
    echo - RUN-OFFLINE-SETUP.bat
    echo - iBridge-Offline-Setup.ps1
    echo.
    echo Available files:
    dir "%SCRIPT_DIR%*Offline*" /b 2>nul
    echo.
    pause
)
goto return_or_exit

:dynamic
echo.
echo ================================================================================
echo                           Dynamic Setup Creator
echo ================================================================================
echo Running from: %SCRIPT_DIR%
echo.
echo This creates a fresh PowerShell script on-the-fly to avoid syntax errors.
echo ✓ Guaranteed syntax-error-free execution
echo ✓ Same functionality as enhanced setup
echo ✓ Best option if experiencing script errors
echo.

if exist "%SCRIPT_DIR%DYNAMIC-SETUP-CREATOR.bat" (
    cd /d "%SCRIPT_DIR%"
    call "DYNAMIC-SETUP-CREATOR.bat"
) else (
    echo ✗ ERROR: DYNAMIC-SETUP-CREATOR.bat not found!
    echo Expected location: %SCRIPT_DIR%DYNAMIC-SETUP-CREATOR.bat
    pause
)
goto return_or_exit

:checkprofiles
echo.
echo ================================================================================
echo                          Checking User Profiles
echo ================================================================================
echo Running from: %SCRIPT_DIR%
echo.

if exist "%SCRIPT_DIR%Check-User-Profiles.ps1" (
    cd /d "%SCRIPT_DIR%"
    powershell -ExecutionPolicy Bypass -File "Check-User-Profiles.ps1"
) else (
    echo ✗ ERROR: Check-User-Profiles.ps1 not found!
    echo.
    echo Manual check - looking for user accounts:
    echo.
    powershell -Command "Get-LocalUser | Where-Object { $_.Name -eq 'Admin' -or $_.Name -eq 'iBridge User' } | Format-Table Name, Enabled, FullName"
    echo.
    echo Manual check - looking for profiles:
    if exist "C:\Users\Admin" (echo ✓ Admin profile exists) else (echo ✗ Admin profile missing)
    if exist "C:\Users\iBridge User" (echo ✓ iBridge User profile exists) else (echo ✗ iBridge User profile missing)
)
echo.
echo Press any key to return to menu...
pause >nul
goto main_menu

:documentation
echo.
echo ================================================================================
echo                            Setup Documentation
echo ================================================================================
echo.
echo Opening documentation files...

set "doc_opened=false"
if exist "%SCRIPT_DIR%README.md" (
    start notepad "%SCRIPT_DIR%README.md"
    set "doc_opened=true"
)
if exist "%SCRIPT_DIR%ENHANCED-README.md" (
    start notepad "%SCRIPT_DIR%ENHANCED-README.md"
    set "doc_opened=true"
)
if exist "%SCRIPT_DIR%SPECIFIC-FILES-README.md" (
    start notepad "%SCRIPT_DIR%SPECIFIC-FILES-README.md"
    set "doc_opened=true"
)

if "%doc_opened%"=="false" (
    echo ✗ No documentation files found!
    echo.
    echo Looking for:
    echo - README.md
    echo - ENHANCED-README.md  
    echo - SPECIFIC-FILES-README.md
    echo.
    echo Available documentation:
    dir "%SCRIPT_DIR%*.md" /b 2>nul
)

echo.
echo Documentation files opened. Close them and press any key to return to menu...
pause >nul
goto main_menu

:versioninfo
echo.
echo ================================================================================
echo                           Version Information
echo ================================================================================
echo.

if exist "%SCRIPT_DIR%VERSION-CHECKING-DOCUMENTATION.md" (
    start notepad "%SCRIPT_DIR%VERSION-CHECKING-DOCUMENTATION.md"
    echo Version checking documentation opened in Notepad.
) else (
    echo ✗ VERSION-CHECKING-DOCUMENTATION.md not found!
    echo.
    echo Version Information:
    echo - Enhanced Setup Script: v2.0.0
    echo - Features: Version checking, upgrade detection, profile creation
    echo - User Accounts: Admin ^(IBr1dG3Pc^), iBridge User ^(Abc654321!^)
    echo.
    echo Applications supported:
    echo - 24.2.2000.exe
    echo - GlassWireSetup.exe
    echo - PBIDesktopSetup_x64.exe
    echo - TeamViewer_Setup_x64.exe
    echo - Tools for Office2019 TechXander
)

echo.
echo Press any key to return to menu...
pause >nul
goto main_menu

:cleanup
echo.
echo ================================================================================
echo                            Cleanup Information
echo ================================================================================
echo.

if exist "%SCRIPT_DIR%CLEANUP-SUMMARY.md" (
    start notepad "%SCRIPT_DIR%CLEANUP-SUMMARY.md"
    echo Cleanup documentation opened in Notepad.
) else (
    echo Cleanup Summary:
    echo.
    echo The setup process creates and organizes:
    echo ✓ C:\iBridge_Setup\ - Main installation folder
    echo   ├── Installers\   - Application installers
    echo   ├── Shortcuts\    - Desktop shortcuts
    echo   ├── Scripts\      - Setup scripts
    echo   ├── Logs\         - Setup logs
    echo   └── Temp\         - Temporary files
    echo.
    echo During cleanup, old installation attempts are cleaned up.
)

echo.
echo Press any key to return to menu...
pause >nul
goto main_menu

:backup
echo.
echo ================================================================================
echo                         Backup Enhanced Launcher
echo ================================================================================
echo Running from: %SCRIPT_DIR%
echo.
echo This launcher includes additional error handling and diagnostics.
echo Best option if experiencing issues with the main setup.
echo.

if exist "%SCRIPT_DIR%BACKUP-ENHANCED-LAUNCHER.bat" (
    cd /d "%SCRIPT_DIR%"
    call "BACKUP-ENHANCED-LAUNCHER.bat"
) else (
    echo ✗ ERROR: BACKUP-ENHANCED-LAUNCHER.bat not found!
    echo Expected location: %SCRIPT_DIR%BACKUP-ENHANCED-LAUNCHER.bat
    pause
)
goto return_or_exit

:cleansetup
echo.
echo ================================================================================
echo                          Clean Previous Setup
echo ================================================================================
echo.
echo ⚠ WARNING: This will remove previous iBridge setup attempts.
echo.
echo This will delete:
echo - C:\iBridge_Setup folder and all contents
echo - Previous log files
echo - Temporary installation files
echo.
echo User accounts will NOT be removed.
echo.
set /p confirm="Are you sure you want to clean previous setup? (Y/N): "
if /i "%confirm%"=="Y" (
    echo.
    echo Cleaning previous setup...
    if exist "C:\iBridge_Setup" (
        rmdir /s /q "C:\iBridge_Setup" 2>nul
        if not exist "C:\iBridge_Setup" (
            echo ✓ Previous setup cleaned successfully
        ) else (
            echo ✗ Could not remove some files ^(may be in use^)
        )
    ) else (
        echo ℹ No previous setup found to clean
    )
) else (
    echo Cleanup cancelled.
)
echo.
echo Press any key to return to menu...
pause >nul
goto main_menu

:return_or_exit
echo.
echo ================================================================================
echo                              Setup Completed
echo ================================================================================
echo.
set /p return_choice="Return to menu (M) or Exit (E)? "
if /i "%return_choice%"=="M" goto main_menu
goto exit

:exit
echo.
echo ================================================================================
echo                                 Goodbye!
echo ================================================================================
echo.
echo Thank you for using iBridge Enhanced Setup.
echo.
echo If you need to run the setup again, just run this menu.
echo Log files are saved in C:\iBridge_Setup\Logs\ for troubleshooting.
echo.
goto end

:end
echo Press any key to exit...
pause >nul
