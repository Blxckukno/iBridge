/**
 * Enterprise Asset Loader
 * Dynamically loads optimized CSS and JavaScript based on performance conditions
 */

class AssetLoader {
    constructor() {
        this.loadedAssets = new Set();
        this.connectionType = this.getConnectionType();
        this.init();
    }

    init() {
        this.loadCriticalCSS();
        this.preloadAssets();
        this.setupLazyLoading();

        console.log('🚀 Asset Loader initialized with', this.connectionType, 'connection');
    }

    /**
     * Detect connection type for adaptive loading
     */
    getConnectionType() {
        if ('connection' in navigator) {
            return navigator.connection.effectiveType || 'unknown';
        }
        return 'unknown';
    }

    /**
     * Load critical CSS immediately
     */
    loadCriticalCSS() {
        const criticalCSS = document.createElement('link');
        criticalCSS.rel = 'stylesheet';
        criticalCSS.href = 'assets/min/critical.min.css';
        criticalCSS.media = 'all';
        document.head.appendChild(criticalCSS);
    }

    /**
     * Preload important assets
     */
    preloadAssets() {
        const assetsToPreload = [
            { href: 'assets/min/styles.min.css', as: 'style' },
            { href: 'assets/min/image-optimization.min.css', as: 'style' },
            { href: 'assets/min/image-optimizer.min.js', as: 'script' }
        ];

        // Only preload on fast connections
        if (this.connectionType === '4g' || this.connectionType === 'unknown') {
            assetsToPreload.forEach(asset => {
                const link = document.createElement('link');
                link.rel = 'preload';
                link.href = asset.href;
                link.as = asset.as;
                document.head.appendChild(link);
            });
        }
    }

    /**
     * Load non-critical CSS asynchronously
     */
    loadCSS(href, media = 'all') {
        return new Promise((resolve, reject) => {
            if (this.loadedAssets.has(href)) {
                resolve();
                return;
            }

            const link = document.createElement('link');
            link.rel = 'stylesheet';
            link.href = href;
            link.media = media;

            link.onload = () => {
                this.loadedAssets.add(href);
                resolve();
            };

            link.onerror = () => reject(new Error(`Failed to load CSS: ${href}`));

            document.head.appendChild(link);
        });
    }

    /**
     * Load JavaScript dynamically
     */
    loadJS(src) {
        return new Promise((resolve, reject) => {
            if (this.loadedAssets.has(src)) {
                resolve();
                return;
            }

            const script = document.createElement('script');
            script.src = src;
            script.async = true;

            script.onload = () => {
                this.loadedAssets.add(src);
                resolve();
            };

            script.onerror = () => reject(new Error(`Failed to load JS: ${src}`));

            document.head.appendChild(script);
        });
    }

    /**
     * Setup lazy loading for non-critical assets
     */
    setupLazyLoading() {
        // Load remaining CSS after page load
        window.addEventListener('load', () => {
            setTimeout(() => {
                this.loadCSS('assets/min/styles.min.css');
                this.loadCSS('assets/min/image-optimization.min.css');
            }, 100);
        });

        // Load JavaScript on interaction
        const events = ['scroll', 'mouseover', 'click', 'touchstart'];
        const loadInteractiveJS = () => {
            this.loadJS('assets/min/image-optimizer.min.js');
            this.loadJS('assets/min/ibridge-auth.min.js');

            // Remove event listeners after first interaction
            events.forEach(event => {
                document.removeEventListener(event, loadInteractiveJS, { passive: true });
            });
        };

        events.forEach(event => {
            document.addEventListener(event, loadInteractiveJS, { passive: true });
        });
    }

    /**
     * Load assets based on viewport
     */
    loadOnVisibility(selector, assets) {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    assets.forEach(asset => {
                        if (asset.type === 'css') {
                            this.loadCSS(asset.href);
                        } else if (asset.type === 'js') {
                            this.loadJS(asset.src);
                        }
                    });
                    observer.unobserve(entry.target);
                }
            });
        });

        document.querySelectorAll(selector).forEach(el => {
            observer.observe(el);
        });
    }

    /**
     * Bundle and cache management
     */
    cacheAssets() {
        if ('caches' in window) {
            caches.open('ibridge-assets-v1').then(cache => {
                const assetsToCache = [
                    'assets/min/critical.min.css',
                    'assets/min/styles.min.css',
                    'assets/min/image-optimization.min.css',
                    'assets/min/image-optimizer.min.js',
                    'assets/min/ibridge-auth.min.js'
                ];

                cache.addAll(assetsToCache).then(() => {
                    console.log('✅ Assets cached successfully');
                });
            });
        }
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.assetLoader = new AssetLoader();

    // Cache assets for offline usage
    if ('serviceWorker' in navigator) {
        window.assetLoader.cacheAssets();
    }
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AssetLoader;
}