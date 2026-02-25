# Windows Local Account Management Scripts

This repository contains PowerShell scripts for setting up and managing local Windows user accounts for the iBridge project.

## Overview

The scripts create two local user accounts:
1. **Admin** - Administrator account for installing applications
2. **iBridge User** - Standard user account for daily use

## Files

### `Create-LocalAccounts.ps1`
Main script that creates both user accounts and sets up the shared application folder.

**Features:**
- Creates Admin account with administrator privileges
- Creates iBridge User account with standard user privileges
- Sets up shared applications folder at `C:\iBridge_Apps`
- Configures appropriate permissions

## Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges

## Usage

### Step 1: Run the Account Creation Script

Open PowerShell as Administrator and run:

```powershell
.\Create-LocalAccounts.ps1
```

**Options:**
- `.\Create-LocalAccounts.ps1 -CreateAdmin` - Create only Admin account
- `.\Create-LocalAccounts.ps1 -CreateUser` - Create only iBridge User account
- `.\Create-LocalAccounts.ps1 -CreateBoth` - Create both accounts (default)

### Step 2: Install Applications (Admin Account)

1. Log in as **Admin** (Password: `IBr1dG3Pc`)
2. Install required applications
3. Create shortcuts and place them in `C:\iBridge_Apps`

### Step 3: Test User Access

1. Log in as **iBridge User** (Password: `Abd654321!`)
2. Verify access to applications via shortcuts in `C:\iBridge_Apps`

## Account Details

| Account | Username | Password | Type | Purpose |
|---------|----------|----------|------|---------|
| Admin | Admin | IBr1dG3Pc | Administrator | Application installation and system management |
| Standard User | iBridge User | Abd654321! | Standard User | Daily use with limited privileges |

## Security Considerations

- Passwords are hardcoded in scripts for automation purposes
- Consider changing passwords after initial setup if security is a concern
- The Admin account should only be used for installation and maintenance
- Regular users should use the iBridge User account for daily tasks

## Folder Structure

```
C:\iBridge_Apps\          # Shared applications folder
├── Shortcuts\            # Application shortcuts
├── Installers\          # Application installers (optional)
└── Documentation\       # Application documentation (optional)
```

## Troubleshooting

### Common Issues

1. **"Access Denied" Error**
   - Ensure you're running PowerShell as Administrator
   - Check User Account Control (UAC) settings

2. **User Already Exists**
   - Delete existing accounts before running the script
   - Or use specific parameters to create only the needed account

3. **Permission Issues**
   - Verify the shared folder permissions
   - Check group memberships for created accounts

### Verification Commands

```powershell
# Check created users
Get-LocalUser | Where-Object {$_.Name -in @("Admin", "iBridge User")}

# Check group memberships
Get-LocalGroupMember -Group "Administrators"
Get-LocalGroupMember -Group "Users"

# Check shared folder permissions
Get-Acl "C:\iBridge_Apps" | Format-List
```

## Next Steps

After running the account creation script:

1. **Application Installation Phase**
   - Create application installation script
   - Define list of applications to install
   - Set up automated installation process

2. **Shortcut Management**
   - Create shortcut creation scripts
   - Organize applications by category
   - Set up desktop/start menu shortcuts

3. **Testing and Validation**
   - Test all applications from both accounts
   - Verify permission restrictions work correctly
   - Document any issues or additional requirements

## Support

For issues or questions, please refer to the troubleshooting section or contact the development team.
