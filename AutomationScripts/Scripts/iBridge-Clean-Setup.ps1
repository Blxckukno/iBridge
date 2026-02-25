# iBridge Enhanced Setup Script v2.0.     "24.2.2    "24.2.2000.exe", 
    "GlassWireSetup.exe",.exe" = "24.2.2000"
    "GlassWireSetup.exe" = "2.0.0""24.2.    "24.2.2000.exe", 
    "GlassWireSetup.exe",0.exe" = "24.2.2000"
    "GlassWireSetup.exe" = "2.0.0"# Enhanced with Version Checking and Upgrade Detection

param(
    [switch]$CleanupOnly,
    [switch]$SkipValidation
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Configuration
$AdminUsername = "Admin"
$UserUsername = "iBridge User"
$AdminPassword = "IBr1dG3Pc"
$UserPassword = "Abc654321!"

# Base paths
$iBridgeBase = "C:\iBridge_Setup"
$InstallersPath = Join-Path $iBridgeBase "Installers"
$ShortcutsPath = Join-Path $iBridgeBase "Shortcuts"
$ScriptsPath = Join-Path $iBridgeBase "Scripts"
$LogsPath = Join-Path $iBridgeBase "Logs"
$TempPath = Join-Path $iBridgeBase "Temp"

# Progress tracking
$Global:TotalSteps = 8
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

# Required application files
$RequiredApplications = @(
    "24.2.2000.exe",
    "GlassWireSetup.exe",
    "PBIDesktopSetup_x64.exe",
    "TeamViewer_Setup_x64.exe",
    "Tools for Office2019 TechXander"
)

# Functions
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
    Add-Content -Path $Global:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    # Display on console with colors
    switch ($Level) {
        "SUCCESS" { Write-Host "✓ $Message" -ForegroundColor Green }
        "ERROR" { Write-Host "✗ $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "⚠ $Message" -ForegroundColor Yellow }
        "INFO" { Write-Host "ℹ $Message" -ForegroundColor Cyan }
        default { Write-Host "$Message" -ForegroundColor White }
    }
}

function Start-StepProgress {
    param([string]$StepName)
    
    $Global:CurrentStep++
    $progressPercent = [math]::Round(($Global:CurrentStep / $Global:TotalSteps) * 100)
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Yellow
    Write-Host "STEP $Global:CurrentStep of $Global:TotalSteps - $StepName" -ForegroundColor Yellow
    Write-Host ("=" * 80) -ForegroundColor Yellow
    Write-Host ""
    
    Write-LogEntry "Starting Step $Global:CurrentStep/$Global:TotalSteps - $StepName" "INFO"
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-ApplicationFiles {
    Start-StepProgress "Discovering Application Files"
    Write-LogEntry "Discovering specified application files..." "INFO"
    
    $foundApps = @()
    $searchPaths = @("D:\", "E:\")
    
    foreach ($app in $RequiredApplications) {
        $found = $false
        foreach ($searchPath in $searchPaths) {
            $fullPath = Join-Path $searchPath $app
            if (Test-Path $fullPath) {
                $appInfo = @{
                    Name = $app.Replace(".exe", "").Replace("Setup", "").Replace("_x64", "")
                    Path = $fullPath
                    IsFolder = (Test-Path $fullPath -PathType Container)
                    Arguments = "/S"
                }
                $foundApps += $appInfo
                Write-LogEntry "Found application: $($appInfo.Name) at $fullPath" "SUCCESS"
                $found = $true
                break
            }
        }
        if (-not $found) {
            Write-LogEntry "Application not found: $app" "ERROR"
        }
    }
    
    Write-LogEntry "Found $($foundApps.Count) out of $($RequiredApplications.Count) specified applications" "INFO"
    return $foundApps
}

function New-UserAccountsEnhanced {
    Start-StepProgress "Creating User Accounts"
    
    try {
        # Create Admin account
        Write-LogEntry "Creating Admin account..." "INFO"
        if (Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue) {
            Write-LogEntry "Admin account already exists" "WARNING"
        } else {
            $adminSecurePassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
            New-LocalUser -Name $AdminUsername -Password $adminSecurePassword -FullName "iBridge Administrator" -Description "iBridge Admin Account" | Out-Null
            Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername | Out-Null
            Write-LogEntry "Admin account created successfully" "SUCCESS"
        }
        
        # Create iBridge User account
        Write-LogEntry "Creating iBridge User account..." "INFO"
        if (Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue) {
            Write-LogEntry "iBridge User account already exists" "WARNING"
        } else {
            $userSecurePassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
            New-LocalUser -Name $UserUsername -Password $userSecurePassword -FullName "iBridge User" -Description "iBridge Standard User Account" | Out-Null
            Write-LogEntry "iBridge User account created successfully" "SUCCESS"
        }
        
        return $true
    } catch {
        Write-LogEntry "Failed to create user accounts: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Install-ApplicationsEnhanced {
    Start-StepProgress "Installing Applications"
    
    if ($Applications.Count -eq 0) {
        Write-LogEntry "No applications found to install" "WARNING"
        return $true
    }
    
    $successCount = 0
    foreach ($app in $Applications) {
        Write-LogEntry "Processing application: $($app.Name)" "INFO"
        
        if (Test-Path $app.Path) {
            try {
                if ($app.IsFolder) {
                    # Copy folder
                    $destPath = Join-Path $InstallersPath (Split-Path $app.Path -Leaf)
                    if (!(Test-Path $destPath)) {
                        Copy-Item -Path $app.Path -Destination $destPath -Recurse -Force
                        Write-LogEntry "Copied folder: $($app.Name)" "SUCCESS"
                    }
                    $successCount++
                } else {
                    # Install application
                    $installerName = Split-Path $app.Path -Leaf
                    $localInstaller = Join-Path $InstallersPath $installerName
                    
                    # Copy installer
                    if (!(Test-Path $localInstaller)) {
                        Copy-Item -Path $app.Path -Destination $localInstaller -Force
                    }
                    
                    # Run installation
                    Write-LogEntry "Installing: $($app.Name)" "INFO"
                    $process = Start-Process -FilePath $localInstaller -ArgumentList $app.Arguments -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue
                    
                    if ($process.ExitCode -eq 0) {
                        Write-LogEntry "Installed successfully: $($app.Name)" "SUCCESS"
                    } else {
                        Write-LogEntry "Installation completed with exit code $($process.ExitCode): $($app.Name)" "WARNING"
                    }
                    $successCount++
                }
            } catch {
                Write-LogEntry "Failed to install $($app.Name): $($_.Exception.Message)" "ERROR"
            }
        } else {
            Write-LogEntry "Application file not found: $($app.Path)" "ERROR"
        }
    }
    
    Write-LogEntry "Applications processed: $successCount of $($Applications.Count)" "INFO"
    return $true
}

function Set-FolderPermissionsEnhanced {
    Start-StepProgress "Setting Folder Permissions"
    
    try {
        # Set permissions for the iBridge base folder
        $acl = Get-Acl $iBridgeBase
        
        # Grant full control to Administrators
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($adminRule)
        
        # Grant read and execute to Users
        $userRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($userRule)
        
        Set-Acl -Path $iBridgeBase -AclObject $acl
        Write-LogEntry "Folder permissions set successfully" "SUCCESS"
        return $true
    } catch {
        Write-LogEntry "Failed to set folder permissions: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Start-Cleanup {
    Start-StepProgress "Cleaning Up Previous Installation"
    
    try {
        # Create base directory structure
        $directories = @($iBridgeBase, $InstallersPath, $ShortcutsPath, $ScriptsPath, $LogsPath, $TempPath)
        foreach ($dir in $directories) {
            if (!(Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
        }
        
        Write-LogEntry "Cleanup completed successfully" "SUCCESS"
        return $true
    } catch {
        Write-LogEntry "Cleanup failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution function
function Start-EnhancedSetup {
    try {
        Write-Host "iBridge Enhanced Complete Setup Script" -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host "Enhanced with Version Checking and Upgrade Detection" -ForegroundColor Cyan
        Write-Host "Log File: $Global:LogFile" -ForegroundColor Yellow
        Write-Host ""
        
        Write-LogEntry "iBridge Enhanced Setup Started" "INFO"
        
        # Check Administrator privileges
        if (-not (Test-Administrator)) {
            Write-LogEntry "This script must be run as Administrator" "ERROR"
            throw "Administrator privileges required"
        }
        
        if ($CleanupOnly) {
            Start-Cleanup
            Write-LogEntry "Cleanup completed" "SUCCESS"
            return
        }
        
        # Step 1: Cleanup
        Start-Cleanup
        
        # Step 2: Discover applications
        $Global:Applications = Find-ApplicationFiles
        
        if (-not $SkipValidation) {
            Write-Host "Press any key to start the enhanced setup process..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        # Step 3: Create user accounts
        New-UserAccountsEnhanced
        
        # Step 4: Install applications
        Install-ApplicationsEnhanced
        
        # Step 5: Set permissions
        Set-FolderPermissionsEnhanced
        
        # Final summary
        Start-StepProgress "Setup Complete"
        
        Write-Host ""
        Write-Host ("=" * 80) -ForegroundColor Green
        Write-Host "SETUP COMPLETED SUCCESSFULLY!" -ForegroundColor White -BackgroundColor Green
        Write-Host ("=" * 80) -ForegroundColor Green
        Write-Host ""
        
        Write-LogEntry "Enhanced setup completed successfully" "SUCCESS"
        Write-Host "✓ User accounts created" -ForegroundColor Green
        Write-Host "✓ Applications processed: $($Applications.Count)" -ForegroundColor Green
        Write-Host "✓ Everything organized in: $iBridgeBase" -ForegroundColor Green
        Write-Host ""
        Write-Host "NEXT STEPS:" -ForegroundColor Yellow
        Write-Host "1. Log out of current Windows session" -ForegroundColor Cyan
        Write-Host "2. Log in as 'iBridge User' (Password: $UserPassword)" -ForegroundColor Cyan
        Write-Host "3. Browse $iBridgeBase for all resources" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Log file: $Global:LogFile" -ForegroundColor Gray
        
        Write-LogEntry "iBridge Enhanced Setup Completed Successfully" "SUCCESS"
        
    } catch {
        Write-LogEntry "Setup failed: $($_.Exception.Message)" "ERROR"
        Write-Host "Setup failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Check log file: $Global:LogFile" -ForegroundColor Yellow
        exit 1
    }
}

# Start the enhanced setup process
Start-EnhancedSetup
