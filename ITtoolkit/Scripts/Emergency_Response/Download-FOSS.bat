@echo off
REM Simple batch file to download essential FOSS tools
echo Starting FOSS tools download...

REM Create download directory
set DOWNLOAD_DIR=%USERPROFILE%\Desktop\FOSS_Tools
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"
echo Created download directory: %DOWNLOAD_DIR%

REM Download 7-Zip
echo Downloading 7-Zip...
powershell -command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $webClient = New-Object System.Net.WebClient; $webClient.Headers.Add('User-Agent', 'Mozilla/5.0'); $webClient.DownloadFile('https://www.7-zip.org/a/7z2408-x64.exe', '%DOWNLOAD_DIR%\7z2408-x64.exe'); Write-Host 'Downloaded 7-Zip' -ForegroundColor Green}"

REM Download LibreOffice
echo Downloading LibreOffice...
powershell -command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $webClient = New-Object System.Net.WebClient; $webClient.Headers.Add('User-Agent', 'Mozilla/5.0'); $webClient.DownloadFile('https://download.documentfoundation.org/libreoffice/stable/24.8.2/win/x86_64/LibreOffice_24.8.2_Win_x86-64.msi', '%DOWNLOAD_DIR%\LibreOffice_24.8.2_Win_x86-64.msi'); Write-Host 'Downloaded LibreOffice' -ForegroundColor Green}"

REM Download Firefox
echo Downloading Firefox...
powershell -command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $webClient = New-Object System.Net.WebClient; $webClient.Headers.Add('User-Agent', 'Mozilla/5.0'); $webClient.DownloadFile('https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US', '%DOWNLOAD_DIR%\Firefox-Setup.exe'); Write-Host 'Downloaded Firefox' -ForegroundColor Green}"

REM Download KeePassXC
echo Downloading KeePassXC...
powershell -command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $webClient = New-Object System.Net.WebClient; $webClient.Headers.Add('User-Agent', 'Mozilla/5.0'); $webClient.DownloadFile('https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-Win64.msi', '%DOWNLOAD_DIR%\KeePassXC-2.7.9-Win64.msi'); Write-Host 'Downloaded KeePassXC' -ForegroundColor Green}"

REM Download VirtualBox
echo Downloading VirtualBox...
powershell -command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $webClient = New-Object System.Net.WebClient; $webClient.Headers.Add('User-Agent', 'Mozilla/5.0'); $webClient.DownloadFile('https://download.virtualbox.org/virtualbox/7.1.4/VirtualBox-7.1.4-165100-Win.exe', '%DOWNLOAD_DIR%\VirtualBox-7.1.4-165100-Win.exe'); Write-Host 'Downloaded VirtualBox' -ForegroundColor Green}"

echo.
echo Download completed! Files saved to: %DOWNLOAD_DIR%
echo.
echo Ready to install FOSS alternatives!
pause
