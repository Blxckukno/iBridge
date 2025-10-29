# Logs directory
This directory stores log files and verification reports from the email policy scripts.

## Log Files

- **Verification Reports**: `verification-YYYYMMDD-HHMMSS.json`
- **Monthly Checks**: `monthly-check-YYYY-MM.json`
- **Error Logs**: Captured automatically by PowerShell scripts

## Retention

- Keep verification logs for at least 90 days
- Archive monthly checks for compliance purposes
- Remove error logs older than 30 days unless needed for troubleshooting
