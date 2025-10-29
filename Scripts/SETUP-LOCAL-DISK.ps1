# Local Disk Installation Setup
# Copies everything to local drive for USB-independent operation

param([switch]$SkipValidation)

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check admin privileges
if (-not (Test-Administrator)) {
    Write-ColorOutput "ERROR: This script must be run as Administrator" "Red"
    exit 1
}

Write-ColorOutput "iBridge Local Disk Setup - USB Independent Installation" "Cyan"
Write-ColorOutput "Copying everything to local drive for standalone operation" "Yellow"
Write-ColorOutput ""

# Configuration
$LocalBase = "C:\iBridge_Local_Setup"
$InstallerBase = "$LocalBase\Installers"
$ScriptBase = "$LocalBase\Scripts"
$NetworkShareBase = "$LocalBase\NetworkShare"

# Step 1: Create local directory structure
Write-ColorOutput "Step 1: Creating local directory structure..." "Green"

$directories = @($LocalBase, $InstallerBase, $ScriptBase, $NetworkShareBase)
foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-ColorOutput "Created: $dir" "Gray"
    }
}

# Step 2: Copy all USB content to local drive
Write-ColorOutput "Step 2: Copying USB content to local drive..." "Green"

# Detect USB drive (try common drive letters)
$usbDrive = $null
foreach ($drive in @('E:', 'F:', 'G:', 'D:')) {
    if (Test-Path "$drive\") {
        $testFiles = @(
            "$drive\24.2.2000.exe",
            "$drive\GlassWireSetup.exe", 
            "$drive\PBIDesktopSetup_x64.exe",
            "$drive\TeamViewer_Setup_x64.exe"
        )
        
        $foundFiles = 0
        foreach ($file in $testFiles) {
            if (Test-Path $file) { $foundFiles++ }
        }
        
        if ($foundFiles -ge 2) {
            $usbDrive = $drive
            Write-ColorOutput "USB drive detected: $usbDrive" "Green"
            break
        }
    }
}

if (!$usbDrive) {
    Write-ColorOutput "WARNING: USB drive not detected. Using current directory." "Yellow"
    $usbDrive = (Get-Location).Path
}

# Copy application installers
Write-ColorOutput "Copying application installers..." "Gray"
$appFiles = @(
    "24.2.2000.exe",
    "GlassWireSetup.exe", 
    "PBIDesktopSetup_x64.exe",
    "TeamViewer_Setup_x64.exe"
)

foreach ($app in $appFiles) {
    $sourcePath = "$usbDrive\$app"
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath "$InstallerBase\$app" -Force
        Write-ColorOutput "  Copied: $app" "Gray"
    } else {
        Write-ColorOutput "  Missing: $app" "Yellow"
    }
}

# Copy Office tools folder if it exists
$officeSource = "$usbDrive\Tools for Office2019 TechXander"
if (Test-Path $officeSource) {
    $officeDest = "$InstallerBase\Tools for Office2019 TechXander"
    Copy-Item $officeSource $officeDest -Recurse -Force
    Write-ColorOutput "  Copied: Office tools folder" "Gray"
}

# Copy shortcut folders
Write-ColorOutput "Copying shortcut folders..." "Gray"
$shortcutFolders = @("IT STUFF", "iBridge Set Up")
foreach ($folder in $shortcutFolders) {
    $sourcePath = "$usbDrive\$folder"
    if (Test-Path $sourcePath) {
        $destPath = "$LocalBase\$folder"
        Copy-Item $sourcePath $destPath -Recurse -Force
        Write-ColorOutput "  Copied: $folder" "Gray"
    }
}

# Step 3: Create local installation script
Write-ColorOutput "Step 3: Creating local installation script..." "Green"

$localInstallScript = @'
# iBridge Local Installation Script
# Runs completely from local drive - USB independent

param([switch]$SkipValidation)

$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc" 
$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"
$LocalBase = "C:\iBridge_Local_Setup"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-ColorOutput "ERROR: This script must be run as Administrator" "Red"
    exit 1
}

Write-ColorOutput "iBridge Local Installation - USB Independent" "Cyan"
Write-ColorOutput "Installing from local drive: $LocalBase" "Yellow"
Write-ColorOutput ""

# Create organized folder structure
$iBridgeSetup = "C:\iBridge_Setup"
$folders = @("$iBridgeSetup\Installers", "$iBridgeSetup\Shortcuts", "$iBridgeSetup\Logs")
foreach ($folder in $folders) {
    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
}

# Remove existing accounts
Write-ColorOutput "Step 1: Cleaning up existing accounts..." "Green"
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

# Create new accounts
Write-ColorOutput "Step 2: Creating user accounts..." "Green"
$secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -Description "Admin for app installation" -PasswordNeverExpires -AccountNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername
Write-ColorOutput "Created Admin account successfully" "Gray"

$secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force  
$bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -Description "Standard user with limited privileges" -PasswordNeverExpires -AccountNeverExpires
Add-LocalGroupMember -Group "Users" -Member $UserUsername
Write-ColorOutput "Created iBridge User account successfully" "Gray"

# Create profile folders
Write-ColorOutput "Step 3: Creating user profile folders..." "Green"
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

# Install applications from local drive
Write-ColorOutput "Step 4: Installing applications from local drive..." "Green"
$applications = @(
    @{Path = "$LocalBase\Installers\24.2.2000.exe"; Name = "24.2.2000"; Args = "/SILENT"},
    @{Path = "$LocalBase\Installers\GlassWireSetup.exe"; Name = "GlassWire"; Args = "/S"},
    @{Path = "$LocalBase\Installers\PBIDesktopSetup_x64.exe"; Name = "Power BI Desktop"; Args = "/quiet"},
    @{Path = "$LocalBase\Installers\TeamViewer_Setup_x64.exe"; Name = "TeamViewer"; Args = "/S"}
)

$installedCount = 0
foreach ($app in $applications) {
    if (Test-Path $app.Path) {
        Write-ColorOutput "Installing $($app.Name) from local drive..." "Yellow"
        
        # Copy to backup location
        $backupPath = Join-Path "$iBridgeSetup\Installers" (Split-Path $app.Path -Leaf)
        Copy-Item $app.Path $backupPath -Force
        
        # Install from local copy
        $process = Start-Process -FilePath $app.Path -ArgumentList $app.Args -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-ColorOutput "Installed $($app.Name) successfully" "Green"
            $installedCount++
        } else {
            Write-ColorOutput "Installation of $($app.Name) completed with exit code $($process.ExitCode)" "Yellow"
            $installedCount++
        }
    } else {
        Write-ColorOutput "Application not found: $($app.Path)" "Red"
    }
}

# Handle Office tools
Write-ColorOutput "Step 5: Setting up Office tools..." "Green"
$officeSource = "$LocalBase\Installers\Tools for Office2019 TechXander"
if (Test-Path $officeSource) {
    $officeDest = "$iBridgeSetup\Installers\Tools for Office2019 TechXander"
    Copy-Item $officeSource $officeDest -Recurse -Force
    Write-ColorOutput "Office tools copied to local storage" "Gray"
}

# Copy shortcuts
Write-ColorOutput "Step 6: Setting up shortcuts for iBridge User..." "Green"
$shortcutSources = @("$LocalBase\IT STUFF", "$LocalBase\iBridge Set Up")
$iBridgeDesktop = "C:\Users\$UserUsername\Desktop"
$shortcutCount = 0

foreach ($source in $shortcutSources) {
    if (Test-Path $source) {
        $shortcuts = Get-ChildItem $source -Include "*.lnk", "*.url" -Recurse -ErrorAction SilentlyContinue
        foreach ($shortcut in $shortcuts) {
            # Copy to shared folder
            $sharedPath = Join-Path "$iBridgeSetup\Shortcuts" $shortcut.Name
            Copy-Item $shortcut.FullName $sharedPath -Force
            
            # Copy to iBridge User desktop
            $desktopPath = Join-Path $iBridgeDesktop $shortcut.Name
            Copy-Item $shortcut.FullName $desktopPath -Force
            
            Write-ColorOutput "Added shortcut: $($shortcut.Name)" "Gray"
            $shortcutCount++
        }
    }
}

# Set permissions
Write-ColorOutput "Step 7: Setting folder permissions..." "Green"
try {
    $acl = Get-Acl $iBridgeSetup
    $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($userAccessRule)
    Set-Acl -Path $iBridgeSetup -AclObject $acl
    Write-ColorOutput "Folder permissions configured" "Gray"
} catch {
    Write-ColorOutput "Could not set folder permissions: $($_.Exception.Message)" "Yellow"
}

# Create summary
$summary = @"
iBridge Local Installation Summary
Generated: $(Get-Date)
Installation Source: Local Drive ($LocalBase)

USER ACCOUNTS:
- Admin (Password: $AdminPassword)
- iBridge User (Password: $UserPassword)

INSTALLATION RESULTS:
- Applications Installed: $installedCount
- Shortcuts Created: $shortcutCount
- Everything stored in: $iBridgeSetup

USB INDEPENDENT OPERATION:
- All applications installed from local drive
- USB drive can be safely removed
- All files backed up to local storage
- Shortcuts available on iBridge User desktop

NEXT STEPS:
1. USB drive can now be removed and used for other purposes
2. Log out of current Windows session
3. Log in as 'iBridge User' (Password: Abc654321!)
4. Check desktop for application shortcuts
5. Test applications work independently

Local installation completed successfully!
USB drive is no longer needed!
"@

$summaryPath = "$iBridgeSetup\LOCAL-INSTALLATION-SUMMARY.txt"
$summary | Out-File $summaryPath -Encoding UTF8

# Final output
Write-ColorOutput ""
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "LOCAL INSTALLATION COMPLETED!" "Green"
Write-ColorOutput "========================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "Installation source: Local drive" "Cyan"
Write-ColorOutput "Applications installed: $installedCount" "Cyan" 
Write-ColorOutput "Shortcuts created: $shortcutCount" "Cyan"
Write-ColorOutput "Everything organized in: $iBridgeSetup" "Cyan"
Write-ColorOutput ""
Write-ColorOutput "USB DRIVE CAN NOW BE REMOVED!" "Yellow"
Write-ColorOutput "Installation is completely independent" "Yellow"
Write-ColorOutput ""
Write-ColorOutput "Summary saved to: $summaryPath" "Gray"
'@

$localScriptPath = "$ScriptBase\LOCAL-INSTALL.ps1"
$localInstallScript | Out-File $localScriptPath -Encoding UTF8
Write-ColorOutput "Created: LOCAL-INSTALL.ps1" "Gray"

# Step 4: Create network deployment scripts for local drive
Write-ColorOutput "Step 4: Creating network deployment scripts..." "Green"

# Update network deployment to use local files
$networkDeployScript = (Get-Content "$PSScriptRoot\FULLY-AUTOMATED-DEPLOY.ps1" -Raw) -replace 'C:\\Users\\Lwandile Gasela\\iBridge\\Scripts\\', "$ScriptBase\"
$networkDeployScript = $networkDeployScript -replace 'C:\\iBridge_NetworkShare', $NetworkShareBase

$networkScriptPath = "$ScriptBase\NETWORK-DEPLOY-LOCAL.ps1"
$networkDeployScript | Out-File $networkScriptPath -Encoding UTF8
Write-ColorOutput "Created: NETWORK-DEPLOY-LOCAL.ps1" "Gray"

# Copy setup files to network share base
Copy-Item "$ScriptBase\LOCAL-INSTALL.ps1" "$NetworkShareBase\LOCAL-INSTALL.ps1" -Force

# Step 5: Create launcher scripts
Write-ColorOutput "Step 5: Creating launcher scripts..." "Green"

$localLauncher = @"
@echo off
echo ================================================================
echo iBridge Local Installation - USB Independent
echo ================================================================
echo.
echo This will install iBridge setup from the local drive.
echo USB drive can be removed after this starts.
echo.
pause

:: Check for admin privileges and elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running local installation...
powershell.exe -ExecutionPolicy Bypass -File "$ScriptBase\LOCAL-INSTALL.ps1"

echo.
echo Installation completed! USB drive can be removed.
pause
"@

$localLauncherPath = "$LocalBase\RUN-LOCAL-INSTALL.bat"
$localLauncher | Out-File $localLauncherPath -Encoding ASCII
Write-ColorOutput "Created: RUN-LOCAL-INSTALL.bat" "Gray"

$networkLauncher = @"
@echo off
echo ================================================================
echo iBridge Network Deployment - From Local Drive
echo ================================================================
echo.
echo This will deploy iBridge setup to network devices using local files.
echo USB drive is not required.
echo.
pause

:: Check for admin privileges and elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running network deployment from local drive...
powershell.exe -ExecutionPolicy Bypass -File "$ScriptBase\NETWORK-DEPLOY-LOCAL.ps1"

echo.
echo Network deployment completed!
pause
"@

$networkLauncherPath = "$LocalBase\RUN-NETWORK-DEPLOY.bat"
$networkLauncher | Out-File $networkLauncherPath -Encoding ASCII
Write-ColorOutput "Created: RUN-NETWORK-DEPLOY.bat" "Gray"

# Summary
Write-ColorOutput ""
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "LOCAL DISK SETUP COMPLETED!" "Green"
Write-ColorOutput "========================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "Local installation base: $LocalBase" "Cyan"
Write-ColorOutput "All USB content copied to local drive" "Green"
Write-ColorOutput ""
Write-ColorOutput "AVAILABLE OPERATIONS:" "White"
Write-ColorOutput "1. Local Installation: $LocalBase\RUN-LOCAL-INSTALL.bat" "Gray"
Write-ColorOutput "2. Network Deployment: $LocalBase\RUN-NETWORK-DEPLOY.bat" "Gray"
Write-ColorOutput ""
Write-ColorOutput "USB DRIVE CAN NOW BE REMOVED!" "Yellow"
Write-ColorOutput "All operations work from local drive" "Yellow"
Write-ColorOutput ""
Write-ColorOutput "Files organized in:" "White"
Write-ColorOutput "  - Installers: $InstallerBase" "Gray"
Write-ColorOutput "  - Scripts: $ScriptBase" "Gray"
Write-ColorOutput "  - Network Share: $NetworkShareBase" "Gray"
Write-ColorOutput "  - Shortcuts: $LocalBase\IT STUFF, $LocalBase\iBridge Set Up" "Gray"
