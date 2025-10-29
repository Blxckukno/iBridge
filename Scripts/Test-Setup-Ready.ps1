# Quick Setup Validation
# Tests the master script in validation-only mode

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "iBridge Setup Validation Test" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Testing the master script configuration..." -ForegroundColor Yellow
Write-Host ""

# Test if the master script exists
$masterScript = ".\iBridge-Complete-Setup.ps1"
if (Test-Path $masterScript) {
    Write-Host "[✓] Master script found: $masterScript" -ForegroundColor Green
} else {
    Write-Host "[✗] Master script not found: $masterScript" -ForegroundColor Red
    exit 1
}

# Test source file paths
Write-Host ""
Write-Host "Checking source file availability..." -ForegroundColor Yellow

$testPaths = @(
    "D:\TeamViewer_Setup_x64.exe",
    "D:\Tools for Office2019 TechXander", 
    "D:\24.2.2000.exe",
    "D:\PBIDesktopSetup_x64.exe",
    "d:\IT STUFF\Desktop-Mtn\MSTeamsSetup.exe",
    "d:\IT STUFF\Desktop-Mtn\Excel.lnk",
    "d:\IT STUFF\Desktop-Mtn\Microsoft 365 Online.url",
    "d:\IT STUFF\Desktop-Mtn\New Citrix Gateway.url",
    "d:\IT STUFF\Desktop-Mtn\Outlook.lnk",
    "d:\IT STUFF\Desktop-Mtn\PowerPoint.lnk",
    "d:\IT STUFF\Desktop-Mtn\Word.lnk"
)

$foundFiles = 0
$totalFiles = $testPaths.Count

foreach ($path in $testPaths) {
    if (Test-Path $path) {
        Write-Host "[✓] $path" -ForegroundColor Green
        $foundFiles++
    } else {
        Write-Host "[✗] $path" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Source files found: $foundFiles of $totalFiles" -ForegroundColor White

if ($foundFiles -eq $totalFiles) {
    Write-Host ""
    Write-Host "[✓] ALL FILES FOUND - READY TO RUN!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To run the complete setup:" -ForegroundColor Yellow
    Write-Host "  Option 1: Double-click RUN-COMPLETE-SETUP.bat" -ForegroundColor White
    Write-Host "  Option 2: Run as Admin: .\iBridge-Complete-Setup.ps1" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "[!] MISSING FILES - Setup may fail" -ForegroundColor Red
    Write-Host "Please ensure all source files are accessible before running setup." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to continue..."
Read-Host
