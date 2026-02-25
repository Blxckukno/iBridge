# Modern IT Support Impact Report Generator V2
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

Write-Log "Starting Modern IT Support Impact Report Generation"
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
    Write-Log "Fetching message trace data..."
    $messages = Get-MessageTrace -StartDate $startDate -EndDate $endDate -SenderAddress $SmartzEmail -Status Delivered

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

            # Get message content for user impact analysis
            try {
                $msgContent = Get-MessageTraceDetail -MessageTraceId $msg.MessageTraceId -RecipientAddress $msg.RecipientAddress
                if ($msgContent) {
                    # Look for user impact indicators
                    if ($msgContent.Subject -match "users affected|impacted users|user impact") {
                        $metrics.UserImpact[$msg.MessageTraceId] = @{
                            Subject = $msgContent.Subject
                            Impact = "High"
                            Users = "Multiple"
                        }
                    }
                }
            }
            catch {
                Write-Log "Could not get message details for ID: $($msg.MessageTraceId)" "WARNING"
            }

            # Calculate response time if it's a thread
            if ($msg.MessageId) {
                $thread = Get-MessageTrace -MessageId $msg.MessageId
                if ($thread.Count -gt 1) {
                    $firstMsg = $thread | Sort-Object Received | Select-Object -First 1
                    $lastMsg = $thread | Sort-Object Received | Select-Object -Last 1
                    $duration = ($lastMsg.Received - $firstMsg.Received).TotalHours
                    
                    if ($duration -gt 0) {
                        $metrics.TurnAroundTimes[$msg.MessageId] = $duration
                    }
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

        if ($metrics.TurnAroundTimes.Count -gt 0) {
            $avgTAT = [math]::Round(($metrics.TurnAroundTimes.Values | Measure-Object -Average).Average, 2)
            $report += "`nAverage Resolution Time: $avgTAT hours"
        }

        $report += "`n`nIssue Categories"
        $report += "`n---------------"
        foreach ($cat in $metrics.Categories.GetEnumerator() | Sort-Object Value -Descending) {
            $report += "`n$($cat.Key): $($cat.Value) incidents"
        }

        $report += "`n`nDaily Volume"
        $report += "`n------------"
        foreach ($vol in $metrics.DailyVolume.GetEnumerator() | Sort-Object Key) {
            $report += "`n$($vol.Key): $($vol.Value) emails"
        }

        if ($metrics.UserImpact.Count -gt 0) {
            $report += "`n`nHigh Impact Issues"
            $report += "`n----------------"
            foreach ($impact in $metrics.UserImpact.GetEnumerator()) {
                $report += "`n[$($impact.Value.Impact)] $($impact.Value.Subject) - Users: $($impact.Value.Users)"
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
"@
        if ($metrics.TurnAroundTimes.Count -gt 0) {
            $summaryText += "`n• Average Resolution Time: $([math]::Round(($metrics.TurnAroundTimes.Values | Measure-Object -Average).Average, 2)) hours"
        }
        if ($metrics.UserImpact.Count -gt 0) {
            $summaryText += "`n• High Impact Issues: $($metrics.UserImpact.Count)"
        }
        
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
        
        if ($metrics.TurnAroundTimes.Count -gt 0) {
            $tatSlide = $presentation.Slides.Add(5, 12)
            $tatSlide.Shapes.Title.TextFrame.TextRange.Text = "Resolution Time Distribution"
            
            $tatChart = $tatSlide.Shapes.AddChart2(201, [Microsoft.Office.Core.XlChartType]::xlColumnClustered).Chart
            
            $excel = $tatChart.ChartData.Workbook
            $worksheet = $excel.Worksheets(1)
            
            $worksheet.Cells(1,1).Value2 = "Time Range"
            $worksheet.Cells(1,2).Value2 = "Count"
            
            # Group resolution times into ranges
            $ranges = @{
                "< 1 hour" = 0
                "1-4 hours" = 0
                "4-8 hours" = 0
                "8-24 hours" = 0
                "> 24 hours" = 0
            }
            
            foreach ($time in $metrics.TurnAroundTimes.Values) {
                switch ($time) {
                    {$_ -lt 1} { $ranges["< 1 hour"]++ }
                    {$_ -ge 1 -and $_ -lt 4} { $ranges["1-4 hours"]++ }
                    {$_ -ge 4 -and $_ -lt 8} { $ranges["4-8 hours"]++ }
                    {$_ -ge 8 -and $_ -lt 24} { $ranges["8-24 hours"]++ }
                    default { $ranges["> 24 hours"]++ }
                }
            }
            
            $row = 2
            foreach ($range in $ranges.GetEnumerator()) {
                $worksheet.Cells($row,1).Value2 = $range.Key
                $worksheet.Cells($row,2).Value2 = $range.Value
                $row++
            }
        }
        
        if ($metrics.UserImpact.Count -gt 0) {
            $impactSlide = $presentation.Slides.Add(6, 2)
            $impactSlide.Shapes.Title.TextFrame.TextRange.Text = "High Impact Issues"
            
            $impactText = "Issues requiring immediate attention or affecting multiple users:`n`n"
            foreach ($impact in $metrics.UserImpact.GetEnumerator() | Sort-Object { $_.Value.Impact } -Descending) {
                $impactText += "• [$($impact.Value.Impact)] $($impact.Value.Subject)`n"
                $impactText += "  Users Affected: $($impact.Value.Users)`n`n"
            }
            
            $impactSlide.Shapes.Item(2).TextFrame.TextRange.Text = $impactText
        }
        
        $presentation.SaveAs($pptPath)
        $presentation.Close()
        $powerPoint.Quit()
        
        Write-Log "PowerPoint report saved to: $pptPath" "SUCCESS"
    }
    else {
        Write-Log "No support emails found in the specified date range" "WARNING"
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
