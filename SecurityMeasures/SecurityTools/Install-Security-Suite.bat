@echo off
echo ========================================================
echo      Security Tools Installation Suite
echo ========================================================
echo.
echo This script will download and install recommended security tools
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Administrator privileges required!
    echo Please right-click and select "Run as administrator"
    pause
    exit /B 1
)

:: Create necessary directories
set DOWNLOAD_DIR=C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\Downloads
set LOG_DIR=C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\Logs

if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Set log file
set LOG_FILE=%LOG_DIR%\SecurityTools_Installation_%date:~-4,4%%date:~-10,2%%date:~-7,2%.log
echo Security Tools Installation Log > %LOG_FILE%
echo Date: %date% Time: %time% >> %LOG_FILE%
echo. >> %LOG_FILE%

echo ========================================================
echo Creating directories and initializing...
echo ========================================================
echo.

:: Function to log
call :log "Starting security tools installation"

:: Install Malwarebytes
call :log "Installing Malwarebytes..."
echo Downloading Malwarebytes...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://downloads.malwarebytes.com/file/mb4_offline' -OutFile '%DOWNLOAD_DIR%\MBSetup.exe'}"
if %errorLevel% neq 0 (
    call :log "Error downloading Malwarebytes"
) else (
    echo Installing Malwarebytes...
    "%DOWNLOAD_DIR%\MBSetup.exe" /SILENT /NORESTART
    if %errorLevel% neq 0 (
        call :log "Error installing Malwarebytes"
    ) else (
        call :log "Malwarebytes installed successfully"
    )
)

:: Install Bitdefender Free
call :log "Installing Bitdefender Free..."
echo Downloading Bitdefender Free...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://download.bitdefender.com/windows/installer/en-us/bitdefender_antivirus.exe' -OutFile '%DOWNLOAD_DIR%\bitdefender_antivirus.exe'}"
if %errorLevel% neq 0 (
    call :log "Error downloading Bitdefender"
) else (
    echo Installing Bitdefender Free...
    "%DOWNLOAD_DIR%\bitdefender_antivirus.exe" /SILENT /NORESTART
    if %errorLevel% neq 0 (
        call :log "Error installing Bitdefender"
    ) else (
        call :log "Bitdefender installed successfully"
    )
)

:: Install Windows Firewall Control
call :log "Installing Windows Firewall Control..."
echo Downloading Windows Firewall Control...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.binisoft.org/download/wfc6setup.exe' -OutFile '%DOWNLOAD_DIR%\wfc6setup.exe'}"
if %errorLevel% neq 0 (
    call :log "Error downloading Windows Firewall Control"
) else (
    echo Installing Windows Firewall Control...
    "%DOWNLOAD_DIR%\wfc6setup.exe" /VERYSILENT /NORESTART
    if %errorLevel% neq 0 (
        call :log "Error installing Windows Firewall Control"
    ) else (
        call :log "Windows Firewall Control installed successfully"
    )
)

:: Install uBlock Origin for browsers
call :log "Installing uBlock Origin..."
echo Please manually install uBlock Origin for your browsers from:
echo Chrome: https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm
echo Firefox: https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/
echo Edge: https://microsoftedge.microsoft.com/addons/detail/ublock-origin/odfafepnkmbhccpbejgmiehpchacaeak

:: Download and extract Sysinternals Suite
call :log "Downloading Sysinternals Suite..."
echo Downloading Sysinternals Suite...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/SysinternalsSuite.zip' -OutFile '%DOWNLOAD_DIR%\SysinternalsSuite.zip'}"
if %errorLevel% neq 0 (
    call :log "Error downloading Sysinternals Suite"
) else (
    echo Extracting Sysinternals Suite...
    powershell -Command "& {Expand-Archive -Path '%DOWNLOAD_DIR%\SysinternalsSuite.zip' -DestinationPath 'C:\Program Files\Sysinternals' -Force}"
    if %errorLevel% neq 0 (
        call :log "Error extracting Sysinternals Suite"
    ) else (
        call :log "Sysinternals Suite installed successfully"
    )
)

:: Install KeePass
call :log "Installing KeePass..."
echo Downloading KeePass...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://sourceforge.net/projects/keepass/files/KeePass%202.x/2.51/KeePass-2.51-Setup.exe/download' -OutFile '%DOWNLOAD_DIR%\KeePass-Setup.exe'}"
if %errorLevel% neq 0 (
    call :log "Error downloading KeePass"
) else (
    echo Installing KeePass...
    "%DOWNLOAD_DIR%\KeePass-Setup.exe" /VERYSILENT /NORESTART
    if %errorLevel% neq 0 (
        call :log "Error installing KeePass"
    ) else (
        call :log "KeePass installed successfully"
    )
)

:: Install Bitwarden
call :log "Installing Bitwarden..."
echo Downloading Bitwarden...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://vault.bitwarden.com/download/?app=desktop&platform=windows' -OutFile '%DOWNLOAD_DIR%\Bitwarden-Installer.exe'}"
if %errorLevel% neq 0 (
    call :log "Error downloading Bitwarden"
) else (
    echo Installing Bitwarden...
    "%DOWNLOAD_DIR%\Bitwarden-Installer.exe" /S
    if %errorLevel% neq 0 (
        call :log "Error installing Bitwarden"
    ) else (
        call :log "Bitwarden installed successfully"
    )
)

:: Download and extract Process Explorer
call :log "Installing Process Explorer..."
echo Downloading Process Explorer...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/ProcessExplorer.zip' -OutFile '%DOWNLOAD_DIR%\ProcessExplorer.zip'}"
if %errorLevel% neq 0 (
    call :log "Error downloading Process Explorer"
) else (
    echo Extracting Process Explorer...
    powershell -Command "& {Expand-Archive -Path '%DOWNLOAD_DIR%\ProcessExplorer.zip' -DestinationPath 'C:\Program Files\ProcessExplorer' -Force}"
    if %errorLevel% neq 0 (
        call :log "Error extracting Process Explorer"
    ) else (
        call :log "Process Explorer installed successfully"
        echo Creating shortcut...
        powershell -Command "& {$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('C:\Users\Public\Desktop\Process Explorer.lnk'); $Shortcut.TargetPath = 'C:\Program Files\ProcessExplorer\procexp64.exe'; $Shortcut.Save()}"
    )
)

:: Download and extract Autoruns
call :log "Installing Autoruns..."
echo Downloading Autoruns...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/Autoruns.zip' -OutFile '%DOWNLOAD_DIR%\Autoruns.zip'}"
if %errorLevel% neq 0 (
    call :log "Error downloading Autoruns"
) else (
    echo Extracting Autoruns...
    powershell -Command "& {Expand-Archive -Path '%DOWNLOAD_DIR%\Autoruns.zip' -DestinationPath 'C:\Program Files\Autoruns' -Force}"
    if %errorLevel% neq 0 (
        call :log "Error extracting Autoruns"
    ) else (
        call :log "Autoruns installed successfully"
        echo Creating shortcut...
        powershell -Command "& {$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('C:\Users\Public\Desktop\Autoruns.lnk'); $Shortcut.TargetPath = 'C:\Program Files\Autoruns\autoruns64.exe'; $Shortcut.Save()}"
    )
)

:: Download and extract TCPView
call :log "Installing TCPView..."
echo Downloading TCPView...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/TCPView.zip' -OutFile '%DOWNLOAD_DIR%\TCPView.zip'}"
if %errorLevel% neq 0 (
    call :log "Error downloading TCPView"
) else (
    echo Extracting TCPView...
    powershell -Command "& {Expand-Archive -Path '%DOWNLOAD_DIR%\TCPView.zip' -DestinationPath 'C:\Program Files\TCPView' -Force}"
    if %errorLevel% neq 0 (
        call :log "Error extracting TCPView"
    ) else (
        call :log "TCPView installed successfully"
        echo Creating shortcut...
        powershell -Command "& {$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('C:\Users\Public\Desktop\TCPView.lnk'); $Shortcut.TargetPath = 'C:\Program Files\TCPView\Tcpview64.exe'; $Shortcut.Save()}"
    )
)

:: Install BleachBit
call :log "Installing BleachBit..."
echo Downloading BleachBit...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.bleachbit.org/download/file/t?file=BleachBit-4.4.2-setup.exe' -OutFile '%DOWNLOAD_DIR%\BleachBit-setup.exe'}"
if %errorLevel% neq 0 (
    call :log "Error downloading BleachBit"
) else (
    echo Installing BleachBit...
    "%DOWNLOAD_DIR%\BleachBit-setup.exe" /S
    if %errorLevel% neq 0 (
        call :log "Error installing BleachBit"
    ) else (
        call :log "BleachBit installed successfully"
    )
)

:: Install VeraCrypt
call :log "Installing VeraCrypt..."
echo Downloading VeraCrypt...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://launchpad.net/veracrypt/trunk/1.25.9/+download/VeraCrypt%20Setup%201.25.9.exe' -OutFile '%DOWNLOAD_DIR%\VeraCrypt_Setup.exe'}"
if %errorLevel% neq 0 (
    call :log "Error downloading VeraCrypt"
) else (
    echo Installing VeraCrypt...
    "%DOWNLOAD_DIR%\VeraCrypt_Setup.exe" /VERYSILENT /NORESTART
    if %errorLevel% neq 0 (
        call :log "Error installing VeraCrypt"
    ) else (
        call :log "VeraCrypt installed successfully"
    )
)

:: Install Wireshark
call :log "Installing Wireshark..."
echo Downloading Wireshark...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://1.na.dl.wireshark.org/win64/Wireshark-win64-latest.exe' -OutFile '%DOWNLOAD_DIR%\Wireshark-setup.exe'}"
if %errorLevel% neq 0 (
    call :log "Error downloading Wireshark"
) else (
    echo Installing Wireshark...
    "%DOWNLOAD_DIR%\Wireshark-setup.exe" /S /desktopicon=yes /quicklaunchicon=yes
    if %errorLevel% neq 0 (
        call :log "Error installing Wireshark"
    ) else (
        call :log "Wireshark installed successfully"
    )
)

:: Optimize Windows Defender settings
call :log "Optimizing Windows Defender..."
echo Optimizing Windows Defender settings...

powershell -Command "& {Set-MpPreference -DisableRealtimeMonitoring $false}"
powershell -Command "& {Set-MpPreference -MAPSReporting Advanced}"
powershell -Command "& {Set-MpPreference -DisableBlockAtFirstSeen $false}"
powershell -Command "& {Set-MpPreference -EnableNetworkProtection Enabled}"

:: Trigger a Windows Defender scan
call :log "Triggering Windows Defender scan..."
echo Scheduling a Windows Defender scan...
powershell -Command "& {Start-MpScan -ScanType QuickScan -AsJob}"

pause
:: Install NetSpot WiFi Analyzer
call :log "Installing NetSpot WiFi Analyzer..."
echo Downloading NetSpot WiFi Analyzer...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://cdn.netspotapp.com/download/Windows/NetSpotSetup.exe' -OutFile '%DOWNLOAD_DIR%\NetSpotSetup.exe'}"
if %errorLevel% neq 0 (
    call :log "Error downloading NetSpot WiFi Analyzer"
) else (
    echo Installing NetSpot WiFi Analyzer...
    "%DOWNLOAD_DIR%\NetSpotSetup.exe" /VERYSILENT /NORESTART
    if %errorLevel% neq 0 (
        call :log "Error installing NetSpot WiFi Analyzer"
    ) else (
        call :log "NetSpot WiFi Analyzer installed successfully"
    )
)

:: Final message
echo.
echo ========================================================
echo Installation complete!
call :log "Security tools installation completed"
echo All tools have been installed. Please restart your computer.
echo See the log file for details: %LOG_FILE%
echo ========================================================
echo.


exit /B 0

:log
echo %~1 >> %LOG_FILE%
echo %~1
goto :eof
