/**
 * Enterprise Performance Optimizer
 * Implements advanced performance monitoring and optimization
 * Includes resource hints, code splitting, and real-time performance tracking
 */

class PerformanceOptimizer {
    constructor() {
        this.metrics = {};
        this.observers = {};
        this.performanceEntries = [];
        this.init();
    }

    init() {
        this.measurePageLoad();
        this.setupResourceHints();
        this.implementCodeSplitting();
        this.setupPerformanceMonitoring();
        this.optimizeImages();
        this.setupIntersectionObserver();
        this.addDashboardLauncher();

        console.log('⚡ Performance Optimizer initialized');
        this.reportInitialMetrics();
    }

    /**
     * Measure and track page load performance
     */
    measurePageLoad() {
        // Mark navigation start
        performance.mark('navigation-start');

        // Measure Time to Interactive (TTI)
        document.addEventListener('DOMContentLoaded', () => {
            performance.mark('dom-content-loaded');
            this.measureTTI();
        });

        // Measure First Contentful Paint (FCP)
        window.addEventListener('load', () => {
            performance.mark('window-loaded');
            this.calculateCoreWebVitals();
        });

        // Track user interactions
        this.trackUserInteractions();
    }

    /**
     * Setup resource hints for better loading
     */
    setupResourceHints() {
        const hints = [
            // DNS prefetch for external domains
            { rel: 'dns-prefetch', href: '//fonts.googleapis.com' },
            { rel: 'dns-prefetch', href: '//cdnjs.cloudflare.com' },

            // Preconnect to critical domains
            { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: true },

            // Prefetch next likely pages
            { rel: 'prefetch', href: 'about.html' },
            { rel: 'prefetch', href: 'services.html' },
            { rel: 'prefetch', href: 'contact.html' }
        ];

        hints.forEach(hint => {
            const link = document.createElement('link');
            Object.keys(hint).forEach(key => {
                if (key === 'crossorigin') {
                    link.crossOrigin = hint[key];
                } else {
                    link[key] = hint[key];
                }
            });
            document.head.appendChild(link);
        });

        console.log('🔗 Resource hints configured');
    }

    /**
     * Implement dynamic code splitting
     */
    implementCodeSplitting() {
        // Lazy load non-critical JavaScript modules
        this.loadModuleOnDemand('features', () => {
            return this.isFeatureNeeded();
        });

        // Load analytics only when user interacts
        this.loadModuleOnInteraction('analytics', ['scroll', 'click', 'touchstart']);

        // Load heavy features on idle
        this.loadModuleOnIdle('heavy-features');
    }

    /**
     * Load module on demand based on condition
     */
    loadModuleOnDemand(moduleName, conditionFn) {
        if (conditionFn()) {
            this.loadModule(moduleName);
        }
    }

    /**
     * Load module on user interaction
     */
    loadModuleOnInteraction(moduleName, events) {
        const loadModule = () => {
            this.loadModule(moduleName);
            events.forEach(event => {
                document.removeEventListener(event, loadModule, { passive: true });
            });
        };

        events.forEach(event => {
            document.addEventListener(event, loadModule, { passive: true });
        });
    }

    /**
     * Load module when browser is idle
     */
    loadModuleOnIdle(moduleName) {
        if ('requestIdleCallback' in window) {
            requestIdleCallback(() => {
                this.loadModule(moduleName);
            });
        } else {
            // Fallback for browsers without requestIdleCallback
            setTimeout(() => {
                this.loadModule(moduleName);
            }, 2000);
        }
    }

    /**
     * Dynamically load JavaScript module
     */
    async loadModule(moduleName) {
        try {
            performance.mark(`${moduleName}-load-start`);

            const script = document.createElement('script');
            script.src = `js/modules/${moduleName}.js`;
            script.async = true;

            return new Promise((resolve, reject) => {
                script.onload = () => {
                    performance.mark(`${moduleName}-load-end`);
                    performance.measure(`${moduleName}-load`, `${moduleName}-load-start`, `${moduleName}-load-end`);
                    console.log(`📦 Module loaded: ${moduleName}`);
                    resolve();
                };
                script.onerror = reject;
                document.head.appendChild(script);
            });
        } catch (error) {
            console.error(`Failed to load module ${moduleName}:`, error);
        }
    }

    /**
     * Setup comprehensive performance monitoring
     */
    setupPerformanceMonitoring() {
        // Monitor Long Tasks
        if ('PerformanceObserver' in window) {
            this.observeLongTasks();
            this.observeLayoutShifts();
            this.observeLargestContentfulPaint();
            this.observeFirstInputDelay();
        }

        // Monitor resource loading
        this.monitorResourceLoading();

        // Setup performance budget alerts
        this.setupPerformanceBudgets();

        // Real-time performance tracking
        this.startRealTimeMonitoring();
    }

    /**
     * Observe Long Tasks (> 50ms)
     */
    observeLongTasks() {
        try {
            const observer = new PerformanceObserver((list) => {
                for (const entry of list.getEntries()) {
                    if (entry.duration > 50) {
                        console.warn('🐌 Long Task detected:', {
                            duration: entry.duration,
                            startTime: entry.startTime,
                            name: entry.name
                        });

                        this.metrics.longTasks = this.metrics.longTasks || [];
                        this.metrics.longTasks.push({
                            duration: entry.duration,
                            startTime: entry.startTime
                        });
                    }
                }
            });

            observer.observe({ entryTypes: ['longtask'] });
            this.observers.longTasks = observer;
        } catch (e) {
            console.warn('Long Task API not supported');
        }
    }

    /**
     * Observe Cumulative Layout Shift (CLS)
     */
    observeLayoutShifts() {
        try {
            let clsValue = 0;
            let clsEntries = [];

            const observer = new PerformanceObserver((list) => {
                for (const entry of list.getEntries()) {
                    if (!entry.hadRecentInput) {
                        clsValue += entry.value;
                        clsEntries.push(entry);
                    }
                }

                this.metrics.cls = clsValue;
                console.log('📐 CLS updated:', clsValue);
            });

            observer.observe({ entryTypes: ['layout-shift'] });
            this.observers.layoutShift = observer;
        } catch (e) {
            console.warn('Layout Shift API not supported');
        }
    }

    /**
     * Observe Largest Contentful Paint (LCP)
     */
    observeLargestContentfulPaint() {
        try {
            const observer = new PerformanceObserver((list) => {
                const entries = list.getEntries();
                const lastEntry = entries[entries.length - 1];

                this.metrics.lcp = lastEntry.startTime;
                console.log('🖼️ LCP updated:', lastEntry.startTime);
            });

            observer.observe({ entryTypes: ['largest-contentful-paint'] });
            this.observers.lcp = observer;
        } catch (e) {
            console.warn('LCP API not supported');
        }
    }

    /**
     * Observe First Input Delay (FID)
     */
    observeFirstInputDelay() {
        try {
            const observer = new PerformanceObserver((list) => {
                for (const entry of list.getEntries()) {
                    this.metrics.fid = entry.processingStart - entry.startTime;
                    console.log('⚡ FID measured:', this.metrics.fid);
                }
            });

            observer.observe({ entryTypes: ['first-input'] });
            this.observers.fid = observer;
        } catch (e) {
            console.warn('FID API not supported');
        }
    }

    /**
     * Monitor resource loading performance
     */
    monitorResourceLoading() {
        const observer = new PerformanceObserver((list) => {
            for (const entry of list.getEntries()) {
                if (entry.duration > 1000) { // Resources taking > 1s
                    console.warn('🐌 Slow resource:', {
                        name: entry.name,
                        duration: entry.duration,
                        size: entry.transferSize || 'unknown'
                    });
                }
            }
        });

        observer.observe({ entryTypes: ['resource'] });
        this.observers.resource = observer;
    }

    /**
     * Setup performance budgets and alerts
     */
    setupPerformanceBudgets() {
        const budgets = {
            fcp: 1800,      // First Contentful Paint < 1.8s
            lcp: 2500,      // Largest Contentful Paint < 2.5s
            fid: 100,       // First Input Delay < 100ms
            cls: 0.1,       // Cumulative Layout Shift < 0.1
            loadTime: 3000  // Total load time < 3s
        };

        // Check budgets periodically
        setInterval(() => {
            this.checkPerformanceBudgets(budgets);
        }, 5000);
    }

    /**
     * Check performance against budgets
     */
    checkPerformanceBudgets(budgets) {
        const violations = [];

        if (this.metrics.fcp && this.metrics.fcp > budgets.fcp) {
            violations.push(`FCP: ${this.metrics.fcp}ms > ${budgets.fcp}ms`);
        }

        if (this.metrics.lcp && this.metrics.lcp > budgets.lcp) {
            violations.push(`LCP: ${this.metrics.lcp}ms > ${budgets.lcp}ms`);
        }

        if (this.metrics.fid && this.metrics.fid > budgets.fid) {
            violations.push(`FID: ${this.metrics.fid}ms > ${budgets.fid}ms`);
        }

        if (this.metrics.cls && this.metrics.cls > budgets.cls) {
            violations.push(`CLS: ${this.metrics.cls} > ${budgets.cls}`);
        }

        if (violations.length > 0) {
            console.warn('⚠️ Performance budget violations:', violations);
            this.reportBudgetViolations(violations);
        }
    }

    /**
     * Start real-time performance monitoring
     */
    startRealTimeMonitoring() {
        // Monitor memory usage
        this.monitorMemoryUsage();

        // Monitor frame rate
        this.monitorFrameRate();

        // Monitor network conditions
        this.monitorNetworkConditions();
    }

    /**
     * Monitor memory usage
     */
    monitorMemoryUsage() {
        if ('memory' in performance) {
            setInterval(() => {
                const memory = performance.memory;
                this.metrics.memory = {
                    used: Math.round(memory.usedJSHeapSize / 1048576), // MB
                    total: Math.round(memory.totalJSHeapSize / 1048576), // MB
                    limit: Math.round(memory.jsHeapSizeLimit / 1048576) // MB
                };

                // Alert if memory usage is high
                const usage = (memory.usedJSHeapSize / memory.jsHeapSizeLimit) * 100;
                if (usage > 80) {
                    console.warn('🧠 High memory usage:', usage.toFixed(1) + '%');
                }
            }, 10000);
        }
    }

    /**
     * Monitor frame rate
     */
    monitorFrameRate() {
        let frames = 0;
        let lastTime = performance.now();

        const measureFrameRate = (currentTime) => {
            frames++;

            if (currentTime >= lastTime + 1000) {
                this.metrics.fps = Math.round((frames * 1000) / (currentTime - lastTime));

                if (this.metrics.fps < 30) {
                    console.warn('🎬 Low frame rate:', this.metrics.fps + ' fps');
                }

                frames = 0;
                lastTime = currentTime;
            }

            requestAnimationFrame(measureFrameRate);
        };

        requestAnimationFrame(measureFrameRate);
    }

    /**
     * Monitor network conditions
     */
    monitorNetworkConditions() {
        if ('connection' in navigator) {
            const connection = navigator.connection;

            this.metrics.network = {
                effectiveType: connection.effectiveType,
                downlink: connection.downlink,
                rtt: connection.rtt,
                saveData: connection.saveData
            };

            // Adjust performance strategies based on connection
            if (connection.saveData || connection.effectiveType === 'slow-2g') {
                this.enableDataSaverMode();
            }

            connection.addEventListener('change', () => {
                console.log('📡 Network conditions changed:', {
                    effectiveType: connection.effectiveType,
                    downlink: connection.downlink
                });
                this.adaptToNetworkConditions(connection);
            });
        }
    }

    /**
     * Enable data saver optimizations
     */
    enableDataSaverMode() {
        console.log('💾 Data saver mode enabled');

        // Disable non-critical animations
        document.documentElement.classList.add('reduce-animations');

        // Reduce image quality
        document.querySelectorAll('img[data-src-low]').forEach(img => {
            img.src = img.dataset.srcLow;
        });

        // Defer non-critical resources
        document.querySelectorAll('link[rel="prefetch"]').forEach(link => {
            link.remove();
        });
    }

    /**
     * Adapt to network conditions
     */
    adaptToNetworkConditions(connection) {
        if (connection.effectiveType === '4g' && !connection.saveData) {
            // Fast connection - load additional resources
            this.loadEnhancedFeatures();
        } else if (connection.effectiveType === 'slow-2g' || connection.saveData) {
            // Slow connection - optimize for speed
            this.enableDataSaverMode();
        }
    }

    /**
     * Load enhanced features for fast connections
     */
    loadEnhancedFeatures() {
        // Preload more resources
        this.preloadAdditionalPages();

        // Enable high-quality images
        document.querySelectorAll('img[data-src-high]').forEach(img => {
            img.src = img.dataset.srcHigh;
        });
    }

    /**
     * Preload additional pages
     */
    preloadAdditionalPages() {
        const pages = ['team.html', 'careers.html', 'blog.html'];
        pages.forEach(page => {
            const link = document.createElement('link');
            link.rel = 'prefetch';
            link.href = page;
            document.head.appendChild(link);
        });
    }

    /**
     * Optimize images based on viewport
     */
    optimizeImages() {
        // Use Intersection Observer for progressive loading
        const imageObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    this.loadHighQualityImage(img);
                    imageObserver.unobserve(img);
                }
            });
        }, {
            rootMargin: '50px 0px'
        });

        document.querySelectorAll('img[data-src-high]').forEach(img => {
            imageObserver.observe(img);
        });
    }

    /**
     * Load high quality image
     */
    loadHighQualityImage(img) {
        const highSrc = img.dataset.srcHigh;
        if (highSrc) {
            const tempImg = new Image();
            tempImg.onload = () => {
                img.src = highSrc;
                img.classList.add('high-quality-loaded');
            };
            tempImg.src = highSrc;
        }
    }

    /**
     * Setup Intersection Observer for performance
     */
    setupIntersectionObserver() {
        // Lazy load sections
        const sectionObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animate-in');
                    this.loadSectionAssets(entry.target);
                }
            });
        });

        document.querySelectorAll('section[data-lazy]').forEach(section => {
            sectionObserver.observe(section);
        });
    }

    /**
     * Load section-specific assets
     */
    loadSectionAssets(section) {
        const sectionName = section.dataset.section;
        if (sectionName) {
            this.loadModule(`sections/${sectionName}`);
        }
    }

    /**
     * Measure Time to Interactive (TTI)
     */
    measureTTI() {
        // Simplified TTI calculation
        const entries = performance.getEntriesByType('navigation');
        if (entries.length > 0) {
            const navigationEntry = entries[0];
            this.metrics.tti = navigationEntry.domInteractive;
            console.log('⏱️ TTI measured:', this.metrics.tti);
        }
    }

    /**
     * Calculate Core Web Vitals
     */
    calculateCoreWebVitals() {
        // First Contentful Paint
        const paintEntries = performance.getEntriesByType('paint');
        const fcpEntry = paintEntries.find(entry => entry.name === 'first-contentful-paint');
        if (fcpEntry) {
            this.metrics.fcp = fcpEntry.startTime;
        }

        // Speed Index calculation (simplified)
        this.metrics.speedIndex = this.calculateSpeedIndex();

        console.log('📊 Core Web Vitals:', {
            FCP: this.metrics.fcp,
            LCP: this.metrics.lcp,
            FID: this.metrics.fid,
            CLS: this.metrics.cls,
            TTI: this.metrics.tti
        });
    }

    /**
     * Calculate Speed Index (simplified)
     */
    calculateSpeedIndex() {
        // Simplified calculation - in production would use more sophisticated methods
        const entries = performance.getEntriesByType('resource');
        const totalSize = entries.reduce((sum, entry) => sum + (entry.transferSize || 0), 0);
        const loadTime = performance.now();
        return Math.round(loadTime * (totalSize / 1000000)); // Rough estimation
    }

    /**
     * Track user interactions for performance impact
     */
    trackUserInteractions() {
        ['click', 'keydown', 'scroll'].forEach(eventType => {
            document.addEventListener(eventType, (e) => {
                const startTime = performance.now();

                // Use requestAnimationFrame to measure interaction lag
                requestAnimationFrame(() => {
                    const endTime = performance.now();
                    const interactionTime = endTime - startTime;

                    if (interactionTime > 16) { // > 1 frame at 60fps
                        console.warn('🐌 Slow interaction:', {
                            type: eventType,
                            duration: interactionTime,
                            target: e.target.tagName
                        });
                    }
                });
            }, { passive: true });
        });
    }

    /**
     * Check if feature is needed
     */
    isFeatureNeeded() {
        // Example condition - check for specific URL parameters or user agent
        return window.location.search.includes('features=advanced');
    }

    /**
     * Report budget violations
     */
    reportBudgetViolations(violations) {
        // In production, this would send to analytics
        console.error('💥 Performance Budget Violations:', violations);

        // Could trigger alerts or notifications here
        this.logPerformanceIssue('budget_violation', violations);
    }

    /**
     * Log performance issues
     */
    logPerformanceIssue(type, details) {
        const logEntry = {
            timestamp: new Date().toISOString(),
            type: type,
            details: details,
            url: window.location.href,
            userAgent: navigator.userAgent,
            metrics: this.metrics
        };

        // Store locally for now (in production would send to server)
        const performanceLogs = JSON.parse(localStorage.getItem('performance_logs') || '[]');
        performanceLogs.push(logEntry);

        // Keep only last 100 entries
        if (performanceLogs.length > 100) {
            performanceLogs.splice(0, performanceLogs.length - 100);
        }

        localStorage.setItem('performance_logs', JSON.stringify(performanceLogs));
    }

    /**
     * Report initial performance metrics
     */
    reportInitialMetrics() {
        setTimeout(() => {
            console.log('📈 Initial Performance Metrics:', this.metrics);

            // Calculate performance score (0-100)
            const score = this.calculatePerformanceScore();
            console.log(`🏆 Performance Score: ${score}/100`);

            if (score < 70) {
                console.warn('⚠️ Performance score below threshold. Consider optimizations.');
            }
        }, 3000);
    }

    /**
     * Calculate overall performance score
     */
    calculatePerformanceScore() {
        let score = 100;

        // Deduct points for poor metrics
        if (this.metrics.fcp > 2000) score -= 20;
        if (this.metrics.lcp > 2500) score -= 25;
        if (this.metrics.fid > 100) score -= 20;
        if (this.metrics.cls > 0.1) score -= 15;
        if (this.metrics.tti > 3000) score -= 20;

        return Math.max(0, score);
    }

    /**
     * Get performance report
     */
    getPerformanceReport() {
        return {
            timestamp: new Date().toISOString(),
            metrics: this.metrics,
            score: this.calculatePerformanceScore(),
            budgetViolations: this.getBudgetViolations(),
            recommendations: this.getRecommendations()
        };
    }

    /**
     * Get current budget violations
     */
    getBudgetViolations() {
        const violations = [];
        const budgets = { fcp: 1800, lcp: 2500, fid: 100, cls: 0.1 };

        Object.keys(budgets).forEach(metric => {
            if (this.metrics[metric] && this.metrics[metric] > budgets[metric]) {
                violations.push({
                    metric: metric,
                    actual: this.metrics[metric],
                    budget: budgets[metric]
                });
            }
        });

        return violations;
    }

    /**
     * Get performance recommendations
     */
    getRecommendations() {
        const recommendations = [];

        if (this.metrics.fcp > 1800) {
            recommendations.push('Optimize critical rendering path');
        }

        if (this.metrics.lcp > 2500) {
            recommendations.push('Optimize largest contentful paint element');
        }

        if (this.metrics.cls > 0.1) {
            recommendations.push('Reduce layout shifts by setting image dimensions');
        }

        if (this.metrics.longTasks && this.metrics.longTasks.length > 5) {
            recommendations.push('Break up long-running JavaScript tasks');
        }

        return recommendations;
    }

    /**
     * Add performance dashboard launcher
     */
    addDashboardLauncher() {
        // Create floating dashboard button
        const dashboardBtn = document.createElement('button');
        dashboardBtn.innerHTML = '📊';
        dashboardBtn.title = 'Open Performance Dashboard';
        dashboardBtn.style.cssText = `
            position: fixed;
            top: 20px;
            left: 20px;
            z-index: 10000;
            background: #A1C44F;
            color: white;
            border: none;
            width: 50px;
            height: 50px;
            border-radius: 50%;
            font-size: 20px;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
            transition: all 0.3s ease;
            opacity: 0.8;
        `;

        dashboardBtn.addEventListener('mouseenter', () => {
            dashboardBtn.style.transform = 'scale(1.1)';
            dashboardBtn.style.opacity = '1';
        });

        dashboardBtn.addEventListener('mouseleave', () => {
            dashboardBtn.style.transform = 'scale(1)';
            dashboardBtn.style.opacity = '0.8';
        });

        dashboardBtn.addEventListener('click', () => {
            this.openPerformanceDashboard();
        });

        document.body.appendChild(dashboardBtn);

        // Add keyboard shortcut (Ctrl+Shift+P)
        document.addEventListener('keydown', (e) => {
            if (e.ctrlKey && e.shiftKey && e.key === 'P') {
                e.preventDefault();
                this.openPerformanceDashboard();
            }
        });
    }

    /**
     * Open performance dashboard in new window
     */
    openPerformanceDashboard() {
        const dashboardUrl = 'performance-dashboard.html';
        const dashboard = window.open(
            dashboardUrl,
            'performance-dashboard',
            'width=1200,height=800,scrollbars=yes,resizable=yes'
        );

        if (dashboard) {
            dashboard.focus();
        } else {
            console.warn('Performance dashboard popup blocked. Please allow popups for this site.');
            // Fallback: navigate to dashboard in same tab
            if (confirm('Performance dashboard popup was blocked. Open in current tab?')) {
                window.location.href = dashboardUrl;
            }
        }
    }

    /**
     * Cleanup observers
     */
    cleanup() {
        Object.values(this.observers).forEach(observer => {
            if (observer && observer.disconnect) {
                observer.disconnect();
            }
        });
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.performanceOptimizer = new PerformanceOptimizer();

    // Cleanup on page unload
    window.addEventListener('beforeunload', () => {
        if (window.performanceOptimizer) {
            window.performanceOptimizer.cleanup();
        }
    });
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PerformanceOptimizer;
}