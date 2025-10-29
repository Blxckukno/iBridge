# Quick-Cleanup.ps1
# Immediate disk cleanup using BleachBit (already downloaded)
# Run in an elevated PowerShell prompt

$toolkitRoot = "$PSScriptRoot\..\.."
$bleachBitZip = "$toolkitRoot\Freeware\03_System_Utilities\BleachBit-4.6.0-portable.zip"
$extractPath = "C:\Tools\BleachBit"

Write-Host "=== Quick Disk Cleanup Tool ===" -ForegroundColor Cyan

# Extract BleachBit if not already extracted
if (!(Test-Path "$extractPath\bleachbit.exe")) {
    Write-Host "Extracting BleachBit..." -ForegroundColor Yellow
    if (Test-Path $bleachBitZip) {
        New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        Expand-Archive -Path $bleachBitZip -DestinationPath $extractPath -Force
        Write-Host "BleachBit extracted to $extractPath" -ForegroundColor Green
    } else {
        Write-Error "BleachBit zip file not found at $bleachBitZip"
        exit 1
    }
}

# Run BleachBit with common cleanup options
Write-Host "Starting BleachBit cleanup..." -ForegroundColor Green
$bleachBitExe = "$extractPath\bleachbit.exe"

if (Test-Path $bleachBitExe) {
    # Run BleachBit GUI for user to select what to clean
    Start-Process -FilePath $bleachBitExe
    Write-Host "BleachBit started. Select cleanup options and click 'Clean'." -ForegroundColor Yellow
    Write-Host "Recommended: Temp files, Browser cache, Windows logs, Recycle bin" -ForegroundColor Cyan
} else {
    Write-Error "BleachBit executable not found after extraction"
}

Write-Host "`nFor automated cleanup, you can also run:" -ForegroundColor Cyan
Write-Host "Windows Disk Cleanup: cleanmgr /sagerun:1" -ForegroundColor White
Write-Host "Temp folder cleanup: Remove-Item -Path `$env:TEMP\* -Recurse -Force" -ForegroundColor White
