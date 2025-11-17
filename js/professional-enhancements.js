/**
 * Professional Website Enhancements
 * iBridge Contact Solutions
 * Adds smooth interactions and visual polish
 */

(function() {
    'use strict';

    // Wait for DOM to be fully loaded
    document.addEventListener('DOMContentLoaded', function() {
        
        // ===== Smooth Scroll Enhancement =====
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                const href = this.getAttribute('href');
                if (href !== '#' && href !== '#!') {
                    e.preventDefault();
                    const target = document.querySelector(href);
                    if (target) {
                        const headerOffset = 80;
                        const elementPosition = target.getBoundingClientRect().top;
                        const offsetPosition = elementPosition + window.pageYOffset - headerOffset;

                        window.scrollTo({
                            top: offsetPosition,
                            behavior: 'smooth'
                        });
                    }
                }
            });
        });

        // ===== Enhanced Image Loading =====
        const images = document.querySelectorAll('img');
        images.forEach(img => {
            // Add loading="lazy" if not already present
            if (!img.hasAttribute('loading')) {
                img.setAttribute('loading', 'lazy');
            }

            // Add loaded class when image loads
            if (img.complete) {
                img.classList.add('loaded');
            } else {
                img.addEventListener('load', function() {
                    this.classList.add('loaded');
                });
            }

            // Error handling for missing images
            img.addEventListener('error', function() {
                this.style.opacity = '0.3';
                this.style.border = '2px dashed #ddd';
            });
        });

        // ===== Professional Card Hover Effects =====
        const cards = document.querySelectorAll('.service-card, .feature-card, .team-card');
        cards.forEach(card => {
            card.addEventListener('mouseenter', function() {
                this.style.willChange = 'transform';
            });
            
            card.addEventListener('mouseleave', function() {
                this.style.willChange = 'auto';
            });
        });

        // ===== Scroll Progress Indicator =====
        const createScrollProgress = () => {
            const progressBar = document.createElement('div');
            progressBar.id = 'scroll-progress';
            progressBar.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 0;
                height: 3px;
                background: linear-gradient(90deg, #A1C44F, #B8D663);
                z-index: 9999;
                transition: width 0.1s ease;
                box-shadow: 0 2px 10px rgba(161, 196, 79, 0.5);
            `;
            document.body.appendChild(progressBar);

            window.addEventListener('scroll', () => {
                const windowHeight = document.documentElement.scrollHeight - document.documentElement.clientHeight;
                const scrolled = (window.scrollY / windowHeight) * 100;
                progressBar.style.width = scrolled + '%';
            });
        };
        createScrollProgress();

        // ===== Active Navigation Highlighting =====
        const updateActiveNav = () => {
            const sections = document.querySelectorAll('section[id]');
            const navLinks = document.querySelectorAll('.nav-menu a');

            window.addEventListener('scroll', () => {
                let current = '';
                
                sections.forEach(section => {
                    const sectionTop = section.offsetTop;
                    const sectionHeight = section.clientHeight;
                    if (window.pageYOffset >= (sectionTop - 150)) {
                        current = section.getAttribute('id');
                    }
                });

                navLinks.forEach(link => {
                    link.classList.remove('active');
                    if (link.getAttribute('href') === '#' + current) {
                        link.classList.add('active');
                    }
                });
            });
        };
        updateActiveNav();

        // ===== Parallax Effect for Hero Background =====
        const hero = document.querySelector('.hero');
        if (hero) {
            window.addEventListener('scroll', () => {
                const scrolled = window.pageYOffset;
                const parallaxSpeed = 0.5;
                hero.style.backgroundPositionY = -(scrolled * parallaxSpeed) + 'px';
            });
        }

        // ===== Button Click Ripple Effect =====
        const buttons = document.querySelectorAll('.btn, button');
        buttons.forEach(button => {
            button.addEventListener('click', function(e) {
                const ripple = document.createElement('span');
                const rect = this.getBoundingClientRect();
                const size = Math.max(rect.width, rect.height);
                const x = e.clientX - rect.left - size / 2;
                const y = e.clientY - rect.top - size / 2;

                ripple.style.cssText = `
                    position: absolute;
                    width: ${size}px;
                    height: ${size}px;
                    left: ${x}px;
                    top: ${y}px;
                    background: rgba(255, 255, 255, 0.5);
                    border-radius: 50%;
                    transform: scale(0);
                    animation: ripple 0.6s ease-out;
                    pointer-events: none;
                `;

                this.style.position = 'relative';
                this.style.overflow = 'hidden';
                this.appendChild(ripple);

                setTimeout(() => ripple.remove(), 600);
            });
        });

        // Add ripple animation
        const style = document.createElement('style');
        style.textContent = `
            @keyframes ripple {
                to {
                    transform: scale(4);
                    opacity: 0;
                }
            }
        `;
        document.head.appendChild(style);

        // ===== Form Input Enhancement =====
        const formInputs = document.querySelectorAll('input, textarea, select');
        formInputs.forEach(input => {
            // Add focus animations
            input.addEventListener('focus', function() {
                this.style.transform = 'scale(1.02)';
                this.style.boxShadow = '0 4px 20px rgba(161, 196, 79, 0.2)';
            });

            input.addEventListener('blur', function() {
                this.style.transform = 'scale(1)';
                this.style.boxShadow = '';
            });

            // Real-time validation indicators
            input.addEventListener('input', function() {
                if (this.value.trim() !== '') {
                    this.style.borderColor = '#A1C44F';
                } else {
                    this.style.borderColor = '';
                }
            });
        });

        // ===== Performance Monitoring =====
        if ('PerformanceObserver' in window) {
            const perfObserver = new PerformanceObserver((list) => {
                list.getEntries().forEach((entry) => {
                    if (entry.loadTime > 2000) {
                        console.warn('Slow resource detected:', entry.name);
                    }
                });
            });
            perfObserver.observe({ entryTypes: ['resource'] });
        }

        // ===== Accessibility Enhancements =====
        // Keyboard navigation support
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Tab') {
                document.body.classList.add('keyboard-navigation');
            }
        });

        document.addEventListener('mousedown', function() {
            document.body.classList.remove('keyboard-navigation');
        });

        // Add keyboard focus styles
        const focusStyle = document.createElement('style');
        focusStyle.textContent = `
            .keyboard-navigation *:focus {
                outline: 3px solid #A1C44F;
                outline-offset: 2px;
            }
        `;
        document.head.appendChild(focusStyle);

        // ===== Loading Performance =====
        // Preload critical images
        const criticalImages = document.querySelectorAll('img[data-critical]');
        criticalImages.forEach(img => {
            const link = document.createElement('link');
            link.rel = 'preload';
            link.as = 'image';
            link.href = img.src;
            document.head.appendChild(link);
        });

        // ===== Service Worker Registration (if available) =====
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('/service-worker.js')
                    .then(reg => console.log('Service Worker registered'))
                    .catch(err => console.log('Service Worker registration failed'));
            });
        }

        console.log('%c✨ Professional Enhancements Loaded', 
            'color: #A1C44F; font-weight: bold; font-size: 14px; padding: 5px 10px; background: #2C3E50; border-radius: 5px;');
    });

})();
