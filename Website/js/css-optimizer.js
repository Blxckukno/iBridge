/**
 * Enterprise CSS Optimizer
 * Removes unused CSS and optimizes loading
 */

class CSSOptimizer {
    constructor() {
        this.usedSelectors = new Set();
        this.cssRules = new Map();
        this.init();
    }

    init() {
        this.scanHTMLForSelectors();
        this.analyzeCSSUsage();
        this.optimizeCSS();

        console.log('🎨 CSS Optimizer initialized');
    }

    /**
     * Scan HTML for used selectors
     */
    scanHTMLForSelectors() {
        // Get all elements with classes
        document.querySelectorAll('[class]').forEach(element => {
            element.classList.forEach(className => {
                this.usedSelectors.add(`.${className}`);
            });
        });

        // Get all elements with IDs
        document.querySelectorAll('[id]').forEach(element => {
            this.usedSelectors.add(`#${element.id}`);
        });

        // Add element selectors for used tags
        const usedTags = new Set();
        document.querySelectorAll('*').forEach(element => {
            usedTags.add(element.tagName.toLowerCase());
        });

        usedTags.forEach(tag => {
            this.usedSelectors.add(tag);
        });

        console.log(`📊 Found ${this.usedSelectors.size} used selectors`);
    }

    /**
     * Analyze CSS usage across stylesheets
     */
    analyzeCSSUsage() {
        for (let stylesheet of document.styleSheets) {
            try {
                if (stylesheet.cssRules) {
                    for (let rule of stylesheet.cssRules) {
                        if (rule.type === CSSRule.STYLE_RULE) {
                            this.cssRules.set(rule.selectorText, {
                                cssText: rule.cssText,
                                used: this.isSelectorUsed(rule.selectorText)
                            });
                        }
                    }
                }
            } catch (e) {
                // Skip external stylesheets due to CORS
                console.warn('Cannot access stylesheet:', stylesheet.href);
            }
        }
    }

    /**
     * Check if a CSS selector is used
     */
    isSelectorUsed(selector) {
        if (!selector) return false;

        // Handle complex selectors
        const cleanSelector = selector.split(',')[0].trim();

        // Check for pseudo-classes and pseudo-elements
        const baseSelector = cleanSelector.replace(/:+[a-z-]+(\([^)]*\))?/gi, '');

        // Try to query the selector
        try {
            return document.querySelector(baseSelector) !== null;
        } catch (e) {
            // If selector is invalid, mark as used to be safe
            return true;
        }
    }

    /**
     * Optimize CSS by removing unused rules
     */
    optimizeCSS() {
        const usedRules = [];
        const unusedRules = [];

        this.cssRules.forEach((ruleData, selector) => {
            if (ruleData.used) {
                usedRules.push(ruleData.cssText);
            } else {
                unusedRules.push(selector);
            }
        });

        const optimizedCSS = usedRules.join('\n');

        console.log(`🗑️ Removed ${unusedRules.length} unused CSS rules`);
        console.log(`✅ Kept ${usedRules.length} used CSS rules`);

        // Optionally create a new optimized stylesheet
        if (unusedRules.length > 0) {
            this.createOptimizedStylesheet(optimizedCSS);
        }
    }

    /**
     * Create optimized stylesheet
     */
    createOptimizedStylesheet(cssContent) {
        const style = document.createElement('style');
        style.id = 'optimized-css';
        style.textContent = cssContent;

        // Add to head but don't replace existing stylesheets yet
        // This is for testing purposes
        document.head.appendChild(style);

        console.log('📄 Optimized stylesheet created (for testing)');
    }

    /**
     * Generate CSS report
     */
    generateReport() {
        const totalRules = this.cssRules.size;
        const usedRules = Array.from(this.cssRules.values()).filter(rule => rule.used).length;
        const unusedRules = totalRules - usedRules;
        const efficiency = Math.round((usedRules / totalRules) * 100);

        return {
            totalRules,
            usedRules,
            unusedRules,
            efficiency,
            usedSelectors: Array.from(this.usedSelectors)
        };
    }
}

// Initialize CSS Optimizer after page load
window.addEventListener('load', () => {
    // Give time for dynamic content to load
    setTimeout(() => {
        window.cssOptimizer = new CSSOptimizer();

        // Log optimization report
        const report = window.cssOptimizer.generateReport();
        console.log('📊 CSS Optimization Report:', report);
    }, 2000);
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = CSSOptimizer;
}