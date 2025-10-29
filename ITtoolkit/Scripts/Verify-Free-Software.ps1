# IT Toolkit Free Software Cleanup Script
# This script identifies and removes trial software, keeping only truly free applications

param(
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

$ToolkitPath = "c:\Users\Lwandile Gasela\iBridge\ITtoolkit"
$ReportPath = "$ToolkitPath\Reports\Free_Software_Cleanup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Define trial/limited software that should be removed or flagged
$TrialSoftware = @{
    "HitmanPro_x64.exe" = @{
        "Reason" = "30-day trial only, requires commercial license"
        "Category" = "Security"
        "Alternative" = "ClamAV, Malwarebytes Free"
        "Action" = "Remove"
    }
    "EmsisoftEmergencyKit.exe" = @{
        "Reason" = "Limited free version, full features require paid license"
        "Category" = "Security"
        "Alternative" = "ESET Online Scanner (web-based)"
        "Action" = "Review"
    }
    "MBSetup.exe" = @{
        "Reason" = "14-day premium trial, reverts to limited free version"
        "Category" = "Security"
        "Alternative" = "Keep if using free version only"
        "Action" = "Review"
    }
}

# Create reports directory if it doesn't exist
if (!(Test-Path "$ToolkitPath\Reports")) {
    New-Item -Path "$ToolkitPath\Reports" -ItemType Directory -Force | Out-Null
}

Write-Host "🔍 IT Toolkit Free Software Verification Started" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$Report = @()
$Report += "IT Toolkit Free Software Cleanup Report"
$Report += "Generated: $(Get-Date)"
$Report += "Mode: $(if($DryRun){'DRY RUN - No files will be modified'}else{'LIVE RUN - Files will be modified'})"
$Report += "=" * 60
$Report += ""

# Scan for trial software
$FoundTrialSoftware = @()
$AllFiles = Get-ChildItem -Path "$ToolkitPath\Freeware" -Recurse -File

Write-Host "🔍 Scanning for trial/limited software..." -ForegroundColor Yellow

foreach ($File in $AllFiles) {
    foreach ($TrialApp in $TrialSoftware.Keys) {
        if ($File.Name -eq $TrialApp) {
            $FoundTrialSoftware += [PSCustomObject]@{
                Name = $File.Name
                FullPath = $File.FullName
                Size = [math]::Round($File.Length / 1MB, 2)
                Reason = $TrialSoftware[$TrialApp].Reason
                Category = $TrialSoftware[$TrialApp].Category
                Alternative = $TrialSoftware[$TrialApp].Alternative
                Action = $TrialSoftware[$TrialApp].Action
            }
        }
    }
}

if ($FoundTrialSoftware.Count -gt 0) {
    Write-Host "⚠️  Found $($FoundTrialSoftware.Count) trial/limited software:" -ForegroundColor Red
    $Report += "TRIAL/LIMITED SOFTWARE FOUND:"
    $Report += ""
    
    foreach ($Item in $FoundTrialSoftware) {
        Write-Host "   • $($Item.Name) ($($Item.Size) MB)" -ForegroundColor Red
        Write-Host "     Reason: $($Item.Reason)" -ForegroundColor Gray
        Write-Host "     Alternative: $($Item.Alternative)" -ForegroundColor Green
        Write-Host "     Action: $($Item.Action)" -ForegroundColor Yellow
        Write-Host ""
        
        $Report += "File: $($Item.Name)"
        $Report += "Path: $($Item.FullPath)"
        $Report += "Size: $($Item.Size) MB"
        $Report += "Reason: $($Item.Reason)"
        $Report += "Alternative: $($Item.Alternative)"
        $Report += "Recommended Action: $($Item.Action)"
        $Report += "-" * 40
    }
}
else {
    Write-Host "✅ No trial software found!" -ForegroundColor Green
    $Report += "✅ NO TRIAL SOFTWARE FOUND - All software appears to be truly free"
}

# Process actions
$RemovedFiles = @()
$ReviewFiles = @()

foreach ($Item in $FoundTrialSoftware) {
    if ($Item.Action -eq "Remove") {
        if (!$DryRun) {
            try {
                Remove-Item -Path $Item.FullPath -Force
                $RemovedFiles += $Item.Name
                Write-Host "🗑️  Removed: $($Item.Name)" -ForegroundColor Red
            }
            catch {
                Write-Host "❌ Failed to remove: $($Item.Name) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "🔍 Would remove: $($Item.Name)" -ForegroundColor Yellow
        }
    }
    elseif ($Item.Action -eq "Review") {
        $ReviewFiles += $Item.Name
        Write-Host "📋 Needs review: $($Item.Name)" -ForegroundColor Yellow
    }
}

# Generate verified free software list
Write-Host "✅ Generating verified free software list..." -ForegroundColor Green

$VerifiedFree = @()
$AllRemainingFiles = Get-ChildItem -Path "$ToolkitPath\Freeware" -Recurse -File | Where-Object { 
    $_.Name -notin $FoundTrialSoftware.Name 
}

foreach ($File in $AllRemainingFiles) {
    $Category = Split-Path (Split-Path $File.FullName -Parent) -Leaf
    $VerifiedFree += [PSCustomObject]@{
        Name = $File.Name
        Category = $Category
        Size = [math]::Round($File.Length / 1MB, 2)
        Path = $File.FullName
    }
}

$Report += ""
$Report += "VERIFIED FREE SOFTWARE ($($VerifiedFree.Count) items):"
$Report += ""

$VerifiedFree | Group-Object Category | ForEach-Object {
    $Report += "$($_.Name):"
    $_.Group | ForEach-Object {
        $Report += "  • $($_.Name) ($($_.Size) MB)"
    }
    $Report += ""
}

# Summary
$Report += ""
$Report += "SUMMARY:"
$Report += "- Total files scanned: $($AllFiles.Count)"
$Report += "- Verified free software: $($VerifiedFree.Count)"
$Report += "- Trial/limited software found: $($FoundTrialSoftware.Count)"
if (!$DryRun) {
    $Report += "- Files removed: $($RemovedFiles.Count)"
    $Report += "- Files requiring review: $($ReviewFiles.Count)"
}

# Write report to file
$Report | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "  Total files scanned: $($AllFiles.Count)" -ForegroundColor White
Write-Host "  Verified free software: $($VerifiedFree.Count)" -ForegroundColor Green
Write-Host "  Trial/limited software: $($FoundTrialSoftware.Count)" -ForegroundColor Red
if (!$DryRun -and $RemovedFiles.Count -gt 0) {
    Write-Host "  Files removed: $($RemovedFiles.Count)" -ForegroundColor Red
}
if ($ReviewFiles.Count -gt 0) {
    Write-Host "  Files needing review: $($ReviewFiles.Count)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📁 Full report saved to: $ReportPath" -ForegroundColor Cyan

# Recommendations
Write-Host ""
Write-Host "💡 Recommendations:" -ForegroundColor Cyan
Write-Host "1. Update Software_Versions.csv to remove deleted items" -ForegroundColor White
Write-Host "2. Consider adding these verified free alternatives:" -ForegroundColor White
Write-Host "   • ClamAV (Full antivirus solution)" -ForegroundColor Green
Write-Host "   • Malwarebytes Free (Anti-malware)" -ForegroundColor Green
Write-Host "   • ESET Online Scanner (On-demand scanning)" -ForegroundColor Green
Write-Host "3. Review licensing terms for flagged software" -ForegroundColor White

if ($DryRun) {
    Write-Host ""
    Write-Host "🔄 To execute changes, run this script without the -DryRun parameter" -ForegroundColor Yellow
}