#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Grant lwandile.gasela@ibridge.co.za comprehensive rights and permissions to ALL groups
.DESCRIPTION
    This script ensures that lwandile.gasela@ibridge.co.za has full administrative rights and permissions
    to all distribution groups, Office 365 groups, security groups, and shared mailboxes in the tenant.
    It will make lwandile the sole manager/owner while preserving existing memberships for other users.
.PARAMETER WhatIf
    Shows what would be done without making actual changes
.PARAMETER AdminUser
    The user to grant comprehensive admin rights to (default: lwandile.gasela@ibridge.co.za)
.EXAMPLE
    .\Fix-Failed-Groups.ps1 -WhatIf
    Test what changes would be made
.EXAMPLE
    .\Fix-Failed-Groups.ps1
    Grant comprehensive admin rights to all groups
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$AdminUser = "lwandile.gasela@ibridge.co.za"
)

# Import configuration
$ConfigPath = Join-Path $PSScriptRoot "..\config\email-config.json"
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found: $ConfigPath"
    exit 1
}

$Config = Get-Content $ConfigPath | ConvertFrom-Json
$LogPath = Join-Path $PSScriptRoot "..\logs"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFile = Join-Path $LogPath "GrantComprehensiveRights-$Timestamp.log"

# Results tracking
$Results = @{
    Timestamp = Get-Date
    AdminUser = $AdminUser
    DistributionGroups = @()
    Office365Groups = @()
    SecurityGroups = @()
    SharedMailboxes = @()
    Summary = @{}
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(switch($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    })
    Add-Content -Path $LogFile -Value $LogEntry
}

function Test-ExchangeConnection {
    try {
        $null = Get-OrganizationConfig -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Grant-DistributionGroupAdminRights {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [object]$Group,
        [string]$AdminUser
    )
    
    try {
        $GroupName = $Group.DisplayName
        $GroupId = $Group.Identity
        
        Write-Log "Processing group: $GroupName" "INFO"
        
        # Check current managers
        $CurrentManagers = @($Group.ManagedBy)
        Write-Log "Current managers: $($CurrentManagers -join ', ')" "INFO"
        
        # Check if admin user is already the sole manager
        if ($CurrentManagers.Count -eq 1) {
            try {
                $ManagerObj = Get-Recipient -Identity $CurrentManagers[0] -ErrorAction Stop
                if ($ManagerObj.PrimarySmtpAddress -eq $AdminUser) {
                    Write-Log "✅ $AdminUser is already sole manager of $GroupName" "SUCCESS"
                    return @{
                        Success = $true
                        Action = "Already Correct"
                        Group = $GroupName
                        GroupType = "DistributionGroup"
                    }
                }
            }
            catch {
                # Continue with the update if we can't resolve
            }
        }
        
        # Set admin user as sole manager
        if ($PSCmdlet.ShouldProcess($GroupId, "Set $AdminUser as sole manager")) {
            Set-DistributionGroup -Identity $GroupId -ManagedBy $AdminUser -ErrorAction Stop
            Write-Log "✅ Successfully set $AdminUser as sole manager of $GroupName" "SUCCESS"
        }
        
        # Apply comprehensive moderation with validated users
        $ValidModerators = @($AdminUser)
        foreach ($User in $Config.AuthorizedUsers) {
            if ($User -ne $AdminUser) {  # Avoid duplicates
                try {
                    $UserCheck = Get-Recipient -Identity $User -ErrorAction SilentlyContinue
                    if ($UserCheck -and $UserCheck.RecipientType -in @("UserMailbox", "MailUser")) {
                        $ValidModerators += $User
                    }
                }
                catch {
                    Write-Log "Could not validate user $User for moderation" "WARNING"
                }
            }
        }
        
        # Remove duplicates and apply moderation
        $ValidModerators = $ValidModerators | Sort-Object -Unique
        
        if ($ValidModerators.Count -gt 0) {
            if ($PSCmdlet.ShouldProcess($GroupId, "Apply comprehensive moderation")) {
                Set-DistributionGroup -Identity $GroupId `
                    -ModerationEnabled:$true `
                    -ModeratedBy $ValidModerators `
                    -SendModerationNotifications Never `
                    -ErrorAction Stop
                
                Write-Log "✅ Applied moderation to $GroupName with $($ValidModerators.Count) moderators" "SUCCESS"
            }
        }
        
        return @{
            Success = $true
            Action = "Set Admin Rights"
            Group = $GroupName
            GroupType = "DistributionGroup"
            ManagerCount = 1
            ModeratorCount = $ValidModerators.Count
        }
    }
    catch {
        Write-Log "❌ Failed to grant admin rights to group $($Group.DisplayName): $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Action = "Failed"
            Group = $Group.DisplayName
            GroupType = "DistributionGroup"
            Error = $_.Exception.Message
        }
    }
}

function Grant-Office365GroupAdminRights {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [object]$Group,
        [string]$AdminUser
    )
    
    try {
        $GroupName = $Group.DisplayName
        $GroupId = $Group.Identity
        
        Write-Log "Processing Office 365 group: $GroupName" "INFO"
        
        # Get current owners and members
        $Owners = @()
        $Members = @()
        
        try {
            $Owners = Get-UnifiedGroupLinks -Identity $GroupId -LinkType Owners -ErrorAction Stop
            $Members = Get-UnifiedGroupLinks -Identity $GroupId -LinkType Members -ErrorAction Stop
        }
        catch {
            Write-Log "Could not get Office 365 group links for $GroupName`: $($_.Exception.Message)" "WARNING"
            return @{
                Success = $false
                Action = "Failed to Get Links"
                Group = $GroupName
                GroupType = "Office365Group"
                Error = $_.Exception.Message
            }
        }
        
        $AdminIsOwner = $Owners.PrimarySmtpAddress -contains $AdminUser
        $AdminIsMember = $Members.PrimarySmtpAddress -contains $AdminUser
        
        # Add admin as member first (required before adding as owner)
        if (-not $AdminIsMember) {
            if ($PSCmdlet.ShouldProcess($GroupId, "Add $AdminUser as member")) {
                Add-UnifiedGroupLinks -Identity $GroupId -LinkType Members -Links $AdminUser -ErrorAction Stop
                Write-Log "✅ Added $AdminUser as member to $GroupName" "SUCCESS"
            }
        }
        
        # Add admin as owner
        if (-not $AdminIsOwner) {
            if ($PSCmdlet.ShouldProcess($GroupId, "Add $AdminUser as owner")) {
                Add-UnifiedGroupLinks -Identity $GroupId -LinkType Owners -Links $AdminUser -ErrorAction Stop
                Write-Log "✅ Added $AdminUser as owner to $GroupName" "SUCCESS"
            }
        }
        
        if ($AdminIsOwner -and $AdminIsMember) {
            Write-Log "✅ $AdminUser already has comprehensive access to $GroupName" "SUCCESS"
        }
        
        return @{
            Success = $true
            Action = "Set Admin Rights"
            Group = $GroupName
            GroupType = "Office365Group"
            AdminIsOwner = $true
            AdminIsMember = $true
            OwnerCount = $Owners.Count + $(if (-not $AdminIsOwner) { 1 } else { 0 })
        }
    }
    catch {
        Write-Log "❌ Failed to grant admin rights to Office 365 group $($Group.DisplayName): $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Action = "Failed"
            Group = $Group.DisplayName
            GroupType = "Office365Group"
            Error = $_.Exception.Message
        }
    }
}

function Grant-SharedMailboxPermissions {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [object]$Mailbox,
        [string]$AdminUser
    )
    
    try {
        $MailboxName = $Mailbox.DisplayName
        $MailboxId = $Mailbox.Identity
        
        Write-Log "Processing shared mailbox: $MailboxName" "INFO"
        
        # Check current permissions
        $FullAccessPerms = Get-MailboxPermission -Identity $MailboxId | Where-Object { $_.User -like "*@*" }
        $SendAsPerms = Get-RecipientPermission -Identity $MailboxId | Where-Object { $_.Trustee -like "*@*" }
        
        $AdminHasFullAccess = $FullAccessPerms.User -contains $AdminUser
        $AdminHasSendAs = $SendAsPerms.Trustee -contains $AdminUser
        
        # Grant Full Access if not already present
        if (-not $AdminHasFullAccess) {
            if ($PSCmdlet.ShouldProcess($MailboxId, "Grant Full Access to $AdminUser")) {
                Add-MailboxPermission -Identity $MailboxId -User $AdminUser -AccessRights FullAccess -InheritanceType All -ErrorAction Stop
                Write-Log "✅ Granted Full Access to $AdminUser on $MailboxName" "SUCCESS"
            }
        }
        
        # Grant Send As if not already present
        if (-not $AdminHasSendAs) {
            if ($PSCmdlet.ShouldProcess($MailboxId, "Grant Send As to $AdminUser")) {
                Add-RecipientPermission -Identity $MailboxId -Trustee $AdminUser -AccessRights SendAs -Confirm:$false -ErrorAction Stop
                Write-Log "✅ Granted Send As to $AdminUser on $MailboxName" "SUCCESS"
            }
        }
        
        if ($AdminHasFullAccess -and $AdminHasSendAs) {
            Write-Log "✅ $AdminUser already has comprehensive access to $MailboxName" "SUCCESS"
        }
        
        return @{
            Success = $true
            Action = "Set Permissions"
            Mailbox = $MailboxName
            MailboxType = "SharedMailbox"
            AdminHasFullAccess = $true
            AdminHasSendAs = $true
        }
    }
    catch {
        Write-Log "❌ Failed to grant permissions to shared mailbox $($Mailbox.DisplayName): $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Action = "Failed"
            Mailbox = $Mailbox.DisplayName
            MailboxType = "SharedMailbox"
            Error = $_.Exception.Message
        }
    }
}

# Main execution
Write-Log "Starting COMPREHENSIVE ADMIN RIGHTS ASSIGNMENT" "INFO"
Write-Log "Target Admin User: $AdminUser" "INFO"
Write-Log "Granting comprehensive rights and permissions to ALL groups and mailboxes..." "INFO"

# Check Exchange Online connection
if (-not (Test-ExchangeConnection)) {
    Write-Log "Not connected to Exchange Online. Attempting to connect..." "WARNING"
    try {
        Connect-ExchangeOnline -ShowProgress $false -ErrorAction Stop
        Write-Log "Connected to Exchange Online successfully" "SUCCESS"
    }
    catch {
        Write-Log "Failed to connect to Exchange Online: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# Verify target admin user exists
try {
    $AdminUserCheck = Get-Recipient -Identity $AdminUser -ErrorAction Stop
    Write-Log "Target admin user $AdminUser verified: $($AdminUserCheck.DisplayName)" "SUCCESS"
}
catch {
    Write-Log "Target admin user $AdminUser not found: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Discover all groups and mailboxes
Write-Log "Discovering all groups and mailboxes in the tenant..." "INFO"

# Get Distribution Groups
$DistributionGroups = @()
try {
    $DistributionGroups = Get-DistributionGroup -ResultSize Unlimited
    Write-Log "Found $($DistributionGroups.Count) distribution groups" "INFO"
}
catch {
    Write-Log "Failed to get distribution groups: $($_.Exception.Message)" "ERROR"
}

# Get Office 365 Groups
$Office365Groups = @()
try {
    $Office365Groups = Get-UnifiedGroup -ResultSize Unlimited
    Write-Log "Found $($Office365Groups.Count) Office 365 groups" "INFO"
}
catch {
    Write-Log "Failed to get Office 365 groups (cmdlet may not be available): $($_.Exception.Message)" "WARNING"
}

# Get Security Groups
$SecurityGroups = @()
try {
    $SecurityGroups = Get-Group -ResultSize Unlimited | Where-Object { $_.RecipientType -eq "MailUniversalSecurityGroup" }
    Write-Log "Found $($SecurityGroups.Count) mail-enabled security groups" "INFO"
}
catch {
    Write-Log "Failed to get security groups: $($_.Exception.Message)" "WARNING"
}

# Get Shared Mailboxes
$SharedMailboxes = @()
try {
    $SharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited
    Write-Log "Found $($SharedMailboxes.Count) shared mailboxes" "INFO"
}
catch {
    Write-Log "Failed to get shared mailboxes: $($_.Exception.Message)" "WARNING"
}

$TotalObjects = $DistributionGroups.Count + $Office365Groups.Count + $SecurityGroups.Count + $SharedMailboxes.Count
Write-Log "Total objects to process: $TotalObjects" "INFO"

# Process Distribution Groups
Write-Log "=== PROCESSING DISTRIBUTION GROUPS ===" "INFO"
foreach ($Group in $DistributionGroups) {
    $Result = Grant-DistributionGroupAdminRights -Group $Group -AdminUser $AdminUser
    $Results.DistributionGroups += $Result
}

# Process Office 365 Groups
if ($Office365Groups.Count -gt 0) {
    Write-Log "=== PROCESSING OFFICE 365 GROUPS ===" "INFO"
    foreach ($Group in $Office365Groups) {
        $Result = Grant-Office365GroupAdminRights -Group $Group -AdminUser $AdminUser
        $Results.Office365Groups += $Result
    }
}

# Process Security Groups (use same logic as distribution groups)
if ($SecurityGroups.Count -gt 0) {
    Write-Log "=== PROCESSING SECURITY GROUPS ===" "INFO"
    foreach ($Group in $SecurityGroups) {
        $Result = Grant-DistributionGroupAdminRights -Group $Group -AdminUser $AdminUser
        $Results.SecurityGroups += $Result
    }
}

# Process Shared Mailboxes
if ($SharedMailboxes.Count -gt 0) {
    Write-Log "=== PROCESSING SHARED MAILBOXES ===" "INFO"
    foreach ($Mailbox in $SharedMailboxes) {
        $Result = Grant-SharedMailboxPermissions -Mailbox $Mailbox -AdminUser $AdminUser
        $Results.SharedMailboxes += $Result
    }
}

# Calculate summary statistics
$AllResults = $Results.DistributionGroups + $Results.Office365Groups + $Results.SecurityGroups + $Results.SharedMailboxes

$Results.Summary = @{
    TotalObjects = $TotalObjects
    DistributionGroups = $DistributionGroups.Count
    Office365Groups = $Office365Groups.Count
    SecurityGroups = $SecurityGroups.Count
    SharedMailboxes = $SharedMailboxes.Count
    TotalSuccessful = ($AllResults | Where-Object { $_.Success -eq $true }).Count
    TotalFailed = ($AllResults | Where-Object { $_.Success -eq $false }).Count
    SuccessRate = if ($AllResults.Count -gt 0) { [Math]::Round(($AllResults | Where-Object { $_.Success -eq $true }).Count / $AllResults.Count * 100, 2) } else { 0 }
}

# Summary
Write-Log "=== COMPREHENSIVE ADMIN RIGHTS ASSIGNMENT SUMMARY ===" "INFO"
Write-Log "Target Admin User: $AdminUser" "INFO"
Write-Log "Total objects processed: $($Results.Summary.TotalObjects)" "INFO"
Write-Log "Distribution groups: $($Results.Summary.DistributionGroups)" "INFO"
Write-Log "Office 365 groups: $($Results.Summary.Office365Groups)" "INFO"
Write-Log "Security groups: $($Results.Summary.SecurityGroups)" "INFO"
Write-Log "Shared mailboxes: $($Results.Summary.SharedMailboxes)" "INFO"
Write-Log "Successfully processed: $($Results.Summary.TotalSuccessful)" "SUCCESS"
Write-Log "Failed: $($Results.Summary.TotalFailed)" $(if ($Results.Summary.TotalFailed -gt 0) { "ERROR" } else { "INFO" })
Write-Log "Success rate: $($Results.Summary.SuccessRate)%" $(if ($Results.Summary.SuccessRate -eq 100) { "SUCCESS" } else { "WARNING" })

# Export results
$ResultsPath = Join-Path $LogPath "GrantComprehensiveRights-Results-$Timestamp.json"
$Results | ConvertTo-Json -Depth 5 | Out-File -FilePath $ResultsPath -Encoding UTF8
Write-Log "Results exported to: $ResultsPath" "INFO"

# Show failed objects if any
$FailedObjects = $AllResults | Where-Object { $_.Success -eq $false }
if ($FailedObjects.Count -gt 0) {
    Write-Log "=== FAILED OBJECTS ===" "WARNING"
    foreach ($Failed in $FailedObjects) {
        $ObjectName = if ($Failed.Group) { $Failed.Group } else { $Failed.Mailbox }
        Write-Log "❌ $ObjectName ($($Failed.GroupType)$($Failed.MailboxType)): $($Failed.Error)" "ERROR"
    }
}

if ($Results.Summary.SuccessRate -eq 100) {
    Write-Log "🎉 SUCCESS: $AdminUser now has comprehensive admin rights to ALL objects!" "SUCCESS"
} else {
    Write-Log "⚠️ PARTIAL SUCCESS: $AdminUser has admin rights to $($Results.Summary.TotalSuccessful) out of $($Results.Summary.TotalObjects) objects" "WARNING"
}

Write-Log "Comprehensive admin rights assignment completed" "SUCCESS"
Write-Log "Log file: $LogFile" "INFO"
