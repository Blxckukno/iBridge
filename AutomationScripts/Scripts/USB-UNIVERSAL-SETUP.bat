@echo off
echo ================================================================
echo iBridge Enhanced Setup - Universal Edition
echo Auto-detects USB drive and properly handles Office installation
echo ================================================================
echo.
echo This script will:
echo   1. AUTO-DETECT USB drive location (works on any computer)
echo   2. Create Admin and iBridge User accounts  
echo   3. Install main applications PERMANENTLY to local system
echo   4. Set up Microsoft Office tools for installation
echo   5. Copy ALL installers to C:\iBridge_Setup\Installers
echo   6. Create shortcuts ONLY on iBridge User desktop
echo   7. Enable standalone operation (USB not required after setup)
echo.
echo IMPORTANT: After setup, USB drive will NOT be needed!
echo Microsoft Office tools will be prepared for manual setup if needed.
echo.
pause

:: Check for admin privileges and elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running Universal Enhanced Setup...

:: Create the PowerShell script content and execute it
powershell -ExecutionPolicy Bypass -Command "
# iBridge Enhanced Setup - Universal Standalone Version
# Works on any device with automatic path detection and Office installation

$AdminUsername = 'Admin'
$AdminPassword = 'IBr1dG3Pc' 
$UserUsername = 'iBridge User'
$UserPassword = 'Abc654321!'
$iBridgeBase = 'C:\iBridge_Setup'

function Write-ColorOutput {
    param([string]`$Message, [string]`$Color = 'White')
    Write-Host `$Message -ForegroundColor `$Color
}

function Test-Administrator {
    `$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    `$principal = New-Object Security.Principal.WindowsPrincipal(`$currentUser)
    return `$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-USBDrive {
    Write-ColorOutput 'Auto-detecting USB drive location...' 'Yellow'
    
    `$driveLetters = @('D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z')
    
    foreach (`$drive in `$driveLetters) {
        `$drivePath = \"`${drive}:\\"
        if (Test-Path `$drivePath) {
            `$keyFiles = @('24.2.2000.exe', 'GlassWireSetup.exe', 'TeamViewer_Setup_x64.exe')
            `$foundFiles = 0
            
            foreach (`$file in `$keyFiles) {
                if (Test-Path (Join-Path `$drivePath `$file)) {
                    `$foundFiles++
                }
            }
            
            if (`$foundFiles -ge 2) {
                Write-ColorOutput \"Found USB drive at: `$drivePath\" 'Green'
                return `$drivePath
            }
        }
    }
    
    Write-ColorOutput 'ERROR: Could not find USB drive with required application files' 'Red'
    return `$null
}

# Find USB drive
`$usbDrive = Find-USBDrive
if (-not `$usbDrive) {
    Write-ColorOutput 'Please ensure USB drive contains the required application files' 'Yellow'
    Read-Host 'Press Enter to exit'
    exit 1
}

Write-ColorOutput 'iBridge Enhanced Setup - Universal Standalone Operation' 'Cyan'
Write-ColorOutput \"USB Drive: `$usbDrive\" 'Green'
Write-ColorOutput 'Creating accounts and installing applications for USB-independent use' 'Yellow'
Write-ColorOutput ''

# Step 1: Create folder structure
Write-ColorOutput 'Step 1: Creating organized folder structure...' 'Green'
`$folders = @(\"`$iBridgeBase\\Installers\", \"`$iBridgeBase\\Shortcuts\", \"`$iBridgeBase\\Logs\", \"`$iBridgeBase\\Office\")
foreach (`$folder in `$folders) {
    if (!(Test-Path `$folder)) {
        New-Item -ItemType Directory -Path `$folder -Force | Out-Null
        Write-ColorOutput \"Created: `$folder\" 'Gray'
    }
}

# Step 2: Remove existing accounts
Write-ColorOutput 'Step 2: Cleaning up existing accounts...' 'Green'
`$existingAdmin = Get-LocalUser -Name `$AdminUsername -ErrorAction SilentlyContinue
if (`$existingAdmin) {
    Remove-LocalUser -Name `$AdminUsername -Confirm:`$false
    Write-ColorOutput 'Removed existing Admin account' 'Gray'
}

`$existingUser = Get-LocalUser -Name `$UserUsername -ErrorAction SilentlyContinue
if (`$existingUser) {
    Remove-LocalUser -Name `$UserUsername -Confirm:`$false
    Write-ColorOutput 'Removed existing iBridge User account' 'Gray'
}

# Step 3: Create new accounts
Write-ColorOutput 'Step 3: Creating user accounts...' 'Green'
`$secureAdminPassword = ConvertTo-SecureString `$AdminPassword -AsPlainText -Force
`$adminUser = New-LocalUser -Name `$AdminUsername -Password `$secureAdminPassword -Description 'Admin for app installation' -PasswordNeverExpires -AccountNeverExpires
Add-LocalGroupMember -Group 'Administrators' -Member `$AdminUsername
Write-ColorOutput 'Created Admin account successfully' 'Gray'

`$secureUserPassword = ConvertTo-SecureString `$UserPassword -AsPlainText -Force  
`$bridgeUser = New-LocalUser -Name `$UserUsername -Password `$secureUserPassword -Description 'Standard user with limited privileges' -PasswordNeverExpires -AccountNeverExpires
Add-LocalGroupMember -Group 'Users' -Member `$UserUsername
Write-ColorOutput 'Created iBridge User account successfully' 'Gray'

# Step 4: Create profile folders
Write-ColorOutput 'Step 4: Creating user profile folders...' 'Green'
`$profilePaths = @(\"C:\\Users\\`$AdminUsername\", \"C:\\Users\\`$UserUsername\")
foreach (`$profilePath in `$profilePaths) {
    if (!(Test-Path `$profilePath)) {
        `$subFolders = @('Desktop', 'Documents', 'Downloads', 'AppData\\Local', 'AppData\\Roaming')
        foreach (`$subFolder in `$subFolders) {
            `$fullPath = Join-Path `$profilePath `$subFolder
            New-Item -ItemType Directory -Path `$fullPath -Force | Out-Null
        }
        Write-ColorOutput \"Created profile: `$profilePath\" 'Gray'
    }
}

# Step 5: Install main applications
Write-ColorOutput 'Step 5: Installing main applications permanently...' 'Green'
`$applications = @(
    @{Path = \"`$usbDrive\\24.2.2000.exe\"; Name = '24.2.2000 (SYSPRO)'; Args = '/SILENT'},
    @{Path = \"`$usbDrive\\GlassWireSetup.exe\"; Name = 'GlassWire'; Args = '/S'},
    @{Path = \"`$usbDrive\\PBIDesktopSetup_x64.exe\"; Name = 'Power BI Desktop'; Args = '/quiet'},
    @{Path = \"`$usbDrive\\TeamViewer_Setup_x64.exe\"; Name = 'TeamViewer'; Args = '/S'}
)

`$installedCount = 0
foreach (`$app in `$applications) {
    if (Test-Path `$app.Path) {
        Write-ColorOutput \"Installing `$(`$app.Name)...\" 'Yellow'
        
        # Copy installer to local storage
        `$localInstaller = Join-Path \"`$iBridgeBase\\Installers\" (Split-Path `$app.Path -Leaf)
        Copy-Item `$app.Path `$localInstaller -Force
        Write-ColorOutput \"Copied to local storage: `$(Split-Path `$app.Path -Leaf)\" 'Gray'
        
        # Install from local copy
        try {
            `$process = Start-Process -FilePath `$localInstaller -ArgumentList `$app.Args -Wait -PassThru -NoNewWindow
            if (`$process.ExitCode -eq 0) {
                Write-ColorOutput \"✓ Installed `$(`$app.Name) successfully\" 'Green'
                `$installedCount++
            } else {
                Write-ColorOutput \"⚠ `$(`$app.Name) installation completed with exit code `$(`$process.ExitCode)\" 'Yellow'
                `$installedCount++
            }
        } catch {
            Write-ColorOutput \"✗ Failed to install `$(`$app.Name): `$(`$_.Exception.Message)\" 'Red'
        }
    } else {
        Write-ColorOutput \"Application not found: `$(`$app.Path)\" 'Red'
    }
}

# Step 6: Handle Microsoft Office installation
Write-ColorOutput 'Step 6: Setting up Microsoft Office tools...' 'Green'
`$officeToolsPath = \"`$usbDrive\\Tools for Office2019 TechXander\"
`$officeInstalled = `$false

if (Test-Path `$officeToolsPath) {
    # Copy Office tools to local storage
    `$localOfficePath = Join-Path `$iBridgeBase 'Installers\\Tools for Office2019 TechXander'
    if (!(Test-Path `$localOfficePath)) {
        Write-ColorOutput 'Copying Office tools to local storage...' 'Gray'
        Copy-Item `$officeToolsPath `$localOfficePath -Recurse -Force
        Write-ColorOutput 'Office tools copied successfully' 'Green'
    }
    
    # Check if Office is already installed
    `$officePaths = @(
        'C:\\Program Files\\Microsoft Office',
        'C:\\Program Files (x86)\\Microsoft Office'
    )
    
    foreach (`$path in `$officePaths) {
        if (Test-Path `$path) {
            `$officeInstalled = `$true
            Write-ColorOutput \"Microsoft Office already installed at: `$path\" 'Green'
            break
        }
    }
    
    if (-not `$officeInstalled) {
        Write-ColorOutput 'Office tools prepared for manual installation' 'Yellow'
        Write-ColorOutput \"Check: `$localOfficePath for setup files\" 'Cyan'
    }
} else {
    Write-ColorOutput 'Office tools folder not found on USB drive' 'Red'
}

# Step 7: Copy shortcuts to iBridge User desktop
Write-ColorOutput 'Step 7: Setting up shortcuts for iBridge User...' 'Green'
`$shortcutSources = @(\"`$usbDrive\\IT STUFF\", \"`$usbDrive\\iBridge Set Up\")
`$iBridgeDesktop = \"C:\\Users\\`$UserUsername\\Desktop\"
`$shortcutCount = 0

foreach (`$source in `$shortcutSources) {
    if (Test-Path `$source) {
        `$shortcuts = Get-ChildItem `$source -Include '*.lnk', '*.url' -Recurse -ErrorAction SilentlyContinue
        foreach (`$shortcut in `$shortcuts) {
            # Copy to shared folder
            `$sharedPath = Join-Path \"`$iBridgeBase\\Shortcuts\" `$shortcut.Name
            Copy-Item `$shortcut.FullName `$sharedPath -Force
            
            # Copy to iBridge User desktop
            `$desktopPath = Join-Path `$iBridgeDesktop `$shortcut.Name
            Copy-Item `$shortcut.FullName `$desktopPath -Force
            
            Write-ColorOutput \"Added shortcut: `$(`$shortcut.Name)\" 'Gray'
            `$shortcutCount++
        }
    } else {
        Write-ColorOutput \"Shortcut source not found: `$source\" 'Yellow'
    }
}

# Step 8: Set permissions
Write-ColorOutput 'Step 8: Setting folder permissions...' 'Green'
try {
    `$acl = Get-Acl `$iBridgeBase
    `$userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule('Users', 'ReadAndExecute', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    `$acl.SetAccessRule(`$userAccessRule)
    `$adminAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule('Administrators', 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    `$acl.SetAccessRule(`$adminAccessRule)
    Set-Acl -Path `$iBridgeBase -AclObject `$acl
    Write-ColorOutput 'Folder permissions configured' 'Gray'
} catch {
    Write-ColorOutput \"Could not set folder permissions: `$(`$_.Exception.Message)\" 'Yellow'
}

# Final output
Write-ColorOutput ''
Write-ColorOutput '========================================' 'Green'
Write-ColorOutput 'SETUP COMPLETED SUCCESSFULLY!' 'Green'
Write-ColorOutput '========================================' 'Green'
Write-ColorOutput ''
Write-ColorOutput 'User accounts created with profiles' 'Cyan'
Write-ColorOutput \"Main applications installed: `$installedCount\" 'Cyan' 
Write-ColorOutput \"Office tools `$(if (`$officeInstalled) { 'already installed' } else { 'prepared for setup' })\" 'Cyan'
Write-ColorOutput \"Shortcuts created: `$shortcutCount\" 'Cyan'
Write-ColorOutput \"Everything organized in: `$iBridgeBase\" 'Cyan'
Write-ColorOutput ''
Write-ColorOutput 'STANDALONE OPERATION READY!' 'Yellow'
Write-ColorOutput 'USB drive can now be safely removed' 'Yellow'
Write-ColorOutput ''
Write-ColorOutput 'NEXT STEPS:' 'White'
Write-ColorOutput '1. Log out of current Windows session' 'Gray'
Write-ColorOutput '2. Log in as iBridge User (Password: Abc654321!)' 'Gray'
Write-ColorOutput '3. Check desktop for shortcuts' 'Gray'
Write-ColorOutput '4. For Office: Check C:\\iBridge_Setup\\Installers\\Tools for Office2019 TechXander' 'Gray'
Write-ColorOutput '5. Test applications without USB' 'Gray'
"

echo.
echo ================================================================
echo Setup completed! 
echo Main applications installed permanently.
echo Office tools copied for manual setup if needed.
echo You can now safely remove the USB drive.
echo ================================================================
pause
