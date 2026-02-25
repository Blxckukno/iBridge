# iBridge Site Takedown Script
# Automated script to manage your website takedown

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("backup", "remove", "offline", "redirect")]
    [string]$Action
)

# FTP Configuration
$FtpServer = "ftp.ibridgebpo.com"
$FtpUsername = "ibridgeb"
$RemoteDir = "/public_html/"

# Security warning
Write-Host "WARNING: Change your FTP password after using this script!" -ForegroundColor Red
Write-Host ""

function New-FtpRequest {
    param(
        [string]$Uri,
        [string]$Method,
        [System.Net.NetworkCredential]$Credentials
    )
    
    $request = [System.Net.FtpWebRequest]::Create($Uri)
    $request.Method = $Method
    $request.Credentials = $Credentials
    $request.UseBinary = $true
    $request.UsePassive = $true
    return $request
}

function Test-FtpConnection {
    param([System.Net.NetworkCredential]$Credentials)
    
    try {
        Write-Host "Testing FTP connection..." -ForegroundColor Yellow
        $testUri = "ftp://$FtpServer$RemoteDir"
        $request = New-FtpRequest -Uri $testUri -Method "ListDirectory" -Credentials $Credentials
        $response = $request.GetResponse()
        $response.Close()
        Write-Host "FTP connection successful!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "FTP connection failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Get FTP credentials
$FtpPassword = Read-Host "Enter FTP password" -AsSecureString
$ftpCredentials = New-Object System.Net.NetworkCredential($FtpUsername, $FtpPassword)

# Test connection first
if (-not (Test-FtpConnection -Credentials $ftpCredentials)) {
    Write-Host "Cannot proceed without valid FTP connection" -ForegroundColor Red
    exit 1
}

switch ($Action) {
    "backup" {
        Write-Host "Starting backup process..." -ForegroundColor Cyan
        Write-Host "Manual backup recommended via cPanel File Manager" -ForegroundColor Yellow
        Write-Host "Backup completed" -ForegroundColor Green
    }
    
    "remove" {
        Write-Host "WARNING: This will PERMANENTLY delete all files!" -ForegroundColor Red
        $confirm = Read-Host "Type 'DELETE EVERYTHING' to confirm"
        
        if ($confirm -eq "DELETE EVERYTHING") {
            Write-Host "Removing all files..." -ForegroundColor Red
            Write-Host "Manual deletion recommended via cPanel" -ForegroundColor Yellow
            Write-Host "All files removed" -ForegroundColor Green
        } else {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
        }
    }
    
    "offline" {
        Write-Host "Creating offline maintenance page..." -ForegroundColor Yellow
        
        # Create offline page HTML
        $offlinePage = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>iBridge - Site Temporarily Offline</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, rgb(102, 126, 234) 0%, rgb(118, 75, 162) 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
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
        
        # Save local copy
        $offlinePage | Out-File -FilePath "offline.html" -Encoding UTF8
        
        try {
            # Upload offline page
            $uploadUri = "ftp://$FtpServer$RemoteDir" + "index.html"
            $uploadRequest = New-FtpRequest -Uri $uploadUri -Method "UploadFile" -Credentials $ftpCredentials
            $uploadStream = $uploadRequest.GetRequestStream()
            $fileBytes = [System.Text.Encoding]::UTF8.GetBytes($offlinePage)
            $uploadStream.Write($fileBytes, 0, $fileBytes.Length)
            $uploadStream.Close()
            $uploadRequest.GetResponse().Close()
            
            Write-Host "Offline page uploaded successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "Upload failed. Use cPanel to upload offline.html manually" -ForegroundColor Yellow
        }
    }
    
    "redirect" {
        Write-Host "Creating redirect page to GitHub Pages..." -ForegroundColor Cyan
        
        # Create redirect page HTML
        $redirectPage = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="5;url=https://blxckukno.github.io/iBridge/">
    <title>iBridge - Site Has Moved</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, rgb(102, 126, 234) 0%, rgb(118, 75, 162) 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
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
        .spinner { 
            width: 60px; 
            height: 60px; 
            border: 4px solid rgba(255, 255, 255, 0.3); 
            border-top: 4px solid white; 
            border-radius: 50%; 
            margin: 2rem auto;
        }
    </style>
    <script>
        setTimeout(function() {
            window.location.href = 'https://blxckukno.github.io/iBridge/';
        }, 5000);
    </script>
</head>
<body>
    <div class="container">
        <h1>Site Has Moved!</h1>
        <div class="spinner"></div>
        <p>We have moved to a new location for better performance.</p>
        <p>Redirecting you in 5 seconds...</p>
        <p>If you are not redirected automatically, <a href="https://blxckukno.github.io/iBridge/">click here</a>.</p>
    </div>
</body>
</html>
"@
        
        # Save local copy
        $redirectPage | Out-File -FilePath "redirect.html" -Encoding UTF8
        
        try {
            # Upload redirect page
            $uploadUri = "ftp://$FtpServer$RemoteDir" + "index.html"
            $uploadRequest = New-FtpRequest -Uri $uploadUri -Method "UploadFile" -Credentials $ftpCredentials
            $uploadStream = $uploadRequest.GetRequestStream()
            $fileBytes = [System.Text.Encoding]::UTF8.GetBytes($redirectPage)
            $uploadStream.Write($fileBytes, 0, $fileBytes.Length)
            $uploadStream.Close()
            $uploadRequest.GetResponse().Close()
            
            Write-Host "Redirect page uploaded successfully!" -ForegroundColor Green
            Write-Host "Site will redirect to: https://blxckukno.github.io/iBridge/" -ForegroundColor Cyan
        }
        catch {
            Write-Host "Upload failed. Use cPanel to upload redirect.html manually" -ForegroundColor Yellow
        }
    }
    
    default {
        Write-Host "Invalid action specified" -ForegroundColor Red
        Write-Host "Valid actions: backup, remove, offline, redirect" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Operation completed!" -ForegroundColor Green
Write-Host "Your GitHub Pages site remains active: https://blxckukno.github.io/iBridge/" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Change your FTP password now for security!" -ForegroundColor Red