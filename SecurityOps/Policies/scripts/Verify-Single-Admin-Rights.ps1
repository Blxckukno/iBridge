#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Verify that lwandile.gasela@ibridge.co.za has sole administrative rights to all groups
.DESCRIPTION
    This script verifies the current state of all distribution groups, Office 365 groups, and security groups
    to ensure that only lwandile.gasela@ibridge.co.za has administrative rights (manager/owner) and that
    Mgqibelo.Gasela@ibridge.co.za has been removed from all admin roles but membership is preserved where applicable.
.PARAMETER Detailed
    Show detailed information for each group
.PARAMETER ExportReport
    Export detailed report to CSV and JSON files
.EXAMPLE
    .\Verify-Single-Admin-Rights.ps1
    Basic verification report
.EXAMPLE
    .\Verify-Single-Admin-Rights.ps1 -Detailed -ExportReport
    Detailed verification with export
#>

[CmdletBinding()]
param(
    [switch]$Detailed,
    [switch]$ExportReport
)

# Configuration
$PrimaryAdmin = "lwandile.gasela@ibridge.co.za"
$FormerAdmin = "Mgqibelo.Gasela@ibridge.co.za"
$ScriptName = "Verify-Single-Admin-Rights"
$LogFile = "C:\Users\Lwandile Gasela\iBridge\Policies\logs\$ScriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$ReportFile = "C:\Users\Lwandile Gasela\iBridge\Policies\logs\$ScriptName-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$CSVFile = "C:\Users\Lwandile Gasela\iBridge\Policies\logs\$ScriptName-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

# Import configuration
$ConfigPath = "C:\Users\Lwandile Gasela\iBridge\Policies\config\email-config.json"
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json
} else {
    Write-Warning "Configuration file not found: $ConfigPath"
    $Config = $null
}

# Results tracking
$VerificationResults = @{
    Timestamp = Get-Date
    ScriptName = $ScriptName
    PrimaryAdmin = $PrimaryAdmin
    FormerAdmin = $FormerAdmin
    DistributionGroups = @()
    Office365Groups = @()
    SecurityGroups = @()
    SharedMailboxes = @()
    Summary = @{}
}

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogEntry
    
    switch ($Level) {
        "ERROR" { Write-Host $LogEntry -ForegroundColor Red }
        "WARNING" { Write-Host $LogEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $LogEntry -ForegroundColor Green }
        "INFO" { Write-Host $LogEntry -ForegroundColor White }
        "CRITICAL" { Write-Host $LogEntry -ForegroundColor Magenta }
    }
}

function Test-ExchangeConnection {
    try {
        $null = Get-OrganizationConfig -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Get-UserDisplayName {
    param([string]$EmailAddress)
    
    try {
        $User = Get-Recipient -Identity $EmailAddress -ErrorAction Stop
        return $User.DisplayName
    }
    catch {
        return "Not Found"
    }
}

function Test-DistributionGroupAdminRights {
    param(
        [object]$Group,
        [string]$PrimaryAdmin,
        [string]$FormerAdmin
    )
    
    try {
        $GroupName = $Group.DisplayName
        $GroupId = $Group.Identity
        $GroupEmail = $Group.PrimarySmtpAddress
        
        # Get current managers
        $CurrentManagers = @($Group.ManagedBy)
        
        # Resolve manager identities to check if they match our target users
        $PrimaryIsManager = $false
        $FormerIsManager = $false
        $ResolvedManagers = @()
        
        foreach ($Manager in $CurrentManagers) {
            try {
                $ManagerObj = Get-Recipient -Identity $Manager -ErrorAction Stop
                $ResolvedManagers += $ManagerObj.PrimarySmtpAddress
                if ($ManagerObj.PrimarySmtpAddress -eq $PrimaryAdmin) {
                    $PrimaryIsManager = $true
                }
                if ($ManagerObj.PrimarySmtpAddress -eq $FormerAdmin) {
                    $FormerIsManager = $true
                }
            }
            catch {
                # If we can't resolve, assume it's a direct match
                $ResolvedManagers += $Manager
                if ($Manager -eq $PrimaryAdmin) {
                    $PrimaryIsManager = $true
                }
                if ($Manager -eq $FormerAdmin) {
                    $FormerIsManager = $true
                }
            }
        }
        
        $ManagerCount = $CurrentManagers.Count
        $OtherManagers = $ResolvedManagers | Where-Object { $_ -ne $PrimaryAdmin -and $_ -ne $FormerAdmin }
        
        # Get members to check membership
        $Members = @()
        $FormerIsMember = $false
        try {
            $Members = Get-DistributionGroupMember -Identity $GroupId -ErrorAction Stop
            $FormerIsMember = $Members.PrimarySmtpAddress -contains $FormerAdmin
        }
        catch {
            Write-Log "Could not get members for $GroupName" "WARNING"
        }
        
        # Check moderation settings
        $ModerationEnabled = $Group.ModerationEnabled
        $Moderators = @($Group.ModeratedBy)
        $FormerIsModerator = $Moderators -contains $FormerAdmin
        
        # Determine compliance status
        $IsCompliant = $PrimaryIsManager -and (-not $FormerIsManager) -and $ManagerCount -eq 1
        $ComplianceIssues = @()
        
        if (-not $PrimaryIsManager) { $ComplianceIssues += "Primary admin not manager" }
        if ($FormerIsManager) { $ComplianceIssues += "Former admin still manager" }
        if ($ManagerCount -gt 1) { $ComplianceIssues += "Multiple managers ($ManagerCount)" }
        if ($OtherManagers.Count -gt 0) { $ComplianceIssues += "Other managers: $($OtherManagers -join ', ')" }
        
        $Result = @{
            GroupName = $GroupName
            GroupType = "DistributionGroup"
            GroupEmail = $GroupEmail
            GroupId = $GroupId
            IsCompliant = $IsCompliant
            ComplianceIssues = $ComplianceIssues
            PrimaryIsManager = $PrimaryIsManager
            FormerIsManager = $FormerIsManager
            FormerIsMember = $FormerIsMember
            ManagerCount = $ManagerCount
            CurrentManagers = $ResolvedManagers
            OtherManagers = $OtherManagers
            ModerationEnabled = $ModerationEnabled
            ModeratorCount = $Moderators.Count
            FormerIsModerator = $FormerIsModerator
            MemberCount = $Members.Count
        }
        
        if ($Detailed) {
            $Status = if ($IsCompliant) { "✅ COMPLIANT" } else { "❌ NON-COMPLIANT" }
            Write-Log "$Status - $GroupName" $(if ($IsCompliant) { "SUCCESS" } else { "WARNING" })
            
            if (-not $IsCompliant) {
                foreach ($Issue in $ComplianceIssues) {
                    Write-Log "  Issue: $Issue" "WARNING"
                }
            }
            
            if ($Detailed) {
                Write-Log "  Managers: $($ResolvedManagers -join ', ')" "INFO"
                Write-Log "  Moderation: $ModerationEnabled ($($Moderators.Count) moderators)" "INFO"
                Write-Log "  Former admin status: Manager=$FormerIsManager, Member=$FormerIsMember, Moderator=$FormerIsModerator" "INFO"
            }
        }
        
        return $Result
    }
    catch {
        Write-Log "Failed to verify group $($Group.DisplayName): $($_.Exception.Message)" "ERROR"
        return @{
            GroupName = $Group.DisplayName
            GroupType = "DistributionGroup"
            IsCompliant = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-Office365GroupAdminRights {
    param(
        [object]$Group,
        [string]$PrimaryAdmin,
        [string]$FormerAdmin
    )
    
    try {
        $GroupName = $Group.DisplayName
        $GroupId = $Group.Identity
        $GroupEmail = $Group.PrimarySmtpAddress
        
        # Get owners and members
        $Owners = @()
        $Members = @()
        
        try {
            $Owners = Get-UnifiedGroupLinks -Identity $GroupId -LinkType Owners -ErrorAction Stop
            $Members = Get-UnifiedGroupLinks -Identity $GroupId -LinkType Members -ErrorAction Stop
        }
        catch {
            Write-Log "Could not get Office 365 group links for $GroupName" "WARNING"
            return @{
                GroupName = $GroupName
                GroupType = "Office365Group"
                IsCompliant = $false
                Error = "Could not get group links"
            }
        }
        
        # Check admin status
        $PrimaryIsOwner = $Owners.PrimarySmtpAddress -contains $PrimaryAdmin
        $PrimaryIsMember = $Members.PrimarySmtpAddress -contains $PrimaryAdmin
        $FormerIsOwner = $Owners.PrimarySmtpAddress -contains $FormerAdmin
        $FormerIsMember = $Members.PrimarySmtpAddress -contains $FormerAdmin
        $OwnerCount = $Owners.Count
        $OtherOwners = $Owners | Where-Object { $_.PrimarySmtpAddress -ne $PrimaryAdmin -and $_.PrimarySmtpAddress -ne $FormerAdmin }
        
        # Determine compliance status
        $IsCompliant = $PrimaryIsOwner -and $PrimaryIsMember -and (-not $FormerIsOwner)
        $ComplianceIssues = @()
        
        if (-not $PrimaryIsOwner) { $ComplianceIssues += "Primary admin not owner" }
        if (-not $PrimaryIsMember) { $ComplianceIssues += "Primary admin not member" }
        if ($FormerIsOwner) { $ComplianceIssues += "Former admin still owner" }
        if ($OtherOwners.Count -gt 0) { $ComplianceIssues += "Other owners: $($OtherOwners.DisplayName -join ', ')" }
        
        $Result = @{
            GroupName = $GroupName
            GroupType = "Office365Group"
            GroupEmail = $GroupEmail
            GroupId = $GroupId
            IsCompliant = $IsCompliant
            ComplianceIssues = $ComplianceIssues
            PrimaryIsOwner = $PrimaryIsOwner
            PrimaryIsMember = $PrimaryIsMember
            FormerIsOwner = $FormerIsOwner
            FormerIsMember = $FormerIsMember
            OwnerCount = $OwnerCount
            MemberCount = $Members.Count
            OtherOwners = $OtherOwners.DisplayName
        }
        
        if ($Detailed) {
            $Status = if ($IsCompliant) { "✅ COMPLIANT" } else { "❌ NON-COMPLIANT" }
            Write-Log "$Status - $GroupName (Office 365)" $(if ($IsCompliant) { "SUCCESS" } else { "WARNING" })
            
            if (-not $IsCompliant) {
                foreach ($Issue in $ComplianceIssues) {
                    Write-Log "  Issue: $Issue" "WARNING"
                }
            }
            
            if ($Detailed) {
                Write-Log "  Owners: $($Owners.DisplayName -join ', ')" "INFO"
                Write-Log "  Former admin status: Owner=$FormerIsOwner, Member=$FormerIsMember" "INFO"
            }
        }
        
        return $Result
    }
    catch {
        Write-Log "Failed to verify Office 365 group $($Group.DisplayName): $($_.Exception.Message)" "ERROR"
        return @{
            GroupName = $Group.DisplayName
            GroupType = "Office365Group"
            IsCompliant = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-SharedMailboxPermissions {
    param(
        [object]$Mailbox,
        [string]$PrimaryAdmin,
        [string]$FormerAdmin
    )
    
    try {
        $MailboxName = $Mailbox.DisplayName
        $MailboxEmail = $Mailbox.PrimarySmtpAddress
        
        # Get permissions
        $FullAccessPerms = Get-MailboxPermission -Identity $Mailbox.Identity | Where-Object { $_.User -like "*@*" }
        $SendAsPerms = Get-RecipientPermission -Identity $Mailbox.Identity | Where-Object { $_.Trustee -like "*@*" }
        
        # Check admin status
        $PrimaryHasFullAccess = $FullAccessPerms.User -contains $PrimaryAdmin
        $PrimaryHasSendAs = $SendAsPerms.Trustee -contains $PrimaryAdmin
        $FormerHasFullAccess = $FullAccessPerms.User -contains $FormerAdmin
        $FormerHasSendAs = $SendAsPerms.Trustee -contains $FormerAdmin
        
        # Determine compliance status
        $IsCompliant = $PrimaryHasFullAccess -and (-not $FormerHasFullAccess) -and (-not $FormerHasSendAs)
        $ComplianceIssues = @()
        
        if (-not $PrimaryHasFullAccess) { $ComplianceIssues += "Primary admin lacks full access" }
        if ($FormerHasFullAccess) { $ComplianceIssues += "Former admin still has full access" }
        if ($FormerHasSendAs) { $ComplianceIssues += "Former admin still has send-as rights" }
        
        $Result = @{
            MailboxName = $MailboxName
            MailboxEmail = $MailboxEmail
            MailboxType = "SharedMailbox"
            IsCompliant = $IsCompliant
            ComplianceIssues = $ComplianceIssues
            PrimaryHasFullAccess = $PrimaryHasFullAccess
            PrimaryHasSendAs = $PrimaryHasSendAs
            FormerHasFullAccess = $FormerHasFullAccess
            FormerHasSendAs = $FormerHasSendAs
            FullAccessCount = $FullAccessPerms.Count
            SendAsCount = $SendAsPerms.Count
        }
        
        if ($Detailed) {
            $Status = if ($IsCompliant) { "✅ COMPLIANT" } else { "❌ NON-COMPLIANT" }
            Write-Log "$Status - $MailboxName (Shared Mailbox)" $(if ($IsCompliant) { "SUCCESS" } else { "WARNING" })
            
            if (-not $IsCompliant) {
                foreach ($Issue in $ComplianceIssues) {
                    Write-Log "  Issue: $Issue" "WARNING"
                }
            }
        }
        
        return $Result
    }
    catch {
        Write-Log "Failed to verify shared mailbox $($Mailbox.DisplayName): $($_.Exception.Message)" "ERROR"
        return @{
            MailboxName = $Mailbox.DisplayName
            MailboxType = "SharedMailbox"
            IsCompliant = $false
            Error = $_.Exception.Message
        }
    }
}

# Main script execution
Write-Log "Starting Single Admin Rights Verification" "INFO"
Write-Log "Primary Admin (should have sole control): $PrimaryAdmin" "INFO"
Write-Log "Former Admin (should be removed from admin roles): $FormerAdmin" "INFO"
Write-Log "Detailed Mode: $Detailed" "INFO"

# Check Exchange Online connection
if (-not (Test-ExchangeConnection)) {
    Write-Log "Not connected to Exchange Online. Attempting to connect..." "WARNING"
    try {
        Connect-ExchangeOnline -ShowProgress $false
        Write-Log "Connected to Exchange Online successfully" "SUCCESS"
    }
    catch {
        Write-Log "Failed to connect to Exchange Online: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# Verify primary admin exists
$PrimaryAdminName = Get-UserDisplayName -EmailAddress $PrimaryAdmin
if ($PrimaryAdminName -eq "Not Found") {
    Write-Log "Primary admin user $PrimaryAdmin not found!" "CRITICAL"
    exit 1
}
Write-Log "Primary admin user verified: $PrimaryAdmin ($PrimaryAdminName)" "SUCCESS"

# Check former admin
$FormerAdminName = Get-UserDisplayName -EmailAddress $FormerAdmin
if ($FormerAdminName -eq "Not Found") {
    Write-Log "Former admin user $FormerAdmin not found in tenant" "INFO"
} else {
    Write-Log "Former admin user found: $FormerAdmin ($FormerAdminName)" "INFO"
}

Write-Log "Discovering all groups and mailboxes..." "INFO"

# Get Distribution Groups
$DistributionGroups = @()
try {
    $DistributionGroups = Get-DistributionGroup -ResultSize Unlimited
    Write-Log "Found $($DistributionGroups.Count) distribution groups" "INFO"
}
catch {
    Write-Log "Failed to get distribution groups: $($_.Exception.Message)" "ERROR"
}

# Get Office 365 Groups
$Office365Groups = @()
try {
    $Office365Groups = Get-UnifiedGroup -ResultSize Unlimited
    Write-Log "Found $($Office365Groups.Count) Office 365 groups" "INFO"
}
catch {
    Write-Log "Failed to get Office 365 groups (cmdlet may not be available): $($_.Exception.Message)" "WARNING"
}

# Get Security Groups
$SecurityGroups = @()
try {
    $SecurityGroups = Get-Group -ResultSize Unlimited | Where-Object { $_.RecipientType -eq "MailUniversalSecurityGroup" }
    Write-Log "Found $($SecurityGroups.Count) mail-enabled security groups" "INFO"
}
catch {
    Write-Log "Failed to get security groups: $($_.Exception.Message)" "WARNING"
}

# Get Shared Mailboxes
$SharedMailboxes = @()
try {
    $SharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited
    Write-Log "Found $($SharedMailboxes.Count) shared mailboxes" "INFO"
}
catch {
    Write-Log "Failed to get shared mailboxes: $($_.Exception.Message)" "WARNING"
}

$TotalObjects = $DistributionGroups.Count + $Office365Groups.Count + $SecurityGroups.Count + $SharedMailboxes.Count
Write-Log "Total objects to verify: $TotalObjects" "INFO"

Write-Log "Starting verification..." "INFO"

# Verify Distribution Groups
Write-Log "Verifying Distribution Groups..." "INFO"
foreach ($Group in $DistributionGroups) {
    $Result = Test-DistributionGroupAdminRights -Group $Group -PrimaryAdmin $PrimaryAdmin -FormerAdmin $FormerAdmin
    $VerificationResults.DistributionGroups += $Result
}

# Verify Office 365 Groups
if ($Office365Groups.Count -gt 0) {
    Write-Log "Verifying Office 365 Groups..." "INFO"
    foreach ($Group in $Office365Groups) {
        $Result = Test-Office365GroupAdminRights -Group $Group -PrimaryAdmin $PrimaryAdmin -FormerAdmin $FormerAdmin
        $VerificationResults.Office365Groups += $Result
    }
}

# Verify Security Groups (use same logic as distribution groups)
if ($SecurityGroups.Count -gt 0) {
    Write-Log "Verifying Security Groups..." "INFO"
    foreach ($Group in $SecurityGroups) {
        $Result = Test-DistributionGroupAdminRights -Group $Group -PrimaryAdmin $PrimaryAdmin -FormerAdmin $FormerAdmin
        $VerificationResults.SecurityGroups += $Result
    }
}

# Verify Shared Mailboxes
if ($SharedMailboxes.Count -gt 0) {
    Write-Log "Verifying Shared Mailboxes..." "INFO"
    foreach ($Mailbox in $SharedMailboxes) {
        $Result = Test-SharedMailboxPermissions -Mailbox $Mailbox -PrimaryAdmin $PrimaryAdmin -FormerAdmin $FormerAdmin
        $VerificationResults.SharedMailboxes += $Result
    }
}

# Calculate summary statistics
$AllResults = $VerificationResults.DistributionGroups + $VerificationResults.Office365Groups + $VerificationResults.SecurityGroups + $VerificationResults.SharedMailboxes

$VerificationResults.Summary = @{
    TotalObjects = $TotalObjects
    DistributionGroups = $DistributionGroups.Count
    Office365Groups = $Office365Groups.Count
    SecurityGroups = $SecurityGroups.Count
    SharedMailboxes = $SharedMailboxes.Count
    TotalCompliant = ($AllResults | Where-Object { $_.IsCompliant -eq $true }).Count
    TotalNonCompliant = ($AllResults | Where-Object { $_.IsCompliant -eq $false }).Count
    CompliancePercentage = if ($AllResults.Count -gt 0) { [Math]::Round(($AllResults | Where-Object { $_.IsCompliant -eq $true }).Count / $AllResults.Count * 100, 2) } else { 0 }
    FormerAdminStillManager = ($AllResults | Where-Object { $_.FormerIsManager -eq $true }).Count
    FormerAdminStillOwner = ($AllResults | Where-Object { $_.FormerIsOwner -eq $true }).Count
    FormerAdminStillHasAccess = ($AllResults | Where-Object { $_.FormerHasFullAccess -eq $true }).Count
    PrimaryAdminMissingAccess = ($AllResults | Where-Object { $_.PrimaryIsManager -eq $false -or $_.PrimaryIsOwner -eq $false -or $_.PrimaryHasFullAccess -eq $false }).Count
    MultipleManagers = ($AllResults | Where-Object { $_.ManagerCount -gt 1 }).Count
    VerificationErrors = ($AllResults | Where-Object { $_.Error }).Count
}

# Display summary
Write-Log "=== SINGLE ADMIN RIGHTS VERIFICATION SUMMARY ===" "INFO"
Write-Log "Total objects verified: $($VerificationResults.Summary.TotalObjects)" "INFO"
Write-Log "Distribution groups: $($VerificationResults.Summary.DistributionGroups)" "INFO"
Write-Log "Office 365 groups: $($VerificationResults.Summary.Office365Groups)" "INFO"
Write-Log "Security groups: $($VerificationResults.Summary.SecurityGroups)" "INFO"
Write-Log "Shared mailboxes: $($VerificationResults.Summary.SharedMailboxes)" "INFO"
Write-Log "Compliant objects: $($VerificationResults.Summary.TotalCompliant)" "SUCCESS"
Write-Log "Non-compliant objects: $($VerificationResults.Summary.TotalNonCompliant)" $(if ($VerificationResults.Summary.TotalNonCompliant -gt 0) { "WARNING" } else { "SUCCESS" })
Write-Log "Compliance percentage: $($VerificationResults.Summary.CompliancePercentage)%" $(if ($VerificationResults.Summary.CompliancePercentage -eq 100) { "SUCCESS" } else { "WARNING" })

if ($VerificationResults.Summary.FormerAdminStillManager -gt 0) {
    Write-Log "⚠️  Former admin still manager in $($VerificationResults.Summary.FormerAdminStillManager) groups" "WARNING"
}
if ($VerificationResults.Summary.FormerAdminStillOwner -gt 0) {
    Write-Log "⚠️  Former admin still owner in $($VerificationResults.Summary.FormerAdminStillOwner) groups" "WARNING"
}
if ($VerificationResults.Summary.FormerAdminStillHasAccess -gt 0) {
    Write-Log "⚠️  Former admin still has access to $($VerificationResults.Summary.FormerAdminStillHasAccess) mailboxes" "WARNING"
}
if ($VerificationResults.Summary.PrimaryAdminMissingAccess -gt 0) {
    Write-Log "⚠️  Primary admin missing access to $($VerificationResults.Summary.PrimaryAdminMissingAccess) objects" "WARNING"
}
if ($VerificationResults.Summary.MultipleManagers -gt 0) {
    Write-Log "⚠️  $($VerificationResults.Summary.MultipleManagers) groups have multiple managers" "WARNING"
}

# Show non-compliant objects
$NonCompliantObjects = $AllResults | Where-Object { $_.IsCompliant -eq $false }
if ($NonCompliantObjects.Count -gt 0) {
    Write-Log "=== NON-COMPLIANT OBJECTS ===" "WARNING"
    foreach ($Object in $NonCompliantObjects) {
        Write-Log "❌ $($Object.GroupName)$($Object.MailboxName) ($($Object.GroupType)$($Object.MailboxType))" "WARNING"
        if ($Object.ComplianceIssues) {
            foreach ($Issue in $Object.ComplianceIssues) {
                Write-Log "   - $Issue" "WARNING"
            }
        }
    }
} else {
    Write-Log "✅ All objects are compliant!" "SUCCESS"
}

# Export results if requested
if ($ExportReport) {
    try {
        $VerificationResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportFile -Encoding UTF8
        Write-Log "Detailed report exported to: $ReportFile" "SUCCESS"
        
        # Create CSV report
        $CSVData = @()
        foreach ($Result in $AllResults) {
            $CSVData += [PSCustomObject]@{
                Name = if ($Result.GroupName) { $Result.GroupName } else { $Result.MailboxName }
                Type = if ($Result.GroupType) { $Result.GroupType } else { $Result.MailboxType }
                Email = if ($Result.GroupEmail) { $Result.GroupEmail } else { $Result.MailboxEmail }
                IsCompliant = $Result.IsCompliant
                ComplianceIssues = ($Result.ComplianceIssues -join "; ")
                PrimaryHasAccess = if ($Result.PrimaryIsManager -ne $null) { $Result.PrimaryIsManager } elseif ($Result.PrimaryIsOwner -ne $null) { $Result.PrimaryIsOwner } else { $Result.PrimaryHasFullAccess }
                FormerHasAccess = if ($Result.FormerIsManager -ne $null) { $Result.FormerIsManager } elseif ($Result.FormerIsOwner -ne $null) { $Result.FormerIsOwner } else { $Result.FormerHasFullAccess }
                FormerIsMember = $Result.FormerIsMember
                Error = $Result.Error
            }
        }
        $CSVData | Export-Csv -Path $CSVFile -NoTypeInformation -Encoding UTF8
        Write-Log "CSV report exported to: $CSVFile" "SUCCESS"
    }
    catch {
        Write-Log "Failed to export reports: $($_.Exception.Message)" "ERROR"
    }
}

# Final status
if ($VerificationResults.Summary.CompliancePercentage -eq 100) {
    Write-Log "🎉 VERIFICATION COMPLETE: Single admin enforcement is 100% compliant!" "SUCCESS"
    Write-Log "✅ $PrimaryAdmin has sole administrative control" "SUCCESS"
    Write-Log "✅ $FormerAdmin has been successfully removed from all admin roles" "SUCCESS"
} else {
    Write-Log "⚠️  VERIFICATION COMPLETE: Some compliance issues found" "WARNING"
    Write-Log "Compliance rate: $($VerificationResults.Summary.CompliancePercentage)%" "WARNING"
    Write-Log "Review the non-compliant objects listed above" "WARNING"
}

Write-Log "Log file: $LogFile" "INFO"
Write-Host "`n=== VERIFICATION COMPLETED ===" -ForegroundColor Green
Write-Host "Compliance: $($VerificationResults.Summary.CompliancePercentage)%" -ForegroundColor $(if ($VerificationResults.Summary.CompliancePercentage -eq 100) { "Green" } else { "Yellow" })
Write-Host "Log file: $LogFile" -ForegroundColor Cyan
if ($ExportReport) {
    Write-Host "Report files: $ReportFile" -ForegroundColor Cyan
    Write-Host "CSV file: $CSVFile" -ForegroundColor Cyan
}
