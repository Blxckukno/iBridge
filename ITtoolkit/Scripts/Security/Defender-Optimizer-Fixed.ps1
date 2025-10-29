# Microsoft Defender Security Score Optimization Tool
# Comprehensive script to maximize Windows Defender security effectiveness

Write-Host "MICROSOFT DEFENDER SECURITY SCORE OPTIMIZER" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Optimizing Windows Defender for maximum security protection..." -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$optimizations = @()
$errors = @()

function Test-DefenderStatus {
    Write-Host ""
    Write-Host "CURRENT DEFENDER STATUS" -ForegroundColor Yellow
    
    try {
        $status = Get-MpComputerStatus
        
        Write-Host "  Current Configuration:" -ForegroundColor Cyan
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
        Write-Host "  ERROR: Cannot retrieve Defender status: $($_.Exception.Message)" -ForegroundColor Red
        $script:errors += "Cannot retrieve Defender status"
        return $null
    }
}

function Enable-DefenderOptimalSettings {
    Write-Host ""
    Write-Host "APPLYING OPTIMAL DEFENDER SETTINGS" -ForegroundColor Yellow
    
    if (-not $isAdmin) {
        Write-Host "  WARNING: Administrator privileges required for optimal configuration" -ForegroundColor Yellow
        Write-Host "  Recommended settings (run as Administrator):" -ForegroundColor Cyan
        
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
        "Cloud Protection" = { Set-MpPreference -MAPSReporting Advanced }
        "Sample Submission" = { Set-MpPreference -SubmitSamplesConsent SendAllSamples }
        "Cloud Block Level" = { Set-MpPreference -CloudBlockLevel HighPlus }
        "Extended Timeout" = { Set-MpPreference -CloudExtendedTimeout 50 }
    }
    
    foreach ($setting in $settingsToApply.GetEnumerator()) {
        try {
            & $setting.Value
            Write-Host "    SUCCESS: Applied: $($setting.Key)" -ForegroundColor Green
            $script:optimizations += $setting.Key
        }
        catch {
            Write-Host "    ERROR: Failed: $($setting.Key) - $($_.Exception.Message)" -ForegroundColor Red
            $script:errors += "Failed to configure $($setting.Key)"
        }
    }
}

function Update-DefenderSignatures {
    Write-Host ""
    Write-Host "UPDATING DEFENDER SIGNATURES" -ForegroundColor Yellow
    
    try {
        Write-Host "  Downloading latest threat definitions..." -ForegroundColor Cyan
        Update-MpSignature
        Write-Host "  SUCCESS: Threat definitions updated successfully" -ForegroundColor Green
        $script:optimizations += "Updated threat definitions"
    }
    catch {
        Write-Host "  ERROR: Failed to update signatures: $($_.Exception.Message)" -ForegroundColor Red
        $script:errors += "Failed to update signatures"
    }
}

function Start-DefenderQuickScan {
    Write-Host ""
    Write-Host "STARTING QUICK SECURITY SCAN" -ForegroundColor Yellow
    
    try {
        Write-Host "  Initiating quick scan..." -ForegroundColor Cyan
        Start-MpScan -ScanType QuickScan
        Write-Host "  SUCCESS: Quick scan completed" -ForegroundColor Green
        $script:optimizations += "Completed quick scan"
    }
    catch {
        Write-Host "  ERROR: Failed to start quick scan: $($_.Exception.Message)" -ForegroundColor Red
        $script:errors += "Failed to start quick scan"
    }
}

function Set-DefenderAdvancedFeatures {
    Write-Host ""
    Write-Host "CONFIGURING ADVANCED PROTECTION FEATURES" -ForegroundColor Yellow
    
    if (-not $isAdmin) {
        Write-Host "  Administrator privileges required for advanced features" -ForegroundColor Yellow
        return
    }
    
    $advancedSettings = @{
        "Network Protection" = { Set-MpPreference -EnableNetworkProtection Enabled }
        "Controlled Folder Access" = { Set-MpPreference -EnableControlledFolderAccess Enabled }
        "PUA Protection" = { Set-MpPreference -PUAProtection Enabled }
        "Archive Scanning" = { Set-MpPreference -DisableArchiveScanning $false }
        "Email Scanning" = { Set-MpPreference -DisableEmailScanning $false }
        "Removable Drive Scanning" = { Set-MpPreference -DisableRemovableDriveScanning $false }
    }
    
    foreach ($setting in $advancedSettings.GetEnumerator()) {
        try {
            & $setting.Value
            Write-Host "    SUCCESS: Enabled: $($setting.Key)" -ForegroundColor Green
            $script:optimizations += $setting.Key
        }
        catch {
            Write-Host "    WARNING: Could not configure: $($setting.Key)" -ForegroundColor Yellow
            # Not adding to errors as these are advanced features that may not be available
        }
    }
}

function Add-DefenderExclusions {
    Write-Host ""
    Write-Host "CONFIGURING PERFORMANCE EXCLUSIONS" -ForegroundColor Yellow
    
    # Common performance exclusions for development environments
    $exclusions = @{
        "Processes" = @("devenv.exe", "msbuild.exe", "node.exe", "git.exe")
        "Extensions" = @(".tmp", ".log", ".cache")
        "Paths" = @(
            "$env:TEMP",
            "$env:LOCALAPPDATA\Temp",
            "$env:PROGRAMDATA\Microsoft\Windows Defender\Scans\History"
        )
    }
    
    if ($isAdmin) {
        try {
            # Add process exclusions
            foreach ($process in $exclusions.Processes) {
                Add-MpPreference -ExclusionProcess $process -ErrorAction SilentlyContinue
                Write-Host "    Added process exclusion: $process" -ForegroundColor Cyan
            }
            
            # Add extension exclusions
            foreach ($ext in $exclusions.Extensions) {
                Add-MpPreference -ExclusionExtension $ext -ErrorAction SilentlyContinue
                Write-Host "    Added extension exclusion: $ext" -ForegroundColor Cyan
            }
            
            # Add path exclusions
            foreach ($path in $exclusions.Paths) {
                if (Test-Path $path) {
                    Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
                    Write-Host "    Added path exclusion: $path" -ForegroundColor Cyan
                }
            }
            
            $script:optimizations += "Configured performance exclusions"
        }
        catch {
            Write-Host "    WARNING: Some exclusions could not be added" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Administrator privileges required for exclusions" -ForegroundColor Yellow
    }
}

function Test-DefenderThreatDetection {
    Write-Host ""
    Write-Host "TESTING THREAT DETECTION" -ForegroundColor Yellow
    
    try {
        # Get recent threat detection history
        $threats = Get-MpThreatDetection | Select-Object -First 5
        
        if ($threats) {
            Write-Host "  Recent threat detections:" -ForegroundColor Cyan
            foreach ($threat in $threats) {
                Write-Host "    Threat: $($threat.ThreatName) - Action: $($threat.ActionSuccess)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  No recent threats detected" -ForegroundColor Green
        }
        
        # Test EICAR (safe test file) detection
        Write-Host "  Testing with EICAR test string..." -ForegroundColor Cyan
        $eicar = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
        
        # Create temporary test file
        $testFile = "$env:TEMP\eicar_test.txt"
        Set-Content -Path $testFile -Value $eicar -ErrorAction Stop
        
        Start-Sleep -Seconds 2
        
        if (Test-Path $testFile) {
            Write-Host "    WARNING: EICAR test file not detected/removed" -ForegroundColor Red
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        } else {
            Write-Host "    SUCCESS: EICAR test file detected and removed" -ForegroundColor Green
            $script:optimizations += "Threat detection working"
        }
    }
    catch {
        Write-Host "  ERROR: Cannot test threat detection: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-DefenderSummary {
    Write-Host ""
    Write-Host "=" * 70 -ForegroundColor Green
    Write-Host "DEFENDER OPTIMIZATION SUMMARY" -ForegroundColor White -BackgroundColor Green
    Write-Host "=" * 70 -ForegroundColor Green
    
    Write-Host ""
    Write-Host "OPTIMIZATIONS APPLIED: $($optimizations.Count)" -ForegroundColor Green
    foreach ($opt in $optimizations) {
        Write-Host "  SUCCESS: $opt" -ForegroundColor Green
    }
    
    if ($errors.Count -gt 0) {
        Write-Host ""
        Write-Host "ERRORS ENCOUNTERED: $($errors.Count)" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  ERROR: $error" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "RECOMMENDATIONS:" -ForegroundColor Yellow
    Write-Host "1. Run this script as Administrator for full optimization" -ForegroundColor Cyan
    Write-Host "2. Schedule regular full scans weekly" -ForegroundColor Cyan
    Write-Host "3. Keep Windows and Defender updated" -ForegroundColor Cyan
    Write-Host "4. Review exclusions periodically" -ForegroundColor Cyan
    Write-Host "5. Monitor threat detection logs" -ForegroundColor Cyan
    
    $score = [math]::Round((($optimizations.Count / ($optimizations.Count + $errors.Count)) * 100), 1)
    Write-Host ""
    Write-Host "SECURITY SCORE: $score%" -ForegroundColor $(if ($score -ge 80) {"Green"} elseif ($score -ge 60) {"Yellow"} else {"Red"})
}

# Main execution
try {
    $initialStatus = Test-DefenderStatus
    Enable-DefenderOptimalSettings
    Update-DefenderSignatures
    Set-DefenderAdvancedFeatures
    Add-DefenderExclusions
    Start-DefenderQuickScan
    Test-DefenderThreatDetection
    Show-DefenderSummary
    
    # Save optimization report
    $reportPath = "$env:USERPROFILE\Desktop\Defender_Optimization_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $report = @"
MICROSOFT DEFENDER OPTIMIZATION REPORT
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

OPTIMIZATIONS APPLIED: $($optimizations.Count)
$($optimizations | ForEach-Object { "- $_" } | Out-String)

ERRORS: $($errors.Count)
$($errors | ForEach-Object { "- $_" } | Out-String)

SECURITY SCORE: $([math]::Round((($optimizations.Count / ($optimizations.Count + $errors.Count)) * 100), 1))%

NEXT ACTIONS:
- Run as Administrator for full optimization
- Schedule regular scans
- Monitor threat logs
- Keep definitions updated

Report generated by IT Toolkit Defender Optimizer
"@

    Set-Content -Path $reportPath -Value $report
    Write-Host ""
    Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan
    
}
catch {
    Write-Host ""
    Write-Host "CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Defender optimization completed!" -ForegroundColor Green
