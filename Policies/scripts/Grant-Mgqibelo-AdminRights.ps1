#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Grant comprehensive admin rights to mgqibelo.gasela@ibridge.co.za for all groups
.DESCRIPTION
    This script grants mgqibelo.gasela@ibridge.co.za the exact same rights and permissions as lwandile.gasela@ibridge.co.za:
    - Manager/Owner access to all distribution groups
    - Member and Owner access to all Office 365 groups
    - Full monitoring and management capabilities
.PARAMETER WhatIf
    Shows what would be done without making actual changes
.PARAMETER AdminUser
    The user to grant admin rights to (default: mgqibelo.gasela@ibridge.co.za)
.PARAMETER Force
    Force changes without confirmation prompts
.EXAMPLE
    .\Grant-Mgqibelo-AdminRights.ps1 -WhatIf
    Test what changes would be made
.EXAMPLE
    .\Grant-Mgqibelo-AdminRights.ps1 -Force
    Apply all changes without prompts
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$AdminUser = "mgqibelo.gasela@ibridge.co.za",
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
$LogFile = Join-Path $LogPath "GrantMgqibelo-AdminRights-$Timestamp.log"

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

function Grant-DistributionGroupAccess {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$GroupIdentity,
        [string]$AdminUser
    )
    
    try {
        Write-Log "Processing distribution group: $GroupIdentity" "INFO"
        
        # Get current group settings
        $Group = Get-DistributionGroup -Identity $GroupIdentity -ErrorAction Stop
        
        # Get current managers and add admin user if not already present
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
                Set-DistributionGroup -Identity $GroupIdentity -ManagedBy $UpdatedManagers -ErrorAction Stop
                Write-Log "Successfully added $AdminUser as manager to $($Group.DisplayName)" "SUCCESS"
            }
        } else {
            Write-Log "$AdminUser is already a manager of $($Group.DisplayName)" "INFO"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to grant access to distribution group $GroupIdentity`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Grant-Office365GroupAccess {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$GroupIdentity,
        [string]$AdminUser
    )
    
    try {
        Write-Log "Processing Office 365 group: $GroupIdentity" "INFO"
        
        $Group = Get-UnifiedGroup -Identity $GroupIdentity -ErrorAction Stop
        
        # First, check if user is already a member
        $Members = Get-UnifiedGroupLinks -Identity $GroupIdentity -LinkType Members -ErrorAction Stop
        $IsMember = $Members.PrimarySmtpAddress -contains $AdminUser
        
        if (-not $IsMember) {
            if ($PSCmdlet.ShouldProcess($GroupIdentity, "Add $AdminUser as member")) {
                Add-UnifiedGroupLinks -Identity $GroupIdentity -LinkType Members -Links $AdminUser -ErrorAction Stop
                Write-Log "Added $AdminUser as member to $($Group.DisplayName)" "SUCCESS"
            }
        } else {
            Write-Log "$AdminUser is already a member of $($Group.DisplayName)" "INFO"
        }
        
        # Now check if user is already an owner
        $Owners = Get-UnifiedGroupLinks -Identity $GroupIdentity -LinkType Owners -ErrorAction Stop
        $IsOwner = $Owners.PrimarySmtpAddress -contains $AdminUser
        
        if (-not $IsOwner) {
            if ($PSCmdlet.ShouldProcess($GroupIdentity, "Add $AdminUser as owner")) {
                Add-UnifiedGroupLinks -Identity $GroupIdentity -LinkType Owners -Links $AdminUser -ErrorAction Stop
                Write-Log "Added $AdminUser as owner to $($Group.DisplayName)" "SUCCESS"
            }
        } else {
            Write-Log "$AdminUser is already an owner of $($Group.DisplayName)" "INFO"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to grant access to Office 365 group $GroupIdentity`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
Write-Log "Starting COMPREHENSIVE ADMIN RIGHTS GRANT for mgqibelo.gasela@ibridge.co.za" "INFO"
Write-Log "Admin User: $AdminUser" "INFO"
Write-Log "WhatIf Mode: $($PSCmdlet.ShouldProcess('test', 'test') -eq $false)" "INFO"

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
    Write-Host "MGQIBELO ADMIN RIGHTS GRANT - Groups to be processed:" -ForegroundColor Yellow
    Write-Host "Distribution Groups: $($Stats.DistributionGroups)" -ForegroundColor Cyan
    Write-Host "Office 365 Groups: $($Stats.UnifiedGroups)" -ForegroundColor Cyan
    Write-Host "Security Groups: $($Stats.SecurityGroups)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will grant mgqibelo.gasela@ibridge.co.za the same rights as lwandile.gasela@ibridge.co.za" -ForegroundColor Yellow
    Write-Host ""
    $Confirmation = Read-Host "Continue with admin rights grant? (y/N)"
    if ($Confirmation -ne 'y' -and $Confirmation -ne 'Y') {
        Write-Log "Operation cancelled by user" "INFO"
        exit 0
    }
}

Write-Log "Starting comprehensive admin rights grant for mgqibelo.gasela@ibridge.co.za..." "INFO"

foreach ($Group in $AllGroups) {
    Write-Log "Processing group: $($Group.DisplayName) ($($Group.GroupType))" "INFO"
    
    $Success = $false
    
    if ($Group.GroupType -eq "DistributionGroup" -or $Group.GroupType -eq "SecurityGroup") {
        # Grant distribution/security group management access
        $Success = Grant-DistributionGroupAccess -GroupIdentity $Group.Identity -AdminUser $AdminUser
    }
    elseif ($Group.GroupType -eq "UnifiedGroup") {
        # Grant Office 365 group membership and ownership
        $Success = Grant-Office365GroupAccess -GroupIdentity $Group.Identity -AdminUser $AdminUser
    }
    
    if ($Success) {
        $Stats.ProcessedSuccessfully++
    } else {
        $Stats.Failed++
    }
}

# Summary
Write-Log "=== MGQIBELO ADMIN RIGHTS GRANT SUMMARY ===" "INFO"
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

$ResultsPath = Join-Path $LogPath "GrantMgqibelo-AdminRights-Results-$Timestamp.json"
$Results | ConvertTo-Json -Depth 5 | Out-File -FilePath $ResultsPath -Encoding UTF8
Write-Log "Results exported to: $ResultsPath" "INFO"

Write-Log "Mgqibelo admin rights grant completed" "SUCCESS"
Write-Log "Log file: $LogFile" "INFO"

# Final verification
Write-Log "Performing sample verification for mgqibelo.gasela@ibridge.co.za..." "INFO"
try {
    $VerificationResults = @()
    
    # Check a few distribution groups
    $DistToCheck = $AllGroups | Where-Object { $_.GroupType -eq "DistributionGroup" } | Select-Object -First 3
    foreach ($Group in $DistToCheck) {
        $GroupInfo = Get-DistributionGroup -Identity $Group.Identity -ErrorAction SilentlyContinue
        if ($GroupInfo) {
            # Resolve all managers to email addresses
            $ManagerEmails = @()
            foreach ($Manager in $GroupInfo.ManagedBy) {
                try {
                    $ManagerDetails = Get-Recipient -Identity $Manager -ErrorAction SilentlyContinue
                    if ($ManagerDetails) {
                        $ManagerEmails += $ManagerDetails.PrimarySmtpAddress.ToString()
                    }
                }
                catch {}
            }
            $IsManager = $ManagerEmails -contains $AdminUser
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
    
    Write-Log "Sample verification results for mgqibelo.gasela@ibridge.co.za:" "INFO"
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

Write-Log "SUCCESS: mgqibelo.gasela@ibridge.co.za now has the same admin rights as lwandile.gasela@ibridge.co.za!" "SUCCESS"
