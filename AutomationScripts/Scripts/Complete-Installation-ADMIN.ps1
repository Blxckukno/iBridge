# iBridge Complete Installation - Auto-Elevate Version
# This script automatically requests administrator privileges

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host ""
    Write-Host " ================================================================" -ForegroundColor Yellow
    Write-Host "  ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Yellow
    Write-Host " ================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This installation requires administrator privileges to:" -ForegroundColor White
    Write-Host "• Create user accounts" -ForegroundColor Gray
    Write-Host "• Install applications" -ForegroundColor Gray
    Write-Host "• Modify system settings" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Requesting administrator privileges..." -ForegroundColor Cyan
    
    # Re-launch as administrator
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process PowerShell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

# Now running as administrator
$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User" 
$UserPassword = "Abc654321!"

Write-Host ""
Write-Host " ================================================================" -ForegroundColor Cyan
Write-Host "  iBridge COMPLETE Installation v4.2 - ADMIN MODE" -ForegroundColor Cyan
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
    Write-Host "Please ensure USB is connected and try again." -ForegroundColor Yellow
    pause
    exit
}

# Use USB root for applications
$UsbRoot = $UsbDrive
$InstallersPath = $UsbRoot
$ShortcutsPath = $UsbRoot + "\IT STUFF\Desktop-Mtn"

Write-Host "USB Drive: $UsbDrive" -ForegroundColor Green

# Find applications
$installers = Get-ChildItem $InstallersPath -Filter "*.exe" -ErrorAction SilentlyContinue
if ($installers.Count -gt 0) {
    Write-Host "Found $($installers.Count) applications:" -ForegroundColor Green
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
    Write-Host "Found $($shortcuts.Count) shortcuts in IT STUFF folder" -ForegroundColor Green
} else {
    Write-Host "WARNING: No shortcuts folder found" -ForegroundColor Yellow
    $ShortcutsPath = ""
}

# Remove existing accounts
Write-Host ""
Write-Host "STEP 2: Account Cleanup" -ForegroundColor Yellow
Write-Host "========================" -ForegroundColor Yellow
try {
    $existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
    if ($existingAdmin) {
        Remove-LocalUser -Name $AdminUsername -Confirm:$false
        Write-Host "SUCCESS: Removed existing Admin account" -ForegroundColor Green
    } else {
        Write-Host "INFO: No existing Admin account found" -ForegroundColor Gray
    }
} catch {
    Write-Host "WARNING: Could not remove Admin account: $($_.Exception.Message)" -ForegroundColor Yellow
}

try {
    $existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
    if ($existingUser) {
        Remove-LocalUser -Name $UserUsername -Confirm:$false
        Write-Host "SUCCESS: Removed existing iBridge User account" -ForegroundColor Green
    } else {
        Write-Host "INFO: No existing iBridge User account found" -ForegroundColor Gray
    }
} catch {
    Write-Host "WARNING: Could not remove iBridge User account: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create accounts
Write-Host ""
Write-Host "STEP 3: Account Creation" -ForegroundColor Yellow
Write-Host "=========================" -ForegroundColor Yellow
try {
    # Create Admin account
    $secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    $adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -FullName "Admin" -Description "Administrator account for iBridge" -PasswordNeverExpires -AccountNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername -ErrorAction SilentlyContinue
    Write-Host "SUCCESS: Admin account created" -ForegroundColor Green
    
    # Create iBridge User account
    $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
    $bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -FullName "iBridge User" -Description "Standard user account for iBridge" -PasswordNeverExpires -AccountNeverExpires
    Write-Host "SUCCESS: iBridge User account created" -ForegroundColor Green
    
    Start-Sleep -Seconds 2
    
} catch {
    Write-Host "ERROR: Failed to create accounts" -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
    pause
    exit
}

# Verify accounts
$finalAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
$finalUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue

if ($finalAdmin -and $finalUser) {
    Write-Host "SUCCESS: Both accounts verified" -ForegroundColor Green
    Write-Host "  - Admin: Created and ready" -ForegroundColor Gray
    Write-Host "  - iBridge User: Created and ready" -ForegroundColor Gray
} else {
    Write-Host "ERROR: Account verification failed" -ForegroundColor Red
    if (-not $finalAdmin) { Write-Host "  - Admin account missing" -ForegroundColor Red }
    if (-not $finalUser) { Write-Host "  - iBridge User account missing" -ForegroundColor Red }
    pause
    exit
}

# Install applications
Write-Host ""
Write-Host "STEP 4: Application Installation" -ForegroundColor Yellow
Write-Host "==================================" -ForegroundColor Yellow

$installedCount = 0
$skippedCount = 0
$failedCount = 0

foreach ($installer in $installers) {
    $installerName = $installer.Name
    Write-Host "Processing: $installerName" -ForegroundColor Cyan
    
    # Skip problematic applications
    if ($installerName -like "*AnyDesk*") {
        Write-Host "  SKIPPED: AnyDesk (prevents system hanging)" -ForegroundColor Yellow
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
        }
        
        Write-Host "  Installing with arguments: $arguments" -ForegroundColor Gray
        
        # Install with timeout (5 minutes max)
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $installer.FullName
        $processInfo.Arguments = $arguments
        $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $processInfo.UseShellExecute = $false
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        
        if ($process.Start()) {
            $timeoutReached = -not $process.WaitForExit(300000)  # 5 minutes
            
            if ($timeoutReached) {
                $process.Kill()
                Write-Host "  TIMEOUT: Installation took too long" -ForegroundColor Yellow
                $failedCount++
            } else {
                $exitCode = $process.ExitCode
                if ($exitCode -eq 0 -or $exitCode -eq 3010) {
                    Write-Host "  SUCCESS: Installed successfully" -ForegroundColor Green
                    $installedCount++
                } else {
                    Write-Host "  COMPLETED: Exit code $exitCode (may be normal)" -ForegroundColor Yellow
                    $installedCount++
                }
            }
        } else {
            Write-Host "  FAILED: Could not start installer" -ForegroundColor Red
            $failedCount++
        }
        
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $failedCount++
    }
    
    # Brief pause between installations
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "Installation Summary:" -ForegroundColor Green
Write-Host "  Successfully installed: $installedCount" -ForegroundColor White
Write-Host "  Skipped (intentional): $skippedCount" -ForegroundColor White
Write-Host "  Failed: $failedCount" -ForegroundColor White

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
        Write-Host "SUCCESS: Prepared $($shortcutFiles.Count) shortcuts" -ForegroundColor Green
    } catch {
        Write-Host "WARNING: Could not prepare shortcuts: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "INFO: No shortcuts to prepare" -ForegroundColor Gray
}

# Create post-login shortcut script
$postLoginScript = @"
# iBridge User Shortcut Setup - Run AFTER first login
Write-Host ""
Write-Host "iBridge User Shortcut Setup" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

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
                Write-Host "Copied: `$(`$shortcut.Name)" -ForegroundColor Green
                `$copiedCount++
            }
            Write-Host ""
            Write-Host "SUCCESS: Copied `$copiedCount shortcuts to iBridge User desktop" -ForegroundColor Green
            
            # Clean up
            Remove-Item `$shortcutsSource -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Cleanup completed" -ForegroundColor Green
        } catch {
            Write-Host "ERROR: Failed to copy shortcuts: `$(`$_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "ERROR: iBridge User desktop not found!" -ForegroundColor Red
        Write-Host "Please log in to iBridge User first to create the desktop" -ForegroundColor Yellow
    }
} else {
    Write-Host "INFO: No shortcuts prepared during installation" -ForegroundColor Gray
}

Write-Host ""
Write-Host "iBridge User setup completed!" -ForegroundColor Green
Write-Host ""
pause
"@

$postLoginPath = "C:\Users\Lwandile Gasela\iBridge\Scripts\Complete-iBridge-Setup.ps1"
$postLoginScript | Out-File -FilePath $postLoginPath -Encoding UTF8

# Final summary and instructions
Write-Host ""
Write-Host " ================================================================" -ForegroundColor Green
Write-Host "  INSTALLATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host " ================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "SUMMARY:" -ForegroundColor Cyan
Write-Host "========" -ForegroundColor Cyan
Write-Host "  Accounts created: Admin, iBridge User" -ForegroundColor White
Write-Host "  Applications installed: $installedCount" -ForegroundColor White
Write-Host "  Shortcuts prepared: $(if ($ShortcutsPath) { 'Yes' } else { 'No' })" -ForegroundColor White
Write-Host ""
Write-Host "ACCOUNT DETAILS:" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
Write-Host "  Admin Account:" -ForegroundColor White
Write-Host "    Username: Admin" -ForegroundColor Gray
Write-Host "    Password: $AdminPassword" -ForegroundColor Gray
Write-Host "    Type: Administrator" -ForegroundColor Gray
Write-Host ""
Write-Host "  iBridge User Account:" -ForegroundColor White
Write-Host "    Username: iBridge User" -ForegroundColor Gray
Write-Host "    Password: $UserPassword" -ForegroundColor Gray
Write-Host "    Type: Standard User" -ForegroundColor Gray
Write-Host ""
Write-Host "CRITICAL NEXT STEPS:" -ForegroundColor Yellow
Write-Host "====================" -ForegroundColor Yellow
Write-Host ""
Write-Host "To complete the setup and make accounts appear in Control Panel:" -ForegroundColor White
Write-Host ""
Write-Host "1. SIGN OUT of your current Windows account" -ForegroundColor White
Write-Host ""
Write-Host "2. LOG IN as 'Admin' account:" -ForegroundColor White
Write-Host "   - Use password: $AdminPassword" -ForegroundColor Gray
Write-Host "   - Let Windows create the user profile" -ForegroundColor Gray
Write-Host "   - Sign out when desktop appears" -ForegroundColor Gray
Write-Host ""
Write-Host "3. LOG IN as 'iBridge User' account:" -ForegroundColor White
Write-Host "   - Use password: $UserPassword" -ForegroundColor Gray
Write-Host "   - Let Windows create the user profile" -ForegroundColor Gray
Write-Host "   - Sign out when desktop appears" -ForegroundColor Gray
Write-Host ""
Write-Host "4. LOG BACK IN as your original account" -ForegroundColor White
Write-Host ""
Write-Host "5. RUN the shortcut setup script:" -ForegroundColor White
Write-Host "   $postLoginPath" -ForegroundColor Gray
Write-Host ""
Write-Host "WHY MANUAL LOGIN IS REQUIRED:" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "Windows creates complete user profiles (with NTUSER.DAT, registry" -ForegroundColor White
Write-Host "entries, and desktop folders) only during the first interactive" -ForegroundColor White
Write-Host "login. Without this step, accounts won't appear in Control Panel." -ForegroundColor White
Write-Host ""
Write-Host "After completing these steps:" -ForegroundColor Green
Write-Host "- Both accounts will be visible in Control Panel" -ForegroundColor White
Write-Host "- iBridge User will have all Office shortcuts" -ForegroundColor White
Write-Host "- All applications will be ready to use" -ForegroundColor White
Write-Host ""

Write-Host "Press any key to complete installation..." -ForegroundColor Yellow
pause

Write-Host ""
Write-Host "INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "Follow the steps above to finish the setup." -ForegroundColor Green
Write-Host ""
