# Account Verification Script
# This script checks if the user accounts were created successfully

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Account Verification Script" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check for Admin account
try {
    $AdminUser = Get-LocalUser -Name "Admin" -ErrorAction Stop
    Write-Host "✓ Admin account found" -ForegroundColor Green
    Write-Host "  Name: $($AdminUser.Name)" -ForegroundColor Gray
    Write-Host "  Description: $($AdminUser.Description)" -ForegroundColor Gray
    Write-Host "  Enabled: $($AdminUser.Enabled)" -ForegroundColor Gray
    
    # Check if Admin is in Administrators group
    $AdminGroups = Get-LocalGroupMember -Group "Administrators" | Where-Object {$_.Name -like "*Admin"}
    if ($AdminGroups) {
        Write-Host "  ✓ Member of Administrators group" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Not found in Administrators group" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Admin account not found" -ForegroundColor Red
}

Write-Host ""

# Check for iBridge User account
try {
    $iBridgeUser = Get-LocalUser -Name "iBridge User" -ErrorAction Stop
    Write-Host "✓ iBridge User account found" -ForegroundColor Green
    Write-Host "  Name: $($iBridgeUser.Name)" -ForegroundColor Gray
    Write-Host "  Description: $($iBridgeUser.Description)" -ForegroundColor Gray
    Write-Host "  Enabled: $($iBridgeUser.Enabled)" -ForegroundColor Gray
    
    # Check if iBridge User is in Users group
    $UserGroups = Get-LocalGroupMember -Group "Users" | Where-Object {$_.Name -like "*iBridge User"}
    if ($UserGroups) {
        Write-Host "  ✓ Member of Users group" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Not found in Users group" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ iBridge User account not found" -ForegroundColor Red
}

Write-Host ""

# Check for shared folder
if (Test-Path "C:\iBridge_Apps") {
    Write-Host "✓ Shared folder exists: C:\iBridge_Apps" -ForegroundColor Green
    
    # Check folder permissions
    try {
        $Acl = Get-Acl "C:\iBridge_Apps"
        $Permissions = $Acl.Access | Where-Object {$_.IdentityReference -like "*iBridge User*"}
        if ($Permissions) {
            Write-Host "  ✓ iBridge User has permissions set" -ForegroundColor Green
        } else {
            Write-Host "  ! iBridge User permissions not found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ! Could not check folder permissions" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Shared folder not found: C:\iBridge_Apps" -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Verification Complete" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to continue..."
Read-Host
