# Simple Site Takedown - File Generator
# Creates files for manual upload via cPanel

Write-Host "iBridge Site Takedown - File Generator" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Create offline maintenance page
$offlinePage = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>iBridge - Site Temporarily Offline</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, rgb(102, 126, 234) 0%, rgb(118, 75, 162) 100%);
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
            max-width: 500px;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .icon { font-size: 4rem; margin-bottom: 1.5rem; opacity: 0.9; }
        h1 { font-size: 2.5rem; margin-bottom: 1rem; font-weight: 300; }
        p { font-size: 1.1rem; line-height: 1.6; margin-bottom: 1rem; opacity: 0.9; }
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
        .contact-info { margin-top: 2rem; font-size: 0.9rem; opacity: 0.8; }
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

# Create redirect page
$redirectPage = @"
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
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, rgb(102, 126, 234) 0%, rgb(118, 75, 162) 100%);
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
            max-width: 500px;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
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
        a { color: white; text-decoration: underline; }
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

# Save both files
$offlinePage | Out-File -FilePath "site-offline.html" -Encoding UTF8
$redirectPage | Out-File -FilePath "site-redirect.html" -Encoding UTF8

Write-Host "✅ Files created successfully:" -ForegroundColor Green
Write-Host "   📄 site-offline.html (maintenance page)" -ForegroundColor White
Write-Host "   📄 site-redirect.html (redirect to GitHub Pages)" -ForegroundColor White
Write-Host ""

Write-Host "🎯 RECOMMENDED: Use the REDIRECT page" -ForegroundColor Yellow
Write-Host "   Visitors will automatically go to your GitHub Pages site" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Manual Upload Instructions:" -ForegroundColor Cyan
Write-Host "1. Go to: https://s41.registerdomain.net.za/cpanel" -ForegroundColor White
Write-Host "2. Username: ibridgeb" -ForegroundColor White
Write-Host "3. Enter your password" -ForegroundColor White
Write-Host "4. Click 'File Manager'" -ForegroundColor White
Write-Host "5. Navigate to 'public_html' folder" -ForegroundColor White
Write-Host "6. DELETE the existing 'index.html' file" -ForegroundColor White
Write-Host "7. UPLOAD either:" -ForegroundColor White
Write-Host "   📄 'site-redirect.html' (RECOMMENDED)" -ForegroundColor Green
Write-Host "   📄 'site-offline.html' (maintenance page)" -ForegroundColor Yellow
Write-Host "8. RENAME the uploaded file to 'index.html'" -ForegroundColor White
Write-Host ""

Write-Host "🌐 Results:" -ForegroundColor Cyan
Write-Host "   📍 External site: Will redirect or show maintenance" -ForegroundColor White
Write-Host "   📍 GitHub Pages: https://blxckukno.github.io/iBridge/ (stays active)" -ForegroundColor Green
Write-Host ""

Write-Host "🔒 IMPORTANT SECURITY:" -ForegroundColor Red
Write-Host "   Change your cPanel/FTP password after this process!" -ForegroundColor Red
Write-Host ""

$choice = Read-Host "Open cPanel now? (y/n)"
if ($choice -eq 'y') {
    Start-Process "https://s41.registerdomain.net.za/cpanel"
    Write-Host "Opening cPanel in your browser..." -ForegroundColor Green
}