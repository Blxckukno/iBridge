# Security Automation Scripts

*PowerShell scripts for automated security configuration and monitoring*

## 🚀 Quick Start

### Prerequisites
- Windows PowerShell 5.1+ or PowerShell Core 7+
- Administrator privileges for system configuration
- Execution policy set to allow script execution

```powershell
# Set execution policy (run as administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

## 📁 Script Categories

### System Hardening Scripts
- `Harden-WindowsSystem.ps1` - Complete Windows hardening
- `Configure-WindowsDefender.ps1` - Advanced Defender configuration
- `Setup-WindowsFirewall.ps1` - Firewall rules and configuration
- `Disable-UnnecessaryServices.ps1` - Service hardening

### Security Monitoring Scripts
- `Monitor-SecurityEvents.ps1` - Real-time security monitoring
- `Scan-SystemSecurity.ps1` - Comprehensive security scan
- `Check-SystemIntegrity.ps1` - File and system integrity
- `Audit-UserAccounts.ps1` - User account security audit

### Network Security Scripts
- `Configure-NetworkSecurity.ps1` - Network hardening
- `Monitor-NetworkConnections.ps1` - Network monitoring
- `Setup-DNSSecurity.ps1` - DNS security configuration
- `Test-NetworkSecurity.ps1` - Network security testing

### Maintenance Scripts
- `Update-SecurityDefinitions.ps1` - Security updates automation
- `Cleanup-SecurityLogs.ps1` - Log management and rotation
- `Backup-SecurityConfig.ps1` - Configuration backup
- `Generate-SecurityReport.ps1` - Security status reporting

## 🛡️ Core Security Scripts

### 1. Complete System Hardening

**File: `automation-scripts/Harden-WindowsSystem.ps1`**

### 2. Windows Defender Configuration

**File: `automation-scripts/Configure-WindowsDefender.ps1`**

### 3. Firewall Setup and Configuration

**File: `automation-scripts/Setup-WindowsFirewall.ps1`**

### 4. Security Monitoring

**File: `automation-scripts/Monitor-SecurityEvents.ps1`**

### 5. System Security Scanner

**File: `automation-scripts/Scan-SystemSecurity.ps1`**

## 📊 Usage Examples

### Daily Security Routine
```powershell
# Run daily security checks
.\Scan-SystemSecurity.ps1 -Detailed
.\Check-SystemIntegrity.ps1
.\Monitor-SecurityEvents.ps1 -Hours 24
```

### Weekly Security Maintenance
```powershell
# Weekly comprehensive security maintenance
.\Update-SecurityDefinitions.ps1
.\Audit-UserAccounts.ps1
.\Generate-SecurityReport.ps1 -OutputPath "C:\SecurityReports\"
.\Backup-SecurityConfig.ps1
```

### Initial System Setup
```powershell
# Complete security setup for new system
.\Harden-WindowsSystem.ps1 -Level High
.\Configure-WindowsDefender.ps1 -MaxProtection
.\Setup-WindowsFirewall.ps1 -Profile Enterprise
.\Configure-NetworkSecurity.ps1
```

## 🔧 Configuration Management

### Security Configuration Files
- `config/security-baseline.json` - Security baseline settings
- `config/firewall-rules.json` - Firewall rule definitions
- `config/monitoring-rules.json` - Monitoring and alerting rules
- `config/compliance-checks.json` - Compliance verification rules

### Template Configurations
- `templates/enterprise-config.json` - Enterprise security template
- `templates/home-user-config.json` - Home user security template
- `templates/developer-config.json` - Developer workstation template
- `templates/server-config.json` - Server security template

## 📈 Reporting and Analytics

### Security Reports
- Daily security status report
- Weekly vulnerability assessment
- Monthly compliance report
- Incident response reports

### Dashboard Integration
- PowerBI dashboard templates
- Grafana dashboard configurations
- Excel report templates
- HTML report generators

## 🔄 Automated Workflows

### Scheduled Tasks Integration
```powershell
# Create scheduled security tasks
$TaskName = "Daily Security Scan"
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Security\automation-scripts\Scan-SystemSecurity.ps1"
$Trigger = New-ScheduledTaskTrigger -Daily -At "2:00 AM"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings
```

### CI/CD Integration
- Azure DevOps pipeline templates
- GitHub Actions workflows
- Jenkins pipeline scripts
- GitLab CI/CD configurations

## 🚨 Incident Response Scripts

### Emergency Response
- `emergency/Isolate-System.ps1` - System isolation
- `emergency/Collect-Evidence.ps1` - Evidence collection
- `emergency/Reset-Passwords.ps1` - Emergency password reset
- `emergency/Block-ThreatIP.ps1` - Threat IP blocking

### Forensics and Investigation
- `forensics/Capture-MemoryDump.ps1` - Memory capture
- `forensics/Analyze-EventLogs.ps1` - Log analysis
- `forensics/Extract-Artifacts.ps1` - Digital artifacts
- `forensics/Generate-Timeline.ps1` - Timeline creation

---

*To see the actual script files, navigate to the automation-scripts folder.*
*Each script includes detailed documentation, parameters, and examples.*