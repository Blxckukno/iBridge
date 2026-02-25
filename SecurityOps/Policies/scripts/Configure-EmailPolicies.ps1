# Exchange Online Configuration Script
# This script configures email policies to restrict response access to shared mailboxes

param(
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = ".\config\email-config.json"
)

# Import configuration
if (Test-Path $ConfigFile) {
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    Write-Host "Configuration loaded from $ConfigFile" -ForegroundColor Green
} else {
    Write-Error "Configuration file not found: $ConfigFile"
    exit 1
}

# Function to create mail flow rules
function New-MailFlowRule {
    param(
        [string]$Name,
        [string]$Description,
        [array]$FromAddresses,
        [array]$AuthorizedUsers,
        [switch]$WhatIf
    )
    
    Write-Host "Creating mail flow rule: $Name" -ForegroundColor Yellow
    
    $ruleParams = @{
        Name = $Name
        Description = $Description
        From = $FromAddresses
        ExceptIfFrom = $AuthorizedUsers
        RejectMessageReasonText = "You are not authorized to send emails from this address. Only designated personnel can send from shared mailboxes."
        RejectMessageEnhancedStatusCode = "5.7.1"
        WhatIf = $WhatIf
    }
    
    try {
        New-TransportRule @ruleParams
        Write-Host "✓ Rule '$Name' created successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create rule '$Name': $($_.Exception.Message)"
    }
}

# Function to configure shared mailbox permissions
function Set-SharedMailboxPermissions {
    param(
        [string]$MailboxIdentity,
        [array]$AuthorizedUsers,
        [array]$ViewOnlyUsers,
        [switch]$WhatIf
    )
    
    Write-Host "Configuring permissions for mailbox: $MailboxIdentity" -ForegroundColor Yellow
    
    try {
        # Remove existing Send As permissions
        Get-RecipientPermission -Identity $MailboxIdentity | Where-Object {$_.Trustee -ne "NT AUTHORITY\SELF"} | ForEach-Object {
            if (-not $WhatIf) {
                Remove-RecipientPermission -Identity $MailboxIdentity -Trustee $_.Trustee -AccessRights SendAs -Confirm:$false
            }
            Write-Host "  Removed SendAs permission for: $($_.Trustee)" -ForegroundColor Gray
        }
        
        # Add Send As permissions for authorized users
        foreach ($user in $AuthorizedUsers) {
            if (-not $WhatIf) {
                Add-RecipientPermission -Identity $MailboxIdentity -Trustee $user -AccessRights SendAs -Confirm:$false
            }
            Write-Host "  ✓ Added SendAs permission for: $user" -ForegroundColor Green
        }
        
        # Set mailbox permissions (Full Access for authorized, Read for others)
        foreach ($user in $AuthorizedUsers) {
            if (-not $WhatIf) {
                Add-MailboxPermission -Identity $MailboxIdentity -User $user -AccessRights FullAccess -InheritanceType All
            }
            Write-Host "  ✓ Added FullAccess permission for: $user" -ForegroundColor Green
        }
        
        # Add read-only access for view-only users (if specified)
        foreach ($user in $ViewOnlyUsers) {
            if (-not $WhatIf) {
                Add-MailboxPermission -Identity $MailboxIdentity -User $user -AccessRights ReadPermission -InheritanceType All
            }
            Write-Host "  ✓ Added ReadPermission for: $user" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Error "Failed to configure permissions for '$MailboxIdentity': $($_.Exception.Message)"
    }
}

# Main execution
Write-Host "Starting Exchange Online Email Policy Configuration" -ForegroundColor Cyan
Write-Host "WhatIf Mode: $WhatIf" -ForegroundColor $(if($WhatIf){"Yellow"}else{"Green"})

# Check if connected to Exchange Online
try {
    Get-OrganizationConfig | Out-Null
    Write-Host "✓ Connected to Exchange Online" -ForegroundColor Green
}
catch {
    Write-Error "Not connected to Exchange Online. Please run Connect-ExchangeOnline.ps1 first."
    exit 1
}

# Process each shared mailbox
foreach ($mailbox in $config.SharedMailboxes) {
    Write-Host "`n--- Processing Mailbox: $($mailbox.DisplayName) ---" -ForegroundColor Magenta
    
    # Configure mailbox permissions
    Set-SharedMailboxPermissions -MailboxIdentity $mailbox.EmailAddress -AuthorizedUsers $config.AuthorizedUsers -WhatIf:$WhatIf
    
    # Create mail flow rule to prevent unauthorized sending
    $ruleName = "Restrict-$($mailbox.DisplayName.Replace(' ', ''))-Sending"
    $ruleDescription = "Prevents unauthorized users from sending emails as $($mailbox.DisplayName)"
    
    New-MailFlowRule -Name $ruleName -Description $ruleDescription -FromAddresses $mailbox.EmailAddress -AuthorizedUsers $config.AuthorizedUsers -WhatIf:$WhatIf
}

# Create distribution group restrictions if specified
if ($config.DistributionGroups) {
    Write-Host "`n--- Processing Distribution Groups ---" -ForegroundColor Magenta
    
    foreach ($group in $config.DistributionGroups) {
        Write-Host "Configuring distribution group: $($group.DisplayName)" -ForegroundColor Yellow
        
        try {
            if (-not $WhatIf) {
                Set-DistributionGroup -Identity $group.EmailAddress -ModerationEnabled $true -ModeratedBy $config.AuthorizedUsers
                Set-DistributionGroup -Identity $group.EmailAddress -SendModerationNotifications Never
            }
            Write-Host "  ✓ Moderation enabled for group: $($group.DisplayName)" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to configure group '$($group.DisplayName)': $($_.Exception.Message)"
        }
    }
}

Write-Host "`n=== Configuration Complete ===" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "This was a WhatIf run. No changes were made." -ForegroundColor Yellow
    Write-Host "To apply changes, run: .\Configure-EmailPolicies.ps1" -ForegroundColor Yellow
} else {
    Write-Host "Email policies have been configured successfully!" -ForegroundColor Green
    Write-Host "Run .\Verify-Policies.ps1 to verify the configuration." -ForegroundColor Cyan
}
