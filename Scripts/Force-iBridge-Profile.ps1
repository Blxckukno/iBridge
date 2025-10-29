# Force iBridge User Profile Creation
# This script uses Windows API calls to properly create the user profile

Write-Host "Force Creating iBridge User Profile" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

# Check if user exists
$user = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
if (-not $user) {
    Write-Host "❌ iBridge User account does not exist!" -ForegroundColor Red
    Write-Host "Please run the setup script first." -ForegroundColor Yellow
    pause
    exit
}

Write-Host "✅ iBridge User account found" -ForegroundColor Green

# Method 1: Use CreateProfile API through COM
Write-Host ""
Write-Host "Method 1: Using Windows CreateProfile API..." -ForegroundColor Cyan

try {
    # Get user SID
    $userSID = $user.SID.Value
    Write-Host "User SID: $userSID" -ForegroundColor White
    
    # Use Windows Shell API to create profile
    $shell = New-Object -ComObject Shell.Application
    $profilePath = "C:\Users\$UserUsername"
    
    # Create the profile using Windows API
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class ProfileAPI {
    [DllImport("userenv.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool CreateProfile(
        [MarshalAs(UnmanagedType.LPWStr)] string pszUserSid,
        [MarshalAs(UnmanagedType.LPWStr)] string pszUserName,
        [MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder pszProfilePath,
        uint cchProfilePath
    );
}
"@

    $profilePathBuilder = New-Object System.Text.StringBuilder(260)
    $result = [ProfileAPI]::CreateProfile($userSID, $UserUsername, $profilePathBuilder, $profilePathBuilder.Capacity)
    
    if ($result) {
        Write-Host "✅ Profile created using Windows API" -ForegroundColor Green
        Write-Host "Profile path: $($profilePathBuilder.ToString())" -ForegroundColor White
    } else {
        Write-Host "⚠️ API call completed but may need additional steps" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "⚠️ Could not use Windows API method: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Method 2: Registry-based profile creation
Write-Host ""
Write-Host "Method 2: Creating registry profile entries..." -ForegroundColor Cyan

try {
    $userSID = $user.SID.Value
    $profilePath = "C:\Users\$UserUsername"
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$userSID"
    
    # Create registry key for profile
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Write-Host "✅ Created profile registry key" -ForegroundColor Green
    }
    
    # Set profile properties
    Set-ItemProperty -Path $regPath -Name "ProfileImagePath" -Value $profilePath -Force
    Set-ItemProperty -Path $regPath -Name "Flags" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $regPath -Name "State" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $regPath -Name "RefCount" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $regPath -Name "RunLogonScriptSync" -Value 0 -Type DWord -Force
    
    Write-Host "✅ Registry profile entries created" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Could not create registry entries: $($_.Exception.Message)" -ForegroundColor Red
}

# Method 3: Force profile creation using runas
Write-Host ""
Write-Host "Method 3: Using runas to trigger profile creation..." -ForegroundColor Cyan

try {
    # Create a batch file that will trigger profile creation
    $batchContent = @"
@echo off
echo Initializing iBridge User profile...
echo Profile creation completed successfully!
timeout /t 2 /nobreak
"@
    
    $batchPath = "C:\temp\profile-init.bat"
    $tempDir = "C:\temp"
    
    if (-not (Test-Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    }
    
    $batchContent | Out-File -FilePath $batchPath -Encoding ASCII -Force
    
    # Use runas to execute as iBridge User
    Write-Host "Starting runas process..." -ForegroundColor Yellow
    $runasCmd = "runas /user:`"$UserUsername`" `"$batchPath`""
    
    Write-Host "Command: $runasCmd" -ForegroundColor White
    Write-Host "Password required: $UserPassword" -ForegroundColor White
    
    # Start the runas process
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "runas"
    $processInfo.Arguments = "/user:`"$UserUsername`" `"$batchPath`""
    $processInfo.UseShellExecute = $true
    $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
    
    $process = [System.Diagnostics.Process]::Start($processInfo)
    
    Write-Host "✅ Started runas process - enter password when prompted" -ForegroundColor Green
    Write-Host "Password: $UserPassword" -ForegroundColor Yellow
    
    # Wait for process to complete
    if ($process.WaitForExit(30000)) {
        Write-Host "✅ Profile initialization completed" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Process timed out" -ForegroundColor Yellow
    }
    
    # Clean up
    if (Test-Path $batchPath) {
        Remove-Item $batchPath -Force -ErrorAction SilentlyContinue
    }
    
} catch {
    Write-Host "⚠️ Could not use runas method: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Method 4: Final verification and manual instructions
Write-Host ""
Write-Host "Final Verification:" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

# Check registry
$userSID = $user.SID.Value
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$userSID"
if (Test-Path $regPath) {
    $regProfile = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
    if ($regProfile) {
        Write-Host "✅ Profile registered in Windows registry" -ForegroundColor Green
        Write-Host "   Path: $($regProfile.ProfileImagePath)" -ForegroundColor White
    }
} else {
    Write-Host "❌ Profile not found in registry" -ForegroundColor Red
}

# Check profile directory
$profilePath = "C:\Users\$UserUsername"
if (Test-Path $profilePath) {
    Write-Host "✅ Profile directory exists: $profilePath" -ForegroundColor Green
    
    # Check for NTUSER.DAT (key indicator of full profile)
    $ntUserPath = "$profilePath\NTUSER.DAT"
    if (Test-Path $ntUserPath) {
        Write-Host "✅ NTUSER.DAT found - profile is complete" -ForegroundColor Green
    } else {
        Write-Host "⚠️ NTUSER.DAT missing - profile incomplete" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Profile directory missing" -ForegroundColor Red
}

Write-Host ""
Write-Host "RECOMMENDED SOLUTION:" -ForegroundColor Yellow
Write-Host "====================" -ForegroundColor Yellow
Write-Host "1. Sign out of your current account" -ForegroundColor White
Write-Host "2. Log in as 'iBridge User' with password: $UserPassword" -ForegroundColor White
Write-Host "3. Wait for Windows to complete first-time setup" -ForegroundColor White
Write-Host "4. Sign out and log back in as your main account" -ForegroundColor White
Write-Host ""
Write-Host "This is the ONLY guaranteed way to create a complete" -ForegroundColor Cyan
Write-Host "Windows user profile that will appear in Control Panel." -ForegroundColor Cyan

Write-Host ""
pause
