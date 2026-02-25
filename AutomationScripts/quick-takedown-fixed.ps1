# Quick Site Takedown Script
# Simple script to create an offline page

Write-Host "iBridge Quick Takedown" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

# Create offline page
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
            max-width: 500px;
        }
        h1 { font-size: 2.5rem; margin-bottom: 1rem; }
        p { font-size: 1.1rem; line-height: 1.6; margin-bottom: 1rem; }
        a {
            display: inline-block;
            margin-top: 2rem;
            padding: 1rem 2rem;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            text-decoration: none;
            border-radius: 50px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Site Maintenance</h1>
        <p>We are currently updating our website to serve you better.</p>
        <p>Thank you for your patience while we make improvements.</p>
        <a href="https://blxckukno.github.io/iBridge/">Visit Our Temporary Site</a>
    </div>
</body>
</html>
"@

# Save the file
$offlineHTML | Out-File -FilePath "site-offline.html" -Encoding UTF8
Write-Host "Created: site-offline.html" -ForegroundColor Green

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Go to: https://s41.registerdomain.net.za/cpanel" -ForegroundColor White
Write-Host "2. Username: ibridgeb" -ForegroundColor White
Write-Host "3. Open File Manager" -ForegroundColor White
Write-Host "4. Navigate to public_html" -ForegroundColor White
Write-Host "5. Delete existing index.html" -ForegroundColor White
Write-Host "6. Upload the new 'site-offline.html' file" -ForegroundColor White
Write-Host "7. Rename it to 'index.html'" -ForegroundColor White

Write-Host ""
$runAuto = Read-Host "Run automated script instead? (y/n)"
if ($runAuto -eq 'y') {
    Write-Host "Running automated takedown script..." -ForegroundColor Green
    .\takedown-site-fixed.ps1 -Action offline
}

Write-Host ""
Write-Host "Remember to change your hosting passwords!" -ForegroundColor Red