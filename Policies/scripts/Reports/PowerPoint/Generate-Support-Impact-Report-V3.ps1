# Modern IT Support Impact Report Generator V3
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

Write-Log "Starting IT Support Impact Analysis"
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

# Initialize metrics
$metrics = @{
    TotalEmails = 0
    Categories = @{}
    DailyVolume = @{}
    IssueTypes = @{}
    UserImpact = @{}
    TurnAroundTimes = @{}
}

try {
    Write-Log "Fetching email data..."
    
    # Use Get-ExoMailbox to get mailbox info
    $mailbox = Get-ExoMailbox -Identity "lwandile.gasela@ibridge.co.za"
    
    if ($mailbox) {
        Write-Log "Found mailbox: $($mailbox.DisplayName)" "SUCCESS"
        
        # Get messages using Get-ExoMessageTracking
        $messages = Get-MessageTracking -SenderAddress $SmartzEmail -StartDate $startDate -EndDate $endDate
        
        if ($messages) {
            $metrics.TotalEmails = $messages.Count
            Write-Log "Found $($messages.Count) support emails" "SUCCESS"
            
            # Process each message
            foreach ($msg in $messages) {
                # Track daily volume
                $date = $msg.Received.ToString('yyyy-MM-dd')
                if (-not $metrics.DailyVolume.ContainsKey($date)) {
                    $metrics.DailyVolume[$date] = 0
                }
                $metrics.DailyVolume[$date]++
                
                # Track categories
                if ($msg.Subject -match "\[(.*?)\]") {
                    $category = $matches[1].Trim()
                    if (-not $metrics.Categories.ContainsKey($category)) {
                        $metrics.Categories[$category] = 0
                    }
                    $metrics.Categories[$category]++
                }
                
                # Track user impact based on subject keywords
                if ($msg.Subject -match "(users?|people|staff|employees|team)\s+(affected|impacted|down|cannot|unable|issue|problem)") {
                    $metrics.UserImpact[$msg.MessageId] = @{
                        Subject = $msg.Subject
                        Impact = "High"
                        Users = "Multiple"
                    }
                }
            }
            
            # Create output directory if it doesn't exist
            if (-not (Test-Path $OutputFolder)) {
                New-Item -ItemType Directory -Path $OutputFolder | Out-Null
            }
            
            # Generate text report
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $reportPath = Join-Path $OutputFolder "IT-Impact-Analysis-$timestamp.txt"
            
            $report = @"
IT Support Impact Analysis Report
===============================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Report Type: $ReportType
Date Range: $($startDate.ToString('yyyy-MM-dd')) to $($endDate.ToString('yyyy-MM-dd'))

Summary Statistics
----------------
Total Support Emails: $($metrics.TotalEmails)
Average Daily Volume: $([math]::Round($metrics.TotalEmails / ($metrics.DailyVolume.Count + 0.1), 2))
"@
            
            if ($metrics.Categories.Count -gt 0) {
                $report += "`n`nIssue Categories"
                $report += "`n---------------"
                foreach ($cat in $metrics.Categories.GetEnumerator() | Sort-Object Value -Descending) {
                    $report += "`n$($cat.Key): $($cat.Value) incidents"
                }
            }
            
            if ($metrics.DailyVolume.Count -gt 0) {
                $report += "`n`nDaily Volume"
                $report += "`n------------"
                foreach ($vol in $metrics.DailyVolume.GetEnumerator() | Sort-Object Key) {
                    $report += "`n$($vol.Key): $($vol.Value) emails"
                }
            }
            
            if ($metrics.UserImpact.Count -gt 0) {
                $report += "`n`nHigh Impact Issues"
                $report += "`n----------------"
                foreach ($impact in $metrics.UserImpact.GetEnumerator()) {
                    $report += "`n[$($impact.Value.Impact)] $($impact.Value.Subject)"
                }
            }
            
            $report | Out-File -FilePath $reportPath -Encoding UTF8
            Write-Log "Analysis report saved to: $reportPath" "SUCCESS"
            
            # Create PowerPoint report
            Write-Log "Creating PowerPoint visualization..."
            $pptPath = Join-Path $OutputFolder "IT-Impact-Report-$timestamp.pptx"
            
            $powerPoint = New-Object -ComObject PowerPoint.Application
            $powerPoint.Visible = [Microsoft.Office.Core.MsoTriState]::msoTrue
            
            $presentation = $powerPoint.Presentations.Add()
            
            # Title slide
            $titleSlide = $presentation.Slides.Add(1, 1)
            $titleSlide.Shapes.Title.TextFrame.TextRange.Text = "IT Support Impact Analysis"
            $titleSlide.Shapes.Item(2).TextFrame.TextRange.Text = "$ReportType Report`n$(Get-Date -Format 'yyyy-MM-dd')"
            
            # Summary slide
            $summarySlide = $presentation.Slides.Add(2, 2)
            $summarySlide.Shapes.Title.TextFrame.TextRange.Text = "Key Metrics"
            
            $summaryText = @"
• Total Support Incidents: $($metrics.TotalEmails)
• Average Daily Volume: $([math]::Round($metrics.TotalEmails / ($metrics.DailyVolume.Count + 0.1), 2))
• Categories Found: $($metrics.Categories.Count)
• High Impact Issues: $($metrics.UserImpact.Count)
"@
            
            $summarySlide.Shapes.Item(2).TextFrame.TextRange.Text = $summaryText
            
            # Create charts
            if ($metrics.Categories.Count -gt 0) {
                $chartSlide = $presentation.Slides.Add(3, 12)
                $chartSlide.Shapes.Title.TextFrame.TextRange.Text = "Issue Categories Distribution"
                
                $chart = $chartSlide.Shapes.AddChart2(201, [Microsoft.Office.Core.XlChartType]::xlPie).Chart
                
                $dataArray = $metrics.Categories.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10
                
                $excel = $chart.ChartData.Workbook
                $worksheet = $excel.Worksheets(1)
                
                $worksheet.Cells(1,1).Value2 = "Category"
                $worksheet.Cells(1,2).Value2 = "Count"
                
                $row = 2
                foreach ($item in $dataArray) {
                    $worksheet.Cells($row,1).Value2 = $item.Key
                    $worksheet.Cells($row,2).Value2 = $item.Value
                    $row++
                }
            }
            
            if ($metrics.DailyVolume.Count -gt 0) {
                $volumeSlide = $presentation.Slides.Add(4, 12)
                $volumeSlide.Shapes.Title.TextFrame.TextRange.Text = "Daily Support Volume"
                
                $volumeChart = $volumeSlide.Shapes.AddChart2(201, [Microsoft.Office.Core.XlChartType]::xlLine).Chart
                
                $volumeData = $metrics.DailyVolume.GetEnumerator() | Sort-Object Key
                
                $excel = $volumeChart.ChartData.Workbook
                $worksheet = $excel.Worksheets(1)
                
                $worksheet.Cells(1,1).Value2 = "Date"
                $worksheet.Cells(1,2).Value2 = "Volume"
                
                $row = 2
                foreach ($item in $volumeData) {
                    $worksheet.Cells($row,1).Value2 = $item.Key
                    $worksheet.Cells($row,2).Value2 = $item.Value
                    $row++
                }
            }
            
            if ($metrics.UserImpact.Count -gt 0) {
                $impactSlide = $presentation.Slides.Add(5, 2)
                $impactSlide.Shapes.Title.TextFrame.TextRange.Text = "High Impact Issues"
                
                $impactText = "Issues requiring immediate attention or affecting multiple users:`n`n"
                foreach ($impact in $metrics.UserImpact.GetEnumerator()) {
                    $impactText += "• [$($impact.Value.Impact)] $($impact.Value.Subject)`n`n"
                }
                
                $impactSlide.Shapes.Item(2).TextFrame.TextRange.Text = $impactText
            }
            
            $presentation.SaveAs($pptPath)
            $presentation.Close()
            $powerPoint.Quit()
            
            Write-Log "PowerPoint report saved to: $pptPath" "SUCCESS"
            Write-Log "Analysis complete with $($metrics.TotalEmails) emails processed" "SUCCESS"
        }
        else {
            Write-Log "No support emails found in the specified date range" "WARNING"
        }
    }
    else {
        Write-Log "Could not find mailbox" "ERROR"
    }
}
catch {
    Write-Log "Error analyzing emails: $($_.Exception.Message)" "ERROR"
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
