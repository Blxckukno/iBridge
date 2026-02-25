// Smooth Scroll JavaScript
// iBridge Contact Solutions - Smooth scrolling functionality

class SmoothScroll {
    constructor() {
        this.duration = 800;
        this.easing = 'easeInOutCubic';
        this.offset = 80; // Account for fixed header

        this.init();
    }

    init() {
        this.setupSmoothScrolling();
        this.setupScrollToTop();
        this.setupScrollAnimations();
    }

    setupSmoothScrolling() {
        // Handle anchor links
        document.addEventListener('click', (e) => {
            const link = e.target.closest('a[href^="#"]');
            if (link) {
                e.preventDefault();
                const targetId = link.getAttribute('href');
                const target = document.querySelector(targetId);

                if (target) {
                    this.scrollToElement(target);
                }
            }
        });

        // Handle form submissions that redirect to anchors
        document.addEventListener('submit', (e) => {
            const form = e.target;
            const action = form.getAttribute('action');

            if (action && action.includes('#')) {
                const targetId = action.split('#')[1];
                const target = document.getElementById(targetId);

                if (target) {
                    setTimeout(() => {
                        this.scrollToElement(target);
                    }, 100);
                }
            }
        });
    }

    setupScrollToTop() {
        // Create scroll to top button
        const scrollToTopBtn = document.createElement('button');
        scrollToTopBtn.className = 'scroll-to-top';
        scrollToTopBtn.innerHTML = '<i class="fas fa-chevron-up"></i>';
        scrollToTopBtn.setAttribute('aria-label', 'Scroll to top');
        scrollToTopBtn.setAttribute('title', 'Scroll to top');

        document.body.appendChild(scrollToTopBtn);

        // Show/hide based on scroll position
        window.addEventListener('scroll', () => {
            if (window.pageYOffset > 300) {
                scrollToTopBtn.classList.add('visible');
            } else {
                scrollToTopBtn.classList.remove('visible');
            }
        });

        // Handle click
        scrollToTopBtn.addEventListener('click', () => {
            this.scrollToTop();
        });
    }

    setupScrollAnimations() {
        // Intersection Observer for scroll animations
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animate-in');
                    observer.unobserve(entry.target);
                }
            });
        }, observerOptions);

        // Observe elements that should animate on scroll
        const animateElements = document.querySelectorAll(
            '.service-card, .feature-item, .kpi-item, .industry-item, .partner-item, .gallery-item, .testimonial-item'
        );

        animateElements.forEach(el => {
            el.classList.add('animate-on-scroll');
            observer.observe(el);
        });
    }

    scrollToElement(element, customOffset = null) {
        const targetPosition = element.offsetTop - (customOffset || this.offset);

        this.smoothScrollTo(targetPosition);

        // Update focus for accessibility
        setTimeout(() => {
            element.focus();
            element.scrollIntoView({ block: 'nearest' });
        }, this.duration);
    }

    scrollToTop() {
        this.smoothScrollTo(0);
    }

    smoothScrollTo(targetPosition) {
        const startPosition = window.pageYOffset;
        const distance = targetPosition - startPosition;
        let startTime = null;

        const animateScroll = (currentTime) => {
            if (startTime === null) startTime = currentTime;
            const timeElapsed = currentTime - startTime;
            const progress = Math.min(timeElapsed / this.duration, 1);

            const easedProgress = this.easingFunctions[this.easing](progress);
            window.scrollTo(0, startPosition + (distance * easedProgress));

            if (timeElapsed < this.duration) {
                requestAnimationFrame(animateScroll);
            }
        };

        requestAnimationFrame(animateScroll);
    }

    // Easing functions
    easingFunctions = {
        linear: t => t,
        easeInQuad: t => t * t,
        easeOutQuad: t => t * (2 - t),
        easeInOutQuad: t => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t,
        easeInCubic: t => t * t * t,
        easeOutCubic: t => (--t) * t * t + 1,
        easeInOutCubic: t => t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1,
        easeInQuart: t => t * t * t * t,
        easeOutQuart: t => 1 - (--t) * t * t * t,
        easeInOutQuart: t => t < 0.5 ? 8 * t * t * t * t : 1 - 8 * (--t) * t * t * t
    };
}

// Initialize smooth scroll
document.addEventListener('DOMContentLoaded', () => {
    new SmoothScroll();
});

// Add scroll animation styles
const scrollStyles = `
    .scroll-to-top {
        position: fixed;
        bottom: 20px;
        right: 20px;
        width: 50px;
        height: 50px;
        background: var(--primary-color, #A1C44F);
        color: white;
        border: none;
        border-radius: 50%;
        font-size: 1.2rem;
        cursor: pointer;
        z-index: 999;
        transition: all 0.3s ease;
        opacity: 0;
        visibility: hidden;
        transform: translateY(100px);
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    }
    
    .scroll-to-top.visible {
        opacity: 1;
        visibility: visible;
        transform: translateY(0);
    }
    
    .scroll-to-top:hover {
        background: var(--secondary-color, #4A5D23);
        transform: translateY(-3px);
        box-shadow: 0 6px 16px rgba(0, 0, 0, 0.2);
    }
    
    .animate-on-scroll {
        opacity: 0;
        transform: translateY(50px);
        transition: all 0.8s ease;
    }
    
    .animate-on-scroll.animate-in {
        opacity: 1;
        transform: translateY(0);
    }
    
    /* Stagger animation for grid items */
    .animate-on-scroll:nth-child(1) { transition-delay: 0.1s; }
    .animate-on-scroll:nth-child(2) { transition-delay: 0.2s; }
    .animate-on-scroll:nth-child(3) { transition-delay: 0.3s; }
    .animate-on-scroll:nth-child(4) { transition-delay: 0.4s; }
    .animate-on-scroll:nth-child(5) { transition-delay: 0.5s; }
    .animate-on-scroll:nth-child(6) { transition-delay: 0.6s; }
    
    /* Reduced motion support */
    @media (prefers-reduced-motion: reduce) {
        .animate-on-scroll {
            opacity: 1;
            transform: none;
            transition: none;
        }
        
        .scroll-to-top {
            transition: opacity 0.3s ease;
        }
    }
    
    @media (max-width: 768px) {
        .scroll-to-top {
            bottom: 15px;
            right: 15px;
            width: 45px;
            height: 45px;
            font-size: 1rem;
        }
    }
`;

const scrollStyleSheet = document.createElement('style');
scrollStyleSheet.textContent = scrollStyles;
document.head.appendChild(scrollStyleSheet);
