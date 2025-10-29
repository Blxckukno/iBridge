# Network Security Guide
*Comprehensive free alternatives to paid network security solutions*

## 🔥 Firewall Configuration

### 1. Windows Defender Firewall (Built-in)
**Best Alternative to:** ZoneAlarm Pro, Norton Firewall
- **Features:**
  - Inbound/outbound traffic filtering
  - Application-based rules
  - Network profile management
  - Advanced security rules
- **Advanced Configuration:**
  ```powershell
  # Enable firewall for all profiles
  Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
  
  # Block all inbound connections by default
  Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
  
  # Allow outbound connections by default
  Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow
  
  # Enable logging
  Set-NetFirewallProfile -Profile Domain,Public,Private -LogAllowed True -LogBlocked True
  ```

### 2. pfSense (Free Router Firmware)
**Download:** https://www.pfsense.org/download/
- **Type:** Router/firewall OS replacement
- **Features:**
  - Enterprise-grade firewall
  - VPN server capabilities
  - Traffic shaping
  - Intrusion detection
  - Network monitoring

### 3. OPNsense (Free Router Firmware)
**Download:** https://opnsense.org/download/
- **Features:**
  - Modern firewall platform
  - Two-factor authentication
  - Forward caching proxy
  - Traffic shaping
  - Virtual private networking

## 🌐 VPN Solutions

### 4. ProtonVPN (Free Tier)
**Download:** https://protonvpn.com/
- **Features:**
  - No data limits
  - Strong encryption
  - No logs policy
  - Secure Core servers
- **Free Limitations:** 3 countries, 1 device, medium speed

### 5. Windscribe (Free Tier)
**Download:** https://windscribe.com/
- **Features:**
  - 10GB/month free
  - Strong encryption
  - Ad blocking built-in
  - Multiple server locations
- **Configuration:** Install client and configure auto-connect

### 6. OpenVPN (Self-hosted)
**Download:** https://openvpn.net/community-downloads/
- **Type:** Self-hosted VPN server
- **Features:**
  - Complete control over VPN
  - Strong encryption
  - Cross-platform support
  - No monthly limits

### 7. WireGuard (Self-hosted)
**Download:** https://www.wireguard.com/install/
- **Features:**
  - Modern VPN protocol
  - Faster than OpenVPN
  - Simpler configuration
  - Better battery life on mobile

## 🛡️ DNS Security

### 8. Cloudflare DNS (1.1.1.1)
**Setup:** Change DNS to 1.1.1.1 and 1.0.0.1
- **Features:**
  - Malware blocking
  - Fast response times
  - Privacy-focused
  - DNSSEC validation
- **Configuration:**
  ```powershell
  # Set Cloudflare DNS
  Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "1.1.1.1","1.0.0.1"
  ```

### 9. Quad9 DNS (9.9.9.9)
**Setup:** Change DNS to 9.9.9.9 and 149.112.112.112
- **Features:**
  - Threat intelligence blocking
  - DNSSEC validation
  - No logging of personal data
  - Global anycast network

### 10. OpenDNS (Free)
**Website:** https://www.opendns.com/home-internet-security/
- **Features:**
  - Phishing protection
  - Malware blocking
  - Content filtering
  - Network monitoring

### 11. Pi-hole (Self-hosted DNS Sinkhole)
**Download:** https://pi-hole.net/
- **Features:**
  - Network-wide ad blocking
  - DNS request logging
  - Custom blacklists/whitelists
  - Statistics dashboard
- **Setup on Windows with WSL:**
  ```bash
  # Install Pi-hole in WSL
  curl -sSL https://install.pi-hole.net | bash
  ```

## 📡 Network Monitoring

### 12. Wireshark (Free)
**Download:** https://www.wireshark.org/download.html
- **Features:**
  - Deep network packet inspection
  - Protocol analysis
  - Network troubleshooting
  - Security analysis
- **Use Cases:**
  - Monitor suspicious network activity
  - Analyze network performance
  - Detect intrusions

### 13. PRTG Network Monitor (Free for 100 sensors)
**Download:** https://www.paessler.com/prtg/download
- **Features:**
  - Network device monitoring
  - Bandwidth monitoring
  - Uptime monitoring
  - Alert system

### 14. Nagios Core (Free)
**Download:** https://www.nagios.org/downloads/nagios-core/
- **Features:**
  - Infrastructure monitoring
  - Alert notifications
  - Performance graphs
  - Custom plugins

## 🔒 Intrusion Detection

### 15. Suricata (Free IDS/IPS)
**Download:** https://suricata.io/download/
- **Features:**
  - Intrusion detection/prevention
  - Network security monitoring
  - Protocol analysis
  - File extraction

### 16. OSSEC (Free HIDS)
**Download:** https://www.ossec.net/downloads/
- **Features:**
  - Host intrusion detection
  - Log analysis
  - File integrity monitoring
  - Active response

### 17. Snort (Free IDS)
**Download:** https://www.snort.org/downloads
- **Features:**
  - Real-time traffic analysis
  - Protocol analysis
  - Content searching/matching
  - Attack detection

## 🏠 Home Network Security

### Router Security Checklist
1. **Change Default Credentials:**
   - Default admin passwords
   - Default SSID names
   - Default Wi-Fi passwords

2. **Firmware Updates:**
   - Enable automatic updates
   - Check monthly for updates
   - Subscribe to security notifications

3. **Wi-Fi Security:**
   - Use WPA3 (or WPA2 if WPA3 unavailable)
   - Strong passphrase (15+ characters)
   - Disable WPS
   - Hide SSID (optional security through obscurity)

4. **Access Control:**
   - MAC address filtering
   - Guest network setup
   - Time-based access controls
   - Device isolation

### Network Hardening Script
```powershell
# Disable unnecessary network services
Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6
Disable-NetAdapterBinding -Name "*" -ComponentID ms_lltdio
Disable-NetAdapterBinding -Name "*" -ComponentID ms_rspndr

# Configure Windows Firewall advanced rules
New-NetFirewallRule -DisplayName "Block Suspicious Ports" -Direction Inbound -Protocol TCP -LocalPort 135,139,445,1433,1434,3389 -Action Block

# Enable network discovery logging
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
```

## 🌍 Network Segmentation

### VLAN Configuration
1. **IoT Device Isolation:**
   - Separate VLAN for smart devices
   - Limited internet access
   - No access to main network

2. **Work/Personal Separation:**
   - Dedicated work VLAN
   - VPN-only internet access
   - Stricter firewall rules

3. **Guest Network:**
   - Isolated guest access
   - Bandwidth limitations
   - Time-based restrictions

## 📊 Network Security Monitoring

### Daily Monitoring
- Router log review
- Unusual bandwidth usage
- Unknown device detection
- Failed authentication attempts

### Weekly Tasks
- Firmware update checks
- Security rule review
- Performance analysis
- Backup configuration

### Monthly Tasks
- Password rotation
- Access list review
- Security assessment
- Penetration testing

## 🚨 Incident Response

### Suspicious Activity Detection
1. **Immediate Actions:**
   - Isolate affected systems
   - Document evidence
   - Change credentials
   - Contact authorities if needed

2. **Investigation:**
   - Log analysis
   - Network traffic review
   - Malware scanning
   - Vulnerability assessment

3. **Recovery:**
   - System restoration
   - Security patch application
   - Configuration hardening
   - Monitoring enhancement

## 🔧 Advanced Network Tools

### 18. Nmap (Network Scanner)
**Download:** https://nmap.org/download.html
- **Features:**
  - Port scanning
  - Service detection
  - OS fingerprinting
  - Vulnerability scanning

### 19. Angry IP Scanner
**Download:** https://angryip.org/download/
- **Features:**
  - Fast network scanner
  - Cross-platform
  - Customizable
  - Export results

### 20. Advanced IP Scanner (Free)
**Download:** https://www.advanced-ip-scanner.com/
- **Features:**
  - Network device discovery
  - Remote control features
  - MAC address detection
  - Port scanning

---

*Last Updated: September 2025*
*Previous: Malware Protection ← | Next: Privacy Tools →*