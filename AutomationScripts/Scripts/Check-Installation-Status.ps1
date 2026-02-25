# Installation Status Checker
# Monitors the installation progress and verifies results

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Installation Status Checker" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if iBridge_Apps folder structure exists
Write-Host "Checking folder structure..." -ForegroundColor Yellow

$Folders = @(
    "C:\iBridge_Apps",
    "C:\iBridge_Apps\Installers", 
    "C:\iBridge_Apps\Shortcuts"
)

foreach ($folder in $Folders) {
    if (Test-Path $folder) {
        $itemCount = (Get-ChildItem $folder -ErrorAction SilentlyContinue).Count
        Write-Host "[FOUND] $folder ($itemCount items)" -ForegroundColor Green
    } else {
        Write-Host "[MISSING] $folder" -ForegroundColor Red
    }
}

Write-Host ""

# Check for copied installers
Write-Host "Checking copied installers..." -ForegroundColor Yellow
$InstallerPath = "C:\iBridge_Apps\Installers"
if (Test-Path $InstallerPath) {
    $installers = Get-ChildItem $InstallerPath -ErrorAction SilentlyContinue
    if ($installers.Count -gt 0) {
        foreach ($installer in $installers) {
            Write-Host "[FOUND] $($installer.Name)" -ForegroundColor Green
        }
    } else {
        Write-Host "[INFO] No installers copied yet" -ForegroundColor Yellow
    }
} else {
    Write-Host "[INFO] Installer directory not created yet" -ForegroundColor Yellow
}

Write-Host ""

# Check for shortcuts
Write-Host "Checking shortcuts..." -ForegroundColor Yellow
$ShortcutPath = "C:\iBridge_Apps\Shortcuts"
if (Test-Path $ShortcutPath) {
    $shortcuts = Get-ChildItem $ShortcutPath -ErrorAction SilentlyContinue
    if ($shortcuts.Count -gt 0) {
        foreach ($shortcut in $shortcuts) {
            Write-Host "[FOUND] $($shortcut.Name)" -ForegroundColor Green
        }
    } else {
        Write-Host "[INFO] No shortcuts copied yet" -ForegroundColor Yellow
    }
} else {
    Write-Host "[INFO] Shortcuts directory not created yet" -ForegroundColor Yellow
}

Write-Host ""

# Check desktop shortcuts for users
Write-Host "Checking user desktop shortcuts..." -ForegroundColor Yellow

$UserDesktops = @(
    "C:\Users\Admin\Desktop",
    "C:\Users\iBridge User\Desktop"
)

foreach ($desktop in $UserDesktops) {
    $username = Split-Path (Split-Path $desktop) -Leaf
    if (Test-Path $desktop) {
        $shortcuts = Get-ChildItem $desktop -Filter "*.lnk" -ErrorAction SilentlyContinue
        $urls = Get-ChildItem $desktop -Filter "*.url" -ErrorAction SilentlyContinue
        $totalShortcuts = $shortcuts.Count + $urls.Count
        Write-Host "[FOUND] $username desktop ($totalShortcuts shortcuts)" -ForegroundColor Green
    } else {
        Write-Host "[INFO] $username desktop not found (created on first login)" -ForegroundColor Blue
    }
}

Write-Host ""

# Check installed programs (basic check)
Write-Host "Checking for installed programs..." -ForegroundColor Yellow

$ProgramsToCheck = @("TeamViewer", "Microsoft Power BI Desktop")
foreach ($program in $ProgramsToCheck) {
    $installed = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*$program*"} -ErrorAction SilentlyContinue
    if ($installed) {
        Write-Host "[INSTALLED] $program" -ForegroundColor Green
    } else {
        Write-Host "[CHECKING] $program (may still be installing)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Status Check Complete" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "To test the setup:" -ForegroundColor Yellow
Write-Host "1. Log in as iBridge User (Password: Abc654321!)" -ForegroundColor Gray
Write-Host "2. Check desktop for application shortcuts" -ForegroundColor Gray  
Write-Host "3. Browse to C:\iBridge_Apps to see all resources" -ForegroundColor Gray

Write-Host ""
Write-Host "Press any key to continue..."
Read-Host
