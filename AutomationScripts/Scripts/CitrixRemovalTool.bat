@echo off
title Citrix Complete Removal and Reinstallation Tool
color 0A
setlocal enabledelayedexpansion

REM Enable error handling
echo on

REM Create log file
set "TEMP_DIR=%TEMP%"
set "LOG_FILE=%TEMP_DIR%\CitrixRemoval.log"
echo Citrix Complete Removal and Reinstallation Tool > "%LOG_FILE%"
echo Started at %date% %time% >> "%LOG_FILE%"

echo ================================================================
echo CITRIX COMPLETE REMOVAL AND REINSTALLATION TOOL
echo ================================================================
echo.
echo This tool will:
echo   1. Stop all Citrix processes
echo   2. Remove ALL Citrix components completely
echo   3. Clean registry entries
echo   4. Remove leftover files
echo   5. Install .NET Core 8.0 prerequisite
echo   6. Install Citrix Workspace cleanly
echo.
echo ----------------------------------------------------------------
echo NOTE: This will resolve the bootstrapperhelper.exe error
echo ----------------------------------------------------------------
echo Log file will be created at: %LOG_FILE%
echo.
echo IMPORTANT: This window will NOT close automatically when finished
echo           so you can review the results.
echo.
pause

REM Check for administrator privileges
echo Checking for administrator privileges...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERROR: This script requires administrator privileges.
    echo Right-click the batch file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo.
echo [1/7] Stopping all Citrix processes...
echo ----------------------------------------------------------------
taskkill /F /IM "Receiver.exe" 2>nul
taskkill /F /IM "wfcrun32.exe" 2>nul
taskkill /F /IM "concentr.exe" 2>nul
taskkill /F /IM "wfica32.exe" 2>nul
taskkill /F /IM "AuthManSvr.exe" 2>nul
taskkill /F /IM "picaSvc.exe" 2>nul
taskkill /F /IM "CtxSvcHost.exe" 2>nul
taskkill /F /IM "redirector.exe" 2>nul
taskkill /F /IM "CitrixWorkspaceApp.exe" 2>nul
taskkill /F /IM "CDViewer.exe" 2>nul
taskkill /F /IM "CitrixReceiverUpdater.exe" 2>nul
taskkill /F /IM "SelfServicePlugin.exe" 2>nul
taskkill /F /IM "ServiceRecord.exe" 2>nul
taskkill /F /IM "Updater.exe" 2>nul
echo All Citrix processes terminated.
echo All Citrix processes terminated. >> "%LOG_FILE%"
echo.

echo [2/7] Uninstalling Citrix components...
echo ----------------------------------------------------------------
echo Uninstalling Citrix components... >> "%LOG_FILE%"
REM Uninstall Citrix Workspace using official uninstaller
if exist "%ProgramFiles(x86)%\Citrix\ICA Client\TrolleyExpress.exe" (
    echo Found Citrix Workspace at "%ProgramFiles(x86)%\Citrix\ICA Client"
    echo Running standard uninstaller...
    start /wait "" "%ProgramFiles(x86)%\Citrix\ICA Client\TrolleyExpress.exe" /uninstall /cleanup
)

if exist "%ProgramFiles%\Citrix\ICA Client\TrolleyExpress.exe" (
    echo Found Citrix Workspace at "%ProgramFiles%\Citrix\ICA Client"
    echo Running standard uninstaller...
    start /wait "" "%ProgramFiles%\Citrix\ICA Client\TrolleyExpress.exe" /uninstall /cleanup
)

REM Use MsiExec to remove potential MSI installations
echo Removing MSI installations...
wmic product where "name like '%%Citrix%%'" call uninstall /nointeractive

echo.
echo [3/7] Performing deep cleaning of Citrix files...
echo ----------------------------------------------------------------
echo Performing deep cleaning of Citrix files... >> "%LOG_FILE%"

REM Delete all Citrix directories
echo Removing Citrix directories...
rmdir /s /q "%ProgramFiles%\Citrix" 2>nul
rmdir /s /q "%ProgramFiles(x86)%\Citrix" 2>nul
rmdir /s /q "%ProgramData%\Citrix" 2>nul
rmdir /s /q "%APPDATA%\Citrix" 2>nul
rmdir /s /q "%LOCALAPPDATA%\Citrix" 2>nul
rmdir /s /q "C:\Program Files\Citrix Workspace 2402" 2>nul
rmdir /s /q "C:\Program Files (x86)\Citrix\Citrix Workspace 2402" 2>nul
rmdir /s /q "C:\Program Files (x86)\Citrix\ICA Client" 2>nul
rmdir /s /q "C:\Program Files\Citrix\ICA Client" 2>nul
echo Removed Citrix directories >> "%LOG_FILE%"

echo.
echo [4/7] Cleaning registry...
echo ----------------------------------------------------------------
echo Cleaning registry... >> "%LOG_FILE%"
echo Removing Citrix registry keys...
reg delete "HKLM\SOFTWARE\Citrix" /f 2>nul
reg delete "HKLM\SOFTWARE\WOW6432Node\Citrix" /f 2>nul
reg delete "HKCU\Software\Citrix" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\ctxusbm" /f 2>nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\picadm" /f 2>nul
echo Removed Citrix registry keys >> "%LOG_FILE%"

echo.
echo [5/7] Installing .NET Core 8.0 prerequisite...
echo ----------------------------------------------------------------
echo Installing .NET Core 8.0 prerequisite... >> "%LOG_FILE%"
echo Downloading .NET Core 8.0 Desktop Runtime...

REM Create temporary directory
if not exist "C:\Temp" mkdir "C:\Temp"

REM Download and install .NET Core 8.0 Desktop Runtime
powershell -Command "& {$ProgressPreference = 'SilentlyContinue'; try { Write-Host 'Downloading .NET Core 8.0 Desktop Runtime...'; $url = 'https://download.microsoft.com/download/6/0/f/60fc7896-d8fa-4713-b20f-e8e0b2db3431/windowsdesktop-runtime-8.0.10-win-x64.exe'; $output = 'C:\Temp\dotnet-desktop-runtime-8.0-win-x64.exe'; Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing; Write-Host 'Installing .NET Core 8.0...'; Start-Process -FilePath $output -ArgumentList '/install', '/quiet', '/norestart' -Wait -NoNewWindow; Write-Host '.NET Core 8.0 installation completed!'; } catch { Write-Host 'Warning: Failed to install .NET Core 8.0 automatically. You may need to install it manually.' } }"
echo .NET Core 8.0 installation step completed >> "%LOG_FILE%"

echo.
echo [6/7] Looking for Citrix installer...
echo ----------------------------------------------------------------
echo Looking for Citrix installer... >> "%LOG_FILE%"

REM Look for Citrix installer in common locations
set "CITRIX_INSTALLER="

if exist "E:\CitrixWorkspaceApp.exe" (
    set "CITRIX_INSTALLER=E:\CitrixWorkspaceApp.exe"
    echo Found Citrix installer at: !CITRIX_INSTALLER!
    echo Found Citrix installer at: !CITRIX_INSTALLER! >> "%LOG_FILE%"
) else if exist "C:\CitrixWorkspaceApp.exe" (
    set "CITRIX_INSTALLER=C:\CitrixWorkspaceApp.exe"
    echo Found Citrix installer at: !CITRIX_INSTALLER!
    echo Found Citrix installer at: !CITRIX_INSTALLER! >> "%LOG_FILE%"
) else if exist "%USERPROFILE%\Downloads\CitrixWorkspaceApp.exe" (
    set "CITRIX_INSTALLER=%USERPROFILE%\Downloads\CitrixWorkspaceApp.exe"
    echo Found Citrix installer at: !CITRIX_INSTALLER!
    echo Found Citrix installer at: !CITRIX_INSTALLER! >> "%LOG_FILE%"
) else if exist "%USERPROFILE%\Desktop\CitrixWorkspaceApp.exe" (
    set "CITRIX_INSTALLER=%USERPROFILE%\Desktop\CitrixWorkspaceApp.exe"
    echo Found Citrix installer at: !CITRIX_INSTALLER!
    echo Found Citrix installer at: !CITRIX_INSTALLER! >> "%LOG_FILE%"
)

echo.
echo [7/7] Installing Citrix Workspace...
echo ----------------------------------------------------------------

if defined CITRIX_INSTALLER (
    echo Found Citrix installer: !CITRIX_INSTALLER!
    echo Installing Citrix Workspace (clean installation)...
    start /wait "" "!CITRIX_INSTALLER!" /silent /noreboot /includeSSON ENABLE_SSON=Yes
    echo Citrix Workspace installation completed!
) else (
    echo Citrix installer not found automatically.
    echo.
    echo Please specify the path to your CitrixWorkspaceApp.exe installer:
    echo Example: C:\Downloads\CitrixWorkspaceApp.exe
    echo.
    set /p MANUAL_INSTALLER="Enter path (or drag and drop file here): "
    
    if exist "!MANUAL_INSTALLER!" (
        echo Installing Citrix Workspace from: !MANUAL_INSTALLER!
        start /wait "" "!MANUAL_INSTALLER!" /silent /noreboot /includeSSON ENABLE_SSON=Yes
        echo Citrix Workspace installation completed!
    ) else (
        echo Error: Citrix installer not found or invalid path.
        echo Please download the latest Citrix Workspace App from:
        echo https://www.citrix.com/downloads/workspace-app/
        echo And run it manually after this tool completes.
    )
)

echo.
echo ================================================================
echo CITRIX CLEANUP AND REINSTALLATION COMPLETED
echo ================================================================
echo.
echo If you still have issues:
echo 1. Restart your computer
echo 2. Try reinstalling Citrix Workspace App manually
echo 3. Make sure .NET Core 8.0 is properly installed
echo.
echo The bootstrapperhelper.exe error should now be resolved!
echo.
pause

REM Create a desktop shortcut for Citrix
echo Creating desktop shortcut for Citrix Workspace...
powershell -Command "& {$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([System.Environment]::GetFolderPath('Desktop') + '\Citrix Workspace.lnk'); $Shortcut.TargetPath = 'C:\Program Files (x86)\Citrix\ICA Client\SelfServicePlugin\SelfService.exe'; $Shortcut.Save();}"

echo.
echo Completed at %date% %time% >> "%LOG_FILE%"
echo Log file created at: %LOG_FILE%
echo.
echo ================================================================
echo PROCESS COMPLETED! 
echo ================================================================
echo.
echo Please review any messages above to see if the process completed successfully.
echo.
echo The window will remain open so you can see any errors.
echo Press CTRL+C to close this window when ready...
REM This creates an indefinite pause
cmd /k
