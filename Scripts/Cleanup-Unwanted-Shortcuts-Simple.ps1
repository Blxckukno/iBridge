# Cleanup Unwanted Shortcuts from Admin and iBridge User Profiles
# Removes shortcuts that should only be on Lwandile Gasela profile

# Only keep these applications on Admin and iBridge User profiles (the 4 official ones)
$AllowedApplications = @(
    "24.2.2000",
    "GlassWire",
    "Power BI Desktop", 
    "TeamViewer"
)

# Get all user profiles except Lwandile Gasela
$ProfilesToClean = @("Admin", "iBridge User")

Write-Host "Cleanup: Starting cleanup of unwanted shortcuts..." -ForegroundColor Yellow

foreach ($profile in $ProfilesToClean) {
    $profilePath = "C:\Users\$profile"
    $desktopPath = "$profilePath\Desktop"
    
    if (Test-Path $desktopPath) {
        Write-Host "Cleaning profile: $profile" -ForegroundColor Cyan
        
        # Get all shortcuts on desktop
        $shortcuts = Get-ChildItem $desktopPath -Filter "*.lnk" -ErrorAction SilentlyContinue
        
        foreach ($shortcut in $shortcuts) {
            $shortcutName = $shortcut.BaseName
            $shouldKeep = $false
            
            # Check if this is one of the allowed applications
            foreach ($allowed in $AllowedApplications) {
                if ($shortcutName -like "*$allowed*") {
                    $shouldKeep = $true
                    break
                }
            }
            
            if (-not $shouldKeep) {
                try {
                    Remove-Item $shortcut.FullName -Force
                    Write-Host "   Removed: $shortcutName" -ForegroundColor Red
                } catch {
                    Write-Host "   Failed to remove: $shortcutName" -ForegroundColor Yellow
                }
            } else {
                Write-Host "   Kept: $shortcutName" -ForegroundColor Green
            }
        }
        
        # Also clean up desktop files that aren't shortcuts
        $desktopFiles = Get-ChildItem $desktopPath -File | Where-Object { $_.Extension -ne ".lnk" }
        
        foreach ($file in $desktopFiles) {
            $fileName = $file.BaseName
            $shouldKeep = $false
            
            # Check if this is one of the allowed applications
            foreach ($allowed in $AllowedApplications) {
                if ($fileName -like "*$allowed*") {
                    $shouldKeep = $true
                    break
                }
            }
            
            if (-not $shouldKeep) {
                try {
                    Remove-Item $file.FullName -Force
                    Write-Host "   Removed file: $fileName" -ForegroundColor Red
                } catch {
                    Write-Host "   Failed to remove file: $fileName" -ForegroundColor Yellow
                }
            }
        }
    } else {
        Write-Host "   Desktop not found for $profile" -ForegroundColor Yellow
    }
}

Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host "Only the 4 official iBridge applications should remain on Admin and iBridge User profiles." -ForegroundColor Green

pause
