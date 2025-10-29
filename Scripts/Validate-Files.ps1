# Pre-Installation Validation Script
# Checks if all source files exist before starting installation

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Pre-Installation File Validation" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Application paths to check
$ApplicationPaths = @(
    "D:\TeamViewer_Setup_x64.exe",
    "D:\Tools for Office2019 TechXander",
    "D:\24.2.2000.exe",
    "D:\PBIDesktopSetup_x64.exe",
    "d:\IT STUFF\Desktop-Mtn\MSTeamsSetup.exe"
)

# Shortcut paths to check
$ShortcutPaths = @(
    "d:\IT STUFF\Desktop-Mtn\Excel.lnk",
    "d:\IT STUFF\Desktop-Mtn\Microsoft 365 Online.url",
    "d:\IT STUFF\Desktop-Mtn\New Citrix Gateway.url",
    "d:\IT STUFF\Desktop-Mtn\Outlook.lnk",
    "d:\IT STUFF\Desktop-Mtn\PowerPoint.lnk",
    "d:\IT STUFF\Desktop-Mtn\Word.lnk"
)

$AllPaths = $ApplicationPaths + $ShortcutPaths
$FoundFiles = @()
$MissingFiles = @()

Write-Host "Checking application files..." -ForegroundColor Yellow
foreach ($path in $ApplicationPaths) {
    if (Test-Path $path) {
        Write-Host "[FOUND] $path" -ForegroundColor Green
        $FoundFiles += $path
    } else {
        Write-Host "[MISSING] $path" -ForegroundColor Red
        $MissingFiles += $path
    }
}

Write-Host ""
Write-Host "Checking shortcut files..." -ForegroundColor Yellow
foreach ($path in $ShortcutPaths) {
    if (Test-Path $path) {
        Write-Host "[FOUND] $path" -ForegroundColor Green
        $FoundFiles += $path
    } else {
        Write-Host "[MISSING] $path" -ForegroundColor Red
        $MissingFiles += $path
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host "Files Found: $($FoundFiles.Count)" -ForegroundColor Green
Write-Host "Files Missing: $($MissingFiles.Count)" -ForegroundColor Red
Write-Host ""

if ($MissingFiles.Count -gt 0) {
    Write-Host "Missing Files:" -ForegroundColor Red
    foreach ($missing in $MissingFiles) {
        Write-Host "  - $missing" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Please ensure all files are in the correct locations before running the installation script." -ForegroundColor Yellow
} else {
    Write-Host "All files found! Ready to proceed with installation." -ForegroundColor Green
    Write-Host ""
    Write-Host "Run the installation script with:" -ForegroundColor Yellow
    Write-Host "  .\Install-Apps-And-Shortcuts.ps1" -ForegroundColor White
}

Write-Host ""
Write-Host "Press any key to continue..."
Read-Host
