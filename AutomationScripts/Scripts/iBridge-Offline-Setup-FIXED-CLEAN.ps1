# iBridge Offline Setup v3.1 - PowerShell 5.1 Compatible
# Clean version without syntax errors

param(
    [string]$UsbDrive = ""
)

# Account credentials
$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

Write-Host ""
Write-Host " ========================================" -ForegroundColor Cyan
Write-Host "  iBridge Offline Setup v3.1 - FIXED" -ForegroundColor Cyan  
Write-Host " ========================================" -ForegroundColor Cyan
Write-Host ""

# Auto-detect USB drive if not specified
if (-not $UsbDrive) {
    Write-Host "Auto-detecting iBridge USB drive..." -ForegroundColor Yellow
    $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 -or $_.DriveType -eq 3 }
    
    foreach ($drive in $drives) {
        $testPath = "$($drive.DeviceID)\iBridge Set Up"
        if (Test-Path $testPath) {
            $UsbDrive = $drive.DeviceID
            Write-Host "Found iBridge USB on drive: $UsbDrive" -ForegroundColor Green
            break
        }
    }
    
    if (-not $UsbDrive) {
        Write-Host "Could not find iBridge USB drive!" -ForegroundColor Red
        Write-Host "Please ensure USB is connected and contains 'iBridge Set Up' folder" -ForegroundColor Yellow
        pause
        exit
    }
}

$UsbPath = "$UsbDrive\iBridge Set Up"
$InstallersPath = "$UsbPath\Applications"

# Verify USB contents
if (-not (Test-Path $InstallersPath)) {
    Write-Host "Applications folder not found at: $InstallersPath" -ForegroundColor Red
    pause
    exit
}

Write-Host "Using USB path: $UsbPath" -ForegroundColor Green

# Remove existing accounts if they exist
Write-Host "Checking for existing accounts..." -ForegroundColor Cyan
try {
    if (Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue) {
        Remove-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
        Write-Host "Removed existing Admin account" -ForegroundColor Green
    }
    if (Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue) {
        Remove-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
        Write-Host "Removed existing iBridge User account" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not remove existing accounts" -ForegroundColor Yellow
}

# Create user accounts
Write-Host "Creating user accounts..." -ForegroundColor Cyan
try {
    # Create Admin account
    $secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    $adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -FullName "Administrator" -Description "Administrator account for iBridge" -PasswordNeverExpires -AccountNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername -ErrorAction SilentlyContinue
    Write-Host "Admin account created successfully" -ForegroundColor Green
    
    # Create iBridge User account  
    $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
    $bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -FullName "iBridge User" -Description "Standard user account for iBridge" -PasswordNeverExpires -AccountNeverExpires
    Write-Host "iBridge User account created successfully" -ForegroundColor Green
    
    # Wait a moment for accounts to be fully created
    Start-Sleep -Seconds 3
    
} catch {
    Write-Host "Failed to create accounts: $($_.Exception.Message)" -ForegroundColor Red
    pause
    exit
}

# Create basic profile directories
Write-Host "Creating basic profile structure..." -ForegroundColor Cyan
$profiles = @($AdminUsername, $UserUsername)
foreach ($profile in $profiles) {
    $profilePath = "C:\Users\$profile"
    
    if (-not (Test-Path $profilePath)) {
        try {
            New-Item -Path $profilePath -ItemType Directory -Force | Out-Null
            Write-Host "Created profile directory for: $profile" -ForegroundColor Green
        } catch {
            Write-Host "Could not create profile directory for: $profile" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Profile directory exists for: $profile" -ForegroundColor Green
    }
}

# Copy applications to local drive
Write-Host "Copying application files..." -ForegroundColor Cyan
$localAppsPath = "C:\iBridge_Apps"
if (-not (Test-Path $localAppsPath)) {
    New-Item -Path $localAppsPath -ItemType Directory -Force | Out-Null
}

$installers = Get-ChildItem $InstallersPath -Filter "*.exe" -ErrorAction SilentlyContinue
foreach ($installer in $installers) {
    $sourcePath = $installer.FullName
    $destPath = "$localAppsPath\$($installer.Name)"
    
    try {
        Copy-Item $sourcePath $destPath -Force
        Write-Host "Copied: $($installer.Name)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to copy: $($installer.Name)" -ForegroundColor Red
    }
}

# Install applications
Write-Host "Installing applications..." -ForegroundColor Cyan
$localInstallers = Get-ChildItem $localAppsPath -Filter "*.exe" -ErrorAction SilentlyContinue

foreach ($installer in $localInstallers) {
    Write-Host "Installing: $($installer.Name)" -ForegroundColor Yellow
    
    try {
        $arguments = "/S"
        
        # Application-specific parameters
        if ($installer.Name -like "*AnyDesk*") {
            # Skip AnyDesk to prevent hanging
            Write-Host "Skipping AnyDesk (manual installation recommended)" -ForegroundColor Yellow
            continue
        } elseif ($installer.Name -like "*TeamViewer*") {
            $arguments = "/S"
        } elseif ($installer.Name -like "*GlassWire*") {
            $arguments = "/S"
        } elseif ($installer.Name -like "*PBI*" -or $installer.Name -like "*PowerBI*") {
            $arguments = "/quiet /norestart"
        } elseif ($installer.Name -like "*24.2.2000*") {
            $arguments = "/S"
        } elseif ($installer.Name -like "*Tools*") {
            $arguments = "/S"
        }
        
        # Start installation with timeout protection
        $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processStartInfo.FileName = $installer.FullName
        $processStartInfo.Arguments = $arguments
        $processStartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $processStartInfo.UseShellExecute = $false
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processStartInfo
        
        if ($process.Start()) {
            # Wait for process with 5 minute timeout
            $timeoutReached = -not $process.WaitForExit(300000)
            
            if ($timeoutReached) {
                $process.Kill()
                Write-Host "Installation timed out (5 minutes): $($installer.Name)" -ForegroundColor Yellow
            } else {
                $exitCode = $process.ExitCode
                if ($exitCode -eq 0) {
                    Write-Host "Successfully installed: $($installer.Name)" -ForegroundColor Green
                } else {
                    Write-Host "Installation completed with exit code $exitCode for: $($installer.Name)" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "Failed to start installer: $($installer.Name)" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "Failed to install: $($installer.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Clean up temporary files
Write-Host "Cleaning up..." -ForegroundColor Cyan
if (Test-Path $localAppsPath) {
    Remove-Item $localAppsPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned up temporary files" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "        iBridge Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Accounts created:" -ForegroundColor Cyan
Write-Host "- Admin (Password: $AdminPassword)" -ForegroundColor White
Write-Host "- iBridge User (Password: $UserPassword)" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Sign out of current account" -ForegroundColor White
Write-Host "2. Log in as 'iBridge User' (password: $UserPassword)" -ForegroundColor White
Write-Host "3. This will complete the profile creation" -ForegroundColor White
Write-Host "4. Sign back in to your main account" -ForegroundColor White
Write-Host "5. Run the shortcut setup script" -ForegroundColor White
Write-Host ""
Write-Host "Profile Setup Note:" -ForegroundColor Cyan
Write-Host "Windows requires the first manual login to create the full" -ForegroundColor White
Write-Host "user profile (Desktop, Documents, AppData folders, etc.)" -ForegroundColor White
Write-Host ""

# Create a shortcut setup script for after login
$shortcutScript = @"
# Run this AFTER logging in to iBridge User once
Write-Host "Setting up iBridge User shortcuts..." -ForegroundColor Cyan

`$shortcutsSource = "$UsbPath\Desktop-Mtn"
`$iBridgeDesktop = "C:\Users\$UserUsername\Desktop"

if (Test-Path `$shortcutsSource) {
    if (Test-Path `$iBridgeDesktop) {
        try {
            `$shortcuts = Get-ChildItem `$shortcutsSource -Filter "*.lnk" -ErrorAction SilentlyContinue
            foreach (`$shortcut in `$shortcuts) {
                `$destPath = "`$iBridgeDesktop\`$(`$shortcut.Name)"
                Copy-Item `$shortcut.FullName `$destPath -Force
                Write-Host "Copied shortcut: `$(`$shortcut.Name)" -ForegroundColor Green
            }
            Write-Host "All shortcuts copied successfully!" -ForegroundColor Green
        } catch {
            Write-Host "Failed to copy shortcuts: `$(`$_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "iBridge User desktop not found - please log in to iBridge User first" -ForegroundColor Yellow
    }
} else {
    Write-Host "Shortcuts folder not found: `$shortcutsSource" -ForegroundColor Yellow
}

pause
"@

$shortcutScriptPath = "C:\Users\Lwandile Gasela\iBridge\Scripts\Setup-iBridge-Shortcuts.ps1"
$shortcutScript | Out-File -FilePath $shortcutScriptPath -Encoding UTF8

Write-Host "Created shortcut setup script: $shortcutScriptPath" -ForegroundColor Green
Write-Host ""

pause
