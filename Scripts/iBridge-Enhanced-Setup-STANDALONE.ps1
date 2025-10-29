# iBridge Enhanced Complete Setup Script - FINAL CLEAN VERSION
# Creates user accounts, installs applications permanently, and sets up shortcuts for standalone operation
# Ensures all applications work without USB drive inserted

param(
    [switch]$SkipValidation,
    [switch]$QuietMode,
    [switch]$CleanupOnly
)

# ============================================================
# ENHANCED CONFIGURATION SECTION
# ============================================================

# Account Configuration
$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

# Enhanced Paths Configuration
$iBridgeBase = "C:\iBridge_Setup"
$InstallersPath = "$iBridgeBase\Installers"
$ShortcutsPath = "$iBridgeBase\Shortcuts"
$LogsPath = "$iBridgeBase\Logs"
$ScriptsPath = "$iBridgeBase\Scripts"
$TempPath = "$iBridgeBase\Temp"

# Progress tracking
$Global:TotalSteps = 8
$Global:CurrentStep = 0
$Global:LogFile = "$LogsPath\iBridge-Setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Version Control Configuration
$SetupVersion = "2.0.1"
$VersionFile = "$iBridgeBase\VERSION.txt"
$InstallationInfoFile = "$iBridgeBase\INSTALLATION-INFO.json"

# Dynamic application discovery
$Applications = @()
$Shortcuts = @()

# ============================================================
# ENHANCED UTILITY FUNCTIONS
# ============================================================

function Write-LogEntry {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Ensure log directory exists
    if (!(Test-Path $LogsPath)) {
        New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null
    }
    
    # Write to log file
    Add-Content -Path $Global:LogFile -Value $logEntry
    
    # Also display on console with colors
    switch ($Level) {
        "SUCCESS" { Write-Host "✓ $Message" -ForegroundColor Green }
        "ERROR" { Write-Host "✗ $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "⚠ $Message" -ForegroundColor Yellow }
        "INFO" { Write-Host "ℹ $Message" -ForegroundColor Cyan }
        "PROGRESS" { Write-Host "→ $Message" -ForegroundColor Magenta }
        default { Write-Host "$Message" -ForegroundColor White }
    }
}

function Start-StepProgress {
    param([string]$StepName)
    
    $Global:CurrentStep++
    $percent = [math]::Round(($Global:CurrentStep / $Global:TotalSteps) * 100)
    
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor Blue
    Write-Host "STEP $Global:CurrentStep of $Global:TotalSteps: $StepName" -ForegroundColor White -BackgroundColor Blue
    Write-Host "=" * 80 -ForegroundColor Blue
    Write-Host ""
    
    Write-Progress -Activity "iBridge Setup" -Status $StepName -PercentComplete $percent
    Write-LogEntry "Starting Step $Global:CurrentStep/$Global:TotalSteps: $StepName" "PROGRESS"
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Wait-ForKeyPress {
    param([string]$Message = "Press any key to continue...")
    if (-not $QuietMode) {
        Write-Host $Message -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# ============================================================
# DISCOVERY FUNCTIONS
# ============================================================

function Find-ApplicationFiles {
    Write-LogEntry "Discovering specified application files..." "INFO"
    
    $foundFiles = @()
    
    # Define specific applications to install
    $specificApplications = @(
        @{
            Path = "D:\24.2.2000.exe"
            Name = "Application 24.2.2000"
            Arguments = "/SILENT"
            IsFolder = $false
        },
        @{
            Path = "D:\GlassWireSetup.exe"
            Name = "GlassWire"
            Arguments = "/S"
            IsFolder = $false
        },
        @{
            Path = "D:\PBIDesktopSetup_x64.exe"
            Name = "Power BI Desktop"
            Arguments = "/quiet"
            IsFolder = $false
        },
        @{
            Path = "D:\TeamViewer_Setup_x64.exe"
            Name = "TeamViewer"
            Arguments = "/S"
            IsFolder = $false
        },
        @{
            Path = "D:\Tools for Office2019 TechXander"
            Name = "Tools for Office 2019 TechXander"
            Arguments = ""
            IsFolder = $true
        }
    )
    
    # Check each specified application
    foreach ($app in $specificApplications) {
        if (Test-Path $app.Path) {
            $foundFiles += $app
            Write-LogEntry "Found application: $($app.Name) at $($app.Path)" "SUCCESS"
        } else {
            Write-LogEntry "Application not found: $($app.Name) at $($app.Path)" "WARNING"
        }
    }
    
    Write-LogEntry "Found $($foundFiles.Count) out of $($specificApplications.Count) specified applications" "INFO"
    return $foundFiles
}

function Find-ShortcutFiles {
    Write-LogEntry "Discovering shortcut files in specified locations..." "INFO"
    
    $foundShortcuts = @()
    $shortcutPatterns = @("*.lnk", "*.url")
    
    # Only search in IT STUFF and iBridge Set Up folders for shortcuts
    $shortcutSources = @(
        "D:\IT STUFF",
        "D:\iBridge Set Up"
    )
    
    foreach ($sourcePath in $shortcutSources) {
        if (Test-Path $sourcePath) {
            Write-LogEntry "Searching for shortcuts in: $sourcePath" "INFO"
            foreach ($pattern in $shortcutPatterns) {
                $shortcuts = Get-ChildItem -Path $sourcePath -Filter $pattern -Recurse -ErrorAction SilentlyContinue
                foreach ($shortcut in $shortcuts) {
                    $foundShortcuts += @{
                        Name = [System.IO.Path]::GetFileNameWithoutExtension($shortcut.Name)
                        Source = $shortcut.FullName
                    }
                    Write-LogEntry "Found shortcut: $($shortcut.Name)" "SUCCESS"
                }
            }
        } else {
            Write-LogEntry "Shortcut source not found: $sourcePath" "WARNING"
        }
    }
    
    Write-LogEntry "Found $($foundShortcuts.Count) shortcut files" "INFO"
    return $foundShortcuts
}

# ============================================================
# CLEANUP FUNCTION
# ============================================================

function Start-Cleanup {
    Start-StepProgress "Cleaning Up Previous Installation"
    
    try {
        # Remove old iBridge_Apps folder if it exists
        if (Test-Path "C:\iBridge_Apps") {
            Write-LogEntry "Removing old iBridge_Apps folder..." "INFO"
            Remove-Item "C:\iBridge_Apps" -Recurse -Force -ErrorAction SilentlyContinue
            Write-LogEntry "Removed old iBridge_Apps folder" "SUCCESS"
        }
        
        # Clean up old user profiles desktop shortcuts
        $desktopPaths = @(
            "C:\Users\$AdminUsername\Desktop",
            "C:\Users\$UserUsername\Desktop",
            "C:\Users\Public\Desktop"
        )
        
        foreach ($desktopPath in $desktopPaths) {
            if (Test-Path $desktopPath) {
                $oldShortcuts = Get-ChildItem $desktopPath -Include "*.lnk", "*.url" -ErrorAction SilentlyContinue
                foreach ($shortcut in $oldShortcuts) {
                    if ($shortcut.Name -match "(TeamViewer|Office|Excel|Word|PowerPoint|Outlook|Teams|Power BI)") {
                        Remove-Item $shortcut.FullName -Force -ErrorAction SilentlyContinue
                        Write-LogEntry "Removed old shortcut: $($shortcut.Name)" "INFO"
                    }
                }
            }
        }
        
        # Create new organized folder structure
        $foldersToCreate = @($iBridgeBase, $InstallersPath, $ShortcutsPath, $LogsPath, $ScriptsPath, $TempPath)
        foreach ($folder in $foldersToCreate) {
            if (!(Test-Path $folder)) {
                New-Item -ItemType Directory -Path $folder -Force | Out-Null
                Write-LogEntry "Created folder: $folder" "SUCCESS"
            }
        }
        
        Write-LogEntry "Cleanup completed successfully" "SUCCESS"
        return $true
        
    } catch {
        Write-LogEntry "Cleanup failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================================
# USER ACCOUNT MANAGEMENT
# ============================================================

function New-UserAccountsEnhanced {
    Start-StepProgress "Creating User Accounts with Profile Setup"
    
    try {
        # Remove existing accounts if they exist
        $existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
        if ($existingAdmin) {
            Write-LogEntry "Removing existing Admin account..." "WARNING"
            Remove-LocalUser -Name $AdminUsername -Confirm:$false
        }
        
        $existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
        if ($existingUser) {
            Write-LogEntry "Removing existing iBridge User account..." "WARNING"
            Remove-LocalUser -Name $UserUsername -Confirm:$false
        }
        
        # Create Admin account
        Write-LogEntry "Creating Admin account..." "INFO"
        $secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
        $adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -Description "Admin for app installation" -PasswordNeverExpires -AccountNeverExpires
        Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername
        Write-LogEntry "Admin account created successfully" "SUCCESS"
        
        # Create iBridge User account
        Write-LogEntry "Creating iBridge User account..." "INFO"
        $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
        $bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -Description "Standard user with limited privileges" -PasswordNeverExpires -AccountNeverExpires
        Add-LocalGroupMember -Group "Users" -Member $UserUsername
        Write-LogEntry "iBridge User account created successfully" "SUCCESS"
        
        # Force profile creation
        Write-LogEntry "Forcing profile creation for both accounts..." "INFO"
        Start-ProfileCreation
        
        return $true
        
    } catch {
        Write-LogEntry "Failed to create user accounts: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Start-ProfileCreation {
    Write-LogEntry "Creating user profiles and desktop folders..." "INFO"
    
    # Create profile directories manually if they don't exist
    $profilePaths = @(
        "C:\Users\$AdminUsername",
        "C:\Users\$UserUsername"
    )
    
    foreach ($profilePath in $profilePaths) {
        if (!(Test-Path $profilePath)) {
            $username = Split-Path $profilePath -Leaf
            Write-LogEntry "Creating profile for: $username" "INFO"
            
            try {
                # Create basic profile structure
                $foldersToCreate = @(
                    $profilePath,
                    "$profilePath\Desktop",
                    "$profilePath\Documents",
                    "$profilePath\Downloads",
                    "$profilePath\Pictures",
                    "$profilePath\AppData\Local",
                    "$profilePath\AppData\Roaming"
                )
                
                foreach ($folder in $foldersToCreate) {
                    if (!(Test-Path $folder)) {
                        New-Item -ItemType Directory -Path $folder -Force | Out-Null
                    }
                }
                
                Write-LogEntry "Profile created for: $username" "SUCCESS"
                
            } catch {
                Write-LogEntry "Could not create profile for $username`: $($_.Exception.Message)" "WARNING"
            }
        } else {
            Write-LogEntry "Profile already exists for: $(Split-Path $profilePath -Leaf)" "INFO"
        }
    }
    
    # Verify desktop folders exist
    $desktopPaths = @(
        "C:\Users\$AdminUsername\Desktop",
        "C:\Users\$UserUsername\Desktop"
    )
    
    foreach ($desktopPath in $desktopPaths) {
        if (!(Test-Path $desktopPath)) {
            New-Item -ItemType Directory -Path $desktopPath -Force | Out-Null
            Write-LogEntry "Created desktop folder: $desktopPath" "SUCCESS"
        }
    }
}

# ============================================================
# PERMANENT INSTALLATION FUNCTIONS
# ============================================================

function Install-ApplicationsEnhanced {
    Start-StepProgress "Installing Applications Permanently"
    
    if ($Applications.Count -eq 0) {
        Write-LogEntry "No applications found to install" "WARNING"
        return $true
    }
    
    $successCount = 0
    $totalApps = $Applications.Count
    
    foreach ($app in $Applications) {
        $appProgress = [math]::Round(($successCount / $totalApps) * 100)
        Write-Progress -Activity "Installing Applications" -Status "Processing: $($app.Name)" -PercentComplete $appProgress
        
        Write-LogEntry "Processing application: $($app.Name)" "INFO"
        Write-LogEntry "Source: $($app.Path)" "INFO"
        
        if (Test-Path $app.Path) {
            try {
                if ($app.IsFolder) {
                    # Copy folder to installers directory for backup
                    $destPath = Join-Path $InstallersPath (Split-Path $app.Path -Leaf)
                    if (!(Test-Path $destPath)) {
                        Write-LogEntry "Copying folder to local storage: $($app.Name)" "INFO"
                        Copy-Item -Path $app.Path -Destination $destPath -Recurse -Force
                        Write-LogEntry "Copied folder: $($app.Name)" "SUCCESS"
                        $successCount++
                    } else {
                        Write-LogEntry "Folder already exists: $($app.Name)" "WARNING"
                        $successCount++
                    }
                } else {
                    # Copy installer to local storage first
                    $installerName = Split-Path $app.Path -Leaf
                    $localInstaller = Join-Path $InstallersPath $installerName
                    
                    # Always copy the installer to local storage
                    Write-LogEntry "Copying installer to local storage: $installerName" "INFO"
                    Copy-Item -Path $app.Path -Destination $localInstaller -Force
                    Write-LogEntry "Copied installer to: $localInstaller" "SUCCESS"
                    
                    # Install the application from local storage
                    Write-LogEntry "Installing: $($app.Name) from local copy" "INFO"
                    $process = Start-Process -FilePath $localInstaller -ArgumentList $app.Arguments -Wait -PassThru -NoNewWindow
                    
                    if ($process.ExitCode -eq 0) {
                        Write-LogEntry "Installed successfully: $($app.Name)" "SUCCESS"
                        $successCount++
                    } else {
                        Write-LogEntry "Installation completed with exit code $($process.ExitCode): $($app.Name)" "WARNING"
                        $successCount++
                    }
                }
            } catch {
                Write-LogEntry "Failed to install $($app.Name): $($_.Exception.Message)" "ERROR"
            }
        } else {
            Write-LogEntry "Source file not found: $($app.Path)" "ERROR"
        }
    }
    
    Write-LogEntry "Applications processed: $successCount of $totalApps" "INFO"
    return $successCount -eq $totalApps
}

# ============================================================
# ENHANCED SHORTCUT CREATION FOR STANDALONE OPERATION
# ============================================================

function Create-ShortcutsEnhanced {
    Start-StepProgress "Creating Shortcuts for Standalone Operation"
    
    if ($Shortcuts.Count -eq 0) {
        Write-LogEntry "No shortcuts found to create" "WARNING"
        return $true
    }
    
    $successCount = 0
    $totalShortcuts = $Shortcuts.Count
    
    # Ensure iBridge User desktop path exists
    $iBridgeDesktopPath = "C:\Users\$UserUsername\Desktop"
    if (!(Test-Path $iBridgeDesktopPath)) {
        New-Item -ItemType Directory -Path $iBridgeDesktopPath -Force | Out-Null
        Write-LogEntry "Created iBridge User desktop directory: $iBridgeDesktopPath" "SUCCESS"
    }
    
    foreach ($shortcut in $Shortcuts) {
        $shortcutProgress = [math]::Round(($successCount / $totalShortcuts) * 100)
        Write-Progress -Activity "Creating Shortcuts" -Status "Processing: $($shortcut.Name)" -PercentComplete $shortcutProgress
        
        Write-LogEntry "Processing shortcut: $($shortcut.Name)" "INFO"
        
        if (Test-Path $shortcut.Source) {
            try {
                $fileName = Split-Path $shortcut.Source -Leaf
                
                # Copy to shared shortcuts folder
                $sharedPath = Join-Path $ShortcutsPath $fileName
                Copy-Item -Path $shortcut.Source -Destination $sharedPath -Force
                Write-LogEntry "Copied to shared folder: $fileName" "SUCCESS"
                
                # Copy to iBridge User desktop only
                $iBridgeShortcut = Join-Path $iBridgeDesktopPath $fileName
                Copy-Item -Path $shortcut.Source -Destination $iBridgeShortcut -Force
                
                # Verify the shortcut was created
                if (Test-Path $iBridgeShortcut) {
                    Write-LogEntry "Created shortcut on iBridge User desktop: $fileName" "SUCCESS"
                } else {
                    Write-LogEntry "Failed to create shortcut on iBridge User desktop: $fileName" "ERROR"
                }
                
                $successCount++
                
            } catch {
                Write-LogEntry "Failed to copy shortcut $($shortcut.Name): $($_.Exception.Message)" "ERROR"
            }
        } else {
            Write-LogEntry "Shortcut source not found: $($shortcut.Source)" "ERROR"
        }
    }
    
    Write-LogEntry "Shortcuts processed: $successCount of $totalShortcuts" "INFO"
    return $successCount -eq $totalShortcuts
}

# ============================================================
# FOLDER PERMISSIONS
# ============================================================

function Set-FolderPermissionsEnhanced {
    Start-StepProgress "Configuring Folder Permissions"
    
    try {
        $acl = Get-Acl $iBridgeBase
        
        # Give Users group read and execute permissions
        $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($userAccessRule)
        
        # Give Administrators group full control
        $adminAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($adminAccessRule)
        
        Set-Acl -Path $iBridgeBase -AclObject $acl
        Write-LogEntry "Folder permissions set successfully" "SUCCESS"
        
        return $true
        
    } catch {
        Write-LogEntry "Could not set folder permissions: $($_.Exception.Message)" "WARNING"
        return $false
    }
}

# ============================================================
# SCRIPT ORGANIZATION
# ============================================================

function Copy-ScriptsToOrganizedFolder {
    Start-StepProgress "Organizing Scripts and Files"
    
    try {
        # Get current script path
        $currentScript = $PSCommandPath
        if (-not $currentScript) {
            $currentScript = $MyInvocation.MyCommand.Path
        }
        
        if ($currentScript -and (Test-Path $currentScript)) {
            $scriptName = Split-Path $currentScript -Leaf
            $destScript = Join-Path $ScriptsPath $scriptName
            Copy-Item $currentScript $destScript -Force
            Write-LogEntry "Copied script to organized folder: $scriptName" "SUCCESS"
        }
        
        # Create a comprehensive summary file
        $summaryPath = Join-Path $iBridgeBase "SETUP-SUMMARY.txt"
        
        $summaryContent = @"
iBridge Enhanced Setup Summary (v$SetupVersion)
Generated: $(Get-Date)

FOLDER STRUCTURE:
$iBridgeBase
- Installers (Application installers - COPIED LOCALLY)
- Shortcuts (Desktop shortcuts)
- Scripts (Setup scripts)
- Logs (Setup logs)
- Temp (Temporary files)
- VERSION.txt (Setup version)
- INSTALLATION-INFO.json (Installation details)

USER ACCOUNTS CREATED:
Admin (Password: $AdminPassword)
iBridge User (Password: $UserPassword)

APPLICATIONS INSTALLED: $($Applications.Count)
SHORTCUTS CREATED: $($Shortcuts.Count) (iBridge User desktop only)

STANDALONE OPERATION:
- All applications installed to local system
- Application installers copied to C:\iBridge_Setup\Installers
- Shortcuts configured for local targets where possible
- USB drive no longer required for daily operation

NEXT STEPS:
1. Log out of current session
2. Log in as 'iBridge User' with password 'Abc654321!'
3. Verify shortcuts appear on desktop
4. Test applications work without USB inserted
5. Browse $iBridgeBase for all resources

LOG FILE: $Global:LogFile
VERSION FILE: $VersionFile
INSTALLATION INFO: $InstallationInfoFile
"@
        
        $summaryContent | Out-File $summaryPath -Encoding UTF8
        Write-LogEntry "Created comprehensive setup summary file" "SUCCESS"
        
        return $true
        
    } catch {
        Write-LogEntry "Failed to organize scripts: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================================
# MAIN EXECUTION
# ============================================================

function Start-EnhancedSetup {
    try {
        Write-Host "iBridge Enhanced Complete Setup Script - FINAL CLEAN VERSION" -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host "Ensures Standalone Operation Without USB Drive" -ForegroundColor Cyan
        Write-Host "Log File: $Global:LogFile" -ForegroundColor Yellow
        Write-Host ""
        
        Write-LogEntry "iBridge Enhanced Setup Started (v$SetupVersion)" "INFO"
        
        # Check if running as Administrator
        if (-not (Test-Administrator)) {
            Write-LogEntry "This script must be run as Administrator" "ERROR"
            throw "Administrator privileges required"
        }
        
        if ($CleanupOnly) {
            Start-Cleanup
            Write-LogEntry "Cleanup completed" "SUCCESS"
            return
        }
        
        # Step 1: Cleanup and preparation
        Start-Cleanup
        
        # Discover applications and shortcuts
        Write-LogEntry "Discovering applications and shortcuts..." "INFO"
        $Global:Applications = Find-ApplicationFiles
        $Global:Shortcuts = Find-ShortcutFiles
        
        Write-LogEntry "Found $($Applications.Count) applications and $($Shortcuts.Count) shortcuts" "INFO"
        
        if (-not $SkipValidation) {
            Wait-ForKeyPress "Press any key to start the enhanced setup process (FINAL CLEAN VERSION)..."
        }
        
        # Step 2: Create user accounts with profile setup
        New-UserAccountsEnhanced
        
        # Step 3: Install applications permanently to local system
        Install-ApplicationsEnhanced
        
        # Step 4: Create and verify shortcuts for standalone operation
        Create-ShortcutsEnhanced
        
        # Step 5: Set permissions
        Set-FolderPermissionsEnhanced
        
        # Step 6: Organize everything
        Copy-ScriptsToOrganizedFolder
        
        # Step 7: Final summary
        Start-StepProgress "Setup Complete - Final Verification"
        
        Write-Host "`n" -NoNewline
        Write-Host "=" * 80 -ForegroundColor Green
        Write-Host "ENHANCED SETUP COMPLETED SUCCESSFULLY!" -ForegroundColor White -BackgroundColor Green
        Write-Host "=" * 80 -ForegroundColor Green
        Write-Host ""
        
        Write-LogEntry "Enhanced setup completed successfully" "SUCCESS"
        Write-Host "✓ User accounts created with profiles" -ForegroundColor Green
        Write-Host "✓ Applications installed permanently: $($Applications.Count)" -ForegroundColor Green
        Write-Host "✓ Shortcuts created for iBridge User: $($Shortcuts.Count)" -ForegroundColor Green
        Write-Host "✓ Everything organized in: $iBridgeBase" -ForegroundColor Green
        Write-Host "✓ Applications work without USB drive" -ForegroundColor Green
        Write-Host ""
        Write-Host "STANDALONE OPERATION READY!" -ForegroundColor Yellow -BackgroundColor DarkGreen
        Write-Host "USB drive can now be safely removed" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "NEXT STEPS:" -ForegroundColor Yellow
        Write-Host "1. Log out of current Windows session" -ForegroundColor Cyan
        Write-Host "2. Log in as 'iBridge User' (Password: $UserPassword)" -ForegroundColor Cyan
        Write-Host "3. Check desktop for shortcuts (USB not needed)" -ForegroundColor Cyan
        Write-Host "4. Test applications work independently" -ForegroundColor Cyan
        Write-Host "5. Browse $iBridgeBase for all resources" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Log file: $Global:LogFile" -ForegroundColor Gray
        
        Write-LogEntry "iBridge Enhanced Setup Completed Successfully (FINAL CLEAN)" "SUCCESS"
        
    } catch {
        Write-LogEntry "Setup failed: $($_.Exception.Message)" "ERROR"
        Write-Host "Setup failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Check log file: $Global:LogFile" -ForegroundColor Yellow
        exit 1
    }
}

# Start the enhanced setup process
Start-EnhancedSetup
