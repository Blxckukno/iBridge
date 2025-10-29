# README.md - Microsoft 365 Security Measures Toolkit

## Overview

This toolkit provides a comprehensive set of scripts and documentation to help investigate, remediate, and prevent security incidents in Microsoft 365 environments, specifically targeting email compromise scenarios.

## Contents

### Scripts

1. **Investigate-M365EmailCompromise.ps1**
   - Analyzes sent emails, inbox rules, mailbox delegations, and sign-in activity
   - Identifies indicators of compromise in Microsoft 365 email accounts
   - Usage: `.\Investigate-M365EmailCompromise.ps1 -UserPrincipalName user@domain.com -DaysToLookBack 14`

2. **Audit-M365UserActivity.ps1**
   - Performs comprehensive user activity auditing across Microsoft 365
   - Examines sign-in patterns, permission changes, and security settings
   - Usage: `.\Audit-M365UserActivity.ps1 -UserPrincipalName user@domain.com -DaysToLookBack 30`
   - Or scan all users: `.\Audit-M365UserActivity.ps1 -AllUsers -DaysToLookBack 30`

3. **Analyze-PhishingEmails.ps1**
   - Detects potential phishing emails that may have led to account compromise
   - Identifies key phishing indicators like spoofed senders, suspicious links, and urgency language
   - Usage: `.\Analyze-PhishingEmails.ps1 -UserPrincipalName user@domain.com -DaysToLookBack 30`
   - Or scan all users: `.\Analyze-PhishingEmails.ps1 -AllUsers -DaysToLookBack 30`

### Documentation

- **M365_Security_Incident_Response_Plan.md**
  - Comprehensive guide for responding to Microsoft 365 security incidents
  - Includes immediate actions, investigation procedures, containment steps, and prevention measures
  - Provides structured approach to handling email compromise incidents

## Prerequisites

All scripts require the following PowerShell modules:
- ExchangeOnlineManagement
- AzureAD
- MSOnline

Install the required modules using:
```powershell
Install-Module -Name ExchangeOnlineManagement -Force
Install-Module -Name AzureAD -Force
Install-Module -Name MSOnline -Force
```

## Permissions Required

To run these scripts, you need an account with the following roles:
- Global Administrator or Security Administrator role
- Exchange Administrator role
- Compliance Administrator role (for some audit log queries)

## Getting Started

1. Clone or download this repository to your secure administrative workstation
2. Install the required PowerShell modules
3. Run the scripts with appropriate parameters based on your investigation needs
4. Review the output logs and CSV reports for analysis

## Immediate Response to Email Compromise

If you suspect an email account has been compromised:

1. Run the investigation script first:
   ```powershell
   .\Investigate-M365EmailCompromise.ps1 -UserPrincipalName compromised@domain.com -DaysToLookBack 14
   ```

2. Reset the user's password immediately if compromise is detected

3. Check for suspicious inbox rules, forwards, and delegates:
   ```powershell
   .\Audit-M365UserActivity.ps1 -UserPrincipalName compromised@domain.com -DaysToLookBack 30
   ```

4. Analyze how the account may have been compromised:
   ```powershell
   .\Analyze-PhishingEmails.ps1 -UserPrincipalName compromised@domain.com -DaysToLookBack 30
   ```

5. Follow the steps in the Security Incident Response Plan document

## Warning

- These scripts are powerful tools and should only be used by authorized security personnel
- Always follow your organization's security policies and procedures
- Ensure you have proper authorization before investigating user accounts
- Document all actions taken during a security investigation

## Author

Security Response Team

## Last Updated

September 10, 2025
