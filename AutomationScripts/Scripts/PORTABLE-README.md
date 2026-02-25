# iBridge Portable Setup Package

## Overview
This is a completely portable setup package that can be copied to any Windows computer and run from any location (USB drive, network folder, local drive, etc.). The setup will automatically detect its location and find application files relative to the script location.

## What This Package Does
1. **Creates Windows User Accounts**:
   - Admin Account: "Admin" (Password: IBr1dG3Pc)
   - Standard User: "iBridge User" (Password: Abc654321!)

2. **Installs Applications**: 
   - Automatically finds and installs applications from the same folder or subfolders
   - Copies installers to C:\iBridge_Apps
   - Runs installations with appropriate silent flags

3. **Creates Desktop Shortcuts**:
   - Places shortcuts on both user desktops
   - Automatically detects installed applications

4. **Sets Up Permissions**:
   - Configures proper folder access for both users

## Package Contents
- `iBridge-Portable-Setup.ps1` - Main PowerShell script (portable version)
- `RUN-PORTABLE-SETUP.bat` - One-click launcher with admin elevation
- `PORTABLE-README.md` - This documentation file
- Application files (place in same folder or subfolders)

## How to Use

### Method 1: Quick Start (Recommended)
1. Copy this entire folder to any location (USB drive, computer, etc.)
2. Right-click `RUN-PORTABLE-SETUP.bat` 
3. Select "Run as administrator"
4. Follow the on-screen prompts

### Method 2: Manual PowerShell
1. Open PowerShell as Administrator
2. Navigate to the folder containing the scripts
3. Run: `.\iBridge-Portable-Setup.ps1`

## Application File Organization

The script will automatically search for application files in these locations (relative to script location):

1. **Same folder as script** (recommended for small packages)
   ```
   USB Drive/
   ├── iBridge-Portable-Setup.ps1
   ├── RUN-PORTABLE-SETUP.bat
   ├── TeamViewer_Setup_x64.exe
   ├── AnyDesk.exe
   └── 24.2.2000.exe
   ```

2. **Apps subfolder** (recommended for organized packages)
   ```
   USB Drive/
   ├── iBridge-Portable-Setup.ps1
   ├── RUN-PORTABLE-SETUP.bat
   └── Apps/
       ├── TeamViewer_Setup_x64.exe
       ├── AnyDesk.exe
       └── 24.2.2000.exe
   ```

3. **Other supported subfolders**:
   - `Applications/`
   - `Installers/`
   - Parent folder of the script

## Supported Application Files

The script will automatically detect and install these files if found:

- `TeamViewer_Setup_x64.exe` - Remote desktop software
- `Tools for Office2019 TechXander/` - Office tools suite (folder)
- `24.2.2000.exe` - Business application
- `AnyDesk.exe` - Remote desktop software  
- `PBIDesktopSetup_x64.exe` - Microsoft Power BI Desktop
- `Teams_windows_x64.exe` - Microsoft Teams

## Portability Features

✅ **No hardcoded drive letters** - Works from any drive  
✅ **Automatic path detection** - Finds files relative to script location  
✅ **Flexible file organization** - Multiple folder structures supported  
✅ **Self-contained** - All dependencies included in package  
✅ **Admin elevation** - Batch file handles privilege escalation  
✅ **Error handling** - Graceful fallbacks if files not found  

## Requirements

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.0 or higher (included in Windows 10/11)
- Administrator privileges (handled automatically by batch file)
- At least 2GB free space on C: drive

## Troubleshooting

### "Execution policy" errors
The batch file will automatically handle PowerShell execution policy issues. If you still get errors, run this in PowerShell as Administrator:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Application files not found"
- Ensure application files are in the same folder as the script OR
- Create an "Apps" subfolder and place files there OR  
- Check the console output to see which paths were searched

### "Access denied" errors
- Make sure you're running as Administrator
- Check that the target drive (C:) has sufficient space
- Ensure Windows User Account Control is not blocking the operation

### Script fails partway through
- The script will show detailed progress and error messages
- Each step can be run independently if needed
- Check the PowerShell console for specific error details

## Security Notes

⚠️ **Administrator Required**: This script creates user accounts and installs software, requiring admin privileges  
⚠️ **Passwords in Script**: Account passwords are stored in plain text in the script for automation  
⚠️ **Silent Installations**: Applications are installed silently without user prompts  
⚠️ **Execution Policy**: The batch file may temporarily change PowerShell execution policy  

## Customization

To modify this package for your needs:

1. **Change Passwords**: Edit the variables in the PowerShell script:
   ```powershell
   $AdminPassword = "your_admin_password"
   $UserPassword = "your_user_password"
   ```

2. **Add Applications**: Place new installer files in the package and add them to the `$ApplicationFiles` array

3. **Change Destination**: Modify the `$DestinationFolder` variable to change where apps are installed

## Support

This portable setup package is designed to work on any Windows computer without modification. If you encounter issues:

1. Check the console output for specific error messages
2. Ensure all application files are present in the expected locations  
3. Verify you have Administrator privileges
4. Make sure the target computer has sufficient disk space

---
**Version**: Portable Edition  
**Compatible**: Windows 10/11, Windows Server 2016+  
**Last Updated**: August 2025
