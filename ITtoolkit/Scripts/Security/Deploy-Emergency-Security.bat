@echo off
echo ============================================
echo      EMERGENCY CLAMAV DEPLOYMENT
echo ============================================
echo.
echo Downloading and installing ClamAV for immediate malware scanning...
echo.

rem Create security tools directory
if not exist "%USERPROFILE%\Desktop\SecurityTools" mkdir "%USERPROFILE%\Desktop\SecurityTools"
cd /d "%USERPROFILE%\Desktop\SecurityTools"

echo [1/4] Downloading ClamAV for Windows...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.clamav.net/downloads/production/clamav-1.3.1.win.x64.msi' -OutFile 'clamav.msi' -UserAgent 'Mozilla/5.0'"

echo [2/4] Installing ClamAV...
if exist clamav.msi (
    msiexec /i clamav.msi /quiet /norestart
    echo ClamAV installation initiated...
) else (
    echo ERROR: Could not download ClamAV
)

echo.
echo [3/4] Downloading YARA rules for malware detection...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/Yara-Rules/rules/archive/master.zip' -OutFile 'yara-rules.zip' -UserAgent 'Mozilla/5.0'"

echo.
echo [4/4] Downloading additional malware removal tools...

echo Downloading RKill (stops malware processes)...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://download.bleepingcomputer.com/rkill/rkill.exe' -OutFile 'rkill.exe' -UserAgent 'Mozilla/5.0'"

echo Downloading Malwarebytes AdwCleaner (removes adware)...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://downloads.malwarebytes.com/file/adwcleaner' -OutFile 'adwcleaner.exe' -UserAgent 'Mozilla/5.0'"

echo.
echo ============================================
echo      RUNNING EMERGENCY TOOLS
echo ============================================

if exist rkill.exe (
    echo Running RKill to stop malware processes...
    rkill.exe
)

if exist adwcleaner.exe (
    echo Running AdwCleaner to remove adware/PUPs...
    adwcleaner.exe /eula /clean /noreboot
)

echo.
echo Emergency security tools deployed!
echo Check C:\Program Files\ClamAV for ClamAV installation
echo.
echo NEXT STEPS:
echo 1. Run Windows Update immediately
echo 2. Enable Windows Defender (requires admin)
echo 3. Run full system scan with ClamAV
echo 4. Check browser extensions and remove suspicious ones
echo 5. Change all passwords immediately
echo.
pause
