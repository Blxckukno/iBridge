# Check current connection and permissions
Write-Host "Checking current Exchange Online connection..."
try {
    $connectionInfo = Get-ConnectionInformation
    Write-Host "Current connection details:"
    $connectionInfo | Format-List

    Write-Host "`nChecking current user permissions..."
    $currentUser = Get-User -Identity $env:USERNAME
    Write-Host "Current user: $($currentUser.UserPrincipalName)"
    
    Write-Host "`nChecking role assignments..."
    $roles = Get-ManagementRoleAssignment -RoleAssignee $currentUser.UserPrincipalName
    Write-Host "Assigned roles:"
    $roles | Select-Object Role, RoleAssigneeType, RoleAssigneeName | Format-Table -AutoSize
    
} catch {
    Write-Host "Error checking permissions: $_" -ForegroundColor Red
    Write-Host "`nTrying to reconnect with additional scopes..."
    
    # Try to connect with additional scopes
    Disconnect-ExchangeOnline -Confirm:$false
    Connect-ExchangeOnline -ShowBanner:$false -ExchangeEnvironmentName O365Default `
        -CommandName "Get-MessageTrace", "Get-TransportRule", "Get-MailContact", "Get-InboundConnector"
}

Write-Host "`nChecking available commands..."
$exchangeCommands = Get-Command -Module ExchangeOnlineManagement
Write-Host "Available Exchange Online commands:"
$exchangeCommands | Select-Object Name | Format-Table -AutoSize
