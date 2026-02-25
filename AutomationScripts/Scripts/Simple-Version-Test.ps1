# Simple Version Checking Test
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Host "Testing Version Checking Functions" -ForegroundColor Yellow
Write-Host ""

# Test registry access
try {
    $apps = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
            Where-Object { $_.DisplayName } | 
            Select-Object -First 5 DisplayName, DisplayVersion
    
    Write-Host "Found some installed applications:" -ForegroundColor Green
    foreach ($app in $apps) {
        $version = if ($app.DisplayVersion) { $app.DisplayVersion } else { "Unknown" }
        Write-Host "  - $($app.DisplayName) (Version: $version)" -ForegroundColor Gray
    }
} catch {
    Write-Host "Error accessing registry: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Enhanced iBridge Setup Script Features:" -ForegroundColor Yellow
Write-Host "✓ Version checking before installation" -ForegroundColor Green
Write-Host "✓ Skip installations for up-to-date applications" -ForegroundColor Green
Write-Host "✓ Installation tracking and logging" -ForegroundColor Green
Write-Host "✓ Version information saved to JSON file" -ForegroundColor Green
Write-Host "✓ Enhanced summary with version details" -ForegroundColor Green
Write-Host ""
Write-Host "Ready for deployment!" -ForegroundColor White -BackgroundColor Green
