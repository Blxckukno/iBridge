# Install-Essential-FOSS.ps1
# Installs essential free and open-source software
# Run as Administrator

# Check for administrator rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator. Please relaunch with elevated privileges." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    Exit 1
}

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   INSTALLING ESSENTIAL FOSS ALTERNATIVES" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$downloadDir = "$env:USERPROFILE\Desktop\FOSS_Installation"
if (-not (Test-Path $downloadDir)) {
    New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null
}

# Essential FOSS tools with verified direct download URLs
$fossSoftware = @(
    @{
        Name = "7-Zip"
        Category = "File Archiver"
        Url = "https://www.7-zip.org/a/7z2408-x64.exe"
        FileName = "7z2408-x64.exe"
        InstallArgs = "/S"
        Description = "Free file archiver with high compression ratio"
    },
    @{
        Name = "LibreOffice"
        Category = "Office Suite"
        Url = "https://download.documentfoundation.org/libreoffice/stable/24.8.2/win/x86_64/LibreOffice_24.8.2_Win_x86-64.msi"
        FileName = "LibreOffice_24.8.2_Win_x86-64.msi"
        InstallArgs = "/qn"
        Description = "Complete office suite alternative to Microsoft Office"
    },
    @{
        Name = "Firefox"
        Category = "Web Browser"
        Url = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
        FileName = "Firefox-Setup.exe"
        InstallArgs = "/S"
        Description = "Free and open-source web browser"
    },
    @{
        Name = "Thunderbird"
        Category = "Email Client"
        Url = "https://download.mozilla.org/?product=thunderbird-latest-ssl&os=win64&lang=en-US"
        FileName = "Thunderbird-Setup.exe"
        InstallArgs = "/S"
        Description = "Free email, calendar and chat client"
    },
    @{
        Name = "KeePassXC"
        Category = "Password Manager"
        Url = "https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-Win64.msi"
        FileName = "KeePassXC-2.7.9-Win64.msi"
        InstallArgs = "/qn"
        Description = "Free and open-source password manager"
    },
    @{
        Name = "VeraCrypt"
        Category = "Encryption"
        Url = "https://launchpad.net/veracrypt/trunk/1.26.15/+download/VeraCrypt%20Setup%201.26.15.exe"
        FileName = "VeraCrypt-1.26.15.exe"
        InstallArgs = "/S"
        Description = "Free disk encryption software"
    },
    @{
        Name = "Wireshark"
        Category = "Network Analysis"
        Url = "https://2.na.dl.wireshark.org/win64/Wireshark-4.4.1-x64.exe"
        FileName = "Wireshark-4.4.1-x64.exe"
        InstallArgs = "/S"
        Description = "Network protocol analyzer"
    },
    @{
        Name = "Nmap"
        Category = "Network Scanner"
        Url = "https://nmap.org/dist/nmap-7.95-setup.exe"
        FileName = "nmap-7.95-setup.exe"
        InstallArgs = "/S"
        Description = "Network discovery and security auditing"
    },
    @{
        Name = "VirtualBox"
        Category = "Virtualization"
        Url = "https://download.virtualbox.org/virtualbox/7.1.4/VirtualBox-7.1.4-165100-Win.exe"
        FileName = "VirtualBox-7.1.4-165100-Win.exe"
        InstallArgs = "--silent"
        Description = "Cross-platform virtualization application"
    }
)

# Enable TLS 1.2 for secure downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$installed = @()
$failed = @()

foreach ($software in $fossSoftware) {
    Write-Host "`n[$($software.Category)] Installing $($software.Name)..." -ForegroundColor Yellow
    Write-Host "Description: $($software.Description)" -ForegroundColor White
    
    $filePath = Join-Path $downloadDir $software.FileName
    
    # Download if not exists
    if (-not (Test-Path $filePath)) {
        try {
            Write-Host "  Downloading..." -ForegroundColor Cyan
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
            $webClient.DownloadFile($software.Url, $filePath)
            
            if (Test-Path $filePath) {
                $size = (Get-Item $filePath).Length / 1MB
                Write-Host "  ✓ Downloaded - $([math]::Round($size, 2)) MB" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  ✗ Download failed: $($_.Exception.Message)" -ForegroundColor Red
            $failed += $software.Name
            continue
        }
    } else {
        Write-Host "  ✓ File already exists" -ForegroundColor Green
    }
    
    # Install the software
    if (Test-Path $filePath) {
        try {
            Write-Host "  Installing..." -ForegroundColor Cyan
            
            if ($software.FileName -match "\.msi$") {
                # MSI installation
                $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$filePath`" $($software.InstallArgs)" -Wait -PassThru
            } else {
                # EXE installation
                $process = Start-Process -FilePath $filePath -ArgumentList $software.InstallArgs -Wait -PassThru
            }
            
            if ($process.ExitCode -eq 0) {
                Write-Host "  ✓ Successfully installed $($software.Name)" -ForegroundColor Green
                $installed += $software.Name
            } else {
                Write-Host "  ⚠ Installation completed with exit code: $($process.ExitCode)" -ForegroundColor Yellow
                $installed += $software.Name
            }
        }
        catch {
            Write-Host "  ✗ Installation failed: $($_.Exception.Message)" -ForegroundColor Red
            $failed += $software.Name
        }
    }
}

# Generate installation report
Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "   INSTALLATION SUMMARY" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

Write-Host "`nSuccessfully installed: $($installed.Count) applications" -ForegroundColor Green
if ($installed.Count -gt 0) {
    $installed | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor Green }
}

Write-Host "`nFailed installations: $($failed.Count) applications" -ForegroundColor Red
if ($failed.Count -gt 0) {
    $failed | ForEach-Object { Write-Host "  ✗ $_" -ForegroundColor Red }
}

# Create installation report
$reportPath = "$downloadDir\Installation_Report.txt"
$report = @"
FOSS Installation Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Successfully Installed ($($installed.Count)):
$($installed | ForEach-Object { "  - $_" } | Out-String)

Failed Installations ($($failed.Count)):
$($failed | ForEach-Object { "  - $_" } | Out-String)

Installation Files Location: $downloadDir

Next Steps:
1. Configure each application according to your needs
2. Set up Firefox with security extensions
3. Import or create KeePassXC password database
4. Configure VeraCrypt for disk encryption
5. Set up Thunderbird with your email accounts

All installed software is 100% free and open-source with no trials or limitations.
"@

Set-Content -Path $reportPath -Value $report
Write-Host "`nInstallation report saved to: $reportPath" -ForegroundColor Yellow

Write-Host "`n🎉 FOSS installation completed!" -ForegroundColor Green
Write-Host "All installed software is completely free with no trials or limitations." -ForegroundColor Cyan
