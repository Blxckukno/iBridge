# Upload Missing Files to Live Site
# PowerShell script to upload ai-automation.html via SFTP

param(
    [Parameter(Mandatory = $true)]
    [string]$HostName,
    
    [Parameter(Mandatory = $true)]
    [string]$UserName,
    
    [Parameter(Mandatory = $true)]
    [string]$Password,
    
    [string]$RemotePath = "/public_html",
    [int]$Port = 22
)

# Check if WinSCP is available
$winscpPath = "C:\Program Files (x86)\WinSCP\WinSCP.com"
if (-not (Test-Path $winscpPath)) {
    Write-Host "WinSCP not found. Please install WinSCP or use manual upload method." -ForegroundColor Red
    Write-Host "Download from: https://winscp.net/eng/download.php" -ForegroundColor Yellow
    exit 1
}

# Files to upload
$filesToUpload = @(
    "ai-automation.html"
)

# Current directory
$localPath = Get-Location

Write-Host "Starting upload to $HostName..." -ForegroundColor Green

# Create WinSCP script
$scriptContent = @"
open sftp://${UserName}:${Password}@${HostName}:${Port}
cd $RemotePath
"@

foreach ($file in $filesToUpload) {
    $localFile = Join-Path $localPath $file
    if (Test-Path $localFile) {
        $scriptContent += "`nput `"$localFile`""
        Write-Host "Preparing to upload: $file" -ForegroundColor Blue
    }
    else {
        Write-Host "Warning: File not found: $file" -ForegroundColor Yellow
    }
}

$scriptContent += "`nexit"

# Write script to temp file
$scriptFile = [System.IO.Path]::GetTempFileName()
$scriptContent | Out-File -FilePath $scriptFile -Encoding ASCII

try {
    # Execute WinSCP
    Write-Host "Uploading files..." -ForegroundColor Green
    & $winscpPath /script=$scriptFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Upload completed successfully!" -ForegroundColor Green
        Write-Host "`nVerification URLs:" -ForegroundColor Yellow
        Write-Host "- https://$HostName/ai-automation.html" -ForegroundColor Cyan
        Write-Host "- https://$HostName/ (test AI & Automation link)" -ForegroundColor Cyan
    }
    else {
        Write-Host "Upload failed. Check credentials and try again." -ForegroundColor Red
    }
}
finally {
    # Clean up
    Remove-Item $scriptFile -Force -ErrorAction SilentlyContinue
}

# Usage examples
Write-Host "`nUsage Examples:" -ForegroundColor Yellow
Write-Host ".\upload-missing-files.ps1 -HostName 'your-server.com' -UserName 'your-username' -Password 'your-password'" -ForegroundColor Gray
Write-Host ".\upload-missing-files.ps1 -HostName 'your-server.com' -UserName 'your-username' -Password 'your-password' -RemotePath '/var/www/html'" -ForegroundColor Gray