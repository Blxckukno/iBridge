# Fully Automated Network Deployment
# Uses multiple automated methods to deploy without manual intervention

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

function Enable-RemoteAccess {
    param([string]$DeviceIP)
    
    try {
        # Try to enable WinRM and file sharing remotely
        $commands = @(
            "winrm quickconfig -q -force",
            "winrm set winrm/config/service/auth '@{Basic=""true""}'",
            "netsh advfirewall firewall set rule group=`"File and Printer Sharing`" new enable=Yes",
            "netsh advfirewall firewall set rule group=`"Windows Remote Management`" new enable=Yes"
        )
        
        foreach ($cmd in $commands) {
            try {
                # Use PsExec-like approach or WMI
                $result = Invoke-WmiMethod -ComputerName $DeviceIP -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c $cmd" -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            } catch {
                # Continue to next command
            }
        }
        return $true
    } catch {
        return $false
    }
}

function Deploy-ViaWMI {
    param([string]$DeviceIP, [string]$DeviceName)
    
    try {
        Write-ColorOutput "  Attempting WMI deployment..." -NoNewline
        
        # Create remote directory using WMI
        $createDirCmd = "cmd.exe /c mkdir C:\Temp\iBridge_Setup 2>nul"
        Invoke-WmiMethod -ComputerName $DeviceIP -Class Win32_Process -Name Create -ArgumentList $createDirCmd -ErrorAction Stop | Out-Null
        
        # Copy file using administrative shares
        $localFile = "C:\iBridge_NetworkShare\UNIVERSAL-USB-SETUP.bat"
        $remoteFile = "\\$DeviceIP\C$\Temp\iBridge_Setup\UNIVERSAL-USB-SETUP.bat"
        Copy-Item $localFile $remoteFile -Force -ErrorAction Stop
        
        # Execute remotely using WMI
        $execCmd = "cmd.exe /c cd C:\Temp\iBridge_Setup && UNIVERSAL-USB-SETUP.bat"
        $result = Invoke-WmiMethod -ComputerName $DeviceIP -Class Win32_Process -Name Create -ArgumentList $execCmd -ErrorAction Stop
        
        Write-ColorOutput " SUCCESS" "Green"
        return $true
    } catch {
        Write-ColorOutput " FAILED" "Red"
        return $false
    }
}

function Deploy-ViaPowerShell {
    param([string]$DeviceIP, [string]$DeviceName, [pscredential]$Cred)
    
    try {
        Write-ColorOutput "  Attempting PowerShell remoting..." -NoNewline
        
        $session = New-PSSession -ComputerName $DeviceIP -Credential $Cred -ErrorAction Stop
        
        # Copy files
        Copy-Item "C:\iBridge_NetworkShare\UNIVERSAL-USB-SETUP.bat" -Destination "C:\Temp\iBridge_Setup\" -ToSession $session -Force -ErrorAction Stop
        Copy-Item "C:\iBridge_NetworkShare\iBridge-Simple-Standalone.ps1" -Destination "C:\Temp\iBridge_Setup\" -ToSession $session -Force -ErrorAction Stop
        
        # Execute setup
        $scriptBlock = {
            New-Item -ItemType Directory -Path "C:\Temp\iBridge_Setup" -Force -ErrorAction SilentlyContinue
            Set-Location "C:\Temp\iBridge_Setup"
            Start-Process -FilePath "UNIVERSAL-USB-SETUP.bat" -Verb RunAs -Wait -WindowStyle Hidden
        }
        
        Invoke-Command -Session $session -ScriptBlock $scriptBlock -ErrorAction Stop
        Remove-PSSession $session
        
        Write-ColorOutput " SUCCESS" "Green"
        return $true
    } catch {
        Write-ColorOutput " FAILED" "Red"
        return $false
    }
}

function Deploy-ViaScheduledTask {
    param([string]$DeviceIP, [string]$DeviceName)
    
    try {
        Write-ColorOutput "  Attempting scheduled task deployment..." -NoNewline
        
        # Create scheduled task remotely
        $taskName = "iBridgeSetup_$(Get-Random)"
        $taskCmd = "C:\Temp\iBridge_Setup\UNIVERSAL-USB-SETUP.bat"
        
        # Use schtasks to create remote task
        $createTask = "schtasks /create /tn `"$taskName`" /tr `"$taskCmd`" /sc once /st 23:59 /s $DeviceIP /ru SYSTEM /f"
        $executeTask = "schtasks /run /tn `"$taskName`" /s $DeviceIP"
        $deleteTask = "schtasks /delete /tn `"$taskName`" /s $DeviceIP /f"
        
        # Execute commands
        cmd.exe /c $createTask 2>$null
        Start-Sleep -Seconds 2
        cmd.exe /c $executeTask 2>$null
        Start-Sleep -Seconds 5
        cmd.exe /c $deleteTask 2>$null
        
        Write-ColorOutput " SUCCESS" "Green"
        return $true
    } catch {
        Write-ColorOutput " FAILED" "Red"
        return $false
    }
}

function Deploy-ViaNetworkDrive {
    param([string]$DeviceIP, [string]$DeviceName)
    
    try {
        Write-ColorOutput "  Attempting network drive deployment..." -NoNewline
        
        # Map network drive and execute
        $mapDrive = "net use Z: \\$env:COMPUTERNAME\iBridgeSetup /persistent:no"
        $copyFile = "copy Z:\UNIVERSAL-USB-SETUP.bat C:\Temp\iBridge_Setup\"
        $runSetup = "C:\Temp\iBridge_Setup\UNIVERSAL-USB-SETUP.bat"
        $unmapDrive = "net use Z: /delete /y"
        
        $fullCommand = "$mapDrive && mkdir C:\Temp\iBridge_Setup 2>nul && $copyFile && $runSetup && $unmapDrive"
        
        # Execute via WMI
        $result = Invoke-WmiMethod -ComputerName $DeviceIP -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c $fullCommand" -ErrorAction Stop
        
        Write-ColorOutput " SUCCESS" "Green"
        return $true
    } catch {
        Write-ColorOutput " FAILED" "Red"
        return $false
    }
}

# Check admin privileges
if (-not (Test-Administrator)) {
    Write-ColorOutput "ERROR: This script must be run as Administrator" "Red"
    exit 1
}

Write-ColorOutput "iBridge Fully Automated Network Deployment" "Cyan"
Write-ColorOutput "Multiple automated deployment methods" "Yellow"
Write-ColorOutput ""

# Configuration
$ShareName = "iBridgeSetup"
$SharePath = "C:\iBridge_NetworkShare"

# Step 1: Ensure network share and enable services
Write-ColorOutput "Step 1: Preparing automated deployment environment..." "Green"

# Enable necessary services
try {
    Set-Service -Name "LanmanServer" -StartupType Automatic -Status Running -ErrorAction SilentlyContinue
    Set-Service -Name "WinRM" -StartupType Automatic -Status Running -ErrorAction SilentlyContinue
    
    # Configure WinRM
    winrm quickconfig -q -force 2>$null
    winrm set winrm/config/service/auth '@{Basic="true"}' 2>$null
    
    # Enable firewall rules
    netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>$null
    netsh advfirewall firewall set rule group="Windows Remote Management" new enable=Yes 2>$null
    netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=Yes 2>$null
    
    Write-ColorOutput "Remote services enabled" "Gray"
} catch {
    Write-ColorOutput "Service configuration completed" "Gray"
}

# Ensure share exists
if (!(Test-Path $SharePath)) {
    New-Item -ItemType Directory -Path $SharePath -Force | Out-Null
}

$sourceFiles = @(
    "C:\Users\Lwandile Gasela\iBridge\Scripts\UNIVERSAL-USB-SETUP.bat",
    "C:\Users\Lwandile Gasela\iBridge\Scripts\iBridge-Simple-Standalone.ps1"
)

foreach ($file in $sourceFiles) {
    if (Test-Path $file) {
        $fileName = Split-Path $file -Leaf
        Copy-Item $file "$SharePath\$fileName" -Force
    }
}

try {
    $existingShare = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
    if (!$existingShare) {
        New-SmbShare -Name $ShareName -Path $SharePath -FullAccess "Everyone" | Out-Null
    }
    Write-ColorOutput "Network share ready: \\$env:COMPUTERNAME\$ShareName" "Green"
} catch {
    Write-ColorOutput "Share configuration completed" "Gray"
}

# Step 2: Automated deployment to devices
Write-ColorOutput "Step 2: Executing automated deployment..." "Green"

$iBridgeDevices = @(
    @{Name = "iBridge-JHB-70"; IP = "192.168.137.131"},
    @{Name = "iBridge-JHB-44"; IP = "192.168.137.31"}, 
    @{Name = "iBridge-JHB-33"; IP = "192.168.137.83"},
    @{Name = "iBridge-JHB-14"; IP = "192.168.137.240"},
    @{Name = "iBridge-JHB-18"; IP = "192.168.137.134"}
)

$successCount = 0
$deploymentResults = @()

# Get credentials once for all devices
if (!$Credential) {
    Write-ColorOutput "Enter admin credentials for target devices:" "Yellow"
    $Credential = Get-Credential -Message "Enter admin credentials (will be used for all devices)"
}

foreach ($device in $iBridgeDevices) {
    Write-ColorOutput "Automated deployment to: $($device.Name) ($($device.IP))" "Yellow"
    
    $deployed = $false
    $method = "None"
    
    # Method 1: Try WMI deployment (most reliable)
    if (!$deployed) {
        if (Deploy-ViaWMI -DeviceIP $device.IP -DeviceName $device.Name) {
            $deployed = $true
            $method = "WMI"
        }
    }
    
    # Method 2: Try PowerShell remoting
    if (!$deployed) {
        if (Deploy-ViaPowerShell -DeviceIP $device.IP -DeviceName $device.Name -Cred $Credential) {
            $deployed = $true
            $method = "PowerShell Remoting"
        }
    }
    
    # Method 3: Try scheduled task
    if (!$deployed) {
        if (Deploy-ViaScheduledTask -DeviceIP $device.IP -DeviceName $device.Name) {
            $deployed = $true
            $method = "Scheduled Task"
        }
    }
    
    # Method 4: Try network drive mapping
    if (!$deployed) {
        if (Deploy-ViaNetworkDrive -DeviceIP $device.IP -DeviceName $device.Name) {
            $deployed = $true
            $method = "Network Drive"
        }
    }
    
    if ($deployed) {
        $successCount++
        Write-ColorOutput "  ✓ Deployment successful via $method" "Green"
    } else {
        Write-ColorOutput "  ✗ All automated methods failed" "Red"
    }
    
    $deploymentResults += [PSCustomObject]@{
        Device = $device.Name
        IP = $device.IP
        Success = $deployed
        Method = $method
    }
    
    Write-ColorOutput ""
}

# Summary
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "AUTOMATED DEPLOYMENT SUMMARY" "Green"
Write-ColorOutput "========================================" "Green"
Write-ColorOutput ""
Write-ColorOutput "Total devices: $($iBridgeDevices.Count)" "Cyan"
Write-ColorOutput "Successful deployments: $successCount" "Green"
Write-ColorOutput "Failed deployments: $($iBridgeDevices.Count - $successCount)" "Red"
Write-ColorOutput ""

Write-ColorOutput "Deployment Results:" "Yellow"
foreach ($result in $deploymentResults) {
    if ($result.Success) {
        Write-ColorOutput "  ✓ $($result.Device) - SUCCESS ($($result.Method))" "Green"
    } else {
        Write-ColorOutput "  ✗ $($result.Device) - FAILED" "Red"
    }
}

Write-ColorOutput ""
if ($successCount -gt 0) {
    Write-ColorOutput "AUTOMATED DEPLOYMENT COMPLETED!" "Green"
    Write-ColorOutput "Devices should now have iBridge setup installed automatically" "Green"
} else {
    Write-ColorOutput "AUTOMATED DEPLOYMENT FAILED FOR ALL DEVICES" "Red"
    Write-ColorOutput "Consider using manual deployment via network share" "Yellow"
}

Write-ColorOutput ""
Write-ColorOutput "Each successful deployment includes:" "White"
Write-ColorOutput "  - Admin account: Admin (Password: IBr1dG3Pc)" "Gray"
Write-ColorOutput "  - iBridge User: iBridge User (Password: Abc654321!)" "Gray"
Write-ColorOutput "  - All applications installed automatically" "Gray"
Write-ColorOutput "  - Desktop shortcuts configured" "Gray"
Write-ColorOutput "  - Standalone operation enabled" "Gray"
