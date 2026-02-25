# Impossible-Travel-Investigation.ps1
# Purpose: Investigate and remediate an impossible travel security incident
# Author: GitHub Copilot
# Date: September 10, 2025

param(
    [Parameter(Mandatory=$false)]
    [string]$UserPrincipalName = "reubendren.padayachee@mtn.com",
    
    [Parameter(Mandatory=$false)]
    [string]$SuspiciousIP1 = "104.234.230.218", # US IP
    
    [Parameter(Mandatory=$false)]
    [string]$SuspiciousIP2 = "197.89.17.36", # South Africa IP
    
    [Parameter(Mandatory=$false)]
    [switch]$ResetPassword,
    
    [Parameter(Mandatory=$false)]
    [switch]$BlockSuspiciousIPs,
    
    [Parameter(Mandatory=$false)]
    [switch]$FullInvestigation,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\Reports"
)

# Initialize
$ErrorActionPreference = "Stop"
$InvestigationFindings = @()

# Function for logging
function Write-InvestigationLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Finding')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with color based on level
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor White }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
        'Finding' { Write-Host $logMessage -ForegroundColor Cyan }
    }
}

# Function to record investigation findings
function Add-InvestigationFinding {
    param(
        [string]$Category,
        [string]$Finding,
        [ValidateSet('Normal', 'Suspicious', 'Malicious')]
        [string]$Severity = 'Normal',
        [string]$Details,
        [DateTime]$Timestamp = (Get-Date)
    )
    
    $findingResult = [PSCustomObject]@{
        Category = $Category
        Finding = $Finding
        Severity = $Severity
        Details = $Details
        Timestamp = $Timestamp
    }
    
    $script:InvestigationFindings += $findingResult
    
    # Log to console
    $severityIcon = switch ($Severity) {
        'Normal' { "[OK]" }
        'Suspicious' { "[SUSPICIOUS]" }
        'Malicious' { "[MALICIOUS]" }
    }
    
    $logLevel = switch ($Severity) {
        'Normal' { "Success" }
        'Suspicious' { "Warning" }
        'Malicious' { "Error" }
    }
    
    Write-InvestigationLog "$severityIcon $Category - $Finding" -Level $logLevel
    
    return $findingResult
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-InvestigationLog "Checking prerequisites and required modules..." -Level Info
    $requiredModules = @(
        "ExchangeOnlineManagement",
        "AzureAD",
        "MSOnline"
    )
    
    $allModulesPresent = $true
    
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-InvestigationLog "Required module not found: $module" -Level Error
            Write-InvestigationLog "Please install it with: Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser" -Level Warning
            $allModulesPresent = $false
        } else {
            Write-InvestigationLog "Module $module is available" -Level Success
        }
    }
    
    if (!$allModulesPresent) {
        Write-InvestigationLog "Missing required modules. Please install them and try again." -Level Error
        return $false
    }
    
    # Check connections
    try {
        Write-InvestigationLog "Connecting to required services..." -Level Info
        
        # Connect to Exchange Online
        Connect-ExchangeOnline -ErrorAction Stop | Out-Null
        Write-InvestigationLog "Connected to Exchange Online" -Level Success
        
        # Connect to Azure AD
        Connect-AzureAD -ErrorAction Stop | Out-Null
        Write-InvestigationLog "Connected to Azure AD" -Level Success
        
        # Try to connect to MSOL
        try {
            Connect-MsolService -ErrorAction Stop | Out-Null
            Write-InvestigationLog "Connected to Microsoft Online Services" -Level Success
        } catch {
            Write-InvestigationLog "Could not connect to MSOnline Service: $_" -Level Warning
            Write-InvestigationLog "Some functions may be limited" -Level Warning
        }
        
        return $true
    } catch {
        Write-InvestigationLog "Failed to connect to required services: $_" -Level Error
        return $false
    }
}

# Function to verify user account
function Verify-UserAccount {
    param(
        [string]$UserPrincipalName
    )
    
    Write-InvestigationLog "Verifying account $UserPrincipalName..." -Level Info
    
    try {
        # Check if account exists
        $user = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop
        
        if ($user) {
            Write-InvestigationLog "Account $UserPrincipalName found: $($user.DisplayName)" -Level Success
            
            # Record basic account info
            Add-InvestigationFinding -Category "Account Info" `
                                    -Finding "Basic Account Details" `
                                    -Severity "Normal" `
                                    -Details "Display Name: $($user.DisplayName)`nDepartment: $($user.Department)`nTitle: $($user.Title)`nLast Password Change: $($user.LastPasswordChangeTimestamp)`nAccount Created: $($user.WhenCreated)`nBlocked: $($user.BlockCredential)"
            
            return $user
        } else {
            Write-InvestigationLog "Account $UserPrincipalName not found!" -Level Error
            return $null
        }
    } catch {
        Write-InvestigationLog "Error verifying account: $_" -Level Error
        return $null
    }
}

# Function to investigate login activity
function Investigate-LoginActivity {
    param(
        [string]$UserPrincipalName,
        [int]$DaysToLookBack = 7
    )
    
    Write-InvestigationLog "Investigating login activity for $UserPrincipalName over the past $DaysToLookBack days..." -Level Info
    
    try {
        # Define start date
        $startDate = (Get-Date).AddDays(-$DaysToLookBack)
        
        # Get sign-in activity
        $signIns = Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$UserPrincipalName'" -Top 1000 | 
                   Where-Object { $_.CreatedDateTime -ge $startDate }
        
        if ($signIns -and $signIns.Count -gt 0) {
            # Group by location and count
            $locationGroups = $signIns | Group-Object Location | Select-Object Name, Count
            
            # Group by IP and count
            $ipGroups = $signIns | Group-Object IpAddress | Select-Object Name, Count
            
            # Get successful vs failed sign-ins
            $successfulSignIns = $signIns | Where-Object { $_.Status.ErrorCode -eq 0 } 
            $failedSignIns = $signIns | Where-Object { $_.Status.ErrorCode -ne 0 }
            
            # Check for sign-ins from suspicious IPs
            $suspiciousIP1SignIns = $signIns | Where-Object { $_.IpAddress -eq $SuspiciousIP1 } | Sort-Object CreatedDateTime
            $suspiciousIP2SignIns = $signIns | Where-Object { $_.IpAddress -eq $SuspiciousIP2 } | Sort-Object CreatedDateTime
            
            # Generate report on suspicious IPs
            $suspiciousIPDetails = ""
            
            if ($suspiciousIP1SignIns) {
                $suspiciousIPDetails += "IP: $SuspiciousIP1 (United States)`n"
                $suspiciousIPDetails += "Sign-in count: $($suspiciousIP1SignIns.Count)`n"
                $suspiciousIPDetails += "First seen: $($suspiciousIP1SignIns[0].CreatedDateTime)`n"
                $suspiciousIPDetails += "Last seen: $($suspiciousIP1SignIns[-1].CreatedDateTime)`n"
                $suspiciousIPDetails += "Client apps used: $($suspiciousIP1SignIns | Group-Object ClientAppUsed | ForEach-Object { "$($_.Name) ($($_.Count) times)" } -join ", ")`n"
                $suspiciousIPDetails += "Success rate: $([math]::Round(($suspiciousIP1SignIns | Where-Object { $_.Status.ErrorCode -eq 0 }).Count / $suspiciousIP1SignIns.Count * 100))%`n`n"
            } else {
                $suspiciousIPDetails += "IP: $SuspiciousIP1 (United States)`n"
                $suspiciousIPDetails += "No sign-ins detected from this IP in the past $DaysToLookBack days`n`n"
            }
            
            if ($suspiciousIP2SignIns) {
                $suspiciousIPDetails += "IP: $SuspiciousIP2 (South Africa)`n"
                $suspiciousIPDetails += "Sign-in count: $($suspiciousIP2SignIns.Count)`n"
                $suspiciousIPDetails += "First seen: $($suspiciousIP2SignIns[0].CreatedDateTime)`n"
                $suspiciousIPDetails += "Last seen: $($suspiciousIP2SignIns[-1].CreatedDateTime)`n"
                $suspiciousIPDetails += "Client apps used: $($suspiciousIP2SignIns | Group-Object ClientAppUsed | ForEach-Object { "$($_.Name) ($($_.Count) times)" } -join ", ")`n"
                $suspiciousIPDetails += "Success rate: $([math]::Round(($suspiciousIP2SignIns | Where-Object { $_.Status.ErrorCode -eq 0 }).Count / $suspiciousIP2SignIns.Count * 100))%`n`n"
            } else {
                $suspiciousIPDetails += "IP: $SuspiciousIP2 (South Africa)`n"
                $suspiciousIPDetails += "No sign-ins detected from this IP in the past $DaysToLookBack days`n`n"
            }
            
            # Check for impossible travel specifically
            $impossibleTravelFound = $false
            $impossibleTravelDetails = ""
            
            if ($suspiciousIP1SignIns -and $suspiciousIP2SignIns) {
                foreach ($ip1SignIn in $suspiciousIP1SignIns) {
                    foreach ($ip2SignIn in $suspiciousIP2SignIns) {
                        $timeDiff = New-TimeSpan -Start $ip1SignIn.CreatedDateTime -End $ip2SignIn.CreatedDateTime
                        
                        # Check if the time difference is within the suspicious window (375 minutes or 6.25 hours)
                        if ([math]::Abs($timeDiff.TotalMinutes) -lt 375) {
                            $impossibleTravelFound = $true
                            $impossibleTravelDetails += "Impossible travel detected:`n"
                            $impossibleTravelDetails += "  * $($ip1SignIn.CreatedDateTime) - $($ip1SignIn.Location.City), $($ip1SignIn.Location.CountryOrRegion) ($($ip1SignIn.IpAddress))`n"
                            $impossibleTravelDetails += "  * $($ip2SignIn.CreatedDateTime) - $($ip2SignIn.Location.City), $($ip2SignIn.Location.CountryOrRegion) ($($ip2SignIn.IpAddress))`n"
                            $impossibleTravelDetails += "  * Time between: $([math]::Round([math]::Abs($timeDiff.TotalMinutes), 2)) minutes`n`n"
                        }
                    }
                }
            }
            
            # Record findings
            $severity = "Normal"
            $details = "Total sign-ins: $($signIns.Count)`nSuccessful sign-ins: $($successfulSignIns.Count)`nFailed sign-ins: $($failedSignIns.Count)`n`n"
            $details += "Sign-ins by location:`n"
            foreach ($loc in $locationGroups) {
                $details += "  * $($loc.Name) - $($loc.Count) sign-ins`n"
            }
            $details += "`nSign-ins by IP address:`n"
            foreach ($ip in $ipGroups) {
                $details += "  * $($ip.Name) - $($ip.Count) sign-ins`n"
            }
            
            $details += "`n==== SUSPICIOUS IP ANALYSIS ====`n$suspiciousIPDetails"
            
            if ($impossibleTravelFound) {
                $severity = "Suspicious"
                $details += "==== IMPOSSIBLE TRAVEL ANALYSIS ====`n$impossibleTravelDetails"
            }
            
            Add-InvestigationFinding -Category "Login Activity" `
                                    -Finding "Sign-in patterns analyzed" `
                                    -Severity $severity `
                                    -Details $details
            
            # Return the sign-in logs for further processing
            return $signIns
        } else {
            Add-InvestigationFinding -Category "Login Activity" `
                                    -Finding "No recent sign-ins" `
                                    -Severity "Suspicious" `
                                    -Details "No sign-in activity found for the past $DaysToLookBack days"
            
            return $null
        }
    } catch {
        Write-InvestigationLog "Error investigating login activity: $_" -Level Error
        Add-InvestigationFinding -Category "Login Activity" `
                                -Finding "Error analyzing sign-ins" `
                                -Severity "Normal" `
                                -Details "Error: $_"
        return $null
    }
}

# Function to investigate inbox rules
function Investigate-InboxRules {
    param(
        [string]$UserPrincipalName
    )
    
    Write-InvestigationLog "Investigating inbox rules for $UserPrincipalName..." -Level Info
    
    try {
        # Get inbox rules
        $inboxRules = Get-InboxRule -Mailbox $UserPrincipalName
        
        if ($inboxRules -and $inboxRules.Count -gt 0) {
            $severity = "Normal"
            $details = "Total rules: $($inboxRules.Count)`n`n"
            
            # Suspicious patterns to look for
            $suspiciousRuleCount = 0
            
            foreach ($rule in $inboxRules) {
                $isRuleSuspicious = $false
                $ruleDetails = "Rule: $($rule.Name)`n"
                $ruleDetails += "  * Enabled: $($rule.Enabled)`n"
                
                if ($rule.ForwardTo -or $rule.ForwardAsAttachmentTo -or $rule.RedirectTo) {
                    $isRuleSuspicious = $true
                    $ruleDetails += "  * [SUSPICIOUS] Forwarding: "
                    
                    if ($rule.ForwardTo) { $ruleDetails += "Forward to: $($rule.ForwardTo)" }
                    if ($rule.ForwardAsAttachmentTo) { $ruleDetails += "Forward as attachment to: $($rule.ForwardAsAttachmentTo)" }
                    if ($rule.RedirectTo) { $ruleDetails += "Redirect to: $($rule.RedirectTo)" }
                    
                    $ruleDetails += "`n"
                }
                
                if ($rule.DeleteMessage -eq $true) {
                    $isRuleSuspicious = $true
                    $ruleDetails += "  * [SUSPICIOUS] Automatically deletes messages`n"
                }
                
                if ($rule.MoveToFolder -eq "Deleted Items" -or $rule.MoveToFolder -eq "Junk Email") {
                    $isRuleSuspicious = $true
                    $ruleDetails += "  * [SUSPICIOUS] Moves messages to $($rule.MoveToFolder) folder`n"
                }
                
                $details += "$ruleDetails`n"
                
                if ($isRuleSuspicious) {
                    $suspiciousRuleCount++
                    $severity = "Suspicious"
                }
            }
            
            if ($suspiciousRuleCount -gt 0) {
                $details = $details.TrimEnd("`n")
                $details += "`n`nPOTENTIALLY MALICIOUS: Found $suspiciousRuleCount suspicious inbox rules"
                
                if ($suspiciousRuleCount -gt 2) {
                    $severity = "Malicious"
                }
            }
            
            Add-InvestigationFinding -Category "Inbox Rules" `
                                    -Finding "Inbox rules analyzed" `
                                    -Severity $severity `
                                    -Details $details
        } else {
            Add-InvestigationFinding -Category "Inbox Rules" `
                                    -Finding "No inbox rules found" `
                                    -Severity "Normal" `
                                    -Details "No inbox rules configured for this mailbox"
        }
    } catch {
        Write-InvestigationLog "Error investigating inbox rules: $_" -Level Error
        Add-InvestigationFinding -Category "Inbox Rules" `
                                -Finding "Error analyzing inbox rules" `
                                -Severity "Normal" `
                                -Details "Error: $_"
    }
}

# Function to investigate email forwarding
function Investigate-EmailForwarding {
    param(
        [string]$UserPrincipalName
    )
    
    Write-InvestigationLog "Investigating email forwarding for $UserPrincipalName..." -Level Info
    
    try {
        # Check mailbox forwarding settings
        $mailbox = Get-Mailbox -Identity $UserPrincipalName
        
        $severity = "Normal"
        $details = ""
        
        if ($mailbox.ForwardingAddress -or $mailbox.ForwardingSmtpAddress -or $mailbox.DeliverToMailboxAndForward) {
            $severity = "Suspicious"
            $details = "Email forwarding is configured:`n"
            
            if ($mailbox.ForwardingAddress) {
                $details += "  * Internal forwarding to: $($mailbox.ForwardingAddress)`n"
            }
            
            if ($mailbox.ForwardingSmtpAddress) {
                $details += "  * External forwarding to: $($mailbox.ForwardingSmtpAddress.Replace('SMTP:', ''))`n"
            }
            
            $details += "  * Deliver to mailbox and forward: $($mailbox.DeliverToMailboxAndForward)`n"
        } else {
            $details = "No email forwarding configured on this mailbox"
        }
        
        Add-InvestigationFinding -Category "Email Forwarding" `
                                -Finding "Mailbox forwarding settings" `
                                -Severity $severity `
                                -Details $details
    } catch {
        Write-InvestigationLog "Error investigating email forwarding: $_" -Level Error
        Add-InvestigationFinding -Category "Email Forwarding" `
                                -Finding "Error analyzing forwarding settings" `
                                -Severity "Normal" `
                                -Details "Error: $_"
    }
}

# Function to reset user password
function Reset-UserPassword {
    param(
        [string]$UserPrincipalName
    )
    
    Write-InvestigationLog "Resetting password for $UserPrincipalName..." -Level Info
    
    try {
        # Generate a strong password
        $length = 16
        $nonAlphaChars = 5
        $password = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)
        
        # Reset the password and force change at next login
        Set-MsolUserPassword -UserPrincipalName $UserPrincipalName -NewPassword $password -ForceChangePassword $true
        
        Add-InvestigationFinding -Category "Remediation" `
                               -Finding "Password reset" `
                               -Severity "Normal" `
                               -Details "Password was reset successfully. User will be forced to change password at next login."
        
        Write-InvestigationLog "Temporary password: $password" -Level Warning
        Write-InvestigationLog "IMPORTANT: Securely communicate this password to the user" -Level Warning
        
        return $password
    } catch {
        Write-InvestigationLog "Error resetting password: $_" -Level Error
        Add-InvestigationFinding -Category "Remediation" `
                               -Finding "Password reset failed" `
                               -Severity "Suspicious" `
                               -Details "Error: $_"
        
        return $null
    }
}

# Function to add IPs to conditional access block list
function Block-SuspiciousIPs {
    param(
        [string[]]$IPAddresses
    )
    
    Write-InvestigationLog "Adding suspicious IPs to block list..." -Level Info
    
    try {
        # NOTE: This is a simplified example. In a real scenario, you would use Conditional Access policies
        # or Microsoft Defender for Cloud Apps to block these IPs. This requires appropriate licensing and permissions.
        
        # For now, we'll just record the action and recommend next steps
        $ipList = $IPAddresses -join ", "
        
        Add-InvestigationFinding -Category "Remediation" `
                               -Finding "IP blocking recommendation" `
                               -Severity "Normal" `
                               -Details "The following IPs should be blocked through Conditional Access policies or added as named locations in Azure AD:`n$ipList"
        
        Write-InvestigationLog "To block these IPs, go to Azure AD > Security > Named locations and add these IPs as blocked named locations" -Level Warning
        
        return $true
    } catch {
        Write-InvestigationLog "Error processing IP block list: $_" -Level Error
        Add-InvestigationFinding -Category "Remediation" `
                               -Finding "IP blocking failed" `
                               -Severity "Suspicious" `
                               -Details "Error: $_"
        
        return $false
    }
}

# Function to generate the investigation report
function Generate-InvestigationReport {
    param(
        [string]$UserPrincipalName,
        [string]$OutputPath
    )
    
    Write-InvestigationLog "Generating investigation report for $UserPrincipalName..." -Level Info
    
    # Create folder if it doesn't exist
    if (!(Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = Join-Path -Path $OutputPath -ChildPath "ImpossibleTravelInvestigation_${timestamp}.html"
    
    # Count findings by severity
    $normalCount = ($InvestigationFindings | Where-Object { $_.Severity -eq "Normal" }).Count
    $suspiciousCount = ($InvestigationFindings | Where-Object { $_.Severity -eq "Suspicious" }).Count
    $maliciousCount = ($InvestigationFindings | Where-Object { $_.Severity -eq "Malicious" }).Count
    
    # Determine overall risk level
    $overallRisk = "Low"
    if ($maliciousCount -gt 0) {
        $overallRisk = "Critical"
    } elseif ($suspiciousCount -gt 2) {
        $overallRisk = "High"
    } elseif ($suspiciousCount -gt 0) {
        $overallRisk = "Medium"
    }
    
    # Generate HTML
    $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Impossible Travel Investigation Report - $UserPrincipalName</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0066cc; }
        h2 { color: #0066cc; margin-top: 20px; border-bottom: 1px solid #ccc; padding-bottom: 5px; }
        .summary { background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 15px 0; }
        .finding { margin: 10px 0; padding: 10px; border-radius: 5px; }
        .normal { background-color: #e8f4f8; border-left: 5px solid #5bc0de; }
        .suspicious { background-color: #fff8e1; border-left: 5px solid #ffb300; }
        .malicious { background-color: #ffebee; border-left: 5px solid #f44336; }
        .finding-header { font-weight: bold; margin-bottom: 5px; }
        .finding-details { white-space: pre-wrap; font-family: Consolas, monospace; font-size: 0.9em; }
        .risk-low { background-color: #dff0d8; padding: 5px 10px; border-radius: 3px; }
        .risk-medium { background-color: #fcf8e3; padding: 5px 10px; border-radius: 3px; }
        .risk-high { background-color: #f2dede; padding: 5px 10px; border-radius: 3px; }
        .risk-critical { background-color: #f44336; color: white; padding: 5px 10px; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>Impossible Travel Investigation Report</h1>
    <div class="summary">
        <p><strong>Account:</strong> $UserPrincipalName</p>
        <p><strong>Investigation Date:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Overall Risk Assessment:</strong> 
            <span class="risk-$($overallRisk.ToLower())">$overallRisk</span>
        </p>
        <p><strong>Findings Summary:</strong> $($InvestigationFindings.Count) total findings ($normalCount normal, $suspiciousCount suspicious, $maliciousCount malicious)</p>
        <p><strong>Suspicious IPs Analyzed:</strong></p>
        <ul>
            <li>$SuspiciousIP1 (United States)</li>
            <li>$SuspiciousIP2 (South Africa)</li>
        </ul>
    </div>
    
    <h2>Detailed Findings</h2>
"@

    $htmlFindings = ""
    foreach ($finding in $InvestigationFindings | Sort-Object -Property Severity, Category) {
        $htmlFindings += @"
    <div class="finding $($finding.Severity.ToLower())">
        <div class="finding-header">[$($finding.Category)] $($finding.Finding) - $($finding.Severity)</div>
        <div class="finding-details">$($finding.Details)</div>
    </div>
"@
    }

    $htmlFooter = @"
    <h2>Recommended Actions</h2>
    <div class="finding normal">
        <div class="finding-details">
1. Classify the reported IPs as VPN connections in Microsoft Defender for Cloud Apps if they are known VPN endpoints.
2. Verify with the user if they were actually traveling or using VPN services.
3. Update anti-virus software on the user's machine.
4. Enable the phishing reporting icon plugin for emails.
5. Consider implementing Multi-Factor Authentication if not already enabled.
6. Review and update Conditional Access policies to account for legitimate VPN usage.
7. Provide security awareness training to the user about proper VPN usage and reporting suspicious activities.
        </div>
    </div>

    <p>Report generated by the Impossible Travel Investigation Tool</p>
</body>
</html>
"@

    $htmlContent = $htmlHeader + $htmlFindings + $htmlFooter
    $htmlContent | Out-File -FilePath $reportFile -Force
    
    Write-InvestigationLog "Investigation report generated: $reportFile" -Level Success
    
    # Also save a CSV version for reference
    $csvFile = Join-Path -Path $OutputPath -ChildPath "ImpossibleTravelInvestigation_${timestamp}.csv"
    $InvestigationFindings | Export-Csv -Path $csvFile -NoTypeInformation
    
    Write-InvestigationLog "CSV data saved: $csvFile" -Level Success
    
    return $reportFile
}

# Main execution flow
Write-InvestigationLog "Impossible Travel Investigation Tool" -Level Info
Write-InvestigationLog "Starting investigation for $UserPrincipalName on $(Get-Date)" -Level Info

# Check prerequisites
if (Test-Prerequisites) {
    # Verify the user account
    $user = Verify-UserAccount -UserPrincipalName $UserPrincipalName
    
    if ($user) {
        # Investigate login activity (always check this for impossible travel incidents)
        $signInLogs = Investigate-LoginActivity -UserPrincipalName $UserPrincipalName -DaysToLookBack 14
        
        # If full investigation is requested, check additional aspects
        if ($FullInvestigation) {
            Investigate-InboxRules -UserPrincipalName $UserPrincipalName
            Investigate-EmailForwarding -UserPrincipalName $UserPrincipalName
        }
        
        # Reset password if requested
        if ($ResetPassword) {
            Reset-UserPassword -UserPrincipalName $UserPrincipalName
        }
        
        # Block suspicious IPs if requested
        if ($BlockSuspiciousIPs) {
            Block-SuspiciousIPs -IPAddresses @($SuspiciousIP1, $SuspiciousIP2)
        }
        
        # Generate the investigation report
        $reportFile = Generate-InvestigationReport -UserPrincipalName $UserPrincipalName -OutputPath $OutputPath
        
        Write-InvestigationLog "`n======================================================" -Level Info
        Write-InvestigationLog "INVESTIGATION SUMMARY" -Level Info
        Write-InvestigationLog "======================================================" -Level Info
        
        # Count suspicious findings
        $suspiciousCount = ($InvestigationFindings | Where-Object { $_.Severity -eq "Suspicious" }).Count
        $maliciousCount = ($InvestigationFindings | Where-Object { $_.Severity -eq "Malicious" }).Count
        
        if ($maliciousCount -gt 0) {
            Write-InvestigationLog "HIGH RISK: Account shows strong indicators of compromise!" -Level Error
            Write-InvestigationLog "Recommended actions:" -Level Warning
            Write-InvestigationLog "1. Reset the user's password immediately" -Level Warning
            Write-InvestigationLog "2. Enable MFA if not already enabled" -Level Warning
            Write-InvestigationLog "3. Block suspicious IPs through Conditional Access policies" -Level Warning
            Write-InvestigationLog "4. Investigate the user's device for malware" -Level Warning
        } elseif ($suspiciousCount -gt 0) {
            Write-InvestigationLog "MEDIUM RISK: Account shows some suspicious activity" -Level Warning
            Write-InvestigationLog "Recommended actions:" -Level Warning
            Write-InvestigationLog "1. Verify with the user if they were traveling or using VPN services" -Level Warning
            Write-InvestigationLog "2. Update anti-virus software on the user's machine" -Level Warning
            Write-InvestigationLog "3. Enable the phishing reporting icon plugin for emails" -Level Warning
        } else {
            Write-InvestigationLog "LOW RISK: This appears to be a false positive" -Level Success
            Write-InvestigationLog "Recommended actions:" -Level Info
            Write-InvestigationLog "1. Classify the IPs as VPN connections in Microsoft Defender for Cloud Apps" -Level Info
            Write-InvestigationLog "2. Update security tools on the user's device as a precaution" -Level Info
        }
        
        Write-InvestigationLog "`nDetailed report saved to: $reportFile" -Level Success
    } else {
        Write-InvestigationLog "Cannot proceed: User account not found or accessible" -Level Error
    }
    
    # Disconnect from services
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        Disconnect-AzureAD -ErrorAction SilentlyContinue
        Write-InvestigationLog "Disconnected from Microsoft 365 services" -Level Info
    } catch {
        Write-InvestigationLog "Error disconnecting from services: $_" -Level Warning
    }
} else {
    Write-InvestigationLog "Prerequisites check failed. Cannot continue." -Level Error
}
