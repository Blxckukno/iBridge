# Simple Email Policy Configuration Script
param([switch]$WhatIf = $false)

# Load configuration
$config = Get-Content ".\config\email-config.json" | ConvertFrom-Json

Write-Host "=== Email Policy Configuration ===" -ForegroundColor Cyan
Write-Host "WhatIf Mode: $WhatIf" -ForegroundColor Yellow

# Check connection
try {
    $org = Get-OrganizationConfig
    Write-Host "✓ Connected to: $($org.DisplayName)" -ForegroundColor Green
}
catch {
    Write-Error "❌ Not connected to Exchange Online. Please run Connect-ExchangeOnline first."
    exit 1
}

# Display what will be configured
Write-Host "`n--- Shared Mailboxes to Restrict ---" -ForegroundColor Magenta
foreach ($mailbox in $config.SharedMailboxes) {
    Write-Host "  • $($mailbox.DisplayName): $($mailbox.EmailAddress)" -ForegroundColor White
}

Write-Host "`n--- Authorized Users ---" -ForegroundColor Magenta
foreach ($user in $config.AuthorizedUsers) {
    Write-Host "  • $user" -ForegroundColor White
}

Write-Host "`n--- Actions that will be performed ---" -ForegroundColor Magenta
foreach ($mailbox in $config.SharedMailboxes) {
    Write-Host "For $($mailbox.DisplayName):" -ForegroundColor Yellow
    Write-Host "  1. Remove existing Send As permissions" -ForegroundColor Gray
    Write-Host "  2. Add Send As permissions for authorized users" -ForegroundColor Gray
    Write-Host "  3. Create transport rule to block unauthorized sending" -ForegroundColor Gray
    Write-Host "  4. Configure mailbox permissions" -ForegroundColor Gray
}

if ($WhatIf) {
    Write-Host "`n✅ This was a WhatIf run. No changes were made." -ForegroundColor Yellow
} else {
    Write-Host "`n⚠️  This would apply actual changes!" -ForegroundColor Red
    Write-Host "Run with -WhatIf first to test." -ForegroundColor Red
}
