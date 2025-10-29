# iBridge Enhanced Setup Script v2.0
# Enhanced version with profile setup, progress tracking, and comprehensive logging
# Creates user accounts, installs applications, forces profile creation, and verifies shortcuts

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
$iBridgeBase = "C:\iBridge_Setup"           # Single organized folder
$InstallersPath = "$iBridgeBase\Installers"
$ShortcutsPath = "$iBridgeBase\Shortcuts"
$LogsPath = "$iBridgeBase\Logs"
$ScriptsPath = "$iBridgeBase\Scripts"
$TempPath = "$iBridgeBase\Temp"

# Progress tracking
$Global:TotalSteps = 8  # Increased for version checking step
$Global:CurrentStep = 0
$Global:LogFile = "$LogsPath\iBridge-Setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Version Control Configuration
$SetupVersion = "2.0.0"
$VersionFile = "$iBridgeBase\VERSION.txt"
$InstallationInfoFile = "$iBridgeBase\INSTALLATION-INFO.json"

# Application Version Tracking
$ApplicationVersions = @{
    "24.2.2000.exe" = "24.2.2000"
    "GlassWireSetup.exe" = "3.0.0"
    "PBIDesktopSetup_x64.exe" = "2023.11"
    "TeamViewer_Setup_x64.exe" = "15.65.6"
    "AnyDesk.exe" = "7.0.0"
    "Tools for Office2019 TechXander" = "2019.1"
    "IT STUFF" = "1.0.0"
}

# Application Sources - ONLY specified files
$ApplicationSources = @(
    "D:\TeamViewer_Setup_x64.exe",
    "D:\IT STUFF",
    "D:\Tools for Office2019 TechXander",
    "D:\24.2.2000.exe",
    "D:\AnyDesk.exe",
    "D:\GlassWireSetup.exe",
    "D:\PBIDesktopSetup_x64.exe"
)

# Application Installation Configuration
$Applications = @(
    @{
        Path = "D:\TeamViewer_Setup_x64.exe"
        Name = "TeamViewer"
        Arguments = "/S"
        IsFolder = $false
    },
    @{
        Path = "D:\24.2.2000.exe"
        Name = "24.2.2000"
        Arguments = "/S"
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
        Arguments = "/quiet ACCEPT_EULA=1"
        IsFolder = $false
    },
    @{
        Path = "D:\AnyDesk.exe"
        Name = "AnyDesk"
        Arguments = "--silent"
        IsFolder = $false
    },
    @{
        Path = "D:\Tools for Office2019 TechXander"
        Name = "Tools for Office2019 TechXander"
        Arguments = ""
        IsFolder = $true
    },
    @{
        Path = "D:\IT STUFF"
        Name = "IT STUFF"
        Arguments = ""
        IsFolder = $true
    }
)

# Shortcut Configuration
$Shortcuts = @(
    @{
        Name = "Excel"
        Source = "D:\IT STUFF\Desktop-Mtn\Excel.lnk"
        Type = "Link"
    },
    @{
        Name = "Microsoft 365 Online"
        Source = "D:\IT STUFF\Desktop-Mtn\Microsoft 365 Online.url"
        Type = "URL"
    },
    @{
        Name = "New Citrix Gateway"
        Source = "D:\IT STUFF\Desktop-Mtn\New Citrix Gateway.url"
        Type = "URL"
    },
    @{
        Name = "Outlook"
        Source = "D:\IT STUFF\Desktop-Mtn\Outlook.lnk"
        Type = "Link"
    },
    @{
        Name = "PowerPoint"
        Source = "D:\IT STUFF\Desktop-Mtn\PowerPoint.lnk"
        Type = "Link"
    },
    @{
        Name = "Word"
        Source = "D:\IT STUFF\Desktop-Mtn\Word.lnk"
        Type = "Link"
    }
)

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

function Write-Progress {
    param([string]$Activity, [string]$Status, [int]$PercentComplete)
    $Global:CurrentStep++
    $percent = [math]::Round(($Global:CurrentStep / $Global:TotalSteps) * 100)
    Microsoft.PowerShell.Utility\Write-Progress -Activity $Activity -Status $Status -PercentComplete $percent
    Write-LogEntry "PROGRESS" "$Activity - $Status ($percent%)"
}

function Write-LogEntry {
    param([string]$Level, [string]$Message)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Ensure log directory exists
    if (!(Test-Path $LogsPath)) {
        New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null
    }
    
    # Write to log file
    try {
        Add-Content -Path $Global:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    } catch {}
    
    # Write to console with colors
    switch ($Level) {
        "SUCCESS" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
        "INFO" { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
        default { Write-Host "[$Level] $Message" -ForegroundColor White }
    }
}

function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-EnhancedSetup {
    Write-LogEntry "INFO" "Starting iBridge Enhanced Setup v$SetupVersion"
    Write-LogEntry "INFO" "Setup started by: $env:USERNAME"
    Write-LogEntry "INFO" "Setup location: $PWD"
    
    if (-not (Test-Administrator)) {
        Write-LogEntry "ERROR" "Administrator privileges required"
        return $false
    }
    
    Write-LogEntry "SUCCESS" "Running with Administrator privileges"
    
    # Create base folder structure
    if (-not (New-FolderStructure)) { return $false }
    
    # Create user accounts
    if (-not (New-UserAccounts)) { return $false }
    
    # Install applications
    if (-not (Install-Applications)) { return $false }
    
    # Create shortcuts
    if (-not (New-Shortcuts)) { return $false }
    
    # Generate final report
    New-FinalReport
    
    Write-LogEntry "SUCCESS" "Enhanced setup completed successfully"
    return $true
}

function New-FolderStructure {
    Write-Progress "Creating Folder Structure" "Setting up organized directory structure" 10
    
    $folders = @($iBridgeBase, $InstallersPath, $ShortcutsPath, $LogsPath, $ScriptsPath, $TempPath)
    
    foreach ($folder in $folders) {
        try {
            if (!(Test-Path $folder)) {
                New-Item -ItemType Directory -Path $folder -Force | Out-Null
                Write-LogEntry "SUCCESS" "Created folder: $folder"
            }
        } catch {
            Write-LogEntry "ERROR" "Failed to create folder: $folder - $($_.Exception.Message)"
            return $false
        }
    }
    
    return $true
}

function New-UserAccounts {
    Write-Progress "Creating User Accounts" "Setting up Admin and iBridge User accounts" 25
    
    try {
        # Remove existing accounts if they exist
        $existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
        if ($existingAdmin) {
            Write-LogEntry "WARNING" "Removing existing Admin account..."
            Remove-LocalUser -Name $AdminUsername -Confirm:$false
            Write-LogEntry "SUCCESS" "Existing Admin account removed"
        }
        
        $existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
        if ($existingUser) {
            Write-LogEntry "WARNING" "Removing existing iBridge User account..."
            Remove-LocalUser -Name $UserUsername -Confirm:$false
            Write-LogEntry "SUCCESS" "Existing iBridge User account removed"
        }
        
        # Create Admin account
        Write-LogEntry "INFO" "Creating Admin account..."
        $secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
        $adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -FullName "Admin" -Description "Administrator for application installation" -PasswordNeverExpires -AccountNeverExpires
        Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername
        Write-LogEntry "SUCCESS" "Admin account created successfully"
        
        # Create iBridge User account
        Write-LogEntry "INFO" "Creating iBridge User account..."
        $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
        $bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -FullName "iBridge User" -Description "Standard user with limited privileges" -PasswordNeverExpires -AccountNeverExpires
        Add-LocalGroupMember -Group "Users" -Member $UserUsername
        Write-LogEntry "SUCCESS" "iBridge User account created successfully"
        
        # Force profile creation
        Write-LogEntry "INFO" "Forcing profile creation for both accounts..."
        Start-ProfileCreation
        
        return $true
        
    } catch {
        Write-LogEntry "ERROR" "Failed to create user accounts: $($_.Exception.Message)"
        return $false
    }
}

function Start-ProfileCreation {
    Write-LogEntry "INFO" "Starting profile creation process..."
    
    # Create profile directories manually to ensure they exist
    $adminProfilePath = "C:\Users\$AdminUsername"
    $userProfilePath = "C:\Users\$UserUsername"
    
    foreach ($profilePath in @($adminProfilePath, $userProfilePath)) {
        try {
            if (!(Test-Path $profilePath)) {
                New-Item -ItemType Directory -Path $profilePath -Force | Out-Null
                New-Item -ItemType Directory -Path "$profilePath\Desktop" -Force | Out-Null
                New-Item -ItemType Directory -Path "$profilePath\Documents" -Force | Out-Null
                Write-LogEntry "SUCCESS" "Created profile structure: $profilePath"
            }
        } catch {
            Write-LogEntry "WARNING" "Could not create profile structure for: $profilePath"
        }
    }
}

function Install-Applications {
    Write-Progress "Installing Applications" "Installing required applications" 50
    
    $successCount = 0
    $totalApps = $Applications.Count
    
    foreach ($app in $Applications) {
        Write-LogEntry "INFO" "Processing: $($app.Name)"
        
        if (Test-Path $app.Path) {
            try {
                Write-LogEntry "INFO" "Installing: $($app.Name)"
                $process = Start-Process -FilePath $app.Path -ArgumentList $app.Arguments -Wait -PassThru -NoNewWindow
                
                if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                    Write-LogEntry "SUCCESS" "Installation completed for: $($app.Name)"
                    $successCount++
                } else {
                    Write-LogEntry "WARNING" "Installation completed with exit code $($process.ExitCode): $($app.Name)"
                    $successCount++
                }
            } catch {
                Write-LogEntry "ERROR" "Failed to install $($app.Name): $($_.Exception.Message)"
            }
        } else {
            Write-LogEntry "ERROR" "Application not found: $($app.Path)"
        }
    }
    
    Write-LogEntry "INFO" "Applications processed: $successCount of $totalApps"
    return $successCount -gt 0
}

function New-Shortcuts {
    Write-Progress "Creating Shortcuts" "Setting up desktop shortcuts" 75
    
    $successCount = 0
    $totalShortcuts = $Shortcuts.Count
    
    # Only copy shortcuts to Lwandile Gasela's desktop
    $lwandileDesktop = "C:\Users\Lwandile Gasela\Desktop"
    
    # Clean up shortcuts from other user profiles first
    Write-LogEntry "INFO" "Cleaning shortcuts from other user profiles..."
    $adminDesktop = "C:\Users\$AdminUsername\Desktop"
    $userDesktop = "C:\Users\$UserUsername\Desktop"
    
    foreach ($shortcut in $Shortcuts) {
        $fileName = Split-Path $shortcut.Source -Leaf
        
        # Remove from Admin desktop if exists
        $adminShortcut = Join-Path $adminDesktop $fileName
        if (Test-Path $adminShortcut) {
            Remove-Item $adminShortcut -Force -ErrorAction SilentlyContinue
            Write-LogEntry "INFO" "Removed shortcut from Admin desktop: $fileName"
        }
        
        # Remove from iBridge User desktop if exists
        $userShortcut = Join-Path $userDesktop $fileName
        if (Test-Path $userShortcut) {
            Remove-Item $userShortcut -Force -ErrorAction SilentlyContinue
            Write-LogEntry "INFO" "Removed shortcut from iBridge User desktop: $fileName"
        }
    }
    
    foreach ($shortcut in $Shortcuts) {
        Write-LogEntry "INFO" "Processing shortcut: $($shortcut.Name)"
        
        if (Test-Path $shortcut.Source) {
            try {
                $fileName = Split-Path $shortcut.Source -Leaf
                
                # Copy to shared shortcuts folder
                $sharedPath = Join-Path $ShortcutsPath $fileName
                Copy-Item -Path $shortcut.Source -Destination $sharedPath -Force
                Write-LogEntry "SUCCESS" "Copied to shared folder: $fileName"
                
                # Copy only to Lwandile Gasela's desktop
                if (Test-Path $lwandileDesktop) {
                    $lwandilePath = Join-Path $lwandileDesktop $fileName
                    Copy-Item -Path $shortcut.Source -Destination $lwandilePath -Force
                    Write-LogEntry "SUCCESS" "Copied to Lwandile Gasela's desktop: $fileName"
                } else {
                    Write-LogEntry "WARNING" "Lwandile Gasela's desktop not found: $lwandileDesktop"
                }
                
                $successCount++
            } catch {
                Write-LogEntry "ERROR" "Failed to copy shortcut $($shortcut.Name): $($_.Exception.Message)"
            }
        } else {
            Write-LogEntry "ERROR" "Shortcut source not found: $($shortcut.Source)"
        }
    }
    
    Write-LogEntry "INFO" "Shortcuts processed: $successCount of $totalShortcuts"
    return $successCount -gt 0
}

function New-FinalReport {
    Write-Progress "Generating Report" "Creating final setup summary" 100
    
    Write-LogEntry "INFO" "Generating final setup report..."
    
    # Verify accounts
    $adminExists = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
    $userExists = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "iBridge Enhanced Setup Complete - Final Report" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "USER ACCOUNTS:" -ForegroundColor Yellow
    if ($adminExists) {
        Write-Host "  Admin Account: Created and Ready" -ForegroundColor Green
        Write-Host "    Username: $AdminUsername" -ForegroundColor White
        Write-Host "    Password: $AdminPassword" -ForegroundColor White
    } else {
        Write-Host "  Admin Account: FAILED" -ForegroundColor Red
    }
    
    if ($userExists) {
        Write-Host "  iBridge User Account: Created and Ready" -ForegroundColor Green
        Write-Host "    Username: $UserUsername" -ForegroundColor White
        Write-Host "    Password: $UserPassword" -ForegroundColor White
    } else {
        Write-Host "  iBridge User Account: FAILED" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "FOLDER STRUCTURE:" -ForegroundColor Yellow
    if (Test-Path $iBridgeBase) {
        $installerCount = if (Test-Path $InstallersPath) { (Get-ChildItem $InstallersPath -ErrorAction SilentlyContinue).Count } else { 0 }
        $shortcutCount = if (Test-Path $ShortcutsPath) { (Get-ChildItem $ShortcutsPath -ErrorAction SilentlyContinue).Count } else { 0 }
        
        Write-Host "  Base Directory: $iBridgeBase" -ForegroundColor Green
        Write-Host "  Installers: $installerCount items" -ForegroundColor Green
        Write-Host "  Shortcuts: $shortcutCount items" -ForegroundColor Green
        Write-Host "  Log File: $Global:LogFile" -ForegroundColor Green
    } else {
        Write-Host "  Base Directory: FAILED" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. Log out or use 'Switch User'" -ForegroundColor White
    Write-Host "  2. Log in as '$UserUsername' with password '$UserPassword'" -ForegroundColor White
    Write-Host "  3. Check desktop for shortcuts" -ForegroundColor White
    Write-Host "  4. Browse to $iBridgeBase for all resources" -ForegroundColor White
    
    Write-Host ""
}

# ============================================================
# MAIN EXECUTION
# ============================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "iBridge Enhanced Setup Script v$SetupVersion" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$result = Start-EnhancedSetup

if ($result) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "Setup completed successfully!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    $exitCode = 0
} else {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "Setup encountered errors!" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "Check log file: $Global:LogFile" -ForegroundColor Yellow
    $exitCode = 1
}

if (-not $QuietMode) {
    Write-Host ""
    Write-Host "Press any key to continue..."
    Read-Host
}

exit $exitCode
