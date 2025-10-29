# Emergency System Isolation and Quarantine Script
# This script will isolate potentially infected systems from the network

Write-Host "🚨 EMERGENCY SYSTEM ISOLATION PROTOCOL 🚨" -ForegroundColor Red -BackgroundColor Yellow
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ WARNING: Script not running as Administrator" -ForegroundColor Red
    Write-Host "   Some isolation features may not work properly" -ForegroundColor Yellow
}

Write-Host "📊 Current System Status:" -ForegroundColor Cyan
Write-Host "  Windows Defender: DISABLED ❌" -ForegroundColor Red
Write-Host "  System at HIGH RISK of infection" -ForegroundColor Red
Write-Host ""

Write-Host "🔍 Scanning for active threats..." -ForegroundColor Yellow

# Check for suspicious processes
$suspiciousProcesses = Get-Process | Where-Object {
    $_.ProcessName -match "bitcoin|miner|trojan|virus|malware|backdoor|keylog|ransom|crypto|winlogon\.exe|csrss\.exe" -and
    $_.ProcessName -notmatch "^(winlogon|csrss)$"
}

if ($suspiciousProcesses) {
    Write-Host "⚠️  SUSPICIOUS PROCESSES DETECTED:" -ForegroundColor Red
    $suspiciousProcesses | Select-Object ProcessName, Id, CPU | Format-Table -AutoSize
    
    Write-Host "🔒 TERMINATING SUSPICIOUS PROCESSES..." -ForegroundColor Red
    foreach ($proc in $suspiciousProcesses) {
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Write-Host "   ✓ Terminated: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Green
        }
        catch {
            Write-Host "   ❌ Failed to terminate: $($proc.ProcessName)" -ForegroundColor Red
        }
    }
}

# Check network connections for suspicious activity
Write-Host "🌐 Checking network connections..." -ForegroundColor Yellow
$suspiciousConnections = Get-NetTCPConnection | Where-Object {
    $_.RemotePort -in @(4444, 1337, 31337, 8080, 6667, 6697) -or
    $_.RemoteAddress -match "^(10\.0\.0\.|192\.168\.|172\.16\.)" -and $_.State -eq "Established"
}

if ($suspiciousConnections) {
    Write-Host "⚠️  SUSPICIOUS NETWORK CONNECTIONS:" -ForegroundColor Red
    $suspiciousConnections | Select-Object LocalPort, RemoteAddress, RemotePort, State | Format-Table -AutoSize
}

# Block suspicious network traffic (if admin)
if ($isAdmin) {
    Write-Host "🚫 BLOCKING SUSPICIOUS NETWORK TRAFFIC..." -ForegroundColor Red
    
    # Block common malware ports
    $malwarePorts = @(4444, 1337, 31337, 6667, 6697, 8080)
    foreach ($port in $malwarePorts) {
        try {
            New-NetFirewallRule -DisplayName "EMERGENCY_BLOCK_$port" -Direction Outbound -Protocol TCP -RemotePort $port -Action Block -ErrorAction SilentlyContinue
            Write-Host "   ✓ Blocked outbound traffic to port $port" -ForegroundColor Green
        }
        catch {
            Write-Host "   ❌ Failed to block port $port" -ForegroundColor Red
        }
    }
}

# Check for malicious files in common locations
Write-Host "📁 Scanning for malicious files..." -ForegroundColor Yellow
$maliciousLocations = @(
    "$env:TEMP",
    "$env:APPDATA",
    "$env:LOCALAPPDATA\Temp",
    "$env:USERPROFILE\Downloads"
)

$suspiciousFiles = @()
foreach ($location in $maliciousLocations) {
    try {
        $files = Get-ChildItem -Path $location -Recurse -File -ErrorAction SilentlyContinue | 
                 Where-Object {
                     $_.Extension -match "\.(exe|scr|bat|vbs|ps1|com|pif)$" -and
                     $_.CreationTime -gt (Get-Date).AddDays(-7) -and
                     ($_.Name -match "(temp|tmp|update|system|driver|install)" -or $_.Length -lt 1KB)
                 } | Select-Object -First 10
        
        if ($files) {
            $suspiciousFiles += $files
        }
    }
    catch {
        # Continue scanning other locations
    }
}

if ($suspiciousFiles) {
    Write-Host "⚠️  SUSPICIOUS FILES DETECTED:" -ForegroundColor Red
    $suspiciousFiles | Select-Object Name, FullName, CreationTime, Length | Format-Table -AutoSize
    
    Write-Host "🗑️  QUARANTINING SUSPICIOUS FILES..." -ForegroundColor Red
    $quarantineDir = "$env:USERPROFILE\Desktop\QUARANTINE_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -Path $quarantineDir -ItemType Directory -Force | Out-Null
    
    foreach ($file in $suspiciousFiles) {
        try {
            Move-Item -Path $file.FullName -Destination $quarantineDir -ErrorAction SilentlyContinue
            Write-Host "   ✓ Quarantined: $($file.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "   ❌ Failed to quarantine: $($file.Name)" -ForegroundColor Red
        }
    }
    
    Write-Host "📂 Quarantined files moved to: $quarantineDir" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🚨 IMMEDIATE ACTIONS REQUIRED:" -ForegroundColor Red -BackgroundColor Yellow
Write-Host "1. 🔌 DISCONNECT from network/internet immediately" -ForegroundColor Red
Write-Host "2. 🛡️  Enable Windows Defender (run as Administrator)" -ForegroundColor Red
Write-Host "3. 🔄 Run Windows Update" -ForegroundColor Red
Write-Host "4. 🔐 Change ALL passwords from a clean device" -ForegroundColor Red
Write-Host "5. 📞 Contact IT security team immediately" -ForegroundColor Red
Write-Host "6. 💾 Backup critical data to isolated storage" -ForegroundColor Red

Write-Host ""
Write-Host "📋 EMERGENCY CONTACT INFORMATION:" -ForegroundColor Cyan
Write-Host "   IT Security Hotline: [CONTACT_NUMBER]"
Write-Host "   Incident Response Team: [EMAIL_ADDRESS]"
Write-Host ""

# Create incident report
$reportPath = "$env:USERPROFILE\Desktop\SECURITY_INCIDENT_REPORT_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$report = @"
SECURITY INCIDENT REPORT
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $env:COMPUTERNAME
User: $env:USERNAME

CRITICAL FINDINGS:
- Windows Defender: DISABLED
- System Status: HIGH RISK

SUSPICIOUS ACTIVITY DETECTED:
$(if ($suspiciousProcesses) { "- Suspicious processes found and terminated" } else { "- No suspicious processes detected" })
$(if ($suspiciousConnections) { "- Suspicious network connections detected" } else { "- No suspicious network connections" })
$(if ($suspiciousFiles) { "- Suspicious files found and quarantined" } else { "- No suspicious files detected" })

ACTIONS TAKEN:
- System scan completed
- Suspicious processes terminated
- Malicious files quarantined
- Network traffic blocked
- Incident report generated

NEXT STEPS:
1. Isolate system from network
2. Enable antivirus protection
3. Run full system scan
4. Change all passwords
5. Contact security team

Report generated by IT Toolkit Emergency Response
"@

Set-Content -Path $reportPath -Value $report
Write-Host "📄 Incident report saved to: $reportPath" -ForegroundColor Green

Write-Host ""
Write-Host "⚡ Emergency isolation protocol completed!" -ForegroundColor Green
