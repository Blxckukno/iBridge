#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Grants lwandile.gasela@ibridge.co.za comprehensive admin rights to all groups and applies email policies
.DESCRIPTION
    This script systematically grants manager/owner rights to all distribution groups, security groups,
    and Office 365 groups in the tenant to enable policy monitoring and management.
.PARAMETER WhatIf
    Shows what would be done without making actual changes
.PARAMETER AdminUser
    The user to grant admin rights to (default: lwandile.gasela@ibridge.co.za)
.PARAMETER Force
    Force changes without confirmation prompts
.EXAMPLE
    .\Grant-Full-AdminRights.ps1 -WhatIf
    Test what changes would be made
.EXAMPLE
    .\Grant-Full-AdminRights.ps1 -Force
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
$LogFile = Join-Path $LogPath "AdminRights-$Timestamp.log"

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

function Grant-GroupAdminRights {
    param(
        [string]$GroupIdentity,
        [string]$AdminUser,
        [string]$GroupType
    )
    
    try {
        Write-Log "Processing $GroupType group: $GroupIdentity" "INFO"
        
        if ($GroupType -eq "DistributionGroup") {
            # Check if user is already a manager
            $Group = Get-DistributionGroup -Identity $GroupIdentity -ErrorAction Stop
            $CurrentManagers = $Group.ManagedBy
            
            if ($CurrentManagers -notcontains $AdminUser) {
                if ($PSCmdlet.ShouldProcess($GroupIdentity, "Add $AdminUser as manager")) {
                    $UpdatedManagers = @($CurrentManagers) + $AdminUser
                    Set-DistributionGroup -Identity $GroupIdentity -ManagedBy $UpdatedManagers -ErrorAction Stop
                    Write-Log "Added $AdminUser as manager to $GroupIdentity" "SUCCESS"
                }
            } else {
                Write-Log "$AdminUser is already a manager of $GroupIdentity" "INFO"
            }
        }
        elseif ($GroupType -eq "UnifiedGroup") {
            # Check if user is already an owner
            $Owners = Get-UnifiedGroupLinks -Identity $GroupIdentity -LinkType Owners -ErrorAction Stop
            
            if ($Owners.PrimarySmtpAddress -notcontains $AdminUser) {
                if ($PSCmdlet.ShouldProcess($GroupIdentity, "Add $AdminUser as owner")) {
                    Add-UnifiedGroupLinks -Identity $GroupIdentity -LinkType Owners -Links $AdminUser -ErrorAction Stop
                    Write-Log "Added $AdminUser as owner to $GroupIdentity" "SUCCESS"
                }
            } else {
                Write-Log "$AdminUser is already an owner of $GroupIdentity" "INFO"
            }
        }
        elseif ($GroupType -eq "SecurityGroup") {
            # For security groups, we need to use Azure AD commands if available
            Write-Log "Security group $GroupIdentity - Admin rights handled via Azure AD" "INFO"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to grant admin rights to $GroupIdentity`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Apply-GroupModeration {
    param(
        [string]$GroupIdentity,
        [string]$GroupType,
        [array]$AuthorizedUsers
    )
    
    try {
        if ($GroupType -eq "DistributionGroup") {
            # Get current group settings
            $Group = Get-DistributionGroup -Identity $GroupIdentity -ErrorAction Stop
            
            # Filter authorized users to only include valid email addresses (exclude Office 365 groups)
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
Write-Log "Starting comprehensive admin rights and policy application" "INFO"
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
        $AllGroups += [PSCustomObject]@{
            Identity = $Group.Identity
            DisplayName = $Group.DisplayName
            PrimarySmtpAddress = $Group.PrimarySmtpAddress
            GroupType = "DistributionGroup"
        }
        $Stats.DistributionGroups++
    }
    Write-Log "Found $($Stats.DistributionGroups) distribution groups" "INFO"
}
catch {
    Write-Log "Failed to retrieve distribution groups: $($_.Exception.Message)" "ERROR"
}

# Get Office 365 Groups (Unified Groups)
try {
    $UnifiedGroups = Get-UnifiedGroup -ResultSize Unlimited
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
catch {
    Write-Log "Failed to retrieve Office 365 groups: $($_.Exception.Message)" "ERROR"
}

# Get Mail-enabled Security Groups
try {
    $SecurityGroups = Get-DistributionGroup -ResultSize Unlimited | Where-Object { $_.RecipientType -eq "MailUniversalSecurityGroup" }
    foreach ($Group in $SecurityGroups) {
        $AllGroups += [PSCustomObject]@{
            Identity = $Group.Identity
            DisplayName = $Group.DisplayName
            PrimarySmtpAddress = $Group.PrimarySmtpAddress
            GroupType = "SecurityGroup"
        }
        $Stats.SecurityGroups++
    }
    Write-Log "Found $($Stats.SecurityGroups) mail-enabled security groups" "INFO"
}
catch {
    Write-Log "Failed to retrieve security groups: $($_.Exception.Message)" "ERROR"
}

Write-Log "Total groups found: $($AllGroups.Count)" "INFO"

# Process each group
if ($AllGroups.Count -eq 0) {
    Write-Log "No groups found to process" "WARNING"
    exit 1
}

if (-not $Force) {
    $Confirmation = Read-Host "Found $($AllGroups.Count) groups. Continue with admin rights assignment? (y/N)"
    if ($Confirmation -ne 'y' -and $Confirmation -ne 'Y') {
        Write-Log "Operation cancelled by user" "INFO"
        exit 0
    }
}

foreach ($Group in $AllGroups) {
    Write-Log "Processing group: $($Group.DisplayName) ($($Group.GroupType))" "INFO"
    
    # Grant admin rights
    $AdminSuccess = Grant-GroupAdminRights -GroupIdentity $Group.Identity -AdminUser $AdminUser -GroupType $Group.GroupType
    
    # Apply moderation (only for distribution groups)
    if ($AdminSuccess -and $Group.GroupType -eq "DistributionGroup") {
        $ModerationSuccess = Apply-GroupModeration -GroupIdentity $Group.Identity -GroupType $Group.GroupType -AuthorizedUsers $Config.AuthorizedUsers
        if ($ModerationSuccess) {
            $Stats.ProcessedSuccessfully++
        } else {
            $Stats.Failed++
        }
    } elseif ($AdminSuccess) {
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

$ResultsPath = Join-Path $LogPath "AdminRights-Results-$Timestamp.json"
$Results | ConvertTo-Json -Depth 5 | Out-File -FilePath $ResultsPath -Encoding UTF8
Write-Log "Results exported to: $ResultsPath" "INFO"

Write-Log "Admin rights assignment and policy application completed" "SUCCESS"
Write-Log "Log file: $LogFile" "INFO"
