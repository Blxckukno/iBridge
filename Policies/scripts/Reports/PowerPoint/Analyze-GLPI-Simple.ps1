# Parameters
$outputPath = Join-Path $PSScriptRoot "..\..\..\Reports"
$reportDate = Get-Date -Format "yyyyMMdd-HHmmss"
$csvPath = Join-Path $outputPath "GLPI-Analysis-$reportDate.csv"

# Create output directory if it doesn't exist
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

# Sample ticket analysis (we'll expand this with more tickets)
$tickets = @(
    @{
        Number = "0080743"
        Title = "Teams and Emails not opening"
        Requester = "Nonhlanhla.Ntombela@ibridge.co.za"
        OpeningDate = "2025-07-10 14:53"
        Technician = "Lindokuhle Mpungose"
        Status = "New"
        Urgency = "Medium"
        Impact = "Medium"
        Priority = "Medium"
        Category = "Applications > Office 365 > Teams"
        AffectedUser = "MTHEM_PHO"
        Description = "Teams and Email access issues after laptop change"
    }
)

# Analysis
$analysis = @{
    TotalTickets = $tickets.Count
    Categories = @{}
    Technicians = @{}
    Urgencies = @{}
    Impacts = @{}
    Statuses = @{}
}

foreach ($ticket in $tickets) {
    # Count categories
    $analysis.Categories[$ticket.Category] = ($analysis.Categories[$ticket.Category] ?? 0) + 1
    
    # Count technician workload
    $analysis.Technicians[$ticket.Technician] = ($analysis.Technicians[$ticket.Technician] ?? 0) + 1
    
    # Count urgencies
    $analysis.Urgencies[$ticket.Urgency] = ($analysis.Urgencies[$ticket.Urgency] ?? 0) + 1
    
    # Count impacts
    $analysis.Impacts[$ticket.Impact] = ($analysis.Impacts[$ticket.Impact] ?? 0) + 1
    
    # Count statuses
    $analysis.Statuses[$ticket.Status] = ($analysis.Statuses[$ticket.Status] ?? 0) + 1
}

# Generate report
$report = [PSCustomObject]@{
    ReportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalTickets = $analysis.TotalTickets
    Categories = $analysis.Categories | ConvertTo-Json
    Technicians = $analysis.Technicians | ConvertTo-Json
    Urgencies = $analysis.Urgencies | ConvertTo-Json
    Impacts = $analysis.Impacts | ConvertTo-Json
    Statuses = $analysis.Statuses | ConvertTo-Json
}

# Export to CSV
$report | Export-Csv -Path $csvPath -NoTypeInformation

# Display summary
Write-Host "`nGLPI Ticket Analysis Summary"
Write-Host "-------------------------"
Write-Host "Total Tickets: $($analysis.TotalTickets)"
Write-Host "`nCategories:"
$analysis.Categories.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}

Write-Host "`nTechnician Workload:"
$analysis.Technicians.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value) tickets"
}

Write-Host "`nImpact Distribution:"
$analysis.Impacts.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}

Write-Host "`nReport exported to: $csvPath"

# Recommendations
Write-Host "`nRecommendations:"
Write-Host "1. Monitor Office 365 related issues as they affect business communication"
Write-Host "2. Consider implementing a laptop change checklist to prevent post-change issues"
Write-Host "3. Track resolution time for medium impact tickets to maintain SLA"

# Next steps for gathering more data
Write-Host "`nTo improve this analysis, we need:"
Write-Host "1. Access to historical GLPI tickets"
Write-Host "2. Resolution times for closed tickets"
Write-Host "3. User feedback on issue resolution"
