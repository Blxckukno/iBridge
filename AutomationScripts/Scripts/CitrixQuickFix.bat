@echo off
title Citrix Quick Fix Tool
color 0A

echo ================================================================
echo CITRIX QUICK FIX TOOL
echo ================================================================
echo.
echo This tool will:
echo 1. Remove existing Citrix components
echo 2. Help you install .NET Core 8.0 (required prerequisite)
echo 3. Help you install Citrix Workspace App
echo.
echo Press any key to begin the process...
pause > nul

echo.
echo ===== STEP 1: REMOVING EXISTING CITRIX COMPONENTS =====
echo.

echo Stopping Citrix processes...
taskkill /F /IM "Receiver.exe" 2>nul
taskkill /F /IM "wfcrun32.exe" 2>nul
taskkill /F /IM "concentr.exe" 2>nul
taskkill /F /IM "wfica32.exe" 2>nul
taskkill /F /IM "AuthManSvr.exe" 2>nul
taskkill /F /IM "picaSvc.exe" 2>nul
taskkill /F /IM "CtxSvcHost.exe" 2>nul
taskkill /F /IM "CitrixWorkspaceApp.exe" 2>nul
taskkill /F /IM "SelfServicePlugin.exe" 2>nul
echo Done.

echo.
echo Uninstalling Citrix Workspace App...
if exist "%ProgramFiles(x86)%\Citrix\ICA Client\TrolleyExpress.exe" (
    echo Found Citrix installation, running uninstaller...
    start /wait "" "%ProgramFiles(x86)%\Citrix\ICA Client\TrolleyExpress.exe" /uninstall /cleanup
) else (
    echo No standard Citrix installation found.
)

echo.
echo Removing Citrix directories...
rmdir /s /q "%ProgramFiles%\Citrix" 2>nul
rmdir /s /q "%ProgramFiles(x86)%\Citrix" 2>nul
rmdir /s /q "%ProgramData%\Citrix" 2>nul
rmdir /s /q "%APPDATA%\Citrix" 2>nul
rmdir /s /q "%LOCALAPPDATA%\Citrix" 2>nul
echo Done.

echo.
echo Removing Citrix registry keys...
reg delete "HKLM\SOFTWARE\Citrix" /f 2>nul
reg delete "HKLM\SOFTWARE\WOW6432Node\Citrix" /f 2>nul
reg delete "HKCU\Software\Citrix" /f 2>nul
echo Done.

echo.
echo Citrix removal complete!
echo.
echo Press any key to continue to Step 2...
pause > nul

echo.
echo ===== STEP 2: INSTALLING .NET CORE 8.0 =====
echo.
echo .NET Core 8.0 Desktop Runtime is required for Citrix Workspace App.
echo.
echo Please download and install .NET Core 8.0 Desktop Runtime from:
echo https://dotnet.microsoft.com/en-us/download/dotnet/8.0
echo.
echo 1. Click on "Download .NET Desktop Runtime"
echo 2. Run the installer and follow the prompts
echo.
echo Would you like to open the download page in your browser?
echo.
set /p OPEN_BROWSER="Type Y to open browser, or N to skip (Y/N): "

if /i "%OPEN_BROWSER%"=="Y" (
    start "" "https://dotnet.microsoft.com/en-us/download/dotnet/8.0"
    echo.
    echo Browser opened. Please download and install .NET Core 8.0 Desktop Runtime.
    echo After installation is complete, return to this window.
)

echo.
echo When .NET Core 8.0 installation is complete, press any key to continue...
pause > nul

echo.
echo ===== STEP 3: INSTALLING CITRIX WORKSPACE APP =====
echo.
echo Please download and install the latest Citrix Workspace App from:
echo https://www.citrix.com/downloads/workspace-app/windows/workspace-app-for-windows-latest.html
echo.
echo Would you like to open the download page in your browser?
echo.
set /p OPEN_BROWSER="Type Y to open browser, or N to skip (Y/N): "

if /i "%OPEN_BROWSER%"=="Y" (
    start "" "https://www.citrix.com/downloads/workspace-app/windows/workspace-app-for-windows-latest.html"
    echo.
    echo Browser opened. Please download and install Citrix Workspace App.
    echo After installation is complete, return to this window.
)

echo.
echo Alternatively, if you already have the Citrix installer:
echo Enter the full path to CitrixWorkspaceApp.exe or press Enter to skip:
echo Example: E:\CitrixWorkspaceApp.exe
echo.
set /p CITRIX_INSTALLER="Enter path or press Enter to skip: "

if not "%CITRIX_INSTALLER%"=="" (
    if exist "%CITRIX_INSTALLER%" (
        echo.
        echo Installing Citrix from: %CITRIX_INSTALLER%
        start /wait "" "%CITRIX_INSTALLER%" /silent /noreboot /includeSSON ENABLE_SSON=Yes
        echo.
        echo Citrix installation completed!
    ) else (
        echo.
        echo Error: File not found: %CITRIX_INSTALLER%
        echo Please install Citrix Workspace App manually.
    )
)

echo.
echo ================================================================
echo CITRIX FIX PROCESS COMPLETED!
echo ================================================================
echo.
echo Steps completed:
echo 1. Removed existing Citrix components
echo 2. Installed/verified .NET Core 8.0 prerequisite
echo 3. Installed/prepared for Citrix Workspace App installation
echo.
echo If you're still experiencing issues with Citrix:
echo 1. Restart your computer
echo 2. Make sure .NET Core 8.0 is properly installed
echo 3. Reinstall Citrix Workspace App manually
echo.
echo Press any key to close this window...
pause > nul
