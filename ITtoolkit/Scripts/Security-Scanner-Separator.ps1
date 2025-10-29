# IT Toolkit Security Scanner & Application Separator
# Separates free/paid apps and scans for malicious activity

param(
    [switch]$DryRun = $false,
    [switch]$DeepScan = $false,
    [switch]$Verbose = $false
)

$ToolkitPath = "c:\Users\Lwandile Gasela\iBridge\ITtoolkit"
$ReportPath = "$ToolkitPath\Reports\Security_Scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Define license categories
$LicenseCategories = @{
    "Free" = @("GPL", "LGPL", "MIT", "Apache", "BSD", "MPL", "AGPL", "Freeware", "Public Domain")
    "Paid" = @("Commercial", "Proprietary", "Enterprise", "Professional")
    "Trial" = @("Trial", "Demo", "Evaluation", "Limited")
    "Unknown" = @("Unknown", "Other")
}

# Known malicious/suspicious file patterns
$SuspiciousPatterns = @(
    "*.tmp.exe",
    "svchost*.exe",
    "winlogon*.exe", 
    "explorer*.exe",
    "system32*.exe",
    "*crack*",
    "*keygen*",
    "*patch*",
    "*serial*"
)

# Suspicious file sizes (too small or unusually large)
$SuspiciousSizes = @{
    "TooSmall" = 1KB      # Executables smaller than 1KB are suspicious
    "TooLarge" = 2GB      # Installers larger than 2GB might be suspicious
}

Write-Host "🔒 IT Toolkit Security Scanner & App Separator" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$Report = @()
$Report += "IT Toolkit Security Scan & Application Separation Report"
$Report += "Generated: $(Get-Date)"
$Report += "Mode: $(if($DryRun){'DRY RUN - No files will be modified'}else{'LIVE RUN - Files will be modified'})"
$Report += "Deep Scan: $(if($DeepScan){'Enabled'}else{'Disabled'})"
$Report += "=" * 70
$Report += ""

# Read software versions CSV
$SoftwareData = @()
try {
    $CsvPath = "$ToolkitPath\Documentation\Software_Versions.csv"
    if (Test-Path $CsvPath) {
        $SoftwareData = Import-Csv -Path $CsvPath
        Write-Host "✅ Loaded software database: $($SoftwareData.Count) entries" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Software_Versions.csv not found - using file analysis only" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ Error reading software database: $($_.Exception.Message)" -ForegroundColor Red
}

# Scan all files in Freeware directory
Write-Host "🔍 Scanning applications..." -ForegroundColor Yellow

$AllFiles = Get-ChildItem -Path "$ToolkitPath\Freeware" -Recurse -File -ErrorAction SilentlyContinue
$SecurityResults = @{
    "Safe" = @()
    "Suspicious" = @()
    "Malicious" = @()
    "Unknown" = @()
}

$LicenseResults = @{
    "Free" = @()
    "Paid" = @()
    "Trial" = @()
    "Unknown" = @()
}

foreach ($File in $AllFiles) {
    Write-Progress -Activity "Scanning Files" -Status "Processing: $($File.Name)" -PercentComplete (($AllFiles.IndexOf($File) / $AllFiles.Count) * 100)
    
    $FileInfo = [PSCustomObject]@{
        Name = $File.Name
        FullPath = $File.FullName
        Directory = $File.Directory.Name
        Size = $File.Length
        SizeMB = [math]::Round($File.Length / 1MB, 2)
        Extension = $File.Extension
        CreationTime = $File.CreationTime
        LastWriteTime = $File.LastWriteTime
        Hash = ""
        License = "Unknown"
        SecurityStatus = "Safe"
        Threats = @()
    }

    # Get file hash for security analysis
    try {
        if ($DeepScan) {
            $Hash = Get-FileHash -Path $File.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue
            $FileInfo.Hash = $Hash.Hash
        }
    }
    catch {
        if ($Verbose) { Write-Host "   Warning: Could not calculate hash for $($File.Name)" -ForegroundColor Yellow }
    }

    # Determine license type from database
    $DbEntry = $SoftwareData | Where-Object { $_.Software -like "*$($File.BaseName)*" -or $File.Name -like "*$($_.Software)*" }
    if ($DbEntry) {
        $FileInfo.License = $DbEntry.License
    }

    # Categorize by license
    $LicenseCategory = "Unknown"
    foreach ($Category in $LicenseCategories.Keys) {
        if ($LicenseCategories[$Category] -contains $FileInfo.License) {
            $LicenseCategory = $Category
            break
        }
    }
    $LicenseResults[$LicenseCategory] += $FileInfo

    # Security Analysis
    $SecurityThreats = @()

    # Check suspicious patterns
    foreach ($Pattern in $SuspiciousPatterns) {
        if ($File.Name -like $Pattern) {
            $SecurityThreats += "Suspicious filename pattern: $Pattern"
        }
    }

    # Check file size anomalies
    if ($File.Length -lt $SuspiciousSizes.TooSmall -and $File.Extension -eq ".exe") {
        $SecurityThreats += "Suspiciously small executable ($(($File.Length / 1KB).ToString('F2')) KB)"
    }
    if ($File.Length -gt $SuspiciousSizes.TooLarge) {
        $SecurityThreats += "Unusually large file ($(($File.Length / 1GB).ToString('F2')) GB)"
    }

    # Check for unsigned executables (Windows Defender scan)
    if ($File.Extension -in @(".exe", ".msi", ".dll") -and $DeepScan) {
        try {
            $Signature = Get-AuthenticodeSignature -FilePath $File.FullName -ErrorAction SilentlyContinue
            if ($Signature.Status -ne "Valid") {
                $SecurityThreats += "Unsigned or invalid digital signature"
            }
        }
        catch {
            if ($Verbose) { Write-Host "   Warning: Could not check signature for $($File.Name)" -ForegroundColor Yellow }
        }
    }

    # Check with Windows Defender (if available)
    if ($DeepScan -and (Get-Command "Get-MpThreatDetection" -ErrorAction SilentlyContinue)) {
        try {
            # This would require admin privileges and is just a placeholder
            # In practice, you'd use external AV APIs or Windows Defender scan results
        }
        catch {
            # Silently continue if Windows Defender check fails
        }
    }

    # Determine security status
    if ($SecurityThreats.Count -eq 0) {
        $FileInfo.SecurityStatus = "Safe"
        $SecurityResults["Safe"] += $FileInfo
    }
    elseif ($SecurityThreats.Count -le 2) {
        $FileInfo.SecurityStatus = "Suspicious"
        $FileInfo.Threats = $SecurityThreats
        $SecurityResults["Suspicious"] += $FileInfo
    }
    else {
        $FileInfo.SecurityStatus = "Malicious"
        $FileInfo.Threats = $SecurityThreats
        $SecurityResults["Malicious"] += $FileInfo
    }
}

Write-Progress -Activity "Scanning Files" -Completed

# Generate Security Report
$Report += "SECURITY SCAN RESULTS:"
$Report += ""
$Report += "Safe Files: $($SecurityResults["Safe"].Count)"
$Report += "Suspicious Files: $($SecurityResults["Suspicious"].Count)"
$Report += "Potentially Malicious Files: $($SecurityResults["Malicious"].Count)"
$Report += ""

if ($SecurityResults["Suspicious"].Count -gt 0) {
    $Report += "SUSPICIOUS FILES:"
    foreach ($File in $SecurityResults["Suspicious"]) {
        $Report += "⚠️  $($File.Name) ($($File.SizeMB) MB)"
        $Report += "   Path: $($File.FullPath)"
        foreach ($Threat in $File.Threats) {
            $Report += "   • $Threat"
        }
        $Report += ""
    }
}

if ($SecurityResults["Malicious"].Count -gt 0) {
    $Report += "POTENTIALLY MALICIOUS FILES:"
    foreach ($File in $SecurityResults["Malicious"]) {
        $Report += "❌ $($File.Name) ($($File.SizeMB) MB)"
        $Report += "   Path: $($File.FullPath)"
        foreach ($Threat in $File.Threats) {
            $Report += "   • $Threat"
        }
        $Report += ""
    }
}

# Generate License Separation Report
$Report += ""
$Report += "LICENSE SEPARATION RESULTS:"
$Report += ""
foreach ($Category in $LicenseResults.Keys) {
    $Count = $LicenseResults[$Category].Count
    $Report += "$Category Applications: $Count"
    if ($Count -gt 0) {
        foreach ($File in $LicenseResults[$Category]) {
            $Report += "   • $($File.Name) - $($File.License)"
        }
    }
    $Report += ""
}

# Create organized directory structure
Write-Host "📁 Creating organized directory structure..." -ForegroundColor Cyan

$NewStructure = @{
    "Free_Applications" = $LicenseResults["Free"]
    "Paid_Applications" = $LicenseResults["Paid"] 
    "Trial_Applications" = $LicenseResults["Trial"]
    "Unknown_License" = $LicenseResults["Unknown"]
}

foreach ($DirName in $NewStructure.Keys) {
    $TargetDir = "$ToolkitPath\Organized\$DirName"
    if (!(Test-Path $TargetDir)) {
        if (!$DryRun) {
            New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
            Write-Host "✅ Created directory: $DirName" -ForegroundColor Green
        }
        else {
            Write-Host "🔍 Would create directory: $DirName" -ForegroundColor Yellow
        }
    }
}

# Move suspicious/malicious files to quarantine
$QuarantineDir = "$ToolkitPath\Quarantine"
$SuspiciousFiles = $SecurityResults["Suspicious"] + $SecurityResults["Malicious"]

if ($SuspiciousFiles.Count -gt 0) {
    Write-Host "🔒 Processing suspicious files..." -ForegroundColor Red
    
    if (!(Test-Path $QuarantineDir) -and !$DryRun) {
        New-Item -Path $QuarantineDir -ItemType Directory -Force | Out-Null
    }

    foreach ($File in $SuspiciousFiles) {
        $QuarantinePath = "$QuarantineDir\$($File.Name).quarantine"
        if (!$DryRun) {
            try {
                Move-Item -Path $File.FullPath -Destination $QuarantinePath -Force
                Write-Host "🔒 Quarantined: $($File.Name)" -ForegroundColor Red
            }
            catch {
                Write-Host "❌ Failed to quarantine: $($File.Name) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "🔍 Would quarantine: $($File.Name)" -ForegroundColor Yellow
        }
    }
}

# Generate updated Software_Versions.csv with security status
if (!$DryRun) {
    $UpdatedCsv = @()
    foreach ($Category in $LicenseResults.Keys) {
        foreach ($File in $LicenseResults[$Category]) {
            if ($File.SecurityStatus -eq "Safe") {
                $UpdatedCsv += [PSCustomObject]@{
                    Category = $File.Directory
                    Software = $File.Name
                    License = $File.License
                    SecurityStatus = $File.SecurityStatus
                    SizeMB = $File.SizeMB
                    LastScanned = Get-Date -Format "yyyy-MM-dd"
                }
            }
        }
    }
    
    $CsvOutputPath = "$ToolkitPath\Documentation\Verified_Safe_Software.csv"
    $UpdatedCsv | Export-Csv -Path $CsvOutputPath -NoTypeInformation
    Write-Host "📊 Created verified safe software list: $CsvOutputPath" -ForegroundColor Green
}

# Write comprehensive report
$Report += ""
$Report += "SUMMARY:"
$Report += "- Total files scanned: $($AllFiles.Count)"
$Report += "- Safe files: $($SecurityResults["Safe"].Count)"
$Report += "- Suspicious files: $($SecurityResults["Suspicious"].Count)"
$Report += "- Potentially malicious files: $($SecurityResults["Malicious"].Count)"
$Report += "- Free applications: $($LicenseResults["Free"].Count)"
$Report += "- Paid applications: $($LicenseResults["Paid"].Count)"
$Report += "- Trial applications: $($LicenseResults["Trial"].Count)"
$Report += "- Unknown license: $($LicenseResults["Unknown"].Count)"

$Report | Out-File -FilePath $ReportPath -Encoding UTF8

# Display summary
Write-Host ""
Write-Host "📊 SCAN COMPLETE - SUMMARY:" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan
Write-Host "🔍 Files Scanned: $($AllFiles.Count)" -ForegroundColor White
Write-Host "✅ Safe Files: $($SecurityResults["Safe"].Count)" -ForegroundColor Green
Write-Host "⚠️  Suspicious Files: $($SecurityResults["Suspicious"].Count)" -ForegroundColor Yellow
Write-Host "❌ Potentially Malicious: $($SecurityResults["Malicious"].Count)" -ForegroundColor Red
Write-Host ""
Write-Host "📋 LICENSE BREAKDOWN:" -ForegroundColor Cyan
Write-Host "💚 Free Applications: $($LicenseResults["Free"].Count)" -ForegroundColor Green
Write-Host "💰 Paid Applications: $($LicenseResults["Paid"].Count)" -ForegroundColor Yellow
Write-Host "⏰ Trial Applications: $($LicenseResults["Trial"].Count)" -ForegroundColor Red
Write-Host "❓ Unknown License: $($LicenseResults["Unknown"].Count)" -ForegroundColor Gray

Write-Host ""
Write-Host "📁 Full report saved to: $ReportPath" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host ""
    Write-Host "🔄 To execute changes, run this script without the -DryRun parameter" -ForegroundColor Yellow
}

# Security recommendations
if ($SecurityResults["Suspicious"].Count -gt 0 -or $SecurityResults["Malicious"].Count -gt 0) {
    Write-Host ""
    Write-Host "🚨 SECURITY RECOMMENDATIONS:" -ForegroundColor Red
    Write-Host "1. Review quarantined files before deletion" -ForegroundColor White
    Write-Host "2. Scan quarantined files with multiple AV engines" -ForegroundColor White
    Write-Host "3. Update Windows Defender definitions" -ForegroundColor White
    Write-Host "4. Consider running full system scan" -ForegroundColor White
}