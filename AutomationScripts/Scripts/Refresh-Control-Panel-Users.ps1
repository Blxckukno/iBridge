# Force Refresh User Accounts in Control Panel
# This script refreshes the Windows user account cache

Write-Host "Forcing Control Panel User Account Refresh..." -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Method 1: Refresh the registry cache
Write-Host "1. Refreshing user account registry cache..." -ForegroundColor Yellow
try {
    # Stop and restart the User Profile Service
    Write-Host "   Stopping User Profile Service..." -ForegroundColor White
    Stop-Service -Name "ProfSvc" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    Write-Host "   Starting User Profile Service..." -ForegroundColor White
    Start-Service -Name "ProfSvc" -ErrorAction SilentlyContinue
    
    Write-Host "   ✅ User Profile Service refreshed" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ Could not restart User Profile Service: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Method 2: Clear Control Panel cache
Write-Host "2. Clearing Control Panel cache..." -ForegroundColor Yellow
try {
    # Clear the thumbnail cache and control panel cache
    $env:LOCALAPPDATA + "\Microsoft\Windows\Caches" | ForEach-Object {
        if (Test-Path $_) {
            Remove-Item "$_\*" -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "   ✅ Cleared cache: $_" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "   ⚠️ Could not clear all caches: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Method 3: Open Windows Settings instead of Control Panel
Write-Host "3. Opening Windows Settings (Modern UI)..." -ForegroundColor Yellow
try {
    Start-Process "ms-settings:otherusers"
    Write-Host "   ✅ Windows Settings opened - check 'Family & other users'" -ForegroundColor Green
    Write-Host "   📝 This is where local accounts typically appear in Windows 10/11" -ForegroundColor Cyan
} catch {
    Write-Host "   ⚠️ Could not open Windows Settings" -ForegroundColor Yellow
}

Write-Host ""

# Method 4: Open classic Control Panel User Accounts
Write-Host "4. Opening classic Control Panel..." -ForegroundColor Yellow
try {
    Start-Process "netplwiz"
    Write-Host "   ✅ User Accounts (netplwiz) opened" -ForegroundColor Green
    Write-Host "   📝 This shows all user accounts and their properties" -ForegroundColor Cyan
} catch {
    Write-Host "   ⚠️ Could not open netplwiz" -ForegroundColor Yellow
}

Write-Host ""

# Method 5: Try traditional Control Panel
Write-Host "5. Opening traditional Control Panel..." -ForegroundColor Yellow
try {
    Start-Process "control" -ArgumentList "userpasswords"
    Write-Host "   ✅ Control Panel User Accounts opened" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ Could not open Control Panel User Accounts" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Account Verification Summary:" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Final verification
$iBridgeUser = Get-LocalUser -Name "iBridge User" -ErrorAction SilentlyContinue
$adminUser = Get-LocalUser -Name "Admin" -ErrorAction SilentlyContinue

if ($iBridgeUser) {
    $iBridgeStatus = if ($iBridgeUser.Enabled) { "ENABLED" } else { "DISABLED" }
    Write-Host "✅ iBridge User: Account exists and is $iBridgeStatus" -ForegroundColor Green
} else {
    Write-Host "❌ iBridge User: Account missing" -ForegroundColor Red
}

if ($adminUser) {
    $adminStatus = if ($adminUser.Enabled) { "ENABLED" } else { "DISABLED" }
    Write-Host "✅ Admin: Account exists and is $adminStatus" -ForegroundColor Green
} else {
    Write-Host "❌ Admin: Account missing" -ForegroundColor Red
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "==========" -ForegroundColor Yellow
Write-Host "1. Check the Windows Settings window that opened" -ForegroundColor White
Write-Host "2. Check the User Accounts (netplwiz) window that opened" -ForegroundColor White  
Write-Host "3. If accounts still don't appear, try restarting Windows" -ForegroundColor White
Write-Host "4. Local accounts may not appear in some Control Panel views" -ForegroundColor White
Write-Host "   but should be visible in Windows Settings > Accounts" -ForegroundColor White

Write-Host ""
Write-Host "Note: In Windows 10/11, local accounts are primarily managed" -ForegroundColor Cyan
Write-Host "through Settings > Accounts > Family & other users rather" -ForegroundColor Cyan
Write-Host "than the classic Control Panel interface." -ForegroundColor Cyan

pause
