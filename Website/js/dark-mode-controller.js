/**
 * iBridge Dark Mode Controller v1.0
 * Advanced dark mode implementation with smooth transitions
 * Created: October 28, 2025
 */

class DarkModeController {
    constructor() {
        this.isDarkMode = false;
        this.transitions = {
            duration: '0.3s',
            easing: 'cubic-bezier(0.4, 0, 0.2, 1)'
        };
        this.themes = {
            light: {
                '--primary-bg': '#ffffff',
                '--secondary-bg': '#f8f9fa',
                '--text-primary': '#333333',
                '--text-secondary': '#6c757d',
                '--border-color': '#e9ecef',
                '--shadow-color': 'rgba(0, 0, 0, 0.1)',
                '--card-bg': '#ffffff',
                '--nav-bg': '#ffffff',
                '--accent-color': '#A1C44F',
                '--success-color': '#28a745',
                '--warning-color': '#ffc107',
                '--danger-color': '#dc3545',
                '--info-color': '#17a2b8'
            },
            dark: {
                '--primary-bg': '#1a1a1a',
                '--secondary-bg': '#2d2d2d',
                '--text-primary': '#ffffff',
                '--text-secondary': '#b3b3b3',
                '--border-color': '#404040',
                '--shadow-color': 'rgba(0, 0, 0, 0.3)',
                '--card-bg': '#2d2d2d',
                '--nav-bg': '#1a1a1a',
                '--accent-color': '#00ff88',
                '--success-color': '#00ff88',
                '--warning-color': '#f39c12',
                '--danger-color': '#e74c3c',
                '--info-color': '#4a90e2'
            }
        };
        this.init();
    }

    init() {
        this.loadUserPreference();
        this.setupThemeVariables();
        this.createToggleControl();
        this.setupKeyboardShortcuts();
        this.observeSystemPreference();
        this.addTransitionStyles();
    }

    loadUserPreference() {
        const savedTheme = localStorage.getItem('iBridge-theme');
        const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

        if (savedTheme) {
            this.isDarkMode = savedTheme === 'dark';
        } else {
            this.isDarkMode = systemPrefersDark;
        }
    }

    setupThemeVariables() {
        const root = document.documentElement;
        const theme = this.isDarkMode ? this.themes.dark : this.themes.light;

        Object.entries(theme).forEach(([property, value]) => {
            root.style.setProperty(property, value);
        });

        // Update body class
        document.body.classList.toggle('dark-mode', this.isDarkMode);
        document.body.classList.toggle('light-mode', !this.isDarkMode);
    }

    addTransitionStyles() {
        const transitionStyle = document.createElement('style');
        transitionStyle.id = 'dark-mode-transitions';
        transitionStyle.textContent = `
            * {
                transition: background-color ${this.transitions.duration} ${this.transitions.easing},
                           color ${this.transitions.duration} ${this.transitions.easing},
                           border-color ${this.transitions.duration} ${this.transitions.easing},
                           box-shadow ${this.transitions.duration} ${this.transitions.easing} !important;
            }

            /* Dark mode specific styles */
            .dark-mode {
                background-color: var(--primary-bg);
                color: var(--text-primary);
            }

            .dark-mode .card,
            .dark-mode .panel,
            .dark-mode .service-card,
            .dark-mode .feature-card {
                background-color: var(--card-bg);
                border-color: var(--border-color);
                box-shadow: 0 4px 20px var(--shadow-color);
            }

            .dark-mode header,
            .dark-mode nav {
                background-color: var(--nav-bg);
                border-color: var(--border-color);
            }

            .dark-mode .hero-section {
                background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
            }

            .dark-mode .stats-section {
                background-color: var(--secondary-bg);
            }

            .dark-mode .footer {
                background: linear-gradient(135deg, #1a1a1a 0%, #0f0f0f 100%);
            }

            .dark-mode input,
            .dark-mode textarea,
            .dark-mode select {
                background-color: var(--secondary-bg);
                color: var(--text-primary);
                border-color: var(--border-color);
            }

            .dark-mode button:not(.btn-primary):not(.btn-success):not(.btn-warning):not(.btn-danger) {
                background-color: var(--secondary-bg);
                color: var(--text-primary);
                border-color: var(--border-color);
            }

            .dark-mode .btn-primary {
                background: linear-gradient(135deg, var(--accent-color), #00cc66);
            }

            .dark-mode .security-dashboard,
            .dark-mode #advanced-security-dashboard {
                background: linear-gradient(135deg, #0f1419 0%, #1a2332 100%);
                border-color: var(--accent-color);
            }

            .dark-mode .testimonial-card {
                background-color: var(--card-bg);
                border-color: var(--border-color);
            }

            .dark-mode .service-process .step {
                background-color: var(--card-bg);
                border-color: var(--border-color);
            }

            .dark-mode .mobile-menu {
                background-color: var(--nav-bg);
                border-color: var(--border-color);
            }

            .dark-mode .contact-form {
                background-color: var(--card-bg);
                border-color: var(--border-color);
            }

            /* Scrollbar styling for dark mode */
            .dark-mode ::-webkit-scrollbar {
                width: 8px;
                height: 8px;
            }

            .dark-mode ::-webkit-scrollbar-track {
                background: var(--secondary-bg);
                border-radius: 4px;
            }

            .dark-mode ::-webkit-scrollbar-thumb {
                background: var(--accent-color);
                border-radius: 4px;
            }

            .dark-mode ::-webkit-scrollbar-thumb:hover {
                background: #00cc66;
            }

            /* Image adjustments for dark mode */
            .dark-mode img:not(.no-filter) {
                filter: brightness(0.9) contrast(1.1);
            }

            .dark-mode .logo {
                filter: brightness(1.2);
            }

            /* Code and pre elements */
            .dark-mode pre,
            .dark-mode code {
                background-color: #0f0f0f;
                color: var(--accent-color);
                border-color: var(--border-color);
            }

            /* Table styles */
            .dark-mode table {
                background-color: var(--card-bg);
                color: var(--text-primary);
            }

            .dark-mode table th {
                background-color: var(--secondary-bg);
                border-color: var(--border-color);
            }

            .dark-mode table td {
                border-color: var(--border-color);
            }

            /* Modal styles */
            .dark-mode .modal-content {
                background-color: var(--card-bg);
                color: var(--text-primary);
                border-color: var(--border-color);
            }

            /* Progress bars */
            .dark-mode .progress {
                background-color: var(--secondary-bg);
            }

            .dark-mode .progress-bar {
                background: linear-gradient(90deg, var(--accent-color), #00cc66);
            }
        `;
        document.head.appendChild(transitionStyle);
    }

    createToggleControl() {
        const toggle = document.createElement('div');
        toggle.id = 'dark-mode-toggle';
        toggle.style.cssText = `
            position: fixed;
            top: 20px;
            right: 120px;
            z-index: 9998;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border: 2px solid rgba(255, 255, 255, 0.2);
            border-radius: 25px;
            padding: 8px;
            cursor: pointer;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            user-select: none;
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 14px;
            font-weight: 600;
        `;

        toggle.innerHTML = `
            <div class="theme-icon" style="font-size: 20px; transition: transform 0.3s;">${this.isDarkMode ? '🌙' : '☀️'}</div>
            <span class="theme-text" style="color: white; min-width: 70px;">${this.isDarkMode ? 'Dark Mode' : 'Light Mode'}</span>
            <div class="toggle-switch" style="
                width: 50px;
                height: 25px;
                background: ${this.isDarkMode ? 'var(--accent-color)' : 'rgba(255,255,255,0.3)'};
                border-radius: 15px;
                position: relative;
                transition: background 0.3s;
            ">
                <div class="toggle-knob" style="
                    width: 21px;
                    height: 21px;
                    background: white;
                    border-radius: 50%;
                    position: absolute;
                    top: 2px;
                    left: ${this.isDarkMode ? '27px' : '2px'};
                    transition: left 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                    box-shadow: 0 2px 10px rgba(0,0,0,0.2);
                "></div>
            </div>
        `;

        // Add hover effects
        toggle.addEventListener('mouseenter', () => {
            toggle.style.transform = 'scale(1.05)';
            toggle.style.background = 'rgba(255, 255, 255, 0.15)';
        });

        toggle.addEventListener('mouseleave', () => {
            toggle.style.transform = 'scale(1)';
            toggle.style.background = 'rgba(255, 255, 255, 0.1)';
        });

        toggle.addEventListener('click', () => {
            this.toggle();
        });

        document.body.appendChild(toggle);
    }

    toggle() {
        this.isDarkMode = !this.isDarkMode;

        // Add a nice animation effect
        document.body.style.transition = 'none';
        document.body.style.filter = 'brightness(0.8)';

        setTimeout(() => {
            this.setupThemeVariables();
            this.updateToggleControl();
            this.saveUserPreference();

            document.body.style.transition = '';
            document.body.style.filter = '';

            // Trigger theme change event
            this.dispatchThemeChangeEvent();
        }, 100);
    }

    updateToggleControl() {
        const toggle = document.getElementById('dark-mode-toggle');
        if (!toggle) return;

        const icon = toggle.querySelector('.theme-icon');
        const text = toggle.querySelector('.theme-text');
        const toggleSwitch = toggle.querySelector('.toggle-switch');
        const knob = toggle.querySelector('.toggle-knob');

        if (icon) {
            icon.textContent = this.isDarkMode ? '🌙' : '☀️';
            icon.style.transform = 'rotate(360deg)';
            setTimeout(() => {
                icon.style.transform = 'rotate(0deg)';
            }, 300);
        }

        if (text) {
            text.textContent = this.isDarkMode ? 'Dark Mode' : 'Light Mode';
        }

        if (toggleSwitch) {
            toggleSwitch.style.background = this.isDarkMode ? 'var(--accent-color)' : 'rgba(255,255,255,0.3)';
        }

        if (knob) {
            knob.style.left = this.isDarkMode ? '27px' : '2px';
        }
    }

    setupKeyboardShortcuts() {
        document.addEventListener('keydown', (e) => {
            // Ctrl/Cmd + Shift + D to toggle dark mode
            if ((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'D') {
                e.preventDefault();
                this.toggle();
            }
        });
    }

    observeSystemPreference() {
        // Watch for system theme changes
        const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
        mediaQuery.addEventListener('change', (e) => {
            // Only auto-switch if user hasn't set a preference
            if (!localStorage.getItem('iBridge-theme')) {
                this.isDarkMode = e.matches;
                this.setupThemeVariables();
                this.updateToggleControl();
            }
        });
    }

    saveUserPreference() {
        localStorage.setItem('iBridge-theme', this.isDarkMode ? 'dark' : 'light');
    }

    dispatchThemeChangeEvent() {
        const event = new CustomEvent('themeChanged', {
            detail: {
                theme: this.isDarkMode ? 'dark' : 'light',
                isDarkMode: this.isDarkMode
            }
        });
        document.dispatchEvent(event);
    }

    // Public API methods
    setTheme(theme) {
        if (theme === 'dark' || theme === 'light') {
            this.isDarkMode = theme === 'dark';
            this.setupThemeVariables();
            this.updateToggleControl();
            this.saveUserPreference();
            this.dispatchThemeChangeEvent();
        }
    }

    getCurrentTheme() {
        return this.isDarkMode ? 'dark' : 'light';
    }

    isDark() {
        return this.isDarkMode;
    }

    isLight() {
        return !this.isDarkMode;
    }

    // Method to update specific components that need special handling
    updateSecurityDashboard() {
        const dashboard = document.getElementById('advanced-security-dashboard');
        if (dashboard && this.isDarkMode) {
            dashboard.style.background = 'linear-gradient(135deg, #0f1419 0%, #1a2332 100%)';
            dashboard.style.borderColor = 'var(--accent-color)';
        }
    }

    // Method to update charts and visualizations
    updateCharts() {
        if (window.advancedSecurityDashboard && window.advancedSecurityDashboard.charts) {
            Object.values(window.advancedSecurityDashboard.charts).forEach(chart => {
                if (chart && chart.options) {
                    const textColor = this.isDarkMode ? '#ffffff' : '#333333';
                    const gridColor = this.isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)';

                    chart.options.plugins.legend.labels.color = textColor;
                    chart.options.scales.x.ticks.color = textColor;
                    chart.options.scales.y.ticks.color = textColor;
                    chart.options.scales.x.grid.color = gridColor;
                    chart.options.scales.y.grid.color = gridColor;

                    chart.update();
                }
            });
        }
    }
}

// Initialize Dark Mode Controller
document.addEventListener('DOMContentLoaded', () => {
    window.darkModeController = new DarkModeController();

    // Listen for theme changes to update charts
    document.addEventListener('themeChanged', (e) => {
        if (window.darkModeController) {
            window.darkModeController.updateSecurityDashboard();
            window.darkModeController.updateCharts();
        }
    });

    console.log('%c🌙 Dark Mode Controller v1.0 Loaded',
        'color: #00ff88; font-weight: bold; background: #000; padding: 5px 10px; border-radius: 5px;');
});