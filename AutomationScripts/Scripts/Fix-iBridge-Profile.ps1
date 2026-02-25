# Test and Fix iBridge User Profile Creation
# This script specifically focuses on creating the iBridge User profile properly

Write-Host "iBridge User Profile Creation Fix" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

# Check if user exists
$user = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
if (-not $user) {
    Write-Host "❌ iBridge User account does not exist!" -ForegroundColor Red
    Write-Host "Creating iBridge User account first..." -ForegroundColor Yellow
    
    try {
        $securePassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
        $newUser = New-LocalUser -Name $UserUsername -Password $securePassword -FullName "iBridge User" -Description "Standard user account for iBridge" -PasswordNeverExpires -AccountNeverExpires
        Write-Host "✅ iBridge User account created" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create iBridge User: $($_.Exception.Message)" -ForegroundColor Red
        pause
        exit
    }
}

Write-Host "✅ iBridge User account exists" -ForegroundColor Green

# Get user SID
$userSID = (Get-LocalUser -Name $UserUsername).SID.Value
Write-Host "User SID: $userSID" -ForegroundColor White

# Check current profile status
$profilePath = "C:\Users\$UserUsername"
Write-Host "Expected profile path: $profilePath" -ForegroundColor White

if (Test-Path $profilePath) {
    Write-Host "✅ Profile directory exists" -ForegroundColor Green
} else {
    Write-Host "❌ Profile directory missing - creating..." -ForegroundColor Yellow
    New-Item -Path $profilePath -ItemType Directory -Force | Out-Null
    Write-Host "✅ Profile directory created" -ForegroundColor Green
}

# Create essential profile structure
Write-Host "Creating profile structure..." -ForegroundColor Cyan

$profileDirs = @(
    "Desktop",
    "Documents", 
    "Downloads",
    "Pictures",
    "Videos",
    "Music",
    "AppData",
    "AppData\Local",
    "AppData\Roaming",
    "AppData\Local\Microsoft",
    "AppData\Roaming\Microsoft"
)

foreach ($dir in $profileDirs) {
    $fullPath = "$profilePath\$dir"
    if (-not (Test-Path $fullPath)) {
        New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
        Write-Host "✅ Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "✅ Exists: $dir" -ForegroundColor Gray
    }
}

# Set proper permissions
Write-Host "Setting profile permissions..." -ForegroundColor Cyan
try {
    $acl = Get-Acl $profilePath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($UserUsername, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $profilePath -AclObject $acl
    Write-Host "✅ Permissions set" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not set permissions: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Register profile in registry
Write-Host "Registering profile in Windows registry..." -ForegroundColor Cyan
try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$userSID"
    
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Write-Host "✅ Created registry key" -ForegroundColor Green
    }
    
    # Set profile path
    Set-ItemProperty -Path $regPath -Name "ProfileImagePath" -Value $profilePath -Force
    Write-Host "✅ Set ProfileImagePath" -ForegroundColor Green
    
    # Set other required values
    Set-ItemProperty -Path $regPath -Name "Flags" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $regPath -Name "State" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $regPath -Name "RefCount" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $regPath -Name "RunLogonScriptSync" -Value 0 -Type DWord -Force
    
    Write-Host "✅ Registry profile registered" -ForegroundColor Green
    
} catch {
    Write-Host "⚠️ Could not register in registry: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Force profile loading by attempting credential-based process
Write-Host "Attempting to initialize profile..." -ForegroundColor Cyan
try {
    # Create a simple script that the user can run to complete profile initialization
    $initScript = @"
# Run this to complete iBridge User profile initialization
`$password = ConvertTo-SecureString "$UserPassword" -AsPlainText -Force
`$credential = New-Object System.Management.Automation.PSCredential("$UserUsername", `$password)

Write-Host "Initializing iBridge User profile..." -ForegroundColor Yellow
Start-Process cmd.exe -Credential `$credential -ArgumentList '/c', 'echo Profile initialized successfully & pause' -WindowStyle Normal -Wait
Write-Host "Profile initialization completed!" -ForegroundColor Green
"@
    
    $initScriptPath = "C:\Users\Lwandile Gasela\iBridge\Scripts\Initialize-iBridge-Profile.ps1"
    $initScript | Out-File -FilePath $initScriptPath -Encoding UTF8
    
    Write-Host "✅ Created profile initialization script" -ForegroundColor Green
    Write-Host "   Location: $initScriptPath" -ForegroundColor White
    
} catch {
    Write-Host "⚠️ Could not create initialization script: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Final verification
Write-Host ""
Write-Host "Profile Creation Summary:" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

# Check if profile shows up in registry
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$userSID"
if (Test-Path $regPath) {
    $regProfilePath = Get-ItemProperty -Path $regPath -Name "ProfileImagePath" -ErrorAction SilentlyContinue
    if ($regProfilePath) {
        Write-Host "✅ Profile registered in Windows registry" -ForegroundColor Green
        Write-Host "   Registry Path: $($regProfilePath.ProfileImagePath)" -ForegroundColor White
    } else {
        Write-Host "❌ Profile not properly registered in registry" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Profile registry key missing" -ForegroundColor Red
}

# Check directory structure
if (Test-Path "$profilePath\Desktop") {
    Write-Host "✅ Desktop folder exists" -ForegroundColor Green
} else {
    Write-Host "❌ Desktop folder missing" -ForegroundColor Red
}

if (Test-Path "$profilePath\AppData") {
    Write-Host "✅ AppData folder exists" -ForegroundColor Green
} else {
    Write-Host "❌ AppData folder missing" -ForegroundColor Red
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "==========" -ForegroundColor Yellow
Write-Host "1. Try logging in to iBridge User account (password: $UserPassword)" -ForegroundColor White
Write-Host "2. Or run the initialization script created above" -ForegroundColor White
Write-Host "3. Check Windows Settings > Accounts > Family & other users" -ForegroundColor White
Write-Host "4. The profile should now appear properly in Control Panel" -ForegroundColor White

Write-Host ""
pause
