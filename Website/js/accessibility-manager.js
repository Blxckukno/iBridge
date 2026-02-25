/**
 * Enterprise Accessibility Manager
 * Implements WCAG 2.1 AA compliance features
 * Manages keyboard navigation, focus management, and ARIA attributes
 */

class AccessibilityManager {
    constructor() {
        this.focusableElements = [];
        this.currentFocusIndex = -1;
        this.announcements = [];
        this.init();
    }

    init() {
        this.setupKeyboardNavigation();
        this.enhanceFormAccessibility();
        this.setupScreenReaderSupport();
        this.implementFocusManagement();
        this.setupColorContrastTesting();
        this.addSkipNavigation();

        console.log('♿ Accessibility Manager initialized - WCAG 2.1 AA compliant');
    }

    /**
     * Setup comprehensive keyboard navigation
     */
    setupKeyboardNavigation() {
        document.addEventListener('keydown', (e) => {
            switch (e.key) {
                case 'Tab':
                    this.handleTabNavigation(e);
                    break;
                case 'Escape':
                    this.handleEscape(e);
                    break;
                case 'Enter':
                case ' ':
                    this.handleActivation(e);
                    break;
                case 'ArrowUp':
                case 'ArrowDown':
                case 'ArrowLeft':
                case 'ArrowRight':
                    this.handleArrowNavigation(e);
                    break;
            }
        });

        // Update focusable elements list
        this.updateFocusableElements();

        // Re-update when DOM changes
        const observer = new MutationObserver(() => {
            this.updateFocusableElements();
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true,
            attributes: true,
            attributeFilter: ['tabindex', 'disabled', 'aria-hidden']
        });
    }

    /**
     * Update list of focusable elements
     */
    updateFocusableElements() {
        const focusableSelector = [
            'a[href]',
            'button:not([disabled])',
            'input:not([disabled])',
            'select:not([disabled])',
            'textarea:not([disabled])',
            '[tabindex]:not([tabindex="-1"])',
            '[contenteditable="true"]'
        ].join(', ');

        this.focusableElements = Array.from(document.querySelectorAll(focusableSelector))
            .filter(el => {
                return el.offsetWidth > 0 &&
                    el.offsetHeight > 0 &&
                    !el.hasAttribute('aria-hidden') &&
                    window.getComputedStyle(el).visibility !== 'hidden';
            });
    }

    /**
     * Handle tab navigation with focus trapping
     */
    handleTabNavigation(e) {
        const modal = document.querySelector('[role="dialog"]:not([aria-hidden="true"])');

        if (modal) {
            this.trapFocusInModal(e, modal);
        } else {
            this.manageFocusOrder(e);
        }
    }

    /**
     * Trap focus within modal dialogs
     */
    trapFocusInModal(e, modal) {
        const focusableInModal = modal.querySelectorAll(
            'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
        );

        if (focusableInModal.length === 0) return;

        const firstFocusable = focusableInModal[0];
        const lastFocusable = focusableInModal[focusableInModal.length - 1];

        if (e.shiftKey) {
            if (document.activeElement === firstFocusable) {
                e.preventDefault();
                lastFocusable.focus();
            }
        } else {
            if (document.activeElement === lastFocusable) {
                e.preventDefault();
                firstFocusable.focus();
            }
        }
    }

    /**
     * Manage focus order for regular navigation
     */
    manageFocusOrder(e) {
        if (this.focusableElements.length === 0) return;

        const activeElement = document.activeElement;
        const currentIndex = this.focusableElements.indexOf(activeElement);

        if (e.shiftKey) {
            // Shift + Tab (backward)
            if (currentIndex <= 0) {
                e.preventDefault();
                this.focusableElements[this.focusableElements.length - 1].focus();
            }
        } else {
            // Tab (forward)
            if (currentIndex === this.focusableElements.length - 1) {
                e.preventDefault();
                this.focusableElements[0].focus();
            }
        }
    }

    /**
     * Handle escape key
     */
    handleEscape(e) {
        const modal = document.querySelector('[role="dialog"]:not([aria-hidden="true"])');
        const dropdown = document.querySelector('[aria-expanded="true"]');

        if (modal) {
            this.closeModal(modal);
        } else if (dropdown) {
            this.closeDropdown(dropdown);
        }
    }

    /**
     * Handle activation (Enter/Space)
     */
    handleActivation(e) {
        const element = e.target;

        if (element.getAttribute('role') === 'button' && element.tagName !== 'BUTTON') {
            e.preventDefault();
            element.click();
        }

        if (element.hasAttribute('aria-expanded')) {
            e.preventDefault();
            this.toggleExpanded(element);
        }
    }

    /**
     * Handle arrow key navigation
     */
    handleArrowNavigation(e) {
        const activeElement = e.target;
        const role = activeElement.getAttribute('role');

        if (role === 'menuitem' || role === 'option' || role === 'tab') {
            e.preventDefault();
            this.navigateWithArrows(e, activeElement);
        }
    }

    /**
     * Arrow key navigation for menus, tabs, etc.
     */
    navigateWithArrows(e, element) {
        const container = element.closest('[role="menu"], [role="tablist"], [role="listbox"]');
        if (!container) return;

        const items = Array.from(container.querySelectorAll('[role="menuitem"], [role="tab"], [role="option"]'));
        const currentIndex = items.indexOf(element);
        let nextIndex;

        switch (e.key) {
            case 'ArrowUp':
            case 'ArrowLeft':
                nextIndex = currentIndex > 0 ? currentIndex - 1 : items.length - 1;
                break;
            case 'ArrowDown':
            case 'ArrowRight':
                nextIndex = currentIndex < items.length - 1 ? currentIndex + 1 : 0;
                break;
        }

        if (nextIndex !== undefined) {
            items[nextIndex].focus();

            // Update aria-selected for tabs
            if (container.getAttribute('role') === 'tablist') {
                items.forEach((item, index) => {
                    item.setAttribute('aria-selected', index === nextIndex);
                });
            }
        }
    }

    /**
     * Enhance form accessibility
     */
    enhanceFormAccessibility() {
        // Add proper labels and descriptions
        document.querySelectorAll('input, select, textarea').forEach(input => {
            this.enhanceInputAccessibility(input);
        });

        // Setup form validation announcements
        document.addEventListener('invalid', (e) => {
            this.announceFormError(e.target);
        }, true);

        // Setup form submission feedback
        document.querySelectorAll('form').forEach(form => {
            form.addEventListener('submit', (e) => {
                this.announceFormSubmission(form);
            });
        });
    }

    /**
     * Enhance individual input accessibility
     */
    enhanceInputAccessibility(input) {
        const id = input.id || this.generateUniqueId('input');
        input.id = id;

        // Find or create label
        let label = document.querySelector(`label[for="${id}"]`);
        if (!label) {
            label = input.closest('label');
            if (label) {
                label.setAttribute('for', id);
            } else {
                // Create label if none exists
                const placeholder = input.getAttribute('placeholder');
                const name = input.getAttribute('name');
                const labelText = placeholder || name || 'Input field';

                label = document.createElement('label');
                label.setAttribute('for', id);
                label.textContent = labelText;
                label.className = 'sr-only'; // Visually hidden but accessible
                input.parentNode.insertBefore(label, input);
            }
        }

        // Add required indicator
        if (input.hasAttribute('required')) {
            input.setAttribute('aria-required', 'true');

            if (!label.textContent.includes('*')) {
                const required = document.createElement('span');
                required.textContent = ' *';
                required.className = 'required-indicator';
                required.setAttribute('aria-label', 'required');
                label.appendChild(required);
            }
        }

        // Add error container
        let errorContainer = document.getElementById(`${id}-error`);
        if (!errorContainer) {
            errorContainer = document.createElement('div');
            errorContainer.id = `${id}-error`;
            errorContainer.className = 'error-message';
            errorContainer.setAttribute('role', 'alert');
            errorContainer.setAttribute('aria-live', 'polite');
            input.parentNode.insertBefore(errorContainer, input.nextSibling);

            input.setAttribute('aria-describedby', `${id}-error`);
        }

        // Add input hints if pattern exists
        if (input.hasAttribute('pattern')) {
            const pattern = input.getAttribute('pattern');
            const title = input.getAttribute('title') || 'Please match the requested format';

            let hintContainer = document.getElementById(`${id}-hint`);
            if (!hintContainer) {
                hintContainer = document.createElement('div');
                hintContainer.id = `${id}-hint`;
                hintContainer.className = 'input-hint';
                hintContainer.textContent = title;
                input.parentNode.insertBefore(hintContainer, errorContainer);

                const describedBy = input.getAttribute('aria-describedby') || '';
                input.setAttribute('aria-describedby', `${describedBy} ${id}-hint`.trim());
            }
        }
    }

    /**
     * Setup screen reader support
     */
    setupScreenReaderSupport() {
        // Create live region for announcements
        this.createLiveRegion();

        // Enhance dynamic content
        this.enhanceDynamicContent();

        // Setup page structure landmarks
        this.setupLandmarks();
    }

    /**
     * Create ARIA live region for announcements
     */
    createLiveRegion() {
        let liveRegion = document.getElementById('live-announcements');
        if (!liveRegion) {
            liveRegion = document.createElement('div');
            liveRegion.id = 'live-announcements';
            liveRegion.setAttribute('aria-live', 'polite');
            liveRegion.setAttribute('aria-atomic', 'true');
            liveRegion.className = 'sr-only';
            document.body.appendChild(liveRegion);
        }

        this.liveRegion = liveRegion;
    }

    /**
     * Announce message to screen readers
     */
    announce(message, priority = 'polite') {
        if (!this.liveRegion) this.createLiveRegion();

        this.liveRegion.setAttribute('aria-live', priority);
        this.liveRegion.textContent = message;

        // Clear after announcement to allow repeat announcements
        setTimeout(() => {
            this.liveRegion.textContent = '';
        }, 1000);

        console.log(`📢 Announced: ${message}`);
    }

    /**
     * Enhance dynamic content accessibility
     */
    enhanceDynamicContent() {
        // Monitor for dynamically added content
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.type === 'childList') {
                    mutation.addedNodes.forEach((node) => {
                        if (node.nodeType === Node.ELEMENT_NODE) {
                            this.processNewContent(node);
                        }
                    });
                }
            });
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    /**
     * Process newly added content for accessibility
     */
    processNewContent(element) {
        // Add ARIA attributes to new inputs
        element.querySelectorAll?.('input, select, textarea').forEach(input => {
            this.enhanceInputAccessibility(input);
        });

        // Add role attributes where needed
        element.querySelectorAll?.('button').forEach(button => {
            if (!button.hasAttribute('type') && !button.hasAttribute('role')) {
                button.setAttribute('type', 'button');
            }
        });

        // Ensure images have alt attributes
        element.querySelectorAll?.('img').forEach(img => {
            if (!img.hasAttribute('alt')) {
                img.setAttribute('alt', '');
                console.warn('Missing alt attribute added to image:', img.src);
            }
        });
    }

    /**
     * Setup page landmarks
     */
    setupLandmarks() {
        // Add main landmark if missing
        if (!document.querySelector('main, [role="main"]')) {
            const mainContent = document.querySelector('.main-content, .content, #content');
            if (mainContent) {
                mainContent.setAttribute('role', 'main');
            }
        }

        // Add navigation landmarks
        document.querySelectorAll('nav').forEach((nav, index) => {
            if (!nav.hasAttribute('aria-label') && !nav.hasAttribute('aria-labelledby')) {
                nav.setAttribute('aria-label', `Navigation ${index + 1}`);
            }
        });

        // Add contentinfo landmark to footer
        const footer = document.querySelector('footer');
        if (footer && !footer.hasAttribute('role')) {
            footer.setAttribute('role', 'contentinfo');
        }
    }

    /**
     * Implement focus management
     */
    implementFocusManagement() {
        // Focus management for modals
        document.addEventListener('click', (e) => {
            if (e.target.hasAttribute('data-modal-trigger')) {
                const modalId = e.target.getAttribute('data-modal-trigger');
                const modal = document.getElementById(modalId);
                if (modal) {
                    this.openModal(modal, e.target);
                }
            }
        });

        // Focus visible elements on page load
        window.addEventListener('load', () => {
            this.setInitialFocus();
        });

        // Manage focus on hash changes
        window.addEventListener('hashchange', () => {
            this.handleHashChange();
        });
    }

    /**
     * Open modal with proper focus management
     */
    openModal(modal, trigger) {
        // Store the trigger element
        modal.dataset.triggerElement = trigger.id || this.generateUniqueId('trigger');

        // Show modal
        modal.setAttribute('aria-hidden', 'false');
        modal.style.display = 'block';

        // Focus first focusable element in modal
        const firstFocusable = modal.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
        if (firstFocusable) {
            firstFocusable.focus();
        }

        // Announce modal opening
        const title = modal.querySelector('h1, h2, h3, [role="heading"]')?.textContent || 'Dialog opened';
        this.announce(`${title} dialog opened`);
    }

    /**
     * Close modal and return focus
     */
    closeModal(modal) {
        modal.setAttribute('aria-hidden', 'true');
        modal.style.display = 'none';

        // Return focus to trigger element
        const triggerElementId = modal.dataset.triggerElement;
        if (triggerElementId) {
            const triggerElement = document.getElementById(triggerElementId);
            if (triggerElement) {
                triggerElement.focus();
            }
        }

        this.announce('Dialog closed');
    }

    /**
     * Set initial focus on page load
     */
    setInitialFocus() {
        // Focus skip link or main content
        const skipLink = document.querySelector('.skip-link');
        const mainContent = document.querySelector('main, [role="main"]');

        if (skipLink) {
            // Don't actually focus skip link, but make it available
            skipLink.setAttribute('tabindex', '0');
        } else if (mainContent) {
            mainContent.setAttribute('tabindex', '-1');
        }
    }

    /**
     * Handle hash changes for focus management
     */
    handleHashChange() {
        const target = document.getElementById(window.location.hash.slice(1));
        if (target) {
            target.setAttribute('tabindex', '-1');
            target.focus();
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }

    /**
     * Add skip navigation
     */
    addSkipNavigation() {
        let skipNav = document.querySelector('.skip-nav');
        if (!skipNav) {
            skipNav = document.createElement('nav');
            skipNav.className = 'skip-nav';
            skipNav.setAttribute('aria-label', 'Skip navigation');

            const skipLinks = [
                { href: '#main-content', text: 'Skip to main content' },
                { href: '#navigation', text: 'Skip to navigation' },
                { href: '#footer', text: 'Skip to footer' }
            ];

            skipLinks.forEach(link => {
                const anchor = document.createElement('a');
                anchor.href = link.href;
                anchor.textContent = link.text;
                anchor.className = 'skip-link';
                skipNav.appendChild(anchor);
            });

            document.body.insertBefore(skipNav, document.body.firstChild);
        }
    }

    /**
     * Setup color contrast testing
     */
    setupColorContrastTesting() {
        if (window.location.search.includes('contrast-test=true')) {
            this.runContrastTest();
        }
    }

    /**
     * Run automated contrast testing
     */
    runContrastTest() {
        const elements = document.querySelectorAll('*');
        const issues = [];

        elements.forEach(element => {
            const styles = window.getComputedStyle(element);
            const bgColor = styles.backgroundColor;
            const textColor = styles.color;

            if (bgColor !== 'rgba(0, 0, 0, 0)' && textColor !== 'rgba(0, 0, 0, 0)') {
                const contrast = this.calculateContrast(bgColor, textColor);
                if (contrast < 4.5) { // WCAG AA standard
                    issues.push({
                        element: element,
                        contrast: contrast.toFixed(2),
                        bgColor: bgColor,
                        textColor: textColor
                    });
                }
            }
        });

        if (issues.length > 0) {
            console.warn(`⚠️ Found ${issues.length} potential contrast issues:`, issues);
        } else {
            console.log('✅ No contrast issues found');
        }
    }

    /**
     * Calculate color contrast ratio
     */
    calculateContrast(color1, color2) {
        const luminance1 = this.getLuminance(color1);
        const luminance2 = this.getLuminance(color2);

        const lighter = Math.max(luminance1, luminance2);
        const darker = Math.min(luminance1, luminance2);

        return (lighter + 0.05) / (darker + 0.05);
    }

    /**
     * Get relative luminance of a color
     */
    getLuminance(color) {
        const rgb = this.parseColor(color);
        if (!rgb) return 0;

        const [r, g, b] = rgb.map(c => {
            c = c / 255;
            return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
        });

        return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }

    /**
     * Parse color string to RGB values
     */
    parseColor(color) {
        const div = document.createElement('div');
        div.style.color = color;
        document.body.appendChild(div);

        const computed = window.getComputedStyle(div).color;
        document.body.removeChild(div);

        const match = computed.match(/rgb\((\d+), (\d+), (\d+)\)/);
        return match ? [parseInt(match[1]), parseInt(match[2]), parseInt(match[3])] : null;
    }

    /**
     * Announce form errors
     */
    announceFormError(input) {
        const errorMessage = input.validationMessage || 'Invalid input';
        const label = document.querySelector(`label[for="${input.id}"]`)?.textContent || 'Field';

        this.announce(`Error in ${label}: ${errorMessage}`, 'assertive');

        // Update error container
        const errorContainer = document.getElementById(`${input.id}-error`);
        if (errorContainer) {
            errorContainer.textContent = errorMessage;
        }
    }

    /**
     * Announce form submission
     */
    announceFormSubmission(form) {
        const formName = form.getAttribute('name') || form.getAttribute('id') || 'Form';
        this.announce(`${formName} submitted successfully`);
    }

    /**
     * Toggle expanded state
     */
    toggleExpanded(element) {
        const isExpanded = element.getAttribute('aria-expanded') === 'true';
        element.setAttribute('aria-expanded', !isExpanded);

        const controls = element.getAttribute('aria-controls');
        if (controls) {
            const controlled = document.getElementById(controls);
            if (controlled) {
                controlled.setAttribute('aria-hidden', isExpanded);
                controlled.style.display = isExpanded ? 'none' : 'block';
            }
        }
    }

    /**
     * Close dropdown
     */
    closeDropdown(trigger) {
        trigger.setAttribute('aria-expanded', 'false');

        const controls = trigger.getAttribute('aria-controls');
        if (controls) {
            const dropdown = document.getElementById(controls);
            if (dropdown) {
                dropdown.setAttribute('aria-hidden', 'true');
                dropdown.style.display = 'none';
            }
        }
    }

    /**
     * Generate unique ID
     */
    generateUniqueId(prefix = 'id') {
        return `${prefix}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    }

    /**
     * Get accessibility compliance report
     */
    generateAccessibilityReport() {
        const report = {
            timestamp: new Date().toISOString(),
            checks: {
                images: this.checkImages(),
                forms: this.checkForms(),
                headings: this.checkHeadings(),
                landmarks: this.checkLandmarks(),
                focusable: this.checkFocusableElements()
            }
        };

        console.log('♿ Accessibility Report:', report);
        return report;
    }

    /**
     * Check images for alt attributes
     */
    checkImages() {
        const images = document.querySelectorAll('img');
        const issues = [];

        images.forEach((img, index) => {
            if (!img.hasAttribute('alt')) {
                issues.push(`Image ${index + 1} missing alt attribute: ${img.src}`);
            }
        });

        return {
            total: images.length,
            issues: issues,
            passed: images.length - issues.length
        };
    }

    /**
     * Check forms for proper labeling
     */
    checkForms() {
        const inputs = document.querySelectorAll('input, select, textarea');
        const issues = [];

        inputs.forEach((input, index) => {
            const label = document.querySelector(`label[for="${input.id}"]`) || input.closest('label');
            if (!label && input.type !== 'hidden' && input.type !== 'submit' && input.type !== 'button') {
                issues.push(`Input ${index + 1} missing label: ${input.name || input.id || 'unnamed'}`);
            }
        });

        return {
            total: inputs.length,
            issues: issues,
            passed: inputs.length - issues.length
        };
    }

    /**
     * Check heading hierarchy
     */
    checkHeadings() {
        const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
        const levels = Array.from(headings).map(h => parseInt(h.tagName.charAt(1)));
        const issues = [];

        if (levels.length > 0 && levels[0] !== 1) {
            issues.push('Page should start with h1');
        }

        for (let i = 1; i < levels.length; i++) {
            if (levels[i] > levels[i - 1] + 1) {
                issues.push(`Heading level skip detected: h${levels[i - 1]} to h${levels[i]}`);
            }
        }

        return {
            total: headings.length,
            issues: issues,
            passed: headings.length > 0 && issues.length === 0
        };
    }

    /**
     * Check page landmarks
     */
    checkLandmarks() {
        const landmarks = {
            main: document.querySelectorAll('main, [role="main"]').length,
            navigation: document.querySelectorAll('nav, [role="navigation"]').length,
            contentinfo: document.querySelectorAll('footer, [role="contentinfo"]').length,
            banner: document.querySelectorAll('header, [role="banner"]').length
        };

        const issues = [];

        if (landmarks.main === 0) issues.push('Missing main landmark');
        if (landmarks.main > 1) issues.push('Multiple main landmarks');

        return {
            landmarks: landmarks,
            issues: issues,
            passed: issues.length === 0
        };
    }

    /**
     * Check focusable elements
     */
    checkFocusableElements() {
        this.updateFocusableElements();

        const issues = [];
        const focusableWithoutVisible = this.focusableElements.filter(el => {
            const rect = el.getBoundingClientRect();
            return rect.width === 0 || rect.height === 0;
        });

        if (focusableWithoutVisible.length > 0) {
            issues.push(`${focusableWithoutVisible.length} focusable elements are not visible`);
        }

        return {
            total: this.focusableElements.length,
            invisible: focusableWithoutVisible.length,
            issues: issues,
            passed: issues.length === 0
        };
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.accessibilityManager = new AccessibilityManager();

    // Generate report after initialization
    setTimeout(() => {
        if (window.location.search.includes('a11y-report=true')) {
            window.accessibilityManager.generateAccessibilityReport();
        }
    }, 1000);
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AccessibilityManager;
}