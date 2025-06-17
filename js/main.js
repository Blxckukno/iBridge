/**
 * iBridge Website - Main JavaScript
 * Vanilla JS implementation with mobile-first approach
 */

// Include header and footer partials dynamically
document.addEventListener('DOMContentLoaded', function() {
    // Include header
    const headerPlaceholder = document.querySelector('header');
    if (headerPlaceholder && !headerPlaceholder.innerHTML.trim()) {
        fetch('partials/header.html')
            .then(response => response.text())
            .then(data => {
                headerPlaceholder.innerHTML = data;
                initNavigation();
            });
    } else {
        initNavigation();
    }
    
    // Include footer
    const footerPlaceholder = document.querySelector('footer');
    if (footerPlaceholder && !footerPlaceholder.innerHTML.trim()) {
        fetch('partials/footer.html')
            .then(response => response.text())
            .then(data => {
                footerPlaceholder.innerHTML = data;
                // Set current year in footer after loading
                const yearSpan = document.querySelector('.current-year');
                if (yearSpan) {
                    yearSpan.textContent = new Date().getFullYear();
                }
            });
    }
});

function initNavigation() {
    // DOM Elements
    const nav = document.querySelector('.nav');
    const navToggle = document.querySelector('.nav-toggle');
    const navMenu = document.querySelector('.nav-menu');
    const dropdownToggles = document.querySelectorAll('.dropdown-toggle');
    const yearSpan = document.querySelector('.current-year');
    const scrollTopBtn = document.querySelector('.scroll-top');

    // Set current year in footer
    if (yearSpan) {
        yearSpan.textContent = new Date().getFullYear();
    }

    // Mobile Menu Toggle
    if (navToggle) {
        const toggleMenu = () => {
        const expanded = navToggle.getAttribute('aria-expanded') === 'true' || false;
        navToggle.setAttribute('aria-expanded', !expanded);
        navMenu.classList.toggle('active');
        document.body.classList.toggle('menu-open');
    };
    navToggle.addEventListener('click', toggleMenu);
    navToggle.addEventListener('touchstart', function(e) { e.preventDefault(); toggleMenu(); }, { passive: false });

    // Close menu when a nav link is clicked (mobile UX)
    navMenu.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', () => {
            if (navMenu.classList.contains('active')) {
                navMenu.classList.remove('active');
                navToggle.setAttribute('aria-expanded', 'false');
                document.body.classList.remove('menu-open');
            }
        });
    });
}

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

// Add animation class to elements when they enter viewport
const animatedElements = document.querySelectorAll('.animate-on-scroll');

const observerOptions = {
    root: null,
    rootMargin: '0px',
    threshold: 0.1
};

const observer = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('fade-in');
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

animatedElements.forEach(element => {
    observer.observe(element);
});

// Animation on scroll for sections, cards, and images
function animateOnScroll() {
    const animatedEls = document.querySelectorAll('.section, .service-card, .feature-card, .team-member, .image-placeholder');
    animatedEls.forEach(el => {
        const rect = el.getBoundingClientRect();
        if (rect.top < window.innerHeight - 60) {
            el.classList.add('visible');
        }
    });
}
window.addEventListener('scroll', animateOnScroll);
window.addEventListener('DOMContentLoaded', animateOnScroll);

// Form validation
const contactForm = document.querySelector('.contact-form');

if (contactForm) {
    contactForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        // Simple form validation
        const name = this.querySelector('[name="name"]');
        const email = this.querySelector('[name="email"]');
        const message = this.querySelector('[name="message"]');
        let isValid = true;
        
        // Clear previous error messages
        document.querySelectorAll('.form-error-message').forEach(el => el.remove());
        
        // Validate name
        if (!name.value.trim()) {
            addErrorMessage(name, 'Please enter your name');
            isValid = false;
        }
        
        // Validate email
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!email.value.trim() || !emailRegex.test(email.value)) {
            addErrorMessage(email, 'Please enter a valid email address');
            isValid = false;
        }
        
        // Validate message
        if (!message.value.trim()) {
            addErrorMessage(message, 'Please enter your message');
            isValid = false;
        }
        
        if (isValid) {
            // Show success message
            const successMessage = document.createElement('div');
            successMessage.className = 'form-success';
            successMessage.textContent = 'Your message has been sent. We will contact you soon!';
            contactForm.prepend(successMessage);
            
            // Reset form
            contactForm.reset();
            
            // Remove success message after 5 seconds
            setTimeout(() => {
                successMessage.remove();
            }, 5000);
            
            // Here you would typically send the form data to your server
            // This is just a frontend demo without actual form submission
        }
    });
}

// Helper function to add error message
function addErrorMessage(element, message) {
    const errorMessage = document.createElement('div');
    errorMessage.className = 'form-error-message';
    errorMessage.textContent = message;
    errorMessage.style.color = 'red';
    errorMessage.style.fontSize = '0.8rem';
    errorMessage.style.marginTop = '5px';
    element.parentNode.appendChild(errorMessage);
    element.classList.add('error');
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
        if (panel) panel.hidden = false;
    });
});

    // Initialize on page load (within navigation context)
    // Set first tab as active by default if none are active
    if (!document.querySelector('[role="tab"][aria-selected="true"]')) {
        const firstTab = document.querySelector('[role="tab"]');
        if (firstTab) {
            firstTab.click();
        }
    }
    
    // Add fade-in animation to hero section
    const hero = document.querySelector('.hero');
    if (hero) {
        hero.classList.add('fade-in');
    }
} // End of initNavigation function