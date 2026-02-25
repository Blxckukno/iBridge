# Microsoft 365 Email Policy Management

This workspace contains PowerShell scripts and documentation for managing email policies in Microsoft 365, specifically for restricting access to shared mailboxes while maintaining viewing permissions.

## Overview

This project helps you implement email policies that:
- Restrict who can respond to emails from shared mailboxes
- Allow select authorized users to respond
- Maintain viewing access for all other users
- Apply to specific distribution groups and shared mailboxes

## Shared Mailboxes to Manage

- **iBridge All**: iBridgeAll@ibridge.co.za
- **Inbound Post-Paid**: inbound_post-paid@ibridge.co.za
- **Inbound Pre-Paid**: Pre-Paid_Inbound@ibridge.co.za

## Authorized Responders

Only the following groups should have response permissions:
- EXCO members
- Communications email address
- HR Email address
- Payroll Email address
- IT email address

## Prerequisites

- Microsoft 365 Global Administrator or Exchange Administrator permissions
- PowerShell 5.1 or later
- Exchange Online PowerShell module
- Azure AD PowerShell module (optional, for advanced user management)

## Quick Start

1. **Install Required Modules**:
   ```powershell
   .\scripts\Install-RequiredModules.ps1
   ```

2. **Connect to Exchange Online**:
   ```powershell
   .\scripts\Connect-ExchangeOnline.ps1
   ```

3. **Configure Email Policies**:
   ```powershell
   .\scripts\Configure-EmailPolicies.ps1
   ```

4. **Verify Configuration**:
   ```powershell
   .\scripts\Verify-Policies.ps1
   ```

## Project Structure

```
├── scripts/                 # PowerShell scripts
├── config/                  # Configuration files
├── docs/                    # Documentation
├── templates/               # Policy templates
└── logs/                    # Log files
```

## Support

For issues or questions, refer to the documentation in the `docs/` folder or Microsoft 365 documentation.
