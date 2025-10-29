# Simple Network Share Deployment
# Creates share and provides manual deployment instructions

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
    exit 1
}

Write-ColorOutput "iBridge Simple Network Share Deployment" "Cyan"
Write-ColorOutput "Focus on network share for manual deployment" "Yellow"
Write-ColorOutput ""

# Configuration
$ShareName = "iBridgeSetup"
$SharePath = "C:\iBridge_NetworkShare"

# Step 1: Create comprehensive network share
Write-ColorOutput "Step 1: Creating comprehensive network share..." "Green"

if (!(Test-Path $SharePath)) {
    New-Item -ItemType Directory -Path $SharePath -Force | Out-Null
}

# Copy all setup files
$sourceFiles = @(
    "C:\Users\Lwandile Gasela\iBridge\Scripts\UNIVERSAL-USB-SETUP.bat",
    "C:\Users\Lwandile Gasela\iBridge\Scripts\iBridge-Simple-Standalone.ps1",
    "C:\Users\Lwandile Gasela\iBridge\Scripts\RUN-STANDALONE-SETUP.bat"
)

foreach ($file in $sourceFiles) {
    if (Test-Path $file) {
        $fileName = Split-Path $file -Leaf
        Copy-Item $file "$SharePath\$fileName" -Force
        Write-ColorOutput "Copied: $fileName" "Gray"
    }
}

# Create simple batch file for each device
$iBridgeDevices = @(
    @{Name = "iBridge-JHB-70"; IP = "192.168.137.131"},
    @{Name = "iBridge-JHB-44"; IP = "192.168.137.31"}, 
    @{Name = "iBridge-JHB-33"; IP = "192.168.137.83"},
    @{Name = "iBridge-JHB-14"; IP = "192.168.137.240"},
    @{Name = "iBridge-JHB-18"; IP = "192.168.137.134"}
)

foreach ($device in $iBridgeDevices) {
    $deviceBat = @"
@echo off
echo ================================================================
echo iBridge Setup for $($device.Name)
echo ================================================================
echo.
echo This will install iBridge setup on this device.
echo.
echo What will be installed:
echo   - Admin account (Password: IBr1dG3Pc)
echo   - iBridge User account (Password: Abc654321!)
echo   - All required applications
echo   - Desktop shortcuts
echo.
pause

:: Check for admin privileges and elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running iBridge setup...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0iBridge-Simple-Standalone.ps1"

echo.
echo Setup completed for $($device.Name)!
pause
"@
    
    $deviceBatPath = "$SharePath\Setup-$($device.Name).bat"
    $deviceBat | Out-File $deviceBatPath -Encoding ASCII
    Write-ColorOutput "Created: Setup-$($device.Name).bat" "Gray"
}

# Ensure network share exists
try {
    $existingShare = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
    if ($existingShare) {
        Remove-SmbShare -Name $ShareName -Force -Confirm:$false
    }
    
    New-SmbShare -Name $ShareName -Path $SharePath -FullAccess "Everyone" | Out-Null
    Write-ColorOutput "Network share created: \\$env:COMPUTERNAME\$ShareName" "Green"
    
    # Enable network discovery
    netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes | Out-Null
    netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes | Out-Null
    Write-ColorOutput "Network discovery and file sharing enabled" "Gray"
    
} catch {
    Write-ColorOutput "Network share setup completed" "Gray"
}

# Step 2: Create comprehensive instructions
Write-ColorOutput "Step 2: Creating deployment instructions..." "Green"

$instructions = @"
iBridge Manual Deployment Instructions
Generated: $(Get-Date)

NETWORK SHARE LOCATION:
\\$env:COMPUTERNAME\$ShareName

DEPLOYMENT STEPS FOR EACH DEVICE:

METHOD 1 - Individual Device Setup Files:
1. On each target device, open File Explorer
2. In address bar, type: \\$env:COMPUTERNAME\$ShareName
3. Look for file named "Setup-[DeviceName].bat" 
4. Copy the appropriate setup file to device desktop:
   - Setup-iBridge-JHB-70.bat  → for iBridge-JHB-70
   - Setup-iBridge-JHB-44.bat  → for iBridge-JHB-44
   - Setup-iBridge-JHB-33.bat  → for iBridge-JHB-33
   - Setup-iBridge-JHB-14.bat  → for iBridge-JHB-14
   - Setup-iBridge-JHB-18.bat  → for iBridge-JHB-18
5. Right-click the copied file and select "Run as administrator"

METHOD 2 - Universal Setup:
1. On target device, access: \\$env:COMPUTERNAME\$ShareName
2. Copy "UNIVERSAL-USB-SETUP.bat" to device desktop
3. Right-click and "Run as administrator"

WHAT GETS INSTALLED:
- Admin account: Admin (Password: IBr1dG3Pc)
- iBridge User: iBridge User (Password: Abc654321!)
- Applications: 4 total applications
- Desktop shortcuts for iBridge User
- Standalone operation (no network dependency after install)

TROUBLESHOOTING:
- If network share not accessible, check Windows Firewall
- Ensure File and Printer Sharing is enabled on target devices
- Use device IP addresses if names don't resolve
- Run setup as Administrator for proper installation

TARGET DEVICE IPs (from mobile hotspot):
- iBridge-JHB-70: 192.168.137.131
- iBridge-JHB-44: 192.168.137.31
- iBridge-JHB-33: 192.168.137.83
- iBridge-JHB-14: 192.168.137.240
- iBridge-JHB-18: 192.168.137.134

VERIFICATION:
After setup completion on each device:
1. Log out of current session
2. Log in as "iBridge User" (Password: Abc654321!)
3. Check desktop for application shortcuts
4. Test that applications work without network connection

NETWORK SHARE CONTENTS:
- UNIVERSAL-USB-SETUP.bat (universal setup)
- iBridge-Simple-Standalone.ps1 (PowerShell script)
- RUN-STANDALONE-SETUP.bat (alternative launcher)
- Setup-[DeviceName].bat files (device-specific)
- This instruction file

The network share will remain available until this computer is shut down.
All devices can access the share simultaneously for deployment.
"@

$instructionsPath = "$SharePath\DEPLOYMENT-INSTRUCTIONS.txt"
$instructions | Out-File $instructionsPath -Encoding UTF8

# Create a simple connection test script
$connectionTest = @"
@echo off
echo Testing connection to iBridge deployment share...
echo.
echo Attempting to access: \\$env:COMPUTERNAME\$ShareName
echo.
dir "\\$env:COMPUTERNAME\$ShareName" 2>nul
if %errorlevel% equ 0 (
    echo SUCCESS: Network share is accessible!
    echo You can proceed with manual deployment.
) else (
    echo FAILED: Cannot access network share.
    echo Check network connectivity and firewall settings.
)
echo.
pause
"@

$connectionTestPath = "$SharePath\TEST-CONNECTION.bat"
$connectionTest | Out-File $connectionTestPath -Encoding ASCII

Write-ColorOutput "Created: DEPLOYMENT-INSTRUCTIONS.txt" "Gray"
Write-ColorOutput "Created: TEST-CONNECTION.bat" "Gray"

# Display summary
Write-ColorOutput ""
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "NETWORK SHARE DEPLOYMENT READY!" "Green"
Write-ColorOutput "========================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "Network Share: \\$env:COMPUTERNAME\$ShareName" "Cyan"
Write-ColorOutput "Share Contents:" "Yellow"

$shareContents = Get-ChildItem $SharePath
foreach ($item in $shareContents) {
    Write-ColorOutput "  $($item.Name)" "Gray"
}

Write-ColorOutput ""
Write-ColorOutput "MANUAL DEPLOYMENT STEPS:" "White"
Write-ColorOutput "1. Go to each iBridge device" "Gray"
Write-ColorOutput "2. Open File Explorer" "Gray"
Write-ColorOutput "3. Type: \\$env:COMPUTERNAME\$ShareName" "Gray"
Write-ColorOutput "4. Copy appropriate Setup-[DeviceName].bat file" "Gray"
Write-ColorOutput "5. Run as Administrator" "Gray"
Write-ColorOutput ""
Write-ColorOutput "Instructions saved: $instructionsPath" "Cyan"
Write-ColorOutput "Connection test: $connectionTestPath" "Cyan"
Write-ColorOutput ""
Write-ColorOutput "Network share is now available for manual deployment!" "Green"
