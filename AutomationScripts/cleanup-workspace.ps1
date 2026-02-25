# iBridge Workspace Cleanup Script
# This script removes duplicate, backup, and unnecessary files while preserving core functionality

Write-Host "🧹 Starting iBridge Workspace Cleanup..." -ForegroundColor Green

# Define paths
$workspaceRoot = "c:\Users\Lwandile Gasela\iBridge"
Set-Location $workspaceRoot

# Create cleanup log
$cleanupLog = @()

# 1. Remove backup files (*.backup, *.html.backup)
Write-Host "`n📁 Removing backup files..." -ForegroundColor Yellow
$backupFiles = Get-ChildItem -Recurse -Include "*.backup", "*.html.backup" -File
foreach ($file in $backupFiles) {
    $cleanupLog += "REMOVED: $($file.FullName)"
    Remove-Item $file.FullName -Force
    Write-Host "  ✓ Removed: $($file.Name)" -ForegroundColor Gray
}

# 2. Remove enhanced versions (keeping main versions)
Write-Host "`n📁 Removing enhanced duplicates..." -ForegroundColor Yellow
$enhancedFiles = Get-ChildItem -Include "*-enhanced.html" -File
foreach ($file in $enhancedFiles) {
    $mainVersion = $file.Name -replace "-enhanced", ""
    if (Test-Path $mainVersion) {
        $cleanupLog += "REMOVED: $($file.FullName) (main version exists: $mainVersion)"
        Remove-Item $file.FullName -Force
        Write-Host "  ✓ Removed: $($file.Name) (keeping main version)" -ForegroundColor Gray
    }
}

# 3. Remove old index variations (keeping main index.html)
Write-Host "`n📁 Removing index variations..." -ForegroundColor Yellow
$indexVariations = Get-ChildItem -Include "index-*.html", "index_*.html" -File
foreach ($file in $indexVariations) {
    $cleanupLog += "REMOVED: $($file.FullName)"
    Remove-Item $file.FullName -Force
    Write-Host "  ✓ Removed: $($file.Name)" -ForegroundColor Gray
}

# 4. Remove clean versions (keeping main versions)
Write-Host "`n📁 Removing clean duplicates..." -ForegroundColor Yellow
$cleanFiles = Get-ChildItem -Include "*-clean.html" -File
foreach ($file in $cleanFiles) {
    $mainVersion = $file.Name -replace "-clean", ""
    if (Test-Path $mainVersion) {
        $cleanupLog += "REMOVED: $($file.FullName) (main version exists: $mainVersion)"
        Remove-Item $file.FullName -Force
        Write-Host "  ✓ Removed: $($file.Name) (keeping main version)" -ForegroundColor Gray
    }
}

# 5. Consolidate CSS files
Write-Host "`n📁 Organizing CSS files..." -ForegroundColor Yellow
$cssFiles = @(
    "css/accessibility.css",
    "css/analytics-styles.css", 
    "css/image-optimization.css",
    "css/mobile-responsive-styles.css",
    "css/security.css"
)

$consolidatedCSS = @"
/* iBridge Consolidated Styles - All additional CSS combined */

/* Accessibility Styles */
"@

foreach ($cssFile in $cssFiles) {
    if (Test-Path $cssFile) {
        $content = Get-Content $cssFile -Raw
        $consolidatedCSS += "`n`n/* From: $cssFile */`n$content"
        $cleanupLog += "CONSOLIDATED: $cssFile"
    }
}

# Write consolidated CSS
Set-Content -Path "css/consolidated.css" -Value $consolidatedCSS -Force
Write-Host "  ✓ Created: css/consolidated.css" -ForegroundColor Green

# Remove individual CSS files that were consolidated
foreach ($cssFile in $cssFiles) {
    if (Test-Path $cssFile) {
        Remove-Item $cssFile -Force
        Write-Host "  ✓ Removed: $cssFile (consolidated)" -ForegroundColor Gray
    }
}

# 6. Create consolidated Python security module
Write-Host "`n📁 Organizing Python security files..." -ForegroundColor Yellow

# Create security module directory
$securityDir = "security_modules"
if (!(Test-Path $securityDir)) {
    New-Item -ItemType Directory -Path $securityDir -Force
    Write-Host "  ✓ Created: $securityDir/" -ForegroundColor Green
}

# List of security Python files to consolidate
$securityFiles = @(
    "comprehensive_security_scanner.py",
    "emergency_security_patch.py", 
    "security_testing_suite.py",
    "simple_security_validation.py",
    "update_html_security.py",
    "advanced_security_fix.py",
    "advanced_security_remediation.py",
    "clean_security_validation.py"
)

$consolidatedPython = @"
#!/usr/bin/env python3
"""
iBridge Security Suite - Consolidated Security Tools
All security validation and testing functionality in one module.
"""

import sys
import os
import re
import sqlite3
import logging
from datetime import datetime

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

print("🔒 iBridge Security Suite Initialized")
print("📅 Generated:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
print("-" * 50)

"@

foreach ($pyFile in $securityFiles) {
    if (Test-Path $pyFile) {
        $content = Get-Content $pyFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($content) {
            $consolidatedPython += "`n`n# ==================== From: $pyFile ====================`n$content"
            $cleanupLog += "CONSOLIDATED: $pyFile"
            Write-Host "  ✓ Consolidated: $pyFile" -ForegroundColor Gray
        }
    }
}

# Write consolidated security module
Set-Content -Path "$securityDir/security_suite.py" -Value $consolidatedPython -Encoding UTF8 -Force
Write-Host "  ✓ Created: $securityDir/security_suite.py" -ForegroundColor Green

# Move individual security files to archive
$archiveDir = "$securityDir/archive"
if (!(Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force
}

foreach ($pyFile in $securityFiles) {
    if (Test-Path $pyFile) {
        Move-Item $pyFile "$archiveDir/" -Force
        Write-Host "  ✓ Archived: $pyFile" -ForegroundColor Gray
    }
}

# 7. Clean up PowerShell scripts
Write-Host "`n📁 Organizing PowerShell scripts..." -ForegroundColor Yellow

$scriptsToKeep = @(
    "cleanup-workspace.ps1"
)

$psScripts = Get-ChildItem -Include "*.ps1" -File | Where-Object { $_.Name -notin $scriptsToKeep }
$scriptArchiveDir = "Scripts/archive"
if (!(Test-Path $scriptArchiveDir)) {
    New-Item -ItemType Directory -Path $scriptArchiveDir -Force
}

foreach ($script in $psScripts) {
    if ($script.Name -match "^(add-|deploy-|fix-|implement-|optimize-)" -or $script.Name -match "upload|AUTO-UPLOAD") {
        Move-Item $script.FullName "$scriptArchiveDir/" -Force
        Write-Host "  ✓ Archived: $($script.Name)" -ForegroundColor Gray
        $cleanupLog += "ARCHIVED: $($script.FullName)"
    }
}

# 8. Clean up report and documentation files
Write-Host "`n📁 Organizing documentation..." -ForegroundColor Yellow

$docsToArchive = Get-ChildItem -Include "*_REPORT*", "*_STATUS*", "*_LOG*", "*.json", "*.csv" -File | Where-Object { $_.Name -match "(SECURITY|REPORT|LOG|VALIDATION)" }
$docsArchive = "Documentation/archive"
if (!(Test-Path $docsArchive)) {
    New-Item -ItemType Directory -Path $docsArchive -Force
}

foreach ($doc in $docsToArchive) {
    Move-Item $doc.FullName "$docsArchive/" -Force
    Write-Host "  ✓ Archived: $($doc.Name)" -ForegroundColor Gray
    $cleanupLog += "ARCHIVED: $($doc.FullName)"
}

# Generate cleanup summary
Write-Host "`n📊 Cleanup Summary:" -ForegroundColor Green
Write-Host "  • Files processed: $($cleanupLog.Count)" -ForegroundColor White
Write-Host "  • CSS files consolidated: css/consolidated.css" -ForegroundColor White  
Write-Host "  • Python security suite: $securityDir/security_suite.py" -ForegroundColor White
Write-Host "  • Scripts archived: $scriptArchiveDir/" -ForegroundColor White
Write-Host "  • Docs archived: $docsArchive/" -ForegroundColor White

# Save cleanup log
$cleanupLog | Out-File "cleanup-log.txt" -Force
Write-Host "`n✅ Cleanup complete! Log saved to cleanup-log.txt" -ForegroundColor Green
Write-Host "🚀 Workspace is now organized and ready for deployment!" -ForegroundColor Green