# Copilot Instructions for IT Toolkit (2025-2026)

## Project Overview
This repository is a blueprint for a comprehensive, offline IT Toolkit designed for Windows 10/11+ environments. It provides:
- Freeware, paid, and FOSS enterprise-grade alternatives for all core IT needs
- Ready-to-use PowerShell and Batch scripts for deployment, diagnostics, and automation
- Up-to-date, official download links for all tools (as of October 2024)
- A structure for rapid, secure, and repeatable IT operations

## Directory Structure
- `Freeware/` — Free, offline installers by category (e.g., Cybersecurity, Backup, Utilities)
- `Paid/` — Paid software installers (no license keys stored here)
- `FOSS_Enterprise_Stack/` — Free/open-source alternatives to paid enterprise tools
- `Scripts/` — PowerShell/BAT scripts for deployment, diagnostics, and automation
- `Documentation/` — Version tracking, deployment guides, and encrypted license info
- `ISO/` — Windows/Linux ISOs for system deployment

## Key Patterns & Conventions
- **Offline Installers Only:** All software is stored as full offline installers (no web installers)
- **Version Tracking:** Use `Documentation/Software_Versions.csv` to track and update all software quarterly
- **Security:** Encrypt portable drives (BitLocker recommended); never store plain-text license keys
- **Script Automation:** Scripts use a helper module (`Scripts/Modules/Get-Latest.psm1`) to always select the latest installer in each folder
- **Self-Hosting:** FOSS stack (Wazuh, TacticalRMM, Proxmox, TrueNAS, etc.) requires self-hosted infrastructure
- **No Credentials in Repo:** All sensitive info (e.g., license keys) must be encrypted or stored in a password manager

## Developer Workflows
- **Add/Update Software:** Place new offline installers in the correct category folder; update `Software_Versions.csv`
- **Script Usage:** Run scripts from an elevated PowerShell prompt; see comments in each script for usage
- **Testing:** Always test new scripts and installers in a VM before production use
- **Quarterly Maintenance:** Review and update all software and scripts every 3 months

## Integration Points
- **Paid vs. Free/FOSS:** For every paid tool, a FOSS alternative is provided in `FOSS_Enterprise_Stack/` with matching features
- **Deployment Scripts:** Scripts reference installers by pattern, not hardcoded filename, for easy updates
- **Documentation:** All guides, cheat sheets, and version info are in `Documentation/`

## Example: Post-Install Automation
- `Scripts/Windows_Deployment/Post-Install.ps1` installs all core runtimes and base software using the latest available installers
- `Scripts/Modules/Get-Latest.psm1` provides a `Get-LatestInstaller` function for dynamic selection

## References
- See `Documentation/DEPLOYMENT_GUIDES.txt` for setup and usage instructions
- All download links and version info are in the main README or `Software_Versions.csv`

---

**AI agents:**
- Always prefer official, up-to-date sources for downloads
- Never expose or commit sensitive data
- Follow the folder structure and naming conventions strictly
- When in doubt, reference the latest documentation in `Documentation/`
