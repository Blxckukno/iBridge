# Windows Server 2019 Backend + Backup Setup

## Scripts created
- `AutomationScripts/deploy-ws2019-backend.ps1`
- `AutomationScripts/configure-ws2019-backend.ps1`
- `AutomationScripts/autounattend.xml`

## 1) Provision VM on Hyper-V host
Run on host as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File AutomationScripts\deploy-ws2019-backend.ps1 `
  -VmName "iBridge-WS2019-Backend" `
  -VmPath "D:\HyperV\iBridge-WS2019-Backend" `
  -IsoPath "D:\ISO\Windows_Server_2019.iso" `
  -SwitchName "Default Switch"
```

Then:
1. Start VM and complete Windows Server 2019 installation.
2. Log into the server VM.

### Unattended install option
1. Copy `AutomationScripts/autounattend.xml` to a USB/root media as `autounattend.xml`.
2. Attach the media to the VM before first boot from ISO.
3. Ensure you edit at least these fields before use:
   - `AdministratorPassword`
   - `ComputerName`
   - `TimeZone` (if needed)
4. If using first-logon automation, place `configure-ws2019-backend.ps1` at:
   - `C:\iBridge\scripts\configure-ws2019-backend.ps1`

## 2) Configure backend inside Windows Server 2019
Copy repository/scripts into VM, then run:

```powershell
powershell -ExecutionPolicy Bypass -File AutomationScripts\configure-ws2019-backend.ps1 `
  -SiteName "iBridgeSite" `
  -SiteRoot "C:\iBridge\site" `
  -BackupRoot "D:\iBridgeBackups" `
  -RetentionDays 14
```

This configures:
- IIS + management features
- Website and app pool
- Backup script (`C:\iBridge\scripts\backup-site.ps1`)
- Maintenance script (`C:\iBridge\scripts\maintenance-checks.ps1`)
- Maintenance window: `00:00 - 04:00`
- Scheduled task: `iBridge Site Backup` (daily 00:00)
- Scheduled task: `iBridge Maintenance Check` (daily 01:00)
- Scheduled task: `iBridge Health Check` (daily 03:00)
- Backup retention cleanup

## 3) Deploy website files
Publish your site files into:
- `C:\iBridge\site`

## 4) Verify backup
Run once manually:

```powershell
powershell -ExecutionPolicy Bypass -File C:\iBridge\scripts\backup-site.ps1
```

Then confirm zip backups in:
- `D:\iBridgeBackups`

Maintenance/health logs are written to:
- `C:\iBridge\logs\maintenance-*.log`

## Notes
- Use a dedicated backup volume (not the OS disk).
- For production, also add off-server backup replication (Azure Backup/Blob or another secure target).
- If you later move to Azure VM/App Service, this structure can be migrated to CI/CD deployment.
