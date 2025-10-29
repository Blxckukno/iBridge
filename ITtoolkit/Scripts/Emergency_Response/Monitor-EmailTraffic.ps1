# Monitor-EmailTraffic.ps1
# Real-time monitoring for suspicious email traffic from @ibridge.co.za compromise
# Run this while investigating the breach

Write-Host "=== REAL-TIME EMAIL TRAFFIC MONITOR ===" -ForegroundColor Red
Write-Host "Monitoring for suspicious email activity..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Cyan

# Email-related ports to monitor
$emailPorts = @(25, 110, 143, 587, 993, 995, 465, 2525)
$suspiciousIPs = @()
$alertCount = 0

function Get-EmailConnections {
    $connections = @()
    
    foreach ($port in $emailPorts) {
        $netstatOutput = netstat -an | Select-String ":$port.*ESTABLISHED"
        foreach ($line in $netstatOutput) {
            if ($line -match "(\d+\.\d+\.\d+\.\d+):$port.*?(\d+\.\d+\.\d+\.\d+):(\d+).*ESTABLISHED") {
                $localIP = $matches[1]
                $remoteIP = $matches[2]
                $remotePort = $matches[3]
                
                $connections += [PSCustomObject]@{
                    LocalIP = $localIP
                    LocalPort = $port
                    RemoteIP = $remoteIP
                    RemotePort = $remotePort
                    Protocol = "TCP"
                    Service = switch ($port) {
                        25 { "SMTP" }
                        110 { "POP3" }
                        143 { "IMAP" }
                        587 { "SMTP (submission)" }
                        993 { "IMAPS" }
                        995 { "POP3S" }
                        465 { "SMTPS" }
                        2525 { "SMTP (alternate)" }
                    }
                    Timestamp = Get-Date
                }
            }
        }
    }
    
    return $connections
}

function Resolve-IPLocation {
    param($IP)
    
    try {
        # Simple IP geolocation check (you can enhance this with proper geolocation APIs)
        $response = Invoke-RestMethod -Uri "http://ip-api.com/json/$IP" -TimeoutSec 5
        return "$($response.country) - $($response.org)"
    } catch {
        return "Unknown"
    }
}

function Check-SuspiciousActivity {
    param($connections)
    
    foreach ($conn in $connections) {
        $suspicious = $false
        $reasons = @()
        
        # Check for non-Microsoft email servers (suspicious for Exchange environment)
        if ($conn.RemoteIP -notmatch "^(40\.|52\.|13\.|20\.|23\.|104\.)" -and 
            $conn.RemoteIP -notmatch "^(207\.46\.|65\.55\.|157\.55\.)") {
            $suspicious = $true
            $reasons += "Non-Microsoft IP"
        }
        
        # Check for unusual email ports
        if ($conn.LocalPort -in @(2525, 465) -and $conn.Service -like "*SMTP*") {
            $suspicious = $true
            $reasons += "Unusual SMTP port"
        }
        
        # Check for connections to known malicious countries (you can customize this list)
        $location = Resolve-IPLocation $conn.RemoteIP
        if ($location -match "(Russia|China|North Korea|Iran)") {
            $suspicious = $true
            $reasons += "Suspicious country: $location"
        }
        
        if ($suspicious) {
            $alertCount++
            Write-Host "`n[ALERT $alertCount] Suspicious email connection detected!" -ForegroundColor Red
            Write-Host "  Time: $($conn.Timestamp)" -ForegroundColor Yellow
            Write-Host "  Service: $($conn.Service)" -ForegroundColor Yellow
            Write-Host "  Remote IP: $($conn.RemoteIP)" -ForegroundColor Yellow
            Write-Host "  Location: $location" -ForegroundColor Yellow
            Write-Host "  Reasons: $($reasons -join ', ')" -ForegroundColor Yellow
            
            # Log to file
            $logEntry = "$($conn.Timestamp),$($conn.Service),$($conn.RemoteIP),$location,`"$($reasons -join '; ')`""
            $logEntry | Out-File -FilePath "SuspiciousEmailTraffic.csv" -Append
            
            # Add to tracking
            if ($conn.RemoteIP -notin $suspiciousIPs) {
                $suspiciousIPs += $conn.RemoteIP
            }
        }
    }
}

# Create CSV header
"Timestamp,Service,RemoteIP,Location,Reasons" | Out-File -FilePath "SuspiciousEmailTraffic.csv"

# Main monitoring loop
$previousConnections = @()
$loopCount = 0

while ($true) {
    try {
        $loopCount++
        $currentConnections = Get-EmailConnections
        
        # Check for new connections
        $newConnections = @()
        foreach ($current in $currentConnections) {
            $exists = $false
            foreach ($previous in $previousConnections) {
                if ($current.RemoteIP -eq $previous.RemoteIP -and $current.LocalPort -eq $previous.LocalPort) {
                    $exists = $true
                    break
                }
            }
            if (-not $exists) {
                $newConnections += $current
            }
        }
        
        if ($newConnections.Count -gt 0) {
            Write-Host "`n[$loopCount] New email connections detected: $($newConnections.Count)" -ForegroundColor Cyan
            Check-SuspiciousActivity $newConnections
        } else {
            Write-Host "[$loopCount] Monitoring... (No new connections)" -ForegroundColor Gray
        }
        
        $previousConnections = $currentConnections
        
        # Show summary every 20 loops
        if ($loopCount % 20 -eq 0) {
            Write-Host "`n=== MONITORING SUMMARY ===" -ForegroundColor Cyan
            Write-Host "Alerts generated: $alertCount" -ForegroundColor Yellow
            Write-Host "Suspicious IPs tracked: $($suspiciousIPs.Count)" -ForegroundColor Yellow
            Write-Host "Current email connections: $($currentConnections.Count)" -ForegroundColor Yellow
        }
        
        Start-Sleep -Seconds 3
        
    } catch {
        Write-Warning "Monitoring error: $_"
        Start-Sleep -Seconds 5
    }
}
