<#
.SYNOPSIS
    Simple Windows Defender Configuration Script
    
.DESCRIPTION
    Configures Windows Defender with enhanced security settings for maximum protection.
    
.PARAMETER MaxProtection
    Enable maximum protection settings
    
.EXAMPLE
    .\Configure-WindowsDefender-Simple.ps1 -MaxProtection
    
.NOTES
    Author: Security Team
    Version: 1.0
    Requires: Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$MaxProtection
)

function Write-Status {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    $color = switch ($Type) {
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Status "This script must be run as Administrator!" "ERROR"
    throw "Administrator privileges required"
}

Write-Status "Starting Windows Defender Configuration..." "INFO"

try {
    # Check if Windows Defender is available
    $defenderStatus = Get-MpComputerStatus
    Write-Status "Windows Defender is available and running" "SUCCESS"
} catch {
    Write-Status "Windows Defender not available: $($_.Exception.Message)" "ERROR"
    throw "Windows Defender is not available on this system"
}

try {
    Write-Status "Configuring core protection settings..." "INFO"
    
    # Enable real-time protection
    Set-MpPreference -DisableRealtimeMonitoring $false
    Write-Status "✓ Enabled real-time monitoring" "SUCCESS"
    
    # Enable behavior monitoring
    Set-MpPreference -DisableBehaviorMonitoring $false
    Write-Status "✓ Enabled behavior monitoring" "SUCCESS"
    
    # Enable IOAV protection
    Set-MpPreference -DisableIOAVProtection $false
    Write-Status "✓ Enabled IOAV protection" "SUCCESS"
    
    # Enable script scanning
    Set-MpPreference -DisableScriptScanning $false
    Write-Status "✓ Enabled script scanning" "SUCCESS"
    
    # Enable intrusion prevention system
    Set-MpPreference -DisableIntrusionPreventionSystem $false
    Write-Status "✓ Enabled intrusion prevention system" "SUCCESS"
    
} catch {
    Write-Status "Failed to configure core protection: $($_.Exception.Message)" "ERROR"
}

try {
    Write-Status "Configuring cloud protection..." "INFO"
    
    # Enable cloud protection
    Set-MpPreference -MAPSReporting Advanced
    Write-Status "✓ Enabled advanced MAPS reporting" "SUCCESS"
    
    # Enable automatic sample submission
    Set-MpPreference -SubmitSamplesConsent SendAllSamples
    Write-Status "✓ Enabled automatic sample submission" "SUCCESS"
    
    # Enable block at first sight
    Set-MpPreference -DisableBlockAtFirstSeen $false
    Write-Status "✓ Enabled block at first sight" "SUCCESS"
    
    if ($MaxProtection) {
        Set-MpPreference -CloudBlockLevel HighPlus
        Set-MpPreference -CloudExtendedTimeout 50
        Write-Status "✓ Set maximum cloud protection level" "SUCCESS"
    } else {
        Set-MpPreference -CloudBlockLevel Default
        Set-MpPreference -CloudExtendedTimeout 10
        Write-Status "✓ Set standard cloud protection level" "SUCCESS"
    }
    
} catch {
    Write-Status "Failed to configure cloud protection: $($_.Exception.Message)" "ERROR"
}

try {
    Write-Status "Configuring threat response actions..." "INFO"
    
    # Set default actions for all threat levels
    Set-MpPreference -SevereThreatDefaultAction Quarantine
    Set-MpPreference -HighThreatDefaultAction Quarantine
    Set-MpPreference -ModerateThreatDefaultAction Quarantine
    Set-MpPreference -LowThreatDefaultAction Quarantine
    Set-MpPreference -UnknownThreatDefaultAction Quarantine
    
    Write-Status "✓ Configured all threats to quarantine" "SUCCESS"
    
} catch {
    Write-Status "Failed to configure threat actions: $($_.Exception.Message)" "ERROR"
}

try {
    Write-Status "Configuring scan settings..." "INFO"
    
    # Enable comprehensive scanning
    Set-MpPreference -DisableArchiveScanning $false
    Set-MpPreference -DisableEmailScanning $false
    Set-MpPreference -DisableRemovableDriveScanning $false
    
    # Configure scan schedule
    Set-MpPreference -ScanScheduleDay 0  # Every day
    Set-MpPreference -ScanScheduleTime 02:00:00
    
    # Configure CPU usage
    Set-MpPreference -ScanAvgCPULoadFactor 50
    
    Write-Status "✓ Configured scan settings" "SUCCESS"
    
} catch {
    Write-Status "Failed to configure scan settings: $($_.Exception.Message)" "ERROR"
}

if ($MaxProtection) {
    try {
        Write-Status "Enabling Controlled Folder Access (Ransomware Protection)..." "INFO"
        
        Set-MpPreference -EnableControlledFolderAccess Enabled
        Write-Status "✓ Enabled Controlled Folder Access" "SUCCESS"
        
        # Add protected folders
        $protectedFolders = @(
            "$env:USERPROFILE\Documents",
            "$env:USERPROFILE\Pictures", 
            "$env:USERPROFILE\Videos",
            "$env:USERPROFILE\Desktop"
        )
        
        foreach ($folder in $protectedFolders) {
            if (Test-Path $folder) {
                try {
                    Add-MpPreference -ControlledFolderAccessProtectedFolders $folder
                    Write-Status "✓ Protected folder: $folder" "SUCCESS"
                } catch {
                    Write-Status "Could not protect folder: $folder" "WARNING"
                }
            }
        }
        
    } catch {
        Write-Status "Failed to configure Controlled Folder Access: $($_.Exception.Message)" "WARNING"
    }
}

try {
    Write-Status "Updating security intelligence..." "INFO"
    
    Update-MpSignature
    Write-Status "✓ Updated security signatures" "SUCCESS"
    
} catch {
    Write-Status "Failed to update security intelligence: $($_.Exception.Message)" "WARNING"
}

# Generate simple status report
try {
    Write-Status "Generating status report..." "INFO"
    
    $status = Get-MpComputerStatus
    $preferences = Get-MpPreference
    
    Write-Host "`n=== WINDOWS DEFENDER STATUS REPORT ===" -ForegroundColor Cyan
    Write-Host "Real-time Protection: " -NoNewline
    Write-Host "$($status.RealTimeProtectionEnabled)" -ForegroundColor $(if($status.RealTimeProtectionEnabled){"Green"}else{"Red"})
    
    Write-Host "Behavior Monitoring: " -NoNewline  
    Write-Host "$($status.BehaviorMonitorEnabled)" -ForegroundColor $(if($status.BehaviorMonitorEnabled){"Green"}else{"Red"})
    
    Write-Host "Cloud Protection: " -NoNewline
    Write-Host "$($preferences.MAPSReporting)" -ForegroundColor Green
    
    Write-Host "Controlled Folder Access: " -NoNewline
    Write-Host "$($preferences.EnableControlledFolderAccess)" -ForegroundColor $(if($preferences.EnableControlledFolderAccess -eq "Enabled"){"Green"}else{"Yellow"})
    
    Write-Host "Last Signature Update: " -NoNewline
    Write-Host "$($status.AntivirusSignatureLastUpdated)" -ForegroundColor Green
    
    Write-Host "`n=== CONFIGURATION COMPLETE ===" -ForegroundColor Green
    Write-Host "Windows Defender is now configured with enhanced protection!" -ForegroundColor White
    
    if ($MaxProtection) {
        Write-Host "`nMaximum protection mode enabled:" -ForegroundColor Cyan
        Write-Host "• Controlled Folder Access enabled" -ForegroundColor White
        Write-Host "• Maximum cloud protection level" -ForegroundColor White
        Write-Host "• Extended timeout for cloud analysis" -ForegroundColor White
    }
    
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    Write-Host "1. Keep Windows updated regularly" -ForegroundColor White
    Write-Host "2. Run weekly full system scans" -ForegroundColor White
    Write-Host "3. Review quarantined items monthly" -ForegroundColor White
    Write-Host "4. Monitor Windows Security center for alerts" -ForegroundColor White
    
} catch {
    Write-Status "Failed to generate status report: $($_.Exception.Message)" "ERROR"
}

Write-Status "Windows Defender configuration completed successfully!" "SUCCESS"