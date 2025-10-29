# Install-Successfully-Downloaded.ps1
# Installs only applications that were successfully downloaded and exist on disk
# Run in an elevated PowerShell prompt

$root = "$PSScriptRoot\..\..\Freeware"
$fossRoot = "$PSScriptRoot\..\..\FOSS_Enterprise_Stack"

# Check and install successfully downloaded Freeware
$freewareApps = @(
    @{ Path = "$root\01_Cybersecurity\MBSetup.exe"; Args = "/VERYSILENT /NORESTART" },
    @{ Path = "$root\01_Cybersecurity\HBCD_PE_x64.iso"; Args = "ISO_FILE" },
    @{ Path = "$root\02_Backup_Recovery\rcsetup153.exe"; Args = "/S" },
    @{ Path = "$root\03_System_Utilities\7z2407-x64.exe"; Args = "/S" },
    @{ Path = "$root\03_System_Utilities\BleachBit-4.6.0-portable.zip"; Args = "EXTRACT" },
    @{ Path = "$root\03_System_Utilities\Everything-1.4.1.1024.x64.zip"; Args = "EXTRACT" },
    @{ Path = "$root\04_Networking\nmap-7.95-setup.exe"; Args = "/S" },
    @{ Path = "$root\04_Networking\Advanced_IP_Scanner_2.5.4594.1.exe"; Args = "/VERYSILENT" },
    @{ Path = "$root\04_Networking\putty-64bit-0.81-installer.msi"; Args = "/qn /norestart" },
    @{ Path = "$root\05_Productivity\SumatraPDF-3.5.2-64-install.exe"; Args = "/S" },
    @{ Path = "$root\05_Productivity\googlechromestandaloneenterprise64.msi"; Args = "/qn /norestart" },
    @{ Path = "$root\06_Runtimes\VisualCppRedist_AIO_x86_x64.exe"; Args = "/y" },
    @{ Path = "$root\07_Drivers\SDI_R2413.exe"; Args = "/VERYSILENT" },
    @{ Path = "$root\07_Drivers\Intel-Driver-and-Support-Assistant-Installer.exe"; Args = "/s" }
)

# Check and install successfully downloaded FOSS apps
$fossApps = @(
    @{ Path = "$fossRoot\01_Endpoint_Protection\wazuh-agent-4.7.3-1.msi"; Args = "/qn /norestart" },
    @{ Path = "$fossRoot\01_Endpoint_Protection\clamav-1.3.1.win.x64.msi"; Args = "/qn /norestart" },
    @{ Path = "$fossRoot\06_Productivity_Suite\DesktopEditors_x64.exe"; Args = "/VERYSILENT /NORESTART" }
)

Write-Host "Installing Freeware Applications..." -ForegroundColor Green
foreach ($app in $freewareApps) {
    if (Test-Path $app.Path) {
        Write-Host "Installing $($app.Path)..." -ForegroundColor Cyan
        if ($app.Args -eq "EXTRACT") {
            Write-Host "  [Manual] Extract and run: $($app.Path)" -ForegroundColor Yellow
        } elseif ($app.Args -eq "ISO_FILE") {
            Write-Host "  [Manual] Mount ISO or burn to USB: $($app.Path)" -ForegroundColor Yellow
        } elseif ($app.Path -match "\.msi$") {
            Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i `"$($app.Path)`" $($app.Args)"
        } else {
            Start-Process -Wait -FilePath $app.Path -ArgumentList $app.Args
        }
        Write-Host "  Done: $($app.Path)" -ForegroundColor Green
    } else {
        Write-Host "  Not found: $($app.Path) (skipped)" -ForegroundColor DarkGray
    }
}

Write-Host "`nInstalling FOSS Enterprise Applications..." -ForegroundColor Green
foreach ($app in $fossApps) {
    if (Test-Path $app.Path) {
        Write-Host "Installing $($app.Path)..." -ForegroundColor Cyan
        if ($app.Path -match "\.msi$") {
            Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i `"$($app.Path)`" $($app.Args)"
        } else {
            Start-Process -Wait -FilePath $app.Path -ArgumentList $app.Args
        }
        Write-Host "  Done: $($app.Path)" -ForegroundColor Green
    } else {
        Write-Host "  Not found: $($app.Path) (skipped)" -ForegroundColor DarkGray
    }
}

Write-Host "`nAll available applications processed!" -ForegroundColor Yellow
Write-Host "Manual actions required for ZIP files and ISOs as noted above." -ForegroundColor Cyan
