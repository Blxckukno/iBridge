# iBridge USB Deployment Package
## Complete Setup Solution for Multiple Devices

### 📦 What's Included:
- **USB-DEPLOYMENT-MENU.bat** - Main menu launcher
- **RUN-ENHANCED-SETUP-FIXED.bat** - Fixed version that uses correct drive detection
- **SETUP-LOCAL-DISK.ps1** - Copy files to local disk for USB independence
- **NETWORK-DEPLOYMENT.ps1** - Deploy to multiple devices via network
- **CREATE-SHORTCUT.ps1** - Create desktop shortcuts

### 🚀 Quick Start:

#### Option 1: Interactive Menu (Recommended)
```
Double-click: USB-DEPLOYMENT-MENU.bat
```

#### Option 2: Direct Fixed Setup
```
Right-click RUN-ENHANCED-SETUP-FIXED.bat → Run as Administrator
```

#### Option 3: Local Disk Independence
```
Right-click PowerShell → Run as Administrator
Set-ExecutionPolicy Bypass -Scope Process
.\SETUP-LOCAL-DISK.ps1
```

### 🔧 What Each Setup Does:

#### **RUN-ENHANCED-SETUP-FIXED.bat**
- ✅ **FIXED** - Uses correct C: drive paths (not D: drive)
- Creates Admin account (Password: IBr1dG3Pc)
- Creates iBridge User account (Password: Abc654321!)
- Installs all 4 applications from correct locations
- Shows clear progress and error handling

#### **SETUP-LOCAL-DISK.ps1**
- Copies all files from USB to C:\iBridge_Local_Setup\
- Creates local launcher for USB independence
- Allows USB to be used for other purposes
- Maintains all functionality on local drive

#### **NETWORK-DEPLOYMENT.ps1**
- Deploys to multiple devices via network
- Targets iBridge-JHB-* hotspot devices
- Automated bulk deployment

### 📋 User Accounts Created:
- **Admin** (Full privileges, Password: IBr1dG3Pc)
- **iBridge User** (Standard user, Password: Abc654321!)

### 📱 Applications Installed:
- TeamViewer
- 24.2.2000
- GlassWire
- Power BI Desktop

### 🛠️ Troubleshooting:

**If you get "files not found" errors:**
- Use RUN-ENHANCED-SETUP-FIXED.bat (drive detection is fixed)
- Ensure all .exe files are present on the same drive

**For USB independence:**
- Run SETUP-LOCAL-DISK.ps1 first
- Then use the local installation

**For multiple devices:**
- Connect devices to iBridge-JHB-* hotspot
- Run NETWORK-DEPLOYMENT.ps1

### ⚠️ Important Notes:
- All scripts require Administrator privileges
- The FIXED version corrects the D: vs C: drive detection issue
- Log out and log in as "iBridge User" after setup completes

---
Generated: August 22, 2025
Fixed Drive Detection Issue: ✅ RESOLVED
