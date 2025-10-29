# Download-SecurityTools.ps1
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
    @{Name="Emsisoft EEK"; URL="https://cdn.emsisoft.com/EmsisoftEmergencyKit.exe"; File="eeksetup.exe"}
    @{Name="Process Explorer"; URL="https://download.sysinternals.com/files/ProcessExplorer.zip"; File="procexp.zip"}
    @{Name="Autoruns"; URL="https://download.sysinternals.com/files/Autoruns.zip"; File="autoruns.zip"}
    @{Name="TCPView"; URL="https://download.sysinternals.com/files/TCPView.zip"; File="tcpview.zip"}
    @{Name="RootkitRevealer"; URL="https://download.sysinternals.com/files/RootkitRevealer.zip"; File="rootkit.zip"}
    @{Name="Microsoft Safety Scanner"; URL="https://go.microsoft.com/fwlink/?LinkId=212732"; File="msert.exe"}
)

$successCount = 0
foreach ($tool in $tools) {
    try {
        Write-Host "Downloading $($tool.Name)..." -ForegroundColor Cyan
        if (!(Test-Path $tool.File)) {
            Invoke-WebRequest -Uri $tool.URL -OutFile $tool.File -UseBasicParsing
            if (Test-Path $tool.File) {
                Write-Host "  ✓ $($tool.Name) downloaded successfully" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "  ✗ $($tool.Name) download failed" -ForegroundColor Red
            }
        } else {
            Write-Host "  ✓ $($tool.Name) already exists" -ForegroundColor Gray
            $successCount++
        }
    } catch {
        Write-Host "  ✗ $($tool.Name) download failed: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== EXTRACTING ZIP FILES ===" -ForegroundColor Cyan
$zipFiles = @("procexp.zip", "autoruns.zip", "tcpview.zip", "rootkit.zip")
foreach ($zip in $zipFiles) {
    if (Test-Path $zip) {
        try {
            Write-Host "Extracting $zip..." -ForegroundColor Yellow
            Expand-Archive -Path $zip -DestinationPath . -Force
            Write-Host "  ✓ $zip extracted" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Failed to extract $zip" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== LAUNCHING SECURITY TOOLS ===" -ForegroundColor Red

# Launch Malwarebytes
if (Test-Path "mbam-setup.exe") {
    Write-Host "Installing Malwarebytes..." -ForegroundColor Green
    Start-Process -FilePath "mbam-setup.exe" -ArgumentList "/S" -Wait
    $mbamPath = "${env:ProgramFiles}\Malwarebytes\Anti-Malware\mbam.exe"
    if (Test-Path $mbamPath) {
        Write-Host "Launching Malwarebytes..." -ForegroundColor Yellow
        Start-Process -FilePath $mbamPath
    }
}

# Launch HitmanPro
if (Test-Path "hitmanpro.exe") {
    Write-Host "Launching HitmanPro..." -ForegroundColor Yellow
    Start-Process -FilePath "hitmanpro.exe"
}

# Launch Emsisoft
if (Test-Path "eeksetup.exe") {
    Write-Host "Extracting Emsisoft Emergency Kit..." -ForegroundColor Green
    Start-Process -FilePath "eeksetup.exe" -ArgumentList "/extract" -Wait
    if (Test-Path "EEK\start.exe") {
        Write-Host "Launching Emsisoft Emergency Kit..." -ForegroundColor Yellow
        Start-Process -FilePath "EEK\start.exe"
    }
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

if (Test-Path "RootkitRevealer64.exe") {
    Write-Host "Launching RootkitRevealer..." -ForegroundColor Yellow
    Start-Process -FilePath "RootkitRevealer64.exe"
}

# Launch Microsoft Safety Scanner
if (Test-Path "msert.exe") {
    Write-Host "Launching Microsoft Safety Scanner..." -ForegroundColor Yellow
    Start-Process -FilePath "msert.exe"
}

Write-Host "`n=== DOWNLOAD AND LAUNCH COMPLETE ===" -ForegroundColor Green
Write-Host "Successfully downloaded: $successCount/$($tools.Count) tools" -ForegroundColor Cyan
Write-Host "`nNEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Run FULL SCANS in each security tool" -ForegroundColor White
Write-Host "2. Quarantine/delete any threats found" -ForegroundColor White
Write-Host "3. Check the comprehensive user audit results" -ForegroundColor White
Write-Host "4. Review all @ibridge.co.za email accounts for:" -ForegroundColor White
Write-Host "   - Malicious forwarding rules" -ForegroundColor Gray
Write-Host "   - Unauthorized delegates" -ForegroundColor Gray
Write-Host "   - Suspicious login activity" -ForegroundColor Gray
Write-Host "5. Force password reset for ALL compromised accounts" -ForegroundColor White
Write-Host "6. Enable MFA on ALL accounts" -ForegroundColor White
