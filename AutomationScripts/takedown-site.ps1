# iBridge Site Takedown Script - FTP Method
# This script will connect to your hosting and remove/replace website files

param(
    [string]$Action = "backup", # Options: backup, remove, redirect, offline
    [string]$FtpServer = "ftp.ibridgebpo.com",
    [string]$Username = "ibridgeb",
    [string]$Password = "QGum81-7ci2L)N",
    [string]$RemoteDir = "/public_html/"
)

Write-Host "iBridge Site Management Script" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host "Action: $Action" -ForegroundColor Yellow
Write-Host "Server: $FtpServer" -ForegroundColor Yellow

# Function to create FTP request
function New-FtpRequest {
    param($Uri, $Method = "ListDirectory", $Credentials)
    
    $request = [System.Net.FtpWebRequest]::Create($Uri)
    $request.Method = $Method
    $request.Credentials = $Credentials
    $request.UseBinary = $true
    $request.KeepAlive = $false
    return $request
}

# Setup credentials
$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential($Username, $securePassword)
$ftpCredentials = New-Object System.Net.NetworkCredential($Username, $Password)

try {
    # Test connection
    Write-Host "`nTesting FTP connection..." -ForegroundColor Yellow
    $testUri = "ftp://$FtpServer$RemoteDir"
    $testRequest = New-FtpRequest -Uri $testUri -Method "ListDirectory" -Credentials $ftpCredentials
    $response = $testRequest.GetResponse()
    Write-Host "✓ Connection successful!" -ForegroundColor Green
    $response.Close()

    switch ($Action.ToLower()) {
        "backup" {
            Write-Host "`n📦 Creating backup of current site..." -ForegroundColor Cyan
            
            # Create backup directory
            $backupDir = "site-backup-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
            New-Item -ItemType Directory -Path $backupDir -Force
            
            # List files on server
            $listRequest = New-FtpRequest -Uri $testUri -Method "ListDirectoryDetails" -Credentials $ftpCredentials
            $listResponse = $listRequest.GetResponse()
            $listStream = $listResponse.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($listStream)
            $fileList = $reader.ReadToEnd()
            $reader.Close()
            $listResponse.Close()
            
            Write-Host "Files found on server:" -ForegroundColor White
            $fileList -split "`n" | Where-Object { $_ -match '\.(html|php|css|js|png|jpg|jpeg|gif)$' } | ForEach-Object {
                if ($_ -match '(\S+\.(html|php|css|js|png|jpg|jpeg|gif))') {
                    $fileName = $matches[1]
                    Write-Host "  - $fileName" -ForegroundColor Gray
                    
                    # Download file
                    try {
                        $downloadUri = "ftp://$FtpServer$RemoteDir$fileName"
                        $downloadRequest = New-FtpRequest -Uri $downloadUri -Method "DownloadFile" -Credentials $ftpCredentials
                        $downloadResponse = $downloadRequest.GetResponse()
                        $downloadStream = $downloadResponse.GetResponseStream()
                        
                        $localPath = Join-Path $backupDir $fileName
                        $fileStream = [System.IO.File]::Create($localPath)
                        $downloadStream.CopyTo($fileStream)
                        $fileStream.Close()
                        $downloadStream.Close()
                        $downloadResponse.Close()
                        
                        Write-Host "    ✓ Downloaded: $fileName" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "    ✗ Failed to download: $fileName - $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
            
            Write-Host "`n✅ Backup completed in folder: $backupDir" -ForegroundColor Green
        }

        "remove" {
            Write-Host "`n🗑️  REMOVING ALL WEBSITE FILES..." -ForegroundColor Red
            Write-Host "WARNING: This will delete all files in $RemoteDir" -ForegroundColor Yellow
            
            $confirm = Read-Host "Type 'DELETE' to confirm removal"
            if ($confirm -eq "DELETE") {
                # List and delete files
                $listRequest = New-FtpRequest -Uri $testUri -Method "ListDirectoryDetails" -Credentials $ftpCredentials
                $listResponse = $listRequest.GetResponse()
                $listStream = $listResponse.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($listStream)
                $fileList = $reader.ReadToEnd()
                $reader.Close()
                $listResponse.Close()
                
                $fileList -split "`n" | Where-Object { $_ -match '\S' } | ForEach-Object {
                    if ($_ -match '(\S+\.(html|php|css|js|png|jpg|jpeg|gif|txt|xml))') {
                        $fileName = $matches[1]
                        try {
                            $deleteUri = "ftp://$FtpServer$RemoteDir$fileName"
                            $deleteRequest = New-FtpRequest -Uri $deleteUri -Method "DeleteFile" -Credentials $ftpCredentials
                            $deleteRequest.GetResponse().Close()
                            Write-Host "  ✓ Deleted: $fileName" -ForegroundColor Green
                        }
                        catch {
                            Write-Host "  ✗ Failed to delete: $fileName" -ForegroundColor Red
                        }
                    }
                }
                Write-Host "`n✅ Site files removed!" -ForegroundColor Green
            }
            else {
                Write-Host "Operation cancelled." -ForegroundColor Yellow
            }
        }

        "offline" {
            Write-Host "`n📄 Creating offline maintenance page..." -ForegroundColor Cyan
            
            # Create offline page
            $offlinePage = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Site Temporarily Offline - iBridge</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0; 
            padding: 0; 
            display: flex; 
            justify-content: center; 
            align-items: center; 
            min-height: 100vh;
            color: white;
        }
        .container { 
            text-align: center; 
            background: rgba(255,255,255,0.1);
            padding: 3rem;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 20px 40px rgba(0,0,0,0.3);
            max-width: 500px;
        }
        h1 { color: #fff; margin-bottom: 1rem; }
        p { color: #f0f0f0; line-height: 1.6; }
        .icon { font-size: 4rem; margin-bottom: 2rem; }
        .redirect { 
            margin-top: 2rem; 
            padding: 1rem 2rem; 
            background: rgba(255,255,255,0.2);
            border: none;
            border-radius: 8px;
            color: white;
            font-size: 1.1rem;
            text-decoration: none;
            display: inline-block;
            transition: all 0.3s ease;
        }
        .redirect:hover {
            background: rgba(255,255,255,0.3);
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">🚧</div>
        <h1>Site Temporarily Offline</h1>
        <p>We're performing maintenance on our website. Please check back soon.</p>
        <p>For immediate assistance, please contact us directly.</p>
        <a href="https://blxckukno.github.io/iBridge/" class="redirect">Visit Our Temporary Site</a>
    </div>
</body>
</html>
"@
            
            # Save offline page locally
            $offlinePage | Out-File -FilePath "offline.html" -Encoding UTF8
            
            # Upload offline page
            $uploadUri = "ftp://$FtpServer$RemoteDir" + "index.html"
            $uploadRequest = New-FtpRequest -Uri $uploadUri -Method "UploadFile" -Credentials $ftpCredentials
            $uploadStream = $uploadRequest.GetRequestStream()
            $fileBytes = [System.Text.Encoding]::UTF8.GetBytes($offlinePage)
            $uploadStream.Write($fileBytes, 0, $fileBytes.Length)
            $uploadStream.Close()
            $uploadRequest.GetResponse().Close()
            
            Write-Host "✅ Offline page uploaded!" -ForegroundColor Green
        }

        "redirect" {
            Write-Host "`n🔄 Creating redirect to GitHub Pages..." -ForegroundColor Cyan
            
            $redirectPage = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="3;url=https://blxckukno.github.io/iBridge/">
    <title>Redirecting to New Site - iBridge</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0; 
            padding: 0; 
            display: flex; 
            justify-content: center; 
            align-items: center; 
            min-height: 100vh;
            color: white;
        }
        .container { 
            text-align: center; 
            background: rgba(255,255,255,0.1);
            padding: 3rem;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 20px 40px rgba(0,0,0,0.3);
        }
        .spinner { 
            border: 4px solid rgba(255,255,255,0.3); 
            border-top: 4px solid white; 
            border-radius: 50%; 
            width: 50px; 
            height: 50px; 
            animation: spin 1s linear infinite; 
            margin: 2rem auto;
        }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
    </style>
    <script>
        setTimeout(function() {
            window.location.href = 'https://blxckukno.github.io/iBridge/';
        }, 3000);
    </script>
</head>
<body>
    <div class="container">
        <h1>Site Has Moved</h1>
        <div class="spinner"></div>
        <p>Redirecting you to our new location...</p>
        <p>If you're not redirected automatically, <a href="https://blxckukno.github.io/iBridge/" style="color: #fff;">click here</a>.</p>
    </div>
</body>
</html>
"@
            
            # Save and upload redirect page
            $redirectPage | Out-File -FilePath "redirect.html" -Encoding UTF8
            
            $uploadUri = "ftp://$FtpServer$RemoteDir" + "index.html"
            $uploadRequest = New-FtpRequest -Uri $uploadUri -Method "UploadFile" -Credentials $ftpCredentials
            $uploadStream = $uploadRequest.GetRequestStream()
            $fileBytes = [System.Text.Encoding]::UTF8.GetBytes($redirectPage)
            $uploadStream.Write($fileBytes, 0, $fileBytes.Length)
            $uploadStream.Close()
            $uploadRequest.GetResponse().Close()
            
            Write-Host "✅ Redirect page uploaded!" -ForegroundColor Green
        }

        default {
            Write-Host "Invalid action. Use: backup, remove, offline, or redirect" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🔒 Security Reminder: Change your hosting passwords!" -ForegroundColor Yellow
Write-Host "🌐 Your GitHub Pages site remains active: https://blxckukno.github.io/iBridge/" -ForegroundColor Green