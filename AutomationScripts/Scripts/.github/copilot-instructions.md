# Windows User Account Management Script

This workspace contains PowerShell scripts for creating and managing Windows local user accounts with specific configurations:

## Project Overview
- **Admin Account**: Administrator with full privileges for application installation
- **iBridge User Account**: Standard user with limited privileges
- **Application Management**: Scripts for installing applications and managing shortcuts

## Script Features
- Create local Windows accounts with specified passwords
- Set appropriate user privileges (Administrator vs Standard User)
- Install applications from Admin account
- Create shortcuts accessible to both accounts
- Manage shared application folder on C:\ drive

## Security Notes
- Scripts require Administrator privileges to run
- Passwords are stored in scripts for automation (consider security implications)
- Follow principle of least privilege for user accounts

## Usage
Scripts should be run with Administrator privileges on Windows systems.
