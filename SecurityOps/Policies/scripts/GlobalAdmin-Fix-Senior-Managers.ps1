# Global Administrator Command to Fix Senior Managers Group
# Run this in Exchange Online PowerShell as a Global Administrator

# Connect to Exchange Online (if not already connected)
Connect-ExchangeOnline

# Fix the Senior Managers group
Set-DistributionGroup -Identity 'Senior Managers20220516104448' -ManagedBy 'lwandile.gasela@ibridge.co.za'

# Verify the change
Get-DistributionGroup -Identity 'Senior Managers20220516104448' | Select DisplayName,ManagedBy

# Show success message
Write-Host "✅ Senior Managers group has been fixed!" -ForegroundColor Green
Write-Host "lwandile.gasela@ibridge.co.za is now the sole manager" -ForegroundColor Green
