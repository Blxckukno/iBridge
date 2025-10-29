# Simplified IT Support Impact Report Generator
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Weekly", "Monthly")]
    [string]$ReportType = "Weekly",

    [Parameter(Mandatory=$false)]
    [string]$SmartzEmail = "support@smartz-solutions.com",

    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "C:\Users\Lwandile Gasela\iBridge\Policies\Reports"
)

function Write-Log {
    param($Message, $Level = "INFO")
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message" -ForegroundColor $(
        switch($Level) {
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
}

Write-Log "Starting IT Support Impact Report Generation"
Write-Log "Report Type: $ReportType"
Write-Log "Support Email: $SmartzEmail"

# Connect to Exchange Online
try {
    Write-Log "Connecting to Exchange Online..."
    Connect-ExchangeOnline
    Write-Log "Successfully connected to Exchange Online" "SUCCESS"
}
catch {
    Write-Log "Failed to connect to Exchange Online: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Set date range
$endDate = Get-Date
$startDate = switch($ReportType) {
    "Weekly" { $endDate.AddDays(-7) }
    "Monthly" { $endDate.AddDays(-30) }
}

Write-Log "Analyzing emails from $($startDate.ToString('yyyy-MM-dd')) to $($endDate.ToString('yyyy-MM-dd'))"

# Search for emails
try {
    Write-Log "Searching for support emails..."
    $searchQuery = "from:$SmartzEmail AND received>=$($startDate.ToString('yyyy-MM-dd')) AND received<=$($endDate.ToString('yyyy-MM-dd'))"
    
    $searchResults = Search-Mailbox -Identity "lwandile.gasela@ibridge.co.za" `
                                  -SearchQuery $searchQuery `
                                  -TargetMailbox "lwandile.gasela@ibridge.co.za" `
                                  -TargetFolder "Support Analysis" `
                                  -LogLevel Full `
                                  -EstimateResultOnly
    
    Write-Log "Found approximately $($searchResults.ResultItemsCount) support emails" "SUCCESS"
    
    # Create basic report with findings
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportPath = Join-Path $OutputFolder "IT-Impact-Summary-$timestamp.txt"
    
    $report = @"
IT Support Impact Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Report Type: $ReportType
Date Range: $($startDate.ToString('yyyy-MM-dd')) to $($endDate.ToString('yyyy-MM-dd'))

Summary:
- Total Emails Found: $($searchResults.ResultItemsCount)
- Search Query: $searchQuery

Note: This is a preliminary report. Full analysis capabilities will be added in subsequent updates.
"@
    
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Log "Basic report saved to: $reportPath" "SUCCESS"
}
catch {
    Write-Log "Error searching emails: $($_.Exception.Message)" "ERROR"
}
finally {
    try {
        Write-Log "Disconnecting from Exchange Online..."
        Disconnect-ExchangeOnline -Confirm:$false
        Write-Log "Disconnected successfully" "SUCCESS"
    }
    catch {
        # Ignore disconnect errors
    }
}
