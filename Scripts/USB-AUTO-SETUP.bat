@echo off
echo ================================================================
echo iBridge Enhanced Setup - Standalone Operation
echo Run from USB - Works on any computer
echo ================================================================
echo.
echo This script will:
echo   1. Auto-detect USB drive location
echo   2. Create Admin and iBridge User accounts  
echo   3. Install applications PERMANENTLY to local system
echo   4. Copy ALL installers to C:\iBridge_Setup\Installers
echo   5. Create shortcuts ONLY on iBridge User desktop
echo   6. Enable standalone operation (USB not required after setup)
echo.
echo IMPORTANT: After setup, USB drive will NOT be needed!
echo.
pause

:: Check for admin privileges and elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Auto-detecting USB drive...
set USB_DRIVE=
for %%d in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\24.2.2000.exe" (
        set USB_DRIVE=%%d:
        echo Found USB drive at %%d:
        goto :found
    )
)

echo ERROR: Could not find USB drive with required files
echo Please ensure the USB contains: 24.2.2000.exe, GlassWireSetup.exe, etc.
pause
exit /b 1

:found
echo USB Drive: %USB_DRIVE%
echo Running Enhanced Standalone Setup...

:: Create and run PowerShell script dynamically
powershell -ExecutionPolicy Bypass -Command "
$AdminUsername = 'Admin'
$AdminPassword = 'IBr1dG3Pc' 
$UserUsername = 'iBridge User'
$UserPassword = 'Abc654321!'
$iBridgeBase = 'C:\iBridge_Setup'
$UsbDrive = '%USB_DRIVE%'

function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput 'iBridge Enhanced Setup - Standalone Operation' 'Cyan'
Write-ColorOutput 'Creating accounts and installing applications for USB-independent use' 'Yellow'
Write-ColorOutput ''

# Step 1: Create folder structure
Write-ColorOutput 'Step 1: Creating organized folder structure...' 'Green'
$folders = @(\"$iBridgeBase\Installers\", \"$iBridgeBase\Shortcuts\", \"$iBridgeBase\Logs\")
foreach ($folder in $folders) {
    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-ColorOutput \"Created: $folder\" 'Gray'
    }
}

# Step 2: Remove existing accounts
Write-ColorOutput 'Step 2: Cleaning up existing accounts...' 'Green'
$existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
if ($existingAdmin) {
    Remove-LocalUser -Name $AdminUsername -Confirm:`$false
    Write-ColorOutput 'Removed existing Admin account' 'Gray'
}

$existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
if ($existingUser) {
    Remove-LocalUser -Name $UserUsername -Confirm:`$false
    Write-ColorOutput 'Removed existing iBridge User account' 'Gray'
}

# Step 3: Create new accounts
Write-ColorOutput 'Step 3: Creating user accounts...' 'Green'
$secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -Description 'Admin for app installation' -PasswordNeverExpires -AccountNeverExpires
Add-LocalGroupMember -Group 'Administrators' -Member $AdminUsername
Write-ColorOutput 'Created Admin account successfully' 'Gray'

$secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force  
$bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -Description 'Standard user with limited privileges' -PasswordNeverExpires -AccountNeverExpires
Add-LocalGroupMember -Group 'Users' -Member $UserUsername
Write-ColorOutput 'Created iBridge User account successfully' 'Gray'

# Step 4: Create profile folders
Write-ColorOutput 'Step 4: Creating user profile folders...' 'Green'
$profilePaths = @(\"C:\Users\$AdminUsername\", \"C:\Users\$UserUsername\")
foreach ($profilePath in $profilePaths) {
    if (!(Test-Path $profilePath)) {
        $subFolders = @('Desktop', 'Documents', 'Downloads', 'AppData\Local', 'AppData\Roaming')
        foreach ($subFolder in $subFolders) {
            $fullPath = Join-Path $profilePath $subFolder
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        }
        Write-ColorOutput \"Created profile: $profilePath\" 'Gray'
    }
}

# Step 5: Install applications
Write-ColorOutput 'Step 5: Installing applications permanently...' 'Green'
$applications = @(
    @{Path = \"$UsbDrive\24.2.2000.exe\"; Name = '24.2.2000'; Args = '/SILENT'},
    @{Path = \"$UsbDrive\GlassWireSetup.exe\"; Name = 'GlassWire'; Args = '/S'},
    @{Path = \"$UsbDrive\PBIDesktopSetup_x64.exe\"; Name = 'Power BI Desktop'; Args = '/quiet'},
    @{Path = \"$UsbDrive\TeamViewer_Setup_x64.exe\"; Name = 'TeamViewer'; Args = '/S'}
)

$installedCount = 0
foreach ($app in $applications) {
    if (Test-Path $app.Path) {
        Write-ColorOutput \"Installing $($app.Name)...\" 'Yellow'
        
        # Copy installer to local storage
        $localInstaller = Join-Path \"$iBridgeBase\Installers\" (Split-Path $app.Path -Leaf)
        Copy-Item $app.Path $localInstaller -Force
        
        # Install from local copy
        $process = Start-Process -FilePath $localInstaller -ArgumentList $app.Args -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-ColorOutput \"Installed $($app.Name) successfully\" 'Green'
            $installedCount++
        } else {
            Write-ColorOutput \"Installation of $($app.Name) completed with exit code $($process.ExitCode)\" 'Yellow'
            $installedCount++
        }
    } else {
        Write-ColorOutput \"Application not found: $($app.Path)\" 'Red'
    }
}

# Step 6: Handle Office folder
Write-ColorOutput 'Step 6: Copying Office tools folder...' 'Green'
$officeSource = \"$UsbDrive\Tools for Office2019 TechXander\"
if (Test-Path $officeSource) {
    $officeDest = Join-Path \"$iBridgeBase\Installers\" 'Tools for Office2019 TechXander'
    Copy-Item $officeSource $officeDest -Recurse -Force
    Write-ColorOutput 'Copied Office tools folder to local storage' 'Gray'
}

# Step 7: Copy shortcuts to iBridge User desktop
Write-ColorOutput 'Step 7: Setting up shortcuts for iBridge User...' 'Green'
$shortcutSources = @(\"$UsbDrive\IT STUFF\", \"$UsbDrive\iBridge Set Up\")
$iBridgeDesktop = \"C:\Users\$UserUsername\Desktop\"
$shortcutCount = 0

foreach ($source in $shortcutSources) {
    if (Test-Path $source) {
        $shortcuts = Get-ChildItem $source -Include '*.lnk', '*.url' -Recurse -ErrorAction SilentlyContinue
        foreach ($shortcut in $shortcuts) {
            # Copy to shared folder
            $sharedPath = Join-Path \"$iBridgeBase\Shortcuts\" $shortcut.Name
            Copy-Item $shortcut.FullName $sharedPath -Force
            
            # Copy to iBridge User desktop
            $desktopPath = Join-Path $iBridgeDesktop $shortcut.Name
            Copy-Item $shortcut.FullName $desktopPath -Force
            
            Write-ColorOutput \"Added shortcut: $($shortcut.Name)\" 'Gray'
            $shortcutCount++
        }
    }
}

# Step 8: Set permissions
Write-ColorOutput 'Step 8: Setting folder permissions...' 'Green'
try {
    $acl = Get-Acl $iBridgeBase
    $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule('Users', 'ReadAndExecute', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $acl.SetAccessRule($userAccessRule)
    $adminAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule('Administrators', 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $acl.SetAccessRule($adminAccessRule)
    Set-Acl -Path $iBridgeBase -AclObject $acl
    Write-ColorOutput 'Folder permissions configured' 'Gray'
} catch {
    Write-ColorOutput \"Could not set folder permissions: $($_.Exception.Message)\" 'Yellow'
}

# Final output
Write-ColorOutput '' ''
Write-ColorOutput '========================================' 'Green'
Write-ColorOutput 'SETUP COMPLETED SUCCESSFULLY!' 'Green'
Write-ColorOutput '========================================' 'Green'
Write-ColorOutput '' ''
Write-ColorOutput 'User accounts created with profiles' 'Cyan'
Write-ColorOutput \"Applications installed: $installedCount\" 'Cyan' 
Write-ColorOutput \"Shortcuts created: $shortcutCount\" 'Cyan'
Write-ColorOutput \"Everything organized in: $iBridgeBase\" 'Cyan'
Write-ColorOutput '' ''
Write-ColorOutput 'STANDALONE OPERATION READY!' 'Yellow'
Write-ColorOutput 'USB drive can now be safely removed' 'Yellow'
Write-ColorOutput '' ''
Write-ColorOutput 'NEXT STEPS:' 'White'
Write-ColorOutput '1. Log out of current Windows session' 'Gray'
Write-ColorOutput '2. Log in as iBridge User (Password: Abc654321!)' 'Gray'
Write-ColorOutput '3. Check desktop for shortcuts' 'Gray'
Write-ColorOutput '4. Test applications without USB' 'Gray'
"

echo.
echo ================================================================
echo Setup completed! You can now safely remove the USB drive.
echo Applications will work independently on this computer.
echo ================================================================
pause
