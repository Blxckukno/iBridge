# Download-Freeware.ps1
# Downloads all latest offline installers listed in Documentation/Software_Versions.csv
# Run in an elevated PowerShell prompt

$csvPath = "$PSScriptRoot\..\..\Documentation\Software_Versions.csv"
$downloadRoot = "$PSScriptRoot\..\..\Freeware"

if (!(Test-Path $csvPath)) {
    Write-Error "Software_Versions.csv not found at $csvPath"
    exit 1
}

$softwareList = Import-Csv $csvPath

foreach ($item in $softwareList) {
    $category = $item.Category -replace '[^\w]', '_'
    $software = $item.Software -replace '[^\w]', '_'
    $url = $item.Source
    if (-not $url) { continue }
    $folder = Join-Path $downloadRoot $category
    if (!(Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }
    $fileName = $url.Split('/')[-1]
    $dest = Join-Path $folder $fileName
    Write-Host "Downloading $software from $url ..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        Write-Host "Saved to $dest" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to download $software from $url"
    }
}
Write-Host "All downloads attempted. Check above for any errors." -ForegroundColor Yellow
