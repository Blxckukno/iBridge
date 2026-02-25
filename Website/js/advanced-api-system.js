/**
 * iBridge Advanced API Enhancement System v1.0
 * Comprehensive API improvements with rate limiting, error handling, and documentation
 * Created: October 28, 2025
 */

class AdvancedAPISystem {
    constructor() {
        this.baseURL = '/api/v2';
        this.apiKey = this.getAPIKey();
        this.rateLimiter = new Map();
        this.retryConfig = {
            maxRetries: 3,
            baseDelay: 1000,
            maxDelay: 10000
        };
        this.cache = new Map();
        this.requestQueue = [];
        this.isProcessingQueue = false;
        this.websocket = null;
        this.eventListeners = new Map();
        this.init();
    }

    init() {
        this.setupInterceptors();
        this.initWebSocket();
        this.startRateLimitCleaner();
        this.loadCachedData();
        this.registerServiceWorker();
        console.log('%c🚀 Advanced API System v1.0 Loaded',
            'color: #00ff88; font-weight: bold; background: #000; padding: 5px 10px; border-radius: 5px;');
    }

    // API Key Management
    getAPIKey() {
        let apiKey = localStorage.getItem('iBridge-api-key');
        if (!apiKey) {
            apiKey = this.generateAPIKey();
            localStorage.setItem('iBridge-api-key', apiKey);
        }
        return apiKey;
    }

    generateAPIKey() {
        const timestamp = Date.now();
        const random = Math.random().toString(36).substring(2);
        return `iBridge_${timestamp}_${random}`;
    }

    // Rate Limiting System
    checkRateLimit(endpoint, limit = 100, window = 60000) {
        const now = Date.now();
        const key = `${endpoint}_${this.apiKey}`;

        if (!this.rateLimiter.has(key)) {
            this.rateLimiter.set(key, {
                requests: [],
                blocked: false,
                resetTime: now + window
            });
        }

        const limiter = this.rateLimiter.get(key);

        // Clean old requests
        limiter.requests = limiter.requests.filter(time => now - time < window);

        if (limiter.requests.length >= limit) {
            limiter.blocked = true;
            limiter.resetTime = now + window;
            throw new APIError(`Rate limit exceeded for ${endpoint}. Try again in ${Math.ceil((limiter.resetTime - now) / 1000)} seconds.`, 429);
        }

        limiter.requests.push(now);
        return true;
    }

    startRateLimitCleaner() {
        setInterval(() => {
            const now = Date.now();
            for (const [key, limiter] of this.rateLimiter.entries()) {
                if (limiter.resetTime <= now) {
                    limiter.blocked = false;
                    limiter.requests = [];
                }
            }
        }, 60000); // Clean every minute
    }

    // Advanced Request System
    async makeRequest(endpoint, options = {}) {
        const requestId = this.generateRequestId();
        const startTime = Date.now();

        try {
            // Check rate limiting
            this.checkRateLimit(endpoint, options.rateLimit?.limit, options.rateLimit?.window);

            // Check cache first
            if (options.method === 'GET' && options.cache !== false) {
                const cached = this.getCachedResponse(endpoint, options.params);
                if (cached && !this.isCacheExpired(cached)) {
                    console.log(`📦 Cache hit for ${endpoint}`);
                    return cached.data;
                }
            }

            // Prepare request
            const requestOptions = this.prepareRequest(endpoint, options);

            // Add to queue if needed
            if (options.queue) {
                return this.queueRequest(requestOptions);
            }

            // Make the actual request
            const response = await this.executeRequest(requestOptions, requestId);

            // Cache successful GET requests
            if (options.method === 'GET' && response.ok && options.cache !== false) {
                this.cacheResponse(endpoint, options.params, response.data, options.cacheTTL);
            }

            // Log analytics
            this.logAPICall(endpoint, options.method, Date.now() - startTime, response.status, requestId);

            return response.data;

        } catch (error) {
            // Enhanced error handling
            const enhancedError = this.enhanceError(error, endpoint, options, requestId);

            // Log error
            this.logAPIError(endpoint, options.method, enhancedError, requestId);

            // Retry logic for certain errors
            if (this.shouldRetry(enhancedError, options.retries || 0)) {
                console.log(`🔄 Retrying ${endpoint} (attempt ${(options.retries || 0) + 1})`);
                await this.delay(this.calculateRetryDelay(options.retries || 0));
                return this.makeRequest(endpoint, { ...options, retries: (options.retries || 0) + 1 });
            }

            throw enhancedError;
        }
    }

    prepareRequest(endpoint, options) {
        const url = this.buildURL(endpoint, options.params);
        const headers = {
            'Content-Type': 'application/json',
            'X-API-Key': this.apiKey,
            'X-Request-ID': this.generateRequestId(),
            'X-Client-Version': '2.0.0',
            'X-Timestamp': Date.now().toString(),
            ...options.headers
        };

        return {
            url,
            method: options.method || 'GET',
            headers,
            body: options.body ? JSON.stringify(options.body) : undefined,
            timeout: options.timeout || 30000,
            credentials: 'include'
        };
    }

    async executeRequest(requestOptions, requestId) {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), requestOptions.timeout);

        try {
            const response = await fetch(requestOptions.url, {
                ...requestOptions,
                signal: controller.signal
            });

            clearTimeout(timeoutId);

            if (!response.ok) {
                throw new APIError(
                    `HTTP ${response.status}: ${response.statusText}`,
                    response.status,
                    await this.safeParseResponse(response)
                );
            }

            const data = await this.safeParseResponse(response);

            return {
                ok: true,
                status: response.status,
                headers: Object.fromEntries(response.headers.entries()),
                data
            };

        } catch (error) {
            clearTimeout(timeoutId);

            if (error.name === 'AbortError') {
                throw new APIError('Request timeout', 408);
            }

            throw error;
        }
    }

    async safeParseResponse(response) {
        try {
            const text = await response.text();
            if (!text) return null;
            return JSON.parse(text);
        } catch (e) {
            console.warn('Failed to parse response as JSON:', e);
            return text;
        }
    }

    // Queue System for Batch Requests
    async queueRequest(requestOptions) {
        return new Promise((resolve, reject) => {
            this.requestQueue.push({
                ...requestOptions,
                resolve,
                reject,
                timestamp: Date.now()
            });

            if (!this.isProcessingQueue) {
                this.processQueue();
            }
        });
    }

    async processQueue() {
        if (this.isProcessingQueue || this.requestQueue.length === 0) return;

        this.isProcessingQueue = true;
        const batchSize = 5;

        while (this.requestQueue.length > 0) {
            const batch = this.requestQueue.splice(0, batchSize);

            await Promise.allSettled(
                batch.map(async (request) => {
                    try {
                        const response = await this.executeRequest(request, request.headers['X-Request-ID']);
                        request.resolve(response.data);
                    } catch (error) {
                        request.reject(error);
                    }
                })
            );

            // Small delay between batches
            await this.delay(100);
        }

        this.isProcessingQueue = false;
    }

    // Caching System
    getCachedResponse(endpoint, params) {
        const key = this.getCacheKey(endpoint, params);
        return this.cache.get(key);
    }

    cacheResponse(endpoint, params, data, ttl = 300000) { // 5 minutes default
        const key = this.getCacheKey(endpoint, params);
        this.cache.set(key, {
            data,
            timestamp: Date.now(),
            ttl
        });

        // Clean cache if it gets too large
        if (this.cache.size > 100) {
            this.cleanCache();
        }
    }

    getCacheKey(endpoint, params) {
        const paramString = params ? new URLSearchParams(params).toString() : '';
        return `${endpoint}?${paramString}`;
    }

    isCacheExpired(cached) {
        return Date.now() - cached.timestamp > cached.ttl;
    }

    cleanCache() {
        const now = Date.now();
        for (const [key, cached] of this.cache.entries()) {
            if (this.isCacheExpired(cached)) {
                this.cache.delete(key);
            }
        }
    }

    // WebSocket Integration
    initWebSocket() {
        if (!window.WebSocket) return;

        const wsProtocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsURL = `${wsProtocol}//${location.host}/api/ws`;

        try {
            this.websocket = new WebSocket(wsURL);

            this.websocket.onopen = () => {
                console.log('🌐 WebSocket connected');
                this.sendWSMessage({ type: 'auth', apiKey: this.apiKey });
            };

            this.websocket.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    this.handleWebSocketMessage(data);
                } catch (e) {
                    console.warn('Failed to parse WebSocket message:', e);
                }
            };

            this.websocket.onclose = () => {
                console.log('🌐 WebSocket disconnected');
                // Reconnect after 5 seconds
                setTimeout(() => this.initWebSocket(), 5000);
            };

            this.websocket.onerror = (error) => {
                console.error('🌐 WebSocket error:', error);
            };

        } catch (error) {
            console.warn('WebSocket not available:', error);
        }
    }

    sendWSMessage(message) {
        if (this.websocket && this.websocket.readyState === WebSocket.OPEN) {
            this.websocket.send(JSON.stringify(message));
        }
    }

    handleWebSocketMessage(data) {
        switch (data.type) {
            case 'notification':
                this.emit('notification', data.payload);
                break;
            case 'update':
                this.emit('dataUpdate', data.payload);
                this.invalidateCache(data.payload.endpoint);
                break;
            case 'error':
                this.emit('error', data.payload);
                break;
            default:
                this.emit('message', data);
        }
    }

    // Event System
    on(event, callback) {
        if (!this.eventListeners.has(event)) {
            this.eventListeners.set(event, new Set());
        }
        this.eventListeners.get(event).add(callback);
    }

    off(event, callback) {
        if (this.eventListeners.has(event)) {
            this.eventListeners.get(event).delete(callback);
        }
    }

    emit(event, data) {
        if (this.eventListeners.has(event)) {
            this.eventListeners.get(event).forEach(callback => {
                try {
                    callback(data);
                } catch (error) {
                    console.error(`Error in event listener for ${event}:`, error);
                }
            });
        }
    }

    // API Documentation System
    getAPIDocumentation() {
        return {
            version: '2.0.0',
            baseURL: this.baseURL,
            authentication: {
                method: 'API Key',
                header: 'X-API-Key',
                description: 'Include your API key in the X-API-Key header'
            },
            rateLimit: {
                default: '100 requests per minute',
                description: 'Rate limits are per API key and reset every minute'
            },
            endpoints: {
                tickets: {
                    list: {
                        method: 'GET',
                        path: '/tickets',
                        description: 'Retrieve a list of tickets',
                        parameters: {
                            page: { type: 'integer', default: 1, description: 'Page number' },
                            limit: { type: 'integer', default: 10, max: 100, description: 'Items per page' },
                            status: { type: 'string', enum: ['open', 'in-progress', 'resolved', 'closed'] },
                            priority: { type: 'string', enum: ['low', 'medium', 'high', 'critical'] },
                            assignee_id: { type: 'integer', description: 'Filter by assignee ID' }
                        },
                        response: {
                            200: {
                                description: 'Success',
                                schema: {
                                    data: 'array of ticket objects',
                                    pagination: 'pagination metadata'
                                }
                            }
                        }
                    },
                    create: {
                        method: 'POST',
                        path: '/tickets',
                        description: 'Create a new ticket',
                        body: {
                            title: { type: 'string', required: true, maxLength: 255 },
                            description: { type: 'string', required: true },
                            priority: { type: 'string', enum: ['low', 'medium', 'high', 'critical'], default: 'medium' },
                            assignee_id: { type: 'integer', optional: true }
                        }
                    },
                    get: {
                        method: 'GET',
                        path: '/tickets/{id}',
                        description: 'Get a specific ticket by ID',
                        parameters: {
                            id: { type: 'integer', required: true, description: 'Ticket ID' }
                        }
                    },
                    update: {
                        method: 'PUT',
                        path: '/tickets/{id}',
                        description: 'Update a ticket',
                        parameters: {
                            id: { type: 'integer', required: true, description: 'Ticket ID' }
                        },
                        body: {
                            title: { type: 'string', maxLength: 255 },
                            description: { type: 'string' },
                            status: { type: 'string', enum: ['open', 'in-progress', 'resolved', 'closed'] },
                            priority: { type: 'string', enum: ['low', 'medium', 'high', 'critical'] },
                            assignee_id: { type: 'integer' }
                        }
                    },
                    delete: {
                        method: 'DELETE',
                        path: '/tickets/{id}',
                        description: 'Delete a ticket',
                        parameters: {
                            id: { type: 'integer', required: true, description: 'Ticket ID' }
                        }
                    }
                },
                analytics: {
                    overview: {
                        method: 'GET',
                        path: '/analytics/overview',
                        description: 'Get system analytics overview',
                        cache: true,
                        cacheTTL: 60000
                    },
                    reports: {
                        method: 'GET',
                        path: '/analytics/reports',
                        description: 'Generate detailed reports',
                        parameters: {
                            type: { type: 'string', enum: ['performance', 'tickets', 'users'], required: true },
                            start_date: { type: 'string', format: 'date', required: true },
                            end_date: { type: 'string', format: 'date', required: true }
                        },
                        rateLimit: { limit: 10, window: 60000 }
                    }
                }
            },
            errors: {
                400: { description: 'Bad Request - Invalid parameters' },
                401: { description: 'Unauthorized - Invalid or missing API key' },
                403: { description: 'Forbidden - Insufficient permissions' },
                404: { description: 'Not Found - Resource does not exist' },
                429: { description: 'Too Many Requests - Rate limit exceeded' },
                500: { description: 'Internal Server Error' },
                503: { description: 'Service Unavailable - System maintenance' }
            },
            examples: {
                createTicket: {
                    method: 'POST',
                    url: '/api/v2/tickets',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-API-Key': 'your-api-key'
                    },
                    body: {
                        title: 'System downtime',
                        description: 'The main server is not responding',
                        priority: 'critical'
                    }
                }
            }
        };
    }

    // High-level API Methods
    async getTickets(params = {}) {
        return this.makeRequest('/tickets', {
            method: 'GET',
            params,
            cache: true,
            cacheTTL: 60000
        });
    }

    async createTicket(ticketData) {
        const response = await this.makeRequest('/tickets', {
            method: 'POST',
            body: ticketData
        });

        this.invalidateCache('/tickets');
        this.emit('ticketCreated', response);
        return response;
    }

    async updateTicket(id, updates) {
        const response = await this.makeRequest(`/tickets/${id}`, {
            method: 'PUT',
            body: updates
        });

        this.invalidateCache('/tickets');
        this.invalidateCache(`/tickets/${id}`);
        this.emit('ticketUpdated', { id, updates, result: response });
        return response;
    }

    async deleteTicket(id) {
        const response = await this.makeRequest(`/tickets/${id}`, {
            method: 'DELETE'
        });

        this.invalidateCache('/tickets');
        this.invalidateCache(`/tickets/${id}`);
        this.emit('ticketDeleted', { id });
        return response;
    }

    async getAnalytics(type = 'overview') {
        return this.makeRequest(`/analytics/${type}`, {
            method: 'GET',
            cache: true,
            cacheTTL: 300000 // 5 minutes
        });
    }

    // Utility Methods
    buildURL(endpoint, params) {
        const url = new URL(this.baseURL + endpoint, window.location.origin);
        if (params) {
            Object.entries(params).forEach(([key, value]) => {
                if (value !== undefined && value !== null) {
                    url.searchParams.append(key, value);
                }
            });
        }
        return url.toString();
    }

    generateRequestId() {
        return 'req_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    enhanceError(error, endpoint, options, requestId) {
        const enhanced = new APIError(
            error.message || 'Unknown API error',
            error.status || 500,
            error.data
        );

        enhanced.endpoint = endpoint;
        enhanced.requestId = requestId;
        enhanced.method = options.method;
        enhanced.timestamp = Date.now();
        enhanced.retryCount = options.retries || 0;

        return enhanced;
    }

    shouldRetry(error, retryCount) {
        if (retryCount >= this.retryConfig.maxRetries) return false;

        // Retry on network errors or 5xx status codes (except 501, 505)
        const retryableStatuses = [408, 429, 500, 502, 503, 504];
        return error.status === undefined || retryableStatuses.includes(error.status);
    }

    calculateRetryDelay(retryCount) {
        const baseDelay = this.retryConfig.baseDelay;
        const delay = Math.min(baseDelay * Math.pow(2, retryCount), this.retryConfig.maxDelay);
        // Add jitter to prevent thundering herd
        return delay + Math.random() * 1000;
    }

    async delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    invalidateCache(pattern) {
        for (const key of this.cache.keys()) {
            if (key.includes(pattern)) {
                this.cache.delete(key);
            }
        }
    }

    // Analytics and Logging
    logAPICall(endpoint, method, duration, status, requestId) {
        const logData = {
            type: 'api_call',
            endpoint,
            method,
            duration,
            status,
            requestId,
            timestamp: Date.now(),
            userAgent: navigator.userAgent
        };

        // Send to analytics if available
        if (window.advancedAnalytics) {
            window.advancedAnalytics.track('api_call', logData);
        }

        console.log(`📡 API Call: ${method} ${endpoint} - ${status} (${duration}ms)`);
    }

    logAPIError(endpoint, method, error, requestId) {
        const errorData = {
            type: 'api_error',
            endpoint,
            method,
            error: {
                message: error.message,
                status: error.status,
                code: error.code
            },
            requestId,
            timestamp: Date.now()
        };

        // Send to analytics if available
        if (window.advancedAnalytics) {
            window.advancedAnalytics.track('api_error', errorData);
        }

        console.error(`📡 API Error: ${method} ${endpoint} - ${error.status}: ${error.message}`);
    }

    // Service Worker Integration
    async registerServiceWorker() {
        if ('serviceWorker' in navigator) {
            try {
                const registration = await navigator.serviceWorker.register('/api-sw.js');
                console.log('📦 API Service Worker registered:', registration);

                // Listen for cache updates
                navigator.serviceWorker.addEventListener('message', (event) => {
                    if (event.data.type === 'CACHE_UPDATED') {
                        this.emit('cacheUpdated', event.data.payload);
                    }
                });
            } catch (error) {
                console.warn('📦 Service Worker registration failed:', error);
            }
        }
    }

    // Development helpers
    createAPITester() {
        const tester = document.createElement('div');
        tester.id = 'api-tester';
        tester.style.cssText = `
            position: fixed;
            bottom: 20px;
            left: 20px;
            background: var(--bg-primary, #fff);
            border: 1px solid var(--border-color, #ddd);
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.1);
            z-index: 9999;
            max-width: 400px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        `;

        tester.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                <h3 style="margin: 0; font-size: 16px;">🧪 API Tester</h3>
                <button onclick="this.closest('#api-tester').remove()" style="background: none; border: none; font-size: 18px; cursor: pointer;">×</button>
            </div>
            
            <div style="margin-bottom: 15px;">
                <select id="api-method" style="width: 100px; padding: 8px; border: 1px solid #ddd; border-radius: 4px; margin-right: 10px;">
                    <option value="GET">GET</option>
                    <option value="POST">POST</option>
                    <option value="PUT">PUT</option>
                    <option value="DELETE">DELETE</option>
                </select>
                <input type="text" id="api-endpoint" placeholder="/tickets" style="flex: 1; padding: 8px; border: 1px solid #ddd; border-radius: 4px; width: calc(100% - 120px);">
            </div>
            
            <textarea id="api-body" placeholder="Request body (JSON)" style="width: 100%; height: 80px; padding: 8px; border: 1px solid #ddd; border-radius: 4px; margin-bottom: 15px; font-family: monospace; font-size: 12px;"></textarea>
            
            <div style="display: flex; gap: 10px;">
                <button onclick="window.advancedAPI.testAPICall()" style="flex: 1; background: #007bff; color: white; border: none; padding: 10px; border-radius: 4px; cursor: pointer;">Test API</button>
                <button onclick="window.advancedAPI.showAPIDocs()" style="background: #28a745; color: white; border: none; padding: 10px 15px; border-radius: 4px; cursor: pointer;">Docs</button>
            </div>
            
            <div id="api-result" style="margin-top: 15px; padding: 10px; background: #f8f9fa; border-radius: 4px; font-family: monospace; font-size: 12px; white-space: pre-wrap; max-height: 200px; overflow-y: auto; display: none;"></div>
        `;

        document.body.appendChild(tester);
    }

    async testAPICall() {
        const method = document.getElementById('api-method').value;
        const endpoint = document.getElementById('api-endpoint').value;
        const bodyText = document.getElementById('api-body').value;
        const resultDiv = document.getElementById('api-result');

        if (!endpoint) {
            showApiNotification('Please enter an endpoint', 'warning');
            return;
        }

        try {
            let body = undefined;
            if (bodyText && (method === 'POST' || method === 'PUT')) {
                body = JSON.parse(bodyText);
            }

            const result = await this.makeRequest(endpoint, {
                method,
                body
            });

            resultDiv.style.display = 'block';
            resultDiv.style.color = '#28a745';
            resultDiv.textContent = JSON.stringify(result, null, 2);

        } catch (error) {
            resultDiv.style.display = 'block';
            resultDiv.style.color = '#dc3545';
            resultDiv.textContent = `Error: ${error.message}\n\n${JSON.stringify(error, null, 2)}`;
        }
    }

    showAPIDocs() {
        const docs = this.getAPIDocumentation();
        const modal = document.createElement('div');
        modal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.8);
            z-index: 10000;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        `;

        modal.innerHTML = `
            <div style="background: white; padding: 30px; border-radius: 12px; max-width: 800px; max-height: 90%; overflow-y: auto;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                    <h2 style="margin: 0;">📚 API Documentation v${docs.version}</h2>
                    <button onclick="this.closest('div').parentElement.remove()" style="background: none; border: none; font-size: 24px; cursor: pointer;">×</button>
                </div>
                <pre style="background: #f8f9fa; padding: 20px; border-radius: 8px; overflow-x: auto; white-space: pre-wrap; font-size: 12px;">${JSON.stringify(docs, null, 2)}</pre>
            </div>
        `;

        document.body.appendChild(modal);
    }

    // Load cached data on initialization
    loadCachedData() {
        try {
            const cached = localStorage.getItem('iBridge-api-cache');
            if (cached) {
                const data = JSON.parse(cached);
                Object.entries(data).forEach(([key, value]) => {
                    this.cache.set(key, value);
                });
            }
        } catch (error) {
            console.warn('Failed to load API cache:', error);
        }
    }

    // Save cache data
    saveCacheData() {
        try {
            const cacheData = Object.fromEntries(this.cache.entries());
            localStorage.setItem('iBridge-api-cache', JSON.stringify(cacheData));
        } catch (error) {
            console.warn('Failed to save API cache:', error);
        }
    }
}

// Custom API Error Class
class APIError extends Error {
    constructor(message, status = 500, data = null, code = null) {
        super(message);
        this.name = 'APIError';
        this.status = status;
        this.data = data;
        this.code = code;
        this.timestamp = Date.now();
    }

    toJSON() {
        return {
            name: this.name,
            message: this.message,
            status: this.status,
            data: this.data,
            code: this.code,
            timestamp: this.timestamp
        };
    }
}

// Initialize Advanced API System
document.addEventListener('DOMContentLoaded', () => {
    window.advancedAPI = new AdvancedAPISystem();

    // Add API tester in development mode
    if (localStorage.getItem('iBridge-dev-mode') === 'true') {
        setTimeout(() => {
            window.advancedAPI.createAPITester();
        }, 1000);
    }

    // Save cache before page unload
    window.addEventListener('beforeunload', () => {
        window.advancedAPI.saveCacheData();
    });

    // Professional notification system for API tester
    function showApiNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: ${type === 'warning' ? '#ff6b35' : type === 'error' ? '#dc3545' : '#28a745'};
            color: white;
            padding: 15px 20px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            z-index: 10000;
            font-weight: 500;
            max-width: 300px;
            transform: translateX(100%);
            transition: transform 0.3s ease;
        `;
        notification.textContent = message;

        document.body.appendChild(notification);

        // Show notification
        setTimeout(() => {
            notification.style.transform = 'translateX(0)';
        }, 10);

        // Auto remove after 3 seconds
        setTimeout(() => {
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, 3000);
    }

    // Make function globally available
    window.showApiNotification = showApiNotification;
});

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { AdvancedAPISystem, APIError };
}