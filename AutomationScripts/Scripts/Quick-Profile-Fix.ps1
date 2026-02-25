# QUICK iBridge User Profile Creator
# This forces the profile creation without waiting for full installation

Write-Host "QUICK iBridge Profile Setup" -ForegroundColor Yellow
Write-Host "===========================" -ForegroundColor Yellow

$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

# Check if account exists
$user = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
if ($user) {
    Write-Host "✅ iBridge User account found" -ForegroundColor Green
} else {
    Write-Host "❌ iBridge User account not found - creating now..." -ForegroundColor Red
    try {
        $securePassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
        $newUser = New-LocalUser -Name $UserUsername -Password $securePassword -FullName "iBridge User" -Description "Standard user" -PasswordNeverExpires -AccountNeverExpires
        Write-Host "✅ iBridge User account created" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create account: $($_.Exception.Message)" -ForegroundColor Red
        pause
        exit
    }
}

Write-Host ""
Write-Host "FASTEST SOLUTION TO MAKE ACCOUNT APPEAR IN CONTROL PANEL:" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Press Windows key + R" -ForegroundColor White
Write-Host "2. Type: runas /user:`"iBridge User`" cmd" -ForegroundColor Cyan
Write-Host "3. Press Enter" -ForegroundColor White
Write-Host "4. When prompted for password, type: $UserPassword" -ForegroundColor Cyan
Write-Host "5. A command prompt will open - just type 'exit' and press Enter" -ForegroundColor White
Write-Host ""
Write-Host "This will force Windows to create the profile immediately!" -ForegroundColor Green
Write-Host ""
Write-Host "Alternative (if you have time):" -ForegroundColor Yellow
Write-Host "1. Sign out" -ForegroundColor White
Write-Host "2. Log in as iBridge User (password: $UserPassword)" -ForegroundColor White
Write-Host "3. Sign out and log back in as your main account" -ForegroundColor White
Write-Host ""

pause
