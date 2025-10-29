# Audit-All-Users-Security.ps1
# Comprehensive security audit for ALL users under administrative control
# Checks for email compromise across entire organization

param(
    [string]$Domain = "ibridge.co.za",
    [switch]$RemoveThreats = $false,
    [switch]$GenerateReport = $true,
    [string]$OutputPath = "C:\SecurityAudit"
)

# Check for administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator!"
    exit 1
}

Write-Host "=== COMPREHENSIVE SECURITY AUDIT FOR ALL USERS ===" -ForegroundColor Red
Write-Host "Domain: @$Domain" -ForegroundColor Yellow
Write-Host "Scope: ALL users under administrative control" -ForegroundColor Yellow

# Create output directory
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = "$OutputPath\SecurityAudit_AllUsers_$timestamp.html"
$csvFile = "$OutputPath\SecurityFindings_AllUsers_$timestamp.csv"

# Initialize findings array
$allFindings = @()
$userStats = @{
    TotalUsers = 0
    CompromisedUsers = 0
    SuspiciousRules = 0
    ExternalDelegates = 0
    MaliciousForwarding = 0
    WeakPasswords = 0
}

function Write-Log {
    param($Message, $Level = "INFO")
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $(switch($Level) { "ERROR" {"Red"} "WARNING" {"Yellow"} "SUCCESS" {"Green"} default {"White"} })
    $logMessage | Out-File -FilePath "$OutputPath\audit_log.txt" -Append
}

function Test-ExchangeConnection {
    try {
        # Try Exchange Online PowerShell first
        Import-Module ExchangeOnlineManagement -ErrorAction Stop
        Connect-ExchangeOnline -ShowProgress $false -ErrorAction Stop
        Write-Log "Connected to Exchange Online" "SUCCESS"
        return "ExchangeOnline"
    } catch {
        try {
            # Try on-premises Exchange
            $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$env:COMPUTERNAME/PowerShell/" -Authentication Kerberos -ErrorAction Stop
            Import-PSSession $Session -DisableNameChecking -ErrorAction Stop
            Write-Log "Connected to on-premises Exchange" "SUCCESS"
            return "OnPremises"
        } catch {
            Write-Log "Cannot connect to Exchange. Trying local AD..." "WARNING"
            return "LocalAD"
        }
    }
}

function Get-AllUsers {
    param($ConnectionType)
    
    Write-Log "Discovering all users..."
    
    switch ($ConnectionType) {
        "ExchangeOnline" {
            try {
                $users = Get-Mailbox -Filter "EmailAddresses -like '*@$Domain'" -ResultSize Unlimited
                Write-Log "Found $($users.Count) mailboxes in Exchange Online" "SUCCESS"
                return $users
            } catch {
                Write-Log "Failed to get Exchange Online users: $_" "ERROR"
                return @()
            }
        }
        "OnPremises" {
            try {
                $users = Get-Mailbox -Filter "EmailAddresses -like '*@$Domain'" -ResultSize Unlimited
                Write-Log "Found $($users.Count) mailboxes in on-premises Exchange" "SUCCESS"
                return $users
            } catch {
                Write-Log "Failed to get on-premises Exchange users: $_" "ERROR"
                return @()
            }
        }
        "LocalAD" {
            try {
                Import-Module ActiveDirectory -ErrorAction Stop
                $users = Get-ADUser -Filter "EmailAddress -like '*@$Domain'" -Properties EmailAddress, LastLogonDate, PasswordLastSet, Enabled
                Write-Log "Found $($users.Count) users in Active Directory" "SUCCESS"
                return $users
            } catch {
                Write-Log "Failed to get AD users: $_" "ERROR"
                # Fallback to local users
                $users = Get-LocalUser | Where-Object { $_.Enabled -eq $true }
                Write-Log "Found $($users.Count) local users" "WARNING"
                return $users
            }
        }
    }
}

function Audit-UserSecurity {
    param($User, $ConnectionType)
    
    $userFindings = @()
    $userEmail = ""
    
    switch ($ConnectionType) {
        "ExchangeOnline" {
            $userEmail = $User.PrimarySmtpAddress
        }
        "OnPremises" {
            $userEmail = $User.PrimarySmtpAddress
        }
        "LocalAD" {
            $userEmail = $User.EmailAddress
        }
        default {
            $userEmail = $User.Name
        }
    }
    
    Write-Log "Auditing user: $userEmail"
    
    # Check inbox rules (if Exchange connection available)
    if ($ConnectionType -in @("ExchangeOnline", "OnPremises")) {
        try {
            $inboxRules = Get-InboxRule -Mailbox $userEmail -ErrorAction SilentlyContinue
            
            foreach ($rule in $inboxRules) {
                $suspicious = $false
                $reasons = @()
                
                # Check for external forwarding
                if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo -or $rule.RedirectTo) {
                    $forwardAddresses = @()
                    if ($rule.ForwardTo) { $forwardAddresses += $rule.ForwardTo }
                    if ($rule.ForwardAsAttachmentTo) { $forwardAddresses += $rule.ForwardAsAttachmentTo }
                    if ($rule.RedirectTo) { $forwardAddresses += $rule.RedirectTo }
                    
                    foreach ($address in $forwardAddresses) {
                        if ($address -notlike "*@$Domain") {
                            $suspicious = $true
                            $reasons += "External forwarding to: $address"
                            $userStats.MaliciousForwarding++
                        }
                    }
                }
                
                # Check for auto-delete rules
                if ($rule.DeleteMessage -eq $true) {
                    $suspicious = $true
                    $reasons += "Auto-delete rule"
                }
                
                # Check for suspicious keywords
                $suspiciousKeywords = @("invoice", "payment", "urgent", "confidential", "bank", "security")
                foreach ($keyword in $suspiciousKeywords) {
                    if ($rule.SubjectContainsWords -like "*$keyword*" -or $rule.BodyContainsWords -like "*$keyword*") {
                        $suspicious = $true
                        $reasons += "Targets $keyword emails"
                    }
                }
                
                if ($suspicious) {
                    $userStats.SuspiciousRules++
                    $finding = [PSCustomObject]@{
                        User = $userEmail
                        FindingType = "Suspicious Email Rule"
                        RuleName = $rule.Name
                        Severity = "HIGH"
                        Details = $reasons -join "; "
                        Action = if($RemoveThreats) {"REMOVED"} else {"DETECTED"}
                        Timestamp = Get-Date
                    }
                    $userFindings += $finding
                    
                    if ($RemoveThreats) {
                        try {
                            Remove-InboxRule -Identity $rule.Identity -Confirm:$false
                            Write-Log "Removed suspicious rule: $($rule.Name) for $userEmail" "SUCCESS"
                        } catch {
                            Write-Log "Failed to remove rule: $($rule.Name) for $userEmail" "ERROR"
                        }
                    }
                }
            }
            
            # Check mailbox permissions
            $permissions = Get-MailboxPermission -Identity $userEmail -ErrorAction SilentlyContinue | Where-Object { 
                $_.User -ne "NT AUTHORITY\SELF" -and 
                $_.User -notlike "*@$Domain" -and
                $_.AccessRights -contains "FullAccess"
            }
            
            foreach ($perm in $permissions) {
                $userStats.ExternalDelegates++
                $finding = [PSCustomObject]@{
                    User = $userEmail
                    FindingType = "External Delegate"
                    RuleName = "FullAccess Permission"
                    Severity = "CRITICAL"
                    Details = "External user $($perm.User) has FullAccess"
                    Action = if($RemoveThreats) {"REMOVED"} else {"DETECTED"}
                    Timestamp = Get-Date
                }
                $userFindings += $finding
                
                if ($RemoveThreats) {
                    try {
                        Remove-MailboxPermission -Identity $userEmail -User $perm.User -AccessRights FullAccess -Confirm:$false
                        Write-Log "Removed external delegate: $($perm.User) from $userEmail" "SUCCESS"
                    } catch {
                        Write-Log "Failed to remove delegate: $($perm.User) from $userEmail" "ERROR"
                    }
                }
            }
            
        } catch {
            Write-Log "Could not audit Exchange settings for $userEmail`: $_" "WARNING"
        }
    }
    
    # Check for weak passwords (AD only)
    if ($ConnectionType -eq "LocalAD" -and $User.PasswordLastSet) {
        $passwordAge = (Get-Date) - $User.PasswordLastSet
        if ($passwordAge.Days -gt 90) {
            $userStats.WeakPasswords++
            $finding = [PSCustomObject]@{
                User = $userEmail
                FindingType = "Weak Password Policy"
                RuleName = "Password Age"
                Severity = "MEDIUM"
                Details = "Password not changed in $($passwordAge.Days) days"
                Action = "MANUAL_ACTION_REQUIRED"
                Timestamp = Get-Date
            }
            $userFindings += $finding
        }
    }
    
    # Check for recent suspicious logins (if possible)
    try {
        if ($ConnectionType -in @("ExchangeOnline", "OnPremises")) {
            # This would require additional permissions and might not work in all environments
            # $auditLogs = Search-UnifiedAuditLog -UserIds $userEmail -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) -Operations UserLoggedIn -ErrorAction SilentlyContinue
        }
    } catch {
        # Silently continue if audit logs are not accessible
    }
    
    if ($userFindings.Count -gt 0) {
        $userStats.CompromisedUsers++
        Write-Log "Found $($userFindings.Count) security issues for $userEmail" "WARNING"
    }
    
    return $userFindings
}

function Generate-Report {
    param($AllFindings)
    
    if ($GenerateReport) {
        Write-Log "Generating comprehensive security report..."
        
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Security Audit Report - $Domain</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #d32f2f; color: white; padding: 20px; text-align: center; }
        .stats { display: flex; justify-content: space-around; margin: 20px 0; }
        .stat-box { background-color: #f5f5f5; padding: 15px; border-radius: 5px; text-align: center; }
        .critical { background-color: #ffebee; border-left: 5px solid #d32f2f; }
        .high { background-color: #fff3e0; border-left: 5px solid #f57c00; }
        .medium { background-color: #f3e5f5; border-left: 5px solid #7b1fa2; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .severity-critical { color: #d32f2f; font-weight: bold; }
        .severity-high { color: #f57c00; font-weight: bold; }
        .severity-medium { color: #7b1fa2; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>SECURITY AUDIT REPORT</h1>
        <h2>Domain: @$Domain</h2>
        <p>Generated: $(Get-Date)</p>
    </div>
    
    <div class="stats">
        <div class="stat-box">
            <h3>$($userStats.TotalUsers)</h3>
            <p>Total Users Audited</p>
        </div>
        <div class="stat-box">
            <h3>$($userStats.CompromisedUsers)</h3>
            <p>Users with Issues</p>
        </div>
        <div class="stat-box">
            <h3>$($userStats.SuspiciousRules)</h3>
            <p>Suspicious Rules</p>
        </div>
        <div class="stat-box">
            <h3>$($userStats.ExternalDelegates)</h3>
            <p>External Delegates</p>
        </div>
    </div>
    
    <h2>Security Findings</h2>
    <table>
        <tr>
            <th>User</th>
            <th>Finding Type</th>
            <th>Severity</th>
            <th>Details</th>
            <th>Action</th>
            <th>Timestamp</th>
        </tr>
"@
        
        foreach ($finding in $AllFindings) {
            $severityClass = "severity-" + $finding.Severity.ToLower()
            $html += @"
        <tr>
            <td>$($finding.User)</td>
            <td>$($finding.FindingType)</td>
            <td class="$severityClass">$($finding.Severity)</td>
            <td>$($finding.Details)</td>
            <td>$($finding.Action)</td>
            <td>$($finding.Timestamp)</td>
        </tr>
"@
        }
        
        $html += @"
    </table>
    
    <h2>Recommended Actions</h2>
    <div class="critical">
        <h3>IMMEDIATE ACTIONS</h3>
        <ul>
            <li>Force password reset for all compromised users</li>
            <li>Enable MFA on all accounts</li>
            <li>Remove all unauthorized delegates and rules</li>
            <li>Review audit logs for the past 30 days</li>
        </ul>
    </div>
    
    <div class="high">
        <h3>SHORT-TERM ACTIONS</h3>
        <ul>
            <li>Implement email security policies</li>
            <li>Deploy advanced threat protection</li>
            <li>Conduct security awareness training</li>
            <li>Review and update incident response procedures</li>
        </ul>
    </div>
    
    <div class="medium">
        <h3>LONG-TERM ACTIONS</h3>
        <ul>
            <li>Regular security audits (monthly)</li>
            <li>Implement zero-trust architecture</li>
            <li>Deploy endpoint detection and response (EDR)</li>
            <li>Enhance monitoring and alerting</li>
        </ul>
    </div>
</body>
</html>
"@
        
        $html | Out-File -FilePath $reportFile -Encoding UTF8
        Write-Log "HTML report saved to: $reportFile" "SUCCESS"
        
        # Also save CSV for further analysis
        $AllFindings | Export-Csv -Path $csvFile -NoTypeInformation
        Write-Log "CSV data saved to: $csvFile" "SUCCESS"
    }
}

# Main execution
try {
    Write-Log "Starting comprehensive security audit..."
    
    # Test connection to Exchange/AD
    $connectionType = Test-ExchangeConnection
    
    # Get all users
    $allUsers = Get-AllUsers $connectionType
    $userStats.TotalUsers = $allUsers.Count
    
    if ($allUsers.Count -eq 0) {
        Write-Log "No users found to audit!" "ERROR"
        exit 1
    }
    
    Write-Log "Auditing $($allUsers.Count) users..." "INFO"
    
    # Audit each user
    $progressCount = 0
    foreach ($user in $allUsers) {
        $progressCount++
        Write-Progress -Activity "Auditing Users" -Status "Processing user $progressCount of $($allUsers.Count)" -PercentComplete (($progressCount / $allUsers.Count) * 100)
        
        $userFindings = Audit-UserSecurity $user $connectionType
        $allFindings += $userFindings
    }
    
    Write-Progress -Completed -Activity "Auditing Users"
    
    # Generate report
    Generate-Report $allFindings
    
    # Summary
    Write-Log "=== AUDIT COMPLETE ===" "SUCCESS"
    Write-Log "Total users audited: $($userStats.TotalUsers)" "INFO"
    Write-Log "Users with security issues: $($userStats.CompromisedUsers)" "WARNING"
    Write-Log "Suspicious email rules found: $($userStats.SuspiciousRules)" "WARNING"
    Write-Log "External delegates found: $($userStats.ExternalDelegates)" "WARNING"
    Write-Log "Malicious forwarding rules: $($userStats.MaliciousForwarding)" "WARNING"
    
    if ($allFindings.Count -gt 0) {
        Write-Log "CRITICAL: Security issues detected across the organization!" "ERROR"
        Write-Log "Review the generated reports immediately." "ERROR"
        
        if ($RemoveThreats) {
            Write-Log "Threat removal was enabled - malicious rules and delegates have been removed." "SUCCESS"
        } else {
            Write-Log "To automatically remove threats, run with -RemoveThreats parameter." "WARNING"
        }
    } else {
        Write-Log "No security issues detected." "SUCCESS"
    }
    
    # Open the report
    if (Test-Path $reportFile) {
        Start-Process $reportFile
    }
    
} catch {
    Write-Log "Critical error during audit: $_" "ERROR"
} finally {
    # Clean up connections
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    } catch {}
    
    Write-Log "Audit completed. Check the output directory: $OutputPath" "INFO"
}
