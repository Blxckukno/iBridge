# Comprehensive M365 Recipient Audit Script
# This script audits all users, groups, and recipients in the tenant
# and compares them against the authorized list

param(
    [switch]$ExportToFile = $false,
    [string]$OutputPath = ".\logs\M365-Audit-Report.json"
)

Write-Host "=== Microsoft 365 Comprehensive Recipient Audit ===" -ForegroundColor Cyan
Write-Host "$(Get-Date)" -ForegroundColor Gray

# Load configuration to get authorized users
try {
    $config = Get-Content ".\config\email-config.json" | ConvertFrom-Json
    Write-Host "✅ Configuration loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to load configuration: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

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

Write-Host "`n--- Gathering All Recipients ---" -ForegroundColor Magenta

# Initialize collections
$auditResults = @{
    Timestamp = Get-Date
    AuthorizedUsers = $config.AuthorizedUsers
    AllRecipients = @()
    UserMailboxes = @()
    SharedMailboxes = @()
    DistributionGroups = @()
    DistributionLists = @()
    SecurityGroups = @()
    DynamicDistributionGroups = @()
    OfficeGroups = @()
    Contacts = @()
    PublicFolders = @()
    AuthorizedFound = @()
    UnauthorizedRecipients = @()
    Summary = @{}
}

Write-Host "🔍 Collecting all recipients..." -ForegroundColor Yellow

try {
    # Get all recipients (this includes everything)
    $allRecipients = Get-Recipient -ResultSize Unlimited | Sort-Object DisplayName
    $auditResults.AllRecipients = $allRecipients | Select-Object DisplayName, PrimarySmtpAddress, RecipientType, RecipientTypeDetails, @{Name='EmailAddresses';Expression={$_.EmailAddresses -join '; '}}
    
    Write-Host "   ✅ Total recipients found: $($allRecipients.Count)" -ForegroundColor Green

    # Get user mailboxes
    Write-Host "🔍 Collecting user mailboxes..." -ForegroundColor Yellow
    $userMailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited | Sort-Object DisplayName
    $auditResults.UserMailboxes = $userMailboxes | Select-Object DisplayName, PrimarySmtpAddress, UserPrincipalName, @{Name='EmailAddresses';Expression={$_.EmailAddresses -join '; '}}
    Write-Host "   ✅ User mailboxes found: $($userMailboxes.Count)" -ForegroundColor Green

    # Get shared mailboxes
    Write-Host "🔍 Collecting shared mailboxes..." -ForegroundColor Yellow
    $sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited | Sort-Object DisplayName
    $auditResults.SharedMailboxes = $sharedMailboxes | Select-Object DisplayName, PrimarySmtpAddress, @{Name='EmailAddresses';Expression={$_.EmailAddresses -join '; '}}
    Write-Host "   ✅ Shared mailboxes found: $($sharedMailboxes.Count)" -ForegroundColor Green

    # Get distribution groups
    Write-Host "🔍 Collecting distribution groups..." -ForegroundColor Yellow
    $distributionGroups = Get-DistributionGroup -ResultSize Unlimited | Sort-Object DisplayName
    $auditResults.DistributionGroups = $distributionGroups | Select-Object DisplayName, PrimarySmtpAddress, @{Name='EmailAddresses';Expression={$_.EmailAddresses -join '; '}}, ModerationEnabled, @{Name='ModeratedBy';Expression={$_.ModeratedBy -join '; '}}
    Write-Host "   ✅ Distribution groups found: $($distributionGroups.Count)" -ForegroundColor Green

    # Get dynamic distribution groups
    Write-Host "🔍 Collecting dynamic distribution groups..." -ForegroundColor Yellow
    try {
        $dynamicGroups = Get-DynamicDistributionGroup -ResultSize Unlimited | Sort-Object DisplayName
        $auditResults.DynamicDistributionGroups = $dynamicGroups | Select-Object DisplayName, PrimarySmtpAddress, @{Name='EmailAddresses';Expression={$_.EmailAddresses -join '; '}}
        Write-Host "   ✅ Dynamic distribution groups found: $($dynamicGroups.Count)" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  Dynamic distribution groups not available or access denied" -ForegroundColor Yellow
        $auditResults.DynamicDistributionGroups = @()
    }

    # Get security groups (mail-enabled)
    Write-Host "🔍 Collecting mail-enabled security groups..." -ForegroundColor Yellow
    try {
        $securityGroups = Get-DistributionGroup -RecipientTypeDetails MailUniversalSecurityGroup -ResultSize Unlimited | Sort-Object DisplayName
        $auditResults.SecurityGroups = $securityGroups | Select-Object DisplayName, PrimarySmtpAddress, @{Name='EmailAddresses';Expression={$_.EmailAddresses -join '; '}}
        Write-Host "   ✅ Mail-enabled security groups found: $($securityGroups.Count)" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  Mail-enabled security groups not available or access denied" -ForegroundColor Yellow
        $auditResults.SecurityGroups = @()
    }

    # Get Office 365 groups
    Write-Host "🔍 Collecting Office 365 groups..." -ForegroundColor Yellow
    try {
        $officeGroups = Get-UnifiedGroup -ResultSize Unlimited | Sort-Object DisplayName
        $auditResults.OfficeGroups = $officeGroups | Select-Object DisplayName, PrimarySmtpAddress, @{Name='EmailAddresses';Expression={$_.EmailAddresses -join '; '}}
        Write-Host "   ✅ Office 365 groups found: $($officeGroups.Count)" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  Office 365 groups not available or access denied" -ForegroundColor Yellow
        $auditResults.OfficeGroups = @()
    }

    # Get mail contacts
    Write-Host "🔍 Collecting mail contacts..." -ForegroundColor Yellow
    try {
        $contacts = Get-MailContact -ResultSize Unlimited | Sort-Object DisplayName
        $auditResults.Contacts = $contacts | Select-Object DisplayName, PrimarySmtpAddress, @{Name='EmailAddresses';Expression={$_.EmailAddresses -join '; '}}
        Write-Host "   ✅ Mail contacts found: $($contacts.Count)" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  Mail contacts not available or access denied" -ForegroundColor Yellow
        $auditResults.Contacts = @()
    }

    # Get public folders
    Write-Host "🔍 Collecting public folders..." -ForegroundColor Yellow
    try {
        $publicFolders = Get-MailPublicFolder -ResultSize Unlimited | Sort-Object DisplayName
        $auditResults.PublicFolders = $publicFolders | Select-Object DisplayName, PrimarySmtpAddress, @{Name='EmailAddresses';Expression={$_.EmailAddresses -join '; '}}
        Write-Host "   ✅ Public folders found: $($publicFolders.Count)" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  Public folders not available or access denied" -ForegroundColor Yellow
        $auditResults.PublicFolders = @()
    }

}
catch {
    Write-Host "❌ Error collecting recipients: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n--- Analyzing Against Authorized List ---" -ForegroundColor Magenta

# Create a list of all email addresses from all recipients
$allEmailAddresses = @()
foreach ($recipient in $allRecipients) {
    $allEmailAddresses += $recipient.PrimarySmtpAddress
    # Also add any additional email addresses
    foreach ($emailAddr in $recipient.EmailAddresses) {
        if ($emailAddr -match "smtp:(.+)") {
            $allEmailAddresses += $matches[1]
        }
    }
}

# Remove duplicates and sort
$allEmailAddresses = $allEmailAddresses | Sort-Object -Unique

# Cross-reference with authorized users
Write-Host "🔍 Cross-referencing with authorized users..." -ForegroundColor Yellow

$authorizedFound = @()
$unauthorizedRecipients = @()

foreach ($emailAddr in $allEmailAddresses) {
    if ($config.AuthorizedUsers -contains $emailAddr) {
        $authorizedFound += $emailAddr
    } else {
        $unauthorizedRecipients += $emailAddr
    }
}

$auditResults.AuthorizedFound = $authorizedFound
$auditResults.UnauthorizedRecipients = $unauthorizedRecipients

# Create summary
$auditResults.Summary = @{
    TotalRecipients = $allRecipients.Count
    TotalEmailAddresses = $allEmailAddresses.Count
    UserMailboxes = $userMailboxes.Count
    SharedMailboxes = $sharedMailboxes.Count
    DistributionGroups = $distributionGroups.Count
    DynamicDistributionGroups = if ($auditResults.DynamicDistributionGroups) { $auditResults.DynamicDistributionGroups.Count } else { 0 }
    SecurityGroups = if ($auditResults.SecurityGroups) { $auditResults.SecurityGroups.Count } else { 0 }
    OfficeGroups = if ($auditResults.OfficeGroups) { $auditResults.OfficeGroups.Count } else { 0 }
    Contacts = if ($auditResults.Contacts) { $auditResults.Contacts.Count } else { 0 }
    PublicFolders = if ($auditResults.PublicFolders) { $auditResults.PublicFolders.Count } else { 0 }
    AuthorizedUsersConfigured = $config.AuthorizedUsers.Count
    AuthorizedUsersFound = $authorizedFound.Count
    UnauthorizedEmailAddresses = $unauthorizedRecipients.Count
}

# Display results
Write-Host "`n=== AUDIT RESULTS ===" -ForegroundColor Cyan

Write-Host "`n--- SUMMARY ---" -ForegroundColor Magenta
Write-Host "📊 Total Recipients: $($auditResults.Summary.TotalRecipients)" -ForegroundColor White
Write-Host "📧 Total Email Addresses: $($auditResults.Summary.TotalEmailAddresses)" -ForegroundColor White
Write-Host "👤 User Mailboxes: $($auditResults.Summary.UserMailboxes)" -ForegroundColor White
Write-Host "🤝 Shared Mailboxes: $($auditResults.Summary.SharedMailboxes)" -ForegroundColor White
Write-Host "👥 Distribution Groups: $($auditResults.Summary.DistributionGroups)" -ForegroundColor White
Write-Host "🔄 Dynamic Distribution Groups: $($auditResults.Summary.DynamicDistributionGroups)" -ForegroundColor White
Write-Host "🛡️  Security Groups: $($auditResults.Summary.SecurityGroups)" -ForegroundColor White
Write-Host "🏢 Office 365 Groups: $($auditResults.Summary.OfficeGroups)" -ForegroundColor White
Write-Host "📞 Contacts: $($auditResults.Summary.Contacts)" -ForegroundColor White
Write-Host "📁 Public Folders: $($auditResults.Summary.PublicFolders)" -ForegroundColor White

Write-Host "`n--- AUTHORIZED USERS ANALYSIS ---" -ForegroundColor Green
Write-Host "✅ Authorized users configured: $($auditResults.Summary.AuthorizedUsersConfigured)" -ForegroundColor Green
Write-Host "✅ Authorized users found in tenant: $($auditResults.Summary.AuthorizedUsersFound)" -ForegroundColor Green

if ($authorizedFound.Count -gt 0) {
    Write-Host "`n📋 AUTHORIZED USERS FOUND IN TENANT:" -ForegroundColor Green
    foreach ($user in $authorizedFound | Sort-Object) {
        Write-Host "   ✅ $user" -ForegroundColor Green
    }
}

# Check for authorized users not found in tenant
$authorizedNotFound = $config.AuthorizedUsers | Where-Object { $_ -notin $authorizedFound }
if ($authorizedNotFound.Count -gt 0) {
    Write-Host "`n⚠️  AUTHORIZED USERS NOT FOUND IN TENANT:" -ForegroundColor Yellow
    foreach ($user in $authorizedNotFound | Sort-Object) {
        Write-Host "   ⚠️  $user" -ForegroundColor Yellow
    }
}

Write-Host "`n--- UNAUTHORIZED RECIPIENTS ---" -ForegroundColor Red
Write-Host "❌ Unauthorized email addresses: $($auditResults.Summary.UnauthorizedEmailAddresses)" -ForegroundColor Red

if ($unauthorizedRecipients.Count -gt 0) {
    Write-Host "`n📋 ALL UNAUTHORIZED EMAIL ADDRESSES:" -ForegroundColor Red
    $counter = 0
    foreach ($email in $unauthorizedRecipients | Sort-Object) {
        $counter++
        Write-Host "   $counter. $email" -ForegroundColor Red
        
        # Show every 20 entries and ask if user wants to continue
        if ($counter % 20 -eq 0 -and $counter -lt $unauthorizedRecipients.Count) {
            Write-Host "`n   [Showing $counter of $($unauthorizedRecipients.Count) unauthorized addresses]" -ForegroundColor Yellow
            $continue = Read-Host "   Continue showing more? (y/n)"
            if ($continue -notmatch '^y') {
                Write-Host "   ... ($($unauthorizedRecipients.Count - $counter) more addresses not shown)" -ForegroundColor Gray
                break
            }
            Write-Host ""
        }
    }
}

# Export to file if requested
if ($ExportToFile) {
    Write-Host "`n--- Exporting Results ---" -ForegroundColor Magenta
    try {
        # Ensure logs directory exists
        if (!(Test-Path ".\logs")) {
            New-Item -ItemType Directory -Path ".\logs" -Force | Out-Null
        }
        
        $auditResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "✅ Audit results exported to: $OutputPath" -ForegroundColor Green
        
        # Also create a summary CSV
        $csvPath = $OutputPath -replace '\.json$', '-Summary.csv'
        $summaryData = @(
            [PSCustomObject]@{Category = "Total Recipients"; Count = $auditResults.Summary.TotalRecipients}
            [PSCustomObject]@{Category = "Total Email Addresses"; Count = $auditResults.Summary.TotalEmailAddresses}
            [PSCustomObject]@{Category = "User Mailboxes"; Count = $auditResults.Summary.UserMailboxes}
            [PSCustomObject]@{Category = "Shared Mailboxes"; Count = $auditResults.Summary.SharedMailboxes}
            [PSCustomObject]@{Category = "Distribution Groups"; Count = $auditResults.Summary.DistributionGroups}
            [PSCustomObject]@{Category = "Dynamic Distribution Groups"; Count = $auditResults.Summary.DynamicDistributionGroups}
            [PSCustomObject]@{Category = "Security Groups"; Count = $auditResults.Summary.SecurityGroups}
            [PSCustomObject]@{Category = "Office 365 Groups"; Count = $auditResults.Summary.OfficeGroups}
            [PSCustomObject]@{Category = "Contacts"; Count = $auditResults.Summary.Contacts}
            [PSCustomObject]@{Category = "Public Folders"; Count = $auditResults.Summary.PublicFolders}
            [PSCustomObject]@{Category = "Authorized Users (Configured)"; Count = $auditResults.Summary.AuthorizedUsersConfigured}
            [PSCustomObject]@{Category = "Authorized Users (Found)"; Count = $auditResults.Summary.AuthorizedUsersFound}
            [PSCustomObject]@{Category = "Unauthorized Email Addresses"; Count = $auditResults.Summary.UnauthorizedEmailAddresses}
        )
        $summaryData | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "✅ Summary exported to: $csvPath" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error exporting results: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== AUDIT COMPLETED ===" -ForegroundColor Cyan
Write-Host "$(Get-Date)" -ForegroundColor Gray

if (!$ExportToFile) {
    Write-Host "`n💡 Tip: Run with -ExportToFile to save detailed results to JSON and CSV files" -ForegroundColor Yellow
}
