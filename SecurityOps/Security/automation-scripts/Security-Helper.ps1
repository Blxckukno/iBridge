<#
.SYNOPSIS
    Security Setup Helper - Run security scripts with administrator privileges
    
.DESCRIPTION
    This helper script checks for administrator privileges and launches security scripts
    with elevated permissions if needed.
    
.PARAMETER Action
    The security action to perform: Harden, Configure, Monitor, or All
    
.EXAMPLE
    .\Security-Helper.ps1 -Action All
    
.NOTES
    Author: Security Team
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Harden", "Configure", "Monitor", "All")]
    [string]$Action = "All"
)

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Start-ElevatedScript {
    param([string]$ScriptPath, [string]$Arguments = "")
    
    Write-Host "Starting elevated script: $ScriptPath" -ForegroundColor Yellow
    
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "powershell.exe"
    $startInfo.Arguments = "-ExecutionPolicy Bypass -File `"$ScriptPath`" $Arguments"
    $startInfo.Verb = "runas"
    $startInfo.UseShellExecute = $true
    $startInfo.WindowStyle = "Normal"
    
    try {
        $process = [System.Diagnostics.Process]::Start($startInfo)
        $process.WaitForExit()
        return $process.ExitCode
    } catch {
        Write-Host "Failed to start elevated process: $($_.Exception.Message)" -ForegroundColor Red
        return 1
    }
}

function Run-SecurityHardening {
    Write-Host "`n=== SYSTEM HARDENING ===" -ForegroundColor Cyan
    Write-Host "This will harden your Windows system with security best practices." -ForegroundColor White
    
    $scriptPath = Join-Path $PSScriptRoot "Harden-WindowsSystem.ps1"
    
    if (Test-IsAdmin) {
        & $scriptPath -Level High -BackupConfig
    } else {
        Start-ElevatedScript -ScriptPath $scriptPath -Arguments "-Level High -BackupConfig"
    }
}

function Run-DefenderConfiguration {
    Write-Host "`n=== WINDOWS DEFENDER CONFIGURATION ===" -ForegroundColor Cyan
    Write-Host "This will configure Windows Defender with maximum protection settings." -ForegroundColor White
    
    $scriptPath = Join-Path $PSScriptRoot "Configure-WindowsDefender.ps1"
    
    if (Test-IsAdmin) {
        & $scriptPath -MaxProtection
    } else {
        Start-ElevatedScript -ScriptPath $scriptPath -Arguments "-MaxProtection"
    }
}

function Run-SecurityMonitoring {
    Write-Host "`n=== SECURITY MONITORING ===" -ForegroundColor Cyan
    Write-Host "This will start security event monitoring (24 hours lookback)." -ForegroundColor White
    
    $scriptPath = Join-Path $PSScriptRoot "Monitor-SecurityEvents.ps1"
    
    if (Test-IsAdmin) {
        & $scriptPath -Hours 24 -AlertThreshold 3
    } else {
        Start-ElevatedScript -ScriptPath $scriptPath -Arguments "-Hours 24 -AlertThreshold 3"
    }
}

# Main execution
Write-Host "=== CYBERSECURITY SETUP HELPER ===" -ForegroundColor Green
Write-Host "This script will help you secure your system using free, legitimate tools." -ForegroundColor White

# Check current privileges
if (Test-IsAdmin) {
    Write-Host "✓ Running with Administrator privileges" -ForegroundColor Green
} else {
    Write-Host "⚠ Some scripts require Administrator privileges and will prompt for elevation" -ForegroundColor Yellow
}

switch ($Action) {
    "Harden" {
        Run-SecurityHardening
    }
    "Configure" {
        Run-DefenderConfiguration
    }
    "Monitor" {
        Run-SecurityMonitoring
    }
    "All" {
        Write-Host "`nRunning complete security setup..." -ForegroundColor Cyan
        
        $continue = Read-Host "`nDo you want to proceed with complete security hardening? (Y/N)"
        if ($continue -eq "Y" -or $continue -eq "y") {
            Run-SecurityHardening
            Start-Sleep -Seconds 3
            Run-DefenderConfiguration
            Start-Sleep -Seconds 3
            Run-SecurityMonitoring
        } else {
            Write-Host "Security setup cancelled by user." -ForegroundColor Yellow
        }
    }
}

Write-Host "`n=== SETUP COMPLETE ===" -ForegroundColor Green
Write-Host "Your system security has been enhanced with free, legitimate tools." -ForegroundColor White
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Reboot your system to apply all changes" -ForegroundColor White
Write-Host "2. Review the security reports in C:\SecurityReports\" -ForegroundColor White
Write-Host "3. Install additional free security tools from the malware-protection guide" -ForegroundColor White
Write-Host "4. Configure your browser with privacy extensions from the privacy-tools guide" -ForegroundColor White

Read-Host "Press Enter to continue..."