# Application Installation and Shortcut Management Script
# This script installs applications as Admin and creates shortcuts for both profiles

param(
    [switch]$InstallApps,
    [switch]$CreateShortcuts,
    [switch]$DoAll
)

# Check if running as Administrator
function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Application installation definitions
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

# Shortcut definitions
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

# Function to install applications
function Install-Applications {
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Installing Applications as Administrator" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Create installation directory on C: drive
    $InstallBase = "C:\iBridge_Apps\Installers"
    if (!(Test-Path $InstallBase)) {
        New-Item -ItemType Directory -Path $InstallBase -Force | Out-Null
        Write-Host "[CREATED] Installation directory: $InstallBase" -ForegroundColor Green
    }
    
    foreach ($app in $Applications) {
        Write-Host "Processing: $($app.Name)" -ForegroundColor Yellow
        
        if (Test-Path $app.Path) {
            try {
                if ($app.IsFolder) {
                    # Copy folder to C: drive
                    $destPath = Join-Path $InstallBase (Split-Path $app.Path -Leaf)
                    if (!(Test-Path $destPath)) {
                        Copy-Item -Path $app.Path -Destination $destPath -Recurse -Force
                        Write-Host "  [SUCCESS] Copied folder to: $destPath" -ForegroundColor Green
                    } else {
                        Write-Host "  [SKIPPED] Folder already exists: $destPath" -ForegroundColor Yellow
                    }
                } else {
                    # Copy installer to C: drive first
                    $installerName = Split-Path $app.Path -Leaf
                    $localInstaller = Join-Path $InstallBase $installerName
                    
                    if (!(Test-Path $localInstaller)) {
                        Copy-Item -Path $app.Path -Destination $localInstaller -Force
                        Write-Host "  [COPIED] Installer to: $localInstaller" -ForegroundColor Green
                    }
                    
                    # Run installation
                    Write-Host "  [INSTALLING] Running installer..." -ForegroundColor Blue
                    $process = Start-Process -FilePath $localInstaller -ArgumentList $app.Arguments -Wait -PassThru -NoNewWindow
                    
                    if ($process.ExitCode -eq 0) {
                        Write-Host "  [SUCCESS] $($app.Name) installed successfully" -ForegroundColor Green
                    } else {
                        Write-Host "  [WARNING] $($app.Name) installation completed with exit code: $($process.ExitCode)" -ForegroundColor Yellow
                    }
                }
            } catch {
                Write-Host "  [ERROR] Failed to install $($app.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "  [ERROR] File not found: $($app.Path)" -ForegroundColor Red
        }
        Write-Host ""
    }
}

# Function to create shortcuts
function Create-Shortcuts {
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Creating Shortcuts for User Profiles" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Create shortcuts directory in shared folder
    $SharedShortcuts = "C:\iBridge_Apps\Shortcuts"
    if (!(Test-Path $SharedShortcuts)) {
        New-Item -ItemType Directory -Path $SharedShortcuts -Force | Out-Null
        Write-Host "[CREATED] Shared shortcuts directory: $SharedShortcuts" -ForegroundColor Green
    }
    
    # Get user profile paths
    $AdminDesktop = "C:\Users\Admin\Desktop"
    $iBridgeDesktop = "C:\Users\iBridge User\Desktop"
    
    foreach ($shortcut in $Shortcuts) {
        Write-Host "Processing shortcut: $($shortcut.Name)" -ForegroundColor Yellow
        
        if (Test-Path $shortcut.Source) {
            try {
                $fileName = Split-Path $shortcut.Source -Leaf
                
                # Copy to shared folder
                $sharedPath = Join-Path $SharedShortcuts $fileName
                Copy-Item -Path $shortcut.Source -Destination $sharedPath -Force
                Write-Host "  [SUCCESS] Copied to shared folder: $sharedPath" -ForegroundColor Green
                
                # Copy to Admin desktop (if exists)
                if (Test-Path $AdminDesktop) {
                    $adminPath = Join-Path $AdminDesktop $fileName
                    Copy-Item -Path $shortcut.Source -Destination $adminPath -Force
                    Write-Host "  [SUCCESS] Copied to Admin desktop: $adminPath" -ForegroundColor Green
                } else {
                    Write-Host "  [INFO] Admin desktop not found, will be created on first login" -ForegroundColor Blue
                }
                
                # Copy to iBridge User desktop (if exists)
                if (Test-Path $iBridgeDesktop) {
                    $iBridgePath = Join-Path $iBridgeDesktop $fileName
                    Copy-Item -Path $shortcut.Source -Destination $iBridgePath -Force
                    Write-Host "  [SUCCESS] Copied to iBridge User desktop: $iBridgePath" -ForegroundColor Green
                } else {
                    Write-Host "  [INFO] iBridge User desktop not found, will be created on first login" -ForegroundColor Blue
                }
                
            } catch {
                Write-Host "  [ERROR] Failed to copy $($shortcut.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "  [ERROR] Shortcut file not found: $($shortcut.Source)" -ForegroundColor Red
        }
        Write-Host ""
    }
}

# Function to set folder permissions
function Set-FolderPermissions {
    Write-Host "Setting folder permissions..." -ForegroundColor Yellow
    
    try {
        # Set permissions for iBridge_Apps folder
        $acl = Get-Acl "C:\iBridge_Apps"
        
        # Give iBridge User read and execute permissions
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("iBridge User", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRule)
        
        # Give Admin full control
        $adminAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Admin", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($adminAccessRule)
        
        Set-Acl -Path "C:\iBridge_Apps" -AclObject $acl
        Write-Host "[SUCCESS] Folder permissions set correctly" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to set folder permissions: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "iBridge Application Installation & Shortcut Management" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
if (-not (Test-Administrator)) {
    Write-Host "[ERROR] This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# Determine what to do
if ($DoAll -or (-not $InstallApps -and -not $CreateShortcuts)) {
    $InstallApps = $true
    $CreateShortcuts = $true
}

# Install applications
if ($InstallApps) {
    Install-Applications
}

# Create shortcuts
if ($CreateShortcuts) {
    Create-Shortcuts
}

# Set permissions
Set-FolderPermissions

# Summary
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Installation and Setup Complete!" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Applications installed to: C:\iBridge_Apps\Installers" -ForegroundColor White
Write-Host "Shortcuts available in: C:\iBridge_Apps\Shortcuts" -ForegroundColor White
Write-Host "Desktop shortcuts created for both Admin and iBridge User" -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Log in as Admin to verify applications are installed" -ForegroundColor Gray
Write-Host "2. Log in as iBridge User to test shortcut access" -ForegroundColor Gray
Write-Host "3. Check C:\iBridge_Apps for all installed components" -ForegroundColor Gray

Write-Host ""
Write-Host "Press any key to continue..."
Read-Host
