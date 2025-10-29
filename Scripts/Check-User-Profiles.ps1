# Profile Verification Script
# Checks if user accounts and profiles were created correctly

Write-Host "iBridge User Profile Verification" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Yellow
Write-Host ""

$AdminUsername = "Admin"
$UserUsername = "iBridge User"

# Check if accounts exist
Write-Host "Checking User Accounts:" -ForegroundColor Cyan
try {
    $adminAccount = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
    if ($adminAccount) {
        Write-Host "✓ Admin account exists" -ForegroundColor Green
        Write-Host "  - Full Name: $($adminAccount.FullName)" -ForegroundColor Gray
        Write-Host "  - Enabled: $($adminAccount.Enabled)" -ForegroundColor Gray
    } else {
        Write-Host "✗ Admin account missing" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error checking Admin account: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $userAccount = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
    if ($userAccount) {
        Write-Host "✓ iBridge User account exists" -ForegroundColor Green
        Write-Host "  - Full Name: $($userAccount.FullName)" -ForegroundColor Gray
        Write-Host "  - Enabled: $($userAccount.Enabled)" -ForegroundColor Gray
    } else {
        Write-Host "✗ iBridge User account missing" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error checking iBridge User account: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Check if profiles exist
Write-Host "Checking User Profiles:" -ForegroundColor Cyan
$adminProfile = "C:\Users\$AdminUsername"
$userProfile = "C:\Users\$UserUsername"

if (Test-Path $adminProfile) {
    Write-Host "✓ Admin profile exists at: $adminProfile" -ForegroundColor Green
    $adminDesktop = "$adminProfile\Desktop"
    if (Test-Path $adminDesktop) {
        Write-Host "  ✓ Desktop folder exists" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Desktop folder missing" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Admin profile missing at: $adminProfile" -ForegroundColor Red
}

if (Test-Path $userProfile) {
    Write-Host "✓ iBridge User profile exists at: $userProfile" -ForegroundColor Green
    $userDesktop = "$userProfile\Desktop"
    if (Test-Path $userDesktop) {
        Write-Host "  ✓ Desktop folder exists" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Desktop folder missing" -ForegroundColor Red
    }
} else {
    Write-Host "✗ iBridge User profile missing at: $userProfile" -ForegroundColor Red
}

Write-Host ""

# Check group memberships
Write-Host "Checking Group Memberships:" -ForegroundColor Cyan
try {
    $adminGroup = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$AdminUsername*" }
    if ($adminGroup) {
        Write-Host "✓ Admin is member of Administrators group" -ForegroundColor Green
    } else {
        Write-Host "✗ Admin is NOT in Administrators group" -ForegroundColor Red
    }
} catch {
    Write-Host "? Could not verify Admin group membership" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Verification Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "If any profiles are missing, the setup script will create them automatically." -ForegroundColor Yellow
