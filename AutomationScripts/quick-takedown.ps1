# Quick Site Takedown - Replace with Offline Page
# Run this script to immediately replace your site with an offline page

Write-Host "🚧 Quick Site Takedown - iBridge" -ForegroundColor Red
Write-Host "=================================" -ForegroundColor Red

# Create simple offline page
$offlineContent = @'
<!DOCTYPE html>
<html><head><title>Site Offline</title><style>body{font-family:Arial;text-align:center;padding:100px;background:#f0f0f0;}h1{color:#333;}.container{max-width:400px;margin:0 auto;padding:40px;background:white;border-radius:10px;box-shadow:0 4px 20px rgba(0,0,0,0.1);}</style></head><body><div class="container"><h1>🚧 Site Temporarily Offline</h1><p>We're performing maintenance.</p><p>Please visit our temporary site:</p><a href="https://blxckukno.github.io/iBridge/">iBridge Temporary Site</a></div></body></html>
'@

# Save offline page
$offlineContent | Out-File -FilePath "quick-offline.html" -Encoding UTF8

Write-Host "✅ Offline page created: quick-offline.html" -ForegroundColor Green

# Show upload instructions
Write-Host "`n📋 Manual Upload Instructions:" -ForegroundColor Yellow
Write-Host "1. Go to: https://s41.registerdomain.net.za/cpanel" -ForegroundColor White
Write-Host "2. Login with username: ibridgeb" -ForegroundColor White
Write-Host "3. Open 'File Manager'" -ForegroundColor White
Write-Host "4. Navigate to 'public_html' folder" -ForegroundColor White
Write-Host "5. Upload 'quick-offline.html'" -ForegroundColor White
Write-Host "6. Rename it to 'index.html' (replace existing)" -ForegroundColor White

Write-Host "`n🤖 Or use the automated script:" -ForegroundColor Cyan
Write-Host ".\takedown-site.ps1 -Action offline" -ForegroundColor White

# Ask if user wants to run automated script
$response = Read-Host "`nRun automated takedown now? (y/n)"
if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host "`n🚀 Running automated takedown..." -ForegroundColor Green
    .\takedown-site.ps1 -Action offline
} else {
    Write-Host "`n📁 Files created. Upload manually or run takedown script later." -ForegroundColor Yellow
}

Write-Host "`n⚠️  IMPORTANT: Change your passwords after takedown!" -ForegroundColor Red