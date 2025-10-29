# Download-FOSS.ps1
# Downloads FOSS enterprise alternatives for all major IT needs
# Run in an elevated PowerShell prompt

$fossList = @(
    @{ Name = 'Wazuh Agent'; Url = 'https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.3-1.msi'; Folder = '01_Endpoint_Protection' },
    @{ Name = 'CrowdSec'; Url = 'https://github.com/crowdsecurity/crowdsec/releases/latest/download/crowdsec_windows_amd64.msi'; Folder = '01_Endpoint_Protection' },
    @{ Name = 'ClamAV'; Url = 'https://www.clamav.net/downloads/production/clamav-1.3.1.win.x64.msi'; Folder = '01_Endpoint_Protection' },
    @{ Name = 'UrBackup Client'; Url = 'https://hndl.urbackup.org/Client/2.5.45/UrBackup%20Client%20IT%202.5.45.exe'; Folder = '04_Backup_Disaster_Recovery' },
    @{ Name = 'Vorta'; Url = 'https://github.com/borgbase/vorta/releases/latest/download/Vorta.exe'; Folder = '04_Backup_Disaster_Recovery' },
    @{ Name = 'RustDesk'; Url = 'https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-1.2.5-x86_64.exe'; Folder = '05_Remote_Access_Support' },
    @{ Name = 'LibreOffice'; Url = 'https://download.documentfoundation.org/libreoffice/stable/24.8.2/win/x86_64/LibreOffice_24.8.2_Win_x86-64.msi'; Folder = '06_Productivity_Suite' },
    @{ Name = 'OnlyOffice Desktop'; Url = 'https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/DesktopEditors_x64.exe'; Folder = '06_Productivity_Suite' },
    @{ Name = 'Thunderbird'; Url = 'https://download.mozilla.org/?product=thunderbird-115.15.0-SSL&os=win64&lang=en-US'; Folder = '06_Productivity_Suite' }
)

$downloadRoot = "$PSScriptRoot\..\..\FOSS_Enterprise_Stack"

foreach ($item in $fossList) {
    $folder = Join-Path $downloadRoot $item.Folder
    if (!(Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }
    $url = $item.Url
    $name = $item.Name -replace '[^\w]', '_'
    $fileName = $url.Split('/')[-1]
    $dest = Join-Path $folder $fileName
    Write-Host "Downloading $name from $url ..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        Write-Host "Saved to $dest" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to download $name from $url"
    }
}
Write-Host "All FOSS downloads attempted. Check above for any errors." -ForegroundColor Yellow
