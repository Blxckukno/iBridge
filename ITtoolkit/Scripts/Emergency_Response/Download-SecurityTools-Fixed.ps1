# Download-SecurityTools-Fixed.ps1
# Manual download of security tools for emergency response

$toolsDir = "C:\Users\Lwandile Gasela\Desktop\iBridge_Emergency_Scan"
if (!(Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir -Force
}
Set-Location $toolsDir

Write-Host "=== DOWNLOADING SECURITY TOOLS ===" -ForegroundColor Red
Write-Host "Download location: $toolsDir" -ForegroundColor Yellow

$tools = @(
    @{Name="Malwarebytes"; URL="https://downloads.malwarebytes.com/file/mb4_offline"; File="mbam-setup.exe"}
    @{Name="HitmanPro"; URL="https://dl.surfright.nl/HitmanPro_x64.exe"; File="hitmanpro.exe"}
    @{Name="Process Explorer"; URL="https://download.sysinternals.com/files/ProcessExplorer.zip"; File="procexp.zip"}
    @{Name="Autoruns"; URL="https://download.sysinternals.com/files/Autoruns.zip"; File="autoruns.zip"}
    @{Name="TCPView"; URL="https://download.sysinternals.com/files/TCPView.zip"; File="tcpview.zip"}
)

$successCount = 0
foreach ($tool in $tools) {
    try {
        Write-Host "Downloading $($tool.Name)..." -ForegroundColor Cyan
        if (!(Test-Path $tool.File)) {
            Invoke-WebRequest -Uri $tool.URL -OutFile $tool.File -UseBasicParsing
            if (Test-Path $tool.File) {
                Write-Host "  Downloaded $($tool.Name) successfully" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "  Download failed for $($tool.Name)" -ForegroundColor Red
            }
        } else {
            Write-Host "  $($tool.Name) already exists" -ForegroundColor Gray
            $successCount++
        }
    } catch {
        Write-Host "  Download failed for $($tool.Name): $_" -ForegroundColor Red
    }
}

Write-Host "`n=== EXTRACTING ZIP FILES ===" -ForegroundColor Cyan
$zipFiles = @("procexp.zip", "autoruns.zip", "tcpview.zip")
foreach ($zip in $zipFiles) {
    if (Test-Path $zip) {
        try {
            Write-Host "Extracting $zip..." -ForegroundColor Yellow
            Expand-Archive -Path $zip -DestinationPath . -Force
            Write-Host "  Extracted $zip" -ForegroundColor Green
        } catch {
            Write-Host "  Failed to extract $zip" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== LAUNCHING SECURITY TOOLS ===" -ForegroundColor Red

# Launch HitmanPro
if (Test-Path "hitmanpro.exe") {
    Write-Host "Launching HitmanPro..." -ForegroundColor Yellow
    Start-Process -FilePath "hitmanpro.exe"
}

# Launch Sysinternals tools
if (Test-Path "procexp64.exe") {
    Write-Host "Launching Process Explorer..." -ForegroundColor Yellow
    Start-Process -FilePath "procexp64.exe"
}

if (Test-Path "Autoruns64.exe") {
    Write-Host "Launching Autoruns..." -ForegroundColor Yellow
    Start-Process -FilePath "Autoruns64.exe"
}

if (Test-Path "Tcpview.exe") {
    Write-Host "Launching TCPView..." -ForegroundColor Yellow
    Start-Process -FilePath "Tcpview.exe"
}

Write-Host "`n=== DOWNLOAD AND LAUNCH COMPLETE ===" -ForegroundColor Green
Write-Host "Successfully downloaded: $successCount/$($tools.Count) tools" -ForegroundColor Cyan
