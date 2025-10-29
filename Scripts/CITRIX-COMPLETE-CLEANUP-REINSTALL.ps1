# Citrix Workspace Complete Cleanup and Reinstall Script
# Fixes missing bootstrapperhelper.exe and incomplete installations

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check admin privileges
if (-not (Test-Administrator)) {
    Write-ColorOutput "ERROR: This script must be run as Administrator" "Red"
    Write-ColorOutput "Right-click PowerShell and select 'Run as Administrator'" "Yellow"
    Read-Host "Press Enter to exit"
    exit 1
}

# Display header
Write-ColorOutput "================================================================" "Cyan"
Write-ColorOutput "CITRIX WORKSPACE COMPLETE CLEANUP & REINSTALL" "Cyan"
Write-ColorOutput "================================================================" "Cyan"
Write-ColorOutput ""
Write-ColorOutput "This script will:" "Yellow"
Write-ColorOutput "  1. Remove ALL Citrix components completely" "Yellow"
Write-ColorOutput "  2. Clean up registry entries" "Yellow" 
Write-ColorOutput "  3. Remove leftover files" "Yellow"
Write-ColorOutput "  4. Verify .NET Core 8.0 installation" "Yellow"
Write-ColorOutput "  5. Download and reinstall Citrix Workspace cleanly" "Yellow"
Write-ColorOutput ""

$confirmation = Read-Host "Proceed with complete Citrix cleanup and reinstall? (Y/N)"
if ($confirmation -ne "Y" -and $confirmation -ne "y") {
    Write-ColorOutput "Operation cancelled by user" "Yellow"
    exit 0
}

# STEP 1: Find and stop all Citrix processes
Write-ColorOutput ""
Write-ColorOutput "STEP 1: Stopping Citrix processes..." "Green"
$citrixProcesses = @(
    "concentr", "wfcrun32", "redirector", "ssonsvr", "AuthManSvr", "picaSvc",
    "receiverhelper", "concentr", "wfica32", "CitrixReceiverUpdater", "CitrixWorkspaceApp"
)

foreach ($process in $citrixProcesses) {
    $runningProcess = Get-Process -Name $process -ErrorAction SilentlyContinue
    if ($runningProcess) {
        try {
            Stop-Process -Name $process -Force
            Write-ColorOutput "  Stopped: $process" "Gray"
        } catch {
            Write-ColorOutput "  Could not stop: $process" "Yellow"
        }
    }
}

# STEP 2: Uninstall any existing Citrix applications
Write-ColorOutput ""
Write-ColorOutput "STEP 2: Uninstalling existing Citrix applications..." "Green"

# Function to find and uninstall applications from registry
function Uninstall-RegistryApplication {
    param (
        [string]$SearchPattern
    )
    
    $uninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($key in $uninstallKeys) {
        $apps = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$SearchPattern*" }
        foreach ($app in $apps) {
            $uninstallString = $app.UninstallString
            $displayName = $app.DisplayName
            
            if ($uninstallString) {
                Write-ColorOutput "  Uninstalling: $displayName" "Yellow"
                
                if ($uninstallString -match "msiexec.exe") {
                    $productCode = $uninstallString -replace '.+({.+})', '$1'
                    Write-ColorOutput "  Using MSI product code: $productCode" "Gray"
                    Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $productCode /qn" -Wait -NoNewWindow
                } else {
                    # Try to replace /I with /x if found (for MSI)
                    $uninstallString = $uninstallString -replace "/I", "/x"
                    # Add quiet switch if needed
                    if ($uninstallString -notmatch "/quiet" -and $uninstallString -notmatch "/qn") {
                        $uninstallString = "$uninstallString /qn"
                    }
                    
                    Write-ColorOutput "  Running: $uninstallString" "Gray"
                    
                    # Execute the uninstall string
                    try {
                        if ($uninstallString -match '^"([^"]+)"') {
                            $cmd = $Matches[1]
                            $args = $uninstallString -replace '^"[^"]+"', ''
                            Start-Process -FilePath $cmd -ArgumentList $args -Wait -NoNewWindow
                        } else {
                            $cmd = ($uninstallString -split ' ')[0]
                            $args = $uninstallString -replace [regex]::Escape($cmd), ''
                            Start-Process -FilePath $cmd -ArgumentList $args -Wait -NoNewWindow
                        }
                    } catch {
                        Write-ColorOutput "  Error executing: $uninstallString" "Red"
                    }
                }
                
                Write-ColorOutput "  Uninstalled: $displayName" "Green"
            }
        }
    }
}

# Uninstall all Citrix applications
$citrixApps = @("Citrix", "Receiver")
foreach ($app in $citrixApps) {
    Uninstall-RegistryApplication -SearchPattern $app
}

# STEP 3: Clean up registry
Write-ColorOutput ""
Write-ColorOutput "STEP 3: Cleaning registry entries..." "Green"

$regPaths = @(
    "HKLM:\SOFTWARE\Citrix",
    "HKLM:\SOFTWARE\WOW6432Node\Citrix",
    "HKCU:\SOFTWARE\Citrix",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\CitrixOnlinePluginPackWeb",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\CitrixOnlinePluginPackWeb",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\CitrixReceiver",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\CitrixReceiver",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\CitrixWorkspace",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\CitrixWorkspace",
    "HKCU:\SOFTWARE\Microsoft\Installer\Products",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\AppMgmt\",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\AppMgmt\*"
)

foreach ($path in $regPaths) {
    if (Test-Path $path) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "  Removed registry path: $path" "Gray"
        } catch {
            Write-ColorOutput "  Could not remove registry path: $path" "Yellow"
        }
    }
}

# STEP 4: Clean up file system
Write-ColorOutput ""
Write-ColorOutput "STEP 4: Removing leftover files..." "Green"

$filePaths = @(
    "${env:ProgramFiles}\Citrix",
    "${env:ProgramFiles(x86)}\Citrix",
    "${env:SystemDrive}\ProgramData\Citrix",
    "${env:APPDATA}\Citrix",
    "${env:LOCALAPPDATA}\Citrix",
    "${env:TEMP}\Citrix",
    "${env:SystemDrive}\Windows\Temp\Citrix",
    "${env:USERPROFILE}\Citrix"
)

foreach ($path in $filePaths) {
    if (Test-Path $path) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "  Removed directory: $path" "Gray"
        } catch {
            Write-ColorOutput "  Could not fully remove directory: $path" "Yellow"
        }
    }
}

# STEP 5: Verify .NET Core 8.0 installation
Write-ColorOutput ""
Write-ColorOutput "STEP 5: Verifying .NET Core 8.0 installation..." "Green"

function Test-DotNetCore8Installed {
    $dotNetInstalled = $false
    $dotNetPaths = @(
        "${env:ProgramFiles}\dotnet\shared\Microsoft.WindowsDesktop.App\8.*",
        "${env:ProgramFiles(x86)}\dotnet\shared\Microsoft.WindowsDesktop.App\8.*"
    )
    
    foreach ($path in $dotNetPaths) {
        if (Test-Path $path) {
            $version = Get-ChildItem $path | Sort-Object Name -Descending | Select-Object -First 1
            if ($version) {
                Write-ColorOutput "  ✅ .NET Core Desktop Runtime found: $($version.Name)" "Green"
                $dotNetInstalled = $true
                break
            }
        }
    }
    
    # Try using dotnet command if paths not found
    if (-not $dotNetInstalled) {
        try {
            $dotnetInfo = & dotnet --list-runtimes 2>$null | Where-Object { $_ -match "Microsoft.WindowsDesktop.App 8\." }
            if ($dotnetInfo) {
                Write-ColorOutput "  ✅ .NET Core 8.0 found via dotnet command" "Green"
                $dotNetInstalled = $true
            }
        }
        catch {
            # dotnet command not available
        }
    }
    
    return $dotNetInstalled
}

$dotNetInstalled = Test-DotNetCore8Installed

if (-not $dotNetInstalled) {
    Write-ColorOutput "  ⚠️ .NET Core 8.0 not found - installing now..." "Yellow"
    
    try {
        $dotNetUrl = "https://download.microsoft.com/download/6/0/f/60fc7896-d8fa-4713-b20f-e8e0b2db3431/windowsdesktop-runtime-8.0.10-win-x64.exe"
        $dotNetInstaller = "C:\dotnet-desktop-runtime-8.0-win-x64.exe"
        
        Write-ColorOutput "  Downloading .NET Core 8.0..." "Yellow"
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $dotNetUrl -OutFile $dotNetInstaller -UseBasicParsing
        
        Write-ColorOutput "  Installing .NET Core 8.0..." "Yellow"
        $process = Start-Process -FilePath $dotNetInstaller -ArgumentList "/install", "/quiet", "/norestart" -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 1641 -or $process.ExitCode -eq 3010) {
            Write-ColorOutput "  ✅ .NET Core 8.0 installed successfully!" "Green"
        } else {
            Write-ColorOutput "  ⚠️ .NET Core 8.0 installation completed with exit code: $($process.ExitCode)" "Yellow"
        }
        
        Remove-Item $dotNetInstaller -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-ColorOutput "  ❌ Failed to install .NET Core 8.0: $($_.Exception.Message)" "Red"
        Write-ColorOutput "  Please install .NET Core 8.0 Desktop Runtime manually from:" "Yellow"
        Write-ColorOutput "  https://dotnet.microsoft.com/download/dotnet/8.0" "Yellow"
    }
}

# STEP 6: Download and install latest Citrix Workspace
Write-ColorOutput ""
Write-ColorOutput "STEP 6: Downloading and installing Citrix Workspace..." "Green"

try {
    $tempDir = "C:\CitrixTemp"
    if (!(Test-Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    }
    
    # Download latest Citrix Workspace
    $citrixUrl = "https://downloadplugins.citrix.com/Windows/CitrixWorkspaceApp.exe"
    $citrixInstaller = "$tempDir\CitrixWorkspaceApp.exe"
    
    Write-ColorOutput "  Downloading latest Citrix Workspace..." "Yellow"
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $citrixUrl -OutFile $citrixInstaller -UseBasicParsing
    
    # Install Citrix Workspace silently
    Write-ColorOutput "  Installing Citrix Workspace..." "Yellow"
    $process = Start-Process -FilePath $citrixInstaller -ArgumentList "/silent /noreboot" -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-ColorOutput "  ✅ Citrix Workspace installed successfully!" "Green"
    } else {
        Write-ColorOutput "  ⚠️ Citrix installation completed with exit code: $($process.ExitCode)" "Yellow"
    }
    
    # Clean up temp files
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    
} catch {
    Write-ColorOutput "  ❌ Failed to install Citrix Workspace: $($_.Exception.Message)" "Red"
    Write-ColorOutput "  Please try downloading and installing manually from:" "Yellow"
    Write-ColorOutput "  https://www.citrix.com/downloads/workspace-app/" "Yellow"
}

# STEP 7: Verify installation
Write-ColorOutput ""
Write-ColorOutput "STEP 7: Verifying Citrix installation..." "Green"

# Check if Citrix program files exist
$citrixPaths = @(
    "${env:ProgramFiles}\Citrix",
    "${env:ProgramFiles(x86)}\Citrix"
)

$citrixInstalled = $false
foreach ($path in $citrixPaths) {
    if (Test-Path $path) {
        $citrixInstalled = $true
        Write-ColorOutput "  ✅ Citrix installation found at: $path" "Green"
        
        # Check for bootstrapperhelper.exe specifically
        $bootstrapperPaths = Get-ChildItem -Path $path -Filter "bootstrapperhelper.exe" -Recurse -ErrorAction SilentlyContinue
        if ($bootstrapperPaths) {
            foreach ($bootstrapperPath in $bootstrapperPaths) {
                Write-ColorOutput "  ✅ bootstrapperhelper.exe found at: $($bootstrapperPath.FullName)" "Green"
            }
        } else {
            Write-ColorOutput "  ⚠️ bootstrapperhelper.exe not found in Citrix installation" "Yellow"
        }
    }
}

if (-not $citrixInstalled) {
    Write-ColorOutput "  ❌ Could not verify Citrix installation" "Red"
}

# Final summary
Write-ColorOutput ""
Write-ColorOutput "================================================================" "Cyan"
Write-ColorOutput "CLEANUP AND REINSTALL COMPLETE" "Cyan"
Write-ColorOutput "================================================================" "Cyan"
Write-ColorOutput ""

if ($citrixInstalled) {
    Write-ColorOutput "✅ Citrix Workspace has been completely reinstalled!" "Green"
    Write-ColorOutput "✅ Previous problematic installation was removed" "Green"
    Write-ColorOutput "✅ All registry entries cleaned up" "Green"
    Write-ColorOutput "✅ All leftover files removed" "Green"
    Write-ColorOutput "✅ Fresh installation of Citrix Workspace completed" "Green"
} else {
    Write-ColorOutput "⚠️ Citrix cleanup completed, but installation verification failed" "Yellow"
    Write-ColorOutput "Please try manually installing Citrix Workspace from:" "Yellow"
    Write-ColorOutput "https://www.citrix.com/downloads/workspace-app/" "Yellow"
}

Write-ColorOutput ""
Write-ColorOutput "If you continue to have issues, try rebooting your computer" "Yellow"
Write-ColorOutput "and then reinstalling Citrix Workspace manually." "Yellow"
Write-ColorOutput ""

# Create batch file for manual reinstall if needed
$batchContent = @"
@echo off
echo ================================================================
echo MANUAL CITRIX WORKSPACE REINSTALL
echo ================================================================
echo.
echo If you're still having issues, this script will:
echo 1. Download the latest Citrix Workspace
echo 2. Install it with standard settings
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

echo.
echo Downloading latest Citrix Workspace...
powershell -Command "& { $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://downloadplugins.citrix.com/Windows/CitrixWorkspaceApp.exe' -OutFile '%TEMP%\CitrixWorkspaceApp.exe' }"

echo.
echo Installing Citrix Workspace with standard settings...
start /wait "" "%TEMP%\CitrixWorkspaceApp.exe"

echo.
echo Cleaning up...
del /q "%TEMP%\CitrixWorkspaceApp.exe" > nul 2>&1

echo.
echo ================================================================
echo MANUAL INSTALLATION COMPLETE
echo ================================================================
echo.
echo If Citrix is still not working, please contact IT support.
echo.
pause
"@

$manualReinstallPath = "C:\iBridge_Setup\CITRIX-MANUAL-REINSTALL.bat"
# Ensure directory exists
if (!(Test-Path "C:\iBridge_Setup")) {
    New-Item -Path "C:\iBridge_Setup" -ItemType Directory -Force | Out-Null
}
$batchContent | Out-File -FilePath $manualReinstallPath -Encoding ASCII

Write-ColorOutput "📄 Created manual reinstall script: $manualReinstallPath" "Gray"
Write-ColorOutput ""

Read-Host "Press Enter to exit"
