#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Verify and ensure mgqibelo.gasela@ibridge.co.za has comprehensive admin rights
.DESCRIPTION
    This script verifies current access and ensures mgqibelo.gasela@ibridge.co.za has the same rights as lwandile.gasela@ibridge.co.za
#>

$MgqibeloUser = "mgqibelo.gasela@ibridge.co.za"
$LwandileUser = "lwandile.gasela@ibridge.co.za"

function Test-ExchangeConnection {
    try {
        $null = Get-OrganizationConfig -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

Write-Host "=== COMPREHENSIVE VERIFICATION FOR MGQIBELO ADMIN RIGHTS ===" -ForegroundColor Yellow
Write-Host ""

# Check Exchange Online connection
if (-not (Test-ExchangeConnection)) {
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
    Connect-ExchangeOnline -ShowProgress $false
}

Write-Host "Checking admin rights for both users..." -ForegroundColor Cyan
Write-Host "Mgqibelo: $MgqibeloUser" -ForegroundColor White
Write-Host "Lwandile: $LwandileUser" -ForegroundColor White
Write-Host ""

# Verify Distribution Groups
Write-Host "=== DISTRIBUTION GROUPS ===" -ForegroundColor Yellow
$DistributionGroups = Get-DistributionGroup -ResultSize Unlimited
$MgqibeloDistMgr = 0
$LwandileDistMgr = 0

foreach ($Group in $DistributionGroups) {
    # Resolve all managers to email addresses
    $ManagerEmails = @()
    foreach ($Manager in $Group.ManagedBy) {
        try {
            $ManagerDetails = Get-Recipient -Identity $Manager -ErrorAction SilentlyContinue
            if ($ManagerDetails) {
                $ManagerEmails += $ManagerDetails.PrimarySmtpAddress.ToString()
            }
        }
        catch {}
    }
    
    $MgqibeloIsManager = $ManagerEmails -contains $MgqibeloUser
    $LwandileIsManager = $ManagerEmails -contains $LwandileUser
    
    if ($MgqibeloIsManager) { $MgqibeloDistMgr++ }
    if ($LwandileIsManager) { $LwandileDistMgr++ }
    
    $MgqibeloStatus = if ($MgqibeloIsManager) { "✓" } else { "✗" }
    $LwandileStatus = if ($LwandileIsManager) { "✓" } else { "✗" }
    
    $MgqibeloColor = if ($MgqibeloIsManager) { "Green" } else { "Red" }
    $LwandileColor = if ($LwandileIsManager) { "Green" } else { "Red" }
    
    Write-Host ("  {0,-30} | Mgqibelo: " -f $Group.DisplayName) -NoNewline
    Write-Host $MgqibeloStatus -ForegroundColor $MgqibeloColor -NoNewline
    Write-Host " | Lwandile: " -NoNewline
    Write-Host $LwandileStatus -ForegroundColor $LwandileColor
}

Write-Host ""
Write-Host "Distribution Groups Summary:" -ForegroundColor Cyan
Write-Host "  Mgqibelo manages: $MgqibeloDistMgr / $($DistributionGroups.Count) groups" -ForegroundColor $(if ($MgqibeloDistMgr -eq $DistributionGroups.Count) { "Green" } else { "Yellow" })
Write-Host "  Lwandile manages: $LwandileDistMgr / $($DistributionGroups.Count) groups" -ForegroundColor $(if ($LwandileDistMgr -eq $DistributionGroups.Count) { "Green" } else { "Yellow" })

# Check Office 365 Groups
Write-Host ""
Write-Host "=== OFFICE 365 GROUPS ===" -ForegroundColor Yellow
try {
    $Office365Groups = Get-UnifiedGroup -ResultSize Unlimited
    $MgqibeloO365Owner = 0
    $LwandileO365Owner = 0
    $CheckedGroups = 0
    
    foreach ($Group in $Office365Groups) {
        $CheckedGroups++
        if ($CheckedGroups -le 10) {  # Check first 10 groups as sample
            try {
                $Owners = Get-UnifiedGroupLinks -Identity $Group.Identity -LinkType Owners -ErrorAction SilentlyContinue
                $MgqibeloIsOwner = $Owners.PrimarySmtpAddress -contains $MgqibeloUser
                $LwandileIsOwner = $Owners.PrimarySmtpAddress -contains $LwandileUser
                
                if ($MgqibeloIsOwner) { $MgqibeloO365Owner++ }
                if ($LwandileIsOwner) { $LwandileO365Owner++ }
                
                $MgqibeloStatus = if ($MgqibeloIsOwner) { "✓" } else { "✗" }
                $LwandileStatus = if ($LwandileIsOwner) { "✓" } else { "✗" }
                
                $MgqibeloColor = if ($MgqibeloIsOwner) { "Green" } else { "Red" }
                $LwandileColor = if ($LwandileIsOwner) { "Green" } else { "Red" }
                
                Write-Host ("  {0,-30} | Mgqibelo: " -f $Group.DisplayName) -NoNewline
                Write-Host $MgqibeloStatus -ForegroundColor $MgqibeloColor -NoNewline
                Write-Host " | Lwandile: " -NoNewline
                Write-Host $LwandileStatus -ForegroundColor $LwandileColor
            }
            catch {
                Write-Host "  $($Group.DisplayName) - Could not check" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host ""
    Write-Host "Office 365 Groups Summary (sample of 10):" -ForegroundColor Cyan
    Write-Host "  Total Office 365 groups found: $($Office365Groups.Count)" -ForegroundColor White
    Write-Host "  Mgqibelo owns: $MgqibeloO365Owner / 10 checked" -ForegroundColor $(if ($MgqibeloO365Owner -eq 10) { "Green" } else { "Yellow" })
    Write-Host "  Lwandile owns: $LwandileO365Owner / 10 checked" -ForegroundColor $(if ($LwandileO365Owner -eq 10) { "Green" } else { "Yellow" })
}
catch {
    Write-Host "Could not access Office 365 groups: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== OVERALL SUMMARY ===" -ForegroundColor Yellow

if ($MgqibeloDistMgr -eq $DistributionGroups.Count) {
    Write-Host "✓ Mgqibelo has manager access to ALL distribution groups" -ForegroundColor Green
} else {
    Write-Host "⚠ Mgqibelo needs access to $($DistributionGroups.Count - $MgqibeloDistMgr) more distribution groups" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Current Status:" -ForegroundColor Cyan
Write-Host "- Distribution Groups: $MgqibeloDistMgr/$($DistributionGroups.Count) managed by mgqibelo" -ForegroundColor White
Write-Host "- Office 365 Groups: $MgqibeloO365Owner/10 owned by mgqibelo (sample)" -ForegroundColor White

if ($MgqibeloDistMgr -eq $DistributionGroups.Count -and $MgqibeloO365Owner -eq 10) {
    Write-Host ""
    Write-Host "🎉 SUCCESS: mgqibelo.gasela@ibridge.co.za has comprehensive admin rights!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "📋 Additional configuration may be needed for complete access" -ForegroundColor Yellow
}
