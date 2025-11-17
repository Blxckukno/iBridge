// Component Manager for iBridge Website
class ComponentManager {
    static async init() {
        this.setupHeader();
        this.setupFooter();
        this.setupTheme();
        this.setupSearch();
        this.setupMobileMenu();
    }

    static setupHeader() {
        // Add fixed header padding to body
        document.body.style.paddingTop = '70px';

        // Handle active nav link
        const currentPath = window.location.pathname;
        document.querySelectorAll('.nav-link').forEach(link => {
            if (link.getAttribute('href') === currentPath.split('/').pop()) {
                link.classList.add('active');
            }
        });

        // Handle dropdown menus
        document.querySelectorAll('.nav-dropdown').forEach(dropdown => {
            if (window.innerWidth < 768) {
                dropdown.addEventListener('click', function(e) {
                    e.preventDefault();
                    this.classList.toggle('active');
                });
            }
        });
    }

    static setupFooter() {
        // Update copyright year
        const yearEl = document.getElementById('currentYear');
        if (yearEl) {
            yearEl.textContent = new Date().getFullYear();
        }

        // Handle footer animations
        const footerSections = document.querySelectorAll('.footer-col');
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('fade-in');
                    observer.unobserve(entry.target);
                }
            });
        }, observerOptions);

        footerSections.forEach(section => observer.observe(section));
    }

    static setupTheme() {
        const toggle = document.querySelector('.theme-toggle');
        if (!toggle) return;

        const currentTheme = localStorage.getItem('theme') || 'light';
        document.documentElement.setAttribute('data-theme', currentTheme);
        toggle.innerHTML = currentTheme === 'light' 
            ? '<i class="fas fa-moon"></i>' 
            : '<i class="fas fa-sun"></i>';

        toggle.addEventListener('click', () => {
            const theme = document.documentElement.getAttribute('data-theme');
            const newTheme = theme === 'light' ? 'dark' : 'light';
            
            document.documentElement.setAttribute('data-theme', newTheme);
            localStorage.setItem('theme', newTheme);
            toggle.innerHTML = newTheme === 'light' 
                ? '<i class="fas fa-moon"></i>' 
                : '<i class="fas fa-sun"></i>';
        });
    }

    static setupSearch() {
        const searchInput = document.querySelector('.search-input');
        if (!searchInput) return;

        searchInput.addEventListener('input', this.debounce(async function(e) {
            const query = e.target.value.trim();
            if (query.length < 2) return;

            try {
                const response = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
                const results = await response.json();
                // Handle search results...
            } catch (error) {
                console.error('Search error:', error);
            }
        }, 300));
    }

    static setupMobileMenu() {
        const menuToggle = document.querySelector('.mobile-menu-toggle');
        const nav = document.querySelector('.enhanced-nav');
        if (!menuToggle || !nav) return;

        menuToggle.addEventListener('click', () => {
            nav.classList.toggle('active');
            menuToggle.setAttribute('aria-expanded', 
                menuToggle.getAttribute('aria-expanded') === 'true' ? 'false' : 'true'
            );
        });

        // Close menu when clicking outside
        document.addEventListener('click', (e) => {
            if (!nav.contains(e.target) && !menuToggle.contains(e.target)) {
                nav.classList.remove('active');
                menuToggle.setAttribute('aria-expanded', 'false');
            }
        });
    }

    static debounce(func, wait) {
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
}

// Initialize components when DOM is loaded
document.addEventListener('DOMContentLoaded', () => ComponentManager.init());
