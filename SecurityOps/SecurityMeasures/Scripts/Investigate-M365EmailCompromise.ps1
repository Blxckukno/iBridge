# Investigate-M365EmailCompromise.ps1
# Purpose: Investigate potential Microsoft 365 email account compromise
# This script helps detect suspicious email sending, inbox rules, delegate permissions,
# and other indicators of compromise in Microsoft 365 accounts

# Required modules: ExchangeOnlineManagement, AzureAD, MSOnline
# Run as a Global Administrator or Security Administrator

param(
    [Parameter(Mandatory=$true)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysToLookBack = 7,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\M365SecurityInvestigation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

function Write-LogMessage {
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
    
    # Write to log file
    Add-Content -Path $OutputPath -Value $logMessage
}

function Test-ModuleInstalled {
    param(
        [string]$ModuleName
    )
    
    if (Get-Module -ListAvailable -Name $ModuleName) {
        Write-LogMessage "Module $ModuleName is installed" -Level Info
        return $true
    } else {
        Write-LogMessage "Module $ModuleName is not installed" -Level Error
        return $false
    }
}

function Connect-RequiredServices {
    # Connect to Exchange Online
    try {
        Write-LogMessage "Connecting to Exchange Online..." -Level Info
        Connect-ExchangeOnline -ErrorAction Stop
        Write-LogMessage "Successfully connected to Exchange Online" -Level Info
    }
    catch {
        Write-LogMessage "Failed to connect to Exchange Online: $_" -Level Error
        return $false
    }
    
    # Connect to Azure AD
    try {
        Write-LogMessage "Connecting to Azure AD..." -Level Info
        Connect-AzureAD -ErrorAction Stop
        Write-LogMessage "Successfully connected to Azure AD" -Level Info
    }
    catch {
        Write-LogMessage "Failed to connect to Azure AD: $_" -Level Error
    }
    
    # Connect to MSOL Service
    try {
        Write-LogMessage "Connecting to MSOnline Service..." -Level Info
        Connect-MsolService -ErrorAction Stop
        Write-LogMessage "Successfully connected to MSOnline Service" -Level Info
    }
    catch {
        Write-LogMessage "Failed to connect to MSOnline Service: $_" -Level Error
    }
    
    return $true
}

function Get-SentEmails {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    $startDate = (Get-Date).AddDays(-$DaysToLookBack)
    $endDate = Get-Date
    
    Write-LogMessage "Retrieving sent emails for $UserPrincipalName from $startDate to $endDate..." -Level Info
    
    try {
        # Search for sent emails in the specified time range
        $searchName = "SentItems_$($UserPrincipalName.Split('@')[0])_$(Get-Date -Format 'yyyyMMddHHmmss')"
        $searchQuery = "Sent:$startDate..$endDate AND From:$UserPrincipalName"
        
        New-ComplianceSearch -Name $searchName -ExchangeLocation $UserPrincipalName -ContentMatchQuery $searchQuery | Out-Null
        Start-ComplianceSearch -Identity $searchName | Out-Null
        
        # Wait for search to complete
        $searchStatus = Get-ComplianceSearch -Identity $searchName
        while ($searchStatus.Status -ne "Completed") {
            Write-LogMessage "Search in progress... Current status: $($searchStatus.Status)" -Level Info
            Start-Sleep -Seconds 5
            $searchStatus = Get-ComplianceSearch -Identity $searchName
        }
        
        Write-LogMessage "Sent email search completed. Found $($searchStatus.Items) items." -Level Info
        
        # Get more details if there are results
        if ($searchStatus.Items -gt 0) {
            $results = Get-ComplianceSearch -Identity $searchName | Select-Object -ExpandProperty SuccessResults
            Write-LogMessage "Email details: $results" -Level Info
            return $results
        } else {
            Write-LogMessage "No sent emails found in the specified time range." -Level Info
            return $null
        }
    }
    catch {
        Write-LogMessage "Error retrieving sent emails: $_" -Level Error
        return $null
    }
}

function Get-InboxRules {
    param(
        [string]$UserPrincipalName
    )
    
    Write-LogMessage "Checking inbox rules for $UserPrincipalName..." -Level Info
    
    try {
        $rules = Get-InboxRule -Mailbox $UserPrincipalName
        
        if ($rules) {
            foreach ($rule in $rules) {
                # Check for suspicious rules (forwarding, deleting, etc.)
                $suspicious = $false
                $reason = ""
                
                if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo -or $rule.RedirectTo) {
                    $suspicious = $true
                    $reason += "Mail forwarding; "
                }
                
                if ($rule.DeleteMessage -eq $true) {
                    $suspicious = $true
                    $reason += "Auto-delete; "
                }
                
                if ($rule.MoveToFolder -match "Deleted Items|Junk|RSS") {
                    $suspicious = $true
                    $reason += "Move to $($rule.MoveToFolder); "
                }
                
                # Log the rule details
                $ruleDetails = [PSCustomObject]@{
                    Name = $rule.Name
                    Description = $rule.Description
                    Enabled = $rule.Enabled
                    Priority = $rule.Priority
                    ForwardTo = $rule.ForwardTo
                    RedirectTo = $rule.RedirectTo
                    DeleteMessage = $rule.DeleteMessage
                    MoveToFolder = $rule.MoveToFolder
                    Suspicious = $suspicious
                    Reason = $reason
                }
                
                $logLevel = if ($suspicious) { "Warning" } else { "Info" }
                Write-LogMessage ("Rule: " + ($ruleDetails | ConvertTo-Json -Compress)) -Level $logLevel
            }
            
            return $rules
        } else {
            Write-LogMessage "No inbox rules found." -Level Info
            return $null
        }
    }
    catch {
        Write-LogMessage "Error retrieving inbox rules: $_" -Level Error
        return $null
    }
}

function Get-MailboxPermissions {
    param(
        [string]$UserPrincipalName
    )
    
    Write-LogMessage "Checking mailbox permissions for $UserPrincipalName..." -Level Info
    
    try {
        # Get delegated permissions
        $delegatedPermissions = Get-MailboxPermission -Identity $UserPrincipalName | Where-Object { 
            $_.IsInherited -eq $false -and 
            $_.User -ne "NT AUTHORITY\SELF" -and 
            $_.User -notlike "S-1-5-*" 
        }
        
        if ($delegatedPermissions) {
            foreach ($permission in $delegatedPermissions) {
                Write-LogMessage "Delegate permission found: $($permission.User) has $($permission.AccessRights) access" -Level Warning
            }
        } else {
            Write-LogMessage "No unusual delegated permissions found." -Level Info
        }
        
        # Get send-as permissions
        $sendAsPermissions = Get-RecipientPermission -Identity $UserPrincipalName | Where-Object { 
            $_.Trustee -ne "NT AUTHORITY\SELF" -and 
            $_.Trustee -notlike "S-1-5-*" 
        }
        
        if ($sendAsPermissions) {
            foreach ($permission in $sendAsPermissions) {
                Write-LogMessage "Send-as permission found: $($permission.Trustee) has $($permission.AccessRights) access" -Level Warning
            }
        } else {
            Write-LogMessage "No unusual send-as permissions found." -Level Info
        }
        
        # Get send-on-behalf permissions
        $mailbox = Get-Mailbox -Identity $UserPrincipalName
        if ($mailbox.GrantSendOnBehalfTo) {
            foreach ($delegate in $mailbox.GrantSendOnBehalfTo) {
                Write-LogMessage "Send-on-behalf permission found: $delegate" -Level Warning
            }
        } else {
            Write-LogMessage "No send-on-behalf permissions found." -Level Info
        }
        
        return @{
            DelegatedPermissions = $delegatedPermissions
            SendAsPermissions = $sendAsPermissions
            SendOnBehalfTo = $mailbox.GrantSendOnBehalfTo
        }
    }
    catch {
        Write-LogMessage "Error retrieving mailbox permissions: $_" -Level Error
        return $null
    }
}

function Get-SignInLogs {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    Write-LogMessage "Checking sign-in logs for $UserPrincipalName..." -Level Info
    
    try {
        # We need the Azure AD module for this
        if (-not (Get-Module -ListAvailable -Name AzureAD)) {
            Write-LogMessage "AzureAD module not installed, skipping sign-in log analysis" -Level Warning
            return $null
        }
        
        $startDate = (Get-Date).AddDays(-$DaysToLookBack)
        
        # Get user object ID
        $user = Get-AzureADUser -Filter "UserPrincipalName eq '$UserPrincipalName'"
        if (-not $user) {
            Write-LogMessage "User not found in Azure AD" -Level Error
            return $null
        }
        
        # Get sign-in logs - Note: This requires Azure AD Premium P1/P2
        # This might need to be adapted based on your Azure AD license
        try {
            $signInLogs = Get-AzureADAuditSignInLogs -Filter "userId eq '$($user.ObjectId)'" -Top 100
            
            if ($signInLogs) {
                foreach ($log in $signInLogs) {
                    $suspicious = $false
                    $reason = ""
                    
                    # Check for unusual locations or failed attempts
                    if ($log.Status.ErrorCode -ne 0) {
                        $suspicious = $true
                        $reason = "Failed login attempt: $($log.Status.FailureReason)"
                    }
                    
                    $logLevel = if ($suspicious) { "Warning" } else { "Info" }
                    Write-LogMessage "Sign-in: $($log.CreatedDateTime) from $($log.IpAddress) ($($log.Location.City), $($log.Location.CountryOrRegion)) - Status: $($log.Status.ErrorCode)" -Level $logLevel
                    
                    if ($suspicious) {
                        Write-LogMessage "  Reason: $reason" -Level Warning
                    }
                }
            } else {
                Write-LogMessage "No sign-in logs found for the specified period." -Level Info
            }
            
            return $signInLogs
        }
        catch {
            Write-LogMessage "Error retrieving sign-in logs (may require Azure AD P1/P2 license): $_" -Level Warning
            return $null
        }
    }
    catch {
        Write-LogMessage "Error in sign-in log analysis: $_" -Level Error
        return $null
    }
}

function Get-MFAStatus {
    param(
        [string]$UserPrincipalName
    )
    
    Write-LogMessage "Checking MFA status for $UserPrincipalName..." -Level Info
    
    try {
        # Get MFA status from MSOnline
        $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName
        
        if ($msolUser) {
            $mfaStatus = $msolUser.StrongAuthenticationRequirements
            $methodDetails = $msolUser.StrongAuthenticationMethods
            
            if ($mfaStatus -and $mfaStatus.Count -gt 0) {
                Write-LogMessage "MFA is enabled for this user. State: $($mfaStatus[0].State)" -Level Info
            } else {
                Write-LogMessage "MFA is not enabled for this user! This is a security risk." -Level Warning
            }
            
            if ($methodDetails) {
                foreach ($method in $methodDetails) {
                    Write-LogMessage "  Authentication method: $($method.MethodType), Default: $($method.IsDefault)" -Level Info
                }
            }
            
            return @{
                MFAStatus = $mfaStatus
                Methods = $methodDetails
            }
        } else {
            Write-LogMessage "User not found in MSOnline service" -Level Error
            return $null
        }
    }
    catch {
        Write-LogMessage "Error checking MFA status: $_" -Level Error
        return $null
    }
}

function Check-CompromiseIndicators {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    Write-LogMessage "Running comprehensive compromise check for $UserPrincipalName..." -Level Info
    
    # Collect all data
    $inboxRules = Get-InboxRules -UserPrincipalName $UserPrincipalName
    $mailboxPermissions = Get-MailboxPermissions -UserPrincipalName $UserPrincipalName
    $sentEmails = Get-SentEmails -UserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
    $signInLogs = Get-SignInLogs -UserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
    $mfaStatus = Get-MFAStatus -UserPrincipalName $UserPrincipalName
    
    # Check for suspicious inbox rules
    $suspiciousRules = $inboxRules | Where-Object { 
        $_.ForwardTo -or 
        $_.ForwardAsAttachmentTo -or 
        $_.RedirectTo -or 
        $_.DeleteMessage -eq $true -or
        $_.MoveToFolder -match "Deleted Items|Junk|RSS"
    }
    
    # Check for suspicious delegated permissions
    $suspiciousDelegates = $false
    if ($mailboxPermissions.DelegatedPermissions -or 
        $mailboxPermissions.SendAsPermissions -or 
        $mailboxPermissions.SendOnBehalfTo) {
        $suspiciousDelegates = $true
    }
    
    # Look for suspicious sign-ins
    $suspiciousSignIns = $signInLogs | Where-Object { $_.Status.ErrorCode -ne 0 }
    
    # Compile results and recommendations
    Write-LogMessage "`n========== INVESTIGATION SUMMARY ==========" -Level Info
    
    $compromiseDetected = $false
    $recommendations = @()
    
    if ($suspiciousRules -and $suspiciousRules.Count -gt 0) {
        $compromiseDetected = $true
        Write-LogMessage "WARNING: Suspicious inbox rules detected!" -Level Warning
        $recommendations += "Immediate action: Review and delete suspicious inbox rules"
    }
    
    if ($suspiciousDelegates) {
        $compromiseDetected = $true
        Write-LogMessage "WARNING: Suspicious mailbox delegations detected!" -Level Warning
        $recommendations += "Immediate action: Review and remove unauthorized mailbox delegates"
    }
    
    if ($suspiciousSignIns -and $suspiciousSignIns.Count -gt 0) {
        $compromiseDetected = $true
        Write-LogMessage "WARNING: Suspicious sign-in attempts detected!" -Level Warning
        $recommendations += "Immediate action: Block access from suspicious IP addresses and locations"
    }
    
    if (-not $mfaStatus.MFAStatus) {
        Write-LogMessage "WARNING: MFA not enabled for this user!" -Level Warning
        $recommendations += "Immediate action: Enable MFA for this user"
    }
    
    # Final assessment
    if ($compromiseDetected) {
        Write-LogMessage "`nPOTENTIAL COMPROMISE DETECTED! Recommended actions:" -Level Warning
        foreach ($recommendation in $recommendations) {
            Write-LogMessage "- $recommendation" -Level Warning
        }
        Write-LogMessage "- Reset the user's password immediately" -Level Warning
        Write-LogMessage "- Consider temporarily blocking the account" -Level Warning
        Write-LogMessage "- Review all devices connected to this account" -Level Warning
    } else {
        Write-LogMessage "`nNo definitive signs of compromise detected. However, continue monitoring the account and consider these security improvements:" -Level Info
        Write-LogMessage "- Ensure MFA is enabled for all users" -Level Info
        Write-LogMessage "- Review and tighten conditional access policies" -Level Info
        Write-LogMessage "- Conduct regular security awareness training" -Level Info
    }
    
    Write-LogMessage "========== END OF SUMMARY ==========" -Level Info
    
    return @{
        UserPrincipalName = $UserPrincipalName
        CompromiseDetected = $compromiseDetected
        SuspiciousRules = $suspiciousRules
        SuspiciousDelegates = $suspiciousDelegates
        SuspiciousSignIns = $suspiciousSignIns
        MFAEnabled = ($mfaStatus.MFAStatus -and $mfaStatus.MFAStatus.Count -gt 0)
        Recommendations = $recommendations
    }
}

# Main execution flow
Write-LogMessage "Starting Microsoft 365 account compromise investigation for $UserPrincipalName" -Level Info
Write-LogMessage "Investigation period: Last $DaysToLookBack days" -Level Info
Write-LogMessage "Log file: $OutputPath" -Level Info

# Check required modules
$modulesRequired = @("ExchangeOnlineManagement", "AzureAD", "MSOnline")
$modulesCheck = $true
foreach ($module in $modulesRequired) {
    if (-not (Test-ModuleInstalled -ModuleName $module)) {
        $modulesCheck = $false
        Write-LogMessage "Please install the $module module using: Install-Module -Name $module -Force -AllowClobber" -Level Error
    }
}

if (-not $modulesCheck) {
    Write-LogMessage "Required modules are missing. Please install them and try again." -Level Error
    exit 1
}

# Connect to required services
if (Connect-RequiredServices) {
    # Run the comprehensive check
    $result = Check-CompromiseIndicators -UserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
    
    # Disconnect from services
    try {
        Disconnect-ExchangeOnline -Confirm:$false
        Disconnect-AzureAD
        Write-LogMessage "Disconnected from Microsoft 365 services" -Level Info
    } catch {
        Write-LogMessage "Error disconnecting from services: $_" -Level Warning
    }
    
    Write-LogMessage "Investigation complete. See the log file for details: $OutputPath" -Level Info
} else {
    Write-LogMessage "Failed to connect to required services. Investigation aborted." -Level Error
}
