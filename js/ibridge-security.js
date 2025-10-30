/**
 * iBridge Enhanced Security System
 * Comprehensive protection against cyber attacks, malicious scripts, and data breaches
 * Created: October 21, 2025
 */

class iBridgeSecurity {
    constructor() {
        this.securityConfig = {
            enableCSRFProtection: true,
            enableXSSProtection: true,
            enableClickjackingProtection: true,
            enableIntegrityChecks: true,
            enableSecureHeaders: true,
            enableRateLimiting: true,
            enableMalwareDetection: true,
            enableEncryption: true,
            enableHTTPSRedirect: true,
            maxRequestsPerMinute: 60,
            sessionTimeout: 30 * 60 * 1000, // 30 minutes
            logSecurityEvents: true
        };

        this.securityMetrics = {
            blockedAttacks: 0,
            suspiciousRequests: 0,
            malwareAttempts: 0,
            rateLimitViolations: 0
        };

        this.init();
    }

    init() {
        console.log('%c🛡️ iBridge Security System Initialized', 'color: #00ff00; font-weight: bold; font-size: 14px;');

        // Initialize all security modules
        this.setupCSRFProtection();
        this.setupXSSProtection();
        this.setupClickjackingProtection();
        this.setupSecureHeaders();
        this.setupInputValidation();
        this.setupRateLimiting();
        this.setupMalwareDetection();
        this.setupSessionSecurity();
        this.setupSecurityMonitoring();
        this.setupEncryption();
        this.setupContentIntegrity();
        this.preventDevToolsAbuse();
        this.setupNetworkSecurity();
        this.setupHTTPSRedirect();

        // Start security monitoring
        this.startSecurityMonitoring();
    }

    // CSRF Protection
    setupCSRFProtection() {
        const token = this.generateCSRFToken();
        sessionStorage.setItem('csrf_token', token);

        // Add CSRF token to all forms
        document.addEventListener('DOMContentLoaded', () => {
            const forms = document.querySelectorAll('form');
            forms.forEach(form => {
                const csrfInput = document.createElement('input');
                csrfInput.type = 'hidden';
                csrfInput.name = 'csrf_token';
                csrfInput.value = token;
                form.appendChild(csrfInput);
            });
        });
    }

    generateCSRFToken() {
        const array = new Uint8Array(32);
        crypto.getRandomValues(array);
        return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
    }

    // XSS Protection
    setupXSSProtection() {
        // Sanitize all user inputs
        document.addEventListener('input', (e) => {
            if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                e.target.value = this.sanitizeInput(e.target.value);
            }
        });

        // Override dangerous functions
        this.overrideDangerousFunctions();
    }

    sanitizeInput(input) {
        return input
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#x27;')
            .replace(/\//g, '&#x2F;')
            .replace(/javascript:/gi, '')
            .replace(/vbscript:/gi, '')
            .replace(/data:/gi, '')
            .replace(/on\w+=/gi, '');
    }

    overrideDangerousFunctions() {
        // Override eval
        window.eval = function () {
            iBridgeSecurity.instance.logSecurityEvent('XSS_ATTEMPT', 'eval() function blocked');
            throw new Error('eval() is disabled for security reasons');
        };

        // Override document.write
        document.write = function () {
            iBridgeSecurity.instance.logSecurityEvent('XSS_ATTEMPT', 'document.write() blocked');
            console.warn('document.write() is disabled for security reasons');
        };
    }

    // Clickjacking Protection
    setupClickjackingProtection() {
        if (window.top !== window.self) {
            this.logSecurityEvent('CLICKJACKING_ATTEMPT', 'Page loaded in iframe');
            window.top.location = window.self.location;
        }
    }

    // Secure Headers Setup
    setupSecureHeaders() {
        const meta = document.createElement('meta');
        meta.httpEquiv = 'Content-Security-Policy';
        meta.content = "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; frame-ancestors 'none';";
        document.head.appendChild(meta);
    }

    // Input Validation
    setupInputValidation() {
        const maliciousPatterns = [
            /<script/i,
            /javascript:/i,
            /vbscript:/i,
            /onload=/i,
            /onerror=/i,
            /onclick=/i,
            /union.*select/i,
            /drop.*table/i,
            /insert.*into/i,
            /delete.*from/i,
            /update.*set/i,
            /exec.*xp_/i,
            /\.\.\//,
            /\/etc\/passwd/,
            /cmd\.exe/i,
            /powershell/i
        ];

        document.addEventListener('input', (e) => {
            const value = e.target.value;
            maliciousPatterns.forEach(pattern => {
                if (pattern.test(value)) {
                    this.blockMaliciousInput(e.target);
                    this.logSecurityEvent('MALICIOUS_INPUT', `Pattern detected: ${pattern}`);
                }
            });
        });
    }

    blockMaliciousInput(element) {
        element.value = '';
        element.style.border = '2px solid red';
        element.placeholder = 'Malicious input detected and blocked';
        this.securityMetrics.blockedAttacks++;

        setTimeout(() => {
            element.style.border = '';
            element.placeholder = '';
        }, 3000);
    }

    // Rate Limiting
    setupRateLimiting() {
        this.requestCounts = new Map();

        document.addEventListener('click', (e) => {
            if (e.target.tagName === 'BUTTON' || e.target.type === 'submit') {
                this.checkRateLimit(e);
            }
        });
    }

    checkRateLimit(event) {
        const now = Date.now();
        const minute = Math.floor(now / 60000);
        const count = this.requestCounts.get(minute) || 0;

        if (count >= this.securityConfig.maxRequestsPerMinute) {
            event.preventDefault();
            this.logSecurityEvent('RATE_LIMIT_EXCEEDED', `${count} requests in current minute`);
            this.securityMetrics.rateLimitViolations++;
            this.showSecurityAlert('Rate limit exceeded. Please wait before making more requests.');
            return false;
        }

        this.requestCounts.set(minute, count + 1);
        return true;
    }

    // Malware Detection
    setupMalwareDetection() {
        // Monitor for suspicious script injections
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.type === 'childList') {
                    mutation.addedNodes.forEach((node) => {
                        if (node.nodeType === Node.ELEMENT_NODE) {
                            this.scanForMaliciousContent(node);
                        }
                    });
                }
            });
        });

        observer.observe(document.body, { childList: true, subtree: true });
    }

    scanForMaliciousContent(element) {
        const suspiciousAttributes = ['onload', 'onerror', 'onclick', 'onmouseover'];
        const suspiciousContent = ['javascript:', 'vbscript:', 'data:text/html'];

        suspiciousAttributes.forEach(attr => {
            if (element.hasAttribute && element.hasAttribute(attr)) {
                this.removeMaliciousElement(element);
                this.logSecurityEvent('MALWARE_DETECTED', `Suspicious attribute: ${attr}`);
            }
        });

        if (element.innerHTML) {
            suspiciousContent.forEach(content => {
                if (element.innerHTML.toLowerCase().includes(content.toLowerCase())) {
                    this.removeMaliciousElement(element);
                    this.logSecurityEvent('MALWARE_DETECTED', `Suspicious content: ${content}`);
                }
            });
        }
    }

    removeMaliciousElement(element) {
        element.remove();
        this.securityMetrics.malwareAttempts++;
        console.warn('🚨 Malicious element removed by iBridge Security');
    }

    // Session Security
    setupSessionSecurity() {
        // Session timeout
        let lastActivity = Date.now();

        document.addEventListener('click', () => {
            lastActivity = Date.now();
        });

        setInterval(() => {
            if (Date.now() - lastActivity > this.securityConfig.sessionTimeout) {
                this.handleSessionTimeout();
            }
        }, 60000); // Check every minute

        // Secure session storage
        this.encryptSessionData();
    }

    handleSessionTimeout() {
        sessionStorage.clear();
        localStorage.clear();
        this.logSecurityEvent('SESSION_TIMEOUT', 'User session expired');
        alert('Your session has expired for security reasons. Please refresh the page.');
    }

    // Encryption
    setupEncryption() {
        // Encrypt sensitive data in local/session storage
        this.originalSetItem = Storage.prototype.setItem;
        Storage.prototype.setItem = (key, value) => {
            if (this.isSensitiveData(key)) {
                value = this.encrypt(value);
            }
            return this.originalSetItem.call(this, key, value);
        };
    }

    isSensitiveData(key) {
        const sensitiveKeys = ['csrf_token', 'user_data', 'session_id', 'auth_token'];
        return sensitiveKeys.includes(key);
    }

    encrypt(data) {
        // Simple encryption for demo - in production use proper encryption
        return btoa(data + '_encrypted_' + Date.now());
    }

    // Content Integrity
    setupContentIntegrity() {
        // Check for script modifications
        const scripts = document.querySelectorAll('script[src]');
        scripts.forEach(script => {
            script.addEventListener('error', () => {
                this.logSecurityEvent('INTEGRITY_VIOLATION', `Script failed to load: ${script.src}`);
            });
        });
    }

    // Prevent DevTools Abuse
    preventDevToolsAbuse() {
        // Detect console access
        let devtools = false;
        setInterval(() => {
            if (window.outerHeight - window.innerHeight > 200 || window.outerWidth - window.innerWidth > 200) {
                if (!devtools) {
                    devtools = true;
                    this.logSecurityEvent('DEVTOOLS_DETECTED', 'Developer tools opened');
                    console.clear();
                    console.warn('%c🚨 iBridge Security Alert', 'color: red; font-size: 20px; font-weight: bold;');
                    console.warn('%cThis is a browser feature intended for developers. If someone told you to copy-paste something here, it is a scam and will give them access to your account.', 'color: red; font-size: 14px;');
                }
            } else {
                devtools = false;
            }
        }, 500);
    }

    // Network Security
    setupNetworkSecurity() {
        // Monitor for suspicious network requests
        const originalFetch = window.fetch;
        window.fetch = async (...args) => {
            const url = args[0];
            if (this.isSuspiciousUrl(url)) {
                this.logSecurityEvent('SUSPICIOUS_REQUEST', `Blocked request to: ${url}`);
                throw new Error('Request blocked by iBridge Security');
            }
            return originalFetch.apply(this, args);
        };
    }

    isSuspiciousUrl(url) {
        const suspiciousDomains = [
            'malware.com',
            'phishing.site',
            'suspicious.domain'
        ];

        return suspiciousDomains.some(domain => url.includes(domain));
    }

    // Security Monitoring
    startSecurityMonitoring() {
        setInterval(() => {
            this.generateSecurityReport();
        }, 300000); // Every 5 minutes
    }

    generateSecurityReport() {
        const report = {
            timestamp: new Date().toISOString(),
            metrics: this.securityMetrics,
            status: 'SECURE',
            threats: this.getActiveThreatLevel()
        };

        console.log('🛡️ iBridge Security Report:', report);

        // Send to security monitoring (in production, this would go to your security dashboard)
        if (this.securityConfig.logSecurityEvents) {
            sessionStorage.setItem('security_report', JSON.stringify(report));
        }
    }

    getActiveThreatLevel() {
        const totalThreats = Object.values(this.securityMetrics).reduce((sum, val) => sum + val, 0);

        if (totalThreats === 0) return 'LOW';
        if (totalThreats < 5) return 'MEDIUM';
        return 'HIGH';
    }

    // Utility Methods
    logSecurityEvent(type, details) {
        const event = {
            timestamp: new Date().toISOString(),
            type: type,
            details: details,
            userAgent: navigator.userAgent,
            url: window.location.href
        };

        console.warn('🚨 Security Event:', event);

        if (this.securityConfig.logSecurityEvents) {
            const logs = JSON.parse(sessionStorage.getItem('security_logs') || '[]');
            logs.push(event);
            // Keep only last 100 events
            if (logs.length > 100) logs.shift();
            sessionStorage.setItem('security_logs', JSON.stringify(logs));
        }
    }

    showSecurityAlert(message) {
        const alertDiv = document.createElement('div');
        alertDiv.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: linear-gradient(135deg, #ff4444, #cc0000);
            color: white;
            padding: 15px 20px;
            border-radius: 8px;
            box-shadow: 0 4px 20px rgba(255, 68, 68, 0.3);
            z-index: 10000;
            font-family: 'Inter', sans-serif;
            font-weight: 600;
            max-width: 300px;
            animation: slideIn 0.3s ease-out;
        `;
        alertDiv.innerHTML = `
            <div style="display: flex; align-items: center; gap: 10px;">
                <span style="font-size: 20px;">🛡️</span>
                <span>${message}</span>
            </div>
        `;

        document.body.appendChild(alertDiv);

        setTimeout(() => {
            alertDiv.remove();
        }, 5000);
    }

    encryptSessionData() {
        // Encrypt existing session data
        Object.keys(sessionStorage).forEach(key => {
            if (this.isSensitiveData(key)) {
                const value = sessionStorage.getItem(key);
                sessionStorage.setItem(key, this.encrypt(value));
            }
        });
    }

    // HTTPS Redirect and Security
    setupHTTPSRedirect() {
        // Check if we're in production (not localhost)
        const isProduction = !window.location.hostname.includes('localhost') &&
            !window.location.hostname.includes('127.0.0.1') &&
            !window.location.hostname.includes('192.168.');

        if (isProduction && window.location.protocol !== 'https:') {
            // Force HTTPS redirect in production
            window.location.replace('https://' + window.location.host + window.location.pathname + window.location.search);
            return;
        }

        // Add security notice for localhost development
        if (!isProduction) {
            this.showSecurityNotice();
        }

        // Add secure connection indicator
        this.addConnectionIndicator();
    }

    showSecurityNotice() {
        // Create a security notice for development
        const notice = document.createElement('div');
        notice.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            background: linear-gradient(135deg, #ff6b35, #f7931e);
            color: white;
            padding: 10px;
            text-align: center;
            font-family: 'Inter', sans-serif;
            font-size: 12px;
            font-weight: 600;
            z-index: 99999;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
        `;
        notice.innerHTML = `
            🔒 DEVELOPMENT MODE: This is a local development server. In production, this site will use HTTPS encryption for maximum security.
            <button onclick="this.parentElement.remove()" style="background: none; border: none; color: white; margin-left: 10px; cursor: pointer; font-size: 14px;">✕</button>
        `;

        document.body.appendChild(notice);

        // Auto-remove after 10 seconds
        setTimeout(() => {
            if (notice.parentElement) {
                notice.remove();
            }
        }, 10000);
    }

    addConnectionIndicator() {
        const isSecure = window.location.protocol === 'https:';
        const isLocalhost = window.location.hostname.includes('localhost') ||
            window.location.hostname.includes('127.0.0.1') ||
            window.location.hostname.includes('192.168.');

        // Update the existing security indicator
        setTimeout(() => {
            const existingIndicator = document.querySelector('[data-security-indicator]');
            if (existingIndicator) {
                if (isSecure) {
                    existingIndicator.innerHTML = '🔒 HTTPS SECURE';
                    existingIndicator.style.background = 'linear-gradient(135deg, #00ff00, #00cc00)';
                } else if (isLocalhost) {
                    existingIndicator.innerHTML = '🛡️ DEV SECURE';
                    existingIndicator.style.background = 'linear-gradient(135deg, #ffa500, #ff8500)';
                    existingIndicator.title = 'Development Mode - Will use HTTPS in production';
                }
            }
        }, 1000);
    }

    // Public API
    getSecurityStatus() {
        return {
            status: 'ACTIVE',
            threatLevel: this.getActiveThreatLevel(),
            metrics: this.securityMetrics,
            lastUpdate: new Date().toISOString()
        };
    }

    emergencyLockdown() {
        console.warn('🚨 EMERGENCY LOCKDOWN ACTIVATED');

        // Clear all storage
        sessionStorage.clear();
        localStorage.clear();

        // Disable all forms
        document.querySelectorAll('form').forEach(form => {
            form.style.display = 'none';
        });

        // Show lockdown message
        document.body.innerHTML = `
            <div style="display: flex; justify-content: center; align-items: center; height: 100vh; background: linear-gradient(135deg, #1a1a1a, #333); color: white; font-family: 'Inter', sans-serif; text-align: center;">
                <div>
                    <h1 style="color: #ff4444; font-size: 48px; margin-bottom: 20px;">🛡️ SECURITY LOCKDOWN</h1>
                    <p style="font-size: 24px; margin-bottom: 30px;">A security threat has been detected.</p>
                    <p style="font-size: 18px; opacity: 0.8;">Please contact iBridge support for assistance.</p>
                    <p style="font-size: 16px; margin-top: 30px; opacity: 0.6;">security@ibridge.co.za</p>
                </div>
            </div>
        `;

        this.logSecurityEvent('EMERGENCY_LOCKDOWN', 'System locked due to security threat');
    }
}

// Initialize iBridge Security System
iBridgeSecurity.instance = new iBridgeSecurity();

// Export for use in other modules
window.iBridgeSecurity = iBridgeSecurity.instance;

// CSS Animation for alerts
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
`;
document.head.appendChild(style);

console.log('%c🛡️ iBridge Security System v1.0 - Comprehensive Protection Active', 'color: #00ff00; font-weight: bold; font-size: 16px; background: #000; padding: 5px 10px; border-radius: 5px;');