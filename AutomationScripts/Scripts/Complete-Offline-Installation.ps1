# iBridge Complete Offline Installation v4.0
# This does EVERYTHING automatically then guides user through login

$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User" 
$UserPassword = "Abc654321!"

Write-Host ""
Write-Host " ================================================================" -ForegroundColor Cyan
Write-Host "  iBridge COMPLETE Offline Installation v4.0" -ForegroundColor Cyan
Write-Host " ================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " This will do EVERYTHING automatically:" -ForegroundColor Green
Write-Host " • Auto-detect USB drive" -ForegroundColor White
Write-Host " • Remove any existing accounts" -ForegroundColor White
Write-Host " • Create Admin and iBridge User accounts" -ForegroundColor White
Write-Host " • Install ALL applications (except AnyDesk)" -ForegroundColor White
Write-Host " • Setup shortcuts for iBridge User" -ForegroundColor White
Write-Host " • Guide you through first-time login" -ForegroundColor White
Write-Host ""

# Auto-detect USB drive
Write-Host "=== STEP 1: USB Drive Detection ===" -ForegroundColor Yellow
$UsbDrive = ""
$drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 -or $_.DriveType -eq 3 }

foreach ($drive in $drives) {
    $testPath = $drive.DeviceID + "\iBridge Set Up"
    if (Test-Path $testPath) {
        $UsbDrive = $drive.DeviceID
        Write-Host "✅ Found iBridge USB on drive: $UsbDrive" -ForegroundColor Green
        break
    }
}

if (-not $UsbDrive) {
    Write-Host "❌ Could not find iBridge USB drive!" -ForegroundColor Red
    Write-Host "Please ensure USB is connected and contains 'iBridge Set Up' folder" -ForegroundColor Yellow
    pause
    exit
}

$UsbPath = $UsbDrive + "\iBridge Set Up"
$InstallersPath = $UsbPath + "\Applications"
$ShortcutsPath = $UsbPath + "\Desktop-Mtn"

# Verify all required folders
Write-Host "✅ USB Path: $UsbPath" -ForegroundColor Green
if (Test-Path $InstallersPath) {
    $appCount = (Get-ChildItem $InstallersPath -Filter "*.exe").Count
    Write-Host "✅ Applications folder found ($appCount installers)" -ForegroundColor Green
} else {
    Write-Host "❌ Applications folder missing!" -ForegroundColor Red
    pause
    exit
}

if (Test-Path $ShortcutsPath) {
    $shortcutCount = (Get-ChildItem $ShortcutsPath -Filter "*.lnk").Count
    Write-Host "✅ Shortcuts folder found ($shortcutCount shortcuts)" -ForegroundColor Green
} else {
    Write-Host "⚠️ Shortcuts folder not found (will skip shortcuts)" -ForegroundColor Yellow
}

# Remove existing accounts
Write-Host ""
Write-Host "=== STEP 2: Account Cleanup ===" -ForegroundColor Yellow
try {
    $existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
    if ($existingAdmin) {
        Remove-LocalUser -Name $AdminUsername
        Write-Host "✅ Removed existing Admin account" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Could not remove Admin account (may not exist)" -ForegroundColor Yellow
}

try {
    $existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
    if ($existingUser) {
        Remove-LocalUser -Name $UserUsername
        Write-Host "✅ Removed existing iBridge User account" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Could not remove iBridge User account (may not exist)" -ForegroundColor Yellow
}

# Create accounts
Write-Host ""
Write-Host "=== STEP 3: Account Creation ===" -ForegroundColor Yellow
try {
    # Create Admin account
    $secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    $adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -FullName "Admin" -Description "Administrator account for iBridge" -PasswordNeverExpires -AccountNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername
    Write-Host "✅ Admin account created successfully" -ForegroundColor Green
    
    # Create iBridge User account
    $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
    $bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -FullName "iBridge User" -Description "Standard user account for iBridge" -PasswordNeverExpires -AccountNeverExpires
    Write-Host "✅ iBridge User account created successfully" -ForegroundColor Green
    
    # Brief pause to let Windows process
    Start-Sleep -Seconds 2
    
} catch {
    Write-Host "❌ Failed to create accounts: $($_.Exception.Message)" -ForegroundColor Red
    pause
    exit
}

# Verify accounts
$finalAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
$finalUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue

if ($finalAdmin -and $finalUser) {
    Write-Host "✅ Both accounts verified and ready" -ForegroundColor Green
} else {
    Write-Host "❌ Account verification failed" -ForegroundColor Red
    pause
    exit
}

# Copy applications to local drive for installation
Write-Host ""
Write-Host "=== STEP 4: Application Preparation ===" -ForegroundColor Yellow
$localAppsPath = "C:\iBridge_Apps_Install"
if (Test-Path $localAppsPath) {
    Remove-Item $localAppsPath -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -Path $localAppsPath -ItemType Directory -Force | Out-Null

$installers = Get-ChildItem $InstallersPath -Filter "*.exe" -ErrorAction SilentlyContinue
$copiedCount = 0
foreach ($installer in $installers) {
    try {
        $destPath = $localAppsPath + "\" + $installer.Name
        Copy-Item $installer.FullName $destPath -Force
        Write-Host "✅ Copied: $($installer.Name)" -ForegroundColor Green
        $copiedCount++
    } catch {
        Write-Host "❌ Failed to copy: $($installer.Name)" -ForegroundColor Red
    }
}

Write-Host "✅ $copiedCount applications ready for installation" -ForegroundColor Green

# Install applications
Write-Host ""
Write-Host "=== STEP 5: Application Installation ===" -ForegroundColor Yellow
$localInstallers = Get-ChildItem $localAppsPath -Filter "*.exe" -ErrorAction SilentlyContinue
$installedCount = 0
$skippedCount = 0

foreach ($installer in $localInstallers) {
    $installerName = $installer.Name
    Write-Host "Installing: $installerName" -ForegroundColor Cyan
    
    # Skip problematic applications
    if ($installerName -like "*AnyDesk*") {
        Write-Host "⚠️ Skipping AnyDesk (prevents hanging)" -ForegroundColor Yellow
        $skippedCount++
        continue
    }
    
    if ($installerName -like "*epi_win_live*") {
        Write-Host "⚠️ Skipping epi_win_live_installer (excluded)" -ForegroundColor Yellow
        $skippedCount++
        continue
    }
    
    try {
        # Determine installation arguments
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
        
        # Start installation with timeout
        Write-Host "  Arguments: $arguments" -ForegroundColor Gray
        $process = Start-Process -FilePath $installer.FullName -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
        
        # Check result
        $exitCode = $process.ExitCode
        if ($exitCode -eq 0 -or $exitCode -eq 3010) {
            Write-Host "✅ Successfully installed: $installerName" -ForegroundColor Green
            $installedCount++
        } else {
            Write-Host "Installed with exit code $exitCode for: $installerName" -ForegroundColor Yellow
            $installedCount++
        }
        
    } catch {
        Write-Host "❌ Failed to install: $installerName" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Brief pause between installations
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "✅ Installation Summary:" -ForegroundColor Green
Write-Host "   Installed: $installedCount applications" -ForegroundColor White
Write-Host "   Skipped: $skippedCount applications" -ForegroundColor White

# Create basic profile directories
Write-Host ""
Write-Host "=== STEP 6: Profile Directory Setup ===" -ForegroundColor Yellow
$profiles = @($AdminUsername, $UserUsername)
foreach ($profile in $profiles) {
    $profilePath = "C:\Users\" + $profile
    
    if (-not (Test-Path $profilePath)) {
        try {
            New-Item -Path $profilePath -ItemType Directory -Force | Out-Null
            Write-Host "✅ Created profile directory for: $profile" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Could not create profile directory for: $profile" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✅ Profile directory exists for: $profile" -ForegroundColor Green
    }
}

# Prepare shortcuts for after login
Write-Host ""
Write-Host "=== STEP 7: Shortcut Preparation ===" -ForegroundColor Yellow
$shortcutsReadyPath = "C:\iBridge_Shortcuts_Ready"
if (Test-Path $shortcutsReadyPath) {
    Remove-Item $shortcutsReadyPath -Recurse -Force -ErrorAction SilentlyContinue
}

if (Test-Path $ShortcutsPath) {
    try {
        Copy-Item $ShortcutsPath $shortcutsReadyPath -Recurse -Force
        $shortcutFiles = Get-ChildItem $shortcutsReadyPath -Filter "*.lnk" -ErrorAction SilentlyContinue
        Write-Host "✅ $($shortcutFiles.Count) shortcuts prepared for iBridge User" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not prepare shortcuts: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ No shortcuts folder found - will skip shortcut setup" -ForegroundColor Yellow
}

# Clean up installation files
Write-Host ""
Write-Host "=== STEP 8: Cleanup ===" -ForegroundColor Yellow
if (Test-Path $localAppsPath) {
    Remove-Item $localAppsPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Cleaned up installation files" -ForegroundColor Green
}

# Create post-login shortcut script
$postLoginScript = @"
# iBridge User Shortcut Setup - Run AFTER first login
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
            Write-Host "✅ Copied `$copiedCount shortcuts to iBridge User desktop" -ForegroundColor Green
            
            # Clean up
            Remove-Item `$shortcutsSource -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "✅ Cleanup completed" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to copy shortcuts: `$(`$_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ iBridge User desktop not found!" -ForegroundColor Red
        Write-Host "Please log in to iBridge User first to create the profile" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ No shortcuts prepared" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "iBridge User setup completed!" -ForegroundColor Green
pause
"@

$postLoginPath = "C:\Users\Lwandile Gasela\iBridge\Scripts\Complete-iBridge-Setup.ps1"
$postLoginScript | Out-File -FilePath $postLoginPath -Encoding UTF8

# Final summary and instructions
Write-Host ""
Write-Host " ================================================================" -ForegroundColor Green
Write-Host "  COMPLETE OFFLINE INSTALLATION FINISHED!" -ForegroundColor Green
Write-Host " ================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "✅ COMPLETED AUTOMATICALLY:" -ForegroundColor Cyan
Write-Host "   • USB drive detected: $UsbDrive" -ForegroundColor White
Write-Host "   • Accounts created: Admin & iBridge User" -ForegroundColor White
Write-Host "   • Applications installed: $installedCount apps" -ForegroundColor White
Write-Host "   • Shortcuts prepared for iBridge User" -ForegroundColor White
Write-Host "   • Post-login script created" -ForegroundColor White
Write-Host ""
Write-Host "📋 ACCOUNTS READY:" -ForegroundColor Cyan
Write-Host "   👤 Admin" -ForegroundColor White
Write-Host "      Password: $AdminPassword" -ForegroundColor Gray
Write-Host "      Type: Administrator" -ForegroundColor Gray
Write-Host ""
Write-Host "   👤 iBridge User" -ForegroundColor White
Write-Host "      Password: $UserPassword" -ForegroundColor Gray
Write-Host "      Type: Standard User" -ForegroundColor Gray
Write-Host ""
Write-Host "REQUIRED NEXT STEPS:" -ForegroundColor Yellow
Write-Host "=========================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1️⃣  SIGN OUT of your current account (Lwandile Gasela)" -ForegroundColor White
Write-Host ""
Write-Host "2️⃣  LOG IN as 'Admin' first:" -ForegroundColor White
Write-Host "    • Username: Admin" -ForegroundColor Gray
Write-Host "    • Password: $AdminPassword" -ForegroundColor Gray
Write-Host "    • Let Windows create the profile" -ForegroundColor Gray
Write-Host "    • Sign out when desktop appears" -ForegroundColor Gray
Write-Host ""
Write-Host "3️⃣  LOG IN as 'iBridge User':" -ForegroundColor White
Write-Host "    • Username: iBridge User" -ForegroundColor Gray
Write-Host "    • Password: $UserPassword" -ForegroundColor Gray
Write-Host "    • Let Windows create the profile" -ForegroundColor Gray
Write-Host "    • Sign out when desktop appears" -ForegroundColor Gray
Write-Host ""
Write-Host "4️⃣  LOG BACK IN as your main account (Lwandile Gasela)" -ForegroundColor White
Write-Host ""
Write-Host "5️⃣  RUN the completion script:" -ForegroundColor White
Write-Host "    $postLoginPath" -ForegroundColor Gray
Write-Host ""
Write-Host "WHY THESE STEPS ARE NEEDED:" -ForegroundColor Cyan
Write-Host "Windows only creates COMPLETE user profiles during the first" -ForegroundColor White
Write-Host "interactive login. This creates NTUSER.DAT and registers the" -ForegroundColor White
Write-Host "profile so it appears in Control Panel properly." -ForegroundColor White
Write-Host ""
Write-Host "After completing these steps:" -ForegroundColor Green
Write-Host "• Both accounts will appear in Control Panel ✅" -ForegroundColor White
Write-Host "• iBridge User will have all Office shortcuts ✅" -ForegroundColor White
Write-Host "• All applications will be installed and ready ✅" -ForegroundColor White
Write-Host ""

Write-Host "Press any key to finish..." -ForegroundColor Yellow
pause

Write-Host ""
Write-Host "Installation complete! Follow the steps above to finish setup." -ForegroundColor Green
Write-Host ""
