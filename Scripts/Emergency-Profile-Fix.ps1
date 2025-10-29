# Force iBridge User Profile Creation - EMERGENCY VERSION
# This will make the account visible

Write-Host "EMERGENCY: Making iBridge User Visible" -ForegroundColor Red
Write-Host "======================================" -ForegroundColor Red

# First, let's see what's wrong
$user = Get-LocalUser -Name "iBridge User" -ErrorAction SilentlyContinue
if ($user) {
    Write-Host "Account exists: $($user.Name)" -ForegroundColor Green
    Write-Host "SID: $($user.SID.Value)" -ForegroundColor White
    Write-Host "Enabled: $($user.Enabled)" -ForegroundColor White
} else {
    Write-Host "ERROR: Account not found!" -ForegroundColor Red
    exit
}

# Check if profile directory exists
$profilePath = "C:\Users\iBridge User"
if (Test-Path $profilePath) {
    Write-Host "Profile directory exists: $profilePath" -ForegroundColor Green
} else {
    Write-Host "Profile directory missing - creating..." -ForegroundColor Yellow
    try {
        New-Item -Path $profilePath -ItemType Directory -Force | Out-Null
        Write-Host "Profile directory created" -ForegroundColor Green
    } catch {
        Write-Host "Could not create profile directory" -ForegroundColor Red
    }
}

# EMERGENCY METHOD: Use LoadUserProfile API
Write-Host ""
Write-Host "Using Windows LoadUserProfile API..." -ForegroundColor Cyan

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

public class ProfileLoader {
    [DllImport("userenv.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool CreateProfile(
        [MarshalAs(UnmanagedType.LPWStr)] string pszUserSid,
        [MarshalAs(UnmanagedType.LPWStr)] string pszUserName,
        [MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszProfilePath,
        uint cchProfilePath
    );
    
    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool LogonUser(
        string lpszUsername,
        string lpszDomain,
        string lpszPassword,
        int dwLogonType,
        int dwLogonProvider,
        out IntPtr phToken
    );
    
    [DllImport("userenv.dll", SetLastError = true)]
    public static extern bool LoadUserProfile(
        IntPtr hToken,
        ref PROFILEINFO lpProfileInfo
    );
    
    [DllImport("userenv.dll", SetLastError = true)]
    public static extern bool UnloadUserProfile(
        IntPtr hToken,
        IntPtr hProfile
    );
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}

[StructLayout(LayoutKind.Sequential)]
public struct PROFILEINFO {
    public int dwSize;
    public int dwFlags;
    [MarshalAs(UnmanagedType.LPWStr)]
    public string lpUserName;
    [MarshalAs(UnmanagedType.LPWStr)]
    public string lpProfilePath;
    [MarshalAs(UnmanagedType.LPWStr)]
    public string lpDefaultPath;
    [MarshalAs(UnmanagedType.LPWStr)]
    public string lpServerName;
    [MarshalAs(UnmanagedType.LPWStr)]
    public string lpPolicyPath;
    public IntPtr hProfile;
}
"@

try {
    $username = "iBridge User"
    $password = "Abc654321!"
    $domain = $env:COMPUTERNAME
    
    # Create profile using Windows API
    $userSID = $user.SID.Value
    $profilePathBuilder = New-Object System.Text.StringBuilder(260)
    
    $result = [ProfileLoader]::CreateProfile($userSID, $username, $profilePathBuilder, $profilePathBuilder.Capacity)
    
    if ($result) {
        Write-Host "SUCCESS: Profile created using Windows API" -ForegroundColor Green
    } else {
        Write-Host "API call completed (may already exist)" -ForegroundColor Yellow
    }
    
    # Try to logon and load profile
    $token = [IntPtr]::Zero
    $logonResult = [ProfileLoader]::LogonUser($username, $domain, $password, 2, 0, [ref]$token)
    
    if ($logonResult -and $token -ne [IntPtr]::Zero) {
        Write-Host "SUCCESS: User logon token obtained" -ForegroundColor Green
        
        # Load the profile
        $profileInfo = New-Object PROFILEINFO
        $profileInfo.dwSize = [System.Runtime.InteropServices.Marshal]::SizeOf($profileInfo)
        $profileInfo.lpUserName = $username
        $profileInfo.lpProfilePath = $null
        
        $loadResult = [ProfileLoader]::LoadUserProfile($token, [ref]$profileInfo)
        
        if ($loadResult) {
            Write-Host "SUCCESS: User profile loaded!" -ForegroundColor Green
            
            # Unload the profile
            [ProfileLoader]::UnloadUserProfile($token, $profileInfo.hProfile) | Out-Null
            Write-Host "Profile unloaded successfully" -ForegroundColor Green
        } else {
            Write-Host "Could not load profile, but token was valid" -ForegroundColor Yellow
        }
        
        # Close the token
        [ProfileLoader]::CloseHandle($token) | Out-Null
    } else {
        Write-Host "Could not obtain logon token" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "API method failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "FINAL CHECK:" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan

# Restart Windows Explorer to refresh
Write-Host "Restarting Windows Explorer..." -ForegroundColor Yellow
try {
    Get-Process explorer | Stop-Process -Force
    Start-Sleep -Seconds 2
    Start-Process explorer
    Write-Host "Explorer restarted" -ForegroundColor Green
} catch {
    Write-Host "Could not restart explorer" -ForegroundColor Yellow
}

Start-Sleep -Seconds 3

# Open Control Panel
Write-Host "Opening Control Panel..." -ForegroundColor Yellow
Start-Process "control" -ArgumentList "userpasswords"

Write-Host ""
Write-Host "IF IBRIDGE USER STILL DOESN'T APPEAR:" -ForegroundColor Red
Write-Host "=====================================" -ForegroundColor Red
Write-Host ""
Write-Host "1. Close Control Panel" -ForegroundColor White
Write-Host "2. Press Windows Key + R" -ForegroundColor White
Write-Host "3. Type: netplwiz" -ForegroundColor Cyan
Write-Host "4. Press Enter" -ForegroundColor White
Write-Host "5. iBridge User SHOULD appear in that window" -ForegroundColor White
Write-Host "6. If it appears there, select it and click Properties" -ForegroundColor White
Write-Host "7. This will force Windows to recognize it" -ForegroundColor White
Write-Host ""

pause
