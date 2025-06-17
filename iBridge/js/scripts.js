// Wait for DOM to be fully loaded
document.addEventListener('DOMContentLoaded', () => {
    // Initialize all components
    initializeNavigation();
    initializeAnimations();
    initializeTestimonials();
    initializeCounters();
    initializeForms();
    initializeScrollToTop();
    checkBrowserCompatibility();
    initializeCSRF();
});

// Navigation functionality
function initializeNavigation() {
    const header = document.querySelector('header');
    const mobileMenuBtn = document.getElementById('mobileMenuBtn');
    const mainMenu = document.getElementById('mainMenu');
    let lastScroll = 0;

    // Mobile menu toggle with improved animation
    if (mobileMenuBtn && mainMenu) {
        mobileMenuBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            mobileMenuBtn.classList.toggle('active');
            mainMenu.classList.toggle('show');
            document.body.classList.toggle('menu-open');
        });

        // Close menu when clicking outside
        document.addEventListener('click', (e) => {
            if (mainMenu.classList.contains('show') && !mainMenu.contains(e.target) && e.target !== mobileMenuBtn) {
                mainMenu.classList.remove('show');
                mobileMenuBtn.classList.remove('active');
                document.body.classList.remove('menu-open');
            }
        });
    }

    // Smooth header scroll behavior
    window.addEventListener('scroll', () => {
        const currentScroll = window.pageYOffset;
        
        if (currentScroll <= 0) {
            header.classList.remove('scroll-up');
            return;
        }
        
        if (currentScroll > lastScroll && !header.classList.contains('scroll-down')) {
            header.classList.remove('scroll-up');
            header.classList.add('scroll-down');
        } else if (currentScroll < lastScroll && header.classList.contains('scroll-down')) {
            header.classList.remove('scroll-down');
            header.classList.add('scroll-up');
        }
        lastScroll = currentScroll;
    });

    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                e.preventDefault();
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
                // Close mobile menu if open
                mainMenu.classList.remove('show');
                mobileMenuBtn.classList.remove('active');
            }
        });
    });

    // Active section highlighting
    const sections = document.querySelectorAll('section[id]');
    window.addEventListener('scroll', () => {
        const scrollPos = window.pageYOffset + 82; // Header height offset

        sections.forEach(section => {
            const top = section.offsetTop;
            const bottom = top + section.offsetHeight;

            if (scrollPos >= top && scrollPos <= bottom) {
                document.querySelector(`nav a[href="#${section.id}"]`)?.classList.add('active');
            } else {
                document.querySelector(`nav a[href="#${section.id}"]`)?.classList.remove('active');
            }
        });
    });
}

// Animations
function initializeAnimations() {
    const animatedElements = document.querySelectorAll('.fade-in, .slide-in');
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
            }
        });
    }, { threshold: 0.1 });

    animatedElements.forEach(element => observer.observe(element));
}

// Testimonials slider
function initializeTestimonials() {
    const testimonials = document.querySelectorAll('.testimonial-item');
    const prevBtn = document.querySelector('.testimonial-prev');
    const nextBtn = document.querySelector('.testimonial-next');
    let currentIndex = 0;

    function showTestimonial(index) {
        testimonials.forEach(item => item.classList.remove('active'));
        testimonials[index].classList.add('active');
    }

    if (prevBtn && nextBtn && testimonials.length > 0) {
        prevBtn.addEventListener('click', () => {
            currentIndex = (currentIndex - 1 + testimonials.length) % testimonials.length;
            showTestimonial(currentIndex);
        });

        nextBtn.addEventListener('click', () => {
            currentIndex = (currentIndex + 1) % testimonials.length;
            showTestimonial(currentIndex);
        });

        // Auto-advance
        setInterval(() => {
            currentIndex = (currentIndex + 1) % testimonials.length;
            showTestimonial(currentIndex);
        }, 5000);
    }
}

// Counter animations
function initializeCounters() {
    const counters = document.querySelectorAll('.counter');
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const counter = entry.target;
                const target = parseInt(counter.getAttribute('data-target'));
                const duration = 2000; // 2 seconds
                const step = target / (duration / 16); // 60fps
                
                let current = 0;
                const timer = setInterval(() => {
                    current += step;
                    counter.textContent = Math.round(current);
                    
                    if (current >= target) {
                        counter.textContent = target;
                        clearInterval(timer);
                    }
                }, 16);

                observer.unobserve(counter);
            }
        });
    }, { threshold: 0.5 });

    counters.forEach(counter => observer.observe(counter));
}

// Form handling
function initializeForms() {
    const forms = document.querySelectorAll('form');
    
    forms.forEach(form => {
        form.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const submitBtn = this.querySelector('[type="submit"]');
            const originalBtnText = submitBtn.innerHTML;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending...';
            submitBtn.disabled = true;

            // Validate form
            const errors = validateForm(this);
            if (errors.length > 0) {
                alert(errors.join('\n'));
                submitBtn.innerHTML = originalBtnText;
                submitBtn.disabled = false;
                return;
            }

            // Simulate form submission
            try {
                await new Promise(resolve => setTimeout(resolve, 1500));
                const formSuccess = document.createElement('div');
                formSuccess.className = 'form-success';
                formSuccess.textContent = 'Thank you! Your message has been sent successfully.';
                form.insertBefore(formSuccess, form.firstChild);
                form.reset();
                setTimeout(() => formSuccess.remove(), 5000);
            } catch (error) {
                alert('An error occurred. Please try again later.');
            } finally {
                submitBtn.innerHTML = originalBtnText;
                submitBtn.disabled = false;
            }
        });
    });
}

// Form validation
function validateForm(form) {
    const errors = [];
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const phoneRegex = /^[0-9+\-\s()]{10,}$/;

    // Name validation
    const nameInput = form.querySelector('[name="name"]');
    if (nameInput && nameInput.value.trim().length < 2) {
        errors.push('Name must be at least 2 characters long');
    }

    // Email validation
    const emailInput = form.querySelector('[name="email"]');
    if (emailInput && !emailRegex.test(emailInput.value)) {
        errors.push('Please enter a valid email address');
    }

    // Phone validation (if exists)
    const phoneInput = form.querySelector('[name="phone"]');
    if (phoneInput && phoneInput.value && !phoneRegex.test(phoneInput.value)) {
        errors.push('Please enter a valid phone number');
    }

    // Message validation
    const messageInput = form.querySelector('[name="message"]');
    if (messageInput && messageInput.value.trim().length < 10) {
        errors.push('Message must be at least 10 characters long');
    }

    return errors;
}

// Scroll-to-top functionality
function initializeScrollToTop() {
    const scrollBtn = document.createElement('button');
    scrollBtn.innerHTML = '<i class="fas fa-arrow-up"></i>';
    scrollBtn.className = 'scroll-to-top';
    scrollBtn.setAttribute('aria-label', 'Scroll to top');
    document.body.appendChild(scrollBtn);

    window.addEventListener('scroll', () => {
        if (window.pageYOffset > 300) {
            scrollBtn.classList.add('show');
        } else {
            scrollBtn.classList.remove('show');
        }
    });

    scrollBtn.addEventListener('click', () => {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
}

// Browser compatibility check
function checkBrowserCompatibility() {
    const unsupportedFeatures = [];
    
    // Check for modern JavaScript features
    if (!('IntersectionObserver' in window)) {
        unsupportedFeatures.push('IntersectionObserver');
    }
    
    if (!('fetch' in window)) {
        unsupportedFeatures.push('Fetch API');
    }

    if (!('CSS' in window && 'supports' in window.CSS)) {
        unsupportedFeatures.push('CSS.supports');
    }
    
    if (unsupportedFeatures.length > 0) {
        const warning = document.createElement('div');
        warning.className = 'browser-warning';
        warning.innerHTML = `
            <p>Your browser might not support all features. Please update your browser or try a modern browser for the best experience.</p>
            <button onclick="this.parentElement.remove()">Dismiss</button>
        `;
        document.body.insertBefore(warning, document.body.firstChild);
    }
}

// Initialize CSRF protection
function initializeCSRF() {
    const csrfToken = Math.random().toString(36).slice(2);
    document.querySelectorAll('form').forEach(form => {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = '_csrf';
        input.value = csrfToken;
        form.appendChild(input);
    });
}

// Lazy loading for images
document.addEventListener('DOMContentLoaded', function() {
    let lazyImages = [].slice.call(document.querySelectorAll('img[loading="lazy"]'));
    let imageObserver = new IntersectionObserver(function(entries, observer) {
        entries.forEach(function(entry) {
            if (entry.isIntersecting) {
                let img = entry.target;
                img.src = img.dataset.src;
                img.classList.add('loaded');
                observer.unobserve(img);
            }
        });
    });

    lazyImages.forEach(function(img) {
        imageObserver.observe(img);
    });
});

// Form validation with modern validation API
class FormValidator {
    constructor(formElement) {
        this.form = formElement;
        this.inputsToValidate = this.form.querySelectorAll('input[required], textarea[required]');
        this.setupValidation();
    }

    setupValidation() {
        this.inputsToValidate.forEach(input => {
            input.addEventListener('input', () => this.validateInput(input));
            input.addEventListener('blur', () => this.validateInput(input));
        });

        this.form.addEventListener('submit', (e) => this.handleSubmit(e));
    }

    validateInput(input) {
        const field = input.closest('.form-field');
        if (!field) return;

        field.classList.remove('success', 'error');
        this.removeErrorMessage(field);

        if (input.checkValidity()) {
            field.classList.add('success');
        } else {
            field.classList.add('error');
            this.showErrorMessage(field, this.getErrorMessage(input));
        }
    }

    getErrorMessage(input) {
        if (input.validity.valueMissing) return 'This field is required';
        if (input.validity.typeMismatch) {
            if (input.type === 'email') return 'Please enter a valid email address';
            if (input.type === 'tel') return 'Please enter a valid phone number';
        }
        if (input.validity.patternMismatch) return input.title || 'Please match the requested format';
        return 'Please enter a valid value';
    }

    showErrorMessage(field, message) {
        const error = document.createElement('div');
        error.className = 'error-message';
        error.textContent = message;
        field.appendChild(error);
    }

    removeErrorMessage(field) {
        const error = field.querySelector('.error-message');
        if (error) error.remove();
    }

    async handleSubmit(e) {
        e.preventDefault();
        
        if (!this.form.checkValidity()) {
            this.inputsToValidate.forEach(input => this.validateInput(input));
            return;
        }

        const submitButton = this.form.querySelector('[type="submit"]');
        submitButton.disabled = true;
        submitButton.classList.add('loading');

        try {
            const formData = new FormData(this.form);
            // Here you would typically send the data to your server
            await this.simulateFormSubmission(formData);
            
            this.showSuccessMessage();
            this.form.reset();
            this.inputsToValidate.forEach(input => {
                const field = input.closest('.form-field');
                if (field) field.classList.remove('success', 'error');
            });
        } catch (error) {
            console.error('Form submission error:', error);
            this.showErrorMessage(this.form, 'Something went wrong. Please try again.');
        } finally {
            submitButton.disabled = false;
            submitButton.classList.remove('loading');
        }
    }

    simulateFormSubmission(formData) {
        return new Promise(resolve => setTimeout(resolve, 1500));
    }

    showSuccessMessage() {
        const successMessage = document.createElement('div');
        successMessage.className = 'form-success';
        successMessage.textContent = 'Thank you! Your message has been sent successfully.';
        this.form.parentNode.insertBefore(successMessage, this.form);
        setTimeout(() => successMessage.remove(), 5000);
    }
}

// Initialize form validation for all forms
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('form').forEach(form => new FormValidator(form));
});

// Enhanced analytics with privacy considerations
class Analytics {
    constructor() {
        this.consent = this.getConsentStatus();
        this.setupConsentBanner();
        if (this.consent) this.initializeAnalytics();
    }

    getConsentStatus() {
        return localStorage.getItem('analyticsConsent') === 'true';
    }

    setupConsentBanner() {
        if (this.consent) return;

        const banner = document.createElement('div');
        banner.className = 'consent-banner';
        banner.innerHTML = `
            <p>We use cookies and analytics to improve your experience. 
               <button class="accept-consent">Accept</button>
               <button class="reject-consent">Reject</button>
            </p>
        `;

        document.body.appendChild(banner);

        banner.querySelector('.accept-consent').addEventListener('click', () => {
            this.setConsent(true);
            banner.remove();
        });

        banner.querySelector('.reject-consent').addEventListener('click', () => {
            this.setConsent(false);
            banner.remove();
        });
    }

    setConsent(value) {
        this.consent = value;
        localStorage.setItem('analyticsConsent', value);
        if (value) this.initializeAnalytics();
    }

    initializeAnalytics() {
        // Initialize analytics only if consent is given
        if (!this.consent) return;

        // Google Analytics
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', 'G-YOUR_MEASUREMENT_ID', {
            'anonymize_ip': true,
            'allow_ad_personalization_signals': false
        });

        // Microsoft Clarity
        (function(c,l,a,r,i,t,y){
            c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
            t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
            y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
        })(window, document, "clarity", "script", "YOUR_CLARITY_ID");

        this.setupEventTracking();
    }

    setupEventTracking() {
        // Track page views
        this.trackPageView();

        // Track user interactions
        document.addEventListener('click', (e) => {
            const target = e.target;
            if (target.matches('a, button, input[type="submit"]')) {
                this.trackEvent('interaction', {
                    type: target.tagName.toLowerCase(),
                    text: target.innerText || target.value,
                    location: this.getElementPath(target)
                });
            }
        });

        // Track form submissions
        document.querySelectorAll('form').forEach(form => {
            form.addEventListener('submit', () => {
                this.trackEvent('form_submission', {
                    formId: form.id || 'unnamed_form',
                    page: window.location.pathname
                });
            });
        });

        // Track scroll depth
        this.trackScrollDepth();
    }

    trackPageView() {
        if (!this.consent) return;
        this.trackEvent('page_view', {
            path: window.location.pathname,
            title: document.title
        });
    }

    trackEvent(eventName, eventParams = {}) {
        if (!this.consent) return;
        // Send to Google Analytics
        gtag('event', eventName, eventParams);
    }

    getElementPath(element) {
        const path = [];
        while (element && element.tagName) {
            let selector = element.tagName.toLowerCase();
            if (element.id) {
                selector += `#${element.id}`;
            } else if (element.className) {
                selector += `.${Array.from(element.classList).join('.')}`;
            }
            path.unshift(selector);
            element = element.parentElement;
        }
        return path.join(' > ');
    }

    trackScrollDepth() {
        let maxScroll = 0;
        const intervals = [25, 50, 75, 90, 100];
        let triggers = new Set(intervals);

        window.addEventListener('scroll', () => {
            if (!this.consent) return;

            const scrollPercent = Math.round((window.scrollY + window.innerHeight) / document.documentElement.scrollHeight * 100);
            
            if (scrollPercent > maxScroll) {
                maxScroll = scrollPercent;
                triggers.forEach(trigger => {
                    if (maxScroll >= trigger) {
                        this.trackEvent('scroll_depth', { depth: trigger });
                        triggers.delete(trigger);
                    }
                });
            }
        }, { passive: true });
    }
}

// Initialize analytics
const analytics = new Analytics();

// Service Worker Registration
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/js/service-worker.js')
            .then(registration => {
                console.log('ServiceWorker registration successful');
                registration.addEventListener('updatefound', () => {
                    const newWorker = registration.installing;
                    newWorker.addEventListener('statechange', () => {
                        if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                            // New content is available, show update notification
                            showUpdateNotification();
                        }
                    });
                });
            })
            .catch(err => console.log('ServiceWorker registration failed: ', err));
    });
}

function showUpdateNotification() {
    const notification = document.createElement('div');
    notification.className = 'update-notification';
    notification.innerHTML = `
        <p>A new version of this site is available!</p>
        <button onclick="window.location.reload()">Update Now</button>
    `;
    document.body.appendChild(notification);
}

// Mobile Menu
const mobileMenuBtn = document.getElementById('mobileMenuBtn');
const mainMenu = document.getElementById('mainMenu');
if (mobileMenuBtn && mainMenu) {
    mobileMenuBtn.addEventListener('click', () => {
        const isExpanded = mainMenu.classList.contains('show');
        mobileMenuBtn.setAttribute('aria-expanded', !isExpanded);
        mainMenu.classList.toggle('show');
    });
}

// Add aria-current to active navigation item
const currentPath = window.location.pathname;
document.querySelectorAll('nav a').forEach(link => {
    if (link.getAttribute('href') === currentPath) {
        link.setAttribute('aria-current', 'page');
    }
});

// Google Analytics Configuration
window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', 'G-YOUR_MEASUREMENT_ID');

// Service Worker Registration
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/service-worker.js')
            .then(registration => {
                console.log('ServiceWorker registration successful');
            })
            .catch(err => {
                console.log('ServiceWorker registration failed: ', err);
            });
    });
}

// Lazy Loading Implementation
document.addEventListener('DOMContentLoaded', function() {
    const lazyImages = document.querySelectorAll('img.lazy-image');
    
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.remove('lazy-image');
                observer.unobserve(img);
            }
        });
    });

    lazyImages.forEach(img => imageObserver.observe(img));
});

// Form Validation and Security
function validateForm(formElement) {
    const form = formElement;
    const emailInput = form.querySelector('input[type="email"]');
    const phoneInput = form.querySelector('input[type="tel"]');
    
    // Email validation
    if (emailInput) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(emailInput.value)) {
            showError(emailInput, 'Please enter a valid email address');
            return false;
        }
    }
    
    // Phone validation
    if (phoneInput) {
        const phoneRegex = /^[0-9+\-\s()]{10,}$/;
        if (!phoneRegex.test(phoneInput.value)) {
            showError(phoneInput, 'Please enter a valid phone number');
            return false;
        }
    }
    
    // XSS Prevention
    const inputs = form.querySelectorAll('input, textarea');
    inputs.forEach(input => {
        input.value = sanitizeInput(input.value);
    });
    
    return true;
}

function sanitizeInput(input) {
    const div = document.createElement('div');
    div.textContent = input;
    return div.innerHTML;
}

function showError(element, message) {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.textContent = message;
    
    // Remove any existing error messages
    const existingError = element.parentNode.querySelector('.error-message');
    if (existingError) {
        existingError.remove();
    }
    
    element.parentNode.appendChild(errorDiv);
    element.classList.add('error');
    
    // Remove error after 5 seconds
    setTimeout(() => {
        errorDiv.remove();
        element.classList.remove('error');
    }, 5000);
}

// Event tracking for analytics
function trackEvent(category, action, label = null) {
    if (typeof gtag !== 'undefined') {
        const eventParams = {
            event_category: category,
            event_action: action
        };
        if (label) {
            eventParams.event_label = label;
        }
        gtag('event', action, eventParams);
    }
}

// Form submission handler with offline support
async function handleFormSubmit(event) {
    event.preventDefault();
    const form = event.target;
    
    if (!validateForm(form)) {
        return false;
    }
    
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());
    
    try {
        // Attempt to submit the form
        const response = await submitFormData(data);
        if (response.ok) {
            showSuccess(form);
            trackEvent('Form', 'Submit', 'Success');
        } else {
            // If online but server error, save to retry later
            await saveFormData(data);
            showError(form, 'Submission error. Will retry automatically.');
            trackEvent('Form', 'Submit', 'Error');
        }
    } catch (error) {
        // If offline, save form data to submit later
        await saveFormData(data);
        showError(form, 'You appear to be offline. Form will be submitted when connection is restored.');
        trackEvent('Form', 'Submit', 'Offline');
    }
}

// Save form data for offline support
async function saveFormData(data) {
    if ('indexedDB' in window) {
        // Implementation for storing form data in IndexedDB
        // This is a placeholder for the actual implementation
        console.log('Form data saved for later submission:', data);
    }
}

// Performance monitoring
if ('performance' in window) {
    window.addEventListener('load', () => {
        const paint = performance.getEntriesByType('paint');
        const timing = performance.timing;
        
        // Report performance metrics to Analytics
        gtag('event', 'performance', {
            event_category: 'Performance',
            event_label: 'Page Load',
            value: timing.loadEventEnd - timing.navigationStart
        });
    });
}

// Initialize all interactive elements
document.addEventListener('DOMContentLoaded', () => {
    // Mobile menu functionality
    const mobileMenuBtn = document.getElementById('mobileMenuBtn');
    const mainMenu = document.getElementById('mainMenu');
    
    if (mobileMenuBtn && mainMenu) {
        mobileMenuBtn.addEventListener('click', () => {
            const isExpanded = mobileMenuBtn.getAttribute('aria-expanded') === 'true';
            mobileMenuBtn.setAttribute('aria-expanded', !isExpanded);
            mainMenu.classList.toggle('show');
            trackEvent('Navigation', 'Mobile Menu Toggle', isExpanded ? 'Close' : 'Open');
        });
    }

    // Initialize form handlers
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', handleFormSubmit);
    });

    // Track outbound links
    document.querySelectorAll('a[href^="http"]').forEach(link => {
        link.addEventListener('click', (e) => {
            trackEvent('Outbound Link', 'Click', link.href);
        });
    });
});

// Scroll-to-Top functionality
const scrollBtn = document.createElement('button');
scrollBtn.innerHTML = '<i class="fas fa-arrow-up"></i>';
scrollBtn.className = 'scroll-top';
scrollBtn.setAttribute('aria-label', 'Scroll to top');
document.body.appendChild(scrollBtn);

window.addEventListener('scroll', () => {
    scrollBtn.style.display = window.scrollY > 300 ? 'block' : 'none';
});

scrollBtn.addEventListener('click', () => {
    window.scrollTo({
        top: 0,
        behavior: 'smooth'
    });
    trackEvent('Navigation', 'Click', 'Scroll to Top');
});
