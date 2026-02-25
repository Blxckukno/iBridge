# Email-SecurityDefender.ps1
# Comprehensive email security tool for Microsoft 365
# Purpose: Detect, investigate and remediate email security incidents including phishing, account compromise, and email-based attacks
# Author: Security Response Team
# Created: September 10, 2025

param(
    [Parameter(Mandatory=$false)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory=$false)]
    [switch]$AllUsers,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysToLookBack = 30,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDirectory = ".\SecurityReports",
    
    [Parameter(Mandatory=$false)]
    [switch]$PerformRemediation,
    
    [Parameter(Mandatory=$false)]
    [switch]$ImplementHardening,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckPermissions
)

# Initialize environment
$ErrorActionPreference = "Continue"
$startTime = Get-Date
$reportDate = Get-Date -Format "yyyyMMdd_HHmmss"
$outputLog = "$OutputDirectory\EmailSecurity_Report_$reportDate.log"
$outputCsv = "$OutputDirectory\EmailSecurity_Findings_$reportDate.csv"
$outputRisks = "$OutputDirectory\EmailSecurity_Risks_$reportDate.csv"
$global:findings = @()
$global:securityRisks = @()

# Ensure output directory exists
if (!(Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

# Function for consistent logging
function Write-SecurityLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info',
        [switch]$NoNewLine
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with color based on level
    switch ($Level) {
        'Info' { $color = 'White' }
        'Warning' { $color = 'Yellow' }
        'Error' { $color = 'Red' }
        'Success' { $color = 'Green' }
    }
    
    if ($NoNewLine) {
        Write-Host $logMessage -ForegroundColor $color -NoNewline
    } else {
        Write-Host $logMessage -ForegroundColor $color
    }
    
    # Write to log file
    Add-Content -Path $outputLog -Value $logMessage
}

# Function to record a security finding
function Add-SecurityFinding {
    param(
        [string]$Category,
        [string]$UserAffected,
        [string]$Description,
        [ValidateSet('Low', 'Medium', 'High', 'Critical')]
        [string]$Severity = 'Medium',
        [string]$RecommendedAction,
        [hashtable]$AdditionalInfo = @{}
    )
    
    $finding = [PSCustomObject]@{
        Timestamp = Get-Date
        Category = $Category
        UserAffected = $UserAffected
        Description = $Description
        Severity = $Severity
        RecommendedAction = $RecommendedAction
    }
    
    # Add any additional properties
    foreach ($key in $AdditionalInfo.Keys) {
        Add-Member -InputObject $finding -MemberType NoteProperty -Name $key -Value $AdditionalInfo[$key]
    }
    
    $global:findings += $finding
    
    $severityColor = switch ($Severity) {
        'Low' { 'Cyan' }
        'Medium' { 'Yellow' }
        'High' { 'Red' }
        'Critical' { 'Red' }
    }
    
    Write-SecurityLog "FINDING: [$Category] $Description" -Level $(if ($Severity -eq 'Critical' -or $Severity -eq 'High') { 'Error' } elseif ($Severity -eq 'Medium') { 'Warning' } else { 'Info' })
    Write-SecurityLog "  Affected: $UserAffected" -Level $(if ($Severity -eq 'Critical' -or $Severity -eq 'High') { 'Error' } elseif ($Severity -eq 'Medium') { 'Warning' } else { 'Info' })
    Write-SecurityLog "  Severity: $Severity" -Level $(if ($Severity -eq 'Critical' -or $Severity -eq 'High') { 'Error' } elseif ($Severity -eq 'Medium') { 'Warning' } else { 'Info' })
    Write-SecurityLog "  Action: $RecommendedAction" -Level $(if ($Severity -eq 'Critical' -or $Severity -eq 'High') { 'Error' } elseif ($Severity -eq 'Medium') { 'Warning' } else { 'Info' })
}

# Function to record a security risk (tenant-wide setting or configuration)
function Add-SecurityRisk {
    param(
        [string]$Category,
        [string]$Description,
        [ValidateSet('Low', 'Medium', 'High', 'Critical')]
        [string]$Severity = 'Medium',
        [string]$RecommendedAction,
        [string]$CurrentState,
        [string]$RecommendedState,
        [bool]$CanRemediate = $false
    )
    
    $risk = [PSCustomObject]@{
        Timestamp = Get-Date
        Category = $Category
        Description = $Description
        Severity = $Severity
        RecommendedAction = $RecommendedAction
        CurrentState = $CurrentState
        RecommendedState = $RecommendedState
        CanRemediate = $CanRemediate
    }
    
    $global:securityRisks += $risk
    
    $severityColor = switch ($Severity) {
        'Low' { 'Cyan' }
        'Medium' { 'Yellow' }
        'High' { 'Red' }
        'Critical' { 'Red' }
    }
    
    Write-SecurityLog "RISK: [$Category] $Description" -Level $(if ($Severity -eq 'Critical' -or $Severity -eq 'High') { 'Error' } elseif ($Severity -eq 'Medium') { 'Warning' } else { 'Info' })
    Write-SecurityLog "  Severity: $Severity" -Level $(if ($Severity -eq 'Critical' -or $Severity -eq 'High') { 'Error' } elseif ($Severity -eq 'Medium') { 'Warning' } else { 'Info' })
    Write-SecurityLog "  Current: $CurrentState" -Level $(if ($Severity -eq 'Critical' -or $Severity -eq 'High') { 'Error' } elseif ($Severity -eq 'Medium') { 'Warning' } else { 'Info' })
    Write-SecurityLog "  Recommended: $RecommendedState" -Level $(if ($Severity -eq 'Critical' -or $Severity -eq 'High') { 'Error' } elseif ($Severity -eq 'Medium') { 'Warning' } else { 'Info' })
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-SecurityLog "Checking prerequisites and required modules..."
    
    $requiredModules = @(
        "ExchangeOnlineManagement",
        "AzureAD",
        "MSOnline"
    )
    
    $allModulesPresent = $true
    
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-SecurityLog "Required module not found: $module" -Level Error
            Write-SecurityLog "Please install it with: Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser" -Level Warning
            $allModulesPresent = $false
        } else {
            Write-SecurityLog "Module $module is available" -Level Success
        }
    }
    
    # Check if we're running as administrator or have sufficient permissions
    try {
        Write-SecurityLog "Checking account permissions..."
        Connect-AzureAD -ErrorAction Stop | Out-Null
        Write-SecurityLog "Successfully connected to Azure AD" -Level Success
        
        Write-SecurityLog "Connecting to Exchange Online..."
        Connect-ExchangeOnline -ErrorAction Stop | Out-Null
        Write-SecurityLog "Successfully connected to Exchange Online" -Level Success
        
        try {
            Connect-MsolService -ErrorAction Stop | Out-Null
            Write-SecurityLog "Successfully connected to MSOnline Service" -Level Success
        } catch {
            Write-SecurityLog "Could not connect to MSOnline Service: $_" -Level Warning
            Write-SecurityLog "Some functions may be limited" -Level Warning
        }
        
        if ($CheckPermissions) {
            Write-SecurityLog "Checking your administrative roles..."
            $roles = @("Global Administrator", "Exchange Administrator", "SharePoint Administrator", "Teams Administrator", "User Administrator", "Security Administrator", "Compliance Administrator")
            $foundRoles = @()
            
            foreach ($roleName in $roles) {
                $role = Get-AzureADDirectoryRole | Where-Object {$_.DisplayName -eq $roleName}
                if ($role) {
                    $members = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId
                    $currentUser = (Get-AzureADCurrentSessionInfo).Account
                    if ($members | Where-Object {$_.UserPrincipalName -eq $currentUser}) {
                        $foundRoles += $roleName
                        Write-SecurityLog "You have the '$roleName' role" -Level Success
                    }
                }
            }
            
            if ($foundRoles.Count -eq 0) {
                Write-SecurityLog "You don't appear to have any administrative roles. Some functions may be limited." -Level Warning
            }
        }
        
        return $true
    } catch {
        Write-SecurityLog "Failed to establish required connections: $_" -Level Error
        Write-SecurityLog "Please make sure you have sufficient permissions and retry." -Level Error
        return $false
    }
}

# Function to check for suspicious inbox rules
function Test-SuspiciousInboxRules {
    param(
        [string]$UserPrincipalName
    )
    
    Write-SecurityLog "Checking inbox rules for $UserPrincipalName..."
    
    try {
        # Try to get inbox rules using EXO cmdlets
        try {
            $inboxRules = Get-InboxRule -Mailbox $UserPrincipalName -ErrorAction Stop
        } catch {
            Write-SecurityLog "Could not retrieve inbox rules using Get-InboxRule. Trying alternative method..." -Level Warning
            
            # Try alternative method with REST API if available
            $inboxRules = $null
        }
        
        if ($inboxRules) {
            Write-SecurityLog "Found $($inboxRules.Count) inbox rules" -Level Info
            
            foreach ($rule in $inboxRules) {
                $suspicious = $false
                $reasons = @()
                
                # Check for suspicious forwarding
                if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo -or $rule.RedirectTo) {
                    $suspicious = $true
                    $forwardTargets = @()
                    if ($rule.ForwardTo) { $forwardTargets += $rule.ForwardTo }
                    if ($rule.ForwardAsAttachmentTo) { $forwardTargets += $rule.ForwardAsAttachmentTo }
                    if ($rule.RedirectTo) { $forwardTargets += $rule.RedirectTo }
                    
                    $reasons += "Email forwarding to: $($forwardTargets -join ', ')"
                }
                
                # Check for automatic deletion
                if ($rule.DeleteMessage -eq $true) {
                    $suspicious = $true
                    $reasons += "Auto-delete messages"
                }
                
                # Check for moving to less visible folders
                if ($rule.MoveToFolder -match "Deleted Items|Junk|RSS") {
                    $suspicious = $true
                    $reasons += "Move to $($rule.MoveToFolder)"
                }
                
                # Check for mark as read (to reduce visibility)
                if ($rule.MarkAsRead -eq $true) {
                    $suspicious = $true
                    $reasons += "Mark as read"
                }
                
                # Log suspicious rules
                if ($suspicious) {
                    $severity = if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo -or $rule.RedirectTo) { "High" } else { "Medium" }
                    
                    Add-SecurityFinding -Category "SuspiciousInboxRule" `
                                       -UserAffected $UserPrincipalName `
                                       -Description "Suspicious inbox rule: '$($rule.Name)'" `
                                       -Severity $severity `
                                       -RecommendedAction "Review and remove this rule if not authorized" `
                                       -AdditionalInfo @{
                                           RuleName = $rule.Name
                                           RuleId = $rule.Identity
                                           SuspiciousActions = ($reasons -join "; ")
                                           Enabled = $rule.Enabled
                                       }
                }
            }
        } else {
            Write-SecurityLog "No inbox rules found or could not access inbox rules" -Level Warning
        }
    } catch {
        Write-SecurityLog "Error checking inbox rules: $_" -Level Error
    }
}

# Function to check for suspicious mailbox forwarding
function Test-MailboxForwarding {
    param(
        [string]$UserPrincipalName
    )
    
    Write-SecurityLog "Checking mailbox forwarding settings for $UserPrincipalName..."
    
    try {
        $mailbox = Get-Mailbox -Identity $UserPrincipalName -ErrorAction Stop
        
        if ($mailbox.ForwardingSmtpAddress -or $mailbox.ForwardingAddress) {
            $forwardTo = if ($mailbox.ForwardingSmtpAddress) { $mailbox.ForwardingSmtpAddress } else { $mailbox.ForwardingAddress }
            
            Add-SecurityFinding -Category "MailboxForwarding" `
                               -UserAffected $UserPrincipalName `
                               -Description "Mailbox has forwarding enabled" `
                               -Severity "High" `
                               -RecommendedAction "Verify if this forwarding is authorized; remove if suspicious" `
                               -AdditionalInfo @{
                                   ForwardingTarget = $forwardTo
                                   DeliverToMailboxAlso = $mailbox.DeliverToMailboxAndForward
                               }
        }
    } catch {
        Write-SecurityLog "Error checking mailbox forwarding: $_" -Level Error
    }
}

# Function to check for suspicious mailbox delegates
function Test-MailboxDelegates {
    param(
        [string]$UserPrincipalName
    )
    
    Write-SecurityLog "Checking mailbox delegates for $UserPrincipalName..."
    
    try {
        # Try to get mailbox permissions
        try {
            $delegatePermissions = Get-MailboxPermission -Identity $UserPrincipalName | Where-Object { 
                $_.IsInherited -eq $false -and 
                $_.User -ne "NT AUTHORITY\SELF" -and 
                $_.User -notlike "S-1-5-*" 
            }
        } catch {
            Write-SecurityLog "Could not retrieve mailbox permissions using Get-MailboxPermission. Limited permissions or module issues." -Level Warning
            $delegatePermissions = $null
        }
        
        if ($delegatePermissions) {
            foreach ($perm in $delegatePermissions) {
                Add-SecurityFinding -Category "MailboxDelegate" `
                                   -UserAffected $UserPrincipalName `
                                   -Description "Account has delegate '$($perm.User)' with '$($perm.AccessRights -join ", ")' permissions" `
                                   -Severity "Medium" `
                                   -RecommendedAction "Verify if this delegation is authorized; remove if suspicious" `
                                   -AdditionalInfo @{
                                       DelegateUser = $perm.User
                                       AccessRights = ($perm.AccessRights -join ", ")
                                       Deny = $perm.Deny
                                   }
            }
        }
        
        # Try to get send-as permissions
        try {
            $sendAsPermissions = Get-RecipientPermission -Identity $UserPrincipalName | Where-Object { 
                $_.Trustee -ne "NT AUTHORITY\SELF" -and 
                $_.Trustee -notlike "S-1-5-*" 
            }
        } catch {
            Write-SecurityLog "Could not retrieve send-as permissions using Get-RecipientPermission. Limited permissions or module issues." -Level Warning
            $sendAsPermissions = $null
        }
        
        if ($sendAsPermissions) {
            foreach ($perm in $sendAsPermissions) {
                Add-SecurityFinding -Category "SendAsPermission" `
                                   -UserAffected $UserPrincipalName `
                                   -Description "Account has send-as permission granted to '$($perm.Trustee)'" `
                                   -Severity "High" `
                                   -RecommendedAction "Verify if this permission is authorized; remove if suspicious" `
                                   -AdditionalInfo @{
                                       Trustee = $perm.Trustee
                                       AccessRights = ($perm.AccessRights -join ", ")
                                   }
            }
        }
    } catch {
        Write-SecurityLog "Error checking mailbox delegates: $_" -Level Error
    }
}

# Function to check MFA status
function Test-MFAStatus {
    param(
        [string]$UserPrincipalName
    )
    
    Write-SecurityLog "Checking MFA status for $UserPrincipalName..."
    
    try {
        $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop
        
        if ($msolUser) {
            $mfaStatus = $msolUser.StrongAuthenticationRequirements
            $mfaEnabled = ($mfaStatus -and $mfaStatus.Count -gt 0)
            
            if (!$mfaEnabled) {
                Add-SecurityFinding -Category "NoMFA" `
                                   -UserAffected $UserPrincipalName `
                                   -Description "Multi-Factor Authentication is not enabled" `
                                   -Severity "High" `
                                   -RecommendedAction "Enable MFA for this account immediately"
            } else {
                Write-SecurityLog "MFA is enabled for $UserPrincipalName" -Level Success
            }
        }
    } catch {
        Write-SecurityLog "Error checking MFA status: $_" -Level Error
    }
}

# Function to check for recent password changes
function Test-RecentPasswordChanges {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    Write-SecurityLog "Checking password change history for $UserPrincipalName..."
    
    try {
        $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop
        
        if ($msolUser -and $msolUser.LastPasswordChangeTimestamp) {
            $lastPwdChange = $msolUser.LastPasswordChangeTimestamp
            $daysSinceChange = (New-TimeSpan -Start $lastPwdChange -End (Get-Date)).Days
            
            if ($daysSinceChange -le $DaysToLookBack) {
                Write-SecurityLog "Password was changed $daysSinceChange days ago on $lastPwdChange" -Level Warning
                
                Add-SecurityFinding -Category "RecentPasswordChange" `
                                   -UserAffected $UserPrincipalName `
                                   -Description "Password was changed recently ($daysSinceChange days ago)" `
                                   -Severity "Medium" `
                                   -RecommendedAction "Verify if this password change was authorized" `
                                   -AdditionalInfo @{
                                       LastPasswordChange = $lastPwdChange
                                       DaysSinceChange = $daysSinceChange
                                   }
            } else {
                Write-SecurityLog "Password was last changed $daysSinceChange days ago (outside our investigation window)" -Level Info
            }
        } else {
            Write-SecurityLog "Could not determine last password change time" -Level Warning
        }
    } catch {
        Write-SecurityLog "Error checking password change history: $_" -Level Error
    }
}

# Function to analyze sender patterns for anomalies
function Test-EmailSendingPatterns {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    Write-SecurityLog "Analyzing email sending patterns for $UserPrincipalName..."
    
    try {
        $startDate = (Get-Date).AddDays(-$DaysToLookBack)
        $endDate = Get-Date
        
        # Try to get message trace data
        try {
            $sentMessages = Get-MessageTrace -SenderAddress $UserPrincipalName -StartDate $startDate -EndDate $endDate -Status Delivered -ErrorAction Stop
            Write-SecurityLog "Found $($sentMessages.Count) sent messages in the past $DaysToLookBack days" -Level Info
            
            # Group by hour to detect unusual sending patterns
            $messagesByHour = $sentMessages | Group-Object { $_.Received.Hour } | Select-Object @{n='Hour';e={$_.Name}}, @{n='Count';e={$_.Count}} | Sort-Object Hour
            
            # Check for unusual volume
            $totalMessages = $sentMessages.Count
            $avgPerDay = [math]::Round($totalMessages / $DaysToLookBack, 2)
            
            if ($avgPerDay -gt 100) {
                Add-SecurityFinding -Category "HighEmailVolume" `
                                   -UserAffected $UserPrincipalName `
                                   -Description "Unusually high email sending volume detected ($totalMessages emails, avg $avgPerDay per day)" `
                                   -Severity "Medium" `
                                   -RecommendedAction "Investigate if this volume is normal for this user" `
                                   -AdditionalInfo @{
                                       TotalSent = $totalMessages
                                       AvgPerDay = $avgPerDay
                                       Period = "$startDate to $endDate"
                                   }
            }
            
            # Check for unusual sending hours (outside business hours)
            $outsideBusinessHours = $messagesByHour | Where-Object { $_.Hour -lt 7 -or $_.Hour -gt 18 }
            $outsideHoursCount = ($outsideBusinessHours | Measure-Object -Property Count -Sum).Sum
            
            if ($outsideHoursCount -gt ($totalMessages * 0.3)) {
                $outsideHoursPercent = [math]::Round(($outsideHoursCount / $totalMessages) * 100, 2)
                
                Add-SecurityFinding -Category "UnusualSendingHours" `
                                   -UserAffected $UserPrincipalName `
                                   -Description "Significant email sending outside business hours ($outsideHoursPercent% of emails)" `
                                   -Severity "Low" `
                                   -RecommendedAction "Review if this pattern is normal for this user" `
                                   -AdditionalInfo @{
                                       OutsideHoursCount = $outsideHoursCount
                                       OutsideHoursPercent = $outsideHoursPercent
                                       TotalMessages = $totalMessages
                                   }
            }
        } catch {
            Write-SecurityLog "Could not retrieve message trace data: $_" -Level Warning
        }
    } catch {
        Write-SecurityLog "Error analyzing email sending patterns: $_" -Level Error
    }
}

# Function to check for tenant-wide security settings
function Test-TenantSecuritySettings {
    Write-SecurityLog "Checking tenant-wide security settings..."
    
    # Check for DMARC, DKIM, SPF
    try {
        # We'll try to check for the domain
        $domains = Get-AcceptedDomain -ErrorAction Stop
        if ($domains) {
            $primaryDomain = $domains | Where-Object { $_.Default -eq $true } | Select-Object -First 1
            
            if ($primaryDomain) {
                $domainName = $primaryDomain.DomainName
                Write-SecurityLog "Checking email authentication for domain: $domainName" -Level Info
                
                # We would check DNS records here, but we can't directly from PowerShell
                # Instead, we'll add a security risk reminder
                
                Add-SecurityRisk -Category "EmailAuthentication" `
                                -Description "Verify email authentication (SPF, DKIM, DMARC) for domain $domainName" `
                                -Severity "High" `
                                -RecommendedAction "Ensure SPF, DKIM, and DMARC are properly configured" `
                                -CurrentState "Unknown (requires manual verification)" `
                                -RecommendedState "SPF, DKIM, and DMARC properly configured and enforced" `
                                -CanRemediate $false
            }
        }
    } catch {
        Write-SecurityLog "Could not check domain settings: $_" -Level Warning
    }
    
    # Check for tenant-wide security defaults
    try {
        # Check for security defaults in Azure AD (requires specific permissions)
        $securityDefaultsEnabled = "Unknown (requires Azure AD admin rights to check)"
        
        Add-SecurityRisk -Category "SecurityDefaults" `
                        -Description "Azure AD Security Defaults status" `
                        -Severity "Medium" `
                        -RecommendedAction "Ensure Security Defaults are enabled if not using Conditional Access" `
                        -CurrentState $securityDefaultsEnabled `
                        -RecommendedState "Enabled (unless using Conditional Access policies)" `
                        -CanRemediate $false
    } catch {
        Write-SecurityLog "Could not check security defaults: $_" -Level Warning
    }
    
    # Check for suspicious OAuth apps
    try {
        Write-SecurityLog "Checking for suspicious OAuth application permissions..." -Level Info
        
        Add-SecurityRisk -Category "OAuthApps" `
                        -Description "Review OAuth apps with mailbox permissions" `
                        -Severity "High" `
                        -RecommendedAction "Review and revoke access for any suspicious OAuth applications with mail.read or mail.readwrite permissions" `
                        -CurrentState "Unknown (requires manual verification)" `
                        -RecommendedState "Only authorized applications have mailbox access permissions" `
                        -CanRemediate $false
    } catch {
        Write-SecurityLog "Could not check OAuth application permissions: $_" -Level Warning
    }
}

# Function to scan a mailbox for phishing indicators
function Test-PhishingIndicators {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    Write-SecurityLog "Scanning for phishing indicators in $UserPrincipalName mailbox..."
    
    try {
        $startDate = (Get-Date).AddDays(-$DaysToLookBack)
        $endDate = Get-Date
        
        # Try to search for suspicious emails using message trace
        try {
            $receivedMail = Get-MessageTrace -RecipientAddress $UserPrincipalName -StartDate $startDate -EndDate $endDate -Status Delivered -ErrorAction Stop
            
            Write-SecurityLog "Analyzing $($receivedMail.Count) emails for phishing indicators..." -Level Info
            
            $suspiciousSubjects = @("password", "urgent", "verify", "login", "credential", "account", "security", "unusual", "suspicious", "access")
            $suspiciousSenders = @(".ml", ".tk", ".ga", ".cf", ".xyz", ".top", "mail.ru", ".pw")
            
            $suspiciousCount = 0
            
            foreach ($email in $receivedMail) {
                $isSuspicious = $false
                $reasons = @()
                
                # Check subject for suspicious keywords
                foreach ($keyword in $suspiciousSubjects) {
                    if ($email.Subject -match $keyword) {
                        $isSuspicious = $true
                        $reasons += "Suspicious keyword in subject: $keyword"
                        break
                    }
                }
                
                # Check sender domain for suspicious TLDs
                foreach ($domain in $suspiciousSenders) {
                    if ($email.FromAddress -match $domain) {
                        $isSuspicious = $true
                        $reasons += "Suspicious sender domain: $domain"
                        break
                    }
                }
                
                if ($isSuspicious) {
                    $suspiciousCount++
                    
                    if ($suspiciousCount <= 10) { # Limit detailed reporting to 10 emails
                        Add-SecurityFinding -Category "SuspiciousEmail" `
                                           -UserAffected $UserPrincipalName `
                                           -Description "Potentially suspicious email received" `
                                           -Severity "Medium" `
                                           -RecommendedAction "Review email for phishing indicators" `
                                           -AdditionalInfo @{
                                               Subject = $email.Subject
                                               Sender = $email.FromAddress
                                               ReceivedTime = $email.Received
                                               SuspiciousIndicators = ($reasons -join "; ")
                                           }
                    }
                }
            }
            
            if ($suspiciousCount > 10) {
                Write-SecurityLog "Found a total of $suspiciousCount suspicious emails (showing details for first 10 only)" -Level Warning
            }
        } catch {
            Write-SecurityLog "Could not retrieve message trace data: $_" -Level Warning
        }
    } catch {
        Write-SecurityLog "Error scanning for phishing indicators: $_" -Level Error
    }
}

# Function to check login activity
function Test-LoginActivity {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    Write-SecurityLog "Checking login activity for $UserPrincipalName..."
    
    try {
        # Try to get AzureAD sign-in logs
        try {
            $user = Get-AzureADUser -Filter "UserPrincipalName eq '$UserPrincipalName'"
            $startDate = (Get-Date).AddDays(-$DaysToLookBack)
            
            if ($user) {
                # Note: This might require Azure AD P1/P2 licensing and appropriate permissions
                $signInLogs = Get-AzureADAuditSignInLogs -Filter "userId eq '$($user.ObjectId)'" -Top 100 -ErrorAction Stop
                
                if ($signInLogs) {
                    Write-SecurityLog "Found $($signInLogs.Count) sign-in records" -Level Info
                    
                    # Check for failed login attempts
                    $failedLogins = $signInLogs | Where-Object { $_.Status.ErrorCode -ne 0 }
                    if ($failedLogins -and $failedLogins.Count -gt 5) {
                        Add-SecurityFinding -Category "FailedLogins" `
                                           -UserAffected $UserPrincipalName `
                                           -Description "Multiple failed login attempts detected ($($failedLogins.Count) failures)" `
                                           -Severity "Medium" `
                                           -RecommendedAction "Verify if these failures are legitimate or potential brute force attempts" `
                                           -AdditionalInfo @{
                                               FailureCount = $failedLogins.Count
                                               RecentFailure = ($failedLogins | Sort-Object CreatedDateTime -Descending | Select-Object -First 1).CreatedDateTime
                                           }
                    }
                    
                    # Check for logins from unusual locations
                    $signInLocations = $signInLogs | Group-Object {$_.Location.CountryOrRegion} | Select-Object Name, Count | Sort-Object Count -Descending
                    if ($signInLocations.Count -gt 3) {
                        Add-SecurityFinding -Category "MultipleLocations" `
                                           -UserAffected $UserPrincipalName `
                                           -Description "Logins from multiple countries/regions detected ($($signInLocations.Count) different locations)" `
                                           -Severity "Medium" `
                                           -RecommendedAction "Verify if these login locations are legitimate" `
                                           -AdditionalInfo @{
                                               Locations = ($signInLocations | ForEach-Object { "$($_.Name) ($($_.Count))" }) -join ", "
                                           }
                    }
                } else {
                    Write-SecurityLog "No sign-in logs found (may require additional permissions or Azure AD P1/P2)" -Level Warning
                }
            }
        } catch {
            Write-SecurityLog "Could not retrieve sign-in logs: $_" -Level Warning
            Write-SecurityLog "This typically requires Azure AD P1/P2 licensing and appropriate permissions" -Level Warning
        }
        
        # Try to get registered devices
        try {
            $user = Get-AzureADUser -Filter "UserPrincipalName eq '$UserPrincipalName'"
            
            if ($user) {
                $devices = Get-AzureADUserRegisteredDevice -ObjectId $user.ObjectId
                
                if ($devices -and $devices.Count -gt 0) {
                    Write-SecurityLog "Found $($devices.Count) registered devices" -Level Info
                    
                    foreach ($device in $devices) {
                        Write-SecurityLog "  - $($device.DisplayName) ($($device.DeviceOSType)) - Last active: $($device.ApproximateLastLogonTimestamp)" -Level Info
                    }
                    
                    # Check for recently added devices
                    $recentDevices = $devices | Where-Object { $_.ApproximateLastLogonTimestamp -gt (Get-Date).AddDays(-$DaysToLookBack) }
                    if ($recentDevices.Count -gt 0) {
                        Add-SecurityFinding -Category "RecentDevices" `
                                           -UserAffected $UserPrincipalName `
                                           -Description "$($recentDevices.Count) device(s) recently active with this account" `
                                           -Severity "Low" `
                                           -RecommendedAction "Verify these devices are legitimate" `
                                           -AdditionalInfo @{
                                               Devices = ($recentDevices | ForEach-Object { "$($_.DisplayName) ($($_.DeviceOSType))" }) -join ", "
                                           }
                    }
                } else {
                    Write-SecurityLog "No registered devices found" -Level Info
                }
            }
        } catch {
            Write-SecurityLog "Could not retrieve registered devices: $_" -Level Warning
        }
    } catch {
        Write-SecurityLog "Error checking login activity: $_" -Level Error
    }
}

# Function to implement security hardening if requested
function Implement-SecurityHardening {
    param(
        [string]$UserPrincipalName
    )
    
    if (!$PerformRemediation) {
        Write-SecurityLog "Skipping remediation (use -PerformRemediation to enable)" -Level Warning
        return
    }
    
    Write-SecurityLog "Implementing security hardening measures for $UserPrincipalName..." -Level Warning
    
    try {
        # 1. Check and remove suspicious inbox rules
        Write-SecurityLog "Checking for suspicious inbox rules to remove..." -Level Info
        
        $suspiciousRules = $global:findings | Where-Object { $_.Category -eq "SuspiciousInboxRule" -and $_.UserAffected -eq $UserPrincipalName }
        
        foreach ($finding in $suspiciousRules) {
            $ruleName = $finding.RuleName
            $ruleId = $finding.RuleId
            
            Write-SecurityLog "Attempting to remove suspicious rule: $ruleName..." -Level Warning
            
            try {
                # Remove-InboxRule -Identity $ruleId -Confirm:$false
                Write-SecurityLog "SIMULATION: Would remove inbox rule: $ruleName (ID: $ruleId)" -Level Warning
            } catch {
                Write-SecurityLog "Failed to remove inbox rule: $_" -Level Error
            }
        }
        
        # 2. Remove suspicious mailbox forwarding
        $forwardingFindings = $global:findings | Where-Object { $_.Category -eq "MailboxForwarding" -and $_.UserAffected -eq $UserPrincipalName }
        
        if ($forwardingFindings) {
            Write-SecurityLog "Attempting to remove mailbox forwarding..." -Level Warning
            
            try {
                # Set-Mailbox -Identity $UserPrincipalName -ForwardingAddress $null -ForwardingSmtpAddress $null
                Write-SecurityLog "SIMULATION: Would remove mailbox forwarding for $UserPrincipalName" -Level Warning
            } catch {
                Write-SecurityLog "Failed to remove mailbox forwarding: $_" -Level Error
            }
        }
        
        # 3. Reset password if suspicious activity detected
        $highRiskFindings = $global:findings | Where-Object { $_.Severity -in @("High", "Critical") -and $_.UserAffected -eq $UserPrincipalName }
        
        if ($highRiskFindings.Count -gt 0) {
            Write-SecurityLog "High risk findings detected. Password reset recommended." -Level Warning
            
            # Generate random password
            $newPassword = -join ((65..90) + (97..122) + (48..57) + (35..38) | Get-Random -Count 16 | ForEach-Object {[char]$_})
            
            Write-SecurityLog "SIMULATION: Would reset password for $UserPrincipalName" -Level Warning
            # Set-MsolUserPassword -UserPrincipalName $UserPrincipalName -NewPassword $newPassword -ForceChangePassword $true
        }
        
        # 4. Enable MFA if not enabled
        $noMfaFinding = $global:findings | Where-Object { $_.Category -eq "NoMFA" -and $_.UserAffected -eq $UserPrincipalName }
        
        if ($noMfaFinding) {
            Write-SecurityLog "MFA not enabled. Attempting to enable..." -Level Warning
            
            try {
                # This requires appropriate permissions and typically would be done via the Admin portal
                Write-SecurityLog "SIMULATION: Would enable MFA for $UserPrincipalName" -Level Warning
            } catch {
                Write-SecurityLog "Failed to enable MFA: $_" -Level Error
            }
        }
    } catch {
        Write-SecurityLog "Error during security hardening: $_" -Level Error
    }
}

# Function to investigate a single user
function Investigate-User {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    Write-SecurityLog "======================================================" -Level Info
    Write-SecurityLog "Starting investigation for: $UserPrincipalName" -Level Info
    Write-SecurityLog "Looking back $DaysToLookBack days" -Level Info
    Write-SecurityLog "======================================================" -Level Info
    
    # Check MFA status
    Test-MFAStatus -UserPrincipalName $UserPrincipalName
    
    # Check for inbox rules
    Test-SuspiciousInboxRules -UserPrincipalName $UserPrincipalName
    
    # Check for mailbox forwarding
    Test-MailboxForwarding -UserPrincipalName $UserPrincipalName
    
    # Check for mailbox delegates
    Test-MailboxDelegates -UserPrincipalName $UserPrincipalName
    
    # Check password history
    Test-RecentPasswordChanges -UserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
    
    # Analyze sending patterns
    Test-EmailSendingPatterns -UserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
    
    # Check login activity
    Test-LoginActivity -UserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
    
    # Check for phishing
    Test-PhishingIndicators -UserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
    
    # Implement security hardening if requested
    if ($ImplementHardening) {
        Implement-SecurityHardening -UserPrincipalName $UserPrincipalName
    }
    
    Write-SecurityLog "Investigation completed for: $UserPrincipalName" -Level Info
}

# Function to investigate all users (or a subset)
function Investigate-AllUsers {
    param(
        [int]$DaysToLookBack,
        [int]$MaxUsers = 100
    )
    
    Write-SecurityLog "Starting investigation for all users (up to $MaxUsers)..." -Level Info
    
    try {
        $users = Get-AzureADUser -Top $MaxUsers -Filter "AccountEnabled eq true" | Where-Object { $_.UserPrincipalName -like "*@*" }
        
        if ($users) {
            $totalUsers = $users.Count
            Write-SecurityLog "Found $totalUsers users to analyze" -Level Info
            
            $processedCount = 0
            foreach ($user in $users) {
                $processedCount++
                $percentComplete = [math]::Round(($processedCount / $totalUsers) * 100)
                Write-SecurityLog "[$percentComplete%] Processing user $processedCount of $totalUsers: $($user.UserPrincipalName)" -Level Info
                
                Investigate-User -UserPrincipalName $user.UserPrincipalName -DaysToLookBack $DaysToLookBack
            }
        } else {
            Write-SecurityLog "No users found or you don't have permission to list users" -Level Warning
        }
    } catch {
        Write-SecurityLog "Error retrieving users: $_" -Level Error
    }
}

# Function to generate summary report
function Generate-SecurityReport {
    $highRiskFindings = $global:findings | Where-Object { $_.Severity -eq "Critical" -or $_.Severity -eq "High" }
    $mediumRiskFindings = $global:findings | Where-Object { $_.Severity -eq "Medium" }
    $lowRiskFindings = $global:findings | Where-Object { $_.Severity -eq "Low" }
    $affectedUsers = $global:findings | Select-Object -ExpandProperty UserAffected -Unique
    
    Write-SecurityLog "`n======================================================" -Level Info
    Write-SecurityLog "SECURITY INVESTIGATION SUMMARY" -Level Info
    Write-SecurityLog "======================================================" -Level Info
    Write-SecurityLog "Investigation completed in: $([math]::Round(((Get-Date) - $startTime).TotalMinutes, 2)) minutes" -Level Info
    Write-SecurityLog "Users analyzed: $($affectedUsers.Count)" -Level Info
    Write-SecurityLog "Total findings: $($global:findings.Count)" -Level Info
    Write-SecurityLog "  - Critical/High risk: $($highRiskFindings.Count)" -Level $(if ($highRiskFindings.Count -gt 0) { "Error" } else { "Success" })
    Write-SecurityLog "  - Medium risk: $($mediumRiskFindings.Count)" -Level $(if ($mediumRiskFindings.Count -gt 0) { "Warning" } else { "Success" })
    Write-SecurityLog "  - Low risk: $($lowRiskFindings.Count)" -Level Info
    Write-SecurityLog "Security recommendations: $($global:securityRisks.Count)" -Level Info
    Write-SecurityLog "======================================================" -Level Info
    
    if ($highRiskFindings.Count -gt 0) {
        Write-SecurityLog "`n== HIGH PRIORITY FINDINGS ==" -Level Error
        foreach ($finding in $highRiskFindings) {
            Write-SecurityLog "[$($finding.Category)] $($finding.Description)" -Level Error
            Write-SecurityLog "  Affected: $($finding.UserAffected)" -Level Error
            Write-SecurityLog "  Action: $($finding.RecommendedAction)" -Level Error
        }
    }
    
    if ($global:securityRisks.Count -gt 0) {
        Write-SecurityLog "`n== SECURITY RECOMMENDATIONS ==" -Level Warning
        foreach ($risk in $global:securityRisks) {
            Write-SecurityLog "[$($risk.Category)] $($risk.Description)" -Level Warning
            Write-SecurityLog "  Recommended: $($risk.RecommendedAction)" -Level Warning
        }
    }
    
    # Export findings to CSV
    if ($global:findings.Count -gt 0) {
        $global:findings | Export-Csv -Path $outputCsv -NoTypeInformation
        Write-SecurityLog "`nFindings exported to: $outputCsv" -Level Info
    }
    
    # Export security risks to CSV
    if ($global:securityRisks.Count -gt 0) {
        $global:securityRisks | Export-Csv -Path $outputRisks -NoTypeInformation
        Write-SecurityLog "Security recommendations exported to: $outputRisks" -Level Info
    }
}

# Main execution
Write-SecurityLog "Email Security Defender v1.0" -Level Info
Write-SecurityLog "Starting security investigation on $(Get-Date)" -Level Info

# Ensure output directory exists
if (!(Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    Write-SecurityLog "Created output directory: $OutputDirectory" -Level Info
}

# Check prerequisites
if (Test-Prerequisites) {
    # Check tenant-wide settings
    Test-TenantSecuritySettings
    
    # Process specific user or all users
    if ($UserPrincipalName) {
        Investigate-User -UserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
    } elseif ($AllUsers) {
        Investigate-AllUsers -DaysToLookBack $DaysToLookBack
    } else {
        Write-SecurityLog "You must specify either -UserPrincipalName or -AllUsers" -Level Error
    }
    
    # Generate report
    Generate-SecurityReport
    
    # Disconnect from services
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        Disconnect-AzureAD -ErrorAction SilentlyContinue
        Write-SecurityLog "Disconnected from Microsoft 365 services" -Level Info
    } catch {
        Write-SecurityLog "Error disconnecting from services: $_" -Level Warning
    }
} else {
    Write-SecurityLog "Prerequisites check failed. Cannot continue." -Level Error
}

Write-SecurityLog "Investigation complete. See the log file for details: $outputLog" -Level Info
