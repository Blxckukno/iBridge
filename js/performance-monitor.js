// Performance Monitor JavaScript
// iBridge Contact Solutions - Performance monitoring and optimization

class PerformanceMonitor {
    constructor() {
        this.metrics = {
            loadTime: 0,
            firstContentfulPaint: 0,
            largestContentfulPaint: 0,
            cumulativeLayoutShift: 0,
            firstInputDelay: 0
        };

        this.init();
    }

    init() {
        this.measureLoadTime();
        this.setupPerformanceObserver();
        this.optimizeImages();
        this.implementLazyLoading();
        this.monitorMemoryUsage();
        this.setupNetworkOptimization();
    }

    measureLoadTime() {
        // Measure page load time
        window.addEventListener('load', () => {
            const loadTime = performance.now();
            this.metrics.loadTime = loadTime;

            console.log(`Page load time: ${loadTime.toFixed(2)}ms`);

            // Report if load time is slow
            if (loadTime > 3000) {
                console.warn('Page load time is slow. Consider optimization.');
            }
        });
    }

    setupPerformanceObserver() {
        // Core Web Vitals monitoring
        if ('PerformanceObserver' in window) {
            // First Contentful Paint
            const fcpObserver = new PerformanceObserver((list) => {
                const entries = list.getEntries();
                entries.forEach((entry) => {
                    if (entry.name === 'first-contentful-paint') {
                        this.metrics.firstContentfulPaint = entry.startTime;
                        console.log(`FCP: ${entry.startTime.toFixed(2)}ms`);
                    }
                });
            });
            fcpObserver.observe({ entryTypes: ['paint'] });

            // Largest Contentful Paint
            const lcpObserver = new PerformanceObserver((list) => {
                const entries = list.getEntries();
                const lastEntry = entries[entries.length - 1];
                this.metrics.largestContentfulPaint = lastEntry.startTime;
                console.log(`LCP: ${lastEntry.startTime.toFixed(2)}ms`);
            });
            lcpObserver.observe({ entryTypes: ['largest-contentful-paint'] });

            // Cumulative Layout Shift
            const clsObserver = new PerformanceObserver((list) => {
                let clsValue = 0;
                const entries = list.getEntries();
                entries.forEach((entry) => {
                    if (!entry.hadRecentInput) {
                        clsValue += entry.value;
                    }
                });
                this.metrics.cumulativeLayoutShift = clsValue;
                console.log(`CLS: ${clsValue.toFixed(4)}`);
            });
            clsObserver.observe({ entryTypes: ['layout-shift'] });

            // First Input Delay
            const fidObserver = new PerformanceObserver((list) => {
                const entries = list.getEntries();
                entries.forEach((entry) => {
                    this.metrics.firstInputDelay = entry.processingStart - entry.startTime;
                    console.log(`FID: ${this.metrics.firstInputDelay.toFixed(2)}ms`);
                });
            });
            fidObserver.observe({ entryTypes: ['first-input'] });
        }
    }

    optimizeImages() {
        // Implement responsive images
        const images = document.querySelectorAll('img');
        images.forEach(img => {
            // Add loading attribute for native lazy loading
            if (!img.hasAttribute('loading')) {
                img.setAttribute('loading', 'lazy');
            }

            // Optimize image dimensions
            img.addEventListener('load', () => {
                const naturalWidth = img.naturalWidth;
                const displayWidth = img.offsetWidth;

                if (naturalWidth > displayWidth * 2) {
                    console.warn(`Image ${img.src} is oversized. Consider using appropriate dimensions.`);
                }
            });

            // Add error handling
            img.addEventListener('error', () => {
                console.error(`Failed to load image: ${img.src}`);
                // Optionally replace with placeholder
                img.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjZGRkIi8+PHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIxNiIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZHk9Ii4zZW0iPkltYWdlIG5vdCBhdmFpbGFibGU8L3RleHQ+PC9zdmc+';
            });
        });
    }

    implementLazyLoading() {
        // Enhanced lazy loading for non-critical resources
        const lazyElements = document.querySelectorAll('[data-src]');

        if ('IntersectionObserver' in window) {
            const lazyImageObserver = new IntersectionObserver((entries) => {
                entries.forEach((entry) => {
                    if (entry.isIntersecting) {
                        const lazyElement = entry.target;

                        if (lazyElement.tagName === 'IMG') {
                            lazyElement.src = lazyElement.dataset.src;
                            lazyElement.classList.remove('lazy');
                        } else {
                            // Handle other elements like iframes
                            lazyElement.setAttribute('src', lazyElement.dataset.src);
                        }

                        lazyImageObserver.unobserve(lazyElement);
                    }
                });
            });

            lazyElements.forEach((lazyElement) => {
                lazyImageObserver.observe(lazyElement);
            });
        } else {
            // Fallback for browsers without IntersectionObserver
            lazyElements.forEach((element) => {
                if (element.tagName === 'IMG') {
                    element.src = element.dataset.src;
                } else {
                    element.setAttribute('src', element.dataset.src);
                }
            });
        }
    }

    monitorMemoryUsage() {
        // Monitor memory usage if supported
        if ('memory' in performance) {
            setInterval(() => {
                const memory = performance.memory;
                const usedMemory = memory.usedJSHeapSize / 1048576; // Convert to MB
                const totalMemory = memory.totalJSHeapSize / 1048576;

                console.log(`Memory usage: ${usedMemory.toFixed(2)}MB / ${totalMemory.toFixed(2)}MB`);

                // Warn if memory usage is high
                if (usedMemory > 50) {
                    console.warn('High memory usage detected. Consider optimization.');
                }
            }, 30000); // Check every 30 seconds
        }
    }

    setupNetworkOptimization() {
        // Prefetch critical resources
        this.prefetchCriticalResources();

        // Monitor network conditions
        if ('connection' in navigator) {
            const connection = navigator.connection;

            // Adjust behavior based on connection
            if (connection.effectiveType === 'slow-2g' || connection.effectiveType === '2g') {
                this.enableDataSavingMode();
            }

            // Listen for connection changes
            connection.addEventListener('change', () => {
                console.log(`Connection changed: ${connection.effectiveType}`);
                this.adjustForConnection(connection.effectiveType);
            });
        }
    }

    prefetchCriticalResources() {
        // Prefetch important pages
        const criticalLinks = [
            '/about.html',
            '/services.html',
            '/contact.html'
        ];

        criticalLinks.forEach(link => {
            const linkElement = document.createElement('link');
            linkElement.rel = 'prefetch';
            linkElement.href = link;
            document.head.appendChild(linkElement);
        });

        // Preload critical fonts
        const criticalFonts = [
            'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap'
        ];

        criticalFonts.forEach(font => {
            const linkElement = document.createElement('link');
            linkElement.rel = 'preload';
            linkElement.href = font;
            linkElement.as = 'style';
            document.head.appendChild(linkElement);
        });
    }

    enableDataSavingMode() {
        console.log('Data saving mode enabled');

        // Reduce image quality
        const images = document.querySelectorAll('img');
        images.forEach(img => {
            if (img.src && !img.src.includes('data:')) {
                // Add compression parameter if using a service
                // This is a placeholder - implement based on your image service
                console.log('Would compress image:', img.src);
            }
        });

        // Disable non-essential animations
        document.body.classList.add('data-saver-mode');

        // Reduce auto-play videos
        const videos = document.querySelectorAll('video[autoplay]');
        videos.forEach(video => {
            video.removeAttribute('autoplay');
            video.preload = 'none';
        });
    }

    adjustForConnection(effectiveType) {
        if (effectiveType === 'slow-2g' || effectiveType === '2g') {
            this.enableDataSavingMode();
        } else {
            // Re-enable full features for faster connections
            document.body.classList.remove('data-saver-mode');
        }
    }

    // Resource hints
    addResourceHints() {
        // DNS prefetch for external domains
        const externalDomains = [
            'https://fonts.googleapis.com',
            'https://cdnjs.cloudflare.com',
            'https://maps.googleapis.com'
        ];

        externalDomains.forEach(domain => {
            const linkElement = document.createElement('link');
            linkElement.rel = 'dns-prefetch';
            linkElement.href = domain;
            document.head.appendChild(linkElement);
        });
    }

    // Performance reporting
    reportPerformanceMetrics() {
        // Report metrics to analytics service
        const report = {
            url: window.location.href,
            timestamp: Date.now(),
            metrics: this.metrics,
            userAgent: navigator.userAgent,
            connection: navigator.connection ? navigator.connection.effectiveType : 'unknown'
        };

        console.log('Performance Report:', report);

        // Send to analytics service (implement as needed)
        // fetch('/api/performance', { method: 'POST', body: JSON.stringify(report) });
    }

    // Cleanup and optimization
    cleanup() {
        // Remove unused event listeners
        // Clean up observers
        // Clear intervals/timeouts
    }
}

// Initialize performance monitoring
document.addEventListener('DOMContentLoaded', () => {
    const performanceMonitor = new PerformanceMonitor();

    // Report metrics after page is fully loaded
    window.addEventListener('load', () => {
        setTimeout(() => {
            performanceMonitor.reportPerformanceMetrics();
        }, 5000); // Wait 5 seconds after load
    });
});

// Add performance optimization styles
const performanceStyles = `
    /* Lazy loading placeholder */
    img.lazy {
        background: #f0f0f0;
        min-height: 200px;
        display: flex;
        align-items: center;
        justify-content: center;
    }
    
    img.lazy::after {
        content: 'Loading...';
        color: #666;
        font-size: 14px;
    }
    
    /* Data saver mode */
    .data-saver-mode * {
        animation: none !important;
        transition: none !important;
    }
    
    .data-saver-mode img {
        filter: blur(0.5px) brightness(0.9);
    }
    
    /* Optimize for slow connections */
    @media (max-width: 768px) {
        .data-saver-mode .hero {
            background-image: none !important;
            background-color: var(--text-dark, #333) !important;
        }
        
        .data-saver-mode .service-img,
        .data-saver-mode .gallery-img {
            display: none;
        }
    }
    
    /* Performance indicators */
    .performance-warning {
        position: fixed;
        top: 100px;
        right: 20px;
        background: #ff9800;
        color: white;
        padding: 10px 15px;
        border-radius: 5px;
        font-size: 12px;
        z-index: 1000;
        opacity: 0;
        transition: opacity 0.3s ease;
    }
    
    .performance-warning.show {
        opacity: 1;
    }
`;

const performanceStyleSheet = document.createElement('style');
performanceStyleSheet.textContent = performanceStyles;
document.head.appendChild(performanceStyleSheet);
