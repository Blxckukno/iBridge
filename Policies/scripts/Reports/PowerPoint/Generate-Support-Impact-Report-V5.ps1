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
$pptxPath = Join-Path $outputPath "IT-Impact-Report-$reportDate.pptx"

# Create PowerPoint presentation
$powerPoint = New-Object -ComObject PowerPoint.Application
$powerPoint.Visible = [Microsoft.Office.Core.MsoTriState]::msoTrue
$presentation = $powerPoint.Presentations.Add()

# Add title slide
$titleSlide = $presentation.Slides.Add(1, 1)
$titleSlide.Shapes.Title.TextFrame.TextRange.Text = "IT Support Impact Report"
$titleSlide.Shapes.SubTitle.TextFrame.TextRange.Text = "Period: $($startDate.ToString('yyyy-MM-dd')) to $($endDate.ToString('yyyy-MM-dd'))"

# Get message data
Write-Host "Fetching email data..."
$messages = Get-MessageTrace -SenderAddress $senderAddress -StartDate $startDate -EndDate $endDate |
    Where-Object { $_.Status -eq "Delivered" }

if (-not $messages) {
    Write-Host "No messages found for the specified period" -ForegroundColor Yellow
    return
}

# Analyze data
$issueCategories = @{}
$userImpact = @{}
$resolutionTimes = @{}

foreach ($message in $messages) {
    # Get detailed message info
    $messageDetail = Get-MessageTraceDetail -MessageId $message.MessageId
    
    # Extract subject for categorization
    $subject = $message.Subject
    if (-not $issueCategories.ContainsKey($subject)) {
        $issueCategories[$subject] = 1
    } else {
        $issueCategories[$subject]++
    }
    
    # Calculate resolution time (using received and delivery time)
    $resolutionTime = $message.Received - $message.DeliveryStatus
    $resolutionTimes[$message.MessageId] = $resolutionTime
    
    # Track impacted users (from recipients)
    $recipients = $message.RecipientAddress -split ';'
    foreach ($recipient in $recipients) {
        if (-not $userImpact.ContainsKey($recipient)) {
            $userImpact[$recipient] = 1
        } else {
            $userImpact[$recipient]++
        }
    }
}

# Create charts slides
# 1. Issue Categories Pie Chart
$categorySlide = $presentation.Slides.Add(2, 12)  # Layout with title and chart
$categorySlide.Shapes.Title.TextFrame.TextRange.Text = "Issue Categories Distribution"
$chart = $categorySlide.Shapes.AddChart2(240, -4100, 600, 400).Chart
$dataArray = @($issueCategories.Keys), @($issueCategories.Values)
$chart.ChartData.Workbook.Worksheets(1).Range("A1").Resize(2, $issueCategories.Count) = $dataArray
$chart.ChartType = 70  # xlPie

# 2. User Impact Bar Chart
$userSlide = $presentation.Slides.Add(3, 12)
$userSlide.Shapes.Title.TextFrame.TextRange.Text = "Users Impacted by Issues"
$chart = $userSlide.Shapes.AddChart2(240, -4100, 600, 400).Chart
$dataArray = @($userImpact.Keys), @($userImpact.Values)
$chart.ChartData.Workbook.Worksheets(1).Range("A1").Resize(2, $userImpact.Count) = $dataArray
$chart.ChartType = 4  # xlBarClustered

# 3. Resolution Times Summary
$timeSlide = $presentation.Slides.Add(4, 2)  # Layout with title and text
$timeSlide.Shapes.Title.TextFrame.TextRange.Text = "Resolution Time Analysis"
$avgResolutionTime = ($resolutionTimes.Values | Measure-Object -Average).Average
$maxResolutionTime = ($resolutionTimes.Values | Measure-Object -Maximum).Maximum
$timeText = @"
Average Resolution Time: $([math]::Round($avgResolutionTime.TotalMinutes, 2)) minutes
Maximum Resolution Time: $([math]::Round($maxResolutionTime.TotalMinutes, 2)) minutes
Total Issues Analyzed: $($messages.Count)
Most Common Issue: $($issueCategories.Keys | Sort-Object { $issueCategories[$_] } -Descending | Select-Object -First 1)
Most Impacted User: $($userImpact.Keys | Sort-Object { $userImpact[$_] } -Descending | Select-Object -First 1)
"@
$timeSlide.Shapes.AddTextbox(1, 50, 100, 600, 300).TextFrame.TextRange.Text = $timeText

# Save presentation
$presentation.SaveAs($pptxPath)
$powerPoint.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($powerPoint)

Write-Host "Report generated successfully at: $pptxPath" -ForegroundColor Green
