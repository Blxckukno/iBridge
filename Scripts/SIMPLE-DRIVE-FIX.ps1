# iBridge Drive Detection Fix - Simple Version
# Fixes the drive detection issue in enhanced setup

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

Write-ColorOutput "iBridge Auto-Drive Detection Fix" "Cyan"
Write-ColorOutput "Finding application files and fixing drive paths" "Yellow"
Write-ColorOutput ""

# Define the required applications
$requiredApps = @(
    "TeamViewer_Setup_x64.exe",
    "24.2.2000.exe", 
    "GlassWireSetup.exe",
    "PBIDesktopSetup_x64.exe"
)

# Search for files across all drives
Write-ColorOutput "Step 1: Scanning drives for application files..." "Green"

$foundDrive = $null
$foundFiles = @{}

$drives = @('C:', 'D:', 'E:', 'F:', 'G:', 'H:')
foreach ($drive in $drives) {
    if (Test-Path $drive) {
        Write-ColorOutput "  Checking $drive..." "Gray"
        
        $foundCount = 0
        foreach ($app in $requiredApps) {
            $searchPath = Get-ChildItem -Path "$drive\" -Name $app -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($searchPath) {
                $fullPath = Join-Path $drive $searchPath
                $foundFiles[$app] = $fullPath
                $foundCount++
                Write-ColorOutput "    Found: $app at $fullPath" "Green"
            }
        }
        
        if ($foundCount -ge 3) {
            $foundDrive = $drive
            Write-ColorOutput "  Primary drive detected: $drive ($foundCount files found)" "Green"
            break
        }
    }
}

if (!$foundDrive) {
    Write-ColorOutput "ERROR: Could not find application files on any drive" "Red"
    Write-ColorOutput "Please ensure the following files are accessible:" "Yellow"
    foreach ($app in $requiredApps) {
        Write-ColorOutput "  - $app" "Gray"
    }
    Read-Host "Press Enter to exit"
    exit 1
}

# Create the setup directory
$setupDir = "C:\iBridge_Setup"
if (!(Test-Path $setupDir)) {
    New-Item -ItemType Directory -Path $setupDir -Force | Out-Null
    Write-ColorOutput "Created directory: $setupDir" "Green"
}

# Create a simple batch launcher that uses the correct paths
Write-ColorOutput "Step 2: Creating corrected batch launcher..." "Green"

$batchContent = @"
@echo off
title iBridge Enhanced Setup - FIXED VERSION
echo ================================================================
echo iBridge Enhanced Setup - FIXED VERSION (Auto Drive Detection)
echo ================================================================
echo.
echo This FIXED version will automatically detect drive locations
echo Applications found on: $foundDrive
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Starting setup with correct drive detection...
echo.

REM Define variables for found files
set "TEAMVIEWER_PATH=$($foundFiles['TeamViewer_Setup_x64.exe'])"
set "APP24_PATH=$($foundFiles['24.2.2000.exe'])"
set "GLASSWIRE_PATH=$($foundFiles['GlassWireSetup.exe'])"
set "POWERBI_PATH=$($foundFiles['PBIDesktopSetup_x64.exe'])"

echo Installing applications from correct locations:
echo   TeamViewer: %TEAMVIEWER_PATH%
echo   24.2.2000: %APP24_PATH%
echo   GlassWire: %GLASSWIRE_PATH%
echo   Power BI: %POWERBI_PATH%
echo.

REM Create user accounts
echo Creating user accounts...
net user "Admin" "IBr1dG3Pc" /add /comment:"Admin for app installation" /expires:never
net user "iBridge User" "Abc654321!" /add /comment:"Standard user with limited privileges" /expires:never
net localgroup administrators "Admin" /add
net localgroup users "iBridge User" /add

REM Install applications with found paths
echo.
echo Installing TeamViewer...
if exist "%TEAMVIEWER_PATH%" (
    "%TEAMVIEWER_PATH%" /S
    echo TeamViewer installation started
) else (
    echo WARNING: TeamViewer not found at %TEAMVIEWER_PATH%
)

echo.
echo Installing 24.2.2000...
if exist "%APP24_PATH%" (
    "%APP24_PATH%" /SILENT
    echo 24.2.2000 installation started
) else (
    echo WARNING: 24.2.2000 not found at %APP24_PATH%
)

echo.
echo Installing GlassWire...
if exist "%GLASSWIRE_PATH%" (
    "%GLASSWIRE_PATH%" /S
    echo GlassWire installation started
) else (
    echo WARNING: GlassWire not found at %GLASSWIRE_PATH%
)

echo.
echo Installing Power BI Desktop...
if exist "%POWERBI_PATH%" (
    "%POWERBI_PATH%" /quiet
    echo Power BI Desktop installation started
) else (
    echo WARNING: Power BI Desktop not found at %POWERBI_PATH%
)

echo.
echo ================================================================
echo SETUP COMPLETED!
echo ================================================================
echo.
echo User Accounts Created:
echo   Admin (Password: IBr1dG3Pc)
echo   iBridge User (Password: Abc654321!)
echo.
echo Applications installed from: $foundDrive
echo.
echo NEXT STEPS:
echo 1. Log out of current Windows session
echo 2. Log in as 'iBridge User' (Password: Abc654321!)
echo 3. Applications should be installed and ready to use
echo.
pause
"@

$batchPath = "$setupDir\RUN-ENHANCED-SETUP-FIXED.bat"
$batchContent | Out-File $batchPath -Encoding ASCII
Write-ColorOutput "Created fixed batch launcher: $batchPath" "Green"

# Create desktop shortcut for easy access
Write-ColorOutput "Step 3: Creating desktop shortcut..." "Green"

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = "$desktopPath\iBridge Setup FIXED.lnk"

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $batchPath
$Shortcut.WorkingDirectory = $setupDir
$Shortcut.Description = "iBridge Enhanced Setup - Fixed Version"
$Shortcut.Save()

Write-ColorOutput "Created desktop shortcut: $shortcutPath" "Green"

# Summary
Write-ColorOutput ""
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "DRIVE DETECTION FIX COMPLETED!" "Green"
Write-ColorOutput "========================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "PROBLEM IDENTIFIED:" "Yellow"
Write-ColorOutput "  Original scripts were looking for files on D: drive" "Red"
Write-ColorOutput "  Files actually located on: $foundDrive" "Green"
Write-ColorOutput ""
Write-ColorOutput "SOLUTION CREATED:" "Green"
Write-ColorOutput "  Fixed batch file: $batchPath" "Cyan"
Write-ColorOutput "  Desktop shortcut: $shortcutPath" "Cyan"
Write-ColorOutput ""
Write-ColorOutput "FILES FOUND AND MAPPED:" "White"
foreach ($app in $requiredApps) {
    if ($foundFiles[$app]) {
        Write-ColorOutput "  $app -> $($foundFiles[$app])" "Gray"
    } else {
        Write-ColorOutput "  $app -> NOT FOUND" "Red"
    }
}
Write-ColorOutput ""
Write-ColorOutput "TO RUN THE FIXED SETUP:" "Cyan"
Write-ColorOutput "  Option 1: Double-click desktop shortcut 'iBridge Setup FIXED'" "Green"
Write-ColorOutput "  Option 2: Run: $batchPath" "Green"
Write-ColorOutput ""
Write-ColorOutput "This will now correctly install all applications from $foundDrive!" "Green"

Read-Host "Press Enter to finish"
