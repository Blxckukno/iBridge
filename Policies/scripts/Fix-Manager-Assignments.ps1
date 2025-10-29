#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Fix the manager assignments - replace GUIDs with proper email addresses
.DESCRIPTION
    This script investigates and fixes the manager assignments for all distribution groups
    to ensure lwandile.gasela@ibridge.co.za is the sole manager
#>

[CmdletBinding()]
param(
    [switch]$WhatIf
)

$PrimaryAdmin = "lwandile.gasela@ibridge.co.za"
$ConfigPath = "C:\Users\Lwandile Gasela\iBridge\Policies\config\email-config.json"
$Config = Get-Content $ConfigPath | ConvertFrom-Json

# Logging
$LogFile = "C:\Users\Lwandile Gasela\iBridge\Policies\logs\Fix-Manager-Assignments-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(switch($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    })
    Add-Content -Path $LogFile -Value $LogEntry
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

Write-Log "Starting Manager Assignment Fix" "INFO"
Write-Log "Target primary admin: $PrimaryAdmin" "INFO"
Write-Log "WhatIf Mode: $WhatIf" "INFO"

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

# Get all distribution groups
$DistributionGroups = Get-DistributionGroup -ResultSize Unlimited
Write-Log "Found $($DistributionGroups.Count) distribution groups" "INFO"

# Check what the problematic GUID represents
$ProblematicGUID = "6ac3115c-e13d-47a0-aef2-4b714caebed8"
try {
    $GuidObject = Get-Recipient -Identity $ProblematicGUID -ErrorAction Stop
    Write-Log "GUID $ProblematicGUID represents: $($GuidObject.DisplayName) ($($GuidObject.PrimarySmtpAddress))" "INFO"
}
catch {
    Write-Log "Could not resolve GUID $ProblematicGUID : $($_.Exception.Message)" "WARNING"
}

# Fix each group
foreach ($Group in $DistributionGroups) {
    Write-Log "Processing group: $($Group.DisplayName)" "INFO"
    
    $CurrentManagers = @($Group.ManagedBy)
    Write-Log "Current managers: $($CurrentManagers -join ', ')" "INFO"
    
    # Check if primary admin is already the sole manager
    if ($CurrentManagers.Count -eq 1 -and $CurrentManagers[0] -eq $PrimaryAdmin) {
        Write-Log "✅ $($Group.DisplayName) already has correct manager" "SUCCESS"
        continue
    }
    
    # Fix the manager assignment
    if ($WhatIf) {
        Write-Log "WHATIF: Would set $PrimaryAdmin as sole manager of $($Group.DisplayName)" "INFO"
    } else {
        try {
            # Clear all managers and set only the primary admin
            Set-DistributionGroup -Identity $Group.Identity -ManagedBy $PrimaryAdmin -ErrorAction Stop
            Write-Log "✅ Successfully set $PrimaryAdmin as sole manager of $($Group.DisplayName)" "SUCCESS"
            
            # Apply proper moderation
            $ValidModerators = @($PrimaryAdmin)
            foreach ($User in $Config.AuthorizedUsers) {
                if ($User -ne "Mgqibelo.Gasela@ibridge.co.za") {  # Exclude Mgqibelo
                    try {
                        $UserCheck = Get-Recipient -Identity $User -ErrorAction SilentlyContinue
                        if ($UserCheck -and $UserCheck.RecipientType -in @("UserMailbox", "MailUser")) {
                            $ValidModerators += $User
                        }
                    }
                    catch {
                        Write-Log "Could not validate moderator $User" "WARNING"
                    }
                }
            }
            
            # Remove duplicates and apply moderation
            $ValidModerators = $ValidModerators | Sort-Object -Unique
            
            Set-DistributionGroup -Identity $Group.Identity `
                -ModerationEnabled:$true `
                -ModeratedBy $ValidModerators `
                -SendModerationNotifications Never `
                -ErrorAction Stop
            
            Write-Log "✅ Applied moderation to $($Group.DisplayName) with $($ValidModerators.Count) moderators" "SUCCESS"
        }
        catch {
            Write-Log "❌ Failed to fix $($Group.DisplayName): $($_.Exception.Message)" "ERROR"
        }
    }
}

Write-Log "Manager assignment fix completed" "SUCCESS"
Write-Log "Log file: $LogFile" "INFO"
