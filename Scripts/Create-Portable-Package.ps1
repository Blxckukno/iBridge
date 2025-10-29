# Create Portable USB Package
# This script creates a complete portable package that can be copied anywhere

$SourcePath = "c:\Users\Lwandile Gasela\iBridge\Scripts"
$DestinationPath = "D:\iBridge Portable Setup"

Write-Host "Creating Portable USB Package..." -ForegroundColor Green
Write-Host "Source: $SourcePath" -ForegroundColor Cyan  
Write-Host "Destination: $DestinationPath" -ForegroundColor Cyan
Write-Host ""

# Create destination folder
if (Test-Path $DestinationPath) {
    Write-Host "Removing existing destination..." -ForegroundColor Yellow
    Remove-Item $DestinationPath -Recurse -Force
}

New-Item $DestinationPath -ItemType Directory -Force | Out-Null
Write-Host "Created destination folder" -ForegroundColor Green

# Copy portable files
$FilesToCopy = @(
    "iBridge-Portable-Setup.ps1",
    "RUN-PORTABLE-SETUP.bat", 
    "PORTABLE-README.md"
)

foreach ($File in $FilesToCopy) {
    $SourceFile = Join-Path $SourcePath $File
    $DestFile = Join-Path $DestinationPath $File
    
    if (Test-Path $SourceFile) {
        Copy-Item $SourceFile $DestFile -Force
        Write-Host "✓ Copied: $File" -ForegroundColor Green
    } else {
        Write-Host "✗ Missing: $File" -ForegroundColor Red
    }
}

# Create Apps subfolder with sample structure
$AppsFolder = Join-Path $DestinationPath "Apps"
New-Item $AppsFolder -ItemType Directory -Force | Out-Null

# Create a sample file structure guide
$StructureGuide = @"
# Application Files Structure Guide

Place your application installer files in this folder for automatic detection.

Supported files:
* TeamViewer_Setup_x64.exe
* Tools for Office2019 TechXander/ (folder)
* 24.2.2000.exe  
* PBIDesktopSetup_x64.exe
* Teams_windows_x64.exe

Example structure:
Apps/
├── TeamViewer_Setup_x64.exe
├── 24.2.2000.exe
├── PBIDesktopSetup_x64.exe
├── Teams_windows_x64.exe
└── Tools for Office2019 TechXander/
    └── (office tools files)

Alternative: You can also place files directly in the same folder as the script.
"@

$StructureGuide | Out-File (Join-Path $AppsFolder "PLACE_APP_FILES_HERE.txt") -Encoding UTF8
Write-Host "✓ Created Apps folder with structure guide" -ForegroundColor Green

# Copy any existing application files from D: drive
$ExistingApps = @(
    "D:\TeamViewer_Setup_x64.exe",
    "D:\24.2.2000.exe", 
    "D:\PBIDesktopSetup_x64.exe",
    "D:\Teams_windows_x64.exe"
)

$CopiedApps = 0
foreach ($AppPath in $ExistingApps) {
    if (Test-Path $AppPath) {
        $FileName = Split-Path $AppPath -Leaf
        $DestAppPath = Join-Path $AppsFolder $FileName
        Copy-Item $AppPath $DestAppPath -Force
        Write-Host "✓ Copied application: $FileName" -ForegroundColor Cyan
        $CopiedApps++
    }
}

# Copy Tools for Office folder if it exists
$OfficeToolsSource = "D:\Tools for Office2019 TechXander"
if (Test-Path $OfficeToolsSource) {
    $OfficeToolsDest = Join-Path $AppsFolder "Tools for Office2019 TechXander"
    Copy-Item $OfficeToolsSource $OfficeToolsDest -Recurse -Force
    Write-Host "✓ Copied Tools for Office folder" -ForegroundColor Cyan
    $CopiedApps++
}

Write-Host ""
Write-Host "Package Creation Complete!" -ForegroundColor Green -BackgroundColor Black
Write-Host "Location: $DestinationPath" -ForegroundColor White
Write-Host "Files copied: $($FilesToCopy.Count) script files + $CopiedApps application files" -ForegroundColor Cyan
Write-Host ""
Write-Host "This package can now be copied to any USB drive or computer!" -ForegroundColor Yellow
Write-Host "To use: Run 'RUN-PORTABLE-SETUP.bat' as Administrator" -ForegroundColor Yellow
Write-Host ""

# Show final structure
Write-Host "Package Structure:" -ForegroundColor White
Get-ChildItem $DestinationPath -Recurse | ForEach-Object {
    $RelativePath = $_.FullName.Replace($DestinationPath, "")
    if ($_.PSIsContainer) {
        Write-Host "📁 $RelativePath" -ForegroundColor Blue
    } else {
        $Size = if ($_.Length -gt 1MB) { "{0:N1} MB" -f ($_.Length / 1MB) } else { "{0:N0} KB" -f ($_.Length / 1KB) }
        Write-Host "📄 $RelativePath ($Size)" -ForegroundColor Gray
    }
}
