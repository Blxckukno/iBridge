# Windows Local Account Creation Script
# This script creates two local user accounts as specified:
# 1. Admin - Administrator account with password: IBr1dG3Pc
# 2. iBridge User - Standard user account with password: Abd654321!

# Requires Administrator privileges to run

param(
    [switch]$CreateAdmin,
    [switch]$CreateUser,
    [switch]$CreateBoth
)

# Function to check if running as Administrator
function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to create local user account
function New-LocalUserAccount {
    param(
        [string]$Username,
        [string]$Password,
        [string]$Description,
        [bool]$IsAdmin = $false
    )
    
    try {
        Write-Host "Creating user account: $Username" -ForegroundColor Green
        
        # Convert password to secure string
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        
        # Create the user account
        $NewUser = New-LocalUser -Name $Username -Password $SecurePassword -Description $Description -PasswordNeverExpires -AccountNeverExpires
        
        if ($NewUser) {
            Write-Host "User account '$Username' created successfully" -ForegroundColor Green
            
            if ($IsAdmin) {
                # Add to Administrators group
                Add-LocalGroupMember -Group "Administrators" -Member $Username
                Write-Host "User '$Username' added to Administrators group" -ForegroundColor Green
            } else {
                # Add to Users group (standard user)
                Add-LocalGroupMember -Group "Users" -Member $Username
                Write-Host "User '$Username' added to Users group" -ForegroundColor Green
            }
            
            return $true
        }
    }
    catch {
        Write-Host "Error creating user '$Username': $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to create shared applications folder
function New-SharedAppFolder {
    try {
        $FolderPath = "C:\iBridge_Apps"
        
        if (!(Test-Path $FolderPath)) {
            New-Item -ItemType Directory -Path $FolderPath -Force | Out-Null
            Write-Host "Created shared applications folder: $FolderPath" -ForegroundColor Green
            
            # Set permissions for both users to access
            $Acl = Get-Acl $FolderPath
            
            # Add read/execute permissions for iBridge User
            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("iBridge User", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
            $Acl.SetAccessRule($AccessRule)
            
            # Admin already has full control
            Set-Acl -Path $FolderPath -AclObject $Acl
            Write-Host "Set permissions for shared folder" -ForegroundColor Green
        } else {
            Write-Host "Shared folder already exists: $FolderPath" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error creating shared folder: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Windows Local Account Setup Script" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Check if running as Administrator
if (-not (Test-Administrator)) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# Determine which accounts to create
if ($CreateBoth -or (-not $CreateAdmin -and -not $CreateUser)) {
    $CreateAdmin = $true
    $CreateUser = $true
}

$success = $true

# Create Admin account
if ($CreateAdmin) {
    Write-Host "Creating Administrator Account..." -ForegroundColor Yellow
    $adminResult = New-LocalUserAccount -Username "Admin" -Password "IBr1dG3Pc" -Description "Administrator account for application installation and system management" -IsAdmin $true
    $success = $success -and $adminResult
    Write-Host ""
}

# Create iBridge User account
if ($CreateUser) {
    Write-Host "Creating Standard User Account..." -ForegroundColor Yellow
    $userResult = New-LocalUserAccount -Username "iBridge User" -Password "Abc654321!" -Description "Standard user account with limited privileges" -IsAdmin $false
    $success = $success -and $userResult
    Write-Host ""
}

# Create shared applications folder
Write-Host "Setting up Shared Applications Folder..." -ForegroundColor Yellow
New-SharedAppFolder
Write-Host ""

# Summary
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Setup Summary:" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

if ($CreateAdmin) {
    Write-Host "Admin Account:" -ForegroundColor White
    Write-Host "  Username: Admin" -ForegroundColor Gray
    Write-Host "  Password: IBr1dG3Pc" -ForegroundColor Gray
    Write-Host "  Type: Administrator" -ForegroundColor Gray
    Write-Host ""
}

if ($CreateUser) {
    Write-Host "Standard User Account:" -ForegroundColor White
    Write-Host "  Username: iBridge User" -ForegroundColor Gray
    Write-Host "  Password: Abc654321!" -ForegroundColor Gray
    Write-Host "  Type: Standard User" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Shared Folder: C:\iBridge_Apps" -ForegroundColor White
Write-Host ""

if ($success) {
    Write-Host "Account setup completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Log in as Admin to install applications" -ForegroundColor Gray
    Write-Host "2. Place application shortcuts in C:\iBridge_Apps" -ForegroundColor Gray
    Write-Host "3. Test access from iBridge User account" -ForegroundColor Gray
} else {
    Write-Host "Some errors occurred during setup. Please check the output above." -ForegroundColor Red
}

Write-Host ""
Write-Host "Script completed. Press any key to continue..."
Read-Host
