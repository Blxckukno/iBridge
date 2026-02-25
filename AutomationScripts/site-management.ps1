# iBridge Site Management Menu
# Interactive script to manage your website takedown

function Show-Menu {
    Clear-Host
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host "       iBridge Site Management        " -ForegroundColor Green  
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Current site: https://www.ibridgebpo.com" -ForegroundColor Yellow
    Write-Host "GitHub Pages: https://blxckukno.github.io/iBridge/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Choose an option:" -ForegroundColor White
    Write-Host ""
    Write-Host "1. Backup current site" -ForegroundColor White
    Write-Host "2. Replace with offline page" -ForegroundColor White  
    Write-Host "3. Replace with redirect page" -ForegroundColor White
    Write-Host "4. Remove all files (PERMANENT)" -ForegroundColor Red
    Write-Host "5. Show manual instructions" -ForegroundColor White
    Write-Host "6. Show security reminders" -ForegroundColor Yellow
    Write-Host "9. Exit" -ForegroundColor Gray
    Write-Host ""
}

function Show-ManualInstructions {
    Write-Host "`n📋 Manual Takedown Instructions:" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Option 1 - Via cPanel:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://s41.registerdomain.net.za/cpanel"
    Write-Host "2. Username: ibridgeb"
    Write-Host "3. Password: [your password]"
    Write-Host "4. Click 'File Manager'"
    Write-Host "5. Navigate to 'public_html'"
    Write-Host "6. Select all files and delete them"
    Write-Host "7. Upload a new index.html with offline message"
    Write-Host ""
    Write-Host "Option 2 - Via FTP:" -ForegroundColor Yellow
    Write-Host "1. Use FileZilla or WinSCP"
    Write-Host "2. Host: ftp.ibridgebpo.com"
    Write-Host "3. Username: ibridgeb"
    Write-Host "4. Password: [your password]"
    Write-Host "5. Navigate to /public_html/"
    Write-Host "6. Delete or replace files"
    Write-Host ""
    Write-Host "Option 3 - DNS Redirect:" -ForegroundColor Yellow
    Write-Host "1. Contact your domain registrar"
    Write-Host "2. Change A record to point to GitHub Pages"
    Write-Host "3. Or add CNAME record for www to blxckukno.github.io"
}

function Show-SecurityReminders {
    Write-Host "`n🔒 CRITICAL Security Actions:" -ForegroundColor Red
    Write-Host "=============================" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  IMMEDIATELY change these passwords:" -ForegroundColor Yellow
    Write-Host "   • cPanel password"
    Write-Host "   • FTP password"
    Write-Host "   • Any email passwords"
    Write-Host ""
    Write-Host "🛡️  Additional security steps:" -ForegroundColor Green
    Write-Host "   • Enable 2FA if available"
    Write-Host "   • Review access logs"
    Write-Host "   • Update any API keys"
    Write-Host "   • Check email forwarding settings"
    Write-Host ""
    Write-Host "📱 Contact hosting provider if needed:" -ForegroundColor Cyan
    Write-Host "   • Support email or phone"
    Write-Host "   • Request account security review"
    Write-Host "   • Ask about access logs"
}

function Create-OfflinePage {
    $offlineHTML = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>iBridge - Site Temporarily Offline</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 3rem 2rem;
            border-radius: 20px;
            backdrop-filter: blur(15px);
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
            max-width: 500px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .icon {
            font-size: 4rem;
            margin-bottom: 1.5rem;
            opacity: 0.9;
        }
        h1 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            font-weight: 300;
        }
        p {
            font-size: 1.1rem;
            line-height: 1.6;
            margin-bottom: 1rem;
            opacity: 0.9;
        }
        .cta-button {
            display: inline-block;
            margin-top: 2rem;
            padding: 1rem 2rem;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            text-decoration: none;
            border-radius: 50px;
            font-weight: 500;
            border: 2px solid rgba(255, 255, 255, 0.3);
            transition: all 0.3s ease;
        }
        .cta-button:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-3px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
        }
        .contact-info {
            margin-top: 2rem;
            font-size: 0.9rem;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🚧</div>
        <h1>Site Maintenance</h1>
        <p>We're currently updating our website to serve you better.</p>
        <p>Thank you for your patience while we make improvements.</p>
        
        <a href="https://blxckukno.github.io/iBridge/" class="cta-button">
            Visit Our Temporary Site
        </a>
        
        <div class="contact-info">
            <p>Need immediate assistance?</p>
            <p>Please use our temporary site above</p>
        </div>
    </div>
</body>
</html>
"@
    
    $offlineHTML | Out-File -FilePath "site-offline.html" -Encoding UTF8
    Write-Host "✅ Created: site-offline.html" -ForegroundColor Green
}

function Create-RedirectPage {
    $redirectHTML = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="5;url=https://blxckukno.github.io/iBridge/">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>iBridge - Site Has Moved</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 3rem 2rem;
            border-radius: 20px;
            backdrop-filter: blur(15px);
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
            max-width: 500px;
        }
        .spinner {
            width: 60px;
            height: 60px;
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-top: 4px solid white;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 2rem auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        h1 { font-size: 2.5rem; margin-bottom: 1rem; font-weight: 300; }
        p { font-size: 1.1rem; line-height: 1.6; margin-bottom: 1rem; opacity: 0.9; }
        a { color: #fff; text-decoration: underline; }
        .countdown { font-size: 2rem; font-weight: bold; margin: 1rem 0; }
    </style>
    <script>
        let countdown = 5;
        function updateCountdown() {
            document.getElementById('countdown').textContent = countdown;
            countdown--;
            if (countdown < 0) {
                window.location.href = 'https://blxckukno.github.io/iBridge/';
            }
        }
        setInterval(updateCountdown, 1000);
        window.onload = function() {
            document.getElementById('countdown').textContent = countdown;
        }
    </script>
</head>
<body>
    <div class="container">
        <h1>🚀 Site Has Moved!</h1>
        <div class="spinner"></div>
        <p>We've moved to a new location for better performance.</p>
        <p>Redirecting you in <span id="countdown" class="countdown">5</span> seconds...</p>
        <p>If you're not redirected automatically,<br>
        <a href="https://blxckukno.github.io/iBridge/">click here to continue</a>.</p>
    </div>
</body>
</html>
"@
    
    $redirectHTML | Out-File -FilePath "site-redirect.html" -Encoding UTF8
    Write-Host "✅ Created: site-redirect.html" -ForegroundColor Green
}

# Main menu loop
do {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-6, 9)"
    
    switch ($choice) {
        "1" {
            Write-Host "`n📦 Starting backup process..." -ForegroundColor Cyan
            .\takedown-site.ps1 -Action backup
            Read-Host "`nPress Enter to continue"
        }
        "2" {
            Write-Host "`n🚧 Creating offline page..." -ForegroundColor Yellow
            Create-OfflinePage
            $runNow = Read-Host "Upload offline page now? (y/n)"
            if ($runNow -eq 'y') {
                .\takedown-site.ps1 -Action offline
            } else {
                Write-Host "📋 Upload 'site-offline.html' manually via cPanel or FTP"
            }
            Read-Host "`nPress Enter to continue"
        }
        "3" {
            Write-Host "`n🔄 Creating redirect page..." -ForegroundColor Cyan
            Create-RedirectPage
            $runNow = Read-Host "Upload redirect page now? (y/n)"
            if ($runNow -eq 'y') {
                .\takedown-site.ps1 -Action redirect
            } else {
                Write-Host "📋 Upload 'site-redirect.html' manually via cPanel or FTP"
            }
            Read-Host "`nPress Enter to continue"
        }
        "4" {
            Write-Host "`n🗑️  PERMANENT REMOVAL WARNING!" -ForegroundColor Red
            Write-Host "This will delete ALL files from your website." -ForegroundColor Red
            $confirm = Read-Host "Type 'DELETE EVERYTHING' to confirm"
            if ($confirm -eq "DELETE EVERYTHING") {
                .\takedown-site.ps1 -Action remove
            } else {
                Write-Host "Operation cancelled." -ForegroundColor Yellow
            }
            Read-Host "`nPress Enter to continue"
        }
        "5" {
            Show-ManualInstructions
            Read-Host "`nPress Enter to continue"
        }
        "6" {
            Show-SecurityReminders
            Read-Host "`nPress Enter to continue"
        }
        "9" {
            Write-Host "`n👋 Goodbye! Remember to change your passwords!" -ForegroundColor Green
            break
        }
        default {
            Write-Host "`n❌ Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep 2
        }
    }
} while ($choice -ne "9")