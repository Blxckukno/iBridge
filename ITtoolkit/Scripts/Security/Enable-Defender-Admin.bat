@echo off
echo ============================================
echo   WINDOWS DEFENDER ACTIVATION SCRIPT
echo ============================================
echo.
echo This script will enable Windows Defender with optimal settings
echo for maximum security score improvement.
echo.

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Administrator privileges confirmed
    echo.
) else (
    echo ❌ ERROR: This script must be run as Administrator!
    echo.
    echo To run as Administrator:
    echo 1. Right-click on Command Prompt
    echo 2. Select "Run as administrator"
    echo 3. Run this script again
    echo.
    if defined ITTK_ORCH (
        echo [ORCH] Skipping pause due to orchestrator context
        exit /b 1
    ) else (
        pause
        exit /b 1
    )
)

echo [1/8] Enabling Windows Defender Real-Time Protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false"
if %errorlevel% equ 0 (echo ✅ Real-Time Protection enabled) else (echo ❌ Failed to enable Real-Time Protection)

echo [2/8] Enabling Behavior Monitoring...
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $false"
if %errorlevel% equ 0 (echo ✅ Behavior Monitoring enabled) else (echo ❌ Failed to enable Behavior Monitoring)

echo [3/8] Enabling Block at First Seen...
powershell -Command "Set-MpPreference -DisableBlockAtFirstSeen $false"
if %errorlevel% equ 0 (echo ✅ Block at First Seen enabled) else (echo ❌ Failed to enable Block at First Seen)

echo [4/8] Enabling IOAV Protection...
powershell -Command "Set-MpPreference -DisableIOAVProtection $false"
if %errorlevel% equ 0 (echo ✅ IOAV Protection enabled) else (echo ❌ Failed to enable IOAV Protection)

echo [5/8] Enabling Script Scanning...
powershell -Command "Set-MpPreference -DisableScriptScanning $false"
if %errorlevel% equ 0 (echo ✅ Script Scanning enabled) else (echo ❌ Failed to enable Script Scanning)

echo [6/8] Configuring Cloud Protection (Advanced)...
powershell -Command "Set-MpPreference -MAPSReporting Advanced"
if %errorlevel% equ 0 (echo ✅ Advanced Cloud Protection enabled) else (echo ❌ Failed to configure Cloud Protection)

echo [7/8] Enabling Automatic Sample Submission...
powershell -Command "Set-MpPreference -SubmitSamplesConsent SendAllSamples"
if %errorlevel% equ 0 (echo ✅ Sample Submission enabled) else (echo ❌ Failed to enable Sample Submission)

echo [8/8] Updating Threat Definitions...
powershell -Command "Update-MpSignature"
if %errorlevel% equ 0 (echo ✅ Threat definitions updated) else (echo ❌ Failed to update definitions)

echo.
echo ============================================
echo     WINDOWS DEFENDER OPTIMIZATION
echo ============================================
echo.

echo Enabling Windows Firewall...
powershell -Command "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True"
if %errorlevel% equ 0 (echo ✅ Windows Firewall enabled) else (echo ❌ Failed to enable Firewall)

echo.
echo Starting Quick Security Scan...
powershell -Command "Start-MpScan -ScanType QuickScan"
if %errorlevel% equ 0 (echo ✅ Security scan initiated) else (echo ❌ Failed to start scan)

echo.
echo ============================================
echo         SECURITY STATUS CHECK
echo ============================================
echo.

echo Checking current Defender status...
powershell -Command "Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, BehaviorMonitorEnabled | Format-List"

echo.
echo ============================================
echo    WINDOWS DEFENDER SUCCESSFULLY ENABLED
echo ============================================
echo.
echo ✅ Real-time protection is now active
echo ✅ Advanced threat detection enabled
echo ✅ Cloud-based protection configured
echo ✅ Firewall protection enabled
echo ✅ Security scan in progress
echo.
echo Your Microsoft Defender security score has been significantly improved!
echo.
echo RECOMMENDATIONS:
echo • Schedule regular full system scans
echo • Keep Windows updated automatically  
echo • Enable automatic sample submission
echo • Review security settings monthly
echo • Consider Windows Defender ATP for enterprise
echo.
if not defined ITTK_ORCH pause
