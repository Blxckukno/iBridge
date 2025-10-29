# Microsoft 365 Email Policy Implementation Guide

## Overview
This guide provides step-by-step instructions for implementing email policies that restrict access to shared mailboxes while maintaining viewing permissions for all users.

## Prerequisites

### Required Permissions
- **Global Administrator** or **Exchange Administrator** role in Microsoft 365
- Access to Exchange Online PowerShell

### Required Software
- PowerShell 5.1 or later
- Exchange Online PowerShell module
- Internet connection

## Implementation Steps

### Step 1: Prepare Your Environment

1. **Open PowerShell as Administrator**
   ```powershell
   # Right-click PowerShell and select "Run as Administrator"
   ```

2. **Install Required Modules**
   ```powershell
   .\scripts\Install-RequiredModules.ps1
   ```

### Step 2: Configure Email Addresses

1. **Edit the Configuration File**
   - Open `config\email-config.json`
   - Update the `AuthorizedUsers` array with actual email addresses:
   ```json
   "AuthorizedUsers": [
     "john.doe@ibridge.co.za",        // EXCO member
     "communications@ibridge.co.za",   // Communications team
     "hr@ibridge.co.za",              // HR department
     "payroll@ibridge.co.za",         // Payroll department
     "it@ibridge.co.za"               // IT department
   ]
   ```

2. **Verify Mailbox Addresses**
   - Confirm that all shared mailboxes exist:
     - `iBridgeAll@ibridge.co.za`
     - `inbound_post-paid@ibridge.co.za`
     - `Pre-Paid_Inbound@ibridge.co.za`

### Step 3: Connect to Exchange Online

```powershell
.\scripts\Connect-ExchangeOnline.ps1
```

**If prompted:**
- Enter your Global Administrator credentials
- Complete MFA if required
- Accept any security prompts

### Step 4: Test Configuration (Recommended)

Before applying changes, run a test to see what would be changed:

```powershell
.\scripts\Configure-EmailPolicies.ps1 -WhatIf
```

This will show you what changes would be made without actually applying them.

### Step 5: Apply Email Policies

```powershell
.\scripts\Configure-EmailPolicies.ps1
```

This script will:
- Remove existing Send As permissions from unauthorized users
- Add Send As permissions for authorized users only
- Create mail flow rules to prevent unauthorized sending
- Configure distribution group moderation (if applicable)

### Step 6: Verify Configuration

```powershell
.\scripts\Verify-Policies.ps1 -Detailed
```

## What These Policies Do

### Shared Mailbox Restrictions
- **Send As Permissions**: Only authorized users can send emails as the shared mailbox
- **Mail Flow Rules**: Prevent unauthorized users from sending emails from shared addresses
- **Access Permissions**: Maintain read access for all users while restricting send access

### Distribution Group Moderation
- **Moderated Groups**: All messages require approval from authorized moderators
- **Silent Moderation**: Rejected senders don't receive notification emails
- **Authorized Moderators**: Only specified users can approve messages

## Testing Your Configuration

### Test 1: Authorized User Sending
1. Log in as an authorized user (e.g., hr@ibridge.co.za)
2. Try to send an email from a shared mailbox
3. **Expected Result**: Email should send successfully

### Test 2: Unauthorized User Sending
1. Log in as a regular user (not in authorized list)
2. Try to send an email from a shared mailbox
3. **Expected Result**: Email should be rejected with an error message

### Test 3: Viewing Access
1. Log in as any user
2. Open a shared mailbox
3. **Expected Result**: Should be able to read emails but not send

## Troubleshooting

### Common Issues

#### "Access Denied" Errors
- **Cause**: Insufficient permissions
- **Solution**: Ensure you have Global Administrator or Exchange Administrator role

#### "Module Not Found" Errors
- **Cause**: PowerShell modules not installed
- **Solution**: Run `Install-RequiredModules.ps1` as Administrator

#### "Mailbox Not Found" Errors
- **Cause**: Shared mailbox doesn't exist or incorrect address
- **Solution**: Verify mailbox addresses in Exchange Admin Center

#### Connection Timeouts
- **Cause**: Network issues or firewall blocking
- **Solution**: Check internet connection and corporate firewall settings

### Advanced Troubleshooting

#### Enable Detailed Logging
```powershell
# Run verification with detailed output
.\scripts\Verify-Policies.ps1 -Detailed -OutputFile "logs\verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
```

#### Check Current Permissions
```powershell
# Check current Send As permissions
Get-RecipientPermission -Identity "iBridgeAll@ibridge.co.za"

# Check current mailbox permissions
Get-MailboxPermission -Identity "iBridgeAll@ibridge.co.za"
```

#### View Transport Rules
```powershell
# List all transport rules
Get-TransportRule | Where-Object {$_.Name -like "*Restrict*"}
```

## Maintenance

### Regular Tasks

#### Monthly Verification
```powershell
# Run monthly verification
.\scripts\Verify-Policies.ps1 -OutputFile "logs\monthly-check-$(Get-Date -Format 'yyyy-MM').json"
```

#### Adding New Authorized Users
1. Edit `config\email-config.json`
2. Add new email address to `AuthorizedUsers` array
3. Re-run configuration:
   ```powershell
   .\scripts\Configure-EmailPolicies.ps1
   ```

#### Removing Authorized Users
1. Edit `config\email-config.json`
2. Remove email address from `AuthorizedUsers` array
3. Re-run configuration:
   ```powershell
   .\scripts\Configure-EmailPolicies.ps1
   ```

### Backup and Recovery

#### Export Current Configuration
```powershell
# Export current transport rules
Get-TransportRule | Export-Csv -Path "backup\transport-rules-$(Get-Date -Format 'yyyyMMdd').csv"

# Export current mailbox permissions
foreach ($mailbox in @("iBridgeAll@ibridge.co.za", "inbound_post-paid@ibridge.co.za", "Pre-Paid_Inbound@ibridge.co.za")) {
    Get-MailboxPermission -Identity $mailbox | Export-Csv -Path "backup\permissions-$($mailbox.Split('@')[0])-$(Get-Date -Format 'yyyyMMdd').csv"
}
```

## Security Considerations

### Best Practices
- **Regular Audits**: Run verification scripts monthly
- **Principle of Least Privilege**: Only grant necessary permissions
- **Documentation**: Keep authorized user lists updated
- **Monitoring**: Monitor mail flow for unauthorized attempts

### Compliance
- **Audit Logging**: All changes are logged in Exchange Online
- **Data Retention**: Configure appropriate retention policies
- **Access Reviews**: Regularly review authorized user lists

## Support and Escalation

### Internal Support
- **IT Department**: it@ibridge.co.za
- **Primary Administrator**: [To be filled in]

### Microsoft Support
- **Exchange Online Documentation**: https://docs.microsoft.com/exchange/
- **PowerShell Documentation**: https://docs.microsoft.com/powershell/exchange/

### Emergency Procedures
If email policies need to be quickly disabled:

```powershell
# Disable all restriction transport rules
Get-TransportRule | Where-Object {$_.Name -like "*Restrict*"} | Disable-TransportRule -Confirm:$false
```

**Note**: Only use this in emergencies and re-enable restrictions as soon as possible.
