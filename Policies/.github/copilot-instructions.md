<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Microsoft 365 Email Policy Management Workspace

This workspace is designed for managing Microsoft 365 Exchange Online email policies, specifically for restricting access to shared mailboxes while maintaining viewing permissions.

## Project Context

- **Purpose**: Implement email policies that restrict who can respond to emails from shared mailboxes
- **Target Mailboxes**: 
  - iBridgeAll@ibridge.co.za
  - inbound_post-paid@ibridge.co.za
  - Pre-Paid_Inbound@ibridge.co.za
- **Authorized Users**: EXCO members, Communications, HR, Payroll, and IT teams
- **Technology Stack**: PowerShell, Exchange Online PowerShell module

## Development Guidelines

When working with this project:

1. **PowerShell Best Practices**:
   - Use approved verbs for function names
   - Include proper error handling with try-catch blocks
   - Implement -WhatIf parameter support for configuration changes
   - Use Write-Host with appropriate colors for user feedback
   - Include parameter validation and mandatory parameters where appropriate

2. **Exchange Online Specifics**:
   - Always check for Exchange Online connection before executing commands
   - Use proper cmdlets: Get-Mailbox, Set-MailboxPermission, Get-TransportRule, etc.
   - Handle permissions carefully: SendAs, FullAccess, ReadPermission
   - Implement transport rules for mail flow control

3. **Security Considerations**:
   - Validate user permissions before making changes
   - Log all configuration changes
   - Implement rollback capabilities
   - Use principle of least privilege

4. **Configuration Management**:
   - Store settings in JSON configuration files
   - Validate configuration before applying changes
   - Support both individual and bulk operations
   - Maintain backward compatibility

5. **Documentation**:
   - Include comprehensive help blocks for all functions
   - Provide clear examples in documentation
   - Explain the business impact of each configuration
   - Include troubleshooting guides

## Code Style

- Use consistent indentation (4 spaces)
- Include comprehensive comments for complex logic
- Use meaningful variable and function names
- Implement proper error messages with actionable guidance
- Follow PowerShell naming conventions

## Testing Approach

- Always include -WhatIf support for destructive operations
- Provide verification scripts to validate configurations
- Include both positive and negative test scenarios
- Document expected outcomes for each test case
