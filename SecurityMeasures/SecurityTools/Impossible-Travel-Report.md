# Security Incident Report: Impossible Travel Alert

## Incident Details

**Subject:** Impossible Travel Security Alert Investigation

**Date of Report:** September 10, 2025

**Affected User:** Reubendren Padayachee

**Incident ID:** IMP-TRAVEL-2025-09

**Severity:** High

## Executive Summary

An "impossible travel" security alert was triggered for Reubendren Padayachee's account, indicating login attempts from geographically distant locations within an unrealistic timeframe. This report details the investigation findings, impact assessment, and recommended mitigation steps to address this security incident.

## Alert Details

**Alert Time/Date:** September 9, 2025, 14:23 SAST

**Alert Type:** Impossible Travel - Microsoft 365 Cloud App Security

**Locations Detected:** 
- Johannesburg, South Africa (Primary location)
- Beijing, China (Suspicious location)

**Time Between Logins:** Approximately 30 minutes

**Physical Distance:** ~11,700 km (impossible to travel physically in the timeframe)

## Investigation Findings

### Account Activity Analysis

- **Primary Location Activity:**
  - Normal email usage patterns observed from Johannesburg
  - Consistent IP address matching corporate network
  - Normal working hours access (08:00 - 17:00 SAST)

- **Suspicious Location Activity:**
  - Mailbox access and mail forwarding rule creation
  - Data extraction attempts (multiple mailbox items accessed)
  - Suspicious API calls to SharePoint and OneDrive services
  - Suspicious rule created to delete certain incoming emails

### Evidence Collection

- Audit logs confirm mailbox rule creation from suspicious IP
- Authentication logs show successful login with valid credentials
- No evidence of MFA challenge from suspicious location
- Mail server logs show bulk email processing from suspicious location

### Root Cause Analysis

The investigation indicates a likely credential compromise. The attacker appears to have obtained the user's password through:

1. Potential phishing attack (suspicious email identified in user's deleted items)
2. Absence of Multi-Factor Authentication allowing single-factor login
3. Possibly the same password used across multiple services (to be confirmed)

## Impact Assessment

### Confirmed Impact

- Creation of mail forwarding rules to external address: `data-backup-services@mail163.cn`
- Evidence of mailbox data access (emails, contacts)
- Creation of email deletion rules targeting security alert messages

### Potential Impact

- Possible access to sensitive documents in OneDrive
- Risk of lateral movement to other accounts
- Potential data exfiltration
- Reputational damage if account used for further attacks

## Immediate Actions Taken

1. **Account Secured:**
   - Password reset forced
   - Suspicious forwarding rules removed
   - MFA enforced
   - All active sessions terminated

2. **Evidence Preserved:**
   - Audit logs exported and secured
   - Suspicious mail rules documented before removal
   - Login attempts from all locations catalogued

3. **Monitoring Enhanced:**
   - Account placed under increased monitoring
   - Alert thresholds lowered for this user
   - IP address from suspicious location blocked

## Recommended Further Actions

### Short-term (24-48 hours)

1. **Extended Investigation:**
   - Analyze all recent email content for sensitive data exposure
   - Review SharePoint and OneDrive access logs for file exfiltration
   - Check for unauthorized mailbox delegates

2. **User Support:**
   - Brief affected user on incident and risks
   - Provide guidance on identifying potential phishing attempts
   - Secure all user devices with up-to-date antivirus scans

3. **Enhanced Security:**
   - Implement Conditional Access policies restricting login locations
   - Block access from high-risk countries not required for business
   - Review and revoke unnecessary application permissions

### Medium-term (1-2 weeks)

1. **Security Improvements:**
   - Deploy phishing-resistant MFA for all users
   - Implement more restrictive location-based access policies
   - Review email forwarding policies and restrictions

2. **Training and Awareness:**
   - Conduct targeted phishing awareness training
   - Distribute guidance on recognizing security alerts
   - Refresh security best practices with all employees

### Long-term (1-3 months)

1. **Policy Enhancements:**
   - Update Acceptable Use Policy with clear guidance on forwarding rules
   - Develop comprehensive response playbook for account compromise
   - Implement regular security posture assessments

2. **Technical Controls:**
   - Evaluate advanced email protection solutions
   - Consider implementing privilege access management
   - Deploy additional monitoring for sensitive accounts

## Lessons Learned

1. MFA is essential for all accounts, especially those with sensitive access
2. Geolocation-based restrictions should be implemented where possible
3. Regular user security awareness training remains critical
4. Email forwarding rules require regular auditing
5. Faster response procedures could limit potential data exposure

## Appendices

### Appendix A: Timeline of Events

- September 9, 14:05 SAST: Normal login from Johannesburg IP address
- September 9, 14:23 SAST: Login from Beijing IP address
- September 9, 14:25 SAST: Mail forwarding rule created
- September 9, 14:28 SAST: Mail deletion rule created
- September 9, 14:35 SAST: Cloud App Security Alert generated
- September 9, 15:02 SAST: Security team initiates investigation
- September 9, 15:15 SAST: Account secured, password reset

### Appendix B: Indicators of Compromise

- Suspicious IP: 220.181.xx.xx (Beijing, China)
- Suspicious email: data-backup-services@mail163.cn
- Suspicious rule name: "Clean Inbox Management"

---

**Report prepared by:** Security Response Team

**Contact for further information:** security-response@example.com
