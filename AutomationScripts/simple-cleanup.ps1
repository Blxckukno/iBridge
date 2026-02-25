# Simple iBridge Workspace Cleanup Script
Write-Host "Starting cleanup..." -ForegroundColor Green

# Set location
Set-Location "c:\Users\Lwandile Gasela\iBridge"

# Remove backup files
Write-Host "Removing backup files..." -ForegroundColor Yellow
Get-ChildItem -Recurse -Include "*.backup" | Remove-Item -Force
Write-Host "Backup files removed" -ForegroundColor Green

# Remove enhanced versions
Write-Host "Removing enhanced duplicates..." -ForegroundColor Yellow
$enhancedFiles = Get-ChildItem -Include "*-enhanced.html"
foreach ($file in $enhancedFiles) {
    Remove-Item $file.FullName -Force
    Write-Host "Removed: $($file.Name)" -ForegroundColor Gray
}

# Remove old index variations
Write-Host "Removing index variations..." -ForegroundColor Yellow
Get-ChildItem -Include "index-*.html", "index_*.html" | Remove-Item -Force

# Remove clean versions
Write-Host "Removing clean duplicates..." -ForegroundColor Yellow
Get-ChildItem -Include "*-clean.html" | Remove-Item -Force

Write-Host "Basic cleanup complete!" -ForegroundColor Green