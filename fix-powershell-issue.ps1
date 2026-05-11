# ========================================
# iBridge - PowerShell OneDrive Fix
# ========================================
# PowerShell script to fix the OneDrive configuration issue
# Run: powershell -ExecutionPolicy Bypass -File fix-powershell-issue.ps1

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "iBridge - PowerShell OneDrive Fix" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Define paths
$oneDrivePath = "$env:USERPROFILE\OneDrive - iBridge Contact Solutions (Pty) Ltd\Documents\PowerShell"
$configFile = "$oneDrivePath\powershell.config.json"
$backupFile = "$oneDrivePath\powershell.config.json.backup"
$disabledFile = "$oneDrivePath\powershell.config.json.disabled"

Write-Host "Checking system configuration..." -ForegroundColor Cyan
Write-Host ""

# Check if OneDrive folder exists
if (-not (Test-Path -Path $oneDrivePath)) {
    Write-Host "✓ PowerShell OneDrive folder not found - no issue to fix" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

# Check if config file exists
if (-not (Test-Path -Path $configFile)) {
    Write-Host "✓ PowerShell config file not found - no issue to fix" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

Write-Host "⚠️  Found problematic PowerShell configuration file" -ForegroundColor Yellow
Write-Host "📍 File: $configFile" -ForegroundColor Yellow
Write-Host ""

# Check if already fixed
if (Test-Path -Path $disabledFile) {
    Write-Host "✓ File is already disabled/fixed" -ForegroundColor Green
    Write-Host ""
    Write-Host "The issue has already been resolved. PowerShell should work normally now." -ForegroundColor Green
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

# Create backup
if (-not (Test-Path -Path $backupFile)) {
    try {
        Copy-Item -Path $configFile -Destination $backupFile -ErrorAction Stop
        Write-Host "✓ Backup created: powershell.config.json.backup" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Warning: Could not create backup (might need admin rights)" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Rename the file to disable it
Write-Host "Disabling problematic configuration..." -ForegroundColor Cyan

try {
    Rename-Item -Path $configFile -NewName "powershell.config.json.disabled" -ErrorAction Stop
    Write-Host "✓ Successfully disabled problematic file!" -ForegroundColor Green
    Write-Host "  Renamed to: powershell.config.json.disabled" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎉 Fix Complete! Your system should now work normally." -ForegroundColor Green
    Write-Host ""
    Write-Host "What was fixed:" -ForegroundColor Cyan
    Write-Host "  - PowerShell will no longer try to load the OneDrive config" -ForegroundColor Gray
    Write-Host "  - Terminal commands should execute without errors" -ForegroundColor Gray
    Write-Host "  - Your development environment is ready" -ForegroundColor Gray
    Write-Host ""
    Write-Host "If you need to restore the original file, rename:" -ForegroundColor Gray
    Write-Host "  powershell.config.json.disabled -> powershell.config.json" -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "✗ Error: Could not rename file" -ForegroundColor Red
    Write-Host ""
    Write-Host "This might be due to:" -ForegroundColor Yellow
    Write-Host "  1. File is in use by OneDrive sync" -ForegroundColor Gray
    Write-Host "  2. Requires administrator privileges" -ForegroundColor Gray
    Write-Host "  3. File permissions are restricted" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Solution:" -ForegroundColor Cyan
    Write-Host "  - Close OneDrive or pause syncing" -ForegroundColor Gray
    Write-Host "  - Run this script as Administrator" -ForegroundColor Gray
    Write-Host "  - Or use the VBS script (fix-powershell-issue.vbs)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
