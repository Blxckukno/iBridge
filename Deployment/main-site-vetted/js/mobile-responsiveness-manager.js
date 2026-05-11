/**
 * Mobile Responsiveness Manager
 * Advanced mobile optimization with touch gestures, responsive design,
 * device detection, and mobile-specific enhancements
 */

class MobileResponsivenessManager {
    constructor() {
        this.config = {
            breakpoints: {
                xs: 320,    // Extra small phones
                sm: 576,    // Small phones
                md: 768,    // Tablets
                lg: 992,    // Small laptops
                xl: 1200,   // Desktops
                xxl: 1400   // Large desktops
            },
            touchGestures: {
                enabled: true,
                swipeThreshold: 50,
                tapDelay: 300,
                longPressDelay: 800
            },
            mobileFeatures: {
                orientationLock: false,
                statusBarOverlay: true,
                viewportFit: 'cover',
                userScalable: false
            },
            performance: {
                lazyLoadOffset: 100,
                imageOptimization: true,
                resourcePriorities: true
            }
        };

        this.deviceInfo = {
            isMobile: false,
            isTablet: false,
            isDesktop: false,
            orientation: 'portrait',
            pixelRatio: window.devicePixelRatio || 1,
            touchCapable: false,
            screenSize: { width: 0, height: 0 },
            viewportSize: { width: 0, height: 0 }
        };

        this.touchEvents = {
            start: { x: 0, y: 0, time: 0 },
            end: { x: 0, y: 0, time: 0 },
            active: false
        };

        this.gestureHandlers = new Map();
        this.responsiveElements = new Set();

        this.init();
    }

    /**
     * Initialize Mobile Responsiveness Manager
     */
    init() {
        try {
            this.detectDevice();
            this.setupViewport();
            this.setupResponsiveDesign();
            this.setupTouchGestures();
            this.setupMobileNavigation();
            this.setupMobileOptimizations();
            this.setupOrientationHandling();
            this.createMobileToolbar();
            this.startResponsiveMonitoring();

            console.log('📱 Mobile Responsiveness Manager initialized');
            console.log('Device Info:', this.deviceInfo);
        } catch (error) {
            console.error('❌ Mobile Responsiveness Manager failed:', error);
        }
    }

    /**
     * Detect device type and capabilities
     */
    detectDevice() {
        const userAgent = navigator.userAgent.toLowerCase();
        const screenWidth = window.innerWidth;

        // Device type detection
        this.deviceInfo.isMobile = /android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini/i.test(userAgent) || screenWidth < this.config.breakpoints.md;
        this.deviceInfo.isTablet = /ipad|android(?!.*mobile)|kindle|silk/i.test(userAgent) || (screenWidth >= this.config.breakpoints.md && screenWidth < this.config.breakpoints.lg);
        this.deviceInfo.isDesktop = !this.deviceInfo.isMobile && !this.deviceInfo.isTablet;

        // Touch capability
        this.deviceInfo.touchCapable = 'ontouchstart' in window || navigator.maxTouchPoints > 0;

        // Screen and viewport sizes
        this.deviceInfo.screenSize = {
            width: window.screen.width,
            height: window.screen.height
        };
        this.deviceInfo.viewportSize = {
            width: window.innerWidth,
            height: window.innerHeight
        };

        // Orientation
        this.deviceInfo.orientation = window.innerHeight > window.innerWidth ? 'portrait' : 'landscape';

        // Add CSS classes for device targeting
        document.body.classList.add(
            this.deviceInfo.isMobile ? 'mobile-device' : 'non-mobile',
            this.deviceInfo.isTablet ? 'tablet-device' : 'non-tablet',
            this.deviceInfo.isDesktop ? 'desktop-device' : 'non-desktop',
            this.deviceInfo.touchCapable ? 'touch-capable' : 'no-touch',
            `orientation-${this.deviceInfo.orientation}`
        );
    }

    /**
     * Setup optimal viewport configuration
     */
    setupViewport() {
        let viewportMeta = document.querySelector('meta[name="viewport"]');

        if (!viewportMeta) {
            viewportMeta = document.createElement('meta');
            viewportMeta.name = 'viewport';
            document.head.appendChild(viewportMeta);
        }

        // Dynamic viewport based on device
        if (this.deviceInfo.isMobile) {
            viewportMeta.content = `width=device-width, initial-scale=1.0, maximum-scale=${this.config.mobileFeatures.userScalable ? '3.0' : '1.0'}, user-scalable=${this.config.mobileFeatures.userScalable ? 'yes' : 'no'}, viewport-fit=${this.config.mobileFeatures.viewportFit}`;
        } else {
            viewportMeta.content = 'width=device-width, initial-scale=1.0';
        }

        // Add theme-color for mobile browsers
        this.addMetaTag('theme-color', '#17a2b8');
        this.addMetaTag('msapplication-navbutton-color', '#17a2b8');
        this.addMetaTag('apple-mobile-web-app-status-bar-style', 'default');
        this.addMetaTag('apple-mobile-web-app-capable', 'yes');
    }

    /**
     * Add meta tag helper
     */
    addMetaTag(name, content) {
        if (!document.querySelector(`meta[name="${name}"]`)) {
            const meta = document.createElement('meta');
            meta.name = name;
            meta.content = content;
            document.head.appendChild(meta);
        }
    }

    /**
     * Setup responsive design enhancements
     */
    setupResponsiveDesign() {
        // Add responsive typography
        this.implementResponsiveTypography();

        // Setup responsive images
        this.setupResponsiveImages();

        // Setup responsive tables
        this.setupResponsiveTables();

        // Setup responsive forms
        this.setupResponsiveForms();

        // Setup responsive navigation
        this.setupResponsiveNavigation();

        // Monitor and adjust layouts
        window.addEventListener('resize', this.debounce(() => {
            this.handleResize();
        }, 250));
    }

    /**
     * Implement responsive typography
     */
    implementResponsiveTypography() {
        const style = document.createElement('style');
        style.textContent = `
            /* Fluid Typography */
            html {
                font-size: clamp(14px, 1.5vw, 18px);
            }
            
            h1 { font-size: clamp(1.8rem, 4vw, 3rem); }
            h2 { font-size: clamp(1.5rem, 3.5vw, 2.5rem); }
            h3 { font-size: clamp(1.3rem, 3vw, 2rem); }
            h4 { font-size: clamp(1.1rem, 2.5vw, 1.5rem); }
            h5 { font-size: clamp(1rem, 2vw, 1.25rem); }
            h6 { font-size: clamp(0.9rem, 1.5vw, 1.1rem); }
            
            p, li { 
                font-size: clamp(0.9rem, 1.2vw, 1.1rem);
                line-height: 1.6;
            }
            
            /* Mobile-first spacing */
            .container, .section {
                padding-left: clamp(15px, 4vw, 50px);
                padding-right: clamp(15px, 4vw, 50px);
            }
            
            .section {
                padding-top: clamp(30px, 8vw, 80px);
                padding-bottom: clamp(30px, 8vw, 80px);
            }
        `;
        document.head.appendChild(style);
    }

    /**
     * Setup responsive images
     */
    setupResponsiveImages() {
        const images = document.querySelectorAll('img:not([data-responsive-processed])');

        images.forEach(img => {
            // Add responsive classes
            if (!img.classList.contains('responsive-img')) {
                img.classList.add('responsive-img');
            }

            // Add loading optimization
            if (!img.hasAttribute('loading')) {
                img.loading = 'lazy';
            }

            // Add mobile-specific sizing
            if (this.deviceInfo.isMobile && !img.hasAttribute('sizes')) {
                img.sizes = '(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw';
            }

            img.setAttribute('data-responsive-processed', 'true');
        });
    }

    /**
     * Setup responsive tables
     */
    setupResponsiveTables() {
        const tables = document.querySelectorAll('table:not([data-responsive-processed])');

        tables.forEach(table => {
            // Wrap tables for horizontal scrolling on mobile
            const wrapper = document.createElement('div');
            wrapper.className = 'table-responsive';
            table.parentNode.insertBefore(wrapper, table);
            wrapper.appendChild(table);

            // Add mobile-friendly headers
            if (this.deviceInfo.isMobile) {
                this.makeMobileFriendlyTable(table);
            }

            table.setAttribute('data-responsive-processed', 'true');
        });
    }

    /**
     * Make table mobile-friendly
     */
    makeMobileFriendlyTable(table) {
        const headers = Array.from(table.querySelectorAll('th')).map(th => th.textContent);
        const rows = table.querySelectorAll('tbody tr');

        rows.forEach(row => {
            const cells = row.querySelectorAll('td');
            cells.forEach((cell, index) => {
                if (headers[index]) {
                    cell.setAttribute('data-label', headers[index]);
                }
            });
        });
    }

    /**
     * Setup responsive forms
     */
    setupResponsiveForms() {
        const forms = document.querySelectorAll('form:not([data-responsive-processed])');

        forms.forEach(form => {
            // Add responsive classes
            form.classList.add('responsive-form');

            // Optimize input types for mobile
            const inputs = form.querySelectorAll('input, textarea, select');
            inputs.forEach(input => {
                this.optimizeInputForMobile(input);
            });

            // Add touch-friendly buttons
            const buttons = form.querySelectorAll('button, input[type="submit"]');
            buttons.forEach(btn => {
                btn.classList.add('touch-friendly-btn');
            });

            form.setAttribute('data-responsive-processed', 'true');
        });
    }

    /**
     * Optimize input for mobile
     */
    optimizeInputForMobile(input) {
        if (!this.deviceInfo.isMobile) return;

        // Set appropriate input types and attributes
        const inputType = input.type?.toLowerCase();

        switch (inputType) {
            case 'email':
                input.setAttribute('autocomplete', 'email');
                input.setAttribute('inputmode', 'email');
                break;
            case 'tel':
                input.setAttribute('autocomplete', 'tel');
                input.setAttribute('inputmode', 'tel');
                break;
            case 'url':
                input.setAttribute('inputmode', 'url');
                break;
            case 'number':
                input.setAttribute('inputmode', 'numeric');
                break;
        }

        // Add mobile-friendly attributes
        input.setAttribute('autocapitalize', 'off');
        input.setAttribute('autocorrect', 'off');
        input.setAttribute('spellcheck', 'false');
    }

    /**
     * Setup responsive navigation
     */
    setupResponsiveNavigation() {
        const navs = document.querySelectorAll('nav, .navigation');

        navs.forEach(nav => {
            if (this.deviceInfo.isMobile) {
                this.createMobileMenu(nav);
            }
        });
    }

    /**
     * Create mobile menu
     */
    createMobileMenu(nav) {
        const menuItems = nav.querySelectorAll('a, .nav-item');

        if (menuItems.length > 3) { // Only create hamburger menu if more than 3 items
            const hamburger = document.createElement('button');
            hamburger.className = 'mobile-menu-toggle';
            hamburger.innerHTML = `
                <span class="hamburger-line"></span>
                <span class="hamburger-line"></span>
                <span class="hamburger-line"></span>
            `;

            const mobileMenu = document.createElement('div');
            mobileMenu.className = 'mobile-menu-overlay';

            // Move menu items to overlay
            menuItems.forEach(item => {
                const clone = item.cloneNode(true);
                clone.classList.add('mobile-menu-item');
                mobileMenu.appendChild(clone);
            });

            // Toggle functionality
            hamburger.addEventListener('click', () => {
                const isOpen = mobileMenu.classList.contains('active');

                if (isOpen) {
                    this.closeMobileMenu(mobileMenu, hamburger);
                } else {
                    this.openMobileMenu(mobileMenu, hamburger);
                }
            });

            nav.appendChild(hamburger);
            document.body.appendChild(mobileMenu);
        }
    }

    /**
     * Open mobile menu
     */
    openMobileMenu(menu, toggle) {
        menu.classList.add('active');
        toggle.classList.add('active');
        document.body.classList.add('mobile-menu-open');

        // Close on overlay click
        menu.addEventListener('click', (e) => {
            if (e.target === menu) {
                this.closeMobileMenu(menu, toggle);
            }
        });

        // Close on escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeMobileMenu(menu, toggle);
            }
        });
    }

    /**
     * Close mobile menu
     */
    closeMobileMenu(menu, toggle) {
        menu.classList.remove('active');
        toggle.classList.remove('active');
        document.body.classList.remove('mobile-menu-open');
    }

    /**
     * Setup touch gestures
     */
    setupTouchGestures() {
        if (!this.config.touchGestures.enabled || !this.deviceInfo.touchCapable) return;

        // Basic touch events
        document.addEventListener('touchstart', (e) => this.handleTouchStart(e), { passive: false });
        document.addEventListener('touchmove', (e) => this.handleTouchMove(e), { passive: false });
        document.addEventListener('touchend', (e) => this.handleTouchEnd(e), { passive: false });

        // Gesture recognition
        this.setupSwipeGestures();
        this.setupPinchZoom();
        this.setupLongPress();

        console.log('👆 Touch gestures enabled');
    }

    /**
     * Handle touch start
     */
    handleTouchStart(e) {
        const touch = e.touches[0];
        this.touchEvents.start = {
            x: touch.clientX,
            y: touch.clientY,
            time: Date.now()
        };
        this.touchEvents.active = true;
    }

    /**
     * Handle touch move
     */
    handleTouchMove(e) {
        if (!this.touchEvents.active) return;

        // Prevent default scrolling on specific elements
        const target = e.target.closest('.no-scroll, .touch-slider, .swipe-area');
        if (target) {
            e.preventDefault();
        }
    }

    /**
     * Handle touch end
     */
    handleTouchEnd(e) {
        if (!this.touchEvents.active) return;

        const touch = e.changedTouches[0];
        this.touchEvents.end = {
            x: touch.clientX,
            y: touch.clientY,
            time: Date.now()
        };

        this.processGesture();
        this.touchEvents.active = false;
    }

    /**
     * Process gesture based on touch data
     */
    processGesture() {
        const { start, end } = this.touchEvents;
        const deltaX = end.x - start.x;
        const deltaY = end.y - start.y;
        const deltaTime = end.time - start.time;
        const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);

        // Determine gesture type
        if (distance < 10 && deltaTime < this.config.touchGestures.tapDelay) {
            this.handleTap(end);
        } else if (distance > this.config.touchGestures.swipeThreshold) {
            this.handleSwipe(deltaX, deltaY, deltaTime);
        } else if (deltaTime > this.config.touchGestures.longPressDelay) {
            this.handleLongPress(end);
        }
    }

    /**
     * Handle tap gesture
     */
    handleTap(position) {
        this.emitGestureEvent('tap', { position });
    }

    /**
     * Handle swipe gesture
     */
    handleSwipe(deltaX, deltaY, deltaTime) {
        const direction = Math.abs(deltaX) > Math.abs(deltaY)
            ? (deltaX > 0 ? 'right' : 'left')
            : (deltaY > 0 ? 'down' : 'up');

        this.emitGestureEvent('swipe', {
            direction,
            distance: Math.abs(deltaX > deltaY ? deltaX : deltaY),
            speed: Math.abs(deltaX > deltaY ? deltaX : deltaY) / deltaTime
        });
    }

    /**
     * Handle long press gesture
     */
    handleLongPress(position) {
        this.emitGestureEvent('longpress', { position });
    }

    /**
     * Emit gesture event
     */
    emitGestureEvent(type, data) {
        const event = new CustomEvent(`mobile-gesture-${type}`, {
            detail: data,
            bubbles: true
        });
        document.dispatchEvent(event);
    }

    /**
     * Setup swipe gestures for specific elements
     */
    setupSwipeGestures() {
        // Image galleries
        const galleries = document.querySelectorAll('.gallery, .carousel, .slider');
        galleries.forEach(gallery => {
            this.enableSwipeNavigation(gallery);
        });

        // Navigation drawers
        document.addEventListener('mobile-gesture-swipe', (e) => {
            const { direction } = e.detail;

            if (direction === 'right') {
                this.handleSwipeRight();
            } else if (direction === 'left') {
                this.handleSwipeLeft();
            }
        });
    }

    /**
     * Enable swipe navigation for element
     */
    enableSwipeNavigation(element) {
        element.addEventListener('mobile-gesture-swipe', (e) => {
            const { direction } = e.detail;
            const currentIndex = parseInt(element.dataset.currentIndex || '0');
            const items = element.querySelectorAll('.slide, .gallery-item, .carousel-item');

            if (direction === 'left' && currentIndex < items.length - 1) {
                this.navigateToSlide(element, currentIndex + 1);
            } else if (direction === 'right' && currentIndex > 0) {
                this.navigateToSlide(element, currentIndex - 1);
            }
        });
    }

    /**
     * Navigate to slide
     */
    navigateToSlide(container, index) {
        container.dataset.currentIndex = index;
        const items = container.querySelectorAll('.slide, .gallery-item, .carousel-item');

        items.forEach((item, i) => {
            item.style.transform = `translateX(${(i - index) * 100}%)`;
        });
    }

    /**
     * Handle swipe right (open menu)
     */
    handleSwipeRight() {
        if (this.deviceInfo.isMobile) {
            const mobileMenu = document.querySelector('.mobile-menu-overlay');
            const hamburger = document.querySelector('.mobile-menu-toggle');

            if (mobileMenu && !mobileMenu.classList.contains('active')) {
                this.openMobileMenu(mobileMenu, hamburger);
            }
        }
    }

    /**
     * Handle swipe left (close menu)
     */
    handleSwipeLeft() {
        const mobileMenu = document.querySelector('.mobile-menu-overlay');
        const hamburger = document.querySelector('.mobile-menu-toggle');

        if (mobileMenu && mobileMenu.classList.contains('active')) {
            this.closeMobileMenu(mobileMenu, hamburger);
        }
    }

    /**
     * Setup pinch zoom functionality
     */
    setupPinchZoom() {
        let initialDistance = 0;
        let currentScale = 1;

        document.addEventListener('touchstart', (e) => {
            if (e.touches.length === 2) {
                initialDistance = this.getDistance(e.touches[0], e.touches[1]);
            }
        });

        document.addEventListener('touchmove', (e) => {
            if (e.touches.length === 2) {
                const currentDistance = this.getDistance(e.touches[0], e.touches[1]);
                const scale = currentDistance / initialDistance;

                if (scale !== currentScale) {
                    currentScale = scale;
                    this.emitGestureEvent('pinch', { scale });
                }
            }
        });
    }

    /**
     * Get distance between two touch points
     */
    getDistance(touch1, touch2) {
        const dx = touch2.clientX - touch1.clientX;
        const dy = touch2.clientY - touch1.clientY;
        return Math.sqrt(dx * dx + dy * dy);
    }

    /**
     * Setup long press functionality
     */
    setupLongPress() {
        // Add long press context menu for images
        const images = document.querySelectorAll('img');
        images.forEach(img => {
            img.addEventListener('mobile-gesture-longpress', (e) => {
                this.showImageContextMenu(img, e.detail.position);
            });
        });
    }

    /**
     * Show image context menu
     */
    showImageContextMenu(img, position) {
        const menu = document.createElement('div');
        menu.className = 'mobile-context-menu';
        menu.innerHTML = `
            <div class="context-menu-item" data-action="save">Save Image</div>
            <div class="context-menu-item" data-action="share">Share Image</div>
            <div class="context-menu-item" data-action="copy">Copy Image</div>
        `;

        menu.style.left = `${position.x}px`;
        menu.style.top = `${position.y}px`;

        document.body.appendChild(menu);

        // Remove menu on tap outside
        setTimeout(() => {
            document.addEventListener('click', () => {
                menu.remove();
            }, { once: true });
        }, 100);
    }

    /**
     * Setup mobile-specific optimizations
     */
    setupMobileOptimizations() {
        if (!this.deviceInfo.isMobile) return;

        // Disable hover effects on mobile
        this.disableHoverEffects();

        // Optimize scroll performance
        this.optimizeScrollPerformance();

        // Setup pull-to-refresh
        this.setupPullToRefresh();

        // Optimize focus management
        this.optimizeFocusManagement();

        // Setup mobile-specific CSS
        this.addMobileCSS();
    }

    /**
     * Disable hover effects on mobile
     */
    disableHoverEffects() {
        const style = document.createElement('style');
        style.textContent = `
            @media (hover: none) and (pointer: coarse) {
                *:hover {
                    /* Disable hover styles on touch devices */
                }
            }
        `;
        document.head.appendChild(style);
    }

    /**
     * Optimize scroll performance
     */
    optimizeScrollPerformance() {
        // Add momentum scrolling
        document.body.style.webkitOverflowScrolling = 'touch';

        // Use passive listeners for scroll events
        document.addEventListener('scroll', this.throttle(() => {
            this.handleScroll();
        }, 16), { passive: true });
    }

    /**
     * Setup pull-to-refresh
     */
    setupPullToRefresh() {
        let startY = 0;
        let currentY = 0;
        let isPulling = false;

        document.addEventListener('touchstart', (e) => {
            if (window.scrollY === 0) {
                startY = e.touches[0].clientY;
                isPulling = true;
            }
        });

        document.addEventListener('touchmove', (e) => {
            if (!isPulling) return;

            currentY = e.touches[0].clientY;
            const pullDistance = currentY - startY;

            if (pullDistance > 100 && window.scrollY === 0) {
                this.showPullToRefreshIndicator();
            }
        });

        document.addEventListener('touchend', () => {
            if (isPulling && currentY - startY > 100) {
                this.triggerRefresh();
            }
            isPulling = false;
            this.hidePullToRefreshIndicator();
        });
    }

    /**
     * Show pull-to-refresh indicator
     */
    showPullToRefreshIndicator() {
        let indicator = document.querySelector('.pull-refresh-indicator');
        if (!indicator) {
            indicator = document.createElement('div');
            indicator.className = 'pull-refresh-indicator';
            indicator.innerHTML = '🔄 Release to refresh';
            document.body.insertBefore(indicator, document.body.firstChild);
        }
        indicator.classList.add('visible');
    }

    /**
     * Hide pull-to-refresh indicator
     */
    hidePullToRefreshIndicator() {
        const indicator = document.querySelector('.pull-refresh-indicator');
        if (indicator) {
            indicator.classList.remove('visible');
        }
    }

    /**
     * Trigger refresh
     */
    triggerRefresh() {
        console.log('🔄 Pull-to-refresh triggered');
        // In a real app, this would refresh content
        setTimeout(() => {
            this.hidePullToRefreshIndicator();
        }, 1000);
    }

    /**
     * Optimize focus management for mobile
     */
    optimizeFocusManagement() {
        // Prevent zoom on input focus
        const inputs = document.querySelectorAll('input, select, textarea');
        inputs.forEach(input => {
            if (input.style.fontSize === '') {
                input.style.fontSize = '16px'; // Prevents zoom on iOS
            }
        });

        // Auto-blur inputs when scrolling
        let scrollTimeout;
        document.addEventListener('scroll', () => {
            clearTimeout(scrollTimeout);
            scrollTimeout = setTimeout(() => {
                if (document.activeElement && document.activeElement.blur) {
                    document.activeElement.blur();
                }
            }, 100);
        }, { passive: true });
    }

    /**
     * Add mobile-specific CSS
     */
    addMobileCSS() {
        const style = document.createElement('style');
        style.textContent = `
            /* Mobile-specific enhancements */
            .mobile-device {
                -webkit-tap-highlight-color: rgba(0, 0, 0, 0.1);
                -webkit-touch-callout: none;
                -webkit-user-select: none;
                user-select: none;
            }
            
            .mobile-device input, 
            .mobile-device textarea, 
            .mobile-device select {
                -webkit-user-select: text;
                user-select: text;
            }
            
            .touch-friendly-btn {
                min-height: 44px;
                min-width: 44px;
                padding: 12px 24px;
                touch-action: manipulation;
            }
            
            .mobile-menu-toggle {
                display: block;
                background: none;
                border: none;
                padding: 10px;
                cursor: pointer;
                z-index: 1001;
            }
            
            .hamburger-line {
                display: block;
                width: 25px;
                height: 3px;
                background: #333;
                margin: 5px 0;
                transition: 0.3s;
            }
            
            .mobile-menu-toggle.active .hamburger-line:nth-child(1) {
                transform: rotate(-45deg) translate(-5px, 6px);
            }
            
            .mobile-menu-toggle.active .hamburger-line:nth-child(2) {
                opacity: 0;
            }
            
            .mobile-menu-toggle.active .hamburger-line:nth-child(3) {
                transform: rotate(45deg) translate(-5px, -6px);
            }
            
            .mobile-menu-overlay {
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100vh;
                background: rgba(0, 0, 0, 0.9);
                z-index: 1000;
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
                transform: translateX(-100%);
                transition: transform 0.3s ease;
            }
            
            .mobile-menu-overlay.active {
                transform: translateX(0);
            }
            
            .mobile-menu-item {
                color: white;
                text-decoration: none;
                padding: 20px;
                font-size: 1.5rem;
                border-bottom: 1px solid rgba(255, 255, 255, 0.2);
                width: 100%;
                text-align: center;
            }
            
            .pull-refresh-indicator {
                position: fixed;
                top: -50px;
                left: 50%;
                transform: translateX(-50%);
                background: #17a2b8;
                color: white;
                padding: 10px 20px;
                border-radius: 0 0 10px 10px;
                transition: top 0.3s ease;
                z-index: 1001;
            }
            
            .pull-refresh-indicator.visible {
                top: 0;
            }
            
            .mobile-context-menu {
                position: fixed;
                background: white;
                border-radius: 8px;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
                z-index: 1002;
                overflow: hidden;
            }
            
            .context-menu-item {
                padding: 15px 20px;
                cursor: pointer;
                border-bottom: 1px solid #eee;
            }
            
            .context-menu-item:hover {
                background: #f8f9fa;
            }
            
            .context-menu-item:last-child {
                border-bottom: none;
            }
            
            /* Responsive table improvements */
            .table-responsive {
                overflow-x: auto;
                -webkit-overflow-scrolling: touch;
            }
            
            @media (max-width: 768px) {
                .table-responsive table {
                    font-size: 0.9rem;
                }
                
                .table-responsive td {
                    position: relative;
                    padding-left: 50% !important;
                }
                
                .table-responsive td:before {
                    content: attr(data-label) ": ";
                    position: absolute;
                    left: 6px;
                    width: 45%;
                    padding-right: 10px;
                    white-space: nowrap;
                    font-weight: bold;
                }
            }
        `;
        document.head.appendChild(style);
    }

    /**
     * Setup orientation handling
     */
    setupOrientationHandling() {
        window.addEventListener('orientationchange', () => {
            setTimeout(() => {
                this.handleOrientationChange();
            }, 100);
        });

        // Also listen for resize as backup
        window.addEventListener('resize', this.debounce(() => {
            this.detectDevice(); // Re-detect on resize
        }, 300));
    }

    /**
     * Handle orientation change
     */
    handleOrientationChange() {
        const newOrientation = window.innerHeight > window.innerWidth ? 'portrait' : 'landscape';

        if (newOrientation !== this.deviceInfo.orientation) {
            document.body.classList.remove(`orientation-${this.deviceInfo.orientation}`);
            document.body.classList.add(`orientation-${newOrientation}`);
            this.deviceInfo.orientation = newOrientation;

            // Emit orientation change event
            const event = new CustomEvent('mobile-orientation-change', {
                detail: { orientation: newOrientation }
            });
            document.dispatchEvent(event);

            console.log(`📱 Orientation changed to: ${newOrientation}`);
        }

        // Update viewport sizes
        this.deviceInfo.viewportSize = {
            width: window.innerWidth,
            height: window.innerHeight
        };
    }

    /**
     * Create mobile toolbar
     */
    createMobileToolbar() {
        if (!this.deviceInfo.isMobile) return;

        const toolbar = document.createElement('div');
        toolbar.className = 'mobile-toolbar';
        toolbar.innerHTML = `
            <button class="toolbar-btn" data-action="back" title="Go Back">
                ← Back
            </button>
            <button class="toolbar-btn" data-action="refresh" title="Refresh">
                🔄 Refresh
            </button>
            <button class="toolbar-btn" data-action="share" title="Share">
                📤 Share
            </button>
            <button class="toolbar-btn mobile-responsive-btn" title="Mobile Tools">
                📱
            </button>
        `;

        // Add toolbar styles
        const toolbarStyles = `
            .mobile-toolbar {
                position: fixed;
                bottom: 0;
                left: 0;
                right: 0;
                background: rgba(255, 255, 255, 0.95);
                backdrop-filter: blur(10px);
                border-top: 1px solid #eee;
                display: flex;
                justify-content: space-around;
                padding: 10px;
                z-index: 999;
                transform: translateY(100%);
                transition: transform 0.3s ease;
            }
            
            .mobile-toolbar.visible {
                transform: translateY(0);
            }
            
            .toolbar-btn {
                background: none;
                border: none;
                padding: 10px;
                font-size: 14px;
                cursor: pointer;
                border-radius: 8px;
                transition: background 0.2s ease;
            }
            
            .toolbar-btn:hover {
                background: rgba(0, 0, 0, 0.1);
            }
            
            .mobile-responsive-btn {
                background: #17a2b8 !important;
                color: white !important;
            }
        `;

        const style = document.createElement('style');
        style.textContent = toolbarStyles;
        document.head.appendChild(style);

        // Add toolbar functionality
        toolbar.addEventListener('click', (e) => {
            const action = e.target.dataset.action;
            this.handleToolbarAction(action);
        });

        document.body.appendChild(toolbar);

        // Show toolbar after a delay
        setTimeout(() => {
            toolbar.classList.add('visible');
        }, 1000);
    }

    /**
     * Handle toolbar actions
     */
    handleToolbarAction(action) {
        switch (action) {
            case 'back':
                if (window.history.length > 1) {
                    window.history.back();
                } else {
                    window.location.href = '/';
                }
                break;
            case 'refresh':
                window.location.reload();
                break;
            case 'share':
                this.shareCurrentPage();
                break;
        }
    }

    /**
     * Share current page
     */
    shareCurrentPage() {
        if (navigator.share) {
            navigator.share({
                title: document.title,
                text: 'Check out this page from iBridge Contact Solutions',
                url: window.location.href
            }).catch(console.error);
        } else {
            // Fallback: copy to clipboard
            navigator.clipboard.writeText(window.location.href).then(() => {
                alert('Page URL copied to clipboard!');
            });
        }
    }

    /**
     * Start responsive monitoring
     */
    startResponsiveMonitoring() {
        // Monitor performance impact of responsive features
        setInterval(() => {
            this.checkResponsivePerformance();
        }, 10000);

        // Monitor viewport changes
        if (window.ResizeObserver) {
            const resizeObserver = new ResizeObserver(() => {
                this.handleResize();
            });
            resizeObserver.observe(document.body);
        }
    }

    /**
     * Check responsive performance
     */
    checkResponsivePerformance() {
        const performanceData = {
            viewport: this.deviceInfo.viewportSize,
            orientation: this.deviceInfo.orientation,
            devicePixelRatio: this.deviceInfo.pixelRatio,
            timestamp: Date.now()
        };

        // Track with analytics if available
        if (window.analyticsManager) {
            window.analyticsManager.trackEvent('mobile_performance_check', performanceData);
        }
    }

    /**
     * Handle resize events
     */
    handleResize() {
        this.detectDevice();

        // Update responsive elements
        this.responsiveElements.forEach(element => {
            this.updateResponsiveElement(element);
        });

        // Emit resize event
        const event = new CustomEvent('mobile-responsive-resize', {
            detail: {
                viewport: this.deviceInfo.viewportSize,
                deviceInfo: this.deviceInfo
            }
        });
        document.dispatchEvent(event);
    }

    /**
     * Update responsive element
     */
    updateResponsiveElement(element) {
        // Re-apply responsive classes based on current viewport
        const breakpoint = this.getCurrentBreakpoint();
        element.className = element.className.replace(/\b(xs|sm|md|lg|xl|xxl)-\w+/g, '');
        element.classList.add(`${breakpoint}-responsive`);
    }

    /**
     * Get current breakpoint
     */
    getCurrentBreakpoint() {
        const width = window.innerWidth;

        if (width < this.config.breakpoints.sm) return 'xs';
        if (width < this.config.breakpoints.md) return 'sm';
        if (width < this.config.breakpoints.lg) return 'md';
        if (width < this.config.breakpoints.xl) return 'lg';
        if (width < this.config.breakpoints.xxl) return 'xl';
        return 'xxl';
    }

    /**
     * Utility functions
     */
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    throttle(func, limit) {
        let inThrottle;
        return function executedFunction(...args) {
            if (!inThrottle) {
                func.apply(this, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    }

    /**
     * Get comprehensive mobile report
     */
    getMobileReport() {
        return {
            deviceInfo: this.deviceInfo,
            config: this.config,
            responsiveElements: this.responsiveElements.size,
            gestureHandlers: this.gestureHandlers.size,
            currentBreakpoint: this.getCurrentBreakpoint(),
            timestamp: new Date().toISOString()
        };
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.mobileResponsivenessManager = new MobileResponsivenessManager();
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = MobileResponsivenessManager;
}