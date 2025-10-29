# iBridge Offline Setup v3.0

## 🚀 **Complete Offline Installation Package**

This package works completely offline and automatically detects the USB drive letter (D:, E:, F:, etc.).

### 📋 **What Gets Installed**

#### **Admin Profile** gets:
- TeamViewer Setup x64
- 24.2.2000 application
- AnyDesk
- GlassWire Setup
- Power BI Desktop Setup x64
- Tools for Office 2019 TechXander
- Office shortcuts folder (Desktop-Mtn only)

**Excluded files (not installed):**
- epi_win_live_installer_2.exe
- ESET KEY.txt
- Log In - Genesys Cloud Accounts - Genesys.url
- prey-installer-bvS8INNySB1TrLK3.exe

#### **iBridge User Profile** gets:
**All Admin applications PLUS:**
- Word.lnk (shortcut)
- Excel.lnk (shortcut)
- Microsoft 365 Online.url
- MS Teams (full installation)
- New Citrix Gateway.url
- Outlook.lnk (shortcut)
- PowerPoint.lnk (shortcut)

### 🔧 **How to Use**

1. **Insert USB** into any Windows computer
2. **Double-click**: `RUN-OFFLINE-SETUP.bat`
3. **Click "Yes"** when prompted for Administrator rights
4. **Wait** for completion (5-10 minutes)

### 🛠️ **Troubleshooting**

#### **If AnyDesk Installation Hangs:**
1. **Stop the installation** (Ctrl+C in PowerShell)
2. **Run**: `FIX-ANYDESK-HANG.bat`
3. **This will**:
   - Disable AnyDesk installation
   - Install all other applications normally
   - Copy AnyDesk.exe to `C:\iBridge_Setup\Installers` for manual installation later

#### **Alternative Method:**
- Edit `iBridge-Offline-Setup.ps1`
- Change `$InstallAnyDesk = $true` to `$InstallAnyDesk = $false`
- Run the setup again

### 🎯 **Auto-Detection Features**

- ✅ **Auto-detects USB drive** (works on D:, E:, F:, etc.)
- ✅ **Completely offline** - no internet required
- ✅ **All files included** on USB
- ✅ **Profile isolation** - only specified items on each profile
- ✅ **Clean installation** - removes unwanted shortcuts
- ✅ **Live Progress Tracker** - Real-time task completion status with ETA
- ✅ **Visual Progress Bar** - See exactly what's happening and how long is left
- ✅ **Step-by-step Status** - Each task shows ✅ Completed, 🔄 In Progress, or ⏳ Pending

### 👥 **Account Details**

| Account | Username | Password | Type |
|---------|----------|----------|------|
| Administrator | Admin | IBr1dG3Pc | Admin Rights |
| Standard User | iBridge User | Abc654321! | Standard User |

### 📁 **File Structure**

```
USB Drive/
├── iBridge Set Up/
│   ├── RUN-OFFLINE-SETUP.bat    ← START HERE
│   ├── iBridge-Offline-Setup.ps1
│   └── [other setup files]
├── IT STUFF/
│   └── Desktop-Mtn/
│       ├── Word.lnk
│       ├── Excel.lnk
│       ├── Outlook.lnk
│       ├── PowerPoint.lnk
│       ├── Microsoft 365 Online.url
│       ├── New Citrix Gateway.url
│       └── MSTeamsSetup.exe
├── TeamViewer_Setup_x64.exe
├── 24.2.2000.exe
├── AnyDesk.exe
├── GlassWireSetup.exe
├── PBIDesktopSetup_x64.exe
└── Tools for Office2019 TechXander/
```

### 🛡️ **Profile Isolation**

- **Lwandile Gasela profile**: Untouched - all your personal apps remain
- **Admin profile**: Only the 7 specified iBridge applications
- **iBridge User profile**: iBridge applications + Office shortcuts + Teams

### 📝 **Logs and Verification**

- Setup logs: `C:\iBridge_Setup\Logs\`
- Summary report: `C:\iBridge_Setup\SETUP-SUMMARY.txt`
- All installations tracked and verified

---

## 🎉 **Ready to Deploy!**

Just plug in the USB and run `RUN-OFFLINE-SETUP.bat` - everything else is automatic!
