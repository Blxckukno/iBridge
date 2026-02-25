# Connect to Exchange Online if not already connected
try {
    $null = Get-EXOMailbox -ResultSize 1
    Write-Host "Already connected to Exchange Online" -ForegroundColor Green
} catch {
    Write-Host "Connecting to Exchange Online..."
    Connect-ExchangeOnline
}

$outputPath = Join-Path $PSScriptRoot "..\..\..\Reports"
$reportDate = Get-Date -Format "yyyyMMdd-HHmmss"
$csvPath = Join-Path $outputPath "IT-Impact-Report-Data-$reportDate.csv"

# Create output directory if it doesn't exist
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

Write-Host "`nChecking for regular mailboxes..."
$regularMailboxes = Get-EXOMailbox -ResultSize Unlimited
Write-Host "Found $($regularMailboxes.Count) regular mailboxes"

Write-Host "`nChecking for shared mailboxes..."
$sharedMailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails SharedMailbox
Write-Host "Found $($sharedMailboxes.Count) shared mailboxes"

Write-Host "`nChecking for distribution groups..."
$distributionGroups = Get-DistributionGroup -ResultSize Unlimited
Write-Host "Found $($distributionGroups.Count) distribution groups"

# Combined search across all types
$allMailboxes = @($regularMailboxes) + @($sharedMailboxes)
$searchPattern = "support@smartz-solutions.com"

Write-Host "`nSearching for '$searchPattern' across all mailbox types..."

# Search in mailboxes
$foundMailboxes = $allMailboxes | Where-Object { 
    $_.PrimarySmtpAddress -like "*$searchPattern*" -or
    $_.EmailAddresses -like "*$searchPattern*"
}

Write-Host "`nMailboxes found matching pattern:"
$foundMailboxes | Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails |
    Format-Table -AutoSize

# Search in distribution groups
$foundGroups = $distributionGroups | Where-Object { 
    $_.PrimarySmtpAddress -like "*$searchPattern*" -or
    $_.EmailAddresses -like "*$searchPattern*"
}

Write-Host "`nDistribution groups found matching pattern:"
$foundGroups | Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails |
    Format-Table -AutoSize

# Search for any recipient
Write-Host "`nSearching for any recipient matching pattern..."
$recipients = Get-Recipient -ResultSize Unlimited -Filter "EmailAddresses -like '*$searchPattern*'"
Write-Host "Recipients found:"
$recipients | Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails |
    Format-Table -AutoSize

if ($recipients) {
    Write-Host "`nChecking permissions for found recipients..."
    foreach ($recipient in $recipients) {
        Write-Host "`nPermissions for $($recipient.PrimarySmtpAddress):"
        try {
            Get-EXOMailboxPermission -Identity $recipient.Identity |
                Where-Object { $_.User -notlike "NT AUTHORITY\*" } |
                Format-Table User, AccessRights -AutoSize
        }
        catch {
            Write-Host "Error getting permissions: $_" -ForegroundColor Red
        }
    }
}
