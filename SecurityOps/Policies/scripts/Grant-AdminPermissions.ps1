#Requires -Modules ExchangeOnlineManagement

<#
.SYNOPSIS
    Grant admin permissions to lwandile.gasela@ibridge.co.za for email policy management
.DESCRIPTION
    This script grants the necessary admin roles and permissions to manage distribution groups,
    shared mailboxes, and email policies in Microsoft 365 Exchange Online.
.PARAMETER WhatIf
    Run in test mode without making changes
.PARAMETER Force
    Force the operation even if some checks fail
#>

[CmdletBinding()]
param(
    [switch]$WhatIf,
    [switch]$Force
)

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-ExchangeConnection {
    try {
        $null = Get-OrganizationConfig -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Configuration
$targetUser = "lwandile.gasela@ibridge.co.za"
$requiredRoles = @(
    'Organization Management',
    'Recipient Management',
    'Distribution Groups'
)

# Main execution
Write-ColorOutput "=== Granting Admin Permissions ===" "Green"
if ($WhatIf) {
    Write-ColorOutput "Running in WhatIf mode - no changes will be made" "Yellow"
}

# Connect to Exchange Online if not already connected
if (-not (Test-ExchangeConnection)) {
    Write-ColorOutput "Connecting to Exchange Online..." "Yellow"
    try {
        Connect-ExchangeOnline -ShowProgress $false -ErrorAction Stop
        Write-ColorOutput "Connected to Exchange Online successfully" "Green"
    } catch {
        Write-ColorOutput "Failed to connect to Exchange Online: $($_.Exception.Message)" "Red"
        exit 1
    }
} else {
    Write-ColorOutput "Already connected to Exchange Online" "Green"
}

# Verify target user exists
Write-ColorOutput "`n=== Verifying Target User ===" "Cyan"
try {
    $user = Get-Mailbox -Identity $targetUser -ErrorAction Stop
    Write-ColorOutput "✓ User found: $($user.DisplayName)" "Green"
} catch {
    Write-ColorOutput "✗ User not found: $targetUser" "Red"
    if (-not $Force) {
        Write-ColorOutput "Use -Force to continue anyway" "Yellow"
        exit 1
    }
}

# Grant required admin roles
Write-ColorOutput "`n=== Granting Admin Roles ===" "Cyan"
foreach ($role in $requiredRoles) {
    try {
        Write-ColorOutput "Processing role: $role" "Yellow"
        
        # Check if user is already a member
        $existingMembers = Get-RoleGroupMember -Identity $role -ErrorAction SilentlyContinue | 
                          Where-Object {$_.PrimarySmtpAddress -eq $targetUser}
        
        if ($existingMembers) {
            Write-ColorOutput "  ✓ User is already a member of $role" "Green"
        } else {
            if ($WhatIf) {
                Write-ColorOutput "  [WhatIf] Would add user to role: $role" "Yellow"
            } else {
                try {
                    Add-RoleGroupMember -Identity $role -Member $targetUser -ErrorAction Stop
                    Write-ColorOutput "  ✓ Successfully added user to role: $role" "Green"
                } catch {
                    Write-ColorOutput "  ✗ Failed to add user to role $role`: $($_.Exception.Message)" "Red"
                }
            }
        }
    } catch {
        Write-ColorOutput "  ✗ Error processing role $role`: $($_.Exception.Message)" "Red"
    }
}

# Grant management rights to target groups
Write-ColorOutput "`n=== Granting Group Management Rights ===" "Cyan"
$targetGroups = @('All Employees', 'iBridge General Enquiries')

foreach ($groupName in $targetGroups) {
    try {
        Write-ColorOutput "Processing group: $groupName" "Yellow"
        
        $group = Get-DistributionGroup -Identity $groupName -ErrorAction Stop
        
        # Check if user is already a manager
        $isManager = $group.ManagedBy -contains $targetUser -or 
                     $group.ManagedBy -contains 'lwandile gasela' -or
                     $group.ManagedBy -like '*lwandile*gasela*'
        
        if ($isManager) {
            Write-ColorOutput "  ✓ User is already a manager of $groupName" "Green"
        } else {
            if ($WhatIf) {
                Write-ColorOutput "  [WhatIf] Would add user as manager of: $groupName" "Yellow"
            } else {
                try {
                    # Get current managers and add the new one
                    $currentManagers = @($group.ManagedBy)
                    $newManagers = $currentManagers + $targetUser
                    
                    Set-DistributionGroup -Identity $group.Identity -ManagedBy $newManagers -ErrorAction Stop
                    Write-ColorOutput "  ✓ Successfully added user as manager of: $groupName" "Green"
                } catch {
                    Write-ColorOutput "  ✗ Failed to add user as manager of $groupName`: $($_.Exception.Message)" "Red"
                    
                    # Try alternative method with just the user
                    try {
                        Write-ColorOutput "  Trying alternative method..." "Yellow"
                        Set-DistributionGroup -Identity $group.Identity -ManagedBy $targetUser -ErrorAction Stop
                        Write-ColorOutput "  ✓ Successfully set user as manager of: $groupName (alternative method)" "Green"
                    } catch {
                        Write-ColorOutput "  ✗ Alternative method also failed: $($_.Exception.Message)" "Red"
                    }
                }
            }
        }
    } catch {
        Write-ColorOutput "  ✗ Error processing group $groupName`: $($_.Exception.Message)" "Red"
    }
}

# Grant permissions to shared mailboxes
Write-ColorOutput "`n=== Granting Shared Mailbox Permissions ===" "Cyan"
$sharedMailboxes = @(
    'iBridgeAll@ibridge.co.za',
    'inbound_post-paid@ibridge.co.za', 
    'Pre-Paid_Inbound@ibridge.co.za'
)

foreach ($mailbox in $sharedMailboxes) {
    try {
        Write-ColorOutput "Processing shared mailbox: $mailbox" "Yellow"
        
        # Check if mailbox exists
        $sharedMB = Get-Mailbox -Identity $mailbox -ErrorAction SilentlyContinue
        if (-not $sharedMB) {
            Write-ColorOutput "  ✗ Shared mailbox not found: $mailbox" "Red"
            continue
        }
        
        # Check current permissions
        $currentPermissions = Get-MailboxPermission -Identity $mailbox -User $targetUser -ErrorAction SilentlyContinue
        
        if ($currentPermissions | Where-Object {$_.AccessRights -contains 'FullAccess'}) {
            Write-ColorOutput "  ✓ User already has FullAccess to: $mailbox" "Green"
        } else {
            if ($WhatIf) {
                Write-ColorOutput "  [WhatIf] Would grant FullAccess to: $mailbox" "Yellow"
            } else {
                try {
                    Add-MailboxPermission -Identity $mailbox -User $targetUser -AccessRights FullAccess -InheritanceType All -ErrorAction Stop
                    Write-ColorOutput "  ✓ Successfully granted FullAccess to: $mailbox" "Green"
                } catch {
                    Write-ColorOutput "  ✗ Failed to grant FullAccess to $mailbox`: $($_.Exception.Message)" "Red"
                }
            }
        }
        
        # Check SendAs permissions
        $sendAsPermissions = Get-RecipientPermission -Identity $mailbox -Trustee $targetUser -ErrorAction SilentlyContinue
        
        if ($sendAsPermissions | Where-Object {$_.AccessRights -contains 'SendAs'}) {
            Write-ColorOutput "  ✓ User already has SendAs permission to: $mailbox" "Green"
        } else {
            if ($WhatIf) {
                Write-ColorOutput "  [WhatIf] Would grant SendAs permission to: $mailbox" "Yellow"
            } else {
                try {
                    Add-RecipientPermission -Identity $mailbox -Trustee $targetUser -AccessRights SendAs -Confirm:$false -ErrorAction Stop
                    Write-ColorOutput "  ✓ Successfully granted SendAs permission to: $mailbox" "Green"
                } catch {
                    Write-ColorOutput "  ✗ Failed to grant SendAs permission to $mailbox`: $($_.Exception.Message)" "Red"
                }
            }
        }
        
    } catch {
        Write-ColorOutput "  ✗ Error processing shared mailbox $mailbox`: $($_.Exception.Message)" "Red"
    }
}

# Summary
Write-ColorOutput "`n=== Summary ===" "Green"
if ($WhatIf) {
    Write-ColorOutput "WhatIf mode completed. Review the output above to see what changes would be made." "Yellow"
    Write-ColorOutput "Run the script without -WhatIf to apply the changes." "Yellow"
} else {
    Write-ColorOutput "Admin permissions grant operation completed." "Green"
    Write-ColorOutput "Run Check-AdminPermissions.ps1 to verify the changes." "Green"
}

Write-ColorOutput "`nNext steps:" "Cyan"
Write-ColorOutput "1. Run Check-AdminPermissions.ps1 to verify permissions" "White"
Write-ColorOutput "2. Run Apply-EmailPolicies.ps1 to apply email policies" "White"
Write-ColorOutput "3. Run Verify-Policies.ps1 to confirm policy application" "White"
