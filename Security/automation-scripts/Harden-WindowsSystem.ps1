<#
.SYNOPSIS
    Complete Windows System Hardening Script
    
.DESCRIPTION
    This script implements comprehensive security hardening for Windows systems
    based on industry best practices and security benchmarks.
    
.PARAMETER Level
    Security hardening level: Basic, Standard, High, Maximum
    
.PARAMETER BackupConfig
    Create backup of current configuration before applying changes
    
.PARAMETER LogPath
    Path for detailed logging of all changes made
    
.EXAMPLE
    .\Harden-WindowsSystem.ps1 -Level High -BackupConfig -LogPath "C:\Logs\Hardening.log"
    
.NOTES
    Author: Security Team
    Version: 1.0
    Requires: Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Basic", "Standard", "High", "Maximum")]
    [string]$Level = "Standard",
    
    [Parameter(Mandatory=$false)]
    [switch]$BackupConfig,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\Logs\SystemHardening.log"
)

# Initialize logging
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogPath -Value $logEntry
}

# Ensure log directory exists
$logDir = Split-Path -Path $LogPath -Parent
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

Write-Log "Starting Windows System Hardening - Level: $Level"

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "This script must be run as Administrator!" "ERROR"
    throw "Administrator privileges required"
}

# Backup current configuration if requested
if ($BackupConfig) {
    Write-Log "Creating configuration backup..."
    $backupPath = "C:\SecurityBackup\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    
    # Export current settings
    Export-StartLayout -Path "$backupPath\StartLayout.xml" -ErrorAction SilentlyContinue
    reg export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies" "$backupPath\Policies.reg" /y
    reg export "HKLM\SYSTEM\CurrentControlSet\Services" "$backupPath\Services.reg" /y
    
    Write-Log "Configuration backed up to: $backupPath"
}

# Security hardening functions
function Set-RegistrySecurity {
    Write-Log "Applying registry security settings..."
    
    # Disable unnecessary services based on level
    $servicesToDisable = @()
    
    switch ($Level) {
        "Basic" { 
            $servicesToDisable += @("Fax", "TelnetD", "RemoteRegistry")
        }
        "Standard" { 
            $servicesToDisable += @("Fax", "TelnetD", "RemoteRegistry", "SSDPSRV", "upnphost", "WSearch")
        }
        "High" { 
            $servicesToDisable += @("Fax", "TelnetD", "RemoteRegistry", "SSDPSRV", "upnphost", "WSearch", "Spooler", "Browser")
        }
        "Maximum" { 
            $servicesToDisable += @("Fax", "TelnetD", "RemoteRegistry", "SSDPSRV", "upnphost", "WSearch", "Spooler", "Browser", "Themes", "TabletInputService")
        }
    }
    
    foreach ($service in $servicesToDisable) {
        try {
            Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled
            Write-Log "Disabled service: $service"
        } catch {
            Write-Log "Failed to disable service: $service - $($_.Exception.Message)" "WARNING"
        }
    }
    
    # Disable SMBv1
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
        Write-Log "Disabled SMBv1 protocol"
    } catch {
        Write-Log "Failed to disable SMBv1: $($_.Exception.Message)" "WARNING"
    }
    
    # Configure User Account Control
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser" -Value 1
    Write-Log "Configured User Account Control settings"
    
    # Disable AutoRun/AutoPlay
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoAutorun" -Value 1
    Write-Log "Disabled AutoRun/AutoPlay"
    
    # Configure Windows Update settings
    if ($Level -in @("High", "Maximum")) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 4
        Write-Log "Configured automatic Windows Updates"
    }
}

function Set-NetworkSecurity {
    Write-Log "Configuring network security settings..."
    
    # Disable IPv6 if not needed (High/Maximum levels)
    if ($Level -in @("High", "Maximum")) {
        try {
            Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6
            Write-Log "Disabled IPv6 on all network adapters"
        } catch {
            Write-Log "Failed to disable IPv6: $($_.Exception.Message)" "WARNING"
        }
    }
    
    # Configure firewall profiles
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow
    Set-NetFirewallProfile -Profile Domain,Public,Private -LogAllowed True -LogBlocked True
    Write-Log "Configured Windows Firewall profiles"
    
    # Disable unnecessary network protocols
    try {
        Disable-NetAdapterBinding -Name "*" -ComponentID ms_lltdio
        Disable-NetAdapterBinding -Name "*" -ComponentID ms_rspndr
        Write-Log "Disabled unnecessary network protocols"
    } catch {
        Write-Log "Failed to disable network protocols: $($_.Exception.Message)" "WARNING"
    }
}

function Set-WindowsDefenderSecurity {
    Write-Log "Configuring Windows Defender security..."
    
    try {
        # Enable real-time protection
        Set-MpPreference -DisableRealtimeMonitoring $false
        Set-MpPreference -DisableBehaviorMonitoring $false
        Set-MpPreference -DisableBlockAtFirstSeen $false
        Set-MpPreference -DisableIOAVProtection $false
        
        # Enable cloud protection
        Set-MpPreference -MAPSReporting Advanced
        Set-MpPreference -SubmitSamplesConsent SendAllSamples
        
        # Configure threat actions
        Set-MpPreference -HighThreatDefaultAction Quarantine
        Set-MpPreference -ModerateThreatDefaultAction Quarantine
        Set-MpPreference -LowThreatDefaultAction Quarantine
        Set-MpPreference -SevereThreatDefaultAction Quarantine
        
        # Enable controlled folder access for ransomware protection
        if ($Level -in @("High", "Maximum")) {
            Set-MpPreference -EnableControlledFolderAccess Enabled
            Write-Log "Enabled Controlled Folder Access"
        }
        
        Write-Log "Windows Defender configured successfully"
    } catch {
        Write-Log "Failed to configure Windows Defender: $($_.Exception.Message)" "WARNING"
    }
}

function Set-PowerShellSecurity {
    Write-Log "Configuring PowerShell security..."
    
    # Configure PowerShell execution policy
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
    
    # Enable PowerShell logging (High/Maximum levels)
    if ($Level -in @("High", "Maximum")) {
        # Enable module logging
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
        if (!(Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "EnableModuleLogging" -Value 1
        
        # Enable script block logging
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
        if (!(Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "EnableScriptBlockLogging" -Value 1
        
        Write-Log "Enabled PowerShell enhanced logging"
    }
}

function Set-AuditPolicies {
    Write-Log "Configuring audit policies..."
    
    # Enable audit policies based on level
    $auditPolicies = @{
        "Basic" = @(
            "Audit Logon Events",
            "Audit Account Logon Events",
            "Audit Privilege Use"
        )
        "Standard" = @(
            "Audit Logon Events",
            "Audit Account Logon Events", 
            "Audit Privilege Use",
            "Audit Policy Change",
            "Audit System Events"
        )
        "High" = @(
            "Audit Logon Events",
            "Audit Account Logon Events",
            "Audit Privilege Use", 
            "Audit Policy Change",
            "Audit System Events",
            "Audit Object Access",
            "Audit Process Tracking"
        )
        "Maximum" = @(
            "Audit Logon Events",
            "Audit Account Logon Events",
            "Audit Privilege Use",
            "Audit Policy Change", 
            "Audit System Events",
            "Audit Object Access",
            "Audit Process Tracking",
            "Audit Directory Service Access",
            "Audit Account Management"
        )
    }
    
    foreach ($policy in $auditPolicies[$Level]) {
        try {
            auditpol /set /category:"$policy" /success:enable /failure:enable | Out-Null
            Write-Log "Enabled audit policy: $policy"
        } catch {
            Write-Log "Failed to set audit policy: $policy" "WARNING"
        }
    }
}

function Set-UserAccountPolicies {
    Write-Log "Configuring user account policies..."
    
    # Configure password policy via secedit
    $secpolContent = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[System Access]
MinimumPasswordAge = 1
MaximumPasswordAge = 90
MinimumPasswordLength = 12
PasswordComplexity = 1
PasswordHistorySize = 12
LockoutBadCount = 5
ResetLockoutCount = 30
LockoutDuration = 30
[Event Audit]
AuditSystemEvents = 3
AuditLogonEvents = 3
AuditObjectAccess = 3
AuditPrivilegeUse = 3
AuditPolicyChange = 3
AuditAccountManage = 3
AuditProcessTracking = 3
AuditDSAccess = 3
AuditAccountLogon = 3
"@
    
    $tempFile = "$env:TEMP\secpol.inf"
    $secpolContent | Out-File -FilePath $tempFile -Encoding ASCII
    
    try {
        secedit /configure /db c:\windows\security\local.sdb /cfg $tempFile /areas SECURITYPOLICY | Out-Null
        Remove-Item $tempFile -Force
        Write-Log "Applied security policy configuration"
    } catch {
        Write-Log "Failed to apply security policy: $($_.Exception.Message)" "WARNING"
    }
}

# Main execution
try {
    Write-Log "Beginning system hardening process..."
    
    Set-RegistrySecurity
    Set-NetworkSecurity  
    Set-WindowsDefenderSecurity
    Set-PowerShellSecurity
    Set-AuditPolicies
    Set-UserAccountPolicies
    
    Write-Log "System hardening completed successfully!" "SUCCESS"
    Write-Log "Please reboot the system to ensure all changes take effect."
    
    # Generate summary report
    $reportPath = "C:\SecurityReports\HardeningReport-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $reportDir = Split-Path -Path $reportPath -Parent
    if (!(Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $report = @"
Windows System Hardening Report
Generated: $(Get-Date)
Hardening Level: $Level
Log File: $LogPath

Summary of Changes Applied:
- Registry security settings configured
- Network security policies applied
- Windows Defender configuration updated
- PowerShell security enhanced
- Audit policies configured
- User account policies strengthened

Next Steps:
1. Reboot the system
2. Verify all critical applications still function
3. Test network connectivity
4. Review security logs regularly
5. Schedule regular security scans

For detailed information, review the log file: $LogPath
"@
    
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Log "Hardening report generated: $reportPath"
    
} catch {
    Write-Log "System hardening failed: $($_.Exception.Message)" "ERROR"
    throw
}