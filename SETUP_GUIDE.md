# iBridge Local Setup - Complete Guide

## 🚀 Quick Start (3 Steps)

### Step 1: Fix the PowerShell Issue (ONE TIME ONLY)
**Choose ONE method:**

#### Option A: VB Script (EASIEST) ✅ RECOMMENDED
```
1. Double-click: fix-powershell-issue.vbs
2. Follow prompts
3. Done!
```

#### Option B: Batch Script
```
1. Double-click: fix-powershell-issue.bat
2. Follow prompts
3. Done!
```

#### Option C: Manual Fix
```
1. Close OneDrive
2. Navigate to: C:\Users\Lwandile Gasela\OneDrive - iBridge Contact Solutions (Pty) Ltd\Documents\PowerShell
3. Rename: powershell.config.json → powershell.config.json.disabled
4. Restart computer
```

**Details:** See `POWERSHELL_FIX_GUIDE.md`

---

### Step 2: Start the Local Server
**Double-click one of:**
- `start-fixed.bat` (includes auto-fix) ✅ RECOMMENDED
- `start.bat` (basic startup)

**Or run manually:**
```bash
cd C:\Users\Lwandile Gasela\iBridge
python serve.py
```

**You should see:**
```
✨ iBridge Server Running!
📍 Local URL: http://localhost:8080
...
Press Ctrl+C to stop the server
```

---

### Step 3: Access the Website
Open your browser and visit:

| Page | URL |
|------|-----|
| 🏠 Main Site | http://localhost:8080 |
| 👥 Employee Intranet | http://localhost:8080/intranet.html |
| 📚 LMS Platform | http://localhost:8080/lms-platform.html |
| 🎫 Ticketing System | http://localhost:8080/TicketingSystem/frontend/professional-dashboard.html |
| 🛡️ Security Dashboard | http://localhost:8080/security-dashboard.html |

---

## 📁 Files Included

### Setup & Fix Scripts
```
fix-powershell-issue.vbs      ← VB Script (EASIEST FIX)
fix-powershell-issue.bat      ← Batch fix script
fix-powershell-issue.ps1      ← PowerShell fix script
start-fixed.bat               ← Start server with auto-fix
start.bat                     ← Simple startup
start-server.bat              ← Alternative startup
```

### Server Scripts
```
serve.py                      ← Python HTTP server (PRIMARY)
run-server.js                 ← Node.js HTTP server (BACKUP)
```

### Documentation
```
POWERSHELL_FIX_GUIDE.md       ← Complete fix guide
SETUP_GUIDE.md                ← This file
```

---

## ⚙️ System Requirements

✅ Windows 10 / Windows 11 / Windows Server
✅ Python 3.8+ (included with venv)
✅ Node.js 14+ (optional, for backup server)
✅ Browser (Chrome, Firefox, Edge, Safari)

---

## 🔧 Troubleshooting

### Problem: "localhost refused to connect"
**Solution:** 
1. Make sure the server is running (see Step 2)
2. Try a different port: http://localhost:8081
3. Check if port 8080 is already in use

### Problem: "Access Denied" when running fix scripts
**Solution:**
1. Right-click the script
2. Select "Run as Administrator"
3. Click "Yes" when prompted

### Problem: "Module not found" or import errors
**Solution:**
1. Python server: `python serve.py` should work (no dependencies)
2. Node.js server: `node run-server.js` should work (no npm install needed)

### Problem: OneDrive still interfering
**Solution:**
1. Close OneDrive: Right-click tray icon → Quit
2. Run the fix script
3. Restart your computer
4. Reopen OneDrive

---

## 📊 What Each Script Does

### VB Script (`fix-powershell-issue.vbs`)
- ✅ Renames problematic PowerShell config
- ✅ Works without administrator privileges
- ✅ Creates backup automatically
- ✅ User-friendly dialogs

### Batch Scripts
- `fix-powershell-issue.bat` - Fix the issue
- `start-fixed.bat` - Fix + Start server (ONE CLICK)
- `start.bat` - Start server only

### Python Server (`serve.py`)
- ✅ No dependencies needed
- ✅ Serves Website directory
- ✅ Adds security headers automatically
- ✅ Handles 404s gracefully
- Primary choice for development

### Node.js Server (`run-server.js`)
- ✅ Standalone executable
- ✅ Advanced security headers
- ✅ Fallback if Python unavailable
- Requires Node.js installed

---

## 🎯 Common Tasks

### Run Server Once (Development)
```bash
start-fixed.bat
```
Then access: http://localhost:8080

### Run Server with Auto-Fix
```bash
start-fixed.bat
```
This fixes PowerShell issue AND starts server

### Check if Port 8080 is Available
```bash
netstat -ano | findstr :8080
```
If results show, port is in use. Try port 8081.

### Stop Server
Press `Ctrl+C` in the terminal window running the server

---

## 🛡️ Security Features

The local development server includes:
- ✅ XSS protection headers
- ✅ Content-Type validation
- ✅ Path traversal prevention
- ✅ Automatic security headers
- ✅ MIME type detection
- ✅ Secure caching policies

---

## 📚 Next Steps

After server is running:

1. **Explore the main site:** http://localhost:8080
2. **Check employee intranet:** http://localhost:8080/intranet.html
3. **Try the LMS:** http://localhost:8080/lms-platform.html
4. **View security dashboard:** http://localhost:8080/security-dashboard.html (Ctrl+Shift+S)

---

## 💡 Tips

- **Keyboard shortcut:** Ctrl+Shift+S opens Security Dashboard
- **Dark mode:** Available on all pages
- **Mobile view:** Responsive on all devices
- **Offline mode:** PWA features available

---

## 🆘 Still Having Issues?

1. **Read:** `POWERSHELL_FIX_GUIDE.md` - Detailed fix documentation
2. **Try:** All three fix methods (one should work)
3. **Check:** Windows Event Viewer for system errors
4. **Restart:** Your computer (often fixes OneDrive issues)

---

## ✅ Checklist

- [ ] Run fix script (one of: .vbs, .bat, .ps1)
- [ ] Verify fix: No "cloud file provider" error
- [ ] Start server with `start-fixed.bat`
- [ ] Access http://localhost:8080 in browser
- [ ] Website loads successfully
- [ ] All navigation links work
- [ ] Ready for development!

---

**Last Updated:** May 5, 2026
**Status:** ✅ Ready for Local Development
