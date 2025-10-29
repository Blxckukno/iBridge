# Install-Downloaded.ps1
# Installs only the applications that were successfully downloaded
# Run in an elevated PowerShell prompt

$root = "$PSScriptRoot\..\..\Freeware"

$apps = @(
    @{ Path = "$root\01_Cybersecurity\MBSetup.exe"; Args = "/S" },
    @{ Path = "$root\01_Cybersecurity\rufus-4.4.exe"; Args = "/S" },
    @{ Path = "$root\02_Backup_Recovery\rcsetup153.exe"; Args = "/S" },
    @{ Path = "$root\03_System_Utilities\7z2407-x64.exe"; Args = "/S" },
    @{ Path = "$root\03_System_Utilities\BleachBit-4.6.0-portable.zip"; Args = "" },
    @{ Path = "$root\03_System_Utilities\Everything-1.4.1.1024.x64.zip"; Args = "" },
    @{ Path = "$root\04_Networking\nmap-7.95-setup.exe"; Args = "/S" },
    @{ Path = "$root\04_Networking\Wireshark-4.4.9-x64.exe"; Args = "/S" },
    @{ Path = "$root\04_Networking\Advanced_IP_Scanner_2.5.4594.1.exe"; Args = "/S" },
    @{ Path = "$root\04_Networking\putty-64bit-0.81-installer.msi"; Args = "/qn /norestart" },
    @{ Path = "$root\05_Productivity\SumatraPDF-3.5.2-64-install.exe"; Args = "/S" },
    @{ Path = "$root\05_Productivity\googlechromestandaloneenterprise64.msi"; Args = "/qn /norestart" },
    @{ Path = "$root\06_Runtimes\VisualCppRedist_AIO_x86_x64.exe"; Args = "/ai" },
    @{ Path = "$root\07_Drivers\SDI_R2413.exe"; Args = "/S" },
    @{ Path = "$root\07_Drivers\Intel-Driver-and-Support-Assistant-Installer.exe"; Args = "/S" }
)

foreach ($app in $apps) {
    if (Test-Path $app.Path) {
        Write-Host "Installing $($app.Path)..." -ForegroundColor Cyan
        if ($app.Path -match ".msi$") {
            Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i `"$($app.Path)`" $($app.Args)"
        } elseif ($app.Path -match ".zip$") {
            Write-Host "(Manual) Extract and install: $($app.Path)" -ForegroundColor Yellow
        } else {
            Start-Process -Wait -FilePath $app.Path -ArgumentList $app.Args
        }
        Write-Host "Done: $($app.Path)" -ForegroundColor Green
    } else {
        Write-Host "Not found: $($app.Path) (skipped)" -ForegroundColor DarkGray
    }
}
Write-Host "All available applications processed." -ForegroundColor Yellow
