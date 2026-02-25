# Offline Mitigation Guide for Email Compromise

## Overview

This guide provides step-by-step instructions for mitigating email compromise without requiring immediate access to Microsoft 365 administrative tools. Use these steps when you suspect an account has been compromised but cannot immediately access the admin portal.

## Initial Response Steps

### 1. Password Reset via Alternative Methods

**If you cannot access the admin portal:**
- Have the affected user reset their password at https://account.microsoft.com/security
- Ensure they use a strong, unique password (16+ characters with complexity)
- If this fails, contact Microsoft Support directly at 1-800-642-7676

### 2. Secure Alternative Communication Channels

- Establish secure communication with the affected user via phone or in-person
- Do not use the compromised email account to communicate about the incident
- Create a temporary email address if needed for emergency communications

### 3. Endpoint Security Checks

Have the affected user:
1. Run full antivirus scans on all devices (Windows Defender, Malwarebytes)
2. Check for unauthorized browser extensions or plugins
3. Look for unexpected software installations
4. Disconnect from networks until scans are complete

## Offline Analysis and Evidence Collection

### 1. Email Forwarding Check (User-Level)

Have the user check their own forwarding settings:
1. Open Outlook (desktop application)
2. Go to File > Account Settings > Account Settings
3. Select the email account and click "Change"
4. Check that no forwarding addresses are configured
5. In Outlook Web App: Settings > Mail > Forwarding

### 2. Rule Examination (User-Level)

Have the user check for suspicious rules:
1. In Outlook desktop: Home tab > Rules > Manage Rules & Alerts
2. Look for rules that forward, delete, or move messages
3. Document any suspicious rules before deleting them
4. In Outlook Web App: Settings > Mail > Rules

### 3. Document Evidence

- Take screenshots of any suspicious settings, rules, or emails
- Create a timeline of unusual activities or observations
- Save copies of suspicious emails (forward as attachment to a secure email)
- Document any reports of others receiving suspicious emails from the account

## Account Recovery and Hardening

### 1. Multi-Factor Authentication Setup

Guide the user through setting up MFA:
1. Visit https://account.microsoft.com/security
2. Set up the Microsoft Authenticator app on their phone
3. Configure SMS or phone call backup methods
4. Save and secure recovery codes

### 2. Device Auditing

Have the user:
1. Sign out of all sessions at https://account.microsoft.com/devices
2. Remove any unrecognized devices or applications
3. Revoke access for any third-party apps they don't recognize

### 3. Local Security Hardening

1. Update all operating systems and applications
2. Set up local device encryption where available
3. Configure screen lock timeouts on all devices
4. Install reputable anti-malware software

## Business Continuity Steps

### 1. Communication Plan

1. Create a list of key contacts who may have received suspicious emails
2. Prepare a template notification about the compromise
3. Establish how to notify contacts (alternative email, phone)
4. Draft guidance on what recipients should do if they interacted with suspicious emails

### 2. Monitoring for Misuse

1. Have colleagues report any suspicious emails from the affected account
2. Watch for unusual account behavior even after password reset
3. Monitor financial accounts or systems that may have been targeted
4. Set up alerts for login attempts from new locations

### 3. Documentation for Later Analysis

Document everything for when admin access is restored:
1. Timeline of events
2. Actions taken by user and IT support
3. Evidence collected (screenshots, email headers, etc.)
4. List of potentially impacted contacts or systems

## When Access is Restored

Once administrator access is restored:
1. Run the Email-Compromise-Investigation.ps1 script for complete remediation
2. Review audit logs for the affected account
3. Check for mailbox delegate permissions changes
4. Implement additional security controls based on findings

## Prevention Guidance

### Security Best Practices to Implement

1. Use unique, complex passwords for each account
2. Enable MFA on all accounts
3. Be vigilant for phishing attempts
4. Regularly check account settings and rules
5. Keep all devices and applications updated
6. Use secure, updated browsers with security extensions
7. Verify unusual requests through alternative channels

---

**Emergency Contacts:**
- IT Security: [PHONE NUMBER]
- Microsoft Support: 1-800-642-7676
- Fraud Alert: [PHONE NUMBER]
