# Generate Email Impact Report
#Requires -Modules ExchangeOnlineManagement, Microsoft.Graph.Sites, Microsoft.Graph.Files
param(
    [Parameter(Mandatory=$false)]
    [string]$StartDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd"),
    
    [Parameter(Mandatory=$false)]
    [string]$EndDate = (Get-Date).ToString("yyyy-MM-dd"),
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\EmailImpactReport-$(Get-Date -Format 'yyyyMMdd-HHmmss').pptx",
    
    [Parameter(Mandatory=$false)]
    [string]$MailboxToAnalyze = "Smartz@ibridge.co.za"
)

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
        # Connect to Exchange Online if not connected
        try {
            $null = Get-EXOMailbox -ResultSize 1 -ErrorAction Stop
            Write-Log "Already connected to Exchange Online" "SUCCESS"
        }
        catch {
            Write-Log "Connecting to Exchange Online..." "INFO"
            Connect-ExchangeOnline -ShowBanner:$false
        }

        # Connect to Microsoft Graph if not connected
        try {
            $null = Get-MgContext -ErrorAction Stop
            Write-Log "Already connected to Microsoft Graph" "SUCCESS"
        }
        catch {
            Write-Log "Connecting to Microsoft Graph..." "INFO"
            Connect-MgGraph -Scopes "Mail.Read", "Mail.ReadBasic", "Sites.Read.All", "Files.Read.All"
        }

        return $true
    }
    catch {
        Write-Log "Failed to connect to required services: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-EmailStatistics {
    param(
        [string]$Mailbox,
        [datetime]$Start,
        [datetime]$End
    )

    try {
        Write-Log "Analyzing emails for $Mailbox between $Start and $End..."
        
        # Get email statistics
        $stats = Get-EXOMailboxFolderStatistics -Identity $Mailbox -FolderScope Inbox
        $messages = Get-EXOMailboxFolderPermission -Identity "$($Mailbox):\Inbox"
        
        # Calculate metrics
        $emailMetrics = @{
            TotalEmails = $stats.ItemsInFolder
            TotalSize = $stats.FolderSize
            DailyAverage = [math]::Round($stats.ItemsInFolder / ((Get-Date) - $Start).Days, 2)
            Categories = @{}
            SenderDomains = @{}
            HourlyDistribution = @{}
        }
        
        Write-Log "Found $($emailMetrics.TotalEmails) total emails" "SUCCESS"
        
        return $emailMetrics
    }
    catch {
        Write-Log "Failed to get email statistics: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Create-PowerPointReport {
    param(
        [hashtable]$EmailMetrics,
        [string]$OutputFile
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
        $titleSlide.Shapes.Title.TextFrame.TextRange.Text = "Email Impact Report"
        $titleSlide.Shapes.Item(2).TextFrame.TextRange.Text = "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        # Summary slide
        $summarySlide = $presentation.Slides.Add(2, 2)
        $summarySlide.Shapes.Title.TextFrame.TextRange.Text = "Email Statistics Summary"
        
        # Add statistics
        $summaryText = @"
Total Emails: $($EmailMetrics.TotalEmails)
Daily Average: $($EmailMetrics.DailyAverage)
Total Size: $($EmailMetrics.TotalSize)
"@
        $summarySlide.Shapes.Item(2).TextFrame.TextRange.Text = $summaryText
        
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
Write-Log "Starting Email Impact Report Generation..."

# Connect to required services
if (-not (Connect-Required-Services)) {
    Write-Log "Failed to connect to required services. Exiting." "ERROR"
    exit 1
}

# Convert dates
$startDateTime = [datetime]::ParseExact($StartDate, "yyyy-MM-dd", $null)
$endDateTime = [datetime]::ParseExact($EndDate, "yyyy-MM-dd", $null)

# Get email statistics
$emailMetrics = Get-EmailStatistics -Mailbox $MailboxToAnalyze -Start $startDateTime -End $endDateTime

if ($null -eq $emailMetrics) {
    Write-Log "Failed to get email metrics. Exiting." "ERROR"
    exit 1
}

# Create PowerPoint report
$fullOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
if (Create-PowerPointReport -EmailMetrics $emailMetrics -OutputFile $fullOutputPath) {
    Write-Log "Email Impact Report generation completed successfully" "SUCCESS"
}
else {
    Write-Log "Failed to generate Email Impact Report" "ERROR"
    exit 1
}
