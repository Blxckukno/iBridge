#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Grants lwandile.gasela@ibridge.co.za comprehensive admin rights to all groups using Global Admin privileges
.DESCRIPTION
    This script must be run by a Global Administrator to grant manager/owner rights to all distribution groups,
    security groups, and Office 365 groups in the tenant to enable policy monitoring and management.
.PARAMETER WhatIf
    Shows what would be done without making actual changes
.PARAMETER AdminUser
    The user to grant admin rights to (default: lwandile.gasela@ibridge.co.za)
.PARAMETER Force
    Force changes without confirmation prompts
.EXAMPLE
    .\Grant-Global-AdminRights.ps1 -WhatIf
    Test what changes would be made
.EXAMPLE
    .\Grant-Global-AdminRights.ps1 -Force
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
$LogFile = Join-Path $LogPath "GlobalAdminRights-$Timestamp.log"

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

function Test-GlobalAdminRights {
    try {
        # Test if we can view organization config and manage recipients
        $null = Get-OrganizationConfig -ErrorAction Stop
        $null = Get-RoleGroupMember -Identity "Organization Management" -ErrorAction Stop
        return $true
    }
    catch {
        Write-Log "Error checking admin rights: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Grant-GroupOwnership {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$GroupIdentity,
        [string]$AdminUser,
        [string]$GroupType
    )
    
    try {
        Write-Log "Granting ownership of $GroupType group: $GroupIdentity to $AdminUser" "INFO"
        
        if ($GroupType -eq "DistributionGroup") {
            # For distribution groups, we need to add the user as a manager
            $Group = Get-DistributionGroup -Identity $GroupIdentity -ErrorAction Stop
            $CurrentManagers = @()
            
            if ($Group.ManagedBy) {
                $CurrentManagers = $Group.ManagedBy
            }
            
            # Check if user is already a manager
            if ($CurrentManagers -notcontains $AdminUser) {
                if ($PSCmdlet.ShouldProcess($GroupIdentity, "Add $AdminUser as manager")) {
                    $UpdatedManagers = @($CurrentManagers) + $AdminUser
                    Set-DistributionGroup -Identity $GroupIdentity -ManagedBy $UpdatedManagers -BypassSecurityGroupManagerCheck -ErrorAction Stop
                    Write-Log "Successfully added $AdminUser as manager to $GroupIdentity" "SUCCESS"
                }
            } else {
                Write-Log "$AdminUser is already a manager of $GroupIdentity" "INFO"
            }
        }
        elseif ($GroupType -eq "UnifiedGroup") {
            # For Office 365 groups, add as owner
            $Owners = Get-UnifiedGroupLinks -Identity $GroupIdentity -LinkType Owners -ErrorAction Stop
            
            if ($Owners.PrimarySmtpAddress -notcontains $AdminUser) {
                if ($PSCmdlet.ShouldProcess($GroupIdentity, "Add $AdminUser as owner")) {
                    Add-UnifiedGroupLinks -Identity $GroupIdentity -LinkType Owners -Links $AdminUser -ErrorAction Stop
                    Write-Log "Successfully added $AdminUser as owner to $GroupIdentity" "SUCCESS"
                }
            } else {
                Write-Log "$AdminUser is already an owner of $GroupIdentity" "INFO"
            }
        }
        elseif ($GroupType -eq "SecurityGroup") {
            # For mail-enabled security groups, add as manager
            $Group = Get-DistributionGroup -Identity $GroupIdentity -ErrorAction Stop
            $CurrentManagers = @()
            
            if ($Group.ManagedBy) {
                $CurrentManagers = $Group.ManagedBy
            }
            
            if ($CurrentManagers -notcontains $AdminUser) {
                if ($PSCmdlet.ShouldProcess($GroupIdentity, "Add $AdminUser as manager")) {
                    $UpdatedManagers = @($CurrentManagers) + $AdminUser
                    Set-DistributionGroup -Identity $GroupIdentity -ManagedBy $UpdatedManagers -BypassSecurityGroupManagerCheck -ErrorAction Stop
                    Write-Log "Successfully added $AdminUser as manager to security group $GroupIdentity" "SUCCESS"
                }
            } else {
                Write-Log "$AdminUser is already a manager of security group $GroupIdentity" "INFO"
            }
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to grant ownership of $GroupIdentity to $AdminUser`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Set-GroupModeration {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$GroupIdentity,
        [string]$GroupType,
        [array]$AuthorizedUsers
    )
    
    try {
        if ($GroupType -eq "DistributionGroup" -or $GroupType -eq "SecurityGroup") {
            # Get current group settings
            $null = Get-DistributionGroup -Identity $GroupIdentity -ErrorAction Stop
            
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
        }
        elseif ($GroupType -eq "UnifiedGroup") {
            Write-Log "Office 365 group $GroupIdentity - Moderation handled via different mechanism" "INFO"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to apply moderation to $GroupIdentity`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
Write-Log "Starting GLOBAL ADMIN comprehensive rights and policy application" "INFO"
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

# Check Global Admin rights
Write-Log "Checking Global Administrator privileges..." "INFO"
if (-not (Test-GlobalAdminRights)) {
    Write-Log "This script requires Global Administrator privileges to modify group ownership" "ERROR"
    Write-Log "Please run this script as a Global Administrator" "ERROR"
    exit 1
}
Write-Log "Global Administrator privileges confirmed" "SUCCESS"

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

# Get Office 365 Groups (if available)
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
    Write-Host "GROUPS TO BE MODIFIED:" -ForegroundColor Yellow
    $AllGroups | ForEach-Object { Write-Host "  - $($_.DisplayName) ($($_.GroupType))" }
    Write-Host ""
    $Confirmation = Read-Host "Found $($AllGroups.Count) groups. Continue with admin rights assignment? (y/N)"
    if ($Confirmation -ne 'y' -and $Confirmation -ne 'Y') {
        Write-Log "Operation cancelled by user" "INFO"
        exit 0
    }
}

Write-Log "Starting group ownership assignment and policy application..." "INFO"

foreach ($Group in $AllGroups) {
    Write-Log "Processing group: $($Group.DisplayName) ($($Group.GroupType))" "INFO"
    
    # Grant ownership
    $OwnershipSuccess = Grant-GroupOwnership -GroupIdentity $Group.Identity -AdminUser $AdminUser -GroupType $Group.GroupType
    
    # Apply moderation (only for distribution groups and security groups)
    if ($OwnershipSuccess -and ($Group.GroupType -eq "DistributionGroup" -or $Group.GroupType -eq "SecurityGroup")) {
        $ModerationSuccess = Set-GroupModeration -GroupIdentity $Group.Identity -GroupType $Group.GroupType -AuthorizedUsers $Config.AuthorizedUsers
        if ($ModerationSuccess) {
            $Stats.ProcessedSuccessfully++
        } else {
            $Stats.Failed++
        }
    } elseif ($OwnershipSuccess) {
        $Stats.ProcessedSuccessfully++
    } else {
        $Stats.Failed++
    }
}

# Summary
Write-Log "=== OPERATION SUMMARY ===" "INFO"
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

$ResultsPath = Join-Path $LogPath "GlobalAdminRights-Results-$Timestamp.json"
$Results | ConvertTo-Json -Depth 5 | Out-File -FilePath $ResultsPath -Encoding UTF8
Write-Log "Results exported to: $ResultsPath" "INFO"

Write-Log "Global Admin rights assignment and policy application completed" "SUCCESS"
Write-Log "Log file: $LogFile" "INFO"

# Final verification
Write-Log "Performing final verification..." "INFO"
try {
    $VerificationResults = @()
    foreach ($Group in $AllGroups | Select-Object -First 3) {
        $GroupInfo = Get-DistributionGroup -Identity $Group.Identity -ErrorAction SilentlyContinue
        if ($GroupInfo) {
            $IsManager = $GroupInfo.ManagedBy -contains $AdminUser
            $VerificationResults += [PSCustomObject]@{
                GroupName = $Group.DisplayName
                IsManager = $IsManager
                ModerationEnabled = $GroupInfo.ModerationEnabled
            }
        }
    }
    
    Write-Log "Sample verification results:" "INFO"
    $VerificationResults | ForEach-Object {
        Write-Log "  $($_.GroupName): Manager=$($_.IsManager), Moderation=$($_.ModerationEnabled)" "INFO"
    }
}
catch {
    Write-Log "Verification check failed: $($_.Exception.Message)" "WARNING"
}

Write-Log "Script execution completed. Check the log file for detailed results." "SUCCESS"
