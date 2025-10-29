# iBridge Complete Setup Script
# Master script that performs the entire setup process
# Creates user accounts, installs applications, and sets up shortcuts

param(
    [switch]$SkipValidation,
    [switch]$QuietMode
)

# ============================================================
# CONFIGURATION SECTION
# ============================================================

# Account Configuration
$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

# Application Paths Configuration
$Applications = @(
    @{
        Name = "TeamViewer"
        Path = "D:\TeamViewer_Setup_x64.exe"
        Arguments = "/S"
        Description = "Remote desktop software"
    },
    @{
        Name = "Tools for Office 2019 TechXander"
        Path = "D:\Tools for Office2019 TechXander"
        Arguments = ""
        Description = "Office tools suite"
        IsFolder = $true
    },
    @{
        Name = "Application 24.2.2000"
        Path = "D:\24.2.2000.exe"
        Arguments = "/SILENT"
        Description = "Business application"
    },
    @{
        Name = "Power BI Desktop"
        Path = "D:\PBIDesktopSetup_x64.exe"
        Arguments = "/quiet"
        Description = "Microsoft Power BI Desktop"
    },
    @{
        Name = "MS Teams Setup"
        Path = "d:\IT STUFF\Desktop-Mtn\MSTeamsSetup.exe"
        Arguments = "/S"
        Description = "Microsoft Teams"
    }
)

# Shortcut Paths Configuration
$Shortcuts = @(
    @{
        Name = "Excel"
        Source = "d:\IT STUFF\Desktop-Mtn\Excel.lnk"
        Type = "Link"
    },
    @{
        Name = "Microsoft 365 Online"
        Source = "d:\IT STUFF\Desktop-Mtn\Microsoft 365 Online.url"
        Type = "URL"
    },
    @{
        Name = "New Citrix Gateway"
        Source = "d:\IT STUFF\Desktop-Mtn\New Citrix Gateway.url"
        Type = "URL"
    },
    @{
        Name = "Outlook"
        Source = "d:\IT STUFF\Desktop-Mtn\Outlook.lnk"
        Type = "Link"
    },
    @{
        Name = "PowerPoint"
        Source = "d:\IT STUFF\Desktop-Mtn\PowerPoint.lnk"
        Type = "Link"
    },
    @{
        Name = "Word"
        Source = "d:\IT STUFF\Desktop-Mtn\Word.lnk"
        Type = "Link"
    }
)

# Base Directories
$iBridgeBase = "C:\iBridge_Apps"
$InstallersPath = "$iBridgeBase\Installers"
$ShortcutsPath = "$iBridgeBase\Shortcuts"

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

function Write-StepHeader {
    param([string]$Title, [string]$Step)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "STEP ${Step}: $Title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Status {
    param([string]$Message, [string]$Status = "INFO")
    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "Blue" }
        default { "White" }
    }
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-AllSourceFiles {
    Write-Status "Validating source files..." "INFO"
    $allPaths = @()
    $allPaths += $Applications | ForEach-Object { $_.Path }
    $allPaths += $Shortcuts | ForEach-Object { $_.Source }
    
    $missingFiles = @()
    $foundFiles = 0
    
    foreach ($path in $allPaths) {
        if (Test-Path $path) {
            $foundFiles++
            Write-Status "Found: $path" "SUCCESS"
        } else {
            $missingFiles += $path
            Write-Status "Missing: $path" "ERROR"
        }
    }
    
    Write-Host ""
    Write-Status "Files found: $foundFiles" "INFO"
    Write-Status "Files missing: $($missingFiles.Count)" "INFO"
    
    if ($missingFiles.Count -gt 0) {
        Write-Status "Cannot proceed - missing source files!" "ERROR"
        return $false
    }
    
    Write-Status "All source files validated successfully!" "SUCCESS"
    return $true
}

# ============================================================
# MAIN FUNCTIONS
# ============================================================

function Create-UserAccounts {
    Write-StepHeader "Creating User Accounts" "1"
    
    try {
        # Remove existing accounts if they exist
        $existingAdmin = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
        if ($existingAdmin) {
            Write-Status "Removing existing Admin account..." "WARNING"
            Remove-LocalUser -Name $AdminUsername -Confirm:$false
        }
        
        $existingUser = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
        if ($existingUser) {
            Write-Status "Removing existing iBridge User account..." "WARNING"
            Remove-LocalUser -Name $UserUsername -Confirm:$false
        }
        
        # Create Admin account
        Write-Status "Creating Admin account..." "INFO"
        $secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
        $adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -Description "Admin for app installation" -PasswordNeverExpires -AccountNeverExpires
        Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername
        Write-Status "Admin account created successfully" "SUCCESS"
        
        # Create iBridge User account
        Write-Status "Creating iBridge User account..." "INFO"
        $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
        $bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -Description "Standard user with limited privileges" -PasswordNeverExpires -AccountNeverExpires
        Add-LocalGroupMember -Group "Users" -Member $UserUsername
        Write-Status "iBridge User account created successfully" "SUCCESS"
        
        return $true
    } catch {
        Write-Status "Failed to create user accounts: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Create-FolderStructure {
    Write-StepHeader "Creating Folder Structure" "2"
    
    try {
        # Create base directory
        if (!(Test-Path $iBridgeBase)) {
            New-Item -ItemType Directory -Path $iBridgeBase -Force | Out-Null
            Write-Status "Created base directory: $iBridgeBase" "SUCCESS"
        }
        
        # Create installers directory
        if (!(Test-Path $InstallersPath)) {
            New-Item -ItemType Directory -Path $InstallersPath -Force | Out-Null
            Write-Status "Created installers directory: $InstallersPath" "SUCCESS"
        }
        
        # Create shortcuts directory
        if (!(Test-Path $ShortcutsPath)) {
            New-Item -ItemType Directory -Path $ShortcutsPath -Force | Out-Null
            Write-Status "Created shortcuts directory: $ShortcutsPath" "SUCCESS"
        }
        
        # Set folder permissions
        try {
            $acl = Get-Acl $iBridgeBase
            
            # Give Users group read and execute permissions
            $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.SetAccessRule($userAccessRule)
            
            # Give Administrators group full control
            $adminAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.SetAccessRule($adminAccessRule)
            
            Set-Acl -Path $iBridgeBase -AclObject $acl
            Write-Status "Folder permissions set successfully" "SUCCESS"
        } catch {
            Write-Status "Warning: Could not set folder permissions: $($_.Exception.Message)" "WARNING"
        }
        
        return $true
    } catch {
        Write-Status "Failed to create folder structure: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Install-Applications {
    Write-StepHeader "Installing Applications" "3"
    
    $successCount = 0
    $totalApps = $Applications.Count
    
    foreach ($app in $Applications) {
        Write-Status "Processing: $($app.Name)" "INFO"
        
        if (Test-Path $app.Path) {
            try {
                if ($app.IsFolder) {
                    # Copy folder to installers directory
                    $destPath = Join-Path $InstallersPath (Split-Path $app.Path -Leaf)
                    if (!(Test-Path $destPath)) {
                        Copy-Item -Path $app.Path -Destination $destPath -Recurse -Force
                        Write-Status "Copied folder: $($app.Name)" "SUCCESS"
                        $successCount++
                    } else {
                        Write-Status "Folder already exists: $($app.Name)" "WARNING"
                        $successCount++
                    }
                } else {
                    # Copy installer and run installation
                    $installerName = Split-Path $app.Path -Leaf
                    $localInstaller = Join-Path $InstallersPath $installerName
                    
                    # Copy installer
                    if (!(Test-Path $localInstaller)) {
                        Copy-Item -Path $app.Path -Destination $localInstaller -Force
                        Write-Status "Copied installer: $installerName" "SUCCESS"
                    }
                    
                    # Run installation
                    Write-Status "Installing: $($app.Name)" "INFO"
                    $process = Start-Process -FilePath $localInstaller -ArgumentList $app.Arguments -Wait -PassThru -NoNewWindow
                    
                    if ($process.ExitCode -eq 0) {
                        Write-Status "Installed successfully: $($app.Name)" "SUCCESS"
                        $successCount++
                    } else {
                        Write-Status "Installation completed with exit code $($process.ExitCode): $($app.Name)" "WARNING"
                        $successCount++
                    }
                }
            } catch {
                Write-Status "Failed to install $($app.Name): $($_.Exception.Message)" "ERROR"
            }
        } else {
            Write-Status "Source file not found: $($app.Path)" "ERROR"
        }
    }
    
    Write-Status "Applications processed: $successCount of $totalApps" "INFO"
    return $successCount -eq $totalApps
}

function Create-Shortcuts {
    Write-StepHeader "Creating Shortcuts" "4"
    
    $successCount = 0
    $totalShortcuts = $Shortcuts.Count
    
    # Get user desktop paths
    $adminDesktop = "C:\Users\$AdminUsername\Desktop"
    $userDesktop = "C:\Users\$UserUsername\Desktop"
    
    foreach ($shortcut in $Shortcuts) {
        Write-Status "Processing shortcut: $($shortcut.Name)" "INFO"
        
        if (Test-Path $shortcut.Source) {
            try {
                $fileName = Split-Path $shortcut.Source -Leaf
                
                # Copy to shared shortcuts folder
                $sharedPath = Join-Path $ShortcutsPath $fileName
                Copy-Item -Path $shortcut.Source -Destination $sharedPath -Force
                Write-Status "Copied to shared folder: $fileName" "SUCCESS"
                
                # Copy to user desktops (if they exist)
                if (Test-Path $adminDesktop) {
                    $adminPath = Join-Path $adminDesktop $fileName
                    Copy-Item -Path $shortcut.Source -Destination $adminPath -Force
                    Write-Status "Copied to Admin desktop: $fileName" "SUCCESS"
                }
                
                if (Test-Path $userDesktop) {
                    $userPath = Join-Path $userDesktop $fileName
                    Copy-Item -Path $shortcut.Source -Destination $userPath -Force
                    Write-Status "Copied to iBridge User desktop: $fileName" "SUCCESS"
                }
                
                $successCount++
            } catch {
                Write-Status "Failed to copy shortcut $($shortcut.Name): $($_.Exception.Message)" "ERROR"
            }
        } else {
            Write-Status "Shortcut source not found: $($shortcut.Source)" "ERROR"
        }
    }
    
    Write-Status "Shortcuts processed: $successCount of $totalShortcuts" "INFO"
    return $successCount -eq $totalShortcuts
}

function Show-FinalReport {
    Write-StepHeader "Setup Complete - Final Report" "5"
    
    # Verify accounts
    $adminExists = Get-LocalUser -Name $AdminUsername -ErrorAction SilentlyContinue
    $userExists = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
    
    Write-Status "USER ACCOUNTS:" "INFO"
    if ($adminExists) {
        Write-Status "Admin Account: Created and Ready" "SUCCESS"
        Write-Status "  Username: $AdminUsername" "INFO"
        Write-Status "  Password: $AdminPassword" "INFO"
    } else {
        Write-Status "Admin Account: FAILED" "ERROR"
    }
    
    if ($userExists) {
        Write-Status "iBridge User Account: Created and Ready" "SUCCESS"
        Write-Status "  Username: $UserUsername" "INFO"
        Write-Status "  Password: $UserPassword" "INFO"
    } else {
        Write-Status "iBridge User Account: FAILED" "ERROR"
    }
    
    Write-Host ""
    Write-Status "FOLDER STRUCTURE:" "INFO"
    if (Test-Path $iBridgeBase) {
        $installerCount = if (Test-Path $InstallersPath) { (Get-ChildItem $InstallersPath -ErrorAction SilentlyContinue).Count } else { 0 }
        $shortcutCount = if (Test-Path $ShortcutsPath) { (Get-ChildItem $ShortcutsPath -ErrorAction SilentlyContinue).Count } else { 0 }
        
        Write-Status "Base Directory: $iBridgeBase" "SUCCESS"
        Write-Status "Installers: $installerCount items in $InstallersPath" "SUCCESS"
        Write-Status "Shortcuts: $shortcutCount items in $ShortcutsPath" "SUCCESS"
    } else {
        Write-Status "Base Directory: FAILED" "ERROR"
    }
    
    Write-Host ""
    Write-Status "INSTALLED APPLICATIONS:" "INFO"
    $installedApps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                     Where-Object {$_.DisplayName -like "*TeamViewer*" -or $_.DisplayName -like "*Power BI*"} | 
                     Select-Object DisplayName, DisplayVersion
    
    if ($installedApps) {
        foreach ($app in $installedApps) {
            Write-Status "$($app.DisplayName) v$($app.DisplayVersion)" "SUCCESS"
        }
    } else {
        Write-Status "No applications detected in registry (may still be installing)" "WARNING"
    }
    
    Write-Host ""
    Write-Status "NEXT STEPS:" "INFO"
    Write-Status "1. Log out or use 'Switch User'" "INFO"
    Write-Status "2. Log in as '$UserUsername' with password '$UserPassword'" "INFO"
    Write-Status "3. Check desktop for shortcuts" "INFO"
    Write-Status "4. Browse to $iBridgeBase for all resources" "INFO"
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "iBridge Setup Complete!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
}

# ============================================================
# MAIN EXECUTION
# ============================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "iBridge Complete Setup Script" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check Administrator privileges
if (-not (Test-Administrator)) {
    Write-Status "This script requires Administrator privileges!" "ERROR"
    Write-Status "Please run PowerShell as Administrator and try again." "WARNING"
    exit 1
}

Write-Status "Running with Administrator privileges" "SUCCESS"

# Validate source files (unless skipped)
if (-not $SkipValidation) {
    if (-not (Test-AllSourceFiles)) {
        Write-Status "Source file validation failed. Exiting..." "ERROR"
        exit 1
    }
}

# Execute setup steps
$step1Success = Create-UserAccounts
$step2Success = Create-FolderStructure
$step3Success = Install-Applications
$step4Success = Create-Shortcuts

# Show final report
Show-FinalReport

# Summary
if ($step1Success -and $step2Success -and $step3Success -and $step4Success) {
    Write-Status "ALL STEPS COMPLETED SUCCESSFULLY!" "SUCCESS"
    $exitCode = 0
} else {
    Write-Status "Some steps encountered issues. Check the log above." "WARNING"
    $exitCode = 1
}

if (-not $QuietMode) {
    Write-Host ""
    Write-Host "Press any key to continue..."
    Read-Host
}

exit $exitCode
