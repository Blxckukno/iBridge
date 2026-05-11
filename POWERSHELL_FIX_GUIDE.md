# PowerShell OneDrive Configuration Issue - Complete Fix Guide

## Problem Summary
Your system is experiencing an issue where PowerShell cannot start due to an inaccessible OneDrive configuration file. This causes the error:
```
"Cannot read the configuration file: The cloud file provider is not running"
```

**Root Cause:** The PowerShell configuration file is located in an OneDrive synchronized folder, but the cloud file provider is not running or accessible.

---

## Quick Fix (Choose One Method)

### ✅ Method 1: VB Script (EASIEST - No Admin Required)
**Steps:**
1. In **File Explorer**, navigate to: `C:\Users\Lwandile Gasela\iBridge`
2. **Double-click** `fix-powershell-issue.vbs`
3. Follow the prompts
4. Done! ✓

**Advantages:**
- Works without administrator privileges
- Simple point-and-click
- Works on any Windows version

---

### ✅ Method 2: Batch File
**Steps:**
1. In **File Explorer**, navigate to: `C:\Users\Lwandile Gasela\iBridge`
2. **Double-click** `fix-powershell-issue.bat`
3. Follow the prompts
4. Done! ✓

**Advantages:**
- Transparent - you see what's happening
- Can be run from any location
- Provides detailed output

---

### ✅ Method 3: PowerShell Script
**Steps:**
1. Open **PowerShell as Administrator**
2. Run the command:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\Users\Lwandile Gasela\iBridge\fix-powershell-issue.ps1"
   ```
3. Follow the prompts
4. Done! ✓

**Advantages:**
- Detailed error reporting
- Professional approach
- Good if you're comfortable with PowerShell

---

### ✅ Method 4: Manual Fix (If Scripts Don't Work)
**Steps:**
1. **Close OneDrive** (right-click OneDrive icon in system tray → Quit)
2. Open **File Explorer**
3. Navigate to: `C:\Users\Lwandile Gasela\OneDrive - iBridge Contact Solutions (Pty) Ltd\Documents\PowerShell`
4. Find the file: `powershell.config.json`
5. Right-click → **Rename** to `powershell.config.json.disabled`
6. **Restart your computer** or open a new terminal

---

## What Gets Fixed

After running any fix method:

| Issue | Before | After |
|-------|--------|-------|
| PowerShell startup | ❌ Fails | ✅ Works |
| Terminal commands | ❌ Error | ✅ Normal |
| Server startup | ❌ Cannot run | ✅ Works |
| Development tools | ❌ Blocked | ✅ Available |

---

## After Fix - Start the Server

Once the PowerShell issue is fixed, you can start the local server:

### Option 1: Use Fixed Startup Script
1. **Double-click** `start-fixed.bat` in the iBridge folder
2. Your server starts automatically!

### Option 2: Manual Start
```bash
cd C:\Users\Lwandile Gasela\iBridge
python serve.py
```

### Option 3: Node.js
```bash
cd C:\Users\Lwandile Gasela\iBridge
node run-server.js
```

---

## Accessing the Website

Once server is running, visit:
- 🏠 Main Site: http://localhost:8080
- 👥 Intranet: http://localhost:8080/intranet.html
- 📚 LMS: http://localhost:8080/lms-platform.html
- 🎫 Tickets: http://localhost:8080/TicketingSystem/frontend/professional-dashboard.html

---

## Troubleshooting

### Scripts Say "Access Denied"
**Solution:** Run as Administrator
1. Right-click the `.bat` or `.vbs` file
2. Select "Run as administrator"
3. Click "Yes" when prompted

### OneDrive Sync Issues
**Solution:** Pause OneDrive sync temporarily
1. Click OneDrive icon (bottom right system tray)
2. Click menu (•••) → "Pause syncing"
3. Run the fix script
4. Restart OneDrive

### Still Getting Error After Fix
**Solution:** Check if file was actually renamed
1. Open File Explorer
2. Navigate to: `C:\Users\Lwandile Gasela\OneDrive - iBridge Contact Solutions (Pty) Ltd\Documents\PowerShell`
3. Look for: `powershell.config.json.disabled`
4. If not there, manually rename the file (see Method 4 above)

---

## Files Included

```
iBridge/
├── fix-powershell-issue.vbs    ← VB Script (EASIEST)
├── fix-powershell-issue.bat    ← Batch script
├── fix-powershell-issue.ps1    ← PowerShell script
├── start-fixed.bat             ← Start server with auto-fix
├── serve.py                    ← Python HTTP server
├── run-server.js               ← Node.js HTTP server
└── POWERSHELL_FIX_GUIDE.md     ← This file
```

---

## What Files Are Modified

When you run any fix:
- **Original file:** `powershell.config.json` 
  - **Renamed to:** `powershell.config.json.disabled`
  - **Backup created:** `powershell.config.json.backup` (if applicable)

All files are in the PowerShell folder. Nothing else is modified.

---

## Reverting the Fix (If Needed)

If you need to restore the original PowerShell configuration:

1. Navigate to: `C:\Users\Lwandile Gasela\OneDrive - iBridge Contact Solutions (Pty) Ltd\Documents\PowerShell`
2. Right-click `powershell.config.json.disabled`
3. Select "Rename" 
4. Change to `powershell.config.json`
5. Restart PowerShell

---

## Prevention

To prevent this issue from recurring:

1. **Move PowerShell config outside OneDrive:**
   - Open File Explorer
   - Right-click the OneDrive PowerShell folder
   - Select "Always keep on this device" (if available)
   - This ensures files aren't cloud-synced

2. **Exclude PowerShell folder from sync:**
   - Open OneDrive settings
   - Go to "Sync & backup"
   - Uncheck the PowerShell folder

---

## Questions or Issues?

If you're still experiencing problems:
1. Try **Method 1 (VB Script)** - most reliable
2. Run as **Administrator** - ensures file permissions
3. **Close OneDrive** temporarily during the fix
4. **Restart your computer** after running the fix

---

**Status:** Once fix is complete, your development environment is ready! ✓
