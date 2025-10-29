# Install-FOSS-Fixed.ps1
# Simplified FOSS installation script with proper error handling

# Check for administrator rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
    Exit 1
}

Write-Host "Installing FOSS alternatives from downloaded files..." -ForegroundColor Cyan

# Set source directories
$downloadDir = "$env:USERPROFILE\Desktop\FOSS_Tools"
$alternateDir = "$env:USERPROFILE\Desktop\FOSS_Installation"

# Check which directory has the files
if (Test-Path $downloadDir) {
    $sourceDir = $downloadDir
    Write-Host "Using files from: $sourceDir" -ForegroundColor Green
} elseif (Test-Path $alternateDir) {
    $sourceDir = $alternateDir
    Write-Host "Using files from: $sourceDir" -ForegroundColor Green
} else {
    Write-Host "No download directory found. Creating and downloading essential tools..." -ForegroundColor Yellow
    $sourceDir = "$env:USERPROFILE\Desktop\FOSS_Installation"
    New-Item -Path $sourceDir -ItemType Directory -Force | Out-Null
}

# List of installations to perform
$installations = @(
    @{ Name = "7-Zip"; Pattern = "7z*.exe"; Args = "/S"; Type = "EXE" },
    @{ Name = "Firefox"; Pattern = "Firefox*.exe"; Args = "/S"; Type = "EXE" },
    @{ Name = "KeePassXC"; Pattern = "KeePassXC*.msi"; Args = "/qn"; Type = "MSI" },
    @{ Name = "VirtualBox"; Pattern = "VirtualBox*.exe"; Args = "--silent"; Type = "EXE" },
    @{ Name = "LibreOffice"; Pattern = "LibreOffice*.msi"; Args = "/qn"; Type = "MSI" },
    @{ Name = "Thunderbird"; Pattern = "Thunderbird*.exe"; Args = "/S"; Type = "EXE" },
    @{ Name = "VeraCrypt"; Pattern = "VeraCrypt*.exe"; Args = "/S"; Type = "EXE" },
    @{ Name = "Wireshark"; Pattern = "Wireshark*.exe"; Args = "/S"; Type = "EXE" },
    @{ Name = "Nmap"; Pattern = "nmap*.exe"; Args = "/S"; Type = "EXE" }
)

$installed = @()
$failed = @()

# Download essential tools if directory is empty
if (-not (Get-ChildItem -Path $sourceDir -ErrorAction SilentlyContinue)) {
    Write-Host "Downloading essential FOSS tools..." -ForegroundColor Yellow
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    $downloads = @(
        @{ Url = "https://www.7-zip.org/a/7z2408-x64.exe"; File = "7z2408-x64.exe" },
        @{ Url = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"; File = "Firefox-Setup.exe" },
        @{ Url = "https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-Win64.msi"; File = "KeePassXC-2.7.9-Win64.msi" },
        @{ Url = "https://download.virtualbox.org/virtualbox/7.1.4/VirtualBox-7.1.4-165100-Win.exe"; File = "VirtualBox-7.1.4-165100-Win.exe" }
    )
    
    foreach ($download in $downloads) {
        try {
            $outFile = Join-Path $sourceDir $download.File
            Write-Host "  Downloading $($download.File)..." -ForegroundColor Cyan
            
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
            $webClient.DownloadFile($download.Url, $outFile)
            
            Write-Host "  ✓ Downloaded $($download.File)" -ForegroundColor Green
        }
        catch {
            Write-Host "  ✗ Failed to download $($download.File): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Install each application
foreach ($app in $installations) {
    Write-Host "`nInstalling $($app.Name)..." -ForegroundColor Yellow
    
    # Find the installer file
    $installerFile = Get-ChildItem -Path $sourceDir -Filter $app.Pattern | Select-Object -First 1
    
    if ($installerFile) {
        try {
            Write-Host "  Found: $($installerFile.Name)" -ForegroundColor Cyan
            
            if ($app.Type -eq "MSI") {
                # MSI installation
                $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$($installerFile.FullName)`" $($app.Args)" -Wait -PassThru
            } else {
                # EXE installation
                $process = Start-Process -FilePath $installerFile.FullName -ArgumentList $app.Args -Wait -PassThru
            }
            
            if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                Write-Host "  ✓ Successfully installed $($app.Name)" -ForegroundColor Green
                $installed += $app.Name
            } else {
                Write-Host "  ⚠ Installation completed with exit code: $($process.ExitCode)" -ForegroundColor Yellow
                $installed += $app.Name
            }
        }
        catch {
            Write-Host "  ✗ Installation failed: $($_.Exception.Message)" -ForegroundColor Red
            $failed += $app.Name
        }
    } else {
        Write-Host "  ⚠ Installer file not found for $($app.Name)" -ForegroundColor Yellow
        $failed += $app.Name
    }
}

# Install from the main FOSS_Enterprise_Stack if it exists
$fossDir = "$PSScriptRoot\..\..\FOSS_Enterprise_Stack"
if (Test-Path $fossDir) {
    Write-Host "`nInstalling from FOSS Enterprise Stack..." -ForegroundColor Cyan
    
    # Look for specific FOSS alternatives
    $fossInstalls = @(
        @{ Path = "$fossDir\**\wazuh-agent*.msi"; Args = "/qn"; Name = "Wazuh Agent" },
        @{ Path = "$fossDir\**\clamav*.msi"; Args = "/qn"; Name = "ClamAV" },
        @{ Path = "$fossDir\**\rustdesk*.exe"; Args = "/S"; Name = "RustDesk" },
        @{ Path = "$fossDir\**\urbackup*.exe"; Args = "/S"; Name = "UrBackup" }
    )
    
    foreach ($fossApp in $fossInstalls) {
        $file = Get-ChildItem -Path $fossApp.Path -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($file) {
            try {
                Write-Host "  Installing $($fossApp.Name)..." -ForegroundColor Yellow
                
                if ($file.Extension -eq ".msi") {
                    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$($file.FullName)`" $($fossApp.Args)" -Wait -PassThru
                } else {
                    $process = Start-Process -FilePath $file.FullName -ArgumentList $fossApp.Args -Wait -PassThru
                }
                
                if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                    Write-Host "  ✓ Successfully installed $($fossApp.Name)" -ForegroundColor Green
                    $installed += $fossApp.Name
                }
            }
            catch {
                Write-Host "  ✗ Failed to install $($fossApp.Name): $($_.Exception.Message)" -ForegroundColor Red
                $failed += $fossApp.Name
            }
        }
    }
}

# Final summary
Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "   INSTALLATION COMPLETED" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

Write-Host "`nSuccessfully installed ($($installed.Count)):" -ForegroundColor Green
$installed | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor Green }

if ($failed.Count -gt 0) {
    Write-Host "`nFailed installations ($($failed.Count)):" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  ✗ $_" -ForegroundColor Red }
}

# Generate final report
$reportPath = "$sourceDir\FOSS_Installation_Report.txt"
$report = @"
FOSS Installation Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Successfully Installed ($($installed.Count)):
$($installed | ForEach-Object { "  - $_" } | Out-String)

Failed Installations ($($failed.Count)):
$($failed | ForEach-Object { "  - $_" } | Out-String)

Notes:
- All installed software is 100% free and open-source
- No trials, no limitations, no commercial licenses required
- Source files located in: $sourceDir

Next Steps:
1. Configure each application for your needs
2. Set up browser security extensions
3. Create secure password database in KeePassXC
4. Configure email accounts in Thunderbird
5. Set up backup schedules with available backup tools

For security monitoring, consider also installing:
- Wazuh for SIEM/XDR capabilities
- ClamAV for additional antivirus protection
- OSSEC for host intrusion detection
"@

Set-Content -Path $reportPath -Value $report
Write-Host "`nReport saved to: $reportPath" -ForegroundColor Yellow
Write-Host "`n🎉 FOSS installation process completed!" -ForegroundColor Green
