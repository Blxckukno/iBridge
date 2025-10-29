# Connect to Exchange Online if not already connected
try {
    $null = Get-EXOMailbox -ResultSize 1
    Write-Host "Already connected to Exchange Online" -ForegroundColor Green
} catch {
    Write-Host "Connecting to Exchange Online..."
    Connect-ExchangeOnline
}

# Parameters for report generation
$outputPath = Join-Path $PSScriptRoot "..\..\..\Reports"
$reportDate = Get-Date -Format "yyyyMMdd-HHmmss"
$csvPath = Join-Path $outputPath "IT-Impact-Report-Data-$reportDate.csv"

# Create output directory if it doesn't exist
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

# Get all mailboxes first
Write-Host "Fetching all mailboxes..."
$allMailboxes = Get-EXOMailbox -ResultSize Unlimited
Write-Host "Found $($allMailboxes.Count) mailboxes"

# Filter for relevant mailboxes
$supportMailboxes = $allMailboxes | Where-Object { 
    $_.EmailAddresses -match "smtp:support@smartz-solutions.com" -or
    $_.PrimarySmtpAddress -eq "support@smartz-solutions.com"
}

Write-Host "Found $($supportMailboxes.Count) relevant mailboxes"

$reportData = @()

foreach ($mailbox in $supportMailboxes) {
    Write-Host "Processing mailbox: $($mailbox.PrimarySmtpAddress)"
    
    # Get folder statistics
    try {
        $stats = Get-EXOMailboxFolderStatistics -Identity $mailbox.Identity |
            Where-Object { $_.FolderPath -eq "/Inbox" }
        
        if ($stats) {
            $reportData += [PSCustomObject]@{
                Mailbox = $mailbox.PrimarySmtpAddress
                DisplayName = $mailbox.DisplayName
                ItemCount = $stats.ItemsInFolder
                Size = $stats.FolderSize
                LastModifiedTime = $stats.LastModifiedTime
            }
        }
    }
    catch {
        Write-Host "Error processing mailbox $($mailbox.PrimarySmtpAddress): $_" -ForegroundColor Red
    }
}

# Export data to CSV
if ($reportData.Count -gt 0) {
    $reportData | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "CSV data saved to: $csvPath" -ForegroundColor Green
} else {
    Write-Host "No data found to export" -ForegroundColor Yellow
}

# Display summary
Write-Host "`nSummary:"
Write-Host "-----------------"
Write-Host "Total Mailboxes Found: $($supportMailboxes.Count)"
Write-Host "Total Mailboxes Processed Successfully: $($reportData.Count)"
$totalItems = ($reportData | Measure-Object -Property ItemCount -Sum).Sum
Write-Host "Total Items Found: $totalItems"
if ($reportData.Count -gt 0) {
    $latestModified = ($reportData | Measure-Object -Property LastModifiedTime -Maximum).Maximum
    Write-Host "Latest Activity: $latestModified"
}

# Additional mailbox permissions check
Write-Host "`nChecking mailbox permissions..."
foreach ($mailbox in $supportMailboxes) {
    Write-Host "`nPermissions for $($mailbox.PrimarySmtpAddress):"
    Get-EXOMailboxPermission -Identity $mailbox.Identity |
        Where-Object { $_.User -notlike "NT AUTHORITY\*" } |
        Format-Table User, AccessRights -AutoSize
}
