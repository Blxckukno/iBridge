/**
 * Enterprise Security Manager
 * Implements comprehensive security measures including CSP, HTTPS, security headers,
 * XSS protection, CSRF tokens, input validation, and security monitoring
 */

class SecurityManager {
    constructor() {
        this.securityConfig = {
            csp: {
                enabled: true,
                reportUri: '/security/csp-report',
                nonce: this.generateNonce()
            },
            headers: {
                hsts: true,
                frameOptions: 'DENY',
                contentTypeOptions: true,
                xssProtection: true,
                referrerPolicy: 'strict-origin-when-cross-origin'
            },
            csrf: {
                enabled: true,
                tokenName: 'csrf_token',
                tokenLength: 32
            },
            validation: {
                strictMode: true,
                sanitization: true
            },
            monitoring: {
                enabled: true,
                alertThreshold: 5,
                logLevel: 'INFO'
            }
        };

        this.securityEvents = [];
        this.blockedAttempts = new Map();
        this.rateLimiter = new Map();

        this.init();
    }

    /**
     * Initialize security system
     */
    init() {
        try {
            this.implementCSP();
            this.setupSecurityHeaders();
            this.enableXSSProtection();
            this.setupCSRFProtection();
            this.initializeInputValidation();
            this.setupSecurityMonitoring();
            this.enforceHTTPS();
            this.setupIntegrityChecks();
            this.initializeSecurityDashboard();

            this.logSecurityEvent('SECURITY_INIT', 'Security Manager initialized successfully');
            console.log('🛡️ Enterprise Security Manager initialized');
        } catch (error) {
            this.logSecurityEvent('SECURITY_ERROR', 'Security initialization failed', error);
            console.error('❌ Security Manager initialization failed:', error);
        }
    }

    isLocalOrPrivateHost(hostname) {
        if (!hostname) return true;
        if (hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '::1') return true;
        if (hostname.endsWith('.local')) return true;
        if (/^10\./.test(hostname)) return true;
        if (/^192\.168\./.test(hostname)) return true;
        if (/^172\.(1[6-9]|2\d|3[0-1])\./.test(hostname)) return true;
        return false;
    }

    /**
     * Implement Content Security Policy
     */
    implementCSP() {
        if (!this.securityConfig.csp.enabled) return;

        const cspDirectives = {
            'default-src': ["'self'"],
            'script-src': [
                "'self'",
                "'unsafe-inline'", // TODO: Remove in production, use nonces
                'https://www.google-analytics.com',
                'https://www.googletagmanager.com',
                'https://cdnjs.cloudflare.com'
            ],
            'style-src': [
                "'self'",
                "'unsafe-inline'", // TODO: Replace with nonces
                'https://fonts.googleapis.com',
                'https://cdnjs.cloudflare.com'
            ],
            'img-src': [
                "'self'",
                'data:',
                'blob:',
                'https://www.google-analytics.com'
            ],
            'font-src': [
                "'self'",
                'https://fonts.gstatic.com'
            ],
            'connect-src': [
                "'self'",
                'https://www.google-analytics.com',
                'https://api.github.com'
            ],
            'frame-src': [
                "'self'",
                'https://www.google.com',
                'https://maps.google.com',
                'https://www.openstreetmap.org'
            ],
            'object-src': ["'none'"],
            'base-uri': ["'self'"],
            'form-action': ["'self'"],
            'frame-ancestors': ["'none'"],
            'upgrade-insecure-requests': []
        };

        const cspString = Object.entries(cspDirectives)
            .map(([directive, sources]) =>
                sources.length > 0 ? `${directive} ${sources.join(' ')}` : directive
            )
            .join('; ');

        // Set CSP header via meta tag (for client-side implementation)
        const cspMeta = document.createElement('meta');
        cspMeta.httpEquiv = 'Content-Security-Policy';
        cspMeta.content = cspString;
        document.head.appendChild(cspMeta);

        this.logSecurityEvent('CSP_IMPLEMENTED', 'Content Security Policy applied');
    }

    /**
     * Setup security headers
     */
    setupSecurityHeaders() {
        // Note: These would typically be set server-side
        // This is client-side simulation for demonstration

        if (this.securityConfig.headers.frameOptions) {
            this.setSecurityHeader('X-Frame-Options', 'DENY');
        }

        if (this.securityConfig.headers.contentTypeOptions) {
            this.setSecurityHeader('X-Content-Type-Options', 'nosniff');
        }

        if (this.securityConfig.headers.xssProtection) {
            this.setSecurityHeader('X-XSS-Protection', '1; mode=block');
        }

        if (this.securityConfig.headers.referrerPolicy) {
            this.setSecurityHeader('Referrer-Policy', this.securityConfig.headers.referrerPolicy);
        }

        this.logSecurityEvent('HEADERS_SET', 'Security headers configured');
    }

    /**
     * Set security header (client-side simulation)
     */
    setSecurityHeader(name, value) {
        // Store for monitoring and reporting
        if (!window.securityHeaders) {
            window.securityHeaders = {};
        }
        window.securityHeaders[name] = value;
    }

    /**
     * Enable XSS Protection
     */
    enableXSSProtection() {
        // DOM XSS Protection
        this.setupDOMPurify();
        this.protectAgainstScriptInjection();
        this.sanitizeUserInputs();

        // Monitor for potential XSS attempts
        this.monitorDOMChanges();

        this.logSecurityEvent('XSS_PROTECTION', 'XSS protection enabled');
    }

    /**
     * Setup DOMPurify for content sanitization
     */
    setupDOMPurify() {
        // Simplified sanitization function (in production, use DOMPurify library)
        window.sanitizeHTML = (html) => {
            const temp = document.createElement('div');
            temp.textContent = html;
            return temp.innerHTML;
        };

        // Override innerHTML to sanitize content
        const originalInnerHTML = Element.prototype.__lookupSetter__('innerHTML') ||
            Object.getOwnPropertyDescriptor(Element.prototype, 'innerHTML').set;

        Object.defineProperty(Element.prototype, 'innerHTML', {
            set: function (value) {
                if (typeof value === 'string') {
                    value = this.sanitizeContent(value);
                }
                originalInnerHTML.call(this, value);
            }
        });
    }

    /**
     * Sanitize content to prevent XSS
     */
    sanitizeContent(content) {
        if (typeof content !== 'string') return content;

        // Basic sanitization (use proper library in production)
        return content
            .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
            .replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, '')
            .replace(/javascript:/gi, '')
            .replace(/on\w+\s*=/gi, '')
            .replace(/<object\b[^<]*(?:(?!<\/object>)<[^<]*)*<\/object>/gi, '')
            .replace(/<embed\b[^<]*(?:(?!<\/embed>)<[^<]*)*<\/embed>/gi, '');
    }

    /**
     * Protect against script injection
     */
    protectAgainstScriptInjection() {
        // Monitor eval usage
        const originalEval = window.eval;
        window.eval = function (code) {
            this.logSecurityEvent('EVAL_DETECTED', 'Eval usage detected', { code });
            if (this.securityConfig.validation.strictMode) {
                throw new Error('eval() is disabled for security reasons');
            }
            return originalEval.call(this, code);
        }.bind(this);

        // Monitor Function constructor
        const originalFunction = window.Function;
        window.Function = function (...args) {
            this.logSecurityEvent('FUNCTION_CONSTRUCTOR', 'Function constructor used', { args });
            if (this.securityConfig.validation.strictMode) {
                throw new Error('Function constructor is disabled for security reasons');
            }
            return originalFunction.apply(this, args);
        }.bind(this);
    }

    /**
     * Setup CSRF Protection
     */
    setupCSRFProtection() {
        if (!this.securityConfig.csrf.enabled) return;

        // Generate CSRF token
        this.csrfToken = this.generateCSRFToken();

        // Add token to all forms
        this.addCSRFTokenToForms();

        // Intercept AJAX requests to add CSRF token
        this.interceptAjaxRequests();

        this.logSecurityEvent('CSRF_PROTECTION', 'CSRF protection enabled');
    }

    /**
     * Generate CSRF token
     */
    generateCSRFToken() {
        const array = new Uint8Array(this.securityConfig.csrf.tokenLength);
        crypto.getRandomValues(array);
        return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
    }

    /**
     * Add CSRF token to all forms
     */
    addCSRFTokenToForms() {
        const forms = document.querySelectorAll('form');
        forms.forEach(form => {
            if (!form.querySelector(`input[name="${this.securityConfig.csrf.tokenName}"]`)) {
                const tokenInput = document.createElement('input');
                tokenInput.type = 'hidden';
                tokenInput.name = this.securityConfig.csrf.tokenName;
                tokenInput.value = this.csrfToken;
                form.appendChild(tokenInput);
            }
        });

        // Watch for dynamically added forms
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                mutation.addedNodes.forEach((node) => {
                    if (node.nodeType === 1) { // Element node
                        if (node.tagName === 'FORM') {
                            this.addCSRFTokenToForm(node);
                        }
                        const forms = node.querySelectorAll && node.querySelectorAll('form');
                        if (forms) {
                            forms.forEach(form => this.addCSRFTokenToForm(form));
                        }
                    }
                });
            });
        });

        observer.observe(document.body, { childList: true, subtree: true });
    }

    /**
     * Add CSRF token to a specific form
     */
    addCSRFTokenToForm(form) {
        if (!form.querySelector(`input[name="${this.securityConfig.csrf.tokenName}"]`)) {
            const tokenInput = document.createElement('input');
            tokenInput.type = 'hidden';
            tokenInput.name = this.securityConfig.csrf.tokenName;
            tokenInput.value = this.csrfToken;
            form.appendChild(tokenInput);
        }
    }

    /**
     * Initialize input validation
     */
    initializeInputValidation() {
        this.setupFormValidation();
        this.setupRealTimeValidation();
        this.preventSQLInjection();

        this.logSecurityEvent('INPUT_VALIDATION', 'Input validation initialized');
    }

    /**
     * Setup form validation
     */
    setupFormValidation() {
        document.addEventListener('submit', (e) => {
            const form = e.target;
            if (form.tagName === 'FORM') {
                if (!this.validateForm(form)) {
                    e.preventDefault();
                    this.logSecurityEvent('FORM_VALIDATION_FAILED', 'Form validation failed');
                }
            }
        });
    }

    /**
     * Validate form inputs
     */
    validateForm(form) {
        const inputs = form.querySelectorAll('input, textarea, select');
        let isValid = true;

        inputs.forEach(input => {
            if (!this.validateInput(input)) {
                isValid = false;
                this.highlightInvalidInput(input);
            }
        });

        return isValid;
    }

    /**
     * Validate individual input
     */
    validateInput(input) {
        const value = input.value.trim();
        const type = input.type || 'text';

        // Check for suspicious patterns
        if (this.containsSuspiciousContent(value)) {
            this.logSecurityEvent('SUSPICIOUS_INPUT', 'Suspicious input detected', {
                type,
                value: value.substring(0, 100)
            });
            return false;
        }

        // Type-specific validation
        switch (type) {
            case 'email':
                return this.validateEmail(value);
            case 'url':
                return this.validateURL(value);
            case 'tel':
                return this.validatePhone(value);
            default:
                return this.validateGeneral(value);
        }
    }

    /**
     * Check for suspicious content
     */
    containsSuspiciousContent(value) {
        const suspiciousPatterns = [
            /<script/i,
            /javascript:/i,
            /vbscript:/i,
            /on\w+\s*=/i,
            /expression\s*\(/i,
            /(union|select|insert|update|delete|drop|create|alter|exec|execute)\s+/i,
            /<iframe/i,
            /<object/i,
            /<embed/i
        ];

        return suspiciousPatterns.some(pattern => pattern.test(value));
    }

    /**
     * Setup security monitoring
     */
    setupSecurityMonitoring() {
        if (!this.securityConfig.monitoring.enabled) return;

        // Monitor console errors for security issues
        window.addEventListener('error', (event) => {
            this.logSecurityEvent('JS_ERROR', 'JavaScript error detected', {
                message: event.message,
                filename: event.filename,
                lineno: event.lineno
            });
        });

        // Monitor unhandled promise rejections
        window.addEventListener('unhandledrejection', (event) => {
            this.logSecurityEvent('UNHANDLED_REJECTION', 'Unhandled promise rejection', {
                reason: event.reason
            });
        });

        // Monitor CSP violations
        document.addEventListener('securitypolicyviolation', (event) => {
            this.logSecurityEvent('CSP_VIOLATION', 'CSP policy violation', {
                violatedDirective: event.violatedDirective,
                blockedURI: event.blockedURI,
                sourceFile: event.sourceFile
            });
        });

        this.logSecurityEvent('MONITORING_ENABLED', 'Security monitoring enabled');
    }

    /**
     * Enforce HTTPS
     */
    enforceHTTPS() {
        if (location.protocol !== 'https:' && !this.isLocalOrPrivateHost(location.hostname)) {
            this.logSecurityEvent('HTTP_REDIRECT', 'Redirecting to HTTPS');
            location.replace('https:' + window.location.href.substring(window.location.protocol.length));
        }
    }

    /**
     * Setup integrity checks
     */
    setupIntegrityChecks() {
        // Check for script integrity
        const scripts = document.querySelectorAll('script[src]');
        scripts.forEach(script => {
            if (!script.hasAttribute('integrity') && !script.src.includes(location.hostname)) {
                this.logSecurityEvent('MISSING_INTEGRITY', 'External script without integrity check', {
                    src: script.src
                });
            }
        });
    }

    /**
     * Generate security nonce
     */
    generateNonce() {
        const array = new Uint8Array(16);
        crypto.getRandomValues(array);
        return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
    }

    /**
     * Log security event
     */
    logSecurityEvent(type, message, details = {}) {
        const event = {
            timestamp: new Date().toISOString(),
            type,
            message,
            details,
            userAgent: navigator.userAgent,
            url: location.href
        };

        this.securityEvents.push(event);

        if (this.securityConfig.monitoring.logLevel === 'DEBUG' ||
            ['SECURITY_ERROR', 'CSP_VIOLATION', 'SUSPICIOUS_INPUT'].includes(type)) {
            console.warn(`[SECURITY] ${type}: ${message}`, details);
        }

        // Send to monitoring endpoint (if available)
        if (this.securityConfig.monitoring.enabled && typeof this.reportSecurityEvent === 'function') {
            this.reportSecurityEvent(event);
        }
    }

    /**
     * Get security report
     */
    getSecurityReport() {
        return {
            timestamp: new Date().toISOString(),
            config: this.securityConfig,
            events: this.securityEvents.slice(-100), // Last 100 events
            blockedAttempts: Array.from(this.blockedAttempts.entries()),
            csrfToken: this.csrfToken ? '***HIDDEN***' : null,
            metrics: {
                totalEvents: this.securityEvents.length,
                errorEvents: this.securityEvents.filter(e => e.type.includes('ERROR')).length,
                violations: this.securityEvents.filter(e => e.type.includes('VIOLATION')).length,
                suspiciousInputs: this.securityEvents.filter(e => e.type === 'SUSPICIOUS_INPUT').length
            }
        };
    }

    /**
     * Initialize security dashboard
     */
    initializeSecurityDashboard() {
        // Create security status indicator
        const securityIndicator = document.createElement('div');
        securityIndicator.innerHTML = '🛡️';
        securityIndicator.title = 'Security Status: Active';
        securityIndicator.style.cssText = `
            position: fixed;
            top: 20px;
            right: 80px;
            z-index: 10000;
            background: #28a745;
            color: white;
            border: none;
            width: 50px;
            height: 50px;
            border-radius: 50%;
            font-size: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
            transition: all 0.3s ease;
            opacity: 0.8;
        `;

        securityIndicator.addEventListener('click', () => {
            this.openSecurityDashboard();
        });

        document.body.appendChild(securityIndicator);

        // Update indicator based on security status
        setInterval(() => {
            const recentViolations = this.securityEvents
                .filter(e => e.type.includes('VIOLATION') || e.type.includes('ERROR'))
                .filter(e => Date.now() - new Date(e.timestamp).getTime() < 300000); // Last 5 minutes

            if (recentViolations.length > 0) {
                securityIndicator.style.background = '#dc3545';
                securityIndicator.title = `Security Alert: ${recentViolations.length} recent violations`;
            } else {
                securityIndicator.style.background = '#28a745';
                securityIndicator.title = 'Security Status: Active';
            }
        }, 30000);
    }

    /**
     * Open security dashboard
     */
    openSecurityDashboard() {
        const dashboardUrl = 'security-dashboard.html';
        const dashboard = window.open(
            dashboardUrl,
            'security-dashboard',
            'width=1200,height=800,scrollbars=yes,resizable=yes'
        );

        if (dashboard) {
            dashboard.focus();
        } else {
            console.warn('Security dashboard popup blocked. Please allow popups for this site.');
            if (confirm('Security dashboard popup was blocked. Open in current tab?')) {
                window.location.href = dashboardUrl;
            }
        }
    }

    // Additional validation methods
    validateEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    validateURL(url) {
        try {
            new URL(url);
            return true;
        } catch {
            return false;
        }
    }

    validatePhone(phone) {
        const phoneRegex = /^[+]?[\d\s\-()]{10,}$/;
        return phoneRegex.test(phone);
    }

    validateGeneral(value) {
        return value.length > 0 && value.length < 10000;
    }

    highlightInvalidInput(input) {
        input.style.border = '2px solid #dc3545';
        setTimeout(() => {
            input.style.border = '';
        }, 3000);
    }

    interceptAjaxRequests() {
        // Intercept XMLHttpRequest
        const originalXHR = window.XMLHttpRequest;
        window.XMLHttpRequest = function () {
            const xhr = new originalXHR();
            const originalSend = xhr.send;

            xhr.send = function (data) {
                xhr.setRequestHeader(this.securityConfig.csrf.tokenName, this.csrfToken);
                return originalSend.call(xhr, data);
            }.bind(this);

            return xhr;
        }.bind(this);

        // Intercept fetch requests
        const originalFetch = window.fetch;
        window.fetch = function (url, options = {}) {
            options.headers = options.headers || {};
            options.headers[this.securityConfig.csrf.tokenName] = this.csrfToken;
            return originalFetch.call(window, url, options);
        }.bind(this);
    }

    monitorDOMChanges() {
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                mutation.addedNodes.forEach((node) => {
                    if (node.nodeType === 1) { // Element node
                        const scripts = node.tagName === 'SCRIPT' ? [node] :
                            (node.querySelectorAll && node.querySelectorAll('script') || []);

                        scripts.forEach(script => {
                            if (script.innerHTML.trim()) {
                                this.logSecurityEvent('DYNAMIC_SCRIPT', 'Dynamic script added to DOM', {
                                    content: script.innerHTML.substring(0, 200)
                                });
                            }
                        });
                    }
                });
            });
        });

        observer.observe(document.body, { childList: true, subtree: true });
    }

    preventSQLInjection() {
        // Client-side SQL injection prevention (basic patterns)
        const sqlPatterns = [
            /(\b(union|select|insert|update|delete|drop|create|alter|exec|execute)\s+)/i,
            /(;|\||&|\$|\*|'|"|\\)/,
            /-{2}/,
            /\/\*/
        ];

        document.addEventListener('input', (e) => {
            const value = e.target.value;
            if (sqlPatterns.some(pattern => pattern.test(value))) {
                this.logSecurityEvent('SQL_INJECTION_ATTEMPT', 'Potential SQL injection detected', {
                    input: value.substring(0, 100)
                });

                if (this.securityConfig.validation.strictMode) {
                    e.target.value = value.replace(/[;|&$*'"\\-]/g, '');
                }
            }
        });
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.securityManager = new SecurityManager();

    // Cleanup on page unload
    window.addEventListener('beforeunload', () => {
        if (window.securityManager) {
            window.securityManager.logSecurityEvent('SESSION_END', 'Security session ended');
        }
    });
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SecurityManager;
}
