#Requires -Modules ExchangeOnlineManagement

<#
.SYNOPSIS
    Check current admin permissions for lwandile.gasela@ibridge.co.za
.DESCRIPTION
    This script checks the current admin role memberships and permissions for the user account
.PARAMETER WhatIf
    Run in test mode without making changes
#>

[CmdletBinding()]
param(
    [switch]$WhatIf
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

# Main execution
Write-ColorOutput "=== Checking Admin Permissions for lwandile.gasela@ibridge.co.za ===" "Green"

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

# Check current user information
Write-ColorOutput "`n=== Current User Information ===" "Cyan"
try {
    $currentUser = Get-Mailbox -Identity "lwandile.gasela@ibridge.co.za" -ErrorAction Stop
    Write-ColorOutput "User: $($currentUser.DisplayName)" "White"
    Write-ColorOutput "Email: $($currentUser.PrimarySmtpAddress)" "White"
    Write-ColorOutput "User Type: $($currentUser.RecipientTypeDetails)" "White"
} catch {
    Write-ColorOutput "Could not retrieve user information: $($_.Exception.Message)" "Red"
}

# Check admin role memberships
Write-ColorOutput "`n=== Admin Role Memberships ===" "Cyan"
$adminRoles = @(
    'Organization Management',
    'Exchange Administrators', 
    'Recipient Management',
    'Mail Recipients',
    'Distribution Groups'
)

foreach ($role in $adminRoles) {
    try {
        $members = Get-RoleGroupMember -Identity $role -ErrorAction SilentlyContinue | 
                   Where-Object {$_.Name -like '*lwandile*' -or $_.Name -like '*gasela*' -or $_.PrimarySmtpAddress -eq 'lwandile.gasela@ibridge.co.za'}
        
        if ($members) {
            Write-ColorOutput "✓ Found in role: $role" "Green"
            foreach ($member in $members) {
                Write-ColorOutput "  - $($member.Name) ($($member.PrimarySmtpAddress))" "White"
            }
        } else {
            Write-ColorOutput "✗ Not found in role: $role" "Red"
        }
    } catch {
        Write-ColorOutput "Could not check role: $role - $($_.Exception.Message)" "Yellow"
    }
}

# Check current permissions on target groups
Write-ColorOutput "`n=== Target Group Permissions ===" "Cyan"
$targetGroups = @('All Employees', 'iBridge General Enquiries')

foreach ($groupName in $targetGroups) {
    try {
        $group = Get-DistributionGroup -Identity $groupName -ErrorAction Stop
        Write-ColorOutput "`nGroup: $($group.DisplayName)" "Yellow"
        Write-ColorOutput "  Identity: $($group.Identity)" "White"
        Write-ColorOutput "  Managed By: $($group.ManagedBy -join ', ')" "White"
        Write-ColorOutput "  Moderation Enabled: $($group.ModerationEnabled)" "White"
        Write-ColorOutput "  Moderators: $($group.ModeratedBy -join ', ')" "White"
        
        # Check if current user is a manager
        $isManager = $group.ManagedBy -contains 'lwandile.gasela@ibridge.co.za' -or 
                     $group.ManagedBy -contains 'lwandile gasela' -or
                     $group.ManagedBy -like '*lwandile*gasela*'
        
        if ($isManager) {
            Write-ColorOutput "  ✓ Current user is a manager" "Green"
        } else {
            Write-ColorOutput "  ✗ Current user is NOT a manager" "Red"
        }
        
    } catch {
        Write-ColorOutput "Could not access group '$groupName': $($_.Exception.Message)" "Red"
    }
}

# Check write scopes that might be limiting permissions
Write-ColorOutput "`n=== Write Scopes Check ===" "Cyan"
try {
    $roleAssignments = Get-ManagementRoleAssignment -RoleAssignee "lwandile.gasela@ibridge.co.za" -ErrorAction SilentlyContinue
    if ($roleAssignments) {
        Write-ColorOutput "Current role assignments:" "White"
        foreach ($assignment in $roleAssignments) {
            Write-ColorOutput "  - Role: $($assignment.Role)" "White"
            Write-ColorOutput "    Write Scope: $($assignment.WriteScope)" "White"
            Write-ColorOutput "    Enabled: $($assignment.Enabled)" "White"
        }
    } else {
        Write-ColorOutput "No direct role assignments found" "Yellow"
    }
} catch {
    Write-ColorOutput "Could not check role assignments: $($_.Exception.Message)" "Yellow"
}

Write-ColorOutput "`n=== Summary ===" "Green"
Write-ColorOutput "Admin permissions check completed. Review the output above to identify any missing permissions." "White"
Write-ColorOutput "If you need to add admin roles, use the Grant-AdminPermissions.ps1 script." "White"
