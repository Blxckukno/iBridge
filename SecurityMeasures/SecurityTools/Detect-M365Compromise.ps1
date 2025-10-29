# Detect-M365Compromise.ps1
# Purpose: Detect signs of compromise in Microsoft 365 accounts and services
# Created: September 10, 2025

param (
    [Parameter(Mandatory=$false)]
    [string]$UserToCheck,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckAllUsers,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckAdminActivity,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckConditionalAccess,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckMailRules,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckDelegates,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckForwarding,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckAuditLogs,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysToCheck = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckAll,
    
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = ".\M365_Compromise_Detection_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
)

# Initialize environment
$ErrorActionPreference = "Continue"
$detectionReport = @()
$script:totalChecks = 0
$script:suspiciousFindings = 0
$geoIPDataCache = @{}

# Colors for HTML report
$normalColor = "#FFFFFF"      # White
$suspiciousColor = "#FFCCCB"  # Light red
$headerColor = "#4F6995"      # Blue-gray
$headerTextColor = "#FFFFFF"  # White

# Function for logging
function Write-DetectionLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Suspicious')]
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
        'Suspicious' { Write-Host $logMessage -ForegroundColor Magenta }
    }
}

# Function to record detection result
function Add-DetectionResult {
    param(
        [string]$Category,
        [string]$CheckName,
        [string]$Description,
        [bool]$IsSuspicious = $false,
        [string]$Details,
        [string]$RecommendedAction
    )
    
    # Increment counters
    $script:totalChecks++
    if ($IsSuspicious) {
        $script:suspiciousFindings++
    }
    
    $checkResult = [PSCustomObject]@{
        Category = $Category
        CheckName = $CheckName
        Description = $Description
        IsSuspicious = $IsSuspicious
        Details = $Details
        RecommendedAction = $RecommendedAction
        Timestamp = Get-Date
    }
    
    $detectionReport += $checkResult
    
    # Log to console
    $statusIcon = if ($IsSuspicious) { "[SUSPICIOUS]" } else { "[OK]" }
    $logLevel = if ($IsSuspicious) { "Suspicious" } else { "Success" }
    
    Write-DetectionLog "$statusIcon $CheckName - $Description" -Level $logLevel
    if ($IsSuspicious) {
        Write-DetectionLog "     Details: $Details" -Level Warning
        Write-DetectionLog "     Recommendation: $RecommendedAction" -Level Warning
    }
    
    return $checkResult
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-DetectionLog "Checking prerequisites and required modules..."
    $requiredModules = @(
        "ExchangeOnlineManagement",
        "AzureAD",
        "MSOnline"
    )
    
    $allModulesPresent = $true
    
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-DetectionLog "Required module not found: $module" -Level Error
            Write-DetectionLog "Please install it with: Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser" -Level Warning
            $allModulesPresent = $false
        } else {
            Write-DetectionLog "Module $module is available" -Level Success
        }
    }
    
    if (!$allModulesPresent) {
        Write-DetectionLog "Missing required modules. Please install them and try again." -Level Error
        return $false
    }
    
    # Check connections
    try {
        Write-DetectionLog "Connecting to required services..."
        
        # Connect to Azure AD
        Connect-AzureAD -ErrorAction Stop | Out-Null
        Write-DetectionLog "Connected to Azure AD" -Level Success
        
        # Connect to Exchange Online
        Connect-ExchangeOnline -ErrorAction Stop | Out-Null
        Write-DetectionLog "Connected to Exchange Online" -Level Success
        
        # Try to connect to MSOL
        try {
            Connect-MsolService -ErrorAction Stop | Out-Null
            Write-DetectionLog "Connected to Microsoft Online Services" -Level Success
        } catch {
            Write-DetectionLog "Could not connect to MSOnline Service: $_" -Level Warning
            Write-DetectionLog "Some functions may be limited" -Level Warning
        }
        
        return $true
    } catch {
        Write-DetectionLog "Failed to connect to required services: $_" -Level Error
        return $false
    }
}

# Function to get geo location from IP
function Get-GeoIPInfo {
    param(
        [string]$IPAddress
    )
    
    # Check if we already have this IP in cache
    if ($geoIPDataCache.ContainsKey($IPAddress)) {
        return $geoIPDataCache[$IPAddress]
    }
    
    try {
        # Use free IP geolocation API
        $response = Invoke-RestMethod -Uri "http://ip-api.com/json/$IPAddress" -Method Get
        
        if ($response.status -eq "success") {
            $geoInfo = [PSCustomObject]@{
                Country = $response.country
                City = $response.city
                ISP = $response.isp
                Org = $response.org
            }
            
            # Add to cache
            $geoIPDataCache[$IPAddress] = $geoInfo
            
            return $geoInfo
        } else {
            return [PSCustomObject]@{
                Country = "Unknown"
                City = "Unknown"
                ISP = "Unknown"
                Org = "Unknown"
            }
        }
    } catch {
        Write-DetectionLog "Error retrieving geolocation data: $_" -Level Warning
        
        return [PSCustomObject]@{
            Country = "Unknown"
            City = "Unknown"
            ISP = "Unknown"
            Org = "Unknown"
        }
    }
}

# Function to check for suspicious sign-ins
function Check-SuspiciousSignIns {
    param(
        [string]$UPN
    )
    
    Write-DetectionLog "Checking for suspicious sign-ins for $UPN..."
    
    try {
        # Define start date (past X days)
        $startDate = (Get-Date).AddDays(-$DaysToCheck)
        
        # Try to get sign-in activity
        $signIns = Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$UPN'" -Top 500 | Where-Object { $_.CreatedDateTime -ge $startDate }
        
        if ($signIns -and $signIns.Count -gt 0) {
            # Group by IP address and count
            $ipGroups = $signIns | Group-Object IpAddress | Select-Object Name, Count
            
            # Group by location
            $locationGroups = $signIns | Group-Object Location | Select-Object Name, Count
            
            # Check for multiple locations in short time periods
            $timeOrderedSignIns = $signIns | Sort-Object CreatedDateTime
            $suspiciousTimeGaps = @()
            $previousSignIn = $null
            $previousLocation = $null
            
            foreach ($signIn in $timeOrderedSignIns) {
                if ($previousSignIn -ne $null -and $previousLocation -ne $signIn.Location) {
                    $timeDiff = New-TimeSpan -Start $previousSignIn.CreatedDateTime -End $signIn.CreatedDateTime
                    
                    # If less than 2 hours between logins from different locations
                    if ($timeDiff.TotalHours -lt 2) {
                        $gapDetails = @{
                            FirstTime = $previousSignIn.CreatedDateTime
                            FirstLocation = $previousLocation
                            FirstIP = $previousSignIn.IpAddress
                            SecondTime = $signIn.CreatedDateTime
                            SecondLocation = $signIn.Location
                            SecondIP = $signIn.IpAddress
                            TimeDifferenceMinutes = $timeDiff.TotalMinutes
                        }
                        $suspiciousTimeGaps += $gapDetails
                    }
                }
                $previousSignIn = $signIn
                $previousLocation = $signIn.Location
            }
            
            # Failed sign-in attempts
            $failedSignIns = $signIns | Where-Object { $_.Status.ErrorCode -ne 0 }
            $failedLoginCount = $failedSignIns.Count
            
            # Check if any findings are suspicious
            $isSuspicious = $false
            $details = "Sign-in activity summary for past $DaysToCheck days:`n"
            $details += "- Total sign-ins: $($signIns.Count)`n"
            $details += "- Unique IP addresses: $($ipGroups.Count)`n"
            $details += "- Unique locations: $($locationGroups.Count)`n"
            $details += "- Failed sign-in attempts: $failedLoginCount`n"
            
            $recommendedAction = "No suspicious activity detected."
            
            if ($suspiciousTimeGaps.Count -gt 0) {
                $isSuspicious = $true
                $details += "`nPOTENTIALLY SUSPICIOUS: Rapid location changes detected (${suspiciousTimeGaps.Count} instances)`n"
                foreach ($gap in $suspiciousTimeGaps) {
                    $details += "  * $($gap.FirstTime) from $($gap.FirstLocation) ($($gap.FirstIP)) to $($gap.SecondTime) from $($gap.SecondLocation) ($($gap.SecondIP)) - $([math]::Round($gap.TimeDifferenceMinutes, 2)) minutes apart`n"
                }
                
                $recommendedAction = "Review suspicious sign-in pattern showing rapid location changes. Verify with user if these represent legitimate travel or possible account compromise. Consider forcing password reset and enabling MFA."
            }
            
            if ($failedLoginCount -gt 5) {
                $isSuspicious = $true
                $details += "`nPOTENTIALLY SUSPICIOUS: High number of failed sign-in attempts ($failedLoginCount)`n"
                
                # Group failed sign-ins by IP and show top 5
                $topFailedIPs = $failedSignIns | Group-Object IpAddress | Sort-Object Count -Descending | Select-Object -First 5
                foreach ($ip in $topFailedIPs) {
                    $geoInfo = Get-GeoIPInfo -IPAddress $ip.Name
                    $details += "  * $($ip.Count) failed attempts from IP $($ip.Name) ($($geoInfo.Country), $($geoInfo.City), $($geoInfo.ISP))`n"
                }
                
                if ($recommendedAction -eq "No suspicious activity detected.") {
                    $recommendedAction = "Investigate high number of failed login attempts. Consider temporarily blocking sign-ins from suspicious IPs and forcing password reset."
                } else {
                    $recommendedAction += " Additionally, investigate high number of failed login attempts."
                }
            }
            
            Add-DetectionResult -Category "Authentication" `
                              -CheckName "Sign-In Activity" `
                              -Description "Check for suspicious sign-in patterns" `
                              -IsSuspicious $isSuspicious `
                              -Details $details `
                              -RecommendedAction $recommendedAction
        } else {
            Add-DetectionResult -Category "Authentication" `
                              -CheckName "Sign-In Activity" `
                              -Description "Check for suspicious sign-in patterns" `
                              -IsSuspicious $false `
                              -Details "No sign-in data found for the past $DaysToCheck days." `
                              -RecommendedAction "No action required."
        }
    } catch {
        Write-DetectionLog "Error checking sign-in activity: $_" -Level Error
        
        Add-DetectionResult -Category "Authentication" `
                          -CheckName "Sign-In Activity" `
                          -Description "Check for suspicious sign-in patterns" `
                          -IsSuspicious $false `
                          -Details "Error retrieving sign-in data: $_" `
                          -RecommendedAction "Verify you have appropriate permissions to view sign-in logs."
    }
}

# Function to check for suspicious inbox rules
function Check-SuspiciousInboxRules {
    param(
        [string]$UPN
    )
    
    Write-DetectionLog "Checking for suspicious inbox rules for $UPN..."
    
    try {
        # Get inbox rules
        $inboxRules = Get-InboxRule -Mailbox $UPN -IncludeHidden
        
        if ($inboxRules -and $inboxRules.Count -gt 0) {
            # Look for potentially suspicious rules
            $suspiciousRules = @()
            
            foreach ($rule in $inboxRules) {
                $isSuspicious = $false
                $reasons = @()
                
                # Check for forwarding rules
                if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo -or $rule.RedirectTo) {
                    $isSuspicious = $true
                    $reasons += "Forwards or redirects emails"
                }
                
                # Check for deletion rules combined with other conditions
                if ($rule.DeleteMessage -eq $true -or $rule.MoveToFolder -match "Deleted Items") {
                    if ($rule.SubjectContainsWords -or $rule.BodyContainsWords -or $rule.From) {
                        $isSuspicious = $true
                        $reasons += "Deletes messages matching specific criteria"
                    }
                }
                
                # Check for rules that mark messages as read
                if ($rule.MarkAsRead -eq $true) {
                    if ($rule.SubjectContainsWords -or $rule.BodyContainsWords -or $rule.From) {
                        $isSuspicious = $true
                        $reasons += "Marks specific messages as read (hiding notifications)"
                    }
                }
                
                # Check for rules that move messages to less visible folders
                if ($rule.MoveToFolder -and $rule.MoveToFolder -notmatch "Inbox") {
                    if ($rule.SubjectContainsWords -or $rule.BodyContainsWords -or $rule.From) {
                        $isSuspicious = $true
                        $reasons += "Moves specific messages out of view"
                    }
                }
                
                # If rule is suspicious, add to list
                if ($isSuspicious) {
                    $suspiciousRules += [PSCustomObject]@{
                        RuleName = $rule.Name
                        RuleId = $rule.Identity
                        Enabled = $rule.Enabled
                        Conditions = $(
                            $conditions = @()
                            if ($rule.SubjectContainsWords) { $conditions += "Subject contains: $($rule.SubjectContainsWords)" }
                            if ($rule.BodyContainsWords) { $conditions += "Body contains: $($rule.BodyContainsWords)" }
                            if ($rule.From) { $conditions += "From: $($rule.From)" }
                            if ($conditions.Count -eq 0) { "No specific conditions" } else { $conditions -join ", " }
                        )
                        Actions = $(
                            $actions = @()
                            if ($rule.ForwardTo) { $actions += "Forward to: $($rule.ForwardTo)" }
                            if ($rule.ForwardAsAttachmentTo) { $actions += "Forward as attachment to: $($rule.ForwardAsAttachmentTo)" }
                            if ($rule.RedirectTo) { $actions += "Redirect to: $($rule.RedirectTo)" }
                            if ($rule.DeleteMessage) { $actions += "Delete message" }
                            if ($rule.MarkAsRead) { $actions += "Mark as read" }
                            if ($rule.MoveToFolder) { $actions += "Move to folder: $($rule.MoveToFolder)" }
                            $actions -join ", "
                        )
                        SuspiciousReasons = $reasons -join ", "
                    }
                }
            }
            
            if ($suspiciousRules.Count -gt 0) {
                $details = "Found $($suspiciousRules.Count) potentially suspicious inbox rules out of $($inboxRules.Count) total rules:`n"
                
                foreach ($rule in $suspiciousRules) {
                    $details += "  * Rule Name: $($rule.RuleName)`n"
                    $details += "    - Enabled: $($rule.Enabled)`n"
                    $details += "    - Conditions: $($rule.Conditions)`n"
                    $details += "    - Actions: $($rule.Actions)`n"
                    $details += "    - Suspicious because: $($rule.SuspiciousReasons)`n"
                }
                
                Add-DetectionResult -Category "Email" `
                                  -CheckName "Suspicious Inbox Rules" `
                                  -Description "Check for potentially malicious inbox rules" `
                                  -IsSuspicious $true `
                                  -Details $details `
                                  -RecommendedAction "Review and delete suspicious inbox rules. Verify with user if they created these rules intentionally. Consider checking for other signs of compromise."
            } else {
                Add-DetectionResult -Category "Email" `
                                  -CheckName "Suspicious Inbox Rules" `
                                  -Description "Check for potentially malicious inbox rules" `
                                  -IsSuspicious $false `
                                  -Details "No suspicious inbox rules detected out of $($inboxRules.Count) total rules." `
                                  -RecommendedAction "No action required."
            }
        } else {
            Add-DetectionResult -Category "Email" `
                              -CheckName "Suspicious Inbox Rules" `
                              -Description "Check for potentially malicious inbox rules" `
                              -IsSuspicious $false `
                              -Details "No inbox rules found." `
                              -RecommendedAction "No action required."
        }
    } catch {
        Write-DetectionLog "Error checking inbox rules: $_" -Level Error
        
        Add-DetectionResult -Category "Email" `
                          -CheckName "Suspicious Inbox Rules" `
                          -Description "Check for potentially malicious inbox rules" `
                          -IsSuspicious $false `
                          -Details "Error retrieving inbox rules: $_" `
                          -RecommendedAction "Verify you have appropriate permissions to view inbox rules."
    }
}

# Function to check for suspicious email forwarding
function Check-SuspiciousForwarding {
    param(
        [string]$UPN
    )
    
    Write-DetectionLog "Checking for suspicious email forwarding for $UPN..."
    
    try {
        # Get mailbox forwarding settings
        $mailbox = Get-Mailbox -Identity $UPN
        
        $forwardingSuspicious = $false
        $details = "Mailbox forwarding settings:`n"
        
        # Check forwarding settings
        if ($mailbox.ForwardingAddress -or $mailbox.ForwardingSmtpAddress) {
            $forwardingSuspicious = $true
            $details += "  * Forwarding enabled`n"
            
            if ($mailbox.ForwardingAddress) {
                $details += "    - Internal forwarding address: $($mailbox.ForwardingAddress)`n"
            }
            
            if ($mailbox.ForwardingSmtpAddress) {
                $forwardingEmail = $mailbox.ForwardingSmtpAddress -replace "SMTP:", ""
                $details += "    - External forwarding address: $forwardingEmail`n"
            }
            
            $details += "    - Deliver to forwarding address and mailbox: $($mailbox.DeliverToMailboxAndForward)`n"
        } else {
            $details += "  * No mailbox-level forwarding configured`n"
        }
        
        # Check for forwarding via transport rules (requires higher permissions)
        try {
            $transportRules = Get-TransportRule | Where-Object { 
                $_.RedirectMessageTo -or 
                $_.BccToRecipients -or 
                $_.AddToRecipients -or 
                $_.CopyTo
            }
            
            if ($transportRules -and $transportRules.Count -gt 0) {
                $affectedRules = $transportRules | Where-Object { $_.From -match $UPN -or !$_.From }
                
                if ($affectedRules -and $affectedRules.Count -gt 0) {
                    $forwardingSuspicious = $true
                    $details += "`n  * Transport rules that may affect this mailbox: $($affectedRules.Count)`n"
                    
                    foreach ($rule in $affectedRules) {
                        $details += "    - Rule: $($rule.Name)`n"
                        
                        if ($rule.RedirectMessageTo) {
                            $details += "      Redirects to: $($rule.RedirectMessageTo -join ', ')`n"
                        }
                        
                        if ($rule.BccToRecipients) {
                            $details += "      BCC to: $($rule.BccToRecipients -join ', ')`n"
                        }
                        
                        if ($rule.AddToRecipients) {
                            $details += "      Adds recipients: $($rule.AddToRecipients -join ', ')`n"
                        }
                        
                        if ($rule.CopyTo) {
                            $details += "      Copies to: $($rule.CopyTo -join ', ')`n"
                        }
                    }
                } else {
                    $details += "`n  * No transport rules affecting this mailbox specifically`n"
                }
            } else {
                $details += "`n  * No suspicious transport rules found`n"
            }
        } catch {
            $details += "`n  * Unable to check transport rules: $($_)`n"
        }
        
        Add-DetectionResult -Category "Email" `
                          -CheckName "Email Forwarding" `
                          -Description "Check for suspicious email forwarding" `
                          -IsSuspicious $forwardingSuspicious `
                          -Details $details `
                          -RecommendedAction $(
                                if ($forwardingSuspicious) {
                                    "Review and disable suspicious email forwarding. Verify with user if they set up forwarding intentionally."
                                } else {
                                    "No action required."
                                }
                            )
    } catch {
        Write-DetectionLog "Error checking email forwarding: $_" -Level Error
        
        Add-DetectionResult -Category "Email" `
                          -CheckName "Email Forwarding" `
                          -Description "Check for suspicious email forwarding" `
                          -IsSuspicious $false `
                          -Details "Error retrieving forwarding settings: $_" `
                          -RecommendedAction "Verify you have appropriate permissions to view mailbox settings."
    }
}

# Function to check for suspicious delegates
function Check-SuspiciousDelegates {
    param(
        [string]$UPN
    )
    
    Write-DetectionLog "Checking for suspicious delegates for $UPN..."
    
    try {
        # Get mailbox delegate permissions
        $delegatePermissions = @()
        
        # Get Full Access permissions
        $fullAccessUsers = Get-MailboxPermission -Identity $UPN | 
                           Where-Object { $_.IsInherited -eq $false -and $_.User -ne "NT AUTHORITY\SELF" }
        
        if ($fullAccessUsers) {
            foreach ($user in $fullAccessUsers) {
                $delegatePermissions += [PSCustomObject]@{
                    Delegate = $user.User
                    Permission = "Full Access"
                    AccessRights = $user.AccessRights -join ', '
                }
            }
        }
        
        # Get Send As permissions
        $sendAsUsers = Get-RecipientPermission -Identity $UPN | 
                       Where-Object { $_.IsInherited -eq $false -and $_.Trustee -ne "NT AUTHORITY\SELF" }
        
        if ($sendAsUsers) {
            foreach ($user in $sendAsUsers) {
                $delegatePermissions += [PSCustomObject]@{
                    Delegate = $user.Trustee
                    Permission = "Send As"
                    AccessRights = $user.AccessRights -join ', '
                }
            }
        }
        
        # Get Send on Behalf permissions
        $mailbox = Get-Mailbox -Identity $UPN
        if ($mailbox.GrantSendOnBehalfTo) {
            foreach ($delegate in $mailbox.GrantSendOnBehalfTo) {
                $delegatePermissions += [PSCustomObject]@{
                    Delegate = $delegate
                    Permission = "Send on Behalf"
                    AccessRights = "SendOnBehalf"
                }
            }
        }
        
        if ($delegatePermissions.Count -gt 0) {
            $details = "Found $($delegatePermissions.Count) delegates with access to this mailbox:`n"
            
            foreach ($permission in $delegatePermissions) {
                $details += "  * Delegate: $($permission.Delegate)`n"
                $details += "    - Permission: $($permission.Permission)`n"
                $details += "    - Access Rights: $($permission.AccessRights)`n"
            }
            
            # For now, we'll just flag this as something to review rather than automatically suspicious
            Add-DetectionResult -Category "Email" `
                              -CheckName "Mailbox Delegates" `
                              -Description "Check for mailbox delegates" `
                              -IsSuspicious $false `
                              -Details $details `
                              -RecommendedAction "Review delegates and ensure they are authorized. Remove any unauthorized delegates."
        } else {
            Add-DetectionResult -Category "Email" `
                              -CheckName "Mailbox Delegates" `
                              -Description "Check for mailbox delegates" `
                              -IsSuspicious $false `
                              -Details "No mailbox delegates found." `
                              -RecommendedAction "No action required."
        }
    } catch {
        Write-DetectionLog "Error checking mailbox delegates: $_" -Level Error
        
        Add-DetectionResult -Category "Email" `
                          -CheckName "Mailbox Delegates" `
                          -Description "Check for mailbox delegates" `
                          -IsSuspicious $false `
                          -Details "Error retrieving delegate permissions: $_" `
                          -RecommendedAction "Verify you have appropriate permissions to view mailbox permissions."
    }
}

# Function to check for suspicious admin activity
function Check-SuspiciousAdminActivity {
    Write-DetectionLog "Checking for suspicious admin activity..."
    
    try {
        # Define start date (past X days)
        $startDate = (Get-Date).AddDays(-$DaysToCheck)
        $endDate = Get-Date
        
        # Define suspicious operations
        $suspiciousOperations = @(
            "Add member to role.",
            "Add service principal.",
            "Add user.",
            "Change user password.",
            "Reset user password.",
            "Update StsRefreshTokenValidFrom Timestamp.",
            "Update user."
        )
        
        # Try to get admin activity
        try {
            $adminActivities = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -Operations $suspiciousOperations -ResultSize 500
            
            if ($adminActivities -and $adminActivities.Count -gt 0) {
                $details = "Found $($adminActivities.Count) potentially suspicious admin activities in the past $DaysToCheck days:`n"
                
                # Group by operation
                $operationGroups = $adminActivities | Group-Object Operations
                
                foreach ($group in $operationGroups) {
                    $details += "`n  * Operation: $($group.Name) - Count: $($group.Count)`n"
                    
                    # Show 5 most recent examples for each operation
                    foreach ($activity in ($group.Group | Sort-Object CreationDate -Descending | Select-Object -First 5)) {
                        $auditData = ConvertFrom-Json $activity.AuditData
                        
                        $details += "    - Time: $($activity.CreationDate)`n"
                        $details += "    - User: $($auditData.UserId)`n"
                        
                        if ($auditData.ObjectId) {
                            $details += "    - Target: $($auditData.ObjectId)`n"
                        }
                        
                        if ($auditData.Target) {
                            foreach ($target in $auditData.Target) {
                                $details += "    - Target: $($target.Id) ($($target.Type))`n"
                            }
                        }
                        
                        if ($auditData.ModifiedProperties) {
                            $details += "    - Modified: "
                            $modProps = @()
                            foreach ($prop in $auditData.ModifiedProperties) {
                                $modProps += "$($prop.Name)"
                            }
                            $details += "$($modProps -join ', ')`n"
                        }
                        
                        $details += "`n"
                    }
                }
                
                # Determine if this is suspicious enough to flag
                $isSuspicious = $adminActivities.Count -gt 10
                
                Add-DetectionResult -Category "Admin Activity" `
                                  -CheckName "Administrative Actions" `
                                  -Description "Check for suspicious administrative activities" `
                                  -IsSuspicious $isSuspicious `
                                  -Details $details `
                                  -RecommendedAction $(
                                        if ($isSuspicious) {
                                            "Review administrative activities for unauthorized actions. Verify that each admin action was legitimate."
                                        } else {
                                            "Review administrative activities as part of standard security practices."
                                        }
                                    )
            } else {
                Add-DetectionResult -Category "Admin Activity" `
                                  -CheckName "Administrative Actions" `
                                  -Description "Check for suspicious administrative activities" `
                                  -IsSuspicious $false `
                                  -Details "No suspicious administrative activities found in the past $DaysToCheck days." `
                                  -RecommendedAction "No action required."
            }
        } catch {
            Add-DetectionResult -Category "Admin Activity" `
                              -CheckName "Administrative Actions" `
                              -Description "Check for suspicious administrative activities" `
                              -IsSuspicious $false `
                              -Details "Error retrieving admin audit logs: $_" `
                              -RecommendedAction "Verify you have appropriate permissions to view audit logs and that audit logging is enabled."
        }
    } catch {
        Write-DetectionLog "Error checking admin activity: $_" -Level Error
        
        Add-DetectionResult -Category "Admin Activity" `
                          -CheckName "Administrative Actions" `
                          -Description "Check for suspicious administrative activities" `
                          -IsSuspicious $false `
                          -Details "Error checking administrative activities: $_" `
                          -RecommendedAction "Verify you have appropriate permissions to view audit logs."
    }
}

# Function to check for suspicious Conditional Access changes
function Check-ConditionalAccessChanges {
    Write-DetectionLog "Checking for Conditional Access policy changes..."
    
    try {
        # Define start date (past X days)
        $startDate = (Get-Date).AddDays(-$DaysToCheck)
        $endDate = Get-Date
        
        # Define operations related to Conditional Access
        $caOperations = @(
            "Add policy.",
            "Update policy.",
            "Delete policy."
        )
        
        # Try to get Conditional Access activity
        try {
            $caActivities = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -Operations $caOperations -ResultSize 100
            
            if ($caActivities -and $caActivities.Count -gt 0) {
                $details = "Found $($caActivities.Count) Conditional Access policy changes in the past $DaysToCheck days:`n"
                
                foreach ($activity in ($caActivities | Sort-Object CreationDate -Descending)) {
                    $auditData = ConvertFrom-Json $activity.AuditData
                    
                    $details += "`n  * Operation: $($activity.Operations)`n"
                    $details += "    - Time: $($activity.CreationDate)`n"
                    $details += "    - User: $($auditData.UserId)`n"
                    
                    if ($auditData.ObjectId) {
                        $details += "    - Policy: $($auditData.ObjectId)`n"
                    }
                    
                    if ($auditData.ModifiedProperties) {
                        $details += "    - Modified Properties: "
                        $modProps = @()
                        foreach ($prop in $auditData.ModifiedProperties) {
                            $modProps += "$($prop.Name)"
                        }
                        $details += "$($modProps -join ', ')`n"
                    }
                }
                
                # Determine if this is suspicious - we'll be conservative and just flag it for review
                $isSuspicious = $caActivities.Count -gt 3
                
                Add-DetectionResult -Category "Policy Changes" `
                                  -CheckName "Conditional Access Policies" `
                                  -Description "Check for Conditional Access policy changes" `
                                  -IsSuspicious $isSuspicious `
                                  -Details $details `
                                  -RecommendedAction $(
                                        if ($isSuspicious) {
                                            "Review Conditional Access policy changes to ensure they were authorized. Unauthorized changes could indicate an attempt to create backdoor access."
                                        } else {
                                            "Review Conditional Access policy changes as part of standard security practices."
                                        }
                                    )
            } else {
                Add-DetectionResult -Category "Policy Changes" `
                                  -CheckName "Conditional Access Policies" `
                                  -Description "Check for Conditional Access policy changes" `
                                  -IsSuspicious $false `
                                  -Details "No Conditional Access policy changes found in the past $DaysToCheck days." `
                                  -RecommendedAction "No action required."
            }
        } catch {
            Add-DetectionResult -Category "Policy Changes" `
                              -CheckName "Conditional Access Policies" `
                              -Description "Check for Conditional Access policy changes" `
                              -IsSuspicious $false `
                              -Details "Error retrieving Conditional Access audit logs: $_" `
                              -RecommendedAction "Verify you have appropriate permissions to view audit logs and that audit logging is enabled."
        }
    } catch {
        Write-DetectionLog "Error checking Conditional Access changes: $_" -Level Error
        
        Add-DetectionResult -Category "Policy Changes" `
                          -CheckName "Conditional Access Policies" `
                          -Description "Check for Conditional Access policy changes" `
                          -IsSuspicious $false `
                          -Details "Error checking Conditional Access policy changes: $_" `
                          -RecommendedAction "Verify you have appropriate permissions to view audit logs."
    }
}

# Function to check for suspicious sent emails
function Check-SuspiciousSentEmails {
    param(
        [string]$UPN
    )
    
    Write-DetectionLog "Checking for suspicious sent emails from $UPN..."
    
    try {
        # Define start date (past X days)
        $startDate = (Get-Date).AddDays(-$DaysToCheck)
        $endDate = Get-Date
        
        # Try to get message trace for sent emails
        $sentEmails = Get-MessageTrace -SenderAddress $UPN -StartDate $startDate -EndDate $endDate
        
        if ($sentEmails -and $sentEmails.Count -gt 0) {
            # Group by recipient domain
            $domainGroups = $sentEmails | Group-Object { $_.RecipientAddress.Split('@')[1] } | Sort-Object Count -Descending
            
            # Check if there are unusual recipient patterns
            $totalEmails = $sentEmails.Count
            $externalEmails = $sentEmails | Where-Object { $_.RecipientAddress -notlike '*@*' + $UPN.Split('@')[1] }
            $externalEmailsCount = $externalEmails.Count
            $externalPercentage = [math]::Round(($externalEmailsCount / $totalEmails) * 100, 2)
            
            # Find bulk emails (same subject to multiple recipients)
            $bulkEmails = $sentEmails | Group-Object Subject | Where-Object { $_.Count -gt 10 } | Sort-Object Count -Descending
            
            $details = "Sent email analysis for the past $DaysToCheck days:`n"
            $details += "  * Total emails sent: $totalEmails`n"
            $details += "  * Emails to external domains: $externalEmailsCount (${externalPercentage}%)`n"
            $details += "`nTop recipient domains:`n"
            
            foreach ($domain in ($domainGroups | Select-Object -First 10)) {
                $details += "  * $($domain.Name): $($domain.Count) emails`n"
            }
            
            $isSuspicious = $false
            
            if ($bulkEmails -and $bulkEmails.Count -gt 0) {
                $isSuspicious = $true
                $details += "`nPOTENTIALLY SUSPICIOUS: Bulk emails (same subject to multiple recipients):`n"
                
                foreach ($bulk in ($bulkEmails | Select-Object -First 5)) {
                    $details += "  * Subject: $($bulk.Name)`n"
                    $details += "    - Recipients: $($bulk.Count)`n"
                    $details += "    - First seen: $($bulk.Group[0].Received)`n"
                    
                    # Add sample recipients
                    $sampleRecipients = $bulk.Group | Select-Object -First 5 | ForEach-Object { $_.RecipientAddress }
                    $details += "    - Sample recipients: $($sampleRecipients -join ', ')`n"
                }
            }
            
            # If high volume of external emails and not a normal pattern, flag as suspicious
            if ($externalPercentage -gt 70 -and $externalEmailsCount -gt 20) {
                $isSuspicious = $true
                $details += "`nPOTENTIALLY SUSPICIOUS: High volume of external emails (${externalPercentage}% of total)`n"
            }
            
            Add-DetectionResult -Category "Email" `
                              -CheckName "Sent Emails" `
                              -Description "Check for suspicious sent email patterns" `
                              -IsSuspicious $isSuspicious `
                              -Details $details `
                              -RecommendedAction $(
                                    if ($isSuspicious) {
                                        "Review suspicious sent email patterns. Consider informing recipients about potential compromise and check for malicious inbox rules, forwarding, or delegations."
                                    } else {
                                        "No action required."
                                    }
                                )
        } else {
            Add-DetectionResult -Category "Email" `
                              -CheckName "Sent Emails" `
                              -Description "Check for suspicious sent email patterns" `
                              -IsSuspicious $false `
                              -Details "No sent emails found for the past $DaysToCheck days." `
                              -RecommendedAction "No action required."
        }
    } catch {
        Write-DetectionLog "Error checking sent emails: $_" -Level Error
        
        Add-DetectionResult -Category "Email" `
                          -CheckName "Sent Emails" `
                          -Description "Check for suspicious sent email patterns" `
                          -IsSuspicious $false `
                          -Details "Error retrieving sent emails: $_" `
                          -RecommendedAction "Verify you have appropriate permissions to view message trace data."
    }
}

# Function to check for suspicious audit logs
function Check-SuspiciousAuditLogs {
    param(
        [string]$UPN
    )
    
    Write-DetectionLog "Checking for suspicious audit logs for $UPN..."
    
    try {
        # Define start date (past X days)
        $startDate = (Get-Date).AddDays(-$DaysToCheck)
        $endDate = Get-Date
        
        # Define suspicious operations
        $suspiciousOperations = @(
            "UserLoggedIn",
            "PasswordLogonInitialAuthUsingPassword",
            "Add service principal",
            "Consent to application",
            "Add OAuth2PermissionGrant",
            "Add app role assignment to service principal",
            "Update application - Certificates and secrets management"
        )
        
        # Try to get audit logs
        try {
            $auditLogs = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -UserIds $UPN -Operations $suspiciousOperations -ResultSize 100
            
            if ($auditLogs -and $auditLogs.Count -gt 0) {
                # Group by operation
                $operationGroups = $auditLogs | Group-Object Operations | Sort-Object Count -Descending
                
                $details = "Found audit logs for the past $DaysToCheck days:`n"
                $details += "  * Total relevant audit logs: $($auditLogs.Count)`n"
                $details += "`nOperations breakdown:`n"
                
                foreach ($group in $operationGroups) {
                    $details += "  * $($group.Name): $($group.Count) events`n"
                }
                
                # Look for application consent
                $appConsents = $auditLogs | Where-Object { $_.Operations -eq "Consent to application" }
                
                $isSuspicious = $false
                
                if ($appConsents -and $appConsents.Count -gt 0) {
                    $isSuspicious = $true
                    $details += "`nPOTENTIALLY SUSPICIOUS: Application consent activities found:`n"
                    
                    foreach ($consent in $appConsents) {
                        $auditData = ConvertFrom-Json $consent.AuditData
                        
                        $details += "  * Time: $($consent.CreationDate)`n"
                        
                        if ($auditData.Target) {
                            foreach ($target in $auditData.Target) {
                                $details += "    - App: $($target.Id) ($($target.Type))`n"
                            }
                        }
                        
                        if ($auditData.ModifiedProperties) {
                            $details += "    - Permissions: "
                            $modProps = @()
                            foreach ($prop in $auditData.ModifiedProperties) {
                                if ($prop.Name -eq "ConsentAction") {
                                    $details += "$($prop.NewValue)`n"
                                }
                            }
                        }
                    }
                }
                
                # Look for certificate/secret management
                $certSecretChanges = $auditLogs | Where-Object { $_.Operations -eq "Update application - Certificates and secrets management" }
                
                if ($certSecretChanges -and $certSecretChanges.Count -gt 0) {
                    $isSuspicious = $true
                    $details += "`nPOTENTIALLY SUSPICIOUS: Application certificate/secret changes found:`n"
                    
                    foreach ($change in $certSecretChanges) {
                        $auditData = ConvertFrom-Json $change.AuditData
                        
                        $details += "  * Time: $($change.CreationDate)`n"
                        
                        if ($auditData.Target) {
                            foreach ($target in $auditData.Target) {
                                $details += "    - App: $($target.Id) ($($target.Type))`n"
                            }
                        }
                        
                        if ($auditData.ModifiedProperties) {
                            $details += "    - Changes: "
                            $modProps = @()
                            foreach ($prop in $auditData.ModifiedProperties) {
                                $modProps += "$($prop.Name)"
                            }
                            $details += "$($modProps -join ', ')`n"
                        }
                    }
                }
                
                Add-DetectionResult -Category "User Activity" `
                                  -CheckName "Suspicious Audit Logs" `
                                  -Description "Check for suspicious user activities in audit logs" `
                                  -IsSuspicious $isSuspicious `
                                  -Details $details `
                                  -RecommendedAction $(
                                        if ($isSuspicious) {
                                            "Review suspicious application consent activities. This could indicate OAuth or consent phishing attacks. Consider revoking suspicious application permissions."
                                        } else {
                                            "No suspicious activity detected in audit logs."
                                        }
                                    )
            } else {
                Add-DetectionResult -Category "User Activity" `
                                  -CheckName "Suspicious Audit Logs" `
                                  -Description "Check for suspicious user activities in audit logs" `
                                  -IsSuspicious $false `
                                  -Details "No suspicious audit logs found for the past $DaysToCheck days." `
                                  -RecommendedAction "No action required."
            }
        } catch {
            Add-DetectionResult -Category "User Activity" `
                              -CheckName "Suspicious Audit Logs" `
                              -Description "Check for suspicious user activities in audit logs" `
                              -IsSuspicious $false `
                              -Details "Error retrieving audit logs: $_" `
                              -RecommendedAction "Verify you have appropriate permissions to view audit logs and that audit logging is enabled."
        }
    } catch {
        Write-DetectionLog "Error checking audit logs: $_" -Level Error
        
        Add-DetectionResult -Category "User Activity" `
                          -CheckName "Suspicious Audit Logs" `
                          -Description "Check for suspicious user activities in audit logs" `
                          -IsSuspicious $false `
                          -Details "Error checking audit logs: $_" `
                          -RecommendedAction "Verify you have appropriate permissions to view audit logs."
    }
}

# Function to generate HTML report
function Generate-HTMLReport {
    param(
        [string]$ReportPath
    )
    
    Write-DetectionLog "Generating HTML detection report..."
    
    $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Microsoft 365 Compromise Detection Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f9f9f9; color: #333; }
        .container { width: 95%; margin: 20px auto; }
        h1 { color: #2d5986; }
        .summary { background-color: #fff; padding: 15px; border-radius: 5px; margin-bottom: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        .summary-stats { display: flex; justify-content: space-between; flex-wrap: wrap; }
        .stat-box { text-align: center; padding: 10px; flex: 1; min-width: 150px; margin: 5px; border-radius: 5px; }
        .normal { background-color: #8FED8F; }
        .suspicious { background-color: #FFCCCB; }
        .table-container { overflow-x: auto; }
        table { border-collapse: collapse; width: 100%; background-color: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        th { background-color: $headerColor; color: $headerTextColor; text-align: left; padding: 12px; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background-color: #f5f5f5; }
        .status-normal { background-color: #8FED8F; padding: 5px 10px; border-radius: 3px; }
        .status-suspicious { background-color: #FFCCCB; padding: 5px 10px; border-radius: 3px; }
        .footer { margin-top: 20px; text-align: center; font-size: 0.8em; color: #666; }
        .details { white-space: pre-wrap; font-family: monospace; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Microsoft 365 Compromise Detection Report</h1>
        <p>Report generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        
        <div class="summary">
            <h2>Detection Summary</h2>
            <div class="summary-stats">
                <div class="stat-box normal">
                    <h3>$($script:totalChecks - $script:suspiciousFindings)</h3>
                    <p>NORMAL</p>
                </div>
                <div class="stat-box suspicious">
                    <h3>$script:suspiciousFindings</h3>
                    <p>SUSPICIOUS</p>
                </div>
                <div class="stat-box">
                    <h3>$script:totalChecks</h3>
                    <p>TOTAL</p>
                </div>
            </div>
        </div>
        
        <h2>Detection Results</h2>
        <div class="table-container">
            <table>
                <tr>
                    <th>Category</th>
                    <th>Check</th>
                    <th>Description</th>
                    <th>Status</th>
                    <th>Details</th>
                    <th>Recommended Action</th>
                </tr>
"@

    $htmlRows = ""
    foreach ($check in $detectionReport) {
        $statusClass = if ($check.IsSuspicious) { "status-suspicious" } else { "status-normal" }
        $statusText = if ($check.IsSuspicious) { "SUSPICIOUS" } else { "Normal" }
        $rowClass = if ($check.IsSuspicious) { "suspicious-row" } else { "normal-row" }
        
        $htmlRows += @"
                <tr class="$rowClass">
                    <td>$($check.Category)</td>
                    <td>$($check.CheckName)</td>
                    <td>$($check.Description)</td>
                    <td><span class="$statusClass">$statusText</span></td>
                    <td><div class="details">$($check.Details)</div></td>
                    <td>$($check.RecommendedAction)</td>
                </tr>
"@
    }

    $htmlFooter = @"
            </table>
        </div>
        
        <div class="footer">
            <p>Detect-M365Compromise.ps1 - Generated by Microsoft 365 Compromise Detection Tool</p>
        </div>
    </div>
</body>
</html>
"@

    $fullHTML = $htmlHeader + $htmlRows + $htmlFooter
    $fullHTML | Out-File -FilePath $ReportPath -Force
    
    Write-DetectionLog "HTML report saved to: $ReportPath" -Level Success
}

# Main execution flow
Write-DetectionLog "Microsoft 365 Compromise Detection Tool" -Level Info
Write-DetectionLog "Starting detection checks on $(Get-Date)" -Level Info

if (Test-Prerequisites) {
    # Run checks
    if ($CheckAll -or $CheckAllUsers) {
        # If checking all users, get list of users
        try {
            $allUsers = Get-MsolUser -MaxResults 1000 | Where-Object { $_.IsLicensed -eq $true }
            
            if ($allUsers -and $allUsers.Count -gt 0) {
                Write-DetectionLog "Found $($allUsers.Count) licensed users to check" -Level Info
                
                foreach ($user in $allUsers) {
                    $upn = $user.UserPrincipalName
                    Write-DetectionLog "Checking user: $upn" -Level Info
                    
                    # Run per-user checks
                    Check-SuspiciousSignIns -UPN $upn
                    Check-SuspiciousInboxRules -UPN $upn
                    Check-SuspiciousForwarding -UPN $upn
                    
                    if ($CheckAll -or $CheckDelegates) {
                        Check-SuspiciousDelegates -UPN $upn
                    }
                    
                    if ($CheckAll -or $CheckAuditLogs) {
                        Check-SuspiciousAuditLogs -UPN $upn
                    }
                    
                    Check-SuspiciousSentEmails -UPN $upn
                }
            } else {
                Write-DetectionLog "No licensed users found or you don't have permission to list users" -Level Warning
            }
        } catch {
            Write-DetectionLog "Error getting users: $_" -Level Error
            
            if ($UserToCheck) {
                Write-DetectionLog "Falling back to checking specified user: $UserToCheck" -Level Warning
                
                # Run per-user checks for specified user
                Check-SuspiciousSignIns -UPN $UserToCheck
                Check-SuspiciousInboxRules -UPN $UserToCheck
                Check-SuspiciousForwarding -UPN $UserToCheck
                
                if ($CheckAll -or $CheckDelegates) {
                    Check-SuspiciousDelegates -UPN $UserToCheck
                }
                
                if ($CheckAll -or $CheckAuditLogs) {
                    Check-SuspiciousAuditLogs -UPN $UserToCheck
                }
                
                Check-SuspiciousSentEmails -UPN $UserToCheck
            }
        }
    } elseif ($UserToCheck) {
        Write-DetectionLog "Checking specified user: $UserToCheck" -Level Info
        
        # Run per-user checks for specified user
        Check-SuspiciousSignIns -UPN $UserToCheck
        Check-SuspiciousInboxRules -UPN $UserToCheck
        Check-SuspiciousForwarding -UPN $UserToCheck
        
        if ($CheckAll -or $CheckDelegates) {
            Check-SuspiciousDelegates -UPN $UserToCheck
        }
        
        if ($CheckAll -or $CheckAuditLogs) {
            Check-SuspiciousAuditLogs -UPN $UserToCheck
        }
        
        Check-SuspiciousSentEmails -UPN $UserToCheck
    }
    
    # Run global checks
    if ($CheckAll -or $CheckAdminActivity) {
        Check-SuspiciousAdminActivity
    }
    
    if ($CheckAll -or $CheckConditionalAccess) {
        Check-ConditionalAccessChanges
    }
    
    # Generate HTML report
    Generate-HTMLReport -ReportPath $ReportPath
    
    # Disconnect from services
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        Disconnect-AzureAD -ErrorAction SilentlyContinue
        Write-DetectionLog "Disconnected from Microsoft 365 services" -Level Info
    } catch {
        Write-DetectionLog "Error disconnecting from services: $_" -Level Warning
    }
    
    # Summary
    Write-DetectionLog "`n======================================================" -Level Info
    Write-DetectionLog "COMPROMISE DETECTION SUMMARY" -Level Info
    Write-DetectionLog "======================================================" -Level Info
    Write-DetectionLog "Total Checks: $script:totalChecks" -Level Info
    Write-DetectionLog "Normal: $($script:totalChecks - $script:suspiciousFindings)" -Level Success
    Write-DetectionLog "Suspicious: $script:suspiciousFindings" -Level $(if ($script:suspiciousFindings -gt 0) { "Suspicious" } else { "Success" })
    Write-DetectionLog "Report saved to: $ReportPath" -Level Info
    
    # Open the report
    if (Test-Path $ReportPath) {
        Write-DetectionLog "Opening report..." -Level Info
        Start-Process $ReportPath
    }
} else {
    Write-DetectionLog "Prerequisites check failed. Cannot continue." -Level Error
}
