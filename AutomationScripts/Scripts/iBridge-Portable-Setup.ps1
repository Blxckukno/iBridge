# iBridge Portable Complete Setup Script
# Master script that performs the entire setup process
# Creates user accounts, installs applications, and sets up shortcuts
# PORTABLE VERSION - Works from any drive/location

param(
    [switch]$SkipValidation,
    [switch]$QuietMode
)

# ============================================================
# PORTABLE CONFIGURATION SECTION
# ============================================================

# Get the directory where this script is located (portable detection)
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Script running from: $ScriptRoot" -ForegroundColor Green

# Look for application files in common locations relative to script
$PossibleAppPaths = @(
    $ScriptRoot                          # Same folder as script
    "$ScriptRoot\Apps"                   # Apps subfolder
    "$ScriptRoot\Applications"           # Applications subfolder
    "$ScriptRoot\Installers"             # Installers subfolder
    (Split-Path -Parent $ScriptRoot)     # Parent folder
)

# Function to find application file
function Find-AppFile {
    param($FileName)
    
    foreach ($BasePath in $PossibleAppPaths) {
        $FullPath = Join-Path $BasePath $FileName
        if (Test-Path $FullPath) {
            Write-Host "Found $FileName at: $FullPath" -ForegroundColor Cyan
            return $FullPath
        }
    }
    
    Write-Warning "Could not find $FileName in any of the expected locations"
    Write-Host "Searched in:" -ForegroundColor Yellow
    foreach ($Path in $PossibleAppPaths) {
        Write-Host "  - $Path" -ForegroundColor Yellow
    }
    return $null
}

# Account Configuration
$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

# Destination folder (always on C: drive)
$DestinationFolder = "C:\iBridge_Apps"

# Application Configuration - Dynamic Path Detection
$ApplicationFiles = @(
    "TeamViewer_Setup_x64.exe",
    "Tools for Office2019 TechXander",
    "24.2.2000.exe",
    "PBIDesktopSetup_x64.exe",
    "Teams_windows_x64.exe"
)

# Build dynamic application list
$Applications = @()
foreach ($AppFile in $ApplicationFiles) {
    $AppPath = Find-AppFile $AppFile
    if ($AppPath) {
        $App = @{
            Name = [System.IO.Path]::GetFileNameWithoutExtension($AppFile)
            Path = $AppPath
            Description = "Application: $AppFile"
        }
        
        # Set specific arguments and properties based on app type
        switch -Wildcard ($AppFile) {
            "TeamViewer*" { 
                $App.Arguments = "/S"
                $App.Description = "Remote desktop software"
            }
            "Tools for Office*" { 
                $App.Arguments = ""
                $App.Description = "Office tools suite"
                $App.IsFolder = $true
            }
            "24.2.2000*" { 
                $App.Arguments = "/SILENT"
                $App.Description = "Business application"
            }
            "PBIDesktop*" { 
                $App.Arguments = "/quiet"
                $App.Description = "Microsoft Power BI Desktop"
            }
            "Teams*" { 
                $App.Arguments = "/S"
                $App.Description = "Microsoft Teams"
            }
            default {
                $App.Arguments = ""
            }
        }
        
        $Applications += $App
    }
}

# Display found applications
Write-Host "`nFound Applications:" -ForegroundColor Green
foreach ($App in $Applications) {
    Write-Host "  - $($App.Name) at $($App.Path)" -ForegroundColor Cyan
}

if ($Applications.Count -eq 0) {
    Write-Warning "No application files found! The script will only create user accounts."
    Write-Host "Please ensure application files are in one of these locations:" -ForegroundColor Yellow
    foreach ($Path in $PossibleAppPaths) {
        Write-Host "  - $Path" -ForegroundColor Yellow
    }
}

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

function Write-StepHeader {
    param([string]$Step, [string]$Description)
    
    Write-Host "`n" -NoNewline
    Write-Host "=" * 70 -ForegroundColor Blue
    Write-Host "${Step}: $Description" -ForegroundColor White -BackgroundColor Blue
    Write-Host "=" * 70 -ForegroundColor Blue
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
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
# VALIDATION FUNCTIONS
# ============================================================

function Test-Prerequisites {
    Write-StepHeader "STEP 1" "Validating Prerequisites"
    
    $allGood = $true
    
    # Check if running as Administrator
    if (-not (Test-Administrator)) {
        Write-Error "This script must be run as Administrator"
        $allGood = $false
    } else {
        Write-Success "Running with Administrator privileges"
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "PowerShell 5.0 or higher is required"
        $allGood = $false
    } else {
        Write-Success "PowerShell version $($PSVersionTable.PSVersion) is supported"
    }
    
    # Check if destination folder can be created
    try {
        if (-not (Test-Path $DestinationFolder)) {
            New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
            Write-Success "Created destination folder: $DestinationFolder"
        } else {
            Write-Success "Destination folder exists: $DestinationFolder"
        }
    } catch {
        Write-Error "Cannot create destination folder: $($_.Exception.Message)"
        $allGood = $false
    }
    
    # Check application files
    $foundApps = 0
    foreach ($App in $Applications) {
        if (Test-Path $App.Path) {
            Write-Success "Found: $($App.Name)"
            $foundApps++
        } else {
            Write-Error "Missing: $($App.Name) at $($App.Path)"
        }
    }
    
    if ($foundApps -eq 0) {
        Write-Error "No application files found"
        Write-Info "The script will only create user accounts"
    } else {
        Write-Success "Found $foundApps application(s)"
    }
    
    if (-not $allGood) {
        throw "Prerequisites validation failed"
    }
    
    Write-Success "All prerequisites validated successfully"
    return $allGood
}

# ============================================================
# USER ACCOUNT MANAGEMENT
# ============================================================

function New-UserAccount {
    param(
        [string]$Username,
        [string]$Password,
        [string]$Description,
        [bool]$IsAdmin = $false
    )
    
    try {
        # Check if user already exists
        $existingUser = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
        if ($existingUser) {
            Write-Info "User '$Username' already exists, skipping creation"
            
            # Update password
            $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
            Set-LocalUser -Name $Username -Password $securePassword
            Write-Success "Updated password for user '$Username'"
        } else {
            # Create new user
            $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
            New-LocalUser -Name $Username -Password $securePassword -Description $Description -PasswordNeverExpires
            Write-Success "Created user account: $Username"
        }
        
        # Add to appropriate group
        if ($IsAdmin) {
            try {
                Add-LocalGroupMember -Group "Administrators" -Member $Username -ErrorAction SilentlyContinue
                Write-Success "Added '$Username' to Administrators group"
            } catch {
                Write-Info "User '$Username' is already in Administrators group"
            }
        } else {
            try {
                Add-LocalGroupMember -Group "Users" -Member $Username -ErrorAction SilentlyContinue
                Write-Success "Added '$Username' to Users group"
            } catch {
                Write-Info "User '$Username' is already in Users group"
            }
        }
        
        return $true
    } catch {
        Write-Error "Failed to create user '$Username': $($_.Exception.Message)"
        return $false
    }
}

function Initialize-UserAccounts {
    Write-StepHeader "STEP 2" "Creating User Accounts"
    
    # Create Admin account
    Write-Info "Creating Administrator account..."
    $adminSuccess = New-UserAccount -Username $AdminUsername -Password $AdminPassword -Description "iBridge Administrator Account" -IsAdmin $true
    
    # Create standard user account
    Write-Info "Creating standard user account..."
    $userSuccess = New-UserAccount -Username $UserUsername -Password $UserPassword -Description "iBridge Standard User Account" -IsAdmin $false
    
    if ($adminSuccess -and $userSuccess) {
        Write-Success "All user accounts created successfully"
    } else {
        throw "Failed to create one or more user accounts"
    }
}

# ============================================================
# APPLICATION INSTALLATION
# ============================================================

function Install-Application {
    param($AppConfig)
    
    Write-Info "Installing: $($AppConfig.Name)"
    Write-Info "Source: $($AppConfig.Path)"
    
    try {
        if ($AppConfig.IsFolder) {
            # Handle folder copy
            $destinationPath = Join-Path $DestinationFolder $AppConfig.Name
            
            if (Test-Path $destinationPath) {
                Write-Info "Removing existing folder: $destinationPath"
                Remove-Item $destinationPath -Recurse -Force
            }
            
            Write-Info "Copying folder to: $destinationPath"
            Copy-Item $AppConfig.Path $destinationPath -Recurse -Force
            Write-Success "Copied folder: $($AppConfig.Name)"
        } else {
            # Handle executable installation
            $destinationPath = Join-Path $DestinationFolder (Split-Path $AppConfig.Path -Leaf)
            
            Write-Info "Copying installer to: $destinationPath"
            Copy-Item $AppConfig.Path $destinationPath -Force
            
            if ($AppConfig.Arguments) {
                Write-Info "Running installer with arguments: $($AppConfig.Arguments)"
                $process = Start-Process $destinationPath -ArgumentList $AppConfig.Arguments -Wait -PassThru
            } else {
                Write-Info "Running installer without arguments"
                $process = Start-Process $destinationPath -Wait -PassThru
            }
            
            if ($process.ExitCode -eq 0) {
                Write-Success "Installed: $($AppConfig.Name)"
            } else {
                Write-Error "Installation failed with exit code: $($process.ExitCode)"
            }
        }
    } catch {
        Write-Error "Failed to install $($AppConfig.Name): $($_.Exception.Message)"
        throw
    }
}

function Install-AllApplications {
    Write-StepHeader "STEP 3" "Installing Applications"
    
    if ($Applications.Count -eq 0) {
        Write-Info "No applications to install"
        return
    }
    
    $successCount = 0
    $totalCount = $Applications.Count
    
    foreach ($App in $Applications) {
        try {
            Install-Application $App
            $successCount++
        } catch {
            Write-Error "Failed to install $($App.Name)"
        }
    }
    
    Write-Success "Installation complete: $successCount/$totalCount applications installed"
}

# ============================================================
# SHORTCUT MANAGEMENT
# ============================================================

function New-DesktopShortcut {
    param(
        [string]$Name,
        [string]$TargetPath,
        [string]$UserProfile,
        [string]$Arguments = "",
        [string]$WorkingDirectory = "",
        [string]$IconLocation = ""
    )
    
    try {
        $desktopPath = Join-Path $UserProfile "Desktop"
        if (-not (Test-Path $desktopPath)) {
            New-Item $desktopPath -ItemType Directory -Force | Out-Null
        }
        
        $shortcutPath = Join-Path $desktopPath "$Name.lnk"
        
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = $TargetPath
        
        if ($Arguments) { $Shortcut.Arguments = $Arguments }
        if ($WorkingDirectory) { $Shortcut.WorkingDirectory = $WorkingDirectory }
        if ($IconLocation) { $Shortcut.IconLocation = $IconLocation }
        
        $Shortcut.Save()
        Write-Success "Created shortcut: $Name for user profile $UserProfile"
        
        return $true
    } catch {
        Write-Error "Failed to create shortcut '$Name': $($_.Exception.Message)"
        return $false
    }
}

function Get-UserProfiles {
    try {
        $profiles = @()
        
        # Get Admin profile
        $adminProfile = "C:\Users\$AdminUsername"
        if (Test-Path $adminProfile) {
            $profiles += @{ Name = $AdminUsername; Path = $adminProfile }
        }
        
        # Get iBridge User profile
        $userProfile = "C:\Users\$UserUsername"
        if (Test-Path $userProfile) {
            $profiles += @{ Name = $UserUsername; Path = $userProfile }
        }
        
        return $profiles
    } catch {
        Write-Error "Failed to get user profiles: $($_.Exception.Message)"
        return @()
    }
}

function Find-InstalledApplications {
    $shortcuts = @()
    
    # Common application paths to check
    $commonPaths = @(
        "C:\Program Files\TeamViewer\TeamViewer.exe",
        "C:\Program Files (x86)\TeamViewer\TeamViewer.exe",
        "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe",
        "C:\Users\$env:USERNAME\AppData\Local\Microsoft\Teams\current\Teams.exe",
        "C:\Program Files\Microsoft\Teams\current\Teams.exe",
        "C:\Program Files (x86)\Microsoft\Teams\current\Teams.exe"
    )
    
    # Check iBridge_Apps folder
    if (Test-Path $DestinationFolder) {
        $appFiles = Get-ChildItem $DestinationFolder -Recurse -Include "*.exe" | Where-Object { $_.Name -notmatch "unins" }
        foreach ($file in $appFiles) {
            $shortcuts += @{
                Name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                Path = $file.FullName
                WorkingDir = $file.DirectoryName
            }
        }
        
        # Check for Tools for Office folder
        $officeToolsPath = Join-Path $DestinationFolder "Tools for Office2019 TechXander"
        if (Test-Path $officeToolsPath) {
            $shortcuts += @{
                Name = "Tools for Office 2019"
                Path = $officeToolsPath
                WorkingDir = $officeToolsPath
            }
        }
    }
    
    # Check common installation paths
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($path)
            $shortcuts += @{
                Name = $name
                Path = $path
                WorkingDir = Split-Path $path -Parent
            }
        }
    }
    
    return $shortcuts
}

function Create-AllShortcuts {
    Write-StepHeader "STEP 4" "Creating Desktop Shortcuts"
    
    $userProfiles = Get-UserProfiles
    $shortcuts = Find-InstalledApplications
    
    if ($shortcuts.Count -eq 0) {
        Write-Info "No applications found for shortcut creation"
        return
    }
    
    Write-Info "Found $($shortcuts.Count) applications for shortcut creation"
    
    $totalCreated = 0
    foreach ($profile in $userProfiles) {
        Write-Info "Creating shortcuts for user: $($profile.Name)"
        
        foreach ($shortcut in $shortcuts) {
            $success = New-DesktopShortcut -Name $shortcut.Name -TargetPath $shortcut.Path -UserProfile $profile.Path -WorkingDirectory $shortcut.WorkingDir
            if ($success) { $totalCreated++ }
        }
    }
    
    Write-Success "Created $totalCreated desktop shortcuts across all user profiles"
}

# ============================================================
# FOLDER PERMISSIONS
# ============================================================

function Set-FolderPermissions {
    Write-StepHeader "STEP 5" "Configuring Folder Permissions"
    
    try {
        if (-not (Test-Path $DestinationFolder)) {
            Write-Error "Destination folder does not exist: $DestinationFolder"
            return
        }
        
        # Get current ACL
        $acl = Get-Acl $DestinationFolder
        
        # Add full control for Administrators
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($adminRule)
        
        # Add read and execute for Users
        $userRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($userRule)
        
        # Apply the ACL
        Set-Acl $DestinationFolder $acl
        Write-Success "Configured permissions for: $DestinationFolder"
        
    } catch {
        Write-Error "Failed to set folder permissions: $($_.Exception.Message)"
    }
}

# ============================================================
# MAIN EXECUTION
# ============================================================

function Start-CompleteSetup {
    try {
        Write-Host "iBridge Portable Complete Setup Script" -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host "Running from: $ScriptRoot" -ForegroundColor Green
        Write-Host "Version: Portable Edition" -ForegroundColor Cyan
        Write-Host ""
        
        if (-not $SkipValidation) {
            Test-Prerequisites
            Wait-ForKeyPress "Press any key to start the setup process..."
        }
        
        # Step 2: Create user accounts
        Initialize-UserAccounts
        Wait-ForKeyPress
        
        # Step 3: Install applications
        Install-AllApplications
        Wait-ForKeyPress
        
        # Step 4: Create shortcuts
        Create-AllShortcuts
        Wait-ForKeyPress
        
        # Step 5: Set permissions
        Set-FolderPermissions
        
        # Final summary
        Write-StepHeader "SETUP COMPLETE" "Installation Summary"
        Write-Success "User accounts created and configured"
        Write-Success "Applications installed to: $DestinationFolder"
        Write-Success "Desktop shortcuts created for all users"
        Write-Success "Folder permissions configured"
        Write-Host ""
        Write-Host "Setup completed successfully!" -ForegroundColor Green -BackgroundColor Black
        Write-Host "You can now log in with either account:" -ForegroundColor Cyan
        Write-Host "  Admin: $AdminUsername (Password: $AdminPassword)" -ForegroundColor Yellow
        Write-Host "  Standard User: $UserUsername (Password: $UserPassword)" -ForegroundColor Yellow
        
    } catch {
        Write-Error "Setup failed: $($_.Exception.Message)"
        Write-Host "Please check the error details above and try again." -ForegroundColor Red
        exit 1
    }
}

# Start the setup process
Start-CompleteSetup
