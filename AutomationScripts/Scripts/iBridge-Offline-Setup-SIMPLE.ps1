# iBridge Offline Setup Script - Simple Working Version
# Basic offline installation without syntax errors

param()

Write-Host "iBridge Offline Setup Starting..." -ForegroundColor Green

# Account Configuration
$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

# Auto-detect USB drive
$USBDrive = $null
$PossibleDrives = @("D:", "E:", "F:", "G:", "H:")

foreach ($drive in $PossibleDrives) {
    if (Test-Path "$drive\iBridge Set Up" -ErrorAction SilentlyContinue) {
        $USBDrive = $drive
        break
    }
}

if (-not $USBDrive) {
    Write-Host "ERROR: iBridge USB drive not found." -ForegroundColor Red
    pause
    exit 1
}

Write-Host "Found iBridge USB on drive: $USBDrive" -ForegroundColor Green

# Check admin rights
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges." -ForegroundColor Red
    pause
    exit 1
}

# Setup paths
$iBridgeBase = "C:\iBridge_Setup"
$InstallersPath = "$iBridgeBase\Installers"
$LogsPath = "$iBridgeBase\Logs"

# Create directories
Write-Host "Creating directories..." -ForegroundColor Cyan
$directories = @($iBridgeBase, $InstallersPath, $LogsPath)
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "Created: $dir" -ForegroundColor Green
    }
}

# Application sources
$ApplicationSources = @(
    "$USBDrive\TeamViewer_Setup_x64.exe",
    "$USBDrive\24.2.2000.exe",
    "$USBDrive\AnyDesk.exe",
    "$USBDrive\GlassWireSetup.exe",
    "$USBDrive\PBIDesktopSetup_x64.exe"
)

# Copy files
Write-Host "Copying application files..." -ForegroundColor Cyan
foreach ($source in $ApplicationSources) {
    if (Test-Path $source) {
        $filename = Split-Path $source -Leaf
        $destination = Join-Path $InstallersPath $filename
        try {
            Copy-Item -Path $source -Destination $destination -Force
            Write-Host "Copied: $filename" -ForegroundColor Green
        } catch {
            Write-Host "Failed to copy: $filename" -ForegroundColor Red
        }
    } else {
        Write-Host "Not found: $source" -ForegroundColor Yellow
    }
}

# Remove existing users
Write-Host "Removing existing accounts..." -ForegroundColor Cyan
try {
    $adminUser = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
    if ($adminUser) {
        Remove-LocalUser -Name $AdminUsername
        Write-Host "Removed existing Admin account" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not remove Admin account" -ForegroundColor Yellow
}

try {
    $bridgeUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
    if ($bridgeUser) {
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
    Write-Host "Failed to create accounts: $($_.Exception.Message)" -ForegroundColor Red
}

# Create profiles
Write-Host "Creating user profiles..." -ForegroundColor Cyan
$profiles = @($AdminUsername, $UserUsername)
foreach ($profile in $profiles) {
    $profilePath = "C:\Users\$profile"
    $desktopPath = "$profilePath\Desktop"
    
    if (-not (Test-Path $profilePath)) {
        New-Item -Path $profilePath -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path $desktopPath)) {
        New-Item -Path $desktopPath -ItemType Directory -Force | Out-Null
    }
    Write-Host "Profile created for: $profile" -ForegroundColor Green
}

# Install applications
Write-Host "Installing applications..." -ForegroundColor Cyan
$installers = Get-ChildItem $InstallersPath -Filter "*.exe" -ErrorAction SilentlyContinue

foreach ($installer in $installers) {
    Write-Host "Installing: $($installer.Name)" -ForegroundColor Yellow
    
    try {
        $arguments = @("/S", "/silent", "/quiet")
        
        # Special handling for specific applications
        if ($installer.Name -like "*AnyDesk*") {
            $arguments = @("--install", "--start-with-win", "--silent")
        } elseif ($installer.Name -like "*TeamViewer*") {
            $arguments = @("/S", "/norestart")
        } elseif ($installer.Name -like "*GlassWire*") {
            $arguments = @("/S")
        } elseif ($installer.Name -like "*PBIDesktop*") {
            $arguments = @("-quiet", "ACCEPT_EULA=1")
        }
        
        $process = Start-Process -FilePath $installer.FullName -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Installed successfully: $($installer.Name)" -ForegroundColor Green
        } else {
            Write-Host "Installation completed with exit code $($process.ExitCode): $($installer.Name)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to install $($installer.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Copy iBridge User shortcuts
Write-Host "Copying iBridge User shortcuts..." -ForegroundColor Cyan
$iBridgeDesktop = "C:\Users\$UserUsername\Desktop"
$iBridgeUserShortcuts = @(
    "$USBDrive\IT STUFF\Desktop-Mtn\Word.lnk",
    "$USBDrive\IT STUFF\Desktop-Mtn\Excel.lnk",
    "$USBDrive\IT STUFF\Desktop-Mtn\Microsoft 365 Online.url",
    "$USBDrive\IT STUFF\Desktop-Mtn\New Citrix Gateway.url",
    "$USBDrive\IT STUFF\Desktop-Mtn\Outlook.lnk",
    "$USBDrive\IT STUFF\Desktop-Mtn\PowerPoint.lnk"
)

if (-not (Test-Path $iBridgeDesktop)) {
    New-Item -Path $iBridgeDesktop -ItemType Directory -Force | Out-Null
}

foreach ($shortcut in $iBridgeUserShortcuts) {
    if (Test-Path $shortcut) {
        $filename = Split-Path $shortcut -Leaf
        $destination = Join-Path $iBridgeDesktop $filename
        try {
            Copy-Item -Path $shortcut -Destination $destination -Force
            Write-Host "Copied shortcut: $filename" -ForegroundColor Green
        } catch {
            Write-Host "Failed to copy shortcut: $filename" -ForegroundColor Red
        }
    }
}

# Install MS Teams
$teamsInstaller = "$USBDrive\IT STUFF\Desktop-Mtn\MSTeamsSetup.exe"
if (Test-Path $teamsInstaller) {
    Write-Host "Installing MS Teams..." -ForegroundColor Yellow
    try {
        $process = Start-Process -FilePath $teamsInstaller -ArgumentList "/S" -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-Host "MS Teams installed successfully" -ForegroundColor Green
        } else {
            Write-Host "MS Teams installation completed with exit code: $($process.ExitCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to install MS Teams: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "Setup Completed Successfully!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "Admin account: $AdminUsername (Password: $AdminPassword)" -ForegroundColor Cyan
Write-Host "iBridge User account: $UserUsername (Password: $UserPassword)" -ForegroundColor Cyan
Write-Host "USB Drive: $USBDrive" -ForegroundColor Cyan
Write-Host ""

pause
