# Import required modules
Import-Module ImportExcel

# Configuration
$config = @{
    DatabasePath = Join-Path $PSScriptRoot "Database\tickets.xlsx"
}

function Get-TicketList {
    param (
        [string]$Status,
        [string]$Priority,
        [string]$Category,
        [string]$AssignedTo,
        [string]$Requester
    )
    
    try {
        $excel = Open-ExcelPackage -Path $config.DatabasePath
        $ws = $excel.Workbook.Worksheets["Tickets"]
        
        # Convert worksheet to array of objects
        $tickets = @()
        $headers = @()
        
        # Get headers from first row
        1..$ws.Dimension.Columns | ForEach-Object {
            $headers += $ws.Cells[1, $_].Text
        }
        
        # Get data
        2..$ws.Dimension.Rows | ForEach-Object {
            $row = $_
            $ticket = [PSCustomObject]@{}
            
            1..$ws.Dimension.Columns | ForEach-Object {
                $ticket | Add-Member -NotePropertyName $headers[$_ - 1] -NotePropertyValue $ws.Cells[$row, $_].Text
            }
            
            # Apply filters
            $include = $true
            if ($Status -and $ticket.Status -ne $Status) { $include = $false }
            if ($Priority -and $ticket.Priority -ne $Priority) { $include = $false }
            if ($Category -and $ticket.Category -ne $Category) { $include = $false }
            if ($AssignedTo -and $ticket.AssignedTo -ne $AssignedTo) { $include = $false }
            if ($Requester -and $ticket.Requester -ne $Requester) { $include = $false }
            
            if ($include) {
                $tickets += $ticket
            }
        }
        
        Close-ExcelPackage $excel
        return $tickets
    }
    catch {
        Write-Error "Error getting tickets: $_"
        return $null
    }
}

function Get-TicketDetails {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TicketID
    )
    
    try {
        $tickets = Get-TicketList
        return $tickets | Where-Object { $_.TicketID -eq $TicketID }
    }
    catch {
        Write-Error "Error getting ticket details: $_"
        return $null
    }
}

# Example usage
Write-Host "Ticket Portal Viewer"
Write-Host "-----------------"

Write-Host "`nAll Open Tickets:"
Get-TicketList -Status "New" | Format-Table TicketID, Subject, Priority, Requester

Write-Host "`nHigh Priority Tickets:"
Get-TicketList -Priority "High" | Format-Table TicketID, Subject, Status, Requester

Write-Host "`nTo view ticket details, use:"
Write-Host "Get-TicketDetails -TicketID 'ticketId'"
