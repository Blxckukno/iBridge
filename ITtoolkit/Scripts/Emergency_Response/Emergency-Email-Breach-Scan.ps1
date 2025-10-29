# Emergency-Email-Breach-Scan.ps1
# Advanced PowerShell script for Microsoft email server breach investigation
# Pinpoints malware location and takes remediation action
# Run as Administrator on DISCONNECTED machine

param(
    [switch]$DownloadMode = $false,  # Set to $true if running on clean machine to download tools
    [string]$USBPath = "E:\SecurityTools"  # Change to your USB drive path
)

# Check for administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator!"
    Write-Host "Please right-click and 'Run as Administrator'" -ForegroundColor Red
    exit 1
}

$toolsDir = "$env:USERPROFILE\Desktop\EmailBreachScan"
New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
Set-Location $toolsDir

Write-Host "=== EMERGENCY EMAIL BREACH RESPONSE ===" -ForegroundColor Red
Write-Host "Target: @ibridge.co.za Microsoft Email Server" -ForegroundColor Yellow
Write-Host "Tools Directory: $toolsDir" -ForegroundColor Cyan

# Function to download or copy tools
function Get-SecurityTool {
    param($Name, $URL, $Filename, $Description)
    
    Write-Host "[$Name] $Description" -ForegroundColor Green
    
    if ($DownloadMode) {
        if (!(Test-Path $Filename)) {
            try {
                Write-Host "  Downloading $Filename..." -ForegroundColor Yellow
                Invoke-WebRequest -Uri $URL -OutFile $Filename -UseBasicParsing
                Write-Host "  Downloaded successfully" -ForegroundColor Green
            } catch {
                Write-Warning "  Failed to download $Filename`: $_"
            }
        } else {
            Write-Host "  $Filename already exists" -ForegroundColor Gray
        }
    } else {
        # Copy from USB
        $sourcePath = Join-Path $USBPath $Filename
        if (Test-Path $sourcePath) {
            Copy-Item $sourcePath . -Force
            Write-Host "  Copied $Filename from USB" -ForegroundColor Green
        } else {
            Write-Warning "  $Filename not found on USB at $sourcePath"
        }
    }
}

# Download/Copy Security Tools
Write-Host "`n=== ACQUIRING SECURITY TOOLS ===" -ForegroundColor Cyan

Get-SecurityTool "Malwarebytes" "https://downloads.malwarebytes.com/file/mb4_offline" "mbam-setup.exe" "Anti-malware scanner"
Get-SecurityTool "HitmanPro" "https://dl.surfright.nl/HitmanPro_x64.exe" "hitmanpro.exe" "Advanced threat scanner"
Get-SecurityTool "Emsisoft EEK" "https://cdn.emsisoft.com/EmsisoftEmergencyKit.exe" "eeksetup.exe" "Emergency malware kit"
Get-SecurityTool "Process Explorer" "https://download.sysinternals.com/files/ProcessExplorer.zip" "procexp.zip" "Process analysis"
Get-SecurityTool "Autoruns" "https://download.sysinternals.com/files/Autoruns.zip" "autoruns.zip" "Startup analysis"
Get-SecurityTool "TCPView" "https://download.sysinternals.com/files/TCPView.zip" "tcpview.zip" "Network connections"
Get-SecurityTool "RootkitRevealer" "https://download.sysinternals.com/files/RootkitRevealer.zip" "rootkitrevealer.zip" "Rootkit detection"

# Extract ZIP files
Write-Host "`n=== EXTRACTING TOOLS ===" -ForegroundColor Cyan
$zipFiles = @("procexp.zip", "autoruns.zip", "tcpview.zip", "rootkitrevealer.zip")
foreach ($zip in $zipFiles) {
    if (Test-Path $zip) {
        Write-Host "Extracting $zip..." -ForegroundColor Yellow
        Expand-Archive -Path $zip -DestinationPath "." -Force
    }
}

# Email Server Diagnostics
Write-Host "`n=== EMAIL SERVER DIAGNOSTICS ===" -ForegroundColor Red

function Test-EmailConnections {
    Write-Host "Checking email-related network connections..." -ForegroundColor Yellow
    
    # Check for suspicious connections to email ports
    $emailPorts = @(25, 110, 143, 587, 993, 995, 465)
    $suspiciousConnections = @()
    
    foreach ($port in $emailPorts) {
        $connections = netstat -an | Select-String ":$port"
        if ($connections) {
            Write-Host "Active connections on port $port (email-related):" -ForegroundColor Red
            $connections | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            $suspiciousConnections += $connections
        }
    }
    
    return $suspiciousConnections
}

function Check-EmailProcesses {
    Write-Host "Analyzing email-related processes..." -ForegroundColor Yellow
    
    # Look for suspicious processes that might be sending emails
    $emailKeywords = @("smtp", "mail", "outlook", "exchange", "imap", "pop3")
    $suspiciousProcesses = @()
    
    foreach ($keyword in $emailKeywords) {
        $processes = Get-Process | Where-Object { $_.ProcessName -like "*$keyword*" -or $_.Description -like "*$keyword*" }
        if ($processes) {
            Write-Host "Email-related processes found:" -ForegroundColor Red
            $processes | ForEach-Object { 
                Write-Host "  $($_.ProcessName) (PID: $($_.Id)) - $($_.Description)" -ForegroundColor Gray
                $suspiciousProcesses += $_
            }
        }
    }
    
    return $suspiciousProcesses
}

function Check-RegistryPersistence {
    Write-Host "Checking registry for email malware persistence..." -ForegroundColor Yellow
    
    $registryKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    )
    
    foreach ($key in $registryKeys) {
        try {
            $entries = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
            if ($entries) {
                $entries.PSObject.Properties | Where-Object { 
                    $_.Name -notmatch "^PS" -and 
                    ($_.Value -like "*mail*" -or $_.Value -like "*smtp*" -or $_.Value -like "*ibridge*")
                } | ForEach-Object {
                    Write-Host "Suspicious registry entry in $key`: $($_.Name) = $($_.Value)" -ForegroundColor Red
                }
            }
        } catch {
            Write-Warning "Could not check registry key: $key"
        }
    }
}

function Check-TaskScheduler {
    Write-Host "Checking scheduled tasks for email malware..." -ForegroundColor Yellow
    
    try {
        $tasks = Get-ScheduledTask | Where-Object { 
            $_.TaskName -like "*mail*" -or 
            $_.TaskName -like "*smtp*" -or 
            $_.TaskName -like "*ibridge*" -or
            $_.Description -like "*mail*"
        }
        
        foreach ($task in $tasks) {
            Write-Host "Suspicious scheduled task: $($task.TaskName)" -ForegroundColor Red
            Write-Host "  State: $($task.State)" -ForegroundColor Gray
            Write-Host "  Description: $($task.Description)" -ForegroundColor Gray
        }
    } catch {
        Write-Warning "Could not check scheduled tasks"
    }
}

# Run diagnostics
$emailConnections = Test-EmailConnections
$emailProcesses = Check-EmailProcesses
Check-RegistryPersistence
Check-TaskScheduler

# Install and launch security tools
Write-Host "`n=== LAUNCHING SECURITY TOOLS ===" -ForegroundColor Cyan

# Install Malwarebytes
if (Test-Path "mbam-setup.exe") {
    Write-Host "Installing Malwarebytes..." -ForegroundColor Green
    Start-Process -FilePath "mbam-setup.exe" -ArgumentList "/verysilent", "/norestart" -Wait
    Start-Sleep -Seconds 5
    
    # Launch Malwarebytes
    $mbamPath = "${env:ProgramFiles}\Malwarebytes\Anti-Malware\mbam.exe"
    if (Test-Path $mbamPath) {
        Write-Host "Launching Malwarebytes - PLEASE RUN FULL SCAN" -ForegroundColor Yellow
        Start-Process -FilePath $mbamPath
    }
}

# Launch HitmanPro
if (Test-Path "hitmanpro.exe") {
    Write-Host "Launching HitmanPro - PLEASE RUN SCAN" -ForegroundColor Yellow
    Start-Process -FilePath "hitmanpro.exe"
}

# Extract and launch Emsisoft
if (Test-Path "eeksetup.exe") {
    Write-Host "Extracting Emsisoft Emergency Kit..." -ForegroundColor Green
    Start-Process -FilePath "eeksetup.exe" -ArgumentList "/extract" -Wait
    
    if (Test-Path "EEK\bin64\a2cmd.exe") {
        Write-Host "Launching Emsisoft Emergency Kit - PLEASE UPDATE AND SCAN" -ForegroundColor Yellow
        Start-Process -FilePath "EEK\bin64\a2cmd.exe"
    }
}

# Launch Sysinternals tools
if (Test-Path "procexp64.exe") {
    Write-Host "Launching Process Explorer - CHECK FOR SUSPICIOUS PROCESSES" -ForegroundColor Yellow
    Start-Process -FilePath "procexp64.exe"
}

if (Test-Path "Autoruns64.exe") {
    Write-Host "Launching Autoruns - CHECK LOGON/SCHEDULED TASKS TABS" -ForegroundColor Yellow
    Start-Process -FilePath "Autoruns64.exe"
}

if (Test-Path "Tcpview.exe") {
    Write-Host "Launching TCPView - MONITOR NETWORK CONNECTIONS" -ForegroundColor Yellow
    Start-Process -FilePath "Tcpview.exe"
}

# Generate incident report
$reportPath = "$toolsDir\IncidentReport_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').txt"
$report = @"
EMAIL BREACH INCIDENT REPORT
Generated: $(Get-Date)
Target Domain: @ibridge.co.za
Scan Location: $env:COMPUTERNAME

SUSPICIOUS EMAIL CONNECTIONS FOUND:
$($emailConnections -join "`n")

SUSPICIOUS EMAIL PROCESSES FOUND:
$($emailProcesses | ForEach-Object { "$($_.ProcessName) (PID: $($_.Id))" } | Out-String)

RECOMMENDATIONS:
1. Complete full scans with all launched tools
2. Quarantine/delete any threats found
3. Check email forwarding rules in all @ibridge.co.za accounts
4. Change passwords for all affected accounts from clean machine
5. Enable MFA on all email accounts
6. Review Exchange/Office 365 audit logs
7. Check for unauthorized delegates/permissions

NEXT STEPS:
1. Run all scanning tools that have launched
2. Document any findings
3. Reboot after cleaning
4. Monitor network traffic after reconnection
5. Implement email security policies
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`nIncident report saved to: $reportPath" -ForegroundColor Green

Write-Host "`n=== CRITICAL NEXT STEPS ===" -ForegroundColor Red
Write-Host "1. INTERACT WITH ALL OPENED SECURITY TOOLS" -ForegroundColor Yellow
Write-Host "2. RUN FULL SCANS IN EACH TOOL" -ForegroundColor Yellow
Write-Host "3. QUARANTINE/DELETE ANY THREATS FOUND" -ForegroundColor Yellow
Write-Host "4. CHECK EMAIL FORWARDING RULES FOR @ibridge.co.za ACCOUNTS" -ForegroundColor Yellow
Write-Host "5. CHANGE ALL EMAIL PASSWORDS FROM CLEAN DEVICE" -ForegroundColor Yellow
Write-Host "6. ENABLE MFA ON ALL ACCOUNTS" -ForegroundColor Yellow

Write-Host "`nPress any key when scans are complete..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host "`n=== SCAN COMPLETE ===" -ForegroundColor Green
Write-Host "Please review the incident report and take the recommended actions." -ForegroundColor Cyan
