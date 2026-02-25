// Accessibility Features JavaScript
// iBridge Contact Solutions - Accessibility enhancements

class AccessibilityFeatures {
    constructor() {
        this.settings = {
            highContrast: false,
            largeText: false,
            reducedMotion: false,
            focusVisible: true
        };

        this.init();
    }

    init() {
        this.setupKeyboardNavigation();
        this.setupFocusManagement();
        this.setupARIAEnhancements();
        this.setupAccessibilityControls();
        this.setupScreenReaderSupport();
        this.detectUserPreferences();
    }

    setupKeyboardNavigation() {
        // Skip links functionality
        const skipLinks = document.querySelectorAll('.skip-link');
        skipLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const target = document.querySelector(link.getAttribute('href'));
                if (target) {
                    target.focus();
                    target.scrollIntoView({ behavior: 'smooth' });
                }
            });
        });

        // Enhanced keyboard navigation for interactive elements
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Tab') {
                this.handleTabNavigation(e);
            }

            if (e.key === 'Escape') {
                this.handleEscapeKey(e);
            }
        });
    }

    handleTabNavigation(e) {
        // Ensure proper tab order and focus visibility
        const focusableElements = this.getFocusableElements();
        const currentIndex = focusableElements.indexOf(document.activeElement);

        if (e.shiftKey && currentIndex === 0) {
            // Wrap to last element when shift+tab on first element
            e.preventDefault();
            focusableElements[focusableElements.length - 1].focus();
        } else if (!e.shiftKey && currentIndex === focusableElements.length - 1) {
            // Wrap to first element when tab on last element
            e.preventDefault();
            focusableElements[0].focus();
        }
    }

    handleEscapeKey(e) {
        // Close any open modals, dropdowns, or overlays
        const openModals = document.querySelectorAll('.modal.active, .dropdown.active, .overlay.active');
        openModals.forEach(modal => {
            modal.classList.remove('active');

            // Return focus to trigger element if available
            const trigger = modal.getAttribute('data-trigger');
            if (trigger) {
                const triggerElement = document.querySelector(trigger);
                if (triggerElement) {
                    triggerElement.focus();
                }
            }
        });
    }

    getFocusableElements() {
        const selector = 'a[href], button, input, textarea, select, details, [tabindex]:not([tabindex="-1"])';
        return Array.from(document.querySelectorAll(selector)).filter(el => {
            return el.offsetWidth > 0 && el.offsetHeight > 0 && !el.disabled;
        });
    }

    setupFocusManagement() {
        // Enhanced focus indicators
        document.addEventListener('focusin', (e) => {
            this.addFocusIndicator(e.target);
        });

        document.addEventListener('focusout', (e) => {
            this.removeFocusIndicator(e.target);
        });

        // Mouse vs keyboard focus differentiation
        document.addEventListener('mousedown', () => {
            document.body.classList.add('mouse-user');
        });

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Tab') {
                document.body.classList.remove('mouse-user');
            }
        });
    }

    addFocusIndicator(element) {
        if (!document.body.classList.contains('mouse-user')) {
            element.classList.add('keyboard-focus');
        }
    }

    removeFocusIndicator(element) {
        element.classList.remove('keyboard-focus');
    }

    setupARIAEnhancements() {
        // Dynamic ARIA labels for interactive elements
        const buttons = document.querySelectorAll('button:not([aria-label])');
        buttons.forEach(button => {
            if (!button.getAttribute('aria-label') && button.textContent.trim()) {
                button.setAttribute('aria-label', button.textContent.trim());
            }
        });

        // ARIA live regions for dynamic content
        this.createLiveRegion();

        // Enhanced form accessibility
        this.enhanceFormAccessibility();

        // Navigation landmarks
        this.addNavigationLandmarks();
    }

    createLiveRegion() {
        if (!document.querySelector('.sr-live-region')) {
            const liveRegion = document.createElement('div');
            liveRegion.className = 'sr-live-region';
            liveRegion.setAttribute('aria-live', 'polite');
            liveRegion.setAttribute('aria-atomic', 'true');
            liveRegion.style.cssText = `
                position: absolute;
                left: -10000px;
                width: 1px;
                height: 1px;
                overflow: hidden;
            `;
            document.body.appendChild(liveRegion);
        }
    }

    announceToScreenReader(message, priority = 'polite') {
        const liveRegion = document.querySelector('.sr-live-region');
        if (liveRegion) {
            liveRegion.setAttribute('aria-live', priority);
            liveRegion.textContent = message;

            // Clear after announcement
            setTimeout(() => {
                liveRegion.textContent = '';
            }, 1000);
        }
    }

    enhanceFormAccessibility() {
        const forms = document.querySelectorAll('form');
        forms.forEach(form => {
            // Associate labels with inputs
            const inputs = form.querySelectorAll('input, textarea, select');
            inputs.forEach(input => {
                if (!input.getAttribute('aria-label') && !input.getAttribute('aria-labelledby')) {
                    const label = form.querySelector(`label[for="${input.id}"]`);
                    if (label) {
                        input.setAttribute('aria-labelledby', label.id || this.generateId('label'));
                        if (!label.id) {
                            label.id = input.getAttribute('aria-labelledby');
                        }
                    }
                }

                // Add required indicators
                if (input.required && !input.getAttribute('aria-required')) {
                    input.setAttribute('aria-required', 'true');
                }
            });

            // Form validation messages
            form.addEventListener('submit', (e) => {
                this.handleFormValidation(form, e);
            });
        });
    }

    handleFormValidation(form, event) {
        const invalidInputs = form.querySelectorAll(':invalid');
        if (invalidInputs.length > 0) {
            event.preventDefault();

            // Focus first invalid input
            invalidInputs[0].focus();

            // Announce validation errors
            const errorCount = invalidInputs.length;
            this.announceToScreenReader(
                `Form has ${errorCount} validation ${errorCount === 1 ? 'error' : 'errors'}. Please correct and try again.`,
                'assertive'
            );
        }
    }

    addNavigationLandmarks() {
        // Add navigation landmarks if missing
        const nav = document.querySelector('nav:not([role])');
        if (nav) {
            nav.setAttribute('role', 'navigation');
            nav.setAttribute('aria-label', 'Main navigation');
        }

        const main = document.querySelector('main:not([role])');
        if (main) {
            main.setAttribute('role', 'main');
        }

        const footer = document.querySelector('footer:not([role])');
        if (footer) {
            footer.setAttribute('role', 'contentinfo');
        }
    }

    setupAccessibilityControls() {
        // Create accessibility control panel
        this.createAccessibilityPanel();

        // Keyboard shortcut for accessibility panel
        document.addEventListener('keydown', (e) => {
            if (e.altKey && e.key === 'a') {
                e.preventDefault();
                this.toggleAccessibilityPanel();
            }
        });
    }

    createAccessibilityPanel() {
        const panel = document.createElement('div');
        panel.className = 'accessibility-panel';
        panel.innerHTML = `
            <button class="accessibility-toggle" aria-label="Accessibility options" title="Press Alt+A to open">
                <i class="fas fa-universal-access"></i>
            </button>
            <div class="accessibility-options">
                <h3>Accessibility Options</h3>
                <div class="option">
                    <label>
                        <input type="checkbox" id="high-contrast"> High Contrast
                    </label>
                </div>
                <div class="option">
                    <label>
                        <input type="checkbox" id="large-text"> Large Text
                    </label>
                </div>
                <div class="option">
                    <label>
                        <input type="checkbox" id="reduced-motion"> Reduce Motion
                    </label>
                </div>
                <button class="reset-settings">Reset Settings</button>
            </div>
        `;

        document.body.appendChild(panel);
        this.setupPanelEventListeners(panel);
    }

    setupPanelEventListeners(panel) {
        const toggle = panel.querySelector('.accessibility-toggle');
        const options = panel.querySelector('.accessibility-options');
        const checkboxes = panel.querySelectorAll('input[type="checkbox"]');
        const resetBtn = panel.querySelector('.reset-settings');

        toggle.addEventListener('click', () => {
            this.toggleAccessibilityPanel();
        });

        checkboxes.forEach(checkbox => {
            checkbox.addEventListener('change', (e) => {
                this.handleSettingChange(e.target.id, e.target.checked);
            });
        });

        resetBtn.addEventListener('click', () => {
            this.resetAccessibilitySettings();
        });

        // Close panel when clicking outside
        document.addEventListener('click', (e) => {
            if (!panel.contains(e.target)) {
                options.style.display = 'none';
            }
        });
    }

    toggleAccessibilityPanel() {
        const options = document.querySelector('.accessibility-options');
        const isVisible = options.style.display === 'block';
        options.style.display = isVisible ? 'none' : 'block';

        if (!isVisible) {
            // Focus first checkbox when opening
            const firstCheckbox = options.querySelector('input[type="checkbox"]');
            if (firstCheckbox) {
                setTimeout(() => firstCheckbox.focus(), 100);
            }
        }
    }

    handleSettingChange(setting, enabled) {
        switch (setting) {
            case 'high-contrast':
                this.toggleHighContrast(enabled);
                break;
            case 'large-text':
                this.toggleLargeText(enabled);
                break;
            case 'reduced-motion':
                this.toggleReducedMotion(enabled);
                break;
        }

        // Save settings
        this.settings[setting.replace('-', '')] = enabled;
        localStorage.setItem('accessibilitySettings', JSON.stringify(this.settings));

        // Announce change
        this.announceToScreenReader(`${setting.replace('-', ' ')} ${enabled ? 'enabled' : 'disabled'}`);
    }

    toggleHighContrast(enabled) {
        document.body.classList.toggle('high-contrast', enabled);
    }

    toggleLargeText(enabled) {
        document.body.classList.toggle('large-text', enabled);
    }

    toggleReducedMotion(enabled) {
        document.body.classList.toggle('reduced-motion', enabled);
    }

    resetAccessibilitySettings() {
        // Reset all settings
        Object.keys(this.settings).forEach(key => {
            this.settings[key] = false;
        });

        // Update UI
        const checkboxes = document.querySelectorAll('.accessibility-panel input[type="checkbox"]');
        checkboxes.forEach(checkbox => {
            checkbox.checked = false;
        });

        // Remove classes
        document.body.classList.remove('high-contrast', 'large-text', 'reduced-motion');

        // Clear storage
        localStorage.removeItem('accessibilitySettings');

        this.announceToScreenReader('Accessibility settings reset to default');
    }

    detectUserPreferences() {
        // Detect system preferences
        if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
            this.settings.reducedMotion = true;
            this.toggleReducedMotion(true);
        }

        if (window.matchMedia('(prefers-contrast: high)').matches) {
            this.settings.highContrast = true;
            this.toggleHighContrast(true);
        }

        // Load saved settings
        const savedSettings = localStorage.getItem('accessibilitySettings');
        if (savedSettings) {
            this.settings = { ...this.settings, ...JSON.parse(savedSettings) };
            this.applySettings();
        }
    }

    applySettings() {
        // Apply saved settings
        if (this.settings.highContrast) this.toggleHighContrast(true);
        if (this.settings.largeText) this.toggleLargeText(true);
        if (this.settings.reducedMotion) this.toggleReducedMotion(true);

        // Update checkboxes
        Object.keys(this.settings).forEach(key => {
            const checkbox = document.querySelector(`#${key.replace(/([A-Z])/g, '-$1').toLowerCase()}`);
            if (checkbox) {
                checkbox.checked = this.settings[key];
            }
        });
    }

    setupScreenReaderSupport() {
        // Enhanced screen reader support
        document.addEventListener('DOMContentLoaded', () => {
            this.announceToScreenReader('Page loaded. Press Alt+A for accessibility options.');
        });

        // Announce route changes for SPAs
        let currentURL = window.location.href;
        const observer = new MutationObserver(() => {
            if (window.location.href !== currentURL) {
                currentURL = window.location.href;
                this.announceToScreenReader('Page content updated');
            }
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    generateId(prefix = 'id') {
        return `${prefix}-${Math.random().toString(36).substr(2, 9)}`;
    }
}

// Initialize accessibility features
document.addEventListener('DOMContentLoaded', () => {
    new AccessibilityFeatures();
});

// Add accessibility styles
const accessibilityStyles = `
    .keyboard-focus {
        outline: 3px solid var(--primary-color, #A1C44F) !important;
        outline-offset: 2px !important;
    }
    
    .mouse-user *:focus {
        outline: none !important;
    }
    
    .accessibility-panel {
        position: fixed;
        bottom: 100px;
        right: 20px;
        z-index: 1000;
    }
    
    .accessibility-toggle {
        width: 50px;
        height: 50px;
        border-radius: 50%;
        background: var(--primary-color, #A1C44F);
        color: white;
        border: none;
        font-size: 1.5rem;
        cursor: pointer;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        transition: all 0.3s ease;
    }
    
    .accessibility-toggle:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 16px rgba(0, 0, 0, 0.2);
    }
    
    .accessibility-options {
        display: none;
        position: absolute;
        bottom: 60px;
        right: 0;
        background: white;
        border-radius: 8px;
        box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
        padding: 1.5rem;
        min-width: 250px;
        border: 1px solid #e0e0e0;
    }
    
    .accessibility-options h3 {
        margin: 0 0 1rem 0;
        font-size: 1.1rem;
        color: var(--text-dark, #333);
    }
    
    .accessibility-options .option {
        margin-bottom: 1rem;
    }
    
    .accessibility-options label {
        display: flex;
        align-items: center;
        cursor: pointer;
        font-size: 0.9rem;
        color: var(--text-dark, #333);
    }
    
    .accessibility-options input[type="checkbox"] {
        margin-right: 0.5rem;
        transform: scale(1.2);
    }
    
    .reset-settings {
        background: #f44336;
        color: white;
        border: none;
        padding: 0.5rem 1rem;
        border-radius: 4px;
        cursor: pointer;
        font-size: 0.9rem;
        transition: background 0.3s ease;
    }
    
    .reset-settings:hover {
        background: #d32f2f;
    }
    
    /* High contrast mode */
    .high-contrast {
        filter: contrast(150%) !important;
    }
    
    .high-contrast * {
        border-color: #000 !important;
        color: #000 !important;
        background-color: #fff !important;
    }
    
    .high-contrast a {
        color: #00f !important;
        text-decoration: underline !important;
    }
    
    .high-contrast button,
    .high-contrast .btn {
        background-color: #000 !important;
        color: #fff !important;
        border: 2px solid #000 !important;
    }
    
    /* Large text mode */
    .large-text {
        font-size: 1.25em !important;
    }
    
    .large-text * {
        font-size: inherit !important;
        line-height: 1.6 !important;
    }
    
    /* Reduced motion mode */
    .reduced-motion *,
    .reduced-motion *::before,
    .reduced-motion *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
        scroll-behavior: auto !important;
    }
    
    /* Screen reader only content */
    .sr-only {
        position: absolute !important;
        width: 1px !important;
        height: 1px !important;
        padding: 0 !important;
        margin: -1px !important;
        overflow: hidden !important;
        clip: rect(0, 0, 0, 0) !important;
        white-space: nowrap !important;
        border: 0 !important;
    }
    
    @media (max-width: 768px) {
        .accessibility-panel {
            bottom: 80px;
            right: 15px;
        }
        
        .accessibility-toggle {
            width: 45px;
            height: 45px;
            font-size: 1.25rem;
        }
        
        .accessibility-options {
            min-width: 200px;
            padding: 1rem;
        }
    }
`;

const accessibilityStyleSheet = document.createElement('style');
accessibilityStyleSheet.textContent = accessibilityStyles;
document.head.appendChild(accessibilityStyleSheet);
