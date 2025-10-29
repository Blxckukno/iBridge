# Alternative Deployment - Multiple Connection Methods
# Handles devices that don't respond to ping but are connected

param([pscredential]$Credential)

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

Write-ColorOutput "iBridge Alternative Deployment - Multiple Connection Methods" "Cyan"
Write-ColorOutput "Handles devices that don't respond to ping" "Yellow"
Write-ColorOutput ""

# Configuration
$ShareName = "iBridgeSetup"
$SharePath = "C:\iBridge_NetworkShare"

# Step 1: Ensure network share exists
Write-ColorOutput "Step 1: Ensuring network share is available..." "Green"

if (!(Test-Path $SharePath)) {
    New-Item -ItemType Directory -Path $SharePath -Force | Out-Null
}

# Copy setup files
$sourceFiles = @(
    "C:\Users\Lwandile Gasela\iBridge\Scripts\UNIVERSAL-USB-SETUP.bat",
    "C:\Users\Lwandile Gasela\iBridge\Scripts\iBridge-Simple-Standalone.ps1",
    "C:\Users\Lwandile Gasela\iBridge\Scripts\RUN-STANDALONE-SETUP.bat"
)

foreach ($file in $sourceFiles) {
    if (Test-Path $file) {
        $fileName = Split-Path $file -Leaf
        Copy-Item $file "$SharePath\$fileName" -Force
    }
}

# Ensure share exists
try {
    $existingShare = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
    if (!$existingShare) {
        New-SmbShare -Name $ShareName -Path $SharePath -FullAccess "Everyone" | Out-Null
    }
    Write-ColorOutput "Network share ready: \\$env:COMPUTERNAME\$ShareName" "Green"
} catch {
    Write-ColorOutput "Share setup complete" "Gray"
}

# Step 2: Try multiple connection methods
Write-ColorOutput "Step 2: Attempting deployment with multiple methods..." "Green"

$iBridgeDevices = @(
    @{Name = "iBridge-JHB-70"; IP = "192.168.137.131"},
    @{Name = "iBridge-JHB-44"; IP = "192.168.137.31"}, 
    @{Name = "iBridge-JHB-33"; IP = "192.168.137.83"},
    @{Name = "iBridge-JHB-14"; IP = "192.168.137.240"},
    @{Name = "iBridge-JHB-18"; IP = "192.168.137.134"}
)

$successCount = 0
$partialCount = 0

foreach ($device in $iBridgeDevices) {
    Write-ColorOutput "Attempting deployment to: $($device.Name) ($($device.IP))" "Yellow"
    
    $deploymentSuccess = $false
    $filesCopied = $false
    
    # Method 1: Try direct file copy (works even without ping response)
    try {
        Write-ColorOutput "  Method 1: Direct file copy..." -NoNewline
        
        $remotePaths = @(
            "\\$($device.IP)\C$\Temp\iBridge_Setup",
            "\\$($device.IP)\C$\Users\Public\Desktop",
            "\\$($device.IP)\C$\Users\Administrator\Desktop"
        )
        
        foreach ($remotePath in $remotePaths) {
            try {
                if ($remotePath -like "*iBridge_Setup") {
                    if (!(Test-Path $remotePath)) {
                        New-Item -ItemType Directory -Path $remotePath -Force | Out-Null
                    }
                    Copy-Item "$SharePath\UNIVERSAL-USB-SETUP.bat" "$remotePath\UNIVERSAL-USB-SETUP.bat" -Force -ErrorAction Stop
                } else {
                    Copy-Item "$SharePath\UNIVERSAL-USB-SETUP.bat" "$remotePath\iBridge-Setup.bat" -Force -ErrorAction Stop
                }
                
                Write-ColorOutput " SUCCESS" "Green"
                $filesCopied = $true
                break
            } catch {
                continue
            }
        }
        
        if (!$filesCopied) {
            Write-ColorOutput " FAILED" "Red"
        }
        
    } catch {
        Write-ColorOutput " FAILED" "Red"
    }
    
    # Method 2: Try PowerShell remoting if files were copied
    if ($filesCopied) {
        try {
            Write-ColorOutput "  Method 2: PowerShell remoting..." -NoNewline
            
            if (!$Credential) {
                Write-ColorOutput ""
                Write-ColorOutput "Enter credentials for $($device.Name):" "Yellow"
                $Credential = Get-Credential -Message "Enter admin credentials for $($device.Name)"
            }
            
            $scriptBlock = {
                if (Test-Path "C:\Temp\iBridge_Setup\UNIVERSAL-USB-SETUP.bat") {
                    Set-Location "C:\Temp\iBridge_Setup"
                    Start-Process -FilePath "UNIVERSAL-USB-SETUP.bat" -Verb RunAs -PassThru
                }
            }
            
            $result = Invoke-Command -ComputerName $device.IP -Credential $Credential -ScriptBlock $scriptBlock -ErrorAction Stop
            Write-ColorOutput " SUCCESS" "Green"
            $deploymentSuccess = $true
            $successCount++
            
        } catch {
            Write-ColorOutput " FAILED (manual execution required)" "Yellow"
            $partialCount++
        }
    }
    
    # Method 3: Create instruction file for manual execution
    if ($filesCopied -and !$deploymentSuccess) {
        try {
            $instructionPath = "\\$($device.IP)\C$\Users\Public\Desktop\iBridge-INSTRUCTIONS.txt"
            $instructions = @"
iBridge Setup Instructions for $($device.Name)
Generated: $(Get-Date)

SETUP LOCATION: C:\Temp\iBridge_Setup\UNIVERSAL-USB-SETUP.bat
ALTERNATE LOCATION: Desktop\iBridge-Setup.bat

TO INSTALL:
1. Right-click on UNIVERSAL-USB-SETUP.bat (or iBridge-Setup.bat)
2. Select "Run as administrator"
3. Follow the prompts

WHAT GETS INSTALLED:
- Admin account (Password: IBr1dG3Pc)
- iBridge User account (Password: Abc654321!)
- All required applications
- Desktop shortcuts

After installation, you can safely remove any USB drives.
All applications will work independently.
"@
            $instructions | Out-File $instructionPath -Encoding UTF8 -Force
            Write-ColorOutput "  Created manual installation instructions" "Gray"
        } catch {
            # Instructions creation failed, but files were copied
        }
    }
    
    if (!$filesCopied) {
        Write-ColorOutput "  All connection methods failed" "Red"
    }
    
    Write-ColorOutput ""
}

# Step 3: Create network share instructions
Write-ColorOutput "Step 3: Creating network access instructions..." "Green"

$networkInstructions = @"
iBridge Network Deployment Instructions
Generated: $(Get-Date)

NETWORK SHARE ACCESS:
Share Location: \\$env:COMPUTERNAME\$ShareName
Available to all devices on network

FOR MANUAL INSTALLATION ON ANY DEVICE:
1. On the target device, open File Explorer
2. In the address bar, type: \\$env:COMPUTERNAME\$ShareName
3. Copy UNIVERSAL-USB-SETUP.bat to the device desktop
4. Right-click and "Run as administrator"

CONNECTED DEVICES (from mobile hotspot):
- iBridge-JHB-70 (192.168.137.131)
- iBridge-JHB-44 (192.168.137.31)
- iBridge-JHB-33 (192.168.137.83)
- iBridge-JHB-14 (192.168.137.240)
- iBridge-JHB-18 (192.168.137.134)

TROUBLESHOOTING:
- If devices don't respond to remote commands, they may have Windows Firewall enabled
- Files should still be copied for manual execution
- Use the network share for manual deployment
- Ensure target devices are powered on and not in sleep mode

WHAT GETS INSTALLED:
- Admin account: Admin (Password: IBr1dG3Pc)
- iBridge User: iBridge User (Password: Abc654321!)
- All applications (4 total)
- Desktop shortcuts for iBridge User
- Standalone operation (no USB required)
"@

$instructionsPath = "$SharePath\NETWORK-DEPLOYMENT-INSTRUCTIONS.txt"
$networkInstructions | Out-File $instructionsPath -Encoding UTF8

# Summary
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "ALTERNATIVE DEPLOYMENT SUMMARY" "Green"
Write-ColorOutput "========================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "Total devices: $($iBridgeDevices.Count)" "Cyan"
Write-ColorOutput "Fully deployed: $successCount" "Green"
Write-ColorOutput "Files copied (manual execution needed): $partialCount" "Yellow"
Write-ColorOutput "Failed completely: $($iBridgeDevices.Count - $successCount - $partialCount)" "Red"
Write-ColorOutput ""
Write-ColorOutput "Network share available: \\$env:COMPUTERNAME\$ShareName" "Cyan"
Write-ColorOutput "Instructions saved: $instructionsPath" "Cyan"
Write-ColorOutput ""

if ($successCount -gt 0) {
    Write-ColorOutput "DEVICES WITH FULL DEPLOYMENT READY!" "Green"
}

if ($partialCount -gt 0) {
    Write-ColorOutput "DEVICES WITH FILES COPIED - MANUAL EXECUTION REQUIRED" "Yellow"
    Write-ColorOutput "Check device desktops for iBridge-Setup.bat or instructions" "Yellow"
}

if (($successCount + $partialCount) -eq 0) {
    Write-ColorOutput "USE NETWORK SHARE FOR MANUAL DEPLOYMENT" "Yellow"
    Write-ColorOutput "Devices can access: \\$env:COMPUTERNAME\$ShareName" "Yellow"
}

Write-ColorOutput ""
Write-ColorOutput "NEXT STEPS:" "White"
Write-ColorOutput "1. Check each device for copied files or use network share" "Gray"
Write-ColorOutput "2. Execute setup files manually if needed" "Gray"
Write-ColorOutput "3. Verify accounts and applications are installed" "Gray"
Write-ColorOutput "4. Test standalone operation" "Gray"
