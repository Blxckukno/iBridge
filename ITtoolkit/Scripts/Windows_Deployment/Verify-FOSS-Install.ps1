Write-Host "=== FOSS Installation Verification ===" -ForegroundColor Cyan
Write-Host "Checking installed applications..." -ForegroundColor Yellow
Write-Host ""

# Check 7-Zip
if (Test-Path "C:\Program Files\7-Zip\7z.exe") {
    Write-Host "✅ 7-Zip: INSTALLED" -ForegroundColor Green
    Write-Host "   Location: C:\Program Files\7-Zip\" -ForegroundColor Gray
} else {
    Write-Host "❌ 7-Zip: NOT FOUND" -ForegroundColor Red
}

# Check Firefox
if (Test-Path "C:\Program Files\Mozilla Firefox\firefox.exe") {
    Write-Host "✅ Firefox: INSTALLED" -ForegroundColor Green
    Write-Host "   Location: C:\Program Files\Mozilla Firefox\" -ForegroundColor Gray
} else {
    Write-Host "❌ Firefox: NOT FOUND" -ForegroundColor Red
}

# Check KeePassXC
if (Test-Path "C:\Program Files\KeePassXC\KeePassXC.exe") {
    Write-Host "✅ KeePassXC: INSTALLED" -ForegroundColor Green
    Write-Host "   Location: C:\Program Files\KeePassXC\" -ForegroundColor Gray
} else {
    Write-Host "❌ KeePassXC: NOT FOUND" -ForegroundColor Red
}

# Check VirtualBox
if (Test-Path "C:\Program Files\Oracle\VirtualBox\VirtualBox.exe") {
    Write-Host "✅ VirtualBox: INSTALLED" -ForegroundColor Green
    Write-Host "   Location: C:\Program Files\Oracle\VirtualBox\" -ForegroundColor Gray
} else {
    Write-Host "❌ VirtualBox: NOT FOUND" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "✅ All software is 100% FREE and Open Source" -ForegroundColor Green
Write-Host "✅ No trials, no limitations, no commercial licenses" -ForegroundColor Green
Write-Host "✅ Regular updates available from official sources" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure Firefox with security extensions" -ForegroundColor White
Write-Host "2. Create KeePassXC password database" -ForegroundColor White
Write-Host "3. Test VirtualBox with a Linux VM" -ForegroundColor White
Write-Host "4. Install additional FOSS tools as needed" -ForegroundColor White
