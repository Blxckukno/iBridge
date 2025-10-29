# Check-EmailSecurity-iBridge.ps1
# Checks Microsoft Exchange/Office 365 for malicious email rules and delegates
# Specifically for @ibridge.co.za domain compromise

param(
    [string]$Domain = "ibridge.co.za",
    [switch]$RemoveThreats = $false  # Set to $true to automatically remove malicious rules
)

Write-Host "=== EMAIL SECURITY AUDIT FOR @$Domain ===" -ForegroundColor Red

# Check if Exchange Online PowerShell is available
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Write-Host "Exchange Online PowerShell module found" -ForegroundColor Green
} catch {
    Write-Warning "Exchange Online PowerShell module not found"
    Write-Host "Please install it with: Install-Module -Name ExchangeOnlineManagement" -ForegroundColor Yellow
    
    # Try legacy Exchange PowerShell
    try {
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential (Get-Credential) -Authentication Basic -AllowRedirection
        Import-PSSession $Session -DisableNameChecking
        Write-Host "Connected using legacy Exchange PowerShell" -ForegroundColor Green
    } catch {
        Write-Error "Cannot connect to Exchange Online. Please run on a machine with Exchange admin access."
        exit 1
    }
}

# Connect to Exchange Online
try {
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
    Connect-ExchangeOnline -ShowProgress $true
    Write-Host "Connected to Exchange Online" -ForegroundColor Green
} catch {
    Write-Error "Failed to connect to Exchange Online: $_"
    exit 1
}

# Get all mailboxes in the domain
Write-Host "`nGetting all mailboxes for @$Domain..." -ForegroundColor Cyan
$mailboxes = Get-Mailbox -Filter "EmailAddresses -like '*@$Domain'" -ResultSize Unlimited

Write-Host "Found $($mailboxes.Count) mailboxes in @$Domain domain" -ForegroundColor Yellow

$suspiciousFindings = @()
$reportPath = "EmailSecurityAudit_$Domain_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').csv"

foreach ($mailbox in $mailboxes) {
    Write-Host "`nAuditing: $($mailbox.PrimarySmtpAddress)" -ForegroundColor Cyan
    
    # Check for suspicious inbox rules
    try {
        $inboxRules = Get-InboxRule -Mailbox $mailbox.PrimarySmtpAddress
        
        foreach ($rule in $inboxRules) {
            $suspicious = $false
            $reasons = @()
            
            # Check for forwarding to external domains
            if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo -or $rule.RedirectTo) {
                $forwardAddresses = @()
                if ($rule.ForwardTo) { $forwardAddresses += $rule.ForwardTo }
                if ($rule.ForwardAsAttachmentTo) { $forwardAddresses += $rule.ForwardAsAttachmentTo }
                if ($rule.RedirectTo) { $forwardAddresses += $rule.RedirectTo }
                
                foreach ($address in $forwardAddresses) {
                    if ($address -notlike "*@$Domain") {
                        $suspicious = $true
                        $reasons += "Forwards to external address: $address"
                    }
                }
            }
            
            # Check for suspicious deletion rules
            if ($rule.DeleteMessage -eq $true) {
                $suspicious = $true
                $reasons += "Automatically deletes messages"
            }
            
            # Check for suspicious move to deleted items
            if ($rule.MoveToFolder -like "*Deleted*" -or $rule.MoveToFolder -like "*Trash*") {
                $suspicious = $true
                $reasons += "Moves messages to deleted items"
            }
            
            # Check for rules that process all messages
            if (!$rule.From -and !$rule.SentTo -and !$rule.SubjectContainsWords -and !$rule.BodyContainsWords) {
                $suspicious = $true
                $reasons += "Processes all incoming messages"
            }
            
            if ($suspicious) {
                $finding = [PSCustomObject]@{
                    Mailbox = $mailbox.PrimarySmtpAddress
                    RuleName = $rule.Name
                    RuleId = $rule.Identity
                    Enabled = $rule.Enabled
                    Reasons = $reasons -join "; "
                    ForwardTo = ($rule.ForwardTo -join ", ")
                    RedirectTo = ($rule.RedirectTo -join ", ")
                    DeleteMessage = $rule.DeleteMessage
                    MoveToFolder = $rule.MoveToFolder
                    Priority = $rule.Priority
                }
                
                $suspiciousFindings += $finding
                
                Write-Host "  SUSPICIOUS RULE FOUND: $($rule.Name)" -ForegroundColor Red
                Write-Host "    Reasons: $($reasons -join ', ')" -ForegroundColor Yellow
                
                if ($RemoveThreats) {
                    Write-Host "    REMOVING RULE..." -ForegroundColor Red
                    Remove-InboxRule -Identity $rule.Identity -Confirm:$false
                    Write-Host "    Rule removed" -ForegroundColor Green
                }
            }
        }
    } catch {
        Write-Warning "Could not check inbox rules for $($mailbox.PrimarySmtpAddress): $_"
    }
    
    # Check for suspicious delegates
    try {
        $delegates = Get-MailboxPermission -Identity $mailbox.PrimarySmtpAddress | Where-Object { 
            $_.User -ne "NT AUTHORITY\SELF" -and 
            $_.User -notlike "*@$Domain" -and
            $_.AccessRights -contains "FullAccess"
        }
        
        foreach ($delegate in $delegates) {
            $finding = [PSCustomObject]@{
                Mailbox = $mailbox.PrimarySmtpAddress
                RuleName = "DELEGATE ACCESS"
                RuleId = "N/A"
                Enabled = $true
                Reasons = "External user has FullAccess"
                ForwardTo = $delegate.User
                RedirectTo = ""
                DeleteMessage = "N/A"
                MoveToFolder = "N/A"
                Priority = "HIGH"
            }
            
            $suspiciousFindings += $finding
            
            Write-Host "  SUSPICIOUS DELEGATE: $($delegate.User)" -ForegroundColor Red
            Write-Host "    Access Rights: $($delegate.AccessRights -join ', ')" -ForegroundColor Yellow
            
            if ($RemoveThreats) {
                Write-Host "    REMOVING DELEGATE..." -ForegroundColor Red
                Remove-MailboxPermission -Identity $mailbox.PrimarySmtpAddress -User $delegate.User -AccessRights FullAccess -Confirm:$false
                Write-Host "    Delegate removed" -ForegroundColor Green
            }
        }
    } catch {
        Write-Warning "Could not check delegates for $($mailbox.PrimarySmtpAddress): $_"
    }
    
    # Check for suspicious send-as permissions
    try {
        $sendAsPerms = Get-RecipientPermission -Identity $mailbox.PrimarySmtpAddress | Where-Object { 
            $_.Trustee -ne "NT AUTHORITY\SELF" -and 
            $_.Trustee -notlike "*@$Domain" -and
            $_.AccessRights -contains "SendAs"
        }
        
        foreach ($perm in $sendAsPerms) {
            $finding = [PSCustomObject]@{
                Mailbox = $mailbox.PrimarySmtpAddress
                RuleName = "SEND-AS PERMISSION"
                RuleId = "N/A"
                Enabled = $true
                Reasons = "External user has SendAs permission"
                ForwardTo = $perm.Trustee
                RedirectTo = ""
                DeleteMessage = "N/A"
                MoveToFolder = "N/A"
                Priority = "HIGH"
            }
            
            $suspiciousFindings += $finding
            
            Write-Host "  SUSPICIOUS SEND-AS: $($perm.Trustee)" -ForegroundColor Red
            
            if ($RemoveThreats) {
                Write-Host "    REMOVING SEND-AS PERMISSION..." -ForegroundColor Red
                Remove-RecipientPermission -Identity $mailbox.PrimarySmtpAddress -Trustee $perm.Trustee -AccessRights SendAs -Confirm:$false
                Write-Host "    Send-As permission removed" -ForegroundColor Green
            }
        }
    } catch {
        Write-Warning "Could not check Send-As permissions for $($mailbox.PrimarySmtpAddress): $_"
    }
}

# Export findings to CSV
if ($suspiciousFindings.Count -gt 0) {
    $suspiciousFindings | Export-Csv -Path $reportPath -NoTypeInformation
    Write-Host "`n=== AUDIT COMPLETE ===" -ForegroundColor Red
    Write-Host "Found $($suspiciousFindings.Count) suspicious items" -ForegroundColor Yellow
    Write-Host "Report saved to: $reportPath" -ForegroundColor Green
    
    Write-Host "`nSUSPICIOUS FINDINGS SUMMARY:" -ForegroundColor Red
    $suspiciousFindings | Format-Table Mailbox, RuleName, Reasons -AutoSize
    
    if (!$RemoveThreats) {
        Write-Host "`nTo automatically remove threats, run with -RemoveThreats parameter" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n=== AUDIT COMPLETE ===" -ForegroundColor Green
    Write-Host "No suspicious email rules or delegates found" -ForegroundColor Green
}

# Additional security recommendations
Write-Host "`n=== SECURITY RECOMMENDATIONS ===" -ForegroundColor Cyan
Write-Host "1. Force password reset for all @$Domain accounts" -ForegroundColor Yellow
Write-Host "2. Enable MFA for all accounts" -ForegroundColor Yellow
Write-Host "3. Review audit logs for suspicious sign-ins" -ForegroundColor Yellow
Write-Host "4. Check for OAuth applications with suspicious permissions" -ForegroundColor Yellow
Write-Host "5. Enable Advanced Threat Protection" -ForegroundColor Yellow
Write-Host "6. Configure DMARC, SPF, and DKIM records" -ForegroundColor Yellow

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
