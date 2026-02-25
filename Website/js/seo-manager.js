/**
 * iBridge Enterprise SEO Manager
 * Handles advanced SEO functionality and monitoring
 */

class EnterpriseSEOManager {
    constructor() {
        this.init();
    }
    
    init() {
        this.setupLazyLoading();
        this.monitorCoreWebVitals();
        this.setupInternalLinkTracking();
        this.generateDynamicStructuredData();
        this.optimizeImages();
    }
    
    setupLazyLoading() {
        if ('loading' in HTMLImageElement.prototype) {
            const images = document.querySelectorAll('img[loading="lazy"]');
            images.forEach(img => {
                img.classList.add('seo-lazy-loaded');
            });
        } else {
            // Fallback for browsers without native lazy loading
            this.implementLazyLoading();
        }
    }
    
    monitorCoreWebVitals() {
        // Monitor Core Web Vitals for SEO
        if ('performance' in window) {
            // Largest Contentful Paint
            new PerformanceObserver((entryList) => {
                const entries = entryList.getEntries();
                const lastEntry = entries[entries.length - 1];
                console.log('LCP:', lastEntry.startTime);
            }).observe({ entryTypes: ['largest-contentful-paint'] });
            
            // Cumulative Layout Shift
            let clsValue = 0;
            new PerformanceObserver((entryList) => {
                for (const entry of entryList.getEntries()) {
                    if (!entry.hadRecentInput) {
                        clsValue += entry.value;
                        console.log('CLS:', clsValue);
                    }
                }
            }).observe({ entryTypes: ['layout-shift'] });
        }
    }
    
    setupInternalLinkTracking() {
        const internalLinks = document.querySelectorAll('a[href^="/"], a[href^="./"], a[href^="../"]');
        internalLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                // Track internal link clicks for SEO analytics
                console.log('Internal link clicked:', link.href);
            });
        });
    }
    
    generateDynamicStructuredData() {
        // Add dynamic structured data based on page content
        const pageType = this.detectPageType();
        if (pageType) {
            this.addPageSpecificStructuredData(pageType);
        }
    }
    
    detectPageType() {
        const url = window.location.pathname;
        const title = document.title.toLowerCase();
        
        if (url.includes('contact') || title.includes('contact')) {
            return 'ContactPage';
        } else if (url.includes('about') || title.includes('about')) {
            return 'AboutPage';
        } else if (url.includes('services') || title.includes('services')) {
            return 'Service';
        }
        return 'WebPage';
    }
    
    addPageSpecificStructuredData(pageType) {
        const structuredData = {
            "@context": "https://schema.org",
            "@type": pageType,
            "name": document.title,
            "description": this.getMetaDescription(),
            "url": window.location.href
        };
        
        const script = document.createElement('script');
        script.type = 'application/ld+json';
        script.textContent = JSON.stringify(structuredData);
        document.head.appendChild(script);
    }
    
    getMetaDescription() {
        const metaDesc = document.querySelector('meta[name="description"]');
        return metaDesc ? metaDesc.getAttribute('content') : '';
    }
    
    optimizeImages() {
        const images = document.querySelectorAll('img');
        images.forEach(img => {
            // Add loading optimization
            if (!img.hasAttribute('loading')) {
                img.setAttribute('loading', 'lazy');
            }
            
            // Optimize alt text for SEO
            if (!img.hasAttribute('alt') || img.getAttribute('alt') === '') {
                const altText = this.generateAltText(img);
                if (altText) {
                    img.setAttribute('alt', altText);
                }
            }
        });
    }
    
    generateAltText(img) {
        const src = img.getAttribute('src') || '';
        const className = img.getAttribute('class') || '';
        const title = img.getAttribute('title') || '';
        
        if (title) return title;
        
        // Generate based on context
        if (src.includes('logo')) return 'iBridge Contact Solutions Logo';
        if (src.includes('team')) return 'iBridge team member';
        if (className.includes('hero')) return 'Professional contact center solutions by iBridge';
        
        return 'iBridge contact center services';
    }
    
    implementLazyLoading() {
        // Fallback lazy loading implementation
        const images = document.querySelectorAll('img[data-src]');
        const imageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    img.src = img.dataset.src;
                    img.classList.remove('lazy');
                    imageObserver.unobserve(img);
                }
            });
        });
        
        images.forEach(img => imageObserver.observe(img));
    }
}

// Initialize SEO Manager when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new EnterpriseSEOManager();
});
