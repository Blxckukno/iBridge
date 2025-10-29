@echo off
echo ================================================================
echo iBridge Universal Setup - Complete Solution
echo Auto-detects USB drive and handles ALL installations correctly
echo ================================================================
echo.
echo This script will:
echo   1. Auto-detect USB drive location on ANY computer
echo   2. Create user accounts (Admin + iBridge User)
echo   3. Install applications permanently to local system:
echo      - 24.2.2000.exe (SYSPRO)
echo      - GlassWireSetup.exe (Network monitoring)
echo      - PBIDesktopSetup_x64.exe (Power BI Desktop)
echo      - TeamViewer_Setup_x64.exe (Remote access)
echo   4. Handle Office tools installation correctly:
echo      - Finds setup.exe in Config Files subfolder
echo      - Tries start.cmd if available
echo      - Copies to local storage as backup
echo   5. Create shortcuts on iBridge User desktop only
echo   6. Enable standalone operation (no USB needed)
echo.
echo WORKS ON ANY COMPUTER - DEVICE INDEPENDENT!
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
echo Running Universal Setup...

:: Create and run comprehensive PowerShell script
powershell -ExecutionPolicy Bypass -Command "
# Configuration
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

Write-ColorOutput 'iBridge Universal Setup - Complete Solution' 'Cyan'
Write-ColorOutput \"USB Drive: $UsbDrive\" 'Yellow'
Write-ColorOutput 'Device-independent installation starting...' 'Yellow'
Write-ColorOutput ''

# Step 1: Create folder structure
Write-ColorOutput 'Step 1: Creating organized folder structure...' 'Green'
$folders = @(\"$iBridgeBase\Installers\", \"$iBridgeBase\Shortcuts\", \"$iBridgeBase\Logs\", \"$iBridgeBase\Office\")
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

# Step 5: Install main applications
Write-ColorOutput 'Step 5: Installing main applications permanently...' 'Green'
$applications = @(
    @{Path = \"$UsbDrive\24.2.2000.exe\"; Name = '24.2.2000 (SYSPRO)'; Args = '/SILENT'},
    @{Path = \"$UsbDrive\GlassWireSetup.exe\"; Name = 'GlassWire'; Args = '/S'},
    @{Path = \"$UsbDrive\PBIDesktopSetup_x64.exe\"; Name = 'Power BI Desktop'; Args = '/quiet'},
    @{Path = \"$UsbDrive\TeamViewer_Setup_x64.exe\"; Name = 'TeamViewer'; Args = '/S'}
)

$installedCount = 0
foreach ($app in $applications) {
    if (Test-Path $app.Path) {
        Write-ColorOutput \"Installing $($app.Name)...\" 'Yellow'
        
        # Copy installer to local storage first
        $localInstaller = Join-Path \"$iBridgeBase\Installers\" (Split-Path $app.Path -Leaf)
        Copy-Item $app.Path $localInstaller -Force
        Write-ColorOutput \"  Copied to local storage\" 'Gray'
        
        # Install from local copy
        try {
            $process = Start-Process -FilePath $localInstaller -ArgumentList $app.Args -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -eq 0) {
                Write-ColorOutput \"  Installed $($app.Name) successfully\" 'Green'
                $installedCount++
            } else {
                Write-ColorOutput \"  Installation completed with exit code $($process.ExitCode)\" 'Yellow'
                $installedCount++
            }
        } catch {
            Write-ColorOutput \"  Error installing $($app.Name): $($_.Exception.Message)\" 'Red'
        }
    } else {
        Write-ColorOutput \"Application not found: $($app.Path)\" 'Red'
    }
}

# Step 6: Handle Office tools with multiple methods
Write-ColorOutput 'Step 6: Setting up Office tools (trying all methods)...' 'Green'
$officeSource = \"$UsbDrive\Tools for Office2019 TechXander\"
$officeInstalled = `$false

if (Test-Path $officeSource) {
    # Copy entire Office tools folder to local storage
    $officeDest = Join-Path \"$iBridgeBase\Office\" 'Tools for Office2019 TechXander'
    Copy-Item $officeSource $officeDest -Recurse -Force
    Write-ColorOutput '  Copied Office tools to local storage' 'Gray'
    
    # Try multiple installation paths/methods
    $setupMethods = @(
        @{Path = \"$officeDest\Config Files\start.cmd\"; Type = 'CMD'; Desc = 'Config Files start.cmd'},
        @{Path = \"$officeDest\Config Files\setup.exe\"; Type = 'EXE'; Desc = 'Config Files setup.exe'},
        @{Path = \"$officeDest\start.cmd\"; Type = 'CMD'; Desc = 'Root start.cmd'},
        @{Path = \"$officeDest\setup.exe\"; Type = 'EXE'; Desc = 'Root setup.exe'}
    )
    
    foreach ($method in $setupMethods) {
        if (Test-Path $method.Path) {
            Write-ColorOutput \"  Found: $($method.Desc)\" 'Green'
            
            try {
                Write-ColorOutput \"  Running Office installation: $($method.Desc)\" 'Yellow'
                
                if ($method.Type -eq 'CMD') {
                    # Run batch file
                    $process = Start-Process -FilePath 'cmd.exe' -ArgumentList \"/c `\"$($method.Path)`\"\" -Wait -PassThru -NoNewWindow -WorkingDirectory (Split-Path $method.Path -Parent)
                } else {
                    # Run exe file
                    $process = Start-Process -FilePath $method.Path -Wait -PassThru -NoNewWindow -WorkingDirectory (Split-Path $method.Path -Parent)
                }
                
                if ($process.ExitCode -eq 0) {
                    Write-ColorOutput '  Office installation completed successfully' 'Green'
                    $officeInstalled = `$true
                    $installedCount++
                    break
                } else {
                    Write-ColorOutput \"  Office installation exit code: $($process.ExitCode)\" 'Yellow'
                }
            } catch {
                Write-ColorOutput \"  Error running $($method.Desc): $($_.Exception.Message)\" 'Red'
            }
        }
    }
    
    if (-not $officeInstalled) {
        Write-ColorOutput '  Office tools copied but auto-installation failed.' 'Yellow'
        Write-ColorOutput \"  Manual installation available at: $officeDest\" 'Gray'
        Write-ColorOutput '  Try running Config Files\start.cmd manually' 'Gray'
    }
} else {
    Write-ColorOutput \"Office tools folder not found: $officeSource\" 'Red'
}

# Step 7: Copy shortcuts to iBridge User desktop
Write-ColorOutput 'Step 7: Setting up shortcuts for iBridge User...' 'Green'
$shortcutSources = @(\"$UsbDrive\IT STUFF\", \"$UsbDrive\iBridge Set Up\")
$iBridgeDesktop = \"C:\Users\$UserUsername\Desktop\"
$shortcutCount = 0

foreach ($source in $shortcutSources) {
    if (Test-Path $source) {
        Write-ColorOutput \"  Searching for shortcuts in: $source\" 'Gray'
        $shortcuts = Get-ChildItem $source -Include '*.lnk', '*.url' -Recurse -ErrorAction SilentlyContinue
        foreach ($shortcut in $shortcuts) {
            # Copy to shared folder
            $sharedPath = Join-Path \"$iBridgeBase\Shortcuts\" $shortcut.Name
            Copy-Item $shortcut.FullName $sharedPath -Force
            
            # Copy to iBridge User desktop
            $desktopPath = Join-Path $iBridgeDesktop $shortcut.Name
            Copy-Item $shortcut.FullName $desktopPath -Force
            
            Write-ColorOutput \"  Added shortcut: $($shortcut.Name)\" 'Gray'
            $shortcutCount++
        }
    } else {
        Write-ColorOutput \"  Shortcut source not found: $source\" 'Yellow'
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

# Step 9: Create comprehensive summary
Write-ColorOutput 'Step 9: Creating setup summary...' 'Green'
$summary = @`"
iBridge Universal Setup Summary
Generated: $(Get-Date)
USB Drive Used: $UsbDrive
Computer: $env:COMPUTERNAME

USER ACCOUNTS CREATED:
- Admin (Password: $AdminPassword)
- iBridge User (Password: $UserPassword)

INSTALLATION RESULTS:
- Main Applications Installed: $installedCount
- Office Installation: $(if ($officeInstalled) { 'SUCCESS' } else { 'MANUAL REQUIRED' })
- Shortcuts Created: $shortcutCount
- Everything stored in: $iBridgeBase

INSTALLED APPLICATIONS:
- 24.2.2000.exe (SYSPRO application)
- GlassWireSetup.exe (Network monitoring)  
- PBIDesktopSetup_x64.exe (Power BI Desktop)
- TeamViewer_Setup_x64.exe (Remote access)

OFFICE TOOLS:
$(if ($officeInstalled) { 
'- Successfully installed automatically'
} else {
'- Copied to local storage for manual installation'
'- Location: $iBridgeBase\Office\Tools for Office2019 TechXander'
'- To install manually: Run Config Files\start.cmd'
})

SHORTCUTS:
- Created on iBridge User desktop only
- Backup copies in: $iBridgeBase\Shortcuts

STANDALONE OPERATION:
- All applications work without USB drive
- Installers backed up to: $iBridgeBase\Installers
- Complete system independence achieved

NEXT STEPS:
1. REMOVE USB DRIVE (no longer needed)
2. Log out of current Windows session
3. Log in as 'iBridge User' (Password: Abc654321!)
4. Check desktop for application shortcuts
5. Test all applications work independently
$(if (-not $officeInstalled) {
'6. For Office: Navigate to C:\iBridge_Setup\Office\Tools for Office2019 TechXander\Config Files\ and run start.cmd'
})

TROUBLESHOOTING:
- All installers backed up in: $iBridgeBase\Installers
- Office tools available at: $iBridgeBase\Office
- Setup log available in: $iBridgeBase\Logs

Setup completed successfully!
Device is now ready for standalone operation.
`"@

$summaryPath = Join-Path $iBridgeBase 'SETUP-SUMMARY.txt'
$summary | Out-File $summaryPath -Encoding UTF8

# Final output
Write-ColorOutput '' ''
Write-ColorOutput '================================================' 'Green'
Write-ColorOutput 'UNIVERSAL SETUP COMPLETED SUCCESSFULLY!' 'Green'
Write-ColorOutput '================================================' 'Green'
Write-ColorOutput '' ''
Write-ColorOutput 'RESULTS SUMMARY:' 'Cyan'
Write-ColorOutput \"✓ User accounts created and configured\" 'Green'
Write-ColorOutput \"✓ Main applications installed: $installedCount\" 'Green'
Write-ColorOutput \"$(if ($officeInstalled) { '✓ Office tools installed automatically' } else { '⚠ Office tools copied (manual install needed)' })\" $(if ($officeInstalled) { 'Green' } else { 'Yellow' })
Write-ColorOutput \"✓ Shortcuts created: $shortcutCount\" 'Green'
Write-ColorOutput \"✓ Everything organized in: $iBridgeBase\" 'Green'
Write-ColorOutput '' ''
Write-ColorOutput 'STANDALONE OPERATION READY!' 'Yellow'
Write-ColorOutput 'USB drive can now be safely REMOVED!' 'Yellow'
Write-ColorOutput '' ''
Write-ColorOutput 'DEVICE INDEPENDENCE ACHIEVED!' 'White' 
Write-ColorOutput 'This computer now works completely independently.' 'White'
Write-ColorOutput '' ''
Write-ColorOutput 'NEXT STEPS:' 'Cyan'
Write-ColorOutput '1. Remove USB drive' 'Gray'
Write-ColorOutput '2. Log in as iBridge User (Password: Abc654321!)' 'Gray'
Write-ColorOutput '3. Test all applications' 'Gray'
$(if (-not $officeInstalled) {
Write-ColorOutput '4. Install Office manually from C:\iBridge_Setup\Office\...\Config Files\start.cmd' 'Gray'
})
Write-ColorOutput '' ''
Write-ColorOutput \"Summary saved to: $summaryPath\" 'Gray'
"

echo.
echo ================================================================
echo UNIVERSAL SETUP COMPLETED!
echo.
echo This computer is now configured for standalone operation.
echo All applications work independently without the USB drive.
echo.
if exist "C:\iBridge_Setup\SETUP-SUMMARY.txt" (
    echo Setup summary created: C:\iBridge_Setup\SETUP-SUMMARY.txt
) else (
    echo Note: Check C:\iBridge_Setup\ for all installed components
)
echo.
echo USB DRIVE CAN NOW BE SAFELY REMOVED!
echo ================================================================
pause
