// Core functionality
import './scripts.js';

// Additional functionality for handling newsletter subscriptions
function handleNewsletterSubmit(event) {
    event.preventDefault();
    const form = event.target;
    const email = form.querySelector('input[type="email"]').value;
    
    // Add loading state
    const submitBtn = form.querySelector('button');
    const originalText = submitBtn.textContent;
    submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Subscribing...';
    submitBtn.disabled = true;

    // Simulate API call
    setTimeout(() => {
        const successMessage = document.createElement('div');
        successMessage.className = 'form-success';
        successMessage.textContent = 'Thank you for subscribing!';
        form.insertBefore(successMessage, form.firstChild);
        form.reset();
        
        // Reset button
        submitBtn.textContent = originalText;
        submitBtn.disabled = false;

        // Remove success message after 5 seconds
        setTimeout(() => successMessage.remove(), 5000);
    }, 1500);

    return false;
}

// Initialize everything when the DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    // Initialize all components from scripts.js
    if (typeof initializeNavigation === 'function') initializeNavigation();
    if (typeof initializeAnimations === 'function') initializeAnimations();
    if (typeof initializeTestimonials === 'function') initializeTestimonials();
    if (typeof initializeCounters === 'function') initializeCounters();
    if (typeof initializeForms === 'function') initializeForms();
    if (typeof initializeScrollToTop === 'function') initializeScrollToTop();
    if (typeof checkBrowserCompatibility === 'function') checkBrowserCompatibility();
    if (typeof initializeCSRF === 'function') initializeCSRF();

    // Add newsletter submission handler to window
    window.handleNewsletterSubmit = handleNewsletterSubmit;
});