# Real-Time Security Monitoring Dashboard
# Continuously monitors system security status

param(
    [int]$RefreshInterval = 10,
    [switch]$ContinuousMode = $false
)

function Show-SecurityDashboard {
    Clear-Host
    
    Write-Host "🔍 REAL-TIME SECURITY MONITORING DASHBOARD" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host "=" * 80 -ForegroundColor Cyan
    
    # Windows Defender Status
    Write-Host "`n🛡️  WINDOWS DEFENDER STATUS" -ForegroundColor Yellow
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defenderStatus) {
            $avEnabled = if ($defenderStatus.AntivirusEnabled) { "✅ ENABLED" } else { "❌ DISABLED" }
            $rtEnabled = if ($defenderStatus.RealTimeProtectionEnabled) { "✅ ACTIVE" } else { "❌ INACTIVE" }
            
            Write-Host "   Antivirus Protection: $avEnabled" -ForegroundColor $(if ($defenderStatus.AntivirusEnabled) { "Green" } else { "Red" })
            Write-Host "   Real-Time Protection: $rtEnabled" -ForegroundColor $(if ($defenderStatus.RealTimeProtectionEnabled) { "Green" } else { "Red" })
            Write-Host "   Last Signature Update: $($defenderStatus.AntivirusSignatureLastUpdated)" -ForegroundColor Cyan
            Write-Host "   Quick Scan Age: $($defenderStatus.QuickScanAge) minutes" -ForegroundColor Cyan
        } else {
            Write-Host "   ⚠️  Windows Defender status unavailable" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "   ❌ Error checking Windows Defender status" -ForegroundColor Red
    }
    
    # Active Security Processes
    Write-Host "`n🔄 ACTIVE SECURITY PROCESSES" -ForegroundColor Green
    $securityProcesses = Get-Process | Where-Object {
        $_.ProcessName -match "MsMpEng|MpCmdRun|windefend|SecurityHealthService|msert|clamav|adwcleaner|rkill"
    }
    
    if ($securityProcesses) {
        $securityProcesses | Select-Object ProcessName, Id, 
            @{Name="CPU%";Expression={$_.CPU}},
            @{Name="Memory(MB)";Expression={[math]::Round($_.WorkingSet/1MB,2)}},
            @{Name="Runtime";Expression={
                try { (Get-Date) - $_.StartTime }
                catch { "Unknown" }
            }} | Format-Table -AutoSize
    } else {
        Write-Host "   ⚠️  No active security processes detected" -ForegroundColor Yellow
    }
    
    # Microsoft Safety Scanner Status
    Write-Host "`n📊 MICROSOFT SAFETY SCANNER STATUS" -ForegroundColor Magenta
    $msertProcesses = Get-Process -Name "msert" -ErrorAction SilentlyContinue
    if ($msertProcesses) {
        Write-Host "   ✅ Active scan in progress" -ForegroundColor Green
        $msertProcesses | ForEach-Object {
            $runtime = try { (Get-Date) - $_.StartTime } catch { "Unknown" }
            Write-Host "     Process ID: $($_.Id) | Runtime: $runtime | Memory: $([math]::Round($_.WorkingSet/1MB,2)) MB" -ForegroundColor Cyan
        }
    } else {
        Write-Host "   ❌ No active scan detected" -ForegroundColor Red
    }
    
    # Network Security Monitoring
    Write-Host "`n🌐 NETWORK CONNECTIONS" -ForegroundColor Cyan
    $connections = Get-NetTCPConnection | Where-Object {
        $_.State -eq "Established" -and 
        $_.RemoteAddress -notlike "127.*" -and 
        $_.RemoteAddress -notlike "::1" -and
        $_.RemoteAddress -notlike "192.168.*"
    } | Select-Object -First 10
    
    if ($connections) {
        $connections | Select-Object LocalPort, RemoteAddress, RemotePort, State | Format-Table -AutoSize
    } else {
        Write-Host "   ✅ No suspicious external connections detected" -ForegroundColor Green
    }
    
    # File System Monitoring
    Write-Host "`n📁 SECURITY TOOLS STATUS" -ForegroundColor Yellow
    $securityDirs = @(
        "$env:USERPROFILE\Desktop\EmergencySecurity",
        "$env:USERPROFILE\Desktop\SecurityTools",
        "$env:USERPROFILE\Desktop\FOSS_Tools"
    )
    
    foreach ($dir in $securityDirs) {
        if (Test-Path $dir) {
            $files = Get-ChildItem $dir -ErrorAction SilentlyContinue
            Write-Host "   📂 $dir ($($files.Count) files)" -ForegroundColor Cyan
            $files | Select-Object -First 5 | ForEach-Object {
                Write-Host "     • $($_.Name) ($([math]::Round($_.Length/1MB,2)) MB)" -ForegroundColor Gray
            }
        }
    }
    
    # Recent Security Events
    Write-Host "`n⚡ RECENT SECURITY EVENTS" -ForegroundColor Green
    try {
        $events = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=@(4625,4624,4672)} -MaxEvents 3 -ErrorAction SilentlyContinue
        if ($events) {
            $events | Select-Object TimeCreated, Id, @{Name="Event";Expression={
                switch ($_.Id) {
                    4624 { "Successful Login" }
                    4625 { "Failed Login" }
                    4672 { "Admin Privileges Assigned" }
                    default { "Security Event $($_.Id)" }
                }
            }} | Format-Table -AutoSize
        } else {
            Write-Host "   ℹ️  No recent security events" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "   ⚠️  Unable to access security event log" -ForegroundColor Yellow
    }
    
    # System Performance Impact
    Write-Host "`n💻 SECURITY IMPACT ON SYSTEM" -ForegroundColor Magenta
    $totalSecurityCPU = ($securityProcesses | Measure-Object -Property CPU -Sum).Sum
    $totalSecurityMemory = ($securityProcesses | Measure-Object -Property WorkingSet -Sum).Sum / 1MB
    
    Write-Host "   Total Security CPU Usage: $([math]::Round($totalSecurityCPU,2))%" -ForegroundColor Cyan
    Write-Host "   Total Security Memory Usage: $([math]::Round($totalSecurityMemory,2)) MB" -ForegroundColor Cyan
    
    # Summary Status
    Write-Host "`n🎯 SECURITY STATUS SUMMARY" -ForegroundColor White -BackgroundColor DarkGreen
    $defenderOK = try { (Get-MpComputerStatus).RealTimeProtectionEnabled } catch { $false }
    $scanningActive = (Get-Process -Name "msert" -ErrorAction SilentlyContinue) -ne $null
    
    if ($defenderOK -and $scanningActive) {
        Write-Host "   🟢 SYSTEM PROTECTED - Active scanning in progress" -ForegroundColor Green
    } elseif ($scanningActive) {
        Write-Host "   🟡 SCANNING ACTIVE - Enable Windows Defender for full protection" -ForegroundColor Yellow
    } elseif ($defenderOK) {
        Write-Host "   🟡 DEFENDER ACTIVE - Consider running additional scans" -ForegroundColor Yellow
    } else {
        Write-Host "   🔴 SYSTEM VULNERABLE - Enable protection immediately" -ForegroundColor Red
    }
    
    if ($ContinuousMode) {
        Write-Host "`n⏱️  Next update in $RefreshInterval seconds... (Press Ctrl+C to stop)" -ForegroundColor Gray
    }
}

# Main execution
if ($ContinuousMode) {
    Write-Host "Starting continuous security monitoring..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
    
    try {
        while ($true) {
            Show-SecurityDashboard
            Start-Sleep -Seconds $RefreshInterval
        }
    }
    catch [System.Management.Automation.PipelineStoppedException] {
        Write-Host "`nMonitoring stopped by user." -ForegroundColor Yellow
    }
} else {
    Show-SecurityDashboard
    Write-Host "`n💡 Tip: Run with -ContinuousMode for live monitoring" -ForegroundColor Cyan
}
