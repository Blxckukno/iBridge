# Simple iBridge User Profile Creator
# This uses Windows' built-in profile creation by simulating a logon

Write-Host "Simple iBridge User Profile Creator" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

$UserUsername = "iBridge User"
$UserPassword = "Abc654321!"

# Check if user exists
$user = Get-LocalUser -Name $UserUsername -ErrorAction SilentlyContinue
if (-not $user) {
    Write-Host "❌ iBridge User account does not exist!" -ForegroundColor Red
    Write-Host "Please run the setup script first to create the account." -ForegroundColor Yellow
    pause
    exit
}

Write-Host "✅ iBridge User account found" -ForegroundColor Green

# The simplest way to create a profile is to actually log in
Write-Host ""
Write-Host "Creating profile using Windows login simulation..." -ForegroundColor Cyan

try {
    # Create credential object
    $securePassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($UserUsername, $securePassword)
    
    Write-Host "Starting credential-based process to initialize profile..." -ForegroundColor Yellow
    
    # Start a simple process as the iBridge User - this forces Windows to create the profile
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "cmd.exe"
    $processInfo.Arguments = "/c echo Profile creation initiated & timeout /t 3 /nobreak"
    $processInfo.UserName = $UserUsername
    $processInfo.Password = $securePassword
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.Domain = $env:COMPUTERNAME
    
    $process = [System.Diagnostics.Process]::Start($processInfo)
    $process.WaitForExit()
    
    Write-Host "✅ Profile initialization process completed" -ForegroundColor Green
    
    # Wait a moment for Windows to complete profile creation
    Write-Host "Waiting for Windows to complete profile setup..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
} catch {
    Write-Host "⚠️ Could not start credential process: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "This might be because the account needs to be logged in manually first." -ForegroundColor Yellow
}

# Alternative method: Create a scheduled task that runs as the user
Write-Host ""
Write-Host "Alternative: Creating scheduled task for profile initialization..." -ForegroundColor Cyan

try {
    $taskName = "iBridge-Profile-Init"
    
    # Remove existing task if it exists
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Create a simple task action
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c echo Profile initialized > C:\temp\profile-init.log"
    
    # Create task to run as iBridge User
    $principal = New-ScheduledTaskPrincipal -UserId $UserUsername -LogonType Password
    
    # Create the task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnDemand -DontStopIfGoingOnBatteries
    
    # Register the task
    Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings | Out-Null
    
    Write-Host "✅ Scheduled task created: $taskName" -ForegroundColor Green
    
    # Run the task immediately
    Start-ScheduledTask -TaskName $taskName
    
    Write-Host "✅ Task started - this should initialize the user profile" -ForegroundColor Green
    
    # Wait for task completion
    Start-Sleep -Seconds 3
    
    # Clean up the task
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "✅ Cleanup completed" -ForegroundColor Green
    
} catch {
    Write-Host "⚠️ Could not create scheduled task: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Check if profile was created
Write-Host ""
Write-Host "Checking profile creation..." -ForegroundColor Cyan

$profilePath = "C:\Users\$UserUsername"
if (Test-Path $profilePath) {
    Write-Host "✅ Profile directory exists: $profilePath" -ForegroundColor Green
    
    # Check for key profile folders
    $keyFolders = @("Desktop", "Documents", "AppData")
    foreach ($folder in $keyFolders) {
        $folderPath = "$profilePath\$folder"
        try {
            if (Test-Path $folderPath) {
                Write-Host "  ✅ $folder folder exists" -ForegroundColor Green
            } else {
                Write-Host "  ❌ $folder folder missing" -ForegroundColor Red
            }
        } catch {
            Write-Host "  ⚠️ Cannot check $folder folder (permission denied)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "❌ Profile directory not found: $profilePath" -ForegroundColor Red
}

Write-Host ""
Write-Host "Final Instructions:" -ForegroundColor Yellow
Write-Host "==================" -ForegroundColor Yellow
Write-Host "1. The most reliable way to create the profile is to:" -ForegroundColor White
Write-Host "   - Sign out of current account" -ForegroundColor White
Write-Host "   - Log in as 'iBridge User' (password: $UserPassword)" -ForegroundColor White
Write-Host "   - This will automatically create the full profile" -ForegroundColor White
Write-Host ""
Write-Host "2. After logging in once, the account will appear in:" -ForegroundColor White
Write-Host "   - Control Panel > User Accounts" -ForegroundColor White
Write-Host "   - Settings > Accounts > Family & other users" -ForegroundColor White
Write-Host ""
Write-Host "3. Then you can log back in as your main account" -ForegroundColor White

Write-Host ""
pause
