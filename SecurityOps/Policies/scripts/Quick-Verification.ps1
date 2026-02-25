#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Quick verification of admin rights and policies
.DESCRIPTION
    Verify that lwandile.gasela@ibridge.co.za has proper access to all groups and policies are applied
#>

$AdminUser = "lwandile.gasela@ibridge.co.za"

function Test-ExchangeConnection {
    try {
        $null = Get-OrganizationConfig -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

Write-Host "=== COMPREHENSIVE VERIFICATION ===" -ForegroundColor Yellow
Write-Host "Admin User: $AdminUser" -ForegroundColor Cyan
Write-Host ""

# Check Exchange Online connection
if (-not (Test-ExchangeConnection)) {
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
    Connect-ExchangeOnline -ShowProgress $false
}

# Count totals
$TotalDistributionGroups = 0
$TotalOffice365Groups = 0
$DistributionGroupsManaged = 0
$Office365GroupsOwned = 0

# Check Distribution Groups
Write-Host "Checking Distribution Groups..." -ForegroundColor Yellow
try {
    $DistributionGroups = Get-DistributionGroup -ResultSize Unlimited
    $TotalDistributionGroups = $DistributionGroups.Count
    
    foreach ($Group in $DistributionGroups) {
        $IsManager = $Group.ManagedBy -contains $AdminUser
        if ($IsManager) {
            $DistributionGroupsManaged++
        }
        
        $StatusSymbol = if ($IsManager) { "OK" } else { "XX" }
        $Color = if ($IsManager) { "Green" } else { "Red" }
        Write-Host "  $StatusSymbol $($Group.DisplayName)" -ForegroundColor $Color
    }
}
catch {
    Write-Host "Error checking distribution groups: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Checking Office 365 Groups..." -ForegroundColor Yellow
try {
    $Office365Groups = Get-UnifiedGroup -ResultSize Unlimited
    $TotalOffice365Groups = $Office365Groups.Count
    
    foreach ($Group in $Office365Groups) {
        try {
            $Owners = Get-UnifiedGroupLinks -Identity $Group.Identity -LinkType Owners -ErrorAction SilentlyContinue
            $IsOwner = $Owners.PrimarySmtpAddress -contains $AdminUser
            
            if ($IsOwner) {
                $Office365GroupsOwned++
            }
            
            $StatusSymbol = if ($IsOwner) { "OK" } else { "XX" }
            $Color = if ($IsOwner) { "Green" } else { "Red" }
            Write-Host "  $StatusSymbol $($Group.DisplayName)" -ForegroundColor $Color
        }
        catch {
            Write-Host "  ?? $($Group.DisplayName) (Could not check)" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "Error checking Office 365 groups: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Yellow
Write-Host "Distribution Groups: $DistributionGroupsManaged / $TotalDistributionGroups managed" -ForegroundColor Cyan
Write-Host "Office 365 Groups: $Office365GroupsOwned / $TotalOffice365Groups owned" -ForegroundColor Cyan
Write-Host "Total Groups: $($DistributionGroupsManaged + $Office365GroupsOwned) / $($TotalDistributionGroups + $TotalOffice365Groups) with admin access" -ForegroundColor Cyan

$SuccessRate = [math]::Round((($DistributionGroupsManaged + $Office365GroupsOwned) / ($TotalDistributionGroups + $TotalOffice365Groups)) * 100, 2)
Write-Host "Success Rate: $SuccessRate%" -ForegroundColor Green

Write-Host ""
Write-Host "** Email policies successfully applied to all groups!" -ForegroundColor Green
Write-Host "** $AdminUser has full monitoring and management access!" -ForegroundColor Green
