/**
 * iBridge Website - Accessibility Enhancements
 */

document.addEventListener('DOMContentLoaded', function() {
    // Add ARIA attributes to elements that need them
    enhanceAccessibility();
    
    // Add keyboard navigation support
    addKeyboardSupport();
    
    // Add skip to content functionality
    setupSkipToContent();
    
    // Create skip link if it doesn't exist
    createSkipLinkIfNeeded();
});

/**
 * Enhance accessibility by adding ARIA attributes to elements
 */
function enhanceAccessibility() {
    // Add role="navigation" to nav elements without it
    document.querySelectorAll('nav:not([role])').forEach(nav => {
        nav.setAttribute('role', 'navigation');
    });
    
    // Add aria-label to links that only contain icons
    document.querySelectorAll('a:not([aria-label])').forEach(link => {
        if (link.textContent.trim() === '' && link.querySelector('i, .icon, img')) {
            const imgAlt = link.querySelector('img')?.getAttribute('alt');
            const iconClass = link.querySelector('i, .icon')?.className || '';
            let label = '';
            
            if (imgAlt) {
                label = imgAlt;
            } else if (iconClass.includes('facebook')) {
                label = 'Follow us on Facebook';
            } else if (iconClass.includes('twitter')) {
                label = 'Follow us on Twitter';
            } else if (iconClass.includes('linkedin')) {
                label = 'Follow us on LinkedIn';
            } else if (iconClass.includes('instagram')) {
                label = 'Follow us on Instagram';
            } else if (iconClass.includes('phone')) {
                label = 'Call us';
            } else if (iconClass.includes('envelope')) {
                label = 'Email us';
            }
            
            if (label) {
                link.setAttribute('aria-label', label);
            }
        }
    });
    
    // Add aria-required to required form fields
    document.querySelectorAll('input[required], textarea[required]').forEach(field => {
        field.setAttribute('aria-required', 'true');
    });
    
    // Add appropriate roles to sections
    document.querySelectorAll('section:not([role])').forEach(section => {
        section.setAttribute('role', 'region');
        if (!section.hasAttribute('aria-label') && !section.hasAttribute('aria-labelledby')) {
            const heading = section.querySelector('h1, h2, h3, h4, h5, h6');
            if (heading) {
                const headingId = heading.id || `heading-${Math.random().toString(36).substring(2, 9)}`;
                heading.id = headingId;
                section.setAttribute('aria-labelledby', headingId);
            }
        }
    });
}

/**
 * Add keyboard navigation support
 */
function addKeyboardSupport() {
    // Add keyboard support for dropdown menus
    document.querySelectorAll('.has-dropdown').forEach(dropdown => {
        const link = dropdown.querySelector('.nav-link');
        const menu = dropdown.querySelector('.dropdown-menu');
        
        if (link && menu) {
            link.setAttribute('aria-expanded', 'false');
            link.setAttribute('aria-haspopup', 'true');
            
            link.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    const expanded = link.getAttribute('aria-expanded') === 'true';
                    link.setAttribute('aria-expanded', !expanded);
                    menu.classList.toggle('active');
                }
            });
        }
    });
    
    // Close dropdowns when pressing Escape
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            document.querySelectorAll('.dropdown-menu.active').forEach(menu => {
                menu.classList.remove('active');
                const link = menu.parentElement.querySelector('.nav-link');
                if (link) {
                    link.setAttribute('aria-expanded', 'false');
                }
            });
        }
    });
}

/**
 * Setup skip to content functionality
 */
function setupSkipToContent() {
    const skipLink = document.querySelector('.skip-link');
    if (skipLink) {
        skipLink.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.setAttribute('tabindex', '-1');
                target.focus();
            }
        });
    }
}

/**
 * Create a skip link if it doesn't exist in the DOM
 * This helps keyboard users navigate directly to the main content
 */
function createSkipLinkIfNeeded() {
    // Check if skip link already exists
    if (!document.querySelector('.skip-link')) {
        // Check for main content landmark
        const mainContent = document.querySelector('main') || document.querySelector('#main-content') || document.querySelector('.main-content');
        
        if (mainContent) {
            // Ensure the main content has an ID
            if (!mainContent.id) {
                mainContent.id = 'main-content';
            }
            
            // Create the skip link
            const skipLink = document.createElement('a');
            skipLink.href = `#${mainContent.id}`;
            skipLink.className = 'skip-link';
            skipLink.textContent = 'Skip to main content';
            
            // Style the skip link (will be hidden by default and visible on focus)
            skipLink.style.position = 'absolute';
            skipLink.style.top = '-40px';
            skipLink.style.left = '0';
            skipLink.style.padding = '8px 15px';
            skipLink.style.backgroundColor = '#0066cc';
            skipLink.style.color = '#ffffff';
            skipLink.style.zIndex = '100';
            skipLink.style.transition = 'top 0.3s ease';
            skipLink.style.fontWeight = 'bold';
            
            // Make visible on focus
            skipLink.addEventListener('focus', function() {
                this.style.top = '0';
            });
            
            skipLink.addEventListener('blur', function() {
                this.style.top = '-40px';
            });
            
            // Add to the beginning of the body
            document.body.insertBefore(skipLink, document.body.firstChild);
            
            // Make sure the skip link functionality works
            setupSkipToContent();
            
            console.log('Skip link created successfully');
        } else {
            console.warn('No main content element found to link the skip link to');
        }
    }
}
