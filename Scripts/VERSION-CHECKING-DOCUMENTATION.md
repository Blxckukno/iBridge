# iBridge Enhanced Setup - Version Checking Documentation

## Overview
The iBridge Enhanced Setup script now includes comprehensive version checking and upgrade detection capabilities to handle existing installations intelligently.

## New Features Added

### 1. Version Checking
- **Automatic Detection**: Scans Windows registry to detect existing application installations
- **Version Comparison**: Compares installed versions with required versions
- **Smart Skipping**: Skips installations for applications that are already up-to-date

### 2. Application Version Tracking
The script now tracks specific versions for each application:
- **24.2.2000.exe**: Version 24.2.2000 (SYSPRO)
- **AnyDesk.exe**: Version 7.0.0
- **GlassWireSetup.exe**: Version 3.0.0
- **PBIDesktopSetup_x64.exe**: Version 2023.11 (Power BI Desktop)
- **TeamViewer_Setup_x64.exe**: Version 15.65.6
- **Tools for Office2019 TechXander**: Version 2019.1

### 3. Installation State Management
- **VERSION.txt**: Stores the setup script version (currently 2.0.0)
- **INSTALLATION-INFO.json**: Detailed installation information including:
  - Setup version and date
  - Application versions found/installed
  - Installation status for each application

### 4. Enhanced Logging
- Detailed logs of version checking process
- Skip notifications for up-to-date applications
- Installation status tracking

## How It Works

### Step-by-Step Process:
1. **Discovery**: Finds all application files on D: drive
2. **Version Check**: Scans registry for existing installations
3. **Comparison**: Compares found versions with required versions
4. **Decision**: Determines which applications to skip vs. install/update
5. **Installation**: Processes only applications that need installation/updates
6. **Tracking**: Saves version information for future reference

### Registry Scanning:
The script checks these registry locations:
- `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*`
- `HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*`
- `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*`

### Smart Installation Logic:
- **Already Up-to-Date**: Skips installation, logs as successful
- **Outdated Version**: Proceeds with installation/upgrade
- **Not Installed**: Proceeds with fresh installation
- **Version Unknown**: Proceeds with installation (safer approach)

## Benefits

### 1. Efficiency
- Reduces installation time by skipping unnecessary installations
- Prevents reinstalling applications that are already current

### 2. Safety
- Avoids potential conflicts from unnecessary reinstallations
- Preserves user settings and configurations

### 3. Reporting
- Clear indication of what was skipped vs. installed
- Detailed version information for troubleshooting

### 4. Future-Proofing
- Version tracking allows for easier updates and maintenance
- Installation history for audit purposes

## Usage Notes

### First Run:
- All applications will be checked and installed as needed
- Version information will be saved for future runs

### Subsequent Runs:
- Only outdated or missing applications will be installed
- Up-to-date applications will be skipped with notification

### Logs and Files Created:
- Setup logs in `C:\iBridge_Setup\Logs\`
- Version file: `C:\iBridge_Setup\VERSION.txt`
- Installation info: `C:\iBridge_Setup\INSTALLATION-INFO.json`
- Setup summary: `C:\iBridge_Setup\SETUP-SUMMARY.txt`

## Script Compatibility
- Compatible with existing iBridge setup infrastructure
- Maintains all previous functionality
- Enhanced user feedback and reporting
- Backward compatible with previous setups

## File Locations
- **Main Script**: `iBridge-Enhanced-Setup.ps1`
- **USB Package**: `D:\iBridge Set Up\`
- **Installation Base**: `C:\iBridge_Setup\`

---
*Version 2.0.0 - Enhanced with Version Checking and Upgrade Detection*
