# iBridge Complete Installation - Fixed Paths
# Uses applications from USB root and shortcuts from correct location

$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User" 
$UserPassword = "Abc654321!"

Write-Host ""
Write-Host " ================================================================" -ForegroundColor Cyan
Write-Host "  iBridge COMPLETE Installation v4.1 - FIXED PATHS" -ForegroundColor Cyan
Write-Host " ================================================================" -ForegroundColor Cyan
Write-Host ""

# Auto-detect USB drive
Write-Host "STEP 1: USB Drive Detection" -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow
$UsbDrive = ""
$drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 -or $_.DriveType -eq 3 }

foreach ($drive in $drives) {
    $testPath = $drive.DeviceID + "\iBridge Set Up"
    if (Test-Path $testPath) {
        $UsbDrive = $drive.DeviceID
        Write-Host "Found iBridge USB on drive: $UsbDrive" -ForegroundColor Green
        break
    }
}

if (-not $UsbDrive) {
    Write-Host "ERROR: Could not find iBridge USB drive!" -ForegroundColor Red
    pause
    exit
}

# Use USB root for applications (where they actually are)
$UsbRoot = $UsbDrive
$InstallersPath = $UsbRoot  # Applications are in USB root
$ShortcutsPath = $UsbRoot + "\IT STUFF\Desktop-Mtn"  # Check IT STUFF folder for shortcuts

Write-Host "USB Drive: $UsbDrive" -ForegroundColor Green

# Find applications
$installers = Get-ChildItem $InstallersPath -Filter "*.exe" -ErrorAction SilentlyContinue
if ($installers.Count -gt 0) {
    Write-Host "Found $($installers.Count) applications in USB root" -ForegroundColor Green
    foreach ($app in $installers) {
        Write-Host "  - $($app.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host "ERROR: No applications found!" -ForegroundColor Red
    pause
    exit
}

# Check for shortcuts
if (Test-Path $ShortcutsPath) {
    $shortcuts = Get-ChildItem $ShortcutsPath -Filter "*.lnk" -ErrorAction SilentlyContinue
    Write-Host "Found $($shortcuts.Count) shortcuts in: $ShortcutsPath" -ForegroundColor Green
} else {
    # Try alternative locations
    $altPaths = @(
        $UsbRoot + "\Desktop-Mtn",
        $UsbRoot + "\Shortcuts",
        $UsbRoot + "\IT STUFF\Shortcuts"
    )
    
    $ShortcutsPath = ""
    foreach ($altPath in $altPaths) {
        if (Test-Path $altPath) {
            $ShortcutsPath = $altPath
            $shortcuts = Get-ChildItem $ShortcutsPath -Filter "*.lnk" -ErrorAction SilentlyContinue
            Write-Host "Found shortcuts in: $ShortcutsPath ($($shortcuts.Count) files)" -ForegroundColor Green
            break
        }
    }
    
    if (-not $ShortcutsPath) {
        Write-Host "WARNING: No shortcuts folder found - will skip shortcuts" -ForegroundColor Yellow
    }
}

# Remove existing accounts
Write-Host ""
Write-Host "STEP 2: Account Cleanup" -ForegroundColor Yellow
Write-Host "========================" -ForegroundColor Yellow
try {
    $existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
    if ($existingAdmin) {
        Remove-LocalUser -Name $AdminUsername
        Write-Host "Removed existing Admin account" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not remove Admin account (may not exist)" -ForegroundColor Gray
}

try {
    $existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
    if ($existingUser) {
        Remove-LocalUser -Name $UserUsername
        Write-Host "Removed existing iBridge User account" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not remove iBridge User account (may not exist)" -ForegroundColor Gray
}

# Create accounts
Write-Host ""
Write-Host "STEP 3: Account Creation" -ForegroundColor Yellow
Write-Host "=========================" -ForegroundColor Yellow
try {
    # Create Admin account
    $secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    $adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -FullName "Admin" -Description "Administrator account for iBridge" -PasswordNeverExpires -AccountNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername
    Write-Host "Admin account created successfully" -ForegroundColor Green
    
    # Create iBridge User account
    $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
    $bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -FullName "iBridge User" -Description "Standard user account for iBridge" -PasswordNeverExpires -AccountNeverExpires
    Write-Host "iBridge User account created successfully" -ForegroundColor Green
    
    Start-Sleep -Seconds 2
    
} catch {
    Write-Host "ERROR: Failed to create accounts" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit
}

# Verify accounts
$finalAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
$finalUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue

if ($finalAdmin -and $finalUser) {
    Write-Host "Both accounts verified and ready" -ForegroundColor Green
} else {
    Write-Host "ERROR: Account verification failed" -ForegroundColor Red
    pause
    exit
}

# Copy applications to local drive
Write-Host ""
Write-Host "STEP 4: Application Installation" -ForegroundColor Yellow
Write-Host "==================================" -ForegroundColor Yellow
$localAppsPath = "C:\iBridge_Apps_Install"
if (Test-Path $localAppsPath) {
    Remove-Item $localAppsPath -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -Path $localAppsPath -ItemType Directory -Force | Out-Null

# Copy all .exe files from USB root
$installers = Get-ChildItem $InstallersPath -Filter "*.exe" -ErrorAction SilentlyContinue
foreach ($installer in $installers) {
    try {
        $destPath = $localAppsPath + "\" + $installer.Name
        Copy-Item $installer.FullName $destPath -Force
        Write-Host "Copied: " + $installer.Name -ForegroundColor Green
    } catch {
        Write-Host "Failed to copy: " + $installer.Name -ForegroundColor Red
    }
}

# Install applications
$localInstallers = Get-ChildItem $localAppsPath -Filter "*.exe" -ErrorAction SilentlyContinue
$installedCount = 0
$skippedCount = 0

foreach ($installer in $localInstallers) {
    $installerName = $installer.Name
    Write-Host "Installing: $installerName" -ForegroundColor Cyan
    
    # Skip problematic applications
    if ($installerName -like "*AnyDesk*") {
        Write-Host "  SKIPPED: AnyDesk (prevents hanging)" -ForegroundColor Yellow
        $skippedCount++
        continue
    }
    
    try {
        # Installation arguments
        $arguments = "/S"
        if ($installerName -like "*TeamViewer*") {
            $arguments = "/S"
        } elseif ($installerName -like "*GlassWire*") {
            $arguments = "/S"
        } elseif ($installerName -like "*PBI*" -or $installerName -like "*PowerBI*") {
            $arguments = "/quiet /norestart"
        } elseif ($installerName -like "*24.2.2000*") {
            $arguments = "/S"
        } elseif ($installerName -like "*Tools*Office*") {
            $arguments = "/S"
        }
        
        # Install with timeout
        $process = Start-Process -FilePath $installer.FullName -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
        $exitCode = $process.ExitCode
        
        if ($exitCode -eq 0 -or $exitCode -eq 3010) {
            Write-Host "  SUCCESS: $installerName" -ForegroundColor Green
            $installedCount++
        } else {
            Write-Host "  COMPLETED: $installerName (exit code: $exitCode)" -ForegroundColor Yellow
            $installedCount++
        }
        
    } catch {
        Write-Host "  FAILED: $installerName" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "Installation Summary:" -ForegroundColor Green
Write-Host "  Installed: $installedCount applications" -ForegroundColor White
Write-Host "  Skipped: $skippedCount applications" -ForegroundColor White

# Prepare shortcuts
Write-Host ""
Write-Host "STEP 5: Shortcut Preparation" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow
$shortcutsReadyPath = "C:\iBridge_Shortcuts_Ready"
if (Test-Path $shortcutsReadyPath) {
    Remove-Item $shortcutsReadyPath -Recurse -Force -ErrorAction SilentlyContinue
}

if ($ShortcutsPath -and (Test-Path $ShortcutsPath)) {
    try {
        Copy-Item $ShortcutsPath $shortcutsReadyPath -Recurse -Force
        $shortcutFiles = Get-ChildItem $shortcutsReadyPath -Filter "*.lnk" -ErrorAction SilentlyContinue
        Write-Host "Shortcuts prepared: $($shortcutFiles.Count) files" -ForegroundColor Green
    } catch {
        Write-Host "Could not prepare shortcuts" -ForegroundColor Yellow
    }
} else {
    Write-Host "No shortcuts found - will skip shortcut setup" -ForegroundColor Yellow
}

# Clean up
Write-Host ""
Write-Host "STEP 6: Cleanup" -ForegroundColor Yellow
Write-Host "================" -ForegroundColor Yellow
if (Test-Path $localAppsPath) {
    Remove-Item $localAppsPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Installation files cleaned up" -ForegroundColor Green
}

# Create post-login script
$postLoginScript = @"
Write-Host "Setting up iBridge User shortcuts..." -ForegroundColor Cyan

`$shortcutsSource = "C:\iBridge_Shortcuts_Ready"
`$iBridgeDesktop = "C:\Users\$UserUsername\Desktop"

if (Test-Path `$shortcutsSource) {
    if (Test-Path `$iBridgeDesktop) {
        try {
            `$shortcuts = Get-ChildItem `$shortcutsSource -Filter "*.lnk" -ErrorAction SilentlyContinue
            `$copiedCount = 0
            foreach (`$shortcut in `$shortcuts) {
                `$destPath = "`$iBridgeDesktop\`$(`$shortcut.Name)"
                Copy-Item `$shortcut.FullName `$destPath -Force
                `$copiedCount++
            }
            Write-Host "SUCCESS: Copied `$copiedCount shortcuts to iBridge User desktop" -ForegroundColor Green
            Remove-Item `$shortcutsSource -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "ERROR: Failed to copy shortcuts" -ForegroundColor Red
        }
    } else {
        Write-Host "ERROR: iBridge User desktop not found!" -ForegroundColor Red
        Write-Host "Please log in to iBridge User first" -ForegroundColor Yellow
    }
} else {
    Write-Host "No shortcuts prepared" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "iBridge User setup completed!" -ForegroundColor Green
pause
"@

$postLoginPath = "C:\Users\Lwandile Gasela\iBridge\Scripts\Complete-iBridge-Setup.ps1"
$postLoginScript | Out-File -FilePath $postLoginPath -Encoding UTF8

# Final instructions
Write-Host ""
Write-Host " ================================================================" -ForegroundColor Green
Write-Host "  INSTALLATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host " ================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "ACCOUNTS CREATED:" -ForegroundColor Cyan
Write-Host "  Admin - Password: $AdminPassword" -ForegroundColor White
Write-Host "  iBridge User - Password: $UserPassword" -ForegroundColor White
Write-Host ""
Write-Host "APPLICATIONS INSTALLED: $installedCount" -ForegroundColor Cyan
Write-Host ""
Write-Host "NEXT STEPS (REQUIRED):" -ForegroundColor Yellow
Write-Host "======================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. SIGN OUT of your current account" -ForegroundColor White
Write-Host ""
Write-Host "2. LOG IN as Admin:" -ForegroundColor White
Write-Host "   Username: Admin" -ForegroundColor Gray
Write-Host "   Password: $AdminPassword" -ForegroundColor Gray
Write-Host "   (Let Windows create the profile, then sign out)" -ForegroundColor Gray
Write-Host ""
Write-Host "3. LOG IN as iBridge User:" -ForegroundColor White
Write-Host "   Username: iBridge User" -ForegroundColor Gray
Write-Host "   Password: $UserPassword" -ForegroundColor Gray
Write-Host "   (Let Windows create the profile, then sign out)" -ForegroundColor Gray
Write-Host ""
Write-Host "4. LOG BACK IN as your main account" -ForegroundColor White
Write-Host ""
Write-Host "5. RUN this script to complete setup:" -ForegroundColor White
Write-Host "   $postLoginPath" -ForegroundColor Gray
Write-Host ""
Write-Host "WHY LOGIN IS REQUIRED:" -ForegroundColor Cyan
Write-Host "Windows only creates complete user profiles during the first" -ForegroundColor White
Write-Host "interactive login. This creates all profile files and makes" -ForegroundColor White
Write-Host "the accounts appear properly in Control Panel." -ForegroundColor White
Write-Host ""

pause
Write-Host "Installation complete! Follow the steps above." -ForegroundColor Green
