# Download-Free-Security-Alternatives.ps1
# Downloads truly free (not trial) alternatives to paid security software
# Run with administrator privileges

# Create a folder to store downloads
$outputDir = "$env:USERPROFILE\Desktop\Security_Tools"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Enable TLS 1.2 for compatibility with secure websites
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Function to download files with progress display
function Download-FileWithProgress {
    param(
        [string]$Name,
        [string]$Url,
        [string]$OutFile
    )
    
    Write-Host "Downloading $Name from $Url..." -ForegroundColor Cyan
    
    try {
        $start = Get-Date
        
        # Create WebClient object for downloading
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PowerShell Script")
        
        # Register event for tracking download progress
        $eventId = [guid]::NewGuid().ToString()
        $null = Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier $eventId -Action {
            $percent = $Event.SourceArgs.ProgressPercentage
            Write-Progress -Activity "Downloading $($Event.MessageData)" -Status "$percent% Complete" -PercentComplete $percent
        } -MessageData $Name
        
        # Register event for download completion
        $null = Register-ObjectEvent -InputObject $webClient -EventName DownloadFileCompleted -SourceIdentifier "$eventId-Completed" -Action {
            Write-Progress -Activity "Downloading $($Event.MessageData)" -Completed
            Write-Host "Download completed: $($Event.MessageData)" -ForegroundColor Green
        } -MessageData $Name
        
        # Start asynchronous download
        $webClient.DownloadFileAsync([uri]$Url, $OutFile)
        
        # Wait for download to complete with timeout
        $timeoutSeconds = 600 # 10 minutes timeout
        $completed = $false
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        
        while (-not $completed -and $timer.Elapsed.TotalSeconds -lt $timeoutSeconds) {
            if ((Get-EventSubscriber | Where-Object { $_.SourceIdentifier -eq "$eventId-Completed" }).Completed) {
                $completed = $true
            } else {
                Start-Sleep -Milliseconds 100
            }
        }
        
        # Clean up event handlers
        Unregister-Event -SourceIdentifier $eventId -ErrorAction SilentlyContinue
        Unregister-Event -SourceIdentifier "$eventId-Completed" -ErrorAction SilentlyContinue
        
        if ($completed) {
            $elapsed = (Get-Date) - $start
            Write-Host "Download completed in $($elapsed.ToString('mm\:ss'))" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Download timed out after $timeoutSeconds seconds" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error downloading $Name. Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Define completely free alternatives to paid security software (NO TRIALS) - Updated September 2025
$securityTools = @(
    # 1. Antivirus and Malware Protection
    @{
        Name = "ClamAV"; 
        Category = "Antivirus"; 
        Url = "https://www.clamav.net/downloads/production/clamav-1.4.1.win.x64.msi"; 
        FileName = "clamav-1.4.1.win.x64.msi"; 
        Description = "Free and open-source antivirus engine for detecting trojans, viruses, malware & other malicious threats"
    },
    @{
        Name = "Immunet"; 
        Category = "Antivirus"; 
        Url = "https://download.immunet.com/binaries/immunet/setup/Immunet-7.5.2-installer.exe"; 
        FileName = "Immunet-7.5.2-installer.exe"; 
        Description = "Free cloud-based antivirus with real-time protection and community features"
    },
    
    # 2. Endpoint Protection Tools
    @{
        Name = "OSSEC HIDS"; 
        Category = "Host Intrusion Detection"; 
        Url = "https://updates.atomicorp.com/channels/atomic/windows/ossec-agent-win32-3.7.0.exe"; 
        FileName = "ossec-agent-win32-3.7.0.exe"; 
        Description = "Open Source HIDS Security that performs log analysis, integrity checking, rootkit detection, and more"
    },
    @{
        Name = "Wazuh Agent"; 
        Category = "SIEM/XDR"; 
        Url = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.8.2-1.msi"; 
        FileName = "wazuh-agent-4.8.2-1.msi"; 
        Description = "Open source security monitoring solution for threat detection, integrity monitoring, and compliance"
    },
    @{
        Name = "OSQuery"; 
        Category = "Endpoint Visibility"; 
        Url = "https://github.com/osquery/osquery/releases/download/5.12.2/osquery-5.12.2.msi"; 
        FileName = "osquery-5.12.2.msi"; 
        Description = "SQL powered operating system instrumentation, monitoring, and analytics framework"
    },
    
    # 3. Network Security Tools
    @{
        Name = "Wireshark"; 
        Category = "Network Analysis"; 
        Url = "https://2.na.dl.wireshark.org/win64/Wireshark-4.4.1-x64.exe"; 
        FileName = "Wireshark-4.4.1-x64.exe"; 
        Description = "The world's foremost network protocol analyzer for examining network traffic"
    },
    @{
        Name = "Nmap"; 
        Category = "Network Scanner"; 
        Url = "https://nmap.org/dist/nmap-7.95-setup.exe"; 
        FileName = "nmap-7.95-setup.exe"; 
        Description = "Network discovery and security auditing tool"
    },
    @{
        Name = "Zeek"; 
        Category = "Network Monitoring"; 
        Url = "https://download.zeek.org/zeek-6.0.5-win64.msi"; 
        FileName = "zeek-6.0.5-win64.msi"; 
        Description = "Powerful network analysis framework focusing on security monitoring"
    },
    
    # 4. System Security Tools
    @{
        Name = "Sysinternals Suite"; 
        Category = "System Tools"; 
        Url = "https://download.sysinternals.com/files/SysinternalsSuite.zip"; 
        FileName = "SysinternalsSuite.zip"; 
        Description = "Advanced system utilities and technical information from Microsoft"
    },
    @{
        Name = "Process Monitor"; 
        Category = "System Monitoring"; 
        Url = "https://download.sysinternals.com/files/ProcessMonitor.zip"; 
        FileName = "ProcessMonitor.zip"; 
        Description = "Advanced monitoring tool that shows real-time file system, registry and process/thread activity"
    },
    @{
        Name = "Autoruns"; 
        Category = "System Security"; 
        Url = "https://download.sysinternals.com/files/Autoruns.zip"; 
        FileName = "Autoruns.zip"; 
        Description = "Shows what programs are configured to run during system bootup or login"
    },
    
    # 5. Remote Management
    @{
        Name = "RustDesk"; 
        Category = "Remote Desktop"; 
        Url = "https://github.com/rustdesk/rustdesk/releases/download/1.3.2/rustdesk-1.3.2-x86_64.exe"; 
        FileName = "rustdesk-1.3.2-x86_64.exe"; 
        Description = "Open source remote desktop software alternative to TeamViewer"
    },
    @{
        Name = "TightVNC"; 
        Category = "Remote Desktop"; 
        Url = "https://www.tightvnc.com/download/2.8.85/tightvnc-2.8.85-gpl-setup-64bit.msi"; 
        FileName = "tightvnc-2.8.85-gpl-setup-64bit.msi"; 
        Description = "Free remote control software package derived from the popular VNC software"
    },
    
    # 6. Backup and Recovery
    @{
        Name = "UrBackup Client"; 
        Category = "Backup"; 
        Url = "https://hndl.urbackup.org/Client/2.6.1/UrBackup-Client-2.6.1.exe"; 
        FileName = "UrBackup-Client-2.6.1.exe"; 
        Description = "Client/server backup system for Windows, Linux and macOS"
    },
    @{
        Name = "Duplicati"; 
        Category = "Backup"; 
        Url = "https://github.com/duplicati/duplicati/releases/download/v2.0.8.1_canary_2024-05-07/duplicati-2.0.8.1_canary_2024-05-07-x64.zip"; 
        FileName = "duplicati-2.0.8.1-x64.zip"; 
        Description = "Free backup software to store encrypted backups online with strong encryption"
    },
    @{
        Name = "Kopia"; 
        Category = "Backup"; 
        Url = "https://github.com/kopia/kopia/releases/download/v0.18.1/KopiaUI-0.18.1-win-x64.zip"; 
        FileName = "KopiaUI-0.18.1-win-x64.zip"; 
        Description = "Fast and secure backup tool with end-to-end encryption"
    },
    @{
        Name = "Rescuezilla"; 
        Category = "Backup & Recovery"; 
        Url = "https://github.com/rescuezilla/rescuezilla/releases/download/2.5.1/rescuezilla-2.5.1-64bit.iso"; 
        FileName = "rescuezilla-2.5.1-64bit.iso"; 
        Description = "Rescue and recovery distribution that makes it easy to rescue a broken computer system"
    },
    
    # 7. Privacy and Encryption
    @{
        Name = "VeraCrypt"; 
        Category = "Encryption"; 
        Url = "https://launchpad.net/veracrypt/trunk/1.26.15/+download/VeraCrypt%20Setup%201.26.15.exe"; 
        FileName = "VeraCrypt-1.26.15.exe"; 
        Description = "Free disk encryption software based on TrueCrypt"
    },
    @{
        Name = "KeePassXC"; 
        Category = "Password Manager"; 
        Url = "https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-Win64.msi"; 
        FileName = "KeePassXC-2.7.9-Win64.msi"; 
        Description = "Free and open-source password manager compatible with KeePass"
    },
    
    # 8. Productivity Suite
    @{
        Name = "LibreOffice"; 
        Category = "Office Suite"; 
        Url = "https://download.documentfoundation.org/libreoffice/stable/24.8.2/win/x86_64/LibreOffice_24.8.2_Win_x86-64.msi"; 
        FileName = "LibreOffice_24.8.2_Win_x86-64.msi"; 
        Description = "Full-featured office productivity suite - alternative to Microsoft Office"
    },
    @{
        Name = "OnlyOffice Desktop"; 
        Category = "Office Suite"; 
        Url = "https://github.com/ONLYOFFICE/DesktopEditors/releases/download/v8.2.0/DesktopEditors-win-x64.exe"; 
        FileName = "DesktopEditors-win-x64.exe"; 
        Description = "Complete office suite with collaboration features"
    },
    @{
        Name = "Thunderbird"; 
        Category = "Email Client"; 
        Url = "https://download.mozilla.org/pub/thunderbird/releases/128.2.3esr/win64/en-US/Thunderbird%20Setup%20128.2.3esr.exe"; 
        FileName = "Thunderbird-128.2.3esr.exe"; 
        Description = "Free email, calendar and chat client from Mozilla"
    },
    @{
        Name = "Firefox"; 
        Category = "Web Browser"; 
        Url = "https://download.mozilla.org/?product=firefox-130.0.1-SSL&os=win64&lang=en-US"; 
        FileName = "Firefox-130.0.1.exe"; 
        Description = "Free and open-source web browser"
    },
    
    # 9. System Utilities
    @{
        Name = "7-Zip"; 
        Category = "Archiving"; 
        Url = "https://www.7-zip.org/a/7z2408-x64.exe"; 
        FileName = "7z2408-x64.exe"; 
        Description = "Free file archiver with high compression ratio"
    },
    @{
        Name = "BleachBit"; 
        Category = "System Cleaner"; 
        Url = "https://download.bleachbit.org/BleachBit-4.6.2-portable.zip"; 
        FileName = "BleachBit-4.6.2-portable.zip"; 
        Description = "Free disk space cleaner, privacy manager, and computer system cleaner"
    },
    @{
        Name = "Everything"; 
        Category = "File Search"; 
        Url = "https://www.voidtools.com/Everything-1.4.1.1026.x64.zip"; 
        FileName = "Everything-1.4.1.1026.x64.zip"; 
        Description = "Locate files and folders by name instantly"
    },
    
    # 10. Monitoring Tools
    @{
        Name = "Zabbix Agent"; 
        Category = "Monitoring"; 
        Url = "https://cdn.zabbix.com/zabbix/binaries/stable/7.0/7.0.4/zabbix_agent-7.0.4-windows-amd64.msi"; 
        FileName = "zabbix_agent-7.0.4-windows-amd64.msi"; 
        Description = "Enterprise-class monitoring solution agent"
    },
    @{
        Name = "NXLog CE"; 
        Category = "Log Collection"; 
        Url = "https://nxlog.co/system/files/products/files/348/nxlog-ce-3.2.2329.msi"; 
        FileName = "nxlog-ce-3.2.2329.msi"; 
        Description = "Multi-platform log management tool that helps collect, process and forward logs"
    },
    
    # 11. Virtualization
    @{
        Name = "VirtualBox"; 
        Category = "Virtualization"; 
        Url = "https://download.virtualbox.org/virtualbox/7.1.4/VirtualBox-7.1.4-165100-Win.exe"; 
        FileName = "VirtualBox-7.1.4-165100-Win.exe"; 
        Description = "Cross-platform virtualization application for x86 and AMD64/Intel64 hardware"
    },
    
    # 12. Runtimes (Essential)
    @{
        Name = "Visual C++ Redistributables"; 
        Category = "Runtime"; 
        Url = "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe"; 
        FileName = "VisualCppRedist_AIO_x86_x64.exe"; 
        Description = "All-in-one Visual C++ redistributable packages"
    },
    @{
        Name = ".NET Desktop Runtime"; 
        Category = "Runtime"; 
        Url = "https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/8.0.8/windowsdesktop-runtime-8.0.8-win-x64.exe"; 
        FileName = "windowsdesktop-runtime-8.0.8-win-x64.exe"; 
        Description = "Microsoft .NET Desktop Runtime for Windows applications"
    },
    @{
        Name = "OpenJDK"; 
        Category = "Runtime"; 
        Url = "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.4%2B7/OpenJDK21U-jdk_x64_windows_hotspot_21.0.4_7.msi"; 
        FileName = "OpenJDK21U-jdk_x64_windows_hotspot_21.0.4_7.msi"; 
        Description = "Open source Java Development Kit"
    }
)

# Download each security tool
$downloadedFiles = @()
$failedDownloads = @()

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  DOWNLOADING FREE SECURITY TOOLS (NO TRIALS)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($tool in $securityTools) {
    $outFile = Join-Path -Path $outputDir -ChildPath $tool.FileName
    
    Write-Host "Processing: $($tool.Name) - $($tool.Category)" -ForegroundColor Yellow
    Write-Host "Description: $($tool.Description)" -ForegroundColor White
    
    $success = Download-FileWithProgress -Name $tool.Name -Url $tool.Url -OutFile $outFile
    
    if ($success -and (Test-Path $outFile)) {
        $fileSize = (Get-Item $outFile).Length / 1MB
        $downloadedFiles += [PSCustomObject]@{
            Name = $tool.Name
            Category = $tool.Category
            Path = $outFile
            Size = "{0:N2} MB" -f $fileSize
        }
    } else {
        $failedDownloads += $tool.Name
    }
    
    Write-Host "" # Empty line for spacing
}

# Generate report of downloaded tools
$reportPath = "$outputDir\Security_Tools_Report.html"
$htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Free Security Tools Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0066cc; }
        h2 { color: #0099ff; margin-top: 20px; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        .success { color: green; }
        .failure { color: red; }
        .category { font-weight: bold; }
    </style>
</head>
<body>
    <h1>Free Security Tools Report</h1>
    <p>Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <h2>Downloaded Tools</h2>
"@

$htmlBody = ""
if ($downloadedFiles.Count -gt 0) {
    $htmlBody += @"
    <table>
        <tr>
            <th>Name</th>
            <th>Category</th>
            <th>File Location</th>
            <th>Size</th>
        </tr>
"@

    foreach ($file in $downloadedFiles) {
        $htmlBody += @"
        <tr>
            <td>$($file.Name)</td>
            <td class="category">$($file.Category)</td>
            <td>$($file.Path)</td>
            <td>$($file.Size)</td>
        </tr>
"@
    }
    
    $htmlBody += "</table>"
} else {
    $htmlBody += "<p class='failure'>No tools were successfully downloaded.</p>"
}

$htmlBody += "<h2>Failed Downloads</h2>"
if ($failedDownloads.Count -gt 0) {
    $htmlBody += "<ul>"
    foreach ($failure in $failedDownloads) {
        $htmlBody += "<li class='failure'>$failure</li>"
    }
    $htmlBody += "</ul>"
} else {
    $htmlBody += "<p class='success'>All downloads completed successfully!</p>"
}

$htmlBody += @"
    <h2>Usage Instructions</h2>
    <ol>
        <li>Install antivirus/malware protection tools first for immediate protection</li>
        <li>For MSI files, double-click to install or use command: <code>msiexec /i "path\to\file.msi" /qn</code></li>
        <li>For ZIP files, extract the contents before using the software</li>
        <li>For ISO files, use a tool like Windows Explorer, 7-Zip, or PowerShell's <code>Mount-DiskImage</code> to mount or extract</li>
        <li>For EXE files, run as administrator to install</li>
    </ol>
    
    <h2>Key Security Tools Categories</h2>
    <ul>
        <li><strong>Antivirus & Malware Protection:</strong> ClamAV, Immunet</li>
        <li><strong>Host Security:</strong> OSSEC HIDS, OSQuery</li>
        <li><strong>Network Security:</strong> Wireshark, Snort, Zeek</li>
        <li><strong>System Security:</strong> Sysinternals Suite, OSQuery</li>
        <li><strong>Forensics:</strong> SANS SIFT, Volatility</li>
        <li><strong>Monitoring & SIEM:</strong> Wazuh, NXLog CE</li>
        <li><strong>Privacy & Encryption:</strong> VeraCrypt, KeePassXC</li>
        <li><strong>Backup & Recovery:</strong> Rescuezilla, Duplicati</li>
    </ul>
</body>
</html>
"@

$htmlReport = $htmlHeader + $htmlBody
Set-Content -Path $reportPath -Value $htmlReport

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  DOWNLOAD SUMMARY" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Successfully downloaded: $($downloadedFiles.Count) tools" -ForegroundColor Green
Write-Host "Failed downloads: $($failedDownloads.Count) tools" -ForegroundColor $(if ($failedDownloads.Count -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Download location: $outputDir" -ForegroundColor Yellow
Write-Host "Report generated: $reportPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT: These are all 100% free and open-source alternatives - NO TRIALS!" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Cyan
