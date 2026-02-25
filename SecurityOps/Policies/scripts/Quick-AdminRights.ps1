# Quick Admin Rights Setup Script
# This script will attempt to grant manager rights to lwandile.gasela@ibridge.co.za

# Connect to Exchange Online
Write-Host "Connecting to Exchange Online..." -ForegroundColor Green
Connect-ExchangeOnline -ShowProgress:$false

# Check current user
Write-Host "`nCurrent User Information:" -ForegroundColor Cyan
try {
    $currentUser = Get-EXOMailbox -Identity "lwandile.gasela@ibridge.co.za"
    Write-Host "User: $($currentUser.DisplayName)" -ForegroundColor White
    Write-Host "Email: $($currentUser.PrimarySmtpAddress)" -ForegroundColor White
} catch {
    Write-Host "Error getting user info: $($_.Exception.Message)" -ForegroundColor Red
}

# Try to add manager to All Employees group
Write-Host "`nAdding manager to All Employees group..." -ForegroundColor Yellow
try {
    $group = Get-DistributionGroup -Identity "All Employees"
    $currentManagers = @($group.ManagedBy)
    
    if ($currentManagers -contains "lwandile.gasela@ibridge.co.za") {
        Write-Host "Already a manager of All Employees" -ForegroundColor Green
    } else {
        $newManagers = $currentManagers + "lwandile.gasela@ibridge.co.za"
        Set-DistributionGroup -Identity "All Employees" -ManagedBy $newManagers
        Write-Host "SUCCESS: Added as manager to All Employees" -ForegroundColor Green
    }
} catch {
    Write-Host "FAILED: Cannot add manager to All Employees - $($_.Exception.Message)" -ForegroundColor Red
}

# Try to add manager to iBridge General Enquiries group
Write-Host "`nAdding manager to iBridge General Enquiries group..." -ForegroundColor Yellow
try {
    $group = Get-DistributionGroup -Identity "iBridge General Enquiries"
    $currentManagers = @($group.ManagedBy)
    
    if ($currentManagers -contains "lwandile.gasela@ibridge.co.za") {
        Write-Host "Already a manager of iBridge General Enquiries" -ForegroundColor Green
    } else {
        $newManagers = $currentManagers + "lwandile.gasela@ibridge.co.za"
        Set-DistributionGroup -Identity "iBridge General Enquiries" -ManagedBy $newManagers
        Write-Host "SUCCESS: Added as manager to iBridge General Enquiries" -ForegroundColor Green
    }
} catch {
    Write-Host "FAILED: Cannot add manager to iBridge General Enquiries - $($_.Exception.Message)" -ForegroundColor Red
}

# Check current status
Write-Host "`nCurrent Group Status:" -ForegroundColor Cyan
try {
    $group1 = Get-DistributionGroup -Identity "All Employees"
    Write-Host "All Employees:" -ForegroundColor Yellow
    Write-Host "  Managed By: $($group1.ManagedBy -join ', ')" -ForegroundColor White
    Write-Host "  Moderation: $($group1.ModerationEnabled)" -ForegroundColor White
    
    $group2 = Get-DistributionGroup -Identity "iBridge General Enquiries"
    Write-Host "iBridge General Enquiries:" -ForegroundColor Yellow
    Write-Host "  Managed By: $($group2.ManagedBy -join ', ')" -ForegroundColor White
    Write-Host "  Moderation: $($group2.ModerationEnabled)" -ForegroundColor White
} catch {
    Write-Host "Cannot retrieve group information: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nScript completed." -ForegroundColor Green
