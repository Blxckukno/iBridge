# iBridge Network Deployment Script for Mobile Hotspot
# Automatically shares and deploys setup to devices on mobile hotspot network

param(
    [string]$NetworkShare = "iBridgeSetup",
    [string]$SharePath = "C:\iBridge_Network_Share",
    [switch]$ScanOnly,
    [switch]$DeployAll
)

# Configuration
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$SetupScript = Join-Path $ScriptPath "iBridge-Simple-Standalone.ps1"
$UniversalSetup = Join-Path $ScriptPath "UNIVERSAL-USB-SETUP.bat"

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

Write-ColorOutput "iBridge Network Deployment - Mobile Hotspot Edition" "Cyan"
Write-ColorOutput "Automated sharing and deployment over your mobile hotspot" "Yellow"
Write-ColorOutput ""

# Step 1: Create network share folder
Write-ColorOutput "Step 1: Setting up network share..." "Green"
if (!(Test-Path $SharePath)) {
    New-Item -ItemType Directory -Path $SharePath -Force | Out-Null
    Write-ColorOutput "Created share folder: $SharePath" "Gray"
}

# Copy all setup files to share
$filesToShare = @(
    $SetupScript,
    $UniversalSetup,
    "E:\24.2.2000.exe",
    "E:\GlassWireSetup.exe", 
    "E:\PBIDesktopSetup_x64.exe",
    "E:\TeamViewer_Setup_x64.exe"
)

# Copy Office tools folder
$officeSource = "E:\Tools for Office2019 TechXander"
if (Test-Path $officeSource) {
    $officeDest = Join-Path $SharePath "Tools for Office2019 TechXander"
    Copy-Item $officeSource $officeDest -Recurse -Force -ErrorAction SilentlyContinue
    Write-ColorOutput "Copied Office tools to share" "Gray"
}

# Copy shortcuts folders
$shortcutFolders = @("E:\IT STUFF", "E:\iBridge Set Up")
foreach ($folder in $shortcutFolders) {
    if (Test-Path $folder) {
        $destName = Split-Path $folder -Leaf
        $dest = Join-Path $SharePath $destName
        Copy-Item $folder $dest -Recurse -Force -ErrorAction SilentlyContinue
        Write-ColorOutput "Copied $destName to share" "Gray"
    }
}

foreach ($file in $filesToShare) {
    if (Test-Path $file) {
        $fileName = Split-Path $file -Leaf
        Copy-Item $file (Join-Path $SharePath $fileName) -Force -ErrorAction SilentlyContinue
        Write-ColorOutput "Copied $fileName to share" "Gray"
    }
}

# Step 2: Create network share
Write-ColorOutput "Step 2: Creating network share..." "Green"
try {
    # Remove existing share if it exists
    Get-SmbShare -Name $NetworkShare -ErrorAction SilentlyContinue | Remove-SmbShare -Force -Confirm:$false

    # Create new share with full access
    New-SmbShare -Name $NetworkShare -Path $SharePath -FullAccess "Everyone" -Description "iBridge Setup Files"
    Write-ColorOutput "Network share created: \\$env:COMPUTERNAME\$NetworkShare" "Green"
    
    # Set folder permissions
    $acl = Get-Acl $SharePath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $SharePath -AclObject $acl
    Write-ColorOutput "Folder permissions set for Everyone" "Gray"
} catch {
    Write-ColorOutput "Error creating share: $($_.Exception.Message)" "Red"
}

# Step 3: Enable network discovery and file sharing
Write-ColorOutput "Step 3: Enabling network discovery..." "Green"
try {
    # Enable network discovery
    netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes | Out-Null
    netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes | Out-Null
    
    # Start required services
    Start-Service -Name "Function Discovery Provider Host" -ErrorAction SilentlyContinue
    Start-Service -Name "Function Discovery Resource Publication" -ErrorAction SilentlyContinue
    Start-Service -Name "Server" -ErrorAction SilentlyContinue
    
    Write-ColorOutput "Network discovery and file sharing enabled" "Gray"
} catch {
    Write-ColorOutput "Warning: Could not fully enable network discovery" "Yellow"
}

# Step 4: Scan for devices on mobile hotspot network
Write-ColorOutput "Step 4: Scanning for devices on your mobile hotspot..." "Green"
$myIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*"}).IPAddress | Select-Object -First 1
$networkBase = $myIP.Substring(0, $myIP.LastIndexOf('.'))

Write-ColorOutput "Your IP: $myIP" "Gray"
Write-ColorOutput "Scanning network: $networkBase.1-254" "Gray"

$onlineDevices = @()
for ($i = 1; $i -le 254; $i++) {
    $testIP = "$networkBase.$i"
    if ($testIP -ne $myIP) {
        $ping = Test-Connection -ComputerName $testIP -Count 1 -Quiet -TimeoutSeconds 1
        if ($ping) {
            try {
                $hostname = [System.Net.Dns]::GetHostByAddress($testIP).HostName
            } catch {
                $hostname = "Unknown"
            }
            $onlineDevices += @{IP = $testIP; Hostname = $hostname}
            Write-ColorOutput "Found device: $testIP ($hostname)" "Yellow"
        }
    }
}

if ($ScanOnly) {
    Write-ColorOutput "Scan complete. Found $($onlineDevices.Count) devices." "Cyan"
    exit 0
}

# Step 5: Create remote deployment script
Write-ColorOutput "Step 5: Creating remote deployment commands..." "Green"
$deployScript = @"
# Remote deployment commands for target devices
# Run these commands on each target device as Administrator

# Method 1: Map network drive and run setup
net use Z: \\$env:COMPUTERNAME\$NetworkShare
Z:\UNIVERSAL-USB-SETUP.bat

# Method 2: Copy and run locally
robocopy \\$env:COMPUTERNAME\$NetworkShare C:\Temp\iBridge_Remote /E
cd C:\Temp\iBridge_Remote
powershell.exe -ExecutionPolicy Bypass -File "iBridge-Simple-Standalone.ps1"

# Method 3: Direct PowerShell execution
powershell.exe -ExecutionPolicy Bypass -Command "Invoke-Expression (Get-Content '\\$env:COMPUTERNAME\$NetworkShare\iBridge-Simple-Standalone.ps1' -Raw)"
"@

$deployScriptPath = Join-Path $SharePath "REMOTE-DEPLOY-COMMANDS.txt"
$deployScript | Out-File $deployScriptPath -Encoding UTF8

# Step 6: Create automated remote deployment (if requested)
if ($DeployAll -and $onlineDevices.Count -gt 0) {
    Write-ColorOutput "Step 6: Attempting automated deployment..." "Green"
    
    $credential = Get-Credential -Message "Enter admin credentials for target devices"
    
    foreach ($device in $onlineDevices) {
        Write-ColorOutput "Deploying to $($device.IP) ($($device.Hostname))..." "Yellow"
        
        try {
            # Try to enable PowerShell remoting on target
            Invoke-Command -ComputerName $device.IP -Credential $credential -ScriptBlock {
                Enable-PSRemoting -Force -SkipNetworkProfileCheck
                Set-ExecutionPolicy RemoteSigned -Force
            } -ErrorAction SilentlyContinue
            
            # Copy and execute setup
            Invoke-Command -ComputerName $device.IP -Credential $credential -ScriptBlock {
                param($ShareUNC, $ComputerName)
                
                # Map network drive
                net use Z: "$ShareUNC" /persistent:no
                
                # Copy files locally
                robocopy "Z:\" "C:\Temp\iBridge_Remote" /E /R:1 /W:1
                
                # Run setup
                if (Test-Path "C:\Temp\iBridge_Remote\iBridge-Simple-Standalone.ps1") {
                    powershell.exe -ExecutionPolicy Bypass -File "C:\Temp\iBridge_Remote\iBridge-Simple-Standalone.ps1"
                }
                
                # Clean up
                net use Z: /delete /y
                
            } -ArgumentList "\\$env:COMPUTERNAME\$NetworkShare", $env:COMPUTERNAME
            
            Write-ColorOutput "Deployment to $($device.IP) completed" "Green"
            
        } catch {
            Write-ColorOutput "Failed to deploy to $($device.IP): $($_.Exception.Message)" "Red"
        }
    }
}

# Final summary
Write-ColorOutput ""
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "NETWORK DEPLOYMENT SETUP COMPLETE!" "Green"
Write-ColorOutput "========================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "NETWORK SHARE READY:" "Cyan"
Write-ColorOutput "Share Name: \\$env:COMPUTERNAME\$NetworkShare" "White"
Write-ColorOutput "Local Path: $SharePath" "Gray"
Write-ColorOutput ""
Write-ColorOutput "DEVICES FOUND ON HOTSPOT:" "Cyan"
if ($onlineDevices.Count -gt 0) {
    foreach ($device in $onlineDevices) {
        Write-ColorOutput "  $($device.IP) - $($device.Hostname)" "White"
    }
} else {
    Write-ColorOutput "  No other devices found" "Gray"
}
Write-ColorOutput ""
Write-ColorOutput "MANUAL DEPLOYMENT OPTIONS:" "Yellow"
Write-ColorOutput "1. Tell users to connect to: \\$env:COMPUTERNAME\$NetworkShare" "Gray"
Write-ColorOutput "2. Users run: UNIVERSAL-USB-SETUP.bat" "Gray"
Write-ColorOutput "3. Or use commands in: REMOTE-DEPLOY-COMMANDS.txt" "Gray"
Write-ColorOutput ""
Write-ColorOutput "AUTOMATED OPTIONS:" "Yellow"
Write-ColorOutput "Re-run with -DeployAll to attempt automatic deployment" "Gray"
Write-ColorOutput "Example: .\NETWORK-DEPLOY-HOTSPOT.ps1 -DeployAll" "Gray"
