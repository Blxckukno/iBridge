/**
 * Enterprise Analytics Manager
 * Implements comprehensive analytics including Google Analytics 4, custom events,
 * conversion tracking, user behavior analysis, A/B testing, and business insights
 */

class AnalyticsManager {
    constructor() {
        this.config = {
            // Replace with actual tracking IDs
            googleAnalytics: {
                measurementId: 'G-XXXXXXXXXX',
                enabled: true
            },
            googleTagManager: {
                containerId: 'GTM-XXXXXXX',
                enabled: false // Enable when GTM is set up
            },
            microsoftClarity: {
                projectId: 'XXXXXXXXX',
                enabled: true
            },
            customAnalytics: {
                enabled: true,
                apiEndpoint: '/api/analytics'
            },
            consentManagement: {
                enabled: true,
                requireConsent: true
            },
            abTesting: {
                enabled: true,
                experiments: []
            }
        };

        this.events = [];
        this.userSession = {
            sessionId: this.generateSessionId(),
            userId: this.getUserId(),
            startTime: Date.now(),
            pageViews: 0,
            events: 0,
            conversions: 0
        };

        this.conversionGoals = {
            'contact_form_submit': { value: 50, currency: 'USD' },
            'phone_click': { value: 25, currency: 'USD' },
            'email_click': { value: 15, currency: 'USD' },
            'career_application': { value: 30, currency: 'USD' },
            'service_inquiry': { value: 40, currency: 'USD' },
            'newsletter_signup': { value: 10, currency: 'USD' }
        };

        this.userBehavior = {
            scrollDepth: 0,
            timeOnPage: 0,
            clickHeatmap: [],
            formInteractions: [],
            searches: []
        };

        this.init();
    }

    /**
     * Initialize Analytics Manager
     */
    init() {
        try {
            this.setupConsentManagement();
            this.initializeGoogleAnalytics();
            this.initializeMicrosoftClarity();
            this.setupCustomAnalytics();
            this.trackPageView();
            this.setupEventListeners();
            this.startUserBehaviorTracking();
            this.setupABTesting();
            this.createAnalyticsDashboard();

            console.log('📊 Analytics Manager initialized successfully');
        } catch (error) {
            console.error('❌ Analytics Manager initialization failed:', error);
        }
    }

    /**
     * Setup consent management
     */
    setupConsentManagement() {
        if (!this.config.consentManagement.enabled) return;

        // Check for existing consent
        this.hasConsent = localStorage.getItem('analytics_consent') === 'granted';

        if (!this.hasConsent && this.config.consentManagement.requireConsent) {
            this.showConsentBanner();
        }
    }

    /**
     * Show consent banner
     */
    showConsentBanner() {
        const banner = document.createElement('div');
        banner.className = 'analytics-consent-banner';
        banner.innerHTML = `
            <div class="consent-content">
                <div class="consent-text">
                    <h4>🍪 We value your privacy</h4>
                    <p>We use analytics cookies to improve your experience and understand how our website is used. This helps us provide better services.</p>
                </div>
                <div class="consent-actions">
                    <button class="consent-btn accept" onclick="analyticsManager.grantConsent()">
                        Accept Analytics
                    </button>
                    <button class="consent-btn decline" onclick="analyticsManager.denyConsent()">
                        Essential Only
                    </button>
                    <button class="consent-btn manage" onclick="analyticsManager.showConsentSettings()">
                        Manage Settings
                    </button>
                </div>
            </div>
        `;

        banner.style.cssText = `
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background: #2C3E50;
            color: white;
            padding: 1rem;
            z-index: 10001;
            box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.2);
            transform: translateY(100%);
            transition: transform 0.3s ease;
        `;

        document.body.appendChild(banner);

        // Animate in
        setTimeout(() => {
            banner.style.transform = 'translateY(0)';
        }, 100);
    }

    /**
     * Grant analytics consent
     */
    grantConsent() {
        localStorage.setItem('analytics_consent', 'granted');
        this.hasConsent = true;
        this.hideConsentBanner();
        this.initializeTrackingServices();
        this.trackEvent('consent_granted', { method: 'banner' });
    }

    /**
     * Deny analytics consent
     */
    denyConsent() {
        localStorage.setItem('analytics_consent', 'denied');
        this.hasConsent = false;
        this.hideConsentBanner();
        this.trackEvent('consent_denied', { method: 'banner' });
    }

    /**
     * Hide consent banner
     */
    hideConsentBanner() {
        const banner = document.querySelector('.analytics-consent-banner');
        if (banner) {
            banner.style.transform = 'translateY(100%)';
            setTimeout(() => banner.remove(), 300);
        }
    }

    /**
     * Initialize Google Analytics 4
     */
    initializeGoogleAnalytics() {
        if (!this.config.googleAnalytics.enabled || !this.hasConsent) return;

        // Load gtag script
        const script = document.createElement('script');
        script.async = true;
        script.src = `https://www.googletagmanager.com/gtag/js?id=${this.config.googleAnalytics.measurementId}`;
        document.head.appendChild(script);

        // Initialize gtag
        window.dataLayer = window.dataLayer || [];
        function gtag() { dataLayer.push(arguments); }
        window.gtag = gtag;

        gtag('js', new Date());
        gtag('config', this.config.googleAnalytics.measurementId, {
            // Enhanced ecommerce and user engagement
            send_page_view: true,
            allow_enhanced_conversions: true,
            allow_google_signals: true,
            cookie_expires: 63072000, // 2 years

            // Custom parameters
            custom_map: {
                'custom_parameter_1': 'user_type',
                'custom_parameter_2': 'page_category'
            }
        });

        console.log('✅ Google Analytics 4 initialized');
    }

    /**
     * Initialize Microsoft Clarity
     */
    initializeMicrosoftClarity() {
        if (!this.config.microsoftClarity.enabled || !this.hasConsent) return;

        (function (c, l, a, r, i, t, y) {
            c[a] = c[a] || function () { (c[a].q = c[a].q || []).push(arguments) };
            t = l.createElement(r); t.async = 1; t.src = "https://www.clarity.ms/tag/" + i;
            y = l.getElementsByTagName(r)[0]; y.parentNode.insertBefore(t, y);
        })(window, document, "clarity", "script", this.config.microsoftClarity.projectId);

        console.log('✅ Microsoft Clarity initialized');
    }

    /**
     * Setup custom analytics
     */
    setupCustomAnalytics() {
        if (!this.config.customAnalytics.enabled) return;

        // Set up custom event queue
        this.eventQueue = [];
        this.flushInterval = 30000; // 30 seconds

        // Start periodic flush
        setInterval(() => {
            this.flushEventQueue();
        }, this.flushInterval);

        console.log('✅ Custom analytics initialized');
    }

    /**
     * Track page view
     */
    trackPageView() {
        const pageData = {
            page_title: document.title,
            page_location: window.location.href,
            page_path: window.location.pathname,
            page_referrer: document.referrer,
            timestamp: new Date().toISOString(),
            session_id: this.userSession.sessionId,
            user_id: this.userSession.userId
        };

        // Google Analytics
        if (this.hasConsent && window.gtag) {
            gtag('event', 'page_view', pageData);
        }

        // Custom analytics
        this.trackCustomEvent('page_view', pageData);

        this.userSession.pageViews++;
        console.log('📄 Page view tracked:', pageData.page_path);
    }

    /**
     * Track custom event
     */
    trackEvent(eventName, parameters = {}) {
        const eventData = {
            event_name: eventName,
            timestamp: new Date().toISOString(),
            session_id: this.userSession.sessionId,
            user_id: this.userSession.userId,
            page_path: window.location.pathname,
            ...parameters
        };

        // Google Analytics
        if (this.hasConsent && window.gtag) {
            gtag('event', eventName, parameters);
        }

        // Microsoft Clarity
        if (this.hasConsent && window.clarity) {
            clarity('set', eventName, JSON.stringify(parameters));
        }

        // Custom analytics
        this.trackCustomEvent(eventName, eventData);

        this.events.push(eventData);
        this.userSession.events++;

        // Check for conversion goals
        if (this.conversionGoals[eventName]) {
            this.trackConversion(eventName, this.conversionGoals[eventName]);
        }

        console.log('🎯 Event tracked:', eventName, parameters);
    }

    /**
     * Track custom event for internal analytics
     */
    trackCustomEvent(eventName, data) {
        if (!this.config.customAnalytics.enabled) return;

        this.eventQueue.push({
            event: eventName,
            data: data,
            timestamp: Date.now()
        });
    }

    /**
     * Track conversion
     */
    trackConversion(goalName, goalData) {
        const conversionData = {
            goal_name: goalName,
            value: goalData.value,
            currency: goalData.currency,
            timestamp: new Date().toISOString()
        };

        // Google Analytics Enhanced Ecommerce
        if (this.hasConsent && window.gtag) {
            gtag('event', 'purchase', {
                transaction_id: this.generateTransactionId(),
                value: goalData.value,
                currency: goalData.currency,
                items: [{
                    item_id: goalName,
                    item_name: goalName.replace(/_/g, ' '),
                    category: 'conversion',
                    quantity: 1,
                    price: goalData.value
                }]
            });
        }

        this.trackCustomEvent('conversion', conversionData);
        this.userSession.conversions++;

        console.log('💰 Conversion tracked:', goalName, goalData);
    }

    /**
     * Setup event listeners for automatic tracking
     */
    setupEventListeners() {
        // Form submissions
        document.addEventListener('submit', (e) => {
            const form = e.target;
            if (form.tagName === 'FORM') {
                const formId = form.id || form.className || 'unknown_form';
                this.trackEvent('form_submit', {
                    form_id: formId,
                    form_name: form.name || formId
                });
            }
        });

        // External link clicks
        document.addEventListener('click', (e) => {
            const link = e.target.closest('a');
            if (link && link.href) {
                const isExternal = !link.href.includes(window.location.hostname);
                const isEmail = link.href.startsWith('mailto:');
                const isPhone = link.href.startsWith('tel:');
                const isDownload = this.isDownloadLink(link.href);

                if (isExternal) {
                    this.trackEvent('external_link_click', {
                        url: link.href,
                        text: link.textContent.trim()
                    });
                } else if (isEmail) {
                    this.trackEvent('email_click', {
                        email: link.href.replace('mailto:', ''),
                        text: link.textContent.trim()
                    });
                } else if (isPhone) {
                    this.trackEvent('phone_click', {
                        phone: link.href.replace('tel:', ''),
                        text: link.textContent.trim()
                    });
                } else if (isDownload) {
                    this.trackEvent('file_download', {
                        file_name: link.href.split('/').pop(),
                        file_url: link.href
                    });
                }

                // Track click heatmap
                this.trackClickHeatmap(e);
            }
        });

        // Scroll depth tracking
        let maxScrollDepth = 0;
        const scrollThresholds = [25, 50, 75, 90, 100];

        window.addEventListener('scroll', () => {
            const scrollPercent = Math.round(
                (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100
            );

            if (scrollPercent > maxScrollDepth) {
                maxScrollDepth = scrollPercent;
                this.userBehavior.scrollDepth = maxScrollDepth;

                // Track milestone scroll depths
                scrollThresholds.forEach(threshold => {
                    if (maxScrollDepth >= threshold && !this.scrollTracked?.[threshold]) {
                        this.scrollTracked = this.scrollTracked || {};
                        this.scrollTracked[threshold] = true;
                        this.trackEvent('scroll_depth', {
                            scroll_depth: threshold,
                            page_path: window.location.pathname
                        });
                    }
                });
            }
        });

        // Time on page tracking
        this.startTime = Date.now();
        window.addEventListener('beforeunload', () => {
            const timeOnPage = Math.round((Date.now() - this.startTime) / 1000);
            this.userBehavior.timeOnPage = timeOnPage;

            this.trackEvent('time_on_page', {
                duration_seconds: timeOnPage,
                page_path: window.location.pathname
            });
        });

        // Search tracking (if search functionality exists)
        const searchInputs = document.querySelectorAll('input[type="search"], input[name*="search"], .search-input');
        searchInputs.forEach(input => {
            input.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' && input.value.trim()) {
                    this.trackEvent('search', {
                        search_term: input.value.trim(),
                        search_type: 'site_search'
                    });
                }
            });
        });
    }

    /**
     * Track click heatmap
     */
    trackClickHeatmap(event) {
        const clickData = {
            x: event.clientX,
            y: event.clientY,
            elementTag: event.target.tagName,
            elementClass: event.target.className,
            elementId: event.target.id,
            timestamp: Date.now(),
            viewportWidth: window.innerWidth,
            viewportHeight: window.innerHeight
        };

        this.userBehavior.clickHeatmap.push(clickData);

        // Limit heatmap data to prevent memory issues
        if (this.userBehavior.clickHeatmap.length > 100) {
            this.userBehavior.clickHeatmap.shift();
        }
    }

    /**
     * Setup A/B testing
     */
    setupABTesting() {
        if (!this.config.abTesting.enabled) return;

        // Example A/B test configuration
        const experiments = [
            {
                name: 'cta_button_color',
                variations: ['blue', 'green', 'orange'],
                selector: '.cta-button',
                traffic: 0.5 // 50% of users
            },
            {
                name: 'hero_headline',
                variations: ['original', 'benefit_focused', 'question_based'],
                selector: '.hero-headline',
                traffic: 0.3 // 30% of users
            }
        ];

        experiments.forEach(experiment => {
            if (Math.random() < experiment.traffic) {
                const variation = this.assignVariation(experiment);
                this.applyVariation(experiment, variation);
                this.trackEvent('ab_test_assignment', {
                    experiment_name: experiment.name,
                    variation: variation
                });
            }
        });
    }

    /**
     * Assign A/B test variation
     */
    assignVariation(experiment) {
        const userHash = this.hashUserId(this.userSession.userId + experiment.name);
        const variationIndex = Math.floor(userHash * experiment.variations.length);
        return experiment.variations[variationIndex];
    }

    /**
     * Apply A/B test variation
     */
    applyVariation(experiment, variation) {
        const elements = document.querySelectorAll(experiment.selector);
        elements.forEach(element => {
            element.classList.add(`ab-${experiment.name}-${variation}`);
            element.setAttribute('data-ab-experiment', experiment.name);
            element.setAttribute('data-ab-variation', variation);
        });
    }

    /**
     * Start user behavior tracking
     */
    startUserBehaviorTracking() {
        // Track form interactions
        const forms = document.querySelectorAll('form');
        forms.forEach(form => {
            const inputs = form.querySelectorAll('input, textarea, select');
            inputs.forEach(input => {
                input.addEventListener('focus', () => {
                    this.userBehavior.formInteractions.push({
                        action: 'focus',
                        field: input.name || input.id || input.type,
                        timestamp: Date.now()
                    });
                });

                input.addEventListener('blur', () => {
                    this.userBehavior.formInteractions.push({
                        action: 'blur',
                        field: input.name || input.id || input.type,
                        value_length: input.value.length,
                        timestamp: Date.now()
                    });
                });
            });
        });

        // Track page visibility
        document.addEventListener('visibilitychange', () => {
            this.trackEvent('page_visibility_change', {
                visibility_state: document.visibilityState,
                hidden: document.hidden
            });
        });
    }

    /**
     * Create analytics dashboard button
     */
    createAnalyticsDashboard() {
        const dashboardBtn = document.createElement('button');
        dashboardBtn.innerHTML = '📊';
        dashboardBtn.title = 'Open Analytics Dashboard';
        dashboardBtn.style.cssText = `
            position: fixed;
            top: 20px;
            right: 200px;
            z-index: 10000;
            background: #17a2b8;
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
            this.openAnalyticsDashboard();
        });

        document.body.appendChild(dashboardBtn);
    }

    /**
     * Open analytics dashboard
     */
    openAnalyticsDashboard() {
        const dashboardData = this.getAnalyticsReport();
        const dashboard = window.open('', 'analytics-dashboard', 'width=1200,height=800,scrollbars=yes,resizable=yes');

        dashboard.document.write(this.generateDashboardHTML(dashboardData));
        dashboard.document.close();
        dashboard.focus();
    }

    /**
     * Generate dashboard HTML
     */
    generateDashboardHTML(data) {
        return `
        <!DOCTYPE html>
        <html>
        <head>
            <title>Analytics Dashboard - iBridge</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
                .header { background: #17a2b8; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
                .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px; }
                .metric-card { background: white; padding: 20px; border-radius: 8px; text-align: center; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                .metric-value { font-size: 2em; font-weight: bold; color: #17a2b8; }
                .metric-label { color: #666; margin-top: 5px; }
                .chart-section { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                .event-list { max-height: 300px; overflow-y: auto; }
                .event-item { padding: 10px; border-bottom: 1px solid #eee; }
                .refresh-btn { background: #28a745; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>📊 Analytics Dashboard</h1>
                <p>Real-time analytics for iBridge Contact Solutions</p>
                <button class="refresh-btn" onclick="window.location.reload()">Refresh Data</button>
            </div>
            
            <div class="metrics-grid">
                <div class="metric-card">
                    <div class="metric-value">${data.session.pageViews}</div>
                    <div class="metric-label">Page Views</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${data.session.events}</div>
                    <div class="metric-label">Events</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${data.session.conversions}</div>
                    <div class="metric-label">Conversions</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${Math.round(data.behavior.timeOnPage / 60)}m</div>
                    <div class="metric-label">Time on Site</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${data.behavior.scrollDepth}%</div>
                    <div class="metric-label">Max Scroll</div>
                </div>
            </div>
            
            <div class="chart-section">
                <h3>Recent Events</h3>
                <div class="event-list">
                    ${data.events.slice(-20).map(event => `
                        <div class="event-item">
                            <strong>${event.event_name}</strong> - ${new Date(event.timestamp).toLocaleTimeString()}
                            <div style="font-size: 0.9em; color: #666;">${JSON.stringify(event.data || {})}</div>
                        </div>
                    `).join('')}
                </div>
            </div>
            
            <div class="chart-section">
                <h3>User Behavior Summary</h3>
                <p><strong>Session ID:</strong> ${data.session.sessionId}</p>
                <p><strong>User ID:</strong> ${data.session.userId}</p>
                <p><strong>Session Start:</strong> ${new Date(data.session.startTime).toLocaleString()}</p>
                <p><strong>Form Interactions:</strong> ${data.behavior.formInteractions.length}</p>
                <p><strong>Click Heatmap Points:</strong> ${data.behavior.clickHeatmap.length}</p>
            </div>
            
            <script>
                console.log('Analytics Dashboard Data:', ${JSON.stringify(data, null, 2)});
            </script>
        </body>
        </html>
        `;
    }

    /**
     * Flush event queue to server
     */
    flushEventQueue() {
        if (this.eventQueue.length === 0) return;

        // In a real implementation, send to your analytics API
        console.log('📤 Flushing analytics events:', this.eventQueue.length);

        // Clear queue after successful send
        this.eventQueue = [];
    }

    /**
     * Helper methods
     */
    generateSessionId() {
        return 'sess_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    getUserId() {
        let userId = localStorage.getItem('analytics_user_id');
        if (!userId) {
            userId = 'user_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            localStorage.setItem('analytics_user_id', userId);
        }
        return userId;
    }

    generateTransactionId() {
        return 'txn_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    hashUserId(input) {
        let hash = 0;
        for (let i = 0; i < input.length; i++) {
            const char = input.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32-bit integer
        }
        return Math.abs(hash) / Math.pow(2, 32);
    }

    isDownloadLink(url) {
        const downloadExtensions = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.zip', '.rar'];
        return downloadExtensions.some(ext => url.toLowerCase().includes(ext));
    }

    /**
     * Get comprehensive analytics report
     */
    getAnalyticsReport() {
        return {
            timestamp: new Date().toISOString(),
            session: this.userSession,
            behavior: this.userBehavior,
            events: this.events,
            config: this.config,
            consent: this.hasConsent
        };
    }

    /**
     * Initialize tracking services after consent
     */
    initializeTrackingServices() {
        this.initializeGoogleAnalytics();
        this.initializeMicrosoftClarity();
    }

    /**
     * Show consent settings modal
     */
    showConsentSettings() {
        // Implementation for detailed consent management
        alert('Consent settings would open here with granular controls for different tracking services.');
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.analyticsManager = new AnalyticsManager();

    // Cleanup on page unload
    window.addEventListener('beforeunload', () => {
        if (window.analyticsManager) {
            window.analyticsManager.flushEventQueue();
        }
    });
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AnalyticsManager;
}