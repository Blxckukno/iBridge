param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,
    [string]$OutputPath = "Website/data/sharepoint-tickets.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $CsvPath)) {
    throw "CSV file not found: $CsvPath"
}

function Get-FieldValue {
    param(
        [pscustomobject]$Row,
        [string[]]$Names
    )

    foreach ($name in $Names) {
        $prop = $Row.PSObject.Properties | Where-Object { $_.Name -ieq $name } | Select-Object -First 1
        if ($null -ne $prop -and -not [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
            return [string]$prop.Value
        }
    }
    return ""
}

$rows = Import-Csv -Path $CsvPath

$tickets = foreach ($row in $rows) {
    $id = Get-FieldValue -Row $row -Names @("ID", "Id", "Ticket ID", "TicketID")
    $title = Get-FieldValue -Row $row -Names @(
        "Title",
        "Ticket Title",
        "Subject",
        "Issue or request title"
    )
    $status = Get-FieldValue -Row $row -Names @("Status", "Ticket Status")
    $priority = Get-FieldValue -Row $row -Names @("Priority", "Urgency")
    $category = Get-FieldValue -Row $row -Names @(
        "Category",
        "Type",
        "Issue or request category"
    )
    $assignedTo = Get-FieldValue -Row $row -Names @(
        "Assigned To",
        "Assigned to",
        "AssignedTo",
        "Owner"
    )
    $created = Get-FieldValue -Row $row -Names @("Created", "Created Date", "Date Created")
    $modified = Get-FieldValue -Row $row -Names @("Modified", "Last Modified", "Updated")
    $description = Get-FieldValue -Row $row -Names @(
        "Description",
        "Details",
        "Issue Description",
        "Issue or request description"
    )

    [ordered]@{
        id = if ([string]::IsNullOrWhiteSpace($id)) { "" } else { $id }
        title = $title
        status = if ([string]::IsNullOrWhiteSpace($status)) { "Open" } else { $status }
        priority = if ([string]::IsNullOrWhiteSpace($priority)) { "Medium" } else { $priority }
        category = $category
        assignedTo = $assignedTo
        created = $created
        modified = $modified
        description = $description
    }
}

$statusCounts = @{}
$priorityCounts = @{}
foreach ($ticket in $tickets) {
    $statusKey = if ([string]::IsNullOrWhiteSpace([string]$ticket.status)) { "Unknown" } else { [string]$ticket.status }
    $priorityKey = if ([string]::IsNullOrWhiteSpace([string]$ticket.priority)) { "Unknown" } else { [string]$ticket.priority }

    if (-not $statusCounts.ContainsKey($statusKey)) { $statusCounts[$statusKey] = 0 }
    if (-not $priorityCounts.ContainsKey($priorityKey)) { $priorityCounts[$priorityKey] = 0 }
    $statusCounts[$statusKey] += 1
    $priorityCounts[$priorityKey] += 1
}

$payload = [ordered]@{
    source = "SharePoint Export"
    generatedAt = (Get-Date).ToString("o")
    importedRowCount = $rows.Count
    total = $tickets.Count
    summary = [ordered]@{
        byStatus = $statusCounts
        byPriority = $priorityCounts
    }
    tickets = $tickets
}

$outDir = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outDir) -and -not (Test-Path $outDir)) {
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null
}

$jsonText = $payload | ConvertTo-Json -Depth 8
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$absoluteOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
[System.IO.File]::WriteAllText($absoluteOutputPath, $jsonText, $utf8NoBom)
Write-Host "Imported $($tickets.Count) tickets to $OutputPath"
