#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Comprehensive fix script to add lwandile.gasela@ibridge.co.za as member/owner to all groups and apply policies
.DESCRIPTION
    This script fixes the issues found in the previous run:
    1. Fixes distribution groups with naming conflicts by using full email addresses
    2. Adds admin user as member first, then owner for Office 365 groups
    3. Applies moderation policies to distribution groups
.PARAMETER WhatIf
    Shows what would be done without making actual changes
.PARAMETER AdminUser
    The user to grant admin rights to (default: lwandile.gasela@ibridge.co.za)
.PARAMETER Force
    Force changes without confirmation prompts
.EXAMPLE
    .\Fix-GlobalAdminRights.ps1 -WhatIf
    Test what changes would be made
.EXAMPLE
    .\Fix-GlobalAdminRights.ps1 -Force
    Apply all changes without prompts
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$AdminUser = "lwandile.gasela@ibridge.co.za",
    [switch]$Force
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
$LogFile = Join-Path $LogPath "FixAdminRights-$Timestamp.log"

# Ensure log directory exists
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
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

function Fix-DistributionGroupOwnership {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$GroupIdentity,
        [string]$AdminUser
    )
    
    try {
        Write-Log "Fixing distribution group: $GroupIdentity" "INFO"
        
        # Get current group settings
        $Group = Get-DistributionGroup -Identity $GroupIdentity -ErrorAction Stop
        
        # Get current managers - use full email addresses to avoid conflicts
        $CurrentManagers = @()
        if ($Group.ManagedBy) {
            foreach ($Manager in $Group.ManagedBy) {
                try {
                    $ManagerDetails = Get-Recipient -Identity $Manager -ErrorAction SilentlyContinue
                    if ($ManagerDetails) {
                        $CurrentManagers += $ManagerDetails.PrimarySmtpAddress.ToString()
                    }
                }
                catch {
                    Write-Log "Could not resolve manager $Manager" "WARNING"
                }
            }
        }
        
        # Check if admin user is already a manager
        if ($CurrentManagers -notcontains $AdminUser) {
            if ($PSCmdlet.ShouldProcess($GroupIdentity, "Add $AdminUser as manager")) {
                $UpdatedManagers = @($CurrentManagers) + $AdminUser
                Set-DistributionGroup -Identity $GroupIdentity -ManagedBy $UpdatedManagers -BypassSecurityGroupManagerCheck -ErrorAction Stop
                Write-Log "Successfully added $AdminUser as manager to $GroupIdentity" "SUCCESS"
            }
        } else {
            Write-Log "$AdminUser is already a manager of $GroupIdentity" "INFO"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to fix distribution group $GroupIdentity`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-Office365GroupOwnership {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$GroupIdentity,
        [string]$AdminUser
    )
    
    try {
        Write-Log "Fixing Office 365 group: $GroupIdentity" "INFO"
        
        # First, check if user is already a member
        $Members = Get-UnifiedGroupLinks -Identity $GroupIdentity -LinkType Members -ErrorAction Stop
        $IsMember = $Members.PrimarySmtpAddress -contains $AdminUser
        
        if (-not $IsMember) {
            if ($PSCmdlet.ShouldProcess($GroupIdentity, "Add $AdminUser as member")) {
                Add-UnifiedGroupLinks -Identity $GroupIdentity -LinkType Members -Links $AdminUser -ErrorAction Stop
                Write-Log "Added $AdminUser as member to $GroupIdentity" "SUCCESS"
            }
        } else {
            Write-Log "$AdminUser is already a member of $GroupIdentity" "INFO"
        }
        
        # Now check if user is already an owner
        $Owners = Get-UnifiedGroupLinks -Identity $GroupIdentity -LinkType Owners -ErrorAction Stop
        $IsOwner = $Owners.PrimarySmtpAddress -contains $AdminUser
        
        if (-not $IsOwner) {
            if ($PSCmdlet.ShouldProcess($GroupIdentity, "Add $AdminUser as owner")) {
                Add-UnifiedGroupLinks -Identity $GroupIdentity -LinkType Owners -Links $AdminUser -ErrorAction Stop
                Write-Log "Added $AdminUser as owner to $GroupIdentity" "SUCCESS"
            }
        } else {
            Write-Log "$AdminUser is already an owner of $GroupIdentity" "INFO"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to fix Office 365 group $GroupIdentity`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Apply-DistributionGroupModeration {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$GroupIdentity,
        [array]$AuthorizedUsers
    )
    
    try {
        # Get current group settings
        $Group = Get-DistributionGroup -Identity $GroupIdentity -ErrorAction Stop
        
        # Skip if moderation is already enabled with the correct moderators
        if ($Group.ModerationEnabled) {
            Write-Log "Moderation already enabled for $GroupIdentity, checking moderators..." "INFO"
        }
        
        # Filter authorized users to only include valid email addresses
        $ValidModerators = @()
        foreach ($User in $AuthorizedUsers) {
            try {
                $UserCheck = Get-Recipient -Identity $User -ErrorAction SilentlyContinue
                if ($UserCheck -and $UserCheck.RecipientType -in @("UserMailbox", "MailUser")) {
                    $ValidModerators += $User
                }
                else {
                    Write-Log "Skipping $User as moderator (not a valid user mailbox)" "WARNING"
                }
            }
            catch {
                Write-Log "Could not validate user $User for moderation" "WARNING"
            }
        }
        
        if ($ValidModerators.Count -gt 0) {
            if ($PSCmdlet.ShouldProcess($GroupIdentity, "Enable moderation with authorized users")) {
                Set-DistributionGroup -Identity $GroupIdentity `
                    -ModerationEnabled:$true `
                    -ModeratedBy $ValidModerators `
                    -SendModerationNotifications Never `
                    -BypassSecurityGroupManagerCheck `
                    -ErrorAction Stop
                
                Write-Log "Applied moderation to $GroupIdentity with $($ValidModerators.Count) moderators" "SUCCESS"
            }
        } else {
            Write-Log "No valid moderators found for $GroupIdentity" "WARNING"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to apply moderation to $GroupIdentity`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
Write-Log "Starting COMPREHENSIVE FIX for admin rights and policy application" "INFO"
Write-Log "Admin User: $AdminUser" "INFO"
Write-Log "WhatIf Mode: $($PSCmdlet.ShouldProcess('test', 'test') -eq $false)" "INFO"

# Check Exchange Online connection
if (-not (Test-ExchangeConnection)) {
    Write-Log "Not connected to Exchange Online. Attempting to connect..." "WARNING"
    try {
        Connect-ExchangeOnline -ShowProgress $true -ErrorAction Stop
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

# Get all groups in the tenant
Write-Log "Discovering all groups in the tenant..." "INFO"

$AllGroups = @()
$Stats = @{
    DistributionGroups = 0
    UnifiedGroups = 0
    SecurityGroups = 0
    ProcessedSuccessfully = 0
    Failed = 0
}

# Get Distribution Groups
try {
    $DistributionGroups = Get-DistributionGroup -ResultSize Unlimited
    foreach ($Group in $DistributionGroups) {
        $GroupType = if ($Group.RecipientType -eq "MailUniversalSecurityGroup") { "SecurityGroup" } else { "DistributionGroup" }
        $AllGroups += [PSCustomObject]@{
            Identity = $Group.Identity
            DisplayName = $Group.DisplayName
            PrimarySmtpAddress = $Group.PrimarySmtpAddress
            GroupType = $GroupType
        }
        if ($GroupType -eq "SecurityGroup") {
            $Stats.SecurityGroups++
        } else {
            $Stats.DistributionGroups++
        }
    }
    Write-Log "Found $($Stats.DistributionGroups) distribution groups and $($Stats.SecurityGroups) security groups" "INFO"
}
catch {
    Write-Log "Failed to retrieve distribution groups: $($_.Exception.Message)" "ERROR"
}

# Get Office 365 Groups
try {
    $UnifiedGroups = Get-UnifiedGroup -ResultSize Unlimited -ErrorAction SilentlyContinue
    if ($UnifiedGroups) {
        foreach ($Group in $UnifiedGroups) {
            $AllGroups += [PSCustomObject]@{
                Identity = $Group.Identity
                DisplayName = $Group.DisplayName
                PrimarySmtpAddress = $Group.PrimarySmtpAddress
                GroupType = "UnifiedGroup"
            }
            $Stats.UnifiedGroups++
        }
        Write-Log "Found $($Stats.UnifiedGroups) Office 365 groups" "INFO"
    }
}
catch {
    Write-Log "Office 365 groups not available or accessible: $($_.Exception.Message)" "WARNING"
}

Write-Log "Total groups found: $($AllGroups.Count)" "INFO"

# Process each group
if ($AllGroups.Count -eq 0) {
    Write-Log "No groups found to process" "WARNING"
    exit 1
}

if (-not $Force) {
    Write-Host ""
    Write-Host "COMPREHENSIVE FIX - Groups to be processed:" -ForegroundColor Yellow
    Write-Host "Distribution Groups: $($Stats.DistributionGroups)" -ForegroundColor Cyan
    Write-Host "Office 365 Groups: $($Stats.UnifiedGroups)" -ForegroundColor Cyan
    Write-Host "Security Groups: $($Stats.SecurityGroups)" -ForegroundColor Cyan
    Write-Host ""
    $Confirmation = Read-Host "Continue with comprehensive fix? (y/N)"
    if ($Confirmation -ne 'y' -and $Confirmation -ne 'Y') {
        Write-Log "Operation cancelled by user" "INFO"
        exit 0
    }
}

Write-Log "Starting comprehensive group fix and policy application..." "INFO"

foreach ($Group in $AllGroups) {
    Write-Log "Processing group: $($Group.DisplayName) ($($Group.GroupType))" "INFO"
    
    $Success = $false
    
    if ($Group.GroupType -eq "DistributionGroup" -or $Group.GroupType -eq "SecurityGroup") {
        # Fix distribution/security group ownership
        $OwnershipSuccess = Fix-DistributionGroupOwnership -GroupIdentity $Group.Identity -AdminUser $AdminUser
        
        # Apply moderation if ownership was successful
        if ($OwnershipSuccess) {
            $ModerationSuccess = Apply-DistributionGroupModeration -GroupIdentity $Group.Identity -AuthorizedUsers $Config.AuthorizedUsers
            $Success = $ModerationSuccess
        }
    }
    elseif ($Group.GroupType -eq "UnifiedGroup") {
        # Fix Office 365 group membership and ownership
        $Success = Fix-Office365GroupOwnership -GroupIdentity $Group.Identity -AdminUser $AdminUser
    }
    
    if ($Success) {
        $Stats.ProcessedSuccessfully++
    } else {
        $Stats.Failed++
    }
}

# Summary
Write-Log "=== COMPREHENSIVE FIX SUMMARY ===" "INFO"
Write-Log "Total groups processed: $($AllGroups.Count)" "INFO"
Write-Log "Distribution groups: $($Stats.DistributionGroups)" "INFO"
Write-Log "Office 365 groups: $($Stats.UnifiedGroups)" "INFO"
Write-Log "Security groups: $($Stats.SecurityGroups)" "INFO"
Write-Log "Successfully processed: $($Stats.ProcessedSuccessfully)" "SUCCESS"
Write-Log "Failed: $($Stats.Failed)" $(if ($Stats.Failed -gt 0) { "ERROR" } else { "INFO" })

# Export results
$Results = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    AdminUser = $AdminUser
    WhatIfMode = $PSCmdlet.ShouldProcess('test', 'test') -eq $false
    TotalGroups = $AllGroups.Count
    Statistics = $Stats
    ProcessedGroups = $AllGroups
}

$ResultsPath = Join-Path $LogPath "FixAdminRights-Results-$Timestamp.json"
$Results | ConvertTo-Json -Depth 5 | Out-File -FilePath $ResultsPath -Encoding UTF8
Write-Log "Results exported to: $ResultsPath" "INFO"

Write-Log "Comprehensive fix completed" "SUCCESS"
Write-Log "Log file: $LogFile" "INFO"

# Final verification
Write-Log "Performing final verification..." "INFO"
try {
    $VerificationResults = @()
    
    # Check a few distribution groups
    $DistToCheck = $AllGroups | Where-Object { $_.GroupType -eq "DistributionGroup" } | Select-Object -First 3
    foreach ($Group in $DistToCheck) {
        $GroupInfo = Get-DistributionGroup -Identity $Group.Identity -ErrorAction SilentlyContinue
        if ($GroupInfo) {
            $IsManager = $GroupInfo.ManagedBy -contains $AdminUser
            $VerificationResults += [PSCustomObject]@{
                GroupName = $Group.DisplayName
                GroupType = "Distribution"
                IsManager = $IsManager
                ModerationEnabled = $GroupInfo.ModerationEnabled
            }
        }
    }
    
    # Check a few Office 365 groups
    $O365ToCheck = $AllGroups | Where-Object { $_.GroupType -eq "UnifiedGroup" } | Select-Object -First 3
    foreach ($Group in $O365ToCheck) {
        try {
            $Owners = Get-UnifiedGroupLinks -Identity $Group.Identity -LinkType Owners -ErrorAction SilentlyContinue
            $Members = Get-UnifiedGroupLinks -Identity $Group.Identity -LinkType Members -ErrorAction SilentlyContinue
            $IsOwner = $Owners.PrimarySmtpAddress -contains $AdminUser
            $IsMember = $Members.PrimarySmtpAddress -contains $AdminUser
            
            $VerificationResults += [PSCustomObject]@{
                GroupName = $Group.DisplayName
                GroupType = "Office365"
                IsOwner = $IsOwner
                IsMember = $IsMember
            }
        }
        catch {
            Write-Log "Could not verify $($Group.DisplayName)" "WARNING"
        }
    }
    
    Write-Log "Sample verification results:" "INFO"
    $VerificationResults | ForEach-Object {
        if ($_.GroupType -eq "Distribution") {
            Write-Log "  $($_.GroupName): Manager=$($_.IsManager), Moderation=$($_.ModerationEnabled)" "INFO"
        } else {
            Write-Log "  $($_.GroupName): Owner=$($_.IsOwner), Member=$($_.IsMember)" "INFO"
        }
    }
}
catch {
    Write-Log "Verification check failed: $($_.Exception.Message)" "WARNING"
}

Write-Log "Comprehensive fix script execution completed." "SUCCESS"
