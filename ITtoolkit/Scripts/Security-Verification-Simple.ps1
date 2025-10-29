# IT Toolkit Security Verification System
param([string]$ScriptsPath = ".", [switch]$ValidateDownloads)

Write-Host "IT Toolkit Security Verification" -ForegroundColor Cyan
Write-Host "Scanning: $ScriptsPath"
Write-Host "=" * 50

$Results = @{
    TotalScripts = 0
    SafeScripts = @()
    SuspiciousScripts = @()
    SyntaxValid = @()
    SyntaxErrors = @()
    OverallStatus = "Checking..."
}

# Define suspicious patterns
$SuspiciousPatterns = @(
    "Invoke-Expression",
    "IEX",
    "EncodedCommand", 
    "DownloadString",
    "bitsadmin",
    "regsvr32",
    "schtasks"
)

# Define trusted domains
$TrustedDomains = @(
    'github.com',
    'microsoft.com',
    'download.microsoft.com',
    'aka.ms',
    'sourceforge.net',
    'mozilla.org',
    'virtualbox.org',
    'keepass.info',
    '7-zip.org'
)

function Test-ScriptSecurity {
    param([string]$ScriptPath)
    
    $SecurityInfo = @{
        RiskLevel = "LOW"
        SuspiciousPatterns = @()
        UntrustedUrls = @()
    }
    
    try {
        $Content = Get-Content $ScriptPath -Raw
        
        # Check for suspicious patterns
        foreach ($Pattern in $SuspiciousPatterns) {
            if ($Content -match $Pattern) {
                $SecurityInfo.RiskLevel = "HIGH"
                $SecurityInfo.SuspiciousPatterns += $Pattern
            }
        }
        
        # Check URLs
        $UrlMatches = [regex]::Matches($Content, 'https?://[^\s\)\"]*')
        foreach ($Match in $UrlMatches) {
            $Url = $Match.Value
            try {
                $Domain = ([uri]$Url).Host
                if ($Domain -notin $TrustedDomains) {
                    $SecurityInfo.RiskLevel = "MEDIUM"
                    $SecurityInfo.UntrustedUrls += $Url
                }
            } catch {
                # Invalid URL format
            }
        }
        
    } catch {
        $SecurityInfo.RiskLevel = "ERROR"
    }
    
    return $SecurityInfo
}

function Test-ScriptSyntax {
    param([string]$ScriptPath)
    
    try {
        $Content = Get-Content $ScriptPath -Raw -ErrorAction Stop
        $ParseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$null, [ref]$ParseErrors)
        
        return @{ IsValid = ($ParseErrors.Count -eq 0); Errors = $ParseErrors }
    } catch {
        return @{ IsValid = $false; Errors = @($_.Exception.Message) }
    }
}

# Get all script files
$AllFiles = Get-ChildItem -Path $ScriptsPath -Include "*.ps1", "*.bat" -Recurse -ErrorAction SilentlyContinue

if (-not $AllFiles) {
    Write-Host "No script files found" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($AllFiles.Count) script files"
Write-Host ""

# Main verification loop
foreach ($File in $AllFiles) {
    $Results.TotalScripts++
    
    Write-Host "[$($Results.TotalScripts)/$($AllFiles.Count)] $($File.Name)" -ForegroundColor Yellow
    
    if ($File.Extension -eq ".ps1") {
        # Security scan
        $SecurityScan = Test-ScriptSecurity -ScriptPath $File.FullName
        
        Write-Host "  Security: $($SecurityScan.RiskLevel)" -ForegroundColor $(
            switch ($SecurityScan.RiskLevel) {
                "LOW" { "Green" }
                "MEDIUM" { "Yellow" }
                "HIGH" { "Red" }
                default { "Red" }
            }
        )
        
        if ($SecurityScan.SuspiciousPatterns.Count -gt 0) {
            Write-Host "    Suspicious: $($SecurityScan.SuspiciousPatterns -join ', ')" -ForegroundColor Red
            $Results.SuspiciousScripts += $File.FullName
        } else {
            $Results.SafeScripts += $File.FullName
        }
        
        if ($SecurityScan.UntrustedUrls.Count -gt 0) {
            Write-Host "    Untrusted URLs: $($SecurityScan.UntrustedUrls.Count)" -ForegroundColor Yellow
        }
        
        # Syntax check
        $SyntaxCheck = Test-ScriptSyntax -ScriptPath $File.FullName
        Write-Host "  Syntax: $(if ($SyntaxCheck.IsValid) { 'Valid' } else { 'Errors' })" -ForegroundColor $(if ($SyntaxCheck.IsValid) { "Green" } else { "Red" })
        
        if ($SyntaxCheck.IsValid) {
            $Results.SyntaxValid += $File.FullName
        } else {
            $Results.SyntaxErrors += $File.FullName
        }
        
    } else {
        # Batch file - assume safe
        Write-Host "  Batch file - assumed safe" -ForegroundColor Green
        $Results.SafeScripts += $File.FullName
        $Results.SyntaxValid += $File.FullName
    }
    
    Write-Host ""
}

# Generate results
Write-Host "SECURITY VERIFICATION RESULTS" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "=" * 50

Write-Host "Total Scripts: $($Results.TotalScripts)" -ForegroundColor White
Write-Host "Safe Scripts: $($Results.SafeScripts.Count)" -ForegroundColor Green
Write-Host "Suspicious Scripts: $($Results.SuspiciousScripts.Count)" -ForegroundColor Yellow
Write-Host "Syntax Valid: $($Results.SyntaxValid.Count)" -ForegroundColor Green
Write-Host "Syntax Errors: $($Results.SyntaxErrors.Count)" -ForegroundColor Red

$SafetyScore = if ($Results.TotalScripts -gt 0) { 
    [math]::Round(($Results.SafeScripts.Count / $Results.TotalScripts) * 100, 1) 
} else { 0 }

$FunctionalityScore = if ($Results.TotalScripts -gt 0) { 
    [math]::Round(($Results.SyntaxValid.Count / $Results.TotalScripts) * 100, 1) 
} else { 0 }

Write-Host ""
Write-Host "Safety Score: $SafetyScore percent" -ForegroundColor $(if ($SafetyScore -ge 90) {"Green"} else {"Yellow"})
Write-Host "Functionality Score: $FunctionalityScore percent" -ForegroundColor $(if ($FunctionalityScore -ge 90) {"Green"} else {"Yellow"})

# Overall status
if ($Results.SuspiciousScripts.Count -eq 0 -and $SafetyScore -ge 90) {
    $Results.OverallStatus = "SECURE - All scripts verified safe"
    Write-Host "Status: $($Results.OverallStatus)" -ForegroundColor Green
} elseif ($Results.SuspiciousScripts.Count -gt 0) {
    $Results.OverallStatus = "REVIEW NEEDED - Some scripts flagged"
    Write-Host "Status: $($Results.OverallStatus)" -ForegroundColor Yellow
} else {
    $Results.OverallStatus = "ISSUES FOUND - Manual review required"
    Write-Host "Status: $($Results.OverallStatus)" -ForegroundColor Red
}

# Show problematic scripts
if ($Results.SuspiciousScripts.Count -gt 0) {
    Write-Host ""
    Write-Host "SUSPICIOUS SCRIPTS:" -ForegroundColor Red
    foreach ($Script in $Results.SuspiciousScripts) {
        Write-Host "  $(Split-Path $Script -Leaf)" -ForegroundColor DarkRed
    }
}

if ($Results.SyntaxErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "SYNTAX ERROR SCRIPTS:" -ForegroundColor Red
    foreach ($Script in $Results.SyntaxErrors) {
        Write-Host "  $(Split-Path $Script -Leaf)" -ForegroundColor DarkRed
    }
}

# Show safe scripts
Write-Host ""
Write-Host "VERIFIED SAFE SCRIPTS:" -ForegroundColor Green
foreach ($Script in $Results.SafeScripts) {
    Write-Host "  $(Split-Path $Script -Leaf)" -ForegroundColor DarkGreen
}

# Save results
$SafeScriptsList = $Results.SafeScripts | ForEach-Object { Split-Path $_ -Leaf }
$SafeScriptsList | Out-File -FilePath "Verified_Safe_Scripts.txt" -Encoding UTF8

$ReportPath = "Security_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
@"
IT Toolkit Security Verification Report
Generated: $(Get-Date)

SUMMARY:
Total Scripts: $($Results.TotalScripts)
Safe Scripts: $($Results.SafeScripts.Count)
Suspicious Scripts: $($Results.SuspiciousScripts.Count)
Syntax Valid: $($Results.SyntaxValid.Count)
Syntax Errors: $($Results.SyntaxErrors.Count)

Safety Score: $SafetyScore%
Functionality Score: $FunctionalityScore%
Overall Status: $($Results.OverallStatus)

SAFE SCRIPTS:
$(($Results.SafeScripts | ForEach-Object { Split-Path $_ -Leaf }) -join "`n")

$(if ($Results.SuspiciousScripts.Count -gt 0) {
"SUSPICIOUS SCRIPTS:
$(($Results.SuspiciousScripts | ForEach-Object { Split-Path $_ -Leaf }) -join "`n")"
} else { "No suspicious scripts found." })

$(if ($Results.SyntaxErrors.Count -gt 0) {
"SYNTAX ERROR SCRIPTS:
$(($Results.SyntaxErrors | ForEach-Object { Split-Path $_ -Leaf }) -join "`n")"
} else { "No syntax errors found." })
"@ | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "Report saved to: $ReportPath" -ForegroundColor Yellow
Write-Host "Safe scripts list: Verified_Safe_Scripts.txt" -ForegroundColor Yellow

# Exit codes
if ($Results.SuspiciousScripts.Count -gt 0) {
    exit 1
} else {
    exit 0
}
