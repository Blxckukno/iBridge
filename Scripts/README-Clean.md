# iBridge Setup Package - Clean & Streamlined

## 📦 **Package Contents**

This streamlined package contains only the essential files needed for the complete iBridge setup:

### 🚀 **Main Setup Files**
- **`START-HERE-MENU.bat`** - Easy menu launcher (Run as Administrator)
- **`RUN-ENHANCED-SETUP.bat`** - Direct enhanced setup launcher
- **`iBridge-Enhanced-Setup.ps1`** - Main PowerShell script (enhanced version)

### 🔍 **Utility Files**
- **`Check-Required-Files.ps1`** - Verify all required files exist before setup

### 📖 **Documentation**
- **`ENHANCED-README.md`** - Complete feature documentation
- **`SPECIFIC-FILES-README.md`** - List of files that will be installed
- **`README.md`** - This overview file

## 🎯 **Quick Start Guide**

### Step 1: Copy Package
Copy this entire folder to any Windows computer

### Step 2: Run Setup
Right-click **`START-HERE-MENU.bat`** → "Run as administrator"

### Step 3: Choose Enhanced Setup
Select option 2 for the enhanced setup

### Step 4: Follow Progress
Watch the 7-step progress with detailed logging

## 📋 **What Gets Installed**

### Applications (6 total):
1. **24.2.2000.exe** - Business application
2. **AnyDesk.exe** - Remote desktop software
3. **GlassWire** - Network monitoring
4. **Power BI Desktop** - Microsoft BI tool
5. **TeamViewer** - Remote access software
6. **Tools for Office 2019** - Office tools suite

### User Accounts:
- **Admin** (Password: IBr1dG3Pc) - Administrator privileges
- **iBridge User** (Password: Abc654321!) - Standard user

### Shortcuts:
- All .lnk and .url files from D:\IT STUFF
- Placed on both user desktops
- Backed up in C:\iBridge_Setup\Shortcuts\

## 📁 **Organized Output**

Everything gets organized in: **`C:\iBridge_Setup\`**
```
C:\iBridge_Setup\
├── Installers\     (Application files)
├── Shortcuts\      (Desktop shortcuts backup)
├── Scripts\        (This setup package)
├── Logs\           (Detailed setup logs)
└── SETUP-SUMMARY.txt
```

## ✅ **Features**

- ✅ **Profile Creation**: Forces user profile creation for shortcuts
- ✅ **Progress Tracking**: 7-step progress with percentages
- ✅ **Detailed Logging**: Complete logs in C:\iBridge_Setup\Logs\
- ✅ **Shortcut Verification**: Confirms shortcuts appear on desktops
- ✅ **Clean Organization**: Everything in one structured folder
- ✅ **Silent Installation**: All apps install without prompts

## 🔧 **Requirements**

- Windows 10/11 with Administrator privileges
- Files must exist on D: drive:
  - D:\24.2.2000.exe
  - D:\AnyDesk.exe  
  - D:\GlassWireSetup.exe
  - D:\PBIDesktopSetup_x64.exe
  - D:\TeamViewer_Setup_x64.exe
  - D:\Tools for Office2019 TechXander\
  - D:\IT STUFF\

## 🚨 **Troubleshooting**

1. **Check files exist**: Run `Check-Required-Files.ps1` first
2. **Check logs**: Look in C:\iBridge_Setup\Logs\ for detailed info
3. **Verify shortcuts**: Log in as 'iBridge User' to see desktop shortcuts
4. **Read documentation**: Check ENHANCED-README.md for full details

---
**Version**: Streamlined Package  
**Files**: Essential only  
**Last Updated**: August 21, 2025
