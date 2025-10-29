#Requires -Modules Microsoft.Graph.Groups, Microsoft.Graph.Users, ExchangeOnlineManagement
<#
.SYNOPSIS
    Specialized script to handle Office 365 groups using Microsoft Graph PowerShell
    
.DESCRIPTION
    This script handles Office 365 groups (like "Senior Managers") that cannot be managed
    through Exchange Online cmdlets due to scope restrictions. It uses Microsoft Graph
    PowerShell to manage group ownership and membership.
    
.PARAMETER TargetAdmin
    The email address of the admin user to grant full rights to
    
.PARAMETER RemoveUser
    The email address of the user to remove from admin roles
    
.PARAMETER WhatIf
    Show what changes would be made without actually making them
    
.PARAMETER Verbose
    Enable verbose logging
    
.EXAMPLE
    .\Fix-Office365-Groups.ps1 -TargetAdmin "lwandile.gasela@ibridge.co.za" -RemoveUser "mgqibelo.gasela@ibridge.co.za"
    
.EXAMPLE
    .\Fix-Office365-Groups.ps1 -TargetAdmin "lwandile.gasela@ibridge.co.za" -WhatIf
    
.NOTES
    Author: Microsoft 365 Policy Management System
    Requires: Microsoft Graph PowerShell SDK, Exchange Online PowerShell
    
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$TargetAdmin = "lwandile.gasela@ibridge.co.za",
    
    [Parameter(Mandatory = $false)]
    [string]$RemoveUser = "mgqibelo.gasela@ibridge.co.za"
)

# Initialize logging
$LogFile = "..\\logs\\Fix-Office365-Groups-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$ResultsFile = "..\\logs\\Fix-Office365-Groups-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$Results = @{
    Timestamp = Get-Date
    TargetAdmin = $TargetAdmin
    RemoveUser = $RemoveUser
    WhatIf = $WhatIfPreference
    ProcessedGroups = @()
    Summary = @{
        Total = 0
        Success = 0
        Failed = 0
        Skipped = 0
    }
    Errors = @()
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
    Add-Content -Path $LogFile -Value $logEntry
}

function Connect-ToServices {
    Write-Log "Connecting to required services..."
    
    # Connect to Microsoft Graph
    try {
        $context = Get-MgContext
        if (-not $context) {
            Write-Log "Connecting to Microsoft Graph..."
            Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All", "Directory.Read.All" -NoWelcome
            Write-Log "Successfully connected to Microsoft Graph" -Level "SUCCESS"
        } else {
            Write-Log "Already connected to Microsoft Graph" -Level "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to connect to Microsoft Graph: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
    
    # Connect to Exchange Online
    try {
        $exoSession = Get-PSSession | Where-Object { $_.Name -like "*ExchangeOnline*" -and $_.State -eq "Opened" }
        if (-not $exoSession) {
            Write-Log "Connecting to Exchange Online..."
            Connect-ExchangeOnline -ShowBanner:$false
            Write-Log "Successfully connected to Exchange Online" -Level "SUCCESS"
        } else {
            Write-Log "Already connected to Exchange Online" -Level "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to connect to Exchange Online: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
    
    return $true
}

function Get-UserByEmail {
    param([string]$Email)
    
    try {
        $user = Get-MgUser -Filter "mail eq '$Email' or userPrincipalName eq '$Email'" -ErrorAction Stop
        if ($user) {
            return $user
        }
        
        # Try alternative search
        $user = Get-MgUser -All | Where-Object { $_.Mail -eq $Email -or $_.UserPrincipalName -eq $Email }
        return $user
    }
    catch {
        Write-Log "Failed to find user $Email`: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Get-Office365Groups {
    Write-Log "Discovering Office 365 groups..."
    
    try {
        # Get all Office 365 groups (GroupTypes contains "Unified")
        $groups = Get-MgGroup -All | Where-Object { $_.GroupTypes -contains "Unified" }
        
        Write-Log "Found $($groups.Count) Office 365 groups"
        
        # Also check for any groups that might be causing issues in Exchange
        $exchangeGroups = @()
        try {
            $exchangeGroups = Get-DistributionGroup -ResultSize Unlimited | Where-Object { $_.GroupType -eq "GroupMailbox" }
            Write-Log "Found $($exchangeGroups.Count) GroupMailbox type groups in Exchange"
        }
        catch {
            Write-Log "Could not query Exchange groups: $($_.Exception.Message)" -Level "WARNING"
        }
        
        # Combine and deduplicate
        $allGroups = @()
        foreach ($group in $groups) {
            $allGroups += [PSCustomObject]@{
                Id = $group.Id
                DisplayName = $group.DisplayName
                Mail = $group.Mail
                Source = "Graph"
                GroupType = "Office365"
            }
        }
        
        foreach ($group in $exchangeGroups) {
            if ($allGroups.DisplayName -notcontains $group.DisplayName) {
                $allGroups += [PSCustomObject]@{
                    Id = $group.ExternalDirectoryObjectId
                    DisplayName = $group.DisplayName
                    Mail = $group.PrimarySmtpAddress
                    Source = "Exchange"
                    GroupType = "GroupMailbox"
                }
            }
        }
        
        return $allGroups
    }
    catch {
        Write-Log "Failed to get Office 365 groups: $($_.Exception.Message)" -Level "ERROR"
        return @()
    }
}

function Update-Office365Group {
    param(
        [PSCustomObject]$Group,
        [PSCustomObject]$TargetAdminUser,
        [PSCustomObject]$RemoveAdminUser
    )
    
    $groupResult = [PSCustomObject]@{
        GroupName = $Group.DisplayName
        GroupId = $Group.Id
        GroupMail = $Group.Mail
        Source = $Group.Source
        Success = $false
        Actions = @()
        Errors = @()
        CurrentOwners = @()
        CurrentMembers = @()
        FinalOwners = @()
        FinalMembers = @()
    }
    
    $Results.ProcessedGroups += $groupResult
    
    try {
        Write-Log "Processing Office 365 group: $($Group.DisplayName)"
        
        # Get current owners
        $currentOwners = Get-MgGroupOwner -GroupId $Group.Id
        $groupResult.CurrentOwners = $currentOwners | ForEach-Object {
            $owner = Get-MgUser -UserId $_.Id -ErrorAction SilentlyContinue
            if ($owner) { $owner.UserPrincipalName } else { $_.Id }
        }
        
        # Get current members
        $currentMembers = Get-MgGroupMember -GroupId $Group.Id
        $groupResult.CurrentMembers = $currentMembers | ForEach-Object {
            $member = Get-MgUser -UserId $_.Id -ErrorAction SilentlyContinue
            if ($member) { $member.UserPrincipalName } else { $_.Id }
        }
        
        Write-Log "Current owners: $($groupResult.CurrentOwners -join ', ')"
        Write-Log "Current members: $($groupResult.CurrentMembers -join ', ')"
        
        # Process ownership changes
        
        # Add target admin as owner if not already
        $isTargetOwner = $currentOwners | Where-Object { $_.Id -eq $TargetAdminUser.Id }
        if (-not $isTargetOwner) {
            if ($WhatIfPreference) {
                Write-Log "[WHATIF] Would add $($TargetAdminUser.UserPrincipalName) as owner of $($Group.DisplayName)" -Level "WARNING"
                $groupResult.Actions += "Would add $($TargetAdminUser.UserPrincipalName) as owner"
            } else {
                try {
                    New-MgGroupOwner -GroupId $Group.Id -DirectoryObjectId $TargetAdminUser.Id
                    Write-Log "✅ Added $($TargetAdminUser.UserPrincipalName) as owner of $($Group.DisplayName)" -Level "SUCCESS"
                    $groupResult.Actions += "Added $($TargetAdminUser.UserPrincipalName) as owner"
                }
                catch {
                    $errorMsg = "Failed to add $($TargetAdminUser.UserPrincipalName) as owner: $($_.Exception.Message)"
                    Write-Log $errorMsg -Level "ERROR"
                    $groupResult.Errors += $errorMsg
                }
            }
        } else {
            Write-Log "✅ $($TargetAdminUser.UserPrincipalName) is already owner of $($Group.DisplayName)" -Level "SUCCESS"
            $groupResult.Actions += "$($TargetAdminUser.UserPrincipalName) already owner"
        }
        
        # Add target admin as member if not already
        $isTargetMember = $currentMembers | Where-Object { $_.Id -eq $TargetAdminUser.Id }
        if (-not $isTargetMember) {
            if ($WhatIfPreference) {
                Write-Log "[WHATIF] Would add $($TargetAdminUser.UserPrincipalName) as member of $($Group.DisplayName)" -Level "WARNING"
                $groupResult.Actions += "Would add $($TargetAdminUser.UserPrincipalName) as member"
            } else {
                try {
                    New-MgGroupMember -GroupId $Group.Id -DirectoryObjectId $TargetAdminUser.Id
                    Write-Log "✅ Added $($TargetAdminUser.UserPrincipalName) as member of $($Group.DisplayName)" -Level "SUCCESS"
                    $groupResult.Actions += "Added $($TargetAdminUser.UserPrincipalName) as member"
                }
                catch {
                    $errorMsg = "Failed to add $($TargetAdminUser.UserPrincipalName) as member: $($_.Exception.Message)"
                    Write-Log $errorMsg -Level "ERROR"
                    $groupResult.Errors += $errorMsg
                }
            }
        } else {
            Write-Log "✅ $($TargetAdminUser.UserPrincipalName) is already member of $($Group.DisplayName)" -Level "SUCCESS"
            $groupResult.Actions += "$($TargetAdminUser.UserPrincipalName) already member"
        }
        
        # Remove specified user from ownership but keep as member
        if ($RemoveAdminUser) {
            $isRemoveUserOwner = $currentOwners | Where-Object { $_.Id -eq $RemoveAdminUser.Id }
            if ($isRemoveUserOwner) {
                if ($WhatIfPreference) {
                    Write-Log "[WHATIF] Would remove $($RemoveAdminUser.UserPrincipalName) from owner role of $($Group.DisplayName)" -Level "WARNING"
                    $groupResult.Actions += "Would remove $($RemoveAdminUser.UserPrincipalName) from owner role"
                } else {
                    try {
                        Remove-MgGroupOwnerByRef -GroupId $Group.Id -DirectoryObjectId $RemoveAdminUser.Id
                        Write-Log "✅ Removed $($RemoveAdminUser.UserPrincipalName) from owner role of $($Group.DisplayName)" -Level "SUCCESS"
                        $groupResult.Actions += "Removed $($RemoveAdminUser.UserPrincipalName) from owner role"
                    }
                    catch {
                        $errorMsg = "Failed to remove $($RemoveAdminUser.UserPrincipalName) from owner role: $($_.Exception.Message)"
                        Write-Log $errorMsg -Level "ERROR"
                        $groupResult.Errors += $errorMsg
                    }
                }
            } else {
                Write-Log "✅ $($RemoveAdminUser.UserPrincipalName) is not owner of $($Group.DisplayName)" -Level "SUCCESS"
                $groupResult.Actions += "$($RemoveAdminUser.UserPrincipalName) not owner"
            }
        }
        
        # Get final state
        if (-not $WhatIfPreference) {
            Start-Sleep -Seconds 2  # Allow time for changes to propagate
            
            $finalOwners = Get-MgGroupOwner -GroupId $Group.Id
            $groupResult.FinalOwners = $finalOwners | ForEach-Object {
                $owner = Get-MgUser -UserId $_.Id -ErrorAction SilentlyContinue
                if ($owner) { $owner.UserPrincipalName } else { $_.Id }
            }
            
            $finalMembers = Get-MgGroupMember -GroupId $Group.Id
            $groupResult.FinalMembers = $finalMembers | ForEach-Object {
                $member = Get-MgUser -UserId $_.Id -ErrorAction SilentlyContinue
                if ($member) { $member.UserPrincipalName } else { $_.Id }
            }
            
            Write-Log "Final owners: $($groupResult.FinalOwners -join ', ')"
            Write-Log "Final members: $($groupResult.FinalMembers -join ', ')"
        }
        
        if ($groupResult.Errors.Count -eq 0) {
            $groupResult.Success = $true
            $Results.Summary.Success++
            Write-Log "✅ Successfully processed $($Group.DisplayName)" -Level "SUCCESS"
        } else {
            $Results.Summary.Failed++
            Write-Log "❌ Failed to fully process $($Group.DisplayName)" -Level "ERROR"
        }
        
    }
    catch {
        $errorMsg = "Failed to process group $($Group.DisplayName): $($_.Exception.Message)"
        Write-Log $errorMsg -Level "ERROR"
        $groupResult.Errors += $errorMsg
        $Results.Summary.Failed++
        $Results.Errors += $errorMsg
    }
}

# Main execution
Write-Log "Starting Office 365 Groups Management Script"
Write-Log "Target Admin: $TargetAdmin"
Write-Log "Remove User: $RemoveUser"
Write-Log "WhatIf Mode: $WhatIfPreference"

# Connect to services
if (-not (Connect-ToServices)) {
    Write-Log "Failed to connect to required services. Exiting." -Level "ERROR"
    exit 1
}

# Get user objects
Write-Log "Getting user objects..."
$targetAdminUser = Get-UserByEmail -Email $TargetAdmin
if (-not $targetAdminUser) {
    Write-Log "Failed to find target admin user: $TargetAdmin" -Level "ERROR"
    exit 1
}
Write-Log "Target admin user verified: $($targetAdminUser.DisplayName) ($($targetAdminUser.UserPrincipalName))" -Level "SUCCESS"

$removeAdminUser = $null
if ($RemoveUser) {
    $removeAdminUser = Get-UserByEmail -Email $RemoveUser
    if (-not $removeAdminUser) {
        Write-Log "Failed to find remove user: $RemoveUser" -Level "ERROR"
        exit 1
    }
    Write-Log "Remove user verified: $($removeAdminUser.DisplayName) ($($removeAdminUser.UserPrincipalName))" -Level "SUCCESS"
}

# Get Office 365 groups
$office365Groups = Get-Office365Groups
if ($office365Groups.Count -eq 0) {
    Write-Log "No Office 365 groups found to process" -Level "WARNING"
    exit 0
}

Write-Log "Found $($office365Groups.Count) Office 365 groups to process"
$Results.Summary.Total = $office365Groups.Count

# Process each group
foreach ($group in $office365Groups) {
    try {
        Update-Office365Group -Group $group -TargetAdminUser $targetAdminUser -RemoveAdminUser $removeAdminUser
    }
    catch {
        Write-Log "Unexpected error processing group $($group.DisplayName): $($_.Exception.Message)" -Level "ERROR"
        $Results.Summary.Failed++
        $Results.Errors += "Unexpected error processing group $($group.DisplayName): $($_.Exception.Message)"
    }
}

# Final summary
Write-Log "=== OFFICE 365 GROUPS MANAGEMENT SUMMARY ==="
Write-Log "Total groups processed: $($Results.Summary.Total)"
Write-Log "Successfully processed: $($Results.Summary.Success)" -Level "SUCCESS"
Write-Log "Failed: $($Results.Summary.Failed)" -Level $(if ($Results.Summary.Failed -gt 0) { "ERROR" } else { "SUCCESS" })
Write-Log "Success rate: $(if ($Results.Summary.Total -gt 0) { [math]::Round(($Results.Summary.Success / $Results.Summary.Total) * 100, 2) } else { 0 })%"

# Export results
try {
    $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $ResultsFile -Encoding UTF8
    Write-Log "Results exported to: $ResultsFile" -Level "SUCCESS"
}
catch {
    Write-Log "Failed to export results: $($_.Exception.Message)" -Level "ERROR"
}

Write-Log "Office 365 Groups Management Script completed"
Write-Log "Log file: $LogFile"

# Show final compliance status
if ($Results.Summary.Failed -eq 0) {
    Write-Log "🎉 ALL OFFICE 365 GROUPS SUCCESSFULLY CONFIGURED!" -Level "SUCCESS"
} else {
    Write-Log "⚠️ SOME OFFICE 365 GROUPS NEED ATTENTION" -Level "WARNING"
    Write-Log "Failed groups require manual intervention or additional permissions" -Level "WARNING"
}
