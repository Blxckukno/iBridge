# Test Network Scanning - PowerShell 5.1 Compatible
Write-Host "Testing network scanning compatibility..." -ForegroundColor Cyan

# Get network adapter
$networkAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
if ($networkAdapter) {
    $networkConfig = Get-NetIPConfiguration -InterfaceIndex $networkAdapter.InterfaceIndex
    $currentIP = $networkConfig.IPv4Address.IPAddress
    $subnet = $currentIP -replace '\.\d+$', ''
    
    Write-Host "Current IP: $currentIP" -ForegroundColor Yellow
    Write-Host "Scanning subnet: $subnet.0/24" -ForegroundColor Yellow
    
    # Test a few IPs to verify scanning works
    $testRange = @(1, 100, 101, 102, 103, 254)
    $foundDevices = @()
    
    foreach ($num in $testRange) {
        $ip = "$subnet.$num"
        Write-Host "Testing $ip..." -NoNewline
        
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
            try {
                $hostname = [System.Net.Dns]::GetHostByAddress($ip).HostName
                $foundDevices += [PSCustomObject]@{
                    IP = $ip
                    Hostname = $hostname
                }
                Write-Host " FOUND: $hostname" -ForegroundColor Green
            } catch {
                $foundDevices += [PSCustomObject]@{
                    IP = $ip
                    Hostname = "Unknown"
                }
                Write-Host " FOUND: Unknown device" -ForegroundColor Yellow
            }
        } else {
            Write-Host " No response" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "Network scan test results:" -ForegroundColor Cyan
    Write-Host "Found $($foundDevices.Count) devices" -ForegroundColor Yellow
    
    foreach ($device in $foundDevices) {
        if ($device.Hostname -like "iBridge-JHB-*" -or $device.Hostname -like "GoRent PC*" -or $device.Hostname -eq "GoRent PC") {
            Write-Host "  $($device.IP) - $($device.Hostname) [TARGET DEVICE]" -ForegroundColor Green
        } else {
            Write-Host "  $($device.IP) - $($device.Hostname)" -ForegroundColor White
        }
    }
} else {
    Write-Host "No active network adapter found" -ForegroundColor Red
}

Write-Host ""
Write-Host "Network scanning test completed!" -ForegroundColor Cyan
