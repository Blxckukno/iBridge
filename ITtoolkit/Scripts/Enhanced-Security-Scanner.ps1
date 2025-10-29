# Enhanced IT Toolkit Security Scanner with Deep Analysis
param(
    [switch]$DryRun = $false,
    [switch]$DeepScan = $true,
    [switch]$QuarantineSuspicious = $false
)

$ToolkitPath = "c:\Users\Lwandile Gasela\iBridge\ITtoolkit"
$ReportPath = "$ToolkitPath\Reports\Enhanced_Security_Scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Import our license database
if (Test-Path "$ToolkitPath\Scripts\Modules\License-Database.psm1") {
    Import-Module "$ToolkitPath\Scripts\Modules\License-Database.psm1" -Force
}

Write-Host "🔒 Enhanced IT Toolkit Security Scanner" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Check Windows Defender status
$DefenderStatus = "Unknown"
try {
    if (Get-Command "Get-MpComputerStatus" -ErrorAction SilentlyContinue) {
        $DefenderInfo = Get-MpComputerStatus
        $DefenderStatus = if ($DefenderInfo.RealTimeProtectionEnabled) { "Active" } else { "Inactive" }
    }
}
catch {
    $DefenderStatus = "Not Available"
}

Write-Host "🛡️  Windows Defender Status: $DefenderStatus" -ForegroundColor $(if($DefenderStatus -eq "Active"){"Green"}else{"Red"})

$Report = @()
$Report += "Enhanced IT Toolkit Security Scan Report"
$Report += "Generated: $(Get-Date)"
$Report += "Windows Defender Status: $DefenderStatus"
$Report += "Deep Scan: $DeepScan"
$Report += "=" * 50
$Report += ""

# Scan all files
$AllFiles = Get-ChildItem -Path "$ToolkitPath\Freeware" -Recurse -File -ErrorAction SilentlyContinue
$Results = @{
    "Safe" = @()
    "Suspicious" = @()
    "Trial" = @()
    "Freemium" = @()
    "Free" = @()
    "Malicious" = @()
}

Write-Host "🔍 Analyzing $($AllFiles.Count) files..." -ForegroundColor Yellow

foreach ($File in $AllFiles) {
    $Progress = [math]::Round(($AllFiles.IndexOf($File) / $AllFiles.Count) * 100, 1)
    Write-Progress -Activity "Security Analysis" -Status "Scanning: $($File.Name)" -PercentComplete $Progress
    
    $Analysis = [PSCustomObject]@{
        Name = $File.Name
        FullPath = $File.FullPath
        Directory = $File.Directory.Name
        Size = $File.Length
        SizeMB = [math]::Round($File.Length / 1MB, 2)
        Extension = $File.Extension
        License = "Unknown"
        LicenseCategory = "Unknown"
        SecurityStatus = "Safe"
        DigitalSignature = "Not Checked"
        Hash = ""
        Threats = @()
        LastModified = $File.LastWriteTime
    }

    # Get license information using our enhanced database
    if (Get-Command "Get-LicenseType" -ErrorAction SilentlyContinue) {
        $LicenseInfo = Get-LicenseType -FileName $File.Name
        $Analysis.License = $LicenseInfo.License
        $Analysis.LicenseCategory = $LicenseInfo.Category
    }

    # Security checks
    $SecurityIssues = @()

    # 1. Check file size anomalies
    if ($File.Extension -eq ".exe" -and $File.Length -lt 5KB) {
        $SecurityIssues += "Suspiciously small executable"
    }
    if ($File.Length -gt 1GB -and $File.Extension -in @(".exe", ".msi")) {
        $SecurityIssues += "Unusually large installer"
    }

    # 2. Check suspicious naming patterns
    $SuspiciousNames = @("crack", "keygen", "patch", "serial", "activator", "loader")
    foreach ($SuspiciousName in $SuspiciousNames) {
        if ($File.Name -like "*$SuspiciousName*") {
            $SecurityIssues += "Suspicious filename contains: $SuspiciousName"
        }
    }

    # 3. Check digital signature (if DeepScan enabled)
    if ($DeepScan -and $File.Extension -in @(".exe", ".msi", ".dll")) {
        try {
            $Signature = Get-AuthenticodeSignature -FilePath $File.FullPath -ErrorAction SilentlyContinue
            if ($Signature) {
                $Analysis.DigitalSignature = $Signature.Status
                if ($Signature.Status -notin @("Valid", "NotSigned")) {
                    $SecurityIssues += "Invalid digital signature: $($Signature.Status)"
                }
                elseif ($Signature.Status -eq "NotSigned" -and $File.Length -gt 1MB) {
                    $SecurityIssues += "Large unsigned executable"
                }
            }
        }
        catch {
            $Analysis.DigitalSignature = "Error checking signature"
        }
    }

    # 4. Calculate file hash for suspicious files
    if ($SecurityIssues.Count -gt 0 -or $DeepScan) {
        try {
            $Hash = Get-FileHash -Path $File.FullPath -Algorithm SHA256 -ErrorAction SilentlyContinue
            if ($Hash) {
                $Analysis.Hash = $Hash.Hash
            }
        }
        catch {
            # Hash calculation failed
        }
    }

    # 5. Check against known trial software
    if ($Analysis.LicenseCategory -eq "Trial") {
        $SecurityIssues += "Trial software - limited time usage"
    }

    $Analysis.Threats = $SecurityIssues

    # Categorize results
    if ($SecurityIssues.Count -eq 0) {
        $Analysis.SecurityStatus = "Safe"
        if ($Analysis.LicenseCategory -eq "Free") {
            $Results["Free"] += $Analysis
        }
        elseif ($Analysis.LicenseCategory -eq "Freemium") {
            $Results["Freemium"] += $Analysis
        }
        else {
            $Results["Safe"] += $Analysis
        }
    }
    elseif ($SecurityIssues.Count -eq 1 -and $SecurityIssues[0] -like "*Trial*") {
        $Analysis.SecurityStatus = "Trial"
        $Results["Trial"] += $Analysis
    }
    elseif ($SecurityIssues.Count -le 2) {
        $Analysis.SecurityStatus = "Suspicious"
        $Results["Suspicious"] += $Analysis
    }
    else {
        $Analysis.SecurityStatus = "Potentially Malicious"
        $Results["Malicious"] += $Analysis
    }
}

Write-Progress -Activity "Security Analysis" -Completed

# Generate detailed report
Write-Host ""
Write-Host "📊 SECURITY ANALYSIS RESULTS:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

foreach ($Category in @("Free", "Freemium", "Safe", "Trial", "Suspicious", "Malicious")) {
    $Count = $Results[$Category].Count
    $Color = switch ($Category) {
        "Free" { "Green" }
        "Freemium" { "Yellow" }
        "Safe" { "Green" }
        "Trial" { "Yellow" }
        "Suspicious" { "Red" }
        "Malicious" { "Red" }
    }
    
    Write-Host "$(switch($Category){'Free'{'💚'};'Freemium'{'💛'};'Safe'{'✅'};'Trial'{'⏰'};'Suspicious'{'⚠️ '};'Malicious'{'❌'}}) $Category Files: $Count" -ForegroundColor $Color
    
    if ($Count -gt 0) {
        $Report += "$Category FILES ($Count):"
        foreach ($File in $Results[$Category]) {
            $ThreatText = if ($File.Threats.Count -gt 0) { " [" + ($File.Threats -join ", ") + "]" } else { "" }
            Write-Host "   • $($File.Name) ($($File.SizeMB) MB)$ThreatText" -ForegroundColor Gray
            $Report += "   • $($File.Name) ($($File.SizeMB) MB) - License: $($File.License)"
            if ($File.Threats.Count -gt 0) {
                $Report += "     Threats: $($File.Threats -join ', ')"
            }
            if ($File.Hash) {
                $Report += "     SHA256: $($File.Hash)"
            }
        }
        $Report += ""
    }
}

# Create organized directory structure
Write-Host ""
Write-Host "📁 Creating organized structure..." -ForegroundColor Cyan

$OrganizedPath = "$ToolkitPath\Organized"
$Directories = @{
    "01_Verified_Free" = $Results["Free"]
    "02_Freemium_Apps" = $Results["Freemium"] 
    "03_Safe_Unknown" = $Results["Safe"]
    "04_Trial_Software" = $Results["Trial"]
    "Quarantine\Suspicious" = $Results["Suspicious"]
    "Quarantine\Malicious" = $Results["Malicious"]
}

foreach ($DirName in $Directories.Keys) {
    $TargetDir = "$OrganizedPath\$DirName"
    if ($Directories[$DirName].Count -gt 0) {
        if (!(Test-Path $TargetDir)) {
            if (!$DryRun) {
                New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
                Write-Host "✅ Created: $DirName" -ForegroundColor Green
            }
            else {
                Write-Host "🔍 Would create: $DirName" -ForegroundColor Yellow
            }
        }
    }
}

# Handle suspicious/malicious files
$QuarantineCount = $Results["Suspicious"].Count + $Results["Malicious"].Count
if ($QuarantineCount -gt 0) {
    Write-Host ""
    Write-Host "🚨 SECURITY ALERT: $QuarantineCount potentially dangerous files found!" -ForegroundColor Red
    
    if ($QuarantineSuspicious -and !$DryRun) {
        $QuarantineDir = "$ToolkitPath\Quarantine"
        if (!(Test-Path $QuarantineDir)) {
            New-Item -Path $QuarantineDir -ItemType Directory -Force | Out-Null
        }
        
        foreach ($File in ($Results["Suspicious"] + $Results["Malicious"])) {
            $QuarantinePath = "$QuarantineDir\$($File.Name).quarantine"
            try {
                Move-Item -Path $File.FullPath -Destination $QuarantinePath -Force
                Write-Host "🔒 Quarantined: $($File.Name)" -ForegroundColor Red
            }
            catch {
                Write-Host "❌ Failed to quarantine: $($File.Name)" -ForegroundColor Red
            }
        }
    }
    elseif (!$QuarantineSuspicious) {
        Write-Host "   Run with -QuarantineSuspicious to automatically quarantine these files" -ForegroundColor Yellow
    }
}

# Generate summary
$TotalFiles = $AllFiles.Count
$SafeFiles = $Results["Free"].Count + $Results["Freemium"].Count + $Results["Safe"].Count
$TrialFiles = $Results["Trial"].Count
$DangerousFiles = $Results["Suspicious"].Count + $Results["Malicious"].Count

$Report += ""
$Report += "FINAL SUMMARY:"
$Report += "- Total files analyzed: $TotalFiles"
$Report += "- Safe files: $SafeFiles"
$Report += "- Trial/Limited files: $TrialFiles"
$Report += "- Suspicious/Malicious: $DangerousFiles"
$Report += "- Free software: $($Results["Free"].Count)"
$Report += "- Freemium software: $($Results["Freemium"].Count)"

# Write report
$Report | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "📈 FINAL SUMMARY:" -ForegroundColor Cyan
Write-Host "   Total Analyzed: $TotalFiles files" -ForegroundColor White
Write-Host "   ✅ Safe: $SafeFiles" -ForegroundColor Green
Write-Host "   ⏰ Trial: $TrialFiles" -ForegroundColor Yellow
Write-Host "   ⚠️  Dangerous: $DangerousFiles" -ForegroundColor Red

Write-Host ""
Write-Host "📁 Report saved: $ReportPath" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "🔄 Run without -DryRun to create organized structure" -ForegroundColor Yellow
}

# Recommendations
Write-Host ""
Write-Host "💡 RECOMMENDATIONS:" -ForegroundColor Cyan
if ($Results["Trial"].Count -gt 0) {
    Write-Host "   • Remove trial software: $($Results["Trial"].Count) items" -ForegroundColor Yellow
}
if ($QuarantineCount -gt 0) {
    Write-Host "   • Review/remove suspicious files: $QuarantineCount items" -ForegroundColor Red
}
if ($Results["Free"].Count -gt 10) {
    Write-Host "   • Great! You have $($Results["Free"].Count) verified free applications" -ForegroundColor Green
}

Write-Host "   • Keep Windows Defender updated and active" -ForegroundColor White
Write-Host "   • Run periodic scans with this tool" -ForegroundColor White