# CEO-EmailCompromise-Response.ps1
# Purpose: Emergency response script for CEO email account compromise
# Author: GitHub Copilot
# Date: September 10, 2025

param (
    [Parameter(Mandatory=$true)]
    [string]$CompromisedAccount,
    
    [Parameter(Mandatory=$false)]
    [switch]$ResetPassword,
    
    [Parameter(Mandatory=$false)]
    [switch]$BlockAccount,
    
    [Parameter(Mandatory=$false)]
    [switch]$UnblockAccount,
    
    [Parameter(Mandatory=$false)]
    [switch]$DisableForwarding,
    
    [Parameter(Mandatory=$false)]
    [switch]$RemoveInboxRules,
    
    [Parameter(Mandatory=$false)]
    [switch]$RemoveDelegates,
    
    [Parameter(Mandatory=$false)]
    [switch]$BlockSuspiciousIPs,
    
    [Parameter(Mandatory=$false)]
    [switch]$QuarantineMaliciousEmails,
    
    [Parameter(Mandatory=$false)]
    [switch]$NotifyUsers,
    
    [Parameter(Mandatory=$false)]
    [switch]$DoAll
)

# Initialize
$ErrorActionPreference = "Continue"
$CompromiseResponses = @()

# Function for logging
function Write-ResponseLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Action')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with color based on level
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor White }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
        'Action' { Write-Host $logMessage -ForegroundColor Cyan }
    }
}

# Function to record response actions
function Add-ResponseAction {
    param(
        [string]$Action,
        [string]$Description,
        [bool]$IsCompleted = $false,
        [string]$Result
    )
    
    $actionResult = [PSCustomObject]@{
        Action = $Action
        Description = $Description
        IsCompleted = $IsCompleted
        Result = $Result
        Timestamp = Get-Date
    }
    
    $CompromiseResponses += $actionResult
    
    # Log to console
    $statusIcon = if ($IsCompleted) { "[COMPLETED]" } else { "[FAILED]" }
    $logLevel = if ($IsCompleted) { "Success" } else { "Error" }
    
    Write-ResponseLog "$statusIcon $Action - $Result" -Level $logLevel
    
    return $actionResult
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-ResponseLog "Checking prerequisites and required modules..." -Level Info
    $requiredModules = @(
        "ExchangeOnlineManagement",
        "AzureAD",
        "MSOnline"
    )
    
    $allModulesPresent = $true
    
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-ResponseLog "Required module not found: $module" -Level Error
            Write-ResponseLog "Please install it with: Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser" -Level Warning
            $allModulesPresent = $false
        } else {
            Write-ResponseLog "Module $module is available" -Level Success
        }
    }
    
    if (!$allModulesPresent) {
        Write-ResponseLog "Missing required modules. Please install them and try again." -Level Error
        return $false
    }
    
    # Check connections
    try {
        Write-ResponseLog "Connecting to required services..." -Level Info
        
        # Connect to Exchange Online
        Connect-ExchangeOnline -ErrorAction Stop | Out-Null
        Write-ResponseLog "Connected to Exchange Online" -Level Success
        
        # Connect to Azure AD
        Connect-AzureAD -ErrorAction Stop | Out-Null
        Write-ResponseLog "Connected to Azure AD" -Level Success
        
        # Try to connect to MSOL
        try {
            Connect-MsolService -ErrorAction Stop | Out-Null
            Write-ResponseLog "Connected to Microsoft Online Services" -Level Success
        } catch {
            Write-ResponseLog "Could not connect to MSOnline Service: $_" -Level Warning
            Write-ResponseLog "Some functions may be limited" -Level Warning
        }
        
        return $true
    } catch {
        Write-ResponseLog "Failed to connect to required services: $_" -Level Error
        return $false
    }
}

# Function to verify compromised account
function Verify-CompromisedAccount {
    param(
        [string]$UserPrincipalName
    )
    
    Write-ResponseLog "Verifying account $UserPrincipalName..." -Level Info
    
    try {
        # Check if account exists
        $user = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop
        
        if ($user) {
            Write-ResponseLog "Account $UserPrincipalName found: $($user.DisplayName)" -Level Success
            return $true
        } else {
            Write-ResponseLog "Account $UserPrincipalName not found!" -Level Error
            return $false
        }
    } catch {
        Write-ResponseLog "Error verifying account: $_" -Level Error
        return $false
    }
}

# Function to block account
function Block-UserAccount {
    param(
        [string]$UserPrincipalName
    )
    
    Write-ResponseLog "Blocking account $UserPrincipalName..." -Level Action
    
    try {
        # Block sign-ins
        Set-MsolUser -UserPrincipalName $UserPrincipalName -BlockCredential $true
        
        # Verify the action
        $user = Get-MsolUser -UserPrincipalName $UserPrincipalName
        if ($user.BlockCredential -eq $true) {
            Add-ResponseAction -Action "Block Account" `
                             -Description "Blocked sign-ins for $UserPrincipalName" `
                             -IsCompleted $true `
                             -Result "Account successfully blocked"
            return $true
        } else {
            Add-ResponseAction -Action "Block Account" `
                             -Description "Attempted to block sign-ins for $UserPrincipalName" `
                             -IsCompleted $false `
                             -Result "Failed to block account"
            return $false
        }
    } catch {
        Add-ResponseAction -Action "Block Account" `
                         -Description "Attempted to block sign-ins for $UserPrincipalName" `
                         -IsCompleted $false `
                         -Result "Error: $_"
        return $false
    }
}

# Function to unblock account
function Unblock-UserAccount {
    param(
        [string]$UserPrincipalName
    )
    
    Write-ResponseLog "Unblocking account $UserPrincipalName..." -Level Action
    
    try {
        # Unblock sign-ins
        Set-MsolUser -UserPrincipalName $UserPrincipalName -BlockCredential $false
        
        # Verify the action
        $user = Get-MsolUser -UserPrincipalName $UserPrincipalName
        if ($user.BlockCredential -eq $false) {
            Add-ResponseAction -Action "Unblock Account" `
                             -Description "Unblocked sign-ins for $UserPrincipalName" `
                             -IsCompleted $true `
                             -Result "Account successfully unblocked"
            return $true
        } else {
            Add-ResponseAction -Action "Unblock Account" `
                             -Description "Attempted to unblock sign-ins for $UserPrincipalName" `
                             -IsCompleted $false `
                             -Result "Failed to unblock account"
            return $false
        }
    } catch {
        Add-ResponseAction -Action "Unblock Account" `
                         -Description "Attempted to unblock sign-ins for $UserPrincipalName" `
                         -IsCompleted $false `
                         -Result "Error: $_"
        return $false
    }
}

# Function to reset password
function Reset-UserPassword {
    param(
        [string]$UserPrincipalName
    )
    
    Write-ResponseLog "Resetting password for $UserPrincipalName..." -Level Action
    
    try {
        # Generate a strong password (this is temporary - user will be forced to change)
        $length = 16
        $nonAlphaChars = 5
        $password = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)
        
        # Reset the password and force change at next login
        Set-MsolUserPassword -UserPrincipalName $UserPrincipalName -NewPassword $password -ForceChangePassword $true
        
        Add-ResponseAction -Action "Reset Password" `
                         -Description "Reset password for $UserPrincipalName" `
                         -IsCompleted $true `
                         -Result "Password reset successfully, user will be forced to change at next login"
        
        # Return the temporary password
        return $password
    } catch {
        Add-ResponseAction -Action "Reset Password" `
                         -Description "Attempted to reset password for $UserPrincipalName" `
                         -IsCompleted $false `
                         -Result "Error: $_"
        return $null
    }
}

# Function to disable email forwarding
function Disable-EmailForwarding {
    param(
        [string]$UserPrincipalName
    )
    
    Write-ResponseLog "Disabling email forwarding for $UserPrincipalName..." -Level Action
    
    try {
        # Check current forwarding settings
        $mailbox = Get-Mailbox -Identity $UserPrincipalName
        $forwardingFound = $false
        
        if ($mailbox.ForwardingAddress -or $mailbox.ForwardingSmtpAddress) {
            $forwardingFound = $true
            $forwardingDetails = ""
            
            if ($mailbox.ForwardingAddress) {
                $forwardingDetails += "Internal forwarding to: $($mailbox.ForwardingAddress)"
            }
            
            if ($mailbox.ForwardingSmtpAddress) {
                if ($forwardingDetails) { $forwardingDetails += " | " }
                $forwardingDetails += "External forwarding to: $($mailbox.ForwardingSmtpAddress.Replace('SMTP:', ''))"
            }
            
            # Remove forwarding
            Set-Mailbox -Identity $UserPrincipalName -ForwardingAddress $null -ForwardingSmtpAddress $null
            
            # Verify the action
            $updatedMailbox = Get-Mailbox -Identity $UserPrincipalName
            if (!$updatedMailbox.ForwardingAddress -and !$updatedMailbox.ForwardingSmtpAddress) {
                Add-ResponseAction -Action "Disable Forwarding" `
                                 -Description "Removed email forwarding for $UserPrincipalName" `
                                 -IsCompleted $true `
                                 -Result "Forwarding removed: $forwardingDetails"
                return $true
            } else {
                Add-ResponseAction -Action "Disable Forwarding" `
                                 -Description "Attempted to remove email forwarding for $UserPrincipalName" `
                                 -IsCompleted $false `
                                 -Result "Failed to remove forwarding"
                return $false
            }
        } else {
            Add-ResponseAction -Action "Disable Forwarding" `
                             -Description "Checked email forwarding for $UserPrincipalName" `
                             -IsCompleted $true `
                             -Result "No forwarding found"
            return $true
        }
    } catch {
        Add-ResponseAction -Action "Disable Forwarding" `
                         -Description "Attempted to remove email forwarding for $UserPrincipalName" `
                         -IsCompleted $false `
                         -Result "Error: $_"
        return $false
    }
}

# Function to remove inbox rules
function Remove-InboxRules {
    param(
        [string]$UserPrincipalName
    )
    
    Write-ResponseLog "Removing inbox rules for $UserPrincipalName..." -Level Action
    
    try {
        # Get inbox rules
        $inboxRules = Get-InboxRule -Mailbox $UserPrincipalName
        
        if ($inboxRules -and $inboxRules.Count -gt 0) {
            $rulesRemoved = 0
            $rulesList = ""
            
            foreach ($rule in $inboxRules) {
                $ruleDetails = "Rule: $($rule.Name)"
                
                if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo -or $rule.RedirectTo) {
                    $ruleDetails += " [Forwarding Rule]"
                }
                
                if ($rule.DeleteMessage -eq $true) {
                    $ruleDetails += " [Delete Rule]"
                }
                
                # Try to remove the rule
                try {
                    Remove-InboxRule -Identity $rule.Identity -Confirm:$false
                    $rulesList += "$ruleDetails - Removed`n"
                    $rulesRemoved++
                } catch {
                    $rulesList += "$ruleDetails - Failed to remove: $_`n"
                }
            }
            
            if ($rulesRemoved -eq $inboxRules.Count) {
                Add-ResponseAction -Action "Remove Inbox Rules" `
                                 -Description "Removed inbox rules for $UserPrincipalName" `
                                 -IsCompleted $true `
                                 -Result "All $rulesRemoved rules removed successfully`n$rulesList"
                return $true
            } else {
                Add-ResponseAction -Action "Remove Inbox Rules" `
                                 -Description "Attempted to remove inbox rules for $UserPrincipalName" `
                                 -IsCompleted $false `
                                 -Result "Removed $rulesRemoved out of $($inboxRules.Count) rules`n$rulesList"
                return $false
            }
        } else {
            Add-ResponseAction -Action "Remove Inbox Rules" `
                             -Description "Checked inbox rules for $UserPrincipalName" `
                             -IsCompleted $true `
                             -Result "No inbox rules found"
            return $true
        }
    } catch {
        Add-ResponseAction -Action "Remove Inbox Rules" `
                         -Description "Attempted to remove inbox rules for $UserPrincipalName" `
                         -IsCompleted $false `
                         -Result "Error: $_"
        return $false
    }
}

# Function to remove delegates
function Remove-Delegates {
    param(
        [string]$UserPrincipalName
    )
    
    Write-ResponseLog "Removing delegates for $UserPrincipalName..." -Level Action
    
    try {
        $delegatesFound = $false
        $delegatesList = ""
        $delegatesRemoved = 0
        $delegatesTotal = 0
        
        # Check Full Access permissions
        $fullAccessUsers = Get-MailboxPermission -Identity $UserPrincipalName | 
                           Where-Object { $_.IsInherited -eq $false -and $_.User -ne "NT AUTHORITY\SELF" }
        
        if ($fullAccessUsers) {
            $delegatesFound = $true
            $delegatesTotal += $fullAccessUsers.Count
            
            foreach ($permission in $fullAccessUsers) {
                $delegateDetails = "Delegate: $($permission.User) - Full Access"
                
                try {
                    Remove-MailboxPermission -Identity $UserPrincipalName -User $permission.User -AccessRights FullAccess -Confirm:$false
                    $delegatesList += "$delegateDetails - Removed`n"
                    $delegatesRemoved++
                } catch {
                    $delegatesList += "$delegateDetails - Failed to remove: $_`n"
                }
            }
        }
        
        # Check Send As permissions
        $sendAsUsers = Get-RecipientPermission -Identity $UserPrincipalName | 
                       Where-Object { $_.IsInherited -eq $false -and $_.Trustee -ne "NT AUTHORITY\SELF" }
        
        if ($sendAsUsers) {
            $delegatesFound = $true
            $delegatesTotal += $sendAsUsers.Count
            
            foreach ($permission in $sendAsUsers) {
                $delegateDetails = "Delegate: $($permission.Trustee) - Send As"
                
                try {
                    Remove-RecipientPermission -Identity $UserPrincipalName -Trustee $permission.Trustee -AccessRights SendAs -Confirm:$false
                    $delegatesList += "$delegateDetails - Removed`n"
                    $delegatesRemoved++
                } catch {
                    $delegatesList += "$delegateDetails - Failed to remove: $_`n"
                }
            }
        }
        
        # Check Send on Behalf permissions
        $mailbox = Get-Mailbox -Identity $UserPrincipalName
        if ($mailbox.GrantSendOnBehalfTo -and $mailbox.GrantSendOnBehalfTo.Count -gt 0) {
            $delegatesFound = $true
            $delegatesTotal += $mailbox.GrantSendOnBehalfTo.Count
            
            try {
                Set-Mailbox -Identity $UserPrincipalName -GrantSendOnBehalfTo $null
                $delegatesList += "Send on Behalf permissions - All removed`n"
                $delegatesRemoved += $mailbox.GrantSendOnBehalfTo.Count
            } catch {
                $delegatesList += "Send on Behalf permissions - Failed to remove: $_`n"
            }
        }
        
        if ($delegatesFound) {
            if ($delegatesRemoved -eq $delegatesTotal) {
                Add-ResponseAction -Action "Remove Delegates" `
                                 -Description "Removed delegates for $UserPrincipalName" `
                                 -IsCompleted $true `
                                 -Result "All $delegatesRemoved delegates removed successfully`n$delegatesList"
                return $true
            } else {
                Add-ResponseAction -Action "Remove Delegates" `
                                 -Description "Attempted to remove delegates for $UserPrincipalName" `
                                 -IsCompleted $false `
                                 -Result "Removed $delegatesRemoved out of $delegatesTotal delegates`n$delegatesList"
                return $false
            }
        } else {
            Add-ResponseAction -Action "Remove Delegates" `
                             -Description "Checked delegates for $UserPrincipalName" `
                             -IsCompleted $true `
                             -Result "No delegates found"
            return $true
        }
    } catch {
        Add-ResponseAction -Action "Remove Delegates" `
                         -Description "Attempted to remove delegates for $UserPrincipalName" `
                         -IsCompleted $false `
                         -Result "Error: $_"
        return $false
    }
}

# Function to get recent suspicious IPs
function Get-SuspiciousIPs {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack = 7
    )
    
    Write-ResponseLog "Checking for suspicious login IPs for $UserPrincipalName..." -Level Action
    
    try {
        # Define start date
        $startDate = (Get-Date).AddDays(-$DaysToLookBack)
        
        # Get sign-in activity
        $signIns = Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$UserPrincipalName'" -Top 100 | 
                   Where-Object { $_.CreatedDateTime -ge $startDate }
        
        if ($signIns -and $signIns.Count -gt 0) {
            # Group by IP and status (success/failure)
            $ipGroups = $signIns | Group-Object IpAddress | Select-Object Name, Count
            
            # Find failed login IPs
            $failedIPs = $signIns | Where-Object { $_.Status.ErrorCode -ne 0 } | Group-Object IpAddress | Select-Object Name, Count
            
            # Create suspicious IP list
            $suspiciousIPs = @()
            
            # Add IPs with high failure counts
            foreach ($ip in $failedIPs) {
                if ($ip.Count -gt 3) {
                    $suspiciousIPs += $ip.Name
                }
            }
            
            # Return results
            if ($suspiciousIPs.Count -gt 0) {
                Add-ResponseAction -Action "Identify Suspicious IPs" `
                                 -Description "Checked login IPs for $UserPrincipalName" `
                                 -IsCompleted $true `
                                 -Result "Found $($suspiciousIPs.Count) suspicious IPs: $($suspiciousIPs -join ', ')"
                return $suspiciousIPs
            } else {
                Add-ResponseAction -Action "Identify Suspicious IPs" `
                                 -Description "Checked login IPs for $UserPrincipalName" `
                                 -IsCompleted $true `
                                 -Result "No obviously suspicious IPs found"
                return @()
            }
        } else {
            Add-ResponseAction -Action "Identify Suspicious IPs" `
                             -Description "Checked login IPs for $UserPrincipalName" `
                             -IsCompleted $true `
                             -Result "No recent sign-ins found"
            return @()
        }
    } catch {
        Add-ResponseAction -Action "Identify Suspicious IPs" `
                         -Description "Attempted to check login IPs for $UserPrincipalName" `
                         -IsCompleted $false `
                         -Result "Error: $_"
        return @()
    }
}

# Function to create transport rule to block emails with attachments or links from the compromised account
function Block-MaliciousEmails {
    param(
        [string]$UserPrincipalName
    )
    
    Write-ResponseLog "Creating transport rule to block potentially malicious emails from $UserPrincipalName..." -Level Action
    
    try {
        $ruleName = "SECURITY-BlockMalicious-$($UserPrincipalName.Split('@')[0])-$(Get-Date -Format 'yyyyMMddHHmm')"
        
        # Create transport rule
        New-TransportRule -Name $ruleName `
                          -From $UserPrincipalName `
                          -SubjectOrBodyContainsWords "click here", "sign in", "verify", "urgent", "important", "account", "password", "credential" `
                          -AttachmentNameMatchesPatterns "*.zip", "*.exe", "*.js", "*.vbs", "*.bat", "*.cmd", "*.ps1", "*.scr" `
                          -AttachmentExtensionMatchesWords "zip", "exe", "js", "vbs", "bat", "cmd", "ps1", "scr" `
                          -AttachmentHasExecutableContent $true `
                          -SetAuditSeverity High `
                          -Mode Enforce `
                          -SetHeaderName "X-MailDetection" `
                          -SetHeaderValue "DetectedMaliciousMailFromCompromisedAccount" `
                          -Quarantine $true
        
        # Verify rule was created
        $rule = Get-TransportRule -Identity $ruleName -ErrorAction SilentlyContinue
        
        if ($rule) {
            Add-ResponseAction -Action "Block Malicious Emails" `
                             -Description "Created transport rule to block potentially malicious emails" `
                             -IsCompleted $true `
                             -Result "Transport rule '$ruleName' created successfully"
            return $true
        } else {
            Add-ResponseAction -Action "Block Malicious Emails" `
                             -Description "Attempted to create transport rule" `
                             -IsCompleted $false `
                             -Result "Failed to create transport rule"
            return $false
        }
    } catch {
        Add-ResponseAction -Action "Block Malicious Emails" `
                         -Description "Attempted to create transport rule" `
                         -IsCompleted $false `
                         -Result "Error: $_"
        return $false
    }
}

# Function to send notification to users
function Send-UserNotification {
    param(
        [string]$CompromisedAccount
    )
    
    Write-ResponseLog "Creating email notification for users about the compromised account..." -Level Action
    
    # Extract the display name from the email
    $displayName = $CompromisedAccount.Split('@')[0]
    try {
        $user = Get-MsolUser -UserPrincipalName $CompromisedAccount
        if ($user) {
            $displayName = $user.DisplayName
        }
    } catch {
        # Continue with the username as fallback
    }
    
    $notificationBody = @"
SECURITY ALERT: Compromised Email Account

We have detected that the email account for $displayName ($CompromisedAccount) has been compromised. An unauthorized party has gained access and is sending phishing emails.

IMPORTANT: If you receive ANY emails containing links or attachments from $displayName, DO NOT click on links or open attachments.

Actions to take immediately:
• Delete these emails from your inbox.
• If you have already clicked a link or opened an attachment, contact the IT Helpdesk without delay.
• Do not respond to suspicious emails from this account.
• Report any suspicious emails to the IT security team.

Our IT team is actively working to secure the account and block further malicious activity. We will share an update once the issue has been resolved.

Your vigilance helps protect our company data and systems.

Thank you,
IT Security Team
"@

    try {
        # For actual sending, you would need to create a message in the admin's mailbox and send it
        # For now we'll just simulate this by writing the notification to a file
        
        $notificationFile = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\CEO-Account-Notification.txt"
        $notificationBody | Out-File -FilePath $notificationFile -Force
        
        Add-ResponseAction -Action "Send User Notification" `
                         -Description "Prepared notification about the compromised account" `
                         -IsCompleted $true `
                         -Result "Notification template created at $notificationFile"
        
        # If you want to actually send the email, you could uncomment and adapt this code
        # using Exchange Online cmdlets
        <#
        $allUsers = Get-User -ResultSize unlimited | Where-Object {$_.UserPrincipalName -ne $CompromisedAccount}
        $totalSent = 0
        
        foreach ($recipient in $allUsers) {
            try {
                Send-MailMessage -To $recipient.UserPrincipalName `
                                -From "security@yourdomain.com" `
                                -Subject "SECURITY ALERT: Compromised Email Account" `
                                -Body $notificationBody `
                                -SmtpServer "smtp.office365.com" `
                                -Port 587 `
                                -UseSSL `
                                -Credential $credential
                $totalSent++
            } catch {
                Write-ResponseLog "Failed to send notification to $($recipient.UserPrincipalName): $_" -Level Warning
            }
        }
        
        if ($totalSent -gt 0) {
            Add-ResponseAction -Action "Send User Notification" `
                             -Description "Sent notification about compromised account" `
                             -IsCompleted $true `
                             -Result "Notification sent to $totalSent users"
        } else {
            Add-ResponseAction -Action "Send User Notification" `
                             -Description "Attempted to send notification about compromised account" `
                             -IsCompleted $false `
                             -Result "Failed to send notifications"
        }
        #>
        
        return $true
    } catch {
        Add-ResponseAction -Action "Send User Notification" `
                         -Description "Attempted to create notification about compromised account" `
                         -IsCompleted $false `
                         -Result "Error: $_"
        return $false
    }
}

# Function to quarantine suspected phishing emails
function Quarantine-SuspectedPhishingEmails {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack = 2
    )
    
    Write-ResponseLog "Searching for and quarantining suspected phishing emails sent from $UserPrincipalName..." -Level Action
    
    try {
        # Define start date
        $startDate = (Get-Date).AddDays(-$DaysToLookBack)
        $endDate = Get-Date
        
        # Get message trace
        $sentEmails = Get-MessageTrace -SenderAddress $UserPrincipalName -StartDate $startDate -EndDate $endDate
        
        if ($sentEmails -and $sentEmails.Count -gt 0) {
            # Look for emails with attachments or suspicious subjects
            $suspiciousSubjects = @("urgent", "password", "verify", "account", "click", "update", "security", "log in", "signin")
            $suspiciousEmails = @()
            
            foreach ($email in $sentEmails) {
                $isPhishy = $false
                
                # Check if has attachment
                if ($email.HasAttachments -eq $true) {
                    $isPhishy = $true
                }
                
                # Check subject for suspicious words
                foreach ($word in $suspiciousSubjects) {
                    if ($email.Subject -match $word) {
                        $isPhishy = $true
                        break
                    }
                }
                
                if ($isPhishy) {
                    $suspiciousEmails += $email
                }
            }
            
            if ($suspiciousEmails.Count -gt 0) {
                Add-ResponseAction -Action "Quarantine Phishing Emails" `
                                 -Description "Identified suspicious emails from $UserPrincipalName" `
                                 -IsCompleted $true `
                                 -Result "Found $($suspiciousEmails.Count) suspicious emails out of $($sentEmails.Count) total emails sent in the past $DaysToLookBack days"
                
                # For actual quarantine, you would need to use content search and compliance features
                # This would typically require Security & Compliance Center PowerShell module and appropriate permissions
                
                # Create report of suspicious emails
                $suspiciousEmailsFile = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\SuspiciousEmails-$(Get-Date -Format 'yyyyMMddHHmm').csv"
                $suspiciousEmails | Export-Csv -Path $suspiciousEmailsFile -NoTypeInformation
                
                Add-ResponseAction -Action "Export Suspicious Emails" `
                                 -Description "Created report of suspicious emails" `
                                 -IsCompleted $true `
                                 -Result "Suspicious emails exported to $suspiciousEmailsFile"
                
                return $true
            } else {
                Add-ResponseAction -Action "Quarantine Phishing Emails" `
                                 -Description "Checked for suspicious emails from $UserPrincipalName" `
                                 -IsCompleted $true `
                                 -Result "No obviously suspicious emails found out of $($sentEmails.Count) total emails sent in the past $DaysToLookBack days"
                return $true
            }
        } else {
            Add-ResponseAction -Action "Quarantine Phishing Emails" `
                             -Description "Checked for suspicious emails from $UserPrincipalName" `
                             -IsCompleted $true `
                             -Result "No emails found in the past $DaysToLookBack days"
            return $true
        }
    } catch {
        Add-ResponseAction -Action "Quarantine Phishing Emails" `
                         -Description "Attempted to check for suspicious emails from $UserPrincipalName" `
                         -IsCompleted $false `
                         -Result "Error: $_"
        return $false
    }
}

# Main execution flow
Write-ResponseLog "Microsoft 365 Email Compromise Emergency Response Tool" -Level Info
Write-ResponseLog "Starting emergency response for $CompromisedAccount on $(Get-Date)" -Level Info

# Check if the compromised account exists
if (Test-Prerequisites) {
    if (Verify-CompromisedAccount -UserPrincipalName $CompromisedAccount) {
        # Block account if requested
        if ($BlockAccount -or $DoAll) {
            Block-UserAccount -UserPrincipalName $CompromisedAccount
        }
        
        # Reset password if requested
        if ($ResetPassword -or $DoAll) {
            $tempPassword = Reset-UserPassword -UserPrincipalName $CompromisedAccount
            if ($tempPassword) {
                Write-ResponseLog "Temporary password: $tempPassword" -Level Warning
                Write-ResponseLog "IMPORTANT: Securely communicate this password to the account owner" -Level Warning
            }
        }
        
        # Disable forwarding if requested
        if ($DisableForwarding -or $DoAll) {
            Disable-EmailForwarding -UserPrincipalName $CompromisedAccount
        }
        
        # Remove inbox rules if requested
        if ($RemoveInboxRules -or $DoAll) {
            Remove-InboxRules -UserPrincipalName $CompromisedAccount
        }
        
        # Remove delegates if requested
        if ($RemoveDelegates -or $DoAll) {
            Remove-Delegates -UserPrincipalName $CompromisedAccount
        }
        
        # Block suspicious IPs if requested
        if ($BlockSuspiciousIPs -or $DoAll) {
            $suspiciousIPs = Get-SuspiciousIPs -UserPrincipalName $CompromisedAccount
            # Note: Actual IP blocking would require Azure AD Conditional Access policies
            # or other security solutions
        }
        
        # Quarantine malicious emails
        if ($QuarantineMaliciousEmails -or $DoAll) {
            Quarantine-SuspectedPhishingEmails -UserPrincipalName $CompromisedAccount
            Block-MaliciousEmails -UserPrincipalName $CompromisedAccount
        }
        
        # Send notification to users
        if ($NotifyUsers -or $DoAll) {
            Send-UserNotification -CompromisedAccount $CompromisedAccount
        }
        
        # Unblock account if requested (typically done after securing it)
        if ($UnblockAccount) {
            Unblock-UserAccount -UserPrincipalName $CompromisedAccount
        }
    } else {
        Write-ResponseLog "Cannot proceed: Compromised account not found or accessible" -Level Error
    }
    
    # Disconnect from services
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        Disconnect-AzureAD -ErrorAction SilentlyContinue
        Write-ResponseLog "Disconnected from Microsoft 365 services" -Level Info
    } catch {
        Write-ResponseLog "Error disconnecting from services: $_" -Level Warning
    }
    
    # Summary
    Write-ResponseLog "`n======================================================" -Level Info
    Write-ResponseLog "EMERGENCY RESPONSE SUMMARY" -Level Info
    Write-ResponseLog "======================================================" -Level Info
    Write-ResponseLog "Compromised account: $CompromisedAccount" -Level Info
    Write-ResponseLog "Actions completed: $($CompromiseResponses.Count)" -Level Info
    
    $successCount = ($CompromiseResponses | Where-Object { $_.IsCompleted -eq $true }).Count
    $failCount = ($CompromiseResponses | Where-Object { $_.IsCompleted -eq $false }).Count
    
    Write-ResponseLog "Successful actions: $successCount" -Level Success
    Write-ResponseLog "Failed actions: $failCount" -Level $(if ($failCount -gt 0) { "Error" } else { "Success" })
    
    if ($failCount -gt 0) {
        Write-ResponseLog "`nFailed actions:" -Level Warning
        $CompromiseResponses | Where-Object { $_.IsCompleted -eq $false } | ForEach-Object {
            Write-ResponseLog "- $($_.Action): $($_.Result)" -Level Warning
        }
    }
    
    Write-ResponseLog "`nRecommended next steps:" -Level Info
    Write-ResponseLog "1. Continue monitoring the account for suspicious activities" -Level Info
    Write-ResponseLog "2. Conduct a full security review of the environment" -Level Info
    Write-ResponseLog "3. Provide security awareness training to all staff" -Level Info
    Write-ResponseLog "4. Review and update email security policies" -Level Info
    Write-ResponseLog "5. When ready to restore access, use: .\CEO-EmailCompromise-Response.ps1 -CompromisedAccount $CompromisedAccount -UnblockAccount" -Level Info
} else {
    Write-ResponseLog "Prerequisites check failed. Cannot continue." -Level Error
}
