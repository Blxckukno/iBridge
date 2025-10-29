# Post-Install.ps1
# Master post-installation script that runs all installations and configurations
# Run in an elevated PowerShell prompt after a fresh Windows install

Import-Module "$PSScriptRoot\..\Modules\Get-Latest.psm1"

Write-Host "=== IT Toolkit Post-Installation Script ===" -ForegroundColor Cyan
Write-Host "Installing Freeware applications..." -ForegroundColor Green

# Install Freeware applications
& "$PSScriptRoot\Install-Downloaded.ps1"

Write-Host "`nInstalling FOSS Enterprise Stack..." -ForegroundColor Green

# Install FOSS applications
& "$PSScriptRoot\Install-FOSS.ps1"

Write-Host "`n=== Installation Summary ===" -ForegroundColor Cyan
Write-Host "Freeware and FOSS applications have been installed." -ForegroundColor Green
Write-Host "Manual extraction required for:" -ForegroundColor Yellow
Write-Host "- BleachBit (portable)" -ForegroundColor Yellow
Write-Host "- Everything (portable)" -ForegroundColor Yellow
Write-Host "- ClamAV (manual setup required)" -ForegroundColor Yellow

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Extract portable applications from their zip files" -ForegroundColor White
Write-Host "2. Configure Wazuh agent with your server IP" -ForegroundColor White
Write-Host "3. Set up ClamAV for on-demand scanning" -ForegroundColor White
Write-Host "4. Configure RustDesk for remote access" -ForegroundColor White

Write-Host "`nPost-Install setup complete!" -ForegroundColor Green
