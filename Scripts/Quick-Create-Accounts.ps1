# Quick Account Creation Script
# Run this as Administrator to create the accounts

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "Creating accounts with correct passwords..." -ForegroundColor Green
Write-Host ""

# Admin account
Write-Host "Creating Admin account..." -ForegroundColor Yellow
try {
    $adminPassword = ConvertTo-SecureString "IBr1dG3Pc" -AsPlainText -Force
    New-LocalUser -Name "Admin" -Password $adminPassword -Description "Administrator account" -PasswordNeverExpires -AccountNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member "Admin"
    Write-Host "SUCCESS: Admin account created" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

# iBridge User account
Write-Host "Creating iBridge User account..." -ForegroundColor Yellow
try {
    $userPassword = ConvertTo-SecureString "Abc654321!" -AsPlainText -Force
    New-LocalUser -Name "iBridge User" -Password $userPassword -Description "Standard user account" -PasswordNeverExpires -AccountNeverExpires
    Add-LocalGroupMember -Group "Users" -Member "iBridge User"
    Write-Host "SUCCESS: iBridge User account created" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

# Create shared folder
Write-Host "Creating shared folder..." -ForegroundColor Yellow
try {
    if (!(Test-Path "C:\iBridge_Apps")) {
        New-Item -ItemType Directory -Path "C:\iBridge_Apps" -Force
    }
    Write-Host "SUCCESS: Shared folder created" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Account Details:" -ForegroundColor Cyan
Write-Host "Admin - Username: Admin, Password: IBr1dG3Pc" -ForegroundColor White
Write-Host "User  - Username: iBridge User, Password: Abc654321!" -ForegroundColor White
Write-Host ""
Write-Host "Verification:" -ForegroundColor Yellow
Get-LocalUser | Where-Object {$_.Name -in @("Admin", "iBridge User")} | Format-Table Name, Enabled, Description
