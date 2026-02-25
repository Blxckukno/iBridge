/**
 * Enterprise Service Worker
 * Advanced caching strategies, offline functionality, and performance optimization
 */

const CACHE_NAME = 'ibridge-cache-v1';
const OFFLINE_URL = '/offline.html';

// Assets to cache immediately (Critical Resources)
const PRECACHE_ASSETS = [
    '/',
    '/index.html',
    '/assets/min/critical.min.css',
    '/css/accessibility.css',
    '/js/asset-loader.js',
    '/js/accessibility-manager.js',
    '/js/performance-optimizer-enhanced.js',
    '/images/iBridge_Logo-removebg-preview.png',
    '/images/generated/og-african-customer-support.png',
    '/manifest.json',
    OFFLINE_URL
];

// Assets to cache on demand (Secondary Resources)
const RUNTIME_CACHE_ASSETS = [
    '/assets/min/styles.min.css',
    '/assets/min/image-optimization.min.css',
    '/about.html',
    '/services.html',
    '/contact.html',
    '/team.html',
    '/careers.html'
];

// Cache strategies for different resource types
const CACHE_STRATEGIES = {
    images: 'CacheFirst',
    css: 'StaleWhileRevalidate',
    js: 'StaleWhileRevalidate',
    html: 'NetworkFirst',
    fonts: 'CacheFirst',
    api: 'NetworkFirst'
};

self.addEventListener('install', event => {
    console.log('ðŸ”§ Service Worker: Installing...');

    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('ðŸ“¦ Service Worker: Precaching assets');
                return cache.addAll(PRECACHE_ASSETS);
            })
            .then(() => {
                console.log('âœ… Service Worker: Installation complete');
                return self.skipWaiting();
            })
            .catch(error => {
                console.error('âŒ Service Worker: Installation failed', error);
            })
    );
});

self.addEventListener('activate', event => {
    console.log('âš¡ Service Worker: Activating...');

    event.waitUntil(
        Promise.all([
            // Clean up old caches
            caches.keys().then(cacheNames => {
                return Promise.all(
                    cacheNames.map(cacheName => {
                        if (cacheName !== CACHE_NAME) {
                            console.log('ðŸ—‘ï¸ Service Worker: Deleting old cache', cacheName);
                            return caches.delete(cacheName);
                        }
                    })
                );
            }),

            // Take control of all clients immediately
            self.clients.claim()
        ])
            .then(() => {
                console.log('âœ… Service Worker: Activation complete');
            })
    );
});

self.addEventListener('fetch', event => {
    // Skip non-GET requests and chrome-extension requests
    if (event.request.method !== 'GET' ||
        event.request.url.startsWith('chrome-extension://')) {
        return;
    }

    const { request } = event;
    const url = new URL(request.url);

    // Handle different resource types with appropriate strategies
    if (url.pathname.endsWith('.html') || url.pathname === '/') {
        event.respondWith(handleHTMLRequest(request));
    } else if (url.pathname.match(/\.(css|js)$/)) {
        event.respondWith(handleAssetRequest(request));
    } else if (url.pathname.match(/\.(jpg|jpeg|png|gif|webp|svg)$/)) {
        event.respondWith(handleImageRequest(request));
    } else if (url.pathname.match(/\.(woff|woff2|ttf|eot)$/)) {
        event.respondWith(handleFontRequest(request));
    } else if (url.pathname.startsWith('/api/')) {
        event.respondWith(handleAPIRequest(request));
    } else {
        event.respondWith(handleGenericRequest(request));
    }
});

/**
 * Handle HTML requests with Network First strategy
 */
async function handleHTMLRequest(request) {
    try {
        // Try network first
        const networkResponse = await fetch(request);

        // Cache successful responses
        if (networkResponse.status === 200) {
            const cache = await caches.open(CACHE_NAME);
            cache.put(request, networkResponse.clone());
        }

        return networkResponse;
    } catch (error) {
        console.log('ðŸŒ Network unavailable, serving from cache:', request.url);

        // Fallback to cache
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            return cachedResponse;
        }

        // Ultimate fallback to offline page
        return caches.match(OFFLINE_URL);
    }
}

/**
 * Handle CSS/JS requests with Stale While Revalidate strategy
 */
async function handleAssetRequest(request) {
    const cache = await caches.open(CACHE_NAME);
    const cachedResponse = await cache.match(request);

    // Serve from cache immediately if available
    if (cachedResponse) {
        // Update cache in background
        fetch(request).then(response => {
            if (response.status === 200) {
                cache.put(request, response.clone());
            }
        }).catch(() => {
            // Ignore network errors for background updates
        });

        return cachedResponse;
    }

    // If not in cache, fetch from network
    try {
        const networkResponse = await fetch(request);
        if (networkResponse.status === 200) {
            cache.put(request, networkResponse.clone());
        }
        return networkResponse;
    } catch (error) {
        // Return a basic fallback for critical assets
        return new Response('/* Asset unavailable */', {
            headers: { 'Content-Type': 'text/css' }
        });
    }
}

/**
 * Handle image requests with Cache First strategy
 */
async function handleImageRequest(request) {
    const cache = await caches.open(CACHE_NAME);
    const cachedResponse = await cache.match(request);

    if (cachedResponse) {
        return cachedResponse;
    }

    try {
        const networkResponse = await fetch(request);
        if (networkResponse.status === 200) {
            cache.put(request, networkResponse.clone());
        }
        return networkResponse;
    } catch (error) {
        // Return placeholder image for failed requests
        return new Response(
            `<svg width="300" height="200" xmlns="http://www.w3.org/2000/svg">
                <rect width="100%" height="100%" fill="#f0f0f0"/>
                <text x="50%" y="50%" text-anchor="middle" dy=".3em" fill="#999">
                    Image unavailable
                </text>
            </svg>`,
            {
                headers: {
                    'Content-Type': 'image/svg+xml'
                }
            }
        );
    }
}

/**
 * Handle font requests with Cache First strategy (long-term caching)
 */
async function handleFontRequest(request) {
    const cache = await caches.open(CACHE_NAME);
    const cachedResponse = await cache.match(request);

    if (cachedResponse) {
        return cachedResponse;
    }

    try {
        const networkResponse = await fetch(request);
        if (networkResponse.status === 200) {
            // Cache fonts for a very long time
            const responseToCache = networkResponse.clone();
            cache.put(request, responseToCache);
        }
        return networkResponse;
    } catch (error) {
        // Fonts are not critical for functionality
        return new Response('', { status: 404 });
    }
}

/**
 * Handle API requests with Network First strategy and timeout
 */
async function handleAPIRequest(request) {
    const TIMEOUT = 5000; // 5 seconds

    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), TIMEOUT);

        const networkResponse = await fetch(request, {
            signal: controller.signal
        });

        clearTimeout(timeoutId);

        // Cache successful API responses for short periods
        if (networkResponse.status === 200) {
            const cache = await caches.open(CACHE_NAME);
            const responseToCache = networkResponse.clone();

            // Add timestamp for cache expiration
            const modifiedResponse = new Response(responseToCache.body, {
                status: responseToCache.status,
                statusText: responseToCache.statusText,
                headers: {
                    ...Object.fromEntries(responseToCache.headers.entries()),
                    'sw-cached-at': Date.now().toString()
                }
            });

            cache.put(request, modifiedResponse);
        }

        return networkResponse;
    } catch (error) {
        console.log('ðŸŒ API request failed, checking cache:', request.url);

        // Try cache with freshness check
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            const cachedAt = cachedResponse.headers.get('sw-cached-at');
            const age = Date.now() - parseInt(cachedAt || '0');

            // Serve cached response if less than 5 minutes old
            if (age < 300000) {
                return cachedResponse;
            }
        }

        // Return error response
        return new Response(
            JSON.stringify({ error: 'Service unavailable' }),
            {
                status: 503,
                headers: { 'Content-Type': 'application/json' }
            }
        );
    }
}

/**
 * Handle generic requests with basic caching
 */
async function handleGenericRequest(request) {
    try {
        const networkResponse = await fetch(request);

        if (networkResponse.status === 200) {
            const cache = await caches.open(CACHE_NAME);
            cache.put(request, networkResponse.clone());
        }

        return networkResponse;
    } catch (error) {
        const cachedResponse = await caches.match(request);
        return cachedResponse || new Response('Resource unavailable', { status: 404 });
    }
}

// Handle background sync for offline actions
self.addEventListener('sync', event => {
    console.log('ðŸ”„ Service Worker: Background sync triggered', event.tag);

    if (event.tag === 'form-submission') {
        event.waitUntil(processOfflineFormSubmissions());
    } else if (event.tag === 'analytics') {
        event.waitUntil(sendOfflineAnalytics());
    }
});

/**
 * Process form submissions that were queued while offline
 */
async function processOfflineFormSubmissions() {
    const submissions = await getStoredSubmissions();

    for (const submission of submissions) {
        try {
            await fetch(submission.url, {
                method: 'POST',
                headers: submission.headers,
                body: submission.body
            });

            console.log('âœ… Offline form submission processed');
            await removeStoredSubmission(submission.id);
        } catch (error) {
            console.log('âŒ Failed to process offline form submission:', error);
        }
    }
}

/**
 * Send analytics data that was queued while offline
 */
async function sendOfflineAnalytics() {
    const analyticsData = await getStoredAnalytics();

    for (const data of analyticsData) {
        try {
            await fetch('/api/analytics', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });

            console.log('âœ… Offline analytics data sent');
            await removeStoredAnalytics(data.id);
        } catch (error) {
            console.log('âŒ Failed to send offline analytics:', error);
        }
    }
}

// Handle push notifications
self.addEventListener('push', event => {
    console.log('ðŸ“± Service Worker: Push notification received');

    let notificationData = { title: 'iBridge Notification' };

    if (event.data) {
        try {
            notificationData = event.data.json();
        } catch (error) {
            notificationData.body = event.data.text();
        }
    }

    const options = {
        body: notificationData.body || 'You have a new notification',
        icon: '/images/iBridge_Logo-removebg-preview.png',
        badge: '/images/favicon.png',
        vibrate: [100, 50, 100],
        data: notificationData.data || {},
        actions: [
            {
                action: 'view',
                title: 'View',
                icon: '/images/icons/view.png'
            },
            {
                action: 'dismiss',
                title: 'Dismiss',
                icon: '/images/icons/dismiss.png'
            }
        ]
    };

    event.waitUntil(
        self.registration.showNotification(notificationData.title, options)
    );
});

// Handle notification clicks
self.addEventListener('notificationclick', event => {
    console.log('ðŸ”” Service Worker: Notification clicked');

    event.notification.close();

    if (event.action === 'view') {
        event.waitUntil(
            clients.openWindow(event.notification.data.url || '/')
        );
    }
});

// Utility functions for offline storage
async function getStoredSubmissions() {
    // In a real implementation, this would use IndexedDB
    return JSON.parse(localStorage.getItem('offline-submissions') || '[]');
}

async function removeStoredSubmission(id) {
    const submissions = await getStoredSubmissions();
    const filtered = submissions.filter(s => s.id !== id);
    localStorage.setItem('offline-submissions', JSON.stringify(filtered));
}

async function getStoredAnalytics() {
    return JSON.parse(localStorage.getItem('offline-analytics') || '[]');
}

async function removeStoredAnalytics(id) {
    const analytics = await getStoredAnalytics();
    const filtered = analytics.filter(a => a.id !== id);
    localStorage.setItem('offline-analytics', JSON.stringify(filtered));
}

// Performance optimization: Preload critical resources
self.addEventListener('message', event => {
    if (event.data && event.data.type === 'PRELOAD_RESOURCES') {
        const resources = event.data.resources;
        preloadResources(resources);
    }
});

async function preloadResources(resources) {
    const cache = await caches.open(CACHE_NAME);

    const preloadPromises = resources.map(async (resource) => {
        try {
            const response = await fetch(resource);
            if (response.status === 200) {
                await cache.put(resource, response);
                console.log('ðŸ“¦ Preloaded:', resource);
            }
        } catch (error) {
            console.warn('âš ï¸ Failed to preload:', resource, error);
        }
    });

    await Promise.all(preloadPromises);
}

console.log('ðŸš€ Service Worker: Script loaded');





