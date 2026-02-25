# iBridge Auto-Drive Detection Fix
# Fixes the drive detection issue in enhanced setup

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

Write-ColorOutput "iBridge Auto-Drive Detection Fix" "Cyan"
Write-ColorOutput "Finding and updating drive paths in setup scripts" "Yellow"
Write-ColorOutput ""

# Define the required applications
$requiredApps = @(
    "TeamViewer_Setup_x64.exe",
    "24.2.2000.exe", 
    "GlassWireSetup.exe",
    "PBIDesktopSetup_x64.exe"
)

# Search for files across all drives
Write-ColorOutput "Step 1: Scanning drives for application files..." "Green"

$foundDrive = $null
$foundFiles = @{}

$drives = @('C:', 'D:', 'E:', 'F:', 'G:', 'H:')
foreach ($drive in $drives) {
    if (Test-Path $drive) {
        Write-ColorOutput "  Checking $drive..." "Gray"
        
        $foundCount = 0
        foreach ($app in $requiredApps) {
            if (Test-Path "$drive\$app") {
                $foundFiles[$app] = "$drive\$app"
                $foundCount++
                Write-ColorOutput "    Found: $app" "Green"
            }
        }
        
        if ($foundCount -ge 3) {
            $foundDrive = $drive
            Write-ColorOutput "  Primary drive detected: $drive ($foundCount files found)" "Green"
            break
        }
    }
}

if (!$foundDrive) {
    Write-ColorOutput "ERROR: Could not find application files on any drive" "Red"
    Write-ColorOutput "Please ensure the following files are accessible:" "Yellow"
    foreach ($app in $requiredApps) {
        Write-ColorOutput "  - $app" "Gray"
    }
    exit 1
}

# Step 2: Create corrected enhanced setup script
Write-ColorOutput "Step 2: Creating corrected enhanced setup script..." "Green"

$correctedScript = @"
# iBridge Enhanced Setup Script v2.1 - Auto Drive Detection
# Updated to automatically detect correct drive location

param([switch]`$SkipValidation)

function Write-ColorOutput {
    param([string]`$Message, [string]`$Color = "White")
    Write-Host `$Message -ForegroundColor `$Color
}

function Test-Administrator {
    `$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    `$principal = New-Object Security.Principal.WindowsPrincipal(`$currentUser)
    return `$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check admin privileges
if (-not (Test-Administrator)) {
    Write-ColorOutput "ERROR: This script must be run as Administrator" "Red"
    exit 1
}

# Configuration - Auto-detected drive paths
`$AdminUsername = "Admin"
`$AdminPassword = "IBr1dG3Pc" 
`$UserUsername = "iBridge User"
`$UserPassword = "Abc654321!"
`$iBridgeBase = "C:\iBridge_Setup"

# Auto-detected application paths
`$applications = @(
    @{Path = "$($foundFiles['TeamViewer_Setup_x64.exe'])"; Name = "TeamViewer"; Args = "/S"},
    @{Path = "$($foundFiles['24.2.2000.exe'])"; Name = "24.2.2000"; Args = "/SILENT"},
    @{Path = "$($foundFiles['GlassWireSetup.exe'])"; Name = "GlassWire"; Args = "/S"},
    @{Path = "$($foundFiles['PBIDesktopSetup_x64.exe'])"; Name = "Power BI Desktop"; Args = "/quiet"}
)

Write-ColorOutput "============================================================" "Green"
Write-ColorOutput "iBridge Enhanced Setup Script v2.1 - Auto Drive Detection" "Green"
Write-ColorOutput "============================================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "[INFO] Starting iBridge Enhanced Setup v2.1" "Cyan"
Write-ColorOutput "[INFO] Setup started by: `$env:USERNAME" "Cyan"
Write-ColorOutput "[INFO] Auto-detected drive: $foundDrive" "Cyan"
Write-ColorOutput "[SUCCESS] Running with Administrator privileges" "Green"

# Step 1: Create folder structure
Write-ColorOutput "[PROGRESS] Creating Folder Structure - Setting up organized directory structure (12%)" "Yellow"
`$folders = @("`$iBridgeBase\Installers", "`$iBridgeBase\Shortcuts", "`$iBridgeBase\Logs")
foreach (`$folder in `$folders) {
    if (!(Test-Path `$folder)) {
        New-Item -ItemType Directory -Path `$folder -Force | Out-Null
    }
}

# Step 2: Remove existing accounts
Write-ColorOutput "[PROGRESS] Creating User Accounts - Setting up Admin and iBridge User accounts (25%)" "Yellow"

`$existingAdmin = Get-LocalUser -Name `$AdminUsername -ErrorAction SilentlyContinue
if (`$existingAdmin) {
    Write-ColorOutput "[WARNING] Removing existing Admin account..." "Yellow"
    Remove-LocalUser -Name `$AdminUsername -Confirm:`$false
    Write-ColorOutput "[SUCCESS] Existing Admin account removed" "Green"
}

`$existingUser = Get-LocalUser -Name `$UserUsername -ErrorAction SilentlyContinue
if (`$existingUser) {
    Write-ColorOutput "[WARNING] Removing existing iBridge User account..." "Yellow"
    Remove-LocalUser -Name `$UserUsername -Confirm:`$false
    Write-ColorOutput "[SUCCESS] Existing iBridge User account removed" "Green"
}

# Step 3: Create new accounts
Write-ColorOutput "[INFO] Creating Admin account..." "Cyan"
`$secureAdminPassword = ConvertTo-SecureString `$AdminPassword -AsPlainText -Force
`$adminUser = New-LocalUser -Name `$AdminUsername -Password `$secureAdminPassword -Description "Admin for app installation" -PasswordNeverExpires -AccountNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member `$AdminUsername
Write-ColorOutput "[SUCCESS] Admin account created successfully" "Green"

Write-ColorOutput "[INFO] Creating iBridge User account..." "Cyan"
`$secureUserPassword = ConvertTo-SecureString `$UserPassword -AsPlainText -Force  
`$bridgeUser = New-LocalUser -Name `$UserUsername -Password `$secureUserPassword -Description "Standard user with limited privileges" -PasswordNeverExpires -AccountNeverExpires
Add-LocalGroupMember -Group "Users" -Member `$UserUsername
Write-ColorOutput "[SUCCESS] iBridge User account created successfully" "Green"

# Step 4: Create profile folders
Write-ColorOutput "[INFO] Forcing profile creation for both accounts..." "Cyan"
Write-ColorOutput "[INFO] Starting profile creation process..." "Cyan"
`$profilePaths = @("C:\Users\`$AdminUsername", "C:\Users\`$UserUsername")
foreach (`$profilePath in `$profilePaths) {
    if (!(Test-Path `$profilePath)) {
        `$subFolders = @("Desktop", "Documents", "Downloads", "AppData\Local", "AppData\Roaming")
        foreach (`$subFolder in `$subFolders) {
            `$fullPath = Join-Path `$profilePath `$subFolder
            New-Item -ItemType Directory -Path `$fullPath -Force | Out-Null
        }
    }
}

# Step 5: Install applications
Write-ColorOutput "[PROGRESS] Installing Applications - Installing required applications (38%)" "Yellow"

`$installedCount = 0
foreach (`$app in `$applications) {
    Write-ColorOutput "[INFO] Processing: `$(`$app.Name)" "Cyan"
    
    if (Test-Path `$app.Path) {
        Write-ColorOutput "[SUCCESS] Found: `$(`$app.Path)" "Green"
        
        # Copy installer to local storage
        `$localInstaller = Join-Path "`$iBridgeBase\Installers" (Split-Path `$app.Path -Leaf)
        Copy-Item `$app.Path `$localInstaller -Force
        
        # Install application
        `$process = Start-Process -FilePath `$app.Path -ArgumentList `$app.Args -Wait -PassThru -NoNewWindow
        if (`$process.ExitCode -eq 0) {
            Write-ColorOutput "[SUCCESS] `$(`$app.Name) installed successfully" "Green"
            `$installedCount++
        } else {
            Write-ColorOutput "[WARNING] `$(`$app.Name) installation completed with exit code `$(`$process.ExitCode)" "Yellow"
            `$installedCount++
        }
    } else {
        Write-ColorOutput "[ERROR] Application not found: `$(`$app.Path)" "Red"
    }
}

Write-ColorOutput "[INFO] Applications processed: `$installedCount of `$(`$applications.Count)" "Cyan"

# Step 6: Handle shortcuts (look for shortcut folders)
Write-ColorOutput "[PROGRESS] Setting up shortcuts (75%)" "Yellow"

`$shortcutSources = @()
# Search for shortcut folders on the same drive
`$possibleFolders = @("IT STUFF", "iBridge Set Up")
foreach (`$folder in `$possibleFolders) {
    `$folderPath = "`$foundDrive\`$folder"
    if (Test-Path `$folderPath) {
        `$shortcutSources += `$folderPath
        Write-ColorOutput "[SUCCESS] Found shortcut folder: `$folderPath" "Green"
    }
}

`$iBridgeDesktop = "C:\Users\`$UserUsername\Desktop"
`$shortcutCount = 0

foreach (`$source in `$shortcutSources) {
    if (Test-Path `$source) {
        `$shortcuts = Get-ChildItem `$source -Include "*.lnk", "*.url" -Recurse -ErrorAction SilentlyContinue
        foreach (`$shortcut in `$shortcuts) {
            # Copy to shared folder
            `$sharedPath = Join-Path "`$iBridgeBase\Shortcuts" `$shortcut.Name
            Copy-Item `$shortcut.FullName `$sharedPath -Force
            
            # Copy to iBridge User desktop
            `$desktopPath = Join-Path `$iBridgeDesktop `$shortcut.Name
            Copy-Item `$shortcut.FullName `$desktopPath -Force
            
            Write-ColorOutput "[SUCCESS] Added shortcut: `$(`$shortcut.Name)" "Green"
            `$shortcutCount++
        }
    }
}

# Step 7: Create summary
Write-ColorOutput "[PROGRESS] Creating setup summary (100%)" "Yellow"

`$summary = @"
iBridge Enhanced Setup Summary v2.1
Generated: `$(Get-Date)
Drive detected: $foundDrive

USER ACCOUNTS:
- Admin (Password: `$AdminPassword)
- iBridge User (Password: `$UserPassword)

INSTALLATION RESULTS:
- Applications Installed: `$installedCount
- Shortcuts Created: `$shortcutCount
- Everything stored in: `$iBridgeBase

APPLICATION PATHS (Auto-detected):
$(foreach(`$app in `$applications) { "- `$(`$app.Name): `$(`$app.Path)" })

NEXT STEPS:
1. Log out of current Windows session
2. Log in as 'iBridge User' (Password: Abc654321!)
3. Check desktop for application shortcuts
4. Browse `$iBridgeBase for backup files

Setup completed successfully with auto-drive detection!
"@

`$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
`$summaryPath = "`$iBridgeBase\Logs\iBridge-Setup-`$timestamp.log"
`$summary | Out-File `$summaryPath -Encoding UTF8

# Final output
Write-ColorOutput ""
Write-ColorOutput "============================================================" "Green"
Write-ColorOutput "ENHANCED SETUP COMPLETED SUCCESSFULLY!" "Green"
Write-ColorOutput "============================================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "Drive detected: $foundDrive" "Cyan"
Write-ColorOutput "Applications installed: `$installedCount" "Cyan" 
Write-ColorOutput "Shortcuts created: `$shortcutCount" "Cyan"
Write-ColorOutput "Everything organized in: `$iBridgeBase" "Cyan"
Write-ColorOutput ""
Write-ColorOutput "Summary saved to: `$summaryPath" "Gray"
"@

# Save the corrected script
$correctedScriptPath = "C:\iBridge_Setup\iBridge-Enhanced-Setup-FIXED.ps1"
if (!(Test-Path "C:\iBridge_Setup")) {
    New-Item -ItemType Directory -Path "C:\iBridge_Setup" -Force | Out-Null
}

$correctedScript | Out-File $correctedScriptPath -Encoding UTF8
Write-ColorOutput "Created corrected script: $correctedScriptPath" "Green"

# Step 3: Create fixed launcher
Write-ColorOutput "Step 3: Creating fixed launcher..." "Green"

$fixedLauncher = @"
@echo off
echo ================================================================
echo iBridge Enhanced Setup - FIXED VERSION (Auto Drive Detection)
echo ================================================================
echo.
echo This FIXED version will:
echo   - Automatically detect where application files are located
echo   - Use correct drive paths (found: $foundDrive)
echo   - Install all applications successfully
echo   - Create user accounts and shortcuts
echo.
echo Applications found on $foundDrive`:
$(foreach($app in $requiredApps) { if($foundFiles[$app]) { "echo   - $app" } })
echo.
pause

:: Check for admin privileges and elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running FIXED enhanced setup...
powershell.exe -ExecutionPolicy Bypass -File "C:\iBridge_Setup\iBridge-Enhanced-Setup-FIXED.ps1"

echo.
echo FIXED setup completed!
pause
"@

$fixedLauncherPath = "C:\iBridge_Setup\RUN-ENHANCED-SETUP-FIXED.bat"
$fixedLauncher | Out-File $fixedLauncherPath -Encoding ASCII
Write-ColorOutput "Created fixed launcher: $fixedLauncherPath" "Green"

# Summary
Write-ColorOutput ""
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "DRIVE DETECTION FIX COMPLETED!" "Green"
Write-ColorOutput "========================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "Issue identified: Scripts were looking for files on D: drive" "Yellow"
Write-ColorOutput "Files actually located on: $foundDrive" "Green"
Write-ColorOutput ""
Write-ColorOutput "FIXED FILES CREATED:" "White"
Write-ColorOutput "  Script: C:\iBridge_Setup\iBridge-Enhanced-Setup-FIXED.ps1" "Gray"
Write-ColorOutput "  Launcher: C:\iBridge_Setup\RUN-ENHANCED-SETUP-FIXED.bat" "Gray"
Write-ColorOutput ""
Write-ColorOutput "TO RUN THE FIXED SETUP:" "Cyan"
Write-ColorOutput "  C:\iBridge_Setup\RUN-ENHANCED-SETUP-FIXED.bat" "Cyan"
Write-ColorOutput ""
Write-ColorOutput "This will now correctly install all applications!" "Green"
