
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
Configuration Manager
Handles all system configuration and settings
"""
import json
import os
from pathlib import Path
from typing import Any, Dict, List


class ConfigManager:
    """Manages system configuration and settings"""
    
    def __init__(self, config_dir: str = None):
        if config_dir is None:
            config_dir = Path.home() / ".antivirus_config"
        
        self.config_dir = Path(config_dir)
        self.config_dir.mkdir(exist_ok=True)
        
        self.config_file = self.config_dir / "config.json"
        self.signature_db_path = self.config_dir / "signatures.db"
        self.quarantine_dir = self.config_dir / "quarantine"
        self.logs_dir = self.config_dir / "logs"
        
        # Create necessary directories
        self.quarantine_dir.mkdir(exist_ok=True)
        self.logs_dir.mkdir(exist_ok=True)
        
        self.config = self._load_default_config()
        self._load_config()
    
    def _load_default_config(self) -> Dict:
        """Load default configuration"""
        return {
            "general": {
                "auto_quarantine": True,
                "auto_update": True,
                "send_telemetry": False,
                "max_scan_threads": 4,
                "scan_memory_limit_mb": 1024
            },
            "real_time_protection": {
                "enabled": True,
                "scan_downloads": True,
                "scan_email_attachments": True,
                "scan_usb_devices": True,
                "monitor_system_files": True,
                "behavioral_analysis": True
            },
            "scanning": {
                "scan_archives": True,
                "scan_compressed": True,
                "max_file_size_mb": 100,
                "scan_timeout_seconds": 300,
                "deep_scan": False,
                "heuristic_analysis": True
            },
            "network": {
                "firewall_enabled": True,
                "block_malicious_ips": True,
                "dns_filtering": True,
                "intrusion_detection": True,
                "port_scan_detection": True,
                "suspicious_traffic_analysis": True
            },
            "web_protection": {
                "url_filtering": True,
                "phishing_protection": True,
                "malware_download_blocking": True,
                "social_engineering_protection": True,
                "safe_browsing": True
            },
            "ransomware_protection": {
                "enabled": True,
                "file_backup": True,
                "behavior_monitoring": True,
                "process_injection_detection": True,
                "encryption_detection": True,
                "honeypot_files": True
            },
            "ml_settings": {
                "enabled": True,
                "confidence_threshold": 0.7,
                "update_model_frequency": "weekly",
                "behavioral_learning": True,
                "anomaly_detection": True
            },
            "updates": {
                "auto_update_definitions": True,
                "auto_update_software": False,
                "update_frequency": "daily",
                "update_server": "https://updates.antivirus.local",
                "check_signatures_on_startup": True
            },
            "exclusions": {
                "paths": [
                    str(Path.home() / ".antivirus_config"),
                    "C:\\Windows\\System32",
                    "C:\\Program Files\\Antivirus"
                ],
                "file_extensions": [".log", ".tmp"],
                "processes": ["antivirus.exe", "system"]
            },
            "notifications": {
                "show_scan_results": True,
                "show_threat_alerts": True,
                "show_update_notifications": True,
                "sound_alerts": True,
                "desktop_notifications": True
            },
            "performance": {
                "low_priority_scanning": True,
                "idle_time_scanning": True,
                "cpu_usage_limit": 80,
                "memory_usage_limit": 70,
                "io_throttling": True
            }
        }
    
    def _load_config(self):
        """Load configuration from file"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    loaded_config = json.load(f)
                    # Merge with defaults
                    self._merge_config(self.config, loaded_config)
            except Exception as e:
                print(f"Error loading config: {e}")
        
        # Save merged config
        self.save_config()
    
    def _merge_config(self, default: Dict, loaded: Dict):
        """Recursively merge loaded config with defaults"""
        for key, value in loaded.items():
            if key in default:
                if isinstance(value, dict) and isinstance(default[key], dict):
                    self._merge_config(default[key], value)
                else:
                    default[key] = value
    
    def save_config(self):
        """Save current configuration to file"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=4)
        except Exception as e:
            print(f"Error saving config: {e}")
    
    def get_setting(self, setting_path: str, default: Any = None) -> Any:
        """Get a configuration setting using dot notation"""
        parts = setting_path.split('.')
        current = self.config
        
        for part in parts:
            if isinstance(current, dict) and part in current:
                current = current[part]
            else:
                return default
        
        return current
    
    def set_setting(self, setting_path: str, value: Any):
        """Set a configuration setting using dot notation"""
        parts = setting_path.split('.')
        current = self.config
        
        for part in parts[:-1]:
            if part not in current:
                current[part] = {}
            current = current[part]
        
        current[parts[-1]] = value
        self.save_config()
    
    def get_scan_paths(self) -> List[str]:
        """Get paths to scan"""
        default_paths = [
            "C:\\",
            str(Path.home()),
            "C:\\Program Files",
            "C:\\Program Files (x86)"
        ]
        return self.get_setting("scanning.scan_paths", default_paths)
    
    def get_excluded_paths(self) -> List[str]:
        """Get paths to exclude from scanning"""
        return self.get_setting("exclusions.paths", [])
    
    def get_excluded_extensions(self) -> List[str]:
        """Get file extensions to exclude"""
        return self.get_setting("exclusions.file_extensions", [])
    
    def is_path_excluded(self, path: str) -> bool:
        """Check if a path should be excluded from scanning"""
        path = str(Path(path).resolve())
        
        for excluded_path in self.get_excluded_paths():
            if path.startswith(str(Path(excluded_path).resolve())):
                return True
        
        return False
    
    def is_extension_excluded(self, extension: str) -> bool:
        """Check if a file extension should be excluded"""
        return extension.lower() in [ext.lower() for ext in self.get_excluded_extensions()]
    
    def get_quarantine_dir(self) -> Path:
        """Get quarantine directory"""
        return self.quarantine_dir
    
    def get_logs_dir(self) -> Path:
        """Get logs directory"""
        return self.logs_dir
    
    def get_signature_db_path(self) -> Path:
        """Get signature database path"""
        return self.signature_db_path
    
    def reset_to_defaults(self):
        """Reset configuration to default values"""
        self.config = self._load_default_config()
        self.save_config()
    
    def export_config(self, file_path: str):
        """Export configuration to file"""
        with open(file_path, 'w') as f:
            json.dump(self.config, f, indent=4)
    
    def import_config(self, file_path: str):
        """Import configuration from file"""
        with open(file_path, 'r') as f:
            imported_config = json.load(f)
            self.config = self._load_default_config()
            self._merge_config(self.config, imported_config)
            self.save_config()
