# Analyze-PhishingEmails.ps1
# Purpose: Identify potential phishing emails in Microsoft 365 mailboxes
# This script helps detect patterns and indicators of phishing that may have led to account compromise

param(
    [Parameter(Mandatory=$false)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory=$false)]
    [switch]$AllUsers,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysToLookBack = 30,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\PhishingDetection_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\PhishingDetection_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# Initialize logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with appropriate color
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor White }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
    }
    
    # Write to log file
    Add-Content -Path $LogPath -Value $logMessage
}

# Check prerequisites
function Check-Prerequisites {
    $requiredModules = @("ExchangeOnlineManagement", "AzureAD", "MSOnline")
    $allModulesPresent = $true
    
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-Log "Required module not found: $module" -Level Error
            Write-Log "Install it with: Install-Module -Name $module -Force" -Level Info
            $allModulesPresent = $false
        }
    }
    
    if (!$allModulesPresent) {
        Write-Log "Missing required modules. Please install them and try again." -Level Error
        exit 1
    }
    
    # Validate parameters
    if (!$UserPrincipalName -and !$AllUsers) {
        Write-Log "You must specify either a UserPrincipalName or use the -AllUsers switch." -Level Error
        exit 1
    }
    
    # Connect to required services
    try {
        Write-Log "Connecting to Exchange Online..." -Level Info
        Connect-ExchangeOnline -ErrorAction Stop
        
        Write-Log "Connecting to Azure AD..." -Level Info
        Connect-AzureAD -ErrorAction Stop
        
        Write-Log "Connecting to MSOnline Service..." -Level Info
        Connect-MsolService -ErrorAction Stop
        
        return $true
    }
    catch {
        Write-Log "Failed to connect to one or more Microsoft 365 services: $_" -Level Error
        return $false
    }
}

# Function to analyze email content for phishing indicators
function Get-PhishingIndicators {
    param(
        [string]$EmailBody,
        [string]$Subject,
        [string]$FromAddress,
        [string]$FromDomain,
        [string[]]$ToAddresses,
        [string]$ReceivedTime,
        [string]$MessageId,
        [string]$HeadersText
    )
    
    # Initialize indicators object
    $indicators = @{
        UrgencyLanguage = $false
        MismatchedLinks = $false
        SuspiciousAttachment = $false
        SpoofedSender = $false
        SuspiciousGreeting = $false
        PoorGrammar = $false
        RequestsCredentials = $false
        ContainsSuspiciousLinks = $false
        MismatchedDisplayName = $false
        SuspiciousDomain = $false
        ScoreTotal = 0
    }
    
    # Check for urgency language in subject
    $urgencyTerms = @("urgent", "immediate", "alert", "attention", "action required", "important", "verify", "suspension", "restricted", "unusual activity")
    foreach ($term in $urgencyTerms) {
        if ($Subject -match $term -or $EmailBody -match $term) {
            $indicators.UrgencyLanguage = $true
            $indicators.ScoreTotal += 1
            break
        }
    }
    
    # Check for suspicious greeting
    $genericGreetings = @("dear user", "valued customer", "dear customer", "dear account holder", "dear sir or madam", "dear sir/madam")
    foreach ($greeting in $genericGreetings) {
        if ($EmailBody -match $greeting) {
            $indicators.SuspiciousGreeting = $true
            $indicators.ScoreTotal += 1
            break
        }
    }
    
    # Check for poor grammar and spelling
    $poorGrammarIndicators = @(
        "kindly", "please do the needful", "your account has been compromised", 
        "verify your account immediately", "failure to respond", "your account will be terminated", 
        "confirm your details", "we detected suspicious"
    )
    foreach ($indicator in $poorGrammarIndicators) {
        if ($EmailBody -match $indicator) {
            $indicators.PoorGrammar = $true
            $indicators.ScoreTotal += 1
            break
        }
    }
    
    # Check for requests for credentials
    $credentialRequests = @(
        "confirm your password", "verify your password", "enter your password", 
        "login to verify", "sign in to confirm", "update your account details", 
        "security verification", "re-enter your credentials", "account verification required"
    )
    foreach ($request in $credentialRequests) {
        if ($EmailBody -match $request) {
            $indicators.RequestsCredentials = $true
            $indicators.ScoreTotal += 2  # Higher weight for credential requests
            break
        }
    }
    
    # Check for suspicious domains in links
    try {
        # Extract URLs from HTML content - simple regex pattern for demonstration
        $urlMatches = [regex]::Matches($EmailBody, '(https?:\/\/[^\s"''<>]+)')
        
        if ($urlMatches.Count -gt 0) {
            foreach ($match in $urlMatches) {
                $url = $match.Groups[1].Value
                
                # Check for URL/text mismatches in HTML (simplified)
                if ($EmailBody -match "<a\s+href=(['""])(?<href>.*?)\1[^>]*>(?<text>.*?)<\/a>" -and $matches.href -ne $matches.text) {
                    $indicators.MismatchedLinks = $true
                    $indicators.ScoreTotal += 2
                }
                
                # Check for suspicious TLDs or domains
                $suspiciousTlds = @(".tk", ".ml", ".ga", ".cf", ".gq", ".xyz", ".top", ".work", ".info", ".ru", ".bid")
                foreach ($tld in $suspiciousTlds) {
                    if ($url -match [regex]::Escape($tld) + "$") {
                        $indicators.SuspiciousDomain = $true
                        $indicators.ScoreTotal += 1
                        break
                    }
                }
                
                # Check for URLs with IP addresses instead of domain names
                if ($url -match "https?:\/\/\d+\.\d+\.\d+\.\d+") {
                    $indicators.SuspiciousDomain = $true
                    $indicators.ScoreTotal += 2
                }
                
                # Check for URLs containing "login", "verify", "secure", "account" keywords
                $suspiciousUrlKeywords = @("login", "verify", "secure", "account", "signin", "credential", "password", "banking", "update", "confirm")
                foreach ($keyword in $suspiciousUrlKeywords) {
                    if ($url -match $keyword) {
                        $indicators.ContainsSuspiciousLinks = $true
                        $indicators.ScoreTotal += 1
                        break
                    }
                }
            }
        }
    }
    catch {
        Write-Log "Error analyzing links in email: $_" -Level Error
    }
    
    # Check for suspicious attachments
    if ($EmailBody -match "\.(exe|zip|js|vbs|bat|scr|hta|cmd|ps1|msi|vbe|wsf)") {
        $indicators.SuspiciousAttachment = $true
        $indicators.ScoreTotal += 2
    }
    
    # Check for spoofed sender
    # This is a simplified check - real implementation would compare header routing
    if ($HeadersText) {
        # Check for display name vs actual email mismatch
        if ($HeadersText -match "From:.*<(?<email>[^>]+)>") {
            $actualEmail = $matches.email
            
            # Check if display name contains a different domain than the email
            if ($HeadersText -match "From:\s*(?<displayName>[^<]+)<") {
                $displayName = $matches.displayName
                if ($displayName -match "\@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})") {
                    $displayDomain = $matches.domain
                    $actualDomain = $actualEmail.Split('@')[1]
                    
                    if ($displayDomain -ne $actualDomain) {
                        $indicators.MismatchedDisplayName = $true
                        $indicators.ScoreTotal += 2
                    }
                }
            }
            
            # Check for mismatched Return-Path
            if ($HeadersText -match "Return-Path:.*<(?<returnpath>[^>]+)>") {
                $returnPath = $matches.returnpath
                if ($returnPath -ne $actualEmail) {
                    $indicators.SpoofedSender = $true
                    $indicators.ScoreTotal += 2
                }
            }
            
            # Check for spoofing in Authentication-Results
            if ($HeadersText -match "Authentication-Results:.*dmarc=(?<dmarc>pass|fail)") {
                if ($matches.dmarc -eq "fail") {
                    $indicators.SpoofedSender = $true
                    $indicators.ScoreTotal += 2
                }
            }
        }
    }
    
    # Determine overall phishing likelihood based on score
    $phishingLikelihood = if ($indicators.ScoreTotal -ge 5) {
        "High"
    } elseif ($indicators.ScoreTotal -ge 3) {
        "Medium"
    } elseif ($indicators.ScoreTotal -ge 1) {
        "Low"
    } else {
        "Minimal"
    }
    
    return @{
        Indicators = $indicators
        PhishingScore = $indicators.ScoreTotal
        PhishingLikelihood = $phishingLikelihood
    }
}

# Function to scan a specific mailbox for phishing
function Scan-MailboxForPhishing {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack
    )
    
    Write-Log "Scanning mailbox for phishing: $UserPrincipalName..." -Level Info
    
    try {
        # Calculate date range
        $startDate = (Get-Date).AddDays(-$DaysToLookBack).ToString("yyyy-MM-dd")
        $endDate = Get-Date -Format "yyyy-MM-dd"
        
        # Initialize results array
        $phishingResults = @()
        
        # Get inbox folder
        $inboxFolderId = (Get-MailboxFolderStatistics -Identity $UserPrincipalName -FolderScope Inbox | 
            Where-Object { $_.FolderType -eq "Inbox" }).FolderId
        
        if (!$inboxFolderId) {
            Write-Log "Could not find Inbox folder for $UserPrincipalName" -Level Error
            return @()
        }
        
        # Convert folder ID to the format needed for Search-Mailbox
        $inboxFolderPath = $UserPrincipalName + ":\Inbox"
        
        # Use content search instead (if available)
        try {
            $searchName = "PhishingScan_$($UserPrincipalName.Split('@')[0])_$(Get-Date -Format 'yyyyMMddHHmmss')"
            
            # Create and start compliance search - targeting the inbox
            Write-Log "Starting content search for recent emails..." -Level Info
            New-ComplianceSearch -Name $searchName -ExchangeLocation $UserPrincipalName -ContentMatchQuery "received>=$startDate AND received<=$endDate" | Out-Null
            Start-ComplianceSearch -Identity $searchName | Out-Null
            
            # Wait for search to complete
            $searchStatus = Get-ComplianceSearch -Identity $searchName
            while ($searchStatus.Status -ne "Completed") {
                Start-Sleep -Seconds 5
                $searchStatus = Get-ComplianceSearch -Identity $searchName
                Write-Log "Search in progress... Current status: $($searchStatus.Status)" -Level Info
            }
            
            Write-Log "Content search completed. Found $($searchStatus.Items) items." -Level Info
            
            # If we found items, process them
            if ($searchStatus.Items -gt 0) {
                # Instead of using content search preview (which can be limited),
                # we'll use Get-MessageTrace and then examine specific messages
                
                $startDateObj = [DateTime]::ParseExact($startDate, "yyyy-MM-dd", $null)
                $endDateObj = [DateTime]::ParseExact($endDate, "yyyy-MM-dd", $null).AddDays(1).AddSeconds(-1)
                
                # Get message trace
                $messageTraces = Get-MessageTrace -RecipientAddress $UserPrincipalName -StartDate $startDateObj -EndDate $endDateObj -PageSize 5000
                
                if ($messageTraces) {
                    Write-Log "Processing $($messageTraces.Count) messages for analysis..." -Level Info
                    
                    $processedCount = 0
                    foreach ($message in $messageTraces) {
                        $processedCount++
                        
                        if ($processedCount % 100 -eq 0) {
                            Write-Log "Processed $processedCount of $($messageTraces.Count) messages..." -Level Info
                        }
                        
                        # Get message headers
                        try {
                            $headers = Get-MessageTrace -MessageId $message.MessageId | Get-MessageTraceDetail
                            $headerText = ($headers | Where-Object { $_.Event -eq "Headers" } | Select-Object -First 1).Data
                            
                            # Basic information from the message
                            $emailInfo = [PSCustomObject]@{
                                UserPrincipalName = $UserPrincipalName
                                Subject = $message.Subject
                                FromAddress = $message.FromAddress
                                FromDomain = ($message.FromAddress -split "@")[1]
                                ToAddresses = $message.RecipientAddress
                                ReceivedTime = $message.Received
                                MessageId = $message.MessageId
                                HeadersText = $headerText
                                EmailBody = "Email body not available in message trace" # Email body typically not available via MessageTrace
                            }
                            
                            # Analyze for phishing indicators
                            $analysisResults = Get-PhishingIndicators -EmailBody $emailInfo.EmailBody `
                                                                     -Subject $emailInfo.Subject `
                                                                     -FromAddress $emailInfo.FromAddress `
                                                                     -FromDomain $emailInfo.FromDomain `
                                                                     -ToAddresses $emailInfo.ToAddresses `
                                                                     -ReceivedTime $emailInfo.ReceivedTime `
                                                                     -MessageId $emailInfo.MessageId `
                                                                     -HeadersText $emailInfo.HeadersText
                            
                            # Add the results to our main results object
                            $phishingResult = [PSCustomObject]@{
                                UserPrincipalName = $UserPrincipalName
                                Subject = $message.Subject
                                FromAddress = $message.FromAddress
                                FromDomain = ($message.FromAddress -split "@")[1]
                                ReceivedTime = $message.Received
                                MessageId = $message.MessageId
                                PhishingScore = $analysisResults.PhishingScore
                                PhishingLikelihood = $analysisResults.PhishingLikelihood
                                UrgencyLanguage = $analysisResults.Indicators.UrgencyLanguage
                                MismatchedLinks = $analysisResults.Indicators.MismatchedLinks
                                SuspiciousAttachment = $analysisResults.Indicators.SuspiciousAttachment
                                SpoofedSender = $analysisResults.Indicators.SpoofedSender
                                SuspiciousGreeting = $analysisResults.Indicators.SuspiciousGreeting
                                PoorGrammar = $analysisResults.Indicators.PoorGrammar
                                RequestsCredentials = $analysisResults.Indicators.RequestsCredentials
                                ContainsSuspiciousLinks = $analysisResults.Indicators.ContainsSuspiciousLinks
                                MismatchedDisplayName = $analysisResults.Indicators.MismatchedDisplayName
                                SuspiciousDomain = $analysisResults.Indicators.SuspiciousDomain
                            }
                            
                            # Add to results array if score is above 0
                            if ($analysisResults.PhishingScore -gt 0) {
                                $phishingResults += $phishingResult
                                
                                if ($analysisResults.PhishingLikelihood -eq "High") {
                                    Write-Log "HIGH LIKELIHOOD PHISHING EMAIL: '$($message.Subject)' from $($message.FromAddress), received $($message.Received)" -Level Warning
                                } elseif ($analysisResults.PhishingLikelihood -eq "Medium") {
                                    Write-Log "Medium likelihood phishing email: '$($message.Subject)' from $($message.FromAddress)" -Level Warning
                                }
                            }
                        }
                        catch {
                            Write-Log "Error processing message ID $($message.MessageId): $_" -Level Error
                        }
                    }
                } else {
                    Write-Log "No message traces found for $UserPrincipalName in the specified time range" -Level Info
                }
            }
        }
        catch {
            Write-Log "Error in content search process: $_" -Level Error
        }
        
        # Clean up search if it exists
        try {
            Remove-ComplianceSearch -Identity $searchName -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch {
            # Just log and continue
            Write-Log "Error cleaning up compliance search: $_" -Level Warning
        }
        
        return $phishingResults
    }
    catch {
        Write-Log "Error scanning mailbox for phishing: $_" -Level Error
        return @()
    }
}

# Function to scan multiple mailboxes
function Start-PhishingScan {
    param(
        [string]$SingleUserPrincipalName,
        [switch]$ScanAllUsers,
        [int]$DaysToLookBack
    )
    
    # Initialize results collection
    $allResults = @()
    
    if ($ScanAllUsers) {
        # Get all licensed users
        Write-Log "Getting all licensed users..." -Level Info
        $users = Get-MsolUser -All | Where-Object { $_.IsLicensed -eq $true }
        $userCount = ($users | Measure-Object).Count
        Write-Log "Found $userCount licensed users" -Level Info
        
        $processedCount = 0
        foreach ($user in $users) {
            $processedCount++
            $percentComplete = [math]::Round(($processedCount / $userCount) * 100)
            Write-Log "[$percentComplete%] Scanning mailbox $processedCount of $userCount: $($user.UserPrincipalName)" -Level Info
            
            $results = Scan-MailboxForPhishing -UserPrincipalName $user.UserPrincipalName -DaysToLookBack $DaysToLookBack
            $allResults += $results
        }
    }
    else {
        Write-Log "Scanning single mailbox: $SingleUserPrincipalName" -Level Info
        $results = Scan-MailboxForPhishing -UserPrincipalName $SingleUserPrincipalName -DaysToLookBack $DaysToLookBack
        $allResults += $results
    }
    
    # Generate summary
    Write-Log "========== PHISHING DETECTION SUMMARY ==========" -Level Info
    $highLikelihood = $allResults | Where-Object { $_.PhishingLikelihood -eq "High" }
    $mediumLikelihood = $allResults | Where-Object { $_.PhishingLikelihood -eq "Medium" }
    $lowLikelihood = $allResults | Where-Object { $_.PhishingLikelihood -eq "Low" }
    
    Write-Log "Total emails analyzed: $($allResults.Count)" -Level Info
    Write-Log "High likelihood phishing: $($highLikelihood.Count)" -Level $(if ($highLikelihood.Count -gt 0) { "Warning" } else { "Info" })
    Write-Log "Medium likelihood phishing: $($mediumLikelihood.Count)" -Level Info
    Write-Log "Low likelihood phishing: $($lowLikelihood.Count)" -Level Info
    
    # Export results to CSV
    if ($allResults.Count -gt 0) {
        $allResults | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-Log "Results exported to $OutputPath" -Level Info
    } else {
        Write-Log "No phishing emails detected in the scan" -Level Info
    }
    
    # Report high likelihood emails
    if ($highLikelihood.Count -gt 0) {
        Write-Log "`nHIGH LIKELIHOOD PHISHING EMAILS DETECTED:" -Level Warning
        foreach ($email in $highLikelihood) {
            Write-Log "Subject: $($email.Subject)" -Level Warning
            Write-Log "From: $($email.FromAddress)" -Level Warning
            Write-Log "Received: $($email.ReceivedTime)" -Level Warning
            Write-Log "Recipient: $($email.UserPrincipalName)" -Level Warning
            Write-Log "Phishing Score: $($email.PhishingScore)" -Level Warning
            Write-Log "Indicators: " -NoNewline -Level Warning
            
            $indicators = @()
            if ($email.UrgencyLanguage) { $indicators += "Urgency Language" }
            if ($email.MismatchedLinks) { $indicators += "Mismatched Links" }
            if ($email.SuspiciousAttachment) { $indicators += "Suspicious Attachment" }
            if ($email.SpoofedSender) { $indicators += "Spoofed Sender" }
            if ($email.SuspiciousGreeting) { $indicators += "Suspicious Greeting" }
            if ($email.PoorGrammar) { $indicators += "Poor Grammar" }
            if ($email.RequestsCredentials) { $indicators += "Requests Credentials" }
            if ($email.ContainsSuspiciousLinks) { $indicators += "Contains Suspicious Links" }
            if ($email.MismatchedDisplayName) { $indicators += "Mismatched Display Name" }
            if ($email.SuspiciousDomain) { $indicators += "Suspicious Domain" }
            
            Write-Log ($indicators -join ", ") -Level Warning
            Write-Log "------------------------------------------" -Level Warning
        }
        
        # Add recommendation
        Write-Log "`nRECOMMENDATION: These high-likelihood phishing emails should be investigated as possible entry points for the security incident." -Level Warning
    }
    
    Write-Log "========== END OF SUMMARY ==========" -Level Info
    
    return $allResults
}

# Main execution block
Write-Log "Starting phishing email analysis..." -Level Info
Write-Log "Analysis period: Last $DaysToLookBack days" -Level Info
Write-Log "Results will be saved to: $OutputPath" -Level Info

# Check prerequisites and establish connections
if (Check-Prerequisites) {
    # Start the scan based on parameters
    if ($UserPrincipalName) {
        Start-PhishingScan -SingleUserPrincipalName $UserPrincipalName -DaysToLookBack $DaysToLookBack
    }
    elseif ($AllUsers) {
        Start-PhishingScan -ScanAllUsers -DaysToLookBack $DaysToLookBack
    }
    
    # Disconnect sessions
    try {
        Disconnect-ExchangeOnline -Confirm:$false
        Disconnect-AzureAD
        Write-Log "Disconnected from Microsoft 365 services" -Level Info
    } catch {
        Write-Log "Error disconnecting from services: $_" -Level Warning
    }
    
    Write-Log "Analysis complete. See the log file for details: $LogPath" -Level Info
} else {
    Write-Log "Failed to establish required connections. Analysis aborted." -Level Error
}
