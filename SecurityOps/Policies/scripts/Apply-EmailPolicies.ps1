# Email Policy Implementation Script
param([switch]$WhatIf = $false)

# Load configuration
$config = Get-Content ".\config\email-config.json" | ConvertFrom-Json

Write-Host "=== iBridge Email Policy Implementation ===" -ForegroundColor Cyan
Write-Host "WhatIf Mode: $WhatIf" -ForegroundColor $(if($WhatIf){"Yellow"}else{"Red"})

# Check Exchange Online connection
try {
    # First try to import the module
    Import-Module ExchangeOnlineManagement -Force -ErrorAction Stop
    
    # Try to get connection information
    $connection = Get-ConnectionInformation -ErrorAction SilentlyContinue
    
    if ($connection -and $connection.State -eq "Connected") {
        Write-Host "✅ Connected to Exchange Online as: $($connection.UserPrincipalName)" -ForegroundColor Green
    } else {
        Write-Host "🔌 Not connected to Exchange Online. Attempting to connect..." -ForegroundColor Yellow
        Connect-ExchangeOnline -ErrorAction Stop
        
        # Verify connection
        $connection = Get-ConnectionInformation -ErrorAction Stop
        if ($connection.State -eq "Connected") {
            Write-Host "✅ Successfully connected to Exchange Online as: $($connection.UserPrincipalName)" -ForegroundColor Green
        } else {
            throw "Failed to establish connection"
        }
    }
}
catch {
    Write-Host "❌ Failed to connect to Exchange Online: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure you have proper permissions and try again." -ForegroundColor Red
    exit 1
}

Write-Host "`n--- Configuration Summary ---" -ForegroundColor Magenta
Write-Host "📧 Groups to configure: $($config.DistributionGroups.Count)" -ForegroundColor White
Write-Host "👥 Authorized users: $($config.AuthorizedUsers.Count)" -ForegroundColor White

foreach ($group in $config.DistributionGroups) {
    Write-Host "`n🔧 Configuring: $($group.DisplayName) ($($group.EmailAddress))" -ForegroundColor Yellow
    
    try {
        # Check if group exists
        $distributionGroup = Get-DistributionGroup -Identity $group.EmailAddress -ErrorAction Stop
        Write-Host "   ✅ Group found: $($distributionGroup.DisplayName)" -ForegroundColor Green
        
        # Show current configuration
        Write-Host "   📋 Current settings:" -ForegroundColor Cyan
        Write-Host "      - Moderation Enabled: $($distributionGroup.ModerationEnabled)" -ForegroundColor Gray
        Write-Host "      - Current Moderators: $($distributionGroup.ModeratedBy.Count)" -ForegroundColor Gray
        
        if ($WhatIf) {
            Write-Host "   🔄 Would configure:" -ForegroundColor Yellow
            Write-Host "      ✓ Enable moderation" -ForegroundColor Gray
            Write-Host "      ✓ Set moderators to authorized users" -ForegroundColor Gray
            Write-Host "      ✓ Set moderation notifications to 'Never'" -ForegroundColor Gray
        } else {
            Write-Host "   🔄 Applying configuration..." -ForegroundColor Yellow
            
            # Validate authorized users exist before setting as moderators
            $validModerators = @()
            foreach ($user in $config.AuthorizedUsers) {
                try {
                    $recipient = Get-Recipient -Identity $user -ErrorAction Stop
                    
                    # Check if this recipient can be used as a moderator
                    if ($recipient.RecipientTypeDetails -eq "GroupMailbox") {
                        Write-Host "      ⚠️  Skipping Office 365 Group (cannot be moderator): $user" -ForegroundColor Yellow
                    } elseif ($recipient.RecipientType -eq "MailUniversalDistributionGroup" -and $recipient.RecipientTypeDetails -eq "GroupMailbox") {
                        Write-Host "      ⚠️  Skipping Office 365 Group (cannot be moderator): $user" -ForegroundColor Yellow
                    } else {
                        $validModerators += $user
                        Write-Host "      ✓ Validated moderator: $user ($($recipient.RecipientTypeDetails))" -ForegroundColor Green
                    }
                }
                catch {
                    Write-Host "      ⚠️  Skipping invalid moderator: $user ($($_.Exception.Message))" -ForegroundColor Yellow
                }
            }
            
            if ($validModerators.Count -eq 0) {
                Write-Host "      ❌ No valid moderators found! Skipping moderation setup." -ForegroundColor Red
                continue
            }
            
            # Enable moderation and set moderators
            Set-DistributionGroup -Identity $group.EmailAddress -ModerationEnabled $true -ModeratedBy $validModerators -SendModerationNotifications Never
            Write-Host "      ✅ Moderation enabled with $($validModerators.Count) moderators" -ForegroundColor Green
            Write-Host "      ✅ Notification policy set to 'Never'" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "   ❌ Error configuring group: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n--- Summary ---" -ForegroundColor Magenta
if ($WhatIf) {
    Write-Host "✅ This was a WhatIf run - no changes were made" -ForegroundColor Yellow
    Write-Host "🔄 To apply changes, run without -WhatIf parameter" -ForegroundColor Cyan
} else {
    Write-Host "✅ Email policy configuration completed!" -ForegroundColor Green
    Write-Host "📧 Email restrictions are now active" -ForegroundColor Green
    Write-Host "👥 Only authorized users can send to configured groups" -ForegroundColor Green
}

Write-Host "`n--- Next Steps ---" -ForegroundColor Magenta
Write-Host "1. Test sending an email from an authorized user" -ForegroundColor White
Write-Host "2. Test sending an email from an unauthorized user (should be rejected)" -ForegroundColor White
Write-Host "3. Run verification script to confirm settings" -ForegroundColor White
