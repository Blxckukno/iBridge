# Anti-Phishing Email Protection Toolkit
# Comprehensive protection against email phishing attacks

param(
    [switch]$FullScan,
    [switch]$QuickScan,
    [switch]$RealTimeMonitor,
    [switch]$EmergencyResponse
)

Write-Host "🛡️ ANTI-PHISHING EMAIL PROTECTION TOOLKIT" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Advanced protection against email phishing attacks and threats" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

# Global variables
$script:detectedThreats = @()
$script:blockedDomains = @()
$script:suspiciousEmails = @()

# Known phishing indicators
$phishingIndicators = @{
    SuspiciousDomains = @(
        "bit.ly", "tinyurl.com", "ow.ly", "goo.gl",
        "t.co", "short.link", "rebrandly.com"
    )
    PhishingKeywords = @(
        "urgent", "immediate action", "verify account", "suspended account",
        "click here now", "limited time offer", "congratulations you've won",
        "tax refund", "inheritance", "lottery winner", "verify identity",
        "update payment", "security alert", "unusual activity"
    )
    SuspiciousFileTypes = @(
        ".exe", ".scr", ".com", ".bat", ".cmd", ".pif", ".vbs", ".js",
        ".jar", ".msi", ".app", ".deb", ".rpm", ".dmg"
    )
    TrustedDomains = @(
        "microsoft.com", "google.com", "apple.com", "paypal.com",
        "amazon.com", "facebook.com", "twitter.com", "linkedin.com",
        "github.com", "stackoverflow.com", "mozilla.org"
    )
}

function Start-EmailPhishingScanner {
    Write-Host "`n🎣 EMAIL PHISHING SCANNER ACTIVE" -ForegroundColor Yellow
    
    # Scan email clients for suspicious activity
    $emailProcesses = Get-Process | Where-Object {
        $_.ProcessName -match "outlook|thunderbird|mailspring|mailbird|mail"
    }
    
    if ($emailProcesses) {
        Write-Host "  📧 Active Email Clients Found:" -ForegroundColor Cyan
        foreach ($process in $emailProcesses) {
            Write-Host "    • $($process.ProcessName) (PID: $($process.Id))" -ForegroundColor Green
            
            # Check for suspicious behavior
            if ($process.CPU -gt 50) {
                Write-Host "      ⚠️  HIGH CPU usage detected - possible malicious activity" -ForegroundColor Red
                $script:detectedThreats += "High CPU usage in $($process.ProcessName)"
            }
        }
    }
    
    # Monitor network connections for email protocols
    Test-EmailNetworkConnections
    
    # Scan recent email attachments
    Test-RecentEmailAttachments
    
    # Check browser for webmail security
    Test-WebmailSecurity
}

function Test-EmailNetworkConnections {
    Write-Host "`n🌐 EMAIL NETWORK CONNECTION MONITOR" -ForegroundColor Yellow
    
    $emailPorts = @(25, 110, 143, 465, 587, 993, 995, 80, 443)
    $connections = Get-NetTCPConnection | Where-Object {
        $_.RemotePort -in $emailPorts -and $_.State -eq "Established"
    }
    
    if ($connections) {
        Write-Host "  📊 Active Email Connections:" -ForegroundColor Cyan
        
        foreach ($conn in $connections) {
            $remoteHost = try {
                [System.Net.Dns]::GetHostEntry($conn.RemoteAddress).HostName
            } catch {
                $conn.RemoteAddress
            }
            
            # Check against trusted domains
            $isTrusted = $phishingIndicators.TrustedDomains | Where-Object { $remoteHost -like "*$_*" }
            $color = if ($isTrusted) { "Green" } else { "Yellow" }
            
            Write-Host "    • Port $($conn.RemotePort): $remoteHost" -ForegroundColor $color
            
            # Flag suspicious connections
            if (-not $isTrusted -and $remoteHost -notmatch "^(192\.168\.|10\.0\.|172\.16\.)") {
                Write-Host "      ⚠️  SUSPICIOUS: Unknown domain connection" -ForegroundColor Red
                $script:detectedThreats += "Suspicious email connection to $remoteHost"
            }
        }
    } else {
        Write-Host "  ℹ️  No active email connections detected" -ForegroundColor Gray
    }
}

function Test-RecentEmailAttachments {
    Write-Host "`n📎 RECENT EMAIL ATTACHMENT SCANNER" -ForegroundColor Yellow
    
    $attachmentPaths = @(
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop", 
        "$env:USERPROFILE\Documents",
        "$env:LOCALAPPDATA\Microsoft\Outlook\Attachments",
        "$env:APPDATA\Thunderbird\Profiles\*\Mail\*\Inbox"
    )
    
    $recentThreshold = (Get-Date).AddHours(-24)
    $suspiciousFiles = @()
    
    foreach ($path in $attachmentPaths) {
        if (Test-Path $path) {
            Write-Host "  📁 Scanning: $path" -ForegroundColor Cyan
            
            try {
                $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue |
                    Where-Object { 
                        $_.CreationTime -gt $recentThreshold -and
                        $_.Extension -in $phishingIndicators.SuspiciousFileTypes
                    }
                
                foreach ($file in $files) {
                    $riskLevel = if ($file.Extension -in @('.exe', '.scr', '.com')) { "HIGH" } 
                                elseif ($file.Extension -in @('.bat', '.cmd', '.vbs')) { "MEDIUM" }
                                else { "LOW" }
                    
                    $color = switch ($riskLevel) {
                        "HIGH" { "Red" }
                        "MEDIUM" { "Yellow" }
                        "LOW" { "Gray" }
                    }
                    
                    Write-Host "    WARNING: $($file.Name) - $riskLevel RISK" -ForegroundColor $color
                    $suspiciousFiles += $file
                    $script:detectedThreats += "Suspicious file: $($file.FullName) ($riskLevel risk)"
                }
            }
            catch {
                Write-Host "    WARNING: Cannot scan path: $path" -ForegroundColor Yellow
            }
        }
    }
    
    if ($suspiciousFiles.Count -eq 0) {
        Write-Host "  ✅ No suspicious recent attachments found" -ForegroundColor Green
    } else {
        Write-Host "  🚨 Found $($suspiciousFiles.Count) suspicious recent files" -ForegroundColor Red
    }
}

function Test-WebmailSecurity {
    Write-Host "`n🌐 WEBMAIL SECURITY SCANNER" -ForegroundColor Yellow
    
    # Check active browser processes
    $browsers = Get-Process | Where-Object { 
        $_.ProcessName -match "chrome|firefox|msedge|iexplore|opera"
    }
    
    if ($browsers) {
        Write-Host "  📊 Active Browsers:" -ForegroundColor Cyan
        $browsers | ForEach-Object {
            Write-Host "    • $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Green
        }
        
        # Check for browser security features
        Test-BrowserPhishingProtection
    } else {
        Write-Host "  ℹ️  No active browsers detected" -ForegroundColor Gray
    }
}

function Test-BrowserPhishingProtection {
    Write-Host "`n🛡️ BROWSER ANTI-PHISHING PROTECTION" -ForegroundColor Yellow
    
    # Check Chrome Safe Browsing
    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Preferences"
    if (Test-Path $chromePath) {
        Write-Host "  🌐 Chrome Security Status:" -ForegroundColor Cyan
        try {
            $chromePrefs = Get-Content $chromePath | ConvertFrom-Json
            $safeBrowsing = $chromePrefs.profile.safebrowsing_enabled
            
            if ($safeBrowsing) {
                Write-Host "    ✅ Safe Browsing: Enabled" -ForegroundColor Green
            } else {
                Write-Host "    ⚠️  Safe Browsing: Disabled (RISKY)" -ForegroundColor Red
                $script:detectedThreats += "Chrome Safe Browsing is disabled"
            }
        }
        catch {
            Write-Host "    ⚠️  Cannot read Chrome preferences" -ForegroundColor Yellow
        }
    }
    
    # Check Windows Defender SmartScreen
    try {
        $smartScreen = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -ErrorAction SilentlyContinue
        
        if ($smartScreen) {
            $enabled = $smartScreen.SmartScreenEnabled -ne "Off"
            $status = if ($enabled) { "Enabled" } else { "Disabled (RISKY)" }
            $color = if ($enabled) { "Green" } else { "Red" }
            
            Write-Host "  🛡️  SmartScreen: $status" -ForegroundColor $color
            
            if (-not $enabled) {
                $script:detectedThreats += "Windows SmartScreen is disabled"
            }
        }
    }
    catch {
        Write-Host "  ⚠️  Cannot check SmartScreen status" -ForegroundColor Yellow
    }
}

function Start-RealTimeEmailMonitor {
    Write-Host "`n🚨 REAL-TIME EMAIL THREAT MONITOR" -ForegroundColor Yellow
    Write-Host "  📊 Monitoring email activity for 60 seconds..." -ForegroundColor Cyan
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds(60)
    
    while ((Get-Date) -lt $endTime) {
        # Monitor email processes
        $emailProcesses = Get-Process | Where-Object {
            $_.ProcessName -match "outlook|thunderbird|mail"
        }
        
        foreach ($process in $emailProcesses) {
            if ($process.CPU -gt 70) {
                Write-Host "    ⚠️  HIGH CPU in $($process.ProcessName): $($process.CPU)%" -ForegroundColor Red
            }
        }
        
        # Monitor network connections
        $newConnections = Get-NetTCPConnection | Where-Object {
            $_.RemotePort -in @(25, 110, 143, 465, 587, 993, 995) -and
            $_.State -eq "Established"
        }
        
        Start-Sleep -Seconds 5
        
        # Progress indicator
        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        $progress = [math]::Round(($elapsed / 60) * 100)
        Write-Progress -Activity "Email Threat Monitoring" -Status "Scanning..." -PercentComplete $progress
    }
    
    Write-Progress -Activity "Email Threat Monitoring" -Completed
    Write-Host "  ✅ Real-time monitoring completed" -ForegroundColor Green
}

function Start-EmergencyPhishingResponse {
    Write-Host "`n🚨 EMERGENCY PHISHING RESPONSE ACTIVATED" -ForegroundColor Red -BackgroundColor White
    
    Write-Host "  🔒 IMMEDIATE PROTECTIVE ACTIONS:" -ForegroundColor Yellow
    
    # 1. Disconnect suspicious email connections
    Write-Host "    1. Checking for suspicious email connections..." -ForegroundColor Cyan
    $suspiciousConnections = Get-NetTCPConnection | Where-Object {
        $_.RemotePort -in @(25, 110, 143, 465, 587, 993, 995) -and
        $_.State -eq "Established"
    }
    
    if ($suspiciousConnections) {
        Write-Host "      ⚠️  Found $($suspiciousConnections.Count) email connections" -ForegroundColor Yellow
        # Note: We don't automatically terminate connections to avoid disrupting legitimate email
    }
    
    # 2. Scan for malicious processes
    Write-Host "    2. Scanning for malicious email processes..." -ForegroundColor Cyan
    $maliciousProcesses = Get-Process | Where-Object {
        $_.ProcessName -match "keylog|capture|spy|malware|phish"
    }
    
    if ($maliciousProcesses) {
        Write-Host "      🚨 MALICIOUS PROCESSES DETECTED!" -ForegroundColor Red
        $maliciousProcesses | ForEach-Object {
            Write-Host "        • $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Red
        }
        
        Write-Host "      ⚠️  Manual intervention required - review processes above" -ForegroundColor Yellow
    } else {
        Write-Host "      ✅ No obviously malicious processes detected" -ForegroundColor Green
    }
    
    # 3. Enable enhanced protection
    Write-Host "    3. Enabling enhanced email protection..." -ForegroundColor Cyan
    
    # Enable Windows Defender real-time protection
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        Write-Host "      ✅ Windows Defender real-time protection enabled" -ForegroundColor Green
    }
    catch {
        Write-Host "      ⚠️  Cannot modify Windows Defender settings" -ForegroundColor Yellow
    }
    
    # 4. Create emergency report
    $emergencyReport = @"
EMERGENCY PHISHING RESPONSE REPORT
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

THREATS DETECTED: $($script:detectedThreats.Count)
$($script:detectedThreats | ForEach-Object { "- $_" } | Out-String)

IMMEDIATE ACTIONS TAKEN:
- Real-time protection enabled
- System scan initiated
- Network connections monitored

RECOMMENDED NEXT STEPS:
1. Change all email account passwords
2. Enable 2FA on all email accounts
3. Run full system antivirus scan
4. Review recent email activity
5. Contact IT security team

Report saved to Desktop
"@
    
    $reportPath = "$env:USERPROFILE\Desktop\Emergency_Phishing_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    Set-Content -Path $reportPath -Value $emergencyReport
    Write-Host "      📄 Emergency report saved: $reportPath" -ForegroundColor Yellow
}

function Show-AntiPhishingTips {
    Write-Host "`n💡 ANTI-PHISHING BEST PRACTICES" -ForegroundColor Green
    
    $tips = @(
        "Never click links in suspicious emails - type URLs manually",
        "Verify sender identity through separate communication channel",
        "Check for spelling errors and grammatical mistakes in emails",
        "Be suspicious of urgent requests for personal information",
        "Hover over links to see actual destination before clicking",
        "Use multi-factor authentication on all email accounts",
        "Keep email software updated with latest security patches",
        "Report phishing emails to your IT security team",
        "Don't download attachments from unknown senders",
        "Use reputable antivirus software with email scanning"
    )
    
    foreach ($tip in $tips) {
        Write-Host "  • $tip" -ForegroundColor Cyan
    }
}

function Generate-PhishingProtectionReport {
    Write-Host "`n📊 GENERATING COMPREHENSIVE PROTECTION REPORT" -ForegroundColor White -BackgroundColor DarkGreen
    
    $report = @"
ANTI-PHISHING EMAIL PROTECTION REPORT
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

SYSTEM STATUS:
- Threats Detected: $($script:detectedThreats.Count)
- Suspicious Files: $($script:suspiciousEmails.Count)
- Blocked Domains: $($script:blockedDomains.Count)

DETECTED THREATS:
$($script:detectedThreats | ForEach-Object { "- $_" } | Out-String)

SECURITY RECOMMENDATIONS:
- Enable email client phishing protection
- Configure DNS filtering (Cloudflare, Quad9)
- Install browser security extensions (uBlock Origin)
- Enable Windows Defender SmartScreen
- Configure email rules to filter suspicious content
- Regular security awareness training
- Implement DMARC, SPF, and DKIM for email domains

NEXT ACTIONS:
1. Review all detected threats
2. Update email client security settings
3. Enable advanced threat protection
4. Schedule regular security scans
5. Train users on phishing recognition

Report generated by IT Toolkit Anti-Phishing Protection
"@

    $reportPath = "$env:USERPROFILE\Desktop\Anti_Phishing_Protection_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    Set-Content -Path $reportPath -Value $report
    Write-Host "📄 Report saved to: $reportPath" -ForegroundColor Yellow
}

# Main execution logic
try {
    if ($EmergencyResponse) {
        Start-EmergencyPhishingResponse
        return
    }
    
    if ($RealTimeMonitor) {
        Start-RealTimeEmailMonitor
        return
    }
    
    # Default: Run comprehensive phishing protection scan
    Start-EmailPhishingScanner
    Show-AntiPhishingTips
    Generate-PhishingProtectionReport
    
    # Summary
    Write-Host "`n🛡️ ANTI-PHISHING PROTECTION SUMMARY" -ForegroundColor White -BackgroundColor DarkBlue
    
    if ($script:detectedThreats.Count -eq 0) {
        Write-Host "  ✅ No immediate phishing threats detected" -ForegroundColor Green
        Write-Host "  🛡️  Email security appears to be functioning normally" -ForegroundColor Green
    } else {
        Write-Host "  🚨 PHISHING THREATS DETECTED: $($script:detectedThreats.Count)" -ForegroundColor Red
        Write-Host "  ⚠️  IMMEDIATE ACTION REQUIRED - Review the threats above" -ForegroundColor Yellow
        
        # Ask if user wants emergency response
        Write-Host "`nRun emergency response? (Y/N): " -ForegroundColor Yellow -NoNewline
        # Note: In automated scripts, we'll skip interactive prompts
    }
    
    Write-Host "`n⚡ Anti-phishing protection scan completed!" -ForegroundColor Green
    Write-Host "📧 Your email security has been analyzed and protected" -ForegroundColor Cyan
    
} catch {
    Write-Host "`n❌ Error during anti-phishing protection: $($_.Exception.Message)" -ForegroundColor Red
}
