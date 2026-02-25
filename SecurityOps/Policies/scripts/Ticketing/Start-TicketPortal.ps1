# Import required modules
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Force -Scope CurrentUser
}

# Configuration
$config = @{
    SupportEmail = "support@ibridge.co.za"
    TicketStorePath = Join-Path $PSScriptRoot "TicketStore"
    LogPath = Join-Path $PSScriptRoot "Logs"
    TemplatesPath = Join-Path $PSScriptRoot "Templates"
    DatabasePath = Join-Path $PSScriptRoot "Database"
}

# Create required directories
@($config.TicketStorePath, $config.LogPath, $config.TemplatesPath, $config.DatabasePath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ | Out-Null
        Write-Host "Created directory: $_"
    }
}

# Initialize ticket database
$ticketDbPath = Join-Path $config.DatabasePath "tickets.xlsx"
if (-not (Test-Path $ticketDbPath)) {
    $excel = Open-ExcelPackage -Path $ticketDbPath -Create
    $ws = Add-Worksheet -ExcelPackage $excel -WorksheetName "Tickets"
    
    # Add headers
    $headers = @(
        "TicketID",
        "Status",
        "Priority",
        "Subject",
        "Requester",
        "AssignedTo",
        "Created",
        "LastUpdated",
        "Category",
        "Description"
    )
    
    $ws.Cells["A1:J1"].Value = $headers
    Close-ExcelPackage $excel
    Write-Host "Created ticket database at $ticketDbPath"
}

function New-TicketFromEmail {
    param (
        [Parameter(Mandatory = $true)]
        [string]$From,
        
        [Parameter(Mandatory = $true)]
        [string]$Subject,
        
        [Parameter(Mandatory = $true)]
        [string]$Body,
        
        [string]$Priority = "Medium",
        [string]$Category = "General"
    )
    
    try {
        # Generate ticket ID
        $ticketId = "IB" + (Get-Date).ToString("yyyyMMddHHmmss")
        
        # Create ticket object
        $ticket = [PSCustomObject]@{
            TicketID = $ticketId
            Status = "New"
            Priority = $Priority
            Subject = $Subject
            Requester = $From
            AssignedTo = ""
            Created = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Category = $Category
            Description = $Body
        }
        
        # Load existing tickets
        $excel = Open-ExcelPackage -Path $ticketDbPath
        $ws = $excel.Workbook.Worksheets["Tickets"]
        
        # Find next empty row
        $row = $ws.Dimension.Rows + 1
        
        # Add new ticket
        $ws.Cells["A$row"].Value = $ticket.TicketID
        $ws.Cells["B$row"].Value = $ticket.Status
        $ws.Cells["C$row"].Value = $ticket.Priority
        $ws.Cells["D$row"].Value = $ticket.Subject
        $ws.Cells["E$row"].Value = $ticket.Requester
        $ws.Cells["F$row"].Value = $ticket.AssignedTo
        $ws.Cells["G$row"].Value = $ticket.Created
        $ws.Cells["H$row"].Value = $ticket.LastUpdated
        $ws.Cells["I$row"].Value = $ticket.Category
        $ws.Cells["J$row"].Value = $ticket.Description
        
        # Save changes
        Close-ExcelPackage $excel
        
        # Send acknowledgment
        Send-TicketAcknowledgment -Ticket $ticket
        
        return $ticket
    }
    catch {
        Write-Error "Error creating ticket: $_"
        return $null
    }
}

function Send-TicketAcknowledgment {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Ticket
    )
    
    try {
        $body = @"
Thank you for contacting iBridge Support.

Your ticket has been created with the following details:

Ticket ID: $($Ticket.TicketID)
Subject: $($Ticket.Subject)
Status: $($Ticket.Status)
Priority: $($Ticket.Priority)

We will process your request and get back to you as soon as possible.

Please include the Ticket ID [$($Ticket.TicketID)] in all future correspondence about this issue.

Best regards,
iBridge Support Team
"@
        
        # Send email using Send-MailMessage or your preferred email sending method
        # For now, we'll just log it
        $logPath = Join-Path $config.LogPath "acknowledgments.log"
        $logEntry = @"
====================================
Date: $(Get-Date)
To: $($Ticket.Requester)
Subject: [Ticket $($Ticket.TicketID)] Acknowledgment
Body:
$body
====================================

"@
        Add-Content -Path $logPath -Value $logEntry
        Write-Host "Acknowledgment logged for ticket $($Ticket.TicketID)"
    }
    catch {
        Write-Error "Error sending acknowledgment: $_"
    }
}

function Start-TicketMonitoring {
    Write-Host "Starting ticket monitoring for $($config.SupportEmail)..."
    
    try {
        # Connect to Exchange Online if not already connected
        $null = Get-EXOMailbox -ResultSize 1
        Write-Host "Already connected to Exchange Online" -ForegroundColor Green
    }
    catch {
        Write-Host "Connecting to Exchange Online..."
        Connect-ExchangeOnline
    }
    
    # Main monitoring loop
    while ($true) {
        try {
            Write-Host "Checking for new emails..."
            
            # Get the support mailbox
            $mailbox = Get-EXOMailbox -Identity $config.SupportEmail
            
            if ($mailbox) {
                # Get unread messages
                $messages = Get-EXOMailboxFolderStatistics -Identity $mailbox.Identity -IncludeOldestAndNewestItems |
                    Where-Object { $_.FolderPath -eq "/Inbox" -and $_.ItemsInFolder -gt 0 }
                
                Write-Host "Found $($messages.ItemsInFolder) messages in inbox"
                
                foreach ($message in $messages) {
                    # Create ticket from email
                    $ticket = New-TicketFromEmail -From $message.From -Subject $message.Subject -Body $message.Body
                    
                    if ($ticket) {
                        Write-Host "Created ticket $($ticket.TicketID) from email"
                    }
                }
            }
            
            # Wait before next check
            Write-Host "Waiting 5 minutes before next check..."
            Start-Sleep -Seconds 300
        }
        catch {
            Write-Error "Error in monitoring loop: $_"
            Start-Sleep -Seconds 60  # Wait a minute before retrying
        }
    }
}
