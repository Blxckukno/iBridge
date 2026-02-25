/**
 * Enterprise Image Optimization Manager
 * Handles lazy loading, WebP conversion, and accessibility
 */

class ImageOptimizer {
    constructor() {
        this.lazyImages = [];
        this.imageObserver = null;
        this.init();
    }

    init() {
        this.setupLazyLoading();
        this.setupWebPDetection();
        this.setupImageAccessibility();
        this.setupImageErrorHandling();

        console.log('ðŸ–¼ï¸ Image Optimizer initialized');
    }

    /**
     * Setup Intersection Observer for lazy loading
     */
    setupLazyLoading() {
        if ('IntersectionObserver' in window) {
            this.imageObserver = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        this.loadImage(entry.target);
                        this.imageObserver.unobserve(entry.target);
                    }
                });
            }, {
                rootMargin: '50px 0px',
                threshold: 0.01
            });

            // Observe all lazy images
            document.querySelectorAll('img[data-src], [data-bg]').forEach(img => {
                this.imageObserver.observe(img);
            });
        } else {
            // Fallback for older browsers
            this.loadAllImages();
        }
    }

    /**
     * Load individual image
     */
    loadImage(img) {
        if (img.dataset.src) {
            // Regular img element
            img.src = img.dataset.src;
            img.classList.add('loaded');

            img.onload = () => {
                img.classList.remove('lazy-image');
                img.removeAttribute('data-src');
            };
        } else if (img.dataset.bg) {
            // Background image
            img.style.backgroundImage = `url(${img.dataset.bg})`;
            img.classList.add('loaded');
            img.removeAttribute('data-bg');
        }
    }

    /**
     * Load all images (fallback)
     */
    loadAllImages() {
        document.querySelectorAll('img[data-src]').forEach(img => {
            img.src = img.dataset.src;
            img.classList.remove('lazy-image');
            img.removeAttribute('data-src');
        });

        document.querySelectorAll('[data-bg]').forEach(element => {
            element.style.backgroundImage = `url(${element.dataset.bg})`;
            element.removeAttribute('data-bg');
        });
    }

    /**
     * WebP format detection and fallback
     */
    setupWebPDetection() {
        const webP = new Image();
        webP.onload = webP.onerror = () => {
            const support = webP.height === 2;
            document.documentElement.classList.toggle('webp-support', support);

            if (support) {
                this.convertToWebP();
            }
        };
        webP.src = 'data:image/webp;base64,UklGRjoAAABXRUJQVlA4IC4AAACyAgCdASoCAAIALmk0mk0iIiIiIgBoSygABc6WWgAA/veff/0PP8bA//LwYAAA';
    }

    /**
     * Convert images to WebP if supported
     */
    convertToWebP() {
        document.querySelectorAll('img[src$=".jpg"], img[src$=".jpeg"], img[src$=".png"]').forEach(img => {
            const webpSrc = img.src.replace(/\.(jpg|jpeg|png)$/, '.webp');

            // Test if WebP version exists
            const testImg = new Image();
            testImg.onload = () => {
                img.src = webpSrc;
            };
            testImg.onerror = () => {
                // Keep original format
            };
            testImg.src = webpSrc;
        });
    }

    /**
     * Setup image accessibility features
     */
    setupImageAccessibility() {
        document.querySelectorAll('img').forEach(img => {
            // Add alt attribute if missing
            if (!img.hasAttribute('alt')) {
                const figcaption = img.closest('figure')?.querySelector('figcaption');
                const title = img.getAttribute('title') || img.dataset.alt || '';

                img.setAttribute('alt', figcaption?.textContent || title || 'Image');
                console.warn('Missing alt attribute added to image:', img.src);
            }

            // Add loading attribute for native lazy loading
            if (!img.hasAttribute('loading') && !img.classList.contains('eager-load')) {
                img.setAttribute('loading', 'lazy');
            }

            // Add decoding attribute for better performance
            if (!img.hasAttribute('decoding')) {
                img.setAttribute('decoding', 'async');
            }
        });
    }

    /**
     * Handle image loading errors
     */
    setupImageErrorHandling() {
        document.addEventListener('error', (e) => {
            if (e.target.tagName === 'IMG') {
                this.handleImageError(e.target);
            }
        }, true);
    }

    /**
     * Handle individual image error
     */
    handleImageError(img) {
        // Try alternative formats or fallback
        const originalSrc = img.src;

        if (originalSrc.includes('.webp')) {
            // Try original format
            const fallbackSrc = originalSrc.replace('.webp', '.jpg');
            img.src = fallbackSrc;
            return;
        }

        // Show placeholder
        img.style.backgroundColor = '#f8f9fa';
        img.style.border = '2px dashed #dee2e6';
        img.alt = img.alt || 'Image failed to load';

        console.error('Image failed to load:', originalSrc);
    }

    /**
     * Preload critical images
     */
    preloadCriticalImages() {
        const criticalImages = [
            'images/iBridge_Logo-removebg-preview.png',
            'images/generated/og-african-customer-support.png'
        ];

        criticalImages.forEach(src => {
            const link = document.createElement('link');
            link.rel = 'preload';
            link.as = 'image';
            link.href = src;
            document.head.appendChild(link);
        });
    }

    /**
     * Generate responsive image markup
     */
    static generateResponsiveImage(src, alt, sizes = '100vw') {
        const baseName = src.replace(/\.[^/.]+$/, "");
        const extension = src.split('.').pop();

        return `
            <picture>
                <source 
                    srcset="${baseName}-320w.webp 320w, 
                            ${baseName}-640w.webp 640w, 
                            ${baseName}-1024w.webp 1024w"
                    sizes="${sizes}"
                    type="image/webp">
                <source 
                    srcset="${baseName}-320w.${extension} 320w, 
                            ${baseName}-640w.${extension} 640w, 
                            ${baseName}-1024w.${extension} 1024w"
                    sizes="${sizes}">
                <img 
                    src="${src}" 
                    alt="${alt}"
                    loading="lazy"
                    decoding="async"
                    class="lazy-image">
            </picture>
        `;
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.imageOptimizer = new ImageOptimizer();

    // Preload critical images
    window.imageOptimizer.preloadCriticalImages();
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ImageOptimizer;
}





