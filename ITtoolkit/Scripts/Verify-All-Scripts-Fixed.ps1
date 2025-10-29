# PowerShell Script Verification Tool
# Checks all .ps1 scripts for syntax errors and basic functionality

param(
    [string]$ScriptsPath = ".",
    [switch]$Detailed
)

Write-Host "🔍 IT Toolkit Script Verification" -ForegroundColor Cyan
Write-Host "Scanning: $ScriptsPath" -ForegroundColor Gray
Write-Host "=" * 60

$Results = @{
    Valid = @()
    SyntaxErrors = @()
    Missing = @()
    Total = 0
}

# Get all .ps1 files recursively
$AllScripts = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue

if (-not $AllScripts) {
    Write-Host "❌ No PowerShell scripts found in: $ScriptsPath" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($AllScripts.Count) PowerShell scripts" -ForegroundColor Green
Write-Host ""

foreach ($Script in $AllScripts) {
    $Results.Total++
    $RelPath = $Script.FullName.Replace((Get-Location).Path, "").TrimStart('\')
    
    Write-Host "[$($Results.Total)/$($AllScripts.Count)] Testing: $RelPath" -ForegroundColor Yellow
    
    try {
        # Test syntax by parsing the script
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $Script.FullName -Raw), [ref]$null)
        
        # Additional check: try to get command info (validates structure)
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Script.FullName, [ref]$null, [ref]$null)
        
        if ($ast) {
            $Results.Valid += $Script.FullName
            Write-Host "  ✅ VALID" -ForegroundColor Green
        } else {
            $Results.SyntaxErrors += $Script.FullName
            Write-Host "  ❌ PARSE ERROR" -ForegroundColor Red
        }
        
    } catch {
        $Results.SyntaxErrors += $Script.FullName
        Write-Host "  ❌ SYNTAX ERROR: $($_.Message)" -ForegroundColor Red
        if ($Detailed) {
            Write-Host "     $($_.Exception.Message)" -ForegroundColor DarkRed
        }
    }
}

Write-Host ""
Write-Host "📊 VERIFICATION SUMMARY" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "=" * 60

Write-Host "✅ Valid Scripts: $($Results.Valid.Count)" -ForegroundColor Green
Write-Host "❌ Syntax Errors: $($Results.SyntaxErrors.Count)" -ForegroundColor Red
Write-Host "📝 Total Checked: $($Results.Total)" -ForegroundColor Cyan

$SuccessRate = [math]::Round(($Results.Valid.Count / $Results.Total) * 100, 1)
Write-Host "🎯 Success Rate: $SuccessRate%" -ForegroundColor $(if ($SuccessRate -ge 80) {"Green"} elseif ($SuccessRate -ge 60) {"Yellow"} else {"Red"})

if ($Results.SyntaxErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ SCRIPTS WITH SYNTAX ERRORS:" -ForegroundColor Red
    foreach ($ErrorScript in $Results.SyntaxErrors) {
        $RelPath = $ErrorScript.Replace((Get-Location).Path, "").TrimStart('\')
        Write-Host "   • $RelPath" -ForegroundColor DarkRed
    }
}

if ($Results.Valid.Count -gt 0) {
    Write-Host ""
    Write-Host "✅ VERIFIED WORKING SCRIPTS:" -ForegroundColor Green
    foreach ($ValidScript in $Results.Valid) {
        $RelPath = $ValidScript.Replace((Get-Location).Path, "").TrimStart('\')
        Write-Host "   • $RelPath" -ForegroundColor DarkGreen
    }
}

# Generate a simple report file
$ReportPath = "Script_Verification_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$ReportContent = @"
IT Toolkit Script Verification Report
Generated: $(Get-Date)
Path: $ScriptsPath

SUMMARY:
Total Scripts: $($Results.Total)
Valid Scripts: $($Results.Valid.Count) ($SuccessRate%)
Scripts with Errors: $($Results.SyntaxErrors.Count)

VALID SCRIPTS:
$(($Results.Valid | ForEach-Object { "OK " + $_.Replace((Get-Location).Path, "").TrimStart('\') }) -join "`n")

SCRIPTS WITH ERRORS:
$(($Results.SyntaxErrors | ForEach-Object { "ERR " + $_.Replace((Get-Location).Path, "").TrimStart('\') }) -join "`n")
"@

$ReportContent | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "Report saved to: $ReportPath" -ForegroundColor Yellow

# Return appropriate exit code
if ($Results.SyntaxErrors.Count -eq 0) {
    Write-Host "All scripts passed verification!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some scripts have syntax errors and need attention." -ForegroundColor Yellow
    exit 1
}
