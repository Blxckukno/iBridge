# Future-Attack-Preparation-Toolkit.ps1
# Comprehensive proactive security measures to prevent future attacks
# Includes configuration hardening, monitoring setup, and security baseline establishment
# Run with administrator privileges

# Enable transcript logging
$logPath = "$env:USERPROFILE\Desktop\Security-Preparation-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').log"
Start-Transcript -Path $logPath

function Write-ColorOutput {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "===================================================" "Cyan"
Write-ColorOutput "   FUTURE ATTACK PREPARATION TOOLKIT" "Cyan"
Write-ColorOutput "   Comprehensive Security Hardening & Monitoring" "Cyan"
Write-ColorOutput "===================================================" "Cyan"
Write-ColorOutput ""

#region Check for Administrator Rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-ColorOutput "ERROR: This script must be run as Administrator. Please relaunch with elevated privileges." "Red"
    Exit 1
}
#endregion

#region Create Output Directory
$outputDir = "$env:USERPROFILE\Desktop\Security_Preparation_Results"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    Write-ColorOutput "Created output directory: $outputDir" "Green"
}
#endregion

#region 1. System Hardening
Write-ColorOutput "`n[1/7] System Hardening..." "Yellow"

# 1.1 Enable Windows Firewall on all profiles
Write-ColorOutput "  • Enabling Windows Firewall on all profiles..." "White"
try {
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Write-ColorOutput "    ✓ Windows Firewall enabled on all profiles" "Green"
} catch {
    Write-ColorOutput "    ✗ Failed to enable Windows Firewall: $_" "Red"
}

# 1.2 Enable Windows Defender real-time protection
Write-ColorOutput "  • Configuring Windows Defender..." "White"
try {
    Set-MpPreference -DisableRealtimeMonitoring $false
    Set-MpPreference -SubmitSamplesConsent 2
    Set-MpPreference -MAPSReporting Advanced
    Set-MpPreference -DisableIOAVProtection $false
    Write-ColorOutput "    ✓ Windows Defender real-time protection enabled" "Green"
} catch {
    Write-ColorOutput "    ✗ Failed to configure Windows Defender: $_" "Red"
}

# 1.3 Set UAC to maximum level
Write-ColorOutput "  • Setting UAC to maximum level..." "White"
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser" -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 1
    Write-ColorOutput "    ✓ UAC set to maximum level" "Green"
} catch {
    Write-ColorOutput "    ✗ Failed to configure UAC: $_" "Red"
}

# 1.4 Enable SMB signing
Write-ColorOutput "  • Enabling SMB signing..." "White"
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RequireSecuritySignature" -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "EnableSecuritySignature" -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "RequireSecuritySignature" -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "EnableSecuritySignature" -Value 1
    Write-ColorOutput "    ✓ SMB signing enabled" "Green"
} catch {
    Write-ColorOutput "    ✗ Failed to enable SMB signing: $_" "Red"
}

# 1.5 Disable unnecessary services
$unnecessaryServices = @("RemoteRegistry", "TlntSvr", "SNMPTRAP", "SharedAccess", "SSDPSRV")
Write-ColorOutput "  • Disabling unnecessary services..." "White"
foreach ($service in $unnecessaryServices) {
    try {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Write-ColorOutput "    ✓ Service '$service' disabled" "Green"
    } catch {
        Write-ColorOutput "    ✗ Failed to disable service '$service': $_" "Red"
    }
}

# 1.6 Enable PowerShell script block logging
Write-ColorOutput "  • Enabling PowerShell script block logging..." "White"
try {
    if (-not (Test-Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging")) {
        New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1
    Write-ColorOutput "    ✓ PowerShell script block logging enabled" "Green"
} catch {
    Write-ColorOutput "    ✗ Failed to enable PowerShell script block logging: $_" "Red"
}
#endregion

#region 2. Email Security Configuration
Write-ColorOutput "`n[2/7] Email Security Configuration..." "Yellow"

# 2.1 Create email security checklist
$emailSecurityChecklistPath = "$outputDir\Email_Security_Checklist.md"
$emailSecurityChecklist = @"
# Email Security Checklist

## Email Authentication Protocols
- [ ] Enable SPF (Sender Policy Framework)
- [ ] Implement DKIM (DomainKeys Identified Mail)
- [ ] Configure DMARC (Domain-based Message Authentication, Reporting & Conformance)

## Account Security
- [ ] Enable MFA (Multi-Factor Authentication) for all email accounts
- [ ] Implement strong password policies (minimum 14 characters, complexity)
- [ ] Set up automatic account lockout after multiple failed attempts
- [ ] Configure regular password rotation (every 60-90 days)

## Email Gateway Security
- [ ] Deploy advanced spam filtering
- [ ] Implement attachment scanning and sandboxing
- [ ] Enable link protection and URL rewriting
- [ ] Configure data loss prevention (DLP) policies

## Admin Settings
- [ ] Restrict mail forwarding to external domains
- [ ] Disable auto-forwarding where possible
- [ ] Limit mailbox delegation permissions
- [ ] Set up alerts for suspicious mailbox rules
- [ ] Implement geo-fencing for login attempts
- [ ] Enable mailbox audit logging

## User Security Training
- [ ] Regular phishing awareness training
- [ ] Recognition of social engineering tactics
- [ ] Proper handling of suspicious emails
- [ ] Reporting procedures for security incidents
"@
Set-Content -Path $emailSecurityChecklistPath -Value $emailSecurityChecklist
Write-ColorOutput "  • Email security checklist created: $emailSecurityChecklistPath" "Green"

# 2.2 Check for suspicious mail forwarding rules (requires Exchange Online connection)
Write-ColorOutput "  • NOTE: To check for suspicious mail forwarding rules, connect to Exchange Online with:" "Yellow"
Write-ColorOutput "    Connect-ExchangeOnline -UserPrincipalName admin@yourdomain.com" "Yellow"
Write-ColorOutput "    Get-Mailbox | Get-InboxRule | Where {`$_.ForwardTo -ne `$null -or `$_.ForwardAsAttachmentTo -ne `$null -or `$_.RedirectTo -ne `$null} | Format-Table Name,Identity,ForwardTo,RedirectTo" "Yellow"
#endregion

#region 3. Network Security Baseline
Write-ColorOutput "`n[3/7] Network Security Baseline..." "Yellow"

# 3.1 Check for open ports
Write-ColorOutput "  • Checking for open ports..." "White"
$openPorts = @()
try {
    $listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | 
                Select-Object LocalPort, @{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}} | 
                Sort-Object LocalPort -Unique

    foreach ($listener in $listeners) {
        $openPorts += [PSCustomObject]@{
            Port = $listener.LocalPort
            Process = $listener.Process
            Risk = if ($listener.LocalPort -in 20, 21, 22, 23, 25, 445, 3389, 5900) { "High" } else { "Low" }
        }
    }
    
    $openPortsPath = "$outputDir\Open_Ports.csv"
    $openPorts | Export-Csv -Path $openPortsPath -NoTypeInformation
    Write-ColorOutput "    ✓ Open ports report saved to: $openPortsPath" "Green"
    
    # Display high-risk ports
    $highRiskPorts = $openPorts | Where-Object { $_.Risk -eq "High" }
    if ($highRiskPorts) {
        Write-ColorOutput "    ! WARNING: High-risk ports detected:" "Red"
        foreach ($port in $highRiskPorts) {
            Write-ColorOutput "      - Port $($port.Port) ($($port.Process))" "Red"
        }
    } else {
        Write-ColorOutput "    ✓ No high-risk ports detected" "Green"
    }
} catch {
    Write-ColorOutput "    ✗ Failed to check for open ports: $_" "Red"
}

# 3.2 Create firewall baseline rules
Write-ColorOutput "  • Creating firewall baseline rules..." "White"
try {
    # Block common dangerous ports
    $dangerousPorts = @(20, 21, 23, 69, 111, 135, 139, 445, 5900)
    
    foreach ($port in $dangerousPorts) {
        $ruleName = "Block-Dangerous-Port-$port"
        if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $port -Protocol TCP -Action Block -Enabled True
            Write-ColorOutput "    ✓ Created rule to block port $port" "Green"
        } else {
            Write-ColorOutput "    ✓ Rule to block port $port already exists" "Green"
        }
    }
    
    # Create rules allowing only necessary outbound traffic
    $allowedPorts = @(80, 443, 53)
    foreach ($port in $allowedPorts) {
        $ruleName = "Allow-Common-Port-$port"
        if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -LocalPort $port -Protocol TCP -Action Allow -Enabled True
            Write-ColorOutput "    ✓ Created rule to allow port $port" "Green"
        } else {
            Write-ColorOutput "    ✓ Rule to allow port $port already exists" "Green"
        }
    }
} catch {
    Write-ColorOutput "    ✗ Failed to create firewall rules: $_" "Red"
}

# 3.3 Check DNS settings
Write-ColorOutput "  • Checking DNS settings..." "White"
try {
    $dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | 
                  Where-Object { $_.ServerAddresses } | 
                  Select-Object InterfaceAlias, ServerAddresses
    
    $dnsServersPath = "$outputDir\DNS_Servers.csv"
    $dnsServers | Export-Csv -Path $dnsServersPath -NoTypeInformation
    Write-ColorOutput "    ✓ DNS server report saved to: $dnsServersPath" "Green"
    
    # Check for public DNS servers
    $publicDNS = @("8.8.8.8", "8.8.4.4", "1.1.1.1", "1.0.0.1", "9.9.9.9", "149.112.112.112", "208.67.222.222", "208.67.220.220")
    $usingPublicDNS = $false
    
    foreach ($dns in $dnsServers) {
        foreach ($server in $dns.ServerAddresses) {
            if ($server -in $publicDNS) {
                Write-ColorOutput "    ! Using public DNS server: $server on $($dns.InterfaceAlias)" "Yellow"
                $usingPublicDNS = $true
            }
        }
    }
    
    if (-not $usingPublicDNS) {
        Write-ColorOutput "    ✓ Using internal DNS servers" "Green"
    }
} catch {
    Write-ColorOutput "    ✗ Failed to check DNS settings: $_" "Red"
}
#endregion

#region 4. Endpoint Detection & Response Setup
Write-ColorOutput "`n[4/7] Endpoint Detection & Response Setup..." "Yellow"

# 4.1 Set up Sysmon (Microsoft Sysinternals)
Write-ColorOutput "  • Setting up Sysmon for advanced event monitoring..." "White"
$sysmonDir = "$env:ProgramFiles\Sysmon"
$sysmonUrl = "https://download.sysinternals.com/files/Sysmon.zip"
$sysmonZip = "$env:TEMP\Sysmon.zip"
$sysmonConfigUrl = "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml"
$sysmonConfig = "$env:TEMP\sysmonconfig.xml"

try {
    # Create Sysmon directory if it doesn't exist
    if (-not (Test-Path $sysmonDir)) {
        New-Item -Path $sysmonDir -ItemType Directory -Force | Out-Null
    }
    
    # Download Sysmon
    Invoke-WebRequest -Uri $sysmonUrl -OutFile $sysmonZip -UseBasicParsing
    
    # Extract Sysmon
    Expand-Archive -Path $sysmonZip -DestinationPath $sysmonDir -Force
    
    # Download Swift on Security's Sysmon config
    Invoke-WebRequest -Uri $sysmonConfigUrl -OutFile $sysmonConfig -UseBasicParsing
    
    # Install Sysmon with the downloaded config
    Start-Process -FilePath "$sysmonDir\Sysmon64.exe" -ArgumentList "-accepteula -i $sysmonConfig" -Wait -NoNewWindow
    
    Write-ColorOutput "    ✓ Sysmon installed and configured successfully" "Green"
} catch {
    Write-ColorOutput "    ✗ Failed to set up Sysmon: $_" "Red"
    Write-ColorOutput "    ! Manual installation required. Download from: https://docs.microsoft.com/en-us/sysinternals/downloads/sysmon" "Yellow"
}

# 4.2 Enable additional Windows event logging
Write-ColorOutput "  • Enhancing Windows event logging..." "White"
try {
    # Enable PowerShell module logging
    if (-not (Test-Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging")) {
        New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" -Value 1
    
    # Enable command line process auditing
    $commandLineAudit = 'cmd /c reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit" /v ProcessCreationIncludeCmdLine_Enabled /t REG_DWORD /d 1 /f'
    Invoke-Expression -Command $commandLineAudit
    
    # Enable additional audit policies
    auditpol /set /subcategory:"Security Group Management" /success:enable /failure:enable
    auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable
    auditpol /set /subcategory:"Logon" /success:enable /failure:enable
    auditpol /set /subcategory:"Account Lockout" /success:enable /failure:enable
    auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
    auditpol /set /subcategory:"Credential Validation" /success:enable /failure:enable
    
    Write-ColorOutput "    ✓ Enhanced Windows event logging configured" "Green"
} catch {
    Write-ColorOutput "    ✗ Failed to enhance Windows event logging: $_" "Red"
}

# 4.3 Create local security baseline script
$securityBaselineScriptPath = "$outputDir\Run-SecurityBaseline.ps1"
$securityBaselineScript = @'
# Run-SecurityBaseline.ps1
# Regular security checks to maintain system security posture
# Run this script weekly as administrator

# Check for unauthorized scheduled tasks
Write-Host "Checking for unauthorized scheduled tasks..." -ForegroundColor Cyan
Get-ScheduledTask | Where-Object { $_.Author -notmatch "Microsoft" } | 
    Format-Table TaskName, Author, State -AutoSize

# Check for unusual services
Write-Host "Checking for unusual services..." -ForegroundColor Cyan
Get-Service | Where-Object { $_.StartType -eq "Automatic" -and $_.Status -eq "Running" } | 
    Where-Object { $_.DisplayName -notmatch "Microsoft|Windows|Intel|NVIDIA|AMD|Dell|HP|Lenovo" } |
    Format-Table Name, DisplayName, Status, StartType -AutoSize

# Check for non-standard startup items
Write-Host "Checking startup items..." -ForegroundColor Cyan
Get-CimInstance Win32_StartupCommand | 
    Format-Table Name, User, Command -AutoSize

# Check for unusual network connections
Write-Host "Checking network connections..." -ForegroundColor Cyan
Get-NetTCPConnection -State Established |
    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess, @{Name="ProcessName";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}} |
    Where-Object { $_.RemoteAddress -notmatch "127.0.0.1|192.168.|10." } |
    Format-Table -AutoSize

# Check for unauthorized local admins
Write-Host "Checking local administrators..." -ForegroundColor Cyan
(Get-LocalGroupMember -Group "Administrators").Name

# Export event logs with critical errors
Write-Host "Checking for critical events..." -ForegroundColor Cyan
$criticalEvents = Get-WinEvent -FilterHashtable @{LogName='System','Application','Security'; Level=1,2} -MaxEvents 100 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, LogName, ProviderName, Id, LevelDisplayName, Message
$criticalEvents | Format-Table -AutoSize

# Write results to file
$outputPath = "$env:USERPROFILE\Desktop\SecurityBaseline-$(Get-Date -Format 'yyyy-MM-dd').csv"
$criticalEvents | Export-Csv -Path $outputPath -NoTypeInformation
Write-Host "Security baseline report saved to: $outputPath" -ForegroundColor Green
'@
Set-Content -Path $securityBaselineScriptPath -Value $securityBaselineScript
Write-ColorOutput "  • Created local security baseline script: $securityBaselineScriptPath" "Green"
#endregion

#region 5. Security Monitoring Setup
Write-ColorOutput "`n[5/7] Security Monitoring Setup..." "Yellow"

# 5.1 Create a script to monitor for suspicious activities
$monitoringScriptPath = "$outputDir\Monitor-Security.ps1"
$monitoringScript = @'
# Monitor-Security.ps1
# Continuous security monitoring script
# Run this script daily as administrator

# Define output file location
$outputDir = "$env:USERPROFILE\SecurityMonitoring"
$dateStamp = Get-Date -Format "yyyy-MM-dd"
$outputPath = "$outputDir\SecurityMonitoring-$dateStamp.log"

# Create output directory if it doesn't exist
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Start logging
Start-Transcript -Path $outputPath -Append

function Write-LogEntry {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Type] $Message"
}

Write-LogEntry "Starting security monitoring scan"

# Monitor failed logon attempts
Write-LogEntry "Checking for failed logon attempts in the past 24 hours" "CHECK"
try {
    $failedLogons = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625
        StartTime = (Get-Date).AddDays(-1)
    } -ErrorAction SilentlyContinue
    
    if ($failedLogons -and $failedLogons.Count -gt 0) {
        Write-LogEntry "Found $($failedLogons.Count) failed logon attempts" "ALERT"
        
        $failedLogons | ForEach-Object {
            $workstation = $_.Properties[13].Value
            $username = $_.Properties[5].Value
            $domain = $_.Properties[6].Value
            
            Write-LogEntry "Failed logon: $domain\$username from $workstation" "ALERT"
        }
    } else {
        Write-LogEntry "No failed logon attempts detected" "OK"
    }
} catch {
    Write-LogEntry "Error checking failed logons: $_" "ERROR"
}

# Monitor for new user accounts
Write-LogEntry "Checking for recently created user accounts" "CHECK"
try {
    $newAccounts = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4720
        StartTime = (Get-Date).AddDays(-7)
    } -ErrorAction SilentlyContinue
    
    if ($newAccounts -and $newAccounts.Count -gt 0) {
        Write-LogEntry "Found $($newAccounts.Count) new user accounts created in the past 7 days" "ALERT"
        
        $newAccounts | ForEach-Object {
            $creator = $_.Properties[4].Value
            $newUser = $_.Properties[0].Value
            
            Write-LogEntry "New account: $newUser created by $creator" "ALERT"
        }
    } else {
        Write-LogEntry "No new user accounts detected" "OK"
    }
} catch {
    Write-LogEntry "Error checking new accounts: $_" "ERROR"
}

# Monitor for privilege escalation
Write-LogEntry "Checking for privilege escalation events" "CHECK"
try {
    $privilegeEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4672
        StartTime = (Get-Date).AddDays(-1)
    } -ErrorAction SilentlyContinue
    
    $privilegeUsers = $privilegeEvents | ForEach-Object { $_.Properties[1].Value } | Sort-Object -Unique
    
    Write-LogEntry "Users with special privileges in the past 24 hours: $($privilegeUsers -join ', ')" "INFO"
} catch {
    Write-LogEntry "Error checking privilege escalation: $_" "ERROR"
}

# Monitor for abnormal network connections
Write-LogEntry "Checking for unusual network connections" "CHECK"
try {
    $suspiciousPorts = @(22, 23, 445, 1433, 3306, 3389, 4444, 5900, 8080)
    $connections = Get-NetTCPConnection -State Established | 
                   Where-Object { $_.RemotePort -in $suspiciousPorts -or $_.LocalPort -in $suspiciousPorts }
    
    if ($connections -and $connections.Count -gt 0) {
        Write-LogEntry "Found $($connections.Count) suspicious network connections" "ALERT"
        
        foreach ($connection in $connections) {
            $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
            $processName = if ($process) { $process.Name } else { "Unknown" }
            
            Write-LogEntry "Connection: $($connection.LocalAddress):$($connection.LocalPort) -> $($connection.RemoteAddress):$($connection.RemotePort) ($processName)" "ALERT"
        }
    } else {
        Write-LogEntry "No suspicious network connections detected" "OK"
    }
} catch {
    Write-LogEntry "Error checking network connections: $_" "ERROR"
}

# Monitor for critical system events
Write-LogEntry "Checking for critical system events in the past 24 hours" "CHECK"
try {
    $criticalEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Level = 1, 2
        StartTime = (Get-Date).AddDays(-1)
    } -ErrorAction SilentlyContinue
    
    if ($criticalEvents -and $criticalEvents.Count -gt 0) {
        Write-LogEntry "Found $($criticalEvents.Count) critical system events" "ALERT"
        
        $criticalEvents | ForEach-Object {
            Write-LogEntry "Critical event: $($_.Id) - $($_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)))..." "ALERT"
        }
    } else {
        Write-LogEntry "No critical system events detected" "OK"
    }
} catch {
    Write-LogEntry "Error checking critical events: $_" "ERROR"
}

# Monitor for scheduled task changes
Write-LogEntry "Checking for scheduled task changes" "CHECK"
try {
    $taskEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-TaskScheduler/Operational'
        ID = 106, 140, 141
        StartTime = (Get-Date).AddDays(-1)
    } -ErrorAction SilentlyContinue
    
    if ($taskEvents -and $taskEvents.Count -gt 0) {
        Write-LogEntry "Found $($taskEvents.Count) scheduled task changes" "ALERT"
        
        $taskEvents | ForEach-Object {
            $taskPath = $_.Properties[0].Value
            Write-LogEntry "Task modified: $taskPath" "ALERT"
        }
    } else {
        Write-LogEntry "No scheduled task changes detected" "OK"
    }
} catch {
    Write-LogEntry "Error checking scheduled task changes: $_" "ERROR"
}

# Monitoring complete
Write-LogEntry "Security monitoring scan completed"
Stop-Transcript
'@
Set-Content -Path $monitoringScriptPath -Value $monitoringScript
Write-ColorOutput "  • Created security monitoring script: $monitoringScriptPath" "Green"

# 5.2 Create scheduled task for the monitoring script
Write-ColorOutput "  • Setting up scheduled task for daily security monitoring..." "White"
try {
    $taskName = "DailySecurityMonitoring"
    $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($taskExists) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$monitoringScriptPath`""
    $trigger = New-ScheduledTaskTrigger -Daily -At 8am
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings
    Write-ColorOutput "    ✓ Daily security monitoring scheduled task created" "Green"
} catch {
    Write-ColorOutput "    ✗ Failed to create scheduled task: $_" "Red"
}

# 5.3 Create a security baseline report
Write-ColorOutput "  • Creating security baseline report..." "White"
$baselineReportPath = "$outputDir\Current_Security_Baseline.html"
$systemInfo = Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer
$securitySettings = @{
    "Windows Update" = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ErrorAction SilentlyContinue).AUOptions
    "UAC Enabled" = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ErrorAction SilentlyContinue).EnableLUA
    "Firewall Enabled" = (Get-NetFirewallProfile -Profile Domain, Public, Private | Select-Object -ExpandProperty Enabled) -contains $true
    "Windows Defender Enabled" = -not (Get-MpPreference).DisableRealtimeMonitoring
    "SMB Signing" = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -ErrorAction SilentlyContinue).RequireSecuritySignature
}

$htmlReport = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Baseline Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #0066cc; }
        h2 { color: #0099ff; margin-top: 30px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        .good { color: green; font-weight: bold; }
        .bad { color: red; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Security Baseline Report</h1>
    <p>Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm")</p>
    
    <h2>System Information</h2>
    <table>
        <tr>
            <th>Property</th>
            <th>Value</th>
        </tr>
        <tr>
            <td>OS Name</td>
            <td>$($systemInfo.WindowsProductName)</td>
        </tr>
        <tr>
            <td>OS Version</td>
            <td>$($systemInfo.WindowsVersion)</td>
        </tr>
        <tr>
            <td>Hardware Abstraction Layer</td>
            <td>$($systemInfo.OsHardwareAbstractionLayer)</td>
        </tr>
    </table>
    
    <h2>Security Settings</h2>
    <table>
        <tr>
            <th>Setting</th>
            <th>Status</th>
            <th>Recommendation</th>
        </tr>
"@

foreach ($setting in $securitySettings.Keys) {
    $value = $securitySettings[$setting]
    $status = if ($null -eq $value) { "Not configured" } elseif ($value -eq 0) { "Disabled" } elseif ($value -eq 1) { "Enabled" } else { $value }
    $cssClass = if ($null -eq $value -or $value -eq 0) { "bad" } else { "good" }
    $recommendation = if ($null -eq $value -or $value -eq 0) { "Configure this setting" } else { "Properly configured" }
    
    $htmlReport += @"
        <tr>
            <td>$setting</td>
            <td class="$cssClass">$status</td>
            <td>$recommendation</td>
        </tr>
"@
}

$htmlReport += @"
    </table>
    
    <h2>Security Recommendations</h2>
    <ul>
        <li>Enable and configure automatic Windows updates</li>
        <li>Ensure antivirus definitions are up-to-date</li>
        <li>Use a password manager and unique passwords for each service</li>
        <li>Enable multi-factor authentication where available</li>
        <li>Encrypt sensitive data and communications</li>
        <li>Regularly back up critical data using the 3-2-1 rule</li>
        <li>Keep all software and operating systems patched and updated</li>
        <li>Implement the principle of least privilege for user accounts</li>
        <li>Use network segmentation to isolate critical systems</li>
        <li>Conduct regular security awareness training for all users</li>
    </ul>
</body>
</html>
"@

Set-Content -Path $baselineReportPath -Value $htmlReport
Write-ColorOutput "    ✓ Security baseline report created: $baselineReportPath" "Green"
#endregion

#region 6. Create Incident Response Plan
Write-ColorOutput "`n[6/7] Creating Incident Response Plan..." "Yellow"

$irpPath = "$outputDir\Incident_Response_Plan.md"
$irp = @"
# Incident Response Plan

## 1. Preparation

### 1.1 Security Tools Inventory
- Wazuh SIEM for monitoring and detection
- ClamAV for antivirus scanning
- OSQuery for endpoint visibility
- Wireshark for network analysis
- Memory forensics tools (Volatility, etc.)
- Log analysis tools
- Disk imaging tools

### 1.2 Contact Information
- IT Security Team: [EMAIL/PHONE]
- System Administrators: [EMAIL/PHONE]
- Management: [EMAIL/PHONE]
- Legal Counsel: [EMAIL/PHONE]
- Law Enforcement Contact: [EMAIL/PHONE]

## 2. Detection and Analysis

### 2.1 Initial Detection
- Monitor security alerts from detection systems
- Watch for unusual user behavior
- Check for unauthorized access attempts
- Monitor system and application logs

### 2.2 Initial Assessment
- Determine the type of incident (malware, breach, etc.)
- Assess the scope and impact
- Identify affected systems
- Document initial findings

### 2.3 Investigation
- Collect and preserve evidence
- Analyze logs and network traffic
- Perform memory forensics if needed
- Identify the attack vector and timeline

## 3. Containment

### 3.1 Short-term Containment
- Isolate affected systems from the network
- Block malicious IP addresses or domains
- Disable compromised accounts
- Stop affected services

### 3.2 Long-term Containment
- Patch vulnerabilities
- Update firewall rules
- Enhance monitoring on similar systems
- Review and update access controls

## 4. Eradication

### 4.1 Remove Malware
- Scan all systems with updated security tools
- Remove identified malware and backdoors
- Delete suspicious files or accounts
- Verify clean state with multiple tools

### 4.2 Mitigate Vulnerabilities
- Apply necessary patches and updates
- Reconfigure vulnerable services
- Implement additional security controls
- Review and update security policies

## 5. Recovery

### 5.1 Restore Systems
- Restore from clean backups if available
- Rebuild systems from scratch if necessary
- Verify system integrity
- Implement additional security measures

### 5.2 Validation
- Test system functionality
- Verify security controls
- Monitor for signs of persistent threats
- Conduct vulnerability scans

### 5.3 Return to Operation
- Gradually restore services
- Closely monitor restored systems
- Implement additional logging
- Update disaster recovery plans

## 6. Lessons Learned

### 6.1 Documentation
- Document the entire incident
- Record timeline of events
- Document response actions taken
- Note lessons learned

### 6.2 Analysis
- Root cause analysis
- Effectiveness of response
- Gaps in security controls
- Recommendations for improvement

### 6.3 Updates
- Update security policies
- Enhance detection capabilities
- Improve response procedures
- Conduct additional training

## 7. Specific Response Procedures

### 7.1 Malware Outbreak
1. Disconnect infected systems from network
2. Identify malware type and behavior
3. Update antivirus definitions
4. Scan all systems
5. Remove identified threats
6. Verify systems are clean
7. Restore from backups if necessary

### 7.2 Data Breach
1. Identify compromised data
2. Determine breach scope and timeline
3. Close the breach point
4. Preserve evidence for investigation
5. Notify affected parties and authorities
6. Implement additional monitoring
7. Review and enhance security controls

### 7.3 Email Security Incident
1. Identify affected accounts
2. Reset passwords immediately
3. Enable MFA if not already enabled
4. Check for unauthorized mail rules or forwarding
5. Review email logs for unauthorized access
6. Check for data exfiltration
7. Enhance email security controls

### 7.4 Ransomware Attack
1. Immediately isolate affected systems
2. Disable network shares
3. Determine ransomware variant
4. Check for lateral movement
5. Assess backup integrity
6. Develop recovery strategy
7. Rebuild systems and restore from backups
8. Report to authorities
"@

Set-Content -Path $irpPath -Value $irp
Write-ColorOutput "  • Incident Response Plan created: $irpPath" "Green"
#endregion

#region 7. Backup Strategy Implementation
Write-ColorOutput "`n[7/7] Implementing Backup Strategy..." "Yellow"

# 7.1 Create backup strategy document
$backupStrategyPath = "$outputDir\Backup_Strategy.md"
$backupStrategy = @"
# 3-2-1 Backup Strategy Implementation

## The 3-2-1 Backup Rule
- **3** copies of important data
- Stored on **2** different media types
- With **1** copy stored offsite

## Backup Types and Schedule

| Type | Schedule | Retention | Tool |
|------|----------|-----------|------|
| Full Backup | Weekly (Sunday) | 4 weeks | UrBackup/Duplicati |
| Incremental Backup | Daily | 14 days | UrBackup/Duplicati |
| Continuous Data Protection | Real-time | 7 days | Kopia |

## Critical Systems and Data

### Priority 1 (Mission Critical)
- Email servers and databases
- Financial systems
- Customer databases
- Authentication systems
- Core business applications

### Priority 2 (Business Critical)
- File servers
- Internal web applications
- Department-specific applications
- Historical records

### Priority 3 (Important)
- Development environments
- Test systems
- Reference materials
- Archives

## Backup Verification Procedures
1. Weekly automated restoration testing
2. Monthly manual verification of random files
3. Quarterly full disaster recovery test
4. Test backup integrity with checksum validation

## Disaster Recovery Process
1. Assess the scope and impact of the data loss
2. Identify the most recent clean backup
3. Prepare recovery environment
4. Restore data according to priority levels
5. Verify data integrity post-restoration
6. Document the recovery process

## Backup Media Security
- Encrypt all backup data (AES-256)
- Store offline media in fireproof safe
- Rotate offsite backups weekly
- Use write-once media for archival backups
- Implement strict access controls

## FOSS Backup Tools

### UrBackup
- Client-server backup system
- Supports full and incremental backups
- File and image-based backups
- Web-based administration

### Duplicati
- Open source backup client
- Strong encryption (AES-256)
- Supports many storage providers
- Incremental backup capabilities

### Kopia
- Fast snapshot-based backups
- Content-defined chunking
- End-to-end encryption
- Cross-platform support

## Implementation Checklist
- [ ] Deploy backup software to all endpoints
- [ ] Configure backup schedules based on priority
- [ ] Set up backup verification processes
- [ ] Test restoration procedures
- [ ] Document backup configurations
- [ ] Train IT staff on recovery procedures
- [ ] Establish offsite backup rotation
- [ ] Implement backup monitoring and alerting
"@

Set-Content -Path $backupStrategyPath -Value $backupStrategy
Write-ColorOutput "  • Backup Strategy document created: $backupStrategyPath" "Green"
#endregion

# Create master checklist of all security preparations
$masterChecklistPath = "$outputDir\Master_Security_Preparation_Checklist.md"
$masterChecklist = @"
# Master Security Preparation Checklist

## System Hardening
- [ ] Windows Firewall enabled on all profiles
- [ ] Windows Defender real-time protection enabled
- [ ] UAC set to maximum level
- [ ] SMB signing enabled
- [ ] Unnecessary services disabled
- [ ] PowerShell script block logging enabled

## Email Security
- [ ] SPF, DKIM, and DMARC implemented
- [ ] MFA enabled on all accounts
- [ ] Strong password policies enforced
- [ ] Advanced spam filtering deployed
- [ ] Mail forwarding to external domains restricted
- [ ] Mailbox audit logging enabled

## Network Security
- [ ] High-risk ports blocked
- [ ] Internal DNS servers configured
- [ ] Network traffic monitoring implemented
- [ ] Regular network vulnerability scanning
- [ ] Network segmentation implemented
- [ ] Secure remote access solutions in place

## Endpoint Detection & Response
- [ ] Sysmon deployed for advanced event monitoring
- [ ] Enhanced Windows event logging enabled
- [ ] Regular security baseline checks scheduled
- [ ] Endpoint protection solution deployed
- [ ] Application whitelisting configured
- [ ] USB device controls implemented

## Security Monitoring
- [ ] Daily security monitoring script deployed
- [ ] Centralized log collection implemented
- [ ] Security alerts configured
- [ ] Regular review of security reports
- [ ] Suspicious activity detection rules created
- [ ] Security monitoring dashboard available

## Incident Response
- [ ] Incident Response Plan documented
- [ ] Response team roles assigned
- [ ] Communication procedures established
- [ ] Recovery procedures documented
- [ ] Regular tabletop exercises conducted
- [ ] Post-incident review process defined

## Backup & Recovery
- [ ] 3-2-1 backup strategy implemented
- [ ] Critical systems identified and prioritized
- [ ] Regular backup testing performed
- [ ] Offsite backup rotation established
- [ ] Backup encryption enforced
- [ ] Disaster recovery procedures documented

## User Security Training
- [ ] Phishing awareness training conducted
- [ ] Security best practices documented
- [ ] Password management training provided
- [ ] Incident reporting procedures communicated
- [ ] Social engineering awareness sessions held
- [ ] Regular security updates shared with users
"@

Set-Content -Path $masterChecklistPath -Value $masterChecklist
Write-ColorOutput "`nMaster Security Preparation Checklist created: $masterChecklistPath" "Green"

Write-ColorOutput "`n===================================================" "Cyan"
Write-ColorOutput "   FUTURE ATTACK PREPARATION TOOLKIT COMPLETED" "Cyan"
Write-ColorOutput "===================================================" "Cyan"
Write-ColorOutput "`nAll security preparation tools and documents have been created in:" "Yellow"
Write-ColorOutput $outputDir "Yellow"
Write-ColorOutput "`nNext Steps:" "Cyan"
Write-ColorOutput "1. Review and complete all items in the Master Security Preparation Checklist" "White"
Write-ColorOutput "2. Set up scheduled tasks for the security monitoring script" "White"
Write-ColorOutput "3. Distribute the Incident Response Plan to relevant team members" "White"
Write-ColorOutput "4. Implement the backup strategy" "White"
Write-ColorOutput "5. Conduct regular security drills and tabletop exercises" "White"
Write-ColorOutput "`nFor ongoing protection:" "Cyan"
Write-ColorOutput "- Run the security baseline script weekly" "White"
Write-ColorOutput "- Review security monitoring logs daily" "White"
Write-ColorOutput "- Verify backups monthly" "White"
Write-ColorOutput "- Update security tools and this toolkit quarterly" "White"

Stop-Transcript
