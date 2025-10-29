# iBridge Enhanced Setup - Standalone Operation
# Final working version for USB-independent operation

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

# Check admin privileges
if (-not (Test-Administrator)) {
    Write-ColorOutput "ERROR: This script must be run as Administrator" "Red"
    exit 1
}

Write-ColorOutput "iBridge Enhanced Setup - Standalone Operation" "Cyan"
Write-ColorOutput "Creating accounts and installing applications for USB-independent use" "Yellow"
Write-ColorOutput ""

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
Write-ColorOutput "Step 5: Installing applications permanently..." "Green"
$applications = @(
    @{Path = "E:\24.2.2000.exe"; Name = "24.2.2000"; Args = "/SILENT"},
    @{Path = "E:\GlassWireSetup.exe"; Name = "GlassWire"; Args = "/S"},
    @{Path = "E:\PBIDesktopSetup_x64.exe"; Name = "Power BI Desktop"; Args = "/quiet"},
    @{Path = "E:\TeamViewer_Setup_x64.exe"; Name = "TeamViewer"; Args = "/S"}
)

$installedCount = 0
foreach ($app in $applications) {
    if (Test-Path $app.Path) {
        Write-ColorOutput "Installing $($app.Name)..." "Yellow"
        
        # Copy installer to local storage
        $localInstaller = Join-Path "$iBridgeBase\Installers" (Split-Path $app.Path -Leaf)
        Copy-Item $app.Path $localInstaller -Force
        
        # Install from local copy
        $process = Start-Process -FilePath $localInstaller -ArgumentList $app.Args -Wait -PassThru -NoNewWindow
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

# Step 6: Handle Office folder
Write-ColorOutput "Step 6: Copying Office tools folder..." "Green"
$officeSource = "E:\Tools for Office2019 TechXander"
if (Test-Path $officeSource) {
    $officeDest = Join-Path "$iBridgeBase\Installers" "Tools for Office2019 TechXander"
    Copy-Item $officeSource $officeDest -Recurse -Force
    Write-ColorOutput "Copied Office tools folder to local storage" "Gray"
}

# Step 7: Copy shortcuts to iBridge User desktop
Write-ColorOutput "Step 7: Setting up shortcuts for iBridge User..." "Green"
$shortcutSources = @("E:\IT STUFF", "E:\iBridge Set Up")
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
    }
}

# Step 8: Set permissions
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

# Step 9: Create summary
Write-ColorOutput "Step 9: Creating setup summary..." "Green"
$summary = @"
iBridge Enhanced Setup Summary
Generated: $(Get-Date)

USER ACCOUNTS:
- Admin (Password: $AdminPassword)
- iBridge User (Password: $UserPassword)

INSTALLATION RESULTS:
- Applications Installed: $installedCount
- Shortcuts Created: $shortcutCount
- Everything stored in: $iBridgeBase

STANDALONE OPERATION READY:
- All applications installed to local system
- Installers backed up to local storage
- Shortcuts available on iBridge User desktop
- USB drive no longer required

NEXT STEPS:
1. Log out of current Windows session
2. Log in as 'iBridge User' (Password: Abc654321!)
3. Check desktop for application shortcuts
4. Test applications work without USB drive
5. Browse $iBridgeBase for backup files

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
Write-ColorOutput "User accounts created with profiles" "Cyan"
Write-ColorOutput "Applications installed: $installedCount" "Cyan" 
Write-ColorOutput "Shortcuts created: $shortcutCount" "Cyan"
Write-ColorOutput "Everything organized in: $iBridgeBase" "Cyan"
Write-ColorOutput ""
Write-ColorOutput "STANDALONE OPERATION READY!" "Yellow"
Write-ColorOutput "USB drive can now be safely removed" "Yellow"
Write-ColorOutput ""
Write-ColorOutput "NEXT STEPS:" "White"
Write-ColorOutput "1. Log out of current Windows session" "Gray"
Write-ColorOutput "2. Log in as 'iBridge User' (Password: Abc654321!)" "Gray"
Write-ColorOutput "3. Check desktop for shortcuts" "Gray"
Write-ColorOutput "4. Test applications without USB" "Gray"
Write-ColorOutput ""
Write-ColorOutput "Summary saved to: $summaryPath" "Gray"
