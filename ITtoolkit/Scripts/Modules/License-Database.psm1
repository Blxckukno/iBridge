# Enhanced License Mapping Database
# Maps common software names to their actual license types

$LicenseDatabase = @{
    # Microsoft Tools
    "Autoruns" = "Microsoft-Freeware"
    "ProcessExplorer" = "Microsoft-Freeware" 
    "RootkitRevealer" = "Microsoft-Freeware"
    "TCPView" = "Microsoft-Freeware"
    "Sysinternals" = "Microsoft-Freeware"
    
    # Antivirus/Security
    "ClamWin" = "GPL-Free"
    "Emsisoft" = "Freemium" # Free version available
    "EmsisoftEmergency" = "Freemium"
    "HitmanPro" = "Trial-30days" # Trial only
    "Malwarebytes" = "Freemium" # Free version available
    "MBSetup" = "Freemium"
    
    # System Utilities
    "7z" = "LGPL-Free"
    "7-Zip" = "LGPL-Free"
    "BleachBit" = "GPL-Free"
    "Everything" = "MIT-Free"
    "Recuva" = "CCleaner-Freeware"
    "rcsetup" = "CCleaner-Freeware"
    
    # Networking
    "Advanced_IP_Scanner" = "Freeware"
    "Advanced_Port_Scanner" = "Freeware"
    "nmap" = "Nmap-License-Free"
    "PuTTY" = "MIT-Free"
    "Wireshark" = "GPL-Free"
    
    # Productivity
    "Chrome" = "Google-Freeware"
    "googlechrome" = "Google-Freeware"
    "SumatraPDF" = "GPL-Free"
    
    # Runtimes
    "VisualCppRedist" = "Microsoft-Free"
    "vcredist" = "Microsoft-Free"
    
    # Drivers
    "Intel-Driver" = "Intel-Freeware"
    "SDI" = "GPL-Free" # Snappy Driver Installer
    
    # Utilities
    "rufus" = "GPL-Free"
    "HBCD" = "Freeware" # Hiren's Boot CD
}

# License categories
$LicenseTypes = @{
    "Free" = @("GPL", "LGPL", "MIT", "Apache", "BSD", "MPL", "AGPL", "Freeware", "Microsoft-Freeware", "Microsoft-Free", "Google-Freeware", "Intel-Freeware", "CCleaner-Freeware", "Nmap-License-Free")
    "Freemium" = @("Freemium") # Free version with paid upgrades
    "Trial" = @("Trial", "Trial-30days", "Demo", "Evaluation")
    "Paid" = @("Commercial", "Proprietary", "Enterprise", "Professional")
}

function Get-LicenseType {
    param($FileName)
    
    foreach ($Software in $LicenseDatabase.Keys) {
        if ($FileName -like "*$Software*") {
            $License = $LicenseDatabase[$Software]
            
            # Determine category
            foreach ($Category in $LicenseTypes.Keys) {
                if ($LicenseTypes[$Category] -contains $License -or $License -like "*$Category*") {
                    return @{
                        License = $License
                        Category = $Category
                    }
                }
            }
        }
    }
    
    return @{
        License = "Unknown"
        Category = "Unknown"
    }
}

Export-ModuleMember -Function Get-LicenseType
Export-ModuleMember -Variable LicenseDatabase, LicenseTypes