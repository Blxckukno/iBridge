# iBridge Network Deployment Script
# Automates sharing and deployment over mobile hotspot/network

param(
    [string]$ShareName = "iBridgeSetup",
    [string]$SharePath = "C:\iBridge_NetworkShare",
    [switch]$CreateShare,
    [switch]$DeployToDevices,
    [switch]$DeployToiBridgeDevices,
    [switch]$InteractiveSelection,
    [switch]$DeployToAllDevices,
    [string[]]$TargetDevices = @(),
    [pscredential]$Credential
)

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

Write-ColorOutput "iBridge Network Deployment - Mobile Hotspot Ready" "Cyan"
Write-ColorOutput "Automated sharing and deployment across network devices" "Yellow"
Write-ColorOutput ""

# Step 1: Create network share for deployment
if ($CreateShare) {
    Write-ColorOutput "Step 1: Creating network share for deployment..." "Green"
    
    # Create share directory
    if (!(Test-Path $SharePath)) {
        New-Item -ItemType Directory -Path $SharePath -Force | Out-Null
        Write-ColorOutput "Created share directory: $SharePath" "Gray"
    }
    
    # Copy all setup files to share
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
        # Remove existing share if it exists
        $existingShare = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
        if ($existingShare) {
            Remove-SmbShare -Name $ShareName -Force -Confirm:$false
        }
        
        # Create new share with full access
        New-SmbShare -Name $ShareName -Path $SharePath -FullAccess "Everyone" | Out-Null
        Write-ColorOutput "Created network share: \\$env:COMPUTERNAME\$ShareName" "Green"
        
        # Configure firewall
        New-NetFirewallRule -DisplayName "iBridge File Sharing" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow -ErrorAction SilentlyContinue
        Write-ColorOutput "Configured firewall for file sharing" "Gray"
        
    } catch {
        Write-ColorOutput "Error creating share: $($_.Exception.Message)" "Red"
    }
}

# Step 2: Auto-discover devices on network
Write-ColorOutput "Step 2: Discovering devices on network..." "Green"

# Get current network information
$networkAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.InterfaceDescription -like "*Wi-Fi*"} | Select-Object -First 1
if ($networkAdapter) {
    $networkConfig = Get-NetIPConfiguration -InterfaceIndex $networkAdapter.InterfaceIndex
    $subnet = $networkConfig.IPv4Address.IPAddress -replace '\.\d+$', ''
    Write-ColorOutput "Scanning subnet: $subnet.0/24" "Gray"
    
    # Ping sweep to find active devices
    $activeDevices = @()
    $iBridgeDevices = @()
    
    Write-ColorOutput "Scanning devices..." "Gray"
    
    # Use regular ForEach-Object for compatibility with PowerShell 5.1
    $jobs = @()
    1..254 | ForEach-Object {
        $ip = "$subnet.$_"
        $jobs += Start-Job -ScriptBlock {
            param($targetIP)
            # Use ping.exe for better compatibility with PowerShell 5.1
            $pingResult = ping $targetIP -n 1 -w 1000 2>$null
            if ($LASTEXITCODE -eq 0) {
                try {
                    $hostname = [System.Net.Dns]::GetHostByAddress($targetIP).HostName
                    [PSCustomObject]@{
                        IP = $targetIP
                        Hostname = $hostname
                    }
                } catch {
                    [PSCustomObject]@{
                        IP = $targetIP
                        Hostname = "Unknown"
                    }
                }
            }
        } -ArgumentList $ip
    }
    
    # Wait for all jobs to complete and collect results
    $activeDevices = $jobs | Wait-Job | Receive-Job | Where-Object { $_ -ne $null }
    $jobs | Remove-Job
    
    # Process devices and identify iBridge targets
    foreach ($device in $activeDevices) {
        # Check if this is an iBridge target device
        if ($device.Hostname -like "iBridge-JHB-*" -or $device.Hostname -like "GoRent PC*" -or $device.Hostname -eq "GoRent PC") {
            $iBridgeDevices += $device
            Write-ColorOutput "  TARGET FOUND: $($device.IP) - $($device.Hostname)" "Green"
        }
    }
    
    Write-ColorOutput "Found $($activeDevices.Count) active devices:" "Yellow"
    $activeDevices | ForEach-Object {
        if ($_.Hostname -like "iBridge-JHB-*" -or $_.Hostname -like "GoRent PC*" -or $_.Hostname -eq "GoRent PC") {
            Write-ColorOutput "  $($_.IP) - $($_.Hostname) [TARGET DEVICE]" "Green"
        } else {
            Write-ColorOutput "  $($_.IP) - $($_.Hostname)" "Gray"
        }
    }
    
    if ($iBridgeDevices.Count -gt 0) {
        Write-ColorOutput "" 
        Write-ColorOutput "iBridge Target Devices Found: $($iBridgeDevices.Count)" "Cyan"
        $iBridgeDevices | ForEach-Object {
            Write-ColorOutput "  $($_.Hostname) ($($_.IP))" "Cyan"
        }
    }
    
    # Store devices globally for interactive selection
    $global:AllNetworkDevices = $activeDevices
    $global:iBridgeNetworkDevices = $iBridgeDevices
}

# Step 3: Interactive device selection
if ($InteractiveSelection -and $global:AllNetworkDevices.Count -gt 0) {
    Write-ColorOutput "Step 3: Interactive Device Selection..." "Green"
    Write-ColorOutput ""
    Write-ColorOutput "Available devices on network:" "Yellow"
    
    # Display numbered list of devices
    for ($i = 0; $i -lt $global:AllNetworkDevices.Count; $i++) {
        $device = $global:AllNetworkDevices[$i]
        $deviceType = ""
        if ($device.Hostname -like "iBridge-JHB-*" -or $device.Hostname -like "GoRent PC*" -or $device.Hostname -eq "GoRent PC") {
            $deviceType = " [iBridge Device]"
        }
        Write-ColorOutput "  $($i + 1)) $($device.IP) - $($device.Hostname)$deviceType" "White"
    }
    
    Write-ColorOutput ""
    Write-ColorOutput "Selection options:" "Cyan"
    Write-ColorOutput "  - Enter device numbers (e.g., 1,3,5)" "Gray"
    Write-ColorOutput "  - Enter 'all' to select all devices" "Gray"
    Write-ColorOutput "  - Enter 'ibridge' to select only iBridge devices" "Gray"
    Write-ColorOutput "  - Enter 'quit' to cancel" "Gray"
    Write-ColorOutput ""
    
    $selection = Read-Host "Enter your selection"
    
    $selectedDevices = @()
    
    if ($selection.ToLower() -eq "all") {
        $selectedDevices = $global:AllNetworkDevices
        Write-ColorOutput "Selected ALL $($selectedDevices.Count) devices for deployment" "Green"
    }
    elseif ($selection.ToLower() -eq "ibridge") {
        $selectedDevices = $global:iBridgeNetworkDevices
        Write-ColorOutput "Selected $($selectedDevices.Count) iBridge devices for deployment" "Green"
    }
    elseif ($selection.ToLower() -eq "quit") {
        Write-ColorOutput "Deployment cancelled by user" "Yellow"
        return
    }
    else {
        # Parse individual device numbers
        try {
            $deviceNumbers = $selection.Split(',') | ForEach-Object { [int]$_.Trim() }
            foreach ($num in $deviceNumbers) {
                if ($num -gt 0 -and $num -le $global:AllNetworkDevices.Count) {
                    $selectedDevices += $global:AllNetworkDevices[$num - 1]
                } else {
                    Write-ColorOutput "Invalid device number: $num" "Red"
                }
            }
            Write-ColorOutput "Selected $($selectedDevices.Count) devices for deployment" "Green"
        }
        catch {
            Write-ColorOutput "Invalid selection format. Please try again." "Red"
            return
        }
    }
    
    if ($selectedDevices.Count -gt 0) {
        Write-ColorOutput ""
        Write-ColorOutput "Deploying to selected devices:" "Yellow"
        $selectedDevices | ForEach-Object {
            Write-ColorOutput "  $($_.Hostname) ($($_.IP))" "Gray"
        }
        
        # Deploy to selected devices
        if (!$Credential) {
            Write-ColorOutput ""
            Write-ColorOutput "Enter credentials for target devices:" "Yellow"
            $Credential = Get-Credential -Message "Enter admin credentials for target devices"
        }
        
        foreach ($device in $selectedDevices) {
            Write-ColorOutput "Deploying to: $($device.Hostname) ($($device.IP))" "Yellow"
            
            try {
                # Test connection first
                if (Test-Connection -ComputerName $device.IP -Count 1 -Quiet) {
                    
                    # Copy setup file to target device
                    $remotePath = "\\$($device.IP)\C$\Temp\iBridge_Setup"
                    if (!(Test-Path $remotePath)) {
                        New-Item -ItemType Directory -Path $remotePath -Force -ErrorAction Stop
                    }
                    
                    Copy-Item "$SharePath\UNIVERSAL-USB-SETUP.bat" "$remotePath\UNIVERSAL-USB-SETUP.bat" -Force
                    Write-ColorOutput "  Copied setup file to $($device.Hostname)" "Gray"
                    
                    # Execute setup remotely
                    $scriptBlock = {
                        param($SetupPath)
                        Set-Location "C:\Temp\iBridge_Setup"
                        Start-Process -FilePath "UNIVERSAL-USB-SETUP.bat" -Verb RunAs -Wait
                    }
                    
                    Invoke-Command -ComputerName $device.IP -Credential $Credential -ScriptBlock $scriptBlock -ArgumentList "C:\Temp\iBridge_Setup\UNIVERSAL-USB-SETUP.bat"
                    Write-ColorOutput "  Setup executed on $($device.Hostname) successfully" "Green"
                    
                } else {
                    Write-ColorOutput "  Cannot reach $($device.Hostname)" "Red"
                }
                
            } catch {
                Write-ColorOutput "  Error deploying to $($device.Hostname): $($_.Exception.Message)" "Red"
            }
        }
    }
}

# Step 4: Deploy to all devices automatically  
if ($DeployToAllDevices -and $global:AllNetworkDevices.Count -gt 0) {
    Write-ColorOutput "Step 4: Auto-deploying to ALL network devices..." "Green"
    
    if (!$Credential) {
        Write-ColorOutput "Enter credentials for network devices:" "Yellow"
        $Credential = Get-Credential -Message "Enter admin credentials for all network devices"
    }
    
    Write-ColorOutput "Deploying to $($global:AllNetworkDevices.Count) devices..." "Yellow"
    
    foreach ($device in $global:AllNetworkDevices) {
        Write-ColorOutput "Deploying to: $($device.Hostname) ($($device.IP))" "Yellow"
        
        try {
            # Test connection first
            if (Test-Connection -ComputerName $device.IP -Count 1 -Quiet) {
                
                # Copy setup file to target device
                $remotePath = "\\$($device.IP)\C$\Temp\iBridge_Setup"
                if (!(Test-Path $remotePath)) {
                    New-Item -ItemType Directory -Path $remotePath -Force -ErrorAction Stop
                }
                
                Copy-Item "$SharePath\UNIVERSAL-USB-SETUP.bat" "$remotePath\UNIVERSAL-USB-SETUP.bat" -Force
                Write-ColorOutput "  Copied setup file to $($device.Hostname)" "Gray"
                
                # Execute setup remotely
                $scriptBlock = {
                    param($SetupPath)
                    Set-Location "C:\Temp\iBridge_Setup"
                    Start-Process -FilePath "UNIVERSAL-USB-SETUP.bat" -Verb RunAs -Wait
                }
                
                Invoke-Command -ComputerName $device.IP -Credential $Credential -ScriptBlock $scriptBlock -ArgumentList "C:\Temp\iBridge_Setup\UNIVERSAL-USB-SETUP.bat"
                Write-ColorOutput "  Setup executed on $($device.Hostname) successfully" "Green"
                
            } else {
                Write-ColorOutput "  Cannot reach $($device.Hostname)" "Red"
            }
            
        } catch {
            Write-ColorOutput "  Error deploying to $($device.Hostname): $($_.Exception.Message)" "Red"
        }
    }
}

# Step 5: Deploy to iBridge devices automatically
if ($DeployToiBridgeDevices -and $iBridgeDevices.Count -gt 0) {
    Write-ColorOutput "Step 5: Auto-deploying to iBridge devices..." "Green"
    
    if (!$Credential) {
        Write-ColorOutput "Enter credentials for iBridge devices:" "Yellow"
        $Credential = Get-Credential -Message "Enter admin credentials for iBridge/GoRent devices"
    }
    
    foreach ($device in $iBridgeDevices) {
        Write-ColorOutput "Deploying to: $($device.Hostname) ($($device.IP))" "Yellow"
        
        try {
            # Test connection first
            if (Test-Connection -ComputerName $device.IP -Count 1 -Quiet) {
                
                # Copy setup file to target device
                $remotePath = "\\$($device.IP)\C$\Temp\iBridge_Setup"
                if (!(Test-Path $remotePath)) {
                    New-Item -ItemType Directory -Path $remotePath -Force -ErrorAction Stop
                }
                
                Copy-Item "$SharePath\UNIVERSAL-USB-SETUP.bat" "$remotePath\UNIVERSAL-USB-SETUP.bat" -Force
                Write-ColorOutput "  Copied setup file to $($device.Hostname)" "Gray"
                
                # Execute setup remotely
                $scriptBlock = {
                    param($SetupPath)
                    Set-Location "C:\Temp\iBridge_Setup"
                    Start-Process -FilePath "UNIVERSAL-USB-SETUP.bat" -Verb RunAs -Wait
                }
                
                Invoke-Command -ComputerName $device.IP -Credential $Credential -ScriptBlock $scriptBlock -ArgumentList "C:\Temp\iBridge_Setup\UNIVERSAL-USB-SETUP.bat"
                Write-ColorOutput "  Setup executed on $($device.Hostname) successfully" "Green"
                
            } else {
                Write-ColorOutput "  Cannot reach $($device.Hostname)" "Red"
            }
            
        } catch {
            Write-ColorOutput "  Error deploying to $($device.Hostname): $($_.Exception.Message)" "Red"
        }
    }
}

# Step 6: Deploy to specific devices
if ($DeployToDevices -and $TargetDevices.Count -gt 0) {
    Write-ColorOutput "Step 6: Deploying to specific target devices..." "Green"
    
    if (!$Credential) {
        Write-ColorOutput "Enter credentials for target devices:" "Yellow"
        $Credential = Get-Credential -Message "Enter admin credentials for target devices"
    }
    
    foreach ($device in $TargetDevices) {
        Write-ColorOutput "Deploying to: $device" "Yellow"
        
        try {
            # Test connection first
            if (Test-Connection -ComputerName $device -Count 1 -Quiet) {
                
                # Copy setup file to target device
                $remotePath = "\\$device\C$\Temp\iBridge_Setup"
                if (!(Test-Path $remotePath)) {
                    New-Item -ItemType Directory -Path $remotePath -Force -ErrorAction Stop
                }
                
                Copy-Item "$SharePath\UNIVERSAL-USB-SETUP.bat" "$remotePath\UNIVERSAL-USB-SETUP.bat" -Force
                Write-ColorOutput "  Copied setup file to $device" "Gray"
                
                # Execute setup remotely
                $scriptBlock = {
                    param($SetupPath)
                    Set-Location "C:\Temp\iBridge_Setup"
                    Start-Process -FilePath "UNIVERSAL-USB-SETUP.bat" -Verb RunAs -Wait
                }
                
                Invoke-Command -ComputerName $device -Credential $Credential -ScriptBlock $scriptBlock -ArgumentList "C:\Temp\iBridge_Setup\UNIVERSAL-USB-SETUP.bat"
                Write-ColorOutput "  Setup executed on $device successfully" "Green"
                
            } else {
                Write-ColorOutput "  Cannot reach $device" "Red"
            }
            
        } catch {
            Write-ColorOutput "  Error deploying to $device`: $($_.Exception.Message)" "Red"
        }
    }
}

# Step 7: Create deployment instructions
Write-ColorOutput "Step 7: Creating deployment instructions..." "Green"

$instructions = @"
iBridge Network Deployment Instructions
Generated: $(Get-Date)

NETWORK SHARE CREATED:
Share Name: $ShareName
Share Path: \\$env:COMPUTERNAME\$ShareName
Local Path: $SharePath

MOBILE HOTSPOT DEPLOYMENT:
1. Ensure this computer is connected to mobile hotspot
2. Other devices connect to same mobile hotspot
3. Run this script with -CreateShare to set up sharing
4. Share setup files via: \\$env:COMPUTERNAME\$ShareName

MANUAL DEPLOYMENT TO OTHER DEVICES:
1. On target device, open Run dialog (Win+R)
2. Type: \\$env:COMPUTERNAME\$ShareName
3. Copy UNIVERSAL-USB-SETUP.bat to target device
4. Right-click and "Run as administrator"

AUTOMATED DEPLOYMENT:
Run this command to deploy to specific devices:
.\NETWORK-DEPLOYMENT.ps1 -DeployToDevices -TargetDevices @("PC1","PC2","PC3")

DISCOVERED NETWORK DEVICES:
$(($activeDevices | ForEach-Object { "  $($_.IP) - $($_.Hostname)" }) -join "`n")

FIREWALL NOTES:
- File sharing firewall rule created
- Target devices may need Windows Defender firewall exceptions
- Ensure "Network discovery" is enabled on target devices

TROUBLESHOOTING:
- If share not accessible, check Windows Defender Firewall
- Ensure target devices have "File and Printer Sharing" enabled
- Use IP addresses if hostnames don't resolve
- Run as Administrator on both source and target devices
"@

$instructionsPath = "$SharePath\DEPLOYMENT-INSTRUCTIONS.txt"
$instructions | Out-File $instructionsPath -Encoding UTF8

Write-ColorOutput ""
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "NETWORK DEPLOYMENT READY!" "Green" 
Write-ColorOutput "========================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "Network Share: \\$env:COMPUTERNAME\$ShareName" "Cyan"
Write-ColorOutput "Setup files available for network deployment" "Cyan"
Write-ColorOutput "Instructions saved: $instructionsPath" "Cyan"
Write-ColorOutput ""
Write-ColorOutput "NEXT STEPS:" "White"
Write-ColorOutput "1. Ensure all devices connected to mobile hotspot" "Gray"
Write-ColorOutput "2. Access share from other devices: \\$env:COMPUTERNAME\$ShareName" "Gray"
Write-ColorOutput "3. Run UNIVERSAL-USB-SETUP.bat as Administrator" "Gray"
Write-ColorOutput "4. Or use automated deployment with -DeployToDevices" "Gray"
Write-ColorOutput ""
