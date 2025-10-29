<#
.SYNOPSIS
    Comprehensive Security Monitoring and Event Analysis Script
    
.DESCRIPTION
    Monitors Windows security events in real-time and generates alerts for suspicious activities.
    Provides detailed analysis of authentication failures, privilege escalation, and system changes.
    
.PARAMETER Hours
    Number of hours to look back for events (default: 24)
    
.PARAMETER RealTime
    Enable real-time monitoring mode
    
.PARAMETER AlertThreshold
    Number of failed logons before generating alert (default: 5)
    
.PARAMETER OutputPath
    Path to save monitoring results and alerts
    
.EXAMPLE
    .\Monitor-SecurityEvents.ps1 -Hours 24 -AlertThreshold 3 -OutputPath "C:\SecurityMonitoring\"
    
.EXAMPLE
    .\Monitor-SecurityEvents.ps1 -RealTime -AlertThreshold 5
    
.NOTES
    Author: Security Team
    Version: 1.0
    Requires: Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [int]$Hours = 24,
    
    [Parameter(Mandatory=$false)]
    [switch]$RealTime,
    
    [Parameter(Mandatory=$false)]
    [int]$AlertThreshold = 5,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "C:\SecurityMonitoring"
)

# Initialize monitoring environment
function Initialize-SecurityMonitoring {
    param([string]$OutputPath)
    
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Host "Created monitoring directory: $OutputPath" -ForegroundColor Green
    }
    
    $script:LogFile = Join-Path $OutputPath "SecurityMonitoring-$(Get-Date -Format 'yyyyMMdd').log"
    $script:AlertFile = Join-Path $OutputPath "SecurityAlerts-$(Get-Date -Format 'yyyyMMdd').txt"
    $script:ReportFile = Join-Path $OutputPath "SecurityReport-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
    
    # Create monitoring log header
    $header = @"
=== Security Monitoring Session Started ===
Timestamp: $(Get-Date)
Monitoring Period: $Hours hours
Alert Threshold: $AlertThreshold failed logons
Real-time Mode: $RealTime
Output Directory: $OutputPath
============================================

"@
    
    Add-Content -Path $script:LogFile -Value $header
}

function Write-SecurityLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "ALERT", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Color coding for console output
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "ALERT" { "Magenta" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    Add-Content -Path $script:LogFile -Value $logEntry
    
    # Write alerts to separate file
    if ($Level -eq "ALERT") {
        Add-Content -Path $script:AlertFile -Value $logEntry
    }
}

function Get-SecurityEvents {
    param([int]$Hours)
    
    Write-SecurityLog "Collecting security events from the last $Hours hours..."
    
    $startTime = (Get-Date).AddHours(-$Hours)
    
    # Define critical security event IDs to monitor
    $criticalEvents = @{
        4625 = "Failed Logon"
        4624 = "Successful Logon"
        4648 = "Logon with Explicit Credentials"
        4720 = "User Account Created"
        4726 = "User Account Deleted"
        4728 = "User Added to Security Group"
        4732 = "User Added to Local Group"
        4756 = "User Added to Universal Group"
        4672 = "Special Privileges Assigned"
        4768 = "Kerberos Authentication Ticket Requested"
        4769 = "Kerberos Service Ticket Requested"
        4776 = "Domain Controller Authentication"
        5152 = "Windows Filtering Platform Blocked"
        5156 = "Windows Filtering Platform Allowed"
        1102 = "Audit Log Cleared"
        4719 = "System Audit Policy Changed"
        4657 = "Registry Value Modified"
        4698 = "Scheduled Task Created"
        4702 = "Scheduled Task Updated"
        7045 = "Service Installed"
        4104 = "PowerShell Script Block"
        4103 = "PowerShell Module Logging"
    }
    
    $allEvents = @()
    
    foreach ($eventId in $criticalEvents.Keys) {
        try {
            $events = Get-WinEvent -FilterHashtable @{
                LogName = 'Security', 'System', 'Microsoft-Windows-PowerShell/Operational'
                ID = $eventId
                StartTime = $startTime
            } -ErrorAction SilentlyContinue
            
            if ($events) {
                $allEvents += $events | Select-Object TimeCreated, Id, LevelDisplayName, Message, @{
                    Name = 'EventDescription'
                    Expression = { $criticalEvents[$_.Id] }
                }
                Write-SecurityLog "Found $($events.Count) events for ID $eventId ($($criticalEvents[$eventId]))"
            }
        } catch {
            Write-SecurityLog "Failed to query event ID $eventId`: $($_.Exception.Message)" "WARNING"
        }
    }
    
    return $allEvents | Sort-Object TimeCreated -Descending
}

function Analyze-FailedLogons {
    param([array]$SecurityEvents, [int]$AlertThreshold)
    
    Write-SecurityLog "Analyzing failed logon attempts..."
    
    $failedLogons = $SecurityEvents | Where-Object { $_.Id -eq 4625 }
    
    if ($failedLogons.Count -eq 0) {
        Write-SecurityLog "No failed logon attempts found" "SUCCESS"
        return
    }
    
    # Group failed logons by user account and source IP
    $logonAnalysis = $failedLogons | ForEach-Object {
        $message = $_.Message
        
        # Extract username and source IP from event message
        $username = if ($message -match "Account Name:\s+([^\s]+)") { $matches[1] } else { "Unknown" }
        $sourceIP = if ($message -match "Source Network Address:\s+([^\s]+)") { $matches[1] } else { "Unknown" }
        $workstation = if ($message -match "Workstation Name:\s+([^\s]+)") { $matches[1] } else { "Unknown" }
        
        [PSCustomObject]@{
            TimeCreated = $_.TimeCreated
            Username = $username
            SourceIP = $sourceIP
            Workstation = $workstation
        }
    }
    
    # Check for brute force attempts
    $userAttempts = $logonAnalysis | Group-Object Username | Where-Object { $_.Count -ge $AlertThreshold }
    $ipAttempts = $logonAnalysis | Group-Object SourceIP | Where-Object { $_.Count -ge $AlertThreshold }
    
    foreach ($attempt in $userAttempts) {
        Write-SecurityLog "BRUTE FORCE ALERT: User '$($attempt.Name)' has $($attempt.Count) failed logon attempts" "ALERT"
    }
    
    foreach ($attempt in $ipAttempts) {
        Write-SecurityLog "BRUTE FORCE ALERT: IP '$($attempt.Name)' has $($attempt.Count) failed logon attempts" "ALERT"
    }
    
    return $logonAnalysis
}

function Analyze-PrivilegeEscalation {
    param([array]$SecurityEvents)
    
    Write-SecurityLog "Analyzing privilege escalation events..."
    
    $privilegeEvents = $SecurityEvents | Where-Object { 
        $_.Id -in @(4672, 4728, 4732, 4756) 
    }
    
    if ($privilegeEvents.Count -eq 0) {
        Write-SecurityLog "No privilege escalation events found"
        return
    }
    
    foreach ($event in $privilegeEvents) {
        $message = $event.Message
        $username = if ($message -match "Subject.*Account Name:\s+([^\s]+)") { $matches[1] } else { "Unknown" }
        $targetUser = if ($message -match "Target.*Account Name:\s+([^\s]+)") { $matches[1] } else { "Unknown" }
        
        switch ($event.Id) {
            4672 { 
                Write-SecurityLog "Special privileges assigned to user: $username" "WARNING"
            }
            4728 { 
                Write-SecurityLog "User $targetUser added to security group by $username" "WARNING"
            }
            4732 { 
                Write-SecurityLog "User $targetUser added to local group by $username" "WARNING"
            }
            4756 { 
                Write-SecurityLog "User $targetUser added to universal group by $username" "WARNING"
            }
        }
    }
}

function Analyze-SystemChanges {
    param([array]$SecurityEvents)
    
    Write-SecurityLog "Analyzing system configuration changes..."
    
    $systemChanges = $SecurityEvents | Where-Object { 
        $_.Id -in @(4719, 4657, 4698, 4702, 7045, 1102) 
    }
    
    foreach ($event in $systemChanges) {
        switch ($event.Id) {
            4719 { 
                Write-SecurityLog "CRITICAL: System audit policy was changed!" "ALERT"
            }
            4657 { 
                Write-SecurityLog "Registry value was modified" "WARNING"
            }
            4698 { 
                Write-SecurityLog "Scheduled task was created" "WARNING"
            }
            4702 { 
                Write-SecurityLog "Scheduled task was updated" "WARNING"
            }
            7045 { 
                Write-SecurityLog "New service was installed" "WARNING"
            }
            1102 { 
                Write-SecurityLog "CRITICAL: Security audit log was cleared!" "ALERT"
            }
        }
    }
}

function Analyze-PowerShellActivity {
    param([array]$SecurityEvents)
    
    Write-SecurityLog "Analyzing PowerShell activity..."
    
    $powershellEvents = $SecurityEvents | Where-Object { 
        $_.Id -in @(4104, 4103) 
    }
    
    if ($powershellEvents.Count -eq 0) {
        Write-SecurityLog "No PowerShell events found"
        return
    }
    
    # Look for suspicious PowerShell activity
    $suspiciousKeywords = @(
        'Invoke-Expression', 'IEX', 'DownloadString', 'DownloadFile',
        'Invoke-WmiMethod', 'Invoke-Command', 'New-Object System.Net',
        'Start-Process', '-EncodedCommand', '-WindowStyle Hidden',
        'Bypass', 'Unrestricted', 'mimikatz', 'powersploit'
    )
    
    foreach ($event in $powershellEvents) {
        $message = $event.Message
        
        foreach ($keyword in $suspiciousKeywords) {
            if ($message -match $keyword) {
                Write-SecurityLog "SUSPICIOUS POWERSHELL: Detected '$keyword' in PowerShell execution" "ALERT"
                break
            }
        }
    }
    
    Write-SecurityLog "Analyzed $($powershellEvents.Count) PowerShell events"
}

function Analyze-NetworkSecurity {
    param([array]$SecurityEvents)
    
    Write-SecurityLog "Analyzing network security events..."
    
    $networkEvents = $SecurityEvents | Where-Object { 
        $_.Id -in @(5152, 5156) 
    }
    
    if ($networkEvents.Count -eq 0) {
        Write-SecurityLog "No network security events found"
        return
    }
    
    $blockedConnections = $networkEvents | Where-Object { $_.Id -eq 5152 }
    $allowedConnections = $networkEvents | Where-Object { $_.Id -eq 5156 }
    
    Write-SecurityLog "Network connections blocked: $($blockedConnections.Count)"
    Write-SecurityLog "Network connections allowed: $($allowedConnections.Count)"
    
    # Analyze blocked connections for patterns
    if ($blockedConnections.Count -gt 0) {
        $blockedIPs = $blockedConnections | ForEach-Object {
            $message = $_.Message
            if ($message -match "Source Address:\s+([^\s]+)") { $matches[1] }
        } | Group-Object | Sort-Object Count -Descending | Select-Object -First 10
        
        foreach ($ip in $blockedIPs) {
            if ($ip.Count -gt 10) {
                Write-SecurityLog "HIGH ACTIVITY: IP $($ip.Name) blocked $($ip.Count) times" "WARNING"
            }
        }
    }
}

function Generate-SecurityReport {
    param(
        [array]$SecurityEvents,
        [array]$FailedLogons,
        [string]$ReportFile
    )
    
    Write-SecurityLog "Generating comprehensive security report..."
    
    $eventSummary = $SecurityEvents | Group-Object Id | Sort-Object Count -Descending
    $recentAlerts = Get-Content $script:AlertFile -ErrorAction SilentlyContinue | Select-Object -Last 20
    
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Security Monitoring Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .alert { background-color: #ffebee; border-left: 5px solid #f44336; padding: 10px; margin: 10px 0; }
        .warning { background-color: #fff3e0; border-left: 5px solid #ff9800; padding: 10px; margin: 10px 0; }
        .success { background-color: #e8f5e8; border-left: 5px solid #4caf50; padding: 10px; margin: 10px 0; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .chart { width: 100%; height: 300px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Security Monitoring Report</h1>
        <p><strong>Generated:</strong> $(Get-Date)</p>
        <p><strong>Monitoring Period:</strong> Last $Hours hours</p>
        <p><strong>Total Events Analyzed:</strong> $($SecurityEvents.Count)</p>
    </div>

    <h2>Executive Summary</h2>
    <div class="$(if($recentAlerts.Count -gt 0){'alert'}else{'success'})">
        <strong>Security Status:</strong> $(if($recentAlerts.Count -gt 0){"ALERTS DETECTED - Immediate attention required"}else{"NORMAL - No critical alerts"})
    </div>

    <h2>Event Summary</h2>
    <table>
        <tr><th>Event ID</th><th>Description</th><th>Count</th></tr>
"@

    foreach ($event in $eventSummary | Select-Object -First 15) {
        $description = switch ($event.Name) {
            4625 { "Failed Logon" }
            4624 { "Successful Logon" }
            4648 { "Logon with Explicit Credentials" }
            4720 { "User Account Created" }
            4726 { "User Account Deleted" }
            4672 { "Special Privileges Assigned" }
            1102 { "Audit Log Cleared" }
            default { "Security Event" }
        }
        
        $htmlReport += "<tr><td>$($event.Name)</td><td>$description</td><td>$($event.Count)</td></tr>"
    }

    $htmlReport += @"
    </table>

    <h2>Recent Security Alerts</h2>
"@

    if ($recentAlerts.Count -gt 0) {
        foreach ($alert in $recentAlerts) {
            $htmlReport += "<div class='alert'>$([System.Web.HttpUtility]::HtmlEncode($alert))</div>"
        }
    } else {
        $htmlReport += "<div class='success'>No recent security alerts</div>"
    }

    $htmlReport += @"
    <h2>Failed Logon Analysis</h2>
"@

    if ($FailedLogons.Count -gt 0) {
        $htmlReport += "<table><tr><th>Time</th><th>Username</th><th>Source IP</th><th>Workstation</th></tr>"
        
        foreach ($logon in ($FailedLogons | Select-Object -First 20)) {
            $htmlReport += "<tr><td>$($logon.TimeCreated)</td><td>$($logon.Username)</td><td>$($logon.SourceIP)</td><td>$($logon.Workstation)</td></tr>"
        }
        
        $htmlReport += "</table>"
    } else {
        $htmlReport += "<div class='success'>No failed logon attempts detected</div>"
    }

    $htmlReport += @"
    <h2>Recommendations</h2>
    <ul>
        <li>Review all security alerts immediately</li>
        <li>Investigate any failed logon attempts from unknown sources</li>
        <li>Monitor for privilege escalation activities</li>
        <li>Ensure all systems have latest security updates</li>
        <li>Regular review of user accounts and permissions</li>
        <li>Enable additional monitoring for PowerShell activity</li>
    </ul>

    <p><em>Report generated by Security Monitoring Script - $(Get-Date)</em></p>
</body>
</html>
"@

    $htmlReport | Out-File -FilePath $ReportFile -Encoding UTF8
    Write-SecurityLog "Security report saved to: $ReportFile" "SUCCESS"
}

function Start-RealTimeMonitoring {
    param([int]$AlertThreshold)
    
    Write-SecurityLog "Starting real-time security monitoring..." "INFO"
    Write-SecurityLog "Press Ctrl+C to stop monitoring" "INFO"
    
    $lastEventTime = Get-Date
    
    try {
        while ($true) {
            Start-Sleep -Seconds 30  # Check every 30 seconds
            
            # Get new events since last check
            $newEvents = Get-WinEvent -FilterHashtable @{
                LogName = 'Security'
                StartTime = $lastEventTime
            } -ErrorAction SilentlyContinue
            
            if ($newEvents) {
                Write-SecurityLog "Found $($newEvents.Count) new security events"
                
                # Quick analysis of critical events
                $criticalEvents = $newEvents | Where-Object { 
                    $_.Id -in @(4625, 1102, 4719, 4720, 4726) 
                }
                
                foreach ($event in $criticalEvents) {
                    switch ($event.Id) {
                        4625 { Write-SecurityLog "REAL-TIME: Failed logon detected" "WARNING" }
                        1102 { Write-SecurityLog "REAL-TIME ALERT: Security log cleared!" "ALERT" }
                        4719 { Write-SecurityLog "REAL-TIME ALERT: Audit policy changed!" "ALERT" }
                        4720 { Write-SecurityLog "REAL-TIME: User account created" "WARNING" }
                        4726 { Write-SecurityLog "REAL-TIME: User account deleted" "WARNING" }
                    }
                }
                
                $lastEventTime = Get-Date
            }
        }
    } catch [System.Management.Automation.HaltCommandException] {
        Write-SecurityLog "Real-time monitoring stopped by user" "INFO"
    } catch {
        Write-SecurityLog "Real-time monitoring error: $($_.Exception.Message)" "ERROR"
    }
}

# Main execution
try {
    Write-Host "=== Windows Security Event Monitoring ===" -ForegroundColor Cyan
    
    # Check administrator privileges
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Administrator privileges required!" -ForegroundColor Red
        throw "This script must be run as Administrator"
    }
    
    Initialize-SecurityMonitoring -OutputPath $OutputPath
    
    if ($RealTime) {
        Start-RealTimeMonitoring -AlertThreshold $AlertThreshold
    } else {
        # Historical analysis mode
        $securityEvents = Get-SecurityEvents -Hours $Hours
        
        if ($securityEvents.Count -eq 0) {
            Write-SecurityLog "No security events found in the specified time period" "INFO"
            return
        }
        
        Write-SecurityLog "Analyzing $($securityEvents.Count) security events..."
        
        # Perform comprehensive analysis
        $failedLogons = Analyze-FailedLogons -SecurityEvents $securityEvents -AlertThreshold $AlertThreshold
        Analyze-PrivilegeEscalation -SecurityEvents $securityEvents
        Analyze-SystemChanges -SecurityEvents $securityEvents
        Analyze-PowerShellActivity -SecurityEvents $securityEvents
        Analyze-NetworkSecurity -SecurityEvents $securityEvents
        
        # Generate comprehensive report
        Generate-SecurityReport -SecurityEvents $securityEvents -FailedLogons $failedLogons -ReportFile $script:ReportFile
        
        Write-SecurityLog "Security monitoring analysis completed!" "SUCCESS"
        Write-SecurityLog "Results saved to: $OutputPath" "INFO"
        
        # Display summary
        Write-Host "`n=== MONITORING SUMMARY ===" -ForegroundColor Cyan
        Write-Host "Events analyzed: $($securityEvents.Count)" -ForegroundColor Green
        Write-Host "Alerts generated: $(if(Test-Path $script:AlertFile){(Get-Content $script:AlertFile).Count}else{0})" -ForegroundColor Yellow
        Write-Host "Report location: $($script:ReportFile)" -ForegroundColor Green
    }
    
} catch {
    Write-Host "Security monitoring failed: $($_.Exception.Message)" -ForegroundColor Red
    throw
}