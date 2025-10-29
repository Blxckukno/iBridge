#Requires -Modules ExchangeOnlineManagement

<#
.SYNOPSIS
    Simple admin permissions check for Exchange Online
.DESCRIPTION
    This script checks basic admin permissions using available Exchange Online cmdlets
#>

[CmdletBinding()]
param()

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

# Main execution
Write-ColorOutput "=== Simple Admin Permissions Check ===" "Green"

# Connect to Exchange Online
Write-ColorOutput "Connecting to Exchange Online..." "Yellow"
try {
    Connect-ExchangeOnline -ShowProgress $false -ErrorAction Stop
    Write-ColorOutput "Connected to Exchange Online successfully" "Green"
} catch {
    Write-ColorOutput "Failed to connect to Exchange Online: $($_.Exception.Message)" "Red"
    exit 1
}

# Check current user
Write-ColorOutput "`n=== Current User Information ===" "Cyan"
try {
    $currentUser = Get-EXOMailbox -Identity "lwandile.gasela@ibridge.co.za" -ErrorAction Stop
    Write-ColorOutput "User: $($currentUser.DisplayName)" "White"
    Write-ColorOutput "Email: $($currentUser.PrimarySmtpAddress)" "White"
    Write-ColorOutput "User Type: $($currentUser.RecipientTypeDetails)" "White"
} catch {
    Write-ColorOutput "Could not retrieve user information: $($_.Exception.Message)" "Red"
}

# Check organization config to verify admin access
Write-ColorOutput "`n=== Organization Access Check ===" "Cyan"
try {
    $orgConfig = Get-OrganizationConfig -ErrorAction Stop
    Write-ColorOutput "✓ Can access organization configuration" "Green"
    Write-ColorOutput "Organization: $($orgConfig.DisplayName)" "White"
} catch {
    Write-ColorOutput "✗ Cannot access organization configuration: $($_.Exception.Message)" "Red"
}

# Check access to distribution groups
Write-ColorOutput "`n=== Distribution Group Access ===" "Cyan"
$targetGroups = @('All Employees', 'iBridge General Enquiries')

foreach ($groupName in $targetGroups) {
    try {
        $group = Get-DistributionGroup -Identity $groupName -ErrorAction Stop
        Write-ColorOutput "✓ Can access group: $($group.DisplayName)" "Green"
        Write-ColorOutput "  Identity: $($group.Identity)" "White"
        Write-ColorOutput "  Managed By: $($group.ManagedBy -join ', ')" "White"
        Write-ColorOutput "  Moderation Enabled: $($group.ModerationEnabled)" "White"
        
        # Check if current user is a manager
        $currentUserEmail = "lwandile.gasela@ibridge.co.za"
        $isManager = $group.ManagedBy -contains $currentUserEmail -or 
                     $group.ManagedBy -contains 'Lwandile Gasela' -or
                     $group.ManagedBy -like '*lwandile*gasela*'
        
        if ($isManager) {
            Write-ColorOutput "  ✓ Current user is a manager" "Green"
        } else {
            Write-ColorOutput "  ✗ Current user is NOT a manager" "Red"
        }
        
        # Test if we can modify the group
        Write-ColorOutput "  Testing modification permissions..." "Yellow"
        try {
            # Try to set the same property to test write access
            Set-DistributionGroup -Identity $group.Identity -DisplayName $group.DisplayName -WhatIf -ErrorAction Stop
            Write-ColorOutput "  ✓ Can modify group settings" "Green"
        } catch {
            Write-ColorOutput "  ✗ Cannot modify group: $($_.Exception.Message)" "Red"
        }
        
    } catch {
        Write-ColorOutput "✗ Cannot access group '$groupName': $($_.Exception.Message)" "Red"
    }
}

# Check access to shared mailboxes
Write-ColorOutput "`n=== Shared Mailbox Access ===" "Cyan"
$sharedMailboxes = @(
    'iBridgeAll@ibridge.co.za',
    'inbound_post-paid@ibridge.co.za',
    'Pre-Paid_Inbound@ibridge.co.za'
)

foreach ($mailbox in $sharedMailboxes) {
    try {
        $sharedMB = Get-EXOMailbox -Identity $mailbox -ErrorAction Stop
        Write-ColorOutput "✓ Can access shared mailbox: $($sharedMB.DisplayName)" "Green"
        Write-ColorOutput "  Type: $($sharedMB.RecipientTypeDetails)" "White"
        
        # Test modification permissions
        try {
            Set-Mailbox -Identity $mailbox -DisplayName $sharedMB.DisplayName -WhatIf -ErrorAction Stop
            Write-ColorOutput "  ✓ Can modify mailbox settings" "Green"
        } catch {
            Write-ColorOutput "  ✗ Cannot modify mailbox: $($_.Exception.Message)" "Red"
        }
        
    } catch {
        Write-ColorOutput "✗ Cannot access shared mailbox '$mailbox': $($_.Exception.Message)" "Red"
    }
}

# Check what Exchange Online cmdlets are available
Write-ColorOutput "`n=== Available Exchange Cmdlets ===" "Cyan"
$availableCmdlets = @(
    'Get-DistributionGroup',
    'Set-DistributionGroup', 
    'Get-EXOMailbox',
    'Set-Mailbox',
    'Get-OrganizationConfig',
    'Get-TransportRule',
    'New-TransportRule'
)

foreach ($cmdlet in $availableCmdlets) {
    if (Get-Command $cmdlet -ErrorAction SilentlyContinue) {
        Write-ColorOutput "✓ Available: $cmdlet" "Green"
    } else {
        Write-ColorOutput "✗ Not available: $cmdlet" "Red"
    }
}

Write-ColorOutput "`n=== Summary ===" "Green"
Write-ColorOutput "Admin permissions check completed." "White"
Write-ColorOutput "If you can modify groups and mailboxes, you have sufficient permissions." "White"
Write-ColorOutput "If you cannot modify them, you may need additional admin roles." "White"
