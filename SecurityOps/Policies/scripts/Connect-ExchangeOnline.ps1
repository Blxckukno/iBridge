# Connect to Exchange Online
# This script handles the connection to Exchange Online with modern authentication

param(
    [Parameter(Mandatory=$false)]
    [string]$UserPrincipalName = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$UseDeviceAuthentication = $false
)

Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan

# Check if Exchange Online module is available
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Error "Exchange Online PowerShell module is not installed. Please run Install-RequiredModules.ps1 first."
    exit 1
}

# Import the module
try {
    Import-Module ExchangeOnlineManagement -Force
    Write-Host "✓ Exchange Online module imported" -ForegroundColor Green
}
catch {
    Write-Error "Failed to import Exchange Online module: $($_.Exception.Message)"
    exit 1
}

# Connect to Exchange Online
try {
    if ($UseDeviceAuthentication) {
        # Use device authentication for environments without interactive login
        Connect-ExchangeOnline -Device
    } elseif ($UserPrincipalName) {
        # Connect with specific user account
        Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName
    } else {
        # Use modern authentication with interactive login
        Connect-ExchangeOnline
    }
    
    Write-Host "✓ Successfully connected to Exchange Online" -ForegroundColor Green
    
    # Verify connection by getting organization info
    $orgConfig = Get-OrganizationConfig
    Write-Host "Connected to organization: $($orgConfig.DisplayName)" -ForegroundColor Cyan
    Write-Host "Exchange Version: $($orgConfig.AdminDisplayVersion)" -ForegroundColor Gray
    
}
catch {
    Write-Error "Failed to connect to Exchange Online: $($_.Exception.Message)"
    Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Ensure you have Global Administrator or Exchange Administrator permissions" -ForegroundColor Yellow
    Write-Host "2. Check your internet connection" -ForegroundColor Yellow
    Write-Host "3. Try using device authentication: -UseDeviceAuthentication" -ForegroundColor Yellow
    Write-Host "4. Verify MFA is properly configured if required" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nConnection successful! You can now run other scripts in this workspace." -ForegroundColor Green
