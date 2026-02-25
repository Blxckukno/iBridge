/**
 * PWA Manager - Progressive Web App Implementation
 * Handles service worker registration, app installation, offline functionality,
 * push notifications, and app-like features
 */

class PWAManager {
    constructor() {
        this.config = {
            swPath: '/sw.js',
            enableNotifications: true,
            enableBackgroundSync: true,
            enablePeriodicSync: false,
            updateCheckInterval: 60000, // 1 minute
            offlineTimeout: 5000
        };

        this.isOnline = navigator.onLine;
        this.swRegistration = null;
        this.deferredPrompt = null;
        this.isInstalled = false;
        this.updateAvailable = false;

        this.init();
    }

    /**
     * Initialize PWA Manager
     */
    async init() {
        try {
            await this.registerServiceWorker();
            this.setupInstallPrompt();
            this.setupOnlineOfflineHandling();
            this.setupUpdateHandling();
            this.createPWAControls();
            this.checkInstallStatus();

            if (this.config.enableNotifications) {
                await this.setupPushNotifications();
            }

            console.log('📱 PWA Manager initialized successfully');
        } catch (error) {
            console.error('❌ PWA Manager initialization failed:', error);
        }
    }

    /**
     * Register Service Worker
     */
    async registerServiceWorker() {
        if (!('serviceWorker' in navigator)) {
            console.warn('Service Worker not supported');
            return;
        }

        try {
            this.swRegistration = await navigator.serviceWorker.register(this.config.swPath, {
                scope: '/'
            });

            console.log('🔧 Service Worker registered:', this.swRegistration.scope);

            // Listen for service worker messages
            navigator.serviceWorker.addEventListener('message', (event) => {
                this.handleServiceWorkerMessage(event.data);
            });

            // Check for updates
            this.swRegistration.addEventListener('updatefound', () => {
                console.log('🔄 New service worker version found');
                this.handleServiceWorkerUpdate();
            });

            // Periodic update checks
            setInterval(() => {
                this.swRegistration.update();
            }, this.config.updateCheckInterval);

        } catch (error) {
            console.error('Service Worker registration failed:', error);
        }
    }

    /**
     * Handle service worker messages
     */
    handleServiceWorkerMessage(message) {
        switch (message.type) {
            case 'SW_UPDATE_AVAILABLE':
                this.showUpdateNotification();
                break;
            case 'CACHE_SIZE':
                this.displayCacheSize(message.size);
                break;
            case 'OFFLINE_FALLBACK':
                this.handleOfflineFallback();
                break;
        }
    }

    /**
     * Handle service worker updates
     */
    handleServiceWorkerUpdate() {
        const newWorker = this.swRegistration.installing;

        newWorker.addEventListener('statechange', () => {
            if (newWorker.state === 'installed') {
                if (navigator.serviceWorker.controller) {
                    // New update available
                    this.updateAvailable = true;
                    this.showUpdateNotification();
                } else {
                    // First install
                    console.log('✅ App cached and ready for offline use');
                    this.showInstallSuccess();
                }
            }
        });
    }

    /**
     * Setup app installation prompt
     */
    setupInstallPrompt() {
        window.addEventListener('beforeinstallprompt', (event) => {
            console.log('📱 Install prompt available');
            event.preventDefault();
            this.deferredPrompt = event;
            this.showInstallButton();
        });

        // Handle app installation
        window.addEventListener('appinstalled', () => {
            console.log('🎉 App installed successfully');
            this.isInstalled = true;
            this.hideInstallButton();
            this.showInstallSuccess();
            this.deferredPrompt = null;

            // Track installation
            if (window.analyticsManager) {
                window.analyticsManager.trackEvent('pwa_installed', {
                    source: 'browser_prompt'
                });
            }
        });
    }

    /**
     * Show install button
     */
    showInstallButton() {
        const installBtn = document.querySelector('.pwa-install-btn');
        if (installBtn) {
            installBtn.style.display = 'block';
            installBtn.addEventListener('click', () => this.promptInstall());
        }
    }

    /**
     * Hide install button
     */
    hideInstallButton() {
        const installBtn = document.querySelector('.pwa-install-btn');
        if (installBtn) {
            installBtn.style.display = 'none';
        }
    }

    /**
     * Prompt app installation
     */
    async promptInstall() {
        if (!this.deferredPrompt) {
            console.warn('No install prompt available');
            return;
        }

        this.deferredPrompt.prompt();
        const { outcome } = await this.deferredPrompt.userChoice;

        console.log('Install prompt outcome:', outcome);

        if (window.analyticsManager) {
            window.analyticsManager.trackEvent('pwa_install_prompt', {
                outcome: outcome
            });
        }

        this.deferredPrompt = null;
    }

    /**
     * Setup online/offline handling
     */
    setupOnlineOfflineHandling() {
        window.addEventListener('online', () => {
            this.isOnline = true;
            this.handleOnline();
        });

        window.addEventListener('offline', () => {
            this.isOnline = false;
            this.handleOffline();
        });

        // Initial check
        this.updateConnectionStatus();
    }

    /**
     * Handle online event
     */
    handleOnline() {
        console.log('🌐 Back online');
        this.updateConnectionStatus();
        this.syncPendingData();
        this.showConnectionStatus('online', 'Back online!');

        // Hide offline banner if visible
        const offlineBanner = document.querySelector('.offline-banner');
        if (offlineBanner) {
            offlineBanner.remove();
        }
    }

    /**
     * Handle offline event
     */
    handleOffline() {
        console.log('📵 Gone offline');
        this.updateConnectionStatus();
        this.showOfflineBanner();
        this.showConnectionStatus('offline', 'You are offline');
    }

    /**
     * Update connection status indicator
     */
    updateConnectionStatus() {
        const statusIndicator = document.querySelector('.connection-status');
        if (statusIndicator) {
            statusIndicator.classList.toggle('online', this.isOnline);
            statusIndicator.classList.toggle('offline', !this.isOnline);
            statusIndicator.textContent = this.isOnline ? 'Online' : 'Offline';
        }
    }

    /**
     * Show offline banner
     */
    showOfflineBanner() {
        if (document.querySelector('.offline-banner')) return;

        const banner = document.createElement('div');
        banner.className = 'offline-banner';
        banner.innerHTML = `
            <div class="offline-content">
                <span class="offline-icon">📵</span>
                <span class="offline-text">You're offline. Some features may be limited.</span>
                <button class="offline-dismiss" onclick="this.parentElement.parentElement.remove()">✕</button>
            </div>
        `;

        document.body.insertBefore(banner, document.body.firstChild);

        // Auto-dismiss after 5 seconds
        setTimeout(() => {
            if (banner.parentElement) {
                banner.remove();
            }
        }, 5000);
    }

    /**
     * Show connection status toast
     */
    showConnectionStatus(status, message) {
        const toast = document.createElement('div');
        toast.className = `connection-toast ${status}`;
        toast.textContent = message;

        document.body.appendChild(toast);

        // Animate in
        setTimeout(() => toast.classList.add('show'), 100);

        // Remove after 3 seconds
        setTimeout(() => {
            toast.classList.remove('show');
            setTimeout(() => toast.remove(), 300);
        }, 3000);
    }

    /**
     * Setup push notifications
     */
    async setupPushNotifications() {
        if (!('Notification' in window) || !('PushManager' in window)) {
            console.warn('Push notifications not supported');
            return;
        }

        try {
            // Request notification permission
            const permission = await Notification.requestPermission();

            if (permission === 'granted') {
                console.log('✅ Notification permission granted');
                await this.subscribeToPush();
            } else {
                console.log('❌ Notification permission denied');
            }
        } catch (error) {
            console.error('Push notification setup failed:', error);
        }
    }

    /**
     * Subscribe to push notifications
     */
    async subscribeToPush() {
        try {
            const subscription = await this.swRegistration.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: this.urlBase64ToUint8Array('your-vapid-public-key-here')
            });

            console.log('📬 Push subscription created:', subscription);

            // Send subscription to server
            await this.sendSubscriptionToServer(subscription);

        } catch (error) {
            console.error('Push subscription failed:', error);
        }
    }

    /**
     * Send subscription to server
     */
    async sendSubscriptionToServer(subscription) {
        try {
            const response = await fetch('/api/push-subscription', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(subscription)
            });

            if (response.ok) {
                console.log('✅ Push subscription saved to server');
            }
        } catch (error) {
            console.error('Failed to save push subscription:', error);
        }
    }

    /**
     * Setup update handling
     */
    setupUpdateHandling() {
        // Listen for update events
        document.addEventListener('sw-update-available', () => {
            this.showUpdateNotification();
        });
    }

    /**
     * Show update notification
     */
    showUpdateNotification() {
        const updateBanner = document.createElement('div');
        updateBanner.className = 'update-banner';
        updateBanner.innerHTML = `
            <div class="update-content">
                <span class="update-icon">🔄</span>
                <span class="update-text">A new version is available!</span>
                <button class="update-btn" onclick="pwaManager.applyUpdate()">Update Now</button>
                <button class="update-dismiss" onclick="this.parentElement.parentElement.remove()">Later</button>
            </div>
        `;

        document.body.insertBefore(updateBanner, document.body.firstChild);
    }

    /**
     * Apply update
     */
    async applyUpdate() {
        if (this.swRegistration?.waiting) {
            this.swRegistration.waiting.postMessage({ type: 'SKIP_WAITING' });
            window.location.reload();
        }
    }

    /**
     * Sync pending data when back online
     */
    async syncPendingData() {
        if (this.swRegistration?.sync && this.config.enableBackgroundSync) {
            try {
                await this.swRegistration.sync.register('contact-form-sync');
                await this.swRegistration.sync.register('analytics-sync');
                console.log('🔄 Background sync registered');
            } catch (error) {
                console.error('Background sync registration failed:', error);
            }
        }
    }

    /**
     * Check install status
     */
    checkInstallStatus() {
        // Check if app is installed
        if (window.matchMedia('(display-mode: standalone)').matches ||
            window.navigator.standalone === true) {
            this.isInstalled = true;
            console.log('📱 App is installed');

            // Hide install button
            this.hideInstallButton();

            // Add installed class to body
            document.body.classList.add('pwa-installed');
        }
    }

    /**
     * Create PWA controls
     */
    createPWAControls() {
        const controlsContainer = document.createElement('div');
        controlsContainer.className = 'pwa-controls';
        controlsContainer.innerHTML = `
            <button class="pwa-install-btn" style="display: none;" title="Install App">
                📱 Install App
            </button>
            <button class="pwa-share-btn" title="Share" onclick="pwaManager.shareApp()">
                📤 Share
            </button>
            <div class="connection-status online">Online</div>
        `;

        // Add styles
        const styles = `
            .pwa-controls {
                position: fixed;
                top: 20px;
                right: 20px;
                z-index: 10000;
                display: flex;
                flex-direction: column;
                gap: 10px;
                align-items: flex-end;
            }
            
            .pwa-install-btn,
            .pwa-share-btn {
                background: linear-gradient(135deg, #17a2b8, #138496);
                color: white;
                border: none;
                padding: 10px 15px;
                border-radius: 25px;
                font-size: 12px;
                font-weight: 500;
                cursor: pointer;
                box-shadow: 0 4px 12px rgba(23, 162, 184, 0.3);
                transition: all 0.3s ease;
                white-space: nowrap;
            }
            
            .pwa-install-btn:hover,
            .pwa-share-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 16px rgba(23, 162, 184, 0.4);
            }
            
            .connection-status {
                background: rgba(0, 0, 0, 0.8);
                color: white;
                padding: 5px 10px;
                border-radius: 15px;
                font-size: 11px;
                font-weight: 500;
            }
            
            .connection-status.online {
                background: rgba(40, 167, 69, 0.8);
            }
            
            .connection-status.offline {
                background: rgba(220, 53, 69, 0.8);
            }
            
            .offline-banner,
            .update-banner {
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                background: #f39c12;
                color: white;
                z-index: 10001;
                transform: translateY(-100%);
                transition: transform 0.3s ease;
            }
            
            .offline-banner {
                background: #e74c3c;
            }
            
            .update-banner {
                background: #3498db;
            }
            
            .offline-banner.show,
            .update-banner.show {
                transform: translateY(0);
            }
            
            .offline-content,
            .update-content {
                display: flex;
                align-items: center;
                justify-content: space-between;
                padding: 15px 20px;
                max-width: 1200px;
                margin: 0 auto;
            }
            
            .offline-text,
            .update-text {
                margin: 0 15px;
                flex-grow: 1;
            }
            
            .update-btn,
            .offline-dismiss,
            .update-dismiss {
                background: rgba(255, 255, 255, 0.2);
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 5px;
                cursor: pointer;
                margin-left: 10px;
                font-weight: 500;
            }
            
            .update-btn:hover,
            .offline-dismiss:hover,
            .update-dismiss:hover {
                background: rgba(255, 255, 255, 0.3);
            }
            
            .connection-toast {
                position: fixed;
                bottom: 20px;
                left: 50%;
                transform: translateX(-50%) translateY(100px);
                background: rgba(0, 0, 0, 0.8);
                color: white;
                padding: 12px 24px;
                border-radius: 25px;
                font-weight: 500;
                z-index: 10002;
                transition: transform 0.3s ease;
            }
            
            .connection-toast.online {
                background: rgba(40, 167, 69, 0.9);
            }
            
            .connection-toast.offline {
                background: rgba(220, 53, 69, 0.9);
            }
            
            .connection-toast.show {
                transform: translateX(-50%) translateY(0);
            }
            
            @media (max-width: 768px) {
                .pwa-controls {
                    top: 10px;
                    right: 10px;
                    flex-direction: row;
                    flex-wrap: wrap;
                }
                
                .offline-content,
                .update-content {
                    flex-direction: column;
                    text-align: center;
                    gap: 10px;
                }
            }
        `;

        const styleSheet = document.createElement('style');
        styleSheet.textContent = styles;
        document.head.appendChild(styleSheet);

        document.body.appendChild(controlsContainer);

        // Show banner on first visit
        setTimeout(() => {
            const banner = document.querySelector('.offline-banner, .update-banner');
            if (banner) {
                banner.classList.add('show');
            }
        }, 1000);
    }

    /**
     * Share app
     */
    async shareApp() {
        const shareData = {
            title: 'iBridge Contact Solutions',
            text: 'Professional Contact Center & Customer Support Services',
            url: window.location.href
        };

        if (navigator.share) {
            try {
                await navigator.share(shareData);
                console.log('✅ App shared successfully');

                if (window.analyticsManager) {
                    window.analyticsManager.trackEvent('pwa_shared', {
                        method: 'native_share'
                    });
                }
            } catch (error) {
                console.log('Share cancelled or failed:', error);
            }
        } else {
            // Fallback: copy to clipboard
            try {
                await navigator.clipboard.writeText(shareData.url);
                this.showToast('Link copied to clipboard!');

                if (window.analyticsManager) {
                    window.analyticsManager.trackEvent('pwa_shared', {
                        method: 'clipboard'
                    });
                }
            } catch (error) {
                console.error('Failed to copy link:', error);
            }
        }
    }

    /**
     * Show toast message
     */
    showToast(message, duration = 3000) {
        const toast = document.createElement('div');
        toast.className = 'pwa-toast';
        toast.textContent = message;
        toast.style.cssText = `
            position: fixed;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: rgba(0, 0, 0, 0.8);
            color: white;
            padding: 12px 24px;
            border-radius: 25px;
            font-weight: 500;
            z-index: 10002;
            transition: opacity 0.3s ease;
        `;

        document.body.appendChild(toast);

        setTimeout(() => {
            toast.style.opacity = '0';
            setTimeout(() => toast.remove(), 300);
        }, duration);
    }

    /**
     * Show install success message
     */
    showInstallSuccess() {
        this.showToast('App installed! Now available offline 🎉', 4000);
    }

    /**
     * Handle offline fallback
     */
    handleOfflineFallback() {
        console.log('📵 Showing offline fallback');

        // Show offline message in main content
        const main = document.querySelector('main, .main-content, #main-content');
        if (main && !this.isOnline) {
            const offlineMessage = document.createElement('div');
            offlineMessage.className = 'offline-fallback';
            offlineMessage.innerHTML = `
                <div class="offline-fallback-content">
                    <h2>📵 You're Offline</h2>
                    <p>This page isn't available offline. Please check your connection and try again.</p>
                    <button onclick="window.location.reload()" class="retry-btn">
                        🔄 Retry
                    </button>
                </div>
            `;

            main.innerHTML = '';
            main.appendChild(offlineMessage);
        }
    }

    /**
     * Utility: Convert VAPID key
     */
    urlBase64ToUint8Array(base64String) {
        const padding = '='.repeat((4 - base64String.length % 4) % 4);
        const base64 = (base64String + padding)
            .replace(/-/g, '+')
            .replace(/_/g, '/');

        const rawData = window.atob(base64);
        const outputArray = new Uint8Array(rawData.length);

        for (let i = 0; i < rawData.length; ++i) {
            outputArray[i] = rawData.charCodeAt(i);
        }

        return outputArray;
    }

    /**
     * Get PWA status report
     */
    getPWAReport() {
        return {
            isOnline: this.isOnline,
            isInstalled: this.isInstalled,
            updateAvailable: this.updateAvailable,
            serviceWorkerRegistered: !!this.swRegistration,
            notificationsEnabled: Notification.permission === 'granted',
            timestamp: new Date().toISOString()
        };
    }
}

// Initialize PWA Manager when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.pwaManager = new PWAManager();
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PWAManager;
}