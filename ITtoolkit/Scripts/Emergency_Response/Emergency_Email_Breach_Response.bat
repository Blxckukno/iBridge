@echo off
REM Emergency_Email_::: Download function (modify for USB if needed)
set "DOWNLOAD=powershell -Command "Invoke-WebRequest -Uri \"%1\" -OutFile \"%2\" -UseBasicParsing""

echo.
echo [1/8] Downloading Malwarebytes...
if not exist "mbam-setup.exe" %DOWNLOAD% "https://downloads.malwarebytes.com/file/mb4_offline" "mbam-setup.exe"_Response.bat
REM Batch script for immediate response to @ibridge.co.za email compromise
REM Run as Administrator on DISCONNECTED machine

title EMERGENCY RESPONSE - iBridge Email Breach

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator!
    echo Please right-click on the file and select "Run as administrator".
    pause
    exit /b
)

:: Create tools directory
set "TOOLSDIR=%USERPROFILE%\Desktop\iBridge_Emergency_Scan"
if not exist "%TOOLSDIR%" mkdir "%TOOLSDIR%"
echo Tools directory: %TOOLSDIR%
cd /d "%TOOLSDIR%"

echo.
echo ===============================================
echo EMERGENCY RESPONSE FOR @IBRIDGE.CO.ZA BREACH
echo ===============================================
echo.
echo CRITICAL: Ensure this machine is DISCONNECTED from network!
echo Press any key to continue or Ctrl+C to abort...
pause >nul

:: Download function (modify for USB if needed)
set "DOWNLOAD=powershell -Command "Invoke-WebRequest -Uri '%1' -OutFile '%2' -UseBasicParsing""

echo.
echo [1/8] Downloading Malwarebytes...
if not exist "mbam-setup.exe" %DOWNLOAD% "https://downloads.malwarebytes.com/file/mb4_offline" "mbam-setup.exe"

echo [2/8] Downloading HitmanPro...
if not exist "hitmanpro.exe" %DOWNLOAD% "https://dl.surfright.nl/HitmanPro_x64.exe" "hitmanpro.exe"

echo [3/8] Downloading Emsisoft Emergency Kit...
if not exist "eeksetup.exe" %DOWNLOAD% "https://cdn.emsisoft.com/EmsisoftEmergencyKit.exe" "eeksetup.exe"

echo [4/8] Downloading Process Explorer...
if not exist "procexp.zip" %DOWNLOAD% "https://download.sysinternals.com/files/ProcessExplorer.zip" "procexp.zip"

echo [5/8] Downloading Autoruns...
if not exist "autoruns.zip" %DOWNLOAD% "https://download.sysinternals.com/files/Autoruns.zip" "autoruns.zip"

echo [6/8] Downloading TCPView...
if not exist "tcpview.zip" %DOWNLOAD% "https://download.sysinternals.com/files/TCPView.zip" "tcpview.zip"

echo [7/8] Downloading RootkitRevealer...
if not exist "rootkit.zip" %DOWNLOAD% "https://download.sysinternals.com/files/RootkitRevealer.zip" "rootkit.zip"

echo [8/8] Downloading Microsoft Safety Scanner...
if not exist "msert.exe" %DOWNLOAD% "https://go.microsoft.com/fwlink/?LinkId=212732" "msert.exe"

echo.
echo ===============================================
echo EXTRACTING TOOLS...
echo ===============================================

:: Extract zip files
if exist "procexp.zip" powershell -command "Expand-Archive -Path 'procexp.zip' -DestinationPath '.' -Force"
if exist "autoruns.zip" powershell -command "Expand-Archive -Path 'autoruns.zip' -DestinationPath '.' -Force"
if exist "tcpview.zip" powershell -command "Expand-Archive -Path 'tcpview.zip' -DestinationPath '.' -Force"
if exist "rootkit.zip" powershell -command "Expand-Archive -Path 'rootkit.zip' -DestinationPath '.' -Force"

echo.
echo ===============================================
echo RUNNING DIAGNOSTICS...
echo ===============================================

:: Create diagnostic report
echo IBRIDGE EMAIL BREACH DIAGNOSTIC REPORT > diagnostic_report.txt
echo Generated: %date% %time% >> diagnostic_report.txt
echo Computer: %COMPUTERNAME% >> diagnostic_report.txt
echo User: %USERNAME% >> diagnostic_report.txt
echo. >> diagnostic_report.txt

echo NETWORK CONNECTIONS ON EMAIL PORTS: >> diagnostic_report.txt
netstat -an | findstr ":25 " >> diagnostic_report.txt
netstat -an | findstr ":110 " >> diagnostic_report.txt
netstat -an | findstr ":143 " >> diagnostic_report.txt
netstat -an | findstr ":587 " >> diagnostic_report.txt
netstat -an | findstr ":993 " >> diagnostic_report.txt
netstat -an | findstr ":995 " >> diagnostic_report.txt
echo. >> diagnostic_report.txt

echo RUNNING PROCESSES: >> diagnostic_report.txt
tasklist /v >> diagnostic_report.txt
echo. >> diagnostic_report.txt

echo STARTUP PROGRAMS: >> diagnostic_report.txt
wmic startup get caption,command,location >> diagnostic_report.txt
echo. >> diagnostic_report.txt

echo SCHEDULED TASKS: >> diagnostic_report.txt
schtasks /query /fo csv | findstr /i "mail\|smtp\|ibridge" >> diagnostic_report.txt
echo. >> diagnostic_report.txt

echo.
echo ===============================================
echo INSTALLING AND LAUNCHING SECURITY TOOLS...
echo ===============================================

:: Install Malwarebytes
echo Installing Malwarebytes (silent install)...
if exist "mbam-setup.exe" (
    start /wait "" "mbam-setup.exe" /verysilent /norestart
    timeout /t 5
    echo Launching Malwarebytes - PLEASE RUN FULL SCAN
    start "" "C:\Program Files\Malwarebytes\Anti-Malware\mbam.exe"
    timeout /t 3
)

:: Extract and run Emsisoft Emergency Kit
echo Extracting Emsisoft Emergency Kit...
if exist "eeksetup.exe" (
    start /wait "" "eeksetup.exe" /extract
    timeout /t 3
    echo Launching Emsisoft Emergency Kit - PLEASE UPDATE AND SCAN
    if exist "EEK\start.exe" start "" "EEK\start.exe"
    timeout /t 3
)

:: Run HitmanPro
echo Launching HitmanPro - PLEASE RUN SCAN
if exist "hitmanpro.exe" (
    start "" "hitmanpro.exe"
    timeout /t 3
)

:: Launch Sysinternals tools
echo Launching Process Explorer - CHECK FOR SUSPICIOUS PROCESSES
if exist "procexp64.exe" (
    start "" "procexp64.exe"
    timeout /t 2
)

echo Launching Autoruns - CHECK LOGON/SCHEDULED TASKS TABS
if exist "Autoruns64.exe" (
    start "" "Autoruns64.exe"
    timeout /t 2
)

echo Launching TCPView - MONITOR NETWORK CONNECTIONS
if exist "Tcpview.exe" (
    start "" "Tcpview.exe"
    timeout /t 2
)

echo Launching RootkitRevealer - CHECK FOR ROOTKITS
if exist "RootkitRevealer64.exe" (
    start "" "RootkitRevealer64.exe"
    timeout /t 2
)

:: Run Microsoft Safety Scanner
echo Launching Microsoft Safety Scanner - PLEASE RUN FULL SCAN
if exist "msert.exe" (
    start "" "msert.exe"
    timeout /t 3
)

echo.
echo ===============================================
echo CRITICAL NEXT STEPS FOR @IBRIDGE.CO.ZA
echo ===============================================
echo.
echo IMMEDIATE ACTIONS:
echo 1. INTERACT WITH ALL OPENED SECURITY TOOLS
echo 2. RUN FULL SCANS IN EACH TOOL
echo 3. QUARANTINE/DELETE ANY THREATS FOUND
echo 4. DOCUMENT ALL FINDINGS
echo.
echo EMAIL SECURITY ACTIONS (ON CLEAN MACHINE):
echo 1. Change passwords for ALL @ibridge.co.za accounts
echo 2. Enable Multi-Factor Authentication (MFA)
echo 3. Check email forwarding rules in Exchange/Office 365
echo 4. Remove any unauthorized delegates/permissions
echo 5. Review audit logs for suspicious sign-ins
echo 6. Check for suspicious OAuth applications
echo.
echo NETWORK SECURITY ACTIONS:
echo 1. Review firewall logs for unusual traffic
echo 2. Check DNS logs for suspicious queries
echo 3. Monitor outbound email traffic
echo 4. Implement email security policies
echo.
echo COMPLIANCE ACTIONS:
echo 1. Notify relevant authorities if required
echo 2. Document the incident thoroughly
echo 3. Preserve evidence as needed
echo 4. Review and update security policies
echo.
echo Diagnostic report saved to: %TOOLSDIR%\diagnostic_report.txt
echo.
echo Press any key when all scans are complete...
pause >nul

echo.
echo ===============================================
echo POST-SCAN CLEANUP CHECKLIST
echo ===============================================
echo.
echo [ ] All security scans completed
echo [ ] Threats quarantined/removed
echo [ ] System rebooted
echo [ ] Email passwords changed (from clean machine)
echo [ ] MFA enabled on all accounts
echo [ ] Email forwarding rules checked/cleaned
echo [ ] Unauthorized delegates removed
echo [ ] Network monitoring implemented
echo [ ] Incident documented
echo.
echo AFTER RECONNECTING TO NETWORK:
echo 1. Monitor for suspicious activity
echo 2. Run additional scans periodically
echo 3. Review email security settings weekly
echo 4. Train users on email security
echo.
pause
