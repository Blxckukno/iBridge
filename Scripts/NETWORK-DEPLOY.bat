@echo off
echo ================================================================
echo iBridge Network Deployment Tool
echo Deploy setup scripts to other network devices
echo ================================================================
echo.
echo Available deployment methods:
echo   1. Share current folder for network access
echo   2. Copy to specific network location
echo   3. Create portable USB package
echo   4. Remote PowerShell deployment (requires WinRM)
echo.

:MENU
echo Select deployment method:
echo [1] Share this folder on network
echo [2] Copy to network location
echo [3] Create USB deployment package
echo [4] Remote PowerShell deployment
echo [5] Exit
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto SHARE_FOLDER
if "%choice%"=="2" goto COPY_NETWORK
if "%choice%"=="3" goto USB_PACKAGE
if "%choice%"=="4" goto REMOTE_DEPLOY
if "%choice%"=="5" goto EXIT
echo Invalid choice. Please try again.
goto MENU

:SHARE_FOLDER
echo.
echo Creating network share for current folder...
echo.
echo Command to run on target devices:
echo \\%COMPUTERNAME%\iBridge-Scripts\UNIVERSAL-USB-SETUP.bat
echo.
echo Setting up share...
net share iBridge-Scripts="%~dp0" /grant:everyone,read
if %errorlevel%==0 (
    echo Success! Folder shared as: \\%COMPUTERNAME%\iBridge-Scripts
    echo.
    echo Target devices can now run:
    echo \\%COMPUTERNAME%\iBridge-Scripts\UNIVERSAL-USB-SETUP.bat
) else (
    echo Failed to create share. Make sure you run as Administrator.
)
pause
goto MENU

:COPY_NETWORK
echo.
set /p networkpath="Enter network path (e.g., \\Server\Share\Folder): "
if "%networkpath%"=="" goto MENU

echo Copying deployment files to %networkpath%...
copy "UNIVERSAL-USB-SETUP.bat" "%networkpath%\" 
copy "iBridge-Simple-Standalone.ps1" "%networkpath%\"
copy "NETWORK-DEPLOYMENT-GUIDE.md" "%networkpath%\"

if %errorlevel%==0 (
    echo Success! Files copied to %networkpath%
    echo.
    echo Target devices can now run:
    echo %networkpath%\UNIVERSAL-USB-SETUP.bat
) else (
    echo Failed to copy files. Check network path and permissions.
)
pause
goto MENU

:USB_PACKAGE
echo.
echo Creating USB deployment package...
set /p usbpath="Enter USB drive path (e.g., E:\): "
if "%usbpath%"=="" goto MENU

echo Copying all necessary files to %usbpath%...
copy "UNIVERSAL-USB-SETUP.bat" "%usbpath%"
copy "iBridge-Simple-Standalone.ps1" "%usbpath%"
copy "NETWORK-DEPLOYMENT-GUIDE.md" "%usbpath%"

echo Creating USB README...
echo iBridge USB Deployment Package > "%usbpath%USB-README.txt"
echo Generated: %date% %time% >> "%usbpath%USB-README.txt"
echo. >> "%usbpath%USB-README.txt"
echo To deploy on target device: >> "%usbpath%USB-README.txt"
echo 1. Insert this USB drive >> "%usbpath%USB-README.txt"
echo 2. Right-click UNIVERSAL-USB-SETUP.bat >> "%usbpath%USB-README.txt"
echo 3. Select "Run as administrator" >> "%usbpath%USB-README.txt"
echo 4. Wait for completion >> "%usbpath%USB-README.txt"
echo 5. Remove USB drive safely >> "%usbpath%USB-README.txt"

if %errorlevel%==0 (
    echo Success! USB package created at %usbpath%
    echo.
    echo Files included:
    echo - UNIVERSAL-USB-SETUP.bat (main installer)
    echo - iBridge-Simple-Standalone.ps1 (PowerShell script)
    echo - NETWORK-DEPLOYMENT-GUIDE.md (documentation)
    echo - USB-README.txt (instructions)
) else (
    echo Failed to create USB package. Check USB path.
)
pause
goto MENU

:REMOTE_DEPLOY
echo.
echo Remote PowerShell Deployment
echo =============================
echo This requires WinRM enabled on target devices.
echo.
set /p targetcomputer="Enter target computer name or IP: "
if "%targetcomputer%"=="" goto MENU

echo.
echo Testing connection to %targetcomputer%...
ping %targetcomputer% -n 1 > nul
if %errorlevel%==0 (
    echo Connection successful.
    echo.
    echo Attempting remote deployment...
    echo Note: You may be prompted for credentials.
    
    powershell.exe -Command "& {
        try {
            $session = New-PSSession -ComputerName '%targetcomputer%'
            if ($session) {
                Write-Host 'PowerShell session established' -ForegroundColor Green
                Copy-Item 'UNIVERSAL-USB-SETUP.bat' -Destination 'C:\Temp\' -ToSession $session
                Copy-Item 'iBridge-Simple-Standalone.ps1' -Destination 'C:\Temp\' -ToSession $session
                Write-Host 'Files copied to target device C:\Temp\' -ForegroundColor Green
                Write-Host 'Run this on target device: C:\Temp\UNIVERSAL-USB-SETUP.bat' -ForegroundColor Yellow
                Remove-PSSession $session
            }
        } catch {
            Write-Host 'Remote deployment failed: ' + $_.Exception.Message -ForegroundColor Red
            Write-Host 'Make sure WinRM is enabled on target device' -ForegroundColor Yellow
        }
    }"
) else (
    echo Cannot reach %targetcomputer%. Check network connection.
)
pause
goto MENU

:EXIT
echo.
echo Network deployment options completed.
echo.
echo Remember: Target devices need Administrator privileges to run the setup.
echo.
pause
exit /b
