# Smartz Support Email Analysis and Report Generation
#Requires -Modules ExchangeOnlineManagement, Microsoft.Graph, ImportExcel
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Weekly", "Monthly")]
    [string]$ReportType = "Weekly",

    [Parameter(Mandatory=$false)]
    [string]$SmartzEmail = "support@smartz-solutions.com",

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = $null
)

# Initialize variables
$startDate = switch($ReportType) {
    "Weekly" { (Get-Date).AddDays(-7) }
    "Monthly" { (Get-Date).AddDays(-30) }
}

$endDate = Get-Date
if (-not $OutputPath) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutputPath = Join-Path $PSScriptRoot "IT-Impact-Report-$($ReportType.ToLower())-$timestamp.pptx"
}

function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $(switch($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    })
}

function Connect-Required-Services {
    try {
        # Connect to Exchange Online
        Write-Log "Connecting to Exchange Online..."
        Connect-ExchangeOnline -ShowBanner:$false
        
        # Connect to Microsoft Graph with required permissions
        Write-Log "Connecting to Microsoft Graph..."
        Connect-MgGraph -Scopes @(
            "Mail.Read",
            "Mail.ReadBasic",
            "Directory.Read.All",
            "Sites.Read.All",
            "Files.Read.All"
        )
        
        return $true
    }
    catch {
        Write-Log "Failed to connect to required services: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-SupportEmailData {
    param(
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [string]$SenderAddress
    )
    
    try {
        Write-Log "Fetching support emails from $StartDate to $EndDate..."
        
        # Search for emails in the specified date range
        $searchQuery = "from:$SenderAddress AND received>=$($StartDate.ToString('yyyy-MM-dd')) AND received<=$($EndDate.ToString('yyyy-MM-dd'))"
        $emails = Search-MailBox -Identity "lwandile.gasela@ibridge.co.za" -SearchQuery $searchQuery -TargetMailbox "lwandile.gasela@ibridge.co.za" -TargetFolder "Support Analysis" -LogLevel Full
        
        # Process emails to extract metrics
        $metrics = @{
            TotalEmails = 0
            IssueCategories = @{}
            TurnAroundTimes = @{}
            UserImpact = @{}
            ResolutionSteps = @{}
            DailyVolume = @{}
            SeverityLevels = @{}
        }
        
        # Process each email
        foreach ($email in $emails) {
            $metrics.TotalEmails++
            
            # Extract subject for categorization
            $subject = $email.Subject
            if ($subject -match "\[(.*?)\]") {
                $category = $matches[1]
                $metrics.IssueCategories[$category] = ($metrics.IssueCategories[$category] ?? 0) + 1
            }
            
            # Calculate turn around time if thread is complete
            if ($email.ConversationTopic) {
                $thread = Get-MessageTrace -ConversationId $email.ConversationId
                if ($thread.Count -gt 1) {
                    $firstEmail = $thread | Sort-Object Received | Select-Object -First 1
                    $lastEmail = $thread | Sort-Object Received | Select-Object -Last 1
                    $turnAroundTime = ($lastEmail.Received - $firstEmail.Received).TotalHours
                    
                    $metrics.TurnAroundTimes[$email.ConversationId] = $turnAroundTime
                }
            }
            
            # Track daily volume
            $date = $email.Received.Date.ToString("yyyy-MM-dd")
            $metrics.DailyVolume[$date] = ($metrics.DailyVolume[$date] ?? 0) + 1
        }
        
        return $metrics
    }
    catch {
        Write-Log "Error processing emails: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Create-PowerPointReport {
    param(
        [hashtable]$Metrics,
        [string]$OutputFile,
        [string]$ReportType
    )
    
    try {
        Write-Log "Creating PowerPoint report..."
        
        # Create PowerPoint application
        $powerPoint = New-Object -ComObject PowerPoint.Application
        $powerPoint.Visible = [Microsoft.Office.Core.MsoTriState]::msoTrue
        
        # Add presentation
        $presentation = $powerPoint.Presentations.Add()
        
        # Title slide
        $titleSlide = $presentation.Slides.Add(1, 1)
        $titleSlide.Shapes.Title.TextFrame.TextRange.Text = "IT Support Impact Report"
        $titleSlide.Shapes.Item(2).TextFrame.TextRange.Text = "$ReportType Report: $(Get-Date -Format 'yyyy-MM-dd')"
        
        # Summary slide
        $summarySlide = $presentation.Slides.Add(2, 2)
        $summarySlide.Shapes.Title.TextFrame.TextRange.Text = "Executive Summary"
        
        $summaryText = @"
Total Incidents: $($Metrics.TotalEmails)
Average Resolution Time: $([math]::Round(($Metrics.TurnAroundTimes.Values | Measure-Object -Average).Average, 2)) hours
Most Common Category: $($Metrics.IssueCategories.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1 | ForEach-Object { $_.Key })
"@
        $summarySlide.Shapes.Item(2).TextFrame.TextRange.Text = $summaryText
        
        # Turn Around Time Graph
        $tatSlide = $presentation.Slides.Add(3, 12)
        $tatSlide.Shapes.Title.TextFrame.TextRange.Text = "Resolution Time Analysis"
        
        # Add chart
        $chart = $tatSlide.Shapes.AddChart2(201, [Microsoft.Office.Core.XlChartType]::xlColumnClustered).Chart
        $dataSheet = $chart.ChartData.Workbook.Worksheets(1)
        
        # Populate chart data
        $row = 2
        foreach ($tat in $Metrics.TurnAroundTimes.GetEnumerator()) {
            $dataSheet.Cells($row, 1).Text = $tat.Key
            $dataSheet.Cells($row, 2).Value2 = $tat.Value
            $row++
        }
        
        # Daily Volume Graph
        $volumeSlide = $presentation.Slides.Add(4, 12)
        $volumeSlide.Shapes.Title.TextFrame.TextRange.Text = "Daily Incident Volume"
        
        $volumeChart = $volumeSlide.Shapes.AddChart2(201, [Microsoft.Office.Core.XlChartType]::xlLine).Chart
        $volumeData = $volumeChart.ChartData.Workbook.Worksheets(1)
        
        # Populate volume data
        $row = 2
        foreach ($vol in $Metrics.DailyVolume.GetEnumerator() | Sort-Object Key) {
            $volumeData.Cells($row, 1).Text = $vol.Key
            $volumeData.Cells($row, 2).Value2 = $vol.Value
            $row++
        }
        
        # Categories Pie Chart
        $categorySlide = $presentation.Slides.Add(5, 12)
        $categorySlide.Shapes.Title.TextFrame.TextRange.Text = "Issue Categories Distribution"
        
        $pieChart = $categorySlide.Shapes.AddChart2(201, [Microsoft.Office.Core.XlChartType]::xlPie).Chart
        $categoryData = $pieChart.ChartData.Workbook.Worksheets(1)
        
        # Populate category data
        $row = 2
        foreach ($cat in $Metrics.IssueCategories.GetEnumerator()) {
            $categoryData.Cells($row, 1).Text = $cat.Key
            $categoryData.Cells($row, 2).Value2 = $cat.Value
            $row++
        }
        
        # Save presentation
        $presentation.SaveAs($OutputFile)
        $presentation.Close()
        $powerPoint.Quit()
        
        Write-Log "PowerPoint report saved to: $OutputFile" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to create PowerPoint report: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
Write-Log "Starting IT Support Impact Report Generation - $ReportType Report"

# Connect to required services
if (-not (Connect-Required-Services)) {
    Write-Log "Failed to connect to required services. Exiting." "ERROR"
    exit 1
}

# Get email data
$metrics = Get-SupportEmailData -StartDate $startDate -EndDate $endDate -SenderAddress $SmartzEmail
if ($null -eq $metrics) {
    Write-Log "Failed to get email metrics. Exiting." "ERROR"
    exit 1
}

# Create PowerPoint report
if (Create-PowerPointReport -Metrics $metrics -OutputFile $OutputPath -ReportType $ReportType) {
    Write-Log "Report generation completed successfully" "SUCCESS"
    Write-Log "Report saved to: $OutputPath" "SUCCESS"
}
else {
    Write-Log "Failed to generate report" "ERROR"
    exit 1
}
