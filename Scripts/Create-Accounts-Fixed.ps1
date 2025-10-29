# Simple Account Creation Script - Fixed Version
# Creates the Admin and iBridge User accounts with proper error handling

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Windows Local Account Creation Script - Fixed Version" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if running as Administrator
if (-not (Test-Administrator)) {
    Write-Host "[ERROR] This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# Password definitions
$adminPassword = "IBr1dG3Pc"
$userPassword = "Abc654321!"

Write-Host "Password Check:" -ForegroundColor Yellow
Write-Host "  Admin Password: $adminPassword" -ForegroundColor Gray
Write-Host "  User Password:  $userPassword" -ForegroundColor Gray
Write-Host ""

# Create Admin account
Write-Host "Creating Admin Account..." -ForegroundColor Yellow
try {
    # Check if Admin account already exists
    $existingAdmin = Get-LocalUser -Name "Admin" -ErrorAction SilentlyContinue
    if ($existingAdmin) {
        Write-Host "[WARNING] Admin account already exists. Removing it first..." -ForegroundColor Yellow
        Remove-LocalUser -Name "Admin" -Confirm:$false
    }
    
    # Create Admin account
    $secureAdminPassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
    $adminUser = New-LocalUser -Name "Admin" -Password $secureAdminPassword -Description "Administrator account for application installation" -PasswordNeverExpires -AccountNeverExpires
    
    # Add to Administrators group
    Add-LocalGroupMember -Group "Administrators" -Member "Admin"
    
    Write-Host "[SUCCESS] Admin account created successfully" -ForegroundColor Green
    Write-Host "  Username: Admin" -ForegroundColor Gray
    Write-Host "  Password: $adminPassword" -ForegroundColor Gray
    Write-Host "  Type: Administrator" -ForegroundColor Gray
} catch {
    Write-Host "[ERROR] Failed to create Admin account: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Create iBridge User account
Write-Host "Creating iBridge User Account..." -ForegroundColor Yellow
try {
    # Check if iBridge User account already exists
    $existingUser = Get-LocalUser -Name "iBridge User" -ErrorAction SilentlyContinue
    if ($existingUser) {
        Write-Host "[WARNING] iBridge User account already exists. Removing it first..." -ForegroundColor Yellow
        Remove-LocalUser -Name "iBridge User" -Confirm:$false
    }
    
    # Create iBridge User account
    $secureUserPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
    $bridgeUser = New-LocalUser -Name "iBridge User" -Password $secureUserPassword -Description "Standard user account with limited privileges" -PasswordNeverExpires -AccountNeverExpires
    
    # Add to Users group (standard user - no admin rights)
    Add-LocalGroupMember -Group "Users" -Member "iBridge User"
    
    Write-Host "[SUCCESS] iBridge User account created successfully" -ForegroundColor Green
    Write-Host "  Username: iBridge User" -ForegroundColor Gray
    Write-Host "  Password: $userPassword" -ForegroundColor Gray
    Write-Host "  Type: Standard User" -ForegroundColor Gray
} catch {
    Write-Host "[ERROR] Failed to create iBridge User account: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Create shared applications folder
Write-Host "Creating Shared Applications Folder..." -ForegroundColor Yellow
try {
    $folderPath = "C:\iBridge_Apps"
    
    if (!(Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
        Write-Host "[SUCCESS] Created shared folder: $folderPath" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Shared folder already exists: $folderPath" -ForegroundColor Yellow
    }
    
    # Set permissions for iBridge User to access the folder
    $acl = Get-Acl $folderPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("iBridge User", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $folderPath -AclObject $acl
    
    Write-Host "[SUCCESS] Set permissions for shared folder" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to create shared folder: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Verification
Write-Host "Verifying Account Creation..." -ForegroundColor Yellow

# Check Admin account
try {
    $adminCheck = Get-LocalUser -Name "Admin" -ErrorAction Stop
    Write-Host "[VERIFIED] Admin account exists and is enabled: $($adminCheck.Enabled)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Admin account verification failed" -ForegroundColor Red
}

# Check iBridge User account
try {
    $userCheck = Get-LocalUser -Name "iBridge User" -ErrorAction Stop
    Write-Host "[VERIFIED] iBridge User account exists and is enabled: $($userCheck.Enabled)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] iBridge User account verification failed" -ForegroundColor Red
}

# Check shared folder
if (Test-Path "C:\iBridge_Apps") {
    Write-Host "[VERIFIED] Shared folder exists: C:\iBridge_Apps" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Shared folder verification failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "IMPORTANT LOGIN INFORMATION" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Admin Account Login:" -ForegroundColor White
Write-Host "  Username: Admin" -ForegroundColor Gray
Write-Host "  Password: $adminPassword" -ForegroundColor Gray
Write-Host ""

Write-Host "iBridge User Account Login:" -ForegroundColor White
Write-Host "  Username: iBridge User" -ForegroundColor Gray
Write-Host "  Password: $userPassword" -ForegroundColor Gray
Write-Host ""

Write-Host "CRITICAL: Note the password spelling!" -ForegroundColor Red
Write-Host "  The password is: A-b-c-6-5-4-3-2-1-!" -ForegroundColor Yellow
Write-Host "  NOT: A-b-d-6-5-4-3-2-1-!" -ForegroundColor Red
Write-Host ""

Write-Host "To login:" -ForegroundColor Yellow
Write-Host "1. Log out or use 'Switch User'" -ForegroundColor Gray
Write-Host "2. Click 'Other user' on login screen" -ForegroundColor Gray
Write-Host "3. Type username exactly as shown above" -ForegroundColor Gray
Write-Host "4. Type password exactly as shown above" -ForegroundColor Gray
Write-Host "5. Ensure Caps Lock is OFF" -ForegroundColor Gray

Write-Host ""
Write-Host "Script completed. Press any key to continue..."
Read-Host
