/**
 * Enhanced Content Security Policy Manager
 * Implements nonce-based CSP and security monitoring
 */

class CSPManager {
    constructor() {
        this.config = {
            reportingEndpoint: '/api/csp-violation-report',
            enableViolationLogging: true,
            enableNonceValidation: true,
            strictMode: true
        };

        this.violations = [];
        this.nonce = this.getPageNonce() || this.generateNonce();

        this.init();
    }

    /**
     * Initialize CSP Manager
     */
    init() {
        try {
            this.setupViolationReporting();
            this.validateCurrentCSP();
            this.setupNonceValidation();

            console.log('🛡️ CSP Manager initialized with nonce:', this.nonce);
        } catch (error) {
            console.error('❌ CSP Manager initialization failed:', error);
        }
    }

    /**
     * Generate cryptographically secure nonce
     */
    generateNonce() {
        const array = new Uint8Array(32);
        crypto.getRandomValues(array);
        return btoa(String.fromCharCode(...array)).replace(/[+/=]/g, '');
    }

    isPublicMainSitePage() {
        const path = (window.location.pathname || '').toLowerCase();
        return !/(ticketingsystem|professional-dashboard|staff-portal|lms-platform|security-dashboard|performance-dashboard|intranet)/i.test(path);
    }

    getPageNonce() {
        return document.querySelector('script[nonce]')?.getAttribute('nonce') || '';
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
     * Setup CSP violation reporting
     */
    setupViolationReporting() {
        document.addEventListener('securitypolicyviolation', (event) => {
            this.handleViolation(event);
        });

        // Legacy support for older browsers
        window.addEventListener('securitypolicyviolation', (event) => {
            this.handleViolation(event);
        });
    }

    /**
     * Handle CSP violations
     */
    handleViolation(event) {
        const violation = {
            blockedURI: event.blockedURI,
            violatedDirective: event.violatedDirective,
            originalPolicy: event.originalPolicy,
            sourceFile: event.sourceFile,
            lineNumber: event.lineNumber,
            columnNumber: event.columnNumber,
            timestamp: new Date().toISOString(),
            userAgent: navigator.userAgent,
            documentURI: event.documentURI
        };

        this.violations.push(violation);

        if (this.config.enableViolationLogging) {
            console.warn('🚨 CSP Violation:', violation);
        }

        // Report violation to server
        this.reportViolation(violation);

        // Track in analytics if available
        if (window.analyticsManager) {
            window.analyticsManager.trackEvent('csp_violation', {
                directive: violation.violatedDirective,
                blocked_uri: violation.blockedURI,
                source_file: violation.sourceFile
            });
        }
    }

    /**
     * Report violation to server
     */
    async reportViolation(violation) {
        try {
            await fetch(this.config.reportingEndpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(violation)
            });
        } catch (error) {
            console.error('Failed to report CSP violation:', error);
        }
    }

    /**
     * Validate current CSP implementation
     */
    validateCurrentCSP() {
        const metaCSP = document.querySelector('meta[http-equiv="Content-Security-Policy"]');

        if (!metaCSP) {
            console.warn('⚠️ No CSP meta tag found');
            return false;
        }

        const cspContent = metaCSP.content;
        const issues = [];

        // Check for unsafe directives
        const scriptDirective = (cspContent.match(/script-src\s+([^;]+)/) || [null, ''])[1];
        if (scriptDirective.includes("'unsafe-inline'")) {
            issues.push("Contains 'unsafe-inline' in script-src");
        }

        if (cspContent.includes("'unsafe-eval'")) {
            issues.push("Contains 'unsafe-eval' directive");
        }

        if (cspContent.includes('*')) {
            issues.push("Contains wildcard (*) sources");
        }

        // Check for required directives
        const requiredDirectives = [
            'default-src',
            'script-src',
            'style-src',
            'img-src',
            'font-src',
            'connect-src'
        ];

        requiredDirectives.forEach(directive => {
            if (!cspContent.includes(directive)) {
                issues.push(`Missing ${directive} directive`);
            }
        });

        if (issues.length > 0) {
            console.warn('⚠️ CSP Issues found:', issues);
            return false;
        }

        console.log('✅ CSP validation passed');
        return true;
    }

    /**
     * Setup nonce validation for scripts
     */
    setupNonceValidation() {
        if (!this.config.enableNonceValidation) return;

        const scripts = document.querySelectorAll('script[nonce]');
        const validNonces = [];
        const expectedNonce = this.getPageNonce() || this.nonce;

        scripts.forEach(script => {
            const scriptNonce = script.getAttribute('nonce');
            if (scriptNonce && scriptNonce === expectedNonce) {
                validNonces.push(scriptNonce);
            } else {
                console.warn('⚠️ Script with invalid nonce found:', script.src || 'inline script');
            }
        });

        console.log(`✅ Validated ${validNonces.length} scripts with correct nonce`);
    }

    /**
     * Create secure script element with nonce
     */
    createSecureScript(src, content = null) {
        const script = document.createElement('script');

        if (src) {
            script.src = src;
        } else if (content) {
            script.textContent = content;
        }

        script.nonce = this.nonce;
        script.crossOrigin = 'anonymous';

        return script;
    }

    /**
     * Safely add inline script with nonce
     */
    addSecureInlineScript(code, parent = document.head) {
        const script = this.createSecureScript(null, code);
        parent.appendChild(script);
        return script;
    }

    /**
     * Safely load external script with nonce
     */
    loadSecureScript(src, parent = document.head) {
        return new Promise((resolve, reject) => {
            const script = this.createSecureScript(src);

            script.onload = () => resolve(script);
            script.onerror = () => reject(new Error(`Failed to load script: ${src}`));

            parent.appendChild(script);
        });
    }

    /**
     * Generate CSP header for current page
     */
    generateCSPHeader() {
        const nonce = this.nonce;
        const isLocal = this.isLocalOrPrivateHost(window.location.hostname);
        const styleSrc = this.isPublicMainSitePage()
            ? "style-src 'self' 'unsafe-inline'"
            : "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com";
        const fontSrc = this.isPublicMainSitePage()
            ? "font-src 'self' data:"
            : "font-src 'self' data: https://fonts.gstatic.com";
        const connectSrc = isLocal ? "connect-src 'self' http://localhost:5000 http://127.0.0.1:5000" : "connect-src 'self'";
        const upgradeDirective = isLocal ? '' : '; upgrade-insecure-requests';

        return [
            "default-src 'self'",
            `script-src 'self' 'nonce-${nonce}'`,
            styleSrc,
            fontSrc,
            "img-src 'self' data: https:",
            connectSrc,
            "frame-src 'self' https://www.google.com https://maps.google.com",
            "frame-ancestors 'none'",
            "base-uri 'self'",
            "form-action 'self'",
            `report-uri ${this.config.reportingEndpoint}`
        ].join('; ') + upgradeDirective;
    }

    /**
     * Get violation report
     */
    getViolationReport() {
        return {
            totalViolations: this.violations.length,
            violations: this.violations,
            timestamp: new Date().toISOString()
        };
    }

    /**
     * Clear violation history
     */
    clearViolations() {
        this.violations = [];
    }

    /**
     * Update CSP meta tag with current nonce
     */
    updateCSPMetaTag() {
        const metaCSP = document.querySelector('meta[http-equiv="Content-Security-Policy"]');
        if (metaCSP) {
            const newCSP = this.generateCSPHeader();
            metaCSP.content = newCSP;
            console.log('📋 CSP meta tag updated with new nonce');
        }
    }
}

/**
 * Security Headers Validator
 * Validates presence and configuration of security headers
 */
class SecurityHeaderValidator {
    constructor() {
        this.expectedHeaders = {
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': 'DENY',
            'X-XSS-Protection': '1; mode=block',
            'Strict-Transport-Security': true, // Just check presence
            'Content-Security-Policy': true,
            'Referrer-Policy': true
        };
    }

    /**
     * Validate security headers in meta tags
     */
    validateMetaHeaders() {
        const results = {};

        Object.keys(this.expectedHeaders).forEach(header => {
            const metaTag = document.querySelector(`meta[http-equiv="${header}"]`);
            const expected = this.expectedHeaders[header];

            if (!metaTag) {
                results[header] = { present: false, status: 'missing' };
            } else {
                const content = metaTag.content;

                if (expected === true) {
                    // Just check presence
                    results[header] = {
                        present: true,
                        content: content,
                        status: 'present'
                    };
                } else if (content === expected) {
                    results[header] = {
                        present: true,
                        content: content,
                        status: 'correct'
                    };
                } else {
                    results[header] = {
                        present: true,
                        content: content,
                        expected: expected,
                        status: 'incorrect'
                    };
                }
            }
        });

        return results;
    }

    /**
     * Generate security report
     */
    generateSecurityReport() {
        const headerResults = this.validateMetaHeaders();
        const issues = [];
        const passed = [];

        Object.entries(headerResults).forEach(([header, result]) => {
            if (result.status === 'missing') {
                issues.push(`Missing security header: ${header}`);
            } else if (result.status === 'incorrect') {
                issues.push(`Incorrect value for ${header}: got "${result.content}", expected "${result.expected}"`);
            } else {
                passed.push(`${header}: ✅`);
            }
        });

        return {
            passed: passed.length,
            failed: issues.length,
            total: Object.keys(this.expectedHeaders).length,
            passedHeaders: passed,
            issues: issues,
            details: headerResults
        };
    }

    /**
     * Log security report to console
     */
    logSecurityReport() {
        const report = this.generateSecurityReport();

        console.group('🔒 Security Headers Report');
        console.log(`Passed: ${report.passed}/${report.total}`);

        if (report.passedHeaders.length > 0) {
            console.log('✅ Passed Headers:', report.passedHeaders);
        }

        if (report.issues.length > 0) {
            console.warn('❌ Issues:', report.issues);
        }

        console.groupEnd();

        return report;
    }
}

/**
 * Secure Script Loader
 * Provides secure methods for loading scripts with CSP compliance
 */
class SecureScriptLoader {
    constructor(cspManager) {
        this.cspManager = cspManager;
        this.loadedScripts = new Set();
        this.failedScripts = new Set();
    }

    /**
     * Load script with integrity checking
     */
    async loadScriptWithIntegrity(src, integrity = null, crossorigin = 'anonymous') {
        if (this.loadedScripts.has(src)) {
            console.log(`Script already loaded: ${src}`);
            return true;
        }

        try {
            const script = document.createElement('script');
            script.src = src;
            script.crossOrigin = crossorigin;
            script.nonce = this.cspManager.nonce;

            if (integrity) {
                script.integrity = integrity;
            }

            const loadPromise = new Promise((resolve, reject) => {
                script.onload = () => {
                    this.loadedScripts.add(src);
                    resolve(true);
                };

                script.onerror = () => {
                    this.failedScripts.add(src);
                    reject(new Error(`Failed to load script: ${src}`));
                };
            });

            document.head.appendChild(script);
            await loadPromise;

            console.log(`✅ Securely loaded script: ${src}`);
            return true;

        } catch (error) {
            console.error(`❌ Failed to load script: ${src}`, error);

            // Track failed script loads
            if (window.analyticsManager) {
                window.analyticsManager.trackEvent('script_load_failed', {
                    src: src,
                    error: error.message
                });
            }

            return false;
        }
    }

    /**
     * Get loading statistics
     */
    getLoadingStats() {
        return {
            loaded: Array.from(this.loadedScripts),
            failed: Array.from(this.failedScripts),
            loadedCount: this.loadedScripts.size,
            failedCount: this.failedScripts.size
        };
    }
}

// Initialize security managers
document.addEventListener('DOMContentLoaded', () => {
    // Initialize CSP Manager
    window.cspManager = new CSPManager();

    // Initialize Security Header Validator
    window.securityHeaderValidator = new SecurityHeaderValidator();

    // Initialize Secure Script Loader
    window.secureScriptLoader = new SecureScriptLoader(window.cspManager);

    // Run initial security validation
    setTimeout(() => {
        window.securityHeaderValidator.logSecurityReport();

        // Log CSP status
        const cspReport = window.cspManager.getViolationReport();
        if (cspReport.totalViolations > 0) {
            console.warn(`🚨 ${cspReport.totalViolations} CSP violations detected`);
        } else {
            console.log('✅ No CSP violations detected');
        }
    }, 1000);

    console.log('🔒 Security managers initialized successfully');
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        CSPManager,
        SecurityHeaderValidator,
        SecureScriptLoader
    };
}
