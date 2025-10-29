# Install-Basic-FOSS.ps1
# Simple FOSS installation script

Write-Host "Installing FOSS alternatives..." -ForegroundColor Cyan

# Check for administrator rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
    Exit 1
}

$sourceDir = "$env:USERPROFILE\Desktop\FOSS_Tools"
$installed = @()
$failed = @()

Write-Host "Looking for installers in: $sourceDir" -ForegroundColor Yellow

# Install 7-Zip
$sevenZip = Get-ChildItem -Path $sourceDir -Filter "7z*.exe" | Select-Object -First 1
if ($sevenZip) {
    Write-Host "Installing 7-Zip..." -ForegroundColor Cyan
    $process = Start-Process -FilePath $sevenZip.FullName -ArgumentList "/S" -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "✓ 7-Zip installed successfully" -ForegroundColor Green
        $installed += "7-Zip"
    } else {
        Write-Host "✗ 7-Zip installation failed" -ForegroundColor Red
        $failed += "7-Zip"
    }
}

# Install Firefox
$firefox = Get-ChildItem -Path $sourceDir -Filter "Firefox*.exe" | Select-Object -First 1
if ($firefox) {
    Write-Host "Installing Firefox..." -ForegroundColor Cyan
    $process = Start-Process -FilePath $firefox.FullName -ArgumentList "/S" -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "✓ Firefox installed successfully" -ForegroundColor Green
        $installed += "Firefox"
    } else {
        Write-Host "✗ Firefox installation failed" -ForegroundColor Red
        $failed += "Firefox"
    }
}

# Install KeePassXC
$keepass = Get-ChildItem -Path $sourceDir -Filter "KeePassXC*.msi" | Select-Object -First 1
if ($keepass) {
    Write-Host "Installing KeePassXC..." -ForegroundColor Cyan
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$($keepass.FullName)`" /qn" -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "✓ KeePassXC installed successfully" -ForegroundColor Green
        $installed += "KeePassXC"
    } else {
        Write-Host "✗ KeePassXC installation failed" -ForegroundColor Red
        $failed += "KeePassXC"
    }
}

# Install VirtualBox
$vbox = Get-ChildItem -Path $sourceDir -Filter "VirtualBox*.exe" | Select-Object -First 1
if ($vbox) {
    Write-Host "Installing VirtualBox..." -ForegroundColor Cyan
    $process = Start-Process -FilePath $vbox.FullName -ArgumentList "--silent" -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "✓ VirtualBox installed successfully" -ForegroundColor Green
        $installed += "VirtualBox"
    } else {
        Write-Host "✗ VirtualBox installation failed" -ForegroundColor Red
        $failed += "VirtualBox"
    }
}

# Summary
Write-Host "`n=== Installation Summary ===" -ForegroundColor Cyan
Write-Host "Successfully installed ($($installed.Count)):" -ForegroundColor Green
foreach ($app in $installed) {
    Write-Host "  ✓ $app" -ForegroundColor Green
}

if ($failed.Count -gt 0) {
    Write-Host "`nFailed installations ($($failed.Count)):" -ForegroundColor Red
    foreach ($app in $failed) {
        Write-Host "  ✗ $app" -ForegroundColor Red
    }
}

Write-Host "`nInstallation completed!" -ForegroundColor Green
