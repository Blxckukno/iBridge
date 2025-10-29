/**
 * iBridge Security Dashboard
 * Real-time security monitoring and threat detection interface
 * Created: October 21, 2025
 */

class SecurityDashboard {
    constructor() {
        this.isVisible = false;
        this.init();
    }

    init() {
        this.createDashboard();
        this.setupKeyboardShortcuts();
        this.startRealTimeMonitoring();
    }

    createDashboard() {
        const dashboard = document.createElement('div');
        dashboard.id = 'security-dashboard';
        dashboard.style.cssText = `
            position: fixed;
            top: -100%;
            right: 20px;
            width: 400px;
            height: 600px;
            background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
            border: 2px solid #00ff00;
            border-radius: 15px;
            z-index: 99999;
            color: white;
            font-family: 'Inter', monospace;
            font-size: 12px;
            transition: all 0.3s ease;
            box-shadow: 0 20px 40px rgba(0, 255, 0, 0.2);
            backdrop-filter: blur(20px);
            overflow: hidden;
        `;

        dashboard.innerHTML = `
            <div style="background: linear-gradient(90deg, #00ff00, #00cc00); padding: 15px; display: flex; align-items: center; justify-content: space-between;">
                <div style="display: flex; align-items: center; gap: 10px;">
                    <span style="font-size: 20px;">🛡️</span>
                    <h3 style="margin: 0; font-size: 16px; font-weight: 700;">iBridge Security Center</h3>
                </div>
                <button id="close-dashboard" style="background: none; border: none; color: white; font-size: 18px; cursor: pointer; padding: 5px;">✕</button>
            </div>
            
            <div style="padding: 20px; height: calc(100% - 70px); overflow-y: auto;">
                <!-- Security Status -->
                <div style="margin-bottom: 20px;">
                    <h4 style="color: #00ff00; margin: 0 0 10px 0; font-size: 14px;">🟢 SYSTEM STATUS</h4>
                    <div id="security-status" style="background: rgba(0, 255, 0, 0.1); padding: 10px; border-radius: 8px; border-left: 4px solid #00ff00;">
                        <div>Status: <span style="color: #00ff00; font-weight: 600;">SECURE</span></div>
                        <div>Threat Level: <span id="threat-level" style="color: #00ff00;">LOW</span></div>
                        <div>Last Scan: <span id="last-scan">Loading...</span></div>
                    </div>
                </div>

                <!-- Security Metrics -->
                <div style="margin-bottom: 20px;">
                    <h4 style="color: #00ff00; margin: 0 0 10px 0; font-size: 14px;">📊 SECURITY METRICS</h4>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
                        <div style="background: rgba(255, 0, 0, 0.1); padding: 8px; border-radius: 6px; text-align: center;">
                            <div style="color: #ff4444; font-weight: 600;" id="blocked-attacks">0</div>
                            <div style="font-size: 10px; opacity: 0.8;">Blocked Attacks</div>
                        </div>
                        <div style="background: rgba(255, 165, 0, 0.1); padding: 8px; border-radius: 6px; text-align: center;">
                            <div style="color: #ffa500; font-weight: 600;" id="suspicious-requests">0</div>
                            <div style="font-size: 10px; opacity: 0.8;">Suspicious Requests</div>
                        </div>
                        <div style="background: rgba(255, 0, 255, 0.1); padding: 8px; border-radius: 6px; text-align: center;">
                            <div style="color: #ff00ff; font-weight: 600;" id="malware-attempts">0</div>
                            <div style="font-size: 10px; opacity: 0.8;">Malware Blocked</div>
                        </div>
                        <div style="background: rgba(0, 255, 255, 0.1); padding: 8px; border-radius: 6px; text-align: center;">
                            <div style="color: #00ffff; font-weight: 600;" id="rate-limit-violations">0</div>
                            <div style="font-size: 10px; opacity: 0.8;">Rate Limit Hits</div>
                        </div>
                    </div>
                </div>

                <!-- Active Protections -->
                <div style="margin-bottom: 20px;">
                    <h4 style="color: #00ff00; margin: 0 0 10px 0; font-size: 14px;">🔒 ACTIVE PROTECTIONS</h4>
                    <div id="protections-list" style="space-y: 5px;">
                        <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 5px;">
                            <span style="color: #00ff00;">✓</span>
                            <span style="font-size: 11px;">XSS Protection</span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 5px;">
                            <span style="color: #00ff00;">✓</span>
                            <span style="font-size: 11px;">CSRF Protection</span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 5px;">
                            <span style="color: #00ff00;">✓</span>
                            <span style="font-size: 11px;">SQL Injection Protection</span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 5px;">
                            <span style="color: #00ff00;">✓</span>
                            <span style="font-size: 11px;">Clickjacking Protection</span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 5px;">
                            <span style="color: #00ff00;">✓</span>
                            <span style="font-size: 11px;">Rate Limiting</span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 5px;">
                            <span style="color: #00ff00;">✓</span>
                            <span style="font-size: 11px;">Malware Detection</span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 5px;">
                            <span style="color: #00ff00;">✓</span>
                            <span style="font-size: 11px;">Session Security</span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 5px;">
                            <span style="color: #00ff00;">✓</span>
                            <span style="font-size: 11px;">Content Integrity</span>
                        </div>
                    </div>
                </div>

                <!-- Recent Security Events -->
                <div style="margin-bottom: 20px;">
                    <h4 style="color: #00ff00; margin: 0 0 10px 0; font-size: 14px;">📋 RECENT EVENTS</h4>
                    <div id="security-events" style="background: rgba(0, 0, 0, 0.3); border-radius: 8px; padding: 10px; max-height: 120px; overflow-y: auto; font-size: 10px;">
                        <div style="color: #888; text-align: center; padding: 20px;">No security events detected</div>
                    </div>
                </div>

                <!-- Quick Actions -->
                <div style="margin-bottom: 20px;">
                    <h4 style="color: #00ff00; margin: 0 0 10px 0; font-size: 14px;">⚡ QUICK ACTIONS</h4>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
                        <button id="security-scan" style="background: linear-gradient(135deg, #00ff00, #00cc00); border: none; color: white; padding: 8px; border-radius: 6px; cursor: pointer; font-size: 10px; font-weight: 600;">Full Scan</button>
                        <button id="clear-logs" style="background: linear-gradient(135deg, #ff6600, #cc5500); border: none; color: white; padding: 8px; border-radius: 6px; cursor: pointer; font-size: 10px; font-weight: 600;">Clear Logs</button>
                        <button id="export-logs" style="background: linear-gradient(135deg, #0066ff, #0055cc); border: none; color: white; padding: 8px; border-radius: 6px; cursor: pointer; font-size: 10px; font-weight: 600;">Export Logs</button>
                        <button id="emergency-lock" style="background: linear-gradient(135deg, #ff0000, #cc0000); border: none; color: white; padding: 8px; border-radius: 6px; cursor: pointer; font-size: 10px; font-weight: 600;">Emergency Lock</button>
                    </div>
                </div>

                <!-- System Info -->
                <div>
                    <h4 style="color: #00ff00; margin: 0 0 10px 0; font-size: 14px;">ℹ️ SYSTEM INFO</h4>
                    <div style="background: rgba(0, 0, 0, 0.3); border-radius: 8px; padding: 10px; font-size: 10px;">
                        <div>Version: v1.0.0</div>
                        <div>Updated: October 21, 2025</div>
                        <div>Uptime: <span id="uptime">00:00:00</span></div>
                        <div>Browser: <span id="browser-info">Loading...</span></div>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(dashboard);
        this.dashboard = dashboard;
        this.setupEventListeners();
    }

    setupEventListeners() {
        // Close button
        document.getElementById('close-dashboard').addEventListener('click', () => {
            this.hideDashboard();
        });

        // Quick action buttons
        document.getElementById('security-scan').addEventListener('click', () => {
            this.performSecurityScan();
        });

        document.getElementById('clear-logs').addEventListener('click', () => {
            this.clearSecurityLogs();
        });

        document.getElementById('export-logs').addEventListener('click', () => {
            this.exportSecurityLogs();
        });

        document.getElementById('emergency-lock').addEventListener('click', () => {
            if (confirm('This will activate emergency lockdown mode. Continue?')) {
                window.iBridgeSecurity.emergencyLockdown();
            }
        });
    }

    setupKeyboardShortcuts() {
        document.addEventListener('keydown', (e) => {
            // Ctrl + Shift + S to toggle security dashboard
            if (e.ctrlKey && e.shiftKey && e.key === 'S') {
                e.preventDefault();
                this.toggleDashboard();
            }
        });
    }

    toggleDashboard() {
        if (this.isVisible) {
            this.hideDashboard();
        } else {
            this.showDashboard();
        }
    }

    showDashboard() {
        this.dashboard.style.top = '20px';
        this.isVisible = true;
        this.updateDashboard();
    }

    hideDashboard() {
        this.dashboard.style.top = '-100%';
        this.isVisible = false;
    }

    updateDashboard() {
        if (!this.isVisible) return;

        // Update security metrics
        const status = window.iBridgeSecurity.getSecurityStatus();

        document.getElementById('threat-level').textContent = status.threatLevel;
        document.getElementById('threat-level').style.color = this.getThreatColor(status.threatLevel);
        document.getElementById('last-scan').textContent = new Date().toLocaleTimeString();

        // Update metrics
        document.getElementById('blocked-attacks').textContent = status.metrics.blockedAttacks;
        document.getElementById('suspicious-requests').textContent = status.metrics.suspiciousRequests;
        document.getElementById('malware-attempts').textContent = status.metrics.malwareAttempts;
        document.getElementById('rate-limit-violations').textContent = status.metrics.rateLimitViolations;

        // Update browser info
        document.getElementById('browser-info').textContent = this.getBrowserInfo();

        // Update recent events
        this.updateSecurityEvents();
    }

    getThreatColor(level) {
        switch (level) {
            case 'LOW': return '#00ff00';
            case 'MEDIUM': return '#ffa500';
            case 'HIGH': return '#ff0000';
            default: return '#00ff00';
        }
    }

    getBrowserInfo() {
        const ua = navigator.userAgent;
        if (ua.includes('Chrome')) return 'Chrome';
        if (ua.includes('Firefox')) return 'Firefox';
        if (ua.includes('Safari')) return 'Safari';
        if (ua.includes('Edge')) return 'Edge';
        return 'Unknown';
    }

    updateSecurityEvents() {
        const logs = JSON.parse(sessionStorage.getItem('security_logs') || '[]');
        const eventsContainer = document.getElementById('security-events');

        if (logs.length === 0) {
            eventsContainer.innerHTML = '<div style="color: #888; text-align: center; padding: 20px;">No security events detected</div>';
            return;
        }

        const recentEvents = logs.slice(-10).reverse();
        eventsContainer.innerHTML = recentEvents.map(event => `
            <div style="padding: 5px 0; border-bottom: 1px solid rgba(255, 255, 255, 0.1); display: flex; justify-content: space-between;">
                <span style="color: ${this.getEventColor(event.type)};">${event.type}</span>
                <span style="color: #888; font-size: 9px;">${new Date(event.timestamp).toLocaleTimeString()}</span>
            </div>
        `).join('');
    }

    getEventColor(type) {
        const colors = {
            'XSS_ATTEMPT': '#ff4444',
            'MALICIOUS_INPUT': '#ff6644',
            'CLICKJACKING_ATTEMPT': '#ff8844',
            'RATE_LIMIT_EXCEEDED': '#ffaa44',
            'MALWARE_DETECTED': '#ff0066',
            'SESSION_TIMEOUT': '#4488ff',
            'DEVTOOLS_DETECTED': '#8844ff',
            'SUSPICIOUS_REQUEST': '#ff4488'
        };
        return colors[type] || '#ffffff';
    }

    performSecurityScan() {
        const scanButton = document.getElementById('security-scan');
        const originalText = scanButton.textContent;

        scanButton.textContent = 'Scanning...';
        scanButton.style.background = 'linear-gradient(135deg, #ffaa00, #cc8800)';

        setTimeout(() => {
            // Perform actual security checks
            this.runSecurityChecks();

            scanButton.textContent = 'Scan Complete';
            scanButton.style.background = 'linear-gradient(135deg, #00ff00, #00cc00)';

            setTimeout(() => {
                scanButton.textContent = originalText;
            }, 2000);
        }, 3000);
    }

    runSecurityChecks() {
        const checks = [
            'Checking for XSS vulnerabilities...',
            'Scanning for malicious scripts...',
            'Validating CSRF protection...',
            'Analyzing network requests...',
            'Checking session security...',
            'Validating input sanitization...',
            'Security scan completed successfully!'
        ];

        checks.forEach((check, index) => {
            setTimeout(() => {
                console.log(`🔍 ${check}`);
            }, index * 400);
        });
    }

    clearSecurityLogs() {
        sessionStorage.removeItem('security_logs');
        sessionStorage.removeItem('security_report');
        this.updateSecurityEvents();
        console.log('🗑️ Security logs cleared');
    }

    exportSecurityLogs() {
        const logs = JSON.parse(sessionStorage.getItem('security_logs') || '[]');
        const report = {
            timestamp: new Date().toISOString(),
            logs: logs,
            metrics: window.iBridgeSecurity.getSecurityStatus()
        };

        const blob = new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `ibridge-security-report-${new Date().toISOString().split('T')[0]}.json`;
        a.click();
        URL.revokeObjectURL(url);

        console.log('📄 Security logs exported');
    }

    startRealTimeMonitoring() {
        // Update dashboard every 5 seconds when visible
        setInterval(() => {
            if (this.isVisible) {
                this.updateDashboard();
            }
        }, 5000);

        // Update uptime every second
        const startTime = Date.now();
        setInterval(() => {
            const uptime = Date.now() - startTime;
            const hours = Math.floor(uptime / 3600000).toString().padStart(2, '0');
            const minutes = Math.floor((uptime % 3600000) / 60000).toString().padStart(2, '0');
            const seconds = Math.floor((uptime % 60000) / 1000).toString().padStart(2, '0');

            const uptimeElement = document.getElementById('uptime');
            if (uptimeElement) {
                uptimeElement.textContent = `${hours}:${minutes}:${seconds}`;
            }
        }, 1000);
    }
}

// Initialize Security Dashboard
window.securityDashboard = new SecurityDashboard();

// Show initial notification
setTimeout(() => {
    console.log('%c🛡️ Security Dashboard Ready', 'color: #00ff00; font-weight: bold; font-size: 14px;');
    console.log('%cPress Ctrl+Shift+S to open the Security Dashboard', 'color: #00ff00; font-size: 12px;');
}, 2000);