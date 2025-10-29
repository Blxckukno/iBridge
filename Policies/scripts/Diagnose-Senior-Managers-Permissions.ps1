#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Diagnose and provide solutions for Senior Managers group permission issues
    
.DESCRIPTION
    This script diagnoses the permission issues with the Senior Managers group
    and provides step-by-step solutions to resolve the write scope restrictions.
    
.EXAMPLE
    .\Diagnose-Senior-Managers-Permissions.ps1
    
#>

[CmdletBinding()]
param()

# Initialize logging
$LogPath = Join-Path $PSScriptRoot "..\logs"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFile = Join-Path $LogPath "Diagnose-Senior-Managers-$Timestamp.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(switch($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        "SOLUTION" { "Cyan" }
        default { "White" }
    })
    Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
}

Write-Log "=== SENIOR MANAGERS GROUP PERMISSION DIAGNOSIS ===" "INFO"

# Check Exchange Online connection
try {
    $orgConfig = Get-OrganizationConfig -ErrorAction Stop
    Write-Log "Connected to Exchange Online: $($orgConfig.DisplayName)" "SUCCESS"
}
catch {
    Write-Log "Not connected to Exchange Online" "ERROR"
    Connect-ExchangeOnline -ShowProgress $false
}

# Get current user information
try {
    $currentUser = Get-Mailbox -Identity (Get-ConnectionInformation).UserPrincipalName -ErrorAction Stop
    Write-Log "Current user: $($currentUser.DisplayName) ($($currentUser.UserPrincipalName))" "INFO"
}
catch {
    Write-Log "Could not get current user information" "WARNING"
}

# Get Senior Managers group details
try {
    $seniorGroup = Get-DistributionGroup -ResultSize Unlimited | Where-Object { $_.DisplayName -like "*Senior*Manager*" }
    if ($seniorGroup) {
        Write-Log "Found Senior Managers group:" "SUCCESS"
        Write-Log "  Name: $($seniorGroup.DisplayName)" "INFO"
        Write-Log "  Identity: $($seniorGroup.Identity)" "INFO"
        Write-Log "  GUID: $($seniorGroup.Guid)" "INFO"
        Write-Log "  Type: $($seniorGroup.RecipientType)" "INFO"
        Write-Log "  Created: $($seniorGroup.WhenCreated)" "INFO"
        Write-Log "  Current Managers: $($seniorGroup.ManagedBy -join ', ')" "INFO"
        
        # Try to get detailed information
        try {
            $groupDetails = Get-DistributionGroup -Identity $seniorGroup.Identity -ErrorAction Stop
            Write-Log "  Organization: $($groupDetails.OrganizationId)" "INFO"
            Write-Log "  Exchange Version: $($groupDetails.ExchangeVersion)" "INFO"
        }
        catch {
            Write-Log "Could not get detailed group information: $($_.Exception.Message)" "WARNING"
        }
    }
    else {
        Write-Log "Senior Managers group not found" "ERROR"
        exit 1
    }
}
catch {
    Write-Log "Error getting Senior Managers group: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Check current user's admin roles
Write-Log "Checking current user's administrative roles..." "INFO"
try {
    # This might not work in all environments
    $adminRoles = Get-MsolUserRole -UserPrincipalName (Get-ConnectionInformation).UserPrincipalName -ErrorAction SilentlyContinue
    if ($adminRoles) {
        Write-Log "Current user has the following admin roles:" "INFO"
        foreach ($role in $adminRoles) {
            Write-Log "  - $($role.Name)" "INFO"
        }
    }
    else {
        Write-Log "Could not retrieve admin roles (might need Azure AD PowerShell)" "WARNING"
    }
}
catch {
    Write-Log "Could not check admin roles: $($_.Exception.Message)" "WARNING"
}

# Check Exchange admin roles
Write-Log "Checking Exchange admin roles..." "INFO"
try {
    $exchangeRoles = Get-ManagementRoleAssignment -Assignee (Get-ConnectionInformation).UserPrincipalName -ErrorAction SilentlyContinue
    if ($exchangeRoles) {
        Write-Log "Current user has the following Exchange roles:" "INFO"
        foreach ($role in $exchangeRoles) {
            Write-Log "  - $($role.Role) (Scope: $($role.RecipientWriteScope))" "INFO"
        }
    }
    else {
        Write-Log "No Exchange role assignments found or insufficient permissions to check" "WARNING"
    }
}
catch {
    Write-Log "Could not check Exchange roles: $($_.Exception.Message)" "WARNING"
}

# Provide solutions
Write-Log "=== SOLUTIONS FOR SENIOR MANAGERS GROUP WRITE SCOPE ISSUE ===" "SOLUTION"
Write-Log "" "SOLUTION"
Write-Log "PROBLEM: The 'Senior Managers' group is out of the current user's write scope." "SOLUTION"
Write-Log "This means lwandile.gasela@ibridge.co.za doesn't have sufficient permissions to modify this group." "SOLUTION"
Write-Log "" "SOLUTION"
Write-Log "SOLUTION OPTIONS:" "SOLUTION"
Write-Log "" "SOLUTION"
Write-Log "1. ASSIGN EXCHANGE ADMIN ROLE TO LWANDILE:" "SOLUTION"
Write-Log "   - Have a Global Admin assign 'Exchange Administrator' role to lwandile.gasela@ibridge.co.za" "SOLUTION"
Write-Log "   - Or assign 'Mail and Calendar Administrator' role" "SOLUTION"
Write-Log "   - This can be done in Microsoft 365 Admin Center > Users > Active users > lwandile.gasela@ibridge.co.za > Roles" "SOLUTION"
Write-Log "" "SOLUTION"
Write-Log "2. HAVE A GLOBAL ADMIN RUN THE SCRIPT:" "SOLUTION"
Write-Log "   - A Global Administrator can run the Fix-Senior-Managers-Group.ps1 script" "SOLUTION"
Write-Log "   - Global Admins have write access to all Exchange objects" "SOLUTION"
Write-Log "" "SOLUTION"
Write-Log "3. HAVE CURRENT GROUP MANAGERS ADD LWANDILE:" "SOLUTION"
Write-Log "   - Contact Itumeleng Kutumela (Itumeleng.Kutumela@ibridge.co.za)" "SOLUTION"
Write-Log "   - Contact Mgqibelo Gasela (Mgqibelo.Gasela@ibridge.co.za)" "SOLUTION"
Write-Log "   - Ask them to add lwandile.gasela@ibridge.co.za as a manager" "SOLUTION"
Write-Log "   - Then lwandile can remove the others and become sole manager" "SOLUTION"
Write-Log "" "SOLUTION"
Write-Log "4. USE EXCHANGE ADMIN CENTER (EAC):" "SOLUTION"
Write-Log "   - Go to https://admin.exchange.microsoft.com" "SOLUTION"
Write-Log "   - Navigate to Recipients > Groups" "SOLUTION"
Write-Log "   - Find 'Senior Managers' group" "SOLUTION"
Write-Log "   - Edit the group and modify the managers" "SOLUTION"
Write-Log "   - This might work if the web interface has different permissions" "SOLUTION"
Write-Log "" "SOLUTION"
Write-Log "5. TEMPORARY ELEVATION:" "SOLUTION"
Write-Log "   - Request temporary Exchange Administrator role" "SOLUTION"
Write-Log "   - Make the changes" "SOLUTION"
Write-Log "   - Role can be removed after completion" "SOLUTION"
Write-Log "" "SOLUTION"
Write-Log "RECOMMENDED APPROACH:" "SOLUTION"
Write-Log "Ask a Global Administrator to run this command:" "SOLUTION"
Write-Log "Set-DistributionGroup -Identity 'Senior Managers20220516104448' -ManagedBy 'lwandile.gasela@ibridge.co.za'" "SOLUTION"
Write-Log "" "SOLUTION"
Write-Log "MANUAL STEPS FOR GLOBAL ADMIN:" "SOLUTION"
Write-Log "1. Connect to Exchange Online as Global Admin" "SOLUTION"
Write-Log "2. Run: Set-DistributionGroup -Identity 'Senior Managers20220516104448' -ManagedBy 'lwandile.gasela@ibridge.co.za'" "SOLUTION"
Write-Log "3. Verify with: Get-DistributionGroup -Identity 'Senior Managers20220516104448' | Select DisplayName,ManagedBy" "SOLUTION"
Write-Log "" "SOLUTION"
Write-Log "After the change is made, re-run the comprehensive rights script to verify 100% compliance." "SOLUTION"

Write-Log "=== DIAGNOSIS COMPLETE ===" "INFO"
Write-Log "Log file: $LogFile" "INFO"

# Create a summary file for easy reference
$summaryFile = Join-Path $LogPath "Senior-Managers-Issue-Summary.txt"
$summaryContent = @"
SENIOR MANAGERS GROUP ISSUE SUMMARY
Generated: $(Get-Date)

PROBLEM:
The 'Senior Managers' group cannot be modified by lwandile.gasela@ibridge.co.za due to Exchange write scope restrictions.

CURRENT STATUS:
- Group Name: Senior Managers
- Group Identity: Senior Managers20220516104448
- Current Managers: Itumeleng Kutumela, Mgqibelo Gasela
- Desired Manager: lwandile.gasela@ibridge.co.za (sole manager)

SOLUTION:
Have a Global Administrator run this command:
Set-DistributionGroup -Identity 'Senior Managers20220516104448' -ManagedBy 'lwandile.gasela@ibridge.co.za'

VERIFICATION:
After the change, run:
Get-DistributionGroup -Identity 'Senior Managers20220516104448' | Select DisplayName,ManagedBy

NEXT STEPS:
1. Contact Global Administrator
2. Have them run the command above
3. Verify the change
4. Re-run the comprehensive rights script to achieve 100% compliance
"@

$summaryContent | Out-File -FilePath $summaryFile -Encoding UTF8
Write-Log "Summary file created: $summaryFile" "SUCCESS"
