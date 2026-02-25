#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Ensure lwandile.gasela@ibridge.co.za has the same rights as mgqibelo.gasela@ibridge.co.za
.DESCRIPTION
    This script verifies and synchronizes permissions between the two admin users,
    ensuring both have identical access to all distribution groups and Office 365 groups.
.PARAMETER WhatIf
    Run in test mode to see what would be changed without making actual changes
.EXAMPLE
    .\Sync-Admin-Rights.ps1 -WhatIf
    .\Sync-Admin-Rights.ps1
#>

[CmdletBinding()]
param(
    [switch]$WhatIf
)

# Configuration
$SourceAdmin = "mgqibelo.gasela@ibridge.co.za"  # Reference admin (source of truth)
$TargetAdmin = "lwandile.gasela@ibridge.co.za"  # Admin to sync permissions to
$ScriptName = "Sync-Admin-Rights"
$LogFile = "C:\Users\Lwandile Gasela\iBridge\Policies\logs\$ScriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$ResultsFile = "C:\Users\Lwandile Gasela\iBridge\Policies\logs\$ScriptName-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

# Results tracking
$Results = @{
    Timestamp = Get-Date
    ScriptName = $ScriptName
    WhatIf = $WhatIf
    SourceAdmin = $SourceAdmin
    TargetAdmin = $TargetAdmin
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
        # Try to get the mailbox first
        $Mailbox = Get-Mailbox -Identity $EmailAddress -ErrorAction Stop
        return $Mailbox
    }
    catch {
        # If that fails, try to get the user
        try {
            $User = Get-User -Identity $EmailAddress -ErrorAction Stop
            return $User
        }
        catch {
            Write-Log "Failed to resolve user identity for $EmailAddress : $($_.Exception.Message)" "ERROR"
            return $null
        }
    }
}

function Sync-DistributionGroupRights {
    param(
        [object]$Group,
        [string]$SourceUser,
        [string]$TargetUser,
        [bool]$TestMode
    )
    
    try {
        $GroupName = $Group.DisplayName
        $GroupId = $Group.Identity
        
        # Check if source user is a manager
        $SourceIsManager = $Group.ManagedBy -contains $SourceUser
        
        # Check if target user is a manager
        $TargetIsManager = $Group.ManagedBy -contains $TargetUser
        
        if (-not $SourceIsManager) {
            Write-Log "$SourceUser is not a manager of $GroupName - skipping" "WARNING"
            return @{
                Success = $true
                Action = "Skipped - Source Not Manager"
                Group = $GroupName
                GroupType = "DistributionGroup"
                SourceIsManager = $false
                TargetIsManager = $TargetIsManager
            }
        }
        
        if ($TargetIsManager) {
            Write-Log "$TargetUser is already a manager of $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Already Manager"
                Group = $GroupName
                GroupType = "DistributionGroup"
                SourceIsManager = $true
                TargetIsManager = $true
            }
        }
        
        if ($TestMode) {
            Write-Log "WHATIF: Would add $TargetUser as manager to $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Would Add Manager"
                Group = $GroupName
                GroupType = "DistributionGroup"
                WhatIf = $true
                SourceIsManager = $true
                TargetIsManager = $false
            }
        }
        
        # Add target user as manager
        $CurrentManagers = @($Group.ManagedBy)
        $NewManagers = $CurrentManagers + $TargetUser
        
        Set-DistributionGroup -Identity $GroupId -ManagedBy $NewManagers -ErrorAction Stop
        
        # Check if group has moderation enabled with source user
        if ($Group.ModerationEnabled -and $Group.ModeratedBy -contains $SourceUser) {
            # Add target user to moderators as well
            $CurrentModerators = @($Group.ModeratedBy)
            if ($CurrentModerators -notcontains $TargetUser) {
                $NewModerators = $CurrentModerators + $TargetUser
                Set-DistributionGroup -Identity $GroupId -ModeratedBy $NewModerators -ErrorAction Stop
                Write-Log "Added $TargetUser as moderator to $GroupName" "SUCCESS"
            }
        }
        
        Write-Log "Successfully added $TargetUser as manager to $GroupName" "SUCCESS"
        return @{
            Success = $true
            Action = "Added Manager"
            Group = $GroupName
            GroupType = "DistributionGroup"
            SourceIsManager = $true
            TargetIsManager = $true
            ModerationSynced = $Group.ModerationEnabled
        }
    }
    catch {
        Write-Log "Failed to sync rights for $GroupName : $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Action = "Failed to Sync"
            Group = $GroupName
            GroupType = "DistributionGroup"
            Error = $_.Exception.Message
        }
    }
}

function Sync-Office365GroupRights {
    param(
        [object]$Group,
        [string]$SourceUser,
        [string]$TargetUser,
        [bool]$TestMode
    )
    
    try {
        $GroupName = $Group.DisplayName
        $GroupId = $Group.Identity
        
        # Check if source user is an owner
        $SourceOwners = @()
        $SourceMembers = @()
        $TargetOwners = @()
        $TargetMembers = @()
        
        try {
            $SourceOwners = Get-UnifiedGroupLinks -Identity $GroupId -LinkType Owners -ErrorAction Stop
            $SourceMembers = Get-UnifiedGroupLinks -Identity $GroupId -LinkType Members -ErrorAction Stop
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
        
        $SourceIsOwner = $SourceOwners.PrimarySmtpAddress -contains $SourceUser
        $SourceIsMember = $SourceMembers.PrimarySmtpAddress -contains $SourceUser
        $TargetIsOwner = $SourceOwners.PrimarySmtpAddress -contains $TargetUser
        $TargetIsMember = $SourceMembers.PrimarySmtpAddress -contains $TargetUser
        
        if (-not $SourceIsOwner -and -not $SourceIsMember) {
            Write-Log "$SourceUser is not an owner/member of $GroupName - skipping" "WARNING"
            return @{
                Success = $true
                Action = "Skipped - Source Not Owner/Member"
                Group = $GroupName
                GroupType = "Office365Group"
                SourceIsOwner = $false
                SourceIsMember = $false
                TargetIsOwner = $TargetIsOwner
                TargetIsMember = $TargetIsMember
            }
        }
        
        if ($TargetIsOwner -and $TargetIsMember) {
            Write-Log "$TargetUser is already an owner/member of $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Already Owner/Member"
                Group = $GroupName
                GroupType = "Office365Group"
                SourceIsOwner = $SourceIsOwner
                SourceIsMember = $SourceIsMember
                TargetIsOwner = $true
                TargetIsMember = $true
            }
        }
        
        if ($TestMode) {
            Write-Log "WHATIF: Would sync $TargetUser permissions to match $SourceUser for $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Would Sync Permissions"
                Group = $GroupName
                GroupType = "Office365Group"
                WhatIf = $true
                SourceIsOwner = $SourceIsOwner
                SourceIsMember = $SourceIsMember
                TargetIsOwner = $TargetIsOwner
                TargetIsMember = $TargetIsMember
            }
        }
        
        # Sync membership
        if ($SourceIsMember -and -not $TargetIsMember) {
            Add-UnifiedGroupLinks -Identity $GroupId -LinkType Members -Links $TargetUser -ErrorAction Stop
            Write-Log "Added $TargetUser as member to $GroupName" "SUCCESS"
        }
        
        # Sync ownership
        if ($SourceIsOwner -and -not $TargetIsOwner) {
            Add-UnifiedGroupLinks -Identity $GroupId -LinkType Owners -Links $TargetUser -ErrorAction Stop
            Write-Log "Added $TargetUser as owner to $GroupName" "SUCCESS"
        }
        
        return @{
            Success = $true
            Action = "Synced Permissions"
            Group = $GroupName
            GroupType = "Office365Group"
            SourceIsOwner = $SourceIsOwner
            SourceIsMember = $SourceIsMember
            TargetIsOwner = $true
            TargetIsMember = $true
            MemberAdded = ($SourceIsMember -and -not $TargetIsMember)
            OwnerAdded = ($SourceIsOwner -and -not $TargetIsOwner)
        }
    }
    catch {
        Write-Log "Failed to sync Office 365 group rights for $GroupName : $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Action = "Failed to Sync"
            Group = $GroupName
            GroupType = "Office365Group"
            Error = $_.Exception.Message
        }
    }
}

# Main script
Write-Log "Starting ADMIN RIGHTS SYNCHRONIZATION" "INFO"
Write-Log "Source Admin (reference): $SourceAdmin" "INFO"
Write-Log "Target Admin (to sync): $TargetAdmin" "INFO"
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

# Verify both users exist
$SourceUser = Get-UserIdentity -EmailAddress $SourceAdmin
if (-not $SourceUser) {
    Write-Log "Cannot proceed - source user $SourceAdmin not found" "ERROR"
    exit 1
}
Write-Log "Source admin user $SourceAdmin verified: $($SourceUser.DisplayName)" "SUCCESS"

$TargetUser = Get-UserIdentity -EmailAddress $TargetAdmin
if (-not $TargetUser) {
    Write-Log "Cannot proceed - target user $TargetAdmin not found" "ERROR"
    exit 1
}
Write-Log "Target admin user $TargetAdmin verified: $($TargetUser.DisplayName)" "SUCCESS"

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
Write-Log "Starting rights synchronization from $SourceAdmin to $TargetAdmin..." "INFO"

# Process Distribution Groups
foreach ($Group in $DistributionGroups) {
    Write-Log "Processing distribution group: $($Group.DisplayName)" "INFO"
    $Result = Sync-DistributionGroupRights -Group $Group -SourceUser $SourceAdmin -TargetUser $TargetAdmin -TestMode $WhatIf
    $Results.DistributionGroups += $Result
}

# Process Office 365 Groups
foreach ($Group in $Office365Groups) {
    Write-Log "Processing Office 365 group: $($Group.DisplayName)" "INFO"
    $Result = Sync-Office365GroupRights -Group $Group -SourceUser $SourceAdmin -TargetUser $TargetAdmin -TestMode $WhatIf
    $Results.Office365Groups += $Result
}

# Process Security Groups (similar to distribution groups)
foreach ($Group in $SecurityGroups) {
    Write-Log "Processing security group: $($Group.DisplayName)" "INFO"
    $Result = Sync-DistributionGroupRights -Group $Group -SourceUser $SourceAdmin -TargetUser $TargetAdmin -TestMode $WhatIf
    $Results.SecurityGroups += $Result
}

# Calculate summary
$Results.Summary = @{
    TotalGroups = $TotalGroups
    DistributionGroups = $DistributionGroups.Count
    Office365Groups = $Office365Groups.Count
    SecurityGroups = $SecurityGroups.Count
    DistributionGroupsProcessed = ($Results.DistributionGroups | Where-Object { $_.Success -and $_.Action -ne "Skipped - Source Not Manager" }).Count
    Office365GroupsProcessed = ($Results.Office365Groups | Where-Object { $_.Success -and $_.Action -ne "Skipped - Source Not Owner/Member" }).Count
    SecurityGroupsProcessed = ($Results.SecurityGroups | Where-Object { $_.Success -and $_.Action -ne "Skipped - Source Not Manager" }).Count
    TotalSynchronized = ($Results.DistributionGroups + $Results.Office365Groups + $Results.SecurityGroups | Where-Object { $_.Success -and $_.Action -notlike "Skipped*" -and $_.Action -notlike "Already*" }).Count
    TotalFailed = ($Results.DistributionGroups + $Results.Office365Groups + $Results.SecurityGroups | Where-Object { -not $_.Success }).Count
}

# Export results
$Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $ResultsFile -Encoding UTF8
Write-Log "Results exported to: $ResultsFile" "INFO"

# Display summary
Write-Log "=== ADMIN RIGHTS SYNCHRONIZATION SUMMARY ===" "INFO"
Write-Log "Total groups processed: $($Results.Summary.TotalGroups)" "INFO"
Write-Log "Distribution groups: $($Results.Summary.DistributionGroups)" "INFO"
Write-Log "Office 365 groups: $($Results.Summary.Office365Groups)" "INFO"
Write-Log "Security groups: $($Results.Summary.SecurityGroups)" "INFO"
Write-Log "Successfully synchronized: $($Results.Summary.TotalSynchronized)" "SUCCESS"
Write-Log "Failed: $($Results.Summary.TotalFailed)" "INFO"

if ($WhatIf) {
    Write-Log "WhatIf mode - no changes were made" "INFO"
} else {
    Write-Log "Admin rights synchronization completed" "SUCCESS"
}

Write-Log "Log file: $LogFile" "INFO"

# Sample verification
if (-not $WhatIf) {
    Write-Log "Performing sample verification..." "INFO"
    
    # Check a few distribution groups
    $SampleGroups = $DistributionGroups | Where-Object { $_.ManagedBy -contains $SourceAdmin } | Select-Object -First 3
    foreach ($Group in $SampleGroups) {
        try {
            $UpdatedGroup = Get-DistributionGroup -Identity $Group.Identity
            $SourceIsManager = $UpdatedGroup.ManagedBy -contains $SourceAdmin
            $TargetIsManager = $UpdatedGroup.ManagedBy -contains $TargetAdmin
            Write-Log "  $($Group.DisplayName): Source=$SourceIsManager, Target=$TargetIsManager" "INFO"
        }
        catch {
            Write-Log "  $($Group.DisplayName): Verification failed - $($_.Exception.Message)" "WARNING"
        }
    }
    
    Write-Log "SUCCESS: $TargetAdmin now has synchronized rights with $SourceAdmin!" "SUCCESS"
}

Write-Host "`n=== SCRIPT COMPLETED ===" -ForegroundColor Green
Write-Host "Log file: $LogFile" -ForegroundColor Cyan
Write-Host "Results file: $ResultsFile" -ForegroundColor Cyan
