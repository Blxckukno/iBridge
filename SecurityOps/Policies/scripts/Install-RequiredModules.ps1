# Install Required PowerShell Modules
# This script installs the necessary modules for Exchange Online management

Write-Host "Installing Required PowerShell Modules for Microsoft 365 Management" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Warning "This script should be run as Administrator for system-wide installation."
    Write-Host "If you continue, modules will be installed for the current user only." -ForegroundColor Yellow
    $scope = "CurrentUser"
} else {
    $scope = "AllUsers"
}

# Set TLS to 1.2 for PowerShell Gallery
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Required modules
$requiredModules = @(
    @{
        Name = "ExchangeOnlineManagement"
        Description = "Exchange Online PowerShell module for managing Exchange Online"
        MinimumVersion = "3.0.0"
    },
    @{
        Name = "MSOnline"
        Description = "Microsoft Online Services module for legacy operations"
        MinimumVersion = "1.1.0"
    },
    @{
        Name = "AzureAD"
        Description = "Azure Active Directory PowerShell module"
        MinimumVersion = "2.0.0"
    }
)

Write-Host "Installation scope: $scope" -ForegroundColor Gray
Write-Host ""

foreach ($module in $requiredModules) {
    Write-Host "Processing module: $($module.Name)" -ForegroundColor Yellow
    Write-Host "  Description: $($module.Description)" -ForegroundColor Gray
    
    # Check if module is already installed
    $installedModule = Get-Module -ListAvailable -Name $module.Name | Sort-Object Version -Descending | Select-Object -First 1
    
    if ($installedModule) {
        $installedVersion = $installedModule.Version
        Write-Host "  Current version: $installedVersion" -ForegroundColor Cyan
        
        # Check if we need to update
        $latestVersion = Find-Module -Name $module.Name -ErrorAction SilentlyContinue
        if ($latestVersion -and $latestVersion.Version -gt $installedVersion) {
            Write-Host "  Newer version available: $($latestVersion.Version)" -ForegroundColor Green
            try {
                Update-Module -Name $module.Name -Scope $scope -Force
                Write-Host "  ✓ Module updated successfully" -ForegroundColor Green
            }
            catch {
                Write-Warning "  Failed to update module: $($_.Exception.Message)"
            }
            catch {
                Write-Warning "  Failed to update module: $($_.Exception.Message)"
            }
        } else {
            Write-Host "  ✓ Module is up to date" -ForegroundColor Green
        }
    } else {
        Write-Host "  Installing module..." -ForegroundColor Yellow
        try {
            Install-Module -Name $module.Name -Scope $scope -Force -AllowClobber -MinimumVersion $module.MinimumVersion
            Write-Host "  ✓ Module installed successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "  Failed to install module: $($_.Exception.Message)"
        }
    }
    Write-Host ""
}

# Verify installations
Write-Host "Verifying module installations..." -ForegroundColor Cyan
foreach ($module in $requiredModules) {
    $installedModule = Get-Module -ListAvailable -Name $module.Name | Sort-Object Version -Descending | Select-Object -First 1
    if ($installedModule) {
        Write-Host "✓ $($module.Name) v$($installedModule.Version) - Installed" -ForegroundColor Green
    } else {
        Write-Host "✗ $($module.Name) - Not found" -ForegroundColor Red
    }
}

Write-Host "`n=== Installation Complete ===" -ForegroundColor Cyan
Write-Host "You can now run Connect-ExchangeOnline.ps1 to connect to your Microsoft 365 environment." -ForegroundColor Green

# Additional setup instructions
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Update the configuration file: config\email-config.json" -ForegroundColor White
Write-Host "2. Connect to Exchange Online: .\scripts\Connect-ExchangeOnline.ps1" -ForegroundColor White
Write-Host "3. Configure email policies: .\scripts\Configure-EmailPolicies.ps1 -WhatIf" -ForegroundColor White
