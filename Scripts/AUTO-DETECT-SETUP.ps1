# Auto-Detecting Enhanced Setup - Uses Local or USB Files
# Automatically finds the best file source

param([switch]$SkipValidation)

$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc" 
$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-ApplicationFiles {
    Write-ColorOutput "Auto-detecting application file locations..." "Yellow"
    
    # Priority search order: Local disk first, then USB drives
    $searchPaths = @(
        "C:\iBridge_Local_Setup\Installers",  # Local disk (highest priority)
        "E:\",                                # USB drive E:
        "F:\",                                # USB drive F:
        "D:\",                                # USB drive D:
        "G:\"                                 # USB drive G:
    )
    
    $applications = @(
        @{File = "24.2.2000.exe"; Name = "24.2.2000"; Args = "/SILENT"; Found = $false; Path = ""},
        @{File = "GlassWireSetup.exe"; Name = "GlassWire"; Args = "/S"; Found = $false; Path = ""},
        @{File = "PBIDesktopSetup_x64.exe"; Name = "Power BI Desktop"; Args = "/quiet"; Found = $false; Path = ""},
        @{File = "TeamViewer_Setup_x64.exe"; Name = "TeamViewer"; Args = "/S"; Found = $false; Path = ""}
    )
    
    foreach ($searchPath in $searchPaths) {
        if (Test-Path $searchPath) {
            Write-ColorOutput "Checking: $searchPath" "Gray"
            
            foreach ($app in $applications) {
                if (!$app.Found) {
                    $fullPath = Join-Path $searchPath $app.File
                    if (Test-Path $fullPath) {
                        $app.Found = $true
                        $app.Path = $fullPath
                        Write-ColorOutput "  Found: $($app.Name) at $fullPath" "Green"
                    }
                }
            }
        }
    }
    
    $foundCount = ($applications | Where-Object {$_.Found}).Count
    Write-ColorOutput ""
    Write-ColorOutput "Application Detection Summary:" "Cyan"
    Write-ColorOutput "Found $foundCount of $($applications.Count) applications" "Yellow"
    
    return $applications
}

function Find-ShortcutFolders {
    Write-ColorOutput "Auto-detecting shortcut folder locations..." "Yellow"
    
    $searchPaths = @(
        "C:\iBridge_Local_Setup",  # Local disk
        "E:\",                     # USB drives
        "F:\",
        "D:\",
        "G:\"
    )
    
    $shortcutFolders = @()
    $targetFolders = @("IT STUFF", "iBridge Set Up")
    
    foreach ($searchPath in $searchPaths) {
        if (Test-Path $searchPath) {
            foreach ($folder in $targetFolders) {
                $fullPath = Join-Path $searchPath $folder
                if (Test-Path $fullPath) {
                    $shortcutFolders += $fullPath
                    Write-ColorOutput "  Found shortcut folder: $fullPath" "Green"
                }
            }
        }
    }
    
    return $shortcutFolders
}

# Check admin privileges
if (-not (Test-Administrator)) {
    Write-ColorOutput "ERROR: This script must be run as Administrator" "Red"
    exit 1
}

Write-ColorOutput "iBridge Auto-Detecting Enhanced Setup" "Cyan"
Write-ColorOutput "Automatically finds files on local disk or USB drives" "Yellow"
Write-ColorOutput ""

# Detect file locations
$applications = Find-ApplicationFiles
$shortcutFolders = Find-ShortcutFolders

if (($applications | Where-Object {$_.Found}).Count -eq 0) {
    Write-ColorOutput "ERROR: No application files found!" "Red"
    Write-ColorOutput "Please ensure files are available on local disk or USB drive" "Yellow"
    exit 1
}

# Setup process
$iBridgeBase = "C:\iBridge_Setup"

# Step 1: Create folder structure
Write-ColorOutput "Step 1: Creating organized folder structure..." "Green"
$folders = @("$iBridgeBase\Installers", "$iBridgeBase\Shortcuts", "$iBridgeBase\Logs")
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

# Step 5: Install applications
Write-ColorOutput "Step 5: Installing applications..." "Green"
$installedCount = 0

foreach ($app in $applications) {
    if ($app.Found) {
        Write-ColorOutput "Installing $($app.Name) from $($app.Path)..." "Yellow"
        
        # Copy installer to local storage
        $localInstaller = Join-Path "$iBridgeBase\Installers" $app.File
        Copy-Item $app.Path $localInstaller -Force
        
        # Install from detected location
        $process = Start-Process -FilePath $app.Path -ArgumentList $app.Args -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-ColorOutput "Installed $($app.Name) successfully" "Green"
            $installedCount++
        } else {
            Write-ColorOutput "Installation of $($app.Name) completed with exit code $($process.ExitCode)" "Yellow"
            $installedCount++
        }
    } else {
        Write-ColorOutput "Skipping $($app.Name) - not found" "Red"
    }
}

# Step 6: Handle Office folder
Write-ColorOutput "Step 6: Handling Office tools..." "Green"
$officeFound = $false
$officePaths = @(
    "C:\iBridge_Local_Setup\Installers\Tools for Office2019 TechXander",
    "E:\Tools for Office2019 TechXander",
    "F:\Tools for Office2019 TechXander",
    "D:\Tools for Office2019 TechXander"
)

foreach ($officePath in $officePaths) {
    if (Test-Path $officePath) {
        $officeDest = Join-Path "$iBridgeBase\Installers" "Tools for Office2019 TechXander"
        Copy-Item $officePath $officeDest -Recurse -Force
        Write-ColorOutput "Copied Office tools from $officePath" "Gray"
        $officeFound = $true
        break
    }
}

if (!$officeFound) {
    Write-ColorOutput "Office tools folder not found" "Yellow"
}

# Step 7: Copy shortcuts
Write-ColorOutput "Step 7: Setting up shortcuts for iBridge User..." "Green"
$iBridgeDesktop = "C:\Users\$UserUsername\Desktop"
$shortcutCount = 0

foreach ($source in $shortcutFolders) {
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
    }
}

# Step 8: Set permissions
Write-ColorOutput "Step 8: Setting folder permissions..." "Green"
try {
    $acl = Get-Acl $iBridgeBase
    $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($userAccessRule)
    Set-Acl -Path $iBridgeBase -AclObject $acl
    Write-ColorOutput "Folder permissions configured" "Gray"
} catch {
    Write-ColorOutput "Could not set folder permissions: $($_.Exception.Message)" "Yellow"
}

# Create summary
$detectedSources = @()
foreach ($app in $applications) {
    if ($app.Found) {
        $source = Split-Path $app.Path -Parent
        if ($detectedSources -notcontains $source) {
            $detectedSources += $source
        }
    }
}

$summary = @"
iBridge Auto-Detecting Setup Summary
Generated: $(Get-Date)

FILE DETECTION:
Sources detected: $($detectedSources -join ', ')
Applications found: $($applications | Where-Object {$_.Found} | Measure-Object).Count of $($applications.Count)

USER ACCOUNTS:
- Admin (Password: $AdminPassword)
- iBridge User (Password: $UserPassword)

INSTALLATION RESULTS:
- Applications Installed: $installedCount
- Shortcuts Created: $shortcutCount
- Office Tools: $(if($officeFound){'Found and copied'}else{'Not found'})
- Everything stored in: $iBridgeBase

NEXT STEPS:
1. Log out of current Windows session
2. Log in as 'iBridge User' (Password: Abc654321!)
3. Check desktop for application shortcuts
4. Test applications work properly
5. Browse $iBridgeBase for backup files

Auto-detection setup completed successfully!
"@

$summaryPath = Join-Path $iBridgeBase "AUTO-DETECT-SUMMARY.txt"
$summary | Out-File $summaryPath -Encoding UTF8

# Final output
Write-ColorOutput ""
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "AUTO-DETECTING SETUP COMPLETED!" "Green"
Write-ColorOutput "========================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "File sources detected: $($detectedSources.Count)" "Cyan"
Write-ColorOutput "Applications installed: $installedCount" "Cyan" 
Write-ColorOutput "Shortcuts created: $shortcutCount" "Cyan"
Write-ColorOutput "Everything organized in: $iBridgeBase" "Cyan"
Write-ColorOutput ""
Write-ColorOutput "NEXT STEPS:" "White"
Write-ColorOutput "1. Log out of current Windows session" "Gray"
Write-ColorOutput "2. Log in as 'iBridge User' (Password: Abc654321!)" "Gray"
Write-ColorOutput "3. Check desktop for shortcuts" "Gray"
Write-ColorOutput "4. Test applications" "Gray"
Write-ColorOutput ""
Write-ColorOutput "Summary saved to: $summaryPath" "Gray"
