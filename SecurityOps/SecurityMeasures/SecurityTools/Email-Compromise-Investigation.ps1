# Email-Compromise-Investigation.ps1
# Purpose: Investigate and remediate a compromised email account
# Author: GitHub Copilot
# Date: September 10, 2025

param(
    [Parameter(Mandatory=$false)]
    [string]$CompromisedAccount = "",
    
    [Parameter(Mandatory=$false)]
    [int]$DaysToInvestigate = 7,
    
    [Parameter(Mandatory=$false)]
    [switch]$ResetPassword,
    
    [Parameter(Mandatory=$false)]
    [switch]$BlockSuspiciousIPs,
    
    [Parameter(Mandatory=$false)]
    [switch]$RemoveSuspiciousRules,
    
    [Parameter(Mandatory=$false)]
    [switch]$RemoveSuspiciousForwarding,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\Reports"
)

# Initialize
$ErrorActionPreference = "Stop"
$InvestigationFindings = @()
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "$OutputPath\EmailCompromiseInvestigation_$timestamp.log"

# Function for logging
function Write-InvestigationLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Finding')]
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
        'Finding' { Write-Host $logMessage -ForegroundColor Cyan }
    }
    
    # Write to log file
    Add-Content -Path $logFile -Value $logMessage -Force
}

# Function to record investigation findings
function Add-InvestigationFinding {
    param(
        [string]$Category,
        [string]$Finding,
        [ValidateSet('Normal', 'Suspicious', 'Malicious')]
        [string]$Severity = 'Normal',
        [string]$Details,
        [DateTime]$Timestamp = (Get-Date)
    )
    
    $findingResult = [PSCustomObject]@{
        Category = $Category
        Finding = $Finding
        Severity = $Severity
        Details = $Details
        Timestamp = $Timestamp
    }
    
    $script:InvestigationFindings += $findingResult
    
    # Log to console
    $severityIcon = switch ($Severity) {
        'Normal' { "[OK]" }
        'Suspicious' { "[SUSPICIOUS]" }
        'Malicious' { "[MALICIOUS]" }
    }
    
    $logLevel = switch ($Severity) {
        'Normal' { "Success" }
        'Suspicious' { "Warning" }
        'Malicious' { "Error" }
    }
    
    Write-InvestigationLog "$severityIcon $Category - $Finding" -Level $logLevel
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-InvestigationLog "Checking prerequisites and required modules..."
    $requiredModules = @(
        "ExchangeOnlineManagement",
        "AzureAD",
        "MSOnline"
    )
    
    $allModulesPresent = $true
    
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-InvestigationLog "Required module not found: $module" -Level Error
            Write-InvestigationLog "Please install it with: Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser" -Level Warning
            $allModulesPresent = $false
        } else {
            Write-InvestigationLog "Module $module is available" -Level Success
        }
    }
    
    if (!$allModulesPresent) {
        Write-InvestigationLog "Missing required modules. Please install them and try again." -Level Error
        return $false
    }
    
    # Check if output directory exists
    if (!(Test-Path $OutputPath)) {
        try {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            Write-InvestigationLog "Created output directory: $OutputPath" -Level Success
        } catch {
            Write-InvestigationLog "Could not create output directory: $_" -Level Error
            return $false
        }
    }
    
    # Check connections
    try {
        Write-InvestigationLog "Connecting to required services..." -Level Info
        
        # Connect to Exchange Online
        Connect-ExchangeOnline -ErrorAction Stop | Out-Null
        Write-InvestigationLog "Connected to Exchange Online" -Level Success
        
        # Connect to Azure AD
        Connect-AzureAD -ErrorAction Stop | Out-Null
        Write-InvestigationLog "Connected to Azure AD" -Level Success
        
        # Try to connect to MSOL
        try {
            Connect-MsolService -ErrorAction Stop | Out-Null
            Write-InvestigationLog "Connected to Microsoft Online Services" -Level Success
        } catch {
            Write-InvestigationLog "Could not connect to MSOnline Service: $_" -Level Warning
            Write-InvestigationLog "Some functions may be limited" -Level Warning
        }
        
        return $true
    } catch {
        Write-InvestigationLog "Failed to connect to required services: $_" -Level Error
        return $false
    }
}

# Function to verify user account
function Verify-UserAccount {
    param(
        [string]$UserPrincipalName
    )
    
    Write-InvestigationLog "Verifying account $UserPrincipalName..." -Level Info
    
    try {
        # Check if account exists
        $user = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop
        
        if ($user) {
            Write-InvestigationLog "Account $UserPrincipalName found: $($user.DisplayName)" -Level Success
            
            # Record basic account info
            Add-InvestigationFinding -Category "Account Info" `
                                    -Finding "Basic Account Details" `
                                    -Severity "Normal" `
                                    -Details "Display Name: $($user.DisplayName)`nDepartment: $($user.Department)`nTitle: $($user.Title)`nLast Password Change: $($user.LastPasswordChangeTimestamp)`nAccount Created: $($user.WhenCreated)`nBlocked: $($user.BlockCredential)"
            
            return $user
        } else {
            Write-InvestigationLog "Account $UserPrincipalName not found!" -Level Error
            return $null
        }
    } catch {
        Write-InvestigationLog "Error verifying account: $_" -Level Error
        return $null
    }
}

# Function to investigate login activity
function Investigate-LoginActivity {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack = 7
    )
    
    Write-InvestigationLog "Investigating login activity for $UserPrincipalName over the past $DaysToLookBack days..." -Level Info
    
    try {
        # Define start date
        $startDate = (Get-Date).AddDays(-$DaysToLookBack)
        
        # Get sign-in activity
        $signIns = Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$UserPrincipalName'" -Top 1000 | 
                   Where-Object { $_.CreatedDateTime -ge $startDate }
        
        if ($signIns -and $signIns.Count -gt 0) {
            # Group by location and count
            $locationGroups = $signIns | Group-Object Location | Select-Object Name, Count
            
            # Group by IP and count
            $ipGroups = $signIns | Group-Object IpAddress | Select-Object Name, Count
            
            # Group by client app
            $appGroups = $signIns | Group-Object ClientAppUsed | Select-Object Name, Count
            
            # Get successful vs failed sign-ins
            $successfulSignIns = $signIns | Where-Object { $_.Status.ErrorCode -eq 0 } 
            $failedSignIns = $signIns | Where-Object { $_.Status.ErrorCode -ne 0 }
            
            # Check for suspicious patterns
            $suspiciousPatterns = @{
                MultipleCountries = ($locationGroups.Count -gt 1)
                FailedAttempts = ($failedSignIns.Count -gt 5)
                UnusualApps = ($signIns | Where-Object { $_.ClientAppUsed -notin @('Mobile Apps and Desktop clients', 'Browser', 'Exchange ActiveSync') }).Count -gt 0
                OddHours = ($signIns | Where-Object { $_.CreatedDateTime.Hour -ge 22 -or $_.CreatedDateTime.Hour -le 5 }).Count -gt 0
            }
            
            $suspiciousCount = ($suspiciousPatterns.Values | Where-Object { $_ -eq $true }).Count
            
            # Record findings
            $severity = "Normal"
            if ($suspiciousCount -ge 3) {
                $severity = "Malicious"
            } elseif ($suspiciousCount -ge 1) {
                $severity = "Suspicious"
            }
            
            $details = "Total sign-ins: $($signIns.Count)`nSuccessful sign-ins: $($successfulSignIns.Count)`nFailed sign-ins: $($failedSignIns.Count)`n`n"
            
            $details += "Sign-ins by location:`n"
            foreach ($loc in $locationGroups) {
                $details += "  * $($loc.Name) - $($loc.Count) sign-ins`n"
            }
            
            $details += "`nSign-ins by IP address:`n"
            foreach ($ip in $ipGroups) {
                $details += "  * $($ip.Name) - $($ip.Count) sign-ins`n"
            }
            
            $details += "`nSign-ins by application:`n"
            foreach ($app in $appGroups) {
                $details += "  * $($app.Name) - $($app.Count) sign-ins`n"
            }
            
            $details += "`nSuspicious patterns detected:`n"
            foreach ($pattern in $suspiciousPatterns.Keys) {
                $value = $suspiciousPatterns[$pattern]
                $details += "  * $pattern`: $value`n"
            }
            
            Add-InvestigationFinding -Category "Login Activity" `
                                    -Finding "Sign-in patterns analyzed" `
                                    -Severity $severity `
                                    -Details $details
            
            # Export sign-in data
            $signInExportPath = "$OutputPath\SignIns_$($UserPrincipalName.Split('@')[0])_$timestamp.csv"
            $signIns | Select-Object CreatedDateTime, UserPrincipalName, IpAddress, Location, ClientAppUsed, DeviceDetail, Status | Export-Csv -Path $signInExportPath -NoTypeInformation
            Write-InvestigationLog "Sign-in data exported to $signInExportPath" -Level Success
            
            # Return the sign-in logs for further processing
            return $signIns
        } else {
            Add-InvestigationFinding -Category "Login Activity" `
                                    -Finding "No recent sign-ins" `
                                    -Severity "Suspicious" `
                                    -Details "No sign-in activity found for the past $DaysToLookBack days"
            
            return $null
        }
    } catch {
        Write-InvestigationLog "Error investigating login activity: $_" -Level Error
        Add-InvestigationFinding -Category "Login Activity" `
                                -Finding "Error analyzing sign-ins" `
                                -Severity "Normal" `
                                -Details "Error: $_"
        return $null
    }
}

# Function to investigate inbox rules
function Investigate-InboxRules {
    param(
        [string]$UserPrincipalName
    )
    
    Write-InvestigationLog "Investigating inbox rules for $UserPrincipalName..." -Level Info
    
    try {
        # Get inbox rules
        $inboxRules = Get-InboxRule -Mailbox $UserPrincipalName
        
        if ($inboxRules -and $inboxRules.Count -gt 0) {
            $severity = "Normal"
            $details = "Total rules: $($inboxRules.Count)`n`n"
            
            # Suspicious patterns to look for
            $suspiciousRules = @()
            $normalRules = @()
            
            foreach ($rule in $inboxRules) {
                $isRuleSuspicious = $false
                $ruleDetails = "Rule: $($rule.Name)`n"
                $ruleDetails += "  * Enabled: $($rule.Enabled)`n"
                
                if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo -or $rule.RedirectTo) {
                    $isRuleSuspicious = $true
                    $ruleDetails += "  * [SUSPICIOUS] Forwarding: "
                    
                    if ($rule.ForwardTo) { $ruleDetails += "Forward to: $($rule.ForwardTo)" }
                    if ($rule.ForwardAsAttachmentTo) { $ruleDetails += "Forward as attachment to: $($rule.ForwardAsAttachmentTo)" }
                    if ($rule.RedirectTo) { $ruleDetails += "Redirect to: $($rule.RedirectTo)" }
                    
                    $ruleDetails += "`n"
                }
                
                if ($rule.DeleteMessage -eq $true) {
                    $isRuleSuspicious = $true
                    $ruleDetails += "  * [SUSPICIOUS] Automatically deletes messages`n"
                }
                
                if ($rule.MoveToFolder -eq "Deleted Items" -or $rule.MoveToFolder -eq "Junk Email") {
                    $isRuleSuspicious = $true
                    $ruleDetails += "  * [SUSPICIOUS] Moves messages to $($rule.MoveToFolder) folder`n"
                }
                
                $details += "$ruleDetails`n"
                
                if ($isRuleSuspicious) {
                    $suspiciousRules += $rule
                    $severity = "Suspicious"
                } else {
                    $normalRules += $rule
                }
            }
            
            if ($suspiciousRules.Count -gt 0) {
                $details = $details.TrimEnd("`n")
                $details += "`n`nPOTENTIALLY MALICIOUS: Found $($suspiciousRules.Count) suspicious inbox rules"
                
                if ($suspiciousRules.Count -gt 2) {
                    $severity = "Malicious"
                }
                
                # Option to remove suspicious rules
                if ($RemoveSuspiciousRules) {
                    Write-InvestigationLog "Removing suspicious inbox rules..." -Level Warning
                    foreach ($rule in $suspiciousRules) {
                        try {
                            Remove-InboxRule -Identity $rule.Identity -Confirm:$false
                            Write-InvestigationLog "Removed rule: $($rule.Name)" -Level Success
                        } catch {
                            Write-InvestigationLog "Failed to remove rule $($rule.Name): $_" -Level Error
                        }
                    }
                }
            }
            
            # Export rules data
            $rulesExportPath = "$OutputPath\InboxRules_$($UserPrincipalName.Split('@')[0])_$timestamp.csv"
            $inboxRules | Export-Csv -Path $rulesExportPath -NoTypeInformation
            Write-InvestigationLog "Inbox rules exported to $rulesExportPath" -Level Success
            
            Add-InvestigationFinding -Category "Inbox Rules" `
                                    -Finding "Inbox rules analyzed" `
                                    -Severity $severity `
                                    -Details $details
        } else {
            Add-InvestigationFinding -Category "Inbox Rules" `
                                    -Finding "No inbox rules found" `
                                    -Severity "Normal" `
                                    -Details "No inbox rules configured for this mailbox"
        }
    } catch {
        Write-InvestigationLog "Error investigating inbox rules: $_" -Level Error
        Add-InvestigationFinding -Category "Inbox Rules" `
                                -Finding "Error analyzing inbox rules" `
                                -Severity "Normal" `
                                -Details "Error: $_"
    }
}

# Function to investigate email forwarding
function Investigate-EmailForwarding {
    param(
        [string]$UserPrincipalName
    )
    
    Write-InvestigationLog "Investigating email forwarding for $UserPrincipalName..." -Level Info
    
    try {
        # Check mailbox forwarding settings
        $mailbox = Get-Mailbox -Identity $UserPrincipalName
        
        $severity = "Normal"
        $details = ""
        
        if ($mailbox.ForwardingAddress -or $mailbox.ForwardingSmtpAddress -or $mailbox.DeliverToMailboxAndForward) {
            $severity = "Suspicious"
            $details = "Email forwarding is configured:`n"
            
            if ($mailbox.ForwardingAddress) {
                $details += "  * Internal forwarding to: $($mailbox.ForwardingAddress)`n"
            }
            
            if ($mailbox.ForwardingSmtpAddress) {
                $details += "  * External forwarding to: $($mailbox.ForwardingSmtpAddress.Replace('SMTP:', ''))`n"
                $severity = "Malicious"
            }
            
            $details += "  * Deliver to mailbox and forward: $($mailbox.DeliverToMailboxAndForward)`n"
            
            # Option to remove suspicious forwarding
            if ($RemoveSuspiciousForwarding -and ($mailbox.ForwardingAddress -or $mailbox.ForwardingSmtpAddress)) {
                Write-InvestigationLog "Removing email forwarding..." -Level Warning
                try {
                    Set-Mailbox -Identity $UserPrincipalName -ForwardingAddress $null -ForwardingSmtpAddress $null -DeliverToMailboxAndForward $false
                    Write-InvestigationLog "Email forwarding removed successfully" -Level Success
                    $details += "`nFORWARDING REMOVED: Email forwarding has been disabled"
                } catch {
                    Write-InvestigationLog "Failed to remove email forwarding: $_" -Level Error
                    $details += "`nERROR: Failed to remove email forwarding: $_"
                }
            }
        } else {
            $details = "No email forwarding configured on this mailbox"
        }
        
        Add-InvestigationFinding -Category "Email Forwarding" `
                                -Finding "Mailbox forwarding settings" `
                                -Severity $severity `
                                -Details $details
    } catch {
        Write-InvestigationLog "Error investigating email forwarding: $_" -Level Error
        Add-InvestigationFinding -Category "Email Forwarding" `
                                -Finding "Error analyzing forwarding settings" `
                                -Severity "Normal" `
                                -Details "Error: $_"
    }
}

# Function to investigate sent items
function Investigate-SentItems {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack = 7
    )
    
    Write-InvestigationLog "Investigating sent emails for $UserPrincipalName over the past $DaysToLookBack days..." -Level Info
    
    try {
        # Calculate date range
        $startDate = (Get-Date).AddDays(-$DaysToLookBack).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $endDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        # Search for sent emails
        $sentItems = Search-Mailbox -Identity $UserPrincipalName -SearchQuery "sent>=$startDate AND sent<=$endDate" -EstimateResultOnly
        
        if ($sentItems -and $sentItems.ResultItemsCount -gt 0) {
            Write-InvestigationLog "Found $($sentItems.ResultItemsCount) sent items in the past $DaysToLookBack days" -Level Info
            
            # Get sample of recent emails
            $recentEmails = Get-MessageTrace -SenderAddress $UserPrincipalName -StartDate (Get-Date).AddDays(-$DaysToLookBack) -EndDate (Get-Date) -PageSize 100
            
            if ($recentEmails -and $recentEmails.Count -gt 0) {
                # Group by recipient domain
                $domainGroups = $recentEmails | Group-Object { ($_.RecipientAddress -split '@')[1] } | Select-Object Name, Count
                
                # Look for bulk emails
                $bulkEmails = $recentEmails | Where-Object { $_.RecipientCount -gt 10 }
                
                # Look for emails with attachments
                $attachmentEmails = $recentEmails | Where-Object { $_.HasAttachments -eq $true }
                
                # Analyze for suspicious patterns
                $suspiciousPatterns = @{
                    HighVolume = ($recentEmails.Count -gt 50)
                    BulkEmails = ($bulkEmails.Count -gt 5)
                    ManyAttachments = ($attachmentEmails.Count -gt 10)
                    ExternalDomains = ($domainGroups | Where-Object { $_.Name -ne ($UserPrincipalName -split '@')[1] }).Count -gt 5
                }
                
                $suspiciousCount = ($suspiciousPatterns.Values | Where-Object { $_ -eq $true }).Count
                
                # Determine severity
                $severity = "Normal"
                if ($suspiciousCount -ge 2) {
                    $severity = "Suspicious"
                }
                if ($suspiciousCount -ge 3) {
                    $severity = "Malicious"
                }
                
                # Prepare details
                $details = "Total sent emails: $($sentItems.ResultItemsCount)`nSample size analyzed: $($recentEmails.Count)`n`n"
                
                $details += "Emails by recipient domain:`n"
                foreach ($domain in $domainGroups) {
                    $details += "  * $($domain.Name) - $($domain.Count) emails`n"
                }
                
                $details += "`nBulk emails (>10 recipients): $($bulkEmails.Count)`n"
                $details += "Emails with attachments: $($attachmentEmails.Count)`n`n"
                
                $details += "Suspicious patterns detected:`n"
                foreach ($pattern in $suspiciousPatterns.Keys) {
                    $value = $suspiciousPatterns[$pattern]
                    $details += "  * $pattern`: $value`n"
                }
                
                # Export message trace data
                $messageTraceExportPath = "$OutputPath\SentEmails_$($UserPrincipalName.Split('@')[0])_$timestamp.csv"
                $recentEmails | Export-Csv -Path $messageTraceExportPath -NoTypeInformation
                Write-InvestigationLog "Message trace data exported to $messageTraceExportPath" -Level Success
                
                Add-InvestigationFinding -Category "Sent Emails" `
                                        -Finding "Sent email patterns analyzed" `
                                        -Severity $severity `
                                        -Details $details
            } else {
                Add-InvestigationFinding -Category "Sent Emails" `
                                        -Finding "No message trace data available" `
                                        -Severity "Normal" `
                                        -Details "Could not retrieve message trace data for detailed analysis."
            }
        } else {
            Add-InvestigationFinding -Category "Sent Emails" `
                                    -Finding "No recent sent emails" `
                                    -Severity "Normal" `
                                    -Details "No sent items found in the past $DaysToLookBack days"
        }
    } catch {
        Write-InvestigationLog "Error investigating sent emails: $_" -Level Error
        Add-InvestigationFinding -Category "Sent Emails" `
                                -Finding "Error analyzing sent emails" `
                                -Severity "Normal" `
                                -Details "Error: $_"
    }
}

# Function to investigate delegate permissions
function Investigate-DelegatePermissions {
    param(
        [string]$UserPrincipalName
    )
    
    Write-InvestigationLog "Investigating delegate permissions for $UserPrincipalName..." -Level Info
    
    try {
        # Get mailbox permissions
        $mailboxPermissions = Get-MailboxPermission -Identity $UserPrincipalName | Where-Object { $_.User -ne "NT AUTHORITY\SELF" -and $_.IsInherited -eq $false }
        
        # Get calendar permissions
        $calendarFolder = $UserPrincipalName + ":\Calendar"
        $calendarPermissions = Get-MailboxFolderPermission -Identity $calendarFolder -ErrorAction SilentlyContinue
        
        # Get send-as permissions
        $sendAsPermissions = Get-RecipientPermission -Identity $UserPrincipalName | Where-Object { $_.Trustee -ne "NT AUTHORITY\SELF" }
        
        # Get send-on-behalf permissions
        $mailbox = Get-Mailbox -Identity $UserPrincipalName
        $sendOnBehalfPermissions = $mailbox.GrantSendOnBehalfTo
        
        $severity = "Normal"
        $details = ""
        $suspiciousPermissions = 0
        
        if ($mailboxPermissions -and $mailboxPermissions.Count -gt 0) {
            $details += "Mailbox Permissions:`n"
            foreach ($perm in $mailboxPermissions) {
                $details += "  * $($perm.User) has $($perm.AccessRights -join ', ') access`n"
                
                # Full Access is potentially suspicious if recently added
                if ($perm.AccessRights -contains "FullAccess") {
                    $suspiciousPermissions++
                }
            }
            $details += "`n"
        } else {
            $details += "No explicit mailbox permissions found`n`n"
        }
        
        if ($sendAsPermissions -and $sendAsPermissions.Count -gt 0) {
            $details += "Send As Permissions:`n"
            foreach ($perm in $sendAsPermissions) {
                $details += "  * $($perm.Trustee) has $($perm.AccessRights -join ', ') access`n"
                $suspiciousPermissions++
            }
            $details += "`n"
        } else {
            $details += "No Send As permissions found`n`n"
        }
        
        if ($sendOnBehalfPermissions -and $sendOnBehalfPermissions.Count -gt 0) {
            $details += "Send on Behalf Permissions:`n"
            foreach ($user in $sendOnBehalfPermissions) {
                $details += "  * $user can send on behalf of this mailbox`n"
                $suspiciousPermissions++
            }
            $details += "`n"
        } else {
            $details += "No Send on Behalf permissions found`n`n"
        }
        
        if ($calendarPermissions -and $calendarPermissions.Count -gt 0) {
            $details += "Calendar Permissions:`n"
            foreach ($perm in $calendarPermissions | Where-Object { $_.User.ToString() -ne "Default" -and $_.User.ToString() -ne "Anonymous" }) {
                $details += "  * $($perm.User) has $($perm.AccessRights) access`n"
            }
        } else {
            $details += "No calendar permissions found or could not access calendar`n"
        }
        
        # Set severity based on suspicious permissions
        if ($suspiciousPermissions -gt 2) {
            $severity = "Malicious"
        } elseif ($suspiciousPermissions -gt 0) {
            $severity = "Suspicious"
        }
        
        Add-InvestigationFinding -Category "Delegate Permissions" `
                                -Finding "Mailbox delegation analyzed" `
                                -Severity $severity `
                                -Details $details
    } catch {
        Write-InvestigationLog "Error investigating delegate permissions: $_" -Level Error
        Add-InvestigationFinding -Category "Delegate Permissions" `
                                -Finding "Error analyzing delegate permissions" `
                                -Severity "Normal" `
                                -Details "Error: $_"
    }
}

# Function to reset user password
function Reset-UserPassword {
    param(
        [string]$UserPrincipalName
    )
    
    Write-InvestigationLog "Resetting password for $UserPrincipalName..." -Level Info
    
    try {
        # Generate a strong password
        Add-Type -AssemblyName System.Web
        $length = 16
        $nonAlphaChars = 5
        $password = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)
        
        # Reset the password and force change at next login
        Set-MsolUserPassword -UserPrincipalName $UserPrincipalName -NewPassword $password -ForceChangePassword $true
        
        Add-InvestigationFinding -Category "Remediation" `
                               -Finding "Password reset" `
                               -Severity "Normal" `
                               -Details "Password was reset successfully. User will be forced to change password at next login."
        
        Write-InvestigationLog "Temporary password: $password" -Level Warning
        Write-InvestigationLog "IMPORTANT: Securely communicate this password to the user" -Level Warning
        
        return $password
    } catch {
        Write-InvestigationLog "Error resetting password: $_" -Level Error
        Add-InvestigationFinding -Category "Remediation" `
                               -Finding "Password reset failed" `
                               -Severity "Suspicious" `
                               -Details "Error: $_"
        
        return $null
    }
}

# Function to block suspicious IPs
function Block-SuspiciousIPs {
    param(
        [string]$UserPrincipalName,
        [array]$SignIns
    )
    
    Write-InvestigationLog "Identifying suspicious IPs to block..." -Level Info
    
    try {
        if (!$SignIns -or $SignIns.Count -eq 0) {
            Write-InvestigationLog "No sign-in data available to identify suspicious IPs" -Level Warning
            return $false
        }
        
        # Group by IP and count
        $ipGroups = $SignIns | Group-Object IpAddress | Sort-Object Count
        
        # Get the least common IPs (potentially suspicious)
        $suspiciousIPs = $ipGroups | Where-Object { $_.Count -le 2 } | Select-Object -ExpandProperty Name
        
        if ($suspiciousIPs -and $suspiciousIPs.Count -gt 0) {
            Write-InvestigationLog "Identified $($suspiciousIPs.Count) potentially suspicious IPs" -Level Info
            
            if ($BlockSuspiciousIPs) {
                $ipList = $suspiciousIPs -join ", "
                
                # Note: In a real scenario, you would use Conditional Access policies
                # or Microsoft Defender for Cloud Apps to block these IPs
                
                Add-InvestigationFinding -Category "Remediation" `
                                       -Finding "Suspicious IPs identified" `
                                       -Severity "Normal" `
                                       -Details "The following IPs should be blocked through Conditional Access policies or added as named locations in Azure AD:`n$ipList"
                
                Write-InvestigationLog "To block these IPs, go to Azure AD > Security > Named locations and add these IPs as blocked named locations" -Level Warning
            } else {
                $ipList = $suspiciousIPs -join ", "
                Add-InvestigationFinding -Category "Suspicious IPs" `
                                       -Finding "Potentially suspicious IPs identified" `
                                       -Severity "Suspicious" `
                                       -Details "The following IPs had unusual access patterns:`n$ipList"
            }
            
            return $true
        } else {
            Write-InvestigationLog "No suspicious IPs identified" -Level Success
            return $false
        }
    } catch {
        Write-InvestigationLog "Error identifying suspicious IPs: $_" -Level Error
        return $false
    }
}

# Function to generate investigation report
function Generate-InvestigationReport {
    param(
        [string]$UserPrincipalName
    )
    
    Write-InvestigationLog "Generating investigation report for $UserPrincipalName..." -Level Info
    
    # Count findings by severity
    $normalCount = ($InvestigationFindings | Where-Object { $_.Severity -eq "Normal" }).Count
    $suspiciousCount = ($InvestigationFindings | Where-Object { $_.Severity -eq "Suspicious" }).Count
    $maliciousCount = ($InvestigationFindings | Where-Object { $_.Severity -eq "Malicious" }).Count
    
    # Determine overall risk level
    $overallRisk = "Low"
    if ($maliciousCount -gt 0) {
        $overallRisk = "Critical"
    } elseif ($suspiciousCount -gt 2) {
        $overallRisk = "High"
    } elseif ($suspiciousCount -gt 0) {
        $overallRisk = "Medium"
    }
    
    # Generate HTML report
    $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Email Compromise Investigation Report - $UserPrincipalName</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0066cc; }
        h2 { color: #0066cc; margin-top: 20px; border-bottom: 1px solid #ccc; padding-bottom: 5px; }
        .summary { background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 15px 0; }
        .finding { margin: 10px 0; padding: 10px; border-radius: 5px; }
        .normal { background-color: #e8f4f8; border-left: 5px solid #5bc0de; }
        .suspicious { background-color: #fff8e1; border-left: 5px solid #ffb300; }
        .malicious { background-color: #ffebee; border-left: 5px solid #f44336; }
        .finding-header { font-weight: bold; margin-bottom: 5px; }
        .finding-details { white-space: pre-wrap; font-family: Consolas, monospace; font-size: 0.9em; }
        .risk-low { background-color: #dff0d8; padding: 5px 10px; border-radius: 3px; }
        .risk-medium { background-color: #fcf8e3; padding: 5px 10px; border-radius: 3px; }
        .risk-high { background-color: #f2dede; padding: 5px 10px; border-radius: 3px; }
        .risk-critical { background-color: #f44336; color: white; padding: 5px 10px; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>Email Compromise Investigation Report</h1>
    <div class="summary">
        <p><strong>Account:</strong> $UserPrincipalName</p>
        <p><strong>Investigation Date:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Overall Risk Assessment:</strong> 
            <span class="risk-$($overallRisk.ToLower())">$overallRisk</span>
        </p>
        <p><strong>Findings Summary:</strong> $($InvestigationFindings.Count) total findings ($normalCount normal, $suspiciousCount suspicious, $maliciousCount malicious)</p>
    </div>
    
    <h2>Executive Summary</h2>
    <div class="finding $($overallRisk.ToLower() -replace 'critical','malicious' -replace 'high|medium','suspicious' -replace 'low','normal')">
        <div class="finding-details">
"@

    # Generate executive summary based on risk level
    $executiveSummary = "Investigation of the account $UserPrincipalName reveals "
    
    switch ($overallRisk) {
        "Critical" {
            $executiveSummary += "strong evidence of compromise. Multiple malicious indicators were detected, including "
            $maliciousFindings = $InvestigationFindings | Where-Object { $_.Severity -eq "Malicious" }
            $executiveSummary += ($maliciousFindings | ForEach-Object { $_.Finding.ToLower() }) -join ", "
            $executiveSummary += ". Immediate action is required to secure this account and prevent further unauthorized access."
        }
        "High" {
            $executiveSummary += "significant suspicious activity that suggests potential compromise. Multiple suspicious indicators were detected, including "
            $suspiciousFindings = $InvestigationFindings | Where-Object { $_.Severity -eq "Suspicious" } | Select-Object -First 3
            $executiveSummary += ($suspiciousFindings | ForEach-Object { $_.Finding.ToLower() }) -join ", "
            $executiveSummary += ". Prompt action is recommended to secure this account."
        }
        "Medium" {
            $executiveSummary += "some suspicious activity that warrants attention. The investigation found "
            $suspiciousFindings = $InvestigationFindings | Where-Object { $_.Severity -eq "Suspicious" }
            $executiveSummary += ($suspiciousFindings | ForEach-Object { $_.Finding.ToLower() }) -join ", "
            $executiveSummary += ". Further monitoring and security measures are recommended."
        }
        "Low" {
            $executiveSummary += "no significant indicators of compromise. The account appears to be operating normally, with typical usage patterns and no suspicious configurations."
        }
    }
    
    $htmlExecutiveSummary = $executiveSummary + @"
        </div>
    </div>
    
    <h2>Detailed Findings</h2>
"@

    $htmlFindings = ""
    foreach ($finding in $InvestigationFindings | Sort-Object -Property Severity, Category) {
        $htmlFindings += @"
    <div class="finding $($finding.Severity.ToLower())">
        <div class="finding-header">[$($finding.Category)] $($finding.Finding) - $($finding.Severity)</div>
        <div class="finding-details">$($finding.Details)</div>
    </div>
"@
    }

    $htmlRecommendations = @"
    <h2>Recommended Actions</h2>
    <div class="finding normal">
        <div class="finding-details">
"@

    # Generate recommendations based on risk level
    switch ($overallRisk) {
        "Critical" {
            $htmlRecommendations += @"
1. IMMEDIATE: Reset the user's password and enable Multi-Factor Authentication
2. IMMEDIATE: Remove any suspicious inbox rules and email forwarding
3. IMMEDIATE: Block suspicious IP addresses through Conditional Access policies
4. Review and revoke unnecessary delegate permissions on the mailbox
5. Scan the user's devices for malware and potential compromise
6. Monitor the account closely for at least 30 days for any recurring suspicious activity
7. Consider security awareness training for the user to prevent future compromises
8. Implement additional email security measures including advanced threat protection
"@
        }
        "High" {
            $htmlRecommendations += @"
1. Reset the user's password and enable Multi-Factor Authentication if not already enabled
2. Remove any suspicious inbox rules and email forwarding
3. Review delegate permissions and remove any that are unnecessary
4. Monitor the account closely for at least 14 days
5. Consider security awareness training for the user
6. Review and implement additional email security measures
"@
        }
        "Medium" {
            $htmlRecommendations += @"
1. Consider resetting the user's password as a precaution
2. Enable Multi-Factor Authentication if not already enabled
3. Review inbox rules and email forwarding settings
4. Monitor the account for at least 7 days for any suspicious activity
5. Provide security best practices guidance to the user
"@
        }
        "Low" {
            $htmlRecommendations += @"
1. No immediate actions required
2. Consider enabling Multi-Factor Authentication if not already enabled
3. Continue regular security monitoring
4. Ensure the user is aware of email security best practices
"@
        }
    }

    $htmlFooter = @"
        </div>
    </div>

    <p>Report generated by the Email Compromise Investigation Tool</p>
</body>
</html>
"@

    $htmlContent = $htmlHeader + $htmlExecutiveSummary + $htmlFindings + $htmlRecommendations + $htmlFooter
    
    # Save the report
    $reportFile = "$OutputPath\EmailCompromiseReport_$($UserPrincipalName.Split('@')[0])_$timestamp.html"
    $htmlContent | Out-File -FilePath $reportFile -Force
    
    Write-InvestigationLog "Investigation report generated: $reportFile" -Level Success
    
    # Also save a CSV version for reference
    $csvFile = "$OutputPath\EmailCompromiseFindings_$($UserPrincipalName.Split('@')[0])_$timestamp.csv"
    $InvestigationFindings | Export-Csv -Path $csvFile -NoTypeInformation
    
    Write-InvestigationLog "CSV data saved: $csvFile" -Level Success
    
    return @{
        ReportPath = $reportFile
        RiskLevel = $overallRisk
    }
}

# Main execution flow
Write-InvestigationLog "Email Compromise Investigation Tool" -Level Info
Write-InvestigationLog "Starting investigation on $(Get-Date)" -Level Info

# Ensure output directory exists
if (!(Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Prompt for account if not provided
if ([string]::IsNullOrEmpty($CompromisedAccount)) {
    $CompromisedAccount = Read-Host "Enter the email address to investigate"
}

# Check prerequisites
if (Test-Prerequisites) {
    # Verify the user account
    $user = Verify-UserAccount -UserPrincipalName $CompromisedAccount
    
    if ($user) {
        # Run investigation components
        $signIns = Investigate-LoginActivity -UserPrincipalName $CompromisedAccount -DaysToLookBack $DaysToInvestigate
        Investigate-InboxRules -UserPrincipalName $CompromisedAccount
        Investigate-EmailForwarding -UserPrincipalName $CompromisedAccount
        Investigate-SentItems -UserPrincipalName $CompromisedAccount -DaysToLookBack $DaysToInvestigate
        Investigate-DelegatePermissions -UserPrincipalName $CompromisedAccount
        
        # Remediation actions
        if ($ResetPassword) {
            Reset-UserPassword -UserPrincipalName $CompromisedAccount
        }
        
        if ($BlockSuspiciousIPs) {
            Block-SuspiciousIPs -UserPrincipalName $CompromisedAccount -SignIns $signIns
        }
        
        # Generate the investigation report
        $reportResult = Generate-InvestigationReport -UserPrincipalName $CompromisedAccount
        
        Write-InvestigationLog "`n======================================================" -Level Info
        Write-InvestigationLog "INVESTIGATION SUMMARY" -Level Info
        Write-InvestigationLog "======================================================" -Level Info
        Write-InvestigationLog "Account: $CompromisedAccount" -Level Info
        Write-InvestigationLog "Risk Level: $($reportResult.RiskLevel)" -Level Info
        
        # Provide summary based on risk level
        switch ($reportResult.RiskLevel) {
            "Critical" {
                Write-InvestigationLog "HIGH RISK: Account shows strong indicators of compromise!" -Level Error
                Write-InvestigationLog "Recommended actions:" -Level Warning
                Write-InvestigationLog "1. Reset the user's password immediately" -Level Warning
                Write-InvestigationLog "2. Enable MFA if not already enabled" -Level Warning
                Write-InvestigationLog "3. Remove suspicious inbox rules and email forwarding" -Level Warning
                Write-InvestigationLog "4. Block suspicious IPs through Conditional Access policies" -Level Warning
                Write-InvestigationLog "5. Investigate the user's device for malware" -Level Warning
            }
            "High" {
                Write-InvestigationLog "MEDIUM-HIGH RISK: Account shows multiple suspicious activities" -Level Warning
                Write-InvestigationLog "Recommended actions:" -Level Warning
                Write-InvestigationLog "1. Reset the user's password" -Level Warning
                Write-InvestigationLog "2. Enable MFA if not already enabled" -Level Warning
                Write-InvestigationLog "3. Review and remove suspicious inbox rules and forwarding" -Level Warning
                Write-InvestigationLog "4. Monitor the account closely" -Level Warning
            }
            "Medium" {
                Write-InvestigationLog "MEDIUM RISK: Account shows some suspicious activity" -Level Warning
                Write-InvestigationLog "Recommended actions:" -Level Warning
                Write-InvestigationLog "1. Consider resetting the user's password" -Level Warning
                Write-InvestigationLog "2. Enable MFA if not already enabled" -Level Warning
                Write-InvestigationLog "3. Monitor the account for additional suspicious activity" -Level Warning
            }
            "Low" {
                Write-InvestigationLog "LOW RISK: No significant indicators of compromise" -Level Success
                Write-InvestigationLog "Recommended actions:" -Level Info
                Write-InvestigationLog "1. Enable MFA if not already enabled" -Level Info
                Write-InvestigationLog "2. Continue regular security monitoring" -Level Info
            }
        }
        
        Write-InvestigationLog "`nDetailed report saved to: $($reportResult.ReportPath)" -Level Success
    } else {
        Write-InvestigationLog "Cannot proceed: User account not found or accessible" -Level Error
    }
    
    # Disconnect from services
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        Disconnect-AzureAD -ErrorAction SilentlyContinue
        Write-InvestigationLog "Disconnected from Microsoft 365 services" -Level Info
    } catch {
        Write-InvestigationLog "Error disconnecting from services: $_" -Level Warning
    }
} else {
    Write-InvestigationLog "Prerequisites check failed. Cannot continue." -Level Error
}
