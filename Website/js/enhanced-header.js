// Enhanced Header JavaScript
// iBridge Contact Solutions - Header functionality

class EnhancedHeader {
    constructor() {
        this.header = document.querySelector('.enhanced-header');
        this.mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
        this.navLinks = document.querySelector('.nav-links');
        this.searchInput = document.querySelector('.search-input');
        this.languageButton = document.querySelector('.language-button');
        this.languageOptions = document.querySelector('.language-options');
        this.dropdowns = document.querySelectorAll('.nav-dropdown');

        this.init();
    }

    init() {
        this.setupMobileMenu();
        this.setupSearch();
        this.setupLanguageSelector();
        this.setupDropdowns();
        this.setupScrollBehavior();
        this.setupKeyboardNavigation();
    }

    setupMobileMenu() {
        if (this.mobileMenuToggle && this.navLinks) {
            this.mobileMenuToggle.addEventListener('click', (e) => {
                e.stopPropagation();
                this.toggleMobileMenu();
            });

            // Close menu when clicking outside
            document.addEventListener('click', (e) => {
                if (!e.target.closest('.enhanced-nav')) {
                    this.closeMobileMenu();
                }
            });

            // Close menu on escape key
            document.addEventListener('keydown', (e) => {
                if (e.key === 'Escape' && this.navLinks.classList.contains('show')) {
                    this.closeMobileMenu();
                    this.mobileMenuToggle.focus();
                }
            });
        }
    }

    toggleMobileMenu() {
        const isOpen = this.navLinks.classList.contains('show');

        if (isOpen) {
            this.closeMobileMenu();
        } else {
            this.openMobileMenu();
        }
    }

    openMobileMenu() {
        this.navLinks.classList.add('show');
        this.mobileMenuToggle.setAttribute('aria-expanded', 'true');
        this.mobileMenuToggle.innerHTML = '<i class="fas fa-times"></i>';

        // Focus first nav link
        const firstLink = this.navLinks.querySelector('.nav-link');
        if (firstLink) {
            setTimeout(() => firstLink.focus(), 100);
        }
    }

    closeMobileMenu() {
        this.navLinks.classList.remove('show');
        this.mobileMenuToggle.setAttribute('aria-expanded', 'false');
        this.mobileMenuToggle.innerHTML = '<i class="fas fa-bars"></i>';
    }

    setupSearch() {
        if (this.searchInput) {
            const searchContainer = this.searchInput.closest('.search-container');

            this.searchInput.addEventListener('focus', () => {
                searchContainer.classList.add('focused');
            });

            this.searchInput.addEventListener('blur', () => {
                searchContainer.classList.remove('focused');
            });

            this.searchInput.addEventListener('keydown', (e) => {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    this.performSearch(this.searchInput.value);
                }
            });
        }
    }

    performSearch(query) {
        if (query.trim()) {
            // Implement search functionality
            console.log('Searching for:', query);
            // You can implement actual search functionality here
            // For now, we'll just log the query
        }
    }

    setupLanguageSelector() {
        if (this.languageButton && this.languageOptions) {
            this.languageButton.addEventListener('click', (e) => {
                e.stopPropagation();
                this.languageOptions.classList.toggle('show');
            });

            // Close language options when clicking outside
            document.addEventListener('click', () => {
                this.languageOptions.classList.remove('show');
            });

            // Handle language selection
            const languageOptions = this.languageOptions.querySelectorAll('.language-option');
            languageOptions.forEach(option => {
                option.addEventListener('click', (e) => {
                    e.preventDefault();
                    const lang = option.dataset.lang;
                    this.changeLanguage(lang);
                });
            });
        }
    }

    changeLanguage(lang) {
        // Implement language change functionality
        console.log('Changing language to:', lang);

        // Update button text
        const langText = this.languageButton.querySelector('span');
        if (langText) {
            langText.textContent = lang.toUpperCase();
        }

        this.languageOptions.classList.remove('show');

        // Store language preference
        localStorage.setItem('preferredLanguage', lang);
    }

    setupDropdowns() {
        this.dropdowns.forEach(dropdown => {
            const link = dropdown.querySelector('.nav-link');
            const content = dropdown.querySelector('.dropdown-content');

            if (link && content) {
                // Toggle dropdown on click
                link.addEventListener('click', (e) => {
                    e.preventDefault();
                    dropdown.classList.toggle('active');
                });

                // Close dropdown when clicking outside
                document.addEventListener('click', (e) => {
                    if (!dropdown.contains(e.target)) {
                        dropdown.classList.remove('active');
                    }
                });

                // Handle keyboard navigation
                link.addEventListener('keydown', (e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        dropdown.classList.toggle('active');
                    }
                });
            }
        });
    }

    setupScrollBehavior() {
        let lastScrollY = window.scrollY;

        window.addEventListener('scroll', () => {
            const currentScrollY = window.scrollY;

            // Hide/show header on scroll
            if (currentScrollY > lastScrollY && currentScrollY > 100) {
                this.header.style.transform = 'translateY(-100%)';
            } else {
                this.header.style.transform = 'translateY(0)';
            }

            // Add shadow when scrolled
            if (currentScrollY > 50) {
                this.header.classList.add('scrolled');
            } else {
                this.header.classList.remove('scrolled');
            }

            lastScrollY = currentScrollY;
        });
    }

    setupKeyboardNavigation() {
        const navLinks = document.querySelectorAll('.nav-link');

        navLinks.forEach((link, index) => {
            link.addEventListener('keydown', (e) => {
                if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
                    e.preventDefault();
                    const nextLink = navLinks[index + 1] || navLinks[0];
                    nextLink.focus();
                } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
                    e.preventDefault();
                    const prevLink = navLinks[index - 1] || navLinks[navLinks.length - 1];
                    prevLink.focus();
                }
            });
        });
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new EnhancedHeader();
});

// Add additional header styles
const additionalStyles = `
    .enhanced-header.scrolled {
        box-shadow: 0 2px 20px rgba(0, 0, 0, 0.1);
        background: rgba(255, 255, 255, 0.98);
    }
    
    .search-container.focused {
        transform: scale(1.02);
    }
    
    .language-options.show {
        display: block;
    }
    
    .nav-dropdown.active .dropdown-content {
        display: block;
    }
    
    .dropdown-content {
        display: none;
        position: absolute;
        top: 100%;
        left: 0;
        min-width: 200px;
        background: white;
        border-radius: 8px;
        box-shadow: 0 5px 25px rgba(0, 0, 0, 0.15);
        padding: 0.5rem 0;
        z-index: 1000;
    }
    
    .dropdown-link {
        display: block;
        padding: 0.75rem 1.5rem;
        color: var(--text-dark);
        text-decoration: none;
        transition: all 0.3s ease;
    }
    
    .dropdown-link:hover {
        background: var(--bg-light);
        color: var(--primary-color);
    }
    
    .language-options {
        display: none;
        position: absolute;
        top: 100%;
        right: 0;
        min-width: 150px;
        background: white;
        border-radius: 8px;
        box-shadow: 0 5px 25px rgba(0, 0, 0, 0.15);
        padding: 0.5rem 0;
        z-index: 1000;
    }
    
    .language-option {
        display: block;
        padding: 0.75rem 1rem;
        color: var(--text-dark);
        text-decoration: none;
        transition: all 0.3s ease;
    }
    
    .language-option:hover {
        background: var(--bg-light);
        color: var(--primary-color);
    }
    
    .notification-badge {
        position: relative;
        cursor: pointer;
    }
    
    .notification-icon {
        font-size: 1.25rem;
        color: var(--text-light);
        transition: all 0.3s ease;
    }
    
    .notification-badge:hover .notification-icon {
        color: var(--primary-color);
    }
    
    .badge {
        position: absolute;
        top: -5px;
        right: -5px;
        background: var(--primary-color);
        color: white;
        border-radius: 50%;
        width: 18px;
        height: 18px;
        font-size: 0.75rem;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: bold;
    }
    
    @media (max-width: 768px) {
        .enhanced-header {
            padding: 0.5rem 0;
        }
        
        .nav-links {
            background: white;
            border-radius: 0 0 15px 15px;
            margin-top: 1px;
        }
        
        .dropdown-content {
            position: static;
            box-shadow: none;
            background: var(--bg-light);
            margin: 0.5rem 0;
            border-radius: 8px;
        }
        
        .search-container,
        .language-selector,
        .notification-badge {
            display: none;
        }
    }
`;

// Inject additional styles
const styleSheet = document.createElement('style');
styleSheet.textContent = additionalStyles;
document.head.appendChild(styleSheet);
