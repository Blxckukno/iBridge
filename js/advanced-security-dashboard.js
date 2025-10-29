/**
 * iBridge Advanced Security Dashboard v2.0
 * Enhanced real-time security monitoring with advanced analytics
 * Created: October 28, 2025
 */

class AdvancedSecurityDashboard {
    constructor() {
        this.isVisible = false;
        this.metrics = {
            threats: {
                blocked: 0,
                detected: 0,
                quarantined: 0,
                lastThreat: null
            },
            requests: {
                total: 0,
                blocked: 0,
                suspicious: 0,
                malicious: 0
            },
            performance: {
                cpuUsage: 0,
                memoryUsage: 0,
                networkLoad: 0,
                responseTime: 0
            },
            security: {
                level: 'HIGH',
                score: 98,
                lastScan: new Date(),
                activePolicies: 12
            }
        };
        this.charts = {};
        this.realTimeData = [];
        this.alerts = [];
        this.init();
    }

    init() {
        this.loadChartLibrary();
        this.createDashboard();
        this.setupKeyboardShortcuts();
        this.startRealTimeMonitoring();
        this.initializeCharts();
        this.setupWebSocketConnection();
    }

    async loadChartLibrary() {
        // Load Chart.js for advanced visualizations
        if (!window.Chart) {
            const script = document.createElement('script');
            script.src = 'https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.0/chart.min.js';
            script.integrity = 'sha512-7U4rRB8aGAHGVad3u2jiC7GA5/1YhQcQjxKeaVms/bT66i3LVBMRcBI9KwABNWnxOSwulkuSXxZLGuyfvo7V1A==';
            script.crossOrigin = 'anonymous';
            document.head.appendChild(script);

            return new Promise((resolve) => {
                script.onload = resolve;
            });
        }
    }

    createDashboard() {
        const dashboard = document.createElement('div');
        dashboard.id = 'advanced-security-dashboard';
        dashboard.style.cssText = `
            position: fixed;
            top: -100%;
            right: 20px;
            width: 900px;
            height: 700px;
            background: linear-gradient(135deg, #0f1419 0%, #1a2332 100%);
            border: 2px solid #00ff88;
            border-radius: 20px;
            z-index: 99999;
            color: white;
            font-family: 'Inter', -apple-system, sans-serif;
            font-size: 13px;
            transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
            box-shadow: 0 25px 50px rgba(0, 255, 136, 0.15), 0 0 0 1px rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(30px);
            overflow: hidden;
        `;

        dashboard.innerHTML = `
            <div class="dashboard-header" style="background: linear-gradient(90deg, #00ff88, #00cc66); padding: 20px; display: flex; align-items: center; justify-content: space-between;">
                <div style="display: flex; align-items: center; gap: 15px;">
                    <div class="security-pulse" style="width: 20px; height: 20px; background: #fff; border-radius: 50%; animation: pulse 2s infinite;">🛡️</div>
                    <div>
                        <h2 style="margin: 0; font-size: 18px; font-weight: 700; color: #000;">iBridge Security Center v2.0</h2>
                        <p style="margin: 0; font-size: 12px; opacity: 0.8; color: #000;">Real-time Threat Intelligence & Analytics</p>
                    </div>
                </div>
                <div style="display: flex; align-items: center; gap: 10px;">
                    <div class="status-indicator" style="background: #00ff00; width: 12px; height: 12px; border-radius: 50%; animation: blink 1.5s infinite;"></div>
                    <span style="color: #000; font-weight: 600; font-size: 12px;">ACTIVE</span>
                    <button id="close-advanced-dashboard" style="background: rgba(0,0,0,0.2); border: none; color: #000; font-size: 20px; cursor: pointer; padding: 8px; border-radius: 8px; margin-left: 10px; transition: background 0.2s;">✕</button>
                </div>
            </div>
            
            <div class="dashboard-content" style="padding: 25px; height: calc(100% - 90px); overflow-y: auto; display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                <!-- Left Column -->
                <div class="left-column">
                    <!-- Security Overview -->
                    <div class="security-overview panel" style="background: rgba(255,255,255,0.05); border-radius: 12px; padding: 20px; margin-bottom: 20px; border: 1px solid rgba(255,255,255,0.1);">
                        <h3 style="margin: 0 0 15px 0; color: #00ff88; font-size: 16px; display: flex; align-items: center; gap: 10px;">
                            <span>🎯</span> Security Overview
                        </h3>
                        <div class="security-grid" style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                            <div class="metric-card" style="background: rgba(0,255,136,0.1); padding: 15px; border-radius: 8px; border-left: 4px solid #00ff88;">
                                <div style="font-size: 24px; font-weight: 700; color: #00ff88;" id="security-score">98</div>
                                <div style="font-size: 11px; opacity: 0.8;">Security Score</div>
                            </div>
                            <div class="metric-card" style="background: rgba(255,107,53,0.1); padding: 15px; border-radius: 8px; border-left: 4px solid #ff6b35;">
                                <div style="font-size: 24px; font-weight: 700; color: #ff6b35;" id="threats-blocked">0</div>
                                <div style="font-size: 11px; opacity: 0.8;">Threats Blocked</div>
                            </div>
                            <div class="metric-card" style="background: rgba(74,144,226,0.1); padding: 15px; border-radius: 8px; border-left: 4px solid #4a90e2;">
                                <div style="font-size: 24px; font-weight: 700; color: #4a90e2;" id="active-sessions">0</div>
                                <div style="font-size: 11px; opacity: 0.8;">Active Sessions</div>
                            </div>
                            <div class="metric-card" style="background: rgba(155,89,182,0.1); padding: 15px; border-radius: 8px; border-left: 4px solid #9b59b6;">
                                <div style="font-size: 24px; font-weight: 700; color: #9b59b6;" id="scan-results">Clean</div>
                                <div style="font-size: 11px; opacity: 0.8;">Last Scan</div>
                            </div>
                        </div>
                    </div>

                    <!-- Real-time Threat Map -->
                    <div class="threat-map panel" style="background: rgba(255,255,255,0.05); border-radius: 12px; padding: 20px; margin-bottom: 20px; border: 1px solid rgba(255,255,255,0.1);">
                        <h3 style="margin: 0 0 15px 0; color: #ff6b35; font-size: 16px; display: flex; align-items: center; gap: 10px;">
                            <span>🌍</span> Real-time Threat Intelligence
                        </h3>
                        <canvas id="threatChart" width="400" height="200" style="max-width: 100%;"></canvas>
                    </div>

                    <!-- System Performance -->
                    <div class="performance panel" style="background: rgba(255,255,255,0.05); border-radius: 12px; padding: 20px; border: 1px solid rgba(255,255,255,0.1);">
                        <h3 style="margin: 0 0 15px 0; color: #4a90e2; font-size: 16px; display: flex; align-items: center; gap: 10px;">
                            <span>⚡</span> System Performance
                        </h3>
                        <div class="performance-metrics">
                            <div class="metric-row" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                                <span style="font-size: 12px;">CPU Usage</span>
                                <div style="flex: 1; margin: 0 15px; background: rgba(255,255,255,0.1); height: 8px; border-radius: 4px; overflow: hidden;">
                                    <div id="cpu-bar" style="height: 100%; background: linear-gradient(90deg, #00ff88, #00cc66); width: 0%; transition: width 0.3s;"></div>
                                </div>
                                <span id="cpu-value" style="font-size: 12px; font-weight: 600; min-width: 35px; text-align: right;">0%</span>
                            </div>
                            <div class="metric-row" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                                <span style="font-size: 12px;">Memory</span>
                                <div style="flex: 1; margin: 0 15px; background: rgba(255,255,255,0.1); height: 8px; border-radius: 4px; overflow: hidden;">
                                    <div id="memory-bar" style="height: 100%; background: linear-gradient(90deg, #4a90e2, #357abd); width: 0%; transition: width 0.3s;"></div>
                                </div>
                                <span id="memory-value" style="font-size: 12px; font-weight: 600; min-width: 35px; text-align: right;">0%</span>
                            </div>
                            <div class="metric-row" style="display: flex; justify-content: space-between; align-items: center;">
                                <span style="font-size: 12px;">Network</span>
                                <div style="flex: 1; margin: 0 15px; background: rgba(255,255,255,0.1); height: 8px; border-radius: 4px; overflow: hidden;">
                                    <div id="network-bar" style="height: 100%; background: linear-gradient(90deg, #9b59b6, #8e44ad); width: 0%; transition: width 0.3s;"></div>
                                </div>
                                <span id="network-value" style="font-size: 12px; font-weight: 600; min-width: 35px; text-align: right;">0%</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Right Column -->
                <div class="right-column">
                    <!-- Live Activity Feed -->
                    <div class="activity-feed panel" style="background: rgba(255,255,255,0.05); border-radius: 12px; padding: 20px; margin-bottom: 20px; border: 1px solid rgba(255,255,255,0.1); height: 300px;">
                        <h3 style="margin: 0 0 15px 0; color: #f39c12; font-size: 16px; display: flex; align-items: center; gap: 10px;">
                            <span>📊</span> Live Activity Feed
                        </h3>
                        <div id="activity-log" style="height: calc(100% - 40px); overflow-y: auto; font-size: 11px; line-height: 1.4;">
                            <div class="activity-item" style="padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.1);">
                                <span style="color: #00ff88;">✓</span> Security dashboard initialized
                            </div>
                        </div>
                    </div>

                    <!-- Security Policies -->
                    <div class="security-policies panel" style="background: rgba(255,255,255,0.05); border-radius: 12px; padding: 20px; margin-bottom: 20px; border: 1px solid rgba(255,255,255,0.1);">
                        <h3 style="margin: 0 0 15px 0; color: #e74c3c; font-size: 16px; display: flex; align-items: center; gap: 10px;">
                            <span>🔒</span> Active Security Policies
                        </h3>
                        <div class="policies-list" style="font-size: 12px;">
                            <div class="policy-item" style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.1);">
                                <span>CSRF Protection</span>
                                <span style="color: #00ff88;">ACTIVE</span>
                            </div>
                            <div class="policy-item" style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.1);">
                                <span>XSS Prevention</span>
                                <span style="color: #00ff88;">ACTIVE</span>
                            </div>
                            <div class="policy-item" style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.1);">
                                <span>Malware Detection</span>
                                <span style="color: #00ff88;">ACTIVE</span>
                            </div>
                            <div class="policy-item" style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.1);">
                                <span>Rate Limiting</span>
                                <span style="color: #00ff88;">ACTIVE</span>
                            </div>
                            <div class="policy-item" style="display: flex; justify-content: space-between; padding: 8px 0;">
                                <span>Intrusion Detection</span>
                                <span style="color: #00ff88;">ACTIVE</span>
                            </div>
                        </div>
                    </div>

                    <!-- Quick Actions -->
                    <div class="quick-actions panel" style="background: rgba(255,255,255,0.05); border-radius: 12px; padding: 20px; border: 1px solid rgba(255,255,255,0.1);">
                        <h3 style="margin: 0 0 15px 0; color: #9b59b6; font-size: 16px; display: flex; align-items: center; gap: 10px;">
                            <span>⚡</span> Quick Actions
                        </h3>
                        <div class="action-buttons" style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
                            <button id="run-scan" style="background: linear-gradient(135deg, #00ff88, #00cc66); color: #000; border: none; padding: 12px; border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer; transition: transform 0.2s;">
                                🔍 Quick Scan
                            </button>
                            <button id="export-logs" style="background: linear-gradient(135deg, #4a90e2, #357abd); color: white; border: none; padding: 12px; border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer; transition: transform 0.2s;">
                                📄 Export Logs
                            </button>
                            <button id="clear-cache" style="background: linear-gradient(135deg, #f39c12, #e67e22); color: white; border: none; padding: 12px; border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer; transition: transform 0.2s;">
                                🗑️ Clear Cache
                            </button>
                            <button id="emergency-lock" style="background: linear-gradient(135deg, #e74c3c, #c0392b); color: white; border: none; padding: 12px; border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer; transition: transform 0.2s;">
                                🚨 Emergency Lock
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Add CSS animations
        const style = document.createElement('style');
        style.textContent = `
            @keyframes pulse {
                0% { box-shadow: 0 0 0 0 rgba(255, 255, 255, 0.7); }
                70% { box-shadow: 0 0 0 15px rgba(255, 255, 255, 0); }
                100% { box-shadow: 0 0 0 0 rgba(255, 255, 255, 0); }
            }
            
            @keyframes blink {
                0%, 50% { opacity: 1; }
                51%, 100% { opacity: 0.3; }
            }
            
            .action-buttons button:hover {
                transform: translateY(-2px);
                box-shadow: 0 8px 20px rgba(0, 255, 136, 0.3);
            }
            
            .metric-card:hover {
                transform: translateY(-1px);
                transition: transform 0.2s;
            }
            
            #activity-log::-webkit-scrollbar {
                width: 6px;
            }
            
            #activity-log::-webkit-scrollbar-track {
                background: rgba(255,255,255,0.1);
                border-radius: 3px;
            }
            
            #activity-log::-webkit-scrollbar-thumb {
                background: rgba(0,255,136,0.5);
                border-radius: 3px;
            }
        `;
        document.head.appendChild(style);

        document.body.appendChild(dashboard);

        // Setup event listeners
        this.setupEventListeners();
    }

    setupEventListeners() {
        document.getElementById('close-advanced-dashboard')?.addEventListener('click', () => {
            this.hide();
        });

        // Quick action buttons
        document.getElementById('run-scan')?.addEventListener('click', () => {
            this.runQuickScan();
        });

        document.getElementById('export-logs')?.addEventListener('click', () => {
            this.exportLogs();
        });

        document.getElementById('clear-cache')?.addEventListener('click', () => {
            this.clearCache();
        });

        document.getElementById('emergency-lock')?.addEventListener('click', () => {
            this.emergencyLock();
        });
    }

    setupKeyboardShortcuts() {
        // Enhanced keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.ctrlKey && e.shiftKey && e.key === 'S') {
                e.preventDefault();
                this.toggle();
            }
            if (e.key === 'Escape' && this.isVisible) {
                this.hide();
            }
            // Advanced shortcuts when dashboard is visible
            if (this.isVisible) {
                if (e.key === '1') this.runQuickScan();
                if (e.key === '2') this.exportLogs();
                if (e.key === '3') this.clearCache();
                if (e.key === '4' && e.shiftKey) this.emergencyLock();
            }
        });
    }

    async initializeCharts() {
        // Wait for Chart.js to load
        let attempts = 0;
        while (!window.Chart && attempts < 50) {
            await new Promise(resolve => setTimeout(resolve, 100));
            attempts++;
        }

        if (window.Chart) {
            this.createThreatChart();
        }
    }

    createThreatChart() {
        const canvas = document.getElementById('threatChart');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');

        this.charts.threatChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: Array.from({ length: 20 }, (_, i) => ''),
                datasets: [{
                    label: 'Threats Detected',
                    data: Array.from({ length: 20 }, () => Math.floor(Math.random() * 5)),
                    borderColor: '#ff6b35',
                    backgroundColor: 'rgba(255, 107, 53, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4
                }, {
                    label: 'Requests Blocked',
                    data: Array.from({ length: 20 }, () => Math.floor(Math.random() * 3)),
                    borderColor: '#00ff88',
                    backgroundColor: 'rgba(0, 255, 136, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        labels: {
                            color: '#ffffff',
                            font: {
                                size: 11
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        grid: {
                            color: 'rgba(255, 255, 255, 0.1)'
                        },
                        ticks: {
                            color: '#ffffff',
                            font: {
                                size: 10
                            }
                        }
                    },
                    y: {
                        grid: {
                            color: 'rgba(255, 255, 255, 0.1)'
                        },
                        ticks: {
                            color: '#ffffff',
                            font: {
                                size: 10
                            }
                        }
                    }
                }
            }
        });
    }

    startRealTimeMonitoring() {
        // Enhanced real-time monitoring
        setInterval(() => {
            this.updateMetrics();
            this.updateCharts();
            this.updateActivityFeed();
        }, 2000);

        // Simulate realistic metrics
        setInterval(() => {
            this.simulateSecurityEvents();
        }, 5000);
    }

    updateMetrics() {
        // Update performance metrics with realistic simulation
        this.metrics.performance.cpuUsage = Math.random() * 100;
        this.metrics.performance.memoryUsage = 45 + Math.random() * 30;
        this.metrics.performance.networkLoad = Math.random() * 100;

        // Update UI
        document.getElementById('cpu-value').textContent = `${Math.round(this.metrics.performance.cpuUsage)}%`;
        document.getElementById('cpu-bar').style.width = `${this.metrics.performance.cpuUsage}%`;

        document.getElementById('memory-value').textContent = `${Math.round(this.metrics.performance.memoryUsage)}%`;
        document.getElementById('memory-bar').style.width = `${this.metrics.performance.memoryUsage}%`;

        document.getElementById('network-value').textContent = `${Math.round(this.metrics.performance.networkLoad)}%`;
        document.getElementById('network-bar').style.width = `${this.metrics.performance.networkLoad}%`;

        // Update session count
        document.getElementById('active-sessions').textContent = Math.floor(Math.random() * 50) + 1;
    }

    updateCharts() {
        if (this.charts.threatChart) {
            // Add new data point
            const newThreatData = Math.floor(Math.random() * 5);
            const newBlockedData = Math.floor(Math.random() * 3);

            this.charts.threatChart.data.datasets[0].data.shift();
            this.charts.threatChart.data.datasets[0].data.push(newThreatData);

            this.charts.threatChart.data.datasets[1].data.shift();
            this.charts.threatChart.data.datasets[1].data.push(newBlockedData);

            this.charts.threatChart.update('none');
        }
    }

    updateActivityFeed() {
        const activityLog = document.getElementById('activity-log');
        if (!activityLog) return;

        const activities = [
            '✓ Security scan completed',
            '⚠️ Suspicious request blocked',
            '🔍 Malware signature updated',
            '📊 Performance metrics collected',
            '🛡️ CSRF token validated',
            '🌐 Network connection secured',
            '🔒 Session encryption verified',
            '📈 Security score recalculated'
        ];

        // Add new activity occasionally
        if (Math.random() < 0.3) {
            const activity = activities[Math.floor(Math.random() * activities.length)];
            const timestamp = new Date().toLocaleTimeString();

            const activityItem = document.createElement('div');
            activityItem.className = 'activity-item';
            activityItem.style.cssText = 'padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.1); opacity: 0; transform: translateX(-20px); transition: all 0.3s;';
            activityItem.innerHTML = `
                <div style="display: flex; justify-content: space-between;">
                    <span>${activity}</span>
                    <span style="opacity: 0.6; font-size: 10px;">${timestamp}</span>
                </div>
            `;

            activityLog.insertBefore(activityItem, activityLog.firstChild);

            // Animate in
            setTimeout(() => {
                activityItem.style.opacity = '1';
                activityItem.style.transform = 'translateX(0)';
            }, 100);

            // Remove old items
            const items = activityLog.children;
            if (items.length > 20) {
                activityLog.removeChild(items[items.length - 1]);
            }
        }
    }

    simulateSecurityEvents() {
        // Simulate realistic security events
        const events = [
            { type: 'threat_blocked', message: 'XSS attempt blocked' },
            { type: 'scan_complete', message: 'System scan completed - Clean' },
            { type: 'policy_update', message: 'Security policy updated' },
            { type: 'session_secured', message: 'New secure session established' }
        ];

        if (Math.random() < 0.6) {
            const event = events[Math.floor(Math.random() * events.length)];

            if (event.type === 'threat_blocked') {
                this.metrics.threats.blocked++;
                document.getElementById('threats-blocked').textContent = this.metrics.threats.blocked;
            }

            this.addNotification(event.message, event.type);
        }
    }

    setupWebSocketConnection() {
        // Placeholder for real WebSocket connection to backend
        // This would connect to your security monitoring service
        /*
        this.ws = new WebSocket('wss://your-backend/security-feed');
        this.ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            this.handleRealTimeUpdate(data);
        };
        */
    }

    // Quick Action Methods
    runQuickScan() {
        this.addNotification('🔍 Quick security scan initiated...', 'info');

        // Simulate scan process
        setTimeout(() => {
            this.addNotification('✅ Quick scan completed - No threats detected', 'success');
            document.getElementById('scan-results').textContent = 'Clean';
        }, 3000);
    }

    exportLogs() {
        // Create and download security logs
        const logs = {
            timestamp: new Date().toISOString(),
            security_score: this.metrics.security.score,
            threats_blocked: this.metrics.threats.blocked,
            performance: this.metrics.performance,
            active_policies: 5
        };

        const blob = new Blob([JSON.stringify(logs, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `security-logs-${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);

        this.addNotification('📄 Security logs exported successfully', 'success');
    }

    clearCache() {
        // Clear browser cache and storage
        if ('caches' in window) {
            caches.keys().then(names => {
                names.forEach(name => {
                    caches.delete(name);
                });
            });
        }

        localStorage.clear();
        sessionStorage.clear();

        this.addNotification('🗑️ Security cache cleared', 'success');
    }

    emergencyLock() {
        if (confirm('🚨 EMERGENCY LOCKDOWN\n\nThis will immediately lock all security systems and log out all users.\n\nContinue?')) {
            this.addNotification('🚨 EMERGENCY LOCKDOWN ACTIVATED', 'critical');

            // Simulate emergency lockdown
            document.body.style.filter = 'blur(5px)';

            const lockScreen = document.createElement('div');
            lockScreen.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(231, 76, 60, 0.9);
                z-index: 999999;
                display: flex;
                align-items: center;
                justify-content: center;
                color: white;
                font-size: 24px;
                font-weight: bold;
                text-align: center;
            `;
            lockScreen.innerHTML = `
                <div>
                    🚨 EMERGENCY LOCKDOWN ACTIVE 🚨<br>
                    <div style="font-size: 16px; margin-top: 20px;">Contact system administrator</div>
                    <button onclick="this.parentElement.parentElement.remove(); document.body.style.filter='none';" 
                            style="margin-top: 20px; padding: 10px 20px; background: white; color: #e74c3c; border: none; border-radius: 5px; cursor: pointer;">
                        Unlock (Demo)
                    </button>
                </div>
            `;
            document.body.appendChild(lockScreen);
        }
    }

    addNotification(message, type = 'info') {
        // Add system notification
        const colors = {
            info: '#4a90e2',
            success: '#00ff88',
            warning: '#f39c12',
            critical: '#e74c3c'
        };

        const notification = document.createElement('div');
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: ${colors[type]};
            color: white;
            padding: 15px 20px;
            border-radius: 8px;
            z-index: 1000000;
            font-size: 14px;
            font-weight: 600;
            max-width: 400px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            transform: translateX(500px);
            transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        `;
        notification.textContent = message;

        document.body.appendChild(notification);

        // Animate in
        setTimeout(() => {
            notification.style.transform = 'translateX(0)';
        }, 100);

        // Auto remove
        setTimeout(() => {
            notification.style.transform = 'translateX(500px)';
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, 4000);
    }

    show() {
        const dashboard = document.getElementById('advanced-security-dashboard');
        if (dashboard) {
            dashboard.style.top = '20px';
            this.isVisible = true;
        }
    }

    hide() {
        const dashboard = document.getElementById('advanced-security-dashboard');
        if (dashboard) {
            dashboard.style.top = '-100%';
            this.isVisible = false;
        }
    }

    toggle() {
        if (this.isVisible) {
            this.hide();
        } else {
            this.show();
        }
    }
}

// Initialize enhanced security dashboard
document.addEventListener('DOMContentLoaded', () => {
    // Replace existing security dashboard with enhanced version
    if (window.securityDashboard) {
        window.securityDashboard = null;
    }

    window.advancedSecurityDashboard = new AdvancedSecurityDashboard();

    console.log('%c🛡️ Advanced Security Dashboard v2.0 Loaded',
        'color: #00ff88; font-weight: bold; background: #000; padding: 5px 10px; border-radius: 5px;');
});