# Install-FOSS.ps1
# Installs only the FOSS (Free and Open Source Software) applications as enterprise-grade alternatives
# These are all truly free/open source - NO TRIALS
# Run in an elevated PowerShell prompt

$root = "$PSScriptRoot\..\..\FOSS_Enterprise_Stack"

# Create a directory for downloads if it doesn't exist
$downloadDir = "$root\Downloads"
if (-not (Test-Path $downloadDir)) {
    New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null
}

# Define all FOSS alternatives - completely free, no trials (Updated September 2025)
$apps = @(
    # 01 - Endpoint Protection & Security
    @{ Name = "Wazuh Agent"; Path = "$root\01_Endpoint_Protection\wazuh-agent-4.8.2-1.msi"; Args = "/qn"; 
       Url = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.8.2-1.msi"; Category = "Security Monitoring" },
    @{ Name = "ClamAV"; Path = "$root\01_Endpoint_Protection\clamav-1.4.1.win.x64.msi"; Args = "/qn"; 
       Url = "https://www.clamav.net/downloads/production/clamav-1.4.1.win.x64.msi"; Category = "Antivirus" },
    @{ Name = "OSSEC"; Path = "$root\01_Endpoint_Protection\ossec-agent-win32-3.7.0.exe"; Args = "/S"; 
       Url = "https://updates.atomicorp.com/channels/atomic/windows/ossec-agent-win32-3.7.0.exe"; Category = "Host Intrusion Detection" },
    @{ Name = "OSQuery"; Path = "$root\01_Endpoint_Protection\osquery-5.12.2.msi"; Args = "/qn"; 
       Url = "https://github.com/osquery/osquery/releases/download/5.12.2/osquery-5.12.2.msi"; Category = "Endpoint Visibility" },

    # 02 - Network Security
    @{ Name = "Zeek"; Path = "$root\02_Network_Security\zeek-6.0.5-win64.msi"; Args = "/qn"; 
       Url = "https://download.zeek.org/zeek-6.0.5-win64.msi"; Category = "Network Monitoring" },
    @{ Name = "Wireshark"; Path = "$root\02_Network_Security\Wireshark-4.4.1-x64.exe"; Args = "/S"; 
       Url = "https://2.na.dl.wireshark.org/win64/Wireshark-4.4.1-x64.exe"; Category = "Network Analysis" },
    @{ Name = "Nmap"; Path = "$root\02_Network_Security\nmap-7.95-setup.exe"; Args = "/S"; 
       Url = "https://nmap.org/dist/nmap-7.95-setup.exe"; Category = "Network Scanner" },

    # 03 - Remote Management
    @{ Name = "RustDesk"; Path = "$root\03_Remote_Management\rustdesk-1.3.2-x86_64.exe"; Args = "/S"; 
       Url = "https://github.com/rustdesk/rustdesk/releases/download/1.3.2/rustdesk-1.3.2-x86_64.exe"; Category = "Remote Desktop" },
    @{ Name = "TightVNC"; Path = "$root\03_Remote_Management\tightvnc-2.8.85-gpl-setup-64bit.msi"; Args = "/qn"; 
       Url = "https://www.tightvnc.com/download/2.8.85/tightvnc-2.8.85-gpl-setup-64bit.msi"; Category = "Remote Desktop" },

    # 04 - Backup & Recovery
    @{ Name = "UrBackup"; Path = "$root\04_Backup_Disaster_Recovery\UrBackup-Client-2.6.1.exe"; Args = "/S"; 
       Url = "https://hndl.urbackup.org/Client/2.6.1/UrBackup-Client-2.6.1.exe"; Category = "Backup Solution" },
    @{ Name = "Duplicati"; Path = "$root\04_Backup_Disaster_Recovery\duplicati-2.0.8.1-x64.zip"; Args = ""; 
       Url = "https://github.com/duplicati/duplicati/releases/download/v2.0.8.1_canary_2024-05-07/duplicati-2.0.8.1_canary_2024-05-07-x64.zip"; Category = "Backup Solution" },
    @{ Name = "Kopia"; Path = "$root\04_Backup_Disaster_Recovery\KopiaUI-0.18.1-win-x64.zip"; Args = ""; 
       Url = "https://github.com/kopia/kopia/releases/download/v0.18.1/KopiaUI-0.18.1-win-x64.zip"; Category = "Backup Solution" },

    # 05 - Productivity Suite
    @{ Name = "LibreOffice"; Path = "$root\05_Productivity_Suite\LibreOffice_24.8.2_Win_x86-64.msi"; Args = "/qn"; 
       Url = "https://download.documentfoundation.org/libreoffice/stable/24.8.2/win/x86_64/LibreOffice_24.8.2_Win_x86-64.msi"; Category = "Office Suite" },
    @{ Name = "OnlyOffice Desktop"; Path = "$root\05_Productivity_Suite\DesktopEditors-win-x64.exe"; Args = "/S"; 
       Url = "https://github.com/ONLYOFFICE/DesktopEditors/releases/download/v8.2.0/DesktopEditors-win-x64.exe"; Category = "Office Suite" },
    @{ Name = "Thunderbird"; Path = "$root\05_Productivity_Suite\Thunderbird-128.2.3esr.exe"; Args = "/S"; 
       Url = "https://download.mozilla.org/pub/thunderbird/releases/128.2.3esr/win64/en-US/Thunderbird%20Setup%20128.2.3esr.exe"; Category = "Email Client" },
    @{ Name = "Firefox"; Path = "$root\05_Productivity_Suite\Firefox-130.0.1.exe"; Args = "/S"; 
       Url = "https://download.mozilla.org/?product=firefox-130.0.1-SSL&os=win64&lang=en-US"; Category = "Web Browser" },

    # 06 - System Administration
    @{ Name = "Zabbix Agent"; Path = "$root\06_System_Administration\zabbix_agent-7.0.4-windows-amd64.msi"; Args = "/qn"; 
       Url = "https://cdn.zabbix.com/zabbix/binaries/stable/7.0/7.0.4/zabbix_agent-7.0.4-windows-amd64.msi"; Category = "Monitoring" },
    @{ Name = "NXLog CE"; Path = "$root\06_System_Administration\nxlog-ce-3.2.2329.msi"; Args = "/qn"; 
       Url = "https://nxlog.co/system/files/products/files/348/nxlog-ce-3.2.2329.msi"; Category = "Log Management" },

    # 07 - Security Tools
    @{ Name = "VeraCrypt"; Path = "$root\07_Security_Tools\VeraCrypt-1.26.15.exe"; Args = "/S"; 
       Url = "https://launchpad.net/veracrypt/trunk/1.26.15/+download/VeraCrypt%20Setup%201.26.15.exe"; Category = "Encryption" },
    @{ Name = "KeePassXC"; Path = "$root\07_Security_Tools\KeePassXC-2.7.9-Win64.msi"; Args = "/qn"; 
       Url = "https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-Win64.msi"; Category = "Password Manager" },

    # 08 - System Utilities
    @{ Name = "7-Zip"; Path = "$root\08_System_Utilities\7z2408-x64.exe"; Args = "/S"; 
       Url = "https://www.7-zip.org/a/7z2408-x64.exe"; Category = "File Archiver" },
    @{ Name = "Sysinternals Suite"; Path = "$root\08_System_Utilities\SysinternalsSuite.zip"; Args = ""; 
       Url = "https://download.sysinternals.com/files/SysinternalsSuite.zip"; Category = "System Tools" },
    @{ Name = "BleachBit"; Path = "$root\08_System_Utilities\BleachBit-4.6.2-portable.zip"; Args = ""; 
       Url = "https://download.bleachbit.org/BleachBit-4.6.2-portable.zip"; Category = "System Cleaner" },
    @{ Name = "Everything"; Path = "$root\08_System_Utilities\Everything-1.4.1.1026.x64.zip"; Args = ""; 
       Url = "https://www.voidtools.com/Everything-1.4.1.1026.x64.zip"; Category = "File Search" },

    # 09 - Runtimes (Essential)
    @{ Name = "Visual C++ Redistributables"; Path = "$root\09_Runtimes\VisualCppRedist_AIO_x86_x64.exe"; Args = "/ai"; 
       Url = "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe"; Category = "Runtime" },
    @{ Name = ".NET Desktop Runtime"; Path = "$root\09_Runtimes\windowsdesktop-runtime-8.0.8-win-x64.exe"; Args = "/quiet"; 
       Url = "https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/8.0.8/windowsdesktop-runtime-8.0.8-win-x64.exe"; Category = "Runtime" },
    @{ Name = "OpenJDK"; Path = "$root\09_Runtimes\OpenJDK21U-jdk_x64_windows_hotspot_21.0.4_7.msi"; Args = "/qn"; 
       Url = "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.4%2B7/OpenJDK21U-jdk_x64_windows_hotspot_21.0.4_7.msi"; Category = "Runtime" },

    # 10 - Virtualization
    @{ Name = "VirtualBox"; Path = "$root\10_Virtualization\VirtualBox-7.1.4-165100-Win.exe"; Args = "/S"; 
       Url = "https://download.virtualbox.org/virtualbox/7.1.4/VirtualBox-7.1.4-165100-Win.exe"; Category = "Virtualization" }
)

# Download function
function Download-File {
    param (
        [string]$Url,
        [string]$OutputPath
    )
    
    try {
        $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        Write-Host "Downloading $Url to $OutputPath..." -ForegroundColor Cyan
        
        # Create a WebClient object
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PowerShell Script")
        
        # Download the file
        $webClient.DownloadFile($Url, $OutputPath)
        
        Write-Host "Download complete: $OutputPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to download $Url. Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

foreach ($app in $apps) {
    # Download if file doesn't exist
    if (-not (Test-Path $app.Path) -and $app.Url) {
        Write-Host "File not found: $($app.Path)" -ForegroundColor Yellow
        Write-Host "Attempting to download $($app.Name)..." -ForegroundColor Cyan
        $success = Download-File -Url $app.Url -OutputPath $app.Path
        if (-not $success) {
            Write-Host "Download failed for $($app.Name), skipping installation." -ForegroundColor Red
            continue
        }
    }

    # Install if file exists
    if (Test-Path $app.Path) {
        Write-Host "Installing $($app.Name) ($($app.Category))..." -ForegroundColor Cyan
        if ($app.Path -match ".msi$") {
            Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i `"$($app.Path)`" $($app.Args)"
        } elseif ($app.Path -match ".zip$") {
            $extractDir = "$root\Extracted\$($app.Name -replace '\s+', '_')"
            Write-Host "(Manual) Extracting to: $extractDir" -ForegroundColor Yellow
            
            # Create extraction directory if it doesn't exist
            if (-not (Test-Path $extractDir)) {
                New-Item -Path $extractDir -ItemType Directory -Force | Out-Null
            }
            
            # Extract the ZIP file
            try {
                Expand-Archive -Path $app.Path -DestinationPath $extractDir -Force
                Write-Host "Extracted to: $extractDir" -ForegroundColor Green
                
                # Look for any .exe or .msi files in the extracted directory
                $installers = Get-ChildItem -Path $extractDir -Recurse -Include "*.exe", "*.msi" | Select-Object -First 1
                if ($installers) {
                    Write-Host "Found potential installer: $($installers.FullName)" -ForegroundColor Cyan
                    Write-Host "Please review and run manually if needed." -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "Failed to extract $($app.Path). Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Start-Process -Wait -FilePath $app.Path -ArgumentList $app.Args
        }
        Write-Host "Done: $($app.Name)" -ForegroundColor Green
    } else {
        Write-Host "Not found: $($app.Path) (skipped)" -ForegroundColor DarkGray
    }
}

# Create a report of installed FOSS alternatives
$reportPath = "$PSScriptRoot\..\..\Documentation\FOSS_Alternatives_Report.md"
$report = @"
# FOSS Alternatives Report
*Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm")*

This report lists all the Free and Open Source Software (FOSS) alternatives to paid enterprise products installed by the IT Toolkit.

## Installed Software

| Category | FOSS Alternative | Replaces | Status |
|----------|-----------------|----------|--------|
"@

foreach ($app in $apps) {
    $status = if (Test-Path $app.Path) { "✅ Available" } else { "❌ Not Available" }
    $report += "`n| $($app.Category) | $($app.Name) | Commercial Solutions | $status |"
}

$report += @"

## Benefits of FOSS Alternatives

1. **Zero Licensing Costs** - All software is completely free to use with no trials or limitations
2. **No Vendor Lock-in** - Open standards and interoperability
3. **Community Support** - Active development communities for ongoing support
4. **Customizability** - Source code available for customization as needed
5. **Security** - Transparent codebase allows for security audits

## Recommended Self-Hosted Infrastructure

For a complete enterprise FOSS stack, consider:

- **Security Monitoring**: Wazuh + ELK Stack
- **Remote Management**: TacticalRMM or MeshCentral
- **Backup**: UrBackup Server + Duplicati
- **Network Monitoring**: Zabbix + OpenNMS
- **Virtualization**: Proxmox VE
- **Storage**: TrueNAS Scale
"@

# Save the report
Set-Content -Path $reportPath -Value $report
Write-Host "Generated FOSS alternatives report at $reportPath" -ForegroundColor Green

Write-Host "All available FOSS applications processed." -ForegroundColor Yellow
Write-Host "`nNOTE: These are all 100% free and open-source alternatives to paid software - NO TRIALS!" -ForegroundColor Green
