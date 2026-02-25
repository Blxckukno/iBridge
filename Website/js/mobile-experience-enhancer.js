/**
 * iBridge Mobile Experience Enhancer v1.0
 * Advanced mobile optimizations and touch interactions
 * Created: October 28, 2025
 */

class MobileExperienceEnhancer {
    constructor() {
        this.isMobile = this.detectMobile();
        this.touchStartY = 0;
        this.isScrolling = false;
        this.swipeThreshold = 50;
        this.tapTimeout = null;
        this.doubleTapDelay = 300;
        this.vibrationSupported = 'vibrate' in navigator;
        this.init();
    }

    init() {
        if (this.isMobile) {
            this.setupTouchOptimizations();
            this.enhanceMobileNavigation();
            this.setupSwipeGestures();
            this.optimizeScrolling();
            this.setupTouchFeedback();
            this.addMobileStyles();
            this.setupPullToRefresh();
            this.optimizeViewport();
            this.addMobileIndicators();
        }
        this.setupResponsiveEnhancements();
    }

    detectMobile() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ||
            (window.innerWidth <= 768 && 'ontouchstart' in window);
    }

    setupTouchOptimizations() {
        // Disable 300ms click delay
        document.addEventListener('touchstart', () => { }, { passive: true });

        // Prevent zoom on double tap for specific elements
        const preventZoomElements = document.querySelectorAll('button, .btn, .card, .service-card');
        preventZoomElements.forEach(element => {
            element.addEventListener('touchend', (e) => {
                e.preventDefault();
                element.click();
            });
        });

        // Add touch-friendly sizing
        const touchTargets = document.querySelectorAll('button, a, .clickable');
        touchTargets.forEach(target => {
            const styles = window.getComputedStyle(target);
            const minSize = 44; // Apple's recommended minimum touch target size

            if (parseInt(styles.height) < minSize || parseInt(styles.width) < minSize) {
                target.style.minHeight = `${minSize}px`;
                target.style.minWidth = `${minSize}px`;
                target.style.display = 'inline-flex';
                target.style.alignItems = 'center';
                target.style.justifyContent = 'center';
            }
        });
    }

    enhanceMobileNavigation() {
        const mobileNav = document.querySelector('.mobile-nav, #mainMenu');
        if (!mobileNav) return;

        // Add smooth slide animations
        mobileNav.style.transition = 'transform 0.3s cubic-bezier(0.4, 0, 0.2, 1)';

        // Improve mobile menu interactions
        const menuToggle = document.querySelector('#mobileMenuBtn, .mobile-menu-toggle');
        if (menuToggle) {
            let isMenuOpen = false;

            menuToggle.addEventListener('touchstart', (e) => {
                e.preventDefault();
                this.provideTouchFeedback();

                isMenuOpen = !isMenuOpen;
                mobileNav.classList.toggle('show', isMenuOpen);

                // Update toggle button
                menuToggle.style.transform = isMenuOpen ? 'rotate(90deg)' : 'rotate(0deg)';

                // Prevent body scroll when menu is open
                document.body.style.overflow = isMenuOpen ? 'hidden' : '';
            });
        }

        // Close menu when tapping outside
        document.addEventListener('touchstart', (e) => {
            if (!mobileNav.contains(e.target) && !menuToggle?.contains(e.target)) {
                mobileNav.classList.remove('show');
                document.body.style.overflow = '';
                if (menuToggle) {
                    menuToggle.style.transform = 'rotate(0deg)';
                }
            }
        });
    }

    setupSwipeGestures() {
        let startX = 0;
        let startY = 0;
        let endX = 0;
        let endY = 0;

        document.addEventListener('touchstart', (e) => {
            startX = e.touches[0].clientX;
            startY = e.touches[0].clientY;
        }, { passive: true });

        document.addEventListener('touchend', (e) => {
            endX = e.changedTouches[0].clientX;
            endY = e.changedTouches[0].clientY;

            const deltaX = endX - startX;
            const deltaY = endY - startY;

            // Horizontal swipes
            if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > this.swipeThreshold) {
                if (deltaX > 0) {
                    this.handleSwipeRight();
                } else {
                    this.handleSwipeLeft();
                }
            }

            // Vertical swipes
            if (Math.abs(deltaY) > Math.abs(deltaX) && Math.abs(deltaY) > this.swipeThreshold) {
                if (deltaY > 0) {
                    this.handleSwipeDown();
                } else {
                    this.handleSwipeUp();
                }
            }
        }, { passive: true });
    }

    handleSwipeRight() {
        // Open mobile menu if available
        const mobileNav = document.querySelector('.mobile-nav, #mainMenu');
        const menuToggle = document.querySelector('#mobileMenuBtn');

        if (mobileNav && !mobileNav.classList.contains('show')) {
            mobileNav.classList.add('show');
            document.body.style.overflow = 'hidden';
            this.provideTouchFeedback();
        }
    }

    handleSwipeLeft() {
        // Close mobile menu if open
        const mobileNav = document.querySelector('.mobile-nav, #mainMenu');

        if (mobileNav && mobileNav.classList.contains('show')) {
            mobileNav.classList.remove('show');
            document.body.style.overflow = '';
            this.provideTouchFeedback();
        }
    }

    handleSwipeDown() {
        // Could be used for pull-to-refresh or other actions
        if (window.scrollY === 0) {
            this.triggerPullToRefresh();
        }
    }

    handleSwipeUp() {
        // Could be used to show additional controls or minimize content
        const footer = document.querySelector('footer');
        if (footer) {
            footer.scrollIntoView({ behavior: 'smooth' });
        }
    }

    optimizeScrolling() {
        // Smooth scrolling for mobile
        document.documentElement.style.scrollBehavior = 'smooth';

        // Momentum scrolling for iOS
        document.body.style.webkitOverflowScrolling = 'touch';

        // Optimize scroll performance
        let ticking = false;

        const updateScrollPosition = () => {
            // Update scroll-dependent elements
            const scrollPercent = (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100;

            // Update progress indicators if they exist
            const progressBars = document.querySelectorAll('.scroll-progress');
            progressBars.forEach(bar => {
                bar.style.width = `${scrollPercent}%`;
            });

            ticking = false;
        };

        document.addEventListener('scroll', () => {
            if (!ticking) {
                requestAnimationFrame(updateScrollPosition);
                ticking = true;
            }
        }, { passive: true });

        // Add scroll progress indicator
        this.addScrollProgressIndicator();
    }

    addScrollProgressIndicator() {
        const progressBar = document.createElement('div');
        progressBar.className = 'scroll-progress';
        progressBar.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 0%;
            height: 3px;
            background: linear-gradient(90deg, var(--accent-color, #00ff88), #00cc66);
            z-index: 10000;
            transition: width 0.1s ease-out;
        `;

        document.body.appendChild(progressBar);
    }

    setupTouchFeedback() {
        const touchableElements = document.querySelectorAll('button, .btn, .card, .service-card, a');

        touchableElements.forEach(element => {
            element.addEventListener('touchstart', () => {
                this.provideTouchFeedback('light');
                element.style.transform = 'scale(0.98)';
                element.style.transition = 'transform 0.1s ease-out';
            }, { passive: true });

            element.addEventListener('touchend', () => {
                element.style.transform = 'scale(1)';
            }, { passive: true });

            element.addEventListener('touchcancel', () => {
                element.style.transform = 'scale(1)';
            }, { passive: true });
        });
    }

    provideTouchFeedback(type = 'medium') {
        if (this.vibrationSupported) {
            const patterns = {
                light: 10,
                medium: 20,
                heavy: 30
            };
            navigator.vibrate(patterns[type] || patterns.medium);
        }
    }

    addMobileStyles() {
        const mobileStyles = document.createElement('style');
        mobileStyles.id = 'mobile-enhancements';
        mobileStyles.textContent = `
            /* Mobile-specific optimizations */
            @media (max-width: 768px) {
                /* Improved touch targets */
                button, .btn, a {
                    min-height: 44px;
                    min-width: 44px;
                    padding: 12px 16px;
                }
                
                /* Better mobile forms */
                input, textarea, select {
                    font-size: 16px; /* Prevent zoom on iOS */
                    padding: 12px;
                    border-radius: 8px;
                }
                
                /* Enhanced mobile navigation */
                .mobile-nav, #mainMenu {
                    position: fixed;
                    top: 0;
                    right: -100%;
                    width: 80%;
                    max-width: 300px;
                    height: 100vh;
                    background: var(--nav-bg, #ffffff);
                    z-index: 9999;
                    transition: right 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                    box-shadow: -5px 0 20px rgba(0, 0, 0, 0.1);
                    padding: 60px 20px 20px;
                    overflow-y: auto;
                }
                
                .mobile-nav.show, #mainMenu.show {
                    right: 0;
                }
                
                /* Mobile overlay */
                .mobile-nav.show::before, #mainMenu.show::before {
                    content: '';
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100vw;
                    height: 100vh;
                    background: rgba(0, 0, 0, 0.5);
                    z-index: -1;
                }
                
                /* Improved mobile cards */
                .card, .service-card, .feature-card {
                    margin-bottom: 20px;
                    border-radius: 12px;
                    overflow: hidden;
                }
                
                /* Better mobile hero section */
                .hero-section {
                    padding: 60px 20px;
                    text-align: center;
                }
                
                .hero-section h1 {
                    font-size: 2.5rem;
                    line-height: 1.2;
                    margin-bottom: 20px;
                }
                
                /* Mobile-friendly sections */
                .section {
                    padding: 40px 20px;
                }
                
                /* Responsive grid improvements */
                .services-grid, .features-grid {
                    grid-template-columns: 1fr;
                    gap: 20px;
                }
                
                /* Mobile testimonials */
                .testimonials-slider {
                    padding: 0 20px;
                }
                
                /* Better mobile footer */
                .footer {
                    padding: 40px 20px;
                }
                
                .footer-content {
                    grid-template-columns: 1fr;
                    gap: 30px;
                    text-align: center;
                }
                
                /* Mobile security dashboard adjustments */
                #advanced-security-dashboard {
                    width: 95%;
                    height: 90%;
                    right: 2.5%;
                    top: 5% !important;
                }
                
                .dashboard-content {
                    grid-template-columns: 1fr !important;
                    gap: 15px;
                }
                
                /* Performance indicator mobile position */
                #performance-indicator {
                    bottom: 80px !important;
                    left: 10px !important;
                    font-size: 11px;
                    padding: 8px 12px;
                }
                
                /* Dark mode toggle mobile position */
                #dark-mode-toggle {
                    top: 10px !important;
                    right: 60px !important;
                    padding: 6px;
                    font-size: 12px;
                }
                
                .theme-text {
                    display: none;
                }
                
                /* Mobile contact form */
                .contact-form {
                    padding: 30px 20px;
                    margin: 0 10px;
                }
                
                /* Improved mobile animations */
                .fade-in-up {
                    transform: translateY(30px);
                }
                
                /* Mobile-specific utilities */
                .mobile-only {
                    display: block !important;
                }
                
                .desktop-only {
                    display: none !important;
                }
                
                /* Better mobile spacing */
                .mb-mobile {
                    margin-bottom: 20px;
                }
                
                .mt-mobile {
                    margin-top: 20px;
                }
                
                /* Mobile text sizes */
                .text-mobile-lg {
                    font-size: 1.5rem;
                }
                
                .text-mobile-sm {
                    font-size: 0.9rem;
                }
            }
            
            /* Touch-specific styles */
            @media (hover: none) and (pointer: coarse) {
                /* Remove hover effects on touch devices */
                .card:hover,
                .service-card:hover,
                .btn:hover {
                    transform: none;
                }
                
                /* Add touch-specific active states */
                .card:active,
                .service-card:active,
                .btn:active {
                    transform: scale(0.98);
                    transition: transform 0.1s ease-out;
                }
            }
        `;

        document.head.appendChild(mobileStyles);
    }

    setupPullToRefresh() {
        let pullStartY = 0;
        let pullMoveY = 0;
        let isPulling = false;
        let pullThreshold = 80;

        const pullIndicator = document.createElement('div');
        pullIndicator.id = 'pull-to-refresh';
        pullIndicator.style.cssText = `
            position: fixed;
            top: -60px;
            left: 50%;
            transform: translateX(-50%);
            background: var(--accent-color, #00ff88);
            color: #000;
            padding: 15px 20px;
            border-radius: 0 0 15px 15px;
            font-size: 14px;
            font-weight: 600;
            z-index: 10001;
            transition: top 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            box-shadow: 0 5px 20px rgba(0, 255, 136, 0.3);
        `;
        pullIndicator.innerHTML = '⬇️ Pull to refresh';

        document.body.appendChild(pullIndicator);

        document.addEventListener('touchstart', (e) => {
            if (window.scrollY === 0) {
                pullStartY = e.touches[0].clientY;
                isPulling = true;
            }
        }, { passive: true });

        document.addEventListener('touchmove', (e) => {
            if (!isPulling) return;

            pullMoveY = e.touches[0].clientY;
            const pullDistance = pullMoveY - pullStartY;

            if (pullDistance > 0 && pullDistance < pullThreshold) {
                pullIndicator.style.top = `${-60 + (pullDistance * 0.5)}px`;
                pullIndicator.innerHTML = '⬇️ Pull to refresh';
            } else if (pullDistance >= pullThreshold) {
                pullIndicator.style.top = '0px';
                pullIndicator.innerHTML = '🔄 Release to refresh';
            }
        }, { passive: true });

        document.addEventListener('touchend', () => {
            if (!isPulling) return;

            const pullDistance = pullMoveY - pullStartY;

            if (pullDistance >= pullThreshold) {
                this.triggerPullToRefresh();
            }

            pullIndicator.style.top = '-60px';
            isPulling = false;
            pullStartY = 0;
            pullMoveY = 0;
        }, { passive: true });
    }

    triggerPullToRefresh() {
        const pullIndicator = document.getElementById('pull-to-refresh');
        if (pullIndicator) {
            pullIndicator.innerHTML = '🔄 Refreshing...';
            pullIndicator.style.top = '0px';

            this.provideTouchFeedback('medium');

            // Simulate refresh
            setTimeout(() => {
                window.location.reload();
            }, 1000);
        }
    }

    optimizeViewport() {
        // Add or update viewport meta tag
        let viewport = document.querySelector('meta[name="viewport"]');
        if (!viewport) {
            viewport = document.createElement('meta');
            viewport.name = 'viewport';
            document.head.appendChild(viewport);
        }

        viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';

        // Add safe area support for newer devices
        const safeAreaStyles = document.createElement('style');
        safeAreaStyles.textContent = `
            /* Safe area insets for newer mobile devices */
            @supports (padding-top: env(safe-area-inset-top)) {
                .safe-area-top {
                    padding-top: env(safe-area-inset-top);
                }
                
                .safe-area-bottom {
                    padding-bottom: env(safe-area-inset-bottom);
                }
                
                .safe-area-left {
                    padding-left: env(safe-area-inset-left);
                }
                
                .safe-area-right {
                    padding-right: env(safe-area-inset-right);
                }
            }
        `;

        document.head.appendChild(safeAreaStyles);
    }

    addMobileIndicators() {
        // Add mobile device indicator for debugging
        if (window.location.hash === '#debug') {
            const indicator = document.createElement('div');
            indicator.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                background: rgba(255, 0, 0, 0.8);
                color: white;
                padding: 5px 10px;
                font-size: 12px;
                z-index: 10002;
            `;
            indicator.textContent = `Mobile: ${this.isMobile} | Width: ${window.innerWidth}`;
            document.body.appendChild(indicator);
        }
    }

    setupResponsiveEnhancements() {
        // Responsive font scaling
        const updateFontSize = () => {
            const vw = Math.max(document.documentElement.clientWidth || 0, window.innerWidth || 0);
            const fontSize = Math.min(Math.max(vw / 100, 14), 18);
            document.documentElement.style.fontSize = `${fontSize}px`;
        };

        updateFontSize();
        window.addEventListener('resize', updateFontSize);

        // Responsive spacing
        const updateSpacing = () => {
            const vw = Math.max(document.documentElement.clientWidth || 0, window.innerWidth || 0);
            const spacing = vw < 768 ? '20px' : vw < 1200 ? '40px' : '60px';
            document.documentElement.style.setProperty('--section-padding', spacing);
        };

        updateSpacing();
        window.addEventListener('resize', updateSpacing);
    }

    // Public API methods
    enableMobileMode() {
        document.body.classList.add('mobile-mode');
        this.setupTouchOptimizations();
    }

    disableMobileMode() {
        document.body.classList.remove('mobile-mode');
    }

    isMobileDevice() {
        return this.isMobile;
    }

    getScreenInfo() {
        return {
            width: window.innerWidth,
            height: window.innerHeight,
            isMobile: this.isMobile,
            orientation: window.innerWidth > window.innerHeight ? 'landscape' : 'portrait',
            pixelRatio: window.devicePixelRatio || 1
        };
    }
}

// Initialize Mobile Experience Enhancer
document.addEventListener('DOMContentLoaded', () => {
    window.mobileExperienceEnhancer = new MobileExperienceEnhancer();

    console.log('%c📱 Mobile Experience Enhancer v1.0 Loaded',
        'color: #00ff88; font-weight: bold; background: #000; padding: 5px 10px; border-radius: 5px;');
});