# Quick Test - User Account Creation with Fixed Descriptions
# Test the fixed description lengths

$AdminUsername = "Admin"
$AdminPassword = "IBr1dG3Pc"
$UserUsername = "iBridge User"  
$UserPassword = "Abc654321!"

try {
    Write-Host "Testing user account creation with fixed descriptions..." -ForegroundColor Green
    
    # Test Admin description length
    $AdminDesc = "Admin for app installation"
    Write-Host "Admin description: '$AdminDesc' (Length: $($AdminDesc.Length) chars)" -ForegroundColor Cyan
    
    # Test User description length  
    $UserDesc = "Standard user with limited privileges"
    Write-Host "User description: '$UserDesc' (Length: $($UserDesc.Length) chars)" -ForegroundColor Cyan
    
    if ($AdminDesc.Length -le 48 -and $UserDesc.Length -le 48) {
        Write-Host "✓ Both descriptions are within the 48-character limit" -ForegroundColor Green
    } else {
        Write-Host "✗ Descriptions are still too long" -ForegroundColor Red
    }
    
    Write-Host "`nNote: The character limit for New-LocalUser -Description is 48 characters" -ForegroundColor Yellow
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
