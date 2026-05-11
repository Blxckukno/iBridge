/**
 * Form Validation Manager
 * Advanced form validation with real-time feedback and custom rules
 */

class FormValidationManager {
    constructor() {
        this.config = {
            enableRealTimeValidation: true,
            enableSubmissionValidation: true,
            showSuccessStates: true,
            debounceDelay: 300,
            scrollToError: true,
            enableAccessibility: true
        };

        this.forms = new Map();
        this.validators = new Map();
        this.customRules = new Map();
        this.isInitialized = false;

        this.init();
    }

    /**
     * Initialize Form Validation Manager
     */
    init() {
        try {
            this.setupDefaultValidators();
            this.setupCustomRules();
            this.bindEventListeners();
            this.initializeExistingForms();
            this.addValidationStyles();

            this.isInitialized = true;
            console.log('ðŸ“ Form Validation Manager initialized');
        } catch (error) {
            console.error('âŒ Form Validation Manager initialization failed:', error);
        }
    }

    /**
     * Setup default validators
     */
    setupDefaultValidators() {
        // Required field validator
        this.validators.set('required', {
            validate: (value, field) => {
                return value.trim().length > 0;
            },
            message: (field) => `${this.getFieldLabel(field)} is required`
        });

        // Email validator
        this.validators.set('email', {
            validate: (value, field) => {
                return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
            },
            message: () => 'Please enter a valid email address'
        });

        // Phone validator
        this.validators.set('phone', {
            validate: (value, field) => {
                const cleaned = value.replace(/[\s\-\(\)]/g, '');
                return /^[\+]?[1-9][\d]{0,15}$/.test(cleaned);
            },
            message: () => 'Please enter a valid phone number'
        });

        // URL validator
        this.validators.set('url', {
            validate: (value, field) => {
                try {
                    new URL(value);
                    return true;
                } catch {
                    return false;
                }
            },
            message: () => 'Please enter a valid URL'
        });

        // Number validator
        this.validators.set('number', {
            validate: (value, field) => {
                return !isNaN(value) && isFinite(value);
            },
            message: () => 'Please enter a valid number'
        });

        // Min length validator
        this.validators.set('minlength', {
            validate: (value, field) => {
                const minLength = parseInt(field.getAttribute('minlength'));
                return value.length >= minLength;
            },
            message: (field) => {
                const minLength = field.getAttribute('minlength');
                return `${this.getFieldLabel(field)} must be at least ${minLength} characters`;
            }
        });

        // Max length validator
        this.validators.set('maxlength', {
            validate: (value, field) => {
                const maxLength = parseInt(field.getAttribute('maxlength'));
                return value.length <= maxLength;
            },
            message: (field) => {
                const maxLength = field.getAttribute('maxlength');
                return `${this.getFieldLabel(field)} must not exceed ${maxLength} characters`;
            }
        });

        // Pattern validator
        this.validators.set('pattern', {
            validate: (value, field) => {
                const pattern = field.getAttribute('pattern');
                return new RegExp(pattern).test(value);
            },
            message: (field) => {
                const title = field.getAttribute('title');
                return title || `${this.getFieldLabel(field)} format is invalid`;
            }
        });

        // Min value validator
        this.validators.set('min', {
            validate: (value, field) => {
                const min = parseFloat(field.getAttribute('min'));
                return parseFloat(value) >= min;
            },
            message: (field) => {
                const min = field.getAttribute('min');
                return `Value must be at least ${min}`;
            }
        });

        // Max value validator
        this.validators.set('max', {
            validate: (value, field) => {
                const max = parseFloat(field.getAttribute('max'));
                return parseFloat(value) <= max;
            },
            message: (field) => {
                const max = field.getAttribute('max');
                return `Value must not exceed ${max}`;
            }
        });

        // Step validator
        this.validators.set('step', {
            validate: (value, field) => {
                const step = parseFloat(field.getAttribute('step'));
                const min = parseFloat(field.getAttribute('min')) || 0;
                return (parseFloat(value) - min) % step === 0;
            },
            message: (field) => {
                const step = field.getAttribute('step');
                return `Value must be in steps of ${step}`;
            }
        });
    }

    /**
     * Setup custom validation rules
     */
    setupCustomRules() {
        // Password strength validator
        this.customRules.set('password-strength', {
            validate: (value, field) => {
                const strength = this.calculatePasswordStrength(value);
                return strength >= 3; // Require at least "Good" strength
            },
            message: () => 'Password must contain at least 8 characters with uppercase, lowercase, number, and special character'
        });

        // Confirm password validator
        this.customRules.set('confirm-password', {
            validate: (value, field) => {
                const passwordField = field.form.querySelector('[data-password-field]');
                return passwordField ? value === passwordField.value : true;
            },
            message: () => 'Passwords do not match'
        });

        // Credit card validator
        this.customRules.set('credit-card', {
            validate: (value, field) => {
                return this.isValidCreditCard(value);
            },
            message: () => 'Please enter a valid credit card number'
        });

        // Date range validator
        this.customRules.set('date-range', {
            validate: (value, field) => {
                const minDate = field.getAttribute('data-min-date');
                const maxDate = field.getAttribute('data-max-date');
                const date = new Date(value);

                if (minDate && date < new Date(minDate)) return false;
                if (maxDate && date > new Date(maxDate)) return false;

                return true;
            },
            message: (field) => {
                const minDate = field.getAttribute('data-min-date');
                const maxDate = field.getAttribute('data-max-date');

                if (minDate && maxDate) {
                    return `Date must be between ${minDate} and ${maxDate}`;
                } else if (minDate) {
                    return `Date must be after ${minDate}`;
                } else if (maxDate) {
                    return `Date must be before ${maxDate}`;
                }

                return 'Invalid date range';
            }
        });

        // File size validator
        this.customRules.set('file-size', {
            validate: (value, field) => {
                if (!field.files || field.files.length === 0) return true;

                const maxSize = parseInt(field.getAttribute('data-max-size')) || 5000000; // 5MB default
                return Array.from(field.files).every(file => file.size <= maxSize);
            },
            message: (field) => {
                const maxSize = field.getAttribute('data-max-size') || '5000000';
                return `File size must not exceed ${this.formatFileSize(maxSize)}`;
            }
        });

        // File type validator
        this.customRules.set('file-type', {
            validate: (value, field) => {
                if (!field.files || field.files.length === 0) return true;

                const allowedTypes = field.getAttribute('data-allowed-types')?.split(',') || [];
                if (allowedTypes.length === 0) return true;

                return Array.from(field.files).every(file => {
                    return allowedTypes.some(type => file.type.match(type.trim()));
                });
            },
            message: (field) => {
                const allowedTypes = field.getAttribute('data-allowed-types') || 'allowed';
                return `Only ${allowedTypes} files are allowed`;
            }
        });
    }

    /**
     * Bind event listeners
     */
    bindEventListeners() {
        // Form submission
        document.addEventListener('submit', (event) => {
            if (event.target.tagName === 'FORM') {
                this.handleFormSubmission(event);
            }
        });

        // Real-time validation
        if (this.config.enableRealTimeValidation) {
            document.addEventListener('input', this.debounce((event) => {
                if (this.isValidatableField(event.target)) {
                    this.validateField(event.target);
                }
            }, this.config.debounceDelay));

            document.addEventListener('blur', (event) => {
                if (this.isValidatableField(event.target)) {
                    this.validateField(event.target);
                }
            });

            document.addEventListener('change', (event) => {
                if (this.isValidatableField(event.target)) {
                    this.validateField(event.target);
                }
            });
        }

        // Dynamic form detection
        document.addEventListener('DOMContentLoaded', () => {
            this.initializeExistingForms();
        });

        // Handle dynamically added forms
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                mutation.addedNodes.forEach((node) => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        if (node.tagName === 'FORM') {
                            this.initializeForm(node);
                        } else {
                            const forms = node.querySelectorAll('form');
                            forms.forEach(form => this.initializeForm(form));
                        }
                    }
                });
            });
        });

        observer.observe(document.body, { childList: true, subtree: true });
    }

    /**
     * Initialize existing forms
     */
    initializeExistingForms() {
        const forms = document.querySelectorAll('form');
        forms.forEach(form => this.initializeForm(form));
    }

    /**
     * Initialize individual form
     */
    initializeForm(form) {
        if (this.forms.has(form)) return;

        const formData = {
            element: form,
            fields: new Map(),
            isValid: false,
            errors: new Map()
        };

        this.forms.set(form, formData);

        // Initialize form fields
        const fields = form.querySelectorAll('input, textarea, select');
        fields.forEach(field => this.initializeField(field, formData));

        // Add form attributes for accessibility
        if (this.config.enableAccessibility) {
            form.setAttribute('novalidate', 'true'); // Disable browser validation
            form.setAttribute('data-validation-manager', 'true');
        }
    }

    /**
     * Initialize individual field
     */
    initializeField(field, formData) {
        const fieldData = {
            element: field,
            validators: [],
            customRules: [],
            isValid: null,
            errors: []
        };

        // Determine validators based on field attributes
        this.setupFieldValidators(field, fieldData);

        formData.fields.set(field, fieldData);

        // Add ARIA attributes for accessibility
        if (this.config.enableAccessibility) {
            field.setAttribute('aria-describedby', `${field.id || field.name}_error`);
        }
    }

    /**
     * Setup validators for a field
     */
    setupFieldValidators(field, fieldData) {
        // Required validator
        if (field.hasAttribute('required')) {
            fieldData.validators.push('required');
        }

        // Type-based validators
        const type = field.type || field.tagName.toLowerCase();
        switch (type) {
            case 'email':
                fieldData.validators.push('email');
                break;
            case 'tel':
                fieldData.validators.push('phone');
                break;
            case 'url':
                fieldData.validators.push('url');
                break;
            case 'number':
            case 'range':
                fieldData.validators.push('number');
                break;
        }

        // Attribute-based validators
        if (field.hasAttribute('minlength')) fieldData.validators.push('minlength');
        if (field.hasAttribute('maxlength')) fieldData.validators.push('maxlength');
        if (field.hasAttribute('pattern')) fieldData.validators.push('pattern');
        if (field.hasAttribute('min')) fieldData.validators.push('min');
        if (field.hasAttribute('max')) fieldData.validators.push('max');
        if (field.hasAttribute('step')) fieldData.validators.push('step');

        // Custom rules based on data attributes
        const customRules = field.getAttribute('data-validation-rules');
        if (customRules) {
            fieldData.customRules = customRules.split(',').map(rule => rule.trim());
        }

        // Auto-detect common patterns
        this.autoDetectValidationRules(field, fieldData);
    }

    /**
     * Auto-detect validation rules based on field patterns
     */
    autoDetectValidationRules(field, fieldData) {
        const name = (field.name || field.id || '').toLowerCase();
        const placeholder = (field.placeholder || '').toLowerCase();

        // Password fields
        if (name.includes('password') && !name.includes('confirm')) {
            fieldData.customRules.push('password-strength');
        }

        // Confirm password fields
        if (name.includes('confirm') && name.includes('password')) {
            fieldData.customRules.push('confirm-password');
        }

        // Credit card fields
        if (name.includes('card') || name.includes('credit') || placeholder.includes('card')) {
            fieldData.customRules.push('credit-card');
        }

        // File upload fields
        if (field.type === 'file') {
            if (field.hasAttribute('data-max-size')) {
                fieldData.customRules.push('file-size');
            }
            if (field.hasAttribute('data-allowed-types')) {
                fieldData.customRules.push('file-type');
            }
        }

        // Date fields with range
        if (field.type === 'date' && (field.hasAttribute('data-min-date') || field.hasAttribute('data-max-date'))) {
            fieldData.customRules.push('date-range');
        }
    }

    /**
     * Handle form submission
     */
    handleFormSubmission(event) {
        const form = event.target;
        const isValid = this.validateForm(form);

        if (!isValid && this.config.enableSubmissionValidation) {
            event.preventDefault();

            // Scroll to first error
            if (this.config.scrollToError) {
                this.scrollToFirstError(form);
            }

            // Track validation failure
            if (window.analyticsManager) {
                window.analyticsManager.trackEvent('form_validation_failed', {
                    form_id: form.id || 'unknown',
                    error_count: this.getFormErrorCount(form)
                });
            }

            return false;
        }

        // Track successful validation
        if (window.analyticsManager) {
            window.analyticsManager.trackEvent('form_validation_passed', {
                form_id: form.id || 'unknown'
            });
        }

        return true;
    }

    /**
     * Validate entire form
     */
    validateForm(form) {
        const formData = this.forms.get(form);
        if (!formData) {
            this.initializeForm(form);
            return this.validateForm(form);
        }

        let isFormValid = true;
        const errors = [];

        // Validate all fields
        formData.fields.forEach((fieldData, field) => {
            const fieldValid = this.validateField(field);
            if (!fieldValid) {
                isFormValid = false;
                errors.push(...fieldData.errors);
            }
        });

        // Cross-field validation
        const crossFieldErrors = this.validateCrossField(form);
        if (crossFieldErrors.length > 0) {
            isFormValid = false;
            errors.push(...crossFieldErrors);
        }

        formData.isValid = isFormValid;
        this.updateFormUI(form, isFormValid, errors);

        return isFormValid;
    }

    /**
     * Validate individual field
     */
    validateField(field) {
        const form = field.form;
        if (!form) return true;

        const formData = this.forms.get(form);
        if (!formData) return true;

        const fieldData = formData.fields.get(field);
        if (!fieldData) return true;

        const value = this.getFieldValue(field);
        const errors = [];

        // Skip validation for empty non-required fields
        if (!value && !field.hasAttribute('required')) {
            fieldData.isValid = true;
            fieldData.errors = [];
            this.updateFieldUI(field, true, []);
            return true;
        }

        // Run standard validators
        fieldData.validators.forEach(validatorName => {
            const validator = this.validators.get(validatorName);
            if (validator && !validator.validate(value, field)) {
                errors.push(validator.message(field));
            }
        });

        // Run custom rules
        fieldData.customRules.forEach(ruleName => {
            const rule = this.customRules.get(ruleName);
            if (rule && !rule.validate(value, field)) {
                errors.push(rule.message(field));
            }
        });

        fieldData.isValid = errors.length === 0;
        fieldData.errors = errors;

        this.updateFieldUI(field, fieldData.isValid, errors);
        return fieldData.isValid;
    }

    /**
     * Cross-field validation
     */
    validateCrossField(form) {
        const errors = [];

        // Example: Validate date ranges
        const startDate = form.querySelector('[data-start-date]');
        const endDate = form.querySelector('[data-end-date]');

        if (startDate && endDate && startDate.value && endDate.value) {
            if (new Date(startDate.value) > new Date(endDate.value)) {
                errors.push('End date must be after start date');
            }
        }

        // Example: Validate password confirmation
        const password = form.querySelector('[data-password-field]');
        const confirmPassword = form.querySelector('[data-confirm-password]');

        if (password && confirmPassword && password.value !== confirmPassword.value) {
            errors.push('Passwords do not match');
        }

        return errors;
    }

    /**
     * Update field UI
     */
    updateFieldUI(field, isValid, errors) {
        // Remove existing classes and messages
        field.classList.remove('valid', 'invalid', 'error');

        const errorContainer = this.getOrCreateErrorContainer(field);
        errorContainer.innerHTML = '';

        // Apply appropriate classes and messages
        if (isValid && field.value.trim()) {
            if (this.config.showSuccessStates) {
                field.classList.add('valid');
            }
        } else if (!isValid) {
            field.classList.add('invalid', 'error');

            if (errors.length > 0) {
                errorContainer.innerHTML = errors.map(error =>
                    `<div class="field-error">${error}</div>`
                ).join('');
            }
        }

        // Update ARIA attributes
        if (this.config.enableAccessibility) {
            field.setAttribute('aria-invalid', (!isValid).toString());

            if (errorContainer.children.length > 0) {
                errorContainer.setAttribute('role', 'alert');
                errorContainer.setAttribute('aria-live', 'polite');
            }
        }
    }

    /**
     * Update form UI
     */
    updateFormUI(form, isValid, errors) {
        // Remove existing error summary
        const existingSummary = form.querySelector('.form-validation-summary');
        if (existingSummary) {
            existingSummary.remove();
        }

        // Add error summary if there are errors
        if (!isValid && errors.length > 0) {
            const summary = document.createElement('div');
            summary.className = 'form-validation-summary error-summary';
            summary.innerHTML = `
                <h4><i class="fas fa-exclamation-triangle"></i> Please correct the following errors:</h4>
                <ul>
                    ${errors.slice(0, 5).map(error => `<li>${error}</li>`).join('')}
                    ${errors.length > 5 ? `<li>And ${errors.length - 5} more errors...</li>` : ''}
                </ul>
            `;

            form.insertBefore(summary, form.firstElementChild);
        }
    }

    /**
     * Get or create error container for field
     */
    getOrCreateErrorContainer(field) {
        const errorId = `${field.id || field.name}_error`;
        let errorContainer = document.getElementById(errorId);

        if (!errorContainer) {
            errorContainer = document.createElement('div');
            errorContainer.id = errorId;
            errorContainer.className = 'field-error-container';

            // Insert after field or field wrapper
            const wrapper = field.closest('.form-group, .field-wrapper') || field.parentElement;
            wrapper.appendChild(errorContainer);
        }

        return errorContainer;
    }

    /**
     * Get field value
     */
    getFieldValue(field) {
        switch (field.type) {
            case 'checkbox':
                return field.checked ? field.value : '';
            case 'radio':
                const radioGroup = field.form.querySelectorAll(`input[name="${field.name}"]`);
                const checked = Array.from(radioGroup).find(radio => radio.checked);
                return checked ? checked.value : '';
            case 'file':
                return field.files.length > 0 ? field.value : '';
            default:
                return field.value.trim();
        }
    }

    /**
     * Get field label
     */
    getFieldLabel(field) {
        const label = field.labels?.[0]?.textContent ||
            field.getAttribute('data-label') ||
            field.getAttribute('placeholder') ||
            field.name ||
            field.id ||
            'Field';
        return label.replace(/[*:]/g, '').trim();
    }

    /**
     * Check if field should be validated
     */
    isValidatableField(field) {
        return field.form &&
            ['INPUT', 'TEXTAREA', 'SELECT'].includes(field.tagName) &&
            field.type !== 'submit' &&
            field.type !== 'button' &&
            field.type !== 'reset' &&
            !field.disabled &&
            !field.readOnly;
    }

    /**
     * Scroll to first error
     */
    scrollToFirstError(form) {
        const firstError = form.querySelector('.invalid, .error');
        if (firstError) {
            firstError.scrollIntoView({
                behavior: 'smooth',
                block: 'center'
            });
            firstError.focus();
        }
    }

    /**
     * Get form error count
     */
    getFormErrorCount(form) {
        const formData = this.forms.get(form);
        if (!formData) return 0;

        let errorCount = 0;
        formData.fields.forEach((fieldData) => {
            errorCount += fieldData.errors.length;
        });

        return errorCount;
    }

    /**
     * Password strength calculator
     */
    calculatePasswordStrength(password) {
        let score = 0;

        if (password.length >= 8) score++;
        if (password.length >= 12) score++;
        if (/[a-z]/.test(password)) score++;
        if (/[A-Z]/.test(password)) score++;
        if (/[0-9]/.test(password)) score++;
        if (/[^A-Za-z0-9]/.test(password)) score++;

        return score;
    }

    /**
     * Credit card validation using Luhn algorithm
     */
    isValidCreditCard(number) {
        const cleaned = number.replace(/\D/g, '');
        if (cleaned.length < 13 || cleaned.length > 19) return false;

        let sum = 0;
        let isEven = false;

        for (let i = cleaned.length - 1; i >= 0; i--) {
            let digit = parseInt(cleaned[i]);

            if (isEven) {
                digit *= 2;
                if (digit > 9) {
                    digit -= 9;
                }
            }

            sum += digit;
            isEven = !isEven;
        }

        return sum % 10 === 0;
    }

    /**
     * Format file size
     */
    formatFileSize(bytes) {
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        if (bytes === 0) return '0 Bytes';

        const i = Math.floor(Math.log(bytes) / Math.log(1024));
        return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
    }

    /**
     * Debounce helper
     */
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    /**
     * Add validation styles
     */
    addValidationStyles() {
        const styles = `
            .form-validation-summary {
                background: #f8d7da;
                border: 1px solid #f5c6cb;
                color: #721c24;
                padding: 15px;
                border-radius: 8px;
                margin-bottom: 20px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            
            .form-validation-summary h4 {
                margin: 0 0 10px 0;
                font-size: 16px;
                display: flex;
                align-items: center;
                gap: 8px;
            }
            
            .form-validation-summary ul {
                margin: 0;
                padding-left: 20px;
            }
            
            .form-validation-summary li {
                margin-bottom: 5px;
            }
            
            .field-error-container {
                margin-top: 5px;
            }
            
            .field-error {
                color: #dc3545;
                font-size: 14px;
                display: flex;
                align-items: center;
                gap: 5px;
                margin-bottom: 3px;
            }
            
            .field-error:before {
                content: "âš ";
                font-size: 12px;
            }
            
            .invalid, .error {
                border-color: #dc3545 !important;
                box-shadow: 0 0 0 0.2rem rgba(220, 53, 69, 0.25) !important;
                background-color: rgba(220, 53, 69, 0.05);
            }
            
            .valid {
                border-color: #28a745 !important;
                box-shadow: 0 0 0 0.2rem rgba(40, 167, 69, 0.25) !important;
                background-color: rgba(40, 167, 69, 0.05);
            }
            
            .valid:after {
                content: "&#10003;";
                color: #28a745;
                position: absolute;
                right: 10px;
                top: 50%;
                transform: translateY(-50%);
                font-weight: bold;
            }
            
            .form-group, .field-wrapper {
                position: relative;
                margin-bottom: 1rem;
            }
            
            .password-strength-meter {
                height: 4px;
                background: #e9ecef;
                border-radius: 2px;
                margin-top: 5px;
                overflow: hidden;
            }
            
            .password-strength-fill {
                height: 100%;
                transition: width 0.3s ease, background-color 0.3s ease;
            }
            
            .strength-weak { background-color: #dc3545; width: 25%; }
            .strength-fair { background-color: #fd7e14; width: 50%; }
            .strength-good { background-color: #ffc107; width: 75%; }
            .strength-strong { background-color: #28a745; width: 100%; }
            
            @media (max-width: 768px) {
                .form-validation-summary {
                    padding: 12px;
                    font-size: 14px;
                }
                
                .field-error {
                    font-size: 13px;
                }
            }
        `;

        const styleSheet = document.createElement('style');
        styleSheet.textContent = styles;
        document.head.appendChild(styleSheet);
    }

    /**
     * Add custom validator
     */
    addValidator(name, validator) {
        this.validators.set(name, validator);
    }

    /**
     * Add custom rule
     */
    addCustomRule(name, rule) {
        this.customRules.set(name, rule);
    }

    /**
     * Get validation report
     */
    getValidationReport() {
        const report = {
            totalForms: this.forms.size,
            validForms: 0,
            invalidForms: 0,
            totalFields: 0,
            validFields: 0,
            invalidFields: 0,
            commonErrors: new Map()
        };

        this.forms.forEach((formData) => {
            if (formData.isValid) {
                report.validForms++;
            } else {
                report.invalidForms++;
            }

            formData.fields.forEach((fieldData) => {
                report.totalFields++;

                if (fieldData.isValid) {
                    report.validFields++;
                } else {
                    report.invalidFields++;

                    fieldData.errors.forEach(error => {
                        const count = report.commonErrors.get(error) || 0;
                        report.commonErrors.set(error, count + 1);
                    });
                }
            });
        });

        return report;
    }
}

// Initialize Form Validation Manager
document.addEventListener('DOMContentLoaded', () => {
    window.formValidationManager = new FormValidationManager();
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = FormValidationManager;
}