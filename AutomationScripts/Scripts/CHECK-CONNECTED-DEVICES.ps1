# Check Connected Devices - Mobile Hotspot Scanner
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Mobile Hotspot Connected Devices Scanner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get network adapter info
$networkAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
if ($networkAdapter) {
    $networkConfig = Get-NetIPConfiguration -InterfaceIndex $networkAdapter.InterfaceIndex
    $currentIP = $networkConfig.IPv4Address.IPAddress
    $subnet = $currentIP -replace '\.\d+$', ''
    
    Write-Host "Host Device: $env:COMPUTERNAME" -ForegroundColor Yellow
    Write-Host "Host IP: $currentIP" -ForegroundColor Yellow
    Write-Host "Scanning subnet: $subnet.0/24" -ForegroundColor Yellow
    Write-Host ""
    
    # Based on your mobile hotspot screenshot, these are the known connected devices:
    $knownDevices = @(
        @{Name = "iBridge-JHB-70"; IP = "192.168.137.131"},
        @{Name = "iBridge-JHB-44"; IP = "192.168.137.31"}, 
        @{Name = "iBridge-JHB-33"; IP = "192.168.137.83"},
        @{Name = "iBridge-JHB-14"; IP = "192.168.137.240"},
        @{Name = "iBridge-JHB-18"; IP = "192.168.137.134"},
        @{Name = "Honor-x6a"; IP = "192.168.137.195"}
    )
    
    Write-Host "Checking known devices from mobile hotspot..." -ForegroundColor Green
    Write-Host ""
    
    $activeDevices = @()
    $iBridgeDevices = @()
    
    foreach ($device in $knownDevices) {
        Write-Host "Testing $($device.Name) ($($device.IP))..." -NoNewline
        
        if (Test-Connection -ComputerName $device.IP -Count 1 -Quiet) {
            Write-Host " ONLINE" -ForegroundColor Green
            
            $deviceInfo = [PSCustomObject]@{
                IP = $device.IP
                Hostname = $device.Name
                Status = "Online"
            }
            
            $activeDevices += $deviceInfo
            
            # Check if this is an iBridge target device
            if ($device.Name -like "iBridge-JHB-*") {
                $iBridgeDevices += $deviceInfo
            }
        } else {
            Write-Host " OFFLINE" -ForegroundColor Red
        }
    }
    
    # Also scan the full range to find any additional devices
    Write-Host ""
    Write-Host "Scanning for additional devices..." -ForegroundColor Green
    
    $scanRange = @(1..254)
    $foundAdditional = @()
    
    foreach ($num in $scanRange) {
        $ip = "$subnet.$num"
        
        # Skip known IPs
        $isKnown = $knownDevices | Where-Object {$_.IP -eq $ip}
        if ($isKnown -or $ip -eq $currentIP) {
            continue
        }
        
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
            try {
                $hostname = [System.Net.Dns]::GetHostByAddress($ip).HostName
                $foundAdditional += [PSCustomObject]@{
                    IP = $ip
                    Hostname = $hostname
                    Status = "Online"
                }
            } catch {
                $foundAdditional += [PSCustomObject]@{
                    IP = $ip
                    Hostname = "Unknown"
                    Status = "Online"
                }
            }
        }
    }
    
    # Display results
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "CONNECTED DEVICES SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $totalDevices = $activeDevices.Count + $foundAdditional.Count
    Write-Host "Total devices found: $totalDevices" -ForegroundColor Yellow
    Write-Host ""
    
    if ($activeDevices.Count -gt 0) {
        Write-Host "Known Mobile Hotspot Devices:" -ForegroundColor Green
        foreach ($device in $activeDevices) {
            if ($device.Hostname -like "iBridge-JHB-*") {
                Write-Host "  $($device.IP) - $($device.Hostname) [iBridge TARGET]" -ForegroundColor Green
            } else {
                Write-Host "  $($device.IP) - $($device.Hostname)" -ForegroundColor White
            }
        }
        Write-Host ""
    }
    
    if ($foundAdditional.Count -gt 0) {
        Write-Host "Additional Devices Found:" -ForegroundColor Yellow
        foreach ($device in $foundAdditional) {
            Write-Host "  $($device.IP) - $($device.Hostname)" -ForegroundColor White
        }
        Write-Host ""
    }
    
    if ($iBridgeDevices.Count -gt 0) {
        Write-Host "iBridge Target Devices Online: $($iBridgeDevices.Count)" -ForegroundColor Cyan
        foreach ($device in $iBridgeDevices) {
            Write-Host "  $($device.Hostname) ($($device.IP))" -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "Ready for iBridge deployment!" -ForegroundColor Green
    } else {
        Write-Host "No iBridge target devices currently online" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "No active network adapter found" -ForegroundColor Red
}

Write-Host ""
Write-Host "Device scan completed!" -ForegroundColor Cyan
