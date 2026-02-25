param(
    [string]$ApiBase = "http://127.0.0.1:5000/api",
    [string]$Source = "chatbot",
    [string]$IntakeKey = ""
)

$payload = @{
    source = $Source
    title = "Sample intake ticket from $Source"
    description = "This is a sample intake payload for future email/chatbot integration."
    priority = "medium"
    category = "integration-test"
    requester = @{
        name = "Integration Bot"
        email = "bot@ibridge.local"
        phone = "+27 00 000 0000"
        department = "IT"
    }
    channel_id = "sample-channel-01"
    external_message_id = "sample-msg-01"
    labels = @("sample", "intake", $Source)
    context = @{
        environment = "showcase"
        created_by = "send-intake-ticket-sample.ps1"
    }
}

$headers = @{
    "Content-Type" = "application/json"
}

if ($IntakeKey) {
    $headers["X-Intake-Key"] = $IntakeKey
}

$uri = "$ApiBase/tickets/intake"
Write-Host "Posting intake payload to $uri"

try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($payload | ConvertTo-Json -Depth 8)
    Write-Host "Created ticket number: $($response.ticket_number)"
    Write-Host "Ticket ID: $($response.ticket.id)"
} catch {
    Write-Error "Failed to create intake ticket: $($_.Exception.Message)"
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message
    }
    exit 1
}
