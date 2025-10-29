<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Email Management System Instructions

This is a Python project for managing email address verification and user account administration.

## Project Context
- Working with user data containing names, surnames, email addresses, and temporary passwords
- Need to verify existing email addresses in admin centre
- Track verification status and manage user accounts
- Export results for further processing

## Code Style Guidelines
- Use pandas for data manipulation and CSV/Excel operations
- Follow PEP 8 naming conventions
- Use type hints where appropriate
- Include proper error handling for file operations
- Create modular functions for reusability

## Security Considerations
- Handle sensitive data (emails, passwords) securely
- Don't hardcode credentials in source code
- Use environment variables for configuration
- Ensure data privacy and protection
