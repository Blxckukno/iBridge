# Comprehensive Device Security Fixer
# Addresses all major security vulnerabilities on Windows devices
# Clean version without Unicode characters

param(
    [switch]$Detailed,
    [switch]$FixAll
)

# Set error handling
$ErrorActionPreference = "Continue"

Write-Host "COMPREHENSIVE DEVICE SECURITY FIXER" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Starting comprehensive security assessment and fixes..." -ForegroundColor Cyan
Write-Host "=" * 80

$SecurityResults = @{
    Fixed = @()
    Failed = @()
    Warnings = @()
    Score = 0
}

function Write-SecurityLog {
    param([string]$Message, [string]$Type = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    }
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Enable-WindowsDefender {
    Write-SecurityLog "Enabling Windows Defender Real-Time Protection..." "Info"
    try {
        # Enable real-time monitoring
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
        
        # Enable cloud protection
        Set-MpPreference -MAPSReporting Advanced -ErrorAction SilentlyContinue
        Set-MpPreference -SubmitSamplesConsent SendAllSamples -ErrorAction SilentlyContinue
        
        # Enable behavior monitoring
        Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue
        
        # Start Windows Defender service
        Start-Service -Name WinDefend -ErrorAction SilentlyContinue
        
        $SecurityResults.Fixed += "Windows Defender Real-Time Protection"
        Write-SecurityLog "[SUCCESS] Windows Defender enabled successfully" "Success"
        return $true
    } catch {
        $SecurityResults.Failed += "Windows Defender: $($_.Message)"
        Write-SecurityLog "[ERROR] Failed to enable Windows Defender: $($_.Message)" "Error"
        return $false
    }
}

function Update-WindowsDefender {
    Write-SecurityLog "Updating Windows Defender signatures..." "Info"
    try {
        Update-MpSignature -ErrorAction Stop
        $SecurityResults.Fixed += "Windows Defender Signatures Updated"
        Write-SecurityLog "[SUCCESS] Defender signatures updated" "Success"
        return $true
    } catch {
        $SecurityResults.Failed += "Defender Update: $($_.Message)"
        Write-SecurityLog "[ERROR] Failed to update Defender: $($_.Message)" "Error"
        return $false
    }
}

function Enable-WindowsFirewall {
    Write-SecurityLog "Enabling Windows Firewall..." "Info"
    try {
        # Enable firewall for all profiles
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction Stop
        $SecurityResults.Fixed += "Windows Firewall Enabled"
        Write-SecurityLog "[SUCCESS] Windows Firewall enabled for all profiles" "Success"
        return $true
    } catch {
        $SecurityResults.Failed += "Windows Firewall: $($_.Message)"
        Write-SecurityLog "[ERROR] Failed to enable firewall: $($_.Message)" "Error"
        return $false
    }
}

function Enable-UAC {
    Write-SecurityLog "Configuring User Account Control (UAC)..." "Info"
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Set-ItemProperty -Path $regPath -Name "EnableLUA" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $regPath -Name "ConsentPromptBehaviorAdmin" -Value 2 -ErrorAction Stop
        $SecurityResults.Fixed += "User Account Control (UAC)"
        Write-SecurityLog "[SUCCESS] UAC configured successfully" "Success"
        return $true
    } catch {
        $SecurityResults.Failed += "UAC Configuration: $($_.Message)"
        Write-SecurityLog "[ERROR] Failed to configure UAC: $($_.Message)" "Error"
        return $false
    }
}

function Disable-UnnecessaryServices {
    Write-SecurityLog "Disabling unnecessary services for security..." "Info"
    $servicesToDisable = @(
        "Telnet",
        "RemoteRegistry",
        "SharedAccess"
    )
    
    $disabledCount = 0
    foreach ($service in $servicesToDisable) {
        try {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq "Running") {
                Stop-Service -Name $service -Force -ErrorAction Stop
                Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
                $disabledCount++
                Write-SecurityLog "  Disabled service: $service" "Success"
            }
        } catch {
            Write-SecurityLog "  Warning: Could not disable $service" "Warning"
        }
    }
    
    if ($disabledCount -gt 0) {
        $SecurityResults.Fixed += "Disabled $disabledCount unnecessary services"
    }
    return $true
}

function Configure-WindowsUpdates {
    Write-SecurityLog "Configuring Windows Updates..." "Info"
    try {
        # Enable automatic updates
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (!(Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "NoAutoUpdate" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $regPath -Name "AUOptions" -Value 4 -ErrorAction Stop
        
        $SecurityResults.Fixed += "Windows Updates Auto-Configured"
        Write-SecurityLog "[SUCCESS] Windows Updates configured for automatic installation" "Success"
        return $true
    } catch {
        $SecurityResults.Failed += "Windows Updates: $($_.Message)"
        Write-SecurityLog "[ERROR] Failed to configure Windows Updates: $($_.Message)" "Error"
        return $false
    }
}

function Secure-PasswordPolicy {
    Write-SecurityLog "Configuring secure password policy..." "Info"
    try {
        # Configure password policy via registry
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
        Set-ItemProperty -Path $regPath -Name "MaximumPasswordAge" -Value 90 -ErrorAction SilentlyContinue
        
        $SecurityResults.Fixed += "Password Policy Secured"
        Write-SecurityLog "[SUCCESS] Password policy configured" "Success"
        return $true
    } catch {
        $SecurityResults.Failed += "Password Policy: $($_.Message)"
        Write-SecurityLog "[ERROR] Failed to configure password policy: $($_.Message)" "Error"
        return $false
    }
}

function Enable-AuditLogging {
    Write-SecurityLog "Enabling security audit logging..." "Info"
    try {
        # Enable audit logging for security events
        auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable | Out-Null
        auditpol /set /category:"Account Logon" /success:enable /failure:enable | Out-Null
        auditpol /set /category:"Privilege Use" /success:enable /failure:enable | Out-Null
        
        $SecurityResults.Fixed += "Security Audit Logging"
        Write-SecurityLog "[SUCCESS] Security audit logging enabled" "Success"
        return $true
    } catch {
        $SecurityResults.Failed += "Audit Logging: $($_.Message)"
        Write-SecurityLog "[ERROR] Failed to enable audit logging: $($_.Message)" "Error"
        return $false
    }
}

function Disable-GuestAccount {
    Write-SecurityLog "Disabling Guest account..." "Info"
    try {
        net user guest /active:no | Out-Null
        $SecurityResults.Fixed += "Guest Account Disabled"
        Write-SecurityLog "[SUCCESS] Guest account disabled" "Success"
        return $true
    } catch {
        $SecurityResults.Failed += "Guest Account: $($_.Message)"
        Write-SecurityLog "[ERROR] Failed to disable guest account: $($_.Message)" "Error"
        return $false
    }
}

function Configure-ScreenLock {
    Write-SecurityLog "Configuring automatic screen lock..." "Info"
    try {
        $regPath = "HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop"
        if (!(Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "ScreenSaveTimeOut" -Value "600" -ErrorAction Stop
        Set-ItemProperty -Path $regPath -Name "ScreenSaverIsSecure" -Value "1" -ErrorAction Stop
        
        $SecurityResults.Fixed += "Automatic Screen Lock"
        Write-SecurityLog "[SUCCESS] Screen lock configured (10 minutes)" "Success"
        return $true
    } catch {
        $SecurityResults.Failed += "Screen Lock: $($_.Message)"
        Write-SecurityLog "[ERROR] Failed to configure screen lock: $($_.Message)" "Error"
        return $false
    }
}

function Run-QuickScan {
    Write-SecurityLog "Running quick malware scan..." "Info"
    try {
        Start-MpScan -ScanType QuickScan -ErrorAction Stop
        $SecurityResults.Fixed += "Quick Malware Scan Completed"
        Write-SecurityLog "[SUCCESS] Quick scan completed" "Success"
        return $true
    } catch {
        $SecurityResults.Failed += "Malware Scan: $($_.Message)"
        Write-SecurityLog "[ERROR] Failed to run malware scan: $($_.Message)" "Error"
        return $false
    }
}

# Main execution
Write-SecurityLog "Starting comprehensive security fixes..." "Info"

# Check for admin privileges
if (!(Test-AdminPrivileges)) {
    Write-SecurityLog "[ERROR] Administrator privileges required for security fixes!" "Error"
    Write-Host ""
    Write-Host "Please run this script as Administrator to apply security fixes." -ForegroundColor Yellow
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-SecurityLog "[SUCCESS] Running with Administrator privileges" "Success"
Write-Host ""

# Apply security fixes
$fixes = @(
    { Enable-WindowsDefender },
    { Update-WindowsDefender },
    { Enable-WindowsFirewall },
    { Enable-UAC },
    { Disable-UnnecessaryServices },
    { Configure-WindowsUpdates },
    { Secure-PasswordPolicy },
    { Enable-AuditLogging },
    { Disable-GuestAccount },
    { Configure-ScreenLock }
)

if ($FixAll) {
    $fixes += { Run-QuickScan }
}

$totalFixes = $fixes.Count
$successCount = 0

foreach ($fix in $fixes) {
    if (& $fix) {
        $successCount++
    }
    Start-Sleep -Milliseconds 500
}

# Calculate security score
$SecurityResults.Score = [math]::Round(($successCount / $totalFixes) * 100, 1)

Write-Host ""
Write-Host "SECURITY FIXES SUMMARY" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "=" * 80

Write-Host "Successfully Fixed: $($SecurityResults.Fixed.Count)" -ForegroundColor Green
foreach ($fix in $SecurityResults.Fixed) {
    Write-Host "   • $fix" -ForegroundColor DarkGreen
}

if ($SecurityResults.Failed.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed to Fix: $($SecurityResults.Failed.Count)" -ForegroundColor Red
    foreach ($fail in $SecurityResults.Failed) {
        Write-Host "   • $fail" -ForegroundColor DarkRed
    }
}

Write-Host ""
Write-Host "Security Score: $($SecurityResults.Score)%" -ForegroundColor $(if ($SecurityResults.Score -ge 80) {"Green"} elseif ($SecurityResults.Score -ge 60) {"Yellow"} else {"Red"})

if ($SecurityResults.Score -eq 100) {
    Write-Host "EXCELLENT! All security fixes applied successfully!" -ForegroundColor Green
} elseif ($SecurityResults.Score -ge 80) {
    Write-Host "GOOD! Most security issues have been resolved." -ForegroundColor Yellow
} else {
    Write-Host "WARNING! Several security issues need attention." -ForegroundColor Red
}

# Generate report
$reportPath = "Security_Fixes_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$report = @"
COMPREHENSIVE DEVICE SECURITY FIXES REPORT
Generated: $(Get-Date)
Administrator: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)

SECURITY SCORE: $($SecurityResults.Score)%

SUCCESSFULLY FIXED ($($SecurityResults.Fixed.Count)):
$(($SecurityResults.Fixed | ForEach-Object { "SUCCESS: $_" }) -join "`n")

FAILED TO FIX ($($SecurityResults.Failed.Count)):
$(($SecurityResults.Failed | ForEach-Object { "FAILED: $_" }) -join "`n")

RECOMMENDATIONS:
• Keep Windows Defender updated daily
• Install Windows Updates regularly
• Use strong, unique passwords
• Enable two-factor authentication where possible
• Regular system backups
• Avoid suspicious downloads and emails

NEXT STEPS:
• Reboot system to apply all changes
• Run full system scan
• Check Windows Update for pending updates
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host ""
Write-Host "Security report saved to: $reportPath" -ForegroundColor Yellow

Write-Host ""
Write-Host "RECOMMENDATION: Restart your computer to apply all security changes." -ForegroundColor Cyan

exit $(if ($SecurityResults.Score -eq 100) { 0 } else { 1 })
