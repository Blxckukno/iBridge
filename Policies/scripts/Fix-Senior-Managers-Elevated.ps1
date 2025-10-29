#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Fix Senior Managers group using elevated Exchange Online connection
    
.DESCRIPTION
    This script connects to Exchange Online with elevated permissions and 
    attempts to fix the Senior Managers group that has scope restrictions.
    
.PARAMETER TargetAdmin
    The user to set as sole manager (default: lwandile.gasela@ibridge.co.za)
    
.EXAMPLE
    .\Fix-Senior-Managers-Elevated.ps1
    
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TargetAdmin = "lwandile.gasela@ibridge.co.za"
)

# Initialize logging
$LogPath = Join-Path $PSScriptRoot "..\logs"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFile = Join-Path $LogPath "Fix-Senior-Managers-Elevated-$Timestamp.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(switch($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    })
    Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
}

Write-Log "Starting ELEVATED Senior Managers Group Fix" "INFO"
Write-Log "Target Admin: $TargetAdmin" "INFO"

# Disconnect any existing session
try {
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    Write-Log "Disconnected existing Exchange Online session" "INFO"
}
catch {
    Write-Log "No existing session to disconnect" "INFO"
}

# Connect with elevated permissions
Write-Log "Connecting to Exchange Online with elevated permissions..." "INFO"
try {
    # Connect as Global Administrator with all scopes
    Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
    Write-Log "Connected to Exchange Online successfully" "SUCCESS"
    
    # Check connection and get organization details
    $orgConfig = Get-OrganizationConfig
    Write-Log "Organization: $($orgConfig.DisplayName)" "INFO"
    Write-Log "Exchange Version: $($orgConfig.AdminDisplayVersion)" "INFO"
    
}
catch {
    Write-Log "Failed to connect to Exchange Online: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Verify target admin user exists and get details
try {
    $AdminUserCheck = Get-Recipient -Identity $TargetAdmin -ErrorAction Stop
    Write-Log "Target admin user verified: $($AdminUserCheck.DisplayName)" "SUCCESS"
    Write-Log "User type: $($AdminUserCheck.RecipientType)" "INFO"
    Write-Log "User GUID: $($AdminUserCheck.Guid)" "INFO"
}
catch {
    Write-Log "Target admin user $TargetAdmin not found: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Find the Senior Managers group with more detailed search
Write-Log "Searching for Senior Managers group with detailed lookup..." "INFO"
$SeniorManagersGroup = $null

try {
    # Try multiple search methods
    $searchMethods = @(
        { Get-DistributionGroup -Identity "Senior Managers" -ErrorAction SilentlyContinue },
        { Get-DistributionGroup -Identity "*Senior Managers*" -ErrorAction SilentlyContinue },
        { Get-DistributionGroup -Identity "Senior Managers20220516104448" -ErrorAction SilentlyContinue },
        { Get-DistributionGroup -ResultSize Unlimited | Where-Object { $_.DisplayName -eq "Senior Managers" } },
        { Get-DistributionGroup -ResultSize Unlimited | Where-Object { $_.DisplayName -like "*Senior*Manager*" } }
    )
    
    foreach ($method in $searchMethods) {
        Write-Log "Trying search method..." "INFO"
        $result = & $method
        if ($result) {
            $SeniorManagersGroup = $result | Select-Object -First 1
            Write-Log "Found group using search method" "SUCCESS"
            break
        }
    }
    
    if (-not $SeniorManagersGroup) {
        Write-Log "Senior Managers group not found with any search method" "ERROR"
        exit 1
    }
    
    Write-Log "Group found: $($SeniorManagersGroup.DisplayName)" "SUCCESS"
    Write-Log "Group Identity: $($SeniorManagersGroup.Identity)" "INFO"
    Write-Log "Group GUID: $($SeniorManagersGroup.Guid)" "INFO"
    Write-Log "Group Type: $($SeniorManagersGroup.RecipientType)" "INFO"
    Write-Log "Group DN: $($SeniorManagersGroup.DistinguishedName)" "INFO"
    
}
catch {
    Write-Log "Error searching for Senior Managers group: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Get detailed group information
try {
    Write-Log "Getting detailed group information..." "INFO"
    
    $currentManagers = @($SeniorManagersGroup.ManagedBy)
    Write-Log "Current managers: $($currentManagers -join ', ')" "INFO"
    
    # Resolve manager names
    $resolvedManagers = @()
    foreach ($manager in $currentManagers) {
        try {
            $managerObj = Get-Recipient -Identity $manager -ErrorAction Stop
            $resolvedManagers += "$($managerObj.DisplayName) ($($managerObj.PrimarySmtpAddress))"
        }
        catch {
            $resolvedManagers += "$manager (could not resolve)"
        }
    }
    Write-Log "Resolved managers: $($resolvedManagers -join ', ')" "INFO"
    
    # Get group properties
    $groupProps = Get-DistributionGroup -Identity $SeniorManagersGroup.Identity
    Write-Log "Group Properties:" "INFO"
    Write-Log "  - RequireSenderAuthenticationEnabled: $($groupProps.RequireSenderAuthenticationEnabled)" "INFO"
    Write-Log "  - ModerationEnabled: $($groupProps.ModerationEnabled)" "INFO"
    Write-Log "  - IsMailboxEnabled: $($groupProps.IsMailboxEnabled)" "INFO"
    Write-Log "  - RecipientTypeDetails: $($groupProps.RecipientTypeDetails)" "INFO"
    
}
catch {
    Write-Log "Error getting group details: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Try different approaches to modify the group
Write-Log "Attempting to modify Senior Managers group with multiple methods..." "INFO"

$fixAttempts = @(
    @{
        Name = "Method 1: Direct Set-DistributionGroup with Identity"
        Script = { Set-DistributionGroup -Identity $SeniorManagersGroup.Identity -ManagedBy $TargetAdmin -ErrorAction Stop }
    },
    @{
        Name = "Method 2: Direct Set-DistributionGroup with GUID"
        Script = { Set-DistributionGroup -Identity $SeniorManagersGroup.Guid -ManagedBy $TargetAdmin -ErrorAction Stop }
    },
    @{
        Name = "Method 3: Direct Set-DistributionGroup with DisplayName"
        Script = { Set-DistributionGroup -Identity $SeniorManagersGroup.DisplayName -ManagedBy $TargetAdmin -ErrorAction Stop }
    },
    @{
        Name = "Method 4: Set-DistributionGroup with DN"
        Script = { Set-DistributionGroup -Identity $SeniorManagersGroup.DistinguishedName -ManagedBy $TargetAdmin -ErrorAction Stop }
    },
    @{
        Name = "Method 5: Add manager first, then remove others"
        Script = { 
            # Add target admin as additional manager
            $currentManagers = @($SeniorManagersGroup.ManagedBy)
            $newManagers = $currentManagers + $TargetAdmin
            Set-DistributionGroup -Identity $SeniorManagersGroup.Identity -ManagedBy $newManagers -ErrorAction Stop
            Start-Sleep -Seconds 2
            # Then set as sole manager
            Set-DistributionGroup -Identity $SeniorManagersGroup.Identity -ManagedBy $TargetAdmin -ErrorAction Stop
        }
    },
    @{
        Name = "Method 6: Use Set-Group instead of Set-DistributionGroup"
        Script = { Set-Group -Identity $SeniorManagersGroup.Identity -ManagedBy $TargetAdmin -ErrorAction Stop }
    }
)

$success = $false
foreach ($attempt in $fixAttempts) {
    Write-Log "Attempting: $($attempt.Name)" "INFO"
    
    try {
        if ($PSCmdlet.ShouldProcess($SeniorManagersGroup.Identity, $attempt.Name)) {
            & $attempt.Script
            Write-Log "✅ SUCCESS: $($attempt.Name) worked!" "SUCCESS"
            $success = $true
            break
        }
    }
    catch {
        Write-Log "❌ FAILED: $($attempt.Name) - $($_.Exception.Message)" "ERROR"
        
        # Check if it's a different error than scope
        if ($_.Exception.Message -notlike "*write scope*") {
            Write-Log "Different error type detected, may need manual intervention" "WARNING"
        }
    }
}

if (-not $success) {
    Write-Log "❌ ALL METHODS FAILED - Manual intervention required" "ERROR"
    
    # Provide specific guidance for manual fix
    Write-Log "=== MANUAL FIX REQUIRED ===" "WARNING"
    Write-Log "The group has persistent scope restrictions. Try these manual approaches:" "WARNING"
    Write-Log "1. Use Exchange Admin Center (https://admin.exchange.microsoft.com)" "WARNING"
    Write-Log "2. Contact Microsoft Support for scope restriction resolution" "WARNING"
    Write-Log "3. Use Azure AD PowerShell if this is hybrid-synchronized" "WARNING"
    Write-Log "4. Check if the group has special compliance or legal hold settings" "WARNING"
    
    exit 1
}

# Verify the changes
Write-Log "Verifying the changes..." "INFO"
try {
    Start-Sleep -Seconds 3  # Wait for changes to propagate
    
    $updatedGroup = Get-DistributionGroup -Identity $SeniorManagersGroup.Identity
    $newManagers = @($updatedGroup.ManagedBy)
    
    Write-Log "Updated managers: $($newManagers -join ', ')" "INFO"
    
    # Resolve new managers
    $resolvedNewManagers = @()
    foreach ($manager in $newManagers) {
        try {
            $managerObj = Get-Recipient -Identity $manager -ErrorAction Stop
            $resolvedNewManagers += "$($managerObj.DisplayName) ($($managerObj.PrimarySmtpAddress))"
        }
        catch {
            $resolvedNewManagers += "$manager (could not resolve)"
        }
    }
    Write-Log "Resolved updated managers: $($resolvedNewManagers -join ', ')" "SUCCESS"
    
    # Check if target admin is sole manager
    if ($newManagers.Count -eq 1) {
        $soleManager = Get-Recipient -Identity $newManagers[0] -ErrorAction Stop
        if ($soleManager.PrimarySmtpAddress -eq $TargetAdmin) {
            Write-Log "🎉 SUCCESS: $TargetAdmin is now the sole manager!" "SUCCESS"
        }
        else {
            Write-Log "⚠️ WARNING: Sole manager is not the target admin" "WARNING"
        }
    }
    else {
        Write-Log "⚠️ WARNING: Group still has multiple managers" "WARNING"
    }
    
}
catch {
    Write-Log "Error verifying changes: $($_.Exception.Message)" "ERROR"
}

Write-Log "Senior Managers group fix attempt completed" "INFO"
Write-Log "Log file: $LogFile" "INFO"
