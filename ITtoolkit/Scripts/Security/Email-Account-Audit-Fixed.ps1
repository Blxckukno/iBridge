# Advanced Email Account Security Audit Tool
# Comprehensive analysis of email account security and threat indicators

Write-Host "EMAIL ACCOUNT SECURITY AUDIT" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Analyzing email accounts for security threats and compromised indicators..." -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

$securityIssues = @()
$recommendations = @()

function Test-EmailClientConnections {
    Write-Host "`nEMAIL CLIENT CONNECTION ANALYSIS" -ForegroundColor Yellow
    
    try {
        # Check for active email connections
        $emailPorts = @(25, 110, 143, 465, 587, 993, 995)
        $emailConnections = Get-NetTCPConnection | Where-Object {
            $_.RemotePort -in $emailPorts -or $_.LocalPort -in $emailPorts
        }
        
        if ($emailConnections) {
            Write-Host "  Active Email Connections:" -ForegroundColor Cyan
            $emailConnections | Select-Object LocalPort, RemoteAddress, RemotePort, State | Format-Table -AutoSize
            
            # Check for suspicious connections
            $suspiciousConnections = $emailConnections | Where-Object {
                $_.RemoteAddress -notmatch "^(outlook|imap|smtp|pop|gmail|yahoo|mail)" -and
                $_.RemoteAddress -notmatch "^(192\.168\.|10\.0\.|172\.16\.)" -and
                $_.State -eq "Established"
            }
            
            if ($suspiciousConnections) {
                Write-Host "  WARNING: Suspicious Email Connections:" -ForegroundColor Red
                $suspiciousConnections | ForEach-Object {
                    Write-Host "    - Connection to $($_.RemoteAddress):$($_.RemotePort)" -ForegroundColor Red
                    $script:securityIssues += "Suspicious email connection to $($_.RemoteAddress):$($_.RemotePort)"
                }
            }
        } else {
            Write-Host "  No active email connections detected" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "Error checking email connections: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-OutlookConfiguration {
    Write-Host "`nOUTLOOK SECURITY CONFIGURATION" -ForegroundColor Yellow
    
    try {
        # Check Outlook registry for security settings
        $outlookVersions = @("16.0", "15.0", "14.0")
        
        foreach ($version in $outlookVersions) {
            $outlookPath = "HKCU:\Software\Microsoft\Office\$version\Outlook"
            
            if (Test-Path $outlookPath) {
                Write-Host "  Outlook $version Configuration:" -ForegroundColor Cyan
                
                # Check security settings
                $securityPath = "$outlookPath\Security"
                if (Test-Path $securityPath) {
                    try {
                        # Macro security level
                        $macroLevel = Get-ItemProperty -Path $securityPath -Name "Level" -ErrorAction SilentlyContinue
                        if ($macroLevel) {
                            $securityLevel = switch ($macroLevel.Level) {
                                1 { "Low (DANGEROUS)" }
                                2 { "Medium (RISKY)" }
                                3 { "High (RECOMMENDED)" }
                                4 { "Very High (SECURE)" }
                                default { "Unknown" }
                            }
                            
                            $color = if ($macroLevel.Level -ge 3) { "Green" } else { "Red" }
                            Write-Host "    Macro Security: $securityLevel" -ForegroundColor $color
                            
                            if ($macroLevel.Level -lt 3) {
                                $script:securityIssues += "Outlook macro security set to unsafe level"
                            }
                        }
                        
                        # External content settings
                        $externalContent = Get-ItemProperty -Path $securityPath -Name "BlockExtContent" -ErrorAction SilentlyContinue
                        if ($externalContent) {
                            $blocked = if ($externalContent.BlockExtContent) { "Blocked (SECURE)" } else { "Allowed (RISKY)" }
                            $color = if ($externalContent.BlockExtContent) { "Green" } else { "Red" }
                            Write-Host "    External Content: $blocked" -ForegroundColor $color
                            
                            if (-not $externalContent.BlockExtContent) {
                                $script:securityIssues += "Outlook allows external content (security risk)"
                            }
                        }
                    }
                    catch {
                        Write-Host "    WARNING: Cannot read security settings" -ForegroundColor Yellow
                    }
                }
                
                # Check for suspicious rules
                $rulesPath = "$outlookPath\Rules"
                if (Test-Path $rulesPath) {
                    try {
                        $rules = Get-ChildItem $rulesPath -ErrorAction SilentlyContinue
                        if ($rules) {
                            Write-Host "    Email Rules: $($rules.Count) configured" -ForegroundColor Cyan
                            
                            # Look for suspicious rule patterns
                            foreach ($rule in $rules) {
                                $ruleName = Split-Path $rule.Name -Leaf
                                if ($ruleName -match "(forward|redirect|delete|move).*external|auto.*reply") {
                                    Write-Host "      WARNING: Potentially suspicious rule: $ruleName" -ForegroundColor Yellow
                                    $script:securityIssues += "Suspicious Outlook rule detected: $ruleName"
                                }
                            }
                        }
                    }
                    catch {
                        Write-Host "    Cannot access email rules" -ForegroundColor Gray
                    }
                }
                break
            }
        }
    }
    catch {
        Write-Host "Error checking Outlook configuration: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-BrowserStoredPasswords {
    Write-Host "`nBROWSER STORED EMAIL CREDENTIALS" -ForegroundColor Yellow
    
    try {
        # Check for stored passwords in browsers (basic detection)
        $browserPaths = @{
            "Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
            "Edge" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data"
            "Firefox" = "$env:APPDATA\Mozilla\Firefox\Profiles\*.default*\logins.json"
        }
        
        foreach ($browser in $browserPaths.GetEnumerator()) {
            $paths = Get-ChildItem $browser.Value -ErrorAction SilentlyContinue
            if ($paths) {
                Write-Host "  $($browser.Key): Credential store detected" -ForegroundColor Cyan
                Write-Host "    Location: $($browser.Value)" -ForegroundColor Gray
                
                # Recommend password manager instead
                $script:recommendations += "Use dedicated password manager instead of browser for email credentials"
            }
        }
    }
    catch {
        Write-Host "Error checking browser passwords: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-EmailCertificates {
    Write-Host "`nEMAIL CERTIFICATE ANALYSIS" -ForegroundColor Yellow
    
    try {
        # Check for S/MIME certificates
        $personalCerts = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object {
            $_.EnhancedKeyUsageList -match "Secure Email|Client Authentication"
        }
        
        if ($personalCerts) {
            Write-Host "  Email Certificates Found:" -ForegroundColor Cyan
            foreach ($cert in $personalCerts) {
                $status = if ($cert.NotAfter -gt (Get-Date)) { "Valid" } else { "EXPIRED" }
                $color = if ($status -eq "Valid") { "Green" } else { "Red" }
                
                Write-Host "    - $($cert.Subject) - $status" -ForegroundColor $color
                Write-Host "      Expires: $($cert.NotAfter)" -ForegroundColor Gray
                
                if ($cert.NotAfter -lt (Get-Date)) {
                    $script:securityIssues += "Expired email certificate: $($cert.Subject)"
                }
            }
        } else {
            Write-Host "  No email certificates installed" -ForegroundColor Gray
            $script:recommendations += "Consider using S/MIME certificates for email encryption"
        }
    }
    catch {
        Write-Host "Error checking certificates: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-EmailBackupSecurity {
    Write-Host "`nEMAIL BACKUP SECURITY" -ForegroundColor Yellow
    
    try {
        $backupLocations = @(
            "$env:LOCALAPPDATA\Microsoft\Outlook\*.pst",
            "$env:USERPROFILE\Documents\Outlook Files\*.pst",
            "$env:USERPROFILE\Desktop\*.pst",
            "$env:USERPROFILE\Documents\*.pst"
        )
        
        $foundBackups = @()
        foreach ($location in $backupLocations) {
            $files = Get-ChildItem $location -ErrorAction SilentlyContinue
            if ($files) {
                $foundBackups += $files
            }
        }
        
        if ($foundBackups) {
            Write-Host "  Email Backup Files Found:" -ForegroundColor Cyan
            foreach ($backup in $foundBackups) {
                Write-Host "    - $($backup.FullName)" -ForegroundColor Gray
                Write-Host "      Size: $([math]::Round($backup.Length/1MB,2)) MB" -ForegroundColor Gray
                Write-Host "      Modified: $($backup.LastWriteTime)" -ForegroundColor Gray
                
                # Check if backup is in a secure location
                if ($backup.FullName -match "(Desktop|Downloads|Public)") {
                    Write-Host "      WARNING: Located in potentially insecure location" -ForegroundColor Yellow
                    $script:securityIssues += "Email backup in insecure location: $($backup.FullName)"
                }
            }
            
            $script:recommendations += "Encrypt email backup files and store in secure location"
            $script:recommendations += "Regularly test email backup restoration process"
        } else {
            Write-Host "  No email backup files found in common locations" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "Error checking email backups: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-EmailPhishingProtection {
    Write-Host "`nANTI-PHISHING CONFIGURATION" -ForegroundColor Yellow
    
    try {
        # Check Windows Defender SmartScreen
        try {
            $smartScreen = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -ErrorAction SilentlyContinue
            
            if ($smartScreen) {
                $status = switch ($smartScreen.SmartScreenEnabled) {
                    "Off" { "Disabled (RISKY)" }
                    "RequireAdmin" { "Enabled for Downloads" }
                    "Warn" { "Enabled with Warnings" }
                    default { "Unknown" }
                }
                
                $color = if ($smartScreen.SmartScreenEnabled -ne "Off") { "Green" } else { "Red" }
                Write-Host "  SmartScreen: $status" -ForegroundColor $color
                
                if ($smartScreen.SmartScreenEnabled -eq "Off") {
                    $script:securityIssues += "Windows SmartScreen disabled - increases phishing risk"
                }
            }
        }
        catch {
            Write-Host "  Cannot check SmartScreen status" -ForegroundColor Yellow
        }
        
        # Check browser phishing protection
        Write-Host "  Browser Protection Recommendations:" -ForegroundColor Cyan
        $browserRecommendations = @(
            "Enable Safe Browsing in Chrome/Edge",
            "Install uBlock Origin for additional protection",
            "Enable phishing and malware protection in Firefox",
            "Configure DNS filtering (Cloudflare, Quad9)"
        )
        
        foreach ($rec in $browserRecommendations) {
            Write-Host "    - $rec" -ForegroundColor Gray
            $script:recommendations += $rec
        }
    }
    catch {
        Write-Host "Error checking phishing protection: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-EmailSecurityRecommendations {
    Write-Host "`nCOMPREHENSIVE EMAIL SECURITY RECOMMENDATIONS" -ForegroundColor Green
    
    $allRecommendations = @(
        "Enable two-factor authentication (2FA) on all email accounts",
        "Use app-specific passwords instead of main account passwords",
        "Regularly review email account access logs and connected devices",
        "Set up email forwarding alerts to detect unauthorized access",
        "Configure email client to download images only from trusted senders",
        "Enable advanced threat protection (ATP) if available",
        "Use encrypted email for sensitive communications (S/MIME, PGP)",
        "Regularly backup email data to secure, encrypted storage",
        "Keep email clients updated to latest security patches",
        "Train users to recognize phishing and social engineering attempts",
        "Implement email filtering and anti-spam solutions",
        "Use strong, unique passwords for each email account",
        "Enable email client security logging and monitoring",
        "Configure automatic email encryption for external communications",
        "Regularly audit email forwarding rules and delegates"
    )
    
    # Combine with detected recommendations
    $finalRecommendations = $allRecommendations + $script:recommendations | Sort-Object | Get-Unique
    
    foreach ($rec in $finalRecommendations) {
        Write-Host "  - $rec" -ForegroundColor Cyan
    }
    
    return $finalRecommendations
}

# Main execution
try {
    Test-EmailClientConnections
    Test-OutlookConfiguration
    Test-BrowserStoredPasswords
    Test-EmailCertificates
    Test-EmailBackupSecurity
    Test-EmailPhishingProtection
    
    $allRecommendations = Get-EmailSecurityRecommendations
    
    # Generate summary
    Write-Host "`nEMAIL SECURITY AUDIT SUMMARY" -ForegroundColor White -BackgroundColor DarkGreen
    
    if ($securityIssues.Count -eq 0) {
        Write-Host "  SUCCESS: No critical email security issues detected" -ForegroundColor Green
        $riskLevel = "LOW"
    } elseif ($securityIssues.Count -le 3) {
        Write-Host "  CAUTION: Minor email security issues detected" -ForegroundColor Yellow
        $riskLevel = "MEDIUM"
    } else {
        Write-Host "  ALERT: Multiple email security issues require attention" -ForegroundColor Red
        $riskLevel = "HIGH"
    }
    
    Write-Host "  Risk Level: $riskLevel" -ForegroundColor $(if ($riskLevel -eq "LOW") {"Green"} elseif ($riskLevel -eq "MEDIUM") {"Yellow"} else {"Red"})
    Write-Host "  Issues Found: $($securityIssues.Count)" -ForegroundColor $(if ($securityIssues.Count -eq 0) {"Green"} else {"Yellow"})
    Write-Host "  Recommendations: $($allRecommendations.Count)" -ForegroundColor Cyan
    
    if ($securityIssues.Count -gt 0) {
        Write-Host "`n  Security Issues Detected:" -ForegroundColor Red
        foreach ($issue in $securityIssues) {
            Write-Host "    - $issue" -ForegroundColor Red
        }
    }
    
    # Save detailed report
    $reportPath = "$env:USERPROFILE\Desktop\Email_Security_Audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $report = @"
EMAIL ACCOUNT SECURITY AUDIT REPORT
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $env:COMPUTERNAME
User: $env:USERNAME

RISK LEVEL: $riskLevel

SECURITY ISSUES DETECTED ($($securityIssues.Count)):
$(if ($securityIssues) { $securityIssues | ForEach-Object { "WARNING: $_" } | Out-String })

SECURITY RECOMMENDATIONS ($($allRecommendations.Count)):
$(foreach ($rec in $allRecommendations) { "RECOMMEND: $rec" })

AUDIT AREAS COVERED:
- Email client connections and suspicious activity
- Outlook security configuration and rules
- Browser stored email credentials
- Email certificates and encryption
- Email backup security
- Anti-phishing protection status

NEXT STEPS:
1. Address all identified security issues immediately
2. Implement high-priority recommendations
3. Enable two-factor authentication on all email accounts
4. Regular monitoring and security audits
5. User training on email security best practices

Report generated by IT Toolkit Email Security Auditor
"@

    Set-Content -Path $reportPath -Value $report
    Write-Host "`nDetailed audit report saved to: $reportPath" -ForegroundColor Yellow
    
} catch {
    Write-Host "`nError during email security audit: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nEmail account security audit completed!" -ForegroundColor Green
