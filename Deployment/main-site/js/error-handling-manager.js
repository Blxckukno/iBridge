/**
 * Error Handling Manager
 * Comprehensive error handling with graceful degradation, logging, and recovery
 */

class ErrorHandlingManager {
    constructor() {
        this.config = {
            enableGlobalErrorHandling: true,
            enableUnhandledRejectionHandling: true,
            enableConsoleErrorCapture: true,
            maxErrorsPerSession: 50,
            errorReportingEndpoint: '/api/errors',
            retryAttempts: 3,
            retryDelay: 1000,
            enableUserNotifications: true
        };

        this.errors = [];
        this.errorCounts = new Map();
        this.isInitialized = false;

        this.init();
    }

    /**
     * Initialize Error Handling Manager
     */
    init() {
        try {
            if (this.config.enableGlobalErrorHandling) {
                this.setupGlobalErrorHandling();
            }

            if (this.config.enableUnhandledRejectionHandling) {
                this.setupUnhandledRejectionHandling();
            }

            this.setupNetworkErrorHandling();
            this.setupFormErrorHandling();
            this.setupImageErrorHandling();
            this.createErrorNotificationSystem();

            this.isInitialized = true;
            console.log('🛡️ Error Handling Manager initialized');
        } catch (error) {
            console.error('❌ Error Handling Manager initialization failed:', error);
        }
    }

    /**
     * Setup global error handling
     */
    setupGlobalErrorHandling() {
        window.addEventListener('error', (event) => {
            this.handleError({
                type: 'javascript_error',
                message: event.message,
                filename: event.filename,
                lineno: event.lineno,
                colno: event.colno,
                error: event.error,
                stack: event.error?.stack,
                timestamp: new Date().toISOString(),
                userAgent: navigator.userAgent,
                url: window.location.href
            });
        });

        // Override console.error to capture console errors
        if (this.config.enableConsoleErrorCapture) {
            const originalConsoleError = console.error;
            console.error = (...args) => {
                this.handleError({
                    type: 'console_error',
                    message: args.join(' '),
                    timestamp: new Date().toISOString(),
                    stack: new Error().stack
                });
                originalConsoleError.apply(console, args);
            };
        }
    }

    /**
     * Setup unhandled promise rejection handling
     */
    setupUnhandledRejectionHandling() {
        window.addEventListener('unhandledrejection', (event) => {
            this.handleError({
                type: 'unhandled_promise_rejection',
                message: event.reason?.message || 'Unhandled Promise Rejection',
                reason: event.reason,
                stack: event.reason?.stack,
                timestamp: new Date().toISOString(),
                url: window.location.href
            });
        });
    }

    /**
     * Setup network error handling
     */
    setupNetworkErrorHandling() {
        // Override fetch to add error handling
        const originalFetch = window.fetch;
        window.fetch = async (...args) => {
            try {
                const response = await originalFetch.apply(this, args);

                if (!response.ok) {
                    this.handleError({
                        type: 'network_error',
                        message: `HTTP ${response.status}: ${response.statusText}`,
                        url: args[0],
                        status: response.status,
                        statusText: response.statusText,
                        timestamp: new Date().toISOString()
                    });
                }

                return response;
            } catch (error) {
                this.handleError({
                    type: 'fetch_error',
                    message: error.message,
                    url: args[0],
                    error: error,
                    stack: error.stack,
                    timestamp: new Date().toISOString()
                });
                throw error;
            }
        };

        // Handle resource loading errors
        document.addEventListener('error', (event) => {
            if (event.target !== window) {
                const element = event.target;
                this.handleResourceError(element);
            }
        }, true);
    }

    /**
     * Handle resource loading errors
     */
    handleResourceError(element) {
        const errorInfo = {
            type: 'resource_error',
            elementType: element.tagName.toLowerCase(),
            src: element.src || element.href,
            timestamp: new Date().toISOString()
        };

        this.handleError(errorInfo);

        // Implement fallback strategies
        switch (element.tagName.toLowerCase()) {
            case 'img':
                this.handleImageError(element);
                break;
            case 'script':
                this.handleScriptError(element);
                break;
            case 'link':
                this.handleLinkError(element);
                break;
        }
    }

    /**
     * Setup form error handling
     */
    setupFormErrorHandling() {
        document.addEventListener('submit', (event) => {
            const form = event.target;
            if (form.tagName === 'FORM') {
                this.validateForm(form, event);
            }
        });

        // Setup real-time validation
        document.addEventListener('input', (event) => {
            if (event.target.form) {
                this.validateField(event.target);
            }
        });

        document.addEventListener('blur', (event) => {
            if (event.target.form) {
                this.validateField(event.target);
            }
        });
    }

    /**
     * Setup image error handling
     */
    setupImageErrorHandling() {
        document.addEventListener('error', (event) => {
            if (event.target.tagName === 'IMG') {
                this.handleImageError(event.target);
            }
        }, true);
    }

    /**
     * Handle image loading errors
     */
    handleImageError(img) {
        // Create fallback image
        const fallbackSvg = `data:image/svg+xml,${encodeURIComponent(`
            <svg xmlns="http://www.w3.org/2000/svg" width="300" height="200" viewBox="0 0 300 200">
                <rect width="300" height="200" fill="#f8f9fa" stroke="#dee2e6" stroke-width="2"/>
                <text x="150" y="100" text-anchor="middle" dy="0.3em" font-family="Arial, sans-serif" 
                      font-size="16" fill="#6c757d">Image not available</text>
                <circle cx="150" cy="70" r="20" fill="none" stroke="#6c757d" stroke-width="2"/>
                <path d="M130 60 L150 50 L170 60 L160 80 L140 80 Z" fill="none" stroke="#6c757d" stroke-width="2"/>
            </svg>
        `)}`;

        img.src = fallbackSvg;
        img.alt = 'Image not available';
        img.classList.add('error-fallback-image');
    }

    /**
     * Handle script loading errors
     */
    handleScriptError(script) {
        const src = script.src;
        console.warn(`Failed to load script: ${src}`);

        // Try to load from CDN or fallback
        if (src.includes('local')) {
            const cdnSrc = src.replace(/^.*\/([^\/]+)$/, 'https://cdn.jsdelivr.net/npm/$1');
            this.loadFallbackScript(cdnSrc);
        }
    }

    /**
     * Load fallback script
     */
    loadFallbackScript(src) {
        const fallbackScript = document.createElement('script');
        fallbackScript.src = src;
        fallbackScript.async = true;
        document.head.appendChild(fallbackScript);
    }

    /**
     * Handle CSS loading errors
     */
    handleLinkError(link) {
        if (link.rel === 'stylesheet') {
            console.warn(`Failed to load stylesheet: ${link.href}`);
            // Could implement fallback CSS loading here
        }
    }

    /**
     * Validate form
     */
    validateForm(form, event) {
        const errors = [];
        const fields = form.querySelectorAll('input, textarea, select');

        fields.forEach(field => {
            const fieldErrors = this.validateField(field);
            if (fieldErrors.length > 0) {
                errors.push(...fieldErrors);
            }
        });

        if (errors.length > 0) {
            event.preventDefault();
            this.displayFormErrors(form, errors);
            return false;
        }

        return true;
    }

    /**
     * Validate individual field
     */
    validateField(field) {
        const errors = [];
        const value = field.value.trim();
        const type = field.type;
        const required = field.hasAttribute('required');

        // Required field validation
        if (required && !value) {
            errors.push(`${this.getFieldLabel(field)} is required`);
        }

        if (value) {
            // Email validation
            if (type === 'email' && !this.isValidEmail(value)) {
                errors.push(`Please enter a valid email address`);
            }

            // Phone validation
            if (type === 'tel' && !this.isValidPhone(value)) {
                errors.push(`Please enter a valid phone number`);
            }

            // URL validation
            if (type === 'url' && !this.isValidUrl(value)) {
                errors.push(`Please enter a valid URL`);
            }

            // Min/Max length validation
            const minLength = field.getAttribute('minlength');
            const maxLength = field.getAttribute('maxlength');

            if (minLength && value.length < parseInt(minLength)) {
                errors.push(`${this.getFieldLabel(field)} must be at least ${minLength} characters`);
            }

            if (maxLength && value.length > parseInt(maxLength)) {
                errors.push(`${this.getFieldLabel(field)} must not exceed ${maxLength} characters`);
            }

            // Pattern validation
            const pattern = field.getAttribute('pattern');
            if (pattern && !new RegExp(pattern).test(value)) {
                errors.push(`${this.getFieldLabel(field)} format is invalid`);
            }
        }

        // Update field UI
        this.updateFieldUI(field, errors);
        return errors;
    }

    /**
     * Update field UI based on validation
     */
    updateFieldUI(field, errors) {
        // Remove existing error classes and messages
        field.classList.remove('error', 'valid');
        const existingError = field.parentElement.querySelector('.field-error');
        if (existingError) {
            existingError.remove();
        }

        if (errors.length > 0) {
            field.classList.add('error');

            const errorElement = document.createElement('div');
            errorElement.className = 'field-error';
            errorElement.textContent = errors[0];
            field.parentElement.appendChild(errorElement);
        } else if (field.value.trim()) {
            field.classList.add('valid');
        }
    }

    /**
     * Get field label for error messages
     */
    getFieldLabel(field) {
        const label = field.labels?.[0]?.textContent ||
            field.getAttribute('placeholder') ||
            field.name ||
            field.id ||
            'Field';
        return label.replace(/[*:]/g, '').trim();
    }

    /**
     * Validation helpers
     */
    isValidEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

    isValidPhone(phone) {
        return /^[\+]?[1-9][\d]{0,15}$/.test(phone.replace(/[\s\-\(\)]/g, ''));
    }

    isValidUrl(url) {
        try {
            new URL(url);
            return true;
        } catch {
            return false;
        }
    }

    /**
     * Display form errors
     */
    displayFormErrors(form, errors) {
        // Remove existing error summary
        const existingSummary = form.querySelector('.form-error-summary');
        if (existingSummary) {
            existingSummary.remove();
        }

        // Create error summary
        const errorSummary = document.createElement('div');
        errorSummary.className = 'form-error-summary';
        errorSummary.innerHTML = `
            <h4>Please correct the following errors:</h4>
            <ul>
                ${errors.map(error => `<li>${error}</li>`).join('')}
            </ul>
        `;

        form.insertBefore(errorSummary, form.firstChild);
        errorSummary.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    /**
     * Handle error with logging and reporting
     */
    handleError(errorInfo) {
        // Prevent error spam
        const errorKey = `${errorInfo.type}_${errorInfo.message}`;
        const count = this.errorCounts.get(errorKey) || 0;
        this.errorCounts.set(errorKey, count + 1);

        if (count > 5) {
            return; // Stop reporting repeated errors
        }

        // Add to error log
        this.errors.push(errorInfo);

        // Limit error storage
        if (this.errors.length > this.config.maxErrorsPerSession) {
            this.errors.shift();
        }

        // Log to console in development
        if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
            console.group('🐛 Error Captured');
            console.error('Type:', errorInfo.type);
            console.error('Message:', errorInfo.message);
            if (errorInfo.stack) console.error('Stack:', errorInfo.stack);
            console.error('Full Info:', errorInfo);
            console.groupEnd();
        }

        // Report to analytics if available
        if (window.analyticsManager) {
            window.analyticsManager.trackEvent('error_occurred', {
                error_type: errorInfo.type,
                error_message: errorInfo.message,
                error_url: errorInfo.url || window.location.href
            });
        }

        // Send to error reporting service
        this.reportError(errorInfo);

        // Show user notification for critical errors
        if (this.config.enableUserNotifications && this.isCriticalError(errorInfo)) {
            this.showErrorNotification(errorInfo);
        }
    }

    /**
     * Check if error is critical
     */
    isCriticalError(errorInfo) {
        const criticalTypes = ['network_error', 'unhandled_promise_rejection'];
        const criticalMessages = ['failed to fetch', 'network error', 'server error'];

        return criticalTypes.includes(errorInfo.type) ||
            criticalMessages.some(msg => errorInfo.message.toLowerCase().includes(msg));
    }

    /**
     * Report error to server
     */
    async reportError(errorInfo) {
        try {
            if (!navigator.onLine) {
                // Queue error for later reporting
                this.queueOfflineError(errorInfo);
                return;
            }

            await fetch(this.config.errorReportingEndpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    ...errorInfo,
                    sessionId: this.getSessionId(),
                    userId: this.getUserId(),
                    timestamp: new Date().toISOString()
                })
            });
        } catch (error) {
            console.warn('Failed to report error:', error);
        }
    }

    /**
     * Queue error for offline reporting
     */
    queueOfflineError(errorInfo) {
        const offlineErrors = JSON.parse(localStorage.getItem('offline_errors') || '[]');
        offlineErrors.push(errorInfo);

        // Limit stored errors
        if (offlineErrors.length > 20) {
            offlineErrors.shift();
        }

        localStorage.setItem('offline_errors', JSON.stringify(offlineErrors));
    }

    /**
     * Create error notification system
     */
    createErrorNotificationSystem() {
        const styles = `
            .error-notification {
                position: fixed;
                top: 20px;
                right: 20px;
                background: #dc3545;
                color: white;
                padding: 15px 20px;
                border-radius: 8px;
                box-shadow: 0 4px 12px rgba(220, 53, 69, 0.3);
                z-index: 10000;
                max-width: 400px;
                transform: translateX(100%);
                transition: transform 0.3s ease;
            }
            
            .error-notification.show {
                transform: translateX(0);
            }
            
            .error-notification .close-btn {
                background: none;
                border: none;
                color: white;
                font-size: 18px;
                cursor: pointer;
                float: right;
                margin-left: 10px;
            }
            
            .form-error-summary {
                background: #f8d7da;
                border: 1px solid #f5c6cb;
                color: #721c24;
                padding: 15px;
                border-radius: 5px;
                margin-bottom: 20px;
            }
            
            .form-error-summary h4 {
                margin: 0 0 10px 0;
                font-size: 16px;
            }
            
            .form-error-summary ul {
                margin: 0;
                padding-left: 20px;
            }
            
            .field-error {
                color: #dc3545;
                font-size: 14px;
                margin-top: 5px;
            }
            
            .error {
                border-color: #dc3545 !important;
                box-shadow: 0 0 0 0.2rem rgba(220, 53, 69, 0.25) !important;
            }
            
            .valid {
                border-color: #28a745 !important;
                box-shadow: 0 0 0 0.2rem rgba(40, 167, 69, 0.25) !important;
            }
            
            .error-fallback-image {
                border: 2px dashed #dee2e6;
                background: #f8f9fa;
                opacity: 0.7;
            }
        `;

        const styleSheet = document.createElement('style');
        styleSheet.textContent = styles;
        document.head.appendChild(styleSheet);
    }

    /**
     * Show error notification to user
     */
    showErrorNotification(errorInfo) {
        const notification = document.createElement('div');
        notification.className = 'error-notification';
        notification.innerHTML = `
            <button class="close-btn" onclick="this.parentElement.remove()">&times;</button>
            <strong>Something went wrong</strong><br>
            <small>${this.getUserFriendlyMessage(errorInfo)}</small>
        `;

        document.body.appendChild(notification);

        // Show notification
        setTimeout(() => notification.classList.add('show'), 100);

        // Auto-dismiss after 5 seconds
        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => notification.remove(), 300);
        }, 5000);
    }

    /**
     * Get user-friendly error message
     */
    getUserFriendlyMessage(errorInfo) {
        const friendlyMessages = {
            'network_error': 'Connection problem. Please check your internet.',
            'fetch_error': 'Unable to connect to server. Please try again.',
            'resource_error': 'Failed to load some content.',
            'javascript_error': 'A technical error occurred. The page should still work.',
            'unhandled_promise_rejection': 'An unexpected error occurred.'
        };

        return friendlyMessages[errorInfo.type] || 'An unexpected error occurred. Please try refreshing the page.';
    }

    /**
     * Retry failed operation
     */
    async retryOperation(operation, maxAttempts = this.config.retryAttempts) {
        for (let attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                return await operation();
            } catch (error) {
                if (attempt === maxAttempts) {
                    throw error;
                }

                console.warn(`Operation failed, retrying (${attempt}/${maxAttempts}):`, error.message);
                await this.delay(this.config.retryDelay * attempt);
            }
        }
    }

    /**
     * Delay helper
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    /**
     * Get session ID
     */
    getSessionId() {
        let sessionId = sessionStorage.getItem('error_session_id');
        if (!sessionId) {
            sessionId = 'sess_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            sessionStorage.setItem('error_session_id', sessionId);
        }
        return sessionId;
    }

    /**
     * Get user ID
     */
    getUserId() {
        return localStorage.getItem('analytics_user_id') || 'anonymous';
    }

    /**
     * Get error report
     */
    getErrorReport() {
        return {
            errors: this.errors,
            errorCounts: Object.fromEntries(this.errorCounts),
            isInitialized: this.isInitialized,
            timestamp: new Date().toISOString()
        };
    }
}

// Initialize Error Handling Manager
document.addEventListener('DOMContentLoaded', () => {
    window.errorHandlingManager = new ErrorHandlingManager();
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ErrorHandlingManager;
}