
# Advanced SQL Security System - Auto-generated Security Patch

# Advanced RCE Protection - Security Enhancement
import builtins
import subprocess
import os
import sys
from functools import wraps

class AdvancedRCEProtection:
    """Advanced Remote Code Execution protection system"""
    
    @staticmethod
    def initialize():
        """Initialize RCE protection"""
        
        # Block dangerous built-in functions
        def blocked_eval(*args, **kwargs):
            raise SecurityError("eval() function is permanently disabled")
        
        def blocked_exec(*args, **kwargs):
            raise SecurityError("exec() function is permanently disabled")
        
        def blocked_compile(*args, **kwargs):
            raise SecurityError("compile() function is permanently disabled")
        
        # Override built-ins
        builtins.eval = blocked_eval
        builtins.exec = blocked_exec
        builtins.compile = blocked_compile
        
        # Secure subprocess
        original_call = subprocess.call
        original_run = subprocess.run
        original_popen = subprocess.Popen
        
        def secure_call(*args, **kwargs):
            if kwargs.get('shell', False):
                raise SecurityError("Shell execution not permitted")
            if len(args) > 0 and isinstance(args[0], str):
                raise SecurityError("String commands not permitted")
            return original_call(*args, **kwargs)
        
        def secure_run(*args, **kwargs):
            if kwargs.get('shell', False):
                raise SecurityError("Shell execution not permitted")
            if len(args) > 0 and isinstance(args[0], str):
                raise SecurityError("String commands not permitted")
            return original_run(*args, **kwargs)
        
        def secure_popen(*args, **kwargs):
            if kwargs.get('shell', False):
                raise SecurityError("Shell execution not permitted")
            if len(args) > 0 and isinstance(args[0], str):
                raise SecurityError("String commands not permitted")
            return original_popen(*args, **kwargs)
        
        subprocess.call = secure_call
        subprocess.run = secure_run
        subprocess.Popen = secure_popen
        
        # Block os.system
        original_system = os.system
        def blocked_system(*args, **kwargs):
            raise SecurityError("os.system() is permanently disabled")
        os.system = blocked_system
        
        print("🔒 Advanced RCE Protection initialized")

class SecurityError(Exception):
    """Security violation exception"""
    pass

# Initialize RCE protection immediately
AdvancedRCEProtection.initialize()


import sqlite3
import re
import hashlib
import secrets
from typing import List, Dict, Any, Optional
import logging

class SQLSecurityManager:
    """Advanced SQL injection prevention system"""
    
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.logger = logging.getLogger('sql_security')
        self.blocked_patterns = [
            r"('|(\x27)|(\x2D)|(\x2D)|(\x23)|(\x3B))",  # Basic injection characters
            r"(\x3D)|(\x27)|(\x22)|(\x5C)|(\x3B)",      # Hex encoded
            r"(union|select|insert|delete|update|create|drop|exec|execute)",  # SQL keywords
            r"(script|javascript|vbscript|onload|onerror)",    # XSS attempts
            r"(\x3C|\x3E|\x22|\x27)",                     # HTML/JS injection
            r"(\d+\s*=\s*\d+)",                           # Always true conditions
            r"(or\s+\d+\s*=\s*\d+)",                     # OR injection
            r"(and\s+\d+\s*=\s*\d+)",                    # AND injection
        ]
    
    def validate_input(self, user_input: str) -> str:
        """Comprehensive input validation and sanitization"""
        if not isinstance(user_input, str):
            return str(user_input)
        
        # Length limit
        if len(user_input) > 1000:
            raise ValueError("Input too long")
        
        # Check for malicious patterns
        input_lower = user_input.lower()
        for pattern in self.blocked_patterns:
            if re.search(pattern, input_lower, re.IGNORECASE):
                self.logger.warning(f"Blocked malicious input: {pattern}")
                raise ValueError("Malicious input detected")
        
        # Basic sanitization
        sanitized = user_input.replace("'", "''")  # Escape single quotes
        sanitized = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', sanitized)  # Remove control chars
        
        return sanitized[:255]  # Truncate to safe length
    
    def execute_query(self, query: str, params: Optional[List] = None) -> List[Dict]:
        """Execute parameterized queries safely"""
        # Validate query structure
        if not self.is_safe_query(query):
            raise ValueError("Unsafe query structure")
        
        # Validate parameters
        if params:
            validated_params = [self.validate_input(str(p)) for p in params]
        else:
            validated_params = []
        
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row  # Return dict-like rows
            cursor = conn.cursor()
            
            if validated_params:
                cursor.execute(query, validated_params)
            else:
                cursor.execute(query)
            
            if query.strip().lower().startswith('select'):
                results = [dict(row) for row in cursor.fetchall()]
            else:
                conn.commit()
                results = [{"affected_rows": cursor.rowcount}]
            
            conn.close()
            return results
            
        except sqlite3.Error as e:
            self.logger.error(f"Database error: {e}")
            raise ValueError("Database operation failed")
    
    def is_safe_query(self, query: str) -> bool:
        """Validate query structure for safety"""
        query_lower = query.lower().strip()
        
        # Must be parameterized (contain ? placeholders)
        if "?" not in query and any(word in query_lower for word in ['where', 'set', 'values']):
            self.logger.warning("Non-parameterized query detected")
            return False
        
        # No string concatenation patterns
        if re.search(r'\+|%s|\{.*\}|f["'].*\{.*\}', query):
            self.logger.warning("String concatenation in query")
            return False
        
        # Check for dangerous SQL keywords in unexpected places
        dangerous_in_data = ['drop', 'create', 'alter', 'exec', 'execute', 'sp_', 'xp_']
        for danger in dangerous_in_data:
            if danger in query_lower and not query_lower.startswith(danger):
                self.logger.warning(f"Dangerous keyword in query: {danger}")
                return False
        
        return True
    
    def create_secure_connection(self):
        """Create a secure database connection with safety settings"""
        conn = sqlite3.connect(self.db_path)
        
        # Enable foreign key constraints
        conn.execute("PRAGMA foreign_keys = ON")
        
        # Set secure defaults
        conn.execute("PRAGMA secure_delete = ON")
        conn.execute("PRAGMA auto_vacuum = INCREMENTAL")
        
        return conn

# Global SQL security instance
sql_security = None

def init_sql_security(db_path: str):
    """Initialize SQL security system"""
    global sql_security
    sql_security = SQLSecurityManager(db_path)
    print("🔒 SQL Security System initialized")

def secure_query(query: str, params: Optional[List] = None) -> List[Dict]:
    """Secure query execution wrapper"""
    if sql_security is None:
        raise RuntimeError("SQL security not initialized")
    return sql_security.execute_query(query, params)



# Secure Execution Framework - Auto-generated Security Patch
import subprocess
import shlex
import os
import sys
from pathlib import Path
import logging

# Configure security logging
security_logger = logging.getLogger('security')
security_logger.setLevel(logging.WARNING)
handler = logging.FileHandler('security.log')
handler.setFormatter(logging.Formatter('%(asctime)s - SECURITY - %(message)s'))
security_logger.addHandler(handler)

class SecureExecutionFramework:
    """Secure command execution with comprehensive validation"""
    
    ALLOWED_COMMANDS = {
        'git': ['status', 'add', 'commit', 'push', 'pull', 'clone'],
        'python': ['-m', '-c'],
        'pip': ['install', 'list', 'show', 'freeze'],
        'node': ['--version'],
        'npm': ['install', 'list', 'audit']
    }
    
    @staticmethod
    def validate_command(command, args=None):
        """Validate command against whitelist"""
        if command not in SecureExecutionFramework.ALLOWED_COMMANDS:
            security_logger.warning(f"Blocked unauthorized command: {command}")
            return False
        
        if args:
            allowed_args = SecureExecutionFramework.ALLOWED_COMMANDS[command]
            for arg in args:
                if not any(arg.startswith(allowed) for allowed in allowed_args):
                    security_logger.warning(f"Blocked unauthorized argument: {arg}")
                    return False
        
        return True
    
    @staticmethod
    def secure_execute(command, args=None, cwd=None):
        """Execute command securely"""
        if not SecureExecutionFramework.validate_command(command, args):
            raise SecurityError(f"Command not allowed: {command}")
        
        # Sanitize arguments
        if args:
            safe_args = [shlex.quote(str(arg)) for arg in args if arg]
            cmd_list = [command] + safe_args
        else:
            cmd_list = [command]
        
        try:
            result = subprocess.run(
                cmd_list,
                cwd=cwd,
                capture_output=True,
                text=True,
                timeout=30,
                check=False,
                shell=False  # Never use shell=True
            )
            
            if result.returncode != 0:
                security_logger.warning(f"Command failed: {command} - {result.stderr}")
            
            return result
            
        except subprocess.TimeoutExpired:
            security_logger.error(f"Command timeout: {command}")
            raise SecurityError("Command execution timeout")
        except Exception as e:
            security_logger.error(f"Command execution error: {e}")
            raise SecurityError(f"Execution failed: {e}")

class SecurityError(Exception):
    """Custom security exception"""
    pass

# Disable dangerous functions
def blocked_eval(*args, **kwargs):
    security_logger.error("Attempt to use eval() - BLOCKED")
    raise SecurityError("eval() function is disabled for security")

def blocked_exec(*args, **kwargs):
    security_logger.error("Attempt to use exec() - BLOCKED")
    raise SecurityError("exec() function is disabled for security")

def blocked_compile(*args, **kwargs):
    security_logger.error("Attempt to use compile() - BLOCKED")
    raise SecurityError("compile() function is disabled for security")

# Override dangerous built-ins
import builtins
builtins.eval = blocked_eval
builtins.exec = blocked_exec
builtins.compile = blocked_compile

# Secure subprocess wrapper
original_call = subprocess.call
original_run = subprocess.run
original_popen = subprocess.Popen

def secure_call(*args, **kwargs):
    if kwargs.get('shell', False):
        security_logger.error("Blocked subprocess.call with shell=True")
        raise SecurityError("shell=True not permitted")
    return original_call(*args, **kwargs)

def secure_run(*args, **kwargs):
    if kwargs.get('shell', False):
        security_logger.error("Blocked subprocess.run with shell=True")
        raise SecurityError("shell=True not permitted")
    return original_run(*args, **kwargs)

def secure_popen(*args, **kwargs):
    if kwargs.get('shell', False):
        security_logger.error("Blocked subprocess.Popen with shell=True")
        raise SecurityError("shell=True not permitted")
    return original_popen(*args, **kwargs)

subprocess.call = secure_call
subprocess.run = secure_run
subprocess.Popen = secure_popen

print("🔒 Secure Execution Framework loaded")


"""
Advanced UI System
Enhanced dashboard with real-time monitoring, advanced controls, and system tray integration
"""

from .real_time_dashboard import RealTimeDashboard
from .system_tray import SystemTrayManager
from .control_panel import AdvancedControlPanel
from .notification_manager import NotificationManager, NotificationType, NotificationPriority
from .theme_manager import ThemeManager, ThemeType

import tkinter as tk
from tkinter import ttk, messagebox
import threading
import logging
import os
import sys
from typing import Dict, List, Any, Optional
from datetime import datetime

class IntegratedUI:
    """
    Integrated UI Manager
    Combines all advanced UI components into a cohesive interface
    """
    
    def __init__(self, antivirus_manager=None):
        self.antivirus_manager = antivirus_manager
        self.running = False
        
        # Initialize logging
        self.logger = logging.getLogger(__name__)
        
        # Main window
        self.main_window: Optional[tk.Tk] = None
        self.window_state = {
            'minimized': False,
            'maximized': False,
            'always_on_top': False,
            'transparency': 1.0
        }
        
        # UI Components
        self.dashboard = None
        self.system_tray = None
        self.control_panel = None
        self.notification_manager = None
        self.theme_manager = None
        
        # UI Settings
        self.ui_settings = {
            'show_dashboard_on_startup': True,
            'minimize_to_tray': True,
            'close_to_tray': True,
            'startup_theme': ThemeType.LIGHT,
            'dashboard_auto_refresh': True,
            'refresh_interval': 5,  # seconds
            'show_notifications': True,
            'enable_system_tray': True,
            'window_position': None,
            'window_size': (1200, 800)
        }
        
        # Menu system
        self.menu_bar = None
        self.context_menus = {}
        
        # Status tracking
        self.ui_status = {
            'dashboard_visible': False,
            'control_panel_visible': False,
            'system_tray_active': False,
            'notifications_enabled': True,
            'theme_applied': False
        }
        
        self.logger.info("Integrated UI initialized")
    
    def initialize(self):
        """Initialize all UI components"""
        try:
            # Create main window
            self._create_main_window()
            
            # Initialize theme manager first (affects all other components)
            self._initialize_theme_manager()
            
            # Initialize notification manager
            self._initialize_notification_manager()
            
            # Initialize dashboard
            self._initialize_dashboard()
            
            # Initialize system tray (if enabled)
            if self.ui_settings['enable_system_tray']:
                self._initialize_system_tray()
            
            # Initialize control panel
            self._initialize_control_panel()
            
            # Setup menu system
            self._setup_menu_system()
            
            # Setup event handlers
            self._setup_event_handlers()
            
            # Apply initial theme
            self._apply_initial_theme()
            
            # Show welcome notification
            if self.notification_manager:
                self.notification_manager.success(
                    "UI Ready",
                    "Advanced UI system initialized successfully"
                )
            
            self.logger.info("Integrated UI components initialized successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Error initializing UI components: {e}")
            return False
    
    def _create_main_window(self):
        """Create the main application window"""
        try:
            self.main_window = tk.Tk()
            self.main_window.title("Advanced Antivirus - Security Dashboard")
            
            # Set window size and position
            width, height = self.ui_settings['window_size']
            self.main_window.geometry(f"{width}x{height}")
            
            if self.ui_settings['window_position']:
                x, y = self.ui_settings['window_position']
                self.main_window.geometry(f"{width}x{height}+{x}+{y}")
            else:
                # Center window
                self._center_window(self.main_window, width, height)
            
            # Set minimum size
            self.main_window.minsize(800, 600)
            
            # Configure window behavior
            self.main_window.protocol("WM_DELETE_WINDOW", self._on_window_close)
            
            self.logger.info("Main window created")
            
        except Exception as e:
            self.logger.error(f"Error creating main window: {e}")
            raise
    
    def _initialize_theme_manager(self):
        """Initialize the theme manager"""
        try:
            self.theme_manager = ThemeManager(self.main_window)
            self.logger.info("Theme manager initialized")
            
        except Exception as e:
            self.logger.error(f"Error initializing theme manager: {e}")
            self.theme_manager = None
    
    def _initialize_notification_manager(self):
        """Initialize the notification manager"""
        try:
            self.notification_manager = NotificationManager(self.antivirus_manager)
            
            if self.ui_settings['show_notifications']:
                self.notification_manager.start()
                self.ui_status['notifications_enabled'] = True
            
            self.logger.info("Notification manager initialized")
            
        except Exception as e:
            self.logger.error(f"Error initializing notification manager: {e}")
            self.notification_manager = None
    
    def _initialize_dashboard(self):
        """Initialize the real-time dashboard"""
        try:
            # Create dashboard frame in main window
            dashboard_frame = ttk.Frame(self.main_window)
            dashboard_frame.pack(fill=tk.BOTH, expand=True)
            
            # Initialize dashboard with correct parameters
            self.dashboard = RealTimeDashboard(security_manager=self.antivirus_manager)
            
            # Initialize the dashboard UI with the parent frame
            self.dashboard.initialize(dashboard_frame)
            
            if self.ui_settings['show_dashboard_on_startup']:
                self.ui_status['dashboard_visible'] = True
            
            self.logger.info("Dashboard initialized")
            
        except Exception as e:
            self.logger.error(f"Error initializing dashboard: {e}")
            self.dashboard = None
    
    def _initialize_system_tray(self):
        """Initialize the system tray manager"""
        try:
            self.system_tray = SystemTrayManager(self.antivirus_manager)
            
            if self.system_tray.start():
                self.ui_status['system_tray_active'] = True
                self.logger.info("System tray initialized")
            else:
                self.logger.warning("System tray initialization failed")
                self.system_tray = None
            
        except Exception as e:
            self.logger.error(f"Error initializing system tray: {e}")
            self.system_tray = None
    
    def _initialize_control_panel(self):
        """Initialize the advanced control panel"""
        try:
            self.control_panel = AdvancedControlPanel(self.antivirus_manager)
            self.logger.info("Control panel initialized")
            
        except Exception as e:
            self.logger.error(f"Error initializing control panel: {e}")
            self.control_panel = None
    
    def _setup_menu_system(self):
        """Setup the main menu system"""
        try:
            if not self.main_window:
                self.logger.error("Cannot setup menu system: main window not initialized")
                return
                
            self.menu_bar = tk.Menu(self.main_window)
            self.main_window.config(menu=self.menu_bar)
            
            # File menu
            file_menu = tk.Menu(self.menu_bar, tearoff=0)
            self.menu_bar.add_cascade(label="File", menu=file_menu)
            file_menu.add_command(label="New Scan", command=self._start_new_scan)
            file_menu.add_command(label="Open Quarantine", command=self._open_quarantine)
            file_menu.add_separator()
            file_menu.add_command(label="Exit", command=self._exit_application)
            
            # View menu
            view_menu = tk.Menu(self.menu_bar, tearoff=0)
            self.menu_bar.add_cascade(label="View", menu=view_menu)
            view_menu.add_command(label="Dashboard", command=self._show_dashboard)
            view_menu.add_command(label="Control Panel", command=self._show_control_panel)
            
            # Tools menu
            tools_menu = tk.Menu(self.menu_bar, tearoff=0)
            self.menu_bar.add_cascade(label="Tools", menu=tools_menu)
            tools_menu.add_command(label="Quick Scan", command=self._start_quick_scan)
            tools_menu.add_command(label="Full Scan", command=self._start_full_scan)
            
            # Themes menu
            themes_menu = tk.Menu(self.menu_bar, tearoff=0)
            self.menu_bar.add_cascade(label="Themes", menu=themes_menu)
            themes_menu.add_command(label="Light Theme", command=lambda: self._apply_theme(ThemeType.LIGHT))
            themes_menu.add_command(label="Dark Theme", command=lambda: self._apply_theme(ThemeType.DARK))
            
            # Help menu
            help_menu = tk.Menu(self.menu_bar, tearoff=0)
            self.menu_bar.add_cascade(label="Help", menu=help_menu)
            help_menu.add_command(label="About", command=self._show_about)
            
            self.logger.info("Menu system setup complete")
            
        except Exception as e:
            self.logger.error(f"Error setting up menu system: {e}")
    
    def _setup_event_handlers(self):
        """Setup event handlers for the main window"""
        try:
            if not self.main_window:
                self.logger.error("Cannot setup event handlers: main window not initialized")
                return
                
            # Window state events
            self.main_window.bind('<Configure>', self._on_window_configure)
            
            # Keyboard shortcuts
            self.main_window.bind('<Control-n>', lambda e: self._start_new_scan())
            self.main_window.bind('<Control-q>', lambda e: self._exit_application())
            self.main_window.bind('<F5>', lambda e: self._refresh_dashboard())
            
            self.logger.info("Event handlers setup complete")
            
        except Exception as e:
            self.logger.error(f"Error setting up event handlers: {e}")
    
    def _apply_initial_theme(self):
        """Apply the initial theme"""
        try:
            if self.theme_manager:
                startup_theme = self.ui_settings['startup_theme']
                self.theme_manager.apply_theme(startup_theme)
                self.logger.info(f"Applied initial theme: {startup_theme}")
        except Exception as e:
            self.logger.error(f"Error applying initial theme: {e}")
    
    def start(self):
        """Start the integrated UI system"""
        try:
            if self.running:
                return True
            
            # Initialize components if not already done
            if not self.main_window:
                if not self.initialize():
                    return False
            
            self.running = True
            
            # Show main window if dashboard should be visible
            if self.main_window:
                if self.ui_settings['show_dashboard_on_startup']:
                    self.main_window.deiconify()
                else:
                    self.main_window.withdraw()
            
            self.logger.info("Integrated UI started")
            return True
            
        except Exception as e:
            self.logger.error(f"Error starting UI: {e}")
            return False
    
    def stop(self):
        """Stop the integrated UI system"""
        try:
            self.running = False
            
            # Stop components
            if self.notification_manager:
                self.notification_manager.stop()
            
            if self.system_tray:
                self.system_tray.stop()
            
            # Close windows
            if self.main_window:
                self.main_window.quit()
            
            self.logger.info("Integrated UI stopped")
            
        except Exception as e:
            self.logger.error(f"Error stopping UI: {e}")
    
    def show_main_window(self):
        """Show the main window"""
        try:
            if self.main_window:
                self.main_window.deiconify()
                self.main_window.lift()
                self.main_window.focus_force()
                self.ui_status['dashboard_visible'] = True
        except Exception as e:
            self.logger.error(f"Error showing main window: {e}")
    
    def hide_main_window(self):
        """Hide the main window"""
        try:
            if self.main_window:
                self.main_window.withdraw()
                self.ui_status['dashboard_visible'] = False
        except Exception as e:
            self.logger.error(f"Error hiding main window: {e}")
    
    def run(self):
        """Run the UI main loop"""
        try:
            if self.main_window:
                self.main_window.mainloop()
        except Exception as e:
            self.logger.error(f"Error in UI main loop: {e}")
    
    # Event handlers
    def _on_window_close(self):
        """Handle main window close event"""
        if self.ui_settings['close_to_tray'] and self.system_tray:
            self.hide_main_window()
            if self.notification_manager:
                self.notification_manager.info(
                    "Minimized to Tray",
                    "Application is still running in the system tray"
                )
        else:
            self._exit_application()
    
    def _on_window_configure(self, event):
        """Handle window configuration changes"""
        if event.widget == self.main_window and self.main_window:
            # Save window position and size
            geometry = self.main_window.geometry()
            # Parse geometry string (e.g., "800x600+100+50")
            size_pos = geometry.split('+')
            if len(size_pos) >= 3:
                size = size_pos[0]
                width, height = map(int, size.split('x'))
                x, y = int(size_pos[1]), int(size_pos[2])
                
                self.ui_settings['window_size'] = (width, height)
                self.ui_settings['window_position'] = (x, y)
    
    # Menu action handlers
    def _start_new_scan(self):
        """Start a new scan"""
        if self.control_panel:
            self.control_panel.show()
    
    def _open_quarantine(self):
        """Open quarantine viewer"""
        if self.notification_manager:
            self.notification_manager.info("Quarantine", "Opening quarantine viewer...")
    
    def _show_dashboard(self):
        """Show the dashboard"""
        self.show_main_window()
    
    def _show_control_panel(self):
        """Show the control panel"""
        if self.control_panel:
            self.control_panel.show()
            self.ui_status['control_panel_visible'] = True
    
    def _start_quick_scan(self):
        """Start quick scan"""
        if self.notification_manager:
            self.notification_manager.scan("Quick Scan", "Starting quick system scan...")
    
    def _start_full_scan(self):
        """Start full scan"""
        if self.notification_manager:
            self.notification_manager.scan("Full Scan", "Starting full system scan...")
    
    def _apply_theme(self, theme_type: ThemeType):
        """Apply theme"""
        if self.theme_manager:
            self.theme_manager.apply_theme(theme_type)
    
    def _refresh_dashboard(self):
        """Refresh dashboard data"""
        if self.dashboard:
            # Trigger dashboard refresh
            pass
    
    def _show_about(self):
        """Show about dialog"""
        about_text = """Advanced Antivirus System
Version 1.0.0

A comprehensive cybersecurity solution with:
• Real-time threat protection
• Advanced scanning engine
• Network security monitoring
• VPN integration
• Browser protection
• Centralized security management

Built with advanced UI components for optimal user experience."""
        
        messagebox.showinfo("About Advanced Antivirus", about_text)
    
    def _exit_application(self):
        """Exit the application"""
        result = messagebox.askyesno("Exit", "Are you sure you want to exit?")
        if result:
            self.stop()
            sys.exit(0)
    
    def _center_window(self, window, width, height):
        """Center window on screen"""
        screen_width = window.winfo_screenwidth()
        screen_height = window.winfo_screenheight()
        
        x = (screen_width - width) // 2
        y = (screen_height - height) // 2
        
        window.geometry(f"{width}x{height}+{x}+{y}")
    
    def get_ui_status(self) -> Dict:
        """Get current UI status"""
        return {
            'running': self.running,
            'components': self.ui_status.copy(),
            'window_state': self.window_state.copy(),
            'settings': self.ui_settings.copy()
        }

__all__ = [
    'RealTimeDashboard',
    'SystemTrayManager', 
    'AdvancedControlPanel',
    'NotificationManager',
    'NotificationType',
    'NotificationPriority',
    'ThemeManager',
    'ThemeType',
    'IntegratedUI'
]