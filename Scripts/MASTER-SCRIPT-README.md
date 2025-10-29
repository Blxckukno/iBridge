# iBridge Complete Setup - Master Script Documentation

## 🎯 **MASTER SCRIPT CREATED: `iBridge-Complete-Setup.ps1`**

This single script performs the entire iBridge setup process from start to finish.

### 📋 **What the Master Script Does:**

**Step 1: Creates User Accounts**
- ✅ Admin account (Username: `Admin`, Password: `IBr1dG3Pc`)
- ✅ iBridge User account (Username: `iBridge User`, Password: `Abc654321!`)
- ✅ Proper group memberships and permissions

**Step 2: Creates Folder Structure**
- ✅ `C:\iBridge_Apps\` (base directory)
- ✅ `C:\iBridge_Apps\Installers\` (applications)
- ✅ `C:\iBridge_Apps\Shortcuts\` (shared shortcuts)
- ✅ Proper folder permissions for both users

**Step 3: Installs Applications**
- ✅ TeamViewer (Remote Desktop)
- ✅ Tools for Office 2019 TechXander
- ✅ Application 24.2.2000
- ✅ AnyDesk (Remote Desktop)
- ✅ Power BI Desktop
- ✅ Microsoft Teams
- ✅ All copied to C: drive and installed

**Step 4: Creates Shortcuts**
- ✅ Excel.lnk
- ✅ Microsoft 365 Online.url
- ✅ New Citrix Gateway.url
- ✅ Outlook.lnk
- ✅ PowerPoint.lnk
- ✅ Word.lnk
- ✅ Available in shared folder and user desktops

**Step 5: Generates Final Report**
- ✅ Verification of all created accounts
- ✅ Summary of installed applications
- ✅ Complete folder structure overview
- ✅ Next steps for testing

### 🚀 **How to Run the Master Script:**

**Option 1: One-Click Batch File (Easiest)**
```cmd
RUN-COMPLETE-SETUP.bat
```
Double-click this file and it will handle everything automatically.

**Option 2: PowerShell as Administrator**
```powershell
.\iBridge-Complete-Setup.ps1
```

**Option 3: With Parameters**
```powershell
# Skip file validation (faster)
.\iBridge-Complete-Setup.ps1 -SkipValidation

# Run in quiet mode (no pause)
.\iBridge-Complete-Setup.ps1 -QuietMode

# Both options
.\iBridge-Complete-Setup.ps1 -SkipValidation -QuietMode
```

### 📁 **Script Files Created:**

| File | Purpose |
|------|---------|
| `iBridge-Complete-Setup.ps1` | **MASTER SCRIPT** - Does everything |
| `RUN-COMPLETE-SETUP.bat` | One-click launcher |
| `Test-Setup-Ready.ps1` | Validation script |
| `Create-Accounts-Fixed.ps1` | Individual account creation |
| `Install-Apps-And-Shortcuts.ps1` | Individual app installation |
| `Check-Installation-Status.ps1` | Status monitoring |

### ⚙️ **Configuration Section:**

All settings are configurable at the top of the master script:
- Account usernames and passwords
- Application paths and install arguments
- Shortcut sources
- Target directories

### 🧪 **Testing the Setup:**

After running the master script:

1. **Verify Accounts**: Try logging in as both Admin and iBridge User
2. **Check Applications**: Verify installations in `C:\iBridge_Apps\Installers`
3. **Test Shortcuts**: Use shortcuts from `C:\iBridge_Apps\Shortcuts`
4. **Desktop Shortcuts**: Check both user desktops for shortcuts

### 📊 **Expected Results:**

- ✅ 2 user accounts created and enabled
- ✅ 6 applications installed/copied to C: drive
- ✅ 6 shortcuts available in shared folder
- ✅ Desktop shortcuts for both users
- ✅ Complete folder structure with proper permissions

### 🔧 **Troubleshooting:**

**If the script fails:**
1. Ensure running as Administrator
2. Check all source files are accessible
3. Review the detailed error messages
4. Run individual scripts for specific steps

**Common Issues:**
- Missing source files on D: drive
- Insufficient administrator privileges
- Antivirus blocking installations
- Network drives not accessible

### 🎉 **Success Indicators:**

When the script completes successfully, you'll see:
- Green "SUCCESS" messages for each step
- Final report showing all accounts and files
- "ALL STEPS COMPLETED SUCCESSFULLY!" message
- Ability to log in as iBridge User with password `Abc654321!`

---

## ✅ **READY TO DEPLOY!**

The master script is now ready to deploy the complete iBridge system with a single command!
