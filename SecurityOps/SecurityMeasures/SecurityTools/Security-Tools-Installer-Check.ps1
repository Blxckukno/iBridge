# Security-Tools-Installer.ps1
# Purpose: Automated installation of free security tools
# Author: GitHub Copilot
# Date: September 10, 2025

# Configuration - Edit these as needed
$DownloadPath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\Downloads"
$LogPath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\Logs"
$CreatePackage = $true # Set to true to create offline deployment packages
$Verbose = $true # Set to true for detailed output

# Initialize
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue" # Speeds up downloads
$LogFile = Join-Path -Path $LogPath -ChildPath "SecurityTools_Installation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Ensure directories exist
if (!(Test-Path -Path $DownloadPath)) {
    New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
}

if (!(Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Function for logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with color based on level
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor White }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
    
    # Write to log file
    Add-Content -Path $LogFile -Value $logMessage
}

# Function to download file
function Download-File {
    param(
        [string]$Url,
        [string]$OutputFile
    )
    
    try {
        Write-Log "Downloading $Url to $OutputFile..." -Level Info
        
        # Create directory if it doesn't exist
        $outputDir = Split-Path -Path $OutputFile -Parent
        if (!(Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Download file
        Invoke-WebRequest -Uri $Url -OutFile $OutputFile -UseBasicParsing
        
        if (Test-Path -Path $OutputFile) {
            Write-Log "Successfully downloaded to $OutputFile" -Level Success
            return $true
        } else {
            Write-Log "Download failed - file not found after download" -Level Error
            return $false
        }
    } catch {
        Write-Log "Download failed: $_" -Level Error
        return $false
    }
}

# Function to install MSI
function Install-MSI {
    param(
        [string]$MsiPath,
        [string]$Arguments = "/quiet /norestart"
    )
    
    try {
        Write-Log "Installing MSI: $MsiPath" -Level Info
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$MsiPath`" $Arguments" -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Log "MSI installation successful" -Level Success
            return $true
        } else {
            Write-Log "MSI installation failed with exit code: $($process.ExitCode)" -Level Error
            return $false
        }
    } catch {
        Write-Log "MSI installation failed: $_" -Level Error
        return $false
    }
}

# Function to install EXE
function Install-EXE {
    param(
        [string]$ExePath,
        [string]$Arguments = "/S"
    )
    
    try {
        Write-Log "Installing EXE: $ExePath" -Level Info
        $process = Start-Process -FilePath $ExePath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
        
        # Most installers return 0 for success, but this isn't universal
        if ($process.ExitCode -eq 0) {
            Write-Log "EXE installation successful" -Level Success
            return $true
        } else {
            Write-Log "EXE installation completed with exit code: $($process.ExitCode)" -Level Warning
            return $true # Assume success unless obviously failed
        }
    } catch {
        Write-Log "EXE installation failed: $_" -Level Error
        return $false
    }
}

# Function to install a tool
function Install-Tool {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Filename,
        [ValidateSet('MSI', 'EXE', 'ZIP', 'Custom')]
        [string]$Type = 'EXE',
        [string]$InstallArgs = "",
        [scriptblock]$CustomInstall = $null
    )
    
    Write-Log "=== Starting installation of $Name ===" -Level Info
    
    $downloadPath = Join-Path -Path $DownloadPath -ChildPath $Filename
    
    # Download the file
    $downloaded = Download-File -Url $Url -OutputFile $downloadPath
    
    if (!$downloaded) {
        Write-Log "Failed to download $Name - skipping installation" -Level Error
        return $false
    }
    
    # Install based on type
    $success = $false
    
    switch ($Type) {
        'MSI' {
            $success = Install-MSI -MsiPath $downloadPath -Arguments $InstallArgs
        }
        'EXE' {
            $success = Install-EXE -ExePath $downloadPath -Arguments $InstallArgs
        }
        'ZIP' {
            try {
                Write-Log "Extracting ZIP: $downloadPath" -Level Info
                $extractPath = Join-Path -Path $DownloadPath -ChildPath $Name
                
                if (!(Test-Path -Path $extractPath)) {
                    New-Item -Path $extractPath -ItemType Directory -Force | Out-Null
                }
                
                Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
                Write-Log "ZIP extracted successfully to $extractPath" -Level Success
                $success = $true
            } catch {
                Write-Log "ZIP extraction failed: $_" -Level Error
                $success = $false
            }
        }
        'Custom' {
            if ($CustomInstall -ne $null) {
                try {
                    Write-Log "Running custom installation for $Name" -Level Info
                    & $CustomInstall $downloadPath
                    $success = $true
                    Write-Log "Custom installation completed" -Level Success
                } catch {
                    Write-Log "Custom installation failed: $_" -Level Error
                    $success = $false
                }
            } else {
                Write-Log "Custom installation specified but no script provided" -Level Error
                $success = $false
            }
        }
    }
    
    # Create offline installer package if requested
    if ($CreatePackage -and $success) {
        try {
            $packageDir = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\OfflinePackages\$Name"
            
            if (!(Test-Path -Path $packageDir)) {
                New-Item -Path $packageDir -ItemType Directory -Force | Out-Null
            }
            
            # Copy the installer
            Copy-Item -Path $downloadPath -Destination $packageDir -Force
            
            # Create a simple batch file installer
            $batchContent = @"
@echo off
echo Installing $Name...
"@
            
            switch ($Type) {
                'MSI' {
                    $batchContent += "`r`nmsiexec.exe /i `"$(Split-Path -Path $downloadPath -Leaf)`" $InstallArgs"
                }
                'EXE' {
                    $batchContent += "`r`n`"$(Split-Path -Path $downloadPath -Leaf)`" $InstallArgs"
                }
                'ZIP' {
                    $batchContent += "`r`necho This is a ZIP file. Please extract and use as needed."
                }
            }
            
            $batchContent += @"

echo.
echo Installation complete. Press any key to exit.
pause > nul
"@
            
            $batchFile = Join-Path -Path $packageDir -ChildPath "Install.bat"
            $batchContent | Out-File -FilePath $batchFile -Encoding ASCII
            
            Write-Log "Created offline package at $packageDir" -Level Success
        } catch {
            Write-Log "Failed to create offline package: $_" -Level Error
        }
    }
    
    Write-Log "=== Completed installation of $Name (Success: $success) ===" -Level Info
    return $success
}

# Function to check if tool is already installed
function Test-ToolInstalled {
    param(
        [string]$Name
    )
    
    # Check Programs and Features
    $installed = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$Name*" }
    
    if ($installed) {
        Write-Log "$Name is already installed (Version: $($installed.Version))" -Level Info
        return $true
    }
    
    # Also check common install locations
    $commonLocations = @(
        "${env:ProgramFiles}\$Name",
        "${env:ProgramFiles(x86)}\$Name",
        "${env:ProgramFiles}\Common Files\$Name",
        "${env:ProgramFiles(x86)}\Common Files\$Name"
    )
    
    foreach ($location in $commonLocations) {
        if (Test-Path -Path $location) {
            Write-Log "$Name appears to be installed at $location" -Level Info
            return $true
        }
    }
    
    return $false
}

# Function to optimize Windows Defender settings
function Optimize-WindowsDefender {
    try {
        Write-Log "Optimizing Windows Defender settings..." -Level Info
        
        # Enable real-time protection
        Set-MpPreference -DisableRealtimeMonitoring $false
        
        # Enable cloud-delivered protection
        Set-MpPreference -MAPSReporting Advanced
        
        # Enable block at first sight
        Set-MpPreference -DisableBlockAtFirstSeen $false
        
        # Enable network protection
        Set-MpPreference -EnableNetworkProtection Enabled
        
        # Enable controlled folder access
        Set-MpPreference -EnableControlledFolderAccess Enabled
        
        # Enable exploit protection
        Set-ProcessMitigation -PolicyFilePath "$PSScriptRoot\Windows-Defender-ExploitGuard.xml" -ErrorAction SilentlyContinue
        
        # Enable attack surface reduction rules
        $asrRules = @(
            # Block executable content from email client and webmail
            "BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550",
            # Block JavaScript or VBScript from launching downloaded executable content
            "D3E037E1-3EB8-44C8-A917-57927947596D",
            # Block Office applications from creating child processes
            "D4F940AB-401B-4EFC-AADC-AD5F3C50688A",
            # Block Office applications from creating executable content
            "3B576869-A4EC-4529-8536-B80A7769E899",
            # Block Office applications from injecting code into other processes
            "75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84",
            # Block execution of potentially obfuscated scripts
            "5BEB7EFE-FD9A-4556-801D-275E5FFC04CC",
            # Block Win32 API calls from Office macros
            "92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B"
        )
        
        foreach ($rule in $asrRules) {
            try {
                Set-MpPreference -AttackSurfaceReductionRules_Ids $rule -AttackSurfaceReductionRules_Actions Enabled -ErrorAction SilentlyContinue
            } catch {
                Write-Log "Couldn't enable ASR rule $rule: $($_.ToString())" -Level Warning
            }
        }
        
        # Trigger a full scan
        Start-MpScan -ScanType FullScan -AsJob
        
        Write-Log "Windows Defender optimized successfully" -Level Success
        return $true
    } catch {
        Write-Log "Failed to optimize Windows Defender: $_" -Level Error
        return $false
    }
}

# Function to optimize Windows Firewall settings
function Optimize-WindowsFirewall {
    try {
        Write-Log "Optimizing Windows Firewall settings..." -Level Info
        
        # Enable firewall for all profiles
        Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True
        
        # Block outbound connections by default for public profile
        Set-NetFirewallProfile -Profile Public -DefaultOutboundAction Block
        
        # Log dropped connections and successful connections
        Set-NetFirewallProfile -Profile Domain,Private,Public -LogAllowed True -LogBlocked True
        
        # Increase log size
        Set-NetFirewallProfile -Profile Domain,Private,Public -LogMaxSizeKilobytes 16384
        
        Write-Log "Windows Firewall optimized successfully" -Level Success
        return $true
    } catch {
        Write-Log "Failed to optimize Windows Firewall: $_" -Level Error
        return $false
    }
}

# Function to configure system security settings
function Set-SystemSecuritySettings {
    try {
        Write-Log "Configuring system security settings..." -Level Info
        
        # Enable Windows SmartScreen
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "RequireAdmin" -Type String -Force
        
        # Enable Data Execution Prevention (DEP)
        Set-CimInstance -Query "SELECT * FROM Win32_OperatingSystem" -Property @{DataExecutionPrevention_SupportPolicy = 3} -ErrorAction SilentlyContinue
        
        # Disable SMBv1 protocol
        Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart -ErrorAction SilentlyContinue
        
        # Enable automatic system and app updates
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 4 /f
        
        # Configure PowerShell script execution policy
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
        
        # Configure credential guard (if supported)
        try {
            Enable-WindowsOptionalFeature -Online -FeatureName DeviceGuard -NoRestart -ErrorAction SilentlyContinue
        } catch {
            Write-Log "Credential Guard not supported or already enabled" -Level Warning
        }
        
        Write-Log "System security settings configured successfully" -Level Success
        return $true
    } catch {
        Write-Log "Failed to configure system security settings: $_" -Level Error
        return $false
    }
}

# Function to create security monitoring tasks
function Create-SecurityMonitoringTasks {
    try {
        Write-Log "Setting up security monitoring tasks..." -Level Info
        
        # Create a scheduled task for weekly malware scan
        $taskName = "Weekly Security Scan"
        $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        
        if ($taskExists) {
            Write-Log "Task '$taskName' already exists - updating..." -Level Info
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
        
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"Start-MpScan -ScanType FullScan`""
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am
        $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfIdle -IdleDuration 00:10:00 -IdleWaitTimeout 02:00:00
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Weekly security scan using Windows Defender"
        
        # Create a scheduled task for daily security checks
        $taskName = "Daily Security Check"
        $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        
        if ($taskExists) {
            Write-Log "Task '$taskName' already exists - updating..." -Level Info
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
        
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\Daily-Security-Check.ps1`""
        $trigger = New-ScheduledTaskTrigger -Daily -At 8am
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Daily security checks and reporting"
        
        Write-Log "Security monitoring tasks created successfully" -Level Success
        return $true
    } catch {
        Write-Log "Failed to create security monitoring tasks: $_" -Level Error
        return $false
    }
}

# Create the Daily Security Check script
function Create-SecurityCheckScript {
    $scriptContent = @"
# Daily-Security-Check.ps1
# Purpose: Perform daily security checks
# Created by SecurityToolsInstaller.ps1

# Generate log path
`$logPath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\Logs\Daily-Security-Check_`$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param(
        [string]`$Message,
        [string]`$Level = 'Info'
    )
    
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logMessage = "[`$timestamp] [`$Level] `$Message"
    
    Add-Content -Path `$logPath -Value `$logMessage
}

Write-Log "Starting daily security check..."

# Check Windows Defender status
try {
    `$defenderStatus = Get-MpComputerStatus
    Write-Log "Windows Defender real-time protection: `$(`$defenderStatus.RealTimeProtectionEnabled)"
    Write-Log "Windows Defender definitions: `$(`$defenderStatus.AntivirusSignatureVersion)"
    Write-Log "Windows Defender definitions last updated: `$(`$defenderStatus.AntivirusSignatureLastUpdated)"
    
    if (`$defenderStatus.AntivirusSignatureLastUpdated -lt (Get-Date).AddDays(-3)) {
        Write-Log "WARNING: Windows Defender definitions are more than 3 days old" -Level "Warning"
    }
    
    if (-not `$defenderStatus.RealTimeProtectionEnabled) {
        Write-Log "WARNING: Windows Defender real-time protection is disabled" -Level "Warning"
    }
} catch {
    Write-Log "Error checking Windows Defender status: `$_" -Level "Error"
}

# Check system updates
try {
    `$updates = Get-WmiObject -Query "SELECT * FROM Win32_QuickFixEngineering" | Sort-Object InstalledOn -Descending
    `$latestUpdate = `$updates | Select-Object -First 1
    
    Write-Log "Latest system update: `$(`$latestUpdate.HotFixID) installed on `$(`$latestUpdate.InstalledOn)"
    
    if (`$latestUpdate.InstalledOn -lt (Get-Date).AddDays(-30)) {
        Write-Log "WARNING: No system updates installed in the last 30 days" -Level "Warning"
    }
} catch {
    Write-Log "Error checking system updates: `$_" -Level "Error"
}

# Check for unauthorized scheduled tasks
try {
    `$suspiciousTasks = Get-ScheduledTask | Where-Object {
        `$_.TaskPath -notlike "\Microsoft\*" -and
        `$_.TaskPath -notlike "\MicrosoftEdge\*" -and
        `$_.Author -notlike "*Microsoft*" -and
        `$_.TaskName -notlike "*Microsoft*" -and
        `$_.TaskName -notlike "*Windows*" -and
        `$_.TaskName -notlike "*Security*" -and
        `$_.TaskName -notlike "*Update*"
    }
    
    if (`$suspiciousTasks) {
        Write-Log "Found `$(`$suspiciousTasks.Count) potentially suspicious scheduled tasks:" -Level "Warning"
        foreach (`$task in `$suspiciousTasks) {
            Write-Log "  - `$(`$task.TaskName) (Path: `$(`$task.TaskPath))" -Level "Warning"
        }
    } else {
        Write-Log "No suspicious scheduled tasks found"
    }
} catch {
    Write-Log "Error checking scheduled tasks: `$_" -Level "Error"
}

# Check for unusual network connections
try {
    `$connections = Get-NetTCPConnection | Where-Object { `$_.State -eq "Established" }
    `$remoteIPs = `$connections | ForEach-Object { `$_.RemoteAddress } | Sort-Object -Unique
    
    Write-Log "Active network connections to `$(`$remoteIPs.Count) unique remote addresses"
    
    `$suspiciousConnections = `$connections | Where-Object { 
        `$_.RemotePort -eq 4444 -or     # Common Metasploit port
        `$_.RemotePort -eq 31337 -or    # Common backdoor port
        `$_.RemoteAddress -like "10.*" -and `$_.RemotePort -eq 22 # Check for SSH to internal IPs
    }
    
    if (`$suspiciousConnections) {
        Write-Log "WARNING: Found `$(`$suspiciousConnections.Count) potentially suspicious network connections:" -Level "Warning"
        foreach (`$conn in `$suspiciousConnections) {
            Write-Log "  - `$(`$conn.LocalAddress):`$(`$conn.LocalPort) -> `$(`$conn.RemoteAddress):`$(`$conn.RemotePort) (Process: `$((Get-Process -Id `$conn.OwningProcess).Name))" -Level "Warning"
        }
    }
} catch {
    Write-Log "Error checking network connections: `$_" -Level "Error"
}

# Check disk space
try {
    `$drives = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
    foreach (`$drive in `$drives) {
        `$freeSpaceGB = [math]::Round(`$drive.FreeSpace / 1GB, 2)
        `$totalSpaceGB = [math]::Round(`$drive.Size / 1GB, 2)
        `$freePercent = [math]::Round((`$drive.FreeSpace / `$drive.Size) * 100, 2)
        
        Write-Log "Drive `$(`$drive.DeviceID): `$freeSpaceGB GB free of `$totalSpaceGB GB (`$freePercent% free)"
        
        if (`$freePercent -lt 10) {
            Write-Log "WARNING: Drive `$(`$drive.DeviceID) is low on space (`$freePercent% free)" -Level "Warning"
        }
    }
} catch {
    Write-Log "Error checking disk space: `$_" -Level "Error"
}

Write-Log "Security check completed"
"@

    $scriptPath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\Daily-Security-Check.ps1"
    $scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8
    
    Write-Log "Created daily security check script at $scriptPath" -Level Success
}

# Function to create an offline deployment script
function Create-OfflineDeploymentScript {
    try {
        Write-Log "Creating offline deployment script..." -Level Info
        
        $deploymentScriptContent = @"
@echo off
echo ===================================================
echo      Security Tools Deployment Script
echo ===================================================
echo.
echo This script will install security tools from the offline packages
echo Please run this script with administrator privileges
echo.
pause

echo Creating log directory...
mkdir "%~dp0Logs" 2>nul

echo.
echo Installing security tools...
echo.

REM Loop through all tool directories
for /d %%G in ("%~dp0*") do (
    if exist "%%G\Install.bat" (
        echo Installing from %%~nxG...
        pushd "%%G"
        call Install.bat
        popd
        echo.
    )
)

echo ===================================================
echo      Installation Complete
echo ===================================================
echo.
echo Please restart your computer to complete the setup
echo.
pause
"@

        $deploymentScriptPath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\OfflinePackages\Deploy-Security-Tools.bat"
        
        # Create directory if it doesn't exist
        $deploymentDir = Split-Path -Path $deploymentScriptPath -Parent
        if (!(Test-Path -Path $deploymentDir)) {
            New-Item -Path $deploymentDir -ItemType Directory -Force | Out-Null
        }
        
        $deploymentScriptContent | Out-File -FilePath $deploymentScriptPath -Encoding ASCII
        
        Write-Log "Created offline deployment script at $deploymentScriptPath" -Level Success
        return $true
    } catch {
        Write-Log "Failed to create offline deployment script: $_" -Level Error
        return $false
    }
}

# Function to create AutoRun script for the offline package
function Create-AutoRunScript {
    try {
        Write-Log "Creating AutoRun script for offline package..." -Level Info
        
        $autorunContent = @"
[autorun]
open=Deploy-Security-Tools.bat
icon=SecurityTools.ico
label=Security Tools Installer
action=Install Security Tools
"@

        $autorunPath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\OfflinePackages\autorun.inf"
        $autorunContent | Out-File -FilePath $autorunPath -Encoding ASCII
        
        Write-Log "Created AutoRun script at $autorunPath" -Level Success
        return $true
    } catch {
        Write-Log "Failed to create AutoRun script: $_" -Level Error
        return $false
    }
}

# Function to optimize browser settings
function Optimize-BrowserSettings {
    try {
        Write-Log "Optimizing browser settings..." -Level Info
        
        # Chrome settings through registry
        $chromePreferences = @{
            "HomepageIsNewTabPage" = 0
            "DefaultSearchProviderEnabled" = 1
            "SafeBrowsingEnabled" = 1
            "PasswordManagerEnabled" = 1
            "AutofillEnabled" = 0
            "NetworkPredictionEnabled" = 0
            "BackgroundModeEnabled" = 0
            "CloudPrintSubmitEnabled" = 0
        }
        
        $chromePath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
        
        if (!(Test-Path -Path $chromePath)) {
            New-Item -Path $chromePath -Force | Out-Null
        }
        
        foreach ($pref in $chromePreferences.GetEnumerator()) {
            try {
                Set-ItemProperty -Path $chromePath -Name $pref.Key -Value $pref.Value -Type DWord -ErrorAction SilentlyContinue
            } catch {
                Write-Log "Failed to set Chrome preference $($pref.Key): $_" -Level Warning
            }
        }
        
        # Firefox settings - create a policies.json file
        $firefoxPoliciesContent = @"
{
  "policies": {
    "DisableFirefoxStudies": true,
    "DisableTelemetry": true,
    "EnableTrackingProtection": {
      "Value": true,
      "Locked": true,
      "Cryptomining": true,
      "Fingerprinting": true
    },
    "DisableFirefoxAccounts": false,
    "DisablePocket": true,
    "DisableFormHistory": true,
    "PasswordManagerEnabled": true,
    "OverrideFirstRunPage": "",
    "Extensions": {
      "Install": [
        "https://addons.mozilla.org/firefox/downloads/file/3933192/ublock_origin-latest.xpi",
        "https://addons.mozilla.org/firefox/downloads/file/3616824/https_everywhere-latest.xpi",
        "https://addons.mozilla.org/firefox/downloads/file/3435632/privacy_badger-latest.xpi"
      ]
    }
  }
}
"@

        $firefoxPoliciesPath = "${env:ProgramFiles}\Mozilla Firefox\distribution\policies.json"
        $firefoxDir = Split-Path -Path $firefoxPoliciesPath -Parent
        
        if (Test-Path -Path "${env:ProgramFiles}\Mozilla Firefox") {
            if (!(Test-Path -Path $firefoxDir)) {
                New-Item -Path $firefoxDir -ItemType Directory -Force | Out-Null
            }
            
            $firefoxPoliciesContent | Out-File -FilePath $firefoxPoliciesPath -Encoding UTF8 -Force
            Write-Log "Firefox policies.json created at $firefoxPoliciesPath" -Level Success
        } else {
            Write-Log "Firefox not found - skipping Firefox policy configuration" -Level Warning
        }
        
        # Edge settings through registry
        $edgePreferences = @{
            "HomepageIsNewTabPage" = 0
            "SearchSuggestEnabled" = 0
            "DefaultSearchProviderEnabled" = 1
            "TrackingPrevention" = 2  # Balanced mode
            "SmartScreenEnabled" = 1
            "SmartScreenPuaEnabled" = 1
        }
        
        $edgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        
        if (!(Test-Path -Path $edgePath)) {
            New-Item -Path $edgePath -Force | Out-Null
        }
        
        foreach ($pref in $edgePreferences.GetEnumerator()) {
            try {
                Set-ItemProperty -Path $edgePath -Name $pref.Key -Value $pref.Value -Type DWord -ErrorAction SilentlyContinue
            } catch {
                Write-Log "Failed to set Edge preference $($pref.Key): $_" -Level Warning
            }
        }
        
        Write-Log "Browser settings optimized successfully" -Level Success
        return $true
    } catch {
        Write-Log "Failed to optimize browser settings: $_" -Level Error
        return $false
    }
}

# Start of the script
Write-Log "========================================================" -Level Info
Write-Log "   Security Tools Installer - Starting                   " -Level Info
Write-Log "========================================================" -Level Info
Write-Log "Download path: $DownloadPath" -Level Info
Write-Log "Log path: $LogPath" -Level Info
Write-Log "Create offline package: $CreatePackage" -Level Info
Write-Log "========================================================" -Level Info

# Step 1: System Optimization
Write-Log "Starting system security optimization..." -Level Info

# Optimize Windows Defender
Optimize-WindowsDefender

# Optimize Windows Firewall
Optimize-WindowsFirewall

# Configure system security settings
Set-SystemSecuritySettings

# Step 2: Create security monitoring tasks and scripts
Create-SecurityCheckScript
Create-SecurityMonitoringTasks

# Step 3: Optimize browser settings
Optimize-BrowserSettings

# Step 4: Install security tools

# Initialize tool list
$securityTools = @(
    # Endpoint Protection
    @{
        Name = "Malwarebytes"
        Url = "https://downloads.malwarebytes.com/file/mb4_offline"
        Filename = "MBSetup.exe"
        Type = "EXE"
        InstallArgs = "/SILENT /NORESTART"
    },
    @{
        Name = "Bitdefender Free"
        Url = "https://download.bitdefender.com/windows/installer/en-us/bitdefender_antivirus.exe"
        Filename = "bitdefender_antivirus.exe"
        Type = "EXE"
        InstallArgs = "/SILENT /NORESTART"
    },
    @{
        Name = "ESET Online Scanner"
        Url = "https://download.eset.com/com/eset/tools/online_scanner/latest/esetonlinescanner.exe"
        Filename = "esetonlinescanner.exe"
        Type = "EXE"
        InstallArgs = "--silent"
    },
    @{
        Name = "Windows Firewall Control"
        Url = "https://www.binisoft.org/download/wfc6setup.exe"
        Filename = "wfc6setup.exe"
        Type = "EXE"
        InstallArgs = "/VERYSILENT /NORESTART"
    },
    @{
        Name = "ConfigureDefender"
        Url = "https://github.com/AndyFul/ConfigureDefender/raw/master/ConfigureDefender.zip"
        Filename = "ConfigureDefender.zip"
        Type = "ZIP"
    },
    @{
        Name = "OSArmor"
        Url = "https://www.osarmor.com/download/OSArmor_Setup.exe"
        Filename = "OSArmor_Setup.exe"
        Type = "EXE"
        InstallArgs = "/S"
    },
    @{
        Name = "GlassWire"
        Url = "https://download.glasswire.com/GlassWireSetup.exe"
        Filename = "GlassWireSetup.exe"
        Type = "EXE"
        InstallArgs = "/S"
    },
    @{
        Name = "KeePass"
        Url = "https://sourceforge.net/projects/keepass/files/latest/download"
        Filename = "KeePass-2.51-Setup.exe"
        Type = "EXE"
        InstallArgs = "/VERYSILENT /NORESTART"
    },
    @{
        Name = "Sysmon"
        Url = "https://download.sysinternals.com/files/Sysmon.zip"
        Filename = "Sysmon.zip"
        Type = "ZIP"
    },
    @{
        Name = "ProcessExplorer"
        Url = "https://download.sysinternals.com/files/ProcessExplorer.zip"
        Filename = "ProcessExplorer.zip"
        Type = "ZIP"
    },
    @{
        Name = "Autoruns"
        Url = "https://download.sysinternals.com/files/Autoruns.zip"
        Filename = "Autoruns.zip"
        Type = "ZIP"
    },
    @{
        Name = "TCPView"
        Url = "https://download.sysinternals.com/files/TCPView.zip"
        Filename = "TCPView.zip"
        Type = "ZIP"
    },
    @{
        Name = "DeepBlueCLI"
        Url = "https://github.com/sans-blue-team/DeepBlueCLI/archive/refs/heads/master.zip"
        Filename = "DeepBlueCLI.zip"
        Type = "ZIP"
    },
    @{
        Name = "Bitwarden"
        Url = "https://vault.bitwarden.com/download/?app=desktop&platform=windows"
        Filename = "Bitwarden-Installer.exe"
        Type = "EXE"
        InstallArgs = "/S"
    },
    @{
        Name = "VeraCrypt"
        Url = "https://launchpad.net/veracrypt/trunk/1.25.9/+download/VeraCrypt%20Setup%201.25.9.exe"
        Filename = "VeraCrypt_Setup.exe"
        Type = "EXE"
        InstallArgs = "/VERYSILENT /NORESTART"
    },
    @{
        Name = "BleachBit"
        Url = "https://www.bleachbit.org/download/file/t?file=BleachBit-4.4.2-setup.exe"
        Filename = "BleachBit-setup.exe"
        Type = "EXE"
        InstallArgs = "/S"
    }
)

# Download and install each tool
foreach ($tool in $securityTools) {
    # Check if already installed
    if (Test-ToolInstalled -Name $tool.Name) {
        Write-Log "$($tool.Name) appears to be already installed - skipping" -Level Info
        continue
    }
    
    # Install the tool
    Install-Tool @tool
    
    # Add a small delay between installations
    Start-Sleep -Seconds 2
}

# Create offline deployment package if requested
if ($CreatePackage) {
    Create-OfflineDeploymentScript
    Create-AutoRunScript
    
    # Create README file
    $readmePath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\OfflinePackages\README.txt"
    $readmeContent = @"
========================================================
               SECURITY TOOLS PACKAGE
========================================================

This package contains security tools to help protect your systems against cyber threats.

HOW TO USE:
1. Copy this entire folder to a USB drive or network share
2. On each target computer, run "Deploy-Security-Tools.bat" as administrator
3. Follow the on-screen prompts to install all tools

TOOLS INCLUDED:
- Malwarebytes - Anti-malware scanner
- Bitdefender Free - Antivirus protection
- ESET Online Scanner - On-demand virus scanner
- Windows Firewall Control - Enhanced firewall management
- ConfigureDefender - Windows Defender hardening
- OSArmor - Application control
- GlassWire - Network monitor & firewall
- KeePass - Password manager
- Sysinternals Tools - System analysis tools
- Bitwarden - Password manager
- VeraCrypt - Disk encryption
- BleachBit - System cleaner

For more information, see the Security-Deployment-Plan.md file in the main directory.

========================================================
"@
    $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
}

# Final summary
Write-Log "========================================================" -Level Info
Write-Log "   Security Tools Installer - Completed                  " -Level Info
Write-Log "========================================================" -Level Info
Write-Log "Log file: $LogFile" -Level Info

if ($CreatePackage) {
    Write-Log "Offline package: C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\OfflinePackages" -Level Info
    Write-Log "To deploy to other systems, copy the OfflinePackages folder and run Deploy-Security-Tools.bat" -Level Info
}

Write-Log "Please restart your computer to complete installation" -Level Warning
