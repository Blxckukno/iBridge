/* Enhanced Google Maps JavaScript */

// Initialize map functionality when page loads
document.addEventListener('DOMContentLoaded', function() {
    initializeMapFeatures();
    setupMapLoadingHandler();
    setupResponsiveMapHeight();
});

// Initialize all map features
function initializeMapFeatures() {
    console.log('🗺️ Initializing Enhanced Google Maps Features');
    
    // Add loading state management
    const mapWrapper = document.getElementById('mapWrapper');
    const mapLoading = document.getElementById('mapLoading');
    const googleMap = document.getElementById('googleMap');
    
    if (googleMap) {
        // Show loading initially
        showMapLoading();
        
        // Hide loading when map loads
        googleMap.addEventListener('load', function() {
            hideMapLoading();
            console.log('✅ Google Maps loaded successfully');
        });
        
        // Handle map load errors
        googleMap.addEventListener('error', function() {
            console.error('❌ Error loading Google Maps');
            showMapError();
        });
    }
    
    // Add click tracking for analytics
    trackMapInteractions();
    
    // Setup accessibility features
    setupMapAccessibility();
}

// Map loading state management
function showMapLoading() {
    const mapLoading = document.getElementById('mapLoading');
    const mapWrapper = document.querySelector('.map-wrapper');
    
    if (mapLoading && mapWrapper) {
        mapLoading.classList.add('active');
        mapWrapper.classList.add('loading');
    }
}

function hideMapLoading() {
    const mapLoading = document.getElementById('mapLoading');
    const mapWrapper = document.querySelector('.map-wrapper');
    
    if (mapLoading && mapWrapper) {
        setTimeout(() => {
            mapLoading.classList.remove('active');
            mapWrapper.classList.remove('loading');
        }, 300);
    }
}

function showMapError() {
    const mapLoading = document.getElementById('mapLoading');
    if (mapLoading) {
        mapLoading.innerHTML = `
            <div class="map-error">
                <i class="fas fa-exclamation-triangle" style="color: #dc3545; font-size: 2rem; margin-bottom: 1rem;"></i>
                <p style="color: #dc3545; font-weight: 600;">Unable to load map</p>
                <p style="color: #6c757d; font-size: 0.9rem;">Please check your internet connection and try again</p>
                <button onclick="reloadMap()" class="btn btn-primary" style="margin-top: 1rem;">
                    <i class="fas fa-redo"></i> Retry
                </button>
            </div>
        `;
        mapLoading.classList.add('active');
    }
}

// Map control functions
function toggleMapView() {
    const iframe = document.getElementById('googleMap');
    if (!iframe) return;
    
    const currentSrc = iframe.src;
    let newSrc;
    
    // Toggle between normal and satellite view
    if (currentSrc.includes('&maptype=satellite')) {
        newSrc = currentSrc.replace('&maptype=satellite', '');
        console.log('🗺️ Switched to normal map view');
    } else {
        newSrc = currentSrc + '&maptype=satellite';
        console.log('🛰️ Switched to satellite view');
    }
    
    showMapLoading();
    iframe.src = newSrc;
    
    // Analytics tracking
    if (typeof gtag !== 'undefined') {
        gtag('event', 'map_view_toggle', {
            'event_category': 'Map Interaction',
            'event_label': currentSrc.includes('&maptype=satellite') ? 'normal' : 'satellite'
        });
    }
}

function centerMap() {
    const iframe = document.getElementById('googleMap');
    if (!iframe) return;
    
    // Add zoom and center parameters to ensure iBridge office is centered
    let currentSrc = iframe.src;
    
    // Remove existing zoom parameter if present
    currentSrc = currentSrc.replace(/&z=\d+/, '');
    
    // Add optimal zoom level for office location
    const newSrc = currentSrc + '&z=16';
    
    showMapLoading();
    iframe.src = newSrc;
    
    console.log('🎯 Map centered on iBridge office');
    
    // Analytics tracking
    if (typeof gtag !== 'undefined') {
        gtag('event', 'map_center', {
            'event_category': 'Map Interaction',
            'event_label': 'center_on_office'
        });
    }
}

function toggleFullscreen() {
    const mapContainer = document.querySelector('.enhanced-map');
    const mapWrapper = document.querySelector('.map-wrapper');
    const iframe = document.getElementById('googleMap');
    
    if (!mapContainer || !iframe) return;
    
    if (mapContainer.classList.contains('map-fullscreen')) {
        // Exit fullscreen
        mapContainer.classList.remove('map-fullscreen');
        document.body.style.overflow = '';
        
        // Update button icon
        const button = event.target.closest('.map-control-btn');
        if (button) {
            button.innerHTML = '<i class="fas fa-expand"></i>';
            button.title = 'Fullscreen';
        }
        
        console.log('📱 Exited fullscreen map mode');
        
        // Analytics
        if (typeof gtag !== 'undefined') {
            gtag('event', 'map_fullscreen_exit', {
                'event_category': 'Map Interaction'
            });
        }
    } else {
        // Enter fullscreen
        mapContainer.classList.add('map-fullscreen');
        document.body.style.overflow = 'hidden';
        
        // Update button icon
        const button = event.target.closest('.map-control-btn');
        if (button) {
            button.innerHTML = '<i class="fas fa-compress"></i>';
            button.title = 'Exit Fullscreen';
        }
        
        console.log('🖥️ Entered fullscreen map mode');
        
        // Analytics
        if (typeof gtag !== 'undefined') {
            gtag('event', 'map_fullscreen_enter', {
                'event_category': 'Map Interaction'
            });
        }
    }
    
    // Handle ESC key to exit fullscreen
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && mapContainer.classList.contains('map-fullscreen')) {
            toggleFullscreen();
        }
    });
}

function reloadMap() {
    const iframe = document.getElementById('googleMap');
    if (!iframe) return;
    
    showMapLoading();
    
    // Reload the iframe
    const currentSrc = iframe.src;
    iframe.src = '';
    
    setTimeout(() => {
        iframe.src = currentSrc;
        console.log('🔄 Map reloaded');
    }, 100);
    
    // Analytics
    if (typeof gtag !== 'undefined') {
        gtag('event', 'map_reload', {
            'event_category': 'Map Interaction'
        });
    }
}

// Setup loading handler
function setupMapLoadingHandler() {
    const iframe = document.getElementById('googleMap');
    if (!iframe) return;
    
    // Show loading on src change
    const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            if (mutation.type === 'attributes' && mutation.attributeName === 'src') {
                showMapLoading();
            }
        });
    });
    
    observer.observe(iframe, {
        attributes: true,
        attributeFilter: ['src']
    });
}

// Responsive map height
function setupResponsiveMapHeight() {
    function adjustMapHeight() {
        const iframe = document.getElementById('googleMap');
        if (!iframe) return;
        
        const windowHeight = window.innerHeight;
        const windowWidth = window.innerWidth;
        
        // Adjust height based on screen size
        if (windowWidth <= 768) {
            iframe.style.height = Math.min(400, windowHeight * 0.4) + 'px';
        } else if (windowWidth <= 1024) {
            iframe.style.height = '420px';
        } else {
            iframe.style.height = '450px';
        }
    }
    
    // Adjust on load and resize
    adjustMapHeight();
    window.addEventListener('resize', adjustMapHeight);
}

// Track map interactions for analytics
function trackMapInteractions() {
    // Track direction button clicks
    document.querySelectorAll('a[href*="google.com/maps/dir"]').forEach(link => {
        link.addEventListener('click', function() {
            console.log('🧭 User requested directions to iBridge office');
            
            if (typeof gtag !== 'undefined') {
                gtag('event', 'get_directions', {
                    'event_category': 'Map Interaction',
                    'event_label': 'iBridge_office'
                });
            }
        });
    });
    
    // Track "View on Google Maps" clicks
    document.querySelectorAll('a[href*="google.com/maps/place"]').forEach(link => {
        link.addEventListener('click', function() {
            console.log('🗺️ User opened location in Google Maps');
            
            if (typeof gtag !== 'undefined') {
                gtag('event', 'view_on_google_maps', {
                    'event_category': 'Map Interaction',
                    'event_label': 'iBridge_office'
                });
            }
        });
    });
}

// Setup accessibility features
function setupMapAccessibility() {
    const iframe = document.getElementById('googleMap');
    if (!iframe) return;
    
    // Add keyboard navigation for map controls
    document.querySelectorAll('.map-control-btn').forEach(btn => {
        btn.addEventListener('keydown', function(e) {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                btn.click();
            }
        });
    });
    
    // Add ARIA labels
    iframe.setAttribute('aria-label', 'Interactive map showing iBridge office location at 328 Kent Avenue, Ferndale, Randburg');
    
    // Add focus management
    iframe.addEventListener('focus', function() {
        console.log('🎯 Map received focus - keyboard navigation available');
    });
}

// Utility function to check if user prefers reduced motion
function prefersReducedMotion() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

// Enhanced error handling
window.addEventListener('error', function(e) {
    if (e.target && e.target.tagName === 'IFRAME' && e.target.id === 'googleMap') {
        console.error('Google Maps iframe error:', e);
        showMapError();
    }
});

// Performance monitoring
function logMapPerformance() {
    if ('performance' in window) {
        window.addEventListener('load', function() {
            setTimeout(() => {
                const perfData = performance.getEntriesByType('navigation')[0];
                console.log('📊 Map page performance:', {
                    loadTime: perfData.loadEventEnd - perfData.loadEventStart,
                    domContentLoaded: perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart
                });
            }, 100);
        });
    }
}

// Initialize performance monitoring
logMapPerformance();

// Export functions for global access
window.toggleMapView = toggleMapView;
window.centerMap = centerMap;
window.toggleFullscreen = toggleFullscreen;
window.reloadMap = reloadMap;

console.log('🗺️ Enhanced Google Maps JavaScript loaded successfully');
