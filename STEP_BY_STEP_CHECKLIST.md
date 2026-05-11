# iBridge Local Setup - STEP BY STEP CHECKLIST

## ✅ BEFORE YOU START
- [ ] You are on Windows 10, Windows 11, or Windows Server
- [ ] You have access to File Explorer
- [ ] You have a web browser (Chrome, Firefox, Edge, Safari)
- [ ] You have the iBridge folder: C:\Users\Lwandile Gasela\iBridge

---

## PHASE 1: FIX POWERSHELL ISSUE (Do This First)

### Option A: VB Script Method (EASIEST) ✅

- [ ] Open File Explorer
- [ ] Navigate to: C:\Users\Lwandile Gasela\iBridge
- [ ] Find the file: **fix-powershell-issue.vbs**
- [ ] Double-click the file
- [ ] Wait for dialog box to appear
- [ ] Click OK or follow prompts
- [ ] Look for success message
- [ ] Close the dialog

✓ **PowerShell issue is FIXED**

### Option B: Batch Script Method

- [ ] Open File Explorer
- [ ] Navigate to: C:\Users\Lwandile Gasela\iBridge
- [ ] Find the file: **fix-powershell-issue.bat**
- [ ] Double-click the file
- [ ] A command window appears
- [ ] Read the output
- [ ] Look for: "Successfully disabled problematic file!"
- [ ] Press any key when prompted
- [ ] Close the window

✓ **PowerShell issue is FIXED**

### Option C: Manual Method

- [ ] Close OneDrive (right-click the OneDrive icon in system tray → Quit)
- [ ] Wait 5 seconds for OneDrive to close
- [ ] Open File Explorer
- [ ] Copy this path: C:\Users\Lwandile Gasela\OneDrive - iBridge Contact Solutions (Pty) Ltd\Documents\PowerShell
- [ ] Paste it in File Explorer address bar
- [ ] Press Enter
- [ ] Find the file: **powershell.config.json**
- [ ] Right-click the file
- [ ] Select: Rename
- [ ] Change name to: **powershell.config.json.disabled**
- [ ] Press Enter
- [ ] Close File Explorer
- [ ] Restart your computer

✓ **PowerShell issue is FIXED**

---

## PHASE 2: VERIFY FIX WORKED

- [ ] Open Command Prompt (Win+R → cmd → Enter)
- [ ] Run: echo test
- [ ] You should see: test
- [ ] Command executed without error?
- [ ] If YES: ✓ Fix worked!
- [ ] If NO: Try a different fix method from Phase 1

---

## PHASE 3: START THE LOCAL SERVER

### Option A: One-Click Startup (EASIEST) ✅

- [ ] Open File Explorer
- [ ] Navigate to: C:\Users\Lwandile Gasela\iBridge
- [ ] Find: **start-fixed.bat**
- [ ] Double-click the file
- [ ] A command window opens
- [ ] Wait for message: "iBridge Local Server Running!"
- [ ] You see: "Press Ctrl+C to stop the server"
- [ ] Browser might open automatically
- [ ] If browser doesn't open, go to Phase 4

✓ **Server is RUNNING**

### Option B: Alternative Startup

- [ ] Open File Explorer
- [ ] Navigate to: C:\Users\Lwandile Gasela\iBridge
- [ ] Find: **start.bat**
- [ ] Double-click the file
- [ ] Wait for server to start
- [ ] Note the port number (default: 8080)
- [ ] Go to Phase 4

✓ **Server is RUNNING**

### Option C: Manual Startup

- [ ] Open Command Prompt
- [ ] Run: cd C:\Users\Lwandile Gasela\iBridge
- [ ] Run: python serve.py
- [ ] Wait for: "iBridge Server Running!"
- [ ] Note the port (usually 8080)
- [ ] Go to Phase 4

✓ **Server is RUNNING**

---

## PHASE 4: ACCESS THE WEBSITE

### Open Main Site

- [ ] Open your web browser (Chrome, Firefox, Edge, Safari)
- [ ] In address bar, type: **http://localhost:8080**
- [ ] Press Enter
- [ ] Page loads successfully?
- [ ] If YES: ✓ Website is working!
- [ ] If NO: Check "Troubleshooting" section below

### Verify Navigation

- [ ] Click on different pages (Services, About, Contact, etc.)
- [ ] Links work correctly?
- [ ] ✓ Navigation verified!

### Try Other Pages

- [ ] Employee Intranet: http://localhost:8080/intranet.html
- [ ] LMS Platform: http://localhost:8080/lms-platform.html
- [ ] Ticketing System: http://localhost:8080/TicketingSystem/frontend/professional-dashboard.html
- [ ] Security Dashboard: http://localhost:8080/security-dashboard.html
- [ ] All pages load?
- [ ] ✓ All pages working!

---

## PHASE 5: STOP THE SERVER (When Done)

- [ ] Click the Command Prompt window where server is running
- [ ] Press: **Ctrl+C**
- [ ] You'll see: "KeyboardInterrupt" or similar
- [ ] Command window closes or returns to prompt
- [ ] ✓ Server STOPPED

---

## ✅ TROUBLESHOOTING CHECKLIST

### Problem: "localhost refused to connect"

- [ ] Is the server running? (See Phase 3)
- [ ] Try http://localhost:8081 (different port)
- [ ] Try http://127.0.0.1:8080 (IP address instead)
- [ ] Wait 5 seconds after starting server
- [ ] Still not working? Try Port Check below

**Port Check:**
- [ ] Open Command Prompt
- [ ] Run: netstat -ano | findstr :8080
- [ ] If results show, port 8080 is in use
- [ ] Try port 8081 or 8082 instead

**Solution:**
- [ ] Close the application using port 8080
- [ ] Or start server with: python serve.py (let it auto-select port)

---

### Problem: "Access Denied" Error on Fix Scripts

- [ ] Right-click the fix script (.vbs or .bat)
- [ ] Select: **Run as Administrator**
- [ ] Click: **Yes** when prompted
- [ ] Follow instructions in Phase 1 again
- [ ] ✓ Should work now

---

### Problem: Still Getting PowerShell Error

- [ ] Close OneDrive: Right-click tray → Quit
- [ ] Wait 10 seconds
- [ ] Try the fix script again (any method from Phase 1)
- [ ] Restart your computer after fix
- [ ] ✓ Should be resolved

---

### Problem: Server Won't Start

**Check 1: Python installed?**
- [ ] Open Command Prompt
- [ ] Run: python --version
- [ ] You should see: Python 3.x.x
- [ ] If error: Try Node.js below

**Check 2: Try Node.js Server**
- [ ] Open Command Prompt
- [ ] Run: cd C:\Users\Lwandile Gasela\iBridge
- [ ] Run: node run-server.js
- [ ] Server starts?
- [ ] ✓ Use Node.js server instead

**Check 3: Port Issue**
- [ ] Run: netstat -ano | findstr :8080
- [ ] Port already in use?
- [ ] Close the application using it
- [ ] Try again

---

### Problem: Browser Shows Blank Page or 404 Error

- [ ] Server is running in command window?
- [ ] URL is correct: http://localhost:8080
- [ ] Refresh page (F5 or Ctrl+R)
- [ ] Hard refresh (Ctrl+Shift+R)
- [ ] Clear browser cache
- [ ] Try different browser
- [ ] ✓ Should load now

---

## 🎉 SUCCESS CHECKLIST

Once everything is working:

- [ ] ✓ PowerShell issue is FIXED (Phase 1)
- [ ] ✓ Fix was VERIFIED (Phase 2)
- [ ] ✓ Server is RUNNING (Phase 3)
- [ ] ✓ Website LOADS (Phase 4 - Main Site)
- [ ] ✓ Navigation WORKS (Phase 4 - Verify)
- [ ] ✓ Other pages LOAD (Phase 4 - Try Other Pages)
- [ ] ✓ Server STOPS properly (Phase 5)
- [ ] ✓ No error messages
- [ ] ✓ All features working

---

## 📝 DAILY WORKFLOW

### Each Time You Want to Develop:
1. [ ] Double-click: **start-fixed.bat**
2. [ ] Wait for: "iBridge Server Running!"
3. [ ] Open: http://localhost:8080
4. [ ] Make your changes
5. [ ] Test in browser
6. [ ] Press Ctrl+C to stop when done

### That's it! No need to fix PowerShell again (it's one-time only)

---

## 📚 FOR MORE HELP

- [ ] Read: COMPREHENSIVE_FIX_SUMMARY.md
- [ ] Read: SETUP_GUIDE.md
- [ ] Read: POWERSHELL_FIX_GUIDE.md
- [ ] Read: QUICK_START.txt

---

## 🏁 READY TO GO!

Once you complete all 5 phases successfully, your iBridge local development environment is fully set up and ready to use.

**Status:** ✅ SYSTEM READY FOR DEVELOPMENT

**Questions?** Check the documentation files or see Troubleshooting section above.
