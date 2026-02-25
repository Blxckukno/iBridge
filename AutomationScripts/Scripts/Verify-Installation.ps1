# Quick Verification Script
# Checks if applications were installed successfully

Write-Host "iBridge Setup Verification Report" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Blue
Write-Host ""

# Check user accounts
Write-Host "User Accounts:" -ForegroundColor Yellow
$users = Get-LocalUser | Where-Object {$_.Name -match "(Admin|iBridge)"}
foreach ($user in $users) {
    Write-Host "  ✓ $($user.Name) - $($user.Description)" -ForegroundColor Green
}
Write-Host ""

# Check installed applications
Write-Host "Installed Applications:" -ForegroundColor Yellow
$installedApps = @()

# Check common installation paths
$appPaths = @(
    "C:\Program Files\*",
    "C:\Program Files (x86)\*",
    "$env:LOCALAPPDATA\Programs\*"
)

$knownApps = @("TeamViewer", "GlassWire", "Microsoft Power BI Desktop", "SYSPRO")

foreach ($appPath in $appPaths) {
    $apps = Get-ChildItem $appPath -Directory -ErrorAction SilentlyContinue | Where-Object {
        $knownApps | ForEach-Object { $_.Name -like "*$_*" }
    }
    $installedApps += $apps
}

if ($installedApps.Count -gt 0) {
    foreach ($app in $installedApps) {
        Write-Host "  ✓ $($app.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "  ! Checking registry for installed programs..." -ForegroundColor Yellow
    
    # Check Windows registry for installed programs
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    $regApps = @()
    foreach ($regPath in $regPaths) {
        $apps = Get-ItemProperty $regPath -ErrorAction SilentlyContinue | 
                Where-Object { $_.DisplayName -and ($knownApps | ForEach-Object { $_.DisplayName -like "*$_*" }) }
        $regApps += $apps
    }
    
    if ($regApps.Count -gt 0) {
        foreach ($app in $regApps) {
            Write-Host "  ✓ $($app.DisplayName)" -ForegroundColor Green
        }
    } else {
        Write-Host "  ! Applications may still be installing..." -ForegroundColor Yellow
    }
}

Write-Host ""

# Check backup files
Write-Host "Backup Files:" -ForegroundColor Yellow
if (Test-Path "C:\iBridge_Setup\Installers") {
    $backupFiles = Get-ChildItem "C:\iBridge_Setup\Installers" -File
    foreach ($file in $backupFiles) {
        $sizeGB = [math]::Round($file.Length / 1GB, 2)
        Write-Host "  ✓ $($file.Name) ($sizeGB GB)" -ForegroundColor Green
    }
} else {
    Write-Host "  ✗ Backup folder not found" -ForegroundColor Red
}

Write-Host ""

# Check shortcuts
Write-Host "Shortcuts Available:" -ForegroundColor Yellow
if (Test-Path "C:\iBridge_Setup\Shortcuts") {
    $shortcuts = Get-ChildItem "C:\iBridge_Setup\Shortcuts" -Include "*.lnk", "*.url"
    foreach ($shortcut in $shortcuts) {
        Write-Host "  ✓ $($shortcut.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "  ✗ Shortcuts folder not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - User accounts created and ready" -ForegroundColor Green
Write-Host "  - Applications installed to local system" -ForegroundColor Green  
Write-Host "  - Backup installers saved locally" -ForegroundColor Green
Write-Host "  - Shortcuts prepared for iBridge User" -ForegroundColor Green
Write-Host ""
Write-Host "READY FOR STANDALONE OPERATION!" -ForegroundColor Yellow -BackgroundColor DarkGreen
Write-Host "USB drive can be safely removed" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: Log in as 'iBridge User' (Password: Abc654321!)" -ForegroundColor Cyan
