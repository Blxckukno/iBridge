/**
 * Testing Framework Manager
 * Comprehensive testing suite for frontend functionality
 */

class TestingFrameworkManager {
    constructor() {
        this.config = {
            enableAutoTesting: false,
            enablePerformanceTesting: true,
            enableAccessibilityTesting: true,
            enableVisualTesting: false,
            testTimeout: 5000,
            enableReporting: true,
            enableConsoleOutput: true
        };

        this.tests = new Map();
        this.testSuites = new Map();
        this.results = new Map();
        this.isRunning = false;
        this.totalTests = 0;
        this.passedTests = 0;
        this.failedTests = 0;

        this.init();
    }

    /**
     * Initialize Testing Framework
     */
    init() {
        try {
            this.setupDefaultTests();
            this.createTestingInterface();

            if (this.config.enableAutoTesting) {
                this.scheduleAutoTests();
            }

            console.log('🧪 Testing Framework Manager initialized');

            // Auto-run basic health checks
            this.runHealthChecks();
        } catch (error) {
            console.error('❌ Testing Framework initialization failed:', error);
        }
    }

    /**
     * Setup default test suites
     */
    setupDefaultTests() {
        // Core functionality tests
        this.addTestSuite('core', 'Core Functionality Tests', [
            {
                name: 'DOM Ready',
                test: () => document.readyState === 'complete',
                description: 'Check if DOM is fully loaded'
            },
            {
                name: 'Required Scripts Loaded',
                test: () => {
                    const requiredScripts = ['analyticsManager', 'errorHandlingManager', 'formValidationManager'];
                    return requiredScripts.every(script => window[script] !== undefined);
                },
                description: 'Verify all required scripts are loaded'
            },
            {
                name: 'Local Storage Available',
                test: () => {
                    try {
                        localStorage.setItem('test', 'test');
                        localStorage.removeItem('test');
                        return true;
                    } catch (e) {
                        return false;
                    }
                },
                description: 'Check if localStorage is available'
            },
            {
                name: 'Session Storage Available',
                test: () => {
                    try {
                        sessionStorage.setItem('test', 'test');
                        sessionStorage.removeItem('test');
                        return true;
                    } catch (e) {
                        return false;
                    }
                },
                description: 'Check if sessionStorage is available'
            }
        ]);

        // Navigation tests
        this.addTestSuite('navigation', 'Navigation Tests', [
            {
                name: 'Navigation Menu Exists',
                test: () => document.querySelector('nav') !== null,
                description: 'Check if navigation menu is present'
            },
            {
                name: 'Mobile Menu Toggle',
                test: () => {
                    const toggle = document.querySelector('.navbar-toggler, .mobile-menu-toggle');
                    return toggle !== null;
                },
                description: 'Check if mobile menu toggle exists'
            },
            {
                name: 'Navigation Links Valid',
                test: () => {
                    const links = document.querySelectorAll('nav a[href]');
                    return Array.from(links).every(link => {
                        const href = link.getAttribute('href');
                        return href && (href.startsWith('#') || href.startsWith('/') || href.startsWith('http'));
                    });
                },
                description: 'Verify all navigation links have valid hrefs'
            }
        ]);

        // Form tests
        this.addTestSuite('forms', 'Form Functionality Tests', [
            {
                name: 'Forms Have Validation',
                test: () => {
                    const forms = document.querySelectorAll('form');
                    return Array.from(forms).every(form =>
                        form.hasAttribute('data-validation-manager') ||
                        form.querySelectorAll('[required]').length > 0
                    );
                },
                description: 'Check if forms have validation setup'
            },
            {
                name: 'Required Fields Marked',
                test: () => {
                    const requiredFields = document.querySelectorAll('[required]');
                    return Array.from(requiredFields).every(field => {
                        const label = field.labels?.[0];
                        return label && (label.textContent.includes('*') ||
                            field.getAttribute('aria-required') === 'true');
                    });
                },
                description: 'Verify required fields are properly marked'
            },
            {
                name: 'Form Submission Handlers',
                test: () => {
                    const forms = document.querySelectorAll('form');
                    return Array.from(forms).every(form => {
                        const hasAction = form.hasAttribute('action');
                        const hasHandler = form.onsubmit !== null;
                        return hasAction || hasHandler;
                    });
                },
                description: 'Check if forms have submission handling'
            }
        ]);

        // Performance tests
        this.addTestSuite('performance', 'Performance Tests', [
            {
                name: 'Page Load Time',
                test: () => {
                    const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
                    return loadTime < 3000; // 3 seconds
                },
                description: 'Check if page loads within 3 seconds'
            },
            {
                name: 'DOM Content Loaded Time',
                test: () => {
                    const domTime = performance.timing.domContentLoadedEventEnd - performance.timing.navigationStart;
                    return domTime < 1500; // 1.5 seconds
                },
                description: 'Check if DOM loads within 1.5 seconds'
            },
            {
                name: 'Resource Count',
                test: () => {
                    const resources = performance.getEntriesByType('resource');
                    return resources.length < 50; // Reasonable resource count
                },
                description: 'Check if resource count is reasonable'
            },
            {
                name: 'Memory Usage',
                test: () => {
                    if (performance.memory) {
                        return performance.memory.usedJSHeapSize < 50000000; // 50MB
                    }
                    return true; // Skip if memory API not available
                },
                description: 'Check if memory usage is within limits'
            }
        ]);

        // Accessibility tests
        this.addTestSuite('accessibility', 'Accessibility Tests', [
            {
                name: 'Page Has Title',
                test: () => document.title && document.title.trim().length > 0,
                description: 'Check if page has a title'
            },
            {
                name: 'Images Have Alt Text',
                test: () => {
                    const images = document.querySelectorAll('img');
                    return Array.from(images).every(img =>
                        img.hasAttribute('alt') || img.hasAttribute('aria-label')
                    );
                },
                description: 'Verify all images have alt text'
            },
            {
                name: 'Form Labels Associated',
                test: () => {
                    const inputs = document.querySelectorAll('input:not([type="hidden"]), textarea, select');
                    return Array.from(inputs).every(input => {
                        return input.labels?.length > 0 ||
                            input.hasAttribute('aria-label') ||
                            input.hasAttribute('aria-labelledby');
                    });
                },
                description: 'Check if form inputs have associated labels'
            },
            {
                name: 'Heading Hierarchy',
                test: () => {
                    const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
                    let lastLevel = 0;

                    return Array.from(headings).every(heading => {
                        const level = parseInt(heading.tagName[1]);
                        if (lastLevel === 0) {
                            lastLevel = level;
                            return level === 1; // Should start with h1
                        }

                        const isValid = level <= lastLevel + 1;
                        lastLevel = level;
                        return isValid;
                    });
                },
                description: 'Verify proper heading hierarchy'
            },
            {
                name: 'Focus Management',
                test: () => {
                    const focusableElements = document.querySelectorAll(
                        'a[href], button, input, textarea, select, [tabindex]:not([tabindex="-1"])'
                    );
                    return focusableElements.length > 0;
                },
                description: 'Check if page has focusable elements'
            }
        ]);

        // Security tests
        this.addTestSuite('security', 'Security Tests', [
            {
                name: 'HTTPS Protocol',
                test: () => location.protocol === 'https:' || location.hostname === 'localhost',
                description: 'Check if site uses HTTPS'
            },
            {
                name: 'No Mixed Content',
                test: () => {
                    const resources = document.querySelectorAll('[src], [href]');
                    return Array.from(resources).every(element => {
                        const url = element.src || element.href;
                        if (url && url.startsWith('http:') && location.protocol === 'https:') {
                            return url.includes('localhost') || url.includes('127.0.0.1');
                        }
                        return true;
                    });
                },
                description: 'Check for mixed content issues'
            },
            {
                name: 'CSP Header Present',
                test: () => {
                    const metaCSP = document.querySelector('meta[http-equiv="Content-Security-Policy"]');
                    return metaCSP !== null;
                },
                description: 'Check if Content Security Policy is present'
            },
            {
                name: 'Forms Use CSRF Protection',
                test: () => {
                    const forms = document.querySelectorAll('form[method="post"]');
                    return Array.from(forms).every(form => {
                        return form.querySelector('[name*="csrf"], [name*="token"]') !== null;
                    });
                },
                description: 'Check if POST forms have CSRF protection'
            }
        ]);

        // PWA tests
        this.addTestSuite('pwa', 'Progressive Web App Tests', [
            {
                name: 'Service Worker Registered',
                test: async () => {
                    return 'serviceWorker' in navigator &&
                        (await navigator.serviceWorker.getRegistrations()).length > 0;
                },
                description: 'Check if service worker is registered'
            },
            {
                name: 'Manifest Present',
                test: () => {
                    return document.querySelector('link[rel="manifest"]') !== null;
                },
                description: 'Check if web app manifest is present'
            },
            {
                name: 'Offline Page Available',
                test: async () => {
                    try {
                        const response = await fetch('/offline.html');
                        return response.ok;
                    } catch (e) {
                        return false;
                    }
                },
                description: 'Check if offline page is available'
            },
            {
                name: 'Cache Storage Available',
                test: () => 'caches' in window,
                description: 'Check if Cache API is available'
            }
        ]);
    }

    /**
     * Add test suite
     */
    addTestSuite(id, name, tests) {
        this.testSuites.set(id, {
            id,
            name,
            tests: tests.map((test, index) => ({
                ...test,
                id: `${id}_${index}`,
                suiteId: id
            }))
        });

        // Add individual tests to tests map
        tests.forEach((test, index) => {
            this.tests.set(`${id}_${index}`, {
                ...test,
                id: `${id}_${index}`,
                suiteId: id
            });
        });
    }

    /**
     * Run all tests
     */
    async runAllTests() {
        if (this.isRunning) {
            console.warn('Tests are already running');
            return;
        }

        this.isRunning = true;
        this.totalTests = 0;
        this.passedTests = 0;
        this.failedTests = 0;
        this.results.clear();

        console.group('🧪 Running All Tests');

        for (const [suiteId, suite] of this.testSuites) {
            await this.runTestSuite(suiteId);
        }

        this.isRunning = false;

        const report = this.generateTestReport();
        this.displayTestResults(report);

        console.groupEnd();

        return report;
    }

    /**
     * Run specific test suite
     */
    async runTestSuite(suiteId) {
        const suite = this.testSuites.get(suiteId);
        if (!suite) {
            console.error(`Test suite '${suiteId}' not found`);
            return;
        }

        console.group(`📋 ${suite.name}`);

        const suiteResults = [];

        for (const test of suite.tests) {
            const result = await this.runTest(test);
            suiteResults.push(result);
            this.results.set(test.id, result);
        }

        console.groupEnd();

        return suiteResults;
    }

    /**
     * Run individual test
     */
    async runTest(test) {
        this.totalTests++;
        const startTime = performance.now();

        try {
            const timeoutPromise = new Promise((_, reject) =>
                setTimeout(() => reject(new Error('Test timeout')), this.config.testTimeout)
            );

            const testPromise = Promise.resolve(test.test());
            const passed = await Promise.race([testPromise, timeoutPromise]);

            const endTime = performance.now();
            const duration = endTime - startTime;

            if (passed) {
                this.passedTests++;
                console.log(`✅ ${test.name} (${duration.toFixed(2)}ms)`);
            } else {
                this.failedTests++;
                console.error(`❌ ${test.name} - Test returned false (${duration.toFixed(2)}ms)`);
            }

            return {
                id: test.id,
                name: test.name,
                description: test.description,
                passed,
                duration,
                error: null
            };

        } catch (error) {
            this.failedTests++;
            const endTime = performance.now();
            const duration = endTime - startTime;

            console.error(`❌ ${test.name} - ${error.message} (${duration.toFixed(2)}ms)`);

            return {
                id: test.id,
                name: test.name,
                description: test.description,
                passed: false,
                duration,
                error: error.message
            };
        }
    }

    /**
     * Run health checks
     */
    async runHealthChecks() {
        const healthTests = this.testSuites.get('core')?.tests || [];
        const results = [];

        for (const test of healthTests) {
            const result = await this.runTest(test);
            results.push(result);
        }

        const allPassed = results.every(result => result.passed);

        if (allPassed) {
            console.log('✅ All health checks passed');
        } else {
            console.warn('⚠️ Some health checks failed');
        }

        return results;
    }

    /**
     * Performance benchmark
     */
    async runPerformanceBenchmark() {
        const benchmarks = {
            domQueries: this.benchmarkDOMQueries(),
            localStorage: this.benchmarkLocalStorage(),
            computation: this.benchmarkComputation(),
            rendering: await this.benchmarkRendering()
        };

        console.group('⚡ Performance Benchmarks');
        Object.entries(benchmarks).forEach(([name, result]) => {
            console.log(`${name}: ${result.duration.toFixed(2)}ms (${result.operations} ops)`);
        });
        console.groupEnd();

        return benchmarks;
    }

    /**
     * Benchmark DOM queries
     */
    benchmarkDOMQueries() {
        const start = performance.now();
        const operations = 1000;

        for (let i = 0; i < operations; i++) {
            document.querySelectorAll('div');
            document.getElementById('nonexistent');
            document.getElementsByClassName('test');
        }

        const end = performance.now();
        return { duration: end - start, operations };
    }

    /**
     * Benchmark localStorage
     */
    benchmarkLocalStorage() {
        const start = performance.now();
        const operations = 100;

        for (let i = 0; i < operations; i++) {
            localStorage.setItem(`test_${i}`, `value_${i}`);
            localStorage.getItem(`test_${i}`);
            localStorage.removeItem(`test_${i}`);
        }

        const end = performance.now();
        return { duration: end - start, operations };
    }

    /**
     * Benchmark computation
     */
    benchmarkComputation() {
        const start = performance.now();
        const operations = 10000;

        let result = 0;
        for (let i = 0; i < operations; i++) {
            result += Math.sqrt(i) * Math.sin(i);
        }

        const end = performance.now();
        return { duration: end - start, operations, result };
    }

    /**
     * Benchmark rendering
     */
    async benchmarkRendering() {
        return new Promise((resolve) => {
            const start = performance.now();

            // Create temporary elements
            const container = document.createElement('div');
            container.style.position = 'absolute';
            container.style.left = '-9999px';
            document.body.appendChild(container);

            for (let i = 0; i < 100; i++) {
                const div = document.createElement('div');
                div.textContent = `Test element ${i}`;
                div.className = 'test-element';
                container.appendChild(div);
            }

            requestAnimationFrame(() => {
                const end = performance.now();
                document.body.removeChild(container);
                resolve({ duration: end - start, operations: 100 });
            });
        });
    }

    /**
     * Generate test report
     */
    generateTestReport() {
        const report = {
            timestamp: new Date().toISOString(),
            totalTests: this.totalTests,
            passedTests: this.passedTests,
            failedTests: this.failedTests,
            passRate: (this.passedTests / this.totalTests * 100).toFixed(1),
            duration: Array.from(this.results.values()).reduce((sum, result) => sum + result.duration, 0),
            suites: {}
        };

        // Group results by suite
        for (const [suiteId, suite] of this.testSuites) {
            const suiteResults = suite.tests.map(test => this.results.get(test.id)).filter(Boolean);

            report.suites[suiteId] = {
                name: suite.name,
                totalTests: suiteResults.length,
                passedTests: suiteResults.filter(r => r.passed).length,
                failedTests: suiteResults.filter(r => !r.passed).length,
                duration: suiteResults.reduce((sum, r) => sum + r.duration, 0),
                results: suiteResults
            };
        }

        return report;
    }

    /**
     * Display test results
     */
    displayTestResults(report) {
        console.group('📊 Test Report Summary');
        console.log(`Total Tests: ${report.totalTests}`);
        console.log(`Passed: ${report.passedTests} (${report.passRate}%)`);
        console.log(`Failed: ${report.failedTests}`);
        console.log(`Duration: ${report.duration.toFixed(2)}ms`);

        Object.entries(report.suites).forEach(([suiteId, suite]) => {
            const passRate = (suite.passedTests / suite.totalTests * 100).toFixed(1);
            console.log(`${suite.name}: ${suite.passedTests}/${suite.totalTests} (${passRate}%)`);
        });

        console.groupEnd();

        // Create visual report if enabled
        if (this.config.enableReporting) {
            this.createVisualReport(report);
        }

        // Track in analytics
        if (window.analyticsManager) {
            window.analyticsManager.trackEvent('test_suite_completed', {
                total_tests: report.totalTests,
                passed_tests: report.passedTests,
                failed_tests: report.failedTests,
                pass_rate: report.passRate,
                duration: report.duration
            });
        }
    }

    /**
     * Create testing interface
     */
    createTestingInterface() {
        // Add keyboard shortcut for running tests
        document.addEventListener('keydown', (event) => {
            // Ctrl+Shift+T to run all tests
            if (event.ctrlKey && event.shiftKey && event.key === 'T') {
                event.preventDefault();
                this.runAllTests();
            }

            // Ctrl+Shift+H to run health checks
            if (event.ctrlKey && event.shiftKey && event.key === 'H') {
                event.preventDefault();
                this.runHealthChecks();
            }
        });

        // Add to global scope for console access
        window.testingFramework = this;

        console.log('🎛️ Testing Interface Ready:');
        console.log('- Run all tests: Ctrl+Shift+T or testingFramework.runAllTests()');
        console.log('- Run health checks: Ctrl+Shift+H or testingFramework.runHealthChecks()');
        console.log('- Run performance benchmark: testingFramework.runPerformanceBenchmark()');
    }

    /**
     * Create visual report
     */
    createVisualReport(report) {
        // Remove existing report
        const existingReport = document.getElementById('test-report');
        if (existingReport) {
            existingReport.remove();
        }

        const reportHTML = `
            <div id="test-report" style="
                position: fixed;
                top: 20px;
                right: 20px;
                width: 400px;
                background: white;
                border: 1px solid #ccc;
                border-radius: 8px;
                box-shadow: 0 4px 12px rgba(0,0,0,0.15);
                z-index: 9999;
                font-family: Arial, sans-serif;
                font-size: 14px;
                max-height: 80vh;
                overflow-y: auto;
            ">
                <div style="
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 15px;
                    border-radius: 8px 8px 0 0;
                    position: relative;
                ">
                    <h3 style="margin: 0; font-size: 16px;">Test Report</h3>
                    <button onclick="this.closest('#test-report').remove()" style="
                        position: absolute;
                        top: 10px;
                        right: 10px;
                        background: none;
                        border: none;
                        color: white;
                        font-size: 20px;
                        cursor: pointer;
                    ">&times;</button>
                </div>
                
                <div style="padding: 15px;">
                    <div style="margin-bottom: 15px;">
                        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                            <strong>Overall: ${report.passedTests}/${report.totalTests}</strong>
                            <span style="color: ${report.failedTests === 0 ? '#28a745' : '#dc3545'}">
                                ${report.passRate}% Pass Rate
                            </span>
                        </div>
                        <div style="
                            width: 100%;
                            height: 8px;
                            background: #e9ecef;
                            border-radius: 4px;
                            overflow: hidden;
                        ">
                            <div style="
                                width: ${report.passRate}%;
                                height: 100%;
                                background: ${report.failedTests === 0 ? '#28a745' : '#ffc107'};
                                transition: width 0.3s ease;
                            "></div>
                        </div>
                    </div>
                    
                    ${Object.entries(report.suites).map(([suiteId, suite]) => {
            const suitePassRate = (suite.passedTests / suite.totalTests * 100).toFixed(1);
            return `
                            <div style="margin-bottom: 12px; padding-bottom: 12px; border-bottom: 1px solid #eee;">
                                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px;">
                                    <strong style="font-size: 13px;">${suite.name}</strong>
                                    <span style="font-size: 12px; color: #666;">
                                        ${suite.passedTests}/${suite.totalTests}
                                    </span>
                                </div>
                                <div style="
                                    width: 100%;
                                    height: 4px;
                                    background: #e9ecef;
                                    border-radius: 2px;
                                    overflow: hidden;
                                ">
                                    <div style="
                                        width: ${suitePassRate}%;
                                        height: 100%;
                                        background: ${suite.failedTests === 0 ? '#28a745' : '#dc3545'};
                                    "></div>
                                </div>
                            </div>
                        `;
        }).join('')}
                    
                    <div style="font-size: 12px; color: #666; text-align: center;">
                        Generated: ${new Date(report.timestamp).toLocaleTimeString()}<br>
                        Duration: ${report.duration.toFixed(0)}ms
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', reportHTML);

        // Auto-remove after 10 seconds
        setTimeout(() => {
            const report = document.getElementById('test-report');
            if (report) report.remove();
        }, 10000);
    }

    /**
     * Schedule automatic tests
     */
    scheduleAutoTests() {
        // Run health checks every 5 minutes
        setInterval(() => {
            this.runHealthChecks();
        }, 5 * 60 * 1000);

        // Run full test suite every hour
        setInterval(() => {
            this.runAllTests();
        }, 60 * 60 * 1000);
    }

    /**
     * Export test results
     */
    exportResults(format = 'json') {
        const report = this.generateTestReport();

        switch (format) {
            case 'json':
                return JSON.stringify(report, null, 2);
            case 'csv':
                return this.convertToCSV(report);
            case 'html':
                return this.convertToHTML(report);
            default:
                return report;
        }
    }

    /**
     * Convert results to CSV
     */
    convertToCSV(report) {
        const rows = ['Suite,Test,Status,Duration,Error'];

        Object.entries(report.suites).forEach(([suiteId, suite]) => {
            suite.results.forEach(result => {
                rows.push([
                    suite.name,
                    result.name,
                    result.passed ? 'PASS' : 'FAIL',
                    result.duration.toFixed(2),
                    result.error || ''
                ].map(field => `"${field}"`).join(','));
            });
        });

        return rows.join('\n');
    }

    /**
     * Convert results to HTML
     */
    convertToHTML(report) {
        return `
            <!DOCTYPE html>
            <html>
            <head>
                <title>Test Report</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 20px; }
                    .summary { background: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
                    .suite { margin-bottom: 20px; }
                    .suite h3 { margin: 0 0 10px 0; }
                    table { width: 100%; border-collapse: collapse; }
                    th, td { padding: 8px; border: 1px solid #ddd; text-align: left; }
                    th { background: #f8f9fa; }
                    .pass { color: #28a745; }
                    .fail { color: #dc3545; }
                </style>
            </head>
            <body>
                <h1>Test Report</h1>
                <div class="summary">
                    <h2>Summary</h2>
                    <p>Total Tests: ${report.totalTests}</p>
                    <p>Passed: <span class="pass">${report.passedTests}</span></p>
                    <p>Failed: <span class="fail">${report.failedTests}</span></p>
                    <p>Pass Rate: ${report.passRate}%</p>
                    <p>Duration: ${report.duration.toFixed(2)}ms</p>
                    <p>Generated: ${new Date(report.timestamp).toLocaleString()}</p>
                </div>
                
                ${Object.entries(report.suites).map(([suiteId, suite]) => `
                    <div class="suite">
                        <h3>${suite.name}</h3>
                        <table>
                            <thead>
                                <tr>
                                    <th>Test</th>
                                    <th>Status</th>
                                    <th>Duration</th>
                                    <th>Error</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${suite.results.map(result => `
                                    <tr>
                                        <td>${result.name}</td>
                                        <td class="${result.passed ? 'pass' : 'fail'}">
                                            ${result.passed ? 'PASS' : 'FAIL'}
                                        </td>
                                        <td>${result.duration.toFixed(2)}ms</td>
                                        <td>${result.error || '-'}</td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    </div>
                `).join('')}
            </body>
            </html>
        `;
    }
}

// Initialize Testing Framework
document.addEventListener('DOMContentLoaded', () => {
    window.testingFrameworkManager = new TestingFrameworkManager();
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = TestingFrameworkManager;
}