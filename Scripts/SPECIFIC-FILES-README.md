# iBridge Setup - Specific Files Only

## 📋 Files That Will Be Installed

The enhanced script has been configured to install ONLY these specific files:

### 🔧 **Applications to Install**
1. **24.2.2000.exe** 
   - Location: `D:\24.2.2000.exe`
   - Install Arguments: `/SILENT`
   - Description: Business application

2. **AnyDesk.exe**
   - Location: `D:\AnyDesk.exe` 
   - Install Arguments: `--silent`
   - Description: Remote desktop software

3. **GlassWire Setup**
   - Location: `D:\GlassWireSetup.exe`
   - Install Arguments: `/S`
   - Description: Network monitoring software

4. **Power BI Desktop**
   - Location: `D:\PBIDesktopSetup_x64.exe`
   - Install Arguments: `/quiet`
   - Description: Microsoft Power BI Desktop

5. **TeamViewer**
   - Location: `D:\TeamViewer_Setup_x64.exe`
   - Install Arguments: `/S`
   - Description: Remote desktop software

6. **Tools for Office 2019 TechXander** (Folder)
   - Location: `D:\Tools for Office2019 TechXander`
   - Type: Folder copy (no installation)
   - Description: Office tools suite

### 📎 **Shortcuts Source Locations**
- **IT STUFF Folder**: `D:\IT STUFF` (searches for .lnk and .url files)
- **iBridge Set Up Folder**: `D:\iBridge Set Up` (searches for .lnk and .url files)

## ✅ **What the Enhanced Script Does**

1. **Creates User Accounts**:
   - Admin (Password: IBr1dG3Pc)
   - iBridge User (Password: Abc654321!)

2. **Installs Applications**:
   - Copies installers to `C:\iBridge_Setup\Installers\`
   - Runs silent installations with specified arguments
   - Copies Tools for Office folder directly

3. **Creates Shortcuts**:
   - Finds all .lnk and .url files in specified folders
   - Copies them to both user desktops
   - Backs them up in `C:\iBridge_Setup\Shortcuts\`

4. **Organizes Everything**:
   - All files go to `C:\iBridge_Setup\`
   - Detailed logs in `C:\iBridge_Setup\Logs\`
   - Progress tracking throughout

## 🚀 **How to Run**

### Option 1: Use the Menu (Recommended)
1. Right-click `START-HERE-MENU.bat` → "Run as administrator"
2. Choose option 2 for Enhanced Setup
3. Follow the progress

### Option 2: Direct Enhanced Setup
1. Right-click `RUN-ENHANCED-SETUP.bat` → "Run as administrator"
2. Follow the progress

## 📊 **Expected Results**

After running the setup:
- **6 applications** will be installed/copied
- **All shortcuts** from IT STUFF and iBridge Set Up folders will be on both user desktops
- **Everything organized** in `C:\iBridge_Setup\`
- **Detailed logs** showing exactly what happened

## ⚠️ **Requirements**

Make sure these files exist before running:
- ✅ `D:\24.2.2000.exe`
- ✅ `D:\AnyDesk.exe`
- ✅ `D:\GlassWireSetup.exe`
- ✅ `D:\PBIDesktopSetup_x64.exe`
- ✅ `D:\TeamViewer_Setup_x64.exe`
- ✅ `D:\Tools for Office2019 TechXander\` (folder)
- ✅ `D:\IT STUFF\` (folder with shortcuts)

The script will show warnings for any missing files and continue with the ones that are found.

---
**Version**: Enhanced - Specific Files Only  
**Last Updated**: August 21, 2025
