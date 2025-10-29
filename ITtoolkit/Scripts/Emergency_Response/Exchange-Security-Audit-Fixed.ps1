# Exchange-Security-Audit-Fixed.ps1
# Fixed version for Exchange Online security audit using correct V3 cmdlets

param(
    [string]$Domain = "ibridge.co.za"
)

Write-Host "=== EXCHANGE ONLINE SECURITY AUDIT (V3 CMDLETS) ===" -ForegroundColor Red

try {
    # Connect to Exchange Online
    Connect-ExchangeOnline -ShowProgress $false
    Write-Host "Connected to Exchange Online successfully" -ForegroundColor Green
    
    # Get all mailboxes for the domain
    Write-Host "Getting all mailboxes for @$Domain..." -ForegroundColor Cyan
    $mailboxes = Get-EXOMailbox -Filter "EmailAddresses -like '*@$Domain'" -PropertySets All
    
    Write-Host "Found $($mailboxes.Count) mailboxes to audit" -ForegroundColor Yellow
    
    $findings = @()
    $totalIssues = 0
    
    foreach ($mailbox in $mailboxes) {
        Write-Host "Auditing: $($mailbox.PrimarySmtpAddress)" -ForegroundColor Cyan
        
        # Check inbox rules using correct V3 cmdlet
        try {
            $rules = Get-EXOInboxRule -Mailbox $mailbox.PrimarySmtpAddress
            
            foreach ($rule in $rules) {
                $suspicious = $false
                $issues = @()
                
                # Check for external forwarding
                if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo -or $rule.RedirectTo) {
                    $allForwards = @()
                    if ($rule.ForwardTo) { $allForwards += $rule.ForwardTo }
                    if ($rule.ForwardAsAttachmentTo) { $allForwards += $rule.ForwardAsAttachmentTo }
                    if ($rule.RedirectTo) { $allForwards += $rule.RedirectTo }
                    
                    foreach ($forward in $allForwards) {
                        if ($forward -notlike "*@$Domain") {
                            $suspicious = $true
                            $issues += "External forwarding to: $forward"
                        }
                    }
                }
                
                # Check for auto-delete
                if ($rule.DeleteMessage) {
                    $suspicious = $true
                    $issues += "Auto-delete enabled"
                }
                
                # Check for suspicious keywords in rule conditions
                $suspiciousKeywords = @("invoice", "payment", "urgent", "confidential", "bank", "security", "CEO", "president")
                if ($rule.SubjectContainsWords) {
                    foreach ($keyword in $suspiciousKeywords) {
                        if ($rule.SubjectContainsWords -like "*$keyword*") {
                            $suspicious = $true
                            $issues += "Targets '$keyword' emails"
                        }
                    }
                }
                
                if ($suspicious) {
                    $totalIssues++
                    $finding = [PSCustomObject]@{
                        User = $mailbox.PrimarySmtpAddress
                        Type = "Suspicious Email Rule"
                        RuleName = $rule.Name
                        Issues = $issues -join "; "
                        Priority = "HIGH"
                        Enabled = $rule.Enabled
                    }
                    $findings += $finding
                    
                    Write-Host "  ⚠️  SUSPICIOUS RULE: $($rule.Name)" -ForegroundColor Red
                    Write-Host "      Issues: $($issues -join '; ')" -ForegroundColor Yellow
                    Write-Host "      Enabled: $($rule.Enabled)" -ForegroundColor $(if($rule.Enabled) {"Red"} else {"Yellow"})
                }
            }
        } catch {
            Write-Host "  Could not check inbox rules: $_" -ForegroundColor Yellow
        }
        
        # Check mailbox permissions using correct V3 cmdlet
        try {
            $permissions = Get-EXOMailboxPermission -Identity $mailbox.PrimarySmtpAddress | 
                Where-Object { 
                    $_.User -ne "NT AUTHORITY\SELF" -and 
                    $_.User -notlike "*@$Domain" -and 
                    $_.AccessRights -contains "FullAccess" 
                }
            
            foreach ($perm in $permissions) {
                $totalIssues++
                $finding = [PSCustomObject]@{
                    User = $mailbox.PrimarySmtpAddress
                    Type = "External Delegate"
                    RuleName = "FullAccess Permission"
                    Issues = "External user '$($perm.User)' has FullAccess"
                    Priority = "CRITICAL"
                    Enabled = $true
                }
                $findings += $finding
                
                Write-Host "  🚨 EXTERNAL DELEGATE: $($perm.User)" -ForegroundColor Red
                Write-Host "      Access: $($perm.AccessRights -join ', ')" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  Could not check permissions: $_" -ForegroundColor Yellow
        }
        
        # Check send-as permissions
        try {
            $sendAsPerms = Get-EXORecipientPermission -Identity $mailbox.PrimarySmtpAddress | 
                Where-Object { 
                    $_.Trustee -ne "NT AUTHORITY\SELF" -and 
                    $_.Trustee -notlike "*@$Domain" -and 
                    $_.AccessRights -contains "SendAs" 
                }
            
            foreach ($perm in $sendAsPerms) {
                $totalIssues++
                $finding = [PSCustomObject]@{
                    User = $mailbox.PrimarySmtpAddress
                    Type = "External Send-As"
                    RuleName = "SendAs Permission"
                    Issues = "External user '$($perm.Trustee)' can send as this user"
                    Priority = "CRITICAL"
                    Enabled = $true
                }
                $findings += $finding
                
                Write-Host "  🚨 EXTERNAL SEND-AS: $($perm.Trustee)" -ForegroundColor Red
            }
        } catch {
            Write-Host "  Could not check Send-As permissions: $_" -ForegroundColor Yellow
        }
    }
    
    # Summary Report
    Write-Host "`n=== SECURITY AUDIT SUMMARY ===" -ForegroundColor Green
    Write-Host "Total mailboxes audited: $($mailboxes.Count)" -ForegroundColor White
    Write-Host "Security issues found: $totalIssues" -ForegroundColor $(if($totalIssues -gt 0) {"Red"} else {"Green"})
    
    if ($findings.Count -gt 0) {
        Write-Host "`n🚨 SECURITY ISSUES DETECTED:" -ForegroundColor Red
        $findings | Format-Table User, Type, Issues, Priority -AutoSize
        
        # Save detailed report
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $reportFile = "ExchangeSecurityAudit_$timestamp.csv"
        $findings | Export-Csv -Path $reportFile -NoTypeInformation
        Write-Host "Detailed report saved to: $reportFile" -ForegroundColor Green
        
        Write-Host "`n🔧 REMEDIATION REQUIRED:" -ForegroundColor Yellow
        Write-Host "1. Remove suspicious email rules immediately" -ForegroundColor White
        Write-Host "2. Remove unauthorized external delegates" -ForegroundColor White
        Write-Host "3. Review and remove suspicious Send-As permissions" -ForegroundColor White
        Write-Host "4. Force password reset for affected accounts" -ForegroundColor White
    } else {
        Write-Host "✅ No security issues detected in email configuration" -ForegroundColor Green
    }
    
    # Additional security checks
    Write-Host "`n=== ADDITIONAL SECURITY RECOMMENDATIONS ===" -ForegroundColor Cyan
    Write-Host "1. Enable MFA for ALL @$Domain accounts" -ForegroundColor White
    Write-Host "2. Review recent sign-in logs for suspicious activity" -ForegroundColor White
    Write-Host "3. Check OAuth applications for unauthorized access" -ForegroundColor White
    Write-Host "4. Implement Advanced Threat Protection" -ForegroundColor White
    Write-Host "5. Set up DMARC, SPF, and DKIM email authentication" -ForegroundColor White
    
    Disconnect-ExchangeOnline -Confirm:$false
    
} catch {
    Write-Host "Error during Exchange audit: $_" -ForegroundColor Red
}
