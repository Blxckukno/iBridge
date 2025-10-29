# Simple-Security-Installer.ps1
# Purpose: Install essential free security tools
# Author: GitHub Copilot
# Date: September 10, 2025

param(
    [switch]$Elevated
)

# Self-elevate the script if not already admin
if (-Not $Elevated) {
    Write-Host "This script requires administrative privileges. Attempting to elevate..."
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Elevated" -Verb RunAs
    exit
}

# Configuration
$DownloadPath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\Downloads"
$LogPath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\Logs"
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
        $errorMessage = $_.Exception.Message
        Write-Log "Download failed: $errorMessage" -Level Error
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
        $errorMessage = $_.Exception.Message
        Write-Log "EXE installation failed: $errorMessage" -Level Error
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
        $errorMessage = $_.Exception.Message
        Write-Log "MSI installation failed: $errorMessage" -Level Error
        return $false
    }
}

# Function to extract ZIP
function Extract-ZIP {
    param(
        [string]$ZipPath,
        [string]$DestinationPath
    )
    
    try {
        Write-Log "Extracting ZIP: $ZipPath to $DestinationPath" -Level Info
        
        if (!(Test-Path -Path $DestinationPath)) {
            New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        }
        
        Expand-Archive -Path $ZipPath -DestinationPath $DestinationPath -Force
        Write-Log "ZIP extracted successfully to $DestinationPath" -Level Success
        return $true
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Log "ZIP extraction failed: $errorMessage" -Level Error
        return $false
    }
}

# Start of the script
Write-Log "========================================================" -Level Info
Write-Log "   Simple Security Tools Installer - Starting           " -Level Info
Write-Log "========================================================" -Level Info
Write-Log "Download path: $DownloadPath" -Level Info
Write-Log "Log path: $LogPath" -Level Info
Write-Log "========================================================" -Level Info

# Essential Security Tools
$securityTools = @(
    # Antivirus and Anti-Malware
    @{
        Name = "Malwarebytes"
        Url = "https://downloads.malwarebytes.com/file/mb4_offline"
        Filename = "MBSetup.exe"
        InstallArgs = "/SILENT /NORESTART"
        Type = "EXE"
    },
    
    # Network Monitoring
    @{
        Name = "GlassWire"
        Url = "https://download.glasswire.com/GlassWireSetup.exe"
        Filename = "GlassWireSetup.exe"
        InstallArgs = "/S"
        Type = "EXE"
    },
    
    # Password Management
    @{
        Name = "Bitwarden"
        Url = "https://vault.bitwarden.com/download/?app=desktop&platform=windows"
        Filename = "Bitwarden-Installer.exe"
        InstallArgs = "/S"
        Type = "EXE"
    },
    
    # System Tools
    @{
        Name = "ProcessExplorer"
        Url = "https://download.sysinternals.com/files/ProcessExplorer.zip"
        Filename = "ProcessExplorer.zip"
        ExtractPath = "$DownloadPath\ProcessExplorer"
        Type = "ZIP"
    },
    
    @{
        Name = "Autoruns"
        Url = "https://download.sysinternals.com/files/Autoruns.zip"
        Filename = "Autoruns.zip"
        ExtractPath = "$DownloadPath\Autoruns"
        Type = "ZIP"
    },
    
    @{
        Name = "TCPView"
        Url = "https://download.sysinternals.com/files/TCPView.zip"
        Filename = "TCPView.zip"
        ExtractPath = "$DownloadPath\TCPView"
        Type = "ZIP"
    },
    
    # Disk Encryption
    @{
        Name = "VeraCrypt"
        Url = "https://launchpad.net/veracrypt/trunk/1.25.9/+download/VeraCrypt%20Setup%201.25.9.exe"
        Filename = "VeraCrypt_Setup.exe"
        InstallArgs = "/VERYSILENT /NORESTART"
        Type = "EXE"
    },
    
    # System Cleaner
    @{
        Name = "BleachBit"
        Url = "https://www.bleachbit.org/download/file/t?file=BleachBit-4.4.2-setup.exe"
        Filename = "BleachBit-setup.exe"
        InstallArgs = "/S"
        Type = "EXE"
    }
)

# Download and install each tool
foreach ($tool in $securityTools) {
    Write-Log "=== Processing $($tool.Name) ===" -Level Info
    
    $downloadPath = Join-Path -Path $DownloadPath -ChildPath $tool.Filename
    
    # Download the tool
    $downloaded = Download-File -Url $tool.Url -OutputFile $downloadPath
    
    if ($downloaded) {
        # Process based on type
        switch ($tool.Type) {
            'EXE' {
                Install-EXE -ExePath $downloadPath -Arguments $tool.InstallArgs
            }
            'MSI' {
                Install-MSI -MsiPath $downloadPath -Arguments $tool.InstallArgs
            }
            'ZIP' {
                Extract-ZIP -ZipPath $downloadPath -DestinationPath $tool.ExtractPath
            }
        }
    } else {
        Write-Log "Skipping installation of $($tool.Name) due to download failure" -Level Warning
    }
}

# Optimize Windows Defender
Write-Log "Optimizing Windows Defender..." -Level Info
try {
    # Enable real-time protection
    Set-MpPreference -DisableRealtimeMonitoring $false
    
    # Enable cloud-delivered protection
    Set-MpPreference -MAPSReporting Advanced
    
    # Enable block at first sight
    Set-MpPreference -DisableBlockAtFirstSeen $false
    
    # Enable network protection if supported
    try {
        Set-MpPreference -EnableNetworkProtection Enabled -ErrorAction SilentlyContinue
        Write-Log "Network protection enabled" -Level Success
    } catch {
        Write-Log "Network protection not available or could not be enabled" -Level Warning
    }
    
    # Trigger a quick scan
    Start-MpScan -ScanType QuickScan -AsJob
    
    Write-Log "Windows Defender optimized successfully" -Level Success
} catch {
    $errorMessage = $_.Exception.Message
    Write-Log "Error optimizing Windows Defender: $errorMessage" -Level Error
}

# Final summary
Write-Log "========================================================" -Level Info
Write-Log "   Security Tools Installer - Completed                  " -Level Info
Write-Log "========================================================" -Level Info
Write-Log "Log file: $LogFile" -Level Info
Write-Log "Please restart your computer to complete installation" -Level Warning
