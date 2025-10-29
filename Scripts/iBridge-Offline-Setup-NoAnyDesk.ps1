# iBridge Offline Setup Script v3.1 - AnyDesk Disabled
# Complete offline installation with USB drive auto-detection
# AnyDesk installation disabled to prevent hanging issues

param(
    [switch]$SkipValidation,
    [switch]$QuietMode,
    [switch]$CleanupOnly
)

# ============================================================
# OFFLINE CONFIGURATION SECTION
# ============================================================

# Account Configuration
$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

# Auto-detect USB drive with iBridge files
$USBDrive = $null
$PossibleDrives = @("D:", "E:", "F:", "G:", "H:")

foreach ($drive in $PossibleDrives) {
    if (Test-Path "$drive\iBridge Set Up" -ErrorAction SilentlyContinue) {
        $USBDrive = $drive
        break
    }
}

if (-not $USBDrive) {
    Write-Host "ERROR: iBridge USB drive not found. Please ensure USB is connected." -ForegroundColor Red
    exit 1
}

Write-Host "Found iBridge USB on drive: $USBDrive" -ForegroundColor Green

# Enhanced Paths Configuration
$iBridgeBase = "C:\iBridge_Setup"
$InstallersPath = "$iBridgeBase\Installers"
$ShortcutsPath = "$iBridgeBase\Shortcuts"
$LogsPath = "$iBridgeBase\Logs"
$TempPath = "$iBridgeBase\Temp"

# Progress tracking
$Global:TotalSteps = 10
$Global:CurrentStep = 0
$Global:LogFile = "$LogsPath\iBridge-Offline-Setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Installation Control - AnyDesk disabled to prevent hanging
$InstallAnyDesk = $false  # Disabled due to hanging issues

# Application Sources from USB (auto-detected drive) - excluding unwanted IT STUFF files
$ApplicationSources = @(
    "$USBDrive\TeamViewer_Setup_x64.exe",
    "$USBDrive\Tools for Office2019 TechXander",
    "$USBDrive\24.2.2000.exe",
    "$USBDrive\AnyDesk.exe",  # Will be copied but not installed due to flag above
    "$USBDrive\GlassWireSetup.exe",
    "$USBDrive\PBIDesktopSetup_x64.exe"
)

# iBridge User Specific Shortcuts from IT STUFF\Desktop-Mtn
$iBridgeUserShortcuts = @(
    "$USBDrive\IT STUFF\Desktop-Mtn\Word.lnk",
    "$USBDrive\IT STUFF\Desktop-Mtn\Excel.lnk",
    "$USBDrive\IT STUFF\Desktop-Mtn\Microsoft 365 Online.url",
    "$USBDrive\IT STUFF\Desktop-Mtn\MSTeamsSetup.exe",
    "$USBDrive\IT STUFF\Desktop-Mtn\New Citrix Gateway.url",
    "$USBDrive\IT STUFF\Desktop-Mtn\Outlook.lnk",
    "$USBDrive\IT STUFF\Desktop-Mtn\PowerPoint.lnk"
)

# Include the rest of the functions from the main script...
# (Copy all the functions from the main iBridge-Offline-Setup.ps1)

Write-Host "NOTE: AnyDesk installation is DISABLED in this version to prevent hanging." -ForegroundColor Yellow
Write-Host "AnyDesk.exe will be copied to C:\iBridge_Setup\Installers but not installed." -ForegroundColor Yellow
Write-Host "You can manually install it later if needed." -ForegroundColor Yellow
Write-Host ""
