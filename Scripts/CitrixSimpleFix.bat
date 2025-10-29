@echo off
echo ================================================================
echo SIMPLIFIED CITRIX REMOVAL AND REINSTALLATION TOOL
echo ================================================================
echo.
echo This tool will remove Citrix components and reinstall cleanly.

REM Ensure window stays open even if errors occur
echo on

REM Wait for user to start the process
pause

REM Stop all Citrix processes
echo [1/5] Stopping all Citrix processes...
taskkill /F /IM "Receiver.exe" 2>nul
taskkill /F /IM "wfcrun32.exe" 2>nul
taskkill /F /IM "concentr.exe" 2>nul
taskkill /F /IM "wfica32.exe" 2>nul
taskkill /F /IM "AuthManSvr.exe" 2>nul
taskkill /F /IM "CtxSvcHost.exe" 2>nul
taskkill /F /IM "CitrixWorkspaceApp.exe" 2>nul
echo All Citrix processes terminated.
pause

REM Uninstall Citrix components
echo [2/5] Uninstalling Citrix components...
if exist "%ProgramFiles(x86)%\Citrix\ICA Client\TrolleyExpress.exe" (
    echo Found Citrix at "%ProgramFiles(x86)%\Citrix\ICA Client"
    start /wait "" "%ProgramFiles(x86)%\Citrix\ICA Client\TrolleyExpress.exe" /uninstall /cleanup
)

if exist "%ProgramFiles%\Citrix\ICA Client\TrolleyExpress.exe" (
    echo Found Citrix at "%ProgramFiles%\Citrix\ICA Client"
    start /wait "" "%ProgramFiles%\Citrix\ICA Client\TrolleyExpress.exe" /uninstall /cleanup
)
pause

REM Delete Citrix directories
echo [3/5] Removing Citrix directories...
rmdir /s /q "%ProgramFiles%\Citrix" 2>nul
rmdir /s /q "%ProgramFiles(x86)%\Citrix" 2>nul
rmdir /s /q "%ProgramData%\Citrix" 2>nul
rmdir /s /q "%APPDATA%\Citrix" 2>nul
rmdir /s /q "%LOCALAPPDATA%\Citrix" 2>nul
echo Citrix directories removed.
pause

REM Install .NET Core 8.0
echo [4/5] Installing .NET Core 8.0 prerequisite...
powershell -Command "& { Write-Host 'Downloading .NET Core 8.0...'; $url = 'https://dotnet.microsoft.com/download/dotnet/thank-you/runtime-desktop-8.0.10-windows-x64-installer'; Write-Host 'Please download and install .NET Core 8.0 Desktop Runtime manually from:'; Write-Host $url -ForegroundColor Cyan; Write-Host 'After installing, return to this window and press any key to continue.'; }"
echo .NET Core 8.0 installation step - press any key when you've completed the installation manually.
pause

REM Install Citrix
echo [5/5] Installing Citrix Workspace...

REM Check for Citrix installer in common locations first
if exist "E:\CitrixWorkspaceApp.exe" (
    set "CITRIX_INSTALLER=E:\CitrixWorkspaceApp.exe"
    echo Found Citrix installer at: E:\CitrixWorkspaceApp.exe
)

if not defined CITRIX_INSTALLER (
    echo Please specify the path to your CitrixWorkspaceApp.exe installer:
    echo Example: E:\CitrixWorkspaceApp.exe
    echo Or download the latest version from:
    echo https://www.citrix.com/downloads/workspace-app/windows/workspace-app-for-windows-latest.html
    set /p CITRIX_INSTALLER="Enter path (or drag and drop file here): "
)

if exist "%CITRIX_INSTALLER%" (
    echo.
    echo Installing Citrix from: %CITRIX_INSTALLER%
    start /wait "" "%CITRIX_INSTALLER%" /silent /noreboot /includeSSON ENABLE_SSON=Yes
    echo.
    echo Citrix installation completed!
) else (
    echo.
    echo Error: Citrix installer not found or invalid path.
    echo Please download the latest Citrix Workspace App from:
    echo https://www.citrix.com/downloads/workspace-app/windows/workspace-app-for-windows-latest.html
    echo And run it manually after closing this window.
)

echo.
echo ================================================================
echo PROCESS COMPLETED!
echo ================================================================
echo.
echo This window will remain open so you can review the results.
echo Press any key to close when ready...

pause
