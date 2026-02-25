# Secure-M365Tenant.ps1
# Purpose: Apply security hardening settings to Microsoft 365 tenant
# Created: September 10, 2025

param (
    [Parameter(Mandatory=$false)]
    [switch]$EnableSecurityD                Write-SecurityLog "Go to Azure Portal: Azure Active Directory - Properties - Manage Security Defaults" -Level Warningfaults,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnforceMFA,
    
    [Parameter(Mandatory=$false)]
    [switch]$BlockLegacyAuth,
    
    [Parameter(Mandatory=$false)]
    [switch]$ConfigureAntispam,
    
    [Parameter(Mandatory=$false)]
    [switch]$ConfigureAntiphishing,
    
    [Parameter(Mandatory=$false)]
    [switch]$ConfigureSa                                -CurrentState "Unified Audit Logging: ${auditEnabled}" `eLinks,
    
    [Parameter(Mandatory=$false)]
    [switch]$ConfigureSafeAttachments,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableAuditLogging,
    
    [Parameter(Mandatory=$false)]
    [switch]$ApplyAll,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckOnly,
    
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = ".\SecurityHardening_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
)

# Initialize environment
$ErrorActionPreference = "Continue"
$securityReport = @()
$script:totalChecks = 0
$script:passedChecks = 0
$script:warningChecks = 0
$script:failedChecks = 0

# Colors for HTML report
$passColor = "#8FED8F"   # Light green
$warnColor = "#FFCC66"   # Light orange/yellow
$failColor = "#FF7F7F"   # Light red
$headerColor = "#4F6995" # Blue-gray
$headerTextColor = "#FFFFFF" # White

# Function for logging
function Write-SecurityLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
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
    }
}

# Function to record check result
function Add-SecurityCheck {
    param(
        [string]$Category,
        [string]$Control,
        [string]$Description,
        [ValidateSet('Pass', 'Warning', 'Fail')]
        [string]$Status = 'Warning',
        [string]$CurrentState,
        [string]$RecommendedState,
        [string]$RemediationSteps
    )
    
    # Increment counters
    $script:totalChecks++
    switch ($Status) {
        'Pass' { $script:passedChecks++ }
        'Warning' { $script:warningChecks++ }
        'Fail' { $script:failedChecks++ }
    }
    
    $checkResult = [PSCustomObject]@{
        Category = $Category
        Control = $Control
        Description = $Description
        Status = $Status
        CurrentState = $CurrentState
        RecommendedState = $RecommendedState
        RemediationSteps = $RemediationSteps
    }
    
    $securityReport += $checkResult
    
    # Log to console
    $statusIcon = switch ($Status) {
        'Pass' { "[PASS]" }
        'Warning' { "[WARNING]" }
        'Fail' { "[FAIL]" }
    }
    
    $logLevel = switch ($Status) {
        'Pass' { "Success" }
        'Warning' { "Warning" }
        'Fail' { "Error" }
    }
    
    Write-SecurityLog "$statusIcon $Control - $Description" -Level $logLevel
    
    return $checkResult
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
    
    if (!$allModulesPresent) {
        Write-SecurityLog "Missing required modules. Please install them and try again." -Level Error
        return $false
    }
    
    # Check connections
    try {
        Write-SecurityLog "Connecting to required services..."
        
        # Connect to Azure AD
        Connect-AzureAD -ErrorAction Stop | Out-Null
        Write-SecurityLog "Connected to Azure AD" -Level Success
        
        # Connect to Exchange Online
        Connect-ExchangeOnline -ErrorAction Stop | Out-Null
        Write-SecurityLog "Connected to Exchange Online" -Level Success
        
        # Try to connect to MSOL
        try {
            Connect-MsolService -ErrorAction Stop | Out-Null
            Write-SecurityLog "Connected to Microsoft Online Services" -Level Success
        } catch {
            Write-SecurityLog "Could not connect to MSOnline Service: $_" -Level Warning
            Write-SecurityLog "Some functions may be limited" -Level Warning
        }
        
        return $true
    } catch {
        Write-SecurityLog "Failed to connect to required services: $_" -Level Error
        return $false
    }
}

# Function to check Security Defaults in Azure AD
function Test-SecurityDefaults {
    Write-SecurityLog "Checking Security Defaults status..."
    
    try {
        # This requires appropriate permissions
        # Note: In a real environment, we would use Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy
        # but it requires Microsoft Graph PowerShell SDK which we don't install here
        
        $securityDefaultsEnabled = "Unknown - requires Global Administrator privileges to check"
        
        Add-SecurityCheck -Category "Account Security" `
                        -Control "Security Defaults" `
                        -Description "Azure AD Security Defaults providing baseline security" `
                        -Status "Warning" `
                        -CurrentState $securityDefaultsEnabled `
                        -RecommendedState "Enabled (unless using custom Conditional Access policies)" `
                        -RemediationSteps "Enable Security Defaults in the Azure Portal under Azure Active Directory - Properties - Manage Security Defaults"
        
        if (!$CheckOnly -and ($EnableSecurityDefaults -or $ApplyAll)) {
            Write-SecurityLog "Security Defaults remediation requires manual intervention in the Azure Portal" -Level Warning
            Write-SecurityLog "Go to Azure Portal > Azure Active Directory > Properties > Manage Security Defaults" -Level Warning
        }
    } catch {
        Write-SecurityLog "Error checking Security Defaults: $_" -Level Error
    }
}

# Function to check MFA status for users
function Test-MFAStatus {
    Write-SecurityLog "Checking Multi-Factor Authentication status..."
    
    try {
        # Get licensed users (limited to 1000 to avoid performance issues)
        $users = Get-MsolUser -MaxResults 1000 | Where-Object { $_.IsLicensed -eq $true }
        
        if ($users -and $users.Count -gt 0) {
            $totalUsers = $users.Count
            $mfaDisabledUsers = @()
            $mfaEnabledCount = 0
            
            foreach ($user in $users) {
                $mfaStatus = $user.StrongAuthenticationRequirements
                
                if (!$mfaStatus -or $mfaStatus.Count -eq 0) {
                    $mfaDisabledUsers += $user.UserPrincipalName
                } else {
                    $mfaEnabledCount++
                }
            }
            
            $mfaPercentage = [math]::Round(($mfaEnabledCount / $totalUsers) * 100, 2)
            
            if ($mfaDisabledUsers.Count -eq 0) {
                Add-SecurityCheck -Category "Account Security" `
                                -Control "Multi-Factor Authentication" `
                                -Description "MFA for all users" `
                                -Status "Pass" `
                                -CurrentState "MFA enabled for all licensed users (${totalUsers} users)" `
                                -RecommendedState "MFA enabled for all users" `
                                -RemediationSteps "No action needed"
            } else {
                # Calculate risk level
                $status = if ($mfaPercentage -lt 50) { "Fail" } else { "Warning" }
                
                Add-SecurityCheck -Category "Account Security" `
                                -Control "Multi-Factor Authentication" `
                                -Description "MFA for all users" `
                                -Status $status `
                                -CurrentState "MFA enabled for $mfaEnabledCount out of $totalUsers users ($mfaPercentage%)" `
                                -RecommendedState "MFA enabled for all users" `
                                -RemediationSteps "Enable MFA for all users without it. First users to secure: admins, executives, finance"
                
                if (!$CheckOnly -and ($EnforceMFA -or $ApplyAll)) {
                    Write-SecurityLog "Would enable MFA for ${$mfaDisabledUsers.Count} users - this requires manual steps in the admin portal" -Level Warning
                    # Note: In production, you could use Set-MsolUser to enable per-user MFA 
                    # or preferably, use Conditional Access policies
                }
            }
        } else {
            Write-SecurityLog "No licensed users found or you don't have permission to list users" -Level Warning
        }
    } catch {
        Write-SecurityLog "Error checking MFA status: $_" -Level Error
    }
}

# Function to check legacy authentication
function Test-LegacyAuthentication {
    Write-SecurityLog "Checking legacy authentication status..."
    
    try {
        # Note: Properly checking legacy auth blocking requires checking Conditional Access policies
        # which would require more advanced permissions
        $legacyAuthStatus = "Unknown - requires Conditional Access checking permissions"
        
        Add-SecurityCheck -Category "Authentication Security" `
                        -Control "Legacy Authentication" `
                        -Description "Block legacy authentication protocols" `
                        -Status "Warning" `
                        -CurrentState $legacyAuthStatus `
                        -RecommendedState "Blocked via Conditional Access or Security Defaults" `
                        -RemediationSteps "Create a Conditional Access policy to block legacy authentication protocols, or enable Security Defaults"
        
        if (!$CheckOnly -and ($BlockLegacyAuth -or $ApplyAll)) {
            Write-SecurityLog "Legacy Authentication blocking requires Conditional Access policies or Security Defaults" -Level Warning
            Write-SecurityLog "This typically requires manual configuration in the Azure Portal" -Level Warning
        }
    } catch {
        Write-SecurityLog "Error checking legacy authentication: $_" -Level Error
    }
}

# Function to check anti-spam settings
function Test-AntispamSettings {
    Write-SecurityLog "Checking anti-spam configuration..."
    
    try {
        # Try to get spam filter policy
        $spamFilterPolicies = Get-HostedContentFilterPolicy -ErrorAction SilentlyContinue
        
        if ($spamFilterPolicies) {
            $defaultPolicy = $spamFilterPolicies | Where-Object { $_.IsDefault -eq $true }
            
            if ($defaultPolicy) {
                $spfAction = $defaultPolicy.SpamAction
                $highConfSpamAction = $defaultPolicy.HighConfidenceSpamAction
                
                $status = if (($spfAction -eq "MoveToJmf" -or $spfAction -eq "Quarantine") -and 
                              ($highConfSpamAction -eq "Quarantine" -or $highConfSpamAction -eq "Reject")) {
                    "Pass"
                } else {
                    "Warning"
                }
                
                Add-SecurityCheck -Category "Email Security" `
                                -Control "Anti-Spam Configuration" `
                                -Description "Effective anti-spam policy settings" `
                                -Status $status `
                                -CurrentState "Spam: ${spfAction}, High Confidence: ${highConfSpamAction}" `
                                -RecommendedState "Spam: Quarantine, High Confidence: Quarantine or Reject" `
                                -RemediationSteps "Update anti-spam policies to quarantine or reject detected spam"
                
                if (!$CheckOnly -and ($ConfigureAntispam -or $ApplyAll) -and $status -ne "Pass") {
                    Write-SecurityLog "Configuring anti-spam policy..." -Level Warning
                    
                    try {
                        # Simulation only - would need to run Set-HostedContentFilterPolicy
                        Write-SecurityLog "SIMULATION: Would update anti-spam policy to use recommended settings" -Level Warning
                    } catch {
                        Write-SecurityLog "Error updating anti-spam policy: $_" -Level Error
                    }
                }
            } else {
                Add-SecurityCheck -Category "Email Security" `
                                -Control "Anti-Spam Configuration" `
                                -Description "Effective anti-spam policy settings" `
                                -Status "Warning" `
                                -CurrentState "Default policy not found" `
                                -RecommendedState "Standard default policy with Quarantine actions" `
                                -RemediationSteps "Configure default anti-spam policy in Security & Compliance Center"
            }
        } else {
            Add-SecurityCheck -Category "Email Security" `
                            -Control "Anti-Spam Configuration" `
                            -Description "Effective anti-spam policy settings" `
                            -Status "Warning" `
                            -CurrentState "Unable to retrieve anti-spam policies" `
                            -RecommendedState "Standard default policy with Quarantine actions" `
                            -RemediationSteps "Ensure you have appropriate permissions and configure anti-spam in Security & Compliance Center"
        }
    } catch {
        Write-SecurityLog "Error checking anti-spam settings: $_" -Level Error
    }
}

# Function to check anti-phishing settings
function Test-AntiphishingSettings {
    Write-SecurityLog "Checking anti-phishing configuration..."
    
    try {
        # Try to get anti-phishing policy
        $phishPolicies = Get-AntiPhishPolicy -ErrorAction SilentlyContinue
        
        if ($phishPolicies) {
            $defaultPolicy = $phishPolicies | Where-Object { $_.IsDefault -eq $true }
            
            if ($defaultPolicy) {
                $impersonationProtection = $defaultPolicy.EnableTargetedUserProtection
                $domainImpersonation = $defaultPolicy.EnableOrganizationDomainsProtection
                $spoof = $defaultPolicy.EnableSpoofIntelligence
                
                $status = if ($impersonationProtection -and $domainImpersonation -and $spoof) {
                    "Pass"
                } elseif ($spoof) {
                    "Warning"
                } else {
                    "Fail"
                }
                
                Add-SecurityCheck -Category "Email Security" `
                                -Control "Anti-Phishing Configuration" `
                                -Description "Effective anti-phishing policy settings" `
                                -Status $status `
                                -CurrentState "Impersonation: ${impersonationProtection}, Domain Impersonation: ${domainImpersonation}, Anti-Spoof: ${spoof}" `
                                -RecommendedState "All protections enabled" `
                                -RemediationSteps "Enable all anti-phishing protections in the Security & Compliance Center"
                
                if (!$CheckOnly -and ($ConfigureAntiphishing -or $ApplyAll) -and $status -ne "Pass") {
                    Write-SecurityLog "Configuring anti-phishing policy..." -Level Warning
                    
                    try {
                        # Simulation only - would need to run Set-AntiPhishPolicy
                        Write-SecurityLog "SIMULATION: Would update anti-phishing policy to enable all protections" -Level Warning
                    } catch {
                        Write-SecurityLog "Error updating anti-phishing policy: $_" -Level Error
                    }
                }
            } else {
                Add-SecurityCheck -Category "Email Security" `
                                -Control "Anti-Phishing Configuration" `
                                -Description "Effective anti-phishing policy settings" `
                                -Status "Warning" `
                                -CurrentState "Default policy not found" `
                                -RecommendedState "Default policy with all protections enabled" `
                                -RemediationSteps "Configure default anti-phishing policy in Security & Compliance Center"
            }
        } else {
            Add-SecurityCheck -Category "Email Security" `
                            -Control "Anti-Phishing Configuration" `
                            -Description "Effective anti-phishing policy settings" `
                            -Status "Warning" `
                            -CurrentState "Unable to retrieve anti-phishing policies" `
                            -RecommendedState "Default policy with all protections enabled" `
                            -RemediationSteps "Ensure you have appropriate permissions and configure anti-phishing in Security & Compliance Center"
        }
    } catch {
        Write-SecurityLog "Error checking anti-phishing settings: $_" -Level Error
    }
}

# Function to check Safe Links settings
function Test-SafeLinksSettings {
    Write-SecurityLog "Checking Safe Links configuration..."
    
    try {
        # Try to get Safe Links policy
        $safeLinksPolicies = Get-SafeLinksPolicy -ErrorAction SilentlyContinue
        
        if ($safeLinksPolicies) {
            $effectivePolicies = $safeLinksPolicies | Where-Object { $_.IsEnabled -eq $true }
            
            if ($effectivePolicies -and $effectivePolicies.Count -gt 0) {
                # Check if policies cover standard settings
                $hasDoNotTrack = $effectivePolicies | Where-Object { $_.DoNotTrackUserClicks -eq $true }
                $hasRealTimeBlocking = $effectivePolicies | Where-Object { $_.IsEnabled -eq $true -and $_.EnableForInternalSenders -eq $true }
                $hasDetonation = $effectivePolicies | Where-Object { $_.DeliverMessageAfterScan -eq $true }
                
                $status = if ($hasDoNotTrack -and $hasRealTimeBlocking -and $hasDetonation) {
                    "Pass"
                } elseif ($hasRealTimeBlocking) {
                    "Warning"
                } else {
                    "Fail"
                }
                
                Add-SecurityCheck -Category "Email Security" `
                                -Control "Safe Links Configuration" `
                                -Description "URL scanning and protection" `
                                -Status $status `
                                -CurrentState "Enabled policies: $($effectivePolicies.Count)" `
                                -RecommendedState "Real-time URL scanning with all protections enabled" `
                                -RemediationSteps "Configure Safe Links policy with recommended settings in Security & Compliance Center"
                
                if (!$CheckOnly -and ($ConfigureSafeLinks -or $ApplyAll) -and $status -ne "Pass") {
                    Write-SecurityLog "Configuring Safe Links policy..." -Level Warning
                    
                    try {
                        # Simulation only - would need to run Set-SafeLinksPolicy
                        Write-SecurityLog "SIMULATION: Would update Safe Links policy to enable all protections" -Level Warning
                    } catch {
                        Write-SecurityLog "Error updating Safe Links policy: $_" -Level Error
                    }
                }
            } else {
                Add-SecurityCheck -Category "Email Security" `
                                -Control "Safe Links Configuration" `
                                -Description "URL scanning and protection" `
                                -Status "Fail" `
                                -CurrentState "No enabled policies found" `
                                -RecommendedState "Real-time URL scanning with all protections enabled" `
                                -RemediationSteps "Configure Safe Links policy with recommended settings in Security & Compliance Center"
            }
        } else {
            Add-SecurityCheck -Category "Email Security" `
                            -Control "Safe Links Configuration" `
                            -Description "URL scanning and protection" `
                            -Status "Warning" `
                            -CurrentState "Unable to retrieve Safe Links policies" `
                            -RecommendedState "Real-time URL scanning with all protections enabled" `
                            -RemediationSteps "Ensure you have appropriate permissions and configure Safe Links in Security & Compliance Center"
        }
    } catch {
        Write-SecurityLog "Error checking Safe Links settings: $_" -Level Error
    }
}

# Function to check Safe Attachments settings
function Test-SafeAttachmentsSettings {
    Write-SecurityLog "Checking Safe Attachments configuration..."
    
    try {
        # Try to get Safe Attachments policy
        $safeAttachmentsPolicies = Get-SafeAttachmentPolicy -ErrorAction SilentlyContinue
        
        if ($safeAttachmentsPolicies) {
            $effectivePolicies = $safeAttachmentsPolicies | Where-Object { $_.IsEnabled -eq $true }
            
            if ($effectivePolicies -and $effectivePolicies.Count -gt 0) {
                # Check if policies cover standard settings
                $hasBlockAction = $effectivePolicies | Where-Object { $_.Action -eq "Block" }
                $hasReplaceAction = $effectivePolicies | Where-Object { $_.Action -eq "Replace" }
                $hasDynamicDelivery = $effectivePolicies | Where-Object { $_.Action -eq "DynamicDelivery" }
                
                $status = if ($hasBlockAction -or $hasReplaceAction -or $hasDynamicDelivery) {
                    "Pass"
                } else {
                    "Fail"
                }
                
                Add-SecurityCheck -Category "Email Security" `
                                -Control "Safe Attachments Configuration" `
                                -Description "Attachment scanning and protection" `
                                -Status $status `
                                -CurrentState "Enabled policies: $($effectivePolicies.Count)" `
                                -RecommendedState "Active protection with Block, Replace, or Dynamic Delivery action" `
                                -RemediationSteps "Configure Safe Attachments policy with recommended settings in Security & Compliance Center"
                
                if (!$CheckOnly -and ($ConfigureSafeAttachments -or $ApplyAll) -and $status -ne "Pass") {
                    Write-SecurityLog "Configuring Safe Attachments policy..." -Level Warning
                    
                    try {
                        # Simulation only - would need to run Set-SafeAttachmentPolicy
                        Write-SecurityLog "SIMULATION: Would update Safe Attachments policy to use recommended settings" -Level Warning
                    } catch {
                        Write-SecurityLog "Error updating Safe Attachments policy: $_" -Level Error
                    }
                }
            } else {
                Add-SecurityCheck -Category "Email Security" `
                                -Control "Safe Attachments Configuration" `
                                -Description "Attachment scanning and protection" `
                                -Status "Fail" `
                                -CurrentState "No enabled policies found" `
                                -RecommendedState "Active protection with Block, Replace, or Dynamic Delivery action" `
                                -RemediationSteps "Configure Safe Attachments policy with recommended settings in Security & Compliance Center"
            }
        } else {
            Add-SecurityCheck -Category "Email Security" `
                            -Control "Safe Attachments Configuration" `
                            -Description "Attachment scanning and protection" `
                            -Status "Warning" `
                            -CurrentState "Unable to retrieve Safe Attachments policies" `
                            -RecommendedState "Active protection with Block, Replace, or Dynamic Delivery action" `
                            -RemediationSteps "Ensure you have appropriate permissions and configure Safe Attachments in Security & Compliance Center"
        }
    } catch {
        Write-SecurityLog "Error checking Safe Attachments settings: $_" -Level Error
    }
}

# Function to check audit logging
function Test-AuditLogging {
    Write-SecurityLog "Checking audit logging configuration..."
    
    try {
        # Try to get audit configuration
        try {
            $adminAuditLogConfig = Get-AdminAuditLogConfig -ErrorAction Stop
            $auditEnabled = $adminAuditLogConfig.UnifiedAuditLogIngestionEnabled
            
            $status = if ($auditEnabled) { "Pass" } else { "Fail" }
            
            Add-SecurityCheck -Category "Monitoring & Detection" `
                            -Control "Audit Logging" `
                            -Description "Unified audit logging for all activities" `
                            -Status $status `
                            -CurrentState "Unified Audit Logging: $auditEnabled" `
                            -RecommendedState "Enabled" `
                            -RemediationSteps "Enable unified audit logging in Security & Compliance Center"
            
            if (!$CheckOnly -and ($EnableAuditLogging -or $ApplyAll) -and !$auditEnabled) {
                Write-SecurityLog "Enabling audit logging..." -Level Warning
                
                try {
                    # Simulation only - would need to run Set-AdminAuditLogConfig
                    Write-SecurityLog "SIMULATION: Would enable unified audit logging" -Level Warning
                } catch {
                    Write-SecurityLog "Error enabling audit logging: $_" -Level Error
                }
            }
        } catch {
            Add-SecurityCheck -Category "Monitoring & Detection" `
                            -Control "Audit Logging" `
                            -Description "Unified audit logging for all activities" `
                            -Status "Warning" `
                            -CurrentState "Unable to retrieve audit configuration" `
                            -RecommendedState "Enabled" `
                            -RemediationSteps "Ensure you have appropriate permissions and enable audit logging in Security & Compliance Center"
        }
    } catch {
        Write-SecurityLog "Error checking audit logging: $_" -Level Error
    }
}

# Function to check outbound spam settings
function Test-OutboundSpamSettings {
    Write-SecurityLog "Checking outbound spam configuration..."
    
    try {
        # Try to get outbound spam filter policy
        $outboundPolicies = Get-HostedOutboundSpamFilterPolicy -ErrorAction SilentlyContinue
        
        if ($outboundPolicies) {
            $defaultPolicy = $outboundPolicies | Where-Object { $_.IsDefault -eq $true }
            
            if ($defaultPolicy) {
                $notificationEnabled = $defaultPolicy.NotifyOutboundSpam
                
                $status = if ($notificationEnabled) { "Pass" } else { "Warning" }
                
                Add-SecurityCheck -Category "Email Security" `
                                -Control "Outbound Spam Notification" `
                                -Description "Notifications for potential outbound spam" `
                                -Status $status `
                                -CurrentState "Admin Notification: ${notificationEnabled}" `
                                -RecommendedState "Enabled" `
                                -RemediationSteps "Enable outbound spam notifications in anti-spam settings"
                
                if (!$CheckOnly -and ($ConfigureAntispam -or $ApplyAll) -and !$notificationEnabled) {
                    Write-SecurityLog "Enabling outbound spam notification..." -Level Warning
                    
                    try {
                        # Simulation only - would need to run Set-HostedOutboundSpamFilterPolicy
                        Write-SecurityLog "SIMULATION: Would enable outbound spam notifications" -Level Warning
                    } catch {
                        Write-SecurityLog "Error enabling outbound spam notifications: $_" -Level Error
                    }
                }
            } else {
                Add-SecurityCheck -Category "Email Security" `
                                -Control "Outbound Spam Notification" `
                                -Description "Notifications for potential outbound spam" `
                                -Status "Warning" `
                                -CurrentState "Default policy not found" `
                                -RecommendedState "Enabled" `
                                -RemediationSteps "Configure outbound spam policy in Security & Compliance Center"
            }
        } else {
            Add-SecurityCheck -Category "Email Security" `
                            -Control "Outbound Spam Notification" `
                            -Description "Notifications for potential outbound spam" `
                            -Status "Warning" `
                            -CurrentState "Unable to retrieve outbound spam policies" `
                            -RecommendedState "Enabled" `
                            -RemediationSteps "Ensure you have appropriate permissions and configure outbound spam in Security & Compliance Center"
        }
    } catch {
        Write-SecurityLog "Error checking outbound spam settings: $_" -Level Error
    }
}

# Function to generate HTML report
function Generate-HTMLReport {
    param(
        [string]$ReportPath
    )
    
    Write-SecurityLog "Generating HTML security report..."
    
    $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Microsoft 365 Security Hardening Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f9f9f9; color: #333; }
        .container { width: 95%; margin: 20px auto; }
        h1 { color: #2d5986; }
        .summary { background-color: #fff; padding: 15px; border-radius: 5px; margin-bottom: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        .summary-stats { display: flex; justify-content: space-between; flex-wrap: wrap; }
        .stat-box { text-align: center; padding: 10px; flex: 1; min-width: 150px; margin: 5px; border-radius: 5px; }
        .pass { background-color: $passColor; }
        .warn { background-color: $warnColor; }
        .fail { background-color: $failColor; }
        .table-container { overflow-x: auto; }
        table { border-collapse: collapse; width: 100%; background-color: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        th { background-color: $headerColor; color: $headerTextColor; text-align: left; padding: 12px; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background-color: #f5f5f5; }
        .status-pass { background-color: $passColor; padding: 5px 10px; border-radius: 3px; }
        .status-warning { background-color: $warnColor; padding: 5px 10px; border-radius: 3px; }
        .status-fail { background-color: $failColor; padding: 5px 10px; border-radius: 3px; }
        .footer { margin-top: 20px; text-align: center; font-size: 0.8em; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Microsoft 365 Security Hardening Report</h1>
        <p>Report generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        
        <div class="summary">
            <h2>Security Summary</h2>
            <div class="summary-stats">
                <div class="stat-box pass">
                    <h3>$script:passedChecks</h3>
                    <p>PASSED</p>
                </div>
                <div class="stat-box warn">
                    <h3>$script:warningChecks</h3>
                    <p>WARNING</p>
                </div>
                <div class="stat-box fail">
                    <h3>$script:failedChecks</h3>
                    <p>FAILED</p>
                </div>
                <div class="stat-box">
                    <h3>$script:totalChecks</h3>
                    <p>TOTAL</p>
                </div>
            </div>
        </div>
        
        <h2>Security Controls</h2>
        <div class="table-container">
            <table>
                <tr>
                    <th>Category</th>
                    <th>Control</th>
                    <th>Description</th>
                    <th>Status</th>
                    <th>Current State</th>
                    <th>Recommended State</th>
                    <th>Remediation Steps</th>
                </tr>
"@

    $htmlRows = ""
    foreach ($check in $securityReport) {
        $statusClass = switch ($check.Status) {
            "Pass" { "status-pass" }
            "Warning" { "status-warning" }
            "Fail" { "status-fail" }
        }
        
        $htmlRows += @"
                <tr>
                    <td>$($check.Category)</td>
                    <td>$($check.Control)</td>
                    <td>$($check.Description)</td>
                    <td><span class="$statusClass">$($check.Status)</span></td>
                    <td>$($check.CurrentState)</td>
                    <td>$($check.RecommendedState)</td>
                    <td>$($check.RemediationSteps)</td>
                </tr>
"@
    }

    $htmlFooter = @"
            </table>
        </div>
        
        <div class="footer">
            <p>Secure-M365Tenant.ps1 - Generated by Microsoft 365 Security Hardening Tool</p>
        </div>
    </div>
</body>
</html>
"@

    $fullHTML = $htmlHeader + $htmlRows + $htmlFooter
    $fullHTML | Out-File -FilePath $ReportPath -Force
    
    Write-SecurityLog "HTML report saved to: $ReportPath" -Level Success
}

# Main execution flow
Write-SecurityLog "Microsoft 365 Security Hardening Tool" -Level Info
Write-SecurityLog "Starting security assessment on $(Get-Date)" -Level Info

if (Test-Prerequisites) {
    # Run all checks
    Test-SecurityDefaults
    Test-MFAStatus
    Test-LegacyAuthentication
    Test-AntispamSettings
    Test-AntiphishingSettings
    Test-SafeLinksSettings
    Test-SafeAttachmentsSettings
    Test-AuditLogging
    Test-OutboundSpamSettings
    
    # Generate HTML report
    Generate-HTMLReport -ReportPath $ReportPath
    
    # Disconnect from services
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        Disconnect-AzureAD -ErrorAction SilentlyContinue
        Write-SecurityLog "Disconnected from Microsoft 365 services" -Level Info
    } catch {
        Write-SecurityLog "Error disconnecting from services: $_" -Level Warning
    }
    
    # Summary
    Write-SecurityLog "`n======================================================" -Level Info
    Write-SecurityLog "SECURITY ASSESSMENT SUMMARY" -Level Info
    Write-SecurityLog "======================================================" -Level Info
    Write-SecurityLog "Total Checks: $script:totalChecks" -Level Info
    Write-SecurityLog "Passed: $script:passedChecks" -Level Success
    Write-SecurityLog "Warnings: $script:warningChecks" -Level Warning
    Write-SecurityLog "Failed: $script:failedChecks" -Level Error
    Write-SecurityLog "Report saved to: $ReportPath" -Level Info
    
    # Open the report
    if (Test-Path $ReportPath) {
        Write-SecurityLog "Opening report..." -Level Info
        Start-Process $ReportPath
    }
} else {
    Write-SecurityLog "Prerequisites check failed. Cannot continue." -Level Error
}
