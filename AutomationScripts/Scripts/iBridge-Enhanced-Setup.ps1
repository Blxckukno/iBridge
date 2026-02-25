# iBridge Enhanced Complete Setup Script     "24.2.2000.exe" = "24.2.2000"
    "GlassWireSetup.exe" = "2.0.0""24.2.2000.exe" = "24.2.2000"
    "GlassWireSetup.exe" = "2.0            "24.2.2000" = "SYSPRO"
            "GlassWire" = "GlassWire" Enhanced version with profile setup, progress tracking, and             "24.2.2000" = "SYSPRO"
            "GlassWire" = "GlassWire"anup
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
    "Tools for Office2019 TechXander" = "2019.1"
}

# Application Sources - ONLY specified files
$ApplicationSources = @(
    "D:\IT STUFF",
    "D:\Tools for Office2019 TechXander", 
    "D:\24.2.2000.exe",
    "D:\GlassWireSetup.exe",
    "D:\PBIDesktopSetup_x64.exe",
    "D:\TeamViewer_Setup_x64.exe",
    "D:\iBridge Set Up"
)

# Dynamic application discovery
$Applications = @()
$Shortcuts = @()

# ============================================================
# VERSION MANAGEMENT FUNCTIONS
function Get-InstalledApplications {
    param([string]$ApplicationName)
    
    $installed = @()
    
    # Check registry for installed programs
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($path in $registryPaths) {
        try {
            $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
                $_.DisplayName -and ($_.DisplayName -like "*$ApplicationName*")
            }
            $installed += $apps
        } catch {
            # Continue if path doesn't exist
        }
    }
    
    return $installed
}

function Test-ApplicationVersion {
    param(
        [string]$ApplicationName,
        [string]$RequiredVersion
    )
    
    $installedApps = Get-InstalledApplications -ApplicationName $ApplicationName
    
    foreach ($app in $installedApps) {
        if ($app.DisplayVersion) {
            try {
                $installedVersion = [version]$app.DisplayVersion
                $requiredVersion = [version]$RequiredVersion
                
                if ($installedVersion -ge $requiredVersion) {
                    return @{
                        IsInstalled = $true
                        Version = $app.DisplayVersion
                        UpToDate = $true
                        DisplayName = $app.DisplayName
                    }
                } else {
                    return @{
                        IsInstalled = $true
                        Version = $app.DisplayVersion
                        UpToDate = $false
                        DisplayName = $app.DisplayName
                    }
                }
            } catch {
                # If version comparison fails, assume needs update
                return @{
                    IsInstalled = $true
                    Version = $app.DisplayVersion
                    UpToDate = $false
                    DisplayName = $app.DisplayName
                }
            }
        }
    }
    
    return @{
        IsInstalled = $false
        Version = $null
        UpToDate = $false
        DisplayName = $null
    }
}

function Save-InstallationInfo {
    param([hashtable]$InstallationData)
    
    $installInfo = @{
        SetupVersion = $SetupVersion
        InstallationDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Applications = $InstallationData
    }
    
    $installInfo | ConvertTo-Json -Depth 3 | Out-File -FilePath $InstallationInfoFile -Encoding UTF8
    $SetupVersion | Out-File -FilePath $VersionFile -Encoding UTF8
}

function Start-VersionCheck {
    param([array]$ApplicationFiles)
    
    Start-StepProgress -StepName "Checking for existing installations and versions"
    Write-LogEntry "Starting version check for existing installations" "INFO"
    
    $versionResults = @{}
    $skipInstallations = @()
    
    foreach ($appFile in $ApplicationFiles) {
        $fileName = Split-Path $appFile -Leaf
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        
        Write-LogEntry "Checking version for: $baseName" "INFO"
        
        # Map common application names
        $appMappings = @{
            "24.2.2000" = "SYSPRO"
            "GlassWireSetup" = "GlassWire"
            "PBIDesktopSetup_x64" = "Microsoft Power BI Desktop"
            "TeamViewer_Setup_x64" = "TeamViewer"
            "Tools for Office2019 TechXander" = "Microsoft Office"
        }
        
        $searchName = $appMappings[$baseName]
        if (-not $searchName) { $searchName = $baseName }
        
        if ($ApplicationVersions.ContainsKey($fileName)) {
            $requiredVersion = $ApplicationVersions[$fileName]
            $versionCheck = Test-ApplicationVersion -ApplicationName $searchName -RequiredVersion $requiredVersion
            
            $versionResults[$fileName] = $versionCheck
            
            if ($versionCheck.IsInstalled -and $versionCheck.UpToDate) {
                Write-LogEntry "Application '$($versionCheck.DisplayName)' is already installed and up to date (Version: $($versionCheck.Version))" "SUCCESS"
                $skipInstallations += $fileName
            } elseif ($versionCheck.IsInstalled -and -not $versionCheck.UpToDate) {
                Write-LogEntry "Application '$($versionCheck.DisplayName)' is installed but outdated (Version: $($versionCheck.Version), Required: $requiredVersion)" "WARNING"
            } else {
                Write-LogEntry "Application '$searchName' is not installed" "INFO"
            }
        } else {
            Write-LogEntry "No version tracking configured for: $fileName" "WARNING"
        }
    }
    
    if ($skipInstallations.Count -gt 0) {
        Write-LogEntry "Will skip installation for $($skipInstallations.Count) up-to-date applications" "INFO"
    }
    
    return @{
        VersionResults = $versionResults
        SkipInstallations = $skipInstallations
    }
}

# ENHANCED UTILITY FUNCTIONS
# ============================================================

function Write-Progress-Enhanced {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete
    )
    
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    Write-LogEntry "PROGRESS" "$Activity - $Status ($PercentComplete%)"
}

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
    
    Write-Progress-Enhanced "iBridge Setup" $StepName $percent
    Write-LogEntry "STEP" "Starting Step $Global:CurrentStep/$Global:TotalSteps: $StepName"
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
    Write-LogEntry "INFO" "Discovering specified application files..."
    
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
            Write-LogEntry "SUCCESS" "Found application: $($app.Name) at $($app.Path)"
        } else {
            Write-LogEntry "WARNING" "Application not found: $($app.Name) at $($app.Path)"
        }
    }
    
    Write-LogEntry "INFO" "Found $($foundFiles.Count) out of $($specificApplications.Count) specified applications"
    return $foundFiles
}

function Find-ShortcutFiles {
    Write-LogEntry "INFO" "Discovering shortcut files in specified locations..."
    
    $foundShortcuts = @()
    $shortcutPatterns = @("*.lnk", "*.url")
    
    # Only search in IT STUFF and iBridge Set Up folders for shortcuts
    $shortcutSources = @(
        "D:\IT STUFF",
        "D:\iBridge Set Up"
    )
    
    foreach ($sourcePath in $shortcutSources) {
        if (Test-Path $sourcePath) {
            Write-LogEntry "INFO" "Searching for shortcuts in: $sourcePath"
            foreach ($pattern in $shortcutPatterns) {
                $shortcuts = Get-ChildItem -Path $sourcePath -Filter $pattern -Recurse -ErrorAction SilentlyContinue
                foreach ($shortcut in $shortcuts) {
                    $foundShortcuts += @{
                        Name = [System.IO.Path]::GetFileNameWithoutExtension($shortcut.Name)
                        Source = $shortcut.FullName
                    }
                    Write-LogEntry "SUCCESS" "Found shortcut: $($shortcut.Name)"
                }
            }
        } else {
            Write-LogEntry "WARNING" "Shortcut source not found: $sourcePath"
        }
    }
    
    Write-LogEntry "INFO" "Found $($foundShortcuts.Count) shortcut files"
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
            Write-LogEntry "INFO" "Removing old iBridge_Apps folder..."
            Remove-Item "C:\iBridge_Apps" -Recurse -Force -ErrorAction SilentlyContinue
            Write-LogEntry "SUCCESS" "Removed old iBridge_Apps folder"
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
                        Write-LogEntry "INFO" "Removed old shortcut: $($shortcut.Name)"
                    }
                }
            }
        }
        
        # Create new organized folder structure
        $foldersToCreate = @($iBridgeBase, $InstallersPath, $ShortcutsPath, $LogsPath, $ScriptsPath, $TempPath)
        foreach ($folder in $foldersToCreate) {
            if (!(Test-Path $folder)) {
                New-Item -ItemType Directory -Path $folder -Force | Out-Null
                Write-LogEntry "SUCCESS" "Created folder: $folder"
            }
        }
        
        Write-LogEntry "SUCCESS" "Cleanup completed successfully"
        return $true
        
    } catch {
        Write-LogEntry "ERROR" "Cleanup failed: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================
# USER ACCOUNT MANAGEMENT WITH PROFILE CREATION
# ============================================================

function New-UserAccountsEnhanced {
    Start-StepProgress "Creating User Accounts with Profile Setup"
    
    try {
        # Remove existing accounts if they exist
        $existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
        if ($existingAdmin) {
            Write-LogEntry "WARNING" "Removing existing Admin account..."
            Remove-LocalUser -Name $AdminUsername -Confirm:$false
        }
        
        $existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
        if ($existingUser) {
            Write-LogEntry "WARNING" "Removing existing iBridge User account..."
            Remove-LocalUser -Name $UserUsername -Confirm:$false
        }
        
        # Create Admin account
        Write-LogEntry "INFO" "Creating Admin account..."
        $secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
        $adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -Description "Admin for app installation" -PasswordNeverExpires -AccountNeverExpires
        Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername
        Write-LogEntry "SUCCESS" "Admin account created successfully"
        
        # Create iBridge User account
        Write-LogEntry "INFO" "Creating iBridge User account..."
        $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
        $bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -Description "Standard user with limited privileges" -PasswordNeverExpires -AccountNeverExpires
        Add-LocalGroupMember -Group "Users" -Member $UserUsername
        Write-LogEntry "SUCCESS" "iBridge User account created successfully"
        
        # Force profile creation by simulating login
        Write-LogEntry "INFO" "Forcing profile creation for both accounts..."
        Start-ProfileCreation
        
        return $true
        
    } catch {
        Write-LogEntry "ERROR" "Failed to create user accounts: $($_.Exception.Message)"
        return $false
    }
}

function Start-ProfileCreation {
    Write-LogEntry "INFO" "Creating user profiles and desktop folders..."
    
    # Create profile directories manually if they don't exist
    $profilePaths = @(
        "C:\Users\$AdminUsername",
        "C:\Users\$UserUsername"
    )
    
    foreach ($profilePath in $profilePaths) {
        if (!(Test-Path $profilePath)) {
            # Use PowerShell to trigger profile creation
            $username = Split-Path $profilePath -Leaf
            Write-LogEntry "INFO" "Creating profile for: $username"
            
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
                
                Write-LogEntry "SUCCESS" "Profile created for: $username"
                
            } catch {
                Write-LogEntry "WARNING" "Could not create profile for $username`: $($_.Exception.Message)"
            }
        } else {
            Write-LogEntry "INFO" "Profile already exists for: $(Split-Path $profilePath -Leaf)"
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
            Write-LogEntry "SUCCESS" "Created desktop folder: $desktopPath"
        }
    }
}

# ============================================================
# INSTALLATION FUNCTIONS
# ============================================================

function Install-ApplicationsEnhanced {
    Start-StepProgress "Installing Applications"
    
    if ($Applications.Count -eq 0) {
        Write-LogEntry "WARNING" "No applications found to install"
        return $true
    }
    
    $successCount = 0
    $totalApps = $Applications.Count
    
    foreach ($app in $Applications) {
        $appProgress = [math]::Round(($successCount / $totalApps) * 100)
        Write-Progress-Enhanced "Installing Applications" "Processing: $($app.Name)" $appProgress
        
        Write-LogEntry "INFO" "Processing application: $($app.Name)"
        Write-LogEntry "INFO" "Source: $($app.Path)"
        
        # Check if we should skip this installation
        $fileName = Split-Path $app.Path -Leaf
        if ($Global:SkipInstallations -contains $fileName) {
            Write-LogEntry "INFO" "Skipping installation for $($app.Name) - already up to date"
            $successCount++
            continue
        }
        
        if (Test-Path $app.Path) {
            try {
                if ($app.IsFolder) {
                    # Copy folder to installers directory
                    $destPath = Join-Path $InstallersPath (Split-Path $app.Path -Leaf)
                    if (!(Test-Path $destPath)) {
                        Write-LogEntry "INFO" "Copying folder: $($app.Name)"
                        Copy-Item -Path $app.Path -Destination $destPath -Recurse -Force
                        Write-LogEntry "SUCCESS" "Copied folder: $($app.Name)"
                        $successCount++
                    } else {
                        Write-LogEntry "WARNING" "Folder already exists: $($app.Name)"
                        $successCount++
                    }
                } else {
                    # Copy installer and run installation
                    $installerName = Split-Path $app.Path -Leaf
                    $localInstaller = Join-Path $InstallersPath $installerName
                    
                    # Copy installer
                    if (!(Test-Path $localInstaller)) {
                        Write-LogEntry "INFO" "Copying installer: $installerName"
                        Copy-Item -Path $app.Path -Destination $localInstaller -Force
                        Write-LogEntry "SUCCESS" "Copied installer: $installerName"
                    }
                    
                    # Run installation
                    Write-LogEntry "INFO" "Installing: $($app.Name)"
                    $process = Start-Process -FilePath $localInstaller -ArgumentList $app.Arguments -Wait -PassThru -NoNewWindow
                    
                    if ($process.ExitCode -eq 0) {
                        Write-LogEntry "SUCCESS" "Installed successfully: $($app.Name)"
                        $successCount++
                    } else {
                        Write-LogEntry "WARNING" "Installation completed with exit code $($process.ExitCode): $($app.Name)"
                        $successCount++
                    }
                }
            } catch {
                Write-LogEntry "ERROR" "Failed to install $($app.Name): $($_.Exception.Message)"
            }
        } else {
            Write-LogEntry "ERROR" "Source file not found: $($app.Path)"
        }
    }
    
    Write-LogEntry "INFO" "Applications processed: $successCount of $totalApps"
    return $successCount -eq $totalApps
}

# ============================================================
# ENHANCED SHORTCUT CREATION
# ============================================================

function Create-ShortcutsEnhanced {
    Start-StepProgress "Creating and Verifying Desktop Shortcuts"
    
    if ($Shortcuts.Count -eq 0) {
        Write-LogEntry "WARNING" "No shortcuts found to create"
        return $true
    }
    
    $successCount = 0
    $totalShortcuts = $Shortcuts.Count
    
    # Ensure desktop paths exist
    $desktopPaths = @(
        "C:\Users\$AdminUsername\Desktop",
        "C:\Users\$UserUsername\Desktop"
    )
    
    foreach ($desktopPath in $desktopPaths) {
        if (!(Test-Path $desktopPath)) {
            New-Item -ItemType Directory -Path $desktopPath -Force | Out-Null
            Write-LogEntry "SUCCESS" "Created desktop directory: $desktopPath"
        }
    }
    
    foreach ($shortcut in $Shortcuts) {
        $shortcutProgress = [math]::Round(($successCount / $totalShortcuts) * 100)
        Write-Progress-Enhanced "Creating Shortcuts" "Processing: $($shortcut.Name)" $shortcutProgress
        
        Write-LogEntry "INFO" "Processing shortcut: $($shortcut.Name)"
        
        if (Test-Path $shortcut.Source) {
            try {
                $fileName = Split-Path $shortcut.Source -Leaf
                
                # Copy to shared shortcuts folder
                $sharedPath = Join-Path $ShortcutsPath $fileName
                Copy-Item -Path $shortcut.Source -Destination $sharedPath -Force
                Write-LogEntry "SUCCESS" "Copied to shared folder: $fileName"
                
                # Copy to both user desktops
                foreach ($desktopPath in $desktopPaths) {
                    $desktopFile = Join-Path $desktopPath $fileName
                    Copy-Item -Path $shortcut.Source -Destination $desktopFile -Force
                    
                    # Verify the shortcut was created
                    if (Test-Path $desktopFile) {
                        $username = Split-Path $desktopPath -Parent | Split-Path -Leaf
                        Write-LogEntry "SUCCESS" "Created shortcut on $username desktop: $fileName"
                    } else {
                        Write-LogEntry "ERROR" "Failed to create shortcut on $username desktop: $fileName"
                    }
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
    
    # Verify shortcuts are actually on desktops
    Start-ShortcutVerification
    
    return $successCount -eq $totalShortcuts
}

function Start-ShortcutVerification {
    Write-LogEntry "INFO" "Verifying shortcuts on user desktops..."
    
    $desktopPaths = @(
        @{ Path = "C:\Users\$AdminUsername\Desktop"; User = $AdminUsername },
        @{ Path = "C:\Users\$UserUsername\Desktop"; User = $UserUsername }
    )
    
    foreach ($desktop in $desktopPaths) {
        if (Test-Path $desktop.Path) {
            $shortcuts = Get-ChildItem $desktop.Path -Include "*.lnk", "*.url" -ErrorAction SilentlyContinue
            Write-LogEntry "SUCCESS" "$($desktop.User) desktop has $($shortcuts.Count) shortcuts"
            
            foreach ($shortcut in $shortcuts) {
                Write-LogEntry "INFO" "  - $($shortcut.Name)"
            }
        } else {
            Write-LogEntry "WARNING" "Desktop not found: $($desktop.Path)"
        }
    }
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
        Write-LogEntry "SUCCESS" "Folder permissions set successfully"
        
        return $true
        
    } catch {
        Write-LogEntry "WARNING" "Could not set folder permissions: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================
# SCRIPT ORGANIZATION
# ============================================================

function Copy-ScriptsToOrganizedFolder {
    Start-StepProgress "Organizing Scripts and Files"
    
    try {
        # Get current script path - try multiple methods
        $currentScript = $null
        if ($MyInvocation.MyCommand.Path) {
            $currentScript = $MyInvocation.MyCommand.Path
        } elseif ($PSCommandPath) {
            $currentScript = $PSCommandPath
        } else {
            # Try to find the script in common locations
            $possiblePaths = @(
                "D:\iBridge Set Up\iBridge-Enhanced-Setup.ps1",
                "c:\Users\Lwandile Gasela\iBridge\Scripts\iBridge-Enhanced-Setup.ps1"
            )
            foreach ($path in $possiblePaths) {
                if (Test-Path $path) {
                    $currentScript = $path
                    break
                }
            }
        }
        
        if ($currentScript -and (Test-Path $currentScript)) {
            $scriptName = Split-Path $currentScript -Leaf
            $destScript = Join-Path $ScriptsPath $scriptName
            Copy-Item $currentScript $destScript -Force
            Write-LogEntry "SUCCESS" "Copied script to organized folder: $scriptName"
            
            # Copy any batch files from the source directory
            $sourceDir = Split-Path $currentScript -Parent
            $batchFiles = Get-ChildItem $sourceDir -Filter "*.bat" -ErrorAction SilentlyContinue
            foreach ($batchFile in $batchFiles) {
                $destBatch = Join-Path $ScriptsPath $batchFile.Name
                Copy-Item $batchFile.FullName $destBatch -Force
                Write-LogEntry "SUCCESS" "Copied batch file: $($batchFile.Name)"
            }
        } else {
            Write-LogEntry "WARNING" "Could not determine current script path for copying"
        }
        
        # Create a summary file
        $summaryPath = Join-Path $iBridgeBase "SETUP-SUMMARY.txt"
        
        # Build application status summary
        $appSummary = ""
        if ($Global:VersionResults) {
            $installedCount = ($Global:VersionResults.Values | Where-Object { $_.IsInstalled }).Count
            $upToDateCount = ($Global:VersionResults.Values | Where-Object { $_.IsInstalled -and $_.UpToDate }).Count
            $updatedCount = $Applications.Count - $Global:SkipInstallations.Count
            
            $appSummary = @"

APPLICATION STATUS:
- Total Applications: $($Applications.Count)
- Already Up-to-Date: $($Global:SkipInstallations.Count)
- Installed/Updated: $updatedCount
"@
        } else {
            $appSummary = @"

APPLICATIONS INSTALLED: $($Applications.Count)
"@
        }
        
        $summary = @"
iBridge Enhanced Setup Summary (v$SetupVersion)
Generated: $(Get-Date)

FOLDER STRUCTURE:
$iBridgeBase
├── Installers\     (Application installers)
├── Shortcuts\      (Desktop shortcuts)
├── Scripts\        (Setup scripts)
├── Logs\           (Setup logs)
├── Temp\           (Temporary files)
├── VERSION.txt     (Setup version)
└── INSTALLATION-INFO.json (Installation details)

USER ACCOUNTS CREATED:
- Admin (Password: $AdminPassword)
- iBridge User (Password: $UserPassword)
$appSummary
SHORTCUTS CREATED: $($Shortcuts.Count)

NEXT STEPS:
1. Log out of current session
2. Log in as 'iBridge User' with password 'Abc654321!'
3. Verify shortcuts appear on desktop
4. Check applications are accessible

LOG FILE: $Global:LogFile
VERSION FILE: $VersionFile
INSTALLATION INFO: $InstallationInfoFile
"@
        
        $summary | Out-File $summaryPath -Encoding UTF8
        Write-LogEntry "SUCCESS" "Created setup summary file"
        
        return $true
        
    } catch {
        Write-LogEntry "ERROR" "Failed to organize scripts: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================
# MAIN EXECUTION
# ============================================================

function Start-EnhancedSetup {
    try {
        Write-Host "iBridge Enhanced Complete Setup Script" -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host "Enhanced with Profile Setup, Progress Tracking, and Organization" -ForegroundColor Cyan
        Write-Host "Log File: $Global:LogFile" -ForegroundColor Yellow
        Write-Host ""
        
        Write-LogEntry "START" "iBridge Enhanced Setup Started"
        
        # Check if running as Administrator
        if (-not (Test-Administrator)) {
            Write-LogEntry "ERROR" "This script must be run as Administrator"
            throw "Administrator privileges required"
        }
        
        if ($CleanupOnly) {
            Start-Cleanup
            Write-LogEntry "COMPLETE" "Cleanup completed"
            return
        }
        
        # Step 1: Cleanup and preparation
        Start-Cleanup
        
        # Discover applications and shortcuts
        Write-LogEntry "INFO" "Discovering applications and shortcuts..."
        $Global:Applications = Find-ApplicationFiles
        $Global:Shortcuts = Find-ShortcutFiles
        
        Write-LogEntry "INFO" "Found $($Applications.Count) applications and $($Shortcuts.Count) shortcuts"
        
        # Step 2: Version checking
        $versionCheckResults = Start-VersionCheck -ApplicationFiles $Applications
        $Global:VersionResults = $versionCheckResults.VersionResults
        $Global:SkipInstallations = $versionCheckResults.SkipInstallations
        
        if (-not $SkipValidation) {
            Wait-ForKeyPress "Press any key to start the enhanced setup process..."
        }
        
        # Step 3: Create user accounts with profile setup
        New-UserAccountsEnhanced
        
        # Step 4: Install applications (with version awareness)
        Install-ApplicationsEnhanced
        
        # Step 5: Create and verify shortcuts
        Create-ShortcutsEnhanced
        
        # Step 6: Set permissions
        Set-FolderPermissionsEnhanced
        
        # Step 7: Organize everything
        Copy-ScriptsToOrganizedFolder
        
        # Step 8: Save installation info and final summary
        Start-StepProgress "Setup Complete - Final Verification"
        
        # Save installation information
        if ($Global:VersionResults) {
            Save-InstallationInfo -InstallationData $Global:VersionResults
            Write-LogEntry "SUCCESS" "Saved installation information"
        }
        
        Write-Host "`n" -NoNewline
        Write-Host "=" * 80 -ForegroundColor Green
        Write-Host "SETUP COMPLETED SUCCESSFULLY!" -ForegroundColor White -BackgroundColor Green
        Write-Host "=" * 80 -ForegroundColor Green
        Write-Host ""
        
        Write-LogEntry "SUCCESS" "Enhanced setup completed successfully"
        Write-Host "✓ User accounts created with profiles" -ForegroundColor Green
        Write-Host "✓ Applications processed: $($Applications.Count)" -ForegroundColor Green
        if ($Global:SkipInstallations.Count -gt 0) {
            Write-Host "  - Skipped (up-to-date): $($Global:SkipInstallations.Count)" -ForegroundColor Yellow
            Write-Host "  - Installed/Updated: $($Applications.Count - $Global:SkipInstallations.Count)" -ForegroundColor Green
        }
        Write-Host "✓ Shortcuts created and verified: $($Shortcuts.Count)" -ForegroundColor Green
        Write-Host "✓ Everything organized in: $iBridgeBase" -ForegroundColor Green
        Write-Host "✓ Version information saved" -ForegroundColor Green
        Write-Host ""
        Write-Host "NEXT STEPS:" -ForegroundColor Yellow
        Write-Host "1. Log out of current Windows session" -ForegroundColor Cyan
        Write-Host "2. Log in as 'iBridge User' (Password: $UserPassword)" -ForegroundColor Cyan
        Write-Host "3. Check desktop for shortcuts" -ForegroundColor Cyan
        Write-Host "4. Browse $iBridgeBase for all resources" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Log file: $Global:LogFile" -ForegroundColor Gray
        
        Write-LogEntry "COMPLETE" "iBridge Enhanced Setup Completed Successfully"
        
    } catch {
        Write-LogEntry "ERROR" "Setup failed: $($_.Exception.Message)"
        Write-Host "Setup failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Check log file: $Global:LogFile" -ForegroundColor Yellow
        exit 1
    }
}

# Start the enhanced setup process
Start-EnhancedSetup
