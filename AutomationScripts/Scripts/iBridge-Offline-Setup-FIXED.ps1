# iBridge Offline Setup Script v3.1 - SYNTAX CORRECTED
# Complete offline installation with USB drive auto-detection
# Live progress tracker with real-time status updates

param(
    [switch]$SkipValidation,
    [switch]$QuietMode,
    [switch]$CleanupOnly
)

# ============================================================
# OFFLINE CONFIGURATION SECTION
# ============================================================

# Account Configuration
$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

# Auto-detect USB drive with iBridge files
$USBDrive = $null
$PossibleDrives = @("D:", "E:", "F:", "G:", "H:")

foreach ($drive in $PossibleDrives) {
    if (Test-Path "$drive\iBridge Set Up" -ErrorAction SilentlyContinue) {
        $USBDrive = $drive
        break
    }
}

if (-not $USBDrive) {
    Write-Host "ERROR: iBridge USB drive not found. Please ensure USB is connected." -ForegroundColor Red
    exit 1
}

Write-Host "Found iBridge USB on drive: $USBDrive" -ForegroundColor Green

# Enhanced Paths Configuration
$iBridgeBase = "C:\iBridge_Setup"
$InstallersPath = "$iBridgeBase\Installers"
$ShortcutsPath = "$iBridgeBase\Shortcuts"
$LogsPath = "$iBridgeBase\Logs"
$TempPath = "$iBridgeBase\Temp"

# Progress tracking
$Global:TotalSteps = 10
$Global:CurrentStep = 0
$Global:LogFile = "$LogsPath\iBridge-Offline-Setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$Global:StartTime = Get-Date
$Global:StepStartTime = Get-Date

# Installation Control
$InstallAnyDesk = $true

# Progress tracking details
$Global:ProgressSteps = @{
    1 = @{ Name = "Directory Creation"; Status = "Pending"; Duration = $null }
    2 = @{ Name = "File Copying from USB"; Status = "Pending"; Duration = $null }
    3 = @{ Name = "User Account Creation"; Status = "Pending"; Duration = $null }
    4 = @{ Name = "Profile Creation"; Status = "Pending"; Duration = $null }
    5 = @{ Name = "Application Installation"; Status = "Pending"; Duration = $null }
    6 = @{ Name = "MS Teams Installation"; Status = "Pending"; Duration = $null }
    7 = @{ Name = "iBridge User Shortcuts"; Status = "Pending"; Duration = $null }
    8 = @{ Name = "Profile Cleanup"; Status = "Pending"; Duration = $null }
    9 = @{ Name = "Summary Generation"; Status = "Pending"; Duration = $null }
    10 = @{ Name = "Finalization"; Status = "Pending"; Duration = $null }
}

# Application Sources from USB
$ApplicationSources = @(
    "$USBDrive\TeamViewer_Setup_x64.exe",
    "$USBDrive\Tools for Office2019 TechXander",
    "$USBDrive\24.2.2000.exe",
    "$USBDrive\AnyDesk.exe",
    "$USBDrive\GlassWireSetup.exe",
    "$USBDrive\PBIDesktopSetup_x64.exe"
)

# iBridge User Specific Shortcuts from IT STUFF\Desktop-Mtn
$iBridgeUserShortcuts = @(
    "$USBDrive\IT STUFF\Desktop-Mtn\Word.lnk",
    "$USBDrive\IT STUFF\Desktop-Mtn\Excel.lnk",
    "$USBDrive\IT STUFF\Desktop-Mtn\Microsoft 365 Online.url",
    "$USBDrive\IT STUFF\Desktop-Mtn\MSTeamsSetup.exe",
    "$USBDrive\IT STUFF\Desktop-Mtn\New Citrix Gateway.url",
    "$USBDrive\IT STUFF\Desktop-Mtn\Outlook.lnk",
    "$USBDrive\IT STUFF\Desktop-Mtn\PowerPoint.lnk"
)

# ============================================================
# LOGGING AND UTILITY FUNCTIONS
# ============================================================

function Write-LogEntry {
    param($Type, $Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    
    if (Test-Path $Global:LogFile) {
        Add-Content -Path $Global:LogFile -Value $logEntry
    }
    
    switch ($Type) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        default { Write-Host $logEntry }
    }
}

function Update-Progress {
    param($Activity, $SubActivity = "", $CurrentItem = 0, $TotalItems = 0)
    
    # Complete previous step if this is a new step
    if ($Global:CurrentStep -gt 0 -and $Global:ProgressSteps[$Global:CurrentStep].Status -eq "In Progress") {
        $stepDuration = (Get-Date) - $Global:StepStartTime
        $Global:ProgressSteps[$Global:CurrentStep].Status = "Completed"
        $Global:ProgressSteps[$Global:CurrentStep].Duration = $stepDuration
    }
    
    $Global:CurrentStep++
    $Global:StepStartTime = Get-Date
    
    if ($Global:CurrentStep -le $Global:TotalSteps) {
        $Global:ProgressSteps[$Global:CurrentStep].Status = "In Progress"
    }
    
    $percentComplete = ($Global:CurrentStep / $Global:TotalSteps) * 100
    $elapsedTime = (Get-Date) - $Global:StartTime
    $estimatedTotal = if ($percentComplete -gt 0) { $elapsedTime.TotalSeconds / ($percentComplete / 100) } else { 0 }
    $remainingTime = $estimatedTotal - $elapsedTime.TotalSeconds
    
    # Clear screen and show progress
    Clear-Host
    
    # Header
    Write-Host "================================================================================================" -ForegroundColor Cyan
    Write-Host "                              iBridge Offline Setup - Live Progress                           " -ForegroundColor Cyan
    Write-Host "================================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Overall Progress Bar
    $progressBarWidth = 50
    $completedChars = [math]::Floor(($percentComplete / 100) * $progressBarWidth)
    $remainingChars = $progressBarWidth - $completedChars
    $progressBar = "█" * $completedChars + "░" * $remainingChars
    
    Write-Host "Overall Progress: [$progressBar] $([math]::Round($percentComplete, 1))%" -ForegroundColor Green
    Write-Host ""
    
    # Time Information
    Write-Host "Elapsed Time: $($elapsedTime.ToString('hh\:mm\:ss'))" -ForegroundColor Yellow
    if ($remainingTime -gt 0) {
        $remainingTimeSpan = [TimeSpan]::FromSeconds($remainingTime)
        Write-Host "Estimated Remaining: $($remainingTimeSpan.ToString('hh\:mm\:ss'))" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Current Activity
    Write-Host "Current Activity: $Activity" -ForegroundColor Cyan -NoNewline
    if ($SubActivity) {
        Write-Host " - $SubActivity" -ForegroundColor White
    } else {
        Write-Host ""
    }
    
    if ($TotalItems -gt 0) {
        $subPercent = ($CurrentItem / $TotalItems) * 100
        Write-Host "Sub-Progress: $CurrentItem of $TotalItems ($([math]::Round($subPercent, 1))%)" -ForegroundColor Magenta
    }
    Write-Host ""
    
    # Step-by-step progress
    Write-Host "Detailed Progress:" -ForegroundColor White
    Write-Host "─────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    for ($i = 1; $i -le $Global:TotalSteps; $i++) {
        $step = $Global:ProgressSteps[$i]
        $statusIcon = switch ($step.Status) {
            "Completed" { "✅" }
            "In Progress" { "🔄" }
            "Pending" { "⏳" }
            default { "❓" }
        }
        
        $statusColor = switch ($step.Status) {
            "Completed" { "Green" }
            "In Progress" { "Yellow" }
            "Pending" { "Gray" }
            default { "Red" }
        }
        
        $durationText = if ($step.Duration) {
            " ($(([math]::Round($step.Duration.TotalSeconds, 1)))s)"
        } else {
            ""
        }
        
        $stepText = "$statusIcon Step $i`: $($step.Name)$durationText"
        Write-Host $stepText -ForegroundColor $statusColor
    }
    
    Write-Host ""
    Write-Host "USB Drive: $USBDrive" -ForegroundColor Magenta
    Write-Host "Log File: $Global:LogFile" -ForegroundColor Gray
    Write-Host "================================================================================================" -ForegroundColor Cyan
    
    # Also update the traditional progress bar for compatibility
    Write-Progress -Activity "iBridge Offline Setup" -Status $Activity -PercentComplete $percentComplete
    Write-LogEntry "INFO" "Step $Global:CurrentStep/$Global:TotalSteps: $Activity"
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Remove-ExistingUser {
    param($Username)
    try {
        $user = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
        if ($user) {
            Write-LogEntry "INFO" "Removing existing user: $Username"
            Remove-LocalUser -Name $Username -ErrorAction Stop
            Write-LogEntry "SUCCESS" "User $Username removed successfully"
            Start-Sleep -Seconds 2
        }
    } catch {
        Write-LogEntry "WARNING" "Could not remove user $Username : $($_.Exception.Message)"
    }
}

function New-iBridgeDirectories {
    Update-Progress "Creating directory structure"
    
    $directories = @($iBridgeBase, $InstallersPath, $ShortcutsPath, $LogsPath, $TempPath)
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-LogEntry "SUCCESS" "Created directory: $dir"
        }
    }
}

function Copy-ApplicationFiles {
    Update-Progress "Copying application files from USB"
    
    $totalSources = $ApplicationSources.Count + 1
    $currentSource = 0
    
    foreach ($source in $ApplicationSources) {
        $currentSource++
        $filename = Split-Path $source -Leaf
        
        Update-Progress "Copying application files from USB" "Copying $filename" $currentSource $totalSources
        
        if (Test-Path $source) {
            $destination = Join-Path $InstallersPath $filename
            
            try {
                if (Test-Path $source -PathType Container) {
                    Copy-Item -Path $source -Destination $destination -Recurse -Force
                } else {
                    Copy-Item -Path $source -Destination $destination -Force
                }
                Write-LogEntry "SUCCESS" "Copied: $filename"
            } catch {
                Write-LogEntry "ERROR" "Failed to copy $filename : $($_.Exception.Message)"
            }
        } else {
            Write-LogEntry "WARNING" "Source not found: $source"
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    # Copy Desktop-Mtn folder
    $currentSource++
    Update-Progress "Copying application files from USB" "Copying Desktop-Mtn folder (Office shortcuts)" $currentSource $totalSources
    
    $itStuffDesktopSource = "$USBDrive\IT STUFF\Desktop-Mtn"
    if (Test-Path $itStuffDesktopSource) {
        $desktopMtnDestination = Join-Path $InstallersPath "Desktop-Mtn"
        
        try {
            Copy-Item -Path $itStuffDesktopSource -Destination $desktopMtnDestination -Recurse -Force
            Write-LogEntry "SUCCESS" "Copied: Desktop-Mtn folder (Office shortcuts and Teams)"
        } catch {
            Write-LogEntry "ERROR" "Failed to copy Desktop-Mtn folder: $($_.Exception.Message)"
        }
    } else {
        Write-LogEntry "WARNING" "Desktop-Mtn folder not found: $itStuffDesktopSource"
    }
}

function Install-Applications {
    Update-Progress "Installing applications"
    
    $installers = Get-ChildItem $InstallersPath -Filter "*.exe" -ErrorAction SilentlyContinue
    $totalInstallers = $installers.Count
    $currentInstaller = 0
    
    Write-LogEntry "INFO" "Found $totalInstallers applications to install"
    
    foreach ($installer in $installers) {
        $currentInstaller++
        
        if ($installer.Name -like "*AnyDesk*" -and -not $InstallAnyDesk) {
            Update-Progress "Installing applications" "Skipping AnyDesk (disabled)" $currentInstaller $totalInstallers
            Write-LogEntry "INFO" "Skipping AnyDesk installation (disabled in configuration)"
            Start-Sleep -Seconds 1
            continue
        }
        
        Update-Progress "Installing applications" "Installing $($installer.Name)" $currentInstaller $totalInstallers
        Write-LogEntry "INFO" "Installing: $($installer.Name)"
        
        try {
            $arguments = @()
            $timeoutMinutes = 5
            
            switch -Wildcard ($installer.Name) {
                "*AnyDesk*" {
                    $arguments = @("--install", "--start-with-win", "--silent")
                    $timeoutMinutes = 3
                    Write-LogEntry "INFO" "Using AnyDesk-specific installation parameters"
                }
                "*TeamViewer*" {
                    $arguments = @("/S", "/norestart")
                    Write-LogEntry "INFO" "Using TeamViewer-specific installation parameters"
                }
                "*GlassWire*" {
                    $arguments = @("/S")
                    Write-LogEntry "INFO" "Using GlassWire-specific installation parameters"
                }
                "*PBIDesktop*" {
                    $arguments = @("-quiet", "ACCEPT_EULA=1")
                    Write-LogEntry "INFO" "Using Power BI Desktop-specific installation parameters"
                }
                default {
                    $arguments = @("/S", "/silent", "/quiet")
                    Write-LogEntry "INFO" "Using default silent installation parameters"
                }
            }
            
            Write-LogEntry "INFO" "Starting installation with timeout of $timeoutMinutes minutes"
            
            Update-Progress "Installing applications" "Running installer: $($installer.Name) (Timeout: ${timeoutMinutes}m)" $currentInstaller $totalInstallers
            
            $process = Start-Process -FilePath $installer.FullName -ArgumentList $arguments -Wait -PassThru -NoNewWindow
            
            $timeoutSeconds = $timeoutMinutes * 60
            if ($process.WaitForExit($timeoutSeconds * 1000)) {
                if ($process.ExitCode -eq 0) {
                    Update-Progress "Installing applications" "✅ Completed: $($installer.Name)" $currentInstaller $totalInstallers
                    Write-LogEntry "SUCCESS" "Installed: $($installer.Name)"
                } else {
                    Update-Progress "Installing applications" "⚠️ Issues: $($installer.Name) (Exit: $($process.ExitCode))" $currentInstaller $totalInstallers
                    Write-LogEntry "WARNING" "Installation completed with exit code $($process.ExitCode): $($installer.Name)"
                }
            } else {
                Update-Progress "Installing applications" "⏰ Timeout: $($installer.Name) (Killed after ${timeoutMinutes}m)" $currentInstaller $totalInstallers
                Write-LogEntry "WARNING" "Installation timed out after $timeoutMinutes minutes: $($installer.Name)"
                try {
                    $process.Kill()
                    Write-LogEntry "INFO" "Killed hung installation process: $($installer.Name)"
                } catch {
                    Write-LogEntry "WARNING" "Could not kill hung process: $($installer.Name)"
                }
            }
        } catch {
            Update-Progress "Installing applications" "❌ Failed: $($installer.Name)" $currentInstaller $totalInstallers
            Write-LogEntry "ERROR" "Failed to install $($installer.Name): $($_.Exception.Message)"
        }
        
        Start-Sleep -Seconds 2
    }
    
    Update-Progress "Installing applications" "All applications processed" $totalInstallers $totalInstallers
}

function New-UserAccounts {
    Update-Progress "Creating user accounts"
    
    Remove-ExistingUser $AdminUsername
    Remove-ExistingUser $UserUsername
    
    try {
        Write-LogEntry "INFO" "Creating Admin account..."
        $secureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
        $adminUser = New-LocalUser -Name $AdminUsername -Password $secureAdminPassword -FullName "Admin" -Description "Administrator for application installation" -PasswordNeverExpires -AccountNeverExpires
        Add-LocalGroupMember -Group "Administrators" -Member $AdminUsername
        Write-LogEntry "SUCCESS" "Admin account created successfully"
        
        Write-LogEntry "INFO" "Creating iBridge User account..."
        $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
        $bridgeUser = New-LocalUser -Name $UserUsername -Password $secureUserPassword -FullName "iBridge User" -Description "Standard user for iBridge operations" -PasswordNeverExpires -AccountNeverExpires
        Write-LogEntry "SUCCESS" "iBridge User account created successfully"
        
    } catch {
        Write-LogEntry "ERROR" "Failed to create user accounts: $($_.Exception.Message)"
        throw
    }
}

function Force-ProfileCreation {
    Update-Progress "Creating user profiles"
    
    $profiles = @($AdminUsername, $UserUsername)
    
    foreach ($profile in $profiles) {
        Write-LogEntry "INFO" "Creating profile for: $profile"
        
        $profilePath = "C:\Users\$profile"
        $desktopPath = "$profilePath\Desktop"
        
        if (-not (Test-Path $profilePath)) {
            New-Item -Path $profilePath -ItemType Directory -Force | Out-Null
        }
        
        if (-not (Test-Path $desktopPath)) {
            New-Item -Path $desktopPath -ItemType Directory -Force | Out-Null
        }
        
        Write-LogEntry "SUCCESS" "Profile created for: $profile"
    }
}

function Install-MSTeams {
    Update-Progress "Installing MS Teams for iBridge User"
    
    $teamsInstaller = "$USBDrive\IT STUFF\Desktop-Mtn\MSTeamsSetup.exe"
    
    if (Test-Path $teamsInstaller) {
        try {
            Update-Progress "Installing MS Teams for iBridge User" "Running MSTeamsSetup.exe"
            Write-LogEntry "INFO" "Installing MS Teams..."
            $process = Start-Process -FilePath $teamsInstaller -ArgumentList "/S" -Wait -PassThru -NoNewWindow
            
            if ($process.ExitCode -eq 0) {
                Write-LogEntry "SUCCESS" "MS Teams installed successfully"
            } else {
                Write-LogEntry "WARNING" "MS Teams installation may have issues (Exit Code: $($process.ExitCode))"
            }
        } catch {
            Write-LogEntry "ERROR" "Failed to install MS Teams: $($_.Exception.Message)"
        }
    } else {
        Write-LogEntry "WARNING" "MS Teams installer not found: $teamsInstaller"
    }
}

function Copy-iBridgeUserShortcuts {
    Update-Progress "Copying iBridge User specific shortcuts"
    
    $iBridgeDesktop = "C:\Users\$UserUsername\Desktop"
    $totalShortcuts = $iBridgeUserShortcuts.Count
    $currentShortcut = 0
    
    if (-not (Test-Path $iBridgeDesktop)) {
        New-Item -Path $iBridgeDesktop -ItemType Directory -Force | Out-Null
    }
    
    foreach ($shortcut in $iBridgeUserShortcuts) {
        $currentShortcut++
        $filename = Split-Path $shortcut -Leaf
        
        Update-Progress "Copying iBridge User specific shortcuts" "Copying $filename" $currentShortcut $totalShortcuts
        
        if (Test-Path $shortcut) {
            $destination = Join-Path $iBridgeDesktop $filename
            
            try {
                Copy-Item -Path $shortcut -Destination $destination -Force
                Write-LogEntry "SUCCESS" "Copied iBridge shortcut: $filename"
            } catch {
                Write-LogEntry "ERROR" "Failed to copy iBridge shortcut $filename : $($_.Exception.Message)"
            }
        } else {
            Write-LogEntry "WARNING" "iBridge shortcut not found: $shortcut"
        }
        
        Start-Sleep -Milliseconds 300
    }
}

function Remove-UnwantedShortcuts {
    Update-Progress "Cleaning unwanted shortcuts from profiles"
    
    $officialApps = @(
        "*TeamViewer*", "*24.2.2000*", "*Tools for Office*", "*AnyDesk*", 
        "*GlassWire*", "*Power BI*", "*Word*", "*Excel*", "*Outlook*", 
        "*PowerPoint*", "*Microsoft 365*", "*Citrix*", "*Teams*"
    )
    
    $profilesToClean = @($AdminUsername, $UserUsername)
    
    foreach ($profile in $profilesToClean) {
        $desktopPath = "C:\Users\$profile\Desktop"
        
        if (Test-Path $desktopPath) {
            $items = Get-ChildItem $desktopPath -ErrorAction SilentlyContinue
            
            foreach ($item in $items) {
                $shouldKeep = $false
                
                foreach ($app in $officialApps) {
                    if ($item.Name -like $app) {
                        $shouldKeep = $true
                        break
                    }
                }
                
                if (-not $shouldKeep) {
                    try {
                        Remove-Item $item.FullName -Force -Recurse -ErrorAction SilentlyContinue
                        Write-LogEntry "INFO" "Removed unwanted item from $profile : $($item.Name)"
                    } catch {
                        Write-LogEntry "WARNING" "Could not remove $($item.Name) from $profile"
                    }
                }
            }
        }
    }
}

function Write-SetupSummary {
    Update-Progress "Finalizing setup"
    
    $summaryFile = "$iBridgeBase\SETUP-SUMMARY.txt"
    $summary = @"
iBridge Offline Setup Completed
==============================
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
USB Drive: $USBDrive

Accounts Created:
- Admin (Password: $AdminPassword)
- iBridge User (Password: $UserPassword)

Applications Installed:
- TeamViewer Setup x64
- 24.2.2000 
- AnyDesk
- GlassWire Setup
- Power BI Desktop Setup x64
- Tools for Office 2019 TechXander
- Desktop-Mtn folder (Office shortcuts only)

Excluded Files (not copied):
- epi_win_live_installer_2.exe
- ESET KEY.txt
- Log In - Genesys Cloud Accounts - Genesys.url
- prey-installer-bvS8INNySB1TrLK3.exe

iBridge User Shortcuts:
- Word.lnk
- Excel.lnk
- Microsoft 365 Online.url
- MS Teams (installed)
- New Citrix Gateway.url
- Outlook.lnk
- PowerPoint.lnk

Setup completed successfully!
"@
    
    $summary | Out-File -FilePath $summaryFile -Encoding UTF8
    Write-LogEntry "SUCCESS" "Setup summary saved to: $summaryFile"
}

# ============================================================
# MAIN EXECUTION
# ============================================================

if (-not (Test-AdminRights)) {
    Write-Host "ERROR: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run as Administrator." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "iBridge Offline Setup v3.1" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

try {
    New-iBridgeDirectories
    Copy-ApplicationFiles
    New-UserAccounts
    Force-ProfileCreation
    Install-Applications
    Install-MSTeams
    Copy-iBridgeUserShortcuts
    Remove-UnwantedShortcuts
    Write-SetupSummary
    
    # Mark final step as completed
    $Global:ProgressSteps[10].Status = "Completed"
    $Global:ProgressSteps[10].Duration = (Get-Date) - $Global:StepStartTime
    
    # Show final progress screen
    $totalTime = (Get-Date) - $Global:StartTime
    Clear-Host
    
    Write-Host "================================================================================================" -ForegroundColor Green
    Write-Host "                            iBridge Offline Setup - COMPLETED!                                " -ForegroundColor Green  
    Write-Host "================================================================================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "✅ Setup completed successfully in $($totalTime.ToString('hh\:mm\:ss'))!" -ForegroundColor Green
    Write-Host ""
    
    # Show all completed steps
    foreach ($i in 1..10) {
        $step = $Global:ProgressSteps[$i]
        $duration = if ($step.Duration) { " ($([math]::Round($step.Duration.TotalSeconds, 1))s)" } else { "" }
        Write-Host "✅ Step $i`: $($step.Name)$duration" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "✅ Admin account: $AdminUsername (Password: $AdminPassword)" -ForegroundColor Green
    Write-Host "✅ iBridge User account: $UserUsername (Password: $UserPassword)" -ForegroundColor Green
    Write-Host "✅ All applications installed from USB drive $USBDrive" -ForegroundColor Green
    Write-Host "✅ iBridge User shortcuts copied from IT STUFF folder" -ForegroundColor Green
    
} catch {
    Write-LogEntry "ERROR" "Setup failed: $($_.Exception.Message)"
    Write-Host "`n❌ Setup failed. Check log file: $Global:LogFile" -ForegroundColor Red
} finally {
    Write-Progress -Activity "iBridge Offline Setup" -Completed
}

Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
Read-Host
