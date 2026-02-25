#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Fix the "Senior Managers" group to set lwandile.gasela@ibridge.co.za as sole manager
    
.DESCRIPTION
    This script specifically targets the "Senior Managers" group which has scope/permission issues.
    It will remove all current managers and set lwandile.gasela@ibridge.co.za as the sole manager.
    
.PARAMETER WhatIf
    Shows what would be done without making actual changes
    
.PARAMETER TargetAdmin
    The user to set as sole manager (default: lwandile.gasela@ibridge.co.za)
    
.EXAMPLE
    .\Fix-Senior-Managers-Group.ps1 -WhatIf
    Test what changes would be made
    
.EXAMPLE
    .\Fix-Senior-Managers-Group.ps1
    Fix the Senior Managers group
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TargetAdmin = "lwandile.gasela@ibridge.co.za"
)

# Initialize logging
$LogPath = Join-Path $PSScriptRoot "..\logs"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFile = Join-Path $LogPath "Fix-Senior-Managers-$Timestamp.log"

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

function Test-ExchangeConnection {
    try {
        $null = Get-OrganizationConfig -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

Write-Log "Starting Senior Managers Group Fix" "INFO"
Write-Log "Target Admin: $TargetAdmin" "INFO"

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
    $AdminUserCheck = Get-Recipient -Identity $TargetAdmin -ErrorAction Stop
    Write-Log "Target admin user $TargetAdmin verified: $($AdminUserCheck.DisplayName)" "SUCCESS"
}
catch {
    Write-Log "Target admin user $TargetAdmin not found: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Find the Senior Managers group
Write-Log "Searching for Senior Managers group..." "INFO"
$SeniorManagersGroup = $null

try {
    # Try different search patterns
    $searchPatterns = @(
        "Senior Managers",
        "*Senior Managers*",
        "*Senior*Manager*"
    )
    
    foreach ($pattern in $searchPatterns) {
        $groups = Get-DistributionGroup -Identity $pattern -ErrorAction SilentlyContinue
        if ($groups) {
            if ($groups -is [array]) {
                $SeniorManagersGroup = $groups | Where-Object { $_.DisplayName -like "*Senior*Manager*" } | Select-Object -First 1
            } else {
                $SeniorManagersGroup = $groups
            }
            break
        }
    }
    
    # If not found in distribution groups, check all groups
    if (-not $SeniorManagersGroup) {
        Write-Log "Not found in distribution groups, searching all groups..." "INFO"
        $allGroups = Get-DistributionGroup -ResultSize Unlimited | Where-Object { $_.DisplayName -like "*Senior*Manager*" }
        if ($allGroups) {
            $SeniorManagersGroup = $allGroups | Select-Object -First 1
        }
    }
    
    if (-not $SeniorManagersGroup) {
        Write-Log "Senior Managers group not found" "ERROR"
        exit 1
    }
    
    Write-Log "Found group: $($SeniorManagersGroup.DisplayName)" "SUCCESS"
    Write-Log "Group Identity: $($SeniorManagersGroup.Identity)" "INFO"
    Write-Log "Group Type: $($SeniorManagersGroup.RecipientType)" "INFO"
    
}
catch {
    Write-Log "Error searching for Senior Managers group: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Get current group details
try {
    Write-Log "Getting current group details..." "INFO"
    
    $currentManagers = @($SeniorManagersGroup.ManagedBy)
    Write-Log "Current managers: $($currentManagers -join ', ')" "INFO"
    
    # Resolve manager names to email addresses
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
    
    # Check if target admin is already sole manager
    if ($currentManagers.Count -eq 1) {
        try {
            $currentManager = Get-Recipient -Identity $currentManagers[0] -ErrorAction Stop
            if ($currentManager.PrimarySmtpAddress -eq $TargetAdmin) {
                Write-Log "✅ $TargetAdmin is already the sole manager of $($SeniorManagersGroup.DisplayName)" "SUCCESS"
                Write-Log "No changes needed" "SUCCESS"
                exit 0
            }
        }
        catch {
            Write-Log "Could not resolve current manager, proceeding with update..." "WARNING"
        }
    }
    
}
catch {
    Write-Log "Error getting group details: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Fix the group management
Write-Log "Attempting to fix Senior Managers group..." "INFO"

try {
    # Method 1: Direct assignment
    Write-Log "Attempting Method 1: Direct manager assignment..." "INFO"
    
    if ($PSCmdlet.ShouldProcess($SeniorManagersGroup.Identity, "Set $TargetAdmin as sole manager")) {
        try {
            Set-DistributionGroup -Identity $SeniorManagersGroup.Identity -ManagedBy $TargetAdmin -ErrorAction Stop
            Write-Log "✅ Successfully set $TargetAdmin as sole manager using Method 1" "SUCCESS"
            
            # Verify the change
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
            
        }
        catch {
            Write-Log "Method 1 failed: $($_.Exception.Message)" "ERROR"
            
            # Method 2: Clear and set
            Write-Log "Attempting Method 2: Clear managers first, then set..." "INFO"
            
            try {
                # This might not work, but let's try
                Set-DistributionGroup -Identity $SeniorManagersGroup.Identity -ManagedBy @() -ErrorAction Stop
                Start-Sleep -Seconds 2
                Set-DistributionGroup -Identity $SeniorManagersGroup.Identity -ManagedBy $TargetAdmin -ErrorAction Stop
                Write-Log "✅ Successfully set $TargetAdmin as sole manager using Method 2" "SUCCESS"
            }
            catch {
                Write-Log "Method 2 failed: $($_.Exception.Message)" "ERROR"
                
                # Method 3: Use Exchange Online PowerShell with different approach
                Write-Log "Attempting Method 3: Alternative Exchange cmdlet approach..." "INFO"
                
                try {
                    # Try using the full identity string
                    $fullIdentity = $SeniorManagersGroup.DistinguishedName
                    Set-DistributionGroup -Identity $fullIdentity -ManagedBy $TargetAdmin -ErrorAction Stop
                    Write-Log "✅ Successfully set $TargetAdmin as sole manager using Method 3" "SUCCESS"
                }
                catch {
                    Write-Log "Method 3 failed: $($_.Exception.Message)" "ERROR"
                    
                    # Method 4: Try with GUID
                    Write-Log "Attempting Method 4: Using GUID..." "INFO"
                    
                    try {
                        $guid = $SeniorManagersGroup.Guid
                        Set-DistributionGroup -Identity $guid -ManagedBy $TargetAdmin -ErrorAction Stop
                        Write-Log "✅ Successfully set $TargetAdmin as sole manager using Method 4" "SUCCESS"
                    }
                    catch {
                        Write-Log "Method 4 failed: $($_.Exception.Message)" "ERROR"
                        Write-Log "❌ All methods failed to update the Senior Managers group" "ERROR"
                        
                        # Provide detailed error information
                        Write-Log "=== DETAILED ERROR INFORMATION ===" "ERROR"
                        Write-Log "Group Name: $($SeniorManagersGroup.DisplayName)" "ERROR"
                        Write-Log "Group Identity: $($SeniorManagersGroup.Identity)" "ERROR"
                        Write-Log "Group GUID: $($SeniorManagersGroup.Guid)" "ERROR"
                        Write-Log "Group Type: $($SeniorManagersGroup.RecipientType)" "ERROR"
                        Write-Log "Group DN: $($SeniorManagersGroup.DistinguishedName)" "ERROR"
                        
                        # Check if this is actually an Office 365 group
                        try {
                            $o365Group = Get-UnifiedGroup -Identity $SeniorManagersGroup.Identity -ErrorAction SilentlyContinue
                            if ($o365Group) {
                                Write-Log "⚠️ This appears to be an Office 365 group, not a distribution group!" "WARNING"
                                Write-Log "Office 365 groups require different cmdlets (Get-UnifiedGroup, Add-UnifiedGroupLinks, etc.)" "WARNING"
                                Write-Log "Run the Fix-Office365-Groups.ps1 script to handle this group properly" "WARNING"
                            }
                        }
                        catch {
                            Write-Log "Could not check if this is an Office 365 group" "INFO"
                        }
                        
                        exit 1
                    }
                }
            }
        }
    }
    
    Write-Log "=== SENIOR MANAGERS GROUP FIX COMPLETED ===" "SUCCESS"
    Write-Log "Group: $($SeniorManagersGroup.DisplayName)" "SUCCESS"
    Write-Log "New sole manager: $TargetAdmin" "SUCCESS"
    Write-Log "Previous managers removed successfully" "SUCCESS"
    
}
catch {
    Write-Log "Unexpected error: $($_.Exception.Message)" "ERROR"
    exit 1
}

Write-Log "Senior Managers group fix completed" "SUCCESS"
Write-Log "Log file: $LogFile" "INFO"
