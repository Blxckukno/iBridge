param(
    [string]$CsvPath = "C:\Users\Lwandile Gasela\Downloads\Tickets.csv"
)

$ErrorActionPreference = "Stop"

Write-Host "[1/4] Importing SharePoint tickets..."
powershell -ExecutionPolicy Bypass -File "AutomationScripts\import-sharepoint-tickets.ps1" -CsvPath $CsvPath

Write-Host "[2/4] Running security audit..."
python "AutomationScripts\security-audit.py"

Write-Host "[3/4] Running full stack sweep..."
python "AutomationScripts\full-stack-sweep.py"

Write-Host "[4/4] Done."
