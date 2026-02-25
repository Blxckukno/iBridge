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

Write-Host "🧹 Starting cleanup of unwanted shortcuts..." -ForegroundColor Yellow

foreach ($profile in $ProfilesToClean) {
    $profilePath = "C:\Users\$profile"
    $desktopPath = "$profilePath\Desktop"
    
    if (Test-Path $desktopPath) {
        Write-Host "`n📂 Cleaning profile: $profile" -ForegroundColor Cyan
        
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
                    Write-Host "   ❌ Removed: $shortcutName" -ForegroundColor Red
                } catch {
                    Write-Host "   ⚠️  Failed to remove: $shortcutName - $($_.Exception.Message)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "   ✅ Kept: $shortcutName" -ForegroundColor Green
            }
        }
        
        # Also clean up desktop icons/files that aren't shortcuts
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
                    Write-Host "   ❌ Removed file: $fileName" -ForegroundColor Red
                } catch {
                    Write-Host "   ⚠️  Failed to remove file: $fileName - $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
        }
    } else {
        Write-Host "   ⚠️  Desktop not found for $profile" -ForegroundColor Yellow
    }
}

# Also check Start Menu shortcuts
Write-Host "`n🔍 Checking Start Menu shortcuts..." -ForegroundColor Cyan

foreach ($profile in $ProfilesToClean) {
    $startMenuPath = "C:\Users\$profile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
    
    if (Test-Path $startMenuPath) {
        $startMenuShortcuts = Get-ChildItem $startMenuPath -Recurse -Filter "*.lnk" -ErrorAction SilentlyContinue
        
        foreach ($shortcut in $startMenuShortcuts) {
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
                    Write-Host "   ❌ Removed Start Menu: $shortcutName" -ForegroundColor Red
                } catch {
                    Write-Host "   ⚠️  Failed to remove Start Menu: $shortcutName" -ForegroundColor Yellow
                }
            }
        }
    }
}

Write-Host "`n✅ Cleanup completed!" -ForegroundColor Green
Write-Host "Only the 4 official iBridge applications should remain on Admin and iBridge User profiles." -ForegroundColor Green
Write-Host "All other applications remain untouched on Lwandile Gasela profile." -ForegroundColor Green

pause
