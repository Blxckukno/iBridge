# Microsoft Defender Security Score Optimization Tool
# Comprehensive script to maximize Windows Defender security effectiveness

Write-Host "🛡️  MICROSOFT DEFENDER SECURITY SCORE OPTIMIZER" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Optimizing Windows Defender for maximum security protection..." -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$optimizations = @()
$errors = @()

function Test-DefenderStatus {
    Write-Host "`n🔍 CURRENT DEFENDER STATUS" -ForegroundColor Yellow
    
    try {
        $status = Get-MpComputerStatus
        
        Write-Host "  📊 Current Configuration:" -ForegroundColor Cyan
        Write-Host "    Antivirus Enabled: $($status.AntivirusEnabled)" -ForegroundColor $(if ($status.AntivirusEnabled) {"Green"} else {"Red"})
        Write-Host "    Real-Time Protection: $($status.RealTimeProtectionEnabled)" -ForegroundColor $(if ($status.RealTimeProtectionEnabled) {"Green"} else {"Red"})
        Write-Host "    Behavior Monitoring: $($status.BehaviorMonitorEnabled)" -ForegroundColor $(if ($status.BehaviorMonitorEnabled) {"Green"} else {"Red"})
        Write-Host "    Cloud Protection: $($status.MAPSReporting)" -ForegroundColor Cyan
        Write-Host "    Automatic Sample Submission: $($status.SubmitSamplesConsent)" -ForegroundColor Cyan
        Write-Host "    Last Signature Update: $($status.AntivirusSignatureLastUpdated)" -ForegroundColor Cyan
        Write-Host "    Last Quick Scan: $($status.QuickScanAge) minutes ago" -ForegroundColor Cyan
        Write-Host "    Last Full Scan: $($status.FullScanAge) minutes ago" -ForegroundColor Cyan
        
        return $status
    }
    catch {
        Write-Host "  ❌ Cannot retrieve Defender status: $($_.Exception.Message)" -ForegroundColor Red
        $script:errors += "Cannot retrieve Defender status"
        return $null
    }
}

function Enable-DefenderOptimalSettings {
    Write-Host "`n⚙️  APPLYING OPTIMAL DEFENDER SETTINGS" -ForegroundColor Yellow
    
    if (-not $isAdmin) {
        Write-Host "  ⚠️  Administrator privileges required for optimal configuration" -ForegroundColor Yellow
        Write-Host "  📋 Recommended settings (run as Administrator):" -ForegroundColor Cyan
        
        $recommendations = @(
            "Set-MpPreference -DisableRealtimeMonitoring `$false",
            "Set-MpPreference -DisableBehaviorMonitoring `$false",
            "Set-MpPreference -DisableBlockAtFirstSeen `$false",
            "Set-MpPreference -DisableIOAVProtection `$false",
            "Set-MpPreference -DisablePrivacyMode `$false",
            "Set-MpPreference -DisableIntrusionPreventionSystem `$false",
            "Set-MpPreference -DisableScriptScanning `$false",
            "Set-MpPreference -MAPSReporting Advanced",
            "Set-MpPreference -SubmitSamplesConsent SendAllSamples",
            "Set-MpPreference -CloudBlockLevel HighPlus",
            "Set-MpPreference -CloudExtendedTimeout 50"
        )
        
        foreach ($cmd in $recommendations) {
            Write-Host "    $cmd" -ForegroundColor Gray
        }
        return
    }
    
    # Apply optimal settings with admin privileges
    $settingsToApply = @{
        "Real-Time Protection" = { Set-MpPreference -DisableRealtimeMonitoring $false }
        "Behavior Monitoring" = { Set-MpPreference -DisableBehaviorMonitoring $false }
        "Block at First Seen" = { Set-MpPreference -DisableBlockAtFirstSeen $false }
        "IOAV Protection" = { Set-MpPreference -DisableIOAVProtection $false }
        "Script Scanning" = { Set-MpPreference -DisableScriptScanning $false }
        "Cloud Protection (Advanced)" = { Set-MpPreference -MAPSReporting Advanced }
        "Sample Submission" = { Set-MpPreference -SubmitSamplesConsent SendAllSamples }
        "High Cloud Protection" = { Set-MpPreference -CloudBlockLevel HighPlus }
        "Extended Cloud Timeout" = { Set-MpPreference -CloudExtendedTimeout 50 }
    }
    
    foreach ($setting in $settingsToApply.GetEnumerator()) {
        try {
            Write-Host "  🔧 Configuring: $($setting.Key)" -ForegroundColor Cyan
            & $setting.Value
            Write-Host "    ✅ Applied: $($setting.Key)" -ForegroundColor Green
            $script:optimizations += $setting.Key
        }
        catch {
            Write-Host "    ❌ Failed: $($setting.Key) - $($_.Exception.Message)" -ForegroundColor Red
            $script:errors += "Failed to configure $($setting.Key)"
        }
    }
}

function Update-DefenderSignatures {
    Write-Host "`n🔄 UPDATING DEFENDER SIGNATURES" -ForegroundColor Yellow
    
    try {
        Write-Host "  📥 Downloading latest threat definitions..." -ForegroundColor Cyan
        Update-MpSignature
        Write-Host "  ✅ Threat definitions updated successfully" -ForegroundColor Green
        $script:optimizations += "Updated threat definitions"
    }
    catch {
        Write-Host "  ❌ Failed to update signatures: $($_.Exception.Message)" -ForegroundColor Red
        $script:errors += "Failed to update signatures"
    }
}

function Configure-DefenderExclusions {
    Write-Host "`n📁 CONFIGURING DEFENDER EXCLUSIONS" -ForegroundColor Yellow
    
    # Remove potentially risky exclusions
    try {
        $currentExclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath -ErrorAction SilentlyContinue
        
        if ($currentExclusions) {
            Write-Host "  📋 Current Exclusions:" -ForegroundColor Cyan
            foreach ($exclusion in $currentExclusions) {
                Write-Host "    • $exclusion" -ForegroundColor Gray
                
                # Check for risky exclusions
                if ($exclusion -match "(C:\\|System32|temp|download|appdata)" -and $isAdmin) {
                    Write-Host "      ⚠️  Potentially risky exclusion detected" -ForegroundColor Yellow
                    Write-Host "      Consider removing: $exclusion" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "  ✅ No path exclusions configured (recommended)" -ForegroundColor Green
        }
        
        # Add performance exclusions for legitimate tools only
        if ($isAdmin) {
            $safeExclusions = @(
                "$env:ProgramFiles\7-Zip",
                "$env:ProgramFiles\Mozilla Firefox", 
                "$env:ProgramFiles\Oracle\VirtualBox"
            )
            
            foreach ($exclusion in $safeExclusions) {
                if (Test-Path $exclusion) {
                    try {
                        Add-MpPreference -ExclusionPath $exclusion -ErrorAction SilentlyContinue
                        Write-Host "  ✅ Added safe exclusion: $exclusion" -ForegroundColor Green
                    }
                    catch {
                        # Exclusion might already exist
                    }
                }
            }
        }
    }
    catch {
        Write-Host "  ⚠️  Cannot access exclusion settings" -ForegroundColor Yellow
    }
}

function Start-DefenderScan {
    Write-Host "`n🔍 INITIATING DEFENDER SCAN" -ForegroundColor Yellow
    
    try {
        Write-Host "  🚀 Starting quick scan..." -ForegroundColor Cyan
        Start-MpScan -ScanType QuickScan
        Write-Host "  ✅ Quick scan initiated successfully" -ForegroundColor Green
        $script:optimizations += "Initiated security scan"
    }
    catch {
        Write-Host "  ❌ Failed to start scan: $($_.Exception.Message)" -ForegroundColor Red
        $script:errors += "Failed to start security scan"
    }
}

function Enable-DefenderFirewall {
    Write-Host "`n🔥 WINDOWS FIREWALL OPTIMIZATION" -ForegroundColor Yellow
    
    try {
        $firewallProfiles = Get-NetFirewallProfile
        
        foreach ($profile in $firewallProfiles) {
            $status = if ($profile.Enabled) { "✅ ENABLED" } else { "❌ DISABLED" }
            Write-Host "  $($profile.Name) Profile: $status" -ForegroundColor $(if ($profile.Enabled) {"Green"} else {"Red"})
        }
        
        if ($isAdmin) {
            # Enable all firewall profiles
            Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
            Write-Host "  🔧 All firewall profiles enabled" -ForegroundColor Green
            $script:optimizations += "Enabled Windows Firewall"
        } else {
            Write-Host "  ⚠️  Admin privileges needed to configure firewall" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ❌ Firewall configuration error: $($_.Exception.Message)" -ForegroundColor Red
        $script:errors += "Firewall configuration failed"
    }
}

function Test-DefenderComponents {
    Write-Host "`n🧩 DEFENDER COMPONENT STATUS" -ForegroundColor Yellow
    
    $components = @{
        "Windows Security Service" = "SecurityHealthService"
        "Antimalware Service" = "MsMpEng"
        "Network Inspection" = "NisSrv"
    }
    
    foreach ($component in $components.GetEnumerator()) {
        $process = Get-Process -Name $component.Value -ErrorAction SilentlyContinue
        if ($process) {
            Write-Host "  ✅ $($component.Key): Running (PID: $($process.Id))" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $($component.Key): Not running" -ForegroundColor Red
            $script:errors += "$($component.Key) service not running"
        }
    }
}

function Get-DefenderThreatHistory {
    Write-Host "`n📊 THREAT DETECTION HISTORY" -ForegroundColor Yellow
    
    try {
        $threats = Get-MpThreatDetection | Select-Object -First 10
        
        if ($threats) {
            Write-Host "  ⚠️  Recent Threat Detections:" -ForegroundColor Red
            $threats | Select-Object ThreatName, Resources, ActionSuccess | Format-Table -AutoSize
        } else {
            Write-Host "  ✅ No recent threats detected" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  ℹ️  No threat history available" -ForegroundColor Gray
    }
}

function Generate-SecurityScoreReport {
    Write-Host "`n📋 SECURITY SCORE ASSESSMENT" -ForegroundColor White -BackgroundColor DarkGreen
    
    $score = 0
    $maxScore = 100
    
    try {
        $status = Get-MpComputerStatus
        
        # Calculate security score based on configuration
        if ($status.AntivirusEnabled) { $score += 20 }
        if ($status.RealTimeProtectionEnabled) { $score += 25 }
        if ($status.BehaviorMonitorEnabled) { $score += 15 }
        if ($status.IoavProtectionEnabled) { $score += 10 }
        if ($status.MAPSReporting -eq "Advanced") { $score += 10 }
        if ($status.SubmitSamplesConsent -ne "NeverSend") { $score += 10 }
        if ($status.AntivirusSignatureAge -lt 1) { $score += 10 }
        
        $scoreColor = if ($score -ge 80) { "Green" } elseif ($score -ge 60) { "Yellow" } else { "Red" }
        
        Write-Host "  🎯 Current Security Score: $score/$maxScore" -ForegroundColor $scoreColor
        Write-Host "  📈 Optimizations Applied: $($optimizations.Count)" -ForegroundColor Cyan
        Write-Host "  ⚠️  Issues Found: $($errors.Count)" -ForegroundColor $(if ($errors.Count -eq 0) {"Green"} else {"Red"})
        
        if ($optimizations.Count -gt 0) {
            Write-Host "`n  ✅ Successful Optimizations:" -ForegroundColor Green
            foreach ($opt in $optimizations) {
                Write-Host "    • $opt" -ForegroundColor Green
            }
        }
        
        if ($errors.Count -gt 0) {
            Write-Host "`n  ❌ Issues Requiring Attention:" -ForegroundColor Red
            foreach ($error in $errors) {
                Write-Host "    • $error" -ForegroundColor Red
            }
        }
        
        return $score
    }
    catch {
        Write-Host "  ❌ Cannot generate security score" -ForegroundColor Red
        return 0
    }
}

# Main execution
try {
    $initialStatus = Test-DefenderStatus
    Test-DefenderComponents
    Enable-DefenderOptimalSettings
    Update-DefenderSignatures
    Configure-DefenderExclusions
    Enable-DefenderFirewall
    Get-DefenderThreatHistory
    Start-DefenderScan
    
    $finalScore = Generate-SecurityScoreReport
    
    # Generate comprehensive report
    $reportPath = "$env:USERPROFILE\Desktop\Defender_Optimization_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $report = @"
MICROSOFT DEFENDER SECURITY OPTIMIZATION REPORT
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $env:COMPUTERNAME
User: $env:USERNAME

SECURITY SCORE: $finalScore/100

OPTIMIZATIONS APPLIED ($($optimizations.Count)):
$(foreach ($opt in $optimizations) { "✅ $opt" })

ISSUES IDENTIFIED ($($errors.Count)):
$(foreach ($error in $errors) { "❌ $error" })

RECOMMENDATIONS:
• Run this script as Administrator for full optimization
• Schedule regular full system scans
• Keep Windows and Defender signatures updated
• Review and minimize security exclusions
• Enable all firewall profiles
• Configure advanced threat protection features

STATUS: $(if ($finalScore -ge 80) { "EXCELLENT SECURITY" } elseif ($finalScore -ge 60) { "GOOD SECURITY" } else { "NEEDS IMPROVEMENT" })

Report generated by IT Toolkit Defender Optimizer
"@

    Set-Content -Path $reportPath -Value $report
    Write-Host "`n📄 Optimization report saved to: $reportPath" -ForegroundColor Yellow
    
} catch {
    Write-Host "`n❌ Critical error during optimization: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n⚡ Microsoft Defender optimization completed!" -ForegroundColor Green
Write-Host "💡 For maximum security, restart your computer and run as Administrator" -ForegroundColor Cyan
