# Master Security Verification System
# Comprehensive security assessment and threat analysis

Write-Host "MASTER SECURITY VERIFICATION SYSTEM" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Comprehensive security assessment starting..." -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Global results tracking
$results = @{
    "SystemSecurity" = "Not Run"
    "DefenderStatus" = "Not Run"
    "EmergencyScans" = "Not Run"
    "NetworkSecurity" = "Not Run"
    "EmailSecurity" = "Not Run"
    "FirewallStatus" = "Not Run"
    "SecurityTools" = "Not Run"
    "ProcessAnalysis" = "Not Run"
}

# 1. System Security Score
Write-Host ""
Write-Host "[1/8] SYSTEM SECURITY BASELINE" -ForegroundColor Cyan

try {
    # Check UAC status
    $uacStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
    $uacEnabled = $uacStatus.EnableLUA -eq 1
    
    # Check Windows Update service
    $wuService = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    $wuRunning = $wuService.Status -eq "Running"
    
    Write-Host "  User Account Control: $(if ($uacEnabled) {'ENABLED'} else {'DISABLED'})" -ForegroundColor $(if ($uacEnabled) {"Green"} else {"Red"})
    Write-Host "  Windows Update Service: $(if ($wuRunning) {'RUNNING'} else {'STOPPED'})" -ForegroundColor $(if ($wuRunning) {"Green"} else {"Red"})
    
    if ($uacEnabled -and $wuRunning) {
        $results["SystemSecurity"] = "SECURE"
    } else {
        $results["SystemSecurity"] = "COMPROMISED"
    }
}
catch {
    Write-Host "  ERROR: Cannot assess system security baseline" -ForegroundColor Red
    $results["SystemSecurity"] = "ERROR"
}

# 2. Windows Defender Status
Write-Host ""
Write-Host "[2/8] WINDOWS DEFENDER STATUS" -ForegroundColor Cyan

try {
    $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    
    if ($defenderStatus) {
        Write-Host "  Antivirus Enabled: $($defenderStatus.AntivirusEnabled)" -ForegroundColor $(if ($defenderStatus.AntivirusEnabled) {"Green"} else {"Red"})
        Write-Host "  Real-Time Protection: $($defenderStatus.RealTimeProtectionEnabled)" -ForegroundColor $(if ($defenderStatus.RealTimeProtectionEnabled) {"Green"} else {"Red"})
        Write-Host "  Behavior Monitor: $($defenderStatus.BehaviorMonitorEnabled)" -ForegroundColor $(if ($defenderStatus.BehaviorMonitorEnabled) {"Green"} else {"Red"})
        Write-Host "  Last Signature Update: $($defenderStatus.AntivirusSignatureLastUpdated)" -ForegroundColor Cyan
        
        if ($defenderStatus.AntivirusEnabled -and $defenderStatus.RealTimeProtectionEnabled) {
            $results["DefenderStatus"] = "SECURE"
        } else {
            $results["DefenderStatus"] = "COMPROMISED"
        }
    } else {
        Write-Host "  ERROR: Cannot retrieve Defender status" -ForegroundColor Red
        $results["DefenderStatus"] = "ERROR"
    }
}
catch {
    Write-Host "  ERROR: Defender service not accessible" -ForegroundColor Red
    $results["DefenderStatus"] = "ERROR"
}

# 3. Emergency Security Tools
Write-Host ""
Write-Host "[3/8] EMERGENCY SECURITY TOOLS" -ForegroundColor Cyan

$emergencyTools = @(
    "$env:USERPROFILE\Desktop\EmergencySecurity\msert.exe",
    "C:\Program Files\ClamAV\clamd.exe",
    "$env:USERPROFILE\Desktop\EmergencySecurity\AdwCleaner.exe"
)

$toolsFound = 0
foreach ($tool in $emergencyTools) {
    if (Test-Path $tool) {
        $toolName = Split-Path $tool -Leaf
        Write-Host "  SUCCESS: $toolName available" -ForegroundColor Green
        $toolsFound++
    }
}

if ($toolsFound -gt 0) {
    Write-Host "  Emergency tools available: $toolsFound/$($emergencyTools.Count)" -ForegroundColor Green
    $results["EmergencyScans"] = "READY"
} else {
    Write-Host "  WARNING: No emergency tools deployed" -ForegroundColor Yellow
    $results["EmergencyScans"] = "NOT_READY"
}

# 4. Network Security Analysis
Write-Host ""
Write-Host "[4/8] NETWORK SECURITY ANALYSIS" -ForegroundColor Cyan

try {
    $allConnections = Get-NetTCPConnection | Where-Object {$_.State -eq "Established"}
    $suspiciousPorts = @(4444, 1337, 31337, 6667, 6697)
    $suspiciousConnections = $allConnections | Where-Object {$_.RemotePort -in $suspiciousPorts}
    
    Write-Host "  Total Active Connections: $($allConnections.Count)" -ForegroundColor Cyan
    
    if ($suspiciousConnections) {
        Write-Host "  WARNING: SUSPICIOUS CONNECTIONS DETECTED:" -ForegroundColor Red
        $suspiciousConnections | ForEach-Object {
            Write-Host "    • $($_.RemoteAddress):$($_.RemotePort)" -ForegroundColor Red
        }
        $results["NetworkSecurity"] = "THREATS_DETECTED"
    } else {
        Write-Host "  SUCCESS: No suspicious network connections detected" -ForegroundColor Green
        $results["NetworkSecurity"] = "SECURE"
    }
}
catch {
    Write-Host "  ERROR: Cannot analyze network connections" -ForegroundColor Red
    $results["NetworkSecurity"] = "ERROR"
}

# 5. Email Security Status
Write-Host ""
Write-Host "[5/8] EMAIL SECURITY STATUS" -ForegroundColor Cyan

$emailProcesses = Get-Process | Where-Object {$_.ProcessName -match "outlook|thunderbird|mail"}
if ($emailProcesses) {
    Write-Host "  Active Email Clients:" -ForegroundColor Cyan
    $emailProcesses | ForEach-Object {
        Write-Host "    • $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Green
    }
    
    # Check for suspicious email processes
    $suspiciousEmail = $emailProcesses | Where-Object {$_.ProcessName -match "keylog|capture|spy|malware"}
    if ($suspiciousEmail) {
        Write-Host "  WARNING: Suspicious email-related processes detected!" -ForegroundColor Red
        $results["EmailSecurity"] = "COMPROMISED"
    } else {
        Write-Host "  SUCCESS: Email clients appear secure" -ForegroundColor Green
        $results["EmailSecurity"] = "SECURE"
    }
} else {
    Write-Host "  INFO: No active email clients detected" -ForegroundColor Gray
    $results["EmailSecurity"] = "NO_CLIENTS"
}

# 6. Windows Firewall Status
Write-Host ""
Write-Host "[6/8] WINDOWS FIREWALL STATUS" -ForegroundColor Cyan

try {
    $firewallProfiles = Get-NetFirewallProfile
    $enabledProfiles = $firewallProfiles | Where-Object {$_.Enabled -eq $true}
    
    Write-Host "  Firewall Profiles:" -ForegroundColor Cyan
    foreach ($profile in $firewallProfiles) {
        $status = if ($profile.Enabled) { "ENABLED" } else { "DISABLED" }
        $color = if ($profile.Enabled) { "Green" } else { "Red" }
        Write-Host "    $($profile.Name): $status" -ForegroundColor $color
    }
    
    if ($enabledProfiles.Count -eq $firewallProfiles.Count) {
        $results["FirewallStatus"] = "SECURE"
    } else {
        $results["FirewallStatus"] = "COMPROMISED"
    }
}
catch {
    Write-Host "  ERROR: Cannot check firewall status" -ForegroundColor Red
    $results["FirewallStatus"] = "ERROR"
}

# 7. Security Tools Inventory
Write-Host ""
Write-Host "[7/8] SECURITY TOOLS INVENTORY" -ForegroundColor Cyan

$securityDirs = @(
    "$env:USERPROFILE\Desktop\EmergencySecurity",
    "C:\Program Files\Windows Defender",
    "C:\Program Files\ClamAV",
    "$PSScriptRoot\Security"
)

$totalTools = 0
foreach ($dir in $securityDirs) {
    if (Test-Path $dir) {
        $files = Get-ChildItem $dir -File -ErrorAction SilentlyContinue
        if ($files) {
            Write-Host "  ${dir}: $($files.Count) security tools" -ForegroundColor Green
            $totalTools += $files.Count
        }
    }
}

Write-Host "  Total Security Tools Available: $totalTools" -ForegroundColor Cyan
$results["SecurityTools"] = if ($totalTools -gt 5) { "EXCELLENT" } elseif ($totalTools -gt 2) { "GOOD" } else { "LIMITED" }

# 8. Process Analysis
Write-Host ""
Write-Host "[8/8] SUSPICIOUS PROCESS ANALYSIS" -ForegroundColor Cyan

$suspiciousPatterns = @("keylog", "capture", "dump", "inject", "exploit", "backdoor", "trojan", "virus")
$allProcesses = Get-Process
$suspiciousProcesses = $allProcesses | Where-Object {
    $processName = $_.ProcessName.ToLower()
    $suspiciousPatterns | Where-Object { $processName -like "*$_*" }
}

if ($suspiciousProcesses) {
    Write-Host "  WARNING: SUSPICIOUS PROCESSES DETECTED:" -ForegroundColor Red
    $suspiciousProcesses | ForEach-Object {
        Write-Host "    • $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Red
    }
    $results["ProcessAnalysis"] = "THREATS_DETECTED"
} else {
    Write-Host "  SUCCESS: No obviously suspicious processes detected" -ForegroundColor Green
    $results["ProcessAnalysis"] = "SECURE"
}

# Final Security Assessment
Write-Host ""
Write-Host "=" * 60 -ForegroundColor Blue
Write-Host "MASTER SECURITY ASSESSMENT RESULTS" -ForegroundColor White -BackgroundColor Blue
Write-Host "=" * 60 -ForegroundColor Blue

Write-Host ""
Write-Host "SECURITY COMPONENTS STATUS:" -ForegroundColor Yellow
foreach ($component in $results.GetEnumerator()) {
    $status = $component.Value
    $color = switch ($status) {
        "SECURE" { "Green" }
        "READY" { "Green" }
        "EXCELLENT" { "Green" }
        "GOOD" { "Cyan" }
        "NO_CLIENTS" { "Gray" }
        "COMPROMISED" { "Red" }
        "THREATS_DETECTED" { "Red" }
        "ERROR" { "Red" }
        "NOT_READY" { "Yellow" }
        "LIMITED" { "Yellow" }
        default { "Gray" }
    }
    
    Write-Host "  $($component.Key): $status" -ForegroundColor $color
}

# Calculate overall security score
$secureCount = ($results.Values | Where-Object { $_ -in @("SECURE", "READY", "EXCELLENT", "GOOD") }).Count
$totalCount = $results.Count
$securityScore = [math]::Round(($secureCount / $totalCount) * 100, 1)

Write-Host ""
Write-Host "OVERALL SECURITY SCORE: $securityScore%" -ForegroundColor $(if ($securityScore -ge 80) {"Green"} elseif ($securityScore -ge 60) {"Yellow"} else {"Red"})

# Generate recommendations
Write-Host ""
Write-Host "SECURITY RECOMMENDATIONS:" -ForegroundColor Yellow

$recommendations = @()
if ($results["DefenderStatus"] -ne "SECURE") {
    $recommendations += "Enable Windows Defender real-time protection"
}
if ($results["FirewallStatus"] -ne "SECURE") {
    $recommendations += "Enable Windows Firewall on all profiles"
}
if ($results["EmergencyScans"] -eq "NOT_READY") {
    $recommendations += "Deploy emergency security tools"
}
if ($results["ProcessAnalysis"] -eq "THREATS_DETECTED") {
    $recommendations += "Investigate and remove suspicious processes"
}

if ($recommendations.Count -eq 0) {
    Write-Host "  SUCCESS: No immediate security actions required" -ForegroundColor Green
} else {
    foreach ($rec in $recommendations) {
        Write-Host "  • $rec" -ForegroundColor Cyan
    }
}

# Save comprehensive report
$reportPath = "$env:USERPROFILE\Desktop\Master_Security_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$securityComponents = $results.GetEnumerator() | ForEach-Object { "- $($_.Key): $($_.Value)" }
$securityComponentsText = $securityComponents -join "`n"

$recommendationsText = if ($recommendations) { 
    $recommendations | ForEach-Object { "- $_" } | Out-String 
} else { 
    "- No immediate actions required" 
}

$report = @"
MASTER SECURITY VERIFICATION REPORT
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

SECURITY ASSESSMENT RESULTS:
$securityComponentsText

OVERALL SECURITY SCORE: $securityScore%

RECOMMENDATIONS:
$recommendationsText

DETAILED ANALYSIS:
- Total Active Network Connections: $($allConnections.Count)
- Security Tools Available: $totalTools
- Email Clients Active: $(($emailProcesses | Measure-Object).Count)
- Firewall Profiles Enabled: $(($enabledProfiles | Measure-Object).Count)

Report generated by IT Toolkit Master Security Verification
"@

Set-Content -Path $reportPath -Value $report
Write-Host ""
Write-Host "Comprehensive report saved to: $reportPath" -ForegroundColor Cyan

Write-Host ""
Write-Host "Master security verification completed!" -ForegroundColor Green
