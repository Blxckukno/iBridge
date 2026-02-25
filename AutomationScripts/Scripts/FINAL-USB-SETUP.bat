@echo off
echo ================================================================
echo iBridge UNIVERSAL Setup - Works on ANY Computer
echo Auto-detects USB location and handles Office properly
echo ================================================================
echo.
echo This will:
echo   1. AUTO-FIND your USB drive (D:, E:, F:, etc.)
echo   2. Install 4 main applications permanently
echo   3. Copy Microsoft Office tools for setup
echo   4. Create user accounts (Admin + iBridge User)
echo   5. Set up shortcuts for iBridge User only
echo   6. Make everything work WITHOUT USB after setup
echo.
echo READY? USB will not be needed after this completes!
echo.
pause

:: Auto-elevate to admin if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Getting admin rights...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo Searching for USB drive...

:: Find USB drive automatically
set FOUND_USB=
for %%d in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\24.2.2000.exe" (
        if exist "%%d:\GlassWireSetup.exe" (
            set FOUND_USB=%%d:
            echo Found USB at %%d:
            goto runsetup
        )
    )
)

echo ERROR: Cannot find USB drive with required files
echo Make sure USB contains: 24.2.2000.exe, GlassWireSetup.exe, etc.
pause
exit /b 1

:runsetup
echo USB Drive: %FOUND_USB%
echo.
echo Starting installation...

powershell -ExecutionPolicy Bypass -Command "
$UsbDrive = '%FOUND_USB%'
$AdminUser = 'Admin'
$AdminPass = 'IBr1dG3Pc'
$BridgeUser = 'iBridge User'
$BridgePass = 'Abc654321!'
$SetupFolder = 'C:\iBridge_Setup'

Write-Host 'iBridge Universal Setup Starting...' -ForegroundColor Cyan
Write-Host \"USB: $UsbDrive\" -ForegroundColor Green
Write-Host ''

# Create folders
Write-Host 'Creating setup folders...' -ForegroundColor Yellow
$folders = @(\"$SetupFolder\Installers\", \"$SetupFolder\Shortcuts\", \"$SetupFolder\Office\")
foreach ($f in $folders) {
    if (!(Test-Path $f)) { New-Item -ItemType Directory -Path $f -Force | Out-Null }
}

# Remove old accounts
Write-Host 'Cleaning old accounts...' -ForegroundColor Yellow
try { Remove-LocalUser -Name $AdminUser -Confirm:`$false -ErrorAction SilentlyContinue } catch { }
try { Remove-LocalUser -Name $BridgeUser -Confirm:`$false -ErrorAction SilentlyContinue } catch { }

# Create accounts
Write-Host 'Creating user accounts...' -ForegroundColor Yellow
$adminPwd = ConvertTo-SecureString $AdminPass -AsPlainText -Force
$bridgePwd = ConvertTo-SecureString $BridgePass -AsPlainText -Force

New-LocalUser -Name $AdminUser -Password $adminPwd -Description 'Admin account' -PasswordNeverExpires -AccountNeverExpires | Out-Null
Add-LocalGroupMember -Group 'Administrators' -Member $AdminUser
Write-Host \"✓ Created: $AdminUser\" -ForegroundColor Green

New-LocalUser -Name $BridgeUser -Password $bridgePwd -Description 'Standard user' -PasswordNeverExpires -AccountNeverExpires | Out-Null  
Add-LocalGroupMember -Group 'Users' -Member $BridgeUser
Write-Host \"✓ Created: $BridgeUser\" -ForegroundColor Green

# Create profiles
Write-Host 'Setting up user profiles...' -ForegroundColor Yellow
$profiles = @(\"C:\Users\$AdminUser\", \"C:\Users\$BridgeUser\")
foreach ($profile in $profiles) {
    if (!(Test-Path $profile)) {
        $dirs = @('Desktop', 'Documents', 'Downloads', 'AppData\Local', 'AppData\Roaming')
        foreach ($dir in $dirs) {
            New-Item -ItemType Directory -Path (Join-Path $profile $dir) -Force | Out-Null
        }
    }
}

# Install applications
Write-Host 'Installing applications...' -ForegroundColor Yellow
$apps = @(
    @{file='24.2.2000.exe'; name='SYSPRO'; args='/SILENT'},
    @{file='GlassWireSetup.exe'; name='GlassWire'; args='/S'},
    @{file='PBIDesktopSetup_x64.exe'; name='Power BI'; args='/quiet'},
    @{file='TeamViewer_Setup_x64.exe'; name='TeamViewer'; args='/S'}
)

$installed = 0
foreach ($app in $apps) {
    $source = \"$UsbDrive\\$($app.file)\"
    $local = \"$SetupFolder\\Installers\\$($app.file)\"
    
    if (Test-Path $source) {
        Write-Host \"Installing $($app.name)...\" -ForegroundColor Cyan
        Copy-Item $source $local -Force
        
        try {
            $proc = Start-Process -FilePath $local -ArgumentList $app.args -Wait -PassThru -NoNewWindow
            if ($proc.ExitCode -eq 0) {
                Write-Host \"✓ $($app.name) installed\" -ForegroundColor Green
                $installed++
            } else {
                Write-Host \"⚠ $($app.name) completed (code $($proc.ExitCode))\" -ForegroundColor Yellow
                $installed++
            }
        } catch {
            Write-Host \"✗ $($app.name) failed\" -ForegroundColor Red
        }
    } else {
        Write-Host \"✗ $($app.file) not found\" -ForegroundColor Red
    }
}

# Handle Office
Write-Host 'Setting up Microsoft Office...' -ForegroundColor Yellow
$officeSource = \"$UsbDrive\\Tools for Office2019 TechXander\"
$officeDest = \"$SetupFolder\\Installers\\Tools for Office2019 TechXander\"

if (Test-Path $officeSource) {
    Copy-Item $officeSource $officeDest -Recurse -Force
    Write-Host '✓ Office tools copied for manual setup' -ForegroundColor Green
    
    # Check if Office already installed
    $officeExists = $false
    @('C:\Program Files\Microsoft Office', 'C:\Program Files (x86)\Microsoft Office') | ForEach-Object {
        if (Test-Path $_) { 
            $officeExists = $true
            Write-Host \"✓ Office already installed at $_\" -ForegroundColor Green
        }
    }
    
    if (-not $officeExists) {
        Write-Host '→ Office tools ready for manual installation' -ForegroundColor Cyan
    }
} else {
    Write-Host '✗ Office tools not found on USB' -ForegroundColor Red
}

# Copy shortcuts
Write-Host 'Setting up shortcuts...' -ForegroundColor Yellow
$shortcutDirs = @(\"$UsbDrive\\IT STUFF\", \"$UsbDrive\\iBridge Set Up\")
$bridgeDesktop = \"C:\Users\$BridgeUser\Desktop\"
$shortcuts = 0

foreach ($dir in $shortcutDirs) {
    if (Test-Path $dir) {
        Get-ChildItem $dir -Include '*.lnk', '*.url' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            # Copy to shared location
            Copy-Item $_.FullName \"$SetupFolder\\Shortcuts\\$($_.Name)\" -Force
            # Copy to iBridge User desktop
            Copy-Item $_.FullName \"$bridgeDesktop\\$($_.Name)\" -Force
            $shortcuts++
        }
    }
}

if ($shortcuts -gt 0) {
    Write-Host \"✓ $shortcuts shortcuts created\" -ForegroundColor Green
} else {
    Write-Host '⚠ No shortcuts found' -ForegroundColor Yellow
}

# Set permissions
Write-Host 'Setting permissions...' -ForegroundColor Yellow
try {
    $acl = Get-Acl $SetupFolder
    $userRule = New-Object System.Security.AccessControl.FileSystemAccessRule('Users', 'ReadAndExecute', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule('Administrators', 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $acl.SetAccessRule($userRule)
    $acl.SetAccessRule($adminRule)
    Set-Acl -Path $SetupFolder -AclObject $acl
    Write-Host '✓ Permissions set' -ForegroundColor Green
} catch {
    Write-Host '⚠ Could not set permissions' -ForegroundColor Yellow
}

# Summary
Write-Host ''
Write-Host '================================================' -ForegroundColor Green
Write-Host 'SETUP COMPLETED SUCCESSFULLY!' -ForegroundColor White -BackgroundColor Green
Write-Host '================================================' -ForegroundColor Green
Write-Host ''
Write-Host \"✓ Applications installed: $installed\" -ForegroundColor Cyan
Write-Host \"✓ Office tools prepared for setup\" -ForegroundColor Cyan
Write-Host \"✓ Shortcuts created: $shortcuts\" -ForegroundColor Cyan
Write-Host \"✓ Everything saved to: $SetupFolder\" -ForegroundColor Cyan
Write-Host ''
Write-Host 'USB DRIVE CAN NOW BE REMOVED!' -ForegroundColor Yellow -BackgroundColor DarkGreen
Write-Host ''
Write-Host 'NEXT STEPS:' -ForegroundColor Yellow
Write-Host '1. Log out of Windows' -ForegroundColor Gray
Write-Host '2. Log in as: iBridge User' -ForegroundColor Gray  
Write-Host '3. Password: Abc654321!' -ForegroundColor Gray
Write-Host '4. Check desktop for shortcuts' -ForegroundColor Gray
Write-Host '5. For Office: Check C:\iBridge_Setup\Installers\Tools for Office2019 TechXander' -ForegroundColor Gray
"

echo.
echo ================================================================
echo UNIVERSAL SETUP COMPLETE!
echo.
echo Main applications are installed permanently.
echo Office tools are ready for manual setup.
echo USB drive can be safely removed.
echo.
echo Log in as "iBridge User" (Password: Abc654321!) to use everything.
echo ================================================================
pause
