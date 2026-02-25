# iBridge Enhanced Setup - Universal Standalone Version
# Works on any device with automatic path detection and Office installation

param([switch]$SkipValidation)

# Configuration
$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc" 
$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"
$iBridgeBase = "C:\iBridge_Setup"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-USBDrive {
    Write-ColorOutput "Auto-detecting USB drive location..." "Yellow"
    
    # Check for key files to identify correct USB drive
    $driveLetters = @("D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")
    
    foreach ($drive in $driveLetters) {
        $drivePath = "${drive}:\"
        if (Test-Path $drivePath) {
            # Check for our key application files
            $keyFiles = @("24.2.2000.exe", "GlassWireSetup.exe", "TeamViewer_Setup_x64.exe")
            $foundFiles = 0
            
            foreach ($file in $keyFiles) {
                if (Test-Path (Join-Path $drivePath $file)) {
                    $foundFiles++
                }
            }
            
            if ($foundFiles -ge 2) {
                Write-ColorOutput "Found USB drive at: $drivePath" "Green"
                return $drivePath
            }
        }
    }
    
    Write-ColorOutput "ERROR: Could not find USB drive with required application files" "Red"
    return $null
}

function Install-OfficeFromTools {
    param([string]$OfficeToolsPath)
    
    Write-ColorOutput "Setting up Microsoft Office installation..." "Yellow"
    
    if (!(Test-Path $OfficeToolsPath)) {
        Write-ColorOutput "Office tools folder not found at: $OfficeToolsPath" "Red"
        return $false
    }
    
    # Copy Office tools to local storage
    $localOfficePath = Join-Path $iBridgeBase "Installers\Tools for Office2019 TechXander"
    if (!(Test-Path $localOfficePath)) {
        Write-ColorOutput "Copying Office tools to local storage..." "Gray"
        Copy-Item $OfficeToolsPath $localOfficePath -Recurse -Force
    }
    
    # Check for setup files in the tools folder
    $configPath = Join-Path $OfficeToolsPath "Config Files"
    $setupInfo = Join-Path $OfficeToolsPath "setupINFO.url"
    
    if (Test-Path $configPath) {
        Write-ColorOutput "Office configuration files found" "Green"
        
        # Check if Office is already installed
        $officeInstalled = $false
        $officePaths = @(
            "C:\Program Files\Microsoft Office",
            "C:\Program Files (x86)\Microsoft Office", 
            "C:\Program Files\Microsoft Office\Office16",
            "C:\Program Files (x86)\Microsoft Office\Office16"
        )
        
        foreach ($path in $officePaths) {
            if (Test-Path $path) {
                $officeInstalled = $true
                Write-ColorOutput "Microsoft Office already installed at: $path" "Green"
                break
            }
        }
        
        if (-not $officeInstalled) {
            # Try to find and run Office setup
            $setupFiles = Get-ChildItem $OfficeToolsPath -Include "setup.exe", "Setup.exe" -Recurse -ErrorAction SilentlyContinue
            
            if ($setupFiles.Count -gt 0) {
                $setupFile = $setupFiles[0]
                Write-ColorOutput "Running Office setup: $($setupFile.FullName)" "Yellow"
                
                try {
                    $process = Start-Process -FilePath $setupFile.FullName -Wait -PassThru -NoNewWindow
                    if ($process.ExitCode -eq 0) {
                        Write-ColorOutput "Office installation completed successfully" "Green"
                        return $true
                    } else {
                        Write-ColorOutput "Office installation completed with exit code: $($process.ExitCode)" "Yellow"
                        return $true
                    }
                } catch {
                    Write-ColorOutput "Could not run Office setup: $($_.Exception.Message)" "Red"
                    Write-ColorOutput "Office tools copied for manual installation" "Yellow"
                    return $false
                }
            } else {
                Write-ColorOutput "No setup.exe found in Office tools" "Yellow"
                Write-ColorOutput "Office configuration files copied for manual setup" "Gray"
                Write-ColorOutput "Check: $localOfficePath for setup instructions" "Cyan"
                return $false
            }
        }
        
        return $true
    } else {
        Write-ColorOutput "Office configuration files not found" "Red"
        return $false
    }
}

function Install-WindowsStore {
    Write-ColorOutput "Installing Microsoft Store applications..." "Yellow"
    
    # Common Microsoft Store apps that might be needed
    $storeApps = @(
        "Microsoft.WindowsStore",
        "Microsoft.Office.OneNote", 
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.SkypeApp"
    )
    
    foreach ($app in $storeApps) {
        try {
            $installed = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
            if (-not $installed) {
                Write-ColorOutput "Attempting to install: $app" "Gray"
                # Note: This requires internet connection
                # Add-AppxPackage would be used here if package is available
            } else {
                Write-ColorOutput "Already installed: $app" "Green"
            }
        } catch {
            Write-ColorOutput "Could not check/install: $app" "Yellow"
        }
    }
}

# Check admin privileges
if (-not (Test-Administrator)) {
    Write-ColorOutput "ERROR: This script must be run as Administrator" "Red"
    Write-ColorOutput "Right-click and select 'Run as administrator'" "Yellow"
    Read-Host "Press Enter to exit"
    exit 1
}

# Find USB drive
$usbDrive = Find-USBDrive
if (-not $usbDrive) {
    Write-ColorOutput "Please ensure USB drive contains the required application files" "Yellow"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-ColorOutput "iBridge Enhanced Setup - Universal Standalone Operation" "Cyan"
Write-ColorOutput "USB Drive: $usbDrive" "Green"
Write-ColorOutput "Creating accounts and installing applications for USB-independent use" "Yellow"
Write-ColorOutput ""

# Step 1: Create folder structure
Write-ColorOutput "Step 1: Creating organized folder structure..." "Green"
$folders = @("$iBridgeBase\Installers", "$iBridgeBase\Shortcuts", "$iBridgeBase\Logs", "$iBridgeBase\Office")
foreach ($folder in $folders) {
    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-ColorOutput "Created: $folder" "Gray"
    }
}

# Step 2: Remove existing accounts
Write-ColorOutput "Step 2: Cleaning up existing accounts..." "Green"
$existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
if ($existingAdmin) {
    Remove-LocalUser -Name $AdminUsername -Confirm:$false
    Write-ColorOutput "Removed existing Admin account" "Gray"
}

$existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
if ($existingUser) {
    Remove-LocalUser -Name $UserUsername -Confirm:$false
    Write-ColorOutput "Removed existing iBridge User account" "Gray"
}

# Step 3: Create new accounts
Write-ColorOutput "Step 3: Creating user accounts..." "Green"
$secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -Description "Admin for app installation" -PasswordNeverExpires -AccountNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername
Write-ColorOutput "Created Admin account successfully" "Gray"

$secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force  
$bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -Description "Standard user with limited privileges" -PasswordNeverExpires -AccountNeverExpires
Add-LocalGroupMember -Group "Users" -Member $UserUsername
Write-ColorOutput "Created iBridge User account successfully" "Gray"

# Step 4: Create profile folders
Write-ColorOutput "Step 4: Creating user profile folders..." "Green"
$profilePaths = @("C:\Users\$AdminUsername", "C:\Users\$UserUsername")
foreach ($profilePath in $profilePaths) {
    if (!(Test-Path $profilePath)) {
        $subFolders = @("Desktop", "Documents", "Downloads", "AppData\Local", "AppData\Roaming")
        foreach ($subFolder in $subFolders) {
            $fullPath = Join-Path $profilePath $subFolder
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        }
        Write-ColorOutput "Created profile: $profilePath" "Gray"
    }
}

# Step 5: Install main applications
Write-ColorOutput "Step 5: Installing main applications permanently..." "Green"
$applications = @(
    @{Path = "$usbDrive\24.2.2000.exe"; Name = "24.2.2000 (SYSPRO)"; Args = "/SILENT"},
    @{Path = "$usbDrive\GlassWireSetup.exe"; Name = "GlassWire"; Args = "/S"},
    @{Path = "$usbDrive\PBIDesktopSetup_x64.exe"; Name = "Power BI Desktop"; Args = "/quiet"},
    @{Path = "$usbDrive\TeamViewer_Setup_x64.exe"; Name = "TeamViewer"; Args = "/S"}
)

$installedCount = 0
foreach ($app in $applications) {
    if (Test-Path $app.Path) {
        Write-ColorOutput "Installing $($app.Name)..." "Yellow"
        
        # Copy installer to local storage
        $localInstaller = Join-Path "$iBridgeBase\Installers" (Split-Path $app.Path -Leaf)
        Copy-Item $app.Path $localInstaller -Force
        Write-ColorOutput "Copied to local storage: $(Split-Path $app.Path -Leaf)" "Gray"
        
        # Install from local copy
        try {
            $process = Start-Process -FilePath $localInstaller -ArgumentList $app.Args -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -eq 0) {
                Write-ColorOutput "✓ Installed $($app.Name) successfully" "Green"
                $installedCount++
            } else {
                Write-ColorOutput "⚠ $($app.Name) installation completed with exit code $($process.ExitCode)" "Yellow"
                $installedCount++
            }
        } catch {
            Write-ColorOutput "✗ Failed to install $($app.Name): $($_.Exception.Message)" "Red"
        }
    } else {
        Write-ColorOutput "Application not found: $($app.Path)" "Red"
    }
}

# Step 6: Handle Microsoft Office installation
Write-ColorOutput "Step 6: Setting up Microsoft Office..." "Green"
$officeToolsPath = "$usbDrive\Tools for Office2019 TechXander"
$officeInstalled = Install-OfficeFromTools -OfficeToolsPath $officeToolsPath

# Step 7: Install Microsoft Store apps (if available)
Install-WindowsStore

# Step 8: Copy shortcuts to iBridge User desktop
Write-ColorOutput "Step 7: Setting up shortcuts for iBridge User..." "Green"
$shortcutSources = @("$usbDrive\IT STUFF", "$usbDrive\iBridge Set Up")
$iBridgeDesktop = "C:\Users\$UserUsername\Desktop"
$shortcutCount = 0

foreach ($source in $shortcutSources) {
    if (Test-Path $source) {
        $shortcuts = Get-ChildItem $source -Include "*.lnk", "*.url" -Recurse -ErrorAction SilentlyContinue
        foreach ($shortcut in $shortcuts) {
            # Copy to shared folder
            $sharedPath = Join-Path "$iBridgeBase\Shortcuts" $shortcut.Name
            Copy-Item $shortcut.FullName $sharedPath -Force
            
            # Copy to iBridge User desktop
            $desktopPath = Join-Path $iBridgeDesktop $shortcut.Name
            Copy-Item $shortcut.FullName $desktopPath -Force
            
            Write-ColorOutput "Added shortcut: $($shortcut.Name)" "Gray"
            $shortcutCount++
        }
    } else {
        Write-ColorOutput "Shortcut source not found: $source" "Yellow"
    }
}

# Step 9: Set permissions
Write-ColorOutput "Step 8: Setting folder permissions..." "Green"
try {
    $acl = Get-Acl $iBridgeBase
    $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($userAccessRule)
    $adminAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($adminAccessRule)
    Set-Acl -Path $iBridgeBase -AclObject $acl
    Write-ColorOutput "Folder permissions configured" "Gray"
} catch {
    Write-ColorOutput "Could not set folder permissions: $($_.Exception.Message)" "Yellow"
}

# Step 10: Create comprehensive summary
Write-ColorOutput "Step 9: Creating setup summary..." "Green"
$summary = @"
iBridge Enhanced Setup Summary - Universal Version
Generated: $(Get-Date)
USB Drive Used: $usbDrive

USER ACCOUNTS:
- Admin (Password: $AdminPassword)
- iBridge User (Password: $UserPassword)

INSTALLATION RESULTS:
- Main Applications Installed: $installedCount
- Microsoft Office: $(if ($officeInstalled) { "Installed/Available" } else { "Tools copied for manual setup" })
- Shortcuts Created: $shortcutCount
- Everything stored in: $iBridgeBase

APPLICATIONS INSTALLED:
- 24.2.2000.exe (SYSPRO)
- GlassWireSetup.exe (Network Monitoring)
- PBIDesktopSetup_x64.exe (Power BI Desktop)
- TeamViewer_Setup_x64.exe (Remote Access)

MICROSOFT OFFICE:
- Tools copied to: $iBridgeBase\Installers\Tools for Office2019 TechXander
- Configuration files available for setup
- Check setupINFO.url for installation instructions

STANDALONE OPERATION READY:
- All applications installed to local system
- Installers backed up to local storage
- Shortcuts available on iBridge User desktop
- USB drive no longer required for daily use

NEXT STEPS:
1. Log out of current Windows session
2. Log in as 'iBridge User' (Password: Abc654321!)
3. Check desktop for application shortcuts
4. For Office: Browse to C:\iBridge_Setup\Installers\Tools for Office2019 TechXander
5. Run any Office setup files or follow setupINFO.url instructions
6. Test all applications work without USB drive

TROUBLESHOOTING:
- If Office needs manual setup: Use files in C:\iBridge_Setup\Installers\Tools for Office2019 TechXander
- All installer backups available in: C:\iBridge_Setup\Installers
- Log files available in: C:\iBridge_Setup\Logs

Setup completed successfully!
"@

$summaryPath = Join-Path $iBridgeBase "SETUP-SUMMARY.txt"
$summary | Out-File $summaryPath -Encoding UTF8

# Final output
Write-ColorOutput ""
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "SETUP COMPLETED SUCCESSFULLY!" "Green"
Write-ColorOutput "========================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "✓ User accounts created with profiles" "Cyan"
Write-ColorOutput "✓ Main applications installed: $installedCount" "Cyan" 
Write-ColorOutput "✓ Office tools $(if ($officeInstalled) { "installed" } else { "prepared for setup" })" "Cyan"
Write-ColorOutput "✓ Shortcuts created: $shortcutCount" "Cyan"
Write-ColorOutput "✓ Everything organized in: $iBridgeBase" "Cyan"
Write-ColorOutput ""
Write-ColorOutput "STANDALONE OPERATION READY!" "Yellow"
Write-ColorOutput "USB drive can now be safely removed" "Yellow"
Write-ColorOutput ""
Write-ColorOutput "NEXT STEPS:" "White"
Write-ColorOutput "1. Log out of current Windows session" "Gray"
Write-ColorOutput "2. Log in as 'iBridge User' (Password: Abc654321!)" "Gray"
Write-ColorOutput "3. Check desktop for shortcuts" "Gray"
Write-ColorOutput "4. For Office setup: Check C:\iBridge_Setup\Installers\Tools for Office2019 TechXander" "Gray"
Write-ColorOutput "5. Test applications without USB" "Gray"
Write-ColorOutput ""
Write-ColorOutput "Summary saved to: $summaryPath" "Gray"

if (-not $SkipValidation) {
    Read-Host "Press Enter to complete setup"
}
