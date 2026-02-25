# Modern IT Support Impact Report Generator V4
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
        
        # Try to find and search the support folder
        Write-Log "Searching for support emails..."
        $supportFolder = Get-ExoMailboxFolderStatistics -Identity $mailbox.Identity | 
                        Where-Object { $_.Name -like "*support*" -or $_.Name -like "*Smartz*" }
        
        if ($supportFolder) {
            Write-Log "Found support folder: $($supportFolder.Name)" "SUCCESS"
            
            # Use Search-Mailbox or Get-MessageTrackingLog depending on what's available
            try {
                $searchQuery = "from:$SmartzEmail AND received>=$($startDate.ToString('yyyy-MM-dd')) AND received<=$($endDate.ToString('yyyy-MM-dd'))"
                $messages = Search-Mailbox -Identity $mailbox.Identity -SearchQuery $searchQuery -TargetMailbox $mailbox.Identity -TargetFolder "Support Analysis" -LogOnly
                
                if ($messages) {
                    $metrics.TotalEmails = $messages.ResultItemsCount
                    Write-Log "Found $($messages.ResultItemsCount) support emails" "SUCCESS"
                }
            }
            catch {
                Write-Log "Search-Mailbox not available, trying Get-EXORecipient..." "WARNING"
                
                # Try using Get-EXORecipient and Get-ExoMailboxFolderStatistics
                $stats = Get-ExoMailboxFolderStatistics -Identity $mailbox.Identity -FolderScope Inbox
                if ($stats) {
                    $metrics.TotalEmails = $stats.ItemsInFolder
                    Write-Log "Found $($stats.ItemsInFolder) total emails in inbox" "SUCCESS"
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
Total Emails Found: $($metrics.TotalEmails)
Note: This is a preliminary report. Additional data collection capabilities will be added as permissions are granted.

Recommendations
--------------
1. Request access to Get-MessageTracking cmdlet
2. Request access to Search-Mailbox cmdlet
3. Consider creating a dedicated support email folder for better tracking

Next Steps
----------
1. Configure message tracking logs for better email analytics
2. Set up support email categorization rules
3. Implement automated impact analysis based on email content
"@
            
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
            $summarySlide.Shapes.Title.TextFrame.TextRange.Text = "Current Status"
            
            $summaryText = @"
• Total Emails Found: $($metrics.TotalEmails)
• Analysis Period: $ReportType
• Date Range: $($startDate.ToString('yyyy-MM-dd')) to $($endDate.ToString('yyyy-MM-dd'))

Next Steps:
• Request necessary Exchange Online permissions
• Configure message tracking
• Set up email categorization rules
• Implement automated impact analysis
"@
            
            $summarySlide.Shapes.Item(2).TextFrame.TextRange.Text = $summaryText
            
            # Recommendations slide
            $recoSlide = $presentation.Slides.Add(3, 2)
            $recoSlide.Shapes.Title.TextFrame.TextRange.Text = "Recommendations"
            
            $recoText = @"
To enable comprehensive email analysis:

1. Exchange Online Access
   • Request Message Tracking permissions
   • Enable Search-Mailbox capability
   • Configure audit logging

2. Email Organization
   • Create dedicated support email folder
   • Implement email categorization rules
   • Set up automatic impact flagging

3. Reporting Setup
   • Configure automated report generation
   • Set up impact thresholds
   • Enable real-time analytics
"@
            
            $recoSlide.Shapes.Item(2).TextFrame.TextRange.Text = $recoText
            
            $presentation.SaveAs($pptPath)
            $presentation.Close()
            $powerPoint.Quit()
            
            Write-Log "PowerPoint report saved to: $pptPath" "SUCCESS"
            Write-Log "Initial analysis complete" "SUCCESS"
        }
        else {
            Write-Log "No dedicated support folder found" "WARNING"
            Write-Log "Consider creating a dedicated folder for support emails" "WARNING"
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

Write-Log "`nNext steps:"
Write-Log "1. Request access to message tracking features (Get-MessageTracking cmdlet)"
Write-Log "2. Set up a dedicated support email folder"
Write-Log "3. Configure email categorization rules"
Write-Log "4. Request additional Exchange Online permissions for comprehensive analysis"
