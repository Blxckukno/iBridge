# Check and Fix iBridge User Account
# Verifies user accounts and recreates iBridge User if missing

Write-Host "Checking iBridge User Account Status..." -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Check if iBridge User exists
try {
    $iBridgeUser = Get-LocalUser -Name "iBridge User" -ErrorAction SilentlyContinue
    if ($iBridgeUser) {
        Write-Host "✅ iBridge User account found in system" -ForegroundColor Green
        Write-Host "   Name: $($iBridgeUser.Name)" -ForegroundColor White
        Write-Host "   Full Name: $($iBridgeUser.FullName)" -ForegroundColor White
        Write-Host "   Enabled: $($iBridgeUser.Enabled)" -ForegroundColor White
        Write-Host "   Account Expires: $($iBridgeUser.AccountExpires)" -ForegroundColor White
        Write-Host "   Password Expires: $($iBridgeUser.PasswordExpires)" -ForegroundColor White
        
        # Check if account is enabled
        if (-not $iBridgeUser.Enabled) {
            Write-Host "⚠️  Account is disabled - enabling it..." -ForegroundColor Yellow
            Enable-LocalUser -Name "iBridge User"
            Write-Host "✅ iBridge User account enabled" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ iBridge User account NOT found in system" -ForegroundColor Red
        Write-Host "   Creating iBridge User account..." -ForegroundColor Yellow
        
        # Create the iBridge User account
        $UserPassword = "Abc654321!"
        $secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
        
        try {
            $newUser = New-LocalUser -Name "iBridge User" -Password $secureUserPassword -FullName "iBridge User" -Description "Standard user for iBridge operations" -PasswordNeverExpires -AccountNeverExpires
            Write-Host "✅ iBridge User account created successfully" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to create iBridge User account: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ Error checking iBridge User account: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Check Admin account too
try {
    $adminUser = Get-LocalUser -Name "Admin" -ErrorAction SilentlyContinue
    if ($adminUser) {
        Write-Host "✅ Admin account found in system" -ForegroundColor Green
        Write-Host "   Name: $($adminUser.Name)" -ForegroundColor White
        Write-Host "   Full Name: $($adminUser.FullName)" -ForegroundColor White
        Write-Host "   Enabled: $($adminUser.Enabled)" -ForegroundColor White
        
        # Check if Admin is in Administrators group
        try {
            $adminGroupMembers = Get-LocalGroupMember -Group "Administrators" | Where-Object { $_.Name -like "*Admin" }
            if ($adminGroupMembers) {
                Write-Host "✅ Admin is in Administrators group" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Admin is NOT in Administrators group - adding..." -ForegroundColor Yellow
                Add-LocalGroupMember -Group "Administrators" -Member "Admin"
                Write-Host "✅ Admin added to Administrators group" -ForegroundColor Green
            }
        } catch {
            Write-Host "⚠️  Could not verify Admin group membership: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Admin account NOT found in system" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error checking Admin account: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# List all local users
Write-Host "All Local User Accounts:" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
try {
    $allUsers = Get-LocalUser | Select-Object Name, FullName, Enabled, LastLogon
    $allUsers | Format-Table -AutoSize
} catch {
    Write-Host "❌ Error listing users: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Check user profiles
Write-Host "User Profile Directories:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
$profilePaths = @("C:\Users\Admin", "C:\Users\iBridge User")
foreach ($path in $profilePaths) {
    if (Test-Path $path) {
        Write-Host "✅ $path exists" -ForegroundColor Green
        $desktopPath = "$path\Desktop"
        if (Test-Path $desktopPath) {
            Write-Host "   ✅ Desktop folder exists" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Desktop folder missing - creating..." -ForegroundColor Yellow
            New-Item -Path $desktopPath -ItemType Directory -Force | Out-Null
            Write-Host "   ✅ Desktop folder created" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ $path does not exist" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Account verification completed!" -ForegroundColor Green
Write-Host ""
Write-Host "If iBridge User still doesn't appear in Control Panel:" -ForegroundColor Yellow
Write-Host "1. Restart Windows (sometimes required for Control Panel refresh)" -ForegroundColor White
Write-Host "2. Try logging out and back in" -ForegroundColor White
Write-Host "3. Check Windows Settings > Accounts > Family & other users" -ForegroundColor White
Write-Host ""

pause
