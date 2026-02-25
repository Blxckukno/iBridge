# Quick Deploy - No Scanning Required
# Uses exact device list from mobile hotspot settings

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

Write-ColorOutput "iBridge Quick Deploy - Using Known Device List" "Cyan"
Write-ColorOutput "No network scanning - deploying to mobile hotspot devices" "Yellow"
Write-ColorOutput ""

# Configuration
$ShareName = "iBridgeSetup"
$SharePath = "C:\iBridge_NetworkShare"

# Step 1: Create network share quickly
Write-ColorOutput "Step 1: Creating network share..." "Green"

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
        Write-ColorOutput "Copied: $fileName" "Gray"
    }
}

# Create network share
try {
    $existingShare = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
    if ($existingShare) {
        Remove-SmbShare -Name $ShareName -Force -Confirm:$false
    }
    
    New-SmbShare -Name $ShareName -Path $SharePath -FullAccess "Everyone" | Out-Null
    Write-ColorOutput "Created network share: \\$env:COMPUTERNAME\$ShareName" "Green"
} catch {
    Write-ColorOutput "Share may already exist or error: $($_.Exception.Message)" "Yellow"
}

# Step 2: Deploy to known iBridge devices (from mobile hotspot list)
Write-ColorOutput "Step 2: Deploying to known iBridge devices..." "Green"

# Exact devices from your mobile hotspot settings
$iBridgeDevices = @(
    @{Name = "iBridge-JHB-70"; IP = "192.168.137.131"},
    @{Name = "iBridge-JHB-44"; IP = "192.168.137.31"}, 
    @{Name = "iBridge-JHB-33"; IP = "192.168.137.83"},
    @{Name = "iBridge-JHB-14"; IP = "192.168.137.240"},
    @{Name = "iBridge-JHB-18"; IP = "192.168.137.134"}
)

Write-ColorOutput "Target devices from mobile hotspot:" "Yellow"
foreach ($device in $iBridgeDevices) {
    Write-ColorOutput "  $($device.Name) - $($device.IP)" "Gray"
}
Write-ColorOutput ""

if (!$Credential) {
    Write-ColorOutput "Enter credentials for iBridge devices:" "Yellow"
    $Credential = Get-Credential -Message "Enter admin credentials for iBridge devices"
}

$successCount = 0
$totalDevices = $iBridgeDevices.Count

foreach ($device in $iBridgeDevices) {
    Write-ColorOutput "Deploying to: $($device.Name) ($($device.IP))" "Yellow"
    
    try {
        # Quick ping test first
        $pingResult = Test-Connection -ComputerName $device.IP -Count 1 -Quiet
        
        if ($pingResult) {
            Write-ColorOutput "  Device is online - proceeding with deployment" "Green"
            
            # Copy setup file to target device
            $remotePath = "\\$($device.IP)\C$\Temp\iBridge_Setup"
            try {
                if (!(Test-Path $remotePath)) {
                    New-Item -ItemType Directory -Path $remotePath -Force -ErrorAction Stop | Out-Null
                }
                
                Copy-Item "$SharePath\UNIVERSAL-USB-SETUP.bat" "$remotePath\UNIVERSAL-USB-SETUP.bat" -Force -ErrorAction Stop
                Write-ColorOutput "  Setup file copied successfully" "Gray"
                
                # Execute setup remotely
                $scriptBlock = {
                    Set-Location "C:\Temp\iBridge_Setup"
                    Start-Process -FilePath "UNIVERSAL-USB-SETUP.bat" -Verb RunAs -Wait
                }
                
                Invoke-Command -ComputerName $device.IP -Credential $Credential -ScriptBlock $scriptBlock -ErrorAction Stop
                Write-ColorOutput "  Deployment completed successfully!" "Green"
                $successCount++
                
            } catch {
                Write-ColorOutput "  File copy/execution error: $($_.Exception.Message)" "Red"
                # Try alternative approach - just copy file for manual execution
                try {
                    $desktopPath = "\\$($device.IP)\C$\Users\Public\Desktop\iBridge-Setup.bat"
                    Copy-Item "$SharePath\UNIVERSAL-USB-SETUP.bat" $desktopPath -Force
                    Write-ColorOutput "  Setup file copied to desktop for manual execution" "Yellow"
                } catch {
                    Write-ColorOutput "  Could not copy to desktop either" "Red"
                }
            }
            
        } else {
            Write-ColorOutput "  Device not responding to ping" "Red"
        }
        
    } catch {
        Write-ColorOutput "  Error: $($_.Exception.Message)" "Red"
    }
    
    Write-ColorOutput "" 
}

# Summary
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "QUICK DEPLOYMENT SUMMARY" "Green"
Write-ColorOutput "========================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "Total devices: $totalDevices" "Cyan"
Write-ColorOutput "Successful deployments: $successCount" "Green"
Write-ColorOutput "Failed deployments: $($totalDevices - $successCount)" "Red"
Write-ColorOutput ""
Write-ColorOutput "Network share available at: \\$env:COMPUTERNAME\$ShareName" "Cyan"
Write-ColorOutput ""

if ($successCount -eq $totalDevices) {
    Write-ColorOutput "ALL DEVICES DEPLOYED SUCCESSFULLY!" "Green"
} elseif ($successCount -gt 0) {
    Write-ColorOutput "PARTIAL DEPLOYMENT COMPLETED" "Yellow"
    Write-ColorOutput "Check failed devices and try manual installation" "Yellow"
} else {
    Write-ColorOutput "NO DEVICES DEPLOYED" "Red"
    Write-ColorOutput "Check network connectivity and credentials" "Red"
}

Write-ColorOutput ""
Write-ColorOutput "Each deployed device should now have:" "White"
Write-ColorOutput "  - Admin account: Admin (Password: IBr1dG3Pc)" "Gray"
Write-ColorOutput "  - iBridge User: iBridge User (Password: Abc654321!)" "Gray"
Write-ColorOutput "  - All applications installed" "Gray"
Write-ColorOutput "  - Desktop shortcuts ready" "Gray"
