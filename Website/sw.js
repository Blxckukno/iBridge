/**
 * Enhanced Service Worker for iBridge PWA
 * Advanced caching, offline functionality, push notifications, and background sync
 */

const CACHE_NAME = 'ibridge-pwa-v2.0.1';
const STATIC_CACHE_NAME = 'ibridge-static-v2.0.1';
const DYNAMIC_CACHE_NAME = 'ibridge-dynamic-v2.0.1';
const API_CACHE_NAME = 'ibridge-api-v2.0.1';

// Files to cache immediately (App Shell)
const STATIC_ASSETS = [
    '/',
    '/index.html',
    '/about.html',
    '/services.html',
    '/contact.html',
    '/careers.html',
    '/css/styles.css',
    '/css/mobile-responsive-styles.css',
    '/css/analytics-styles.css',
    '/css/accessibility.css',
    '/css/security.css',
    '/css/seo-enhancements.css',
    '/js/analytics-manager.js',
    '/js/mobile-responsiveness-manager.js',
    '/js/seo-manager.js',
    '/js/performance-optimizer.js',
    '/js/security-manager.js',
    '/js/accessibility-manager.js',
    '/images/iBridge_Logo-removebg-preview.png',
    '/images/icons/icon-192x192.png',
    '/images/icons/icon-512x512.png',
    '/manifest.json',
    '/offline.html'
];

// API endpoints to cache
const API_ENDPOINTS = [
    '/api/analytics',
    '/api/performance',
    '/api/contact'
];

// Cache strategies
const CACHE_STRATEGIES = {
    CACHE_FIRST: 'cache-first',
    NETWORK_FIRST: 'network-first',
    STALE_WHILE_REVALIDATE: 'stale-while-revalidate',
    NETWORK_ONLY: 'network-only',
    CACHE_ONLY: 'cache-only'
};

// Routes and their cache strategies
const ROUTE_CACHE_STRATEGIES = new Map([
    ['/', CACHE_STRATEGIES.STALE_WHILE_REVALIDATE],
    ['/api/', CACHE_STRATEGIES.NETWORK_FIRST],
    ['/images/', CACHE_STRATEGIES.CACHE_FIRST],
    ['/css/', CACHE_STRATEGIES.CACHE_FIRST],
    ['/js/', CACHE_STRATEGIES.CACHE_FIRST],
    ['default', CACHE_STRATEGIES.STALE_WHILE_REVALIDATE]
]);

/**
 * Service Worker Installation
 */
self.addEventListener('install', event => {
    console.log('ðŸ”§ Service Worker: Installing...');

    event.waitUntil(
        Promise.all([
            // Cache static assets
            caches.open(STATIC_CACHE_NAME).then(cache => {
                console.log('ðŸ“¦ Caching static assets...');
                return cache.addAll(STATIC_ASSETS);
            }),

            // Skip waiting to activate immediately
            self.skipWaiting()
        ])
    );
});

/**
 * Service Worker Activation
 */
self.addEventListener('activate', event => {
    console.log('ðŸš€ Service Worker: Activating...');

    event.waitUntil(
        Promise.all([
            // Clean up old caches
            cleanupOldCaches(),

            // Claim all clients
            self.clients.claim()
        ])
    );
});

/**
 * Fetch Event Handler with Advanced Caching
 */
self.addEventListener('fetch', event => {
    const { request } = event;
    const url = new URL(request.url);

    // Skip non-GET requests
    if (request.method !== 'GET') {
        return;
    }

    // Skip chrome-extension and non-http(s) requests
    if (!url.protocol.startsWith('http')) {
        return;
    }

    event.respondWith(handleFetchRequest(request));
});

/**
 * Handle fetch request with appropriate cache strategy
 */
async function handleFetchRequest(request) {
    const url = new URL(request.url);
    const strategy = getCacheStrategy(url.pathname);

    try {
        switch (strategy) {
            case CACHE_STRATEGIES.CACHE_FIRST:
                return await cacheFirst(request);
            case CACHE_STRATEGIES.NETWORK_FIRST:
                return await networkFirst(request);
            case CACHE_STRATEGIES.STALE_WHILE_REVALIDATE:
                return await staleWhileRevalidate(request);
            case CACHE_STRATEGIES.NETWORK_ONLY:
                return await fetch(request);
            case CACHE_STRATEGIES.CACHE_ONLY:
                return await cacheOnly(request);
            default:
                return await staleWhileRevalidate(request);
        }
    } catch (error) {
        console.warn('Fetch failed, serving offline page:', error);
        return await getOfflineFallback(request);
    }
}

/**
 * Get cache strategy for a given path
 */
function getCacheStrategy(pathname) {
    for (const [route, strategy] of ROUTE_CACHE_STRATEGIES) {
        if (route === 'default') continue;
        if (pathname.startsWith(route)) {
            return strategy;
        }
    }
    return ROUTE_CACHE_STRATEGIES.get('default');
}

/**
 * Cache First Strategy
 */
async function cacheFirst(request) {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
        return cachedResponse;
    }

    const networkResponse = await fetch(request);
    await cacheResponse(request, networkResponse.clone());
    return networkResponse;
}

/**
 * Network First Strategy
 */
async function networkFirst(request) {
    try {
        const networkResponse = await fetch(request);
        await cacheResponse(request, networkResponse.clone());
        return networkResponse;
    } catch (error) {
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            return cachedResponse;
        }
        throw error;
    }
}

/**
 * Stale While Revalidate Strategy
 */
async function staleWhileRevalidate(request) {
    const cachedResponse = await caches.match(request);

    const fetchPromise = fetch(request).then(networkResponse => {
        cacheResponse(request, networkResponse.clone());
        return networkResponse;
    }).catch(error => {
        console.warn('Network request failed:', error);
        return null;
    });

    if (cachedResponse) {
        // Return cached response immediately, update in background
        fetchPromise.catch(() => { }); // Prevent unhandled rejection
        return cachedResponse;
    }

    // If no cache, wait for network
    return await fetchPromise || await getOfflineFallback(request);
}

/**
 * Cache Only Strategy
 */
async function cacheOnly(request) {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
        return cachedResponse;
    }
    throw new Error('Resource not in cache');
}

/**
 * Cache response with appropriate cache name
 */
async function cacheResponse(request, response) {
    if (!response || response.status !== 200 || response.type !== 'basic') {
        return;
    }

    const url = new URL(request.url);
    let cacheName = DYNAMIC_CACHE_NAME;

    // Use specific cache for API responses
    if (url.pathname.startsWith('/api/')) {
        cacheName = API_CACHE_NAME;
    }

    const cache = await caches.open(cacheName);
    await cache.put(request, response);
}

/**
 * Get offline fallback based on request type
 */
async function getOfflineFallback(request) {
    const url = new URL(request.url);

    // For HTML pages, serve offline page
    if (request.headers.get('accept')?.includes('text/html')) {
        const offlineResponse = await caches.match('/offline.html');
        if (offlineResponse) {
            return offlineResponse;
        }
    }

    // For images, serve placeholder
    if (request.headers.get('accept')?.includes('image/')) {
        return new Response(
            `<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
                <rect width="200" height="200" fill="#f0f0f0"/>
                <text x="100" y="100" text-anchor="middle" dy="0.3em" font-family="Arial" font-size="14" fill="#666">
                    Image Unavailable
                </text>
            </svg>`,
            { headers: { 'Content-Type': 'image/svg+xml' } }
        );
    }

    // For API requests, return cached data or empty response
    if (url.pathname.startsWith('/api/')) {
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            return cachedResponse;
        }
        return new Response(JSON.stringify({ error: 'Offline', cached: false }), {
            headers: { 'Content-Type': 'application/json' }
        });
    }

    // Generic offline response
    return new Response('Offline', { status: 503, statusText: 'Service Unavailable' });
}

/**
 * Clean up old caches
 */
async function cleanupOldCaches() {
    const cacheNames = await caches.keys();
    const currentCaches = [STATIC_CACHE_NAME, DYNAMIC_CACHE_NAME, API_CACHE_NAME];

    return Promise.all(
        cacheNames.map(cacheName => {
            if (!currentCaches.includes(cacheName)) {
                console.log('ðŸ—‘ï¸ Deleting old cache:', cacheName);
                return caches.delete(cacheName);
            }
        })
    );
}

/**
 * Push Notification Handling
 */
self.addEventListener('push', event => {
    console.log('ðŸ“¬ Push notification received');

    const options = {
        body: 'You have a new message from iBridge!',
        icon: '/images/icons/icon-192x192.png',
        badge: '/images/icons/badge-72x72.png',
        vibrate: [200, 100, 200],
        data: {
            url: '/',
            timestamp: Date.now()
        },
        actions: [
            {
                action: 'view',
                title: 'View',
                icon: '/images/icons/view-icon.png'
            },
            {
                action: 'dismiss',
                title: 'Dismiss',
                icon: '/images/icons/dismiss-icon.png'
            }
        ]
    };

    if (event.data) {
        const payload = event.data.json();
        options.title = payload.title || 'iBridge Contact Solutions';
        options.body = payload.body || options.body;
        options.data.url = payload.url || options.data.url;
    }

    event.waitUntil(
        self.registration.showNotification('iBridge Contact Solutions', options)
    );
});

/**
 * Notification Click Handling
 */
self.addEventListener('notificationclick', event => {
    console.log('ðŸ”” Notification clicked:', event.notification);

    event.notification.close();

    const { action } = event;
    const { url } = event.notification.data;

    if (action === 'dismiss') {
        return;
    }

    event.waitUntil(
        clients.matchAll({ type: 'window' }).then(clientList => {
            // Check if app is already open
            for (const client of clientList) {
                if (client.url === url && 'focus' in client) {
                    return client.focus();
                }
            }

            // Open new window
            if (clients.openWindow) {
                return clients.openWindow(url);
            }
        })
    );
});

/**
 * Background Sync
 */
self.addEventListener('sync', event => {
    console.log('ðŸ”„ Background sync:', event.tag);

    if (event.tag === 'contact-form-sync') {
        event.waitUntil(syncContactForms());
    } else if (event.tag === 'analytics-sync') {
        event.waitUntil(syncAnalyticsData());
    }
});

/**
 * Sync contact forms when online
 */
async function syncContactForms() {
    try {
        // Get pending forms from IndexedDB
        const pendingForms = await getPendingForms();

        for (const form of pendingForms) {
            try {
                const response = await fetch('/api/contact', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(form.data)
                });

                if (response.ok) {
                    await removePendingForm(form.id);
                    console.log('âœ… Form synced successfully:', form.id);
                }
            } catch (error) {
                console.warn('âŒ Failed to sync form:', form.id, error);
            }
        }
    } catch (error) {
        console.error('Background sync failed:', error);
    }
}

/**
 * Sync analytics data when online
 */
async function syncAnalyticsData() {
    try {
        // Get pending analytics data
        const pendingData = await getPendingAnalytics();

        for (const data of pendingData) {
            try {
                const response = await fetch('/api/analytics', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(data.payload)
                });

                if (response.ok) {
                    await removePendingAnalytics(data.id);
                    console.log('âœ… Analytics synced successfully:', data.id);
                }
            } catch (error) {
                console.warn('âŒ Failed to sync analytics:', data.id, error);
            }
        }
    } catch (error) {
        console.error('Analytics sync failed:', error);
    }
}

/**
 * Message Handling from Main Thread
 */
self.addEventListener('message', event => {
    const { type, payload } = event.data;

    switch (type) {
        case 'CACHE_URLS':
            event.waitUntil(cacheUrls(payload.urls));
            break;
        case 'CLEAR_CACHE':
            event.waitUntil(clearAllCaches());
            break;
        case 'GET_CACHE_SIZE':
            event.waitUntil(getCacheSize().then(size => {
                event.ports[0].postMessage({ type: 'CACHE_SIZE', size });
            }));
            break;
        case 'UPDATE_AVAILABLE':
            // Notify main thread about update
            broadcastUpdate();
            break;
    }
});

/**
 * Cache specific URLs
 */
async function cacheUrls(urls) {
    const cache = await caches.open(DYNAMIC_CACHE_NAME);
    return cache.addAll(urls);
}

/**
 * Clear all caches
 */
async function clearAllCaches() {
    const cacheNames = await caches.keys();
    return Promise.all(cacheNames.map(name => caches.delete(name)));
}

/**
 * Get total cache size
 */
async function getCacheSize() {
    let totalSize = 0;
    const cacheNames = await caches.keys();

    for (const name of cacheNames) {
        const cache = await caches.open(name);
        const keys = await cache.keys();

        for (const key of keys) {
            const response = await cache.match(key);
            if (response) {
                const blob = await response.blob();
                totalSize += blob.size;
            }
        }
    }

    return totalSize;
}

/**
 * Broadcast update to all clients
 */
async function broadcastUpdate() {
    const clients = await self.clients.matchAll();
    clients.forEach(client => {
        client.postMessage({
            type: 'SW_UPDATE_AVAILABLE',
            message: 'New version available. Refresh to update.'
        });
    });
}

/**
 * Periodic Background Sync (if supported)
 */
self.addEventListener('periodicsync', event => {
    if (event.tag === 'content-sync') {
        event.waitUntil(syncContent());
    }
});

/**
 * Sync content periodically
 */
async function syncContent() {
    try {
        // Update critical content in background
        const criticalUrls = [
            '/',
            '/services.html',
            '/contact.html'
        ];

        await cacheUrls(criticalUrls);
        console.log('ðŸ”„ Content synced in background');
    } catch (error) {
        console.error('Periodic sync failed:', error);
    }
}

// Placeholder functions for IndexedDB operations
// In a real implementation, these would interact with IndexedDB
async function getPendingForms() { return []; }
async function removePendingForm(id) { return true; }
async function getPendingAnalytics() { return []; }
async function removePendingAnalytics(id) { return true; }

console.log('ðŸš€ iBridge Service Worker loaded successfully');




