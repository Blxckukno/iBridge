# Cleanup and Recreate Accounts Script
# This script removes existing accounts and profiles, then creates fresh ones

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "CLEANUP AND RECREATE ACCOUNTS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Account Configuration
$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

Write-Host "Step 1: Removing existing accounts..." -ForegroundColor Yellow
Write-Host ""

# Remove Admin account if it exists
try {
    $existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
    if ($existingAdmin) {
        Write-Host "Removing existing Admin account..." -ForegroundColor Red
        Remove-LocalUser -Name $AdminUsername -Confirm:$false
        Write-Host "✅ Admin account removed" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  Admin account does not exist" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Error removing Admin account: $($_.Exception.Message)" -ForegroundColor Red
}

# Remove iBridge User account if it exists
try {
    $existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
    if ($existingUser) {
        Write-Host "Removing existing iBridge User account..." -ForegroundColor Red
        Remove-LocalUser -Name $UserUsername -Confirm:$false
        Write-Host "✅ iBridge User account removed" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  iBridge User account does not exist" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Error removing iBridge User account: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 2: Removing existing profile folders..." -ForegroundColor Yellow
Write-Host ""

# Remove Admin profile folder
$adminProfilePath = "C:\Users\$AdminUsername"
if (Test-Path $adminProfilePath) {
    Write-Host "Removing Admin profile folder: $adminProfilePath" -ForegroundColor Red
    try {
        Remove-Item $adminProfilePath -Recurse -Force
        Write-Host "✅ Admin profile folder removed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error removing Admin profile folder: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "ℹ️  Admin profile folder does not exist" -ForegroundColor Gray
}

# Remove iBridge User profile folder
$userProfilePath = "C:\Users\$UserUsername"
if (Test-Path $userProfilePath) {
    Write-Host "Removing iBridge User profile folder: $userProfilePath" -ForegroundColor Red
    try {
        Remove-Item $userProfilePath -Recurse -Force
        Write-Host "✅ iBridge User profile folder removed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error removing iBridge User profile folder: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "ℹ️  iBridge User profile folder does not exist" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Step 3: Creating fresh accounts..." -ForegroundColor Yellow
Write-Host ""

# Create Admin account
Write-Host "Creating Admin account..." -ForegroundColor Green
try {
    $secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -FullName "iBridge Administrator" -Description "Administrator for application installation" -PasswordNeverExpires -AccountNeverExpires | Out-Null
    Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername | Out-Null
    Write-Host "✅ Admin account created successfully" -ForegroundColor Green
    Write-Host "   Username: $AdminUsername" -ForegroundColor White
    Write-Host "   Password: $AdminPassword" -ForegroundColor White
} catch {
    Write-Host "❌ Error creating Admin account: $($_.Exception.Message)" -ForegroundColor Red
}

# Create iBridge User account
Write-Host "Creating iBridge User account..." -ForegroundColor Green
try {
    $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
    New-LocalUser -Name $UserUsername -Password $secureUserPassword -FullName "iBridge User" -Description "Standard user with limited privileges" -PasswordNeverExpires -AccountNeverExpires | Out-Null
    Add-LocalGroupMember -Group "Users" -Member $UserUsername | Out-Null
    Write-Host "✅ iBridge User account created successfully" -ForegroundColor Green
    Write-Host "   Username: $UserUsername" -ForegroundColor White
    Write-Host "   Password: $UserPassword" -ForegroundColor White
} catch {
    Write-Host "❌ Error creating iBridge User account: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 4: Verification..." -ForegroundColor Yellow
Write-Host ""

# Verify accounts were created
$adminCheck = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
$userCheck = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue

Write-Host "Account verification:" -ForegroundColor White
if ($adminCheck) {
    Write-Host "✅ Admin account: EXISTS and READY" -ForegroundColor Green
} else {
    Write-Host "❌ Admin account: MISSING" -ForegroundColor Red
}

if ($userCheck) {
    Write-Host "✅ iBridge User account: EXISTS and READY" -ForegroundColor Green
} else {
    Write-Host "❌ iBridge User account: MISSING" -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "CLEANUP AND RECREATION COMPLETE!" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run the main setup script (iBridge-Simple-Setup.ps1)" -ForegroundColor White
Write-Host "2. The script should now work without 'already exists' errors" -ForegroundColor White
Write-Host "3. Fresh profiles will be created during the setup process" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to continue..."
Read-Host
