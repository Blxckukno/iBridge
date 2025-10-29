# Backup-and-Cleanup.ps1
# 1. Copy files to OneDrive
# 2. Remove old files from local device
# 3. Clean up duplicates and orphaned apps
# 4. Run BleachBit for deep cleanup
# Run in an elevated PowerShell prompt

param(
    [string]$OneDrivePath = "$env:USERPROFILE\OneDrive",
    [int]$OldFilesDays = 180  # Files older than 6 months
)

$toolkitRoot = "$PSScriptRoot\..\.."
$bleachBitZip = "$toolkitRoot\Freeware\03_System_Utilities\BleachBit-4.6.0-portable.zip"
$extractPath = "C:\Tools\BleachBit"

Write-Host "=== Backup to OneDrive and Cleanup ===" -ForegroundColor Cyan
Write-Host "OneDrive Path: $OneDrivePath" -ForegroundColor Yellow
Write-Host "Files older than $OldFilesDays days will be moved to OneDrive" -ForegroundColor Yellow

# Check if OneDrive is available
if (!(Test-Path $OneDrivePath)) {
    Write-Error "OneDrive path not found: $OneDrivePath"
    Write-Host "Please ensure OneDrive is set up and syncing" -ForegroundColor Red
    exit 1
}

# Create backup folders in OneDrive
$backupDate = Get-Date -Format "yyyy-MM-dd"
$backupFolder = "$OneDrivePath\Backup_$backupDate"
$documentsBackup = "$backupFolder\Documents"
$desktopBackup = "$backupFolder\Desktop"
$downloadsBackup = "$backupFolder\Downloads"
$picturesBackup = "$backupFolder\Pictures"

Write-Host "Creating backup folders..." -ForegroundColor Green
New-Item -ItemType Directory -Path $documentsBackup -Force | Out-Null
New-Item -ItemType Directory -Path $desktopBackup -Force | Out-Null
New-Item -ItemType Directory -Path $downloadsBackup -Force | Out-Null
New-Item -ItemType Directory -Path $picturesBackup -Force | Out-Null

# Function to copy old files to OneDrive
function Copy-OldFiles {
    param($SourcePath, $DestinationPath, $Days)
    
    if (Test-Path $SourcePath) {
        Write-Host "Processing: $SourcePath" -ForegroundColor Cyan
        $oldFiles = Get-ChildItem -Path $SourcePath -Recurse -File | Where-Object { 
            $_.LastWriteTime -lt (Get-Date).AddDays(-$Days) -and 
            $_.Extension -notmatch '\.(exe|msi|dll|sys)$'  # Exclude system files
        }
        
        foreach ($file in $oldFiles) {
            try {
                $relativePath = $file.FullName.Substring($SourcePath.Length + 1)
                $destFile = Join-Path $DestinationPath $relativePath
                $destDir = Split-Path $destFile -Parent
                
                if (!(Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                
                Copy-Item -Path $file.FullName -Destination $destFile -Force
                Write-Host "Copied: $relativePath" -ForegroundColor Gray
            } catch {
                Write-Warning "Failed to copy: $($file.FullName)"
            }
        }
        return $oldFiles.Count
    }
    return 0
}

# Backup old files to OneDrive
Write-Host "`n=== Step 1: Backing up old files to OneDrive ===" -ForegroundColor Green
$documentsCount = Copy-OldFiles "$env:USERPROFILE\Documents" $documentsBackup $OldFilesDays
$desktopCount = Copy-OldFiles "$env:USERPROFILE\Desktop" $desktopBackup $OldFilesDays
$downloadsCount = Copy-OldFiles "$env:USERPROFILE\Downloads" $downloadsBackup $OldFilesDays
$picturesCount = Copy-OldFiles "$env:USERPROFILE\Pictures" $picturesBackup $OldFilesDays

Write-Host "`nBackup Summary:" -ForegroundColor Yellow
Write-Host "Documents: $documentsCount files" -ForegroundColor White
Write-Host "Desktop: $desktopCount files" -ForegroundColor White
Write-Host "Downloads: $downloadsCount files" -ForegroundColor White
Write-Host "Pictures: $picturesCount files" -ForegroundColor White

# Wait for OneDrive sync
Write-Host "`nWaiting 30 seconds for OneDrive sync..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Remove old files from local device (after backup)
Write-Host "`n=== Step 2: Removing old files from local device ===" -ForegroundColor Green
function Remove-OldFiles {
    param($SourcePath, $Days)
    
    if (Test-Path $SourcePath) {
        $oldFiles = Get-ChildItem -Path $SourcePath -Recurse -File | Where-Object { 
            $_.LastWriteTime -lt (Get-Date).AddDays(-$Days) -and 
            $_.Extension -notmatch '\.(exe|msi|dll|sys)$'
        }
        
        foreach ($file in $oldFiles) {
            try {
                Remove-Item -Path $file.FullName -Force
                Write-Host "Removed: $($file.Name)" -ForegroundColor Gray
            } catch {
                Write-Warning "Failed to remove: $($file.FullName)"
            }
        }
        return $oldFiles.Count
    }
    return 0
}

$removedDocs = Remove-OldFiles "$env:USERPROFILE\Documents" $OldFilesDays
$removedDesktop = Remove-OldFiles "$env:USERPROFILE\Desktop" $OldFilesDays
$removedDownloads = Remove-OldFiles "$env:USERPROFILE\Downloads" $OldFilesDays

Write-Host "`nRemoved files: $($removedDocs + $removedDesktop + $removedDownloads)" -ForegroundColor Yellow

# Remove duplicate documents
Write-Host "`n=== Step 3: Finding and removing duplicate files ===" -ForegroundColor Green
$duplicates = Get-ChildItem -Path "$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop", "$env:USERPROFILE\Downloads" -Recurse -File | 
    Group-Object -Property Length, Name | 
    Where-Object { $_.Count -gt 1 }

foreach ($group in $duplicates) {
    $files = $group.Group | Sort-Object LastWriteTime
    # Keep the newest, remove the rest
    for ($i = 0; $i -lt ($files.Count - 1); $i++) {
        try {
            Remove-Item -Path $files[$i].FullName -Force
            Write-Host "Removed duplicate: $($files[$i].Name)" -ForegroundColor Gray
        } catch {
            Write-Warning "Failed to remove duplicate: $($files[$i].FullName)"
        }
    }
}

# Clean up orphaned applications
Write-Host "`n=== Step 4: Cleaning up orphaned applications ===" -ForegroundColor Green
Write-Host "Running Windows built-in cleanup..." -ForegroundColor Cyan

# Clean temporary files
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clean Windows Update cache
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service -Name wuauserv -ErrorAction SilentlyContinue

# Extract and run BleachBit
Write-Host "`n=== Step 5: Running BleachBit for deep cleanup ===" -ForegroundColor Green
if (!(Test-Path "$extractPath\bleachbit.exe")) {
    Write-Host "Extracting BleachBit..." -ForegroundColor Yellow
    if (Test-Path $bleachBitZip) {
        New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        Expand-Archive -Path $bleachBitZip -DestinationPath $extractPath -Force
        Write-Host "BleachBit extracted to $extractPath" -ForegroundColor Green
    } else {
        Write-Warning "BleachBit zip file not found, skipping deep cleanup"
    }
}

if (Test-Path "$extractPath\bleachbit.exe") {
    Write-Host "Starting BleachBit for final cleanup..." -ForegroundColor Green
    Start-Process -FilePath "$extractPath\bleachbit.exe"
    Write-Host "BleachBit started. Recommended cleaners:" -ForegroundColor Yellow
    Write-Host "- System: Temporary files, Logs, Recycle Bin" -ForegroundColor White
    Write-Host "- Applications: Browser cache, Adobe Flash, Office temporary files" -ForegroundColor White
}

Write-Host "`n=== Cleanup Complete! ===" -ForegroundColor Green
Write-Host "Files backed up to: $backupFolder" -ForegroundColor Cyan
Write-Host "Old files removed from local device" -ForegroundColor Cyan
Write-Host "Duplicates cleaned up" -ForegroundColor Cyan
Write-Host "System temporary files cleaned" -ForegroundColor Cyan
Write-Host "`nDon't forget to empty Recycle Bin and run BleachBit!" -ForegroundColor Yellow
