# Manual Commands to Create Accounts
# Copy and paste these commands one by one in Administrator PowerShell

# Create Admin Account
$adminPassword = ConvertTo-SecureString "IBr1dG3Pc" -AsPlainText -Force
New-LocalUser -Name "Admin" -Password $adminPassword -Description "Administrator account" -PasswordNeverExpires -AccountNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member "Admin"

# Create iBridge User Account  
$userPassword = ConvertTo-SecureString "Abc654321!" -AsPlainText -Force
New-LocalUser -Name "iBridge User" -Password $userPassword -Description "Standard user account" -PasswordNeverExpires -AccountNeverExpires
Add-LocalGroupMember -Group "Users" -Member "iBridge User"

# Create Shared Folder
New-Item -ItemType Directory -Path "C:\iBridge_Apps" -Force

# Verify Accounts Created
Get-LocalUser | Where-Object {$_.Name -in @("Admin", "iBridge User")} | Format-Table Name, Enabled, Description
