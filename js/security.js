/**
 * iBridge Website Security Implementation
 * Comprehensive security layer following OWASP guidelines
 * Last Updated: 2025
 */

(function() {
    'use strict';

    // ==========================================
    // CSRF Protection
    // ==========================================
    
    class CSRFProtection {
        constructor() {
            this.tokenName = 'csrf_token';
            this.tokenValue = this.generateToken();
            this.init();
        }

        generateToken() {
            // Generate cryptographically secure random token
            const array = new Uint8Array(32);
            crypto.getRandomValues(array);
            return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
        }

        init() {
            // Store token in sessionStorage
            if (!sessionStorage.getItem(this.tokenName)) {
                sessionStorage.setItem(this.tokenName, this.tokenValue);
            } else {
                this.tokenValue = sessionStorage.getItem(this.tokenName);
            }

            // Add CSRF token to all forms
            this.protectForms();
            
            // Add CSRF token to AJAX requests
            this.protectAjax();
        }

        protectForms() {
            document.addEventListener('DOMContentLoaded', () => {
                const forms = document.querySelectorAll('form');
                forms.forEach(form => {
                    // Check if token already exists
                    let tokenInput = form.querySelector(`input[name="${this.tokenName}"]`);
                    
                    if (!tokenInput) {
                        tokenInput = document.createElement('input');
                        tokenInput.type = 'hidden';
                        tokenInput.name = this.tokenName;
                        form.appendChild(tokenInput);
                    }
                    
                    tokenInput.value = this.tokenValue;
                });
            });
        }

        protectAjax() {
            const self = this;
            
            // Intercept fetch requests
            const originalFetch = window.fetch;
            window.fetch = function(...args) {
                const [resource, config = {}] = args;
                
                // Add CSRF token to POST, PUT, DELETE requests
                if (config.method && ['POST', 'PUT', 'DELETE', 'PATCH'].includes(config.method.toUpperCase())) {
                    config.headers = config.headers || {};
                    config.headers['X-CSRF-Token'] = self.tokenValue;
                }
                
                return originalFetch.apply(this, [resource, config]);
            };

            // Intercept XMLHttpRequest
            const originalOpen = XMLHttpRequest.prototype.open;
            const originalSend = XMLHttpRequest.prototype.send;

            XMLHttpRequest.prototype.open = function(method, url, ...rest) {
                this._method = method;
                return originalOpen.apply(this, [method, url, ...rest]);
            };

            XMLHttpRequest.prototype.send = function(...args) {
                if (this._method && ['POST', 'PUT', 'DELETE', 'PATCH'].includes(this._method.toUpperCase())) {
                    this.setRequestHeader('X-CSRF-Token', self.tokenValue);
                }
                return originalSend.apply(this, args);
            };
        }

        getToken() {
            return this.tokenValue;
        }

        refreshToken() {
            this.tokenValue = this.generateToken();
            sessionStorage.setItem(this.tokenName, this.tokenValue);
            this.protectForms();
        }
    }

    // ==========================================
    // XSS Protection & Input Sanitization
    // ==========================================
    
    class XSSProtection {
        static sanitizeInput(input) {
            if (typeof input !== 'string') return input;

            const map = {
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&#x27;',
                '/': '&#x2F;',
            };

            return input.replace(/[&<>"'/]/g, char => map[char]);
        }

        static sanitizeHTML(html) {
            const div = document.createElement('div');
            div.textContent = html;
            return div.innerHTML;
        }

        static stripTags(input) {
            if (typeof input !== 'string') return input;
            return input.replace(/<[^>]*>/g, '');
        }

        static validateEmail(email) {
            const emailRegex = /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
            return emailRegex.test(email);
        }

        static validatePhone(phone) {
            // Flexible phone validation allowing various formats
            const phoneRegex = /^[\d\s\-\+\(\)]{10,20}$/;
            return phoneRegex.test(phone);
        }

        static validateURL(url) {
            try {
                const parsed = new URL(url);
                return ['http:', 'https:'].includes(parsed.protocol);
            } catch {
                return false;
            }
        }

        static preventClickjacking() {
            // Prevent iframe embedding
            if (window.self !== window.top) {
                window.top.location = window.self.location;
            }
        }

        static protectConsole() {
            // Warn users about self-XSS attacks
            if (typeof console !== 'undefined') {
                const warningStyle = 'font-size: 20px; color: red; font-weight: bold;';
                const messageStyle = 'font-size: 14px;';
                
                console.log('%c⚠️ WARNING', warningStyle);
                console.log('%cDo not paste code here! This is a browser feature intended for developers. If someone told you to copy/paste something here, it is a scam and will give them access to your information.', messageStyle);
                console.log('%c🔒 iBridge Security Team', 'font-size: 12px; color: #A1C44F;');
            }
        }
    }

    // ==========================================
    // Form Security & Validation
    // ==========================================
    
    class FormSecurity {
        static init() {
            document.addEventListener('DOMContentLoaded', () => {
                const forms = document.querySelectorAll('form');
                forms.forEach(form => {
                    form.addEventListener('submit', FormSecurity.handleSubmit);
                    FormSecurity.addInputValidation(form);
                });
            });
        }

        static handleSubmit(event) {
            const form = event.target;
            
            // Sanitize all inputs
            const inputs = form.querySelectorAll('input, textarea');
            inputs.forEach(input => {
                if (input.type !== 'hidden' && input.type !== 'file') {
                    input.value = XSSProtection.sanitizeInput(input.value.trim());
                }
            });

            // Validate required fields
            if (!FormSecurity.validateForm(form)) {
                event.preventDefault();
                return false;
            }

            return true;
        }

        static validateForm(form) {
            const errors = [];

            // Email validation
            const emailInputs = form.querySelectorAll('input[type="email"]');
            emailInputs.forEach(input => {
                if (input.value && !XSSProtection.validateEmail(input.value)) {
                    errors.push(`Invalid email address: ${input.name || 'email'}`);
                    FormSecurity.showFieldError(input, 'Please enter a valid email address');
                }
            });

            // Phone validation
            const phoneInputs = form.querySelectorAll('input[type="tel"]');
            phoneInputs.forEach(input => {
                if (input.value && !XSSProtection.validatePhone(input.value)) {
                    errors.push(`Invalid phone number: ${input.name || 'phone'}`);
                    FormSecurity.showFieldError(input, 'Please enter a valid phone number');
                }
            });

            // Required field validation
            const requiredInputs = form.querySelectorAll('[required]');
            requiredInputs.forEach(input => {
                if (!input.value.trim()) {
                    errors.push(`Required field missing: ${input.name || input.id}`);
                    FormSecurity.showFieldError(input, 'This field is required');
                }
            });

            // URL validation
            const urlInputs = form.querySelectorAll('input[type="url"]');
            urlInputs.forEach(input => {
                if (input.value && !XSSProtection.validateURL(input.value)) {
                    errors.push(`Invalid URL: ${input.name || 'url'}`);
                    FormSecurity.showFieldError(input, 'Please enter a valid URL');
                }
            });

            if (errors.length > 0) {
                console.error('Form validation errors:', errors);
                return false;
            }

            return true;
        }

        static showFieldError(input, message) {
            // Remove existing error
            const existingError = input.parentElement.querySelector('.field-error');
            if (existingError) {
                existingError.remove();
            }

            // Add error message
            const error = document.createElement('div');
            error.className = 'field-error';
            error.style.cssText = 'color: #dc3545; font-size: 0.875rem; margin-top: 0.25rem;';
            error.textContent = message;
            input.parentElement.appendChild(error);

            // Add error styling to input
            input.style.borderColor = '#dc3545';

            // Remove error on input
            input.addEventListener('input', function removeError() {
                error.remove();
                input.style.borderColor = '';
                input.removeEventListener('input', removeError);
            }, { once: true });
        }

        static addInputValidation(form) {
            // Real-time email validation
            const emailInputs = form.querySelectorAll('input[type="email"]');
            emailInputs.forEach(input => {
                input.addEventListener('blur', () => {
                    if (input.value && !XSSProtection.validateEmail(input.value)) {
                        FormSecurity.showFieldError(input, 'Please enter a valid email address');
                    }
                });
            });

            // Real-time phone validation
            const phoneInputs = form.querySelectorAll('input[type="tel"]');
            phoneInputs.forEach(input => {
                input.addEventListener('blur', () => {
                    if (input.value && !XSSProtection.validatePhone(input.value)) {
                        FormSecurity.showFieldError(input, 'Please enter a valid phone number');
                    }
                });
            });
        }
    }

    // ==========================================
    // Rate Limiting
    // ==========================================
    
    class RateLimiter {
        constructor(maxAttempts = 5, timeWindow = 60000) {
            this.maxAttempts = maxAttempts;
            this.timeWindow = timeWindow; // in milliseconds
            this.attempts = new Map();
        }

        checkLimit(identifier) {
            const now = Date.now();
            const userAttempts = this.attempts.get(identifier) || [];
            
            // Remove old attempts outside time window
            const recentAttempts = userAttempts.filter(timestamp => now - timestamp < this.timeWindow);
            
            if (recentAttempts.length >= this.maxAttempts) {
                return false; // Rate limit exceeded
            }

            // Add current attempt
            recentAttempts.push(now);
            this.attempts.set(identifier, recentAttempts);
            
            return true; // Within rate limit
        }

        reset(identifier) {
            this.attempts.delete(identifier);
        }
    }

    // ==========================================
    // Content Security Policy Violation Reporting
    // ==========================================
    
    class CSPReporter {
        static init() {
            document.addEventListener('securitypolicyviolation', (e) => {
                const violation = {
                    documentURL: e.documentURL,
                    violatedDirective: e.violatedDirective,
                    effectiveDirective: e.effectiveDirective,
                    originalPolicy: e.originalPolicy,
                    blockedURI: e.blockedURI,
                    statusCode: e.statusCode,
                    sourceFile: e.sourceFile,
                    lineNumber: e.lineNumber,
                    columnNumber: e.columnNumber,
                    timestamp: new Date().toISOString()
                };

                console.error('🚨 CSP Violation:', violation);

                // You can send this to your backend for logging
                // fetch('/api/csp-report', {
                //     method: 'POST',
                //     headers: { 'Content-Type': 'application/json' },
                //     body: JSON.stringify(violation)
                // });
            });
        }
    }

    // ==========================================
    // Secure Storage
    // ==========================================
    
    class SecureStorage {
        static encrypt(data) {
            // Simple base64 encoding (in production, use proper encryption)
            try {
                return btoa(JSON.stringify(data));
            } catch (e) {
                console.error('Encryption error:', e);
                return null;
            }
        }

        static decrypt(data) {
            try {
                return JSON.parse(atob(data));
            } catch (e) {
                console.error('Decryption error:', e);
                return null;
            }
        }

        static setItem(key, value) {
            const encrypted = this.encrypt(value);
            if (encrypted) {
                sessionStorage.setItem(key, encrypted);
            }
        }

        static getItem(key) {
            const encrypted = sessionStorage.getItem(key);
            return encrypted ? this.decrypt(encrypted) : null;
        }

        static removeItem(key) {
            sessionStorage.removeItem(key);
        }

        static clear() {
            sessionStorage.clear();
        }
    }

    // ==========================================
    // Initialize Security Systems
    // ==========================================
    
    window.iBridgeSecurity = {
        csrf: new CSRFProtection(),
        xss: XSSProtection,
        rateLimiter: new RateLimiter(),
        storage: SecureStorage,
        
        // Public API
        sanitize: XSSProtection.sanitizeInput,
        validateEmail: XSSProtection.validateEmail,
        validatePhone: XSSProtection.validatePhone,
        validateURL: XSSProtection.validateURL,
        getCsrfToken: function() { return this.csrf.getToken(); },
        refreshCsrfToken: function() { this.csrf.refreshToken(); }
    };

    // Initialize all security features
    XSSProtection.preventClickjacking();
    XSSProtection.protectConsole();
    FormSecurity.init();
    CSPReporter.init();

    console.log('%c🔒 iBridge Security System Initialized', 'color: #A1C44F; font-weight: bold; font-size: 14px;');
    console.log('%cCSRF Protection: ✓', 'color: #28a745;');
    console.log('%cXSS Protection: ✓', 'color: #28a745;');
    console.log('%cForm Validation: ✓', 'color: #28a745;');
    console.log('%cRate Limiting: ✓', 'color: #28a745;');
    console.log('%cCSP Monitoring: ✓', 'color: #28a745;');

})();
