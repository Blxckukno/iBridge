# Comprehensive Trial Software Detection & Removal Script
param(
    [switch]$DryRun = $false,
    [switch]$Force = $false
)

$ToolkitPath = "c:\Users\Lwandile Gasela\iBridge\ITtoolkit"
$ReportPath = "$ToolkitPath\Reports\Trial_Software_Removal_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Comprehensive database of known trial software
$TrialSoftwareDatabase = @{
    # Security Software Trials
    "HitmanPro" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Security" }
    "Norton" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Security" }
    "McAfee" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Security" }
    "Kaspersky" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Security" }
    "Bitdefender" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Security" }
    "ESET" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Security" }
    "Avast" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Security" }
    "AVG" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Security" }
    "Trend" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Security" }
    "Sophos" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Security" }
    "F-Secure" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Security" }
    
    # Backup Software Trials
    "Acronis" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Backup" }
    "Carbonite" = @{ "Type" = "Trial"; "Duration" = "15 days"; "Category" = "Backup" }
    "IDrive" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Backup" }
    "Backblaze" = @{ "Type" = "Trial"; "Duration" = "15 days"; "Category" = "Backup" }
    "SpiderOak" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Backup" }
    
    # System Utilities Trials
    "CCleaner" = @{ "Type" = "Trial"; "Duration" = "14 days"; "Category" = "Utilities" }
    "Advanced SystemCare" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Utilities" }
    "IObit" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Utilities" }
    "Auslogics" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Utilities" }
    "Glary" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Utilities" }
    "Wise" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Utilities" }
    
    # Productivity Trials
    "WinRAR" = @{ "Type" = "Trial"; "Duration" = "40 days"; "Category" = "Productivity" }
    "WinZip" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Productivity" }
    "Office" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Productivity" }
    "Adobe" = @{ "Type" = "Trial"; "Duration" = "7 days"; "Category" = "Productivity" }
    "Corel" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Productivity" }
    
    # Remote Access Trials
    "TeamViewer" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Remote" }
    "LogMeIn" = @{ "Type" = "Trial"; "Duration" = "14 days"; "Category" = "Remote" }
    "GoToMyPC" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Remote" }
    "AnyDesk" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Remote" }
    
    # Monitoring Trials
    "PRTG" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Monitoring" }
    "SolarWinds" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Monitoring" }
    "ManageEngine" = @{ "Type" = "Trial"; "Duration" = "30 days"; "Category" = "Monitoring" }
}

# Keywords that indicate trial software
$TrialKeywords = @(
    "trial", "demo", "evaluation", "eval", "30day", "30-day", "preview", 
    "beta", "rc", "candidate", "test", "temp", "limited", "expire"
)

Write-Host "🔍 Comprehensive Trial Software Detection & Removal" -ForegroundColor Red
Write-Host "=================================================" -ForegroundColor Red

$Report = @()
$Report += "Comprehensive Trial Software Detection & Removal Report"
$Report += "Generated: $(Get-Date)"
$Report += "Mode: $(if($DryRun){'DRY RUN - No files will be modified'}else{'LIVE RUN - Files will be modified'})"
$Report += "=" * 60
$Report += ""

# Scan all directories for potential trial software
$SearchPaths = @(
    "$ToolkitPath\Freeware",
    "$ToolkitPath\Paid", 
    "$ToolkitPath\FOSS_Enterprise_Stack"
)

$FoundTrialSoftware = @()
$TotalFilesScanned = 0

foreach ($SearchPath in $SearchPaths) {
    if (Test-Path $SearchPath) {
        Write-Host "🔍 Scanning: $SearchPath" -ForegroundColor Yellow
        
        $Files = Get-ChildItem -Path $SearchPath -Recurse -File -ErrorAction SilentlyContinue
        $TotalFilesScanned += $Files.Count
        
        foreach ($File in $Files) {
            $IsTrialSoftware = $false
            $TrialReason = ""
            $TrialInfo = $null
            
            # Check against known trial software database
            foreach ($TrialName in $TrialSoftwareDatabase.Keys) {
                if ($File.Name -like "*$TrialName*" -or $File.BaseName -like "*$TrialName*") {
                    $IsTrialSoftware = $true
                    $TrialInfo = $TrialSoftwareDatabase[$TrialName]
                    $TrialReason = "Known trial software: $TrialName ($($TrialInfo.Duration) $($TrialInfo.Type))"
                    break
                }
            }
            
            # Check for trial keywords in filename
            if (!$IsTrialSoftware) {
                foreach ($Keyword in $TrialKeywords) {
                    if ($File.Name -like "*$Keyword*" -or $File.BaseName -like "*$Keyword*") {
                        $IsTrialSoftware = $true
                        $TrialReason = "Suspicious filename contains trial keyword: $Keyword"
                        break
                    }
                }
            }
            
            # Check file properties for trial indicators
            if (!$IsTrialSoftware -and $File.Extension -in @(".exe", ".msi")) {
                try {
                    $FileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($File.FullName)
                    $ProductName = $FileVersion.ProductName
                    $Description = $FileVersion.FileDescription
                    
                    if ($ProductName -or $Description) {
                        foreach ($Keyword in $TrialKeywords) {
                            if ($ProductName -like "*$Keyword*" -or $Description -like "*$Keyword*") {
                                $IsTrialSoftware = $true
                                $TrialReason = "File metadata contains trial indicator: $Keyword"
                                break
                            }
                        }
                    }
                }
                catch {
                    # Unable to read file version info
                }
            }
            
            if ($IsTrialSoftware) {
                $TrialFile = [PSCustomObject]@{
                    Name = $File.Name
                    FullPath = $File.FullName
                    Directory = $File.Directory.Name
                    SizeMB = [math]::Round($File.Length / 1MB, 2)
                    Reason = $TrialReason
                    Category = if($TrialInfo) { $TrialInfo.Category } else { "Unknown" }
                    LastModified = $File.LastWriteTime
                }
                
                $FoundTrialSoftware += $TrialFile
                Write-Host "⚠️  Found trial software: $($File.Name)" -ForegroundColor Red
            }
        }
    }
}

# Display results
Write-Host ""
Write-Host "📊 SCAN RESULTS:" -ForegroundColor Cyan
Write-Host "Total files scanned: $TotalFilesScanned" -ForegroundColor White
Write-Host "Trial software found: $($FoundTrialSoftware.Count)" -ForegroundColor $(if($FoundTrialSoftware.Count -eq 0){"Green"}else{"Red"})

if ($FoundTrialSoftware.Count -eq 0) {
    Write-Host "✅ No trial software detected - Your toolkit is clean!" -ForegroundColor Green
    $Report += "✅ SCAN COMPLETE: No trial software found"
    $Report += "All $TotalFilesScanned files appear to be genuinely free software."
}
else {
    Write-Host ""
    Write-Host "❌ TRIAL SOFTWARE DETECTED:" -ForegroundColor Red
    
    $Report += "❌ TRIAL SOFTWARE DETECTED ($($FoundTrialSoftware.Count) files):"
    $Report += ""
    
    foreach ($Trial in $FoundTrialSoftware) {
        Write-Host "   • $($Trial.Name) ($($Trial.SizeMB) MB)" -ForegroundColor Red
        Write-Host "     Path: $($Trial.FullPath)" -ForegroundColor Gray
        Write-Host "     Reason: $($Trial.Reason)" -ForegroundColor Yellow
        Write-Host "     Category: $($Trial.Category)" -ForegroundColor Cyan
        Write-Host ""
        
        $Report += "File: $($Trial.Name)"
        $Report += "Path: $($Trial.FullPath)"
        $Report += "Size: $($Trial.SizeMB) MB"
        $Report += "Reason: $($Trial.Reason)"
        $Report += "Category: $($Trial.Category)"
        $Report += "Last Modified: $($Trial.LastModified)"
        $Report += "-" * 40
    }
    
    # Remove trial software
    if (!$DryRun) {
        Write-Host "🗑️  REMOVING TRIAL SOFTWARE..." -ForegroundColor Red
        $RemovedCount = 0
        $FailedRemovals = @()
        
        foreach ($Trial in $FoundTrialSoftware) {
            try {
                if ($Force -or (Read-Host "Remove $($Trial.Name)? (y/N)") -eq 'y') {
                    Remove-Item -Path $Trial.FullPath -Force
                    Write-Host "✅ Removed: $($Trial.Name)" -ForegroundColor Green
                    $RemovedCount++
                }
            }
            catch {
                Write-Host "❌ Failed to remove: $($Trial.Name) - $($_.Exception.Message)" -ForegroundColor Red
                $FailedRemovals += $Trial.Name
            }
        }
        
        $Report += ""
        $Report += "REMOVAL RESULTS:"
        $Report += "Successfully removed: $RemovedCount files"
        $Report += "Failed removals: $($FailedRemovals.Count) files"
        if ($FailedRemovals.Count -gt 0) {
            $Report += "Failed files: $($FailedRemovals -join ', ')"
        }
        
        Write-Host ""
        Write-Host "📊 REMOVAL SUMMARY:" -ForegroundColor Cyan
        Write-Host "✅ Successfully removed: $RemovedCount files" -ForegroundColor Green
        if ($FailedRemovals.Count -gt 0) {
            Write-Host "❌ Failed to remove: $($FailedRemovals.Count) files" -ForegroundColor Red
        }
    }
    else {
        Write-Host "🔍 DRY RUN: Would remove $($FoundTrialSoftware.Count) trial software files" -ForegroundColor Yellow
    }
}

# Update documentation
if (!$DryRun -and $FoundTrialSoftware.Count -gt 0) {
    Write-Host ""
    Write-Host "📝 Updating documentation..." -ForegroundColor Cyan
    
    # Create removal log
    $RemovalLog = "$ToolkitPath\Documentation\Trial_Software_Removal_Log.txt"
    $LogEntry = @()
    $LogEntry += "Trial Software Removal - $(Get-Date)"
    $LogEntry += "Files removed: $($FoundTrialSoftware.Count)"
    foreach ($Trial in $FoundTrialSoftware) {
        $LogEntry += "- $($Trial.Name) ($($Trial.Reason))"
    }
    $LogEntry += ""
    
    Add-Content -Path $RemovalLog -Value $LogEntry
}

# Save comprehensive report
$Report += ""
$Report += "SCAN SUMMARY:"
$Report += "- Total files scanned: $TotalFilesScanned"
$Report += "- Trial software detected: $($FoundTrialSoftware.Count)"
$Report += "- Toolkit cleanliness: $(if($FoundTrialSoftware.Count -eq 0){'100% Clean'}else{'Needs cleaning'})"

$Report | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "📁 Full report saved to: $ReportPath" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host ""
    Write-Host "🔄 To remove trial software, run: .\Remove-All-Trials.ps1 -Force" -ForegroundColor Yellow
}

# Final verification
if (!$DryRun -and $FoundTrialSoftware.Count -gt 0) {
    Write-Host ""
    Write-Host "🔄 Running verification scan..." -ForegroundColor Cyan
    
    # Quick re-scan to verify removal
    $RemainingTrials = @()
    foreach ($Trial in $FoundTrialSoftware) {
        if (Test-Path $Trial.FullPath) {
            $RemainingTrials += $Trial.Name
        }
    }
    
    if ($RemainingTrials.Count -eq 0) {
        Write-Host "✅ VERIFICATION COMPLETE: All trial software successfully removed!" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  WARNING: $($RemainingTrials.Count) trial files still present:" -ForegroundColor Red
        foreach ($Remaining in $RemainingTrials) {
            Write-Host "   • $Remaining" -ForegroundColor Yellow
        }
    }
}