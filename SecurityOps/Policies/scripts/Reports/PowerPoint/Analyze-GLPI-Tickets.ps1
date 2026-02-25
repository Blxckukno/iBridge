# Import required modules
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Force -Scope CurrentUser
}
Import-Module ImportExcel

# Parameters
$outputPath = Join-Path $PSScriptRoot "..\..\..\Reports"
$reportDate = Get-Date -Format "yyyyMMdd-HHmmss"
$excelPath = Join-Path $outputPath "IT-Impact-Report-$reportDate.xlsx"
$startDate = (Get-Date).AddDays(-30)  # Last 30 days
$endDate = Get-Date

# Ensure output directory exists
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

Write-Host "Analyzing GLPI tickets from support@smartz-solutions.com..."

# Initialize data structures
$ticketData = @{
    Categories = @{}
    Impact = @{}
    Status = @{}
    Urgency = @{}
    ResponseTimes = [System.Collections.ArrayList]@()
    TechnicianLoad = @{}
    AffectedUsers = [System.Collections.ArrayList]@()
}

# Connect to Exchange Online
try {
    $null = Get-EXOMailbox -ResultSize 1
    Write-Host "Already connected to Exchange Online" -ForegroundColor Green
} catch {
    Write-Host "Connecting to Exchange Online..."
    Connect-ExchangeOnline
}

# Get current mailbox
$currentMailbox = Get-EXOMailbox -Identity $env:USERNAME
Write-Host "Searching in mailbox: $($currentMailbox.PrimarySmtpAddress)"

# Search for GLPI tickets
$searchPattern = "GLPI #"
Write-Host "Searching for tickets..."

try {
    # Get folders to search through
    $folders = Get-EXOMailboxFolderStatistics -Identity $currentMailbox.Identity
    
    foreach ($folder in $folders) {
        Write-Host "Processing folder: $($folder.FolderPath)"
        
        # Parse each ticket found
        $tickets = Search-Mailbox -Identity $currentMailbox.Identity -SearchQuery $searchPattern -TargetFolder $folder.FolderPath
        
        foreach ($ticket in $tickets) {
            # Extract ticket information
            $ticketNumber = if ($ticket.Subject -match '\[GLPI #(\d+)\]') { $matches[1] } else { "Unknown" }
            $category = if ($ticket.Body -match 'Category\s*:(.*?)(?:\r|\n)') { $matches[1].Trim() } else { "Unknown" }
            $impact = if ($ticket.Body -match 'Impact\s*:(.*?)(?:\r|\n)') { $matches[1].Trim() } else { "Unknown" }
            $status = if ($ticket.Body -match 'Status\s*:(.*?)(?:\r|\n)') { $matches[1].Trim() } else { "Unknown" }
            $urgency = if ($ticket.Body -match 'Urgency\s*:(.*?)(?:\r|\n)') { $matches[1].Trim() } else { "Unknown" }
            $technician = if ($ticket.Body -match 'Assigned to technicians\s*:(.*?)(?:\r|\n)') { $matches[1].Trim() } else { "Unassigned" }
            
            # Update statistics
            $ticketData.Categories[$category] = ($ticketData.Categories[$category] ?? 0) + 1
            $ticketData.Impact[$impact] = ($ticketData.Impact[$impact] ?? 0) + 1
            $ticketData.Status[$status] = ($ticketData.Status[$status] ?? 0) + 1
            $ticketData.Urgency[$urgency] = ($ticketData.Urgency[$urgency] ?? 0) + 1
            $ticketData.TechnicianLoad[$technician] = ($ticketData.TechnicianLoad[$technician] ?? 0) + 1
            
            # Calculate response time
            if ($ticket.Body -match 'Opening date\s*:(.*?)(?:\r|\n)') {
                $openingDate = [DateTime]::ParseExact($matches[1].Trim(), "yyyy-MM-dd HH:mm", $null)
                $responseTime = ($ticket.ReceivedTime - $openingDate).TotalHours
                $ticketData.ResponseTimes.Add(@{
                    TicketNumber = $ticketNumber
                    ResponseTime = $responseTime
                }) | Out-Null
            }
            
            # Track affected users
            if ($ticket.Body -match 'Username\s*:(.*?)(?:\r|\n)') {
                $ticketData.AffectedUsers.Add($matches[1].Trim()) | Out-Null
            }
        }
    }
    
    # Create Excel report
    $excel = Open-ExcelPackage -Path $excelPath -Create
    
    # Add Categories worksheet
    $ws = Add-Worksheet -ExcelPackage $excel -WorksheetName "Categories"
    $categoryData = $ticketData.Categories.GetEnumerator() | Select-Object @{N='Category';E={$_.Key}}, @{N='Count';E={$_.Value}}
    $categoryData | Export-Excel -ExcelPackage $excel -WorksheetName "Categories" -AutoSize -TableName "Categories"
    
    # Add chart
    $chart = New-ExcelChartDefinition -ChartType Pie `
        -Title "Ticket Distribution by Category" `
        -XRange "Categories!A2:A$($categoryData.Count+1)" `
        -YRange "Categories!B2:B$($categoryData.Count+1)" `
        -Width 400 -Height 300
    Add-ExcelChart -Worksheet $ws -ChartDefinition $chart
    
    # Add Impact Analysis worksheet
    $ws = Add-Worksheet -ExcelPackage $excel -WorksheetName "Impact Analysis"
    $impactData = $ticketData.Impact.GetEnumerator() | Select-Object @{N='Impact Level';E={$_.Key}}, @{N='Count';E={$_.Value}}
    $impactData | Export-Excel -ExcelPackage $excel -WorksheetName "Impact Analysis" -AutoSize -TableName "Impact"
    
    # Add Technician Load worksheet
    $ws = Add-Worksheet -ExcelPackage $excel -WorksheetName "Technician Load"
    $techData = $ticketData.TechnicianLoad.GetEnumerator() | Select-Object @{N='Technician';E={$_.Key}}, @{N='Tickets';E={$_.Value}}
    $techData | Export-Excel -ExcelPackage $excel -WorksheetName "Technician Load" -AutoSize -TableName "TechnicianLoad"
    
    # Add Response Times worksheet
    $ws = Add-Worksheet -ExcelPackage $excel -WorksheetName "Response Times"
    $responseData = $ticketData.ResponseTimes | Sort-Object ResponseTime
    $responseData | Export-Excel -ExcelPackage $excel -WorksheetName "Response Times" -AutoSize -TableName "ResponseTimes"
    
    # Save and close Excel file
    Close-ExcelPackage $excel
    
    # Display summary
    Write-Host "`nAnalysis Summary:"
    Write-Host "-----------------"
    Write-Host "Total Categories: $($ticketData.Categories.Count)"
    Write-Host "Total Technicians: $($ticketData.TechnicianLoad.Count)"
    Write-Host "Average Response Time: $([math]::Round(($ticketData.ResponseTimes | Measure-Object -Property ResponseTime -Average).Average, 2)) hours"
    Write-Host "Most Common Category: $(($ticketData.Categories.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key)"
    Write-Host "Most Active Technician: $(($ticketData.TechnicianLoad.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key)"
    Write-Host "`nReport saved to: $excelPath"
    
} catch {
    Write-Host "Error processing tickets: $_" -ForegroundColor Red
}
