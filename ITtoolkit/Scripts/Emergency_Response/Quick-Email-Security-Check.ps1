# Quick-Email-Security-Check.ps1
# Quick security check for @ibridge.co.za accounts

param(
    [string]$Domain = "ibridge.co.za"
)

Write-Host "=== QUICK EMAIL SECURITY CHECK ===" -ForegroundColor Red
Write-Host "Checking @$Domain accounts for compromise" -ForegroundColor Yellow

$findings = @()
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Try to connect to Exchange Online
try {
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
    
    # Check if Exchange Online module is available
    if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
        Import-Module ExchangeOnlineManagement
        Connect-ExchangeOnline -ShowProgress $false
        $connected = $true
        Write-Host "Connected to Exchange Online successfully" -ForegroundColor Green
    } else {
        Write-Host "Exchange Online PowerShell module not available" -ForegroundColor Red
        $connected = $false
    }
} catch {
    Write-Host "Failed to connect to Exchange Online: $_" -ForegroundColor Red
    $connected = $false
}

if ($connected) {
    try {
        # Get all mailboxes for the domain
        Write-Host "Getting mailboxes for @$Domain..." -ForegroundColor Cyan
        $mailboxes = Get-Mailbox -Filter "EmailAddresses -like '*@$Domain'" -ResultSize 50 -ErrorAction Stop
        
        Write-Host "Found $($mailboxes.Count) mailboxes to check" -ForegroundColor Yellow
        
        $checkedCount = 0
        $issuesFound = 0
        
        foreach ($mailbox in $mailboxes) {
            $checkedCount++
            Write-Host "[$checkedCount/$($mailboxes.Count)] Checking: $($mailbox.PrimarySmtpAddress)" -ForegroundColor Gray
            
            # Check for suspicious inbox rules
            try {
                $rules = Get-InboxRule -Mailbox $mailbox.PrimarySmtpAddress -ErrorAction SilentlyContinue
                
                foreach ($rule in $rules) {
                    $suspicious = $false
                    $details = @()
                    
                    # Check for external forwarding
                    if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo -or $rule.RedirectTo) {
                        $allForwards = @()
                        if ($rule.ForwardTo) { $allForwards += $rule.ForwardTo }
                        if ($rule.ForwardAsAttachmentTo) { $allForwards += $rule.ForwardAsAttachmentTo }
                        if ($rule.RedirectTo) { $allForwards += $rule.RedirectTo }
                        
                        foreach ($forward in $allForwards) {
                            if ($forward -notlike "*@$Domain") {
                                $suspicious = $true
                                $details += "External forwarding to: $forward"
                            }
                        }
                    }
                    
                    # Check for auto-delete
                    if ($rule.DeleteMessage) {
                        $suspicious = $true
                        $details += "Auto-delete enabled"
                    }
                    
                    if ($suspicious) {
                        $issuesFound++
                        $finding = [PSCustomObject]@{
                            User = $mailbox.PrimarySmtpAddress
                            Issue = "Suspicious Email Rule"
                            RuleName = $rule.Name
                            Details = $details -join "; "
                            Severity = "HIGH"
                            Timestamp = Get-Date
                        }
                        $findings += $finding
                        
                        Write-Host "  SUSPICIOUS RULE: $($rule.Name) - $($details -join '; ')" -ForegroundColor Red
                    }
                }
            } catch {
                Write-Host "  Could not check rules: $_" -ForegroundColor Yellow
            }
            
            # Check for external delegates
            try {
                $permissions = Get-MailboxPermission -Identity $mailbox.PrimarySmtpAddress -ErrorAction SilentlyContinue | 
                    Where-Object { $_.User -ne "NT AUTHORITY\SELF" -and $_.User -notlike "*@$Domain" -and $_.AccessRights -contains "FullAccess" }
                
                foreach ($perm in $permissions) {
                    $issuesFound++
                    $finding = [PSCustomObject]@{
                        User = $mailbox.PrimarySmtpAddress
                        Issue = "External Delegate"
                        RuleName = "FullAccess Permission"
                        Details = "External user $($perm.User) has FullAccess"
                        Severity = "CRITICAL"
                        Timestamp = Get-Date
                    }
                    $findings += $finding
                    
                    Write-Host "  EXTERNAL DELEGATE: $($perm.User)" -ForegroundColor Red
                }
            } catch {
                Write-Host "  Could not check permissions: $_" -ForegroundColor Yellow
            }
        }
        
        # Disconnect
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "Error during mailbox audit: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Cannot perform Exchange audit - checking local system instead..." -ForegroundColor Yellow
    
    # Check local system for email-related threats
    Write-Host "Checking for suspicious processes..." -ForegroundColor Cyan
    $emailProcesses = Get-Process | Where-Object { 
        $_.ProcessName -like "*mail*" -or 
        $_.ProcessName -like "*smtp*" -or 
        $_.ProcessName -like "*outlook*" 
    }
    
    if ($emailProcesses) {
        Write-Host "Email-related processes found:" -ForegroundColor Yellow
        $emailProcesses | ForEach-Object {
            Write-Host "  $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Gray
        }
    }
    
    # Check network connections
    Write-Host "Checking network connections on email ports..." -ForegroundColor Cyan
    $emailPorts = @(25, 110, 143, 587, 993, 995, 465)
    $connections = Get-NetTCPConnection | Where-Object { $_.LocalPort -in $emailPorts -and $_.State -eq "Established" }
    
    if ($connections) {
        Write-Host "Active email connections found:" -ForegroundColor Yellow
        $connections | ForEach-Object {
            Write-Host "  $($_.LocalAddress):$($_.LocalPort) -> $($_.RemoteAddress):$($_.RemotePort)" -ForegroundColor Gray
        }
    }
}

# Summary
Write-Host "`n=== QUICK SECURITY CHECK SUMMARY ===" -ForegroundColor Green
if ($connected) {
    Write-Host "Mailboxes checked: $checkedCount" -ForegroundColor White
    Write-Host "Security issues found: $issuesFound" -ForegroundColor $(if($issuesFound -gt 0) {"Red"} else {"Green"})
} else {
    Write-Host "Local system check completed" -ForegroundColor White
}

if ($findings.Count -gt 0) {
    Write-Host "`nSECURITY ISSUES DETECTED:" -ForegroundColor Red
    $findings | Format-Table User, Issue, Details -AutoSize
    
    # Save findings
    $outputFile = "QuickSecurityCheck_$timestamp.csv"
    $findings | Export-Csv -Path $outputFile -NoTypeInformation
    Write-Host "Findings saved to: $outputFile" -ForegroundColor Green
} else {
    Write-Host "No immediate security issues detected" -ForegroundColor Green
}

Write-Host "`nRECOMMENDED IMMEDIATE ACTIONS:" -ForegroundColor Yellow
Write-Host "1. Force password reset for ALL @$Domain accounts" -ForegroundColor White
Write-Host "2. Enable MFA on all accounts" -ForegroundColor White
Write-Host "3. Review and remove suspicious email rules" -ForegroundColor White
Write-Host "4. Remove unauthorized delegates" -ForegroundColor White
Write-Host "5. Check audit logs for suspicious sign-ins" -ForegroundColor White
Write-Host "6. Run full malware scans on all systems" -ForegroundColor White
