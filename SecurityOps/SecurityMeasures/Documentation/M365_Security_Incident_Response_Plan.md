# Microsoft 365 Security Incident Response Plan

## Table of Contents
1. [Immediate Response Actions](#immediate-response-actions)
2. [Investigation Procedures](#investigation-procedures)
3. [Containment and Remediation](#containment-and-remediation)
4. [Recovery Steps](#recovery-steps)
5. [Post-Incident Actions](#post-incident-actions)
6. [Prevention Measures](#prevention-measures)
7. [Appendix: PowerShell Scripts and Resources](#appendix-powershell-scripts-and-resources)

## Immediate Response Actions

### Priority 1: Isolate Affected Accounts
- **Reset passwords** for compromised accounts immediately
  - Use the Microsoft 365 Admin Center or PowerShell
  - Choose strong passwords (16+ characters with complexity)
  - Do not reuse passwords from other services
- **Enable MFA** on the affected accounts if not already enabled
  - In Microsoft 365 Admin Center → Security → MFA
  - Require immediate enrollment when the user logs in next
- **Block suspicious sign-ins**
  - Review and block suspicious IP addresses in Azure AD Conditional Access
  - Consider implementing location-based restrictions

### Priority 2: Preserve Evidence
- **Export audit logs** before taking remediation steps
  - Use Compliance Center or Security & Compliance PowerShell
  - Capture sign-in logs, mail flow logs, and admin activities
- **Document suspicious activities**
  - Take screenshots of suspicious rules, forwards, delegations
  - Note timestamps, IP addresses, and patterns of behavior
- **Save copies of suspicious emails**
  - Preserve full headers and attachments
  - Document message IDs and routing information

### Priority 3: Activate Response Team
- **Notify key stakeholders**
  - IT Security team
  - Department managers
  - Legal/compliance teams if sensitive data was involved
- **Document the incident timeline**
  - When was it discovered?
  - What indicators led to the discovery?
  - What actions have been taken so far?
- **Establish communication channels**
  - Create a dedicated Teams channel for incident updates
  - Define who needs to be included in communications
  - Set regular update intervals

## Investigation Procedures

### Step 1: Identify Scope of Compromise
- Run the provided PowerShell scripts to analyze:
  - **Suspicious sent emails**: Look for emails sent without user knowledge
  - **Inbox rules**: Check for forwarding, deletion, or move rules
  - **Mailbox delegates**: Identify unauthorized access grants
  - **Sign-in activities**: Review locations, devices, and times
  - **MFA status**: Verify if MFA was bypassed or not enabled

### Step 2: User Activity Analysis
- **Interview affected users**
  - When did they last access their account normally?
  - Have they noticed any unusual behavior?
  - Did they receive suspicious phishing emails recently?
- **Check device security**
  - Scan user devices for malware
  - Check for unauthorized applications or browser extensions
  - Review browser saved passwords/cookies that may be compromised

### Step 3: Determine Attack Vector
- **Analyze recent phishing campaigns**
  - Look for targeted phishing attempts in the organization
  - Check email headers of suspicious messages
- **Review password practices**
  - Check for password reuse across services
  - Verify if passwords were exposed in known breaches
- **Assess application permissions**
  - Review OAuth app permissions granted by users
  - Check for suspicious third-party app integrations

### Step 4: Assess Data Exposure
- **Identify potentially accessed data**
  - Email content and attachments
  - OneDrive/SharePoint documents
  - Teams conversations and files
- **Review email forwarding history**
  - Check if emails were auto-forwarded to external addresses
  - Examine mail flow logs for unusual patterns
- **Document potential data breach scope**
  - Types of information potentially exposed
  - Time period of potential exposure
  - Number of records or documents involved

## Containment and Remediation

### Step 1: Secure Compromised Accounts
- **Remove unauthorized access**
  - Delete suspicious inbox rules
  - Remove unauthorized delegates
  - Revoke OAuth permissions to suspicious applications
  - Disable email forwarding
- **Implement account restrictions**
  - Apply Conditional Access policies to limit access
  - Consider temporary reduced privileges
  - Implement session time limits

### Step 2: Extend Security to Related Accounts
- **Identify accounts with similar patterns**
  - Check for similar forwarding rules across the organization
  - Look for access from the same suspicious IP addresses
- **Reset credentials for potentially affected accounts**
  - Prioritize accounts with administrative privileges
  - Focus on accounts with access to sensitive data
  - Check accounts with shared passwords or similar usernames

### Step 3: Block Attack Infrastructure
- **Block malicious domains and IPs**
  - Update mail flow rules to block known-bad senders
  - Add phishing domains to block lists
  - Implement connection filtering rules
- **Review and tighten security rules**
  - Update anti-phishing policies
  - Enhance attachment scanning settings
  - Implement more aggressive spam filtering

## Recovery Steps

### Step 1: Restore Normal Operations
- **Re-enable accounts with proper security**
  - Ensure MFA is working properly
  - Verify correct permissions are in place
  - Monitor for any signs of continuing compromise
- **Restore legitimate email flow**
  - Ensure legitimate emails are not being blocked
  - Update any temporary mail flow rules
  - Monitor for delivery issues

### Step 2: Data Recovery (If Needed)
- **Restore deleted emails**
  - Use eDiscovery to recover permanently deleted items
  - Restore from backups if available
  - Check recoverable items folders
- **Recover altered documents**
  - Use versioning in SharePoint/OneDrive
  - Restore previous document versions
  - Check recycle bins for deleted files

### Step 3: User Support
- **Provide clear instructions to affected users**
  - How to verify account security
  - Steps to take if they notice suspicious activity
  - New security practices to follow
- **Establish monitoring period**
  - Extra scrutiny on recently compromised accounts
  - Lower threshold for suspicious activity alerts
  - Regular check-ins with affected users

## Post-Incident Actions

### Step 1: Comprehensive Security Review
- **Conduct a full Microsoft 365 security assessment**
  - Use Microsoft Secure Score
  - Review all security policies
  - Identify and remediate security gaps
- **Review incident response effectiveness**
  - What worked well in the response?
  - What could be improved?
  - Update response procedures based on lessons learned

### Step 2: User Education
- **Conduct security awareness training**
  - Phishing awareness
  - Password security practices
  - How to identify and report suspicious activity
- **Establish clear reporting procedures**
  - Who to contact when suspicious activity is detected
  - What information to provide in reports
  - Expectations for response time

### Step 3: Documentation and Reporting
- **Complete incident documentation**
  - Full timeline of the incident
  - Actions taken during response
  - Evidence collected
- **Prepare appropriate notifications**
  - Internal stakeholders
  - Customers (if applicable)
  - Regulatory bodies (if required by compliance obligations)

## Prevention Measures

### Technical Controls
- **Enable MFA for all users**
  - No exceptions for standard accounts
  - Consider requiring phishing-resistant methods (e.g., FIDO2 keys)
- **Implement Conditional Access Policies**
  - Location-based restrictions
  - Device compliance requirements
  - Risk-based access controls
- **Configure Advanced Threat Protection**
  - Safe Links to scan URLs in emails
  - Safe Attachments to detect malicious files
  - Anti-phishing protection with mailbox intelligence

### Mail Security Enhancements
- **Implement DMARC, DKIM, and SPF**
  - Protect your domain from spoofing
  - Set appropriate DMARC policy (monitor, quarantine, or reject)
  - Configure proper SPF records
- **External email warnings**
  - Add banners to emails from external senders
  - Warn users when replying to external domains
- **Attachment restrictions**
  - Block high-risk attachment types
  - Sandbox suspicious attachments
  - Implement Protected View for Office files

### Account Security Measures
- **Implement Just-In-Time access**
  - Time-limited administrative access
  - Approval workflows for privileged actions
- **Regular access reviews**
  - Audit user permissions quarterly
  - Review service account permissions
  - Validate external sharing settings
- **Password policies**
  - Implement password expiration appropriate to your environment
  - Consider passwordless options where feasible
  - Use banned password lists

### Monitoring and Detection
- **Enable comprehensive auditing**
  - Turn on unified audit logging
  - Retain logs for at least 90 days (ideally longer)
  - Configure alerts for suspicious activities
- **Regular security scans**
  - Scheduled reviews of inbox rules across the organization
  - Regular checks for unauthorized forwarding
  - Periodic reviews of OAuth app permissions
- **Implement automated response**
  - Automated blocking of suspicious sign-ins
  - User risk policies to force password resets
  - Integration with SIEM solutions

## Appendix: PowerShell Scripts and Resources

### Investigation Scripts
- `Investigate-M365EmailCompromise.ps1`: Detailed analysis of potential email compromise
- `Audit-M365UserActivity.ps1`: Comprehensive account activity auditing

### Useful Microsoft Documentation
- [Microsoft 365 Security Roadmap](https://docs.microsoft.com/en-us/microsoft-365/security/microsoft-365-security-for-bdm)
- [Office 365 ATP Setup Guide](https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/office-365-atp)
- [Azure AD Security Best Practices](https://docs.microsoft.com/en-us/azure/security/fundamentals/identity-management-best-practices)

### Additional Resources
- Microsoft Security & Compliance Center: https://protection.office.com
- Microsoft Defender for Office 365: https://security.microsoft.com
- Azure AD Admin Center: https://aad.portal.azure.com

---

**Document Version:** 1.0  
**Last Updated:** September 10, 2025  
**Prepared By:** Security Response Team
