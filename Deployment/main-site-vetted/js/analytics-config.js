/**
 * Analytics Configuration for iBridge Contact Solutions
 * Configure your tracking IDs and analytics settings here
 */

window.iBridgeAnalyticsConfig = {
    // Google Analytics 4 Configuration
    googleAnalytics: {
        measurementId: 'G-XXXXXXXXXX', // Replace with your GA4 Measurement ID
        enabled: true,
        enhanced_conversions: true,
        google_signals: true,
        send_page_view: true
    },

    // Google Tag Manager (Optional)
    googleTagManager: {
        containerId: 'GTM-XXXXXXX', // Replace with your GTM Container ID
        enabled: false // Set to true when GTM is configured
    },

    // Microsoft Clarity (Heatmaps & Session Recordings)
    microsoftClarity: {
        projectId: 'XXXXXXXXX', // Replace with your Clarity Project ID
        enabled: true
    },

    // Facebook Pixel (Optional)
    facebookPixel: {
        pixelId: 'XXXXXXXXXXXXXXX', // Replace with your Facebook Pixel ID
        enabled: false
    },

    // LinkedIn Insight Tag (Optional)
    linkedinInsight: {
        partnerId: 'XXXXXXX', // Replace with your LinkedIn Partner ID
        enabled: false
    },

    // Custom Analytics API
    customAnalytics: {
        enabled: true,
        apiEndpoint: '/api/analytics', // Your backend analytics endpoint
        batchSize: 50,
        flushInterval: 30000, // 30 seconds
        retryAttempts: 3
    },

    // Privacy & Consent Management
    privacySettings: {
        requireConsent: true,
        consentDuration: 365, // days
        respectDoNotTrack: true,
        anonymizeIP: true,
        cookieSameSite: 'Lax'
    },

    // Conversion Goals & Values
    conversionGoals: {
        'contact_form_submit': {
            value: 50,
            currency: 'USD',
            category: 'lead_generation'
        },
        'phone_click': {
            value: 25,
            currency: 'USD',
            category: 'contact_intent'
        },
        'email_click': {
            value: 15,
            currency: 'USD',
            category: 'contact_intent'
        },
        'career_application': {
            value: 30,
            currency: 'USD',
            category: 'recruitment'
        },
        'service_inquiry': {
            value: 40,
            currency: 'USD',
            category: 'lead_generation'
        },
        'newsletter_signup': {
            value: 10,
            currency: 'USD',
            category: 'engagement'
        },
        'brochure_download': {
            value: 20,
            currency: 'USD',
            category: 'content_engagement'
        },
        'quote_request': {
            value: 75,
            currency: 'USD',
            category: 'lead_generation'
        }
    },

    // A/B Testing Configuration
    abTesting: {
        enabled: true,
        experiments: [
            {
                name: 'cta_button_color',
                variations: ['blue', 'green', 'orange'],
                selector: '.cta-button',
                traffic: 0.5, // 50% of users
                objectives: ['click_rate', 'conversion_rate']
            },
            {
                name: 'hero_headline',
                variations: ['original', 'benefit_focused', 'question_based'],
                selector: '.hero-headline',
                traffic: 0.3, // 30% of users
                objectives: ['engagement_time', 'scroll_depth']
            },
            {
                name: 'contact_form_position',
                variations: ['top', 'middle', 'bottom'],
                selector: '.contact-section',
                traffic: 0.4, // 40% of users
                objectives: ['form_completion_rate']
            }
        ]
    },

    // Real-time Monitoring
    monitoring: {
        enabled: true,
        performanceThresholds: {
            pageLloadTime: 3000, // milliseconds
            firstContentfulPaint: 1800,
            largestContentfulPaint: 2500,
            cumulativeLayoutShift: 0.1,
            firstInputDelay: 100
        },
        alertEndpoint: '/api/performance-alerts',
        businessHours: {
            start: 9, // 9 AM
            end: 17, // 5 PM
            timezone: 'America/New_York'
        }
    },

    // Event Tracking Configuration
    eventTracking: {
        scrollDepthThresholds: [25, 50, 75, 90, 100],
        formInteractionTracking: true,
        linkClickTracking: true,
        fileDownloadTracking: true,
        errorTracking: true,
        performanceTracking: true,
        searchTracking: true
    },

    // Dashboard Configuration
    dashboard: {
        enabled: true,
        position: 'bottom-right',
        minimized: false,
        autoRefresh: 60000, // 1 minute
        showMetrics: [
            'pageViews',
            'uniqueVisitors',
            'conversionRate',
            'avgSessionDuration',
            'bounceRate',
            'topPages'
        ]
    },

    // Data Export Settings
    dataExport: {
        formats: ['json', 'csv', 'pdf'],
        scheduledReports: {
            daily: {
                enabled: true,
                time: '09:00',
                recipients: ['admin@ibridge-solutions.com']
            },
            weekly: {
                enabled: true,
                day: 'monday',
                time: '09:00',
                recipients: ['admin@ibridge-solutions.com', 'marketing@ibridge-solutions.com']
            },
            monthly: {
                enabled: true,
                date: 1,
                time: '09:00',
                recipients: ['admin@ibridge-solutions.com', 'executives@ibridge-solutions.com']
            }
        }
    },

    // Integration Settings
    integrations: {
        crm: {
            enabled: false,
            endpoint: '/api/crm-sync',
            syncInterval: 3600000 // 1 hour
        },
        emailMarketing: {
            enabled: false,
            platform: 'mailchimp', // or 'sendgrid', 'constantcontact'
            apiKey: 'your-api-key'
        },
        helpdesk: {
            enabled: false,
            platform: 'zendesk', // or 'freshdesk', 'intercom'
            apiEndpoint: '/api/helpdesk-sync'
        }
    }
};

// Apply configuration to analytics manager when available
document.addEventListener('DOMContentLoaded', function () {
    if (typeof analyticsManager !== 'undefined' && window.iBridgeAnalyticsConfig) {
        // Merge configurations
        Object.assign(analyticsManager.config, window.iBridgeAnalyticsConfig);

        console.log('📊 Analytics configuration applied');

        // Initialize custom tracking based on configuration
        if (window.iBridgeAnalyticsConfig.eventTracking.errorTracking) {
            window.addEventListener('error', function (error) {
                analyticsManager.trackEvent('javascript_error', {
                    message: error.message,
                    filename: error.filename,
                    lineno: error.lineno,
                    colno: error.colno
                });
            });
        }

        // Track performance metrics
        if (window.iBridgeAnalyticsConfig.eventTracking.performanceTracking) {
            window.addEventListener('load', function () {
                setTimeout(() => {
                    const perfData = performance.getEntriesByType('navigation')[0];
                    if (perfData) {
                        analyticsManager.trackEvent('page_performance', {
                            load_time: perfData.loadEventEnd - perfData.navigationStart,
                            dom_ready: perfData.domContentLoadedEventEnd - perfData.navigationStart,
                            first_byte: perfData.responseStart - perfData.navigationStart
                        });
                    }
                }, 1000);
            });
        }
    }
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = window.iBridgeAnalyticsConfig;
}