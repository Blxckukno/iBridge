# Check Global Administrator Role Members
param(
    [string]$LogFile = "C:\Users\Lwandile Gasela\iBridge\Policies\logs\GlobalAdmins-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Write-Host $logMessage
    if ($LogFile) {
        Add-Content -Path $LogFile -Value $logMessage
    }
}

try {
    Write-Log "Checking Global Administrator role members..."
    
    # Connect to Microsoft Graph
    try {
        Connect-MgGraph -NoWelcome -ErrorAction Stop
        Write-Log "Connected to Microsoft Graph" "SUCCESS"
    }
    catch {
        Write-Log "Failed to connect to Microsoft Graph: $($_.Exception.Message)" "ERROR"
        exit 1
    }
    
    # Get Global Administrator role
    $globalAdminRole = Get-MgDirectoryRole | Where-Object {$_.DisplayName -eq 'Global Administrator'}
    
    if (-not $globalAdminRole) {
        Write-Log "Global Administrator role not found" "ERROR"
        exit 1
    }
    
    Write-Log "Found Global Administrator role: $($globalAdminRole.Id)"
    
    # Get role members
    $roleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRole.Id
    
    Write-Log "Found $($roleMembers.Count) Global Administrator(s):"
    Write-Log "=" * 50
    
    foreach ($member in $roleMembers) {
        try {
            $user = Get-MgUser -UserId $member.Id
            Write-Log "✓ $($user.DisplayName) ($($user.UserPrincipalName))" "SUCCESS"
            
            # Check if this is lwandile.gasela@ibridge.co.za
            if ($user.UserPrincipalName -eq "lwandile.gasela@ibridge.co.za") {
                Write-Log "✅ CONFIRMED: lwandile.gasela@ibridge.co.za is a Global Administrator" "SUCCESS"
            }
            
            # Check if this is the former admin
            if ($user.UserPrincipalName -eq "Mgqibelo.Gasela@ibridge.co.za") {
                Write-Log "⚠️  WARNING: Mgqibelo.Gasela@ibridge.co.za still has Global Administrator rights" "WARNING"
            }
        }
        catch {
            Write-Log "Failed to get user details for member ID: $($member.Id)" "ERROR"
        }
    }
    
    Write-Log "=" * 50
    Write-Log "Global Administrator check completed"
    
}
catch {
    Write-Log "Error during Global Administrator check: $($_.Exception.Message)" "ERROR"
    exit 1
}
finally {
    try {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
        Write-Log "Disconnected from Microsoft Graph"
    }
    catch {
        # Ignore disconnect errors
    }
}
