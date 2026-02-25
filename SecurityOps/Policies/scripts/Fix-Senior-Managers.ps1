#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Attempt to fix the Senior Managers group with enhanced permissions
.DESCRIPTION
    This script attempts to fix the Senior Managers group that has scope issues
#>

[CmdletBinding()]
param(
    [switch]$WhatIf
)

$PrimaryAdmin = "lwandile.gasela@ibridge.co.za"
$GroupName = "Senior Managers"

# Logging
$LogFile = "C:\Users\Lwandile Gasela\iBridge\Policies\logs\Fix-Senior-Managers-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

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

Write-Log "Starting Senior Managers Group Fix" "INFO"
Write-Log "Target primary admin: $PrimaryAdmin" "INFO"
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

# Find the Senior Managers group
try {
    $Group = Get-DistributionGroup -Identity $GroupName -ErrorAction Stop
    Write-Log "Found group: $($Group.DisplayName) ($($Group.Identity))" "INFO"
    Write-Log "Current managers: $($Group.ManagedBy -join ', ')" "INFO"
    Write-Log "Group scope: $($Group.RecipientTypeDetails)" "INFO"
    
    # Check if Mgqibelo is still in the managers
    $MgqibeloIsManager = $Group.ManagedBy -contains "Mgqibelo" -or $Group.ManagedBy -contains "Mgqibelo.Gasela@ibridge.co.za"
    
    if ($MgqibeloIsManager) {
        Write-Log "Mgqibelo is still a manager - needs to be removed" "WARNING"
        
        if ($WhatIf) {
            Write-Log "WHATIF: Would remove Mgqibelo and set $PrimaryAdmin as sole manager" "INFO"
        } else {
            try {
                # Try to set the primary admin as sole manager
                Set-DistributionGroup -Identity $Group.Identity -ManagedBy $PrimaryAdmin -ErrorAction Stop
                Write-Log "✅ Successfully set $PrimaryAdmin as sole manager of $($Group.DisplayName)" "SUCCESS"
            }
            catch {
                Write-Log "❌ Failed to update Senior Managers group: $($_.Exception.Message)" "ERROR"
                Write-Log "This may be due to the group being created with different permissions or organizational scope" "WARNING"
                
                # Try alternative approach - remove Mgqibelo first, then add primary admin
                try {
                    Write-Log "Trying alternative approach..." "INFO"
                    $CurrentManagers = @($Group.ManagedBy)
                    $NewManagers = @($PrimaryAdmin)
                    
                    # Add other managers except Mgqibelo
                    foreach ($Manager in $CurrentManagers) {
                        if ($Manager -ne "Mgqibelo" -and $Manager -ne "Mgqibelo.Gasela@ibridge.co.za") {
                            $NewManagers += $Manager
                        }
                    }
                    
                    Set-DistributionGroup -Identity $Group.Identity -ManagedBy $NewManagers -ErrorAction Stop
                    Write-Log "✅ Successfully updated managers (removed Mgqibelo, added $PrimaryAdmin)" "SUCCESS"
                }
                catch {
                    Write-Log "❌ Alternative approach also failed: $($_.Exception.Message)" "ERROR"
                    Write-Log "This group may require manual intervention or different administrative permissions" "WARNING"
                }
            }
        }
    } else {
        Write-Log "Mgqibelo is not currently a manager of this group" "INFO"
        
        # Check if primary admin is a manager
        $PrimaryIsManager = $Group.ManagedBy -contains $PrimaryAdmin
        if (-not $PrimaryIsManager) {
            Write-Log "Primary admin is not a manager - adding..." "INFO"
            if ($WhatIf) {
                Write-Log "WHATIF: Would add $PrimaryAdmin as manager" "INFO"
            } else {
                try {
                    $CurrentManagers = @($Group.ManagedBy)
                    $NewManagers = @($PrimaryAdmin) + $CurrentManagers
                    Set-DistributionGroup -Identity $Group.Identity -ManagedBy $NewManagers -ErrorAction Stop
                    Write-Log "✅ Successfully added $PrimaryAdmin as manager" "SUCCESS"
                }
                catch {
                    Write-Log "❌ Failed to add primary admin as manager: $($_.Exception.Message)" "ERROR"
                }
            }
        } else {
            Write-Log "✅ Primary admin is already a manager" "SUCCESS"
        }
    }
}
catch {
    Write-Log "❌ Failed to find or process Senior Managers group: $($_.Exception.Message)" "ERROR"
}

Write-Log "Senior Managers group fix completed" "SUCCESS"
Write-Log "Log file: $LogFile" "INFO"
