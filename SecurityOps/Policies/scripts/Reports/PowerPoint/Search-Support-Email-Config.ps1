# Connect to Exchange Online if not already connected
try {
    $null = Get-EXOMailbox -ResultSize 1
    Write-Host "Already connected to Exchange Online" -ForegroundColor Green
} catch {
    Write-Host "Connecting to Exchange Online..."
    Connect-ExchangeOnline
}

Write-Host "`nLooking for messages from or to support@smartz-solutions.com..."

# Get access to reporting cmdlets
try {
    # First try searching last 7 days
    $endDate = Get-Date
    $startDate = $endDate.AddDays(-7)
    
    Write-Host "`nSearching message trace for the last 7 days..."
    $messages = Search-MessageTrace -StartDate $startDate -EndDate $endDate -SenderAddress "support@smartz-solutions.com"
    Write-Host "Messages from support@smartz-solutions.com: $($messages.Count)"
    
    $receivedMessages = Search-MessageTrace -StartDate $startDate -EndDate $endDate -RecipientAddress "support@smartz-solutions.com"
    Write-Host "Messages to support@smartz-solutions.com: $($receivedMessages.Count)"
    
    if ($messages -or $receivedMessages) {
        Write-Host "`nMessage Details:"
        Write-Host "-----------------"
        
        if ($messages) {
            Write-Host "`nMessages From support@smartz-solutions.com:"
            $messages | Select-Object Received, SenderAddress, RecipientAddress, Subject |
                Format-Table -AutoSize
        }
        
        if ($receivedMessages) {
            Write-Host "`nMessages To support@smartz-solutions.com:"
            $receivedMessages | Select-Object Received, SenderAddress, RecipientAddress, Subject |
                Format-Table -AutoSize
        }
    }
} catch {
    Write-Host "Error accessing message trace: $_" -ForegroundColor Red
}

# Try searching for any references to the domain
Write-Host "`nSearching for any mailboxes or groups with *@smartz-solutions.com..."
$recipients = Get-Recipient -ResultSize Unlimited -Filter "EmailAddresses -like '*@smartz-solutions.com'"

if ($recipients) {
    Write-Host "`nFound recipients with smartz-solutions.com domain:"
    $recipients | Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails |
        Format-Table -AutoSize
} else {
    Write-Host "No recipients found with smartz-solutions.com domain" -ForegroundColor Yellow
}

# Check for contact objects
Write-Host "`nSearching for contact objects..."
$contacts = Get-MailContact -ResultSize Unlimited -Filter "EmailAddresses -like '*@smartz-solutions.com'"

if ($contacts) {
    Write-Host "`nFound contacts with smartz-solutions.com domain:"
    $contacts | Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails |
        Format-Table -AutoSize
} else {
    Write-Host "No contacts found with smartz-solutions.com domain" -ForegroundColor Yellow
}

Write-Host "`nChecking transport rules..."
$rules = Get-TransportRule | Where-Object {
    $_.From -like "*@smartz-solutions.com" -or
    $_.SentTo -like "*@smartz-solutions.com"
}

if ($rules) {
    Write-Host "`nFound transport rules related to smartz-solutions.com:"
    $rules | Select-Object Name, State, Mode, Priority |
        Format-Table -AutoSize
} else {
    Write-Host "No transport rules found related to smartz-solutions.com" -ForegroundColor Yellow
}

# Check connector configurations
Write-Host "`nChecking mail connectors..."
$connectors = Get-InboundConnector | Where-Object {
    $_.SenderDomains -like "*smartz-solutions.com"
}

if ($connectors) {
    Write-Host "`nFound inbound connectors for smartz-solutions.com:"
    $connectors | Select-Object Name, Enabled, ConnectorType |
        Format-Table -AutoSize
} else {
    Write-Host "No inbound connectors found for smartz-solutions.com" -ForegroundColor Yellow
}
