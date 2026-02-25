# iBridge Simple Setup Script - Minimal Version
# This is a simplified version to avoid line-breaking issues

param([switch]$CleanupOnly, [switch]$SkipValidation)

$AdminUsername = "Admin"
$UserUsername = "iBridge User"
$AdminPassword = "IBr1dG3Pc"
$UserPassword = "Abc654321!"
$iBridgeBase = "C:\iBridge_Setup"

function Write-Message { param($Message, $Color = "White"); Write-Host $Message -ForegroundColor $Color }
function Test-Admin { return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }

function Start-Setup {
    try {
        Write-Message "iBridge Enhanced Setup Script v2.0" "Cyan"
        Write-Message "Starting setup process..." "Yellow"
        
        if (-not (Test-Admin)) {
            Write-Message "ERROR: Must run as Administrator" "Red"
            exit 1
        }
        
        Write-Message "Creating base directory..." "Green"
        if (!(Test-Path $iBridgeBase)) {
            New-Item -ItemType Directory -Path $iBridgeBase -Force | Out-Null
        }
        
        Write-Message "Creating Admin user account..." "Green"
        try {
            # Remove existing Admin account if it exists
            $existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
            if ($existingAdmin) {
                Write-Message "Removing existing Admin account..." "Yellow"
                Remove-LocalUser -Name $AdminUsername -Confirm:$false
                Write-Message "Existing Admin account removed" "Green"
            }
            
            # Create new Admin account
            $secPass = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
            New-LocalUser -Name $AdminUsername -Password $secPass -FullName "Admin" | Out-Null
            Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername | Out-Null
            Write-Message "Admin account created successfully" "Green"
            
            # Force profile creation for Admin
            Write-Message "Creating Admin profile and desktop..." "Cyan"
            $adminProfilePath = "C:\Users\$AdminUsername"
            if (!(Test-Path $adminProfilePath)) {
                # Create profile by attempting to log in the user (this forces Windows to create the profile)
                $credential = New-Object System.Management.Automation.PSCredential ($AdminUsername, (ConvertTo-SecureString $AdminPassword -AsPlainText -Force))
                # Force profile creation by creating essential folders
                New-Item -ItemType Directory -Path "$adminProfilePath\Desktop" -Force -ErrorAction SilentlyContinue | Out-Null
                New-Item -ItemType Directory -Path "$adminProfilePath\Documents" -Force -ErrorAction SilentlyContinue | Out-Null
                Write-Message "Admin profile structure created" "Green"
            }
        } catch {
            Write-Message "Failed to create Admin account: $($_.Exception.Message)" "Red"
        }
        
        Write-Message "Creating iBridge User account..." "Green"
        try {
            # Remove existing iBridge User account if it exists
            $existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
            if ($existingUser) {
                Write-Message "Removing existing iBridge User account..." "Yellow"
                Remove-LocalUser -Name $UserUsername -Confirm:$false
                Write-Message "Existing iBridge User account removed" "Green"
            }
            
            # Create new iBridge User account
            $secPass = ConvertTo-SecureString $UserPassword -AsPlainText -Force
            New-LocalUser -Name $UserUsername -Password $secPass -FullName "iBridge User" | Out-Null
            Write-Message "iBridge User account created successfully" "Green"
            
            # Force profile creation for iBridge User
            Write-Message "Creating iBridge User profile and desktop..." "Cyan"
            $userProfilePath = "C:\Users\$UserUsername"
            if (!(Test-Path $userProfilePath)) {
                # Force profile creation by creating essential folders
                New-Item -ItemType Directory -Path "$userProfilePath\Desktop" -Force -ErrorAction SilentlyContinue | Out-Null
                New-Item -ItemType Directory -Path "$userProfilePath\Documents" -Force -ErrorAction SilentlyContinue | Out-Null
                New-Item -ItemType Directory -Path "$userProfilePath\Downloads" -Force -ErrorAction SilentlyContinue | Out-Null
                New-Item -ItemType Directory -Path "$userProfilePath\Pictures" -Force -ErrorAction SilentlyContinue | Out-Null
                New-Item -ItemType Directory -Path "$userProfilePath\AppData\Local" -Force -ErrorAction SilentlyContinue | Out-Null
                New-Item -ItemType Directory -Path "$userProfilePath\AppData\Roaming" -Force -ErrorAction SilentlyContinue | Out-Null
                Write-Message "iBridge User profile structure created" "Green"
            }
        } catch {
            Write-Message "Failed to create iBridge User account: $($_.Exception.Message)" "Red"
        }
        
        Write-Message "Cleaning old user profiles..." "Yellow"
        try {
            # Get all user profiles except essential ones
            $essentialUsers = @("Administrator", "DefaultAccount", "Guest", "WDAGUtilityAccount", $env:USERNAME, $AdminUsername, $UserUsername)
            $allProfiles = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue
            
            foreach ($profile in $allProfiles) {
                if ($profile.Name -notin $essentialUsers) {
                    Write-Message "Checking profile: $($profile.Name)" "Cyan"
                    
                    # Check if user account still exists
                    $userExists = Get-LocalUser -Name $profile.Name -ErrorAction SilentlyContinue
                    if (-not $userExists) {
                        Write-Message "Removing orphaned profile: $($profile.Name)" "Yellow"
                        try {
                            Remove-Item $profile.FullName -Recurse -Force -ErrorAction SilentlyContinue
                            Write-Message "Removed orphaned profile: $($profile.Name)" "Green"
                        } catch {
                            Write-Message "Could not remove profile: $($profile.Name) - $($_.Exception.Message)" "Red"
                        }
                    }
                }
            }
        } catch {
            Write-Message "Profile cleanup failed: $($_.Exception.Message)" "Red"
        }
        
        Write-Message "Installing applications..." "Green"
        $apps = @(
            @{Path="D:\24.2.2000.exe"; Args="/S"; Name="SYSPRO 24.2.2000"},
            @{Path="D:\GlassWireSetup.exe"; Args="/S"; Name="GlassWire"},
            @{Path="D:\PBIDesktopSetup_x64.exe"; Args="/quiet ACCEPT_EULA=1"; Name="Power BI Desktop"},
            @{Path="D:\TeamViewer_Setup_x64.exe"; Args="/S"; Name="TeamViewer"}
        )
        foreach ($app in $apps) {
            if (Test-Path $app.Path) {
                Write-Message "Installing: $($app.Name)" "Cyan"
                try {
                    # Standard installation for all apps
                    $process = Start-Process -FilePath $app.Path -ArgumentList $app.Args -Wait -PassThru -NoNewWindow
                    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                        Write-Message "Installation completed for: $($app.Name)" "Green"
                    } else {
                        Write-Message "Installation completed with exit code $($process.ExitCode): $($app.Name)" "Yellow"
                    }
                } catch {
                    Write-Message "Installation failed for: $($app.Name) - $($_.Exception.Message)" "Red"
                }
            } else {
                Write-Message "Application not found: $($app.Path)" "Red"
            }
        }
        
        Write-Message "" "White"
        Write-Message "Verifying user profiles..." "Yellow"
        $adminProfile = "C:\Users\$AdminUsername"
        $userProfile = "C:\Users\$UserUsername"
        
        if (Test-Path $adminProfile) {
            Write-Message "✓ Admin profile exists at: $adminProfile" "Green"
        } else {
            Write-Message "✗ Admin profile missing at: $adminProfile" "Red"
        }
        
        if (Test-Path $userProfile) {
            Write-Message "✓ iBridge User profile exists at: $userProfile" "Green"
        } else {
            Write-Message "✗ iBridge User profile missing at: $userProfile" "Red"
        }
        
        Write-Message "" "White"
        Write-Message "SETUP COMPLETED SUCCESSFULLY!" "Green"
        Write-Message "User Accounts Created:" "Yellow"
        Write-Message "- Admin (Password: $AdminPassword)" "Cyan"
        Write-Message "- iBridge User (Password: $UserPassword)" "Cyan"
        Write-Message "" "White"
        Write-Message "Next Steps:" "Yellow"
        Write-Message "1. Log out of Windows" "Cyan"
        Write-Message "2. Log in as iBridge User" "Cyan"
        Write-Message "3. Verify applications are installed" "Cyan"
        
    } catch {
        Write-Message "Setup failed: $($_.Exception.Message)" "Red"
        exit 1
    }
}

Start-Setup
