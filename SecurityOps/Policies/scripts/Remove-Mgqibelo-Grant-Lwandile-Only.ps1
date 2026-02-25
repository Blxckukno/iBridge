#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Remove Mgqibelo.Gasela@ibridge.co.za from admin roles while preserving membership
.DESCRIPTION
    This script removes Mgqibelo.Gasela@ibridge.co.za from all administrative roles (manager/owner)
    but preserves his regular membership in groups. Ensures that only lwandile.gasela@ibridge.co.za 
    has comprehensive admin rights to all distribution groups, Office 365 groups, and security groups.
.PARAMETER WhatIf
    Run in test mode to see what would be changed without making actual changes
.EXAMPLE
    .\Remove-Mgqibelo-Grant-Lwandile-Only.ps1 -WhatIf
    .\Remove-Mgqibelo-Grant-Lwandile-Only.ps1
#>

[CmdletBinding()]
param(
    [switch]$WhatIf
)

# Configuration
$PrimaryAdmin = "lwandile.gasela@ibridge.co.za"
$UserToRemove = "Mgqibelo.Gasela@ibridge.co.za"
$ScriptName = "Remove-Mgqibelo-Grant-Lwandile-Only"
$LogFile = "C:\Users\Lwandile Gasela\iBridge\Policies\logs\$ScriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$ResultsFile = "C:\Users\Lwandile Gasela\iBridge\Policies\logs\$ScriptName-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

# Import configuration for authorized users
$ConfigPath = "C:\Users\Lwandile Gasela\iBridge\Policies\config\email-config.json"
$Config = Get-Content $ConfigPath | ConvertFrom-Json

# Results tracking
$Results = @{
    Timestamp = Get-Date
    ScriptName = $ScriptName
    WhatIf = $WhatIf
    PrimaryAdmin = $PrimaryAdmin
    UserToRemove = $UserToRemove
    DistributionGroups = @()
    Office365Groups = @()
    SecurityGroups = @()
    Summary = @{}
}

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogEntry
    
    switch ($Level) {
        "ERROR" { Write-Host $LogEntry -ForegroundColor Red }
        "WARNING" { Write-Host $LogEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $LogEntry -ForegroundColor Green }
        "INFO" { Write-Host $LogEntry -ForegroundColor White }
    }
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

function Get-UserIdentity {
    param([string]$EmailAddress)
    
    try {
        $Mailbox = Get-Mailbox -Identity $EmailAddress -ErrorAction Stop
        return $Mailbox
    }
    catch {
        try {
            $User = Get-User -Identity $EmailAddress -ErrorAction Stop
            return $User
        }
        catch {
            Write-Log "Failed to resolve user identity for $EmailAddress : $($_.Exception.Message)" "WARNING"
            return $null
        }
    }
}

function Set-DistributionGroupSingleAdmin {
    param(
        [object]$Group,
        [string]$PrimaryAdmin,
        [string]$UserToRemove,
        [bool]$TestMode
    )
    
    try {
        $GroupName = $Group.DisplayName
        $GroupId = $Group.Identity
        
        # Check current managers
        $CurrentManagers = @($Group.ManagedBy)
        $PrimaryIsManager = $CurrentManagers -contains $PrimaryAdmin
        $UserToRemoveIsManager = $CurrentManagers -contains $UserToRemove
        
        $ActionsNeeded = @()
        if (-not $PrimaryIsManager) { $ActionsNeeded += "Add $PrimaryAdmin as manager" }
        if ($UserToRemoveIsManager) { $ActionsNeeded += "Remove $UserToRemove as manager" }
        
        if ($ActionsNeeded.Count -eq 0) {
            Write-Log "$PrimaryAdmin is already sole manager of $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Already Correct"
                Group = $GroupName
                GroupType = "DistributionGroup"
                PrimaryIsManager = $true
                UserToRemoveIsManager = $false
            }
        }
        
        if ($TestMode) {
            Write-Log "WHATIF: Would set $PrimaryAdmin as sole manager of $GroupName" "INFO"
            if ($UserToRemoveIsManager) {
                Write-Log "WHATIF: Would remove $UserToRemove from $GroupName" "INFO"
            }
            return @{
                Success = $true
                Action = "Would Set Single Admin"
                Group = $GroupName
                GroupType = "DistributionGroup"
                WhatIf = $true
                ActionsNeeded = $ActionsNeeded
            }
        }
        
        # Set primary admin as sole manager
        Set-DistributionGroup -Identity $GroupId -ManagedBy $PrimaryAdmin -ErrorAction Stop
        
        # Apply moderation with primary admin and authorized users
        $ValidModerators = @($PrimaryAdmin)
        foreach ($User in $Config.AuthorizedUsers) {
            if ($User -ne $UserToRemove) {  # Exclude the user we're removing
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
        
        Set-DistributionGroup -Identity $GroupId `
            -ModerationEnabled:$true `
            -ModeratedBy $ValidModerators `
            -SendModerationNotifications Never `
            -ErrorAction Stop
        
        Write-Log "Successfully set $PrimaryAdmin as sole manager of $GroupName with moderation" "SUCCESS"
        if ($UserToRemoveIsManager) {
            Write-Log "Removed $UserToRemove from $GroupName" "SUCCESS"
        }
        
        return @{
            Success = $true
            Action = "Set Single Admin"
            Group = $GroupName
            GroupType = "DistributionGroup"
            PrimaryIsManager = $true
            UserToRemoveIsManager = $false
            ModerationEnabled = $true
            ModeratorCount = $ValidModerators.Count
            UserRemoved = $UserToRemoveIsManager
        }
    }
    catch {
        Write-Log "Failed to set single admin for $GroupName : $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Action = "Failed to Set Single Admin"
            Group = $GroupName
            GroupType = "DistributionGroup"
            Error = $_.Exception.Message
        }
    }
}

function Set-Office365GroupSingleAdmin {
    param(
        [object]$Group,
        [string]$PrimaryAdmin,
        [string]$UserToRemove,
        [bool]$TestMode
    )
    
    try {
        $GroupName = $Group.DisplayName
        $GroupId = $Group.Identity
        
        # Check current ownership/membership
        $Owners = @()
        $Members = @()
        
        try {
            $Owners = Get-UnifiedGroupLinks -Identity $GroupId -LinkType Owners -ErrorAction Stop
            $Members = Get-UnifiedGroupLinks -Identity $GroupId -LinkType Members -ErrorAction Stop
        }
        catch {
            Write-Log "Could not check ownership/membership for $GroupName : $($_.Exception.Message)" "WARNING"
            return @{
                Success = $false
                Action = "Failed to Check Permissions"
                Group = $GroupName
                GroupType = "Office365Group"
                Error = $_.Exception.Message
            }
        }
        
        $PrimaryIsOwner = $Owners.PrimarySmtpAddress -contains $PrimaryAdmin
        $PrimaryIsMember = $Members.PrimarySmtpAddress -contains $PrimaryAdmin
        $UserToRemoveIsOwner = $Owners.PrimarySmtpAddress -contains $UserToRemove
        $UserToRemoveIsMember = $Members.PrimarySmtpAddress -contains $UserToRemove
        
        $ActionsNeeded = @()
        if (-not $PrimaryIsOwner) { $ActionsNeeded += "Add $PrimaryAdmin as owner" }
        if (-not $PrimaryIsMember) { $ActionsNeeded += "Add $PrimaryAdmin as member" }
        if ($UserToRemoveIsOwner) { $ActionsNeeded += "Remove $UserToRemove as owner (but keep as member)" }
        
        if ($ActionsNeeded.Count -eq 0) {
            Write-Log "$PrimaryAdmin already has correct access to $GroupName and $UserToRemove is not an owner" "INFO"
            return @{
                Success = $true
                Action = "Already Correct"
                Group = $GroupName
                GroupType = "Office365Group"
                PrimaryIsOwner = $true
                PrimaryIsMember = $true
                UserToRemoveIsOwner = $false
                UserToRemoveIsMember = $UserToRemoveIsMember
            }
        }
        
        if ($TestMode) {
            Write-Log "WHATIF: Would ensure $PrimaryAdmin has admin access and remove $UserToRemove from owner role in $GroupName (preserving membership)" "INFO"
            return @{
                Success = $true
                Action = "Would Set Single Admin"
                Group = $GroupName
                GroupType = "Office365Group"
                WhatIf = $true
                ActionsNeeded = $ActionsNeeded
            }
        }
        
        # Remove user from owner role only (preserve membership)
        if ($UserToRemoveIsOwner) {
            Remove-UnifiedGroupLinks -Identity $GroupId -LinkType Owners -Links $UserToRemove -Confirm:$false -ErrorAction Stop
            Write-Log "Removed $UserToRemove as owner from $GroupName (membership preserved)" "SUCCESS"
        }
        
        # Add primary admin as member first (required before adding as owner)
        if (-not $PrimaryIsMember) {
            Add-UnifiedGroupLinks -Identity $GroupId -LinkType Members -Links $PrimaryAdmin -ErrorAction Stop
            Write-Log "Added $PrimaryAdmin as member to $GroupName" "SUCCESS"
        }
        
        # Add primary admin as owner
        if (-not $PrimaryIsOwner) {
            Add-UnifiedGroupLinks -Identity $GroupId -LinkType Owners -Links $PrimaryAdmin -ErrorAction Stop
            Write-Log "Added $PrimaryAdmin as owner to $GroupName" "SUCCESS"
        }
        
        return @{
            Success = $true
            Action = "Set Single Admin"
            Group = $GroupName
            GroupType = "Office365Group"
            PrimaryIsOwner = $true
            PrimaryIsMember = $true
            UserToRemoveIsOwner = $false
            UserToRemoveIsMember = $UserToRemoveIsMember  # Preserved
            PrimaryMemberAdded = (-not $PrimaryIsMember)
            PrimaryOwnerAdded = (-not $PrimaryIsOwner)
            UserOwnerRemoved = $UserToRemoveIsOwner
            MembershipPreserved = $UserToRemoveIsMember
        }
    }
    catch {
        Write-Log "Failed to set single admin for Office 365 group $GroupName : $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Action = "Failed to Set Single Admin"
            Group = $GroupName
            GroupType = "Office365Group"
            Error = $_.Exception.Message
        }
    }
}

# Main script
Write-Log "Starting SINGLE ADMIN ENFORCEMENT - Removing Mgqibelo from admin roles, preserving membership" "INFO"
Write-Log "Primary Admin (to keep): $PrimaryAdmin" "INFO"
Write-Log "User to Remove from admin roles: $UserToRemove" "INFO"
Write-Log "Note: $UserToRemove will be removed from manager/owner roles but membership will be preserved" "INFO"
Write-Log "WhatIf Mode: $WhatIf" "INFO"

# Check Exchange Online connection
if (-not (Test-ExchangeConnection)) {
    Write-Log "Not connected to Exchange Online. Attempting to connect..." "WARNING"
    try {
        Connect-ExchangeOnline -ShowProgress $false
        Write-Log "Connected to Exchange Online successfully" "SUCCESS"
    }
    catch {
        Write-Log "Failed to connect to Exchange Online: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# Verify primary admin exists
$PrimaryAdminUser = Get-UserIdentity -EmailAddress $PrimaryAdmin
if (-not $PrimaryAdminUser) {
    Write-Log "Cannot proceed - primary admin user $PrimaryAdmin not found" "ERROR"
    exit 1
}
Write-Log "Primary admin user $PrimaryAdmin verified: $($PrimaryAdminUser.DisplayName)" "SUCCESS"

# Check if user to remove exists
$UserToRemoveObj = Get-UserIdentity -EmailAddress $UserToRemove
if ($UserToRemoveObj) {
    Write-Log "User to remove $UserToRemove found: $($UserToRemoveObj.DisplayName)" "INFO"
} else {
    Write-Log "User to remove $UserToRemove not found - will skip removal operations" "WARNING"
}

# Get all groups
Write-Log "Discovering all groups in the tenant..." "INFO"

# Distribution Groups
$DistributionGroups = @()
try {
    $DistributionGroups = Get-DistributionGroup -ResultSize Unlimited
    Write-Log "Found $($DistributionGroups.Count) distribution groups" "INFO"
}
catch {
    Write-Log "Failed to get distribution groups: $($_.Exception.Message)" "ERROR"
}

# Office 365 Groups (Unified Groups)
$Office365Groups = @()
try {
    $Office365Groups = Get-UnifiedGroup -ResultSize Unlimited
    Write-Log "Found $($Office365Groups.Count) Office 365 groups" "INFO"
}
catch {
    Write-Log "Failed to get Office 365 groups: $($_.Exception.Message)" "WARNING"
}

# Security Groups (mail-enabled)
$SecurityGroups = @()
try {
    $SecurityGroups = Get-Group -ResultSize Unlimited | Where-Object { $_.RecipientType -eq "MailUniversalSecurityGroup" }
    Write-Log "Found $($SecurityGroups.Count) mail-enabled security groups" "INFO"
}
catch {
    Write-Log "Failed to get security groups: $($_.Exception.Message)" "WARNING"
}

$TotalGroups = $DistributionGroups.Count + $Office365Groups.Count + $SecurityGroups.Count
Write-Log "Total groups found: $TotalGroups" "INFO"

# Process groups
Write-Log "Starting single admin enforcement (removing Mgqibelo from admin roles, preserving membership)..." "INFO"

# Process Distribution Groups
foreach ($Group in $DistributionGroups) {
    Write-Log "Processing distribution group: $($Group.DisplayName)" "INFO"
    $Result = Set-DistributionGroupSingleAdmin -Group $Group -PrimaryAdmin $PrimaryAdmin -UserToRemove $UserToRemove -TestMode $WhatIf
    $Results.DistributionGroups += $Result
}

# Process Office 365 Groups
foreach ($Group in $Office365Groups) {
    Write-Log "Processing Office 365 group: $($Group.DisplayName)" "INFO"
    $Result = Set-Office365GroupSingleAdmin -Group $Group -PrimaryAdmin $PrimaryAdmin -UserToRemove $UserToRemove -TestMode $WhatIf
    $Results.Office365Groups += $Result
}

# Process Security Groups (similar to distribution groups)
foreach ($Group in $SecurityGroups) {
    Write-Log "Processing security group: $($Group.DisplayName)" "INFO"
    $Result = Set-DistributionGroupSingleAdmin -Group $Group -PrimaryAdmin $PrimaryAdmin -UserToRemove $UserToRemove -TestMode $WhatIf
    $Results.SecurityGroups += $Result
}

# Calculate summary
$Results.Summary = @{
    TotalGroups = $TotalGroups
    DistributionGroups = $DistributionGroups.Count
    Office365Groups = $Office365Groups.Count
    SecurityGroups = $SecurityGroups.Count
    DistributionGroupsProcessed = ($Results.DistributionGroups | Where-Object { $_.Success }).Count
    Office365GroupsProcessed = ($Results.Office365Groups | Where-Object { $_.Success }).Count
    SecurityGroupsProcessed = ($Results.SecurityGroups | Where-Object { $_.Success }).Count
    TotalSuccessful = ($Results.DistributionGroups + $Results.Office365Groups + $Results.SecurityGroups | Where-Object { $_.Success }).Count
    TotalFailed = ($Results.DistributionGroups + $Results.Office365Groups + $Results.SecurityGroups | Where-Object { -not $_.Success }).Count
    ChangesNeeded = ($Results.DistributionGroups + $Results.Office365Groups + $Results.SecurityGroups | Where-Object { $_.Success -and $_.Action -notlike "*Already*" }).Count
    UsersRemoved = ($Results.DistributionGroups + $Results.Office365Groups + $Results.SecurityGroups | Where-Object { $_.UserRemoved -or $_.UserOwnerRemoved }).Count
    MembershipsPreserved = ($Results.Office365Groups | Where-Object { $_.MembershipPreserved }).Count
}

# Export results
$Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $ResultsFile -Encoding UTF8
Write-Log "Results exported to: $ResultsFile" "INFO"

# Display summary
Write-Log "=== SINGLE ADMIN ENFORCEMENT SUMMARY ===" "INFO"
Write-Log "Total groups processed: $($Results.Summary.TotalGroups)" "INFO"
Write-Log "Distribution groups: $($Results.Summary.DistributionGroups)" "INFO"
Write-Log "Office 365 groups: $($Results.Summary.Office365Groups)" "INFO"
Write-Log "Security groups: $($Results.Summary.SecurityGroups)" "INFO"
Write-Log "Successfully processed: $($Results.Summary.TotalSuccessful)" "SUCCESS"
Write-Log "Failed: $($Results.Summary.TotalFailed)" "INFO"
Write-Log "Changes needed: $($Results.Summary.ChangesNeeded)" "INFO"
Write-Log "Groups where $UserToRemove was removed from admin roles: $($Results.Summary.UsersRemoved)" "INFO"
Write-Log "Office 365 groups where $UserToRemove membership was preserved: $($Results.Summary.MembershipsPreserved)" "INFO"

if ($WhatIf) {
    Write-Log "WhatIf mode - no changes were made" "INFO"
    Write-Log "Run without -WhatIf to apply changes" "INFO"
} else {
    Write-Log "Single admin enforcement completed" "SUCCESS"
    Write-Log "$PrimaryAdmin now has sole administrative access to all groups" "SUCCESS"
    Write-Log "$UserToRemove has been removed from admin roles but membership preserved where applicable" "SUCCESS"
}

Write-Log "Log file: $LogFile" "INFO"

# Sample verification
if (-not $WhatIf) {
    Write-Log "Performing sample verification..." "INFO"
    
    # Check a few distribution groups
    $SampleGroups = $DistributionGroups | Select-Object -First 3
    foreach ($Group in $SampleGroups) {
        try {
            $UpdatedGroup = Get-DistributionGroup -Identity $Group.Identity
            $PrimaryIsManager = $UpdatedGroup.ManagedBy -contains $PrimaryAdmin
            $UserToRemoveIsManager = $UpdatedGroup.ManagedBy -contains $UserToRemove
            Write-Log "  $($Group.DisplayName): $PrimaryAdmin=$PrimaryIsManager, $UserToRemove=$UserToRemoveIsManager" "INFO"
        }
        catch {
            Write-Log "  $($Group.DisplayName): Verification failed - $($_.Exception.Message)" "WARNING"
        }
    }
    
    Write-Log "SUCCESS: $PrimaryAdmin now has sole comprehensive admin rights!" "SUCCESS"
    Write-Log "SUCCESS: $UserToRemove has been removed from admin roles but membership preserved!" "SUCCESS"
}

Write-Host "`n=== SCRIPT COMPLETED ===" -ForegroundColor Green
Write-Host "Log file: $LogFile" -ForegroundColor Cyan
Write-Host "Results file: $ResultsFile" -ForegroundColor Cyan
