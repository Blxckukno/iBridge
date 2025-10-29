@echo off
:: Dynamic iBridge Setup Creator
:: This creates the PowerShell script on-the-fly to avoid encoding issues

title iBridge Dynamic Setup Creator
color 0A

echo ===============================================================================
echo                        iBridge Dynamic Setup Creator
echo ===============================================================================
echo.
echo This script will create a fresh PowerShell script and run it immediately
echo to avoid any file encoding or corruption issues.
echo.
echo Press any key to continue...
pause > nul

echo.
echo Creating PowerShell script dynamically...

:: Create the PowerShell script content
(
echo # iBridge Dynamic Setup Script
echo param^([switch]$CleanupOnly^)
echo.
echo $AdminUsername = "Admin"
echo $UserUsername = "iBridge User"
echo $AdminPassword = "IBr1dG3Pc"
echo $UserPassword = "Abc654321!"
echo.
echo function Write-Message { param^($Message, $Color = "White"^); Write-Host $Message -ForegroundColor $Color }
echo function Test-Admin { return ^([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent^(^)^).IsInRole^([Security.Principal.WindowsBuiltInRole]::Administrator^) }
echo.
echo Write-Message "iBridge Setup Script v2.0" "Cyan"
echo Write-Message "Starting setup process..." "Yellow"
echo.
echo if ^(-not ^(Test-Admin^)^) {
echo     Write-Message "ERROR: Must run as Administrator" "Red"
echo     exit 1
echo }
echo.
echo Write-Message "Creating Admin user account..." "Green"
echo try {
echo     # Remove existing Admin account if it exists
echo     $existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
echo     if ^($existingAdmin^) {
echo         Write-Message "Removing existing Admin account..." "Yellow"
echo         Remove-LocalUser -Name $AdminUsername -Confirm:$false
echo         Write-Message "Existing Admin account removed" "Green"
echo     }
echo     
echo     # Create new Admin account
echo     $secPass = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
echo     New-LocalUser -Name $AdminUsername -Password $secPass -FullName "iBridge Administrator" ^| Out-Null
echo     Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername ^| Out-Null
echo     Write-Message "Admin account created successfully" "Green"
echo     Write-Message "Creating Admin profile and desktop..." "Cyan"
echo     $adminProfilePath = "C:\Users\$AdminUsername"
echo     if ^(^!^(Test-Path $adminProfilePath^)^) {
echo         New-Item -ItemType Directory -Path "$adminProfilePath\Desktop" -Force -ErrorAction SilentlyContinue ^| Out-Null
echo         New-Item -ItemType Directory -Path "$adminProfilePath\Documents" -Force -ErrorAction SilentlyContinue ^| Out-Null
echo         Write-Message "Admin profile structure created" "Green"
echo     }
echo } catch {
echo     Write-Message "Failed to create Admin account: $^($_.Exception.Message^)" "Red"
echo }
echo.
echo Write-Message "Creating iBridge User account..." "Green"
echo try {
echo     # Remove existing iBridge User account if it exists
echo     $existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
echo     if ^($existingUser^) {
echo         Write-Message "Removing existing iBridge User account..." "Yellow"
echo         Remove-LocalUser -Name $UserUsername -Confirm:$false
echo         Write-Message "Existing iBridge User account removed" "Green"
echo     }
echo     
echo     # Create new iBridge User account
echo     $secPass = ConvertTo-SecureString $UserPassword -AsPlainText -Force
echo     New-LocalUser -Name $UserUsername -Password $secPass -FullName "iBridge User" ^| Out-Null
echo     Write-Message "iBridge User account created successfully" "Green"
echo     Write-Message "Creating iBridge User profile and desktop..." "Cyan"
echo     $userProfilePath = "C:\Users\$UserUsername"
echo     if ^(^!^(Test-Path $userProfilePath^)^) {
echo         New-Item -ItemType Directory -Path "$userProfilePath\Desktop" -Force -ErrorAction SilentlyContinue ^| Out-Null
echo         New-Item -ItemType Directory -Path "$userProfilePath\Documents" -Force -ErrorAction SilentlyContinue ^| Out-Null
echo         New-Item -ItemType Directory -Path "$userProfilePath\Downloads" -Force -ErrorAction SilentlyContinue ^| Out-Null
echo         New-Item -ItemType Directory -Path "$userProfilePath\Pictures" -Force -ErrorAction SilentlyContinue ^| Out-Null
echo         New-Item -ItemType Directory -Path "$userProfilePath\AppData\Local" -Force -ErrorAction SilentlyContinue ^| Out-Null
echo         New-Item -ItemType Directory -Path "$userProfilePath\AppData\Roaming" -Force -ErrorAction SilentlyContinue ^| Out-Null
echo         Write-Message "iBridge User profile structure created" "Green"
echo     }
echo } catch {
echo     Write-Message "Failed to create iBridge User account: $^($_.Exception.Message^)" "Red"
echo }
echo.
echo Write-Message "Cleaning old user profiles..." "Yellow"
echo try {
echo     $essentialUsers = @^("Administrator", "DefaultAccount", "Guest", "WDAGUtilityAccount", $env:USERNAME, $AdminUsername, $UserUsername^)
echo     $allProfiles = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue
echo     foreach ^($profile in $allProfiles^) {
echo         if ^($profile.Name -notin $essentialUsers^) {
echo             $userExists = Get-LocalUser -Name $profile.Name -ErrorAction SilentlyContinue
echo             if ^(-not $userExists^) {
echo                 Write-Message "Removing orphaned profile: $^($profile.Name^)" "Yellow"
echo                 Remove-Item $profile.FullName -Recurse -Force -ErrorAction SilentlyContinue
echo                 Write-Message "Removed orphaned profile: $^($profile.Name^)" "Green"
echo             }
echo         }
echo     }
echo } catch {
echo     Write-Message "Profile cleanup failed: $^($_.Exception.Message^)" "Red"
echo }
echo.
echo Write-Message "Installing applications..." "Green"
echo $apps = @^(
echo     @{Path="D:\24.2.2000.exe"; Args="/S"; Name="SYSPRO 24.2.2000"},
echo     @{Path="D:\GlassWireSetup.exe"; Args="/S"; Name="GlassWire"},
echo     @{Path="D:\PBIDesktopSetup_x64.exe"; Args="/quiet ACCEPT_EULA=1"; Name="Power BI Desktop"},
echo     @{Path="D:\TeamViewer_Setup_x64.exe"; Args="/S"; Name="TeamViewer"}
echo ^)
echo foreach ^($app in $apps^) {
echo     if ^(Test-Path $app.Path^) {
echo         Write-Message "Installing: $^($app.Name^)" "Cyan"
echo         try {
echo             $process = Start-Process -FilePath $app.Path -ArgumentList $app.Args -Wait -PassThru -NoNewWindow
echo             if ^($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010^) {
echo                 Write-Message "Installation completed for: $^($app.Name^)" "Green"
echo             } else {
echo                 Write-Message "Installation completed with exit code $^($process.ExitCode^): $^($app.Name^)" "Yellow"
echo             }
echo         } catch {
echo             Write-Message "Installation failed for: $^($app.Name^) - $^($_.Exception.Message^)" "Red"
echo         }
echo     } else {
echo         Write-Message "Application not found: $^($app.Path^)" "Red"
echo     }
echo }
echo.
echo Write-Message "" "White"
echo Write-Message "SETUP COMPLETED SUCCESSFULLY!" "Green"
echo Write-Message "User Accounts Created:" "Yellow"
echo Write-Message "- Admin ^(Password: $AdminPassword^)" "Cyan"
echo Write-Message "- iBridge User ^(Password: $UserPassword^)" "Cyan"
echo Write-Message "" "White"
echo Write-Message "Next Steps:" "Yellow"
echo Write-Message "1. Log out of Windows" "Cyan"
echo Write-Message "2. Log in as iBridge User" "Cyan"
echo Write-Message "3. Verify applications are installed" "Cyan"
) > "%~dp0iBridge-Dynamic-Setup.ps1"

echo PowerShell script created successfully!
echo.
echo Running the dynamic setup script...
echo ===============================================================================

:: Run the dynamically created script
powershell -ExecutionPolicy Bypass -File "%~dp0iBridge-Dynamic-Setup.ps1"

:: Check result
if %ERRORLEVEL% equ 0 (
    echo.
    echo ===============================================================================
    echo                          Setup Completed Successfully
    echo ===============================================================================
) else (
    echo.
    echo ===============================================================================
    echo                             Setup Failed
    echo ===============================================================================
    echo Error code: %ERRORLEVEL%
)

echo.
echo Press any key to exit...
pause > nul
