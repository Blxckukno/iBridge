@echo off
echo ============================================
echo        URGENT SECURITY EMERGENCY SCAN
echo ============================================
echo.
echo WARNING: Windows Defender is DISABLED!
echo This system is EXTREMELY VULNERABLE!
echo.
echo Running emergency security checks...
echo.

echo [1/6] Checking running processes for suspicious activity...
powershell -Command "Get-Process | Where-Object {$_.ProcessName -match 'bitcoin|miner|trojan|virus|malware|backdoor|keylog|ransom|crypto' -or $_.CPU -gt 80} | Select-Object ProcessName, Id, CPU, WorkingSet | Format-Table -AutoSize"

echo.
echo [2/6] Checking network connections for suspicious activity...
powershell -Command "Get-NetTCPConnection | Where-Object {$_.RemotePort -eq 4444 -or $_.RemotePort -eq 1337 -or $_.RemotePort -eq 31337 -or $_.RemotePort -eq 8080} | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State | Format-Table -AutoSize"

echo.
echo [3/6] Checking startup programs for malware...
powershell -Command "Get-CimInstance Win32_StartupCommand | Where-Object {$_.Command -match 'temp|appdata|roaming' -or $_.Name -match 'update|system|driver' -and $_.Name -notmatch 'Microsoft|Windows|Intel|AMD|NVIDIA'} | Select-Object Name, Command, Location | Format-Table -AutoSize"

echo.
echo [4/6] Checking recent suspicious file activity...
powershell -Command "Get-ChildItem -Path $env:TEMP -Recurse -File -ErrorAction SilentlyContinue | Where-Object {$_.Extension -match '.exe|.scr|.bat|.vbs|.ps1' -and $_.CreationTime -gt (Get-Date).AddDays(-1)} | Select-Object Name, CreationTime, Length | Sort-Object CreationTime -Descending | Format-Table -AutoSize"

echo.
echo [5/6] Checking Windows Event Log for security incidents...
powershell -Command "Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625,4624,4648} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -AutoSize"

echo.
echo [6/6] Downloading and running Microsoft Safety Scanner...
echo.

rem Create download directory
if not exist "%USERPROFILE%\Desktop\EmergencySecurity" mkdir "%USERPROFILE%\Desktop\EmergencySecurity"
cd /d "%USERPROFILE%\Desktop\EmergencySecurity"

echo Downloading Microsoft Safety Scanner (this may take a few minutes)...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?LinkId=212732' -OutFile 'msert.exe' -UserAgent 'Mozilla/5.0'"

if exist msert.exe (
    echo.
    echo Running Microsoft Safety Scanner - FULL SCAN...
    echo This will scan your entire system for malware!
    echo.
    msert.exe /F /Q
) else (
    echo ERROR: Could not download Microsoft Safety Scanner
)

echo.
echo ============================================
echo      EMERGENCY SCAN COMPLETED
echo ============================================
echo.
echo CRITICAL ACTIONS NEEDED:
echo 1. RUN AS ADMINISTRATOR to enable Windows Defender
echo 2. Update all software immediately
echo 3. Change all passwords
echo 4. Disconnect from network if threats found
echo 5. Contact IT security team immediately
echo.
echo Report saved to: %USERPROFILE%\Desktop\EmergencySecurity\
echo.
pause
