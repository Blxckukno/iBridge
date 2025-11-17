/**
 * iBridge Website - Main JavaScript
 * Vanilla JS implementation with mobile-first approach
 */

// DOM Elements
const nav = document.querySelector('.nav');
const navMenu = document.querySelector('.nav-menu');
const dropdownToggles = document.querySelectorAll('.dropdown-toggle');
const yearSpan = document.getElementById('currentYear');
const scrollTopBtn = document.querySelector('.scroll-top');

// Set current year in footer
if (yearSpan) {
    yearSpan.textContent = new Date().getFullYear();
}

// Navigation code
// No mobile menu toggle needed as it's been removed

// Dropdown Menus
dropdownToggles.forEach(toggle => {
    toggle.addEventListener('click', (e) => {
        e.preventDefault();
        const expanded = toggle.getAttribute('aria-expanded') === 'true' || false;
        toggle.setAttribute('aria-expanded', !expanded);
        
        // Find the dropdown menu
        const dropdown = toggle.nextElementSibling;
        dropdown.classList.toggle('active');
        
        // Close other open dropdowns
        dropdownToggles.forEach(otherToggle => {
            if (otherToggle !== toggle) {
                otherToggle.setAttribute('aria-expanded', 'false');
                otherToggle.nextElementSibling.classList.remove('active');
            }
        });
    });
});

// Handle click outside to close dropdown
document.addEventListener('click', (e) => {
    if (!e.target.closest('.dropdown')) {
        dropdownToggles.forEach(toggle => {
            toggle.setAttribute('aria-expanded', 'false');
            const dropdown = toggle.nextElementSibling;
            if (dropdown) dropdown.classList.remove('active');
        });
    }
});

// Header scroll effect
function handleHeaderScroll() {
    // Only proceed if nav element exists
    if (!nav) return;
    
    if (window.scrollY > 50) {
        nav.classList.add('scrolled');
    } else {
        nav.classList.remove('scrolled');
    }
}

// Scroll to top button
function handleScrollButton() {
    if (window.scrollY > 300) {
        scrollTopBtn?.classList.add('visible');
    } else {
        scrollTopBtn?.classList.remove('visible');
    }
}

// Scroll to top function
if (scrollTopBtn) {
    scrollTopBtn.addEventListener('click', () => {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
}

// Scroll event listeners
window.addEventListener('scroll', () => {
    handleHeaderScroll();
    handleScrollButton();
});

// Lazy Loading Images
function lazyLoadImages() {
    // Skip the header logo for immediate loading
    const images = document.querySelectorAll('img:not([loading="lazy"]):not([src*="iBridge_Logo-removebg-preview.png"])');
    
    images.forEach(img => {
        // Only add lazy loading to images that don't already have it
        if (!img.hasAttribute('loading')) {
            img.setAttribute('loading', 'lazy');
        }
    });
}

// Call lazy loading function after DOM is fully loaded
document.addEventListener('DOMContentLoaded', lazyLoadImages);

// Enhanced Animation Observer for Services Page
const observerOptions = {
    root: null,
    rootMargin: '50px',
    threshold: [0.1, 0.25, 0.5]
};

const animationObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('fade-in', 'visible');
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
            
            // Don't unobserve service elements to prevent disappearing
            const isServiceElement = entry.target.matches('.service-card, .feature-card, .benefit-card, .approach-card');
            if (!isServiceElement) {
                animationObserver.unobserve(entry.target);
            }
        }
    });
}, observerOptions);

// Enhanced animation elements selector
const animatedElements = document.querySelectorAll(
    '.animate-on-scroll, .section, .service-card, .feature-card, .team-member, .image-placeholder, .benefit-card, .approach-card'
);

// Apply animation observer to all elements
animatedElements.forEach(element => {
    animationObserver.observe(element);
});

// Animation on scroll for sections, cards, and images (Enhanced)
function animateOnScroll() {
    const animatedEls = document.querySelectorAll('.section, .service-card, .feature-card, .team-member, .image-placeholder');
    animatedEls.forEach(el => {
        const rect = el.getBoundingClientRect();
        if (rect.top < window.innerHeight - 60) {
            el.classList.add('visible');
            el.style.opacity = '1';
            el.style.transform = 'translateY(0)';
        }
    });
}

// Enhanced Form validation with real-time feedback
const contactForm = document.querySelector('.contact-form');

if (contactForm) {
    const formInputs = contactForm.querySelectorAll('input, textarea');
    
    // Add real-time validation feedback
    formInputs.forEach(input => {
        input.addEventListener('blur', function() {
            validateInput(this);
        });
        
        // Clear error when user starts typing again
        input.addEventListener('input', function() {
            const errorMessage = this.parentNode.querySelector('.form-error-message');
            if (errorMessage) {
                errorMessage.remove();
                this.classList.remove('error');
            }
        });
    });
    
    contactForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        // Simple form validation
        const name = this.querySelector('[name="name"]');
        const email = this.querySelector('[name="email"]');
        const message = this.querySelector('[name="message"]');
        let isValid = true;
        
        // Clear previous error messages
        document.querySelectorAll('.form-error-message').forEach(el => el.remove());
        
        // Validate each input
        if (!validateInput(name)) isValid = false;
        if (!validateInput(email)) isValid = false;
        if (!validateInput(message)) isValid = false;
        
        if (isValid) {
            // Show success message
            const successMessage = document.createElement('div');
            successMessage.className = 'form-success';
            successMessage.innerHTML = '<i class="fas fa-check-circle"></i> Your message has been sent. We will contact you soon!';
            successMessage.style.color = '#28a745';
            successMessage.style.padding = '10px';
            successMessage.style.marginBottom = '15px';
            successMessage.style.borderLeft = '4px solid #28a745';
            successMessage.style.backgroundColor = '#f8f9fa';
            contactForm.prepend(successMessage);
            
            // Reset form
            contactForm.reset();
            
            // Remove success message after 5 seconds
            setTimeout(() => {
                successMessage.remove();
            }, 5000);
        }
    });
}

// Enhanced validation function
function validateInput(input) {
    let isValid = true;
    const errorMessage = input.parentNode.querySelector('.form-error-message');
    const value = input.value.trim();
    
    // Remove existing error message
    if (errorMessage) errorMessage.remove();
    
    // Check for empty required fields
    if (input.required && !value) {
        const fieldName = input.name.charAt(0).toUpperCase() + input.name.slice(1);
        addErrorMessage(input, `Please enter your ${input.name}`);
        isValid = false;
    }
    // Additional validation based on input type
    else {
        isValid = validateByInputType(input, value);
    }
    
    // Toggle error class
    input.classList.toggle('error', !isValid);
    
    return isValid;
}

// Separate function to validate by input type
function validateByInputType(input, value) {
    if (input.name === 'email' && value) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(value)) {
            addErrorMessage(input, 'Please enter a valid email address');
            return false;
        }
    } else if (input.name === 'message' && value) {
        if (value.length < 10) {
            addErrorMessage(input, 'Your message should be at least 10 characters');
            return false;
        }
    } else if (input.name === 'phone' && value) {
        const phoneRegex = /^[\d\s+\-()]{7,20}$/;
        if (!phoneRegex.test(value)) {
            addErrorMessage(input, 'Please enter a valid phone number');
            return false;
        }
    }
    return true;
}

// Helper function to add error message
function addErrorMessage(element, message) {
    const errorMessage = document.createElement('div');
    errorMessage.className = 'form-error-message';
    errorMessage.innerHTML = `<i class="fas fa-exclamation-circle"></i> ${message}`;
    errorMessage.style.color = '#dc3545';
    errorMessage.style.fontSize = '0.8rem';
    errorMessage.style.marginTop = '5px';
    errorMessage.style.display = 'flex';
    errorMessage.style.alignItems = 'center';
    errorMessage.style.gap = '5px';
    element.parentNode.appendChild(errorMessage);
}

// Tab functionality
const tabButtons = document.querySelectorAll('[role="tab"]');
const tabPanels = document.querySelectorAll('[role="tabpanel"]');

tabButtons.forEach(button => {
    button.addEventListener('click', () => {
        // Deactivate all tabs
        tabButtons.forEach(btn => {
            btn.setAttribute('aria-selected', 'false');
            btn.classList.remove('active');
        });
        
        // Hide all tab panels
        tabPanels.forEach(panel => {
            panel.hidden = true;
        });
        
        // Activate clicked tab
        button.setAttribute('aria-selected', 'true');
        button.classList.add('active');
        
        // Show corresponding panel
        const panelId = button.getAttribute('aria-controls');
        const panel = document.getElementById(panelId);
        if (panel) {
            panel.hidden = false;
        }
    });
});

// Mark active navigation item
document.addEventListener('DOMContentLoaded', function() {
    // Get the current page URL
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    
    // Find all nav links
    const navLinks = document.querySelectorAll('.nav-link');
    
    // Check each link against current page
    navLinks.forEach(link => {
        const href = link.getAttribute('href');
        if (href === currentPage || 
            (currentPage === 'index.html' && href === '/') ||
            (href !== '/' && currentPage.includes(href))) {
            link.classList.add('active');
            
            // If it's in a dropdown, mark the parent too
            const parentItem = link.closest('.has-dropdown');
            if (parentItem) {
                const parentLink = parentItem.querySelector('.nav-link');
                if (parentLink) {
                    parentLink.classList.add('parent-active');
                }
            }
        }
    });
});
