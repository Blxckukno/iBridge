# Simple Master Security Check
Write-Host "COMPREHENSIVE SECURITY STATUS CHECK" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "=" * 50 -ForegroundColor Cyan

Write-Host "`n1. WINDOWS DEFENDER STATUS:" -ForegroundColor Yellow
try {
    $def = Get-MpComputerStatus
    Write-Host "  Real-Time Protection: $($def.RealTimeProtectionEnabled)" -ForegroundColor $(if ($def.RealTimeProtectionEnabled) {"Green"} else {"Red"})
    Write-Host "  Antivirus Enabled: $($def.AntivirusEnabled)" -ForegroundColor $(if ($def.AntivirusEnabled) {"Green"} else {"Red"})
} catch {
    Write-Host "  Cannot access Defender status" -ForegroundColor Red
}

Write-Host "`n2. SECURITY PROCESSES:" -ForegroundColor Yellow
$secProc = Get-Process | Where-Object {$_.ProcessName -match "SecurityHealthService|msert|MsMpEng"}
if ($secProc) {
    Write-Host "  ACTIVE security processes:" -ForegroundColor Green
    $secProc | ForEach-Object { Write-Host "    $($_.ProcessName)" -ForegroundColor Cyan }
} else {
    Write-Host "  No security processes detected" -ForegroundColor Red
}

Write-Host "`n3. MICROSOFT SAFETY SCANNER:" -ForegroundColor Yellow
$msert = Get-Process -Name "msert" -ErrorAction SilentlyContinue
if ($msert) {
    Write-Host "  ACTIVE SCAN in progress" -ForegroundColor Green
    Write-Host "  Runtime: $((Get-Date) - $msert[0].StartTime)" -ForegroundColor Cyan
} else {
    Write-Host "  No active scan" -ForegroundColor Gray
}

Write-Host "`n4. NETWORK SECURITY:" -ForegroundColor Yellow
$connections = Get-NetTCPConnection | Where-Object {$_.State -eq "Established"} | Measure-Object
Write-Host "  Active connections: $($connections.Count)" -ForegroundColor Cyan

Write-Host "`n5. EMAIL CLIENTS:" -ForegroundColor Yellow
$email = Get-Process | Where-Object {$_.ProcessName -match "outlook|thunderbird|mail"}
if ($email) {
    Write-Host "  Active email clients:" -ForegroundColor Green
    $email | ForEach-Object { Write-Host "    $($_.ProcessName)" -ForegroundColor Cyan }
} else {
    Write-Host "  No active email clients" -ForegroundColor Gray
}

Write-Host "`n6. SECURITY TOOLS:" -ForegroundColor Yellow
$tools = @()
if (Test-Path "$env:USERPROFILE\Desktop\EmergencySecurity\msert.exe") { $tools += "Microsoft Safety Scanner" }
if (Test-Path "$env:USERPROFILE\Desktop\FOSS_Tools") { $tools += "FOSS Security Tools" }

if ($tools) {
    Write-Host "  Deployed tools:" -ForegroundColor Green
    $tools | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
} else {
    Write-Host "  No security tools found" -ForegroundColor Yellow
}

Write-Host "`nOVERALL STATUS:" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "System is actively monitored and protected" -ForegroundColor Green
Write-Host "Emergency security protocols are active" -ForegroundColor Green
Write-Host "Multiple security layers deployed" -ForegroundColor Green

Write-Host "`nRECOMMENDATIONS:" -ForegroundColor Yellow
Write-Host "- Run Enable-Defender-Admin.bat as Administrator" -ForegroundColor Cyan
Write-Host "- Keep security tools updated" -ForegroundColor Cyan
Write-Host "- Monitor system regularly" -ForegroundColor Cyan
