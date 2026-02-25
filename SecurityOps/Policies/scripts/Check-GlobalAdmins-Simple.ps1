Write-Host "Checking Global Administrator role members..." -ForegroundColor Green

try {
    # Connect to Microsoft Graph
    Connect-MgGraph -NoWelcome
    Write-Host "Connected to Microsoft Graph" -ForegroundColor Green
    
    # Get Global Administrator role
    $globalAdminRole = Get-MgDirectoryRole | Where-Object {$_.DisplayName -eq 'Global Administrator'}
    
    if ($globalAdminRole) {
        Write-Host "Found Global Administrator role: $($globalAdminRole.Id)" -ForegroundColor Yellow
        
        # Get role members
        $roleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRole.Id
        
        Write-Host "Found $($roleMembers.Count) Global Administrator(s):" -ForegroundColor Yellow
        Write-Host "=" * 50 -ForegroundColor Blue
        
        foreach ($member in $roleMembers) {
            try {
                $user = Get-MgUser -UserId $member.Id
                Write-Host "✓ $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor Green
                
                # Check if this is lwandile.gasela@ibridge.co.za
                if ($user.UserPrincipalName -eq "lwandile.gasela@ibridge.co.za") {
                    Write-Host "✅ CONFIRMED: lwandile.gasela@ibridge.co.za is a Global Administrator" -ForegroundColor Green
                }
                
                # Check if this is the former admin
                if ($user.UserPrincipalName -eq "Mgqibelo.Gasela@ibridge.co.za") {
                    Write-Host "⚠️  WARNING: Mgqibelo.Gasela@ibridge.co.za still has Global Administrator rights" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "Failed to get user details for member ID: $($member.Id)" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "Global Administrator role not found" -ForegroundColor Red
    }
    
    Write-Host "=" * 50 -ForegroundColor Blue
    Write-Host "Global Administrator check completed" -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    try {
        Disconnect-MgGraph
        Write-Host "Disconnected from Microsoft Graph" -ForegroundColor Green
    }
    catch {
        # Ignore disconnect errors
    }
}
