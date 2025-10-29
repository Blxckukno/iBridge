# Analyze-Cleanup.ps1
# Analyzes what files will be moved/removed before running the full cleanup
# Safe preview mode to see what the cleanup will do

param(
    [string]$OneDrivePath = "$env:USERPROFILE\OneDrive",
    [int]$OldFilesDays = 180
)

Write-Host "=== Cleanup Analysis (Preview Mode) ===" -ForegroundColor Cyan
Write-Host "This will show what files would be moved/removed without actually doing it" -ForegroundColor Yellow

# Check OneDrive availability
if (!(Test-Path $OneDrivePath)) {
    Write-Error "OneDrive path not found: $OneDrivePath"
    exit 1
}

# Analyze function
function Analyze-OldFiles {
    param($Path, $Days)
    
    if (!(Test-Path $Path)) { return @() }
    
    $oldFiles = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | Where-Object { 
        $_.LastWriteTime -lt (Get-Date).AddDays(-$Days) -and 
        $_.Extension -notmatch '\.(exe|msi|dll|sys)$'
    }
    
    return $oldFiles
}

# Analyze duplicates
function Analyze-Duplicates {
    param($Paths)
    
    $duplicates = @()
    $allFiles = @()
    
    foreach ($path in $Paths) {
        if (Test-Path $path) {
            $allFiles += Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue
        }
    }
    
    $groups = $allFiles | Group-Object -Property Length, Name | Where-Object { $_.Count -gt 1 }
    
    foreach ($group in $groups) {
        $files = $group.Group | Sort-Object LastWriteTime
        # All but the newest are duplicates
        for ($i = 0; $i -lt ($files.Count - 1); $i++) {
            $duplicates += $files[$i]
        }
    }
    
    return $duplicates
}

# Analysis
Write-Host "`n=== Old Files Analysis ===" -ForegroundColor Green
$documentsOld = Analyze-OldFiles "$env:USERPROFILE\Documents" $OldFilesDays
$desktopOld = Analyze-OldFiles "$env:USERPROFILE\Desktop" $OldFilesDays
$downloadsOld = Analyze-OldFiles "$env:USERPROFILE\Downloads" $OldFilesDays
$picturesOld = Analyze-OldFiles "$env:USERPROFILE\Pictures" $OldFilesDays

$totalOldFiles = $documentsOld.Count + $desktopOld.Count + $downloadsOld.Count + $picturesOld.Count
$totalOldSize = ($documentsOld + $desktopOld + $downloadsOld + $picturesOld | Measure-Object -Property Length -Sum).Sum / 1GB

Write-Host "Files older than $OldFilesDays days:" -ForegroundColor Yellow
Write-Host "  Documents: $($documentsOld.Count) files" -ForegroundColor White
Write-Host "  Desktop: $($desktopOld.Count) files" -ForegroundColor White
Write-Host "  Downloads: $($downloadsOld.Count) files" -ForegroundColor White
Write-Host "  Pictures: $($picturesOld.Count) files" -ForegroundColor White
Write-Host "  Total: $totalOldFiles files ({0:N2} GB)" -f $totalOldSize -ForegroundColor Cyan

Write-Host "`n=== Duplicate Files Analysis ===" -ForegroundColor Green
$duplicateFiles = Analyze-Duplicates @("$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop", "$env:USERPROFILE\Downloads")
$duplicateSize = ($duplicateFiles | Measure-Object -Property Length -Sum).Sum / 1GB

Write-Host "Duplicate files: $($duplicateFiles.Count) files ({0:N2} GB)" -f $duplicateSize -ForegroundColor Cyan

Write-Host "`n=== Temporary Files Analysis ===" -ForegroundColor Green
$tempFiles = 0
$tempSize = 0

if (Test-Path "$env:TEMP") {
    $tempItems = Get-ChildItem -Path "$env:TEMP" -Recurse -ErrorAction SilentlyContinue
    $tempFiles += $tempItems.Count
    $tempSize += ($tempItems | Where-Object { !$_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum
}

if (Test-Path "$env:LOCALAPPDATA\Temp") {
    $localTempItems = Get-ChildItem -Path "$env:LOCALAPPDATA\Temp" -Recurse -ErrorAction SilentlyContinue
    $tempFiles += $localTempItems.Count
    $tempSize += ($localTempItems | Where-Object { !$_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum
}

Write-Host "Temporary files: $tempFiles items ({0:N2} GB)" -f ($tempSize / 1GB) -ForegroundColor Cyan

Write-Host "`n=== Total Space to Recover ===" -ForegroundColor Green
$totalRecovery = $totalOldSize + $duplicateSize + ($tempSize / 1GB)
Write-Host "Estimated space recovery: {0:N2} GB" -f $totalRecovery -ForegroundColor Yellow

Write-Host "`n=== Sample Files to be Moved ===" -ForegroundColor Green
Write-Host "Old Documents (first 10):" -ForegroundColor Yellow
$documentsOld | Select-Object -First 10 | ForEach-Object { 
    Write-Host "  $($_.Name) - $($_.LastWriteTime.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
}

Write-Host "`nDuplicate Files (first 10):" -ForegroundColor Yellow
$duplicateFiles | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.Name) - {0:N2} MB" -f ($_.Length / 1MB) -ForegroundColor Gray
}

Write-Host "`n=== Recommendations ===" -ForegroundColor Green
if ($totalRecovery -gt 5) {
    Write-Host "✓ Significant cleanup potential: {0:N2} GB" -f $totalRecovery -ForegroundColor Green
} elseif ($totalRecovery -gt 1) {
    Write-Host "○ Moderate cleanup potential: {0:N2} GB" -f $totalRecovery -ForegroundColor Yellow
} else {
    Write-Host "○ Limited cleanup potential: {0:N2} GB" -f $totalRecovery -ForegroundColor Yellow
}

Write-Host "`nTo proceed with actual cleanup, run:" -ForegroundColor Cyan
Write-Host "  .\Scripts\Maintenance_Cleanup\Backup-and-Cleanup.ps1" -ForegroundColor White
