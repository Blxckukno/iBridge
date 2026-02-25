#Requires -Modules ExchangeOnlineManagement, AzureAD

<#
.SYNOPSIS
    Grant comprehensive admin permissions for Microsoft 365 email policy management
.DESCRIPTION
    This script grants both Azure AD and Exchange Online admin roles necessary to manage
    distribution groups, shared mailboxes, and email policies.
.PARAMETER WhatIf
    Run in test mode without making changes
.PARAMETER SkipAzureAD
    Skip Azure AD role assignments (Exchange Online only)
.PARAMETER SkipExchange
    Skip Exchange Online role assignments (Azure AD only)
#>

[CmdletBinding()]
param(
    [switch]$WhatIf,
    [switch]$SkipAzureAD,
    [switch]$SkipExchange
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

function Test-AzureADConnection {
    try {
        $null = Get-AzureADCurrentSessionInfo -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Configuration
$targetUser = "lwandile.gasela@ibridge.co.za"
$targetUserUPN = "lwandile.gasela@ibridge.co.za"

# Azure AD roles needed
$azureADRoles = @(
    'Exchange Administrator',
    'Groups Administrator',
    'User Administrator'
)

# Exchange Online roles needed
$exchangeRoles = @(
    'Organization Management',
    'Recipient Management',
    'Distribution Groups',
    'Mail Recipients'
)

# Main execution
Write-ColorOutput "=== Comprehensive Admin Permissions Setup ===" "Green"
if ($WhatIf) {
    Write-ColorOutput "Running in WhatIf mode - no changes will be made" "Yellow"
}

# Connect to services
if (-not $SkipAzureAD) {
    Write-ColorOutput "`n=== Connecting to Azure AD ===" "Cyan"
    if (-not (Test-AzureADConnection)) {
        try {
            Connect-AzureAD -ErrorAction Stop
            Write-ColorOutput "Connected to Azure AD successfully" "Green"
        } catch {
            Write-ColorOutput "Failed to connect to Azure AD: $($_.Exception.Message)" "Red"
            Write-ColorOutput "Continuing with Exchange Online only..." "Yellow"
            $SkipAzureAD = $true
        }
    } else {
        Write-ColorOutput "Already connected to Azure AD" "Green"
    }
}

if (-not $SkipExchange) {
    Write-ColorOutput "`n=== Connecting to Exchange Online ===" "Cyan"
    if (-not (Test-ExchangeConnection)) {
        try {
            Connect-ExchangeOnline -ShowProgress $false -ErrorAction Stop
            Write-ColorOutput "Connected to Exchange Online successfully" "Green"
        } catch {
            Write-ColorOutput "Failed to connect to Exchange Online: $($_.Exception.Message)" "Red"
            Write-ColorOutput "Continuing with Azure AD only..." "Yellow"
            $SkipExchange = $true
        }
    } else {
        Write-ColorOutput "Already connected to Exchange Online" "Green"
    }
}

# Grant Azure AD admin roles
if (-not $SkipAzureAD) {
    Write-ColorOutput "`n=== Granting Azure AD Admin Roles ===" "Cyan"
    
    try {
        # Get the user object
        $user = Get-AzureADUser -Filter "userPrincipalName eq '$targetUserUPN'" -ErrorAction Stop
        Write-ColorOutput "Found user: $($user.DisplayName)" "Green"
        
        foreach ($roleName in $azureADRoles) {
            try {
                Write-ColorOutput "Processing Azure AD role: $roleName" "Yellow"
                
                # Get the role template
                $roleTemplate = Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq $roleName}
                if (-not $roleTemplate) {
                    Write-ColorOutput "  ✗ Role template not found: $roleName" "Red"
                    continue
                }
                
                # Get or create the role
                $role = Get-AzureADDirectoryRole | Where-Object {$_.DisplayName -eq $roleName}
                if (-not $role) {
                    if ($WhatIf) {
                        Write-ColorOutput "  [WhatIf] Would enable directory role: $roleName" "Yellow"
                    } else {
                        $role = Enable-AzureADDirectoryRole -RoleTemplateId $roleTemplate.ObjectId
                        Write-ColorOutput "  ✓ Enabled directory role: $roleName" "Green"
                    }
                } else {
                    Write-ColorOutput "  ✓ Directory role already exists: $roleName" "Green"
                }
                
                if ($role) {
                    # Check if user is already a member
                    $existingMembers = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId | 
                                      Where-Object {$_.UserPrincipalName -eq $targetUserUPN}
                    
                    if ($existingMembers) {
                        Write-ColorOutput "  ✓ User is already a member of: $roleName" "Green"
                    } else {
                        if ($WhatIf) {
                            Write-ColorOutput "  [WhatIf] Would add user to Azure AD role: $roleName" "Yellow"
                        } else {
                            try {
                                Add-AzureADDirectoryRoleMember -ObjectId $role.ObjectId -RefObjectId $user.ObjectId -ErrorAction Stop
                                Write-ColorOutput "  ✓ Successfully added user to Azure AD role: $roleName" "Green"
                            } catch {
                                Write-ColorOutput "  ✗ Failed to add user to Azure AD role $roleName`: $($_.Exception.Message)" "Red"
                            }
                        }
                    }
                }
            } catch {
                Write-ColorOutput "  ✗ Error processing Azure AD role $roleName`: $($_.Exception.Message)" "Red"
            }
        }
    } catch {
        Write-ColorOutput "Error getting Azure AD user: $($_.Exception.Message)" "Red"
    }
}

# Grant Exchange Online admin roles
if (-not $SkipExchange) {
    Write-ColorOutput "`n=== Granting Exchange Online Admin Roles ===" "Cyan"
    
    foreach ($roleName in $exchangeRoles) {
        try {
            Write-ColorOutput "Processing Exchange role: $roleName" "Yellow"
            
            # Check if user is already a member
            $existingMembers = Get-RoleGroupMember -Identity $roleName -ErrorAction SilentlyContinue | 
                              Where-Object {$_.PrimarySmtpAddress -eq $targetUser}
            
            if ($existingMembers) {
                Write-ColorOutput "  ✓ User is already a member of: $roleName" "Green"
            } else {
                if ($WhatIf) {
                    Write-ColorOutput "  [WhatIf] Would add user to Exchange role: $roleName" "Yellow"
                } else {
                    try {
                        Add-RoleGroupMember -Identity $roleName -Member $targetUser -ErrorAction Stop
                        Write-ColorOutput "  ✓ Successfully added user to Exchange role: $roleName" "Green"
                    } catch {
                        Write-ColorOutput "  ✗ Failed to add user to Exchange role $roleName`: $($_.Exception.Message)" "Red"
                    }
                }
            }
        } catch {
            Write-ColorOutput "  ✗ Error processing Exchange role $roleName`: $($_.Exception.Message)" "Red"
        }
    }
}

# Create custom management scope if needed
if (-not $SkipExchange) {
    Write-ColorOutput "`n=== Creating Custom Management Scope ===" "Cyan"
    
    $scopeName = "iBridge-EmailPolicy-Management"
    
    try {
        $existingScope = Get-ManagementScope -Identity $scopeName -ErrorAction SilentlyContinue
        if ($existingScope) {
            Write-ColorOutput "✓ Management scope already exists: $scopeName" "Green"
        } else {
            if ($WhatIf) {
                Write-ColorOutput "[WhatIf] Would create management scope: $scopeName" "Yellow"
            } else {
                try {
                    New-ManagementScope -Name $scopeName -RecipientRestrictionFilter "RecipientType -eq 'MailUniversalDistributionGroup' -or RecipientType -eq 'MailUniversalSecurityGroup' -or RecipientType -eq 'SharedMailbox'" -ErrorAction Stop
                    Write-ColorOutput "✓ Created management scope: $scopeName" "Green"
                    
                    # Assign the scope to the user
                    New-ManagementRoleAssignment -Role "Distribution Groups" -User $targetUser -CustomRecipientWriteScope $scopeName -ErrorAction Stop
                    Write-ColorOutput "✓ Assigned management scope to user" "Green"
                } catch {
                    Write-ColorOutput "✗ Failed to create management scope: $($_.Exception.Message)" "Red"
                }
            }
        }
    } catch {
        Write-ColorOutput "Error checking management scope: $($_.Exception.Message)" "Red"
    }
}

# Summary and next steps
Write-ColorOutput "`n=== Summary ===" "Green"
if ($WhatIf) {
    Write-ColorOutput "WhatIf mode completed. Review the output above to see what changes would be made." "Yellow"
    Write-ColorOutput "Run the script without -WhatIf to apply the changes." "Yellow"
} else {
    Write-ColorOutput "Comprehensive admin permissions setup completed." "Green"
    Write-ColorOutput "Wait 5-10 minutes for permissions to propagate across Microsoft 365." "Yellow"
}

Write-ColorOutput "`nNext steps:" "Cyan"
Write-ColorOutput "1. Wait 5-10 minutes for permissions to propagate" "White"
Write-ColorOutput "2. Run Check-AdminPermissions.ps1 to verify permissions" "White"
Write-ColorOutput "3. Try Grant-AdminPermissions.ps1 for Exchange-specific permissions" "White"
Write-ColorOutput "4. Run Apply-EmailPolicies.ps1 to apply email policies" "White"
Write-ColorOutput "5. Run Verify-Policies.ps1 to confirm policy application" "White"

Write-ColorOutput "`nIf you still encounter 'write scope' errors:" "Yellow"
Write-ColorOutput "- You may need Global Administrator to grant these permissions" "White"
Write-ColorOutput "- Or work with your current Global Administrator to run these scripts" "White"
