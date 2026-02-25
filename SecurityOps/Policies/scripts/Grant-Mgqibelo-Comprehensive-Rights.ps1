#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Grant comprehensive admin rights to mgqibelo.gasela@ibridge.co.za
.DESCRIPTION
    This script grants mgqibelo.gasela@ibridge.co.za the same admin rights as lwandile.gasela@ibridge.co.za
    across all distribution groups and Office 365 groups in the tenant.
.PARAMETER WhatIf
    Run in test mode to see what would be changed without making actual changes
.EXAMPLE
    .\Grant-Mgqibelo-Comprehensive-Rights.ps1 -WhatIf
    .\Grant-Mgqibelo-Comprehensive-Rights.ps1
#>

[CmdletBinding()]
param(
    [switch]$WhatIf
)

# Configuration
$MgqibeloAdmin = "mgqibelo.gasela@ibridge.co.za"
$LwandileAdmin = "lwandile.gasela@ibridge.co.za"
$ScriptName = "Grant-Mgqibelo-Comprehensive-Rights"
$LogFile = "C:\Users\Lwandile Gasela\iBridge\Policies\logs\$ScriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$ResultsFile = "C:\Users\Lwandile Gasela\iBridge\Policies\logs\$ScriptName-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

# Results tracking
$Results = @{
    Timestamp = Get-Date
    ScriptName = $ScriptName
    WhatIf = $WhatIf
    MgqibeloAdmin = $MgqibeloAdmin
    LwandileAdmin = $LwandileAdmin
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
        # Try to get the user by email address first
        $User = Get-User -Identity $EmailAddress -ErrorAction Stop
        return $User
    }
    catch {
        # If that fails, try to get the mailbox instead
        try {
            $Mailbox = Get-Mailbox -Identity $EmailAddress -ErrorAction Stop
            # Get the user object from the mailbox
            $User = Get-User -Identity $Mailbox.UserPrincipalName -ErrorAction Stop
            return $User
        }
        catch {
            Write-Log "Failed to resolve user identity for $EmailAddress : $($_.Exception.Message)" "ERROR"
            return $null
        }
    }
}

function Grant-DistributionGroupManagerRights {
    param(
        [object]$Group,
        [string]$UserEmail,
        [bool]$TestMode
    )
    
    try {
        $GroupName = $Group.DisplayName
        $GroupId = $Group.Identity
        
        # Check if user is already a manager
        $IsManager = $Group.ManagedBy -contains $UserEmail
        
        if ($IsManager) {
            Write-Log "$UserEmail is already a manager of $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Already Manager"
                Group = $GroupName
                GroupType = "DistributionGroup"
                AlreadyExists = $true
            }
        }
        
        if ($TestMode) {
            Write-Log "WHATIF: Would add $UserEmail as manager to $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Would Add Manager"
                Group = $GroupName
                GroupType = "DistributionGroup"
                WhatIf = $true
            }
        }
        
        # Add user as manager
        $CurrentManagers = @($Group.ManagedBy)
        $NewManagers = $CurrentManagers + $UserEmail
        
        Set-DistributionGroup -Identity $GroupId -ManagedBy $NewManagers -ErrorAction Stop
        
        # Enable moderation with authorized users
        $AuthorizedUsers = @($UserEmail, $LwandileAdmin)
        Set-DistributionGroup -Identity $GroupId -ModerationEnabled $true -ModeratedBy $AuthorizedUsers -SendModerationNotifications Never -ErrorAction Stop
        
        Write-Log "Successfully added $UserEmail as manager to $GroupName with moderation" "SUCCESS"
        return @{
            Success = $true
            Action = "Added Manager"
            Group = $GroupName
            GroupType = "DistributionGroup"
            ModerationEnabled = $true
        }
    }
    catch {
        Write-Log "Failed to add $UserEmail as manager to $GroupName : $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Action = "Failed to Add Manager"
            Group = $GroupName
            GroupType = "DistributionGroup"
            Error = $_.Exception.Message
        }
    }
}

function Grant-Office365GroupOwnerRights {
    param(
        [object]$Group,
        [string]$UserEmail,
        [bool]$TestMode
    )
    
    try {
        $GroupName = $Group.DisplayName
        $GroupId = $Group.Identity
        
        # Check if user is already a member
        $IsMember = $false
        try {
            $Members = Get-UnifiedGroupLinks -Identity $GroupId -LinkType Members -ErrorAction Stop
            $IsMember = $Members.PrimarySmtpAddress -contains $UserEmail
        }
        catch {
            Write-Log "Could not check membership for $GroupName : $($_.Exception.Message)" "WARNING"
        }
        
        # Check if user is already an owner
        $IsOwner = $false
        try {
            $Owners = Get-UnifiedGroupLinks -Identity $GroupId -LinkType Owners -ErrorAction Stop
            $IsOwner = $Owners.PrimarySmtpAddress -contains $UserEmail
        }
        catch {
            Write-Log "Could not check ownership for $GroupName : $($_.Exception.Message)" "WARNING"
        }
        
        if ($IsOwner -and $IsMember) {
            Write-Log "$UserEmail is already an owner and member of $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Already Owner/Member"
                Group = $GroupName
                GroupType = "Office365Group"
                AlreadyExists = $true
            }
        }
        
        if ($TestMode) {
            Write-Log "WHATIF: Would add $UserEmail as owner/member to $GroupName" "INFO"
            return @{
                Success = $true
                Action = "Would Add Owner/Member"
                Group = $GroupName
                GroupType = "Office365Group"
                WhatIf = $true
            }
        }
        
        # Add as member first, then owner
        if (-not $IsMember) {
            Add-UnifiedGroupLinks -Identity $GroupId -LinkType Members -Links $UserEmail -ErrorAction Stop
            Write-Log "Added $UserEmail as member to $GroupName" "SUCCESS"
        }
        
        if (-not $IsOwner) {
            Add-UnifiedGroupLinks -Identity $GroupId -LinkType Owners -Links $UserEmail -ErrorAction Stop
            Write-Log "Added $UserEmail as owner to $GroupName" "SUCCESS"
        }
        
        return @{
            Success = $true
            Action = "Added Owner/Member"
            Group = $GroupName
            GroupType = "Office365Group"
            MemberAdded = (-not $IsMember)
            OwnerAdded = (-not $IsOwner)
        }
    }
    catch {
        Write-Log "Failed to add $UserEmail as owner/member to $GroupName : $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Action = "Failed to Add Owner/Member"
            Group = $GroupName
            GroupType = "Office365Group"
            Error = $_.Exception.Message
        }
    }
}

# Main script
Write-Log "Starting COMPREHENSIVE ADMIN RIGHTS GRANT for $MgqibeloAdmin" "INFO"
Write-Log "Target Admin User: $MgqibeloAdmin" "INFO"
Write-Log "Reference Admin User: $LwandileAdmin" "INFO"
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

# Verify target user
$MgqibeloUser = Get-UserIdentity -EmailAddress $MgqibeloAdmin
if (-not $MgqibeloUser) {
    Write-Log "Cannot proceed - target user $MgqibeloAdmin not found" "ERROR"
    exit 1
}
Write-Log "Target admin user $MgqibeloAdmin verified: $($MgqibeloUser.DisplayName)" "SUCCESS"

# Verify reference user
$LwandileUser = Get-UserIdentity -EmailAddress $LwandileAdmin
if (-not $LwandileUser) {
    Write-Log "Cannot proceed - reference user $LwandileAdmin not found" "ERROR"
    exit 1
}
Write-Log "Reference admin user $LwandileAdmin verified: $($LwandileUser.DisplayName)" "SUCCESS"

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
Write-Log "Starting comprehensive admin rights grant for $MgqibeloAdmin..." "INFO"

# Process Distribution Groups
foreach ($Group in $DistributionGroups) {
    Write-Log "Processing distribution group: $($Group.DisplayName)" "INFO"
    $Result = Grant-DistributionGroupManagerRights -Group $Group -UserEmail $MgqibeloAdmin -TestMode $WhatIf
    $Results.DistributionGroups += $Result
}

# Process Office 365 Groups
foreach ($Group in $Office365Groups) {
    Write-Log "Processing Office 365 group: $($Group.DisplayName)" "INFO"
    $Result = Grant-Office365GroupOwnerRights -Group $Group -UserEmail $MgqibeloAdmin -TestMode $WhatIf
    $Results.Office365Groups += $Result
}

# Process Security Groups (similar to distribution groups)
foreach ($Group in $SecurityGroups) {
    Write-Log "Processing security group: $($Group.DisplayName)" "INFO"
    $Result = Grant-DistributionGroupManagerRights -Group $Group -UserEmail $MgqibeloAdmin -TestMode $WhatIf
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
}

# Export results
$Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $ResultsFile -Encoding UTF8
Write-Log "Results exported to: $ResultsFile" "INFO"

# Display summary
Write-Log "=== MGQIBELO COMPREHENSIVE ADMIN RIGHTS GRANT SUMMARY ===" "INFO"
Write-Log "Total groups processed: $($Results.Summary.TotalGroups)" "INFO"
Write-Log "Distribution groups: $($Results.Summary.DistributionGroups)" "INFO"
Write-Log "Office 365 groups: $($Results.Summary.Office365Groups)" "INFO"
Write-Log "Security groups: $($Results.Summary.SecurityGroups)" "INFO"
Write-Log "Successfully processed: $($Results.Summary.TotalSuccessful)" "SUCCESS"
Write-Log "Failed: $($Results.Summary.TotalFailed)" "INFO"

if ($WhatIf) {
    Write-Log "WhatIf mode - no changes were made" "INFO"
} else {
    Write-Log "Mgqibelo comprehensive admin rights grant completed" "SUCCESS"
}

Write-Log "Log file: $LogFile" "INFO"

# Sample verification
if (-not $WhatIf) {
    Write-Log "Performing sample verification for $MgqibeloAdmin..." "INFO"
    
    # Check a few distribution groups
    $SampleGroups = $DistributionGroups | Select-Object -First 3
    foreach ($Group in $SampleGroups) {
        try {
            $UpdatedGroup = Get-DistributionGroup -Identity $Group.Identity
            $IsManager = $UpdatedGroup.ManagedBy -contains $MgqibeloAdmin
            $HasModeration = $UpdatedGroup.ModerationEnabled
            Write-Log "  $($Group.DisplayName): Manager=$IsManager, Moderation=$HasModeration" "INFO"
        }
        catch {
            Write-Log "  $($Group.DisplayName): Verification failed - $($_.Exception.Message)" "WARNING"
        }
    }
    
    # Check a few Office 365 groups
    $SampleO365Groups = $Office365Groups | Select-Object -First 3
    foreach ($Group in $SampleO365Groups) {
        try {
            $Owners = Get-UnifiedGroupLinks -Identity $Group.Identity -LinkType Owners
            $Members = Get-UnifiedGroupLinks -Identity $Group.Identity -LinkType Members
            $IsOwner = $Owners.PrimarySmtpAddress -contains $MgqibeloAdmin
            $IsMember = $Members.PrimarySmtpAddress -contains $MgqibeloAdmin
            Write-Log "  $($Group.DisplayName): Owner=$IsOwner, Member=$IsMember" "INFO"
        }
        catch {
            Write-Log "  $($Group.DisplayName): Verification failed - $($_.Exception.Message)" "WARNING"
        }
    }
    
    Write-Log "SUCCESS: $MgqibeloAdmin now has comprehensive admin rights matching $LwandileAdmin!" "SUCCESS"
}

Write-Host "`n=== SCRIPT COMPLETED ===" -ForegroundColor Green
Write-Host "Log file: $LogFile" -ForegroundColor Cyan
Write-Host "Results file: $ResultsFile" -ForegroundColor Cyan
