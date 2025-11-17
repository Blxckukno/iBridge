/**
 * Enhanced Input Validation and Sanitization System
 * For iBridge Website Security
 * Version: 1.0.0
 * 
 * Features:
 * - Real-time input validation
 * - Advanced sanitization algorithms
 * - SQL injection prevention
 * - XSS attack mitigation
 * - CSRF token validation
 * - Input rate limiting
 */

(function() {
    'use strict';

    // Validation Configuration
    const VALIDATION_CONFIG = {
        // Input type patterns
        patterns: {
            email: /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/,
            phone: /^[\+]?[1-9][\d]{0,15}$/,
            name: /^[a-zA-Z\s\u00C0-\u017F'-]{2,50}$/,
            alphanumeric: /^[a-zA-Z0-9\s]{1,100}$/,
            url: /^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$/,
            zipcode: /^[0-9]{4,10}$/,
            creditcard: /^[0-9]{13,19}$/,
            strongPassword: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/
        },
        
        // Malicious pattern detection
        maliciousPatterns: {
            xss: [
                /<script[^>]*>.*?<\/script>/gi,
                /<iframe[^>]*>.*?<\/iframe>/gi,
                /<object[^>]*>.*?<\/object>/gi,
                /<embed[^>]*>.*?<\/embed>/gi,
                /<link[^>]*>/gi,
                /<meta[^>]*>/gi,
                /javascript:/gi,
                /vbscript:/gi,
                /on\w+\s*=/gi,
                /document\.cookie/gi,
                /window\.location/gi,
                /eval\s*\(/gi,
                /setTimeout\s*\(/gi,
                /setInterval\s*\(/gi,
                /Function\s*\(/gi,
                /XMLHttpRequest/gi,
                /fetch\s*\(/gi
            ],
            
            sqlInjection: [
                /(\bselect\b|\bunion\b|\binsert\b|\bdelete\b|\bdrop\b|\bcreate\b|\balter\b|\bupdate\b)/gi,
                /(\bor\b|\band\b)\s+[\w\s]*=[\w\s]*/gi,
                /;\s*drop\s+table/gi,
                /;\s*delete\s+from/gi,
                /;\s*insert\s+into/gi,
                /;\s*update\s+set/gi,
                /'\s*or\s*'.*'=/gi,
                /'\s*or\s*1\s*=\s*1/gi,
                /'\s*union\s*select/gi,
                /'\s*and\s*.*=/gi,
                /benchmark\s*\(/gi,
                /sleep\s*\(/gi,
                /waitfor\s+delay/gi
            ],
            
            commandInjection: [
                /;\s*(cat|ls|dir|type|echo|ping|wget|curl|nc|netcat|telnet|ssh)/gi,
                /\|\s*(cat|ls|dir|type|echo|ping|wget|curl|nc|netcat|telnet|ssh)/gi,
                /&&\s*(cat|ls|dir|type|echo|ping|wget|curl|nc|netcat|telnet|ssh)/gi,
                /`[^`]*`/gi,
                /\$\([^)]*\)/gi,
                /\${[^}]*}/gi,
                /%0a|%0d|%3b|%26/gi
            ],
            
            pathTraversal: [
                /\.\.\//gi,
                /\.\.\\/gi,
                /%2e%2e%2f/gi,
                /%2e%2e%5c/gi,
                /\.\.%2f/gi,
                /\.\.%5c/gi
            ],
            
            ldapInjection: [
                /\(\|\(/gi,
                /\)\|\)/gi,
                /\(\&\(/gi,
                /\)\&\)/gi,
                /\(\!\(/gi,
                /\)\!\)/gi
            ]
        },
        
        // Input limits
        limits: {
            maxLength: {
                name: 50,
                email: 100,
                phone: 20,
                message: 2000,
                address: 200,
                company: 100,
                subject: 150
            },
            maxInputsPerMinute: 30,
            maxSubmissionsPerHour: 5
        }
    };

    // Input tracking for rate limiting
    let inputTracker = {
        inputs: [],
        submissions: []
    };

    // CSRF token management
    let csrfToken = generateCSRFToken();

    /**
     * Enhanced Input Validator Class
     */
    class InputValidator {
        constructor() {
            this.isInitialized = false;
            this.violationCount = 0;
            this.init();
        }

        init() {
            this.setupRealTimeValidation();
            this.setupFormValidation();
            this.setupCSRFProtection();
            this.setupRateLimiting();
            this.isInitialized = true;
            
            console.log('🛡️ Enhanced Input Validation System Initialized');
        }

        setupRealTimeValidation() {
            // Real-time input validation
            document.addEventListener('input', (e) => {
                if (e.target.matches('input, textarea, select')) {
                    this.validateInputRealTime(e.target);
                }
            }, true);

            // Paste event validation
            document.addEventListener('paste', (e) => {
                if (e.target.matches('input, textarea')) {
                    setTimeout(() => this.validateInputRealTime(e.target), 10);
                }
            }, true);
        }

        setupFormValidation() {
            document.addEventListener('submit', (e) => {
                const form = e.target;
                if (!this.validateForm(form)) {
                    e.preventDefault();
                    this.showValidationError('Form contains invalid or suspicious content');
                }
            }, true);
        }

        setupCSRFProtection() {
            // Add CSRF tokens to all forms
            document.addEventListener('DOMContentLoaded', () => {
                this.addCSRFTokensToForms();
            });

            // Refresh CSRF token periodically
            setInterval(() => {
                csrfToken = generateCSRFToken();
                this.updateCSRFTokens();
            }, 30 * 60 * 1000); // 30 minutes
        }

        setupRateLimiting() {
            // Track input rate
            document.addEventListener('input', () => {
                this.trackInputRate();
            }, true);

            // Track form submissions
            document.addEventListener('submit', () => {
                this.trackSubmissionRate();
            }, true);
        }

        validateInputRealTime(input) {
            const value = input.value;
            if (!value) return true;

            // Check for malicious patterns
            const threat = this.scanForThreats(value);
            if (threat.detected) {
                this.handleThreatDetection(input, threat);
                return false;
            }

            // Validate based on input type
            const isValid = this.validateByType(input, value);
            this.updateInputValidationUI(input, isValid);

            return isValid;
        }

        validateForm(form) {
            let isValid = true;
            const inputs = form.querySelectorAll('input, textarea, select');
            
            // Validate CSRF token
            if (!this.validateCSRFToken(form)) {
                this.logSecurityEvent('csrf_token_validation_failed', { form: form.action });
                return false;
            }

            // Validate each input
            inputs.forEach(input => {
                if (!this.validateInputRealTime(input)) {
                    isValid = false;
                }
            });

            // Check submission rate
            if (!this.checkSubmissionRate()) {
                this.logSecurityEvent('submission_rate_exceeded');
                return false;
            }

            return isValid;
        }

        scanForThreats(value) {
            const threats = {
                detected: false,
                types: [],
                patterns: []
            };

            // Check each threat category
            Object.entries(VALIDATION_CONFIG.maliciousPatterns).forEach(([category, patterns]) => {
                patterns.forEach(pattern => {
                    if (pattern.test(value)) {
                        threats.detected = true;
                        threats.types.push(category);
                        threats.patterns.push(pattern.toString());
                    }
                });
            });

            return threats;
        }

        handleThreatDetection(input, threat) {
            this.violationCount++;
            
            // Sanitize the input
            const sanitized = this.sanitizeInput(input.value);
            input.value = sanitized;

            // Log the security event
            this.logSecurityEvent('malicious_input_detected', {
                inputName: input.name || input.id,
                threatTypes: threat.types,
                originalValue: input.value.substring(0, 100) + '...',
                sanitizedValue: sanitized
            });

            // Update UI to show threat was blocked
            this.showThreatBlockedUI(input);

            // If too many violations, trigger lockdown
            if (this.violationCount > 5) {
                this.triggerSecurityLockdown();
            }
        }

        sanitizeInput(value) {
            if (!value) return '';

            let sanitized = value;

            // Remove script tags and event handlers
            sanitized = sanitized.replace(/<script[^>]*>.*?<\/script>/gi, '');
            sanitized = sanitized.replace(/<iframe[^>]*>.*?<\/iframe>/gi, '');
            sanitized = sanitized.replace(/on\w+\s*=/gi, '');
            sanitized = sanitized.replace(/javascript:/gi, '');
            sanitized = sanitized.replace(/vbscript:/gi, '');

            // Remove SQL injection patterns
            sanitized = sanitized.replace(/(\bselect\b|\bunion\b|\binsert\b|\bdelete\b|\bdrop\b)/gi, '');
            sanitized = sanitized.replace(/'\s*or\s*'.*'=/gi, '');
            sanitized = sanitized.replace(/;\s*drop\s+table/gi, '');

            // Remove command injection patterns
            sanitized = sanitized.replace(/;\s*(cat|ls|dir|type|echo|ping|wget|curl)/gi, '');
            sanitized = sanitized.replace(/\|\s*(cat|ls|dir|type|echo|ping|wget|curl)/gi, '');
            sanitized = sanitized.replace(/`[^`]*`/gi, '');

            // Remove path traversal
            sanitized = sanitized.replace(/\.\.\//gi, '');
            sanitized = sanitized.replace(/\.\.\\/gi, '');

            // HTML encode special characters
            sanitized = sanitized
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#x27;');

            return sanitized;
        }

        validateByType(input, value) {
            const type = this.getInputType(input);
            const pattern = VALIDATION_CONFIG.patterns[type];
            
            if (!pattern) return true;

            // Check length limits
            const maxLength = VALIDATION_CONFIG.limits.maxLength[type];
            if (maxLength && value.length > maxLength) {
                return false;
            }

            return pattern.test(value);
        }

        getInputType(input) {
            // Determine input type based on various factors
            const type = input.type?.toLowerCase();
            const name = input.name?.toLowerCase();
            const id = input.id?.toLowerCase();
            
            if (type === 'email' || name?.includes('email') || id?.includes('email')) {
                return 'email';
            }
            if (type === 'tel' || name?.includes('phone') || id?.includes('phone')) {
                return 'phone';
            }
            if (name?.includes('name') || id?.includes('name')) {
                return 'name';
            }
            if (type === 'url' || name?.includes('url') || name?.includes('website')) {
                return 'url';
            }
            if (type === 'password') {
                return 'strongPassword';
            }
            
            return 'alphanumeric';
        }

        updateInputValidationUI(input, isValid) {
            input.classList.remove('input-valid', 'input-invalid');
            input.classList.add(isValid ? 'input-valid' : 'input-invalid');
            
            // Update border color
            input.style.borderColor = isValid ? '#4caf50' : '#f44336';
            
            // Show/hide validation message
            this.updateValidationMessage(input, isValid);
        }

        updateValidationMessage(input, isValid) {
            const existingMessage = input.parentElement.querySelector('.validation-message');
            if (existingMessage) {
                existingMessage.remove();
            }

            if (!isValid) {
                const message = document.createElement('div');
                message.className = 'validation-message';
                message.style.cssText = `
                    color: #f44336;
                    font-size: 0.8rem;
                    margin-top: 0.25rem;
                `;
                message.textContent = this.getValidationMessage(input);
                input.parentElement.appendChild(message);
            }
        }

        getValidationMessage(input) {
            const type = this.getInputType(input);
            const messages = {
                email: 'Please enter a valid email address',
                phone: 'Please enter a valid phone number',
                name: 'Please enter a valid name (letters only)',
                url: 'Please enter a valid URL',
                strongPassword: 'Password must be at least 8 characters with uppercase, lowercase, number and special character',
                alphanumeric: 'Please enter valid characters only'
            };
            
            return messages[type] || 'Please enter valid information';
        }

        showThreatBlockedUI(input) {
            // Add visual indicator that a threat was blocked
            input.style.backgroundColor = '#ffebee';
            input.style.borderColor = '#d32f2f';
            
            // Show threat blocked message
            const message = document.createElement('div');
            message.className = 'threat-blocked-message';
            message.style.cssText = `
                color: #d32f2f;
                font-size: 0.8rem;
                margin-top: 0.25rem;
                font-weight: bold;
            `;
            message.innerHTML = '🛡️ Security threat blocked and input sanitized';
            input.parentElement.appendChild(message);
            
            // Remove after 5 seconds
            setTimeout(() => {
                input.style.backgroundColor = '';
                message.remove();
            }, 5000);
        }

        addCSRFTokensToForms() {
            document.querySelectorAll('form').forEach(form => {
                if (!form.querySelector('input[name="csrf_token"]')) {
                    const csrfInput = document.createElement('input');
                    csrfInput.type = 'hidden';
                    csrfInput.name = 'csrf_token';
                    csrfInput.value = csrfToken;
                    form.appendChild(csrfInput);
                }
            });
        }

        updateCSRFTokens() {
            document.querySelectorAll('input[name="csrf_token"]').forEach(input => {
                input.value = csrfToken;
            });
        }

        validateCSRFToken(form) {
            const tokenInput = form.querySelector('input[name="csrf_token"]');
            if (!tokenInput) return false;
            
            return tokenInput.value === csrfToken;
        }

        trackInputRate() {
            const now = Date.now();
            inputTracker.inputs.push(now);
            
            // Keep only last minute of inputs
            inputTracker.inputs = inputTracker.inputs.filter(
                time => now - time < 60000
            );
            
            // Check rate limit
            if (inputTracker.inputs.length > VALIDATION_CONFIG.limits.maxInputsPerMinute) {
                this.logSecurityEvent('input_rate_exceeded', {
                    rate: inputTracker.inputs.length,
                    limit: VALIDATION_CONFIG.limits.maxInputsPerMinute
                });
                
                this.showValidationError('Input rate limit exceeded. Please slow down.');
                return false;
            }
            
            return true;
        }

        trackSubmissionRate() {
            const now = Date.now();
            inputTracker.submissions.push(now);
            
            // Keep only last hour of submissions
            inputTracker.submissions = inputTracker.submissions.filter(
                time => now - time < 3600000
            );
        }

        checkSubmissionRate() {
            if (inputTracker.submissions.length > VALIDATION_CONFIG.limits.maxSubmissionsPerHour) {
                this.showValidationError('Submission rate limit exceeded. Please try again later.');
                return false;
            }
            return true;
        }

        triggerSecurityLockdown() {
            console.error('🚨 SECURITY LOCKDOWN: Too many validation violations');
            
            // Disable all forms
            document.querySelectorAll('form').forEach(form => {
                form.style.pointerEvents = 'none';
                form.setAttribute('data-security-locked', 'true');
            });
            
            // Show lockdown notice
            this.showValidationError('Security lockdown activated due to suspicious activity. Please refresh and try again.');
            
            // Log the event
            this.logSecurityEvent('security_lockdown_triggered', {
                violationCount: this.violationCount,
                reason: 'excessive_validation_violations'
            });
        }

        showValidationError(message) {
            // Remove existing error
            const existing = document.querySelector('.validation-error-notice');
            if (existing) existing.remove();
            
            const notice = document.createElement('div');
            notice.className = 'validation-error-notice';
            notice.style.cssText = `
                position: fixed;
                top: 20px;
                left: 50%;
                transform: translateX(-50%);
                background: #d32f2f;
                color: white;
                padding: 1rem 2rem;
                border-radius: 8px;
                font-weight: bold;
                z-index: 10000;
                box-shadow: 0 4px 20px rgba(0,0,0,0.3);
                max-width: 400px;
                text-align: center;
            `;
            notice.textContent = message;
            
            document.body.appendChild(notice);
            
            // Auto-remove after 8 seconds
            setTimeout(() => notice.remove(), 8000);
        }

        logSecurityEvent(type, details = {}) {
            // Integration with security monitoring system
            if (window.iBridgeSecurityMonitor?.getMonitor()) {
                window.iBridgeSecurityMonitor.getMonitor().logSecurityEvent(type, details);
            } else {
                console.warn('🛡️ Security Event:', { type, details });
            }
        }
    }

    // Utility functions
    function generateCSRFToken() {
        const array = new Uint8Array(32);
        crypto.getRandomValues(array);
        return btoa(String.fromCharCode.apply(null, array)).replace(/[^a-zA-Z0-9]/g, '');
    }

    // Initialize the input validator
    let inputValidator;
    
    function initializeInputValidation() {
        try {
            inputValidator = new InputValidator();
            
            // Add validation styles
            addValidationStyles();
            
            console.log('✅ Enhanced Input Validation System Active');
        } catch (error) {
            console.error('❌ Failed to initialize input validation:', error);
        }
    }

    function addValidationStyles() {
        const style = document.createElement('style');
        style.textContent = `
            .input-valid {
                border-color: #4caf50 !important;
                box-shadow: 0 0 0 2px rgba(76, 175, 80, 0.2);
            }
            
            .input-invalid {
                border-color: #f44336 !important;
                box-shadow: 0 0 0 2px rgba(244, 67, 54, 0.2);
            }
            
            .validation-message {
                animation: fadeIn 0.3s ease-out;
            }
            
            .threat-blocked-message {
                animation: slideIn 0.3s ease-out;
            }
            
            @keyframes fadeIn {
                from { opacity: 0; transform: translateY(-10px); }
                to { opacity: 1; transform: translateY(0); }
            }
            
            @keyframes slideIn {
                from { opacity: 0; transform: translateX(-20px); }
                to { opacity: 1; transform: translateX(0); }
            }
        `;
        document.head.appendChild(style);
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializeInputValidation);
    } else {
        initializeInputValidation();
    }

    // Export for external access
    window.iBridgeInputValidator = {
        getValidator: () => inputValidator,
        validateInput: (value, type) => inputValidator?.validateByType({ type }, value),
        sanitizeInput: (value) => inputValidator?.sanitizeInput(value),
        version: '1.0.0'
    };

})();
