param(
    [string]$SiteName = "iBridgeSite",
    [string]$SiteRoot = "C:\iBridge\site",
    [string]$BackupRoot = "D:\iBridgeBackups",
    [int]$RetentionDays = 14,
    [string]$BindingHostHeader = "",
    [int]$BindingPort = 80,
    [int]$HealthMinFreeDiskPercent = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
        IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw "Run this script as Administrator."
    }
}

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

Assert-Admin

Write-Host "Installing IIS + management features..."
Install-WindowsFeature -Name Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Http-Errors,Web-Http-Redirect,Web-Performance,Web-Stat-Compression,Web-Security,Web-Filtering,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext45,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Mgmt-Tools,Web-Mgmt-Console -IncludeManagementTools | Out-Null

Ensure-Directory $SiteRoot
Ensure-Directory $BackupRoot

Import-Module WebAdministration

if (-not (Test-Path "IIS:\AppPools\$SiteName")) {
    New-WebAppPool -Name $SiteName | Out-Null
}
Set-ItemProperty "IIS:\AppPools\$SiteName" -Name processModel.identityType -Value ApplicationPoolIdentity

if (-not (Test-Path "IIS:\Sites\$SiteName")) {
    New-Website -Name $SiteName -PhysicalPath $SiteRoot -Port $BindingPort -ApplicationPool $SiteName | Out-Null
}

if ($BindingHostHeader -and $BindingHostHeader.Trim().Length -gt 0) {
    $existing = Get-WebBinding -Name $SiteName -Protocol "http" | Where-Object { $_.bindingInformation -like "*:$BindingPort:$BindingHostHeader" }
    if (-not $existing) {
        New-WebBinding -Name $SiteName -Protocol "http" -Port $BindingPort -HostHeader $BindingHostHeader | Out-Null
    }
}

$backupScriptPath = "C:\iBridge\scripts\backup-site.ps1"
$maintenanceScriptPath = "C:\iBridge\scripts\maintenance-checks.ps1"
Ensure-Directory (Split-Path -Parent $backupScriptPath)

$backupScript = @"
param(
    [string]`$Source = "$SiteRoot",
    [string]`$BackupRoot = "$BackupRoot",
    [int]`$RetentionDays = $RetentionDays
)

Set-StrictMode -Version Latest
`$ErrorActionPreference = "Stop"

if (-not (Test-Path `$Source)) { throw "Source path not found: `$Source" }
if (-not (Test-Path `$BackupRoot)) { New-Item -Path `$BackupRoot -ItemType Directory -Force | Out-Null }

`$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
`$dest = Join-Path `$BackupRoot "site-backup-`$stamp"
New-Item -Path `$dest -ItemType Directory -Force | Out-Null

robocopy `$Source `$dest /MIR /R:2 /W:2 /NFL /NDL /NP | Out-Null

`$zip = Join-Path `$BackupRoot "site-backup-`$stamp.zip"
Compress-Archive -Path (Join-Path `$dest "*") -DestinationPath `$zip -CompressionLevel Optimal
Remove-Item `$dest -Recurse -Force

`$cutoff = (Get-Date).AddDays(-`$RetentionDays)
Get-ChildItem `$BackupRoot -File -Filter "site-backup-*.zip" |
    Where-Object { `$_.LastWriteTime -lt `$cutoff } |
    Remove-Item -Force
"@

Set-Content -Path $backupScriptPath -Value $backupScript -Encoding UTF8

$maintenanceScript = @"
param(
    [string]`$SiteName = "$SiteName",
    [int]`$MinFreeDiskPercent = $HealthMinFreeDiskPercent
)

Set-StrictMode -Version Latest
`$ErrorActionPreference = "Stop"
Import-Module WebAdministration -ErrorAction SilentlyContinue

`$logRoot = "C:\iBridge\logs"
if (-not (Test-Path `$logRoot)) { New-Item -Path `$logRoot -ItemType Directory -Force | Out-Null }
`$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
`$logFile = Join-Path `$logRoot "maintenance-`$stamp.log"

function Write-Log([string]`$Line) {
    "`$(Get-Date -Format o) `$Line" | Add-Content -Path `$logFile -Encoding UTF8
}

Write-Log "Starting maintenance checks"

# Check critical IIS services
`$criticalServices = @("W3SVC", "WAS")
foreach (`$svcName in `$criticalServices) {
    `$svc = Get-Service -Name `$svcName -ErrorAction SilentlyContinue
    if (-not `$svc) {
        Write-Log "WARN service missing: `$svcName"
        continue
    }
    if (`$svc.Status -ne "Running") {
        Write-Log "WARN service not running: `$svcName, attempting restart"
        try {
            Start-Service -Name `$svcName
            Write-Log "OK restarted service: `$svcName"
        } catch {
            Write-Log "ERROR failed to restart service `$svcName: `$($_.Exception.Message)"
        }
    } else {
        Write-Log "OK service running: `$svcName"
    }
}

# Basic website local health test
try {
    `$resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1" -TimeoutSec 10
    Write-Log "OK local HTTP health: status=`$(`$resp.StatusCode)"
} catch {
    Write-Log "ERROR local HTTP health failed: `$($_.Exception.Message)"
}

# Disk free space checks
`$drives = Get-PSDrive -PSProvider FileSystem
foreach (`$d in `$drives) {
    if (`$d.Used -eq `$null -or `$d.Free -eq `$null) { continue }
    `$total = [double](`$d.Used + `$d.Free)
    if (`$total -le 0) { continue }
    `$freePct = [math]::Round((`$d.Free / `$total) * 100, 2)
    if (`$freePct -lt `$MinFreeDiskPercent) {
        Write-Log "WARN low disk space: drive=`$(`$d.Name) free=`$freePct% threshold=`$MinFreeDiskPercent%"
    } else {
        Write-Log "OK disk space: drive=`$(`$d.Name) free=`$freePct%"
    }
}

# Cleanup old IIS logs (older than 30 days)
`$iisLogRoot = "C:\inetpub\logs\LogFiles"
if (Test-Path `$iisLogRoot) {
    Get-ChildItem `$iisLogRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { `$_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Log "OK IIS log cleanup complete (retention: 30 days)"
}

# Check whether reboot is pending
`$pendingReboot = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
if (`$pendingReboot) {
    Write-Log "WARN reboot pending"
} else {
    Write-Log "OK no pending reboot"
}

Write-Log "Maintenance checks complete"
"@
Set-Content -Path $maintenanceScriptPath -Value $maintenanceScript -Encoding UTF8

$backupTaskName = "iBridge Site Backup"
$maintenanceTaskName = "iBridge Maintenance Check"
$healthTaskName = "iBridge Health Check"

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

$backupAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$backupScriptPath`""
$backupTrigger = New-ScheduledTaskTrigger -Daily -At 12:00AM

$maintenanceAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$maintenanceScriptPath`""
$maintenanceTrigger = New-ScheduledTaskTrigger -Daily -At 1:00AM

$healthAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$maintenanceScriptPath`""
$healthTrigger = New-ScheduledTaskTrigger -Daily -At 3:00AM

foreach ($task in @($backupTaskName, $maintenanceTaskName, $healthTaskName)) {
    if (Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $task -Confirm:$false
    }
}

Register-ScheduledTask -TaskName $backupTaskName -Action $backupAction -Trigger $backupTrigger -Principal $principal -Settings $settings | Out-Null
Register-ScheduledTask -TaskName $maintenanceTaskName -Action $maintenanceAction -Trigger $maintenanceTrigger -Principal $principal -Settings $settings | Out-Null
Register-ScheduledTask -TaskName $healthTaskName -Action $healthAction -Trigger $healthTrigger -Principal $principal -Settings $settings | Out-Null

Write-Host "Windows Server backend configuration complete."
Write-Host "Site root: $SiteRoot"
Write-Host "Backup root: $BackupRoot"
Write-Host "Maintenance window: 00:00 to 04:00"
Write-Host "Scheduled task: $backupTaskName (daily at 00:00)"
Write-Host "Scheduled task: $maintenanceTaskName (daily at 01:00)"
Write-Host "Scheduled task: $healthTaskName (daily at 03:00)"
Write-Host "Maintenance logs: C:\iBridge\logs\maintenance-*.log"
