/**
 * Enhanced Features for iBridge Website
 */

class WebsiteEnhancer {
    constructor() {
        this.initializeFeatures();
    }

    initializeFeatures() {
        this.initializeThemeSwitch();
        this.initializeBackToTop();
        this.initializeSmoothTransitions();
        this.initializeLazyLoading();
        this.initializeLiveChat();
        this.initializeServiceWorker();
        this.initializeAccessibility();
    }

    initializeThemeSwitch() {
        // Add theme switcher button
        const switcher = document.createElement('button');
        switcher.className = 'theme-switcher';
        switcher.innerHTML = '<i class="fas fa-moon"></i>';
        switcher.setAttribute('aria-label', 'Toggle dark mode');
        document.body.appendChild(switcher);

        // Set initial theme
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        const savedTheme = localStorage.getItem('theme');
        if (savedTheme) {
            document.documentElement.setAttribute('data-theme', savedTheme);
            this.updateThemeIcon(savedTheme === 'dark');
        } else if (prefersDark) {
            document.documentElement.setAttribute('data-theme', 'dark');
            this.updateThemeIcon(true);
        }

        // Handle theme switching
        switcher.addEventListener('click', () => {
            const currentTheme = document.documentElement.getAttribute('data-theme');
            const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
            
            document.documentElement.setAttribute('data-theme', newTheme);
            localStorage.setItem('theme', newTheme);
            this.updateThemeIcon(newTheme === 'dark');
        });
    }

    updateThemeIcon(isDark) {
        const icon = document.querySelector('.theme-switcher i');
        if (icon) {
            icon.className = isDark ? 'fas fa-sun' : 'fas fa-moon';
        }
    }

    initializeBackToTop() {
        const button = document.createElement('button');
        button.className = 'back-to-top';
        button.innerHTML = '<i class="fas fa-arrow-up"></i>';
        button.setAttribute('aria-label', 'Back to top');
        document.body.appendChild(button);

        window.addEventListener('scroll', () => {
            if (window.pageYOffset > 300) {
                button.classList.add('visible');
            } else {
                button.classList.remove('visible');
            }
        });

        button.addEventListener('click', () => {
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        });
    }

    initializeSmoothTransitions() {
        document.body.classList.add('page-transition');
        
        window.addEventListener('load', () => {
            document.body.classList.add('loaded');
        });

        // Handle navigation transitions
        document.addEventListener('click', (e) => {
            const link = e.target.closest('a');
            if (link && link.href.startsWith(window.location.origin)) {
                e.preventDefault();
                document.body.classList.remove('loaded');
                setTimeout(() => {
                    window.location = link.href;
                }, 500);
            }
        });
    }

    initializeLazyLoading() {
        // Use native lazy loading where supported
        document.querySelectorAll('img').forEach(img => {
            img.loading = 'lazy';
            img.classList.add('responsive-img');
            
            img.addEventListener('load', () => {
                img.classList.add('loaded');
            });
        });

        // Implement Intersection Observer for custom elements
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('loaded');
                    observer.unobserve(entry.target);
                }
            });
        });

        document.querySelectorAll('.lazy-load').forEach(el => {
            observer.observe(el);
        });
    }

    initializeLiveChat() {
        const chatButton = document.createElement('div');
        chatButton.className = 'chat-widget';
        chatButton.innerHTML = `
            <div class="chat-button" aria-label="Open live chat">
                <i class="fas fa-comments"></i>
            </div>
        `;
        document.body.appendChild(chatButton);

        chatButton.addEventListener('click', () => {
            // Initialize chat widget (implement your chat solution here)
            this.openChatWidget();
        });
    }

    openChatWidget() {
        // Implement your chat widget initialization here
        console.log('Chat widget opened');
    }

    async initializeServiceWorker() {
        if ('serviceWorker' in navigator) {
            try {
                const registration = await navigator.serviceWorker.register('/service-worker.js');
                console.log('ServiceWorker registered:', registration);
            } catch (error) {
                console.error('ServiceWorker registration failed:', error);
            }
        }
    }

    initializeAccessibility() {
        // Add skip to main content link
        const skipLink = document.createElement('a');
        skipLink.href = '#main';
        skipLink.className = 'skip-link sr-only';
        skipLink.textContent = 'Skip to main content';
        document.body.insertBefore(skipLink, document.body.firstChild);

        // Add ARIA labels where missing
        document.querySelectorAll('button:not([aria-label])').forEach(button => {
            if (!button.textContent.trim()) {
                button.setAttribute('aria-label', 'Button');
            }
        });

        // Add keyboard navigation support
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Tab') {
                document.body.classList.add('keyboard-nav');
            }
        });

        document.addEventListener('mousedown', () => {
            document.body.classList.remove('keyboard-nav');
        });
    }
}

// Initialize enhancements when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const enhancer = new WebsiteEnhancer();
});
