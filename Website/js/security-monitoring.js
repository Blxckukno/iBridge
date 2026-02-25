// Security Monitoring JavaScript
// iBridge Contact Solutions - Security monitoring and protection

class SecurityMonitor {
    constructor() {
        this.securityLevel = 'high';
        this.threats = [];
        this.init();
    }

    init() {
        this.setupCSPMonitoring();
        this.setupXSSProtection();
        this.setupClickjackingProtection();
        this.setupFormValidation();
        this.startSecurityScanning();
    }

    setupCSPMonitoring() {
        // Monitor CSP violations
        document.addEventListener('securitypolicyviolation', (e) => {
            this.logSecurityEvent('CSP Violation', {
                blockedURI: e.blockedURI,
                violatedDirective: e.violatedDirective,
                originalPolicy: e.originalPolicy
            });
        });
    }

    setupXSSProtection() {
        // Enhanced XSS protection
        const originalInnerHTML = Element.prototype.innerHTML;
        Element.prototype.innerHTML = function (value) {
            if (typeof value === 'string' && this.sanitizeHTML) {
                value = this.sanitizeHTML(value);
            }
            return originalInnerHTML.call(this, value);
        };
    }

    setupClickjackingProtection() {
        // Prevent clickjacking
        if (window.top !== window.self) {
            this.logSecurityEvent('Clickjacking Attempt', {
                referrer: document.referrer,
                userAgent: navigator.userAgent
            });

            // Optionally break out of frame
            // window.top.location = window.self.location;
        }
    }

    setupFormValidation() {
        // Enhanced form security
        document.addEventListener('submit', (e) => {
            const form = e.target;
            if (form.tagName === 'FORM') {
                this.validateForm(form, e);
            }
        });
    }

    validateForm(form, event) {
        const inputs = form.querySelectorAll('input, textarea');
        let isValid = true;

        inputs.forEach(input => {
            if (this.containsSuspiciousContent(input.value)) {
                this.logSecurityEvent('Suspicious Form Input', {
                    field: input.name || input.type,
                    value: input.value.substring(0, 100) // Log only first 100 chars
                });
                isValid = false;
            }
        });

        if (!isValid) {
            event.preventDefault();
            this.showSecurityWarning('Suspicious content detected in form submission.');
        }
    }

    containsSuspiciousContent(value) {
        const suspiciousPatterns = [
            /<script[\s\S]*?>[\s\S]*?<\/script>/gi,
            /javascript:/gi,
            /on\w+\s*=/gi,
            /eval\s*\(/gi,
            /expression\s*\(/gi
        ];

        return suspiciousPatterns.some(pattern => pattern.test(value));
    }

    startSecurityScanning() {
        // Periodic security scanning
        setInterval(() => {
            this.scanForThreats();
        }, 30000); // Every 30 seconds
    }

    scanForThreats() {
        // Check for suspicious scripts
        const scripts = document.querySelectorAll('script');
        scripts.forEach(script => {
            if (script.src && !this.isWhitelistedSource(script.src)) {
                this.logSecurityEvent('Unauthorized Script', {
                    src: script.src,
                    content: script.textContent.substring(0, 200)
                });
            }
        });

        // Check for suspicious iframes
        const iframes = document.querySelectorAll('iframe');
        iframes.forEach(iframe => {
            if (!this.isWhitelistedSource(iframe.src)) {
                this.logSecurityEvent('Unauthorized Iframe', {
                    src: iframe.src
                });
            }
        });
    }

    isWhitelistedSource(src) {
        const whitelist = [
            'https://cdnjs.cloudflare.com',
            'https://fonts.googleapis.com',
            'https://fonts.gstatic.com',
            'https://maps.googleapis.com',
            window.location.origin
        ];

        return whitelist.some(domain => src.startsWith(domain));
    }

    logSecurityEvent(type, details) {
        const event = {
            type,
            details,
            timestamp: new Date().toISOString(),
            userAgent: navigator.userAgent,
            url: window.location.href
        };

        this.threats.push(event);
        console.warn('Security Event:', event);

        // Send to security monitoring service (implement as needed)
        this.reportSecurityEvent(event);
    }

    reportSecurityEvent(event) {
        // Implement reporting to your security service
        // Example: fetch('/api/security/report', { method: 'POST', body: JSON.stringify(event) });
    }

    showSecurityWarning(message) {
        const warning = document.createElement('div');
        warning.className = 'security-warning';
        warning.innerHTML = `
            <div class="warning-content">
                <i class="fas fa-shield-alt"></i>
                <h3>Security Warning</h3>
                <p>${message}</p>
                <button onclick="this.parentElement.parentElement.remove()">Dismiss</button>
            </div>
        `;

        document.body.appendChild(warning);

        setTimeout(() => {
            if (warning.parentElement) {
                warning.remove();
            }
        }, 10000);
    }

    // HTML sanitization function
    sanitizeHTML(html) {
        const temp = document.createElement('div');
        temp.textContent = html;
        return temp.innerHTML;
    }
}

// Initialize security monitoring
document.addEventListener('DOMContentLoaded', () => {
    new SecurityMonitor();
});

// Add security warning styles
const securityStyles = `
    .security-warning {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(255, 0, 0, 0.9);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 10001;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }
    
    .warning-content {
        text-align: center;
        padding: 2rem;
        background: rgba(0, 0, 0, 0.8);
        border-radius: 10px;
        max-width: 500px;
    }
    
    .warning-content i {
        font-size: 3rem;
        margin-bottom: 1rem;
    }
    
    .warning-content h3 {
        font-size: 1.5rem;
        margin-bottom: 1rem;
    }
    
    .warning-content p {
        margin-bottom: 2rem;
        line-height: 1.6;
    }
    
    .warning-content button {
        padding: 0.75rem 2rem;
        background: white;
        color: #333;
        border: none;
        border-radius: 5px;
        font-weight: bold;
        cursor: pointer;
        transition: all 0.3s ease;
    }
    
    .warning-content button:hover {
        background: #f0f0f0;
        transform: translateY(-2px);
    }
`;

const securityStyleSheet = document.createElement('style');
securityStyleSheet.textContent = securityStyles;
document.head.appendChild(securityStyleSheet);
