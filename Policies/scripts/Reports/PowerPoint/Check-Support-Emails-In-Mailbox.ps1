# Get current user's mailbox
Write-Host "Checking current mailbox..."
$currentMailbox = Get-EXOMailbox -Identity $env:USERNAME
Write-Host "Current mailbox: $($currentMailbox.PrimarySmtpAddress)"

# Get basic statistics
Write-Host "`nGetting mailbox statistics..."
try {
    $stats = Get-EXOMailboxStatistics -Identity $currentMailbox.Identity
    Write-Host "Total items in mailbox: $($stats.ItemCount)"
    Write-Host "Total size: $($stats.TotalItemSize)"
} catch {
    Write-Host "Error getting statistics: $_" -ForegroundColor Red
}

Write-Host "`nLooking for support@smartz-solutions.com in your mailbox..."
Write-Host "This might take a few minutes..."

# List all folders
Write-Host "`nChecking mailbox folders (this helps us understand where to look)..."
try {
    $folders = Get-EXOMailboxFolder -Identity "$($currentMailbox.Identity):" |
        Select-Object Name, FolderPath
    Write-Host "Available folders:"
    $folders | Format-Table -AutoSize
} catch {
    Write-Host "Error listing folders: $_" -ForegroundColor Red
}

Write-Host "`nNOTE: Based on the results, you may need to:"
Write-Host "1. Check if you have the correct email address for support"
Write-Host "2. Request additional permissions if needed"
Write-Host "3. Check if the support emails are stored in a different mailbox"
Write-Host "4. Verify if there are any mail flow rules affecting these emails"
