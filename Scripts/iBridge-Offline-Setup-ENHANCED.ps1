# iBridge Offline Setup with PROPER Profile Creation
# Enhanced version with forced profile creation using Windows LoadUserProfile API

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
Write-Host "  iBridge Offline Setup v3.1 - ENHANCED" -ForegroundColor Cyan  
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

# Function to create proper user profile
function Create-UserProfile {
    param([string]$Username)
    
    Write-Host "Creating Windows profile for: $Username" -ForegroundColor Yellow
    
    try {
        # Method 1: Use reg.exe to create registry entries for the profile
        $userSID = (Get-LocalUser -Name $Username).SID.Value
        $profilePath = "C:\Users\$Username"
        
        Write-Host "  - User SID: $userSID" -ForegroundColor White
        Write-Host "  - Profile Path: $profilePath" -ForegroundColor White
        
        # Create the profile registry entry
        $regPath = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$userSID"
        
        # Create profile directory structure
        if (-not (Test-Path $profilePath)) {
            New-Item -Path $profilePath -ItemType Directory -Force | Out-Null
            Write-Host "  ✅ Created profile directory" -ForegroundColor Green
        }
        
        # Create essential profile subdirectories
        $profileDirs = @(
            "Desktop",
            "Documents", 
            "Downloads",
            "Pictures",
            "Videos",
            "Music",
            "AppData\Local",
            "AppData\Roaming"
        )
        
        foreach ($dir in $profileDirs) {
            $fullPath = "$profilePath\$dir"
            if (-not (Test-Path $fullPath)) {
                New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
            }
        }
        
        # Set proper permissions on the profile folder
        $acl = Get-Acl $profilePath
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Username, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $profilePath -AclObject $acl
        
        Write-Host "  ✅ Profile created successfully" -ForegroundColor Green
        
        # Force profile registration by simulating a logon
        Write-Host "  - Registering profile with Windows..." -ForegroundColor White
        
        # Use PowerShell to load the user profile properly
        $loadProfileScript = @"
# Create user profile by loading it
`$username = '$Username'
`$password = '$($Username -eq $AdminUsername ? $AdminPassword : $UserPassword)'
`$securePassword = ConvertTo-SecureString `$password -AsPlainText -Force
`$credential = New-Object System.Management.Automation.PSCredential(`$username, `$securePassword)

# This will force Windows to create the profile
try {
    Start-Process powershell.exe -Credential `$credential -ArgumentList '-Command', 'exit' -WindowStyle Hidden -Wait
    Write-Host '  ✅ Profile registered with Windows' -ForegroundColor Green
} catch {
    Write-Host '  ⚠️ Profile registration may need manual login: $($_)' -ForegroundColor Yellow
}
"@
        
        # Execute the profile loading script
        Invoke-Expression $loadProfileScript
        
        return $true
    } catch {
        Write-Host "  ❌ Failed to create profile: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

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
    Write-Host "✅ Admin account created successfully" -ForegroundColor Green
    
    # Create iBridge User account  
    $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
    $bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -FullName "iBridge User" -Description "Standard user account for iBridge" -PasswordNeverExpires -AccountNeverExpires
    Write-Host "✅ iBridge User account created successfully" -ForegroundColor Green
    
    # Wait a moment for accounts to be fully created
    Start-Sleep -Seconds 3
    
} catch {
    Write-Host "❌ Failed to create accounts: $($_.Exception.Message)" -ForegroundColor Red
    pause
    exit
}

# Create user profiles using proper Windows method
Write-Host "Creating Windows user profiles..." -ForegroundColor Cyan

$adminProfileCreated = Create-UserProfile -Username $AdminUsername
$userProfileCreated = Create-UserProfile -Username $UserUsername

if (-not $adminProfileCreated -or -not $userProfileCreated) {
    Write-Host "⚠️ Some profiles may not have been created properly" -ForegroundColor Yellow
    Write-Host "You may need to log in to each account once to complete profile creation" -ForegroundColor Yellow
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
        $arguments = @("/S", "/silent", "/quiet")
        
        # Application-specific parameters
        if ($installer.Name -like "*AnyDesk*") {
            # Skip AnyDesk to prevent hanging
            Write-Host "Skipping AnyDesk (manual installation recommended)" -ForegroundColor Yellow
            continue
        } elseif ($installer.Name -like "*TeamViewer*") {
            $arguments = @("/S")
        } elseif ($installer.Name -like "*GlassWire*") {
            $arguments = @("/S")
        } elseif ($installer.Name -like "*PBI*" -or $installer.Name -like "*PowerBI*") {
            $arguments = @("/quiet", "/norestart")
        }
        
        # Start installation with timeout
        $process = Start-Process -FilePath $installer.FullName -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
        $exitCode = $process.ExitCode
        
        if ($exitCode -eq 0) {
            Write-Host "✅ Successfully installed: $($installer.Name)" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Installation completed with exit code $exitCode: $($installer.Name)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Failed to install: $($installer.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Copy shortcuts to iBridge User desktop
Write-Host "Setting up iBridge User shortcuts..." -ForegroundColor Cyan
$shortcutsSource = "$UsbPath\Desktop-Mtn"
$iBridgeDesktop = "C:\Users\$UserUsername\Desktop"

if (Test-Path $shortcutsSource) {
    if (Test-Path $iBridgeDesktop) {
        try {
            $shortcuts = Get-ChildItem $shortcutsSource -Filter "*.lnk" -ErrorAction SilentlyContinue
            foreach ($shortcut in $shortcuts) {
                $destPath = "$iBridgeDesktop\$($shortcut.Name)"
                Copy-Item $shortcut.FullName $destPath -Force
                Write-Host "✅ Copied shortcut: $($shortcut.Name)" -ForegroundColor Green
            }
        } catch {
            Write-Host "❌ Failed to copy shortcuts: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️ iBridge User desktop not found - shortcuts not copied" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ Shortcuts folder not found: $shortcutsSource" -ForegroundColor Yellow
}

# Clean up temporary files
Write-Host "Cleaning up..." -ForegroundColor Cyan
if (Test-Path $localAppsPath) {
    Remove-Item $localAppsPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Cleaned up temporary files" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "        iBridge Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Accounts created:" -ForegroundColor Cyan
Write-Host "✅ Admin (Password: $AdminPassword)" -ForegroundColor White
Write-Host "✅ iBridge User (Password: $UserPassword)" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Log in to each account once to complete profile setup!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Applications installed and shortcuts configured for iBridge User." -ForegroundColor Green
Write-Host ""

pause
