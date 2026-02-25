
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
System Tray Manager
Provides system tray integration with notifications and quick access controls
"""

import tkinter as tk
from tkinter import ttk, messagebox
import threading
import time
import logging
from datetime import datetime
from typing import Dict, List, Any, Optional, Callable, TYPE_CHECKING
import os
import sys

if TYPE_CHECKING:
    from pystray import Icon

# Optional dependency handling
try:
    import pystray
    from pystray import Icon, Menu, MenuItem
    from PIL import Image, ImageDraw
    PYSTRAY_AVAILABLE = True
except ImportError:
    PYSTRAY_AVAILABLE = False
    print("Warning: pystray not available. System tray functionality will be limited.")

try:
    import plyer
    PLYER_AVAILABLE = True
except ImportError:
    PLYER_AVAILABLE = False
    print("Warning: plyer not available. Cross-platform notifications will be limited.")


class SystemTrayManager:
    """
    System Tray Manager for the antivirus application
    Provides system tray integration with notifications and quick access controls
    """
    
    def __init__(self, antivirus_manager=None):
        self.antivirus_manager = antivirus_manager
        self.icon = None  # Optional[Icon] when pystray is available
        self.running = False
        self.menu_items = []
        self.notification_queue = []
        
        # Initialize logging
        self.logger = logging.getLogger(__name__)
        
        # Status tracking
        self.protection_status = "active"
        self.last_scan_time = None
        self.threats_detected = 0
        
        # Notification settings
        self.notification_settings = {
            'enabled': True,
            'timeout': 5,
            'max_notifications': 10
        }
        
        # UI components
        self.protection_status_window = None
        self.quick_access_window = None
        
        self.logger.info("System Tray Manager initialized")
    
    def create_icon_image(self, status: str = "active"):
        """Create system tray icon image based on status"""
        if not PYSTRAY_AVAILABLE:
            return None
            
        try:
            # Import PIL components when needed
            from PIL import Image, ImageDraw
            
            # Create a simple icon
            width = height = 64
            image = Image.new('RGBA', (width, height), (0, 0, 0, 0))
            draw = ImageDraw.Draw(image)
            
            # Choose color based on status
            if status == "active":
                color = (0, 128, 0, 255)  # Green
            elif status == "warning":
                color = (255, 165, 0, 255)  # Orange
            elif status == "danger":
                color = (255, 0, 0, 255)  # Red
            else:
                color = (128, 128, 128, 255)  # Gray
            
            # Draw a shield shape
            padding = 8
            shield_points = [
                (width//2, padding),
                (width - padding, height//3),
                (width - padding, height - padding*2),
                (width//2, height - padding),
                (padding, height - padding*2),
                (padding, height//3)
            ]
            
            draw.polygon(shield_points, fill=color, outline=(255, 255, 255, 255))
            
            # Add a small checkmark or warning symbol
            if status == "active":
                # Draw checkmark
                check_points = [
                    (width//3, height//2),
                    (width//2 - 2, height//2 + 8),
                    (width*2//3, height//2 - 4)
                ]
                draw.line(check_points, fill=(255, 255, 255, 255), width=3)
            elif status in ["warning", "danger"]:
                # Draw exclamation mark
                draw.rectangle([width//2-2, height//3, width//2+2, height*2//3-4], fill=(255, 255, 255, 255))
                draw.rectangle([width//2-2, height*2//3, width//2+2, height*2//3+4], fill=(255, 255, 255, 255))
            
            return image
            
        except Exception as e:
            self.logger.error(f"Error creating icon image: {e}")
            return None
    
    def create_menu(self):
        """Create system tray context menu"""
        if not PYSTRAY_AVAILABLE:
            return None
            
        try:
            from pystray import Menu, MenuItem
            
            menu_items = [
                MenuItem("Show Dashboard", self.show_dashboard, default=True),
                MenuItem("---", None),  # Separator
                MenuItem("Start Quick Scan", self.start_quick_scan),
                MenuItem("Show Protection Status", self.show_protection_status),
                MenuItem("---", None),  # Separator
                MenuItem("Connect VPN", self.connect_vpn),
                MenuItem("Disconnect VPN", self.disconnect_vpn),
                MenuItem("Show VPN Status", self.show_vpn_status),
                MenuItem("---", None),  # Separator
                MenuItem("Show Quarantine", self.show_quarantine),
                MenuItem("Show Settings", self.show_settings),
                MenuItem("---", None),  # Separator
                MenuItem("Toggle Protection", self.toggle_protection),
                MenuItem("Update Virus Definitions", self.update_definitions),
                MenuItem("Show About Dialog", self.show_about),
                MenuItem("---", None),  # Separator
                MenuItem("Exit", self.exit_application),
                MenuItem("Show Quick Access", self.show_quick_access)
            ]
            
            return Menu(*menu_items)
            
        except Exception as e:
            self.logger.error(f"Error creating menu: {e}")
            return None
    
    def start(self):
        """Start the system tray manager"""
        if not PYSTRAY_AVAILABLE:
            self.logger.warning("Cannot start system tray - pystray not available")
            return False
            
        try:
            from pystray import Icon
            
            self.running = True
            
            # Create icon image and menu
            icon_image = self.create_icon_image(self.protection_status)
            menu = self.create_menu()
            
            if icon_image and menu:
                self.icon = Icon("Antivirus", icon_image, menu=menu)
                if self.icon:  # Type guard for None check
                    self.icon.title = "Antivirus Protection - Active"
                
                # Start notification processing thread
                notification_thread = threading.Thread(target=self._process_notifications, daemon=True)
                notification_thread.start()
                
                # Start status monitoring thread
                status_thread = threading.Thread(target=self._monitor_status, daemon=True)
                status_thread.start()
                
                # Run the icon (blocking call)
                if self.icon:  # Type guard for None check
                    self.icon.run()
                return True
            else:
                self.logger.error("Failed to create icon or menu")
                return False
                
        except Exception as e:
            self.logger.error(f"Error starting system tray: {e}")
            return False
    
    def stop(self):
        """Stop the system tray manager"""
        try:
            self.running = False
            if self.icon:
                self.icon.stop()
                self.icon = None
            self.logger.info("System tray manager stopped")
            
        except Exception as e:
            self.logger.error(f"Error stopping system tray: {e}")
    
    def update_status(self, status: str, title: Optional[str] = None):
        """Update system tray icon status"""
        try:
            self.protection_status = status
            
            if self.icon and PYSTRAY_AVAILABLE:
                # Update icon image
                new_image = self.create_icon_image(status)
                if new_image:
                    self.icon.icon = new_image
                
                # Update title
                if title:
                    self.icon.title = title
                elif status == "active":
                    self.icon.title = "Antivirus Protection - Active"
                elif status == "warning":
                    self.icon.title = "Antivirus Protection - Warning"
                elif status == "danger":
                    self.icon.title = "Antivirus Protection - Danger"
                else:
                    self.icon.title = "Antivirus Protection - Inactive"
                
        except Exception as e:
            self.logger.error(f"Error updating icon status: {e}")
    
    def _process_notifications(self):
        """Process notification queue"""
        while self.running:
            try:
                if self.notification_queue and self.notification_settings['enabled']:
                    notification_data = self.notification_queue.pop(0)
                    self._show_notification(**notification_data)
                
                time.sleep(1)
                
            except Exception as e:
                self.logger.error(f"Error processing notifications: {e}")
                time.sleep(5)
    
    def _show_notification(self, title: str, message: str, icon_type: str = "info", timeout: int = 5):
        """Show system notification"""
        try:
            if PLYER_AVAILABLE:
                # Import notification when needed to avoid conflicts
                try:
                    import plyer.notification
                    # Use plyer for cross-platform notifications
                    plyer.notification.notify(
                        title=title,
                        message=message,
                        timeout=timeout,
                        app_name="Antivirus"
                    )
                except (ImportError, AttributeError) as e:
                    # Fallback if import fails at runtime
                    self.logger.warning(f"Failed to use plyer notification: {e}")
                    self.logger.info(f"Notification: {title} - {message}")
            else:
                # Fallback to basic notification
                self.logger.info(f"Notification: {title} - {message}")
                
        except Exception as e:
            self.logger.error(f"Error showing notification: {e}")
    
    def add_notification(self, title: str, message: str, icon_type: str = "info", timeout: int = 5):
        """Add notification to queue"""
        if len(self.notification_queue) < self.notification_settings['max_notifications']:
            self.notification_queue.append({
                'title': title,
                'message': message,
                'icon_type': icon_type,
                'timeout': timeout
            })
    
    def _monitor_status(self):
        """Monitor system status and update icon"""
        while self.running:
            try:
                if self.antivirus_manager:
                    # Get overall protection status
                    status = self.antivirus_manager.get_protection_status()
                    self.update_status(status.get('overall_status', 'inactive'))
                
                time.sleep(5)  # Check every 5 seconds
                
            except Exception as e:
                self.logger.error(f"Error monitoring status: {e}")
                time.sleep(10)
    
    # Menu action handlers
    def show_dashboard(self, icon=None, item=None):
        """Show main dashboard"""
        try:
            if self.antivirus_manager and hasattr(self.antivirus_manager, 'ui_manager'):
                self.antivirus_manager.ui_manager.show_dashboard()
            else:
                self.logger.warning("Dashboard not available")
                
        except Exception as e:
            self.logger.error(f"Error showing dashboard: {e}")
    
    def start_quick_scan(self, icon=None, item=None):
        """Start a quick system scan"""
        try:
            if self.antivirus_manager:
                # Start quick scan in background
                scan_thread = threading.Thread(
                    target=self.antivirus_manager.start_quick_scan,
                    daemon=True
                )
                scan_thread.start()
                
                self.add_notification(
                    "Quick Scan Started",
                    "System scan is now running in the background",
                    "info"
                )
            else:
                self.logger.warning("Antivirus manager not available")
                
        except Exception as e:
            self.logger.error(f"Error starting quick scan: {e}")
    
    def show_protection_status(self, icon=None, item=None):
        """Show protection status window"""
        try:
            if self.protection_status_window and self.protection_status_window.winfo_exists():
                self.protection_status_window.lift()
                return
            
            # Create status window
            self.protection_status_window = tk.Toplevel()
            self.protection_status_window.title("Protection Status")
            self.protection_status_window.geometry("400x300")
            self.protection_status_window.resizable(False, False)
            
            # Make window stay on top
            self.protection_status_window.attributes('-topmost', True)
            
            # Create status display
            main_frame = ttk.Frame(self.protection_status_window, padding="10")
            main_frame.grid(row=0, column=0, sticky="nsew")
            
            # Protection status
            status_label = ttk.Label(main_frame, text="Protection Status:", font=("Arial", 12, "bold"))
            status_label.grid(row=0, column=0, sticky=tk.W, pady=(0, 5))
            
            status_color = "green" if self.protection_status == "active" else "red"
            status_text = self.protection_status.title()
            status_value = ttk.Label(main_frame, text=status_text, foreground=status_color)
            status_value.grid(row=0, column=1, sticky=tk.W, pady=(0, 5))
            
            # Last scan
            scan_label = ttk.Label(main_frame, text="Last Scan:", font=("Arial", 10))
            scan_label.grid(row=1, column=0, sticky=tk.W, pady=2)
            
            scan_time = self.last_scan_time.strftime("%Y-%m-%d %H:%M:%S") if self.last_scan_time else "Never"
            scan_value = ttk.Label(main_frame, text=scan_time)
            scan_value.grid(row=1, column=1, sticky=tk.W, pady=2)
            
            # Threats detected
            threats_label = ttk.Label(main_frame, text="Threats Detected:", font=("Arial", 10))
            threats_label.grid(row=2, column=0, sticky=tk.W, pady=2)
            
            threats_value = ttk.Label(main_frame, text=str(self.threats_detected))
            threats_value.grid(row=2, column=1, sticky=tk.W, pady=2)
            
            # Buttons
            button_frame = ttk.Frame(main_frame)
            button_frame.grid(row=3, column=0, columnspan=2, pady=(20, 0))
            
            scan_btn = ttk.Button(button_frame, text="Start Scan", command=self.start_quick_scan)
            scan_btn.grid(row=0, column=0, padx=(0, 10))
            
            close_btn = ttk.Button(button_frame, text="Close", 
                                 command=self.protection_status_window.destroy)
            close_btn.grid(row=0, column=1)
            
        except Exception as e:
            self.logger.error(f"Error showing protection status: {e}")
    
    def connect_vpn(self, icon=None, item=None):
        """Connect VPN"""
        try:
            if self.antivirus_manager and hasattr(self.antivirus_manager, 'vpn_manager'):
                self.antivirus_manager.vpn_manager.connect()
                self.add_notification("VPN", "Connecting to VPN...", "info")
            else:
                self.logger.warning("VPN manager not available")
                
        except Exception as e:
            self.logger.error(f"Error connecting VPN: {e}")
    
    def disconnect_vpn(self, icon=None, item=None):
        """Disconnect VPN"""
        try:
            if self.antivirus_manager and hasattr(self.antivirus_manager, 'vpn_manager'):
                self.antivirus_manager.vpn_manager.disconnect()
                self.add_notification("VPN", "Disconnecting from VPN...", "info")
            else:
                self.logger.warning("VPN manager not available")
                
        except Exception as e:
            self.logger.error(f"Error disconnecting VPN: {e}")
    
    def show_vpn_status(self, icon=None, item=None):
        """Show VPN status"""
        try:
            if self.antivirus_manager and hasattr(self.antivirus_manager, 'vpn_manager'):
                status = self.antivirus_manager.vpn_manager.get_status()
                self.add_notification("VPN Status", f"Status: {status}", "info")
            else:
                self.logger.warning("VPN manager not available")
                
        except Exception as e:
            self.logger.error(f"Error showing VPN status: {e}")
    
    def show_quarantine(self, icon=None, item=None):
        """Show quarantine window"""
        try:
            if self.antivirus_manager and hasattr(self.antivirus_manager, 'quarantine_manager'):
                self.antivirus_manager.quarantine_manager.show_quarantine_window()
            else:
                self.logger.warning("Quarantine manager not available")
                
        except Exception as e:
            self.logger.error(f"Error showing quarantine: {e}")
    
    def show_settings(self, icon=None, item=None):
        """Show settings window"""
        try:
            if self.antivirus_manager and hasattr(self.antivirus_manager, 'ui_manager'):
                self.antivirus_manager.ui_manager.show_settings()
            else:
                self.logger.warning("Settings not available")
                
        except Exception as e:
            self.logger.error(f"Error showing settings: {e}")
    
    def toggle_protection(self, icon=None, item=None):
        """Toggle protection on/off"""
        try:
            if self.antivirus_manager:
                if self.protection_status == "active":
                    self.antivirus_manager.stop_protection()
                    self.update_status("inactive", "Antivirus Protection - Disabled")
                    self.add_notification("Protection", "Real-time protection disabled", "warning")
                else:
                    self.antivirus_manager.start_protection()
                    self.update_status("active", "Antivirus Protection - Active")
                    self.add_notification("Protection", "Real-time protection enabled", "info")
            else:
                self.logger.warning("Antivirus manager not available")
                
        except Exception as e:
            self.logger.error(f"Error toggling protection: {e}")
    
    def update_definitions(self, icon=None, item=None):
        """Update virus definitions"""
        try:
            if self.antivirus_manager:
                update_thread = threading.Thread(
                    target=self.antivirus_manager.update_virus_definitions,
                    daemon=True
                )
                update_thread.start()
                self.add_notification("Updates", "Checking for virus definition updates...", "info")
            else:
                self.logger.warning("Antivirus manager not available")
                
        except Exception as e:
            self.logger.error(f"Error updating definitions: {e}")
    
    def show_about(self, icon=None, item=None):
        """Show about dialog"""
        try:
            about_text = """
iBridge Antivirus System
Version 1.0.0

Advanced antivirus protection with:
• Real-time scanning
• VPN protection
• Secure data vault
• Browser protection
• System tray integration

© 2024 iBridge Security
            """
            
            messagebox.showinfo("About iBridge Antivirus", about_text.strip())
            
        except Exception as e:
            self.logger.error(f"Error showing about dialog: {e}")
    
    def exit_application(self, icon=None, item=None):
        """Exit the application"""
        try:
            if messagebox.askyesno("Exit", "Are you sure you want to exit the antivirus?"):
                self.stop()
                if self.antivirus_manager:
                    self.antivirus_manager.shutdown()
                sys.exit(0)
                
        except Exception as e:
            self.logger.error(f"Error exiting application: {e}")
    
    def show_quick_access(self, icon=None, item=None):
        """Show quick access window"""
        try:
            if self.quick_access_window and self.quick_access_window.winfo_exists():
                self.quick_access_window.lift()
                return
            
            # Create quick access window
            self.quick_access_window = tk.Toplevel()
            self.quick_access_window.title("Quick Access")
            self.quick_access_window.geometry("250x300")
            self.quick_access_window.resizable(False, False)
            self.quick_access_window.attributes('-topmost', True)
            
            main_frame = ttk.Frame(self.quick_access_window, padding="10")
            main_frame.grid(row=0, column=0, sticky="nsew")
            
            # Quick action buttons
            buttons = [
                ("Quick Scan", self.start_quick_scan),
                ("Show Dashboard", self.show_dashboard),
                ("Protection Status", self.show_protection_status),
                ("Connect VPN", self.connect_vpn),
                ("Disconnect VPN", self.disconnect_vpn),
                ("Show Quarantine", self.show_quarantine),
                ("Show Settings", self.show_settings),
                ("Update Definitions", self.update_definitions)
            ]
            
            for i, (text, command) in enumerate(buttons):
                btn = ttk.Button(main_frame, text=text, command=command, width=20)
                btn.grid(row=i, column=0, pady=2, sticky="ew")
            
            # Close button
            close_btn = ttk.Button(main_frame, text="Close", 
                                 command=self.quick_access_window.destroy, width=20)
            close_btn.grid(row=len(buttons), column=0, pady=(10, 0), sticky="ew")
            
        except Exception as e:
            self.logger.error(f"Error showing quick access: {e}")


def main():
    """Test the system tray manager"""
    # Create a simple test
    tray_manager = SystemTrayManager()
    
    # Add some test notifications
    tray_manager.add_notification("Test", "System tray is working!", "info")
    
    # Start the tray
    try:
        tray_manager.start()
    except KeyboardInterrupt:
        tray_manager.stop()


if __name__ == "__main__":
    main()