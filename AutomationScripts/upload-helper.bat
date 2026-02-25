@echo off
echo ===============================================
echo iBridge Website Upload Script
echo ===============================================
echo.
echo This script will help you upload ai-automation.html
echo.
echo SECURITY NOTE: Please update your hosting password
echo after using this script, as it was shared in chat.
echo.
pause

REM Check if file exists
if not exist "ai-automation.html" (
    echo ERROR: ai-automation.html not found in current directory
    echo Please run this script from your iBridge project folder
    pause
    exit /b 1
)

echo.
echo Files ready to upload:
echo - ai-automation.html (810 lines)
echo - .htaccess (redirect prevention)
echo.
echo MANUAL UPLOAD STEPS:
echo 1. Open your cPanel File Manager
echo 2. Go to public_html folder
echo 3. Upload ai-automation.html
echo 4. Create .htaccess with the content below:
echo.
echo ErrorDocument 404 /index.html
echo RewriteEngine On
echo RewriteCond %%{HTTP_HOST} !^ibridgebpo\.com$ [NC]
echo RewriteRule ^(.*)$ https://ibridgebpo.com/$1 [R=301,L]
echo.
echo 5. Test: https://ibridgebpo.com/ai-automation.html
echo.
echo Upload completed manually through cPanel File Manager.
echo.
pause