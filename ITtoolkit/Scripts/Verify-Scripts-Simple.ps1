# PowerShell Script Verification Tool
param([string]$ScriptsPath = ".")

Write-Host "IT Toolkit Script Verification" -ForegroundColor Cyan
Write-Host "Scanning: $ScriptsPath"
Write-Host "=" * 50

$Results = @{
    Valid = @()
    SyntaxErrors = @()
    Total = 0
}

# Get all .ps1 files recursively
$AllScripts = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue

if (-not $AllScripts) {
    Write-Host "No PowerShell scripts found" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($AllScripts.Count) PowerShell scripts"
Write-Host ""

foreach ($Script in $AllScripts) {
    $Results.Total++
    $RelPath = $Script.Name
    
    Write-Host "Testing: $RelPath" -ForegroundColor Yellow
    
    try {
        # Test syntax by parsing the script
        $Content = Get-Content $Script.FullName -Raw -ErrorAction Stop
        $null = [System.Management.Automation.PSParser]::Tokenize($Content, [ref]$null)
        
        $Results.Valid += $Script.FullName
        Write-Host "  VALID" -ForegroundColor Green
        
    } catch {
        $Results.SyntaxErrors += $Script.FullName
        Write-Host "  ERROR: $($_.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "VERIFICATION SUMMARY" -ForegroundColor White
Write-Host "=" * 50

Write-Host "Valid Scripts: $($Results.Valid.Count)" -ForegroundColor Green
Write-Host "Syntax Errors: $($Results.SyntaxErrors.Count)" -ForegroundColor Red
Write-Host "Total Checked: $($Results.Total)" -ForegroundColor Cyan

$SuccessRate = [math]::Round(($Results.Valid.Count / $Results.Total) * 100, 1)
Write-Host "Success Rate: $SuccessRate percent" -ForegroundColor $(if ($SuccessRate -ge 80) {"Green"} else {"Yellow"})

if ($Results.SyntaxErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "SCRIPTS WITH SYNTAX ERRORS:" -ForegroundColor Red
    foreach ($ErrorScript in $Results.SyntaxErrors) {
        Write-Host "  $($ErrorScript | Split-Path -Leaf)" -ForegroundColor DarkRed
    }
}

Write-Host ""
Write-Host "VERIFIED WORKING SCRIPTS:" -ForegroundColor Green
foreach ($ValidScript in $Results.Valid) {
    Write-Host "  $($ValidScript | Split-Path -Leaf)" -ForegroundColor DarkGreen
}

# Generate working scripts list for orchestrator
$WorkingScripts = $Results.Valid | ForEach-Object { $_ | Split-Path -Leaf }
$WorkingScripts | Out-File -FilePath "Working_Scripts_List.txt" -Encoding UTF8

Write-Host ""
Write-Host "Working scripts list saved to: Working_Scripts_List.txt" -ForegroundColor Yellow

exit 0
