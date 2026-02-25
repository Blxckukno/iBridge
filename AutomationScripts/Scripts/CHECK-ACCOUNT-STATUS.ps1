# Account Status Checker
# This script checks the current status of the target accounts without requiring admin privileges

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "ACCOUNT STATUS CHECKER" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$AdminUsername = "Admin"
$UserUsername = "iBridge User"

Write-Host "Checking local user accounts..." -ForegroundColor Yellow
Write-Host ""

# Check Admin account
$adminExists = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
if ($adminExists) {
    Write-Host "✅ Admin account: EXISTS" -ForegroundColor Green
    Write-Host "   Name: $($adminExists.Name)" -ForegroundColor White
    Write-Host "   Full Name: $($adminExists.FullName)" -ForegroundColor White
    Write-Host "   Enabled: $($adminExists.Enabled)" -ForegroundColor White
    Write-Host "   Description: $($adminExists.Description)" -ForegroundColor White
} else {
    Write-Host "❌ Admin account: DOES NOT EXIST" -ForegroundColor Red
}

Write-Host ""

# Check iBridge User account
$userExists = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
if ($userExists) {
    Write-Host "✅ iBridge User account: EXISTS" -ForegroundColor Green
    Write-Host "   Name: $($userExists.Name)" -ForegroundColor White
    Write-Host "   Full Name: $($userExists.FullName)" -ForegroundColor White
    Write-Host "   Enabled: $($userExists.Enabled)" -ForegroundColor White
    Write-Host "   Description: $($userExists.Description)" -ForegroundColor White
} else {
    Write-Host "❌ iBridge User account: DOES NOT EXIST" -ForegroundColor Red
}

Write-Host ""
Write-Host "Checking profile folders..." -ForegroundColor Yellow
Write-Host ""

# Check Admin profile folder
$adminProfilePath = "C:\Users\$AdminUsername"
if (Test-Path $adminProfilePath) {
    $adminFolder = Get-Item $adminProfilePath
    Write-Host "✅ Admin profile folder: EXISTS" -ForegroundColor Green
    Write-Host "   Path: $adminProfilePath" -ForegroundColor White
    Write-Host "   Created: $($adminFolder.CreationTime)" -ForegroundColor White
} else {
    Write-Host "❌ Admin profile folder: DOES NOT EXIST" -ForegroundColor Red
    Write-Host "   Expected path: $adminProfilePath" -ForegroundColor White
}

Write-Host ""

# Check iBridge User profile folder
$userProfilePath = "C:\Users\$UserUsername"
if (Test-Path $userProfilePath) {
    $userFolder = Get-Item $userProfilePath
    Write-Host "✅ iBridge User profile folder: EXISTS" -ForegroundColor Green
    Write-Host "   Path: $userProfilePath" -ForegroundColor White
    Write-Host "   Created: $($userFolder.CreationTime)" -ForegroundColor White
} else {
    Write-Host "❌ iBridge User profile folder: DOES NOT EXIST" -ForegroundColor Red
    Write-Host "   Expected path: $userProfilePath" -ForegroundColor White
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "STATUS CHECK COMPLETE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Expected configuration summary
Write-Host ""
Write-Host "EXPECTED CONFIGURATION:" -ForegroundColor Yellow
Write-Host "Admin Account:" -ForegroundColor White
Write-Host "  Username: Admin" -ForegroundColor Gray
Write-Host "  Password: IBr1dG3Pc" -ForegroundColor Gray
Write-Host "  Group: Administrators" -ForegroundColor Gray
Write-Host ""
Write-Host "iBridge User Account:" -ForegroundColor White
Write-Host "  Username: iBridge User" -ForegroundColor Gray
Write-Host "  Password: Abc654321!" -ForegroundColor Gray
Write-Host "  Group: Users" -ForegroundColor Gray
