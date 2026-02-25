/**
 * iBridge Authentication System - Frontend Integration
 * Handles user authentication, session management, and API calls
 */

class iBridgeAuth {
    constructor() {
        this.apiBase = 'http://127.0.0.1:5000/api';
        this.token = localStorage.getItem('ibridge_token');
        this.user = this.getStoredUser();

        // Initialize authentication state
        this.checkAuthState();
    }

    // Authentication Methods
    async login(username, password) {
        try {
            const response = await fetch(`${this.apiBase}/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ username, password })
            });

            const data = await response.json();

            if (response.ok) {
                this.token = data.access_token;
                this.user = data.user;

                localStorage.setItem('ibridge_token', this.token);
                localStorage.setItem('ibridge_user', JSON.stringify(this.user));

                this.showNotification('Login successful!', 'success');
                this.updateUI();

                return { success: true, user: this.user };
            } else {
                this.showNotification(data.error || 'Login failed', 'error');
                return { success: false, error: data.error };
            }
        } catch (error) {
            console.error('Login error:', error);
            this.showNotification('Connection error. Please try again.', 'error');
            return { success: false, error: 'Network error' };
        }
    }

    async register(userData) {
        try {
            const response = await fetch(`${this.apiBase}/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(userData)
            });

            const data = await response.json();

            if (response.ok) {
                this.token = data.access_token;
                this.user = data.user;

                localStorage.setItem('ibridge_token', this.token);
                localStorage.setItem('ibridge_user', JSON.stringify(this.user));

                this.showNotification('Registration successful!', 'success');
                this.updateUI();

                return { success: true, user: this.user };
            } else {
                this.showNotification(data.error || 'Registration failed', 'error');
                return { success: false, error: data.error };
            }
        } catch (error) {
            console.error('Registration error:', error);
            this.showNotification('Connection error. Please try again.', 'error');
            return { success: false, error: 'Network error' };
        }
    }

    async logout() {
        try {
            if (this.token) {
                await fetch(`${this.apiBase}/logout`, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${this.token}`,
                    }
                });
            }
        } catch (error) {
            console.error('Logout error:', error);
        } finally {
            this.token = null;
            this.user = null;
            localStorage.removeItem('ibridge_token');
            localStorage.removeItem('ibridge_user');

            this.showNotification('Logged out successfully', 'info');
            this.updateUI();

            // Redirect to home page
            window.location.href = '/index.html';
        }
    }

    // API Request Helper
    async apiRequest(endpoint, options = {}) {
        const headers = {
            'Content-Type': 'application/json',
            ...options.headers
        };

        if (this.token) {
            headers['Authorization'] = `Bearer ${this.token}`;
        }

        try {
            const response = await fetch(`${this.apiBase}${endpoint}`, {
                ...options,
                headers
            });

            if (response.status === 401) {
                // Token expired or invalid
                this.logout();
                return null;
            }

            return response;
        } catch (error) {
            console.error('API request error:', error);
            throw error;
        }
    }

    // Ticket API Methods
    async getTickets() {
        try {
            const response = await this.apiRequest('/tickets');
            if (response && response.ok) {
                return await response.json();
            }
        } catch (error) {
            console.error('Get tickets error:', error);
        }
        return [];
    }

    async createTicket(ticketData) {
        try {
            const response = await this.apiRequest('/tickets', {
                method: 'POST',
                body: JSON.stringify(ticketData)
            });

            if (response && response.ok) {
                const ticket = await response.json();
                this.showNotification('Ticket created successfully!', 'success');
                return ticket;
            }
        } catch (error) {
            console.error('Create ticket error:', error);
            this.showNotification('Failed to create ticket', 'error');
        }
        return null;
    }

    async updateTicket(ticketId, updates) {
        try {
            const response = await this.apiRequest(`/tickets/${ticketId}`, {
                method: 'PUT',
                body: JSON.stringify(updates)
            });

            if (response && response.ok) {
                const ticket = await response.json();
                this.showNotification('Ticket updated successfully!', 'success');
                return ticket;
            }
        } catch (error) {
            console.error('Update ticket error:', error);
            this.showNotification('Failed to update ticket', 'error');
        }
        return null;
    }

    // Multi-channel intake (email/chatbot/webhook) -> ticket
    async createIntakeTicket(intakeData, intakeKey = '') {
        try {
            const headers = {};
            if (intakeKey) headers['X-Intake-Key'] = intakeKey;
            const response = await this.apiRequest('/tickets/intake', {
                method: 'POST',
                headers,
                body: JSON.stringify(intakeData || {})
            });

            if (response && response.ok) {
                const payload = await response.json();
                this.showNotification(`Ticket created: ${payload.ticket_number || 'N/A'}`, 'success');
                return payload;
            }
            const err = response ? await response.json().catch(() => ({})) : {};
            throw new Error(err.error || 'Intake ticket creation failed');
        } catch (error) {
            console.error('createIntakeTicket error:', error);
            this.showNotification(error.message || 'Intake ticket creation failed', 'error');
            return null;
        }
    }

    // Course API Methods
    async getCourses() {
        try {
            const response = await this.apiRequest('/courses');
            if (response && response.ok) {
                return await response.json();
            }
        } catch (error) {
            console.error('Get courses error:', error);
        }
        return [];
    }

    async enrollCourse(courseId) {
        try {
            const response = await this.apiRequest(`/courses/${courseId}/enroll`, {
                method: 'POST'
            });

            if (response && response.ok) {
                this.showNotification('Enrolled in course successfully!', 'success');
                return true;
            } else {
                const data = await response.json();
                this.showNotification(data.error || 'Enrollment failed', 'error');
            }
        } catch (error) {
            console.error('Enroll course error:', error);
            this.showNotification('Failed to enroll in course', 'error');
        }
        return false;
    }

    async getLmsTrainingResources(track = '') {
        try {
            const qs = track ? `?track=${encodeURIComponent(track)}` : '';
            const response = await this.apiRequest(`/lms/training-resources${qs}`, { method: 'GET' });
            if (response && response.ok) return await response.json();
        } catch (error) {
            console.error('getLmsTrainingResources error:', error);
        }
        return { count: 0, resources: [] };
    }

    async startLmsTrainingResource(resourceId) {
        try {
            const response = await this.apiRequest(`/lms/training-resources/${encodeURIComponent(resourceId)}/start`, {
                method: 'POST',
                body: JSON.stringify({})
            });
            if (response && response.ok) return await response.json();
        } catch (error) {
            console.error('startLmsTrainingResource error:', error);
        }
        return null;
    }

    async completeLmsTrainingResource(resourceId, progressDelta = 12) {
        try {
            const response = await this.apiRequest(`/lms/training-resources/${encodeURIComponent(resourceId)}/complete`, {
                method: 'POST',
                body: JSON.stringify({ progress_delta: progressDelta })
            });
            if (response && response.ok) return await response.json();
        } catch (error) {
            console.error('completeLmsTrainingResource error:', error);
        }
        return null;
    }

    // Utility Methods
    isAuthenticated() {
        return !!this.token && !!this.user;
    }

    getUser() {
        return this.user;
    }

    hasRole(role) {
        return this.user && this.user.role === role;
    }

    isAdmin() {
        return this.hasRole('admin');
    }

    isEmployee() {
        return this.hasRole('employee');
    }

    getStoredUser() {
        const stored = localStorage.getItem('ibridge_user');
        return stored ? JSON.parse(stored) : null;
    }

    checkAuthState() {
        if (this.token && this.user) {
            this.updateUI();
        }
    }

    updateUI() {
        // Update login/logout buttons
        const loginButtons = document.querySelectorAll('.login-btn');
        const logoutButtons = document.querySelectorAll('.logout-btn');
        const userInfo = document.querySelectorAll('.user-info');

        if (this.isAuthenticated()) {
            loginButtons.forEach(btn => btn.style.display = 'none');
            logoutButtons.forEach(btn => btn.style.display = 'block');

            userInfo.forEach(info => {
                info.style.display = 'block';
                info.textContent = `Welcome, ${this.user.username}`;
            });

            // Show/hide admin features
            const adminElements = document.querySelectorAll('.admin-only');
            adminElements.forEach(el => {
                el.style.display = this.isAdmin() ? 'block' : 'none';
            });

        } else {
            loginButtons.forEach(btn => btn.style.display = 'block');
            logoutButtons.forEach(btn => btn.style.display = 'none');
            userInfo.forEach(info => info.style.display = 'none');
        }
    }

    // Login Modal Management
    showLoginModal() {
        const modal = this.createLoginModal();
        document.body.appendChild(modal);
        setTimeout(() => modal.classList.add('active'), 10);
    }

    createLoginModal() {
        const modal = document.createElement('div');
        modal.className = 'auth-modal-overlay';
        modal.innerHTML = `
            <div class="auth-modal">
                <div class="auth-modal-header">
                    <h3>iBridge Login</h3>
                    <button class="auth-modal-close">&times;</button>
                </div>
                <div class="auth-modal-body">
                    <form id="loginForm" class="auth-form">
                        <div class="form-group">
                            <label for="username">Username</label>
                            <input type="text" id="username" name="username" required>
                        </div>
                        <div class="form-group">
                            <label for="password">Password</label>
                            <input type="password" id="password" name="password" required>
                        </div>
                        <div class="form-actions">
                            <button type="submit" class="auth-btn primary">Login</button>
                            <button type="button" class="auth-btn secondary" onclick="iBridgeAuth.showRegisterModal()">Register</button>
                        </div>
                    </form>
                    <div class="test-credentials">
                        <h4>Test Accounts:</h4>
                        <div class="test-account" onclick="iBridgeAuth.quickLogin('admin', 'admin123')">
                            <strong>Admin:</strong> admin / admin123
                        </div>
                        <div class="test-account" onclick="iBridgeAuth.quickLogin('employee', 'employee123')">
                            <strong>Employee:</strong> employee / employee123
                        </div>
                        <div class="test-account" onclick="iBridgeAuth.quickLogin('customer', 'customer123')">
                            <strong>Customer:</strong> customer / customer123
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Add event listeners
        modal.querySelector('.auth-modal-close').onclick = () => this.closeModal(modal);
        modal.querySelector('#loginForm').onsubmit = (e) => this.handleLogin(e, modal);
        modal.onclick = (e) => {
            if (e.target === modal) this.closeModal(modal);
        };

        return modal;
    }

    async quickLogin(username, password) {
        const result = await this.login(username, password);
        if (result.success) {
            const modal = document.querySelector('.auth-modal-overlay');
            if (modal) this.closeModal(modal);
        }
    }

    async handleLogin(event, modal) {
        event.preventDefault();
        const formData = new FormData(event.target);
        const username = formData.get('username');
        const password = formData.get('password');

        const result = await this.login(username, password);
        if (result.success) {
            this.closeModal(modal);
        }
    }

    closeModal(modal) {
        modal.classList.remove('active');
        setTimeout(() => modal.remove(), 300);
    }

    // Notification System
    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `auth-notification ${type}`;
        notification.textContent = message;

        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 25px;
            background: ${type === 'success' ? '#10b981' : type === 'error' ? '#ef4444' : '#3b82f6'};
            color: white;
            border-radius: 8px;
            z-index: 10000;
            transform: translateX(400px);
            transition: transform 0.3s ease;
        `;

        document.body.appendChild(notification);
        setTimeout(() => notification.style.transform = 'translateX(0)', 100);
        setTimeout(() => {
            notification.style.transform = 'translateX(400px)';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }
}

// CSS Styles for Authentication Components
const authStyles = `
    .auth-modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.5);
        backdrop-filter: blur(5px);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 10000;
        opacity: 0;
        visibility: hidden;
        transition: all 0.3s ease;
    }

    .auth-modal-overlay.active {
        opacity: 1;
        visibility: visible;
    }

    .auth-modal {
        background: white;
        border-radius: 12px;
        max-width: 400px;
        width: 90%;
        max-height: 80vh;
        overflow: hidden;
        box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
        transform: scale(0.9) translateY(20px);
        transition: all 0.3s ease;
    }

    .auth-modal-overlay.active .auth-modal {
        transform: scale(1) translateY(0);
    }

    .auth-modal-header {
        background: linear-gradient(135deg, #A1C44F, #B8D663);
        color: white;
        padding: 20px;
        position: relative;
    }

    .auth-modal-header h3 {
        margin: 0;
        font-size: 1.25rem;
        font-weight: 600;
    }

    .auth-modal-close {
        position: absolute;
        right: 20px;
        top: 50%;
        transform: translateY(-50%);
        background: none;
        border: none;
        color: white;
        font-size: 1.5rem;
        cursor: pointer;
        width: 30px;
        height: 30px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 50%;
        transition: background 0.2s;
    }

    .auth-modal-close:hover {
        background: rgba(255, 255, 255, 0.2);
    }

    .auth-modal-body {
        padding: 30px;
    }

    .auth-form .form-group {
        margin-bottom: 20px;
    }

    .auth-form label {
        display: block;
        margin-bottom: 5px;
        font-weight: 500;
        color: #374151;
    }

    .auth-form input {
        width: 100%;
        padding: 12px 16px;
        border: 2px solid #e5e7eb;
        border-radius: 8px;
        font-size: 1rem;
        transition: border-color 0.2s;
    }

    .auth-form input:focus {
        outline: none;
        border-color: #A1C44F;
        box-shadow: 0 0 0 3px rgba(161, 196, 79, 0.1);
    }

    .form-actions {
        display: flex;
        gap: 10px;
        margin-top: 30px;
    }

    .auth-btn {
        flex: 1;
        padding: 12px 20px;
        border: none;
        border-radius: 8px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s;
    }

    .auth-btn.primary {
        background: #A1C44F;
        color: white;
    }

    .auth-btn.primary:hover {
        background: #8FB347;
    }

    .auth-btn.secondary {
        background: #f3f4f6;
        color: #374151;
        border: 1px solid #d1d5db;
    }

    .auth-btn.secondary:hover {
        background: #e5e7eb;
    }

    .test-credentials {
        margin-top: 30px;
        padding-top: 20px;
        border-top: 1px solid #e5e7eb;
    }

    .test-credentials h4 {
        margin: 0 0 15px 0;
        font-size: 0.875rem;
        color: #6b7280;
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .test-account {
        padding: 10px;
        background: #f9fafb;
        border-radius: 6px;
        margin-bottom: 5px;
        cursor: pointer;
        font-size: 0.875rem;
        transition: background 0.2s;
    }

    .test-account:hover {
        background: #f3f4f6;
    }

    .user-info {
        display: none;
        color: #A1C44F;
        font-weight: 600;
    }

    .admin-only {
        display: none;
    }
`;

// Add styles to document
const styleSheet = document.createElement('style');
styleSheet.textContent = authStyles;
document.head.appendChild(styleSheet);

// Initialize global authentication instance
window.iBridgeAuth = new iBridgeAuth();

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function () {
    // Add login buttons to existing navigation
    const navigation = document.querySelector('nav, .nav, .header-nav');
    if (navigation && !document.querySelector('.auth-controls')) {
        const authControls = document.createElement('div');
        authControls.className = 'auth-controls';
        authControls.innerHTML = `
            <button class="login-btn" onclick="iBridgeAuth.showLoginModal()">Login</button>
            <span class="user-info"></span>
            <button class="logout-btn" onclick="iBridgeAuth.logout()" style="display: none;">Logout</button>
        `;
        navigation.appendChild(authControls);
    }

    // Initialize UI state
    iBridgeAuth.updateUI();
});
