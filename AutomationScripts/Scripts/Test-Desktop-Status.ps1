# Test Desktop and Shortcut Status
Write-Host "Checking Desktop Status and Shortcuts" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow
Write-Host ""

# Check if user accounts exist
$adminExists = Get-LocalUser -Name "Admin" -ErrorAction SilentlyContinue
$userExists = Get-LocalUser -Name "iBridge User" -ErrorAction SilentlyContinue

Write-Host "User Account Status:" -ForegroundColor Cyan
if ($adminExists) {
    Write-Host "  ✓ Admin account exists" -ForegroundColor Green
} else {
    Write-Host "  ✗ Admin account missing" -ForegroundColor Red
}

if ($userExists) {
    Write-Host "  ✓ iBridge User account exists" -ForegroundColor Green
} else {
    Write-Host "  ✗ iBridge User account missing" -ForegroundColor Red
}

Write-Host ""

# Check desktop directories
$desktops = @(
    @{ Path = "C:\Users\Admin\Desktop"; Name = "Admin Desktop" },
    @{ Path = "C:\Users\iBridge User\Desktop"; Name = "iBridge User Desktop" }
)

Write-Host "Desktop Directory Status:" -ForegroundColor Cyan
foreach ($desktop in $desktops) {
    if (Test-Path $desktop.Path) {
        $shortcuts = Get-ChildItem $desktop.Path -Include "*.lnk", "*.url" -ErrorAction SilentlyContinue
        Write-Host "  ✓ $($desktop.Name): Exists ($($shortcuts.Count) shortcuts)" -ForegroundColor Green
        
        if ($shortcuts.Count -gt 0) {
            foreach ($shortcut in $shortcuts | Select-Object -First 3) {
                Write-Host "    - $($shortcut.Name)" -ForegroundColor Gray
            }
            if ($shortcuts.Count -gt 3) {
                Write-Host "    ... and $($shortcuts.Count - 3) more" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "  ✗ $($desktop.Name): Missing" -ForegroundColor Red
    }
}

Write-Host ""

# Check if iBridge setup folder exists
if (Test-Path "C:\iBridge_Setup") {
    Write-Host "iBridge Setup Folder Status:" -ForegroundColor Cyan
    Write-Host "  ✓ C:\iBridge_Setup exists" -ForegroundColor Green
    
    $subfolders = @("Installers", "Shortcuts", "Scripts", "Logs", "Temp")
    foreach ($folder in $subfolders) {
        $folderPath = "C:\iBridge_Setup\$folder"
        if (Test-Path $folderPath) {
            $itemCount = (Get-ChildItem $folderPath -ErrorAction SilentlyContinue).Count
            Write-Host "    ✓ $folder ($itemCount items)" -ForegroundColor Green
        } else {
            Write-Host "    ✗ $folder (missing)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "iBridge Setup Folder Status:" -ForegroundColor Cyan
    Write-Host "  ✗ C:\iBridge_Setup does not exist" -ForegroundColor Red
}

Write-Host ""
Write-Host "Recommendation:" -ForegroundColor Yellow
Write-Host "The enhanced script with version checking and fixes is ready." -ForegroundColor Green
Write-Host "Try running it again to see the improvements!" -ForegroundColor Green
