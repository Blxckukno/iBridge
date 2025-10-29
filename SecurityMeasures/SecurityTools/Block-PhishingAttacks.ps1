# Block-PhishingAttacks.ps1
# Purpose: Configure email security settings to block phishing attacks
# Created: September 10, 2025

param (
    [Parameter(Mandat                Write-SecurityLog "Error checking SPF for ${domainName}: $_" -Level Errorry=$false)]
    [switch]$ConfigureSPF,
    
    [Parameter(Mandatory=$false)]
    [switch]$ConfigureDKIM,
    
    [Parameter(Mandatory=$false)]
    [switch]$ConfigureDMARC,
    
    [Parameter(Mandatory=$false)]
    [switch]$BlockDangerousAttachments,
    
    [Parameter(Mandatory=$false)]
    [switch]$BlockExternalForwarding,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnablePhishingProtection,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableSafeLinksProtection,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableSafeAttachmentsProtection,
    
    [Parameter(Mandatory=$false)]
    [switch]$ApplyAll,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckOnly
)

# Initialize environment
$ErrorActionPreference = "Continue"
$script:domainInfo = @{}

# Function for logging
function Write-SecurityLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with color based on level
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor White }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-SecurityLog "Checking prerequisites and required modules..."
    $requiredModules = @(
        "ExchangeOnlineManagement",
        "DnsClient"
    )
    
    $allModulesPresent = $true
    
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-SecurityLog "Required module not found: $module" -Level Error
            Write-SecurityLog "Please install it with: Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser" -Level Warning
            $allModulesPresent = $false
        } else {
            Write-SecurityLog "Module $module is available" -Level Success
        }
    }
    
    if (!$allModulesPresent) {
        Write-SecurityLog "Missing required modules. Please install them and try again." -Level Error
        return $false
    }
    
    # Check connections
    try {
        Write-SecurityLog "Connecting to required services..."
        
        # Connect to Exchange Online
        Connect-ExchangeOnline -ErrorAction Stop | Out-Null
        Write-SecurityLog "Connected to Exchange Online" -Level Success
        
        return $true
    } catch {
        Write-SecurityLog "Failed to connect to required services: $_" -Level Error
        return $false
    }
}

# Function to get all domains in the tenant
function Get-M365Domains {
    Write-SecurityLog "Getting domains for the tenant..."
    
    try {
        $domains = Get-AcceptedDomain
        
        foreach ($domain in $domains) {
            $script:domainInfo[$domain.DomainName] = @{
                Name = $domain.DomainName
                Default = $domain.Default
                AuthenticationType = $domain.DomainType
                SPFRecord = $null
                DKIMEnabled = $null
                DMARCRecord = $null
                DMARCPolicy = $null
            }
            
            Write-SecurityLog "Found domain: $($domain.DomainName)" -Level Info
        }
        
        return $true
    } catch {
        Write-SecurityLog "Error getting accepted domains: $_" -Level Error
        return $false
    }
}

# Function to check SPF records
function Check-SPFRecords {
    Write-SecurityLog "Checking SPF records for domains..."
    
    foreach ($domainName in $script:domainInfo.Keys) {
        Write-SecurityLog "Checking SPF for $domainName..." -Level Info
        
        try {
            $spfRecord = Resolve-DnsName -Name $domainName -Type TXT -ErrorAction SilentlyContinue | 
                         Where-Object { $_.Strings -match "v=spf1" }
            
            if ($spfRecord) {
                $spfText = $spfRecord.Strings -join " "
                $script:domainInfo[$domainName].SPFRecord = $spfText
                
                Write-SecurityLog "SPF record found for ${domainName}: ${spfText}" -Level Success
                
                # Check if SPF includes Office 365
                if ($spfText -notmatch "include:spf.protection.outlook.com") {
                    Write-SecurityLog "SPF record for $domainName does not include Office 365 SPF!" -Level Warning
                }
                
                # Check if SPF ends with appropriate qualifier
                if ($spfText -match " [-?~]all$") {
                    if ($spfText -match " -all$") {
                        Write-SecurityLog "SPF record for $domainName uses strict -all qualifier (recommended)" -Level Success
                    } else {
                        Write-SecurityLog "SPF record for $domainName uses soft fail (~all) or neutral (?all) qualifier - consider using -all" -Level Warning
                    }
                } else {
                    Write-SecurityLog "SPF record for $domainName does not end with an appropriate all qualifier" -Level Warning
                }
            } else {
                Write-SecurityLog "No SPF record found for $domainName" -Level Error
            }
        } catch {
            Write-SecurityLog "Error checking SPF for $domainName: $_" -Level Error
        }
    }
}

# Function to check DKIM configuration
function Check-DKIMConfiguration {
    Write-SecurityLog "Checking DKIM configuration for domains..."
    
    foreach ($domainName in $script:domainInfo.Keys) {
        Write-SecurityLog "Checking DKIM for $domainName..." -Level Info
        
        try {
            # Check if DKIM is enabled in Office 365
            $dkimConfig = Get-DkimSigningConfig -Identity $domainName -ErrorAction SilentlyContinue
            
            if ($dkimConfig) {
                $script:domainInfo[$domainName].DKIMEnabled = $dkimConfig.Enabled
                
                if ($dkimConfig.Enabled) {
                    Write-SecurityLog "DKIM is enabled for $domainName" -Level Success
                } else {
                    Write-SecurityLog "DKIM is not enabled for $domainName" -Level Warning
                }
                
                # Check DKIM selectors
                try {
                    $selector1 = Resolve-DnsName -Name "selector1._domainkey.$domainName" -Type CNAME -ErrorAction SilentlyContinue
                    $selector2 = Resolve-DnsName -Name "selector2._domainkey.$domainName" -Type CNAME -ErrorAction SilentlyContinue
                    
                    if ($selector1 -and $selector2) {
                        Write-SecurityLog "DKIM selectors are properly configured for $domainName" -Level Success
                    } else {
                        Write-SecurityLog "DKIM selectors are not properly configured for $domainName" -Level Warning
                    }
                } catch {
                    Write-SecurityLog "Error checking DKIM selectors for ${domainName}: $_" -Level Warning
                }
            } else {
                Write-SecurityLog "No DKIM configuration found for $domainName" -Level Warning
            }
        } catch {
            Write-SecurityLog "Error checking DKIM for ${domainName}: $_" -Level Error
        }
    }
}

# Function to check DMARC records
function Check-DMARCRecords {
    Write-SecurityLog "Checking DMARC records for domains..."
    
    foreach ($domainName in $script:domainInfo.Keys) {
        Write-SecurityLog "Checking DMARC for $domainName..." -Level Info
        
        try {
            $dmarcRecord = Resolve-DnsName -Name "_dmarc.$domainName" -Type TXT -ErrorAction SilentlyContinue | 
                           Where-Object { $_.Strings -match "v=DMARC1" }
            
            if ($dmarcRecord) {
                $dmarcText = $dmarcRecord.Strings -join " "
                $script:domainInfo[$domainName].DMARCRecord = $dmarcText
                
                # Extract policy
                if ($dmarcText -match "p=([a-z]+)") {
                    $script:domainInfo[$domainName].DMARCPolicy = $matches[1]
                }
                
                Write-SecurityLog "DMARC record found for ${domainName}: ${dmarcText}" -Level Success
                
                # Check policy strength
                if ($script:domainInfo[$domainName].DMARCPolicy -eq "reject") {
                    Write-SecurityLog "DMARC policy for $domainName is set to 'reject' (recommended)" -Level Success
                } elseif ($script:domainInfo[$domainName].DMARCPolicy -eq "quarantine") {
                    Write-SecurityLog "DMARC policy for $domainName is set to 'quarantine' (consider reject)" -Level Warning
                } else {
                    Write-SecurityLog "DMARC policy for $domainName is set to 'none' (not recommended)" -Level Warning
                }
                
                # Check reporting
                if ($dmarcText -notmatch "rua=") {
                    Write-SecurityLog "DMARC record for $domainName does not specify aggregate reports (rua)" -Level Warning
                }
            } else {
                Write-SecurityLog "No DMARC record found for $domainName" -Level Error
            }
        } catch {
            Write-SecurityLog "Error checking DMARC for ${domainName}: $_" -Level Error
        }
    }
}

# Function to configure SPF
function Configure-SPF {
    Write-SecurityLog "Configuring SPF records..."
    
    foreach ($domainName in $script:domainInfo.Keys) {
        if (!$script:domainInfo[$domainName].SPFRecord -or 
            $script:domainInfo[$domainName].SPFRecord -notmatch "include:spf.protection.outlook.com") {
            
            Write-SecurityLog "SPF record for $domainName needs to be configured" -Level Warning
            
            # Build recommended SPF record
            $recommendedSPF = "v=spf1 include:spf.protection.outlook.com -all"
            
            # Check if domain has existing SPF
            if ($script:domainInfo[$domainName].SPFRecord) {
                Write-SecurityLog "Current SPF for ${domainName}: $($script:domainInfo[$domainName].SPFRecord)" -Level Info
            }
            
            Write-SecurityLog "Recommended SPF for ${domainName}: ${recommendedSPF}" -Level Info
            
            if (!$CheckOnly) {
                Write-SecurityLog "Manual configuration required - DNS record update needed" -Level Warning
                Write-SecurityLog "Please add this TXT record to your DNS for ${domainName}:" -Level Warning
                Write-SecurityLog "Type: TXT" -Level Warning
                Write-SecurityLog "Host: @" -Level Warning
                Write-SecurityLog "Value: $recommendedSPF" -Level Warning
                Write-SecurityLog "TTL: 3600 (or default)" -Level Warning
            }
        } else {
            Write-SecurityLog "SPF record for $domainName already includes Office 365" -Level Success
            
            # Check if SPF ends with -all
            if ($script:domainInfo[$domainName].SPFRecord -notmatch " -all$") {
                Write-SecurityLog "Consider updating SPF for $domainName to end with '-all' instead of '~all' or '?all'" -Level Warning
                
                if (!$CheckOnly) {
                    Write-SecurityLog "Manual configuration required - DNS record update needed" -Level Warning
                    Write-SecurityLog "Current SPF: $($script:domainInfo[$domainName].SPFRecord)" -Level Warning
                    $updatedSpf = $script:domainInfo[$domainName].SPFRecord -replace "(?:~|\?)all$", "-all"
                    Write-SecurityLog "Recommended SPF: $updatedSpf" -Level Warning
                }
            }
        }
    }
}

# Function to configure DKIM
function Configure-DKIM {
    Write-SecurityLog "Configuring DKIM..."
    
    foreach ($domainName in $script:domainInfo.Keys) {
        if ($script:domainInfo[$domainName].DKIMEnabled -ne $true) {
            Write-SecurityLog "DKIM is not enabled for $domainName" -Level Warning
            
            if (!$CheckOnly) {
                try {
                    # Enable DKIM
                    New-DkimSigningConfig -DomainName $domainName -Enabled $true -ErrorAction Stop
                    Write-SecurityLog "DKIM has been enabled for $domainName" -Level Success
                    
                    # Get the CNAME records that need to be added
                    $dkimConfig = Get-DkimSigningConfig -Identity $domainName
                    
                    Write-SecurityLog "Please add the following CNAME records to your DNS for ${domainName}:" -Level Warning
                    Write-SecurityLog "Record 1:" -Level Warning
                    Write-SecurityLog "Type: CNAME" -Level Warning
                    Write-SecurityLog "Host: selector1._domainkey" -Level Warning
                    Write-SecurityLog "Value: $($dkimConfig.Selector1CNAME)" -Level Warning
                    Write-SecurityLog "TTL: 3600 (or default)" -Level Warning
                    
                    Write-SecurityLog "Record 2:" -Level Warning
                    Write-SecurityLog "Type: CNAME" -Level Warning
                    Write-SecurityLog "Host: selector2._domainkey" -Level Warning
                    Write-SecurityLog "Value: $($dkimConfig.Selector2CNAME)" -Level Warning
                    Write-SecurityLog "TTL: 3600 (or default)" -Level Warning
                    
                } catch {
                    Write-SecurityLog "Error enabling DKIM for $domainName: $_" -Level Error
                }
            }
        } else {
            Write-SecurityLog "DKIM is already enabled for $domainName" -Level Success
        }
    }
}

# Function to configure DMARC
function Configure-DMARC {
    Write-SecurityLog "Configuring DMARC records..."
    
    foreach ($domainName in $script:domainInfo.Keys) {
        if (!$script:domainInfo[$domainName].DMARCRecord) {
            Write-SecurityLog "No DMARC record found for $domainName" -Level Warning
            
            # Generate a recommended DMARC record
            # Start with monitoring mode (p=none)
            $recommendedDMARC = "v=DMARC1; p=none; sp=none; rua=mailto:dmarc-reports@$domainName; ruf=mailto:dmarc-reports@$domainName; fo=1; adkim=r; aspf=r;"
            
            if (!$CheckOnly) {
                Write-SecurityLog "Manual configuration required - DNS record update needed" -Level Warning
                Write-SecurityLog "Please add this TXT record to your DNS for $domainName:" -Level Warning
                Write-SecurityLog "Type: TXT" -Level Warning
                Write-SecurityLog "Host: _dmarc" -Level Warning
                Write-SecurityLog "Value: $recommendedDMARC" -Level Warning
                Write-SecurityLog "TTL: 3600 (or default)" -Level Warning
                Write-SecurityLog "NOTE: Initially use 'p=none' for monitoring, then gradually increase to 'p=quarantine' and finally 'p=reject'" -Level Warning
            }
        } else {
            Write-SecurityLog "DMARC record exists for $domainName" -Level Success
            
            # Check if policy can be strengthened
            if ($script:domainInfo[$domainName].DMARCPolicy -eq "none") {
                Write-SecurityLog "DMARC policy for $domainName is currently set to 'none' (monitoring mode)" -Level Warning
                Write-SecurityLog "Consider updating to 'p=quarantine' after monitoring, and eventually to 'p=reject'" -Level Warning
                
                if (!$CheckOnly) {
                    # Suggest a stronger policy - but caution about testing first!
                    $currentDMARC = $script:domainInfo[$domainName].DMARCRecord
                    $updatedDMARC = $currentDMARC -replace "p=none", "p=quarantine"
                    
                    Write-SecurityLog "Manual configuration required - DNS record update needed" -Level Warning
                    Write-SecurityLog "Current DMARC: $currentDMARC" -Level Warning
                    Write-SecurityLog "Suggested DMARC: $updatedDMARC" -Level Warning
                    Write-SecurityLog "WARNING: Test thoroughly before implementing p=quarantine or p=reject!" -Level Warning
                }
            } elseif ($script:domainInfo[$domainName].DMARCPolicy -eq "quarantine") {
                Write-SecurityLog "DMARC policy for $domainName is currently set to 'quarantine'" -Level Info
                Write-SecurityLog "Consider updating to 'p=reject' after sufficient testing period" -Level Warning
            }
        }
    }
}

# Function to block dangerous attachment types
function Configure-DangerousAttachments {
    Write-SecurityLog "Configuring dangerous attachment blocking..."
    
    try {
        # Get current malware filter policy
        $malwarePolicy = Get-MalwareFilterPolicy -Identity Default
        
        if ($malwarePolicy) {
            $fileTypes = $malwarePolicy.FileTypes
            
            # Common dangerous file types
            $dangerousTypes = @(
                "ace", "apk", "app", "appx", "bat", "chm", "cmd", "com", "dll", "exe", 
                "hlp", "hta", "inf", "ins", "iso", "jar", "jnlp", "js", "jse", "lib", 
                "lnk", "mde", "msc", "msh", "msh1", "msh2", "mshxml", "msi", "msix", 
                "msp", "mst", "ops", "pif", "ps1", "reg", "scf", "scr", "sct", "shb", 
                "sys", "vb", "vbe", "vbs", "vxd", "wsc", "wsf", "wsh"
            )
            
            # Check if all dangerous types are blocked
            $missingTypes = $dangerousTypes | Where-Object { $fileTypes -notcontains $_ }
            
            if ($missingTypes -and $missingTypes.Count -gt 0) {
                Write-SecurityLog "Some dangerous file types are not blocked: $($missingTypes -join ', ')" -Level Warning
                
                if (!$CheckOnly -and ($BlockDangerousAttachments -or $ApplyAll)) {
                    # Add missing dangerous types
                    $updatedTypes = $fileTypes + $missingTypes
                    
                    try {
                        Set-MalwareFilterPolicy -Identity Default -FileTypes $updatedTypes
                        Write-SecurityLog "Dangerous file types have been added to the block list" -Level Success
                    } catch {
                        Write-SecurityLog "Error updating malware filter policy: $_" -Level Error
                    }
                }
            } else {
                Write-SecurityLog "All common dangerous file types are already blocked" -Level Success
            }
        } else {
            Write-SecurityLog "No malware filter policy found" -Level Warning
        }
    } catch {
        Write-SecurityLog "Error checking malware filter policy: $_" -Level Error
    }
}

# Function to block external forwarding
function Configure-ExternalForwarding {
    Write-SecurityLog "Configuring external forwarding block..."
    
    try {
        # Get current remote domain settings
        $remoteDomains = Get-RemoteDomain
        $defaultRemoteDomain = $remoteDomains | Where-Object { $_.DomainName -eq "*" }
        
        if ($defaultRemoteDomain) {
            $currentSetting = $defaultRemoteDomain.AutoForwardEnabled
            
            if ($currentSetting -eq $true) {
                Write-SecurityLog "External auto-forwarding is currently enabled (security risk)" -Level Warning
                
                if (!$CheckOnly -and ($BlockExternalForwarding -or $ApplyAll)) {
                    try {
                        Set-RemoteDomain -Identity Default -AutoForwardEnabled $false
                        Write-SecurityLog "External auto-forwarding has been disabled" -Level Success
                    } catch {
                        Write-SecurityLog "Error disabling external auto-forwarding: $_" -Level Error
                    }
                }
            } else {
                Write-SecurityLog "External auto-forwarding is already disabled (recommended)" -Level Success
            }
        } else {
            Write-SecurityLog "Default remote domain configuration not found" -Level Warning
        }
        
        # Additional check for per-mailbox forwarding
        try {
            $mailboxes = Get-Mailbox -ResultSize 100 -Filter {ForwardingAddress -ne $null -or ForwardingSmtpAddress -ne $null}
            
            if ($mailboxes -and $mailboxes.Count -gt 0) {
                Write-SecurityLog "Found $($mailboxes.Count) mailboxes with forwarding enabled" -Level Warning
                
                foreach ($mailbox in $mailboxes) {
                    Write-SecurityLog "  * $($mailbox.UserPrincipalName)" -Level Warning
                    
                    if ($mailbox.ForwardingAddress) {
                        Write-SecurityLog "    - Internal forwarding to: $($mailbox.ForwardingAddress)" -Level Info
                    }
                    
                    if ($mailbox.ForwardingSmtpAddress) {
                        Write-SecurityLog "    - External forwarding to: $($mailbox.ForwardingSmtpAddress.Replace('SMTP:', ''))" -Level Warning
                        
                        if (!$CheckOnly -and ($BlockExternalForwarding -or $ApplyAll)) {
                            try {
                                Set-Mailbox -Identity $mailbox.Identity -ForwardingSmtpAddress $null
                                Write-SecurityLog "    - External forwarding disabled for $($mailbox.UserPrincipalName)" -Level Success
                            } catch {
                                Write-SecurityLog "    - Error disabling forwarding: $_" -Level Error
                            }
                        }
                    }
                }
            } else {
                Write-SecurityLog "No mailboxes with forwarding configured found" -Level Success
            }
        } catch {
            Write-SecurityLog "Error checking mailbox forwarding: $_" -Level Error
        }
    } catch {
        Write-SecurityLog "Error checking remote domain settings: $_" -Level Error
    }
}

# Function to configure anti-phishing policies
function Configure-PhishingProtection {
    Write-SecurityLog "Configuring anti-phishing protection..."
    
    try {
        # Get current anti-phishing policy
        $phishPolicies = Get-AntiPhishPolicy
        $defaultPolicy = $phishPolicies | Where-Object { $_.IsDefault -eq $true }
        
        if ($defaultPolicy) {
            # Check current settings
            $impersonationProtection = $defaultPolicy.EnableTargetedUserProtection
            $domainImpersonation = $defaultPolicy.EnableOrganizationDomainsProtection
            $spoof = $defaultPolicy.EnableSpoofIntelligence
            $mailboxIntelligence = $defaultPolicy.EnableMailboxIntelligence
            
            $changes = @()
            
            if (!$impersonationProtection) { $changes += "EnableTargetedUserProtection" }
            if (!$domainImpersonation) { $changes += "EnableOrganizationDomainsProtection" }
            if (!$spoof) { $changes += "EnableSpoofIntelligence" }
            if (!$mailboxIntelligence) { $changes += "EnableMailboxIntelligence" }
            
            if ($changes.Count -gt 0) {
                Write-SecurityLog "Anti-phishing policy has suboptimal settings: $($changes -join ', ') should be enabled" -Level Warning
                
                if (!$CheckOnly -and ($EnablePhishingProtection -or $ApplyAll)) {
                    try {
                        # Enhance the policy
                        Set-AntiPhishPolicy -Identity $defaultPolicy.Identity `
                            -EnableTargetedUserProtection $true `
                            -EnableOrganizationDomainsProtection $true `
                            -EnableSpoofIntelligence $true `
                            -EnableMailboxIntelligence $true
                            
                        Write-SecurityLog "Anti-phishing policy has been enhanced" -Level Success
                    } catch {
                        Write-SecurityLog "Error updating anti-phishing policy: $_" -Level Error
                    }
                }
            } else {
                Write-SecurityLog "Anti-phishing policy already has recommended settings" -Level Success
            }
        } else {
            Write-SecurityLog "Default anti-phishing policy not found" -Level Warning
            
            if (!$CheckOnly -and ($EnablePhishingProtection -or $ApplyAll)) {
                try {
                    # Create a new policy
                    New-AntiPhishPolicy -Name "Enhanced Security Policy" `
                        -AdminDisplayName "Policy with enhanced security settings" `
                        -EnableTargetedUserProtection $true `
                        -EnableOrganizationDomainsProtection $true `
                        -EnableSpoofIntelligence $true `
                        -EnableMailboxIntelligence $true
                        
                    Write-SecurityLog "New anti-phishing policy created with enhanced settings" -Level Success
                } catch {
                    Write-SecurityLog "Error creating anti-phishing policy: $_" -Level Error
                }
            }
        }
    } catch {
        Write-SecurityLog "Error configuring anti-phishing protection: $_" -Level Error
    }
}

# Function to configure Safe Links
function Configure-SafeLinks {
    Write-SecurityLog "Configuring Safe Links protection..."
    
    try {
        # Get current Safe Links policy
        $safeLinksPolicies = Get-SafeLinksPolicy
        $defaultPolicy = $safeLinksPolicies | Where-Object { $_.IsDefault -eq $true }
        
        if ($defaultPolicy) {
            # Check current settings
            $enableSafeLinks = $defaultPolicy.IsEnabled
            $trackClicks = !$defaultPolicy.DoNotTrackUserClicks
            $scanUrls = $defaultPolicy.ScanUrls
            $blockUrls = $defaultPolicy.EnableForInternalSenders
            
            $changes = @()
            
            if (!$enableSafeLinks) { $changes += "IsEnabled" }
            if (!$trackClicks) { $changes += "TrackClicks" }
            if (!$scanUrls) { $changes += "ScanUrls" }
            if (!$blockUrls) { $changes += "EnableForInternalSenders" }
            
            if ($changes.Count -gt 0) {
                Write-SecurityLog "Safe Links policy has suboptimal settings: $($changes -join ', ') should be enabled" -Level Warning
                
                if (!$CheckOnly -and ($EnableSafeLinksProtection -or $ApplyAll)) {
                    try {
                        # Enhance the policy
                        Set-SafeLinksPolicy -Identity $defaultPolicy.Identity `
                            -IsEnabled $true `
                            -DoNotTrackUserClicks $false `
                            -ScanUrls $true `
                            -EnableForInternalSenders $true
                            
                        Write-SecurityLog "Safe Links policy has been enhanced" -Level Success
                    } catch {
                        Write-SecurityLog "Error updating Safe Links policy: $_" -Level Error
                    }
                }
            } else {
                Write-SecurityLog "Safe Links policy already has recommended settings" -Level Success
            }
        } else {
            Write-SecurityLog "Default Safe Links policy not found" -Level Warning
            
            if (!$CheckOnly -and ($EnableSafeLinksProtection -or $ApplyAll)) {
                try {
                    # Create a new policy
                    New-SafeLinksPolicy -Name "Enhanced Security Policy" `
                        -AdminDisplayName "Policy with enhanced security settings" `
                        -IsEnabled $true `
                        -DoNotTrackUserClicks $false `
                        -ScanUrls $true `
                        -EnableForInternalSenders $true
                        
                    Write-SecurityLog "New Safe Links policy created with enhanced settings" -Level Success
                } catch {
                    Write-SecurityLog "Error creating Safe Links policy: $_" -Level Error
                }
            }
        }
    } catch {
        Write-SecurityLog "Error configuring Safe Links protection: $_" -Level Error
    }
}

# Function to configure Safe Attachments
function Configure-SafeAttachments {
    Write-SecurityLog "Configuring Safe Attachments protection..."
    
    try {
        # Get current Safe Attachments policy
        $safeAttachmentsPolicies = Get-SafeAttachmentPolicy
        $defaultPolicy = $safeAttachmentsPolicies | Where-Object { $_.IsDefault -eq $true }
        
        if ($defaultPolicy) {
            # Check current settings
            $enableSafeAttachments = $defaultPolicy.Enable
            $action = $defaultPolicy.Action # Block, Replace, or DynamicDelivery
            
            $changes = @()
            
            if (!$enableSafeAttachments) { $changes += "Enable" }
            if ($action -ne "Block" -and $action -ne "Replace" -and $action -ne "DynamicDelivery") { 
                $changes += "Action ($action should be Block, Replace, or DynamicDelivery)" 
            }
            
            if ($changes.Count -gt 0) {
                Write-SecurityLog "Safe Attachments policy has suboptimal settings: $($changes -join ', ')" -Level Warning
                
                if (!$CheckOnly -and ($EnableSafeAttachmentsProtection -or $ApplyAll)) {
                    try {
                        # Enhance the policy (using Block as the most secure option)
                        Set-SafeAttachmentPolicy -Identity $defaultPolicy.Identity `
                            -Enable $true `
                            -Action Block
                            
                        Write-SecurityLog "Safe Attachments policy has been enhanced" -Level Success
                    } catch {
                        Write-SecurityLog "Error updating Safe Attachments policy: $_" -Level Error
                    }
                }
            } else {
                Write-SecurityLog "Safe Attachments policy already has recommended settings" -Level Success
            }
        } else {
            Write-SecurityLog "Default Safe Attachments policy not found" -Level Warning
            
            if (!$CheckOnly -and ($EnableSafeAttachmentsProtection -or $ApplyAll)) {
                try {
                    # Create a new policy
                    New-SafeAttachmentPolicy -Name "Enhanced Security Policy" `
                        -AdminDisplayName "Policy with enhanced security settings" `
                        -Enable $true `
                        -Action Block
                        
                    Write-SecurityLog "New Safe Attachments policy created with enhanced settings" -Level Success
                } catch {
                    Write-SecurityLog "Error creating Safe Attachments policy: $_" -Level Error
                }
            }
        }
    } catch {
        Write-SecurityLog "Error configuring Safe Attachments protection: $_" -Level Error
    }
}

# Main execution flow
Write-SecurityLog "Microsoft 365 Phishing Protection Tool" -Level Info
Write-SecurityLog "Starting configuration on $(Get-Date)" -Level Info

if (Test-Prerequisites) {
    # Get domains in tenant
    if (Get-M365Domains) {
        # Check current configurations
        Check-SPFRecords
        Check-DKIMConfiguration
        Check-DMARCRecords
        
        # Apply configurations based on parameters
        if ($ConfigureSPF -or $ApplyAll) {
            Configure-SPF
        }
        
        if ($ConfigureDKIM -or $ApplyAll) {
            Configure-DKIM
        }
        
        if ($ConfigureDMARC -or $ApplyAll) {
            Configure-DMARC
        }
        
        if ($BlockDangerousAttachments -or $ApplyAll) {
            Configure-DangerousAttachments
        }
        
        if ($BlockExternalForwarding -or $ApplyAll) {
            Configure-ExternalForwarding
        }
        
        if ($EnablePhishingProtection -or $ApplyAll) {
            Configure-PhishingProtection
        }
        
        if ($EnableSafeLinksProtection -or $ApplyAll) {
            Configure-SafeLinks
        }
        
        if ($EnableSafeAttachmentsProtection -or $ApplyAll) {
            Configure-SafeAttachments
        }
    }
    
    # Disconnect from services
    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        Write-SecurityLog "Disconnected from Exchange Online" -Level Info
    } catch {
        Write-SecurityLog "Error disconnecting from services: $_" -Level Warning
    }
    
    # Summary
    Write-SecurityLog "`n======================================================" -Level Info
    Write-SecurityLog "PHISHING PROTECTION SUMMARY" -Level Info
    Write-SecurityLog "======================================================" -Level Info
    
    foreach ($domainName in $script:domainInfo.Keys) {
        Write-SecurityLog "Domain: $domainName" -Level Info
        Write-SecurityLog "  SPF: $(if ($script:domainInfo[$domainName].SPFRecord) { "Configured" } else { "Missing" })" -Level $(if ($script:domainInfo[$domainName].SPFRecord) { "Success" } else { "Warning" })
        Write-SecurityLog "  DKIM: $(if ($script:domainInfo[$domainName].DKIMEnabled) { "Enabled" } else { "Disabled" })" -Level $(if ($script:domainInfo[$domainName].DKIMEnabled) { "Success" } else { "Warning" })
        Write-SecurityLog "  DMARC: $(if ($script:domainInfo[$domainName].DMARCRecord) { "Configured (Policy: $($script:domainInfo[$domainName].DMARCPolicy))" } else { "Missing" })" -Level $(if ($script:domainInfo[$domainName].DMARCRecord) { "Success" } else { "Warning" })
    }
    
    Write-SecurityLog "`nRecommended next steps:" -Level Info
    
    if ($CheckOnly) {
        Write-SecurityLog "This was a check-only run. Use the following parameters to apply configurations:" -Level Info
        Write-SecurityLog "  -ConfigureSPF: Configure SPF records" -Level Info
        Write-SecurityLog "  -ConfigureDKIM: Configure DKIM signing" -Level Info
        Write-SecurityLog "  -ConfigureDMARC: Configure DMARC records" -Level Info
        Write-SecurityLog "  -BlockDangerousAttachments: Block dangerous file attachments" -Level Info
        Write-SecurityLog "  -BlockExternalForwarding: Block external email forwarding" -Level Info
        Write-SecurityLog "  -EnablePhishingProtection: Configure anti-phishing policies" -Level Info
        Write-SecurityLog "  -EnableSafeLinksProtection: Configure Safe Links" -Level Info
        Write-SecurityLog "  -EnableSafeAttachmentsProtection: Configure Safe Attachments" -Level Info
        Write-SecurityLog "  -ApplyAll: Apply all recommendations" -Level Info
    } else {
        Write-SecurityLog "Some configurations require manual DNS updates. Review the output above for details." -Level Warning
        Write-SecurityLog "After implementing DNS changes, wait 24-48 hours for propagation, then run this script again with -CheckOnly to verify." -Level Info
    }
} else {
    Write-SecurityLog "Prerequisites check failed. Cannot continue." -Level Error
}
