# Remove Email Policy Configuration
# This script removes the email policies and restores default settings

param(
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = ".\config\email-config.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

Write-Host "Email Policy Removal Script" -ForegroundColor Red
Write-Host "This script will remove all configured email restrictions!" -ForegroundColor Yellow

if (-not $Force) {
    $confirm = Read-Host "Are you sure you want to proceed? (Type 'YES' to continue)"
    if ($confirm -ne "YES") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Import configuration
if (Test-Path $ConfigFile) {
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    Write-Host "Configuration loaded from $ConfigFile" -ForegroundColor Green
} else {
    Write-Error "Configuration file not found: $ConfigFile"
    exit 1
}

# Check Exchange Online connection
try {
    Get-OrganizationConfig | Out-Null
    Write-Host "✓ Connected to Exchange Online" -ForegroundColor Green
}
catch {
    Write-Error "Not connected to Exchange Online. Please run Connect-ExchangeOnline.ps1 first."
    exit 1
}

# Function to remove transport rules
function Remove-MailFlowRules {
    param(
        [array]$SharedMailboxes,
        [switch]$WhatIf
    )
    
    Write-Host "`n--- Removing Transport Rules ---" -ForegroundColor Magenta
    
    foreach ($mailbox in $SharedMailboxes) {
        $ruleName = "Restrict-$($mailbox.DisplayName.Replace(' ', ''))-Sending"
        
        try {
            $rule = Get-TransportRule -Identity $ruleName -ErrorAction Stop
            
            if ($WhatIf) {
                Write-Host "Would remove transport rule: $ruleName" -ForegroundColor Yellow
            } else {
                Remove-TransportRule -Identity $ruleName -Confirm:$false
                Write-Host "✓ Removed transport rule: $ruleName" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Transport rule not found: $ruleName" -ForegroundColor Gray
        }
    }
}

# Function to restore distribution group settings
function Restore-DistributionGroups {
    param(
        [array]$DistributionGroups,
        [switch]$WhatIf
    )
    
    if (-not $DistributionGroups) { return }
    
    Write-Host "`n--- Restoring Distribution Groups ---" -ForegroundColor Magenta
    
    foreach ($group in $DistributionGroups) {
        try {
            $distributionGroup = Get-DistributionGroup -Identity $group.EmailAddress -ErrorAction Stop
            
            if ($distributionGroup.ModerationEnabled) {
                if ($WhatIf) {
                    Write-Host "Would disable moderation for: $($group.DisplayName)" -ForegroundColor Yellow
                } else {
                    Set-DistributionGroup -Identity $group.EmailAddress -ModerationEnabled $false
                    Write-Host "✓ Disabled moderation for: $($group.DisplayName)" -ForegroundColor Green
                }
            } else {
                Write-Host "Moderation already disabled for: $($group.DisplayName)" -ForegroundColor Gray
            }
        }
        catch {
            Write-Warning "Failed to process group '$($group.DisplayName)': $($_.Exception.Message)"
        }
    }
}

# Function to remove specific permissions (optional - use with caution)
function Remove-SpecificPermissions {
    param(
        [array]$SharedMailboxes,
        [array]$AuthorizedUsers,
        [switch]$WhatIf
    )
    
    Write-Host "`n--- Removing Specific Permissions ---" -ForegroundColor Magenta
    Write-Host "WARNING: This will remove Send As permissions for authorized users!" -ForegroundColor Red
    
    if (-not $Force) {
        $confirm = Read-Host "Remove Send As permissions for authorized users? (Type 'YES' to continue)"
        if ($confirm -ne "YES") {
            Write-Host "Skipping permission removal." -ForegroundColor Yellow
            return
        }
    }
    
    foreach ($mailbox in $SharedMailboxes) {
        Write-Host "Processing mailbox: $($mailbox.DisplayName)" -ForegroundColor Yellow
        
        foreach ($user in $AuthorizedUsers) {
            try {
                $permission = Get-RecipientPermission -Identity $mailbox.EmailAddress -Trustee $user -ErrorAction Stop
                
                if ($WhatIf) {
                    Write-Host "  Would remove SendAs permission for: $user" -ForegroundColor Yellow
                } else {
                    Remove-RecipientPermission -Identity $mailbox.EmailAddress -Trustee $user -AccessRights SendAs -Confirm:$false
                    Write-Host "  ✓ Removed SendAs permission for: $user" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "  No SendAs permission found for: $user" -ForegroundColor Gray
            }
        }
    }
}

# Main execution
Write-Host "`nStarting Email Policy Removal" -ForegroundColor Cyan
Write-Host "WhatIf Mode: $WhatIf" -ForegroundColor $(if($WhatIf){"Yellow"}else{"Red"})

# Remove transport rules
Remove-MailFlowRules -SharedMailboxes $config.SharedMailboxes -WhatIf:$WhatIf

# Restore distribution groups
Restore-DistributionGroups -DistributionGroups $config.DistributionGroups -WhatIf:$WhatIf

# Optional: Remove specific permissions
Write-Host "`n--- Optional: Permission Removal ---" -ForegroundColor Magenta
$removePermissions = Read-Host "Remove Send As permissions for authorized users? (y/N)"
if ($removePermissions -eq 'y' -or $removePermissions -eq 'Y') {
    Remove-SpecificPermissions -SharedMailboxes $config.SharedMailboxes -AuthorizedUsers $config.AuthorizedUsers -WhatIf:$WhatIf
}

Write-Host "`n=== Removal Complete ===" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "This was a WhatIf run. No changes were made." -ForegroundColor Yellow
    Write-Host "To apply changes, run: .\Remove-EmailPolicies.ps1 -Force" -ForegroundColor Yellow
} else {
    Write-Host "Email policies have been removed!" -ForegroundColor Green
    Write-Host "Run .\Verify-Policies.ps1 to verify the removal." -ForegroundColor Cyan
    Write-Host "`nIMPORTANT: Your shared mailboxes are now unrestricted!" -ForegroundColor Red
}
