const CACHE_NAME = 'ibridge-cache-v1';
const OFFLINE_URL = 'offline.html';

const urlsToCache = [
    './',
    'index.html',
    'css/styles.css',
    'js/scripts.js',
    'js/bundle.js',
    'images/logo.png',
    'images/logo.svg',
    OFFLINE_URL,
    'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css',
    'https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap',
    'https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&family=Playfair+Display:wght@400;700&display=swap'
];

// Install Service Worker
self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('Opened cache');
                return cache.addAll(urlsToCache);
            })
    );
});

// Activate Service Worker
self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cacheName => {
                    if (cacheName !== CACHE_NAME) {
                        return caches.delete(cacheName);
                    }
                })
            );
        })
    );
});

// Fetch Event Strategy
self.addEventListener('fetch', event => {
    // Skip cross-origin requests
    if (!event.request.url.startsWith(self.location.origin)) {
        return;
    }

    event.respondWith(
        caches.match(event.request)
            .then(response => {
                // Cache hit - return response
                if (response) {
                    return response;
                }

                return fetch(event.request)
                    .then(response => {
                        // Check if we received a valid response
                        if (!response || response.status !== 200 || response.type !== 'basic') {
                            return response;
                        }

                        // Clone the response
                        const responseToCache = response.clone();

                        caches.open(CACHE_NAME)
                            .then(cache => {
                                cache.put(event.request, responseToCache);
                            });

                        return response;
                    })
                    .catch(() => {
                        // If the request is for a page, show offline page
                        if (event.request.mode === 'navigate') {
                            return caches.match(OFFLINE_URL);
                        }
                    });
            })
    );
});

// Handle background sync for forms
self.addEventListener('sync', event => {
    if (event.tag === 'form-sync') {
        event.waitUntil(syncForms());
    }
});

// Sync stored form submissions
async function syncForms() {
    try {
        const formData = await getStoredFormData();
        if (formData.length === 0) return;

        for (const data of formData) {
            try {
                await fetch('/api/submit-form', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(data)
                });

                await removeFormData(data.id);
            } catch (error) {
                console.error('Error syncing form:', error);
            }
        }
    } catch (error) {
        console.error('Error in syncForms:', error);
    }
}

// Push notification event handler
self.addEventListener('push', event => {
    const options = {
        body: event.data.text(),
        icon: '/images/icons/icon-192x192.png',
        badge: '/images/icons/badge-72x72.png',
        vibrate: [100, 50, 100],
        data: {
            dateOfArrival: Date.now(),
            primaryKey: '1'
        },
        actions: [
            {
                action: 'explore',
                title: 'View Details',
                icon: '/images/icons/checkmark.png'
            },
            {
                action: 'close',
                title: 'Close',
                icon: '/images/icons/xmark.png'
            },
        ]
    };

    event.waitUntil(
        self.registration.showNotification('iBridge Contact Solutions', options)
    );
});