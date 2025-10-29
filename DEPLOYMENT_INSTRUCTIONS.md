# Deploy ai-automation.html to Live Site

## Problem Summary
- The live site links to `ai-automation.html` but the file doesn't exist on the server
- When users click "AI & Automation", they get redirected to a WordPress dev site
- The file exists locally and needs to be uploaded

## Files to Upload
- `ai-automation.html` (main file - 810 lines)
- All required images already exist on live server

## Upload Methods

### Method 1: cPanel File Manager (Easiest)
1. Log into your hosting provider's cPanel
2. Open **File Manager**
3. Navigate to your website's root directory (usually `public_html` or `www`)
4. Click **Upload**
5. Select `ai-automation.html` from your local folder
6. Click **Upload** and wait for completion
7. Verify the file appears in the directory listing

### Method 2: FTP/SFTP Client
Use FileZilla, WinSCP, or similar:
1. Connect to your hosting server
   - Host: `your-ftp-server.com`
   - Username: `your-ftp-username`
   - Password: `your-ftp-password`
   - Port: 21 (FTP) or 22 (SFTP)
2. Navigate to your website root directory
3. Upload `ai-automation.html` to the root folder
4. Ensure file permissions are set to 644

### Method 3: PowerShell Script (Advanced)
Use the provided `upload-missing-files.ps1` script

## Verification Steps
After upload, test these URLs:
1. ✅ https://ibridgebpo.com/ai-automation.html (should load properly)
2. ✅ https://ibridgebpo.com/ (AI & Automation link should work)
3. ✅ https://ibridgebpo.com/services.html (AI & Automation link should work)

## Expected Results
- No more WordPress redirects
- AI & Automation page displays correctly
- All navigation links work properly
- Users can access the full AI solutions content

## Troubleshooting
If the page still redirects after upload:
1. Clear browser cache
2. Check file permissions (should be 644)
3. Verify file is in the correct directory
4. Contact hosting provider about 404 redirect settings