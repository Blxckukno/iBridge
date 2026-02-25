# First check our current mailbox to see if we have any emails from support
Write-Host "Checking current mailbox for support emails..."

$currentMailbox = Get-EXOMailbox -Identity $env:USERNAME
Write-Host "Current mailbox: $($currentMailbox.PrimarySmtpAddress)"

# Try to find any folders containing support emails
Write-Host "`nChecking mailbox folders..."
$folders = Get-EXOMailboxFolderStatistics -Identity $currentMailbox.Identity
$folders | Where-Object { $_.ItemsInFolder -gt 0 } | 
    Select-Object FolderPath, ItemsInFolder |
    Format-Table -AutoSize

Write-Host "`nChecking all mailboxes for potential access to support emails..."
$allMailboxes = Get-EXOMailbox -ResultSize Unlimited |
    Where-Object { $_.RecipientTypeDetails -in @('UserMailbox', 'SharedMailbox') }

foreach ($mailbox in $allMailboxes) {
    Write-Host "`nChecking mailbox: $($mailbox.PrimarySmtpAddress)"
    try {
        $stats = Get-EXOMailboxStatistics -Identity $mailbox.Identity -ErrorAction Stop
        Write-Host "Total items: $($stats.ItemCount)"
        
        # Check permissions
        $permissions = Get-EXOMailboxPermission -Identity $mailbox.Identity |
            Where-Object { $_.User -notlike "NT AUTHORITY\*" }
        
        if ($permissions) {
            Write-Host "Permissions:"
            $permissions | Select-Object User, AccessRights | Format-Table -AutoSize
        }
    }
    catch {
        Write-Host "Error accessing mailbox: $_" -ForegroundColor Red
    }
}
