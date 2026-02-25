# Quick Audit Summary Script
# Shows key findings from the M365 audit

param(
    [switch]$ShowUnauthorized = $false,
    [int]$MaxUnauthorized = 50
)

Write-Host "=== M365 EMAIL POLICY AUDIT SUMMARY ===" -ForegroundColor Cyan
Write-Host "$(Get-Date)" -ForegroundColor Gray

# Check if audit files exist
$jsonFile = ".\logs\M365-Audit-Report.json"
$csvFile = ".\logs\M365-Audit-Report-Summary.csv"

if (!(Test-Path $jsonFile)) {
    Write-Host "❌ Audit report not found. Run Audit-All-Recipients.ps1 first." -ForegroundColor Red
    exit 1
}

try {
    # Load the detailed audit results
    $auditResults = Get-Content $jsonFile | ConvertFrom-Json
    
    Write-Host "`n--- SUMMARY METRICS ---" -ForegroundColor Green
    Write-Host "📊 Total Recipients: $($auditResults.Summary.TotalRecipients)" -ForegroundColor White
    Write-Host "📧 Total Email Addresses: $($auditResults.Summary.TotalEmailAddresses)" -ForegroundColor White
    Write-Host "👤 User Mailboxes: $($auditResults.Summary.UserMailboxes)" -ForegroundColor White
    Write-Host "👥 Distribution Groups: $($auditResults.Summary.DistributionGroups)" -ForegroundColor White
    
    Write-Host "`n--- AUTHORIZATION STATUS ---" -ForegroundColor Yellow
    Write-Host "✅ Authorized Users Found: $($auditResults.Summary.AuthorizedUsersFound)/$($auditResults.Summary.AuthorizedUsersConfigured)" -ForegroundColor Green
    Write-Host "❌ Unauthorized Email Addresses: $($auditResults.Summary.UnauthorizedEmailAddresses)" -ForegroundColor Red
    
    # Calculate percentage
    $unauthorizedPercent = [math]::Round(($auditResults.Summary.UnauthorizedEmailAddresses / $auditResults.Summary.TotalEmailAddresses) * 100, 1)
    Write-Host "📊 Unauthorized Percentage: $unauthorizedPercent%" -ForegroundColor Red
    
    Write-Host "`n--- AUTHORIZED USERS ---" -ForegroundColor Green
    foreach ($user in $auditResults.AuthorizedFound) {
        Write-Host "   ✅ $user" -ForegroundColor Green
    }
    
    if ($ShowUnauthorized) {
        Write-Host "`n--- UNAUTHORIZED USERS (First $MaxUnauthorized) ---" -ForegroundColor Red
        $counter = 0
        foreach ($user in $auditResults.UnauthorizedRecipients) {
            $counter++
            Write-Host "   $counter. $user" -ForegroundColor Red
            if ($counter -ge $MaxUnauthorized) {
                $remaining = $auditResults.UnauthorizedRecipients.Count - $counter
                if ($remaining -gt 0) {
                    Write-Host "   ... and $remaining more" -ForegroundColor Gray
                }
                break
            }
        }
    }
    
    Write-Host "`n--- COMPLIANCE STATUS ---" -ForegroundColor Magenta
    if ($auditResults.Summary.AuthorizedUsersFound -eq $auditResults.Summary.AuthorizedUsersConfigured) {
        Write-Host "✅ All authorized users found in tenant" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some authorized users not found in tenant" -ForegroundColor Yellow
    }
    
    if ($unauthorizedPercent -gt 90) {
        Write-Host "❌ HIGH RISK: $unauthorizedPercent% of recipients are unauthorized" -ForegroundColor Red
        Write-Host "   🚨 IMMEDIATE ACTION REQUIRED: Apply email policies" -ForegroundColor Red
    } elseif ($unauthorizedPercent -gt 50) {
        Write-Host "⚠️  MEDIUM RISK: $unauthorizedPercent% of recipients are unauthorized" -ForegroundColor Yellow
        Write-Host "   ⚡ Action recommended: Review and apply policies" -ForegroundColor Yellow
    } else {
        Write-Host "✅ LOW RISK: $unauthorizedPercent% of recipients are unauthorized" -ForegroundColor Green
    }
    
    Write-Host "`n--- NEXT STEPS ---" -ForegroundColor Cyan
    Write-Host "1. Review the detailed report: $jsonFile" -ForegroundColor White
    Write-Host "2. Apply email policies: .\scripts\Apply-EmailPolicies.ps1" -ForegroundColor White
    Write-Host "3. Verify policies: .\scripts\Verify-Policies.ps1" -ForegroundColor White
    Write-Host "4. Monitor for violations regularly" -ForegroundColor White
    
    Write-Host "`n💡 TIP: Run with -ShowUnauthorized to see unauthorized recipients" -ForegroundColor Yellow
    Write-Host "💡 TIP: Use -MaxUnauthorized to control how many are shown" -ForegroundColor Yellow
    
}
catch {
    Write-Host "❌ Error reading audit results: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== AUDIT SUMMARY COMPLETE ===" -ForegroundColor Cyan
