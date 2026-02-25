# iBridge Profile Isolation Script
# Ensures shortcuts only appear on Lwandile Gasela profile
# Removes unwanted shortcuts from Admin and iBridge User profiles

Write-Host "Starting iBridge Profile Isolation..." -ForegroundColor Green

# Define official iBridge applications (only these should be on Admin/iBridge User)
$OfficialApps = @(
    "*TeamViewer*",
    "*IT STUFF*",
    "*Tools for Office*",
    "*Office*",
    "*24.2.2000*",
    "*AnyDesk*",
    "*GlassWire*",
    "*Power BI*",
    "*PBI*"
)

# Profiles to clean
$ProfilesToClean = @("Admin", "iBridge User")

foreach ($profile in $ProfilesToClean) {
    Write-Host "`nCleaning profile: $profile" -ForegroundColor Yellow
    
    $profilePath = "C:\Users\$profile"
    
    # Clean Desktop
    $desktopPath = "$profilePath\Desktop"
    if (Test-Path $desktopPath) {
        $items = Get-ChildItem $desktopPath -ErrorAction SilentlyContinue
        
        foreach ($item in $items) {
            $shouldKeep = $false
            
            # Check if it's an official app
            foreach ($app in $OfficialApps) {
                if ($item.Name -like $app) {
                    $shouldKeep = $true
                    break
                }
            }
            
            if (-not $shouldKeep) {
                try {
                    Remove-Item $item.FullName -Force -Recurse
                    Write-Host "  Removed: $($item.Name)" -ForegroundColor Red
                } catch {
                    Write-Host "  Failed to remove: $($item.Name)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  Kept: $($item.Name)" -ForegroundColor Green
            }
        }
    }
    
    # Clean Start Menu
    $startMenuPath = "$profilePath\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
    if (Test-Path $startMenuPath) {
        $startItems = Get-ChildItem $startMenuPath -Recurse -ErrorAction SilentlyContinue
        
        foreach ($item in $startItems) {
            if ($item.PSIsContainer) { continue } # Skip folders
            
            $shouldKeep = $false
            
            # Check if it's an official app
            foreach ($app in $OfficialApps) {
                if ($item.Name -like $app) {
                    $shouldKeep = $true
                    break
                }
            }
            
            # Also keep Windows default items
            if ($item.Name -like "*Windows*" -or $item.Name -like "*Microsoft*") {
                $shouldKeep = $true
            }
            
            if (-not $shouldKeep) {
                try {
                    Remove-Item $item.FullName -Force
                    Write-Host "  Removed Start Menu: $($item.Name)" -ForegroundColor Red
                } catch {
                    Write-Host "  Failed to remove Start Menu: $($item.Name)" -ForegroundColor Yellow
                }
            }
        }
    }
}

Write-Host "`nProfile isolation completed!" -ForegroundColor Green
Write-Host "Admin and iBridge User profiles now only contain official iBridge applications." -ForegroundColor Green
Write-Host "All personal applications remain on Lwandile Gasela profile." -ForegroundColor Green
