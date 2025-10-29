# Quick$re    "D:\24.2.2000.exe", 
    "D:\GlassWireSetup.exe",redFiles = @(
    "D:\24.2.2000.exe", 
    "D:\GlassWireSetup.exe",e Check - Verify Required Files Exist
# Run this to check if all required files are present before running setup

Write-Host "iBridge Setup - File Verification" -ForegroundColor White -BackgroundColor Blue
Write-Host "Checking for required files..." -ForegroundColor Cyan
Write-Host ""

$RequiredFiles = @(
    "D:\24.2.2000.exe",
    "D:\GlassWireSetup.exe",
    "D:\PBIDesktopSetup_x64.exe",
    "D:\TeamViewer_Setup_x64.exe",
    "D:\Tools for Office2019 TechXander",
    "D:\IT STUFF"
)

$foundCount = 0
$totalCount = $RequiredFiles.Count

foreach ($file in $RequiredFiles) {
    if (Test-Path $file) {
        Write-Host "FOUND: $file" -ForegroundColor Green
        $foundCount++
    } else {
        Write-Host "MISSING: $file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Summary: $foundCount of $totalCount files found" -ForegroundColor $(if($foundCount -eq $totalCount){"Green"}else{"Yellow"})

if ($foundCount -eq $totalCount) {
    Write-Host "All required files are present! You can run the setup." -ForegroundColor Green
} else {
    Write-Host "Some files are missing. The setup will continue with available files." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
