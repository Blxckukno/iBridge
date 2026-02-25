# Verify Email Policy Configuration
# This script verifies that the email policies have been configured correctly

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = ".\config\email-config.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = ""
)

# Import configuration
if (Test-Path $ConfigFile) {
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    Write-Host "Configuration loaded from $ConfigFile" -ForegroundColor Green
} else {
    Write-Error "Configuration file not found: $ConfigFile"
    exit 1
}

# Check Exchange Online connection
try {
    # First try to import the module
    Import-Module ExchangeOnlineManagement -Force -ErrorAction Stop
    
    # Try to get connection information
    $connection = Get-ConnectionInformation -ErrorAction SilentlyContinue
    
    if ($connection -and $connection.State -eq "Connected") {
        Write-Host "✅ Connected to Exchange Online as: $($connection.UserPrincipalName)" -ForegroundColor Green
    } else {
        Write-Host "🔌 Not connected to Exchange Online. Attempting to connect..." -ForegroundColor Yellow
        Connect-ExchangeOnline -ErrorAction Stop
        
        # Verify connection
        $connection = Get-ConnectionInformation -ErrorAction Stop
        if ($connection.State -eq "Connected") {
            Write-Host "✅ Successfully connected to Exchange Online as: $($connection.UserPrincipalName)" -ForegroundColor Green
        } else {
            throw "Failed to establish connection"
        }
    }
}
catch {
    Write-Host "❌ Failed to connect to Exchange Online: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure you have proper permissions and try again." -ForegroundColor Red
    exit 1
}

# Initialize results
$results = @{
    SharedMailboxes = @()
    TransportRules = @()
    DistributionGroups = @()
    Summary = @{
        TotalChecks = 0
        PassedChecks = 0
        FailedChecks = 0
        Warnings = 0
    }
}

Write-Host "Starting Email Policy Verification" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray

# Function to test mailbox permissions
function Test-MailboxPermissions {
    param(
        [string]$MailboxIdentity,
        [array]$ExpectedAuthorizedUsers
    )
    
    $mailboxResult = @{
        Mailbox = $MailboxIdentity
        Status = "Unknown"
        Issues = @()
        Permissions = @()
    }
    
    try {
        # Check if mailbox exists
        $mailbox = Get-Mailbox -Identity $MailboxIdentity -ErrorAction Stop
        $mailboxResult.Status = "Found"
        
        # Get current permissions
        $sendAsPermissions = Get-RecipientPermission -Identity $MailboxIdentity | Where-Object {$_.Trustee -ne "NT AUTHORITY\SELF"}
        $mailboxPermissions = Get-MailboxPermission -Identity $MailboxIdentity | Where-Object {$_.User -ne "NT AUTHORITY\SELF"}
        
        # Check SendAs permissions
        $currentSendAsUsers = $sendAsPermissions.Trustee
        foreach ($expectedUser in $ExpectedAuthorizedUsers) {
            $hasPermission = $currentSendAsUsers -contains $expectedUser
            $permissionStatus = @{
                User = $expectedUser
                Permission = "SendAs"
                HasAccess = $hasPermission
            }
            $mailboxResult.Permissions += $permissionStatus
            
            if (-not $hasPermission) {
                $mailboxResult.Issues += "Missing SendAs permission for: $expectedUser"
                $results.Summary.FailedChecks++
            } else {
                $results.Summary.PassedChecks++
            }
            $results.Summary.TotalChecks++
        }
        
        # Check for unauthorized SendAs permissions
        foreach ($permission in $sendAsPermissions) {
            if ($permission.Trustee -notin $ExpectedAuthorizedUsers) {
                $mailboxResult.Issues += "Unauthorized SendAs permission found: $($permission.Trustee)"
                $results.Summary.Warnings++
            }
        }
        
        if ($Detailed) {
            Write-Host "    SendAs Permissions:" -ForegroundColor Gray
            foreach ($permission in $sendAsPermissions) {
                $status = if ($permission.Trustee -in $ExpectedAuthorizedUsers) { "✓" } else { "⚠" }
                Write-Host "      $status $($permission.Trustee)" -ForegroundColor $(if($permission.Trustee -in $ExpectedAuthorizedUsers){"Green"}else{"Yellow"})
            }
        }
    }
    catch {
        $mailboxResult.Status = "Not Found"
        $mailboxResult.Issues += "Mailbox not found or access denied: $($_.Exception.Message)"
        $results.Summary.FailedChecks++
        $results.Summary.TotalChecks++
    }
    
    return $mailboxResult
}

# Function to test transport rules
function Test-TransportRules {
    param(
        [array]$SharedMailboxes,
        [array]$AuthorizedUsers
    )
    
    $transportRulesResult = @()
    
    foreach ($mailbox in $SharedMailboxes) {
        $expectedRuleName = "Restrict-$($mailbox.DisplayName.Replace(' ', ''))-Sending"
        
        try {
            $rule = Get-TransportRule -Identity $expectedRuleName -ErrorAction Stop
            
            $ruleResult = @{
                RuleName = $expectedRuleName
                Status = "Found"
                Enabled = $rule.State -eq "Enabled"
                Issues = @()
            }
            
            # Verify rule configuration
            if ($rule.From -notcontains $mailbox.EmailAddress) {
                $ruleResult.Issues += "Rule does not target correct mailbox: $($mailbox.EmailAddress)"
                $results.Summary.FailedChecks++
            } else {
                $results.Summary.PassedChecks++
            }
            
            if ($rule.State -ne "Enabled") {
                $ruleResult.Issues += "Rule is not enabled"
                $results.Summary.FailedChecks++
            } else {
                $results.Summary.PassedChecks++
            }
            
            $results.Summary.TotalChecks += 2
            
        }
        catch {
            $ruleResult = @{
                RuleName = $expectedRuleName
                Status = "Not Found"
                Enabled = $false
                Issues = @("Transport rule not found")
            }
            $results.Summary.FailedChecks++
            $results.Summary.TotalChecks++
        }
        
        $transportRulesResult += $ruleResult
    }
    
    return $transportRulesResult
}

# Function to test distribution group moderation
function Test-DistributionGroups {
    param(
        [array]$DistributionGroups,
        [array]$AuthorizedUsers
    )
    
    $groupResults = @()
    
    foreach ($group in $DistributionGroups) {
        try {
            $distributionGroup = Get-DistributionGroup -Identity $group.EmailAddress -ErrorAction Stop
            
            $groupResult = @{
                GroupName = $group.DisplayName
                EmailAddress = $group.EmailAddress
                Status = "Found"
                ModerationEnabled = $distributionGroup.ModerationEnabled
                Issues = @()
            }
            
            # Check moderation settings
            if (-not $distributionGroup.ModerationEnabled) {
                $groupResult.Issues += "Moderation is not enabled"
                $results.Summary.FailedChecks++
            } else {
                $results.Summary.PassedChecks++
            }
            
            # Check moderators
            $moderators = $distributionGroup.ModeratedBy
            $missingModerators = $AuthorizedUsers | Where-Object { $_ -notin $moderators }
            if ($missingModerators) {
                $groupResult.Issues += "Missing moderators: $($missingModerators -join ', ')"
                $results.Summary.FailedChecks++
            } else {
                $results.Summary.PassedChecks++
            }
            
            $results.Summary.TotalChecks += 2
            
        }
        catch {
            $groupResult = @{
                GroupName = $group.DisplayName
                EmailAddress = $group.EmailAddress
                Status = "Not Found"
                ModerationEnabled = $false
                Issues = @("Distribution group not found")
            }
            $results.Summary.FailedChecks++
            $results.Summary.TotalChecks++
        }
        
        $groupResults += $groupResult
    }
    
    return $groupResults
}

# Main verification process
Write-Host "`n--- Verifying Shared Mailboxes ---" -ForegroundColor Magenta
foreach ($mailbox in $config.SharedMailboxes) {
    Write-Host "Checking mailbox: $($mailbox.DisplayName) ($($mailbox.EmailAddress))" -ForegroundColor Yellow
    $mailboxResult = Test-MailboxPermissions -MailboxIdentity $mailbox.EmailAddress -ExpectedAuthorizedUsers $config.AuthorizedUsers
    $results.SharedMailboxes += $mailboxResult
    
    if ($mailboxResult.Issues.Count -eq 0) {
        Write-Host "  ✓ All permissions configured correctly" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Issues found:" -ForegroundColor Red
        foreach ($issue in $mailboxResult.Issues) {
            Write-Host "    - $issue" -ForegroundColor Red
        }
    }
}

Write-Host "`n--- Verifying Transport Rules ---" -ForegroundColor Magenta
$results.TransportRules = Test-TransportRules -SharedMailboxes $config.SharedMailboxes -AuthorizedUsers $config.AuthorizedUsers
foreach ($rule in $results.TransportRules) {
    $status = if ($rule.Status -eq "Found" -and $rule.Enabled -and $rule.Issues.Count -eq 0) { "✓" } else { "✗" }
    $color = if ($status -eq "✓") { "Green" } else { "Red" }
    Write-Host "$status Transport Rule: $($rule.RuleName)" -ForegroundColor $color
    
    if ($rule.Issues.Count -gt 0) {
        foreach ($issue in $rule.Issues) {
            Write-Host "    - $issue" -ForegroundColor Red
        }
    }
}

if ($config.DistributionGroups) {
    Write-Host "`n--- Verifying Distribution Groups ---" -ForegroundColor Magenta
    $results.DistributionGroups = Test-DistributionGroups -DistributionGroups $config.DistributionGroups -AuthorizedUsers $config.AuthorizedUsers
    foreach ($group in $results.DistributionGroups) {
        $status = if ($group.Status -eq "Found" -and $group.ModerationEnabled -and $group.Issues.Count -eq 0) { "✓" } else { "✗" }
        $color = if ($status -eq "✓") { "Green" } else { "Red" }
        Write-Host "$status Distribution Group: $($group.GroupName)" -ForegroundColor $color
        
        if ($group.Issues.Count -gt 0) {
            foreach ($issue in $group.Issues) {
                Write-Host "    - $issue" -ForegroundColor Red
            }
        }
    }
}

# Summary
Write-Host "`n=== Verification Summary ===" -ForegroundColor Cyan
Write-Host "Total Checks: $($results.Summary.TotalChecks)" -ForegroundColor White
Write-Host "Passed: $($results.Summary.PassedChecks)" -ForegroundColor Green
Write-Host "Failed: $($results.Summary.FailedChecks)" -ForegroundColor Red
Write-Host "Warnings: $($results.Summary.Warnings)" -ForegroundColor Yellow

$successRate = if ($results.Summary.TotalChecks -gt 0) { 
    [math]::Round(($results.Summary.PassedChecks / $results.Summary.TotalChecks) * 100, 2) 
} else { 0 }

Write-Host "Success Rate: $successRate%" -ForegroundColor $(if($successRate -gt 80){"Green"}elseif($successRate -gt 60){"Yellow"}else{"Red"})

# Save results to file if specified
if ($OutputFile) {
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "`nDetailed results saved to: $OutputFile" -ForegroundColor Cyan
}

Write-Host "`nVerification complete!" -ForegroundColor Green
