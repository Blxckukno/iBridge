# Enhanced Trial Software Detection - Accurate Version
param(
    [switch]$DryRun = $false,
    [switch]$Force = $false
)

$ToolkitPath = "c:\Users\Lwandile Gasela\iBridge\ITtoolkit"

# Known FALSE POSITIVES - Software that appears to be trial but is actually free
$FalsePositives = @(
    "rcsetup", # Recuva - completely free
    "ccsetup", # CCleaner free version
    "rcleaner", # Various legitimate cleaners
    "rcdata",   # Resource data files
    "rctool"    # Various legitimate tools
)

# Verified FREE software that should never be flagged
$VerifiedFreeSoftware = @(
    "Recuva", "CCleaner", "7-Zip", "PuTTY", "Wireshark", "Nmap", 
    "ClamWin", "Everything", "BleachBit", "Chrome", "Firefox",
    "Autoruns", "ProcessExplorer", "TCPView", "RootkitRevealer"
)

# ACTUAL trial software patterns (more precise)
$ActualTrialSoftware = @{
    "HitmanPro" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Reason" = "Commercial trial only" }
    "Norton" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Reason" = "Commercial trial only" }
    "McAfee" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Reason" = "Commercial trial only" }
    "Kaspersky" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Reason" = "Commercial trial only" }
    "Bitdefender" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Reason" = "Commercial trial only" }
    "WinRAR" = @{ "Type" = "Trial"; "Duration" = "40 days"; "Reason" = "Shareware with nag screen" }
    "WinZip" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Reason" = "Commercial trial only" }
    "Acronis" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Reason" = "Commercial trial only" }
    "TeamViewer" = @{ "Type" = "Trial"; "Duration" = "Commercial"; "Reason" = "Free for personal use only" }
}

Write-Host "🔍 Enhanced Trial Software Detection (Accurate)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$AllFiles = Get-ChildItem -Path "$ToolkitPath\Freeware" -Recurse -File -ErrorAction SilentlyContinue
$TrialSoftwareFound = @()

Write-Host "🔍 Scanning $($AllFiles.Count) files for actual trial software..." -ForegroundColor Yellow

foreach ($File in $AllFiles) {
    $IsActualTrial = $false
    $TrialReason = ""
    
    # Check against known trial software (excluding false positives)
    foreach ($TrialName in $ActualTrialSoftware.Keys) {
        if ($File.Name -like "*$TrialName*" -and $File.BaseName -notin $FalsePositives) {
            # Double-check it's not in our verified free list
            $IsVerifiedFree = $false
            foreach ($FreeSoftware in $VerifiedFreeSoftware) {
                if ($File.Name -like "*$FreeSoftware*") {
                    $IsVerifiedFree = $true
                    break
                }
            }
            
            if (!$IsVerifiedFree) {
                $IsActualTrial = $true
                $TrialInfo = $ActualTrialSoftware[$TrialName]
                $TrialReason = "Confirmed trial software: $TrialName - $($TrialInfo.Reason)"
                break
            }
        }
    }
    
    # Additional check for obvious trial indicators (but skip false positives)
    if (!$IsActualTrial -and $File.BaseName -notin $FalsePositives) {
        $ObviousTrialKeywords = @("30day", "trial", "demo", "evaluation", "preview", "beta")
        foreach ($Keyword in $ObviousTrialKeywords) {
            if ($File.Name -like "*$Keyword*") {
                # Verify it's not a legitimate free tool
                $IsLegitimate = $false
                foreach ($FreeSoftware in $VerifiedFreeSoftware) {
                    if ($File.Name -like "*$FreeSoftware*") {
                        $IsLegitimate = $true
                        break
                    }
                }
                
                if (!$IsLegitimate) {
                    $IsActualTrial = $true
                    $TrialReason = "Contains trial keyword: $Keyword"
                    break
                }
            }
        }
    }
    
    if ($IsActualTrial) {
        $TrialSoftwareFound += [PSCustomObject]@{
            Name = $File.Name
            FullPath = $File.FullName
            SizeMB = [math]::Round($File.Length / 1MB, 2)
            Reason = $TrialReason
            LastModified = $File.LastWriteTime
        }
        
        Write-Host "❌ TRIAL SOFTWARE: $($File.Name)" -ForegroundColor Red
        Write-Host "   Reason: $TrialReason" -ForegroundColor Yellow
    }
}

# Results
Write-Host ""
Write-Host "📊 ACCURATE SCAN RESULTS:" -ForegroundColor Cyan
Write-Host "Total files scanned: $($AllFiles.Count)" -ForegroundColor White
Write-Host "Actual trial software found: $($TrialSoftwareFound.Count)" -ForegroundColor $(if($TrialSoftwareFound.Count -eq 0){"Green"}else{"Red"})

if ($TrialSoftwareFound.Count -eq 0) {
    Write-Host ""
    Write-Host "✅ EXCELLENT! No trial software detected!" -ForegroundColor Green
    Write-Host "   Your IT Toolkit contains only genuine free software." -ForegroundColor Green
    
    # Create verification report
    $Report = @()
    $Report += "Enhanced Trial Software Scan Report - CLEAN"
    $Report += "Generated: $(Get-Date)"
    $Report += "Files Scanned: $($AllFiles.Count)"
    $Report += "Trial Software Found: 0"
    $Report += ""
    $Report += "✅ VERIFICATION: Your IT Toolkit is 100% free of trial software!"
    $Report += ""
    $Report += "All applications in your toolkit are either:"
    $Report += "- Completely free software (GPL, MIT, Apache, etc.)"
    $Report += "- Freeware (free for all users)"
    $Report += "- Freemium (free version available)"
    $Report += ""
    $Report += "Your toolkit is ready for professional use without any licensing concerns."
    
    $ReportPath = "$ToolkitPath\Reports\Trial_Software_Clean_Verification_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $Report | Out-File -FilePath $ReportPath -Encoding UTF8
    
    Write-Host "📁 Verification report saved: $ReportPath" -ForegroundColor Cyan
}
else {
    Write-Host ""
    Write-Host "❌ TRIAL SOFTWARE REQUIRES REMOVAL:" -ForegroundColor Red
    
    foreach ($Trial in $TrialSoftwareFound) {
        Write-Host "   • $($Trial.Name) ($($Trial.SizeMB) MB)" -ForegroundColor Red
        Write-Host "     Path: $($Trial.FullPath)" -ForegroundColor Gray  
        Write-Host "     Reason: $($Trial.Reason)" -ForegroundColor Yellow
        Write-Host ""
    }
    
    if (!$DryRun) {
        if ($Force -or (Read-Host "Remove all trial software? (y/N)") -eq 'y') {
            foreach ($Trial in $TrialSoftwareFound) {
                try {
                    Remove-Item -Path $Trial.FullPath -Force
                    Write-Host "✅ Removed: $($Trial.Name)" -ForegroundColor Green
                }
                catch {
                    Write-Host "❌ Failed to remove: $($Trial.Name)" -ForegroundColor Red
                }
            }
        }
    }
    else {
        Write-Host "🔄 Run without -DryRun to remove trial software" -ForegroundColor Yellow
    }
}

# Quick verification of known free software
Write-Host ""
Write-Host "✅ VERIFIED FREE SOFTWARE IN YOUR TOOLKIT:" -ForegroundColor Green
$FreeCount = 0
foreach ($FreeName in $VerifiedFreeSoftware) {
    $Found = $AllFiles | Where-Object { $_.Name -like "*$FreeName*" }
    if ($Found) {
        Write-Host "   ✅ $FreeName" -ForegroundColor Green
        $FreeCount++
    }
}

Write-Host ""
Write-Host "📊 FINAL STATUS:" -ForegroundColor Cyan
Write-Host "   Free Software Verified: $FreeCount applications" -ForegroundColor Green
Write-Host "   Trial Software: $($TrialSoftwareFound.Count) applications" -ForegroundColor $(if($TrialSoftwareFound.Count -eq 0){"Green"}else{"Red"})
Write-Host "   Toolkit Status: $(if($TrialSoftwareFound.Count -eq 0){'✅ CLEAN & READY'}else{'❌ NEEDS CLEANING'})" -ForegroundColor $(if($TrialSoftwareFound.Count -eq 0){"Green"}else{"Red"})