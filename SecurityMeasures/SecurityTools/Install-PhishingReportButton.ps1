# Install-PhishingReportButton.ps1
# Purpose: Install Phishing Report Button for Microsoft Outlook
# Author: GitHub Copilot
# Date: September 10, 2025

param (
    [Parameter(Mandatory=$false)]
    [string]$DownloadPath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\Downloads",
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateDeploymentPackage,
    
    [Parameter(Mandatory=$false)]
    [string]$DeploymentPath = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\Deployment\PhishingButton"
)

# Initialize
$ErrorActionPreference = "Stop"
$LogFile = "C:\Users\Lwandile Gasela\iBridge\SecurityMeasures\SecurityTools\Logs\PhishingButtonInstall_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

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

# Create directories if they don't exist
if (!(Test-Path -Path $DownloadPath)) {
    New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
}

if (!(Test-Path -Path (Split-Path -Path $LogFile -Parent))) {
    New-Item -Path (Split-Path -Path $LogFile -Parent) -ItemType Directory -Force | Out-Null
}

if ($CreateDeploymentPackage -and !(Test-Path -Path $DeploymentPath)) {
    New-Item -Path $DeploymentPath -ItemType Directory -Force | Out-Null
}

Write-Log "Starting installation of Phishing Report Button for Outlook..." -Level Info

# Check if Outlook is installed
$outlookInstalled = $false
try {
    $outlookPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE" -ErrorAction SilentlyContinue)."(default)"
    if ($outlookPath -and (Test-Path -Path $outlookPath)) {
        $outlookInstalled = $true
        Write-Log "Microsoft Outlook found at: $outlookPath" -Level Success
    } else {
        Write-Log "Microsoft Outlook not found through registry" -Level Warning
        
        # Try common installation paths
        $commonPaths = @(
            "${env:ProgramFiles}\Microsoft Office\root\Office16\OUTLOOK.EXE",
            "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\OUTLOOK.EXE",
            "${env:ProgramFiles}\Microsoft Office\Office16\OUTLOOK.EXE",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OUTLOOK.EXE",
            "${env:ProgramFiles}\Microsoft Office\Office15\OUTLOOK.EXE",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office15\OUTLOOK.EXE"
        )
        
        foreach ($path in $commonPaths) {
            if (Test-Path -Path $path) {
                $outlookInstalled = $true
                $outlookPath = $path
                Write-Log "Microsoft Outlook found at: $outlookPath" -Level Success
                break
            }
        }
    }
    
    if (!$outlookInstalled) {
        Write-Log "Microsoft Outlook not found. Please install Outlook before continuing." -Level Error
        exit 1
    }
} catch {
    Write-Log "Error checking for Outlook: $_" -Level Error
    exit 1
}

# Options for Phishing Report Button
$phishingButtonOptions = @(
    @{
        Name = "Microsoft Report Message Add-in"
        DownloadUrl = "https://www.microsoft.com/en-us/download/details.aspx?id=102708"
        InstallerUrl = "https://aka.ms/ReportMessage"
        Description = "Microsoft's official Report Message add-in for Outlook"
        MicrosoftApproved = $true
    },
    @{
        Name = "KnowBe4 Phish Alert Button"
        DownloadUrl = "https://www.knowbe4.com/phish-alert"
        InstallerUrl = "https://www.knowbe4.com/hubfs/phishalertoutlook.exe"
        Description = "KnowBe4's Phish Alert Button for Outlook"
        MicrosoftApproved = $false
    }
)

# Select phishing button option
Write-Log "Available phishing reporting add-ins:" -Level Info
for ($i = 0; $i -lt $phishingButtonOptions.Count; $i++) {
    Write-Log "[$i] $($phishingButtonOptions[$i].Name) - $($phishingButtonOptions[$i].Description)" -Level Info
}

$selection = 0  # Default to Microsoft's option
$selectedOption = $phishingButtonOptions[$selection]

Write-Log "Selected: $($selectedOption.Name)" -Level Success

# Download the installer
$installerFilename = if ($selectedOption.Name -eq "Microsoft Report Message Add-in") {
    "ReportMessage.click-to-run"
} else {
    "PhishAlertButton.exe"
}

$installerPath = Join-Path -Path $DownloadPath -ChildPath $installerFilename

try {
    Write-Log "Downloading $($selectedOption.Name) from $($selectedOption.InstallerUrl)..." -Level Info
    Invoke-WebRequest -Uri $selectedOption.InstallerUrl -OutFile $installerPath -UseBasicParsing
    
    if (Test-Path -Path $installerPath) {
        Write-Log "Download completed successfully: $installerPath" -Level Success
    } else {
        Write-Log "Failed to download installer" -Level Error
        exit 1
    }
} catch {
    Write-Log "Error downloading installer: $_" -Level Error
    exit 1
}

# Install the add-in
try {
    Write-Log "Installing $($selectedOption.Name)..." -Level Info
    
    if ($selectedOption.Name -eq "Microsoft Report Message Add-in") {
        # Microsoft's add-in uses click-to-run which should just execute
        Start-Process -FilePath $installerPath -Wait
        Write-Log "Installation initiated. Please follow the on-screen instructions to complete installation." -Level Success
    } else {
        # KnowBe4 uses an EXE installer
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
        Write-Log "Installation completed" -Level Success
    }
} catch {
    Write-Log "Error during installation: $_" -Level Error
    exit 1
}

# Create deployment package if requested
if ($CreateDeploymentPackage) {
    Write-Log "Creating deployment package..." -Level Info
    
    try {
        # Create the deployment directory
        if (!(Test-Path -Path $DeploymentPath)) {
            New-Item -Path $DeploymentPath -ItemType Directory -Force | Out-Null
        }
        
        # Copy the installer
        Copy-Item -Path $installerPath -Destination $DeploymentPath -Force
        
        # Create deployment script
        $deploymentScriptPath = Join-Path -Path $DeploymentPath -ChildPath "Install-PhishingReportButton.bat"
        $deploymentScript = @"
@echo off
echo ===================================================
echo      Phishing Report Button Installation
echo ===================================================
echo.
echo Installing $($selectedOption.Name)...
echo.

"@

        if ($selectedOption.Name -eq "Microsoft Report Message Add-in") {
            $deploymentScript += @"
echo This will open Microsoft's Report Message installer.
echo Please follow the on-screen instructions to complete installation.
echo.
start "" "$installerFilename"
"@
        } else {
            $deploymentScript += @"
echo Installing KnowBe4 Phish Alert Button silently...
start /wait "" "$installerFilename" /S
echo Installation complete.
"@
        }
        
        $deploymentScript += @"

echo.
echo ===================================================
echo      Installation Complete
echo ===================================================
echo.
echo Please restart Outlook to complete the setup.
echo.
pause
"@
        
        $deploymentScript | Out-File -FilePath $deploymentScriptPath -Encoding ASCII
        
        # Create README file
        $readmePath = Join-Path -Path $DeploymentPath -ChildPath "README.txt"
        $readmeContent = @"
===================================================
     Phishing Report Button Deployment Package
===================================================

This package contains the $($selectedOption.Name) for Microsoft Outlook.

HOW TO USE:
1. Run "Install-PhishingReportButton.bat" as administrator
2. Follow the on-screen instructions
3. Restart Outlook after installation

WHAT IT DOES:
The phishing report button adds a toolbar icon to Outlook that allows users to easily report suspicious emails to the security team for investigation.

TRAINING RESOURCES:
1. Show users how to identify suspicious emails (unexpected attachments, unusual requests, etc.)
2. Demonstrate how to use the report button when they receive a suspicious email
3. Emphasize the importance of reporting rather than interacting with suspicious content

For more information:
$($selectedOption.DownloadUrl)

===================================================
"@
        $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
        
        Write-Log "Deployment package created at: $DeploymentPath" -Level Success
    } catch {
        Write-Log "Error creating deployment package: $_" -Level Error
    }
}

# Instructions for users
Write-Log "`n====================================================" -Level Info
Write-Log "NEXT STEPS" -Level Info
Write-Log "====================================================" -Level Info
Write-Log "1. Restart Outlook to activate the phishing report button" -Level Info
Write-Log "2. Train users on how to identify and report suspicious emails" -Level Info
Write-Log "3. Create a process for handling reported phishing emails" -Level Info
Write-Log "4. Consider enabling email authentication (SPF, DKIM, DMARC)" -Level Info
Write-Log "`nInstallation log saved to: $LogFile" -Level Success

# Finished
Write-Log "Installation process completed" -Level Success
