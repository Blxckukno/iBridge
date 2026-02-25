#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Grant mgqibelo.gasela@ibridge.co.za access to all Office 365 groups
.DESCRIPTION
    This script specifically handles Office 365 groups to ensure mgqibelo.gasela@ibridge.co.za 
    has the same owner and member access as lwandile.gasela@ibridge.co.za
#>

$AdminUser = "mgqibelo.gasela@ibridge.co.za"

function Test-ExchangeConnection {
    try {
        $null = Get-OrganizationConfig -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

Write-Host "=== GRANTING OFFICE 365 GROUP ACCESS TO MGQIBELO ===" -ForegroundColor Yellow
Write-Host "Admin User: $AdminUser" -ForegroundColor Cyan

# Check Exchange Online connection
if (-not (Test-ExchangeConnection)) {
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
    Connect-ExchangeOnline -ShowProgress $false
}

$ProcessedCount = 0
$SuccessCount = 0
$FailedCount = 0

try {
    Write-Host "Discovering Office 365 groups..." -ForegroundColor Yellow
    $Office365Groups = Get-UnifiedGroup -ResultSize Unlimited
    $TotalGroups = $Office365Groups.Count
    Write-Host "Found $TotalGroups Office 365 groups to process" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($Group in $Office365Groups) {
        $ProcessedCount++
        $Percent = [math]::Round(($ProcessedCount / $TotalGroups) * 100, 1)
        Write-Host "Processing ($ProcessedCount/$TotalGroups - $Percent%): $($Group.DisplayName)" -ForegroundColor White
        
        try {
            # Check if user is already a member
            $Members = Get-UnifiedGroupLinks -Identity $Group.Identity -LinkType Members -ErrorAction Stop
            $IsMember = $Members.PrimarySmtpAddress -contains $AdminUser
            
            if (-not $IsMember) {
                Add-UnifiedGroupLinks -Identity $Group.Identity -LinkType Members -Links $AdminUser -ErrorAction Stop
                Write-Host "  + Added as member" -ForegroundColor Green
            } else {
                Write-Host "  ✓ Already a member" -ForegroundColor DarkGray
            }
            
            # Check if user is already an owner
            $Owners = Get-UnifiedGroupLinks -Identity $Group.Identity -LinkType Owners -ErrorAction Stop
            $IsOwner = $Owners.PrimarySmtpAddress -contains $AdminUser
            
            if (-not $IsOwner) {
                Add-UnifiedGroupLinks -Identity $Group.Identity -LinkType Owners -Links $AdminUser -ErrorAction Stop
                Write-Host "  + Added as owner" -ForegroundColor Green
            } else {
                Write-Host "  ✓ Already an owner" -ForegroundColor DarkGray
            }
            
            $SuccessCount++
        }
        catch {
            Write-Host "  ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
            $FailedCount++
        }
    }
    
    Write-Host ""
    Write-Host "=== OFFICE 365 GROUPS SUMMARY ===" -ForegroundColor Yellow
    Write-Host "Total groups processed: $ProcessedCount" -ForegroundColor Cyan
    Write-Host "Successfully processed: $SuccessCount" -ForegroundColor Green
    Write-Host "Failed: $FailedCount" -ForegroundColor $(if ($FailedCount -gt 0) { "Red" } else { "Green" })
    
    $SuccessRate = [math]::Round(($SuccessCount / $ProcessedCount) * 100, 2)
    Write-Host "Success Rate: $SuccessRate%" -ForegroundColor Green
    
    if ($FailedCount -eq 0) {
        Write-Host ""
        Write-Host "🎉 SUCCESS: mgqibelo.gasela@ibridge.co.za now has owner/member access to ALL Office 365 groups!" -ForegroundColor Green
    }
}
catch {
    Write-Host "Error accessing Office 365 groups: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Office 365 group access grant completed for mgqibelo.gasela@ibridge.co.za" -ForegroundColor Green
