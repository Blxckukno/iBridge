# Network Deployment Guide for iBridge Setup

## Methods to Deploy to Other Network Devices

### Method 1: Shared Network Folder (Recommended)
1. **Create a shared folder on your device:**
   - Share the `C:\Users\Lwandile Gasela\iBridge\Scripts` folder
   - Set permissions for network users
   - Other devices can access via `\\YourComputerName\Scripts`

2. **Run from network share:**
   - On target device: `\\YourComputerName\Scripts\UNIVERSAL-USB-SETUP.bat`
   - Must run as Administrator on target device

### Method 2: Copy to Network Drives
- Copy scripts to mapped network drives (Z:, Y:, etc.)
- Run locally on each target device

### Method 3: Remote PowerShell (Advanced)
- Use PowerShell remoting to execute scripts on remote devices
- Requires WinRM enabled on target devices

### Method 4: Group Policy Deployment (Domain Networks)
- Deploy scripts via Group Policy if on domain network
- Automated deployment to multiple devices

### Method 5: USB Drive Method (Physical)
- Copy UNIVERSAL-USB-SETUP.bat to USB drive
- Physically connect to each target device
- Run setup script locally

## Requirements for Target Devices:
- Windows 10/11
- Administrator access
- Network connectivity (for remote methods)
- PowerShell 5.1 or higher

## Security Considerations:
- Scripts contain passwords in plain text
- Ensure secure network connections
- Consider encrypted file sharing
- Verify target device trust levels
