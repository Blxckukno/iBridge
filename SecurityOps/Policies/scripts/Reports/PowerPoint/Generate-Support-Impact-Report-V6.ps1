# Import required modules
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Force -Scope CurrentUser
}
Import-Module ImportExcel

# Connect to Exchange Online if not already connected
try {
    $null = Get-EXOMailbox -ResultSize 1
    Write-Host "Already connected to Exchange Online" -ForegroundColor Green
} catch {
    Write-Host "Connecting to Exchange Online..."
    Connect-ExchangeOnline
}

# Parameters for report generation
$startDate = (Get-Date).AddDays(-30)  # For monthly report
$endDate = Get-Date
$senderAddress = "support@smartz-solutions.com"
$outputPath = Join-Path $PSScriptRoot "..\..\..\Reports"
$reportDate = Get-Date -Format "yyyyMMdd-HHmmss"
$csvPath = Join-Path $outputPath "IT-Impact-Report-Data-$reportDate.csv"
$excelPath = Join-Path $outputPath "IT-Impact-Report-$reportDate.xlsx"

# Create output directory if it doesn't exist
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

# Get mailbox data for support emails
Write-Host "Fetching email data..."
$mailboxes = Get-EXOMailbox -ResultSize Unlimited | Where-Object { 
    $_.EmailAddresses -match "smtp:support@smartz-solutions.com" 
}

$reportData = @()

foreach ($mailbox in $mailboxes) {
    Write-Host "Processing mailbox: $($mailbox.PrimarySmtpAddress)"
    
    # Get folder statistics
    $stats = Get-EXOMailboxFolderStatistics -Identity $mailbox.Identity |
        Where-Object { $_.FolderPath -eq "/Inbox" }
    
    if ($stats) {
        $reportData += [PSCustomObject]@{
            Mailbox = $mailbox.PrimarySmtpAddress
            ItemCount = $stats.ItemsInFolder
            Size = $stats.FolderSize
            LastModifiedTime = $stats.LastModifiedTime
        }
    }
}

# Export data to CSV
$reportData | Export-Csv -Path $csvPath -NoTypeInformation

# Create Excel workbook with charts
$excel = Open-ExcelPackage -Path $excelPath -Create

# Add data worksheet
$ws = Add-WorkSheet -ExcelPackage $excel -WorksheetName "Support Data"
$reportData | Export-Excel -ExcelPackage $excel -WorksheetName "Support Data" -AutoSize -TableName "SupportData"

# Create summary worksheet
$ws = Add-WorkSheet -ExcelPackage $excel -WorksheetName "Summary"

# Add chart
$chart = New-ExcelChartDefinition -ChartType Pie `
    -Title "Support Email Distribution" `
    -XRange "Support Data!A2:A$($reportData.Count+1)" `
    -YRange "Support Data!B2:B$($reportData.Count+1)" `
    -Width 400 -Height 300

Add-ExcelChart -Worksheet $ws -ChartDefinition $chart

# Save and close Excel file
Close-ExcelPackage $excel

Write-Host "Report generated successfully!" -ForegroundColor Green
Write-Host "CSV data saved to: $csvPath" -ForegroundColor Green
Write-Host "Excel report saved to: $excelPath" -ForegroundColor Green

# Display summary
Write-Host "`nSummary:"
Write-Host "-----------------"
Write-Host "Total Mailboxes Processed: $($reportData.Count)"
$totalItems = ($reportData | Measure-Object -Property ItemCount -Sum).Sum
Write-Host "Total Items Found: $totalItems"
$latestModified = ($reportData | Measure-Object -Property LastModifiedTime -Maximum).Maximum
Write-Host "Latest Activity: $latestModified"
