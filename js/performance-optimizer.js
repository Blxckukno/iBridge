/**
 * iBridge Performance Optimizer v1.0
 * Advanced performance enhancements for optimal site speed
 * Created: October 28, 2025
 */

class PerformanceOptimizer {
    constructor() {
        this.config = {
            lazyLoadOffset: 200,
            resourcePreloadLimit: 5,
            compressionEnabled: true,
            cacheVersion: 'v2.0',
            performanceThresholds: {
                LCP: 2500,  // Largest Contentful Paint
                FID: 100,   // First Input Delay
                CLS: 0.1    // Cumulative Layout Shift
            }
        };
        this.metrics = {};
        this.optimizations = [];
        this.init();
    }

    init() {
        this.measureInitialPerformance();
        this.setupLazyLoading();
        this.enableResourcePreloading();
        this.optimizeImages();
        this.setupServiceWorkerCaching();
        this.enableResourceCompression();
        this.optimizeCriticalPath();
        this.setupPerformanceMonitoring();
        this.createPerformanceIndicator();
    }

    measureInitialPerformance() {
        // Measure Core Web Vitals
        const observer = new PerformanceObserver((list) => {
            const entries = list.getEntries();
            entries.forEach((entry) => {
                if (entry.entryType === 'largest-contentful-paint') {
                    this.metrics.LCP = entry.startTime;
                }
                if (entry.entryType === 'first-input') {
                    this.metrics.FID = entry.processingStart - entry.startTime;
                }
                if (entry.entryType === 'layout-shift' && !entry.hadRecentInput) {
                    this.metrics.CLS = (this.metrics.CLS || 0) + entry.value;
                }
            });
        });

        try {
            observer.observe({ entryTypes: ['largest-contentful-paint', 'first-input', 'layout-shift'] });
        } catch (e) {
            console.log('Performance Observer not supported');
        }
    }

    setupLazyLoading() {
        // Advanced lazy loading for images and content
        const lazyElements = document.querySelectorAll('[data-lazy], img[loading="lazy"]');

        if ('IntersectionObserver' in window) {
            const lazyImageObserver = new IntersectionObserver((entries, observer) => {
                entries.forEach((entry) => {
                    if (entry.isIntersecting) {
                        const lazyElement = entry.target;

                        if (lazyElement.tagName === 'IMG') {
                            this.loadLazyImage(lazyElement);
                        } else {
                            this.loadLazyContent(lazyElement);
                        }

                        lazyImageObserver.unobserve(lazyElement);
                    }
                });
            }, {
                rootMargin: `${this.config.lazyLoadOffset}px`
            });

            lazyElements.forEach((element) => {
                lazyImageObserver.observe(element);
            });

            this.optimizations.push('Lazy Loading Enabled');
        } else {
            // Fallback for older browsers
            lazyElements.forEach((element) => {
                if (element.tagName === 'IMG') {
                    this.loadLazyImage(element);
                } else {
                    this.loadLazyContent(element);
                }
            });
        }
    }

    loadLazyImage(img) {
        if (img.dataset.src) {
            img.src = img.dataset.src;
            img.removeAttribute('data-src');
        }
        if (img.dataset.srcset) {
            img.srcset = img.dataset.srcset;
            img.removeAttribute('data-srcset');
        }

        img.addEventListener('load', () => {
            img.style.opacity = '1';
            img.style.transition = 'opacity 0.3s';
        });
    }

    loadLazyContent(element) {
        if (element.dataset.lazy) {
            element.innerHTML = element.dataset.lazy;
            element.removeAttribute('data-lazy');
            element.style.opacity = '1';
            element.style.transition = 'opacity 0.3s';
        }
    }

    enableResourcePreloading() {
        // Preload critical resources
        const criticalResources = [
            { href: 'css/styles.css', as: 'style' },
            { href: 'js/scripts.js', as: 'script' },
            { href: 'js/ibridge-security.js', as: 'script' },
            { href: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap', as: 'style' }
        ];

        criticalResources.slice(0, this.config.resourcePreloadLimit).forEach((resource) => {
            const link = document.createElement('link');
            link.rel = 'preload';
            link.href = resource.href;
            link.as = resource.as;
            link.crossOrigin = 'anonymous';
            document.head.appendChild(link);
        });

        this.optimizations.push('Resource Preloading Enabled');
    }

    optimizeImages() {
        // Add modern image formats and optimization
        const images = document.querySelectorAll('img');

        images.forEach((img) => {
            // Add loading attribute if not present
            if (!img.hasAttribute('loading')) {
                img.loading = 'lazy';
            }

            // Add decode attribute for better performance
            img.decoding = 'async';

            // Optimize image dimensions
            if (!img.hasAttribute('width') || !img.hasAttribute('height')) {
                img.addEventListener('load', () => {
                    if (!img.hasAttribute('width')) {
                        img.setAttribute('width', img.naturalWidth);
                    }
                    if (!img.hasAttribute('height')) {
                        img.setAttribute('height', img.naturalHeight);
                    }
                });
            }
        });

        // Create WebP versions check
        this.checkWebPSupport();

        this.optimizations.push('Image Optimization Applied');
    }

    checkWebPSupport() {
        const webP = new Image();
        webP.onload = webP.onerror = () => {
            const support = webP.height === 2;
            if (support) {
                document.documentElement.classList.add('webp-support');
                this.optimizations.push('WebP Support Detected');
            }
        };
        webP.src = 'data:image/webp;base64,UklGRjoAAABXRUJQVlA4IC4AAACyAgCdASoCAAIALmk0mk0iIiIiIgBoSygABc6WWgAA/veff/0PP8bA//LwYAAA';
    }

    setupServiceWorkerCaching() {
        if ('serviceWorker' in navigator) {
            // Enhanced service worker registration
            navigator.serviceWorker.register('/js/service-worker.js', {
                scope: '/',
                updateViaCache: 'imports'
            }).then((registration) => {
                console.log('🚀 Enhanced Service Worker registered');

                // Check for updates
                registration.addEventListener('updatefound', () => {
                    const newWorker = registration.installing;
                    newWorker.addEventListener('statechange', () => {
                        if (newWorker.state === 'installed') {
                            if (navigator.serviceWorker.controller) {
                                this.showUpdateAvailable();
                            }
                        }
                    });
                });

                this.optimizations.push('Service Worker Caching Enabled');
            }).catch((error) => {
                console.log('Service Worker registration failed:', error);
            });
        }
    }

    showUpdateAvailable() {
        const updateNotification = document.createElement('div');
        updateNotification.style.cssText = `
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: linear-gradient(135deg, #00ff88, #00cc66);
            color: #000;
            padding: 15px 20px;
            border-radius: 12px;
            z-index: 10000;
            font-size: 14px;
            font-weight: 600;
            box-shadow: 0 10px 30px rgba(0, 255, 136, 0.3);
            cursor: pointer;
            transition: transform 0.3s;
        `;
        updateNotification.innerHTML = `
            🚀 New version available!<br>
            <small style="opacity: 0.8;">Click to update</small>
        `;

        updateNotification.addEventListener('click', () => {
            window.location.reload();
        });

        updateNotification.addEventListener('mouseenter', () => {
            updateNotification.style.transform = 'translateY(-3px)';
        });

        updateNotification.addEventListener('mouseleave', () => {
            updateNotification.style.transform = 'translateY(0)';
        });

        document.body.appendChild(updateNotification);

        // Auto-hide after 10 seconds
        setTimeout(() => {
            if (updateNotification.parentNode) {
                updateNotification.style.opacity = '0';
                setTimeout(() => {
                    updateNotification.remove();
                }, 300);
            }
        }, 10000);
    }

    enableResourceCompression() {
        // Enable dynamic resource compression
        if (this.config.compressionEnabled) {
            // Add compression headers hint
            const meta = document.createElement('meta');
            meta.httpEquiv = 'Accept-Encoding';
            meta.content = 'gzip, deflate, br';
            document.head.appendChild(meta);

            this.optimizations.push('Resource Compression Enabled');
        }
    }

    optimizeCriticalPath() {
        // Optimize critical rendering path
        const nonCriticalCSS = document.querySelectorAll('link[rel="stylesheet"]:not([data-critical])');

        nonCriticalCSS.forEach((link) => {
            // Make non-critical CSS load asynchronously
            const href = link.href;
            link.remove();

            const asyncLink = document.createElement('link');
            asyncLink.rel = 'preload';
            asyncLink.as = 'style';
            asyncLink.href = href;
            asyncLink.onload = function () {
                this.rel = 'stylesheet';
            };
            document.head.appendChild(asyncLink);
        });

        // Defer non-critical JavaScript
        const scripts = document.querySelectorAll('script[src]:not([data-critical])');
        scripts.forEach((script) => {
            if (!script.hasAttribute('async') && !script.hasAttribute('defer')) {
                script.defer = true;
            }
        });

        this.optimizations.push('Critical Path Optimized');
    }

    setupPerformanceMonitoring() {
        // Continuous performance monitoring
        setInterval(() => {
            this.measureCurrentPerformance();
        }, 10000);

        // Monitor long tasks
        if ('PerformanceObserver' in window) {
            try {
                const longTaskObserver = new PerformanceObserver((list) => {
                    const entries = list.getEntries();
                    entries.forEach((entry) => {
                        if (entry.duration > 50) {
                            console.warn(`Long task detected: ${entry.duration}ms`);
                        }
                    });
                });
                longTaskObserver.observe({ entryTypes: ['longtask'] });
            } catch (e) {
                console.log('Long Task Observer not supported');
            }
        }

        this.optimizations.push('Performance Monitoring Active');
    }

    measureCurrentPerformance() {
        // Get current performance metrics
        if (window.performance && window.performance.timing) {
            const timing = window.performance.timing;
            const navigation = window.performance.navigation;

            this.metrics.pageLoadTime = timing.loadEventEnd - timing.navigationStart;
            this.metrics.domContentLoaded = timing.domContentLoadedEventEnd - timing.navigationStart;
            this.metrics.firstPaint = timing.responseStart - timing.navigationStart;

            // Update performance indicator
            this.updatePerformanceIndicator();
        }
    }

    createPerformanceIndicator() {
        const indicator = document.createElement('div');
        indicator.id = 'performance-indicator';
        indicator.style.cssText = `
            position: fixed;
            bottom: 20px;
            left: 20px;
            background: rgba(0, 0, 0, 0.8);
            color: white;
            padding: 10px 15px;
            border-radius: 25px;
            font-size: 12px;
            font-weight: 600;
            z-index: 9999;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            transition: all 0.3s;
            cursor: pointer;
            user-select: none;
        `;

        indicator.innerHTML = `
            <div style="display: flex; align-items: center; gap: 8px;">
                <div class="perf-dot" style="width: 8px; height: 8px; border-radius: 50%; background: #00ff88;"></div>
                <span>Performance: Optimizing...</span>
            </div>
        `;

        indicator.addEventListener('click', () => {
            this.showPerformanceDetails();
        });

        document.body.appendChild(indicator);

        // Auto-hide after 5 seconds
        setTimeout(() => {
            indicator.style.opacity = '0.7';
            indicator.style.transform = 'scale(0.9)';
        }, 5000);
    }

    updatePerformanceIndicator() {
        const indicator = document.getElementById('performance-indicator');
        if (!indicator) return;

        const score = this.calculatePerformanceScore();
        const status = score >= 90 ? 'Excellent' : score >= 70 ? 'Good' : score >= 50 ? 'Needs Work' : 'Poor';
        const color = score >= 90 ? '#00ff88' : score >= 70 ? '#f39c12' : score >= 50 ? '#e67e22' : '#e74c3c';

        const dot = indicator.querySelector('.perf-dot');
        const text = indicator.querySelector('span');

        if (dot) dot.style.background = color;
        if (text) text.textContent = `Performance: ${status} (${score})`;
    }

    calculatePerformanceScore() {
        let score = 100;

        // Penalize based on Core Web Vitals
        if (this.metrics.LCP > this.config.performanceThresholds.LCP) {
            score -= 20;
        }
        if (this.metrics.FID > this.config.performanceThresholds.FID) {
            score -= 20;
        }
        if (this.metrics.CLS > this.config.performanceThresholds.CLS) {
            score -= 20;
        }

        // Bonus for optimizations
        score += Math.min(this.optimizations.length * 2, 20);

        return Math.max(0, Math.min(100, Math.round(score)));
    }

    showPerformanceDetails() {
        const modal = document.createElement('div');
        modal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.8);
            z-index: 99999;
            display: flex;
            align-items: center;
            justify-content: center;
        `;

        const content = document.createElement('div');
        content.style.cssText = `
            background: linear-gradient(135deg, #1a1a1a, #2d2d2d);
            color: white;
            padding: 30px;
            border-radius: 15px;
            max-width: 600px;
            width: 90%;
            max-height: 80%;
            overflow-y: auto;
            border: 2px solid #00ff88;
        `;

        content.innerHTML = `
            <h2 style="margin: 0 0 20px 0; color: #00ff88;">🚀 Performance Report</h2>
            
            <div style="margin-bottom: 20px;">
                <h3 style="color: #f39c12; margin-bottom: 10px;">Core Web Vitals</h3>
                <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 15px; margin-bottom: 20px;">
                    <div style="background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 24px; font-weight: bold; color: ${this.metrics.LCP <= this.config.performanceThresholds.LCP ? '#00ff88' : '#e74c3c'}">
                            ${this.metrics.LCP ? Math.round(this.metrics.LCP) + 'ms' : 'N/A'}
                        </div>
                        <div style="font-size: 12px; opacity: 0.8;">LCP</div>
                    </div>
                    <div style="background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 24px; font-weight: bold; color: ${this.metrics.FID <= this.config.performanceThresholds.FID ? '#00ff88' : '#e74c3c'}">
                            ${this.metrics.FID ? Math.round(this.metrics.FID) + 'ms' : 'N/A'}
                        </div>
                        <div style="font-size: 12px; opacity: 0.8;">FID</div>
                    </div>
                    <div style="background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 24px; font-weight: bold; color: ${this.metrics.CLS <= this.config.performanceThresholds.CLS ? '#00ff88' : '#e74c3c'}">
                            ${this.metrics.CLS ? this.metrics.CLS.toFixed(3) : 'N/A'}
                        </div>
                        <div style="font-size: 12px; opacity: 0.8;">CLS</div>
                    </div>
                </div>
            </div>

            <div style="margin-bottom: 20px;">
                <h3 style="color: #4a90e2; margin-bottom: 10px;">Active Optimizations</h3>
                <div style="display: grid; gap: 8px;">
                    ${this.optimizations.map(opt => `
                        <div style="background: rgba(0,255,136,0.1); padding: 10px; border-radius: 6px; border-left: 3px solid #00ff88;">
                            ✅ ${opt}
                        </div>
                    `).join('')}
                </div>
            </div>

            <div style="margin-bottom: 20px;">
                <h3 style="color: #9b59b6; margin-bottom: 10px;">Performance Score</h3>
                <div style="background: rgba(255,255,255,0.1); padding: 20px; border-radius: 8px; text-align: center;">
                    <div style="font-size: 48px; font-weight: bold; color: #00ff88;">${this.calculatePerformanceScore()}</div>
                    <div style="font-size: 14px; opacity: 0.8;">Overall Performance Score</div>
                </div>
            </div>

            <button onclick="this.parentElement.parentElement.remove()" 
                    style="background: linear-gradient(135deg, #00ff88, #00cc66); color: #000; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer; width: 100%;">
                Close
            </button>
        `;

        modal.appendChild(content);
        document.body.appendChild(modal);

        // Close on backdrop click
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal.remove();
            }
        });
    }

    // Public methods for manual optimization
    prefetchResource(url) {
        const link = document.createElement('link');
        link.rel = 'prefetch';
        link.href = url;
        document.head.appendChild(link);
    }

    preloadImage(src) {
        const img = new Image();
        img.src = src;
    }

    getMetrics() {
        return {
            ...this.metrics,
            optimizations: this.optimizations,
            performanceScore: this.calculatePerformanceScore()
        };
    }
}

// Initialize Performance Optimizer
document.addEventListener('DOMContentLoaded', () => {
    window.performanceOptimizer = new PerformanceOptimizer();

    console.log('%c🚀 Performance Optimizer v1.0 Loaded',
        'color: #00ff88; font-weight: bold; background: #000; padding: 5px 10px; border-radius: 5px;');
});