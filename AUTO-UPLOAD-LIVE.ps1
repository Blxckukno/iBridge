# iBridge File Upload Script - Direct Upload to Live Server
# This script uploads ai-automation.html and .htaccess to fix the redirect issue

param(
    [string]$Server = "s41.registerdomain.net.za",
    [string]$Username = "ibridgeb", 
    [string]$Password = "QGum81-7ci2L)N",
    [string]$RemotePath = "/public_html"
)

Write-Host "=== iBridge Live Site Upload ===" -ForegroundColor Green
Write-Host "Uploading files to fix WordPress redirect issue..." -ForegroundColor Yellow

# Check if files exist locally
$filesToUpload = @(
    @{Local = "ai-automation.html"; Remote = "ai-automation.html" },
    @{Local = ".htaccess"; Remote = ".htaccess" }
)

$allFilesExist = $true
foreach ($file in $filesToUpload) {
    if (-not (Test-Path $file.Local)) {
        Write-Host "ERROR: $($file.Local) not found!" -ForegroundColor Red
        $allFilesExist = $false
    }
    else {
        Write-Host "✓ Found: $($file.Local)" -ForegroundColor Green
    }
}

if (-not $allFilesExist) {
    Write-Host "Please ensure all files are in the current directory" -ForegroundColor Red
    exit 1
}

# Try using curl for FTP upload (available on Windows 10+)
Write-Host "`nAttempting upload via FTP..." -ForegroundColor Cyan

foreach ($file in $filesToUpload) {
    $localFile = $file.Local
    $remoteFile = "$RemotePath/$($file.Remote)"
    $ftpUrl = "ftp://$Server$remoteFile"
    
    Write-Host "Uploading $localFile to $ftpUrl..." -ForegroundColor Blue
    
    try {
        # Use curl for FTP upload
        $curlArgs = @(
            "-T", $localFile,
            "--user", "${Username}:${Password}",
            $ftpUrl,
            "--ftp-create-dirs"
        )
        
        $result = & curl @curlArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Successfully uploaded $localFile" -ForegroundColor Green
        }
        else {
            Write-Host "✗ Failed to upload $localFile" -ForegroundColor Red
            Write-Host "Error: $result" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ Upload failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Upload Complete ===" -ForegroundColor Green
Write-Host "Test URLs:" -ForegroundColor Yellow
Write-Host "- https://ibridgebpo.com/ai-automation.html" -ForegroundColor Cyan
Write-Host "- https://ibridgebpo.com/ (check AI & Automation link)" -ForegroundColor Cyan

Write-Host "`nIf uploads succeeded, the WordPress redirect should be fixed!" -ForegroundColor Green