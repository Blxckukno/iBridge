# Get-Latest.psm1
# Helper module to select the latest installers in each folder

function Get-LatestInstaller {
    <#
    .SYNOPSIS
    Gets the latest installer in a specified directory by version or date.
    
    .DESCRIPTION
    This function finds the latest installer in the specified directory by
    parsing version numbers from file names or comparing file creation dates.
    
    .PARAMETER Path
    The path to search for installers.
    
    .PARAMETER Filter
    The file pattern to match (e.g., "*.exe", "*.msi"). Default is all installer types.
    
    .PARAMETER VersionRegex
    A regular expression to extract version numbers from file names.
    Default pattern matches common version formats like 1.2.3 or v1.2.3.4.
    
    .PARAMETER UseFileDate
    If specified, uses file creation/modification date instead of parsing version from filename.
    
    .EXAMPLE
    Get-LatestInstaller -Path "C:\Downloads" -Filter "Firefox*.exe"
    
    .EXAMPLE
    Get-LatestInstaller -Path "C:\Program Files" -UseFileDate
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$Filter = "*.*",
        
        [Parameter(Mandatory=$false)]
        [string]$VersionRegex = '(?:v|version|ver|rev)?[.-_]?(\d+(?:\.\d+){1,3})',
        
        [Parameter(Mandatory=$false)]
        [switch]$UseFileDate,
        
        # Support legacy parameters
        [Parameter(DontShow)]
        [string]$FolderPath,
        
        [Parameter(DontShow)]
        [string]$NamePattern
    )
    
    # Handle legacy parameter support
    if ($FolderPath -and -not $Path) {
        $Path = $FolderPath
    }
    
    if ($NamePattern -and -not $Filter) {
        $Filter = "*$NamePattern*"
    }
    
    # Check if the path exists
    if (-not (Test-Path -Path $Path)) {
        Write-Error "The specified path '$Path' does not exist."
        return $null
    }
    
    # Define the installer file types if no specific filter is provided
    if ($Filter -eq "*.*") {
        $Filter = "*.exe", "*.msi", "*.zip", "*.msu", "*.iso"
    } else {
        $Filter = @($Filter)
    }
    
    # Get all matching files
    $files = $Filter | ForEach-Object {
        Get-ChildItem -Path $Path -Filter $_ -File -Recurse
    }
    
    if ($null -eq $files -or $files.Count -eq 0) {
        Write-Warning "No files matching the pattern were found in '$Path'."
        return $null
    }
    
    # Choose between version number or file date comparison
    if ($UseFileDate) {
        # Sort by the last write time (newest first)
        $latestFile = $files | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
    } else {
        # Parse version from file name
        $latestVersion = $null
        $latestFile = $null
        
        foreach ($file in $files) {
            # Extract version using regex
            if ($file.Name -match $VersionRegex) {
                $versionStr = $matches[1]
                
                try {
                    # Parse the version string
                    $version = [version]$versionStr
                    
                    # Compare with current latest version
                    if ($null -eq $latestVersion -or $version -gt $latestVersion) {
                        $latestVersion = $version
                        $latestFile = $file
                    }
                } catch {
                    # If version parsing fails, continue to next file
                    continue
                }
            }
        }
        
        # If no parsable versions found, fall back to date sorting
        if ($null -eq $latestFile) {
            Write-Verbose "No parsable versions found, falling back to file date."
            $latestFile = $files | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
        }
    }
    
    # Return the latest file full path for compatibility with old function
    if ($latestFile) {
        return $latestFile.FullName
    } else {
        return $null
    }
}

function Get-FOSSAlternative {
    <#
    .SYNOPSIS
    Returns information about FOSS alternatives to commercial software.
    
    .DESCRIPTION
    This function provides information about Free and Open Source Software (FOSS)
    alternatives to commercial/paid software in different categories.
    
    .PARAMETER Category
    The software category to look for alternatives in.
    
    .PARAMETER CommercialProduct
    The name of the commercial product to find alternatives for.
    
    .PARAMETER ListAll
    List all FOSS alternatives in the database.
    
    .EXAMPLE
    Get-FOSSAlternative -Category "Antivirus"
    
    .EXAMPLE
    Get-FOSSAlternative -CommercialProduct "Adobe Photoshop"
    
    .EXAMPLE
    Get-FOSSAlternative -ListAll
    #>
    
    [CmdletBinding(DefaultParameterSetName="Category")]
    param (
        [Parameter(ParameterSetName="Category")]
        [string]$Category,
        
        [Parameter(ParameterSetName="Commercial")]
        [string]$CommercialProduct,
        
        [Parameter(ParameterSetName="All")]
        [switch]$ListAll
    )
    
    # Define the FOSS alternatives database
    $fossAlternatives = @(
        # Antivirus & Security
        @{
            Category = "Antivirus"
            Commercial = "Kaspersky, McAfee, Norton"
            Name = "ClamAV"
            Description = "Open source antivirus engine"
            URL = "https://www.clamav.net/"
            License = "GPL"
        },
        @{
            Category = "Antivirus"
            Commercial = "Avast, AVG"
            Name = "Immunet"
            Description = "Free community-driven cloud antivirus"
            URL = "https://www.immunet.com/"
            License = "Freeware"
        },
        
        # Endpoint Management
        @{
            Category = "Endpoint Management"
            Commercial = "ManageEngine, Microsoft SCCM"
            Name = "TacticalRMM"
            Description = "Remote monitoring and management platform"
            URL = "https://tacticalrmm.com/"
            License = "MIT"
        },
        @{
            Category = "Endpoint Management"
            Commercial = "TeamViewer, LogMeIn"
            Name = "RustDesk"
            Description = "Open source remote desktop software"
            URL = "https://rustdesk.com/"
            License = "AGPL-3.0"
        },
        @{
            Category = "Endpoint Management"
            Commercial = "ConnectWise Control, Datto RMM"
            Name = "MeshCentral"
            Description = "Full computer management"
            URL = "https://meshcentral.com/"
            License = "Apache-2.0"
        },
        
        # Monitoring & SIEM
        @{
            Category = "SIEM/XDR"
            Commercial = "Splunk, IBM QRadar, Microsoft Sentinel"
            Name = "Wazuh"
            Description = "Security monitoring, threat detection and response"
            URL = "https://wazuh.com/"
            License = "GPL-2.0"
        },
        @{
            Category = "Network Monitoring"
            Commercial = "SolarWinds, PRTG"
            Name = "Zabbix"
            Description = "Enterprise-class monitoring solution"
            URL = "https://www.zabbix.com/"
            License = "GPL-2.0"
        },
        @{
            Category = "Network Monitoring"
            Commercial = "WhatsUp Gold, Nagios XI"
            Name = "LibreNMS"
            Description = "Auto-discovering network monitoring"
            URL = "https://www.librenms.org/"
            License = "GPL-3.0"
        },
        
        # Backup Solutions
        @{
            Category = "Backup"
            Commercial = "Veeam, Acronis"
            Name = "UrBackup"
            Description = "Client/server backup system"
            URL = "https://www.urbackup.org/"
            License = "AGPL-3.0"
        },
        @{
            Category = "Backup"
            Commercial = "Commvault, Veritas"
            Name = "Duplicati"
            Description = "Free backup software with encryption"
            URL = "https://www.duplicati.com/"
            License = "LGPL-2.1"
        },
        @{
            Category = "Backup"
            Commercial = "ArcServe, Metallic"
            Name = "Kopia"
            Description = "Fast and secure backup tool"
            URL = "https://kopia.io/"
            License = "Apache-2.0"
        },
        
        # Virtualization
        @{
            Category = "Virtualization"
            Commercial = "VMware ESXi, Microsoft Hyper-V"
            Name = "Proxmox VE"
            Description = "Complete server virtualization platform"
            URL = "https://www.proxmox.com/en/proxmox-ve"
            License = "AGPL-3.0"
        },
        @{
            Category = "Virtualization"
            Commercial = "VMware Workstation, Parallels"
            Name = "VirtualBox"
            Description = "Cross-platform virtualization"
            URL = "https://www.virtualbox.org/"
            License = "GPL-2.0"
        },
        
        # Storage
        @{
            Category = "Storage"
            Commercial = "NetApp, EMC"
            Name = "TrueNAS"
            Description = "Open source storage operating system"
            URL = "https://www.truenas.com/"
            License = "BSD-2-Clause"
        },
        @{
            Category = "Storage"
            Commercial = "Dell EMC Unity, HP MSA"
            Name = "OpenMediaVault"
            Description = "Network attached storage solution"
            URL = "https://www.openmediavault.org/"
            License = "GPL-3.0"
        },
        
        # Productivity
        @{
            Category = "Office Suite"
            Commercial = "Microsoft Office"
            Name = "LibreOffice"
            Description = "Full-featured office productivity suite"
            URL = "https://www.libreoffice.org/"
            License = "LGPL-3.0"
        },
        @{
            Category = "Office Suite"
            Commercial = "Microsoft Office 365"
            Name = "OnlyOffice"
            Description = "Complete office suite with collaboration"
            URL = "https://www.onlyoffice.com/"
            License = "AGPL-3.0"
        },
        @{
            Category = "Email Client"
            Commercial = "Microsoft Outlook"
            Name = "Thunderbird"
            Description = "Email, calendar and chat client"
            URL = "https://www.thunderbird.net/"
            License = "MPL-2.0"
        },
        
        # Design & Graphics
        @{
            Category = "Photo Editing"
            Commercial = "Adobe Photoshop"
            Name = "GIMP"
            Description = "Image editing program"
            URL = "https://www.gimp.org/"
            License = "GPL-3.0"
        },
        @{
            Category = "Vector Graphics"
            Commercial = "Adobe Illustrator"
            Name = "Inkscape"
            Description = "Professional vector graphics editor"
            URL = "https://inkscape.org/"
            License = "GPL-2.0"
        },
        @{
            Category = "PDF Management"
            Commercial = "Adobe Acrobat Pro"
            Name = "PDF Split and Merge"
            Description = "Tool to split, merge, rotate PDF files"
            URL = "https://pdfsam.org/"
            License = "AGPL-3.0"
        }
    )
    
    # Filter the results based on parameters
    $results = switch ($PSCmdlet.ParameterSetName) {
        "Category" {
            if ([string]::IsNullOrEmpty($Category)) {
                # Return unique categories if no specific category is provided
                $fossAlternatives | ForEach-Object { $_.Category } | Sort-Object -Unique
                return
            } else {
                $fossAlternatives | Where-Object { $_.Category -like "*$Category*" }
            }
        }
        "Commercial" {
            $fossAlternatives | Where-Object { $_.Commercial -like "*$CommercialProduct*" }
        }
        "All" {
            $fossAlternatives
        }
    }
    
    # Return the results
    return $results
}

function Download-FOSSAlternative {
    <#
    .SYNOPSIS
    Downloads a FOSS alternative to a specified location.
    
    .DESCRIPTION
    This function downloads a Free and Open Source Software (FOSS)
    alternative to a specified location using direct download URLs.
    
    .PARAMETER Name
    The name of the FOSS software to download.
    
    .PARAMETER OutPath
    The path where the downloaded file should be saved.
    
    .EXAMPLE
    Download-FOSSAlternative -Name "ClamAV" -OutPath "C:\Downloads"
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$OutPath
    )
    
    # Define download URLs for FOSS software
    $downloadUrls = @{
        # Security
        "ClamAV" = "https://www.clamav.net/downloads/production/clamav-1.3.1.win.x64.msi"
        "Immunet" = "https://download.immunet.com/binaries/immunet/setup/Immunet-7.0.15.11121-installer.exe"
        "OSSEC" = "https://updates.atomicorp.com/channels/atomic/windows/ossec-agent-win32-3.7.0.exe"
        "Wazuh" = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.3-1.msi"
        
        # Remote Management
        "RustDesk" = "https://github.com/rustdesk/rustdesk/releases/download/1.2.5/rustdesk-1.2.5-x86_64.exe"
        "MeshCentral" = "https://github.com/Ylianst/MeshCentral/archive/refs/tags/v1.1.15.zip"
        "TacticalRMM" = "https://github.com/amidaware/tacticalrmm/releases/download/v0.17.2/tactical_agent_0.17.2_windows_amd64.exe"
        
        # Backup
        "UrBackup" = "https://hndl.urbackup.org/Client/2.5.25/UrBackup-Client-2.5.25.exe"
        "Duplicati" = "https://github.com/duplicati/duplicati/releases/download/v2.0.6.3-2.0.6.3_beta_2021-06-17/duplicati-2.0.6.3_beta_2021-06-17-x64.zip"
        "Kopia" = "https://github.com/kopia/kopia/releases/download/v0.15.0/KopiaUI-0.15.0-win-x64.zip"
        
        # Office Suite
        "LibreOffice" = "https://download.documentfoundation.org/libreoffice/stable/24.8.3/win/x86_64/LibreOffice_24.8.3_Win_x86-64.msi"
        "OnlyOffice" = "https://github.com/ONLYOFFICE/DesktopEditors/releases/download/v8.0.0/DesktopEditors-win-x64.exe"
        "Thunderbird" = "https://download.mozilla.org/?product=thunderbird-115.8.1-SSL&os=win64&lang=en-US"
        
        # Utilities
        "7-Zip" = "https://www.7-zip.org/a/7z2301-x64.exe"
        "VeraCrypt" = "https://launchpad.net/veracrypt/trunk/1.26.7/+download/VeraCrypt%20Setup%201.26.7.exe"
        "KeePassXC" = "https://github.com/keepassxreboot/keepassxc/releases/download/2.7.6/KeePassXC-2.7.6-Win64.msi"
        
        # Monitoring
        "Zabbix" = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.9/zabbix_agent-6.4.9-windows-amd64.msi"
        "Wireshark" = "https://www.wireshark.org/download/win64/Wireshark-win64-4.2.0.exe"
        "OpenVAS" = "https://github.com/greenbone/openvas-scanner/releases/latest"
    }
    
    # Check if the software is in our list
    if (-not $downloadUrls.ContainsKey($Name)) {
        Write-Error "Software '$Name' not found in the download database."
        # Show available options
        Write-Host "Available software options:" -ForegroundColor Yellow
        $downloadUrls.Keys | Sort-Object | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
        return $false
    }
    
    # Ensure output directory exists
    if (-not (Test-Path $OutPath)) {
        New-Item -Path $OutPath -ItemType Directory -Force | Out-Null
    }
    
    # Determine file name from URL
    $url = $downloadUrls[$Name]
    $fileName = [System.IO.Path]::GetFileName($url.Split('?')[0])
    if ([string]::IsNullOrEmpty($fileName)) {
        $fileName = "$Name-installer.exe"
    }
    
    $outFile = Join-Path -Path $OutPath -ChildPath $fileName
    
    # Download the file
    try {
        Write-Host "Downloading $Name from $url..." -ForegroundColor Cyan
        
        # Create WebClient and set headers
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PowerShell Script")
        
        # Download the file
        $webClient.DownloadFile($url, $outFile)
        
        Write-Host "Successfully downloaded $Name to $outFile" -ForegroundColor Green
        return $outFile
    }
    catch {
        Write-Error "Failed to download $Name. Error: $($_.Exception.Message)"
        return $false
    }
}

# Export module functions
Export-ModuleMember -Function Get-LatestInstaller, Get-FOSSAlternative, Download-FOSSAlternative
