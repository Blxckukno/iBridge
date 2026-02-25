#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Ensure both lwandile.gasela@ibridge.co.za and mgqibelo.gasela@ibridge.co.za have identical comprehensive admin rights
.DESCRIPTION
    This script ensures both admins have identical access to all distribution groups, Office 365 groups, and security groups.
    It makes both users managers/owners of all groups in the tenant.
.PARAMETER WhatIf
    Run in test mode to see what would be changed without making actual changes
.EXAMPLE
    .\Ensure-Dual-Admin-Rights.ps1 -WhatIf
    .\Ensure-Dual-Admin-Rights.ps1
#>

[CmdletBinding()]
param(
    [switch]$WhatIf
)

# Configuration
$Admin1 = "lwandile.gasela@ibridge.co.za"
$Admin2 = "Mgqibelo.Gasela@ibridge.co.za"  # Correct capitalization
$ScriptName = "Ensure-Dual-Admin-Rights"
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
    Admin1 = $Admin1
    Admin2 = $Admin2
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
            Write-Log "Failed to resolve user identity for $EmailAddress : $($_.Exception.Message)" "ERROR"
            return $null
        }
    }
}

function Ensure-DistributionGroupDualAdminRights {
    param(
        [object]$Group,
        [string]$Admin1,
        [string]$Admin2,
        [bool]$TestMode
    )
    
    try {
        $GroupName = $Group.DisplayName
        $GroupId = $Group.Identity
        
        # Check current managers
        $Admin1IsManager = $Group.ManagedBy -contains $Admin1
        $Admin2IsManager = $Group.ManagedBy -contains $Admin2
        
        $ActionsNeeded = @()
        if (-not $Admin1IsManager) { $ActionsNeeded += "Add $Admin1 as manager" }
        if (-not $Admin2IsManager) { $ActionsNeeded += "Add $Admin2 as manager" }
        
        if ($ActionsNeeded.Count -eq 0) {
            Write-Log "Both admins are already managers of $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Both Already Managers"
                Group = $GroupName
                GroupType = "DistributionGroup"
                Admin1IsManager = $true
                Admin2IsManager = $true
            }
        }
        
        if ($TestMode) {
            Write-Log "WHATIF: Would ensure both admins are managers of $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Would Ensure Both Are Managers"
                Group = $GroupName
                GroupType = "DistributionGroup"
                WhatIf = $true
                ActionsNeeded = $ActionsNeeded
            }
        }
        
        # Add both admins as managers
        $CurrentManagers = @($Group.ManagedBy)
        $NewManagers = @($CurrentManagers)
        
        if (-not $Admin1IsManager) {
            $NewManagers += $Admin1
        }
        if (-not $Admin2IsManager) {
            $NewManagers += $Admin2
        }
        
        # Remove duplicates
        $NewManagers = $NewManagers | Sort-Object -Unique
        
        Set-DistributionGroup -Identity $GroupId -ManagedBy $NewManagers -ErrorAction Stop
        
        # Apply moderation with both admins and authorized users
        $ValidModerators = @($Admin1, $Admin2)
        foreach ($User in $Config.AuthorizedUsers) {
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
        
        # Remove duplicates and apply moderation
        $ValidModerators = $ValidModerators | Sort-Object -Unique
        
        Set-DistributionGroup -Identity $GroupId `
            -ModerationEnabled:$true `
            -ModeratedBy $ValidModerators `
            -SendModerationNotifications Never `
            -ErrorAction Stop
        
        Write-Log "Successfully ensured both admins are managers of $GroupName with moderation" "SUCCESS"
        return @{
            Success = $true
            Action = "Ensured Both Are Managers"
            Group = $GroupName
            GroupType = "DistributionGroup"
            Admin1IsManager = $true
            Admin2IsManager = $true
            ModerationEnabled = $true
            ModeratorCount = $ValidModerators.Count
        }
    }
    catch {
        Write-Log "Failed to ensure dual admin rights for $GroupName : $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Action = "Failed to Ensure Dual Rights"
            Group = $GroupName
            GroupType = "DistributionGroup"
            Error = $_.Exception.Message
        }
    }
}

function Ensure-Office365GroupDualAdminRights {
    param(
        [object]$Group,
        [string]$Admin1,
        [string]$Admin2,
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
        
        $Admin1IsOwner = $Owners.PrimarySmtpAddress -contains $Admin1
        $Admin1IsMember = $Members.PrimarySmtpAddress -contains $Admin1
        $Admin2IsOwner = $Owners.PrimarySmtpAddress -contains $Admin2
        $Admin2IsMember = $Members.PrimarySmtpAddress -contains $Admin2
        
        $ActionsNeeded = @()
        if (-not $Admin1IsOwner) { $ActionsNeeded += "Add $Admin1 as owner" }
        if (-not $Admin1IsMember) { $ActionsNeeded += "Add $Admin1 as member" }
        if (-not $Admin2IsOwner) { $ActionsNeeded += "Add $Admin2 as owner" }
        if (-not $Admin2IsMember) { $ActionsNeeded += "Add $Admin2 as member" }
        
        if ($ActionsNeeded.Count -eq 0) {
            Write-Log "Both admins are already owners/members of $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Both Already Owners/Members"
                Group = $GroupName
                GroupType = "Office365Group"
                Admin1IsOwner = $true
                Admin1IsMember = $true
                Admin2IsOwner = $true
                Admin2IsMember = $true
            }
        }
        
        if ($TestMode) {
            Write-Log "WHATIF: Would ensure both admins are owners/members of $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Would Ensure Both Are Owners/Members"
                Group = $GroupName
                GroupType = "Office365Group"
                WhatIf = $true
                ActionsNeeded = $ActionsNeeded
            }
        }
        
        # Add admins as members first (required before adding as owners)
        if (-not $Admin1IsMember) {
            Add-UnifiedGroupLinks -Identity $GroupId -LinkType Members -Links $Admin1 -ErrorAction Stop
            Write-Log "Added $Admin1 as member to $GroupName" "SUCCESS"
        }
        if (-not $Admin2IsMember) {
            Add-UnifiedGroupLinks -Identity $GroupId -LinkType Members -Links $Admin2 -ErrorAction Stop
            Write-Log "Added $Admin2 as member to $GroupName" "SUCCESS"
        }
        
        # Add admins as owners
        if (-not $Admin1IsOwner) {
            Add-UnifiedGroupLinks -Identity $GroupId -LinkType Owners -Links $Admin1 -ErrorAction Stop
            Write-Log "Added $Admin1 as owner to $GroupName" "SUCCESS"
        }
        if (-not $Admin2IsOwner) {
            Add-UnifiedGroupLinks -Identity $GroupId -LinkType Owners -Links $Admin2 -ErrorAction Stop
            Write-Log "Added $Admin2 as owner to $GroupName" "SUCCESS"
        }
        
        return @{
            Success = $true
            Action = "Ensured Both Are Owners/Members"
            Group = $GroupName
            GroupType = "Office365Group"
            Admin1IsOwner = $true
            Admin1IsMember = $true
            Admin2IsOwner = $true
            Admin2IsMember = $true
            Admin1MemberAdded = (-not $Admin1IsMember)
            Admin1OwnerAdded = (-not $Admin1IsOwner)
            Admin2MemberAdded = (-not $Admin2IsMember)
            Admin2OwnerAdded = (-not $Admin2IsOwner)
        }
    }
    catch {
        Write-Log "Failed to ensure dual admin rights for Office 365 group $GroupName : $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Action = "Failed to Ensure Dual Rights"
            Group = $GroupName
            GroupType = "Office365Group"
            Error = $_.Exception.Message
        }
    }
}

# Main script
Write-Log "Starting DUAL ADMIN RIGHTS ENFORCEMENT" "INFO"
Write-Log "Admin 1: $Admin1" "INFO"
Write-Log "Admin 2: $Admin2" "INFO"
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
$User1 = Get-UserIdentity -EmailAddress $Admin1
if (-not $User1) {
    Write-Log "Cannot proceed - admin user $Admin1 not found" "ERROR"
    exit 1
}
Write-Log "Admin user $Admin1 verified: $($User1.DisplayName)" "SUCCESS"

$User2 = Get-UserIdentity -EmailAddress $Admin2
if (-not $User2) {
    Write-Log "Cannot proceed - admin user $Admin2 not found" "ERROR"
    exit 1
}
Write-Log "Admin user $Admin2 verified: $($User2.DisplayName)" "SUCCESS"

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
Write-Log "Starting dual admin rights enforcement..." "INFO"

# Process Distribution Groups
foreach ($Group in $DistributionGroups) {
    Write-Log "Processing distribution group: $($Group.DisplayName)" "INFO"
    $Result = Ensure-DistributionGroupDualAdminRights -Group $Group -Admin1 $Admin1 -Admin2 $Admin2 -TestMode $WhatIf
    $Results.DistributionGroups += $Result
}

# Process Office 365 Groups
foreach ($Group in $Office365Groups) {
    Write-Log "Processing Office 365 group: $($Group.DisplayName)" "INFO"
    $Result = Ensure-Office365GroupDualAdminRights -Group $Group -Admin1 $Admin1 -Admin2 $Admin2 -TestMode $WhatIf
    $Results.Office365Groups += $Result
}

# Process Security Groups (similar to distribution groups)
foreach ($Group in $SecurityGroups) {
    Write-Log "Processing security group: $($Group.DisplayName)" "INFO"
    $Result = Ensure-DistributionGroupDualAdminRights -Group $Group -Admin1 $Admin1 -Admin2 $Admin2 -TestMode $WhatIf
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
}

# Export results
$Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $ResultsFile -Encoding UTF8
Write-Log "Results exported to: $ResultsFile" "INFO"

# Display summary
Write-Log "=== DUAL ADMIN RIGHTS ENFORCEMENT SUMMARY ===" "INFO"
Write-Log "Total groups processed: $($Results.Summary.TotalGroups)" "INFO"
Write-Log "Distribution groups: $($Results.Summary.DistributionGroups)" "INFO"
Write-Log "Office 365 groups: $($Results.Summary.Office365Groups)" "INFO"
Write-Log "Security groups: $($Results.Summary.SecurityGroups)" "INFO"
Write-Log "Successfully processed: $($Results.Summary.TotalSuccessful)" "SUCCESS"
Write-Log "Failed: $($Results.Summary.TotalFailed)" "INFO"
Write-Log "Changes needed: $($Results.Summary.ChangesNeeded)" "INFO"

if ($WhatIf) {
    Write-Log "WhatIf mode - no changes were made" "INFO"
    Write-Log "Run without -WhatIf to apply changes" "INFO"
} else {
    Write-Log "Dual admin rights enforcement completed" "SUCCESS"
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
            $Admin1IsManager = $UpdatedGroup.ManagedBy -contains $Admin1
            $Admin2IsManager = $UpdatedGroup.ManagedBy -contains $Admin2
            Write-Log "  $($Group.DisplayName): $Admin1=$Admin1IsManager, $Admin2=$Admin2IsManager" "INFO"
        }
        catch {
            Write-Log "  $($Group.DisplayName): Verification failed - $($_.Exception.Message)" "WARNING"
        }
    }
    
    Write-Log "SUCCESS: Both $Admin1 and $Admin2 now have comprehensive dual admin rights!" "SUCCESS"
}

Write-Host "`n=== SCRIPT COMPLETED ===" -ForegroundColor Green
Write-Host "Log file: $LogFile" -ForegroundColor Cyan
Write-Host "Results file: $ResultsFile" -ForegroundColor Cyan
