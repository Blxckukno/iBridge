# Simple mailbox list script
Write-Host "Connecting to Exchange Online..."
Connect-ExchangeOnline

Write-Host "`nGetting mailboxes..."
$mailboxes = Get-EXOMailbox -ResultSize 50 | Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails

Write-Host "`nAvailable Mailboxes:"
$mailboxes | Format-Table -AutoSize
