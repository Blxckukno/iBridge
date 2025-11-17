/**
 * Security Event Logger for iBridge Website
 * 
 * This script logs security-related events to a secure endpoint for monitoring and analysis.
 * Version: 1.0.0
 * Last Updated: September 9, 2025
 */

(function() {
    'use strict';
    
    // Configuration
    const config = {
        logEndpoint: '/api/security/log',
        enableConsoleLogging: false, // Set to false in production
        bufferSize: 10,              // Number of events to buffer before sending
        sendInterval: 30000,         // Send logs every 30 seconds if buffer not filled
        applicationId: 'iBridge-Website',
        version: '1.0.0'
    };
    
    // Event buffer
    let eventBuffer = [];
    let sendTimer = null;
    
    /**
     * Log a security event
     * @param {string} eventType - Type of security event
     * @param {Object} eventData - Event details
     */
    window.logSecurityEvent = function(eventType, eventData = {}) {
        if (!eventType) {
            console.error('Security event type is required');
            return;
        }
        
        // Create event object
        const event = {
            eventType,
            timestamp: new Date().toISOString(),
            url: window.location.href,
            userAgent: navigator.userAgent,
            referrer: document.referrer || 'direct',
            sessionId: getSessionId(),
            clientInfo: {
                screenWidth: window.screen.width,
                screenHeight: window.screen.height,
                viewportWidth: window.innerWidth,
                viewportHeight: window.innerHeight,
                timezoneOffset: new Date().getTimezoneOffset(),
                language: navigator.language || navigator.userLanguage
            },
            data: eventData
        };
        
        // Add to buffer
        eventBuffer.push(event);
        
        // Log to console if enabled
        if (config.enableConsoleLogging) {
            console.log('Security Event:', event);
        }
        
        // Send immediately if buffer is full
        if (eventBuffer.length >= config.bufferSize) {
            sendEvents();
        } else if (!sendTimer) {
            // Start timer if not already running
            sendTimer = setTimeout(sendEvents, config.sendInterval);
        }
    };
    
    /**
     * Send events to the logging endpoint
     */
    function sendEvents() {
        // Clear timer
        if (sendTimer) {
            clearTimeout(sendTimer);
            sendTimer = null;
        }
        
        // Don't send if buffer is empty
        if (eventBuffer.length === 0) {
            return;
        }
        
        // Prepare payload
        const payload = {
            application: config.applicationId,
            version: config.version,
            timestamp: new Date().toISOString(),
            events: [...eventBuffer]
        };
        
        // Clear buffer before sending to prevent loss if browser closes
        const eventsToSend = [...eventBuffer];
        eventBuffer = [];
        
        // Send data to server
        fetch(config.logEndpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload),
            keepalive: true // Ensure data is sent even if page is being unloaded
        })
        .then(response => {
            if (!response.ok) {
                // If sending fails, add events back to buffer
                eventBuffer = [...eventsToSend, ...eventBuffer];
                throw new Error('Failed to send security events');
            }
            
            if (config.enableConsoleLogging) {
                console.log('Security events sent successfully:', eventsToSend.length);
            }
        })
        .catch(error => {
            if (config.enableConsoleLogging) {
                console.error('Error sending security events:', error);
            }
            
            // Add events back to buffer if they couldn't be sent
            eventBuffer = [...eventsToSend, ...eventBuffer];
            
            // Limit buffer size to prevent memory issues
            if (eventBuffer.length > config.bufferSize * 3) {
                eventBuffer = eventBuffer.slice(-config.bufferSize * 3);
            }
        })
        .finally(() => {
            // Restart timer for any new events
            if (eventBuffer.length > 0) {
                sendTimer = setTimeout(sendEvents, config.sendInterval);
            }
        });
    }
    
    /**
     * Get or create a session ID
     * @returns {string} Session ID
     */
    function getSessionId() {
        let sessionId = sessionStorage.getItem('security_session_id');
        
        if (!sessionId) {
            sessionId = generateSessionId();
            sessionStorage.setItem('security_session_id', sessionId);
        }
        
        return sessionId;
    }
    
    /**
     * Generate a random session ID
     * @returns {string} Generated session ID
     */
    function generateSessionId() {
        const timestamp = new Date().getTime().toString(36);
        const random = Math.random().toString(36).substring(2, 10);
        return `${timestamp}-${random}`;
    }
    
    // Log initialization
    if (config.enableConsoleLogging) {
        console.log('Security logger initialized:', config.applicationId, config.version);
    }
    
    // Monitor for common security events
    
    // Monitor failed form submissions
    document.addEventListener('submit', function(e) {
        const form = e.target;
        
        // Monitor login forms specifically
        if (form.id === 'login-form' || form.classList.contains('login-form') || 
            form.getAttribute('action')?.includes('login') || 
            form.querySelector('input[type="password"]')) {
            
            // Store the form submission for monitoring failed attempts
            const formData = new FormData(form);
            const username = formData.get('username') || formData.get('email') || formData.get('user');
            
            if (username) {
                // Just log that a login attempt happened, not the credentials
                logSecurityEvent('login_attempt', {
                    formId: form.id || 'unknown',
                    formAction: form.getAttribute('action') || 'unknown',
                    hasUsername: !!username,
                    hasPassword: !!formData.get('password')
                });
            }
        }
    });
    
    // Monitor suspicious behavior like rapid clicking
    let clickCount = 0;
    const clickThreshold = 10;
    const clickTimeWindow = 3000; // 3 seconds
    
    document.addEventListener('click', function() {
        clickCount++;
        
        if (clickCount === 1) {
            setTimeout(function() {
                if (clickCount >= clickThreshold) {
                    logSecurityEvent('rapid_clicking', {
                        clicks: clickCount,
                        timeWindow: clickTimeWindow
                    });
                }
                clickCount = 0;
            }, clickTimeWindow);
        }
    });
    
    // Monitor for common XSS attempts in URL
    const xssPatterns = [
        /<script>/i,
        /javascript:/i,
        /onerror=/i,
        /onload=/i,
        /onclick=/i,
        /alert\(/i,
        /prompt\(/i,
        /eval\(/i
    ];
    
    function checkForXssAttempts() {
        const url = window.location.href;
        
        for (const pattern of xssPatterns) {
            if (pattern.test(url)) {
                logSecurityEvent('potential_xss_attempt', {
                    pattern: pattern.toString(),
                    url: url
                });
                break;
            }
        }
    }
    
    // Check on page load
    checkForXssAttempts();
    
    // Send events on page unload
    window.addEventListener('beforeunload', function() {
        if (eventBuffer.length > 0) {
            sendEvents();
        }
    });
})();
