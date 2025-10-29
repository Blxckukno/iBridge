# Simple FOSS Download Script
# Creates output directory and downloads key free alternatives

$outputDir = "$env:USERPROFILE\Desktop\FOSS_Tools"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    Write-Host "Created output directory: $outputDir" -ForegroundColor Green
}

# Enable TLS 1.2 for secure downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Starting FOSS tools download..." -ForegroundColor Cyan

# Key FOSS tools with verified URLs
$tools = @(
    @{ Name = "7-Zip"; Url = "https://www.7-zip.org/a/7z2408-x64.exe"; File = "7z2408-x64.exe" },
    @{ Name = "LibreOffice"; Url = "https://download.documentfoundation.org/libreoffice/stable/24.8.2/win/x86_64/LibreOffice_24.8.2_Win_x86-64.msi"; File = "LibreOffice_24.8.2_Win_x86-64.msi" },
    @{ Name = "Firefox"; Url = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"; File = "Firefox-Setup.exe" },
    @{ Name = "Thunderbird"; Url = "https://download.mozilla.org/?product=thunderbird-latest-ssl&os=win64&lang=en-US"; File = "Thunderbird-Setup.exe" },
    @{ Name = "VirtualBox"; Url = "https://download.virtualbox.org/virtualbox/7.1.4/VirtualBox-7.1.4-165100-Win.exe"; File = "VirtualBox-7.1.4-165100-Win.exe" },
    @{ Name = "KeePassXC"; Url = "https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-Win64.msi"; File = "KeePassXC-2.7.9-Win64.msi" },
    @{ Name = "VeraCrypt"; Url = "https://launchpad.net/veracrypt/trunk/1.26.15/+download/VeraCrypt%20Setup%201.26.15.exe"; File = "VeraCrypt-1.26.15.exe" },
    @{ Name = "Wireshark"; Url = "https://2.na.dl.wireshark.org/win64/Wireshark-4.4.1-x64.exe"; File = "Wireshark-4.4.1-x64.exe" },
    @{ Name = "Nmap"; Url = "https://nmap.org/dist/nmap-7.95-setup.exe"; File = "nmap-7.95-setup.exe" }
)

$downloaded = @()
$failed = @()

foreach ($tool in $tools) {
    try {
        $outFile = Join-Path $outputDir $tool.File
        Write-Host "Downloading $($tool.Name)..." -ForegroundColor Yellow
        
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $webClient.DownloadFile($tool.Url, $outFile)
        
        if (Test-Path $outFile) {
            $size = (Get-Item $outFile).Length / 1MB
            Write-Host "✓ Downloaded $($tool.Name) - $([math]::Round($size, 2)) MB" -ForegroundColor Green
            $downloaded += $tool.Name
        }
    }
    catch {
        Write-Host "✗ Failed to download $($tool.Name): $($_.Exception.Message)" -ForegroundColor Red
        $failed += $tool.Name
    }
}

Write-Host "`n=== DOWNLOAD SUMMARY ===" -ForegroundColor Cyan
Write-Host "Successfully downloaded: $($downloaded.Count) tools" -ForegroundColor Green
Write-Host "Failed downloads: $($failed.Count) tools" -ForegroundColor Red
Write-Host "Download location: $outputDir" -ForegroundColor Yellow

if ($downloaded.Count -gt 0) {
    Write-Host "`nSuccessfully downloaded:" -ForegroundColor Green
    $downloaded | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
}

if ($failed.Count -gt 0) {
    Write-Host "`nFailed downloads:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

Write-Host "`nReady to proceed with installation!" -ForegroundColor Cyan
