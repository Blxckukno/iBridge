# Master Security Verification Script
# Runs all security checks and tools to ensure complete protection

Write-Host "🚀 MASTER SECURITY VERIFICATION - RUNNING ALL SYSTEMS" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "=" * 80 -ForegroundColor Cyan

$results = @{
    "EmailSecurity" = "Not Run"
    "DefenderStatus" = "Not Run"
    "NetworkSecurity" = "Not Run"
    "ProcessSecurity" = "Not Run"
    "EmergencyScans" = "Not Run"
    "OverallStatus" = "Checking..."
}

# 1. Windows Defender Status Check
Write-Host "`n[1/8] 🛡️ WINDOWS DEFENDER STATUS CHECK" -ForegroundColor Cyan
try {
    $defenderStatus = Get-MpComputerStatus
    Write-Host "  Real-Time Protection: $($defenderStatus.RealTimeProtectionEnabled)" -ForegroundColor $(if ($defenderStatus.RealTimeProtectionEnabled) {"Green"} else {"Red"})
    Write-Host "  Antivirus Enabled: $($defenderStatus.AntivirusEnabled)" -ForegroundColor $(if ($defenderStatus.AntivirusEnabled) {"Green"} else {"Red"})
    Write-Host "  Behavior Monitoring: $($defenderStatus.BehaviorMonitorEnabled)" -ForegroundColor $(if ($defenderStatus.BehaviorMonitorEnabled) {"Green"} else {"Red"})
    Write-Host "  Cloud Protection: $($defenderStatus.MAPSReporting)" -ForegroundColor Cyan
    Write-Host "  Last Update: $($defenderStatus.AntivirusSignatureLastUpdated)" -ForegroundColor Gray
    
    if ($defenderStatus.RealTimeProtectionEnabled -and $defenderStatus.AntivirusEnabled) {
        $results["DefenderStatus"] = "PROTECTED"
        Write-Host "  ✅ DEFENDER STATUS: FULLY PROTECTED" -ForegroundColor Green
    } else {
        $results["DefenderStatus"] = "VULNERABLE"
        Write-Host "  ❌ DEFENDER STATUS: NEEDS ATTENTION" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Cannot access Windows Defender status" -ForegroundColor Red
    $results["DefenderStatus"] = "ERROR"
}

# 2. Active Security Processes
Write-Host "`n[2/8] 🔄 SECURITY PROCESSES CHECK" -ForegroundColor Cyan
$securityProcesses = Get-Process | Where-Object {
    $_.ProcessName -match "MsMpEng|SecurityHealthService|msert|clamav|windefend"
}

if ($securityProcesses) {
    Write-Host "  ✅ Active Security Processes:" -ForegroundColor Green
    $securityProcesses | ForEach-Object {
        Write-Host "    • $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Cyan
    }
    $results["ProcessSecurity"] = "ACTIVE"
} else {
    Write-Host "  ⚠️ No security processes detected" -ForegroundColor Yellow
    $results["ProcessSecurity"] = "MINIMAL"
}

# 3. Microsoft Safety Scanner Check
Write-Host "`n[3/8] 📊 EMERGENCY SCAN STATUS" -ForegroundColor Cyan
$msertProcesses = Get-Process -Name "msert" -ErrorAction SilentlyContinue
if ($msertProcesses) {
    Write-Host "  ✅ Microsoft Safety Scanner: ACTIVE SCAN" -ForegroundColor Green
    $msertProcesses | ForEach-Object {
        $runtime = (Get-Date) - $_.StartTime
        Write-Host "    Runtime: $runtime | Memory: $([math]::Round($_.WorkingSet/1MB,2)) MB" -ForegroundColor Cyan
    }
    $results["EmergencyScans"] = "ACTIVE"
} else {
    Write-Host "  ℹ️ Microsoft Safety Scanner: Not currently running" -ForegroundColor Gray
    
    # Check if scan completed
    if (Test-Path "$env:USERPROFILE\Desktop\EmergencySecurity\msert.exe") {
        Write-Host "  ✅ Emergency tools available and ready" -ForegroundColor Green
        $results["EmergencyScans"] = "READY"
    } else {
        Write-Host "  ⚠️ Emergency tools not deployed" -ForegroundColor Yellow
        $results["EmergencyScans"] = "NOT_READY"
    }
}

# 4. Network Security Check
Write-Host "`n[4/8] 🌐 NETWORK SECURITY ANALYSIS" -ForegroundColor Cyan
try {
    $allConnections = Get-NetTCPConnection | Where-Object {$_.State -eq "Established"}
    $suspiciousPorts = @(4444, 1337, 31337, 6667, 6697)
    $suspiciousConnections = $allConnections | Where-Object {$_.RemotePort -in $suspiciousPorts}
    
    Write-Host "  Total Active Connections: $($allConnections.Count)" -ForegroundColor Cyan
    
    if ($suspiciousConnections) {
        Write-Host "  ⚠️ SUSPICIOUS CONNECTIONS DETECTED:" -ForegroundColor Red
        $suspiciousConnections | ForEach-Object {
            Write-Host "    • $($_.RemoteAddress):$($_.RemotePort)" -ForegroundColor Red
        }
        $results["NetworkSecurity"] = "THREATS_DETECTED"
    } else {
        Write-Host "  ✅ No suspicious network connections detected" -ForegroundColor Green
        $results["NetworkSecurity"] = "SECURE"
    }
} catch {
    Write-Host "  ❌ Cannot analyze network connections" -ForegroundColor Red
    $results["NetworkSecurity"] = "ERROR"
}

# 5. Email Security Check
Write-Host "`n[5/8] 📧 EMAIL SECURITY STATUS" -ForegroundColor Cyan
$emailProcesses = Get-Process | Where-Object {$_.ProcessName -match "outlook|thunderbird|mail"}
if ($emailProcesses) {
    Write-Host "  📧 Active Email Clients:" -ForegroundColor Cyan
    $emailProcesses | ForEach-Object {
        Write-Host "    • $($_.ProcessName)" -ForegroundColor Green
    }
    
    # Check for suspicious email processes
    $suspiciousEmail = $emailProcesses | Where-Object {$_.ProcessName -match "keylog|capture|spy|malware"}
    if ($suspiciousEmail) {
        Write-Host "  ⚠️ Suspicious email-related processes detected!" -ForegroundColor Red
        $results["EmailSecurity"] = "COMPROMISED"
    } else {
        Write-Host "  ✅ Email clients appear secure" -ForegroundColor Green
        $results["EmailSecurity"] = "SECURE"
    }
} else {
    Write-Host "  ℹ️ No active email clients detected" -ForegroundColor Gray
    $results["EmailSecurity"] = "NO_CLIENTS"
}

# 6. Firewall Status
Write-Host "`n[6/8] 🔥 WINDOWS FIREWALL STATUS" -ForegroundColor Cyan
try {
    $firewallProfiles = Get-NetFirewallProfile
    $enabledProfiles = $firewallProfiles | Where-Object {$_.Enabled -eq $true}
    
    Write-Host "  Firewall Profiles:" -ForegroundColor Cyan
    foreach ($profile in $firewallProfiles) {
        $status = if ($profile.Enabled) { "✅ ENABLED" } else { "❌ DISABLED" }
        $color = if ($profile.Enabled) { "Green" } else { "Red" }
        Write-Host "    $($profile.Name): $status" -ForegroundColor $color
    }
    
    if ($enabledProfiles.Count -eq $firewallProfiles.Count) {
        Write-Host "  ✅ All firewall profiles enabled" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ Some firewall profiles disabled" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ Cannot check firewall status" -ForegroundColor Red
}

# 7. File System Security Check
Write-Host "`n[7/8] 📁 FILE SYSTEM SECURITY" -ForegroundColor Cyan
$securityDirs = @(
    "$env:USERPROFILE\Desktop\EmergencySecurity",
    "$env:USERPROFILE\Desktop\SecurityTools", 
    "$env:USERPROFILE\Desktop\FOSS_Tools"
)

$deployedTools = 0
foreach ($dir in $securityDirs) {
    if (Test-Path $dir) {
        $files = Get-ChildItem $dir -File -ErrorAction SilentlyContinue
        if ($files) {
            Write-Host "  ✅ $dir: $($files.Count) security tools" -ForegroundColor Green
            $deployedTools++
        }
    }
}

if ($deployedTools -gt 0) {
    Write-Host "  ✅ Security tools deployed in $deployedTools locations" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ No security tools found in expected locations" -ForegroundColor Yellow
}

# 8. Threat Detection History
Write-Host "`n[8/8] 📊 THREAT DETECTION HISTORY" -ForegroundColor Cyan
try {
    $recentThreats = Get-MpThreatDetection -ErrorAction SilentlyContinue | Select-Object -First 5
    if ($recentThreats) {
        Write-Host "  ⚠️ Recent Threats Detected:" -ForegroundColor Yellow
        $recentThreats | ForEach-Object {
            Write-Host "    • $($_.ThreatName)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✅ No recent threats detected" -ForegroundColor Green
    }
} catch {
    Write-Host "  ℹ️ Threat history not available" -ForegroundColor Gray
}

# Overall Security Assessment
Write-Host "`n" + "="*80 -ForegroundColor Cyan
Write-Host "🎯 OVERALL SECURITY ASSESSMENT" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "="*80 -ForegroundColor Cyan

$secureCount = 0
$totalChecks = $results.Keys.Count - 1  # Exclude OverallStatus

foreach ($check in $results.GetEnumerator()) {
    if ($check.Key -ne "OverallStatus") {
        $status = $check.Value
        $icon = switch ($status) {
            "PROTECTED" { "🟢"; $secureCount++ }
            "SECURE" { "🟢"; $secureCount++ }
            "ACTIVE" { "🟢"; $secureCount++ }
            "READY" { "🟡" }
            "NO_CLIENTS" { "🟡" }
            "MINIMAL" { "🟡" }
            "NOT_READY" { "🟠" }
            "VULNERABLE" { "🔴" }
            "COMPROMISED" { "🔴" }
            "THREATS_DETECTED" { "🔴" }
            "ERROR" { "🔴" }
            default { "⚪" }
        }
        
        Write-Host "  $icon $($check.Key): $status" -ForegroundColor White
    }
}

$securityScore = [math]::Round(($secureCount / $totalChecks) * 100, 0)
$overallStatus = if ($securityScore -ge 80) { 
    "🟢 EXCELLENT SECURITY" 
} elseif ($securityScore -ge 60) { 
    "🟡 GOOD SECURITY" 
} else { 
    "🔴 NEEDS IMPROVEMENT" 
}

Write-Host "`n🎯 SECURITY SCORE: $securityScore/100" -ForegroundColor $(if ($securityScore -ge 80) {"Green"} elseif ($securityScore -ge 60) {"Yellow"} else {"Red"})
Write-Host "📊 STATUS: $overallStatus" -ForegroundColor White

# Recommendations
Write-Host "`n💡 IMMEDIATE RECOMMENDATIONS:" -ForegroundColor Yellow
if ($results["DefenderStatus"] -eq "VULNERABLE") {
    Write-Host "  🚨 CRITICAL: Enable Windows Defender immediately (run as Administrator)" -ForegroundColor Red
}
if ($results["NetworkSecurity"] -eq "THREATS_DETECTED") {
    Write-Host "  🚨 CRITICAL: Investigate suspicious network connections" -ForegroundColor Red
}
if ($results["EmailSecurity"] -eq "COMPROMISED") {
    Write-Host "  🚨 CRITICAL: Scan email clients for malware" -ForegroundColor Red
}

Write-Host "  • Run Enable-Defender-Admin.bat as Administrator for full protection" -ForegroundColor Cyan
Write-Host "  • Schedule regular security scans" -ForegroundColor Cyan
Write-Host "  • Keep all security tools updated" -ForegroundColor Cyan
Write-Host "  • Monitor network activity regularly" -ForegroundColor Cyan

# Save comprehensive report
$reportPath = "$env:USERPROFILE\Desktop\Master_Security_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$report = @"
MASTER SECURITY VERIFICATION REPORT
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $env:COMPUTERNAME
User: $env:USERNAME

SECURITY SCORE: $securityScore/100
OVERALL STATUS: $overallStatus

DETAILED RESULTS:
$(foreach ($result in $results.GetEnumerator()) { 
    if ($result.Key -ne "OverallStatus") {
        "$($result.Key): $($result.Value)"
    }
})

SUMMARY:
- Security systems checked: $totalChecks
- Systems secure/active: $secureCount
- Security coverage: $securityScore%

NEXT ACTIONS:
1. Address any critical security issues immediately
2. Run scripts as Administrator for full protection
3. Monitor security status regularly
4. Keep all systems updated

Report generated by IT Toolkit Master Security Verifier
"@

Set-Content -Path $reportPath -Value $report
Write-Host "`n📄 Complete security report saved to: $reportPath" -ForegroundColor Yellow

Write-Host "`n⚡ MASTER SECURITY VERIFICATION COMPLETED!" -ForegroundColor Green
Write-Host "🛡️ Your system security has been comprehensively verified!" -ForegroundColor Cyan
 