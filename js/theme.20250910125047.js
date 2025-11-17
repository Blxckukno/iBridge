// Theme Manager for iBridge Website
class ThemeManager {
    static THEME_KEY = 'ibridge-theme';
    static THEME_SOURCE_KEY = 'ibridge-theme-source';
    static DEFAULT_THEME = 'light';

    static init() {
        // Get theme source (user/system) and saved theme
        const themeSource = localStorage.getItem(this.THEME_SOURCE_KEY) || 'system';
        const savedTheme = localStorage.getItem(this.THEME_KEY);
        const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        
        // Determine initial theme
        let initialTheme;
        if (themeSource === 'system') {
            initialTheme = systemPrefersDark ? 'dark' : 'light';
        } else {
            initialTheme = savedTheme || this.DEFAULT_THEME;
        }

        // Apply initial theme
        this.applyTheme(initialTheme, themeSource);

        // Set up theme toggle button
        const themeToggle = document.querySelector('.theme-toggle');
        if (themeToggle) {
            themeToggle.innerHTML = this.getToggleIcon(initialTheme);
            themeToggle.setAttribute('aria-label', `Switch to ${initialTheme === 'light' ? 'dark' : 'light'} mode`);
            
            themeToggle.addEventListener('click', () => this.toggleTheme());
        }

        // Listen for system theme changes
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
            if (this.getThemeSource() === 'system') {
                this.applyTheme(e.matches ? 'dark' : 'light', 'system');
            }
        });
    }

    static getToggleIcon(theme) {
        return theme === 'light' 
            ? '<i class="fas fa-moon" aria-hidden="true"></i>' 
            : '<i class="fas fa-sun" aria-hidden="true"></i>';
    }

    static getThemeSource() {
        return localStorage.getItem(this.THEME_SOURCE_KEY) || 'system';
    }

    static applyTheme(theme, source = 'user') {
        document.documentElement.setAttribute('data-theme', theme);
        
        // Update toggle button if it exists
        const themeToggle = document.querySelector('.theme-toggle');
        if (themeToggle) {
            themeToggle.innerHTML = this.getToggleIcon(theme);
            themeToggle.setAttribute('aria-label', `Switch to ${theme === 'light' ? 'dark' : 'light'} mode`);
        }

        // Store theme preference
        localStorage.setItem(this.THEME_KEY, theme);
        localStorage.setItem(this.THEME_SOURCE_KEY, source);

        // Dispatch event for other components that might need to react to theme changes
        window.dispatchEvent(new CustomEvent('themechange', { detail: { theme } }));
    }

    static toggleTheme() {
        const currentTheme = document.documentElement.getAttribute('data-theme');
        const newTheme = currentTheme === 'light' ? 'dark' : 'light';
        this.applyTheme(newTheme);
    }

    static getCurrentTheme() {
        return document.documentElement.getAttribute('data-theme') || this.DEFAULT_THEME;
    }
}

// Initialize theme manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => ThemeManager.init());
