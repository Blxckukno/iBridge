/**
 * iBridge Advanced Analytics System v1.0
 * Comprehensive user behavior, security events, and performance analytics
 * Created: October 28, 2025
 */

class AdvancedAnalytics {
    constructor() {
        this.sessionId = this.generateSessionId();
        this.userId = this.getUserId();
        this.startTime = Date.now();
        this.events = [];
        this.metrics = {
            pageViews: 0,
            userInteractions: 0,
            errors: 0,
            performance: {},
            security: {},
            engagement: {}
        };
        this.heatmapData = [];
        this.scrollData = [];
        this.clickData = [];
        this.config = {
            batchSize: 10,
            sendInterval: 30000, // 30 seconds
            enableHeatmap: true,
            enableScrollTracking: true,
            enableErrorTracking: true,
            enableSecurityTracking: true,
            enablePerformanceTracking: true
        };
        this.init();
    }

    init() {
        this.setupEventTracking();
        this.setupPerformanceTracking();
        this.setupSecurityTracking();
        this.setupHeatmapTracking();
        this.setupScrollTracking();
        this.setupErrorTracking();
        this.setupEngagementTracking();
        this.setupBatchSending();
        this.createAnalyticsDashboard();
        this.startSession();
    }

    generateSessionId() {
        return 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    getUserId() {
        let userId = localStorage.getItem('iBridge-user-id');
        if (!userId) {
            userId = 'user_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            localStorage.setItem('iBridge-user-id', userId);
        }
        return userId;
    }

    setupEventTracking() {
        // Track page views
        this.trackEvent('page_view', {
            url: window.location.href,
            title: document.title,
            referrer: document.referrer,
            userAgent: navigator.userAgent,
            viewport: {
                width: window.innerWidth,
                height: window.innerHeight
            }
        });

        // Track clicks
        document.addEventListener('click', (e) => {
            const element = e.target;
            const elementInfo = this.getElementInfo(element);

            this.trackEvent('click', {
                element: elementInfo,
                coordinates: { x: e.clientX, y: e.clientY },
                timestamp: Date.now()
            });

            // Store click data for heatmap
            if (this.config.enableHeatmap) {
                this.clickData.push({
                    x: e.clientX,
                    y: e.clientY,
                    timestamp: Date.now(),
                    element: elementInfo.tagName
                });
            }
        });

        // Track form interactions
        document.addEventListener('submit', (e) => {
            const form = e.target;
            this.trackEvent('form_submit', {
                formId: form.id,
                formClass: form.className,
                fields: Array.from(form.elements).map(el => ({
                    name: el.name,
                    type: el.type,
                    value: el.type === 'password' ? '[HIDDEN]' : el.value?.substring(0, 100)
                }))
            });
        });

        // Track input focus
        document.addEventListener('focusin', (e) => {
            if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                this.trackEvent('input_focus', {
                    element: this.getElementInfo(e.target)
                });
            }
        });

        // Track navigation
        window.addEventListener('beforeunload', () => {
            this.trackEvent('page_unload', {
                timeOnPage: Date.now() - this.startTime,
                scrollDepth: this.calculateScrollDepth()
            });
            this.sendBatch(true); // Force send before leaving
        });
    }

    setupPerformanceTracking() {
        if (!this.config.enablePerformanceTracking) return;

        // Track page load performance
        window.addEventListener('load', () => {
            setTimeout(() => {
                const perfData = performance.getEntriesByType('navigation')[0];
                if (perfData) {
                    this.metrics.performance = {
                        loadTime: perfData.loadEventEnd - perfData.loadEventStart,
                        domContentLoaded: perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart,
                        firstByte: perfData.responseStart - perfData.requestStart,
                        dns: perfData.domainLookupEnd - perfData.domainLookupStart,
                        tcp: perfData.connectEnd - perfData.connectStart,
                        ssl: perfData.secureConnectionStart > 0 ? perfData.connectEnd - perfData.secureConnectionStart : 0
                    };

                    this.trackEvent('performance', this.metrics.performance);
                }

                // Track Core Web Vitals
                this.trackCoreWebVitals();
            }, 1000);
        });

        // Track resource performance
        const trackResourcePerformance = () => {
            const resources = performance.getEntriesByType('resource');
            const slowResources = resources.filter(r => r.duration > 1000);

            if (slowResources.length > 0) {
                this.trackEvent('slow_resources', {
                    count: slowResources.length,
                    resources: slowResources.map(r => ({
                        name: r.name,
                        duration: r.duration,
                        size: r.transferSize
                    }))
                });
            }
        };

        setTimeout(trackResourcePerformance, 5000);
    }

    trackCoreWebVitals() {
        // Largest Contentful Paint (LCP)
        new PerformanceObserver((entryList) => {
            const entries = entryList.getEntries();
            const lastEntry = entries[entries.length - 1];
            this.trackEvent('core_web_vital', {
                metric: 'LCP',
                value: lastEntry.startTime,
                rating: lastEntry.startTime <= 2500 ? 'good' : lastEntry.startTime <= 4000 ? 'needs-improvement' : 'poor'
            });
        }).observe({ entryTypes: ['largest-contentful-paint'] });

        // First Input Delay (FID)
        new PerformanceObserver((entryList) => {
            const entries = entryList.getEntries();
            entries.forEach(entry => {
                const fid = entry.processingStart - entry.startTime;
                this.trackEvent('core_web_vital', {
                    metric: 'FID',
                    value: fid,
                    rating: fid <= 100 ? 'good' : fid <= 300 ? 'needs-improvement' : 'poor'
                });
            });
        }).observe({ entryTypes: ['first-input'] });

        // Cumulative Layout Shift (CLS)
        let clsValue = 0;
        new PerformanceObserver((entryList) => {
            const entries = entryList.getEntries();
            entries.forEach(entry => {
                if (!entry.hadRecentInput) {
                    clsValue += entry.value;
                }
            });

            this.trackEvent('core_web_vital', {
                metric: 'CLS',
                value: clsValue,
                rating: clsValue <= 0.1 ? 'good' : clsValue <= 0.25 ? 'needs-improvement' : 'poor'
            });
        }).observe({ entryTypes: ['layout-shift'] });
    }

    setupSecurityTracking() {
        if (!this.config.enableSecurityTracking) return;

        // Track security events
        document.addEventListener('securityEvent', (e) => {
            this.trackEvent('security_event', e.detail);
        });

        // Monitor for potential threats
        const securityMonitor = () => {
            // Check for suspicious activity
            const suspiciousPatterns = [
                /javascript:/i,
                /<script/i,
                /eval\(/i,
                /document\.write/i
            ];

            const currentUrl = window.location.href;
            suspiciousPatterns.forEach(pattern => {
                if (pattern.test(currentUrl)) {
                    this.trackEvent('security_threat', {
                        type: 'suspicious_url',
                        url: currentUrl,
                        pattern: pattern.toString()
                    });
                }
            });

            // Check for console tampering
            if (window.console && typeof window.console.log !== 'function') {
                this.trackEvent('security_threat', {
                    type: 'console_tampering',
                    timestamp: Date.now()
                });
            }
        };

        setInterval(securityMonitor, 10000);
    }

    setupHeatmapTracking() {
        if (!this.config.enableHeatmap) return;

        // Track mouse movements for heatmap
        let mouseTrackingThrottle = 0;
        document.addEventListener('mousemove', (e) => {
            const now = Date.now();
            if (now - mouseTrackingThrottle > 100) { // Throttle to every 100ms
                this.heatmapData.push({
                    x: e.clientX,
                    y: e.clientY,
                    timestamp: now
                });
                mouseTrackingThrottle = now;

                // Limit heatmap data size
                if (this.heatmapData.length > 1000) {
                    this.heatmapData = this.heatmapData.slice(-500);
                }
            }
        });
    }

    setupScrollTracking() {
        if (!this.config.enableScrollTracking) return;

        let maxScroll = 0;
        let scrollThrottle = 0;

        window.addEventListener('scroll', () => {
            const now = Date.now();
            if (now - scrollThrottle > 250) { // Throttle scroll tracking
                const scrollPercent = this.calculateScrollDepth();
                maxScroll = Math.max(maxScroll, scrollPercent);

                this.scrollData.push({
                    scrollPercent,
                    timestamp: now
                });

                scrollThrottle = now;

                // Track scroll milestones
                if (scrollPercent >= 25 && !this.scrollMilestones?.quarter) {
                    this.trackEvent('scroll_milestone', { milestone: '25%' });
                    this.scrollMilestones = { ...this.scrollMilestones, quarter: true };
                }
                if (scrollPercent >= 50 && !this.scrollMilestones?.half) {
                    this.trackEvent('scroll_milestone', { milestone: '50%' });
                    this.scrollMilestones = { ...this.scrollMilestones, half: true };
                }
                if (scrollPercent >= 75 && !this.scrollMilestones?.threeQuarters) {
                    this.trackEvent('scroll_milestone', { milestone: '75%' });
                    this.scrollMilestones = { ...this.scrollMilestones, threeQuarters: true };
                }
                if (scrollPercent >= 90 && !this.scrollMilestones?.near_bottom) {
                    this.trackEvent('scroll_milestone', { milestone: '90%' });
                    this.scrollMilestones = { ...this.scrollMilestones, near_bottom: true };
                }
            }
        });

        this.scrollMilestones = {};
    }

    setupErrorTracking() {
        if (!this.config.enableErrorTracking) return;

        // Track JavaScript errors
        window.addEventListener('error', (e) => {
            this.trackEvent('javascript_error', {
                message: e.message,
                filename: e.filename,
                lineno: e.lineno,
                colno: e.colno,
                stack: e.error?.stack,
                userAgent: navigator.userAgent,
                url: window.location.href
            });
            this.metrics.errors++;
        });

        // Track unhandled promise rejections
        window.addEventListener('unhandledrejection', (e) => {
            this.trackEvent('unhandled_promise_rejection', {
                reason: e.reason?.toString(),
                stack: e.reason?.stack,
                url: window.location.href
            });
        });

        // Track CSP violations
        document.addEventListener('securitypolicyviolation', (e) => {
            this.trackEvent('csp_violation', {
                blockedURI: e.blockedURI,
                violatedDirective: e.violatedDirective,
                originalPolicy: e.originalPolicy,
                sourceFile: e.sourceFile,
                lineNumber: e.lineNumber
            });
        });
    }

    setupEngagementTracking() {
        let startTime = Date.now();
        let isActive = true;
        let totalActiveTime = 0;
        let lastActiveTime = startTime;

        // Track tab visibility
        document.addEventListener('visibilitychange', () => {
            const now = Date.now();
            if (document.hidden) {
                if (isActive) {
                    totalActiveTime += now - lastActiveTime;
                    isActive = false;
                }
                this.trackEvent('tab_hidden', { activeTime: totalActiveTime });
            } else {
                lastActiveTime = now;
                isActive = true;
                this.trackEvent('tab_visible', { totalActiveTime });
            }
        });

        // Track user activity
        const activityEvents = ['click', 'scroll', 'keypress', 'mousemove'];
        let lastActivity = Date.now();

        const trackActivity = () => {
            lastActivity = Date.now();
            if (!isActive) {
                lastActiveTime = lastActivity;
                isActive = true;
            }
        };

        activityEvents.forEach(event => {
            document.addEventListener(event, trackActivity, { passive: true });
        });

        // Check for inactivity
        setInterval(() => {
            const now = Date.now();
            if (isActive && now - lastActivity > 30000) { // 30 seconds of inactivity
                totalActiveTime += lastActivity - lastActiveTime;
                isActive = false;
                this.trackEvent('user_inactive', { totalActiveTime });
            }
        }, 5000);

        // Track engagement metrics periodically
        setInterval(() => {
            this.metrics.engagement = {
                totalTime: Date.now() - startTime,
                activeTime: totalActiveTime + (isActive ? Date.now() - lastActiveTime : 0),
                scrollDepth: this.calculateScrollDepth(),
                clickCount: this.clickData.length,
                interactions: this.metrics.userInteractions
            };
        }, 10000);
    }

    setupBatchSending() {
        // Send analytics data in batches
        setInterval(() => {
            this.sendBatch();
        }, this.config.sendInterval);

        // Send on page unload
        window.addEventListener('beforeunload', () => {
            this.sendBatch(true);
        });
    }

    trackEvent(eventType, data = {}) {
        const event = {
            id: this.generateEventId(),
            type: eventType,
            sessionId: this.sessionId,
            userId: this.userId,
            timestamp: Date.now(),
            url: window.location.href,
            data: data
        };

        this.events.push(event);
        this.metrics.userInteractions++;

        // Send immediately for critical events
        const criticalEvents = ['javascript_error', 'security_threat', 'csp_violation'];
        if (criticalEvents.includes(eventType)) {
            this.sendBatch(true);
        }

        // Trigger custom event for real-time dashboard updates
        document.dispatchEvent(new CustomEvent('analyticsEvent', { detail: event }));
    }

    generateEventId() {
        return 'event_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    getElementInfo(element) {
        return {
            tagName: element.tagName,
            id: element.id,
            className: element.className,
            text: element.textContent?.substring(0, 100),
            href: element.href,
            src: element.src
        };
    }

    calculateScrollDepth() {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        const documentHeight = document.documentElement.scrollHeight - window.innerHeight;
        return documentHeight > 0 ? Math.round((scrollTop / documentHeight) * 100) : 0;
    }

    sendBatch(force = false) {
        if (this.events.length === 0) return;

        if (!force && this.events.length < this.config.batchSize) return;

        const batch = {
            sessionId: this.sessionId,
            userId: this.userId,
            timestamp: Date.now(),
            events: [...this.events],
            metrics: { ...this.metrics },
            heatmapData: this.config.enableHeatmap ? [...this.heatmapData] : [],
            scrollData: this.config.enableScrollTracking ? [...this.scrollData] : []
        };

        // In a real implementation, you would send this to your analytics server
        console.log('📊 Analytics Batch:', batch);

        // Store locally for demonstration
        this.storeAnalyticsData(batch);

        // Clear sent data
        this.events = [];
        this.heatmapData = [];
        this.scrollData = [];
    }

    storeAnalyticsData(batch) {
        try {
            const existingData = JSON.parse(localStorage.getItem('iBridge-analytics') || '[]');
            existingData.push(batch);

            // Keep only last 10 batches to prevent storage overflow
            const recentData = existingData.slice(-10);
            localStorage.setItem('iBridge-analytics', JSON.stringify(recentData));
        } catch (e) {
            console.warn('Failed to store analytics data:', e);
        }
    }

    createAnalyticsDashboard() {
        // Create analytics dashboard toggle
        const toggle = document.createElement('div');
        toggle.id = 'analytics-toggle';
        toggle.style.cssText = `
            position: fixed;
            bottom: 80px;
            right: 20px;
            background: linear-gradient(135deg, #4a90e2, #357abd);
            color: white;
            padding: 12px;
            border-radius: 50%;
            cursor: pointer;
            z-index: 9997;
            font-size: 20px;
            box-shadow: 0 4px 20px rgba(74, 144, 226, 0.3);
            transition: transform 0.3s;
        `;
        toggle.innerHTML = '📊';
        toggle.title = 'Analytics Dashboard (Alt+A)';

        toggle.addEventListener('click', () => {
            this.showAnalyticsDashboard();
        });

        toggle.addEventListener('mouseenter', () => {
            toggle.style.transform = 'scale(1.1)';
        });

        toggle.addEventListener('mouseleave', () => {
            toggle.style.transform = 'scale(1)';
        });

        document.body.appendChild(toggle);

        // Keyboard shortcut
        document.addEventListener('keydown', (e) => {
            if (e.altKey && e.key === 'a') {
                e.preventDefault();
                this.showAnalyticsDashboard();
            }
        });
    }

    showAnalyticsDashboard() {
        const modal = document.createElement('div');
        modal.id = 'analytics-dashboard-modal';
        modal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.8);
            z-index: 99998;
            display: flex;
            align-items: center;
            justify-content: center;
        `;

        const dashboard = document.createElement('div');
        dashboard.style.cssText = `
            background: linear-gradient(135deg, #1a1a1a, #2d2d2d);
            color: white;
            padding: 30px;
            border-radius: 20px;
            max-width: 900px;
            width: 90%;
            max-height: 80%;
            overflow-y: auto;
            border: 2px solid #4a90e2;
        `;

        const analytics = this.getAnalyticsSummary();

        dashboard.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px;">
                <h2 style="margin: 0; color: #4a90e2; font-size: 24px;">📊 Analytics Dashboard</h2>
                <button onclick="this.closest('#analytics-dashboard-modal').remove()" 
                        style="background: rgba(255,255,255,0.1); border: none; color: white; font-size: 24px; cursor: pointer; padding: 10px; border-radius: 50%;">×</button>
            </div>

            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px;">
                <div style="background: rgba(0,255,136,0.1); padding: 20px; border-radius: 12px; border-left: 4px solid #00ff88;">
                    <h3 style="margin: 0 0 10px 0; color: #00ff88;">Page Views</h3>
                    <div style="font-size: 32px; font-weight: bold;">${analytics.pageViews}</div>
                </div>
                <div style="background: rgba(74,144,226,0.1); padding: 20px; border-radius: 12px; border-left: 4px solid #4a90e2;">
                    <h3 style="margin: 0 0 10px 0; color: #4a90e2;">User Interactions</h3>
                    <div style="font-size: 32px; font-weight: bold;">${analytics.interactions}</div>
                </div>
                <div style="background: rgba(243,156,18,0.1); padding: 20px; border-radius: 12px; border-left: 4px solid #f39c12;">
                    <h3 style="margin: 0 0 10px 0; color: #f39c12;">Avg. Session Time</h3>
                    <div style="font-size: 32px; font-weight: bold;">${this.formatTime(analytics.avgSessionTime)}</div>
                </div>
                <div style="background: rgba(231,76,60,0.1); padding: 20px; border-radius: 12px; border-left: 4px solid #e74c3c;">
                    <h3 style="margin: 0 0 10px 0; color: #e74c3c;">Errors</h3>
                    <div style="font-size: 32px; font-weight: bold;">${analytics.errors}</div>
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px;">
                <div style="background: rgba(255,255,255,0.05); padding: 20px; border-radius: 12px;">
                    <h3 style="margin: 0 0 15px 0; color: #9b59b6;">Top Events</h3>
                    <div style="font-size: 12px;">
                        ${analytics.topEvents.map(event => `
                            <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.1);">
                                <span>${event.type}</span>
                                <span style="color: #00ff88;">${event.count}</span>
                            </div>
                        `).join('')}
                    </div>
                </div>
                <div style="background: rgba(255,255,255,0.05); padding: 20px; border-radius: 12px;">
                    <h3 style="margin: 0 0 15px 0; color: #e67e22;">Performance Metrics</h3>
                    <div style="font-size: 12px;">
                        <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.1);">
                            <span>Page Load Time</span>
                            <span style="color: #00ff88;">${analytics.performance.loadTime || 'N/A'}</span>
                        </div>
                        <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.1);">
                            <span>First Byte</span>
                            <span style="color: #00ff88;">${analytics.performance.firstByte || 'N/A'}</span>
                        </div>
                        <div style="display: flex; justify-content: space-between; padding: 8px 0;">
                            <span>DOM Ready</span>
                            <span style="color: #00ff88;">${analytics.performance.domContentLoaded || 'N/A'}</span>
                        </div>
                    </div>
                </div>
            </div>

            <div style="display: flex; gap: 10px; justify-content: center;">
                <button onclick="window.advancedAnalytics.exportAnalytics()" 
                        style="background: linear-gradient(135deg, #00ff88, #00cc66); color: #000; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer;">
                    📄 Export Data
                </button>
                <button onclick="window.advancedAnalytics.clearAnalytics()" 
                        style="background: linear-gradient(135deg, #e74c3c, #c0392b); color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; cursor: pointer;">
                    🗑️ Clear Data
                </button>
            </div>
        `;

        modal.appendChild(dashboard);
        document.body.appendChild(modal);

        // Close on backdrop click
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal.remove();
            }
        });
    }

    getAnalyticsSummary() {
        const data = JSON.parse(localStorage.getItem('iBridge-analytics') || '[]');
        const allEvents = data.flatMap(batch => batch.events);

        const eventCounts = {};
        allEvents.forEach(event => {
            eventCounts[event.type] = (eventCounts[event.type] || 0) + 1;
        });

        const topEvents = Object.entries(eventCounts)
            .sort(([, a], [, b]) => b - a)
            .slice(0, 5)
            .map(([type, count]) => ({ type, count }));

        const sessionTimes = data.map(batch => batch.metrics.engagement?.totalTime || 0);
        const avgSessionTime = sessionTimes.length > 0 ?
            sessionTimes.reduce((a, b) => a + b, 0) / sessionTimes.length : 0;

        return {
            pageViews: eventCounts.page_view || 0,
            interactions: this.metrics.userInteractions,
            errors: this.metrics.errors,
            avgSessionTime,
            topEvents,
            performance: this.metrics.performance
        };
    }

    formatTime(ms) {
        const seconds = Math.floor(ms / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);

        if (hours > 0) {
            return `${hours}h ${minutes % 60}m`;
        } else if (minutes > 0) {
            return `${minutes}m ${seconds % 60}s`;
        } else {
            return `${seconds}s`;
        }
    }

    exportAnalytics() {
        const data = JSON.parse(localStorage.getItem('iBridge-analytics') || '[]');
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `iBridge-analytics-${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    clearAnalytics() {
        if (confirm('Are you sure you want to clear all analytics data?')) {
            localStorage.removeItem('iBridge-analytics');
            this.events = [];
            this.heatmapData = [];
            this.scrollData = [];
            this.metrics = {
                pageViews: 0,
                userInteractions: 0,
                errors: 0,
                performance: {},
                security: {},
                engagement: {}
            };
            document.getElementById('analytics-dashboard-modal')?.remove();
        }
    }

    startSession() {
        this.trackEvent('session_start', {
            userAgent: navigator.userAgent,
            language: navigator.language,
            platform: navigator.platform,
            cookieEnabled: navigator.cookieEnabled,
            onLine: navigator.onLine,
            screen: {
                width: screen.width,
                height: screen.height,
                availWidth: screen.availWidth,
                availHeight: screen.availHeight,
                pixelDepth: screen.pixelDepth
            }
        });
    }

    // Public API methods
    track(eventType, data) {
        this.trackEvent(eventType, data);
    }

    getSessionData() {
        return {
            sessionId: this.sessionId,
            userId: this.userId,
            startTime: this.startTime,
            metrics: this.metrics
        };
    }

    setUserId(userId) {
        this.userId = userId;
        localStorage.setItem('iBridge-user-id', userId);
    }
}

// Initialize Advanced Analytics
document.addEventListener('DOMContentLoaded', () => {
    window.advancedAnalytics = new AdvancedAnalytics();

    console.log('%c📊 Advanced Analytics v1.0 Loaded',
        'color: #4a90e2; font-weight: bold; background: #000; padding: 5px 10px; border-radius: 5px;');
});