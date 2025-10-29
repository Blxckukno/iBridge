# Email Security Analysis and Threat Detection Tool
# Comprehensive email security assessment for multiple email clients

Write-Host "📧 EMAIL SECURITY ANALYSIS TOOL" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Scanning for email threats and security vulnerabilities..." -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

$emailThreats = @()
$securityIssues = @()
$recommendations = @()

# Function to check Outlook security
function Test-OutlookSecurity {
    Write-Host "`n📧 MICROSOFT OUTLOOK ANALYSIS" -ForegroundColor Yellow
    
    # Check if Outlook is installed
    $outlookPath = @(
        "${env:ProgramFiles}\Microsoft Office\root\Office16\OUTLOOK.EXE",
        "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\OUTLOOK.EXE",
        "${env:ProgramFiles}\Microsoft Office\Office16\OUTLOOK.EXE",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OUTLOOK.EXE"
    )
    
    $outlookInstalled = $false
    foreach ($path in $outlookPath) {
        if (Test-Path $path) {
            $outlookInstalled = $true
            Write-Host "  ✅ Outlook found at: $path" -ForegroundColor Green
            break
        }
    }
    
    if (-not $outlookInstalled) {
        Write-Host "  ⚠️  Outlook not detected in standard locations" -ForegroundColor Yellow
        return
    }
    
    # Check Outlook registry settings for security
    try {
        $outlookSecurity = @{
            "Macro Security" = $null
            "Attachment Security" = $null
            "External Content" = $null
        }
        
        # Check macro security settings
        $macroSecurity = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\Outlook\Security" -Name "Level" -ErrorAction SilentlyContinue
        if ($macroSecurity) {
            $outlookSecurity["Macro Security"] = switch ($macroSecurity.Level) {
                1 { "Low (Unsafe)" }
                2 { "Medium" }
                3 { "High (Recommended)" }
                4 { "Very High" }
                default { "Unknown" }
            }
        }
        
        Write-Host "  📊 Security Settings:" -ForegroundColor Cyan
        foreach ($setting in $outlookSecurity.GetEnumerator()) {
            if ($setting.Value) {
                $color = if ($setting.Value -match "(High|Very High)") { "Green" } elseif ($setting.Value -match "Low") { "Red" } else { "Yellow" }
                Write-Host "    $($setting.Key): $($setting.Value)" -ForegroundColor $color
            }
        }
    }
    catch {
        Write-Host "  ⚠️  Cannot access Outlook security settings" -ForegroundColor Yellow
    }
    
    # Check for suspicious Outlook add-ins
    try {
        $addinsPath = "HKCU:\Software\Microsoft\Office\Outlook\Addins"
        if (Test-Path $addinsPath) {
            $addins = Get-ChildItem $addinsPath -ErrorAction SilentlyContinue
            if ($addins) {
                Write-Host "  🔌 Installed Add-ins:" -ForegroundColor Cyan
                foreach ($addin in $addins) {
                    $addinName = Split-Path $addin.Name -Leaf
                    $suspicious = $addinName -match "(keylog|capture|monitor|track|spy|malware)"
                    $color = if ($suspicious) { "Red" } else { "Green" }
                    Write-Host "    • $addinName" -ForegroundColor $color
                    
                    if ($suspicious) {
                        $script:emailThreats += "Suspicious Outlook add-in: $addinName"
                    }
                }
            }
        }
    }
    catch {
        Write-Host "  ⚠️  Cannot check Outlook add-ins" -ForegroundColor Yellow
    }
}

# Function to check email client processes
function Test-EmailProcesses {
    Write-Host "`n📧 EMAIL CLIENT PROCESSES" -ForegroundColor Yellow
    
    $emailProcesses = Get-Process | Where-Object {
        $_.ProcessName -match "outlook|thunderbird|mailspring|mailbird|emlxl|mail"
    }
    
    if ($emailProcesses) {
        Write-Host "  📊 Active Email Clients:" -ForegroundColor Cyan
        $emailProcesses | Select-Object ProcessName, Id, 
            @{Name="Memory(MB)";Expression={[math]::Round($_.WorkingSet/1MB,2)}},
            @{Name="CPU";Expression={$_.CPU}} | Format-Table -AutoSize
            
        # Check for suspicious email-related processes
        $suspiciousEmailProcesses = $emailProcesses | Where-Object {
            $_.ProcessName -match "keylog|capture|monitor|spy|malware"
        }
        
        if ($suspiciousEmailProcesses) {
            Write-Host "  🚨 SUSPICIOUS EMAIL PROCESSES DETECTED:" -ForegroundColor Red
            $suspiciousEmailProcesses | ForEach-Object {
                Write-Host "    ⚠️  $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Red
                $script:emailThreats += "Suspicious email process: $($_.ProcessName)"
            }
        }
    } else {
        Write-Host "  ℹ️  No active email clients detected" -ForegroundColor Gray
    }
}

# Function to check email attachments in common locations
function Test-EmailAttachments {
    Write-Host "`n📎 EMAIL ATTACHMENT ANALYSIS" -ForegroundColor Yellow
    
    $attachmentLocations = @(
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Documents",
        "$env:LOCALAPPDATA\Microsoft\Outlook\Attachments"
    )
    
    $suspiciousExtensions = @('.exe', '.scr', '.com', '.bat', '.cmd', '.pif', '.vbs', '.js', '.jar', '.zip')
    $recentThreshold = (Get-Date).AddDays(-7)
    
    foreach ($location in $attachmentLocations) {
        if (Test-Path $location) {
            Write-Host "  📁 Scanning: $location" -ForegroundColor Cyan
            
            try {
                $recentFiles = Get-ChildItem -Path $location -Recurse -File -ErrorAction SilentlyContinue | 
                    Where-Object { 
                        $_.CreationTime -gt $recentThreshold -and
                        $_.Extension -in $suspiciousExtensions
                    } | Select-Object -First 10
                
                if ($recentFiles) {
                    Write-Host "    ⚠️  Recent suspicious files:" -ForegroundColor Yellow
                    foreach ($file in $recentFiles) {
                        $risk = if ($file.Extension -in @('.exe', '.scr', '.com')) { "HIGH" } else { "MEDIUM" }
                        $color = if ($risk -eq "HIGH") { "Red" } else { "Yellow" }
                        Write-Host "      • $($file.Name) ($risk RISK)" -ForegroundColor $color
                        
                        $script:emailThreats += "Suspicious file: $($file.FullName) ($risk risk)"
                    }
                }
            }
            catch {
                Write-Host "    ⚠️  Cannot scan location" -ForegroundColor Yellow
            }
        }
    }
}

# Function to check browser email security
function Test-BrowserEmailSecurity {
    Write-Host "`n🌐 BROWSER EMAIL SECURITY" -ForegroundColor Yellow
    
    # Check for common webmail sessions
    $browsers = @("chrome", "firefox", "msedge", "iexplore")
    $activeBrowsers = Get-Process | Where-Object { $_.ProcessName -in $browsers }
    
    if ($activeBrowsers) {
        Write-Host "  📊 Active Browsers:" -ForegroundColor Cyan
        $activeBrowsers | Select-Object ProcessName, Id | Format-Table -AutoSize
        
        # Check for browser extensions (basic check)
        $extensionPaths = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions",
            "$env:APPDATA\Mozilla\Firefox\Profiles\*.default*\extensions",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Extensions"
        )
        
        foreach ($path in $extensionPaths) {
            if (Test-Path $path) {
                $extensions = Get-ChildItem $path -Directory -ErrorAction SilentlyContinue | Measure-Object
                if ($extensions.Count -gt 0) {
                    Write-Host "    Extensions found in: $path ($($extensions.Count) extensions)" -ForegroundColor Cyan
                }
            }
        }
    }
}

# Function to check Windows Mail app
function Test-WindowsMailApp {
    Write-Host "`n📧 WINDOWS MAIL APP ANALYSIS" -ForegroundColor Yellow
    
    # Check if Windows Mail is installed
    $mailApp = Get-AppxPackage -Name "microsoft.windowscommunicationsapps" -ErrorAction SilentlyContinue
    
    if ($mailApp) {
        Write-Host "  ✅ Windows Mail app installed (Version: $($mailApp.Version))" -ForegroundColor Green
        
        # Check Mail app data location
        $mailDataPath = "$env:LOCALAPPDATA\Packages\microsoft.windowscommunicationsapps_8wekyb3d8bbwe"
        if (Test-Path $mailDataPath) {
            Write-Host "  📁 Mail data location: $mailDataPath" -ForegroundColor Cyan
            
            # Check for suspicious files in mail data
            try {
                $suspiciousFiles = Get-ChildItem $mailDataPath -Recurse -File -ErrorAction SilentlyContinue | 
                    Where-Object { $_.Extension -in @('.exe', '.scr', '.bat') } | Select-Object -First 5
                
                if ($suspiciousFiles) {
                    Write-Host "    ⚠️  Suspicious files in mail data:" -ForegroundColor Red
                    $suspiciousFiles | ForEach-Object {
                        Write-Host "      • $($_.Name)" -ForegroundColor Red
                        $script:emailThreats += "Suspicious file in Mail app: $($_.FullName)"
                    }
                }
            }
            catch {
                Write-Host "    ⚠️  Cannot scan mail data directory" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  ℹ️  Windows Mail app not installed" -ForegroundColor Gray
    }
}

# Function to generate email security recommendations
function Get-EmailSecurityRecommendations {
    Write-Host "`n💡 EMAIL SECURITY RECOMMENDATIONS" -ForegroundColor Green
    
    $recommendations = @(
        "Enable multi-factor authentication (MFA) on all email accounts",
        "Configure email client to block external images and links",
        "Set up email filtering rules to quarantine suspicious attachments",
        "Regularly update email client software",
        "Use encrypted email communication for sensitive information",
        "Enable advanced threat protection in email client",
        "Configure automatic backup of email data",
        "Set up email forwarding alerts to detect unauthorized access",
        "Use strong, unique passwords for email accounts",
        "Regularly review email account access logs"
    )
    
    foreach ($rec in $recommendations) {
        Write-Host "  • $rec" -ForegroundColor Cyan
    }
}

# Main execution
try {
    Test-OutlookSecurity
    Test-EmailProcesses
    Test-EmailAttachments
    Test-BrowserEmailSecurity
    Test-WindowsMailApp
    
    # Summary
    Write-Host "`n📊 EMAIL SECURITY SUMMARY" -ForegroundColor White -BackgroundColor DarkGreen
    
    if ($emailThreats.Count -eq 0) {
        Write-Host "  ✅ No immediate email security threats detected" -ForegroundColor Green
    } else {
        Write-Host "  🚨 EMAIL SECURITY THREATS DETECTED ($($emailThreats.Count)):" -ForegroundColor Red
        foreach ($threat in $emailThreats) {
            Write-Host "    • $threat" -ForegroundColor Red
        }
    }
    
    Get-EmailSecurityRecommendations
    
    # Save report
    $reportPath = "$env:USERPROFILE\Desktop\Email_Security_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $report = @"
EMAIL SECURITY ANALYSIS REPORT
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

THREATS DETECTED: $($emailThreats.Count)
$(if ($emailThreats) { $emailThreats | ForEach-Object { "- $_" } | Out-String })

RECOMMENDATIONS:
$($recommendations | ForEach-Object { "- $_" } | Out-String)

Report generated by IT Toolkit Email Security Analyzer
"@

    Set-Content -Path $reportPath -Value $report
    Write-Host "`n📄 Report saved to: $reportPath" -ForegroundColor Yellow
    
} catch {
    Write-Host "`n❌ Error during email security analysis: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n⚡ Email security analysis completed!" -ForegroundColor Green
