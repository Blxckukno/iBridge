# List available mailboxes and their statistics
#Requires -Modules ExchangeOnlineManagement, Microsoft.Graph

function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $(switch($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    })
}

Write-Log "Connecting to Exchange Online..."
try {
    Connect-ExchangeOnline -ShowBanner:$false
    Write-Log "Connected successfully" "SUCCESS"
}
catch {
    Write-Log "Failed to connect: $($_.Exception.Message)" "ERROR"
    exit 1
}

Write-Log "Getting list of mailboxes..."
$mailboxes = Get-EXOMailbox -ResultSize Unlimited | Where-Object { $_.RecipientTypeDetails -in @("UserMailbox", "SharedMailbox") }

Write-Log "Found $($mailboxes.Count) mailboxes:" "SUCCESS"
Write-Log "-" * 50

foreach ($mailbox in $mailboxes) {
    Write-Host ""
    Write-Host "Display Name: $($mailbox.DisplayName)" -ForegroundColor Green
    Write-Host "Email: $($mailbox.PrimarySmtpAddress)" -ForegroundColor Yellow
    Write-Host "Type: $($mailbox.RecipientTypeDetails)" -ForegroundColor Cyan
    Write-Host "-" * 50
}
