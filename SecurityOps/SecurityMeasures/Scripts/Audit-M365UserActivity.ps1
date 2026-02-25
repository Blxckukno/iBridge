# Audit-M365UserActivity.ps1
# Purpose: Comprehensive user account activity auditing for Microsoft 365
# This script helps identify suspicious account activities, permission changes,
# and geographic login patterns that may indicate account compromise

param(
    [Parameter(Mandatory=$false)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory=$false)]
    [switch]$AllUsers,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysToLookBack = 30,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\M365AuditReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

# Functions for logging
function Write-LogEntry {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with color based on level
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor White }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
    }
}

# Check prerequisites
function Check-Prerequisites {
    $requiredModules = @("ExchangeOnlineManagement", "AzureAD", "MSOnline")
    $allModulesPresent = $true
    
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-LogEntry "Required module not found: $module" -Level Error
            Write-LogEntry "Install it with: Install-Module -Name $module -Force" -Level Info
            $allModulesPresent = $false
        }
    }
    
    if (!$allModulesPresent) {
        Write-LogEntry "Missing required modules. Please install them and try again." -Level Error
        exit 1
    }
    
    # Validate parameters
    if (!$UserPrincipalName -and !$AllUsers) {
        Write-LogEntry "You must specify either a UserPrincipalName or use the -AllUsers switch." -Level Error
        exit 1
    }
    
    # Connect to required services
    try {
        Write-LogEntry "Connecting to Exchange Online..." -Level Info
        Connect-ExchangeOnline -ErrorAction Stop
        
        Write-LogEntry "Connecting to Azure AD..." -Level Info
        Connect-AzureAD -ErrorAction Stop
        
        Write-LogEntry "Connecting to MSOnline Service..." -Level Info
        Connect-MsolService -ErrorAction Stop
        
        return $true
    }
    catch {
        Write-LogEntry "Failed to connect to one or more Microsoft 365 services: $_" -Level Error
        return $false
    }
}

# Function to analyze login activities
function Get-UserLoginActivity {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    Write-LogEntry "Analyzing login activities for $UserPrincipalName..." -Level Info
    
    try {
        # Get the user object
        $user = Get-AzureADUser -Filter "UserPrincipalName eq '$UserPrincipalName'"
        if (!$user) {
            Write-LogEntry "User $UserPrincipalName not found in Azure AD" -Level Error
            return $null
        }
        
        # Get sign-in logs - Note: This requires Azure AD Premium P1/P2
        $startDate = (Get-Date).AddDays(-$DaysToLookBack)
        $loginActivities = @()
        
        try {
            $signInLogs = Get-AzureADAuditSignInLogs -Filter "userId eq '$($user.ObjectId)'" -Top 100
            
            if ($signInLogs -and $signInLogs.Count -gt 0) {
                Write-LogEntry "Retrieved $($signInLogs.Count) login events" -Level Info
                
                foreach ($log in $signInLogs) {
                    $loginData = [PSCustomObject]@{
                        UserPrincipalName = $UserPrincipalName
                        Timestamp = $log.CreatedDateTime
                        IPAddress = $log.IpAddress
                        Location = "$($log.Location.City), $($log.Location.CountryOrRegion)"
                        DeviceDetail = $log.DeviceDetail.DisplayName
                        Application = $log.AppDisplayName
                        ClientApp = $log.ClientAppUsed
                        Status = $log.Status.ErrorCode
                        FailureReason = $log.Status.FailureReason
                        ConditionalAccessStatus = $log.ConditionalAccessStatus
                        IsInteractive = $log.IsInteractive
                        RiskLevel = $log.RiskLevel
                        RiskState = $log.RiskState
                        RiskDetail = $log.RiskDetail
                    }
                    
                    # Flag suspicious activities
                    $suspicious = $false
                    $reason = ""
                    
                    # Failed login attempt
                    if ($log.Status.ErrorCode -ne 0) {
                        $suspicious = $true
                        $reason += "Failed login; "
                    }
                    
                    # Check for risk level
                    if ($log.RiskLevel -in @("high", "medium")) {
                        $suspicious = $true
                        $reason += "Risk level: $($log.RiskLevel); "
                    }
                    
                    # Add to the activity log
                    Add-Member -InputObject $loginData -MemberType NoteProperty -Name "Suspicious" -Value $suspicious
                    Add-Member -InputObject $loginData -MemberType NoteProperty -Name "SuspiciousReason" -Value $reason
                    $loginActivities += $loginData
                    
                    # Report suspicious activities
                    if ($suspicious) {
                        Write-LogEntry "Suspicious login detected: $($log.CreatedDateTime) from $($log.IpAddress) ($($log.Location.City), $($log.Location.CountryOrRegion)) - $reason" -Level Warning
                    }
                }
            } else {
                Write-LogEntry "No login activities found for $UserPrincipalName in the past $DaysToLookBack days" -Level Info
            }
            
            return $loginActivities
        }
        catch {
            Write-LogEntry "Error retrieving sign-in logs (may require Azure AD P1/P2): $_" -Level Warning
            return @()
        }
    }
    catch {
        Write-LogEntry "Error processing login activities: $_" -Level Error
        return @()
    }
}

# Function to analyze permission changes
function Get-UserPermissionChanges {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    Write-LogEntry "Analyzing permission changes for $UserPrincipalName..." -Level Info
    
    try {
        # Get the mailbox permissions
        $mailboxPermissions = Get-MailboxPermission -Identity $UserPrincipalName | Where-Object {
            $_.IsInherited -eq $false -and $_.User -ne "NT AUTHORITY\SELF" -and $_.User -notlike "S-1-5-*"
        }
        
        $permissionChanges = @()
        
        if ($mailboxPermissions) {
            foreach ($perm in $mailboxPermissions) {
                $permData = [PSCustomObject]@{
                    UserPrincipalName = $UserPrincipalName
                    DelegateUser = $perm.User
                    AccessRights = ($perm.AccessRights -join ", ")
                    PermissionType = "Mailbox Permission"
                    IsInherited = $perm.IsInherited
                    Deny = $perm.Deny
                    InheritanceType = $perm.InheritanceType
                }
                $permissionChanges += $permData
                
                Write-LogEntry "Mailbox permission: $($perm.User) has $($perm.AccessRights) access to $UserPrincipalName's mailbox" -Level Info
            }
        }
        
        # Get send-as permissions
        $sendAsPermissions = Get-RecipientPermission -Identity $UserPrincipalName | Where-Object {
            $_.Trustee -ne "NT AUTHORITY\SELF" -and $_.Trustee -notlike "S-1-5-*"
        }
        
        if ($sendAsPermissions) {
            foreach ($perm in $sendAsPermissions) {
                $permData = [PSCustomObject]@{
                    UserPrincipalName = $UserPrincipalName
                    DelegateUser = $perm.Trustee
                    AccessRights = ($perm.AccessRights -join ", ")
                    PermissionType = "Send As Permission"
                    IsInherited = $false
                    Deny = $false
                    InheritanceType = "None"
                }
                $permissionChanges += $permData
                
                Write-LogEntry "Send As permission: $($perm.Trustee) has $($perm.AccessRights) rights to $UserPrincipalName" -Level Warning
            }
        }
        
        # Get send-on-behalf permissions
        $mailbox = Get-Mailbox -Identity $UserPrincipalName
        if ($mailbox.GrantSendOnBehalfTo) {
            foreach ($delegate in $mailbox.GrantSendOnBehalfTo) {
                $permData = [PSCustomObject]@{
                    UserPrincipalName = $UserPrincipalName
                    DelegateUser = $delegate.ToString()
                    AccessRights = "SendOnBehalf"
                    PermissionType = "Send On Behalf Permission"
                    IsInherited = $false
                    Deny = $false
                    InheritanceType = "None"
                }
                $permissionChanges += $permData
                
                Write-LogEntry "Send On Behalf permission: $delegate has rights to $UserPrincipalName" -Level Warning
            }
        }
        
        # Attempt to get audit logs for permission changes (requires E5 or additional licenses)
        try {
            $startDate = (Get-Date).AddDays(-$DaysToLookBack)
            $endDate = Get-Date
            
            # This requires appropriate licensing and permissions
            $auditLogs = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -RecordType ExchangeAdmin -Operations "Add-MailboxPermission", "Remove-MailboxPermission" -UserIds $UserPrincipalName -ResultSize 1000
            
            if ($auditLogs -and $auditLogs.Count -gt 0) {
                Write-LogEntry "Found $($auditLogs.Count) permission change audit records" -Level Info
                
                foreach ($log in $auditLogs) {
                    $auditData = ConvertFrom-Json $log.AuditData
                    
                    $permData = [PSCustomObject]@{
                        UserPrincipalName = $UserPrincipalName
                        Timestamp = $log.CreationDate
                        Operation = $auditData.Operation
                        DelegateUser = $auditData.Parameters | Where-Object { $_.Name -eq "User" } | Select-Object -ExpandProperty Value
                        AccessRights = ($auditData.Parameters | Where-Object { $_.Name -eq "AccessRights" } | Select-Object -ExpandProperty Value)
                        PermissionType = "Audit Log: " + $auditData.Operation
                    }
                    $permissionChanges += $permData
                    
                    Write-LogEntry "Permission change audit: $($auditData.Operation) performed on $UserPrincipalName's mailbox at $($log.CreationDate)" -Level Warning
                }
            }
        }
        catch {
            Write-LogEntry "Unable to retrieve permission change audit logs (may require E5 license): $_" -Level Warning
        }
        
        return $permissionChanges
    }
    catch {
        Write-LogEntry "Error processing permission changes: $_" -Level Error
        return @()
    }
}

# Function to get mailbox settings and rules
function Get-MailboxConfiguration {
    param(
        [string]$UserPrincipalName
    )
    
    Write-LogEntry "Retrieving mailbox configuration for $UserPrincipalName..." -Level Info
    
    try {
        # Get mailbox information
        $mailbox = Get-Mailbox -Identity $UserPrincipalName
        
        # Get inbox rules
        $inboxRules = Get-InboxRule -Mailbox $UserPrincipalName
        $rulesData = @()
        
        if ($inboxRules) {
            foreach ($rule in $inboxRules) {
                # Check for suspicious rules
                $suspicious = $false
                $reason = ""
                
                if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo -or $rule.RedirectTo) {
                    $suspicious = $true
                    $reason += "Email forwarding; "
                }
                
                if ($rule.DeleteMessage -eq $true) {
                    $suspicious = $true
                    $reason += "Auto-delete; "
                }
                
                if ($rule.MoveToFolder -match "Deleted Items|Junk|RSS") {
                    $suspicious = $true
                    $reason += "Move to $($rule.MoveToFolder); "
                }
                
                $ruleData = [PSCustomObject]@{
                    UserPrincipalName = $UserPrincipalName
                    RuleName = $rule.Name
                    Description = $rule.Description
                    Enabled = $rule.Enabled
                    Priority = $rule.Priority
                    ForwardTo = $rule.ForwardTo -join ", "
                    RedirectTo = $rule.RedirectTo -join ", "
                    DeleteMessage = $rule.DeleteMessage
                    MoveToFolder = $rule.MoveToFolder
                    Conditions = ($rule.Conditions | ConvertTo-Json -Depth 2 -Compress)
                    Suspicious = $suspicious
                    SuspiciousReason = $reason
                }
                $rulesData += $ruleData
                
                if ($suspicious) {
                    Write-LogEntry "SUSPICIOUS RULE DETECTED: $($rule.Name) - $reason" -Level Warning
                }
            }
        }
        
        # Get auto-forwarding settings
        $forwardingSMTP = $mailbox.ForwardingSmtpAddress
        $forwardingAddress = $mailbox.ForwardingAddress
        
        if ($forwardingSMTP -or $forwardingAddress) {
            Write-LogEntry "WARNING: Mailbox forwarding is enabled for $UserPrincipalName" -Level Warning
            if ($forwardingSMTP) {
                Write-LogEntry "  Forwarding to SMTP address: $forwardingSMTP" -Level Warning
            }
            if ($forwardingAddress) {
                Write-LogEntry "  Forwarding to address: $forwardingAddress" -Level Warning
            }
        }
        
        # Return configuration data
        return @{
            Mailbox = $mailbox
            InboxRules = $rulesData
            ForwardingSMTP = $forwardingSMTP
            ForwardingAddress = $forwardingAddress
        }
    }
    catch {
        Write-LogEntry "Error retrieving mailbox configuration: $_" -Level Error
        return $null
    }
}

# Function to analyze recent device activities
function Get-UserDeviceActivity {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    Write-LogEntry "Analyzing device activities for $UserPrincipalName..." -Level Info
    
    try {
        # Get the user object
        $user = Get-AzureADUser -Filter "UserPrincipalName eq '$UserPrincipalName'"
        if (!$user) {
            Write-LogEntry "User $UserPrincipalName not found in Azure AD" -Level Error
            return @()
        }
        
        # Get registered devices
        $devices = Get-AzureADUserRegisteredDevice -ObjectId $user.ObjectId
        $deviceActivities = @()
        
        if ($devices -and $devices.Count -gt 0) {
            Write-LogEntry "Found $($devices.Count) registered devices for $UserPrincipalName" -Level Info
            
            foreach ($device in $devices) {
                $deviceData = [PSCustomObject]@{
                    UserPrincipalName = $UserPrincipalName
                    DeviceName = $device.DisplayName
                    DeviceId = $device.DeviceId
                    DeviceOS = $device.DeviceOSType
                    DeviceOSVersion = $device.DeviceOSVersion
                    ApproximateLastLogon = $device.ApproximateLastLogonTimestamp
                    TrustType = $device.DeviceTrustType
                    IsCompliant = $device.IsCompliant
                    IsManaged = $device.IsManaged
                }
                $deviceActivities += $deviceData
                
                # Check suspicious timing
                $recentDevice = $false
                if ($device.ApproximateLastLogonTimestamp -gt (Get-Date).AddDays(-7)) {
                    $recentDevice = $true
                    Write-LogEntry "Recent device activity: $($device.DisplayName) ($($device.DeviceOSType)) last active on $($device.ApproximateLastLogonTimestamp)" -Level Info
                }
                
                # Check compliance status
                if ($device.IsCompliant -eq $false -and $recentDevice) {
                    Write-LogEntry "WARNING: Non-compliant device recently used: $($device.DisplayName)" -Level Warning
                }
            }
        } else {
            Write-LogEntry "No registered devices found for $UserPrincipalName" -Level Info
        }
        
        return $deviceActivities
    }
    catch {
        Write-LogEntry "Error processing device activities: $_" -Level Error
        return @()
    }
}

# Function to get MFA status
function Get-UserMFAStatus {
    param(
        [string]$UserPrincipalName
    )
    
    Write-LogEntry "Checking MFA status for $UserPrincipalName..." -Level Info
    
    try {
        # Get MFA status from MSOnline
        $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName
        
        if ($msolUser) {
            $mfaStatus = $msolUser.StrongAuthenticationRequirements
            $methodDetails = $msolUser.StrongAuthenticationMethods
            $mfaPhone = $msolUser.StrongAuthenticationUserDetails.PhoneNumber
            $mfaEmail = $msolUser.StrongAuthenticationUserDetails.Email
            
            $mfaData = [PSCustomObject]@{
                UserPrincipalName = $UserPrincipalName
                MFAEnabled = ($mfaStatus -and $mfaStatus.Count -gt 0)
                MFAState = if ($mfaStatus -and $mfaStatus.Count -gt 0) { $mfaStatus[0].State } else { "Disabled" }
                DefaultMethod = ($methodDetails | Where-Object { $_.IsDefault -eq $true } | Select-Object -ExpandProperty MethodType)
                PhoneNumber = $mfaPhone
                AlternateEmail = $mfaEmail
                MethodCount = ($methodDetails | Measure-Object).Count
                Methods = ($methodDetails | ForEach-Object { $_.MethodType }) -join ", "
            }
            
            if ($mfaData.MFAEnabled) {
                Write-LogEntry "MFA is enabled for $UserPrincipalName. State: $($mfaData.MFAState)" -Level Info
                Write-LogEntry "  Default method: $($mfaData.DefaultMethod)" -Level Info
            } else {
                Write-LogEntry "WARNING: MFA is NOT enabled for $UserPrincipalName!" -Level Warning
            }
            
            return $mfaData
        } else {
            Write-LogEntry "User $UserPrincipalName not found in MSOnline service" -Level Error
            return $null
        }
    }
    catch {
        Write-LogEntry "Error checking MFA status: $_" -Level Error
        return $null
    }
}

# Function to generate a comprehensive security report for a user
function Generate-UserSecurityReport {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    Write-LogEntry "Generating comprehensive security report for $UserPrincipalName..." -Level Info
    
    $report = [PSCustomObject]@{
        UserPrincipalName = $UserPrincipalName
        GeneratedDate = Get-Date
        LookbackPeriod = $DaysToLookBack
    }
    
    # Get basic user info
    try {
        $user = Get-MsolUser -UserPrincipalName $UserPrincipalName
        $mailbox = Get-Mailbox -Identity $UserPrincipalName
        
        Add-Member -InputObject $report -MemberType NoteProperty -Name "DisplayName" -Value $user.DisplayName
        Add-Member -InputObject $report -MemberType NoteProperty -Name "IsAdmin" -Value ($user.IsLicensed)
        Add-Member -InputObject $report -MemberType NoteProperty -Name "LastPasswordChange" -Value $user.LastPasswordChangeTimestamp
        Add-Member -InputObject $report -MemberType NoteProperty -Name "PasswordNeverExpires" -Value $user.PasswordNeverExpires
        Add-Member -InputObject $report -MemberType NoteProperty -Name "LicenseStatus" -Value $user.IsLicensed
        Add-Member -InputObject $report -MemberType NoteProperty -Name "Licenses" -Value (($user.Licenses | ForEach-Object { $_.AccountSkuId }) -join ", ")
    }
    catch {
        Write-LogEntry "Error retrieving basic user info: $_" -Level Error
    }
    
    # Get MFA status
    $mfaStatus = Get-UserMFAStatus -UserPrincipalName $UserPrincipalName
    Add-Member -InputObject $report -MemberType NoteProperty -Name "MFAEnabled" -Value $mfaStatus.MFAEnabled
    Add-Member -InputObject $report -MemberType NoteProperty -Name "MFAState" -Value $mfaStatus.MFAState
    Add-Member -InputObject $report -MemberType NoteProperty -Name "MFADefaultMethod" -Value $mfaStatus.DefaultMethod
    
    # Get mailbox configuration
    $mailboxConfig = Get-MailboxConfiguration -UserPrincipalName $UserPrincipalName
    $suspiciousRules = $mailboxConfig.InboxRules | Where-Object { $_.Suspicious -eq $true }
    Add-Member -InputObject $report -MemberType NoteProperty -Name "HasForwarding" -Value ($mailboxConfig.ForwardingSMTP -or $mailboxConfig.ForwardingAddress)
    Add-Member -InputObject $report -MemberType NoteProperty -Name "ForwardingTarget" -Value (
        if ($mailboxConfig.ForwardingSMTP) { $mailboxConfig.ForwardingSMTP } elseif ($mailboxConfig.ForwardingAddress) { $mailboxConfig.ForwardingAddress } else { $null }
    )
    Add-Member -InputObject $report -MemberType NoteProperty -Name "TotalRules" -Value ($mailboxConfig.InboxRules | Measure-Object).Count
    Add-Member -InputObject $report -MemberType NoteProperty -Name "SuspiciousRules" -Value ($suspiciousRules | Measure-Object).Count
    Add-Member -InputObject $report -MemberType NoteProperty -Name "SuspiciousRuleDetails" -Value ($suspiciousRules | ForEach-Object { "$($_.RuleName): $($_.SuspiciousReason)" } -join "; ")
    
    # Get permissions data
    $permissionsData = Get-UserPermissionChanges -UserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
    Add-Member -InputObject $report -MemberType NoteProperty -Name "TotalDelegates" -Value ($permissionsData | Measure-Object).Count
    Add-Member -InputObject $report -MemberType NoteProperty -Name "DelegatesList" -Value (($permissionsData | ForEach-Object { "$($_.DelegateUser) ($($_.PermissionType))" }) -join "; ")
    
    # Get login data
    $loginActivities = Get-UserLoginActivity -UserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
    $suspiciousLogins = $loginActivities | Where-Object { $_.Suspicious -eq $true }
    Add-Member -InputObject $report -MemberType NoteProperty -Name "TotalLogins" -Value ($loginActivities | Measure-Object).Count
    Add-Member -InputObject $report -MemberType NoteProperty -Name "SuspiciousLogins" -Value ($suspiciousLogins | Measure-Object).Count
    Add-Member -InputObject $report -MemberType NoteProperty -Name "UniqueIPs" -Value (($loginActivities | Select-Object -ExpandProperty IPAddress -Unique | Measure-Object).Count)
    Add-Member -InputObject $report -MemberType NoteProperty -Name "UniqueLocations" -Value (($loginActivities | Select-Object -ExpandProperty Location -Unique | Measure-Object).Count)
    Add-Member -InputObject $report -MemberType NoteProperty -Name "UniqueDevices" -Value (($loginActivities | Select-Object -ExpandProperty DeviceDetail -Unique | Where-Object { $_ } | Measure-Object).Count)
    
    # Get device data
    $deviceActivities = Get-UserDeviceActivity -UserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
    Add-Member -InputObject $report -MemberType NoteProperty -Name "RegisteredDevices" -Value ($deviceActivities | Measure-Object).Count
    
    # Overall security score and risk assessment
    $riskFactors = 0
    $riskReasons = @()
    
    # Check MFA
    if (!$mfaStatus.MFAEnabled) {
        $riskFactors += 3
        $riskReasons += "No MFA"
    }
    
    # Check suspicious rules
    if (($suspiciousRules | Measure-Object).Count -gt 0) {
        $riskFactors += 3
        $riskReasons += "$($suspiciousRules.Count) suspicious inbox rules"
    }
    
    # Check forwarding
    if ($report.HasForwarding) {
        $riskFactors += 3
        $riskReasons += "Email forwarding enabled"
    }
    
    # Check delegates
    if ($report.TotalDelegates -gt 0) {
        $riskFactors += 1
        $riskReasons += "$($report.TotalDelegates) delegates with mailbox access"
    }
    
    # Check suspicious logins
    if ($suspiciousLogins.Count -gt 0) {
        $riskFactors += 2
        $riskReasons += "$($suspiciousLogins.Count) suspicious login attempts"
    }
    
    # Check password policy
    if ($report.PasswordNeverExpires) {
        $riskFactors += 1
        $riskReasons += "Password never expires"
    }
    
    # Set risk level
    $riskLevel = if ($riskFactors -ge 5) {
        "High"
    } elseif ($riskFactors -ge 3) {
        "Medium"
    } elseif ($riskFactors -ge 1) {
        "Low"
    } else {
        "Minimal"
    }
    
    Add-Member -InputObject $report -MemberType NoteProperty -Name "RiskLevel" -Value $riskLevel
    Add-Member -InputObject $report -MemberType NoteProperty -Name "RiskFactors" -Value $riskFactors
    Add-Member -InputObject $report -MemberType NoteProperty -Name "RiskReasons" -Value ($riskReasons -join ", ")
    
    # Display summary findings
    Write-LogEntry "========== SECURITY ASSESSMENT FOR $UserPrincipalName ==========" -Level Info
    Write-LogEntry "Risk Level: $riskLevel" -Level $(if ($riskLevel -eq "High") { "Error" } elseif ($riskLevel -eq "Medium") { "Warning" } else { "Info" })
    if ($riskReasons.Count -gt 0) {
        Write-LogEntry "Risk factors:" -Level Warning
        foreach ($reason in $riskReasons) {
            Write-LogEntry " - $reason" -Level Warning
        }
    }
    Write-LogEntry "MFA Enabled: $($mfaStatus.MFAEnabled)" -Level $(if ($mfaStatus.MFAEnabled) { "Info" } else { "Warning" })
    Write-LogEntry "Email Forwarding: $($report.HasForwarding)" -Level $(if ($report.HasForwarding) { "Warning" } else { "Info" })
    if ($report.HasForwarding) {
        Write-LogEntry " - Forwarded to: $($report.ForwardingTarget)" -Level Warning
    }
    Write-LogEntry "Suspicious Rules: $($report.SuspiciousRules)" -Level $(if ($report.SuspiciousRules -gt 0) { "Warning" } else { "Info" })
    Write-LogEntry "Delegates with Access: $($report.TotalDelegates)" -Level $(if ($report.TotalDelegates -gt 0) { "Warning" } else { "Info" })
    Write-LogEntry "Suspicious Logins: $($report.SuspiciousLogins)" -Level $(if ($report.SuspiciousLogins -gt 0) { "Warning" } else { "Info" })
    Write-LogEntry "========== END OF ASSESSMENT ==========" -Level Info
    
    return $report
}

# Main execution function
function Start-M365AuditProcess {
    # Check prerequisites and establish connections
    if (-not (Check-Prerequisites)) {
        Write-LogEntry "Failed to establish required connections. Exiting." -Level Error
        return
    }
    
    $allReports = @()
    
    if ($UserPrincipalName) {
        # Process single user
        Write-LogEntry "Starting audit for $UserPrincipalName" -Level Info
        $report = Generate-UserSecurityReport -UserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
        $allReports += $report
    }
    elseif ($AllUsers) {
        # Process all users
        Write-LogEntry "Starting audit for all licensed users" -Level Info
        
        # Get all licensed users
        $users = Get-MsolUser -All | Where-Object { $_.IsLicensed -eq $true }
        $totalUsers = ($users | Measure-Object).Count
        
        Write-LogEntry "Found $totalUsers licensed users" -Level Info
        $processedCount = 0
        
        foreach ($user in $users) {
            $processedCount++
            $percentComplete = [math]::Round(($processedCount / $totalUsers) * 100, 2)
            Write-LogEntry "[$percentComplete%] Processing $($user.UserPrincipalName) ($processedCount of $totalUsers)" -Level Info
            
            $report = Generate-UserSecurityReport -UserPrincipalName $user.UserPrincipalName -DaysToLookBack $DaysToLookBack
            $allReports += $report
        }
    }
    
    # Export report to CSV
    if ($allReports.Count -gt 0) {
        $allReports | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-LogEntry "Audit report exported to $OutputPath" -Level Info
        
        # Identify high-risk accounts
        $highRiskAccounts = $allReports | Where-Object { $_.RiskLevel -eq "High" }
        if ($highRiskAccounts.Count -gt 0) {
            Write-LogEntry "ATTENTION: $($highRiskAccounts.Count) high-risk accounts identified!" -Level Error
            foreach ($account in $highRiskAccounts) {
                Write-LogEntry "High risk: $($account.UserPrincipalName) - $($account.RiskReasons)" -Level Error
            }
        }
    } else {
        Write-LogEntry "No reports were generated" -Level Warning
    }
    
    # Disconnect sessions
    try {
        Disconnect-ExchangeOnline -Confirm:$false
        Disconnect-AzureAD
        Write-LogEntry "Disconnected from Microsoft 365 services" -Level Info
    } catch {
        Write-LogEntry "Error disconnecting from services: $_" -Level Warning
    }
}

# Start the audit process
Start-M365AuditProcess
