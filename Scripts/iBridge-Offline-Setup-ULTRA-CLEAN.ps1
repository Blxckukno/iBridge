# iBridge Offline Setup - PowerShell 5.1 Compatible
# Syntax-clean version for USB deployment

$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User" 
$UserPassword = "Abc654321!"

Write-Host ""
Write-Host " ========================================" -ForegroundColor Cyan
Write-Host "  iBridge Offline Setup v3.1" -ForegroundColor Cyan
Write-Host " ========================================" -ForegroundColor Cyan
Write-Host ""

# Auto-detect USB drive
Write-Host "Auto-detecting iBridge USB drive..." -ForegroundColor Yellow
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
    Write-Host "Could not find iBridge USB drive!" -ForegroundColor Red
    pause
    exit
}

$UsbPath = $UsbDrive + "\iBridge Set Up"
$InstallersPath = $UsbPath + "\Applications"

Write-Host "Using USB path: $UsbPath" -ForegroundColor Green

# Remove existing accounts
Write-Host "Removing existing accounts..." -ForegroundColor Cyan
try {
    $existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
    if ($existingAdmin) {
        Remove-LocalUser -Name $AdminUsername
        Write-Host "Removed existing Admin account" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not remove Admin account" -ForegroundColor Yellow
}

try {
    $existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
    if ($existingUser) {
        Remove-LocalUser -Name $UserUsername
        Write-Host "Removed existing iBridge User account" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not remove iBridge User account" -ForegroundColor Yellow
}

# Create accounts
Write-Host "Creating user accounts..." -ForegroundColor Cyan
try {
    $secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    $adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -FullName "Admin" -Description "Administrator account" -PasswordNeverExpires -AccountNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername
    Write-Host "Admin account created successfully" -ForegroundColor Green
    
    $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
    $bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -FullName "iBridge User" -Description "Standard user account" -PasswordNeverExpires -AccountNeverExpires
    Write-Host "iBridge User account created successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to create accounts" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Create profiles
Write-Host "Creating user profiles..." -ForegroundColor Cyan
$profiles = @($AdminUsername, $UserUsername)
foreach ($profile in $profiles) {
    $profilePath = "C:\Users\" + $profile
    $desktopPath = $profilePath + "\Desktop"
    
    if (-not (Test-Path $profilePath)) {
        New-Item -Path $profilePath -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path $desktopPath)) {
        New-Item -Path $desktopPath -ItemType Directory -Force | Out-Null
    }
    Write-Host "Profile created for: $profile" -ForegroundColor Green
}

# Copy applications
Write-Host "Copying applications..." -ForegroundColor Cyan
$localAppsPath = "C:\iBridge_Apps"
if (-not (Test-Path $localAppsPath)) {
    New-Item -Path $localAppsPath -ItemType Directory -Force | Out-Null
}

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
Write-Host "Installing applications..." -ForegroundColor Cyan
$localInstallers = Get-ChildItem $localAppsPath -Filter "*.exe" -ErrorAction SilentlyContinue

foreach ($installer in $localInstallers) {
    $installerName = $installer.Name
    Write-Host "Installing: $installerName" -ForegroundColor Yellow
    
    # Skip AnyDesk to prevent hanging
    if ($installerName -like "*AnyDesk*") {
        Write-Host "Skipping AnyDesk (manual installation recommended)" -ForegroundColor Yellow
        continue
    }
    
    try {
        $arguments = "/S"
        
        if ($installerName -like "*TeamViewer*") {
            $arguments = "/S"
        } elseif ($installerName -like "*GlassWire*") {
            $arguments = "/S"
        } elseif ($installerName -like "*PBI*") {
            $arguments = "/quiet /norestart"
        } elseif ($installerName -like "*PowerBI*") {
            $arguments = "/quiet /norestart"
        }
        
        $process = Start-Process -FilePath $installer.FullName -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
        $exitCode = $process.ExitCode
        
        if ($exitCode -eq 0) {
            Write-Host "Successfully installed: $installerName" -ForegroundColor Green
        } else {
            Write-Host "Installation completed with exit code $exitCode for: $installerName" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to install: $installerName" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Copy shortcuts to iBridge User desktop
Write-Host "Setting up iBridge User shortcuts..." -ForegroundColor Cyan
$shortcutsSource = $UsbPath + "\Desktop-Mtn"
$iBridgeDesktop = "C:\Users\" + $UserUsername + "\Desktop"

if (Test-Path $shortcutsSource) {
    if (Test-Path $iBridgeDesktop) {
        try {
            $shortcuts = Get-ChildItem $shortcutsSource -Filter "*.lnk" -ErrorAction SilentlyContinue
            foreach ($shortcut in $shortcuts) {
                $destPath = $iBridgeDesktop + "\" + $shortcut.Name
                Copy-Item $shortcut.FullName $destPath -Force
                Write-Host "Copied shortcut: " + $shortcut.Name -ForegroundColor Green
            }
        } catch {
            Write-Host "Failed to copy shortcuts" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    } else {
        Write-Host "iBridge User desktop not found - shortcuts not copied" -ForegroundColor Yellow
    }
} else {
    Write-Host "Shortcuts folder not found" -ForegroundColor Yellow
}

# Clean up
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
Write-Host "IMPORTANT: Log in to each account once to complete profile setup!" -ForegroundColor Yellow
Write-Host ""

pause
