
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
Configuration Management System
Centralized configuration with enterprise policy management and validation
"""

import os
import sys
import json
import sqlite3
import threading
import time
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List, Union
from dataclasses import dataclass, asdict, field
from enum import Enum
import hashlib
import yaml
import configparser
import shutil
import re
from cryptography.fernet import Fernet

class ConfigScope(Enum):
    """Configuration scope levels"""
    SYSTEM = "system"          # System-wide settings
    USER = "user"              # User-specific settings
    APPLICATION = "application" # Application defaults
    POLICY = "policy"          # Enterprise policy (read-only)
    RUNTIME = "runtime"        # Runtime overrides

class ConfigType(Enum):
    """Configuration value types"""
    STRING = "string"
    INTEGER = "integer"
    FLOAT = "float"
    BOOLEAN = "boolean"
    LIST = "list"
    DICT = "dict"
    FILE_PATH = "file_path"
    DIRECTORY_PATH = "directory_path"
    URL = "url"
    EMAIL = "email"

@dataclass
class ConfigItem:
    """Configuration item definition"""
    key: str
    value: Any
    config_type: ConfigType
    scope: ConfigScope
    description: str = ""
    default_value: Any = None
    validation_rules: Optional[Dict[str, Any]] = field(default_factory=dict)
    is_sensitive: bool = False
    is_readonly: bool = False
    requires_restart: bool = False
    category: str = "general"
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    
    def __post_init__(self):
        if self.validation_rules is None:
            self.validation_rules = {}
        if self.created_at is None:
            self.created_at = datetime.now().isoformat()
        if self.updated_at is None:
            self.updated_at = self.created_at

class ConfigurationManager:
    """
    Advanced configuration management with enterprise policy support
    """
    
    def __init__(self, app_root=None):
        self.app_root = Path(app_root or os.getcwd())
        self.config_dir = self.app_root / "config"
        self.config_db = self.config_dir / "configuration.db"
        
        # Configuration files by scope
        self.config_files = {
            ConfigScope.SYSTEM: self.config_dir / "system_config.json",
            ConfigScope.USER: self.config_dir / "user_config.json", 
            ConfigScope.APPLICATION: self.config_dir / "app_config.json",
            ConfigScope.POLICY: self.config_dir / "policy_config.json",
            ConfigScope.RUNTIME: self.config_dir / "runtime_config.json"
        }
        
        # Encryption for sensitive values
        self.encryption_key_file = self.config_dir / ".config_key"
        self.cipher = None
        
        # Configuration cache
        self._config_cache = {}
        self._cache_lock = threading.RLock()
        self._config_schemas = {}
        self._change_callbacks = []
        
        # Validation rules
        self._validation_rules = {}
        
        self._setup_directories()
        self._setup_encryption()
        self._init_database()
        self._load_schemas()
        self._load_configurations()
    
    def _setup_directories(self):
        """Setup configuration directories"""
        self.config_dir.mkdir(parents=True, exist_ok=True)
        
        # Create subdirectories
        for subdir in ['schemas', 'templates', 'backups', 'exports']:
            (self.config_dir / subdir).mkdir(exist_ok=True)
    
    def _setup_encryption(self):
        """Setup encryption for sensitive configuration values"""
        try:
            if self.encryption_key_file.exists():
                with open(self.encryption_key_file, 'rb') as f:
                    key = f.read()
            else:
                key = Fernet.generate_key()
                with open(self.encryption_key_file, 'wb') as f:
                    f.write(key)
                # Secure the key file (Windows)
                os.chmod(self.encryption_key_file, 0o600)
            
            self.cipher = Fernet(key)
        except Exception as e:
            print(f"Encryption setup failed: {e}")
            self.cipher = None
    
    def _init_database(self):
        """Initialize configuration database"""
        try:
            with sqlite3.connect(self.config_db) as conn:
                conn.execute('''
                    CREATE TABLE IF NOT EXISTS config_items (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        key TEXT NOT NULL,
                        value TEXT,
                        config_type TEXT NOT NULL,
                        scope TEXT NOT NULL,
                        description TEXT,
                        default_value TEXT,
                        validation_rules TEXT,
                        is_sensitive BOOLEAN DEFAULT 0,
                        is_readonly BOOLEAN DEFAULT 0,
                        requires_restart BOOLEAN DEFAULT 0,
                        category TEXT DEFAULT 'general',
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE(key, scope)
                    )
                ''')
                
                conn.execute('''
                    CREATE TABLE IF NOT EXISTS config_history (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        key TEXT NOT NULL,
                        scope TEXT NOT NULL,
                        old_value TEXT,
                        new_value TEXT,
                        changed_by TEXT,
                        change_reason TEXT,
                        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                ''')
                
                conn.execute('''
                    CREATE TABLE IF NOT EXISTS config_schemas (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT UNIQUE NOT NULL,
                        version TEXT NOT NULL,
                        schema_data TEXT NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                ''')
                
                conn.execute('''
                    CREATE TABLE IF NOT EXISTS config_policies (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        policy_name TEXT NOT NULL,
                        policy_data TEXT NOT NULL,
                        applies_to TEXT, -- user, group, or system
                        priority INTEGER DEFAULT 100,
                        active BOOLEAN DEFAULT 1,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                ''')
                
                conn.commit()
        except Exception as e:
            print(f"Database initialization failed: {e}")
    
    def _load_schemas(self):
        """Load configuration schemas"""
        self._create_default_schemas()
    
    def _create_default_schemas(self):
        """Create default configuration schemas"""
        # Antivirus Core Schema
        antivirus_schema = {
            "name": "antivirus_core",
            "version": "1.0",
            "categories": {
                "scanning": {
                    "scan_on_startup": {
                        "type": "boolean",
                        "default": True,
                        "description": "Perform system scan on startup"
                    },
                    "real_time_protection": {
                        "type": "boolean", 
                        "default": True,
                        "description": "Enable real-time file protection"
                    },
                    "scan_archives": {
                        "type": "boolean",
                        "default": True,
                        "description": "Scan inside archive files"
                    },
                    "max_file_size_mb": {
                        "type": "integer",
                        "default": 100,
                        "min": 1,
                        "max": 1000,
                        "description": "Maximum file size to scan (MB)"
                    }
                },
                "quarantine": {
                    "quarantine_directory": {
                        "type": "directory_path",
                        "default": "./quarantine",
                        "description": "Directory for quarantined files"
                    },
                    "auto_quarantine": {
                        "type": "boolean",
                        "default": True,
                        "description": "Automatically quarantine threats"
                    }
                }
            }
        }
        
        # Firewall Schema
        firewall_schema = {
            "name": "firewall",
            "version": "1.0",
            "categories": {
                "protection": {
                    "enabled": {
                        "type": "boolean",
                        "default": True,
                        "description": "Enable firewall protection"
                    },
                    "default_policy": {
                        "type": "string",
                        "default": "deny",
                        "options": ["allow", "deny"],
                        "description": "Default policy for unmatched traffic"
                    },
                    "stealth_mode": {
                        "type": "boolean",
                        "default": False,
                        "description": "Enable stealth mode"
                    }
                },
                "logging": {
                    "log_level": {
                        "type": "string",
                        "default": "info",
                        "options": ["debug", "info", "warning", "error"],
                        "description": "Firewall logging level"
                    },
                    "log_file_size_mb": {
                        "type": "integer",
                        "default": 10,
                        "min": 1,
                        "max": 100,
                        "description": "Maximum log file size (MB)"
                    }
                }
            }
        }
        
        # VPN Schema
        vpn_schema = {
            "name": "vpn",
            "version": "1.0",
            "categories": {
                "connection": {
                    "auto_connect": {
                        "type": "boolean",
                        "default": False,
                        "description": "Auto-connect on startup"
                    },
                    "protocol": {
                        "type": "string",
                        "default": "openvpn",
                        "options": ["openvpn", "wireguard", "ikev2"],
                        "description": "VPN protocol"
                    },
                    "encryption": {
                        "type": "string",
                        "default": "aes256",
                        "options": ["aes128", "aes256", "chacha20"],
                        "description": "Encryption algorithm"
                    }
                },
                "killswitch": {
                    "enabled": {
                        "type": "boolean",
                        "default": True,
                        "description": "Enable kill switch"
                    },
                    "block_local_traffic": {
                        "type": "boolean",
                        "default": False,
                        "description": "Block local network traffic when VPN is off"
                    }
                }
            }
        }
        
        # UI Schema
        ui_schema = {
            "name": "ui",
            "version": "1.0",
            "categories": {
                "appearance": {
                    "theme": {
                        "type": "string",
                        "default": "dark",
                        "options": ["light", "dark", "auto"],
                        "description": "UI theme"
                    },
                    "language": {
                        "type": "string",
                        "default": "en",
                        "options": ["en", "es", "fr", "de", "zh"],
                        "description": "Interface language"
                    }
                },
                "notifications": {
                    "show_notifications": {
                        "type": "boolean",
                        "default": True,
                        "description": "Show system notifications"
                    },
                    "notification_level": {
                        "type": "string",
                        "default": "normal",
                        "options": ["minimal", "normal", "verbose"],
                        "description": "Notification detail level"
                    }
                }
            }
        }
        
        # Store schemas
        for schema in [antivirus_schema, firewall_schema, vpn_schema, ui_schema]:
            self._store_schema(schema)
    
    def _store_schema(self, schema):
        """Store configuration schema in database"""
        try:
            with sqlite3.connect(self.config_db) as conn:
                conn.execute('''
                    INSERT OR REPLACE INTO config_schemas (name, version, schema_data)
                    VALUES (?, ?, ?)
                ''', (schema['name'], schema['version'], json.dumps(schema)))
                conn.commit()
                
            self._config_schemas[schema['name']] = schema
        except Exception as e:
            print(f"Failed to store schema {schema['name']}: {e}")
    
    def _load_configurations(self):
        """Load all configuration scopes"""
        for scope in ConfigScope:
            self._load_scope_configuration(scope)
    
    def _load_scope_configuration(self, scope: ConfigScope):
        """Load configuration for specific scope"""
        try:
            config_file = self.config_files[scope]
            if config_file.exists():
                with open(config_file, 'r') as f:
                    config_data = json.load(f)
                
                with self._cache_lock:
                    if scope not in self._config_cache:
                        self._config_cache[scope] = {}
                    self._config_cache[scope].update(config_data)
        except Exception as e:
            print(f"Failed to load {scope.value} configuration: {e}")
    
    def get_value(self, key: str, scope: Optional[ConfigScope] = None, default=None):
        """
        Get configuration value with scope precedence
        """
        # Scope precedence: RUNTIME > USER > POLICY > SYSTEM > APPLICATION
        search_order = [
            ConfigScope.RUNTIME,
            ConfigScope.USER,
            ConfigScope.POLICY, 
            ConfigScope.SYSTEM,
            ConfigScope.APPLICATION
        ]
        
        if scope:
            # If specific scope requested, check only that scope
            search_order = [scope]
        
        with self._cache_lock:
            for check_scope in search_order:
                if check_scope in self._config_cache:
                    scope_config = self._config_cache[check_scope]
                    if key in scope_config:
                        value = scope_config[key]
                        
                        # Decrypt if sensitive
                        if self._is_sensitive_key(key) and self.cipher:
                            try:
                                value = self.cipher.decrypt(value.encode()).decode()
                            except Exception:
                                pass  # Return as-is if decryption fails
                        
                        return self._convert_value_type(key, value)
        
        return default
    
    def set_value(self, key: str, value: Any, scope: ConfigScope = ConfigScope.USER, 
                  description: str = "", config_type: Optional[ConfigType] = None,
                  validation_rules: Optional[Dict[str, Any]] = None, changed_by: str = "system"):
        """
        Set configuration value with validation
        """
        try:
            # Validate the value
            if not self._validate_value(key, value, config_type, validation_rules):
                raise ValueError(f"Validation failed for key: {key}")
            
            # Check if key is readonly in policy scope
            if self._is_readonly_key(key):
                raise ValueError(f"Key {key} is read-only")
            
            # Get old value for history
            old_value = self.get_value(key, scope)
            
            # Encrypt if sensitive
            store_value = value
            if self._is_sensitive_key(key) and self.cipher:
                store_value = self.cipher.encrypt(str(value).encode()).decode()
            
            # Update cache
            with self._cache_lock:
                if scope not in self._config_cache:
                    self._config_cache[scope] = {}
                self._config_cache[scope][key] = store_value
            
            # Save to file
            self._save_scope_configuration(scope)
            
            # Update database
            self._update_config_database(key, value, scope, description, 
                                       config_type, validation_rules)
            
            # Log change history
            self._log_config_change(key, scope, old_value, value, changed_by)
            
            # Notify callbacks
            self._notify_change_callbacks(key, old_value, value, scope)
            
            return True
            
        except Exception as e:
            print(f"Failed to set configuration {key}: {e}")
            return False
    
    def _validate_value(self, key: str, value: Any, config_type: Optional[ConfigType] = None,
                       validation_rules: Optional[Dict[str, Any]] = None) -> bool:
        """Validate configuration value"""
        try:
            # Get validation rules
            rules = validation_rules or self._get_validation_rules(key)
            if not rules:
                return True  # No rules = valid
            
            # Type validation
            if config_type:
                if not self._validate_type(value, config_type):
                    return False
            
            # Custom validation rules
            if 'min' in rules and value < rules['min']:
                return False
            if 'max' in rules and value > rules['max']:
                return False
            if 'options' in rules and value not in rules['options']:
                return False
            if 'pattern' in rules:
                import re
                if not re.match(rules['pattern'], str(value)):
                    return False
            
            return True
            
        except Exception as e:
            print(f"Validation error for {key}: {e}")
            return False
    
    def _validate_type(self, value: Any, config_type: ConfigType) -> bool:
        """Validate value type"""
        try:
            if config_type == ConfigType.STRING:
                return isinstance(value, str)
            elif config_type == ConfigType.INTEGER:
                return isinstance(value, int)
            elif config_type == ConfigType.FLOAT:
                return isinstance(value, (int, float))
            elif config_type == ConfigType.BOOLEAN:
                return isinstance(value, bool)
            elif config_type == ConfigType.LIST:
                return isinstance(value, list)
            elif config_type == ConfigType.DICT:
                return isinstance(value, dict)
            elif config_type == ConfigType.FILE_PATH:
                return isinstance(value, str) and Path(value).is_file()
            elif config_type == ConfigType.DIRECTORY_PATH:
                return isinstance(value, str) and Path(value).is_dir()
            elif config_type == ConfigType.URL:
                import re
                url_pattern = r'^https?://.+'
                return isinstance(value, str) and bool(re.match(url_pattern, value))
            elif config_type == ConfigType.EMAIL:
                import re
                email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
                return isinstance(value, str) and bool(re.match(email_pattern, value))
            
            return True
        except Exception:
            return False
    
    def _convert_value_type(self, key: str, value: Any) -> Any:
        """Convert value to appropriate type based on schema"""
        try:
            # Get type from schema
            config_type = self._get_config_type(key)
            if not config_type:
                return value
            
            if config_type == ConfigType.BOOLEAN and isinstance(value, str):
                return value.lower() in ('true', '1', 'yes', 'on')
            elif config_type == ConfigType.INTEGER and isinstance(value, str):
                return int(value)
            elif config_type == ConfigType.FLOAT and isinstance(value, str):
                return float(value)
            elif config_type == ConfigType.LIST and isinstance(value, str):
                return json.loads(value)
            elif config_type == ConfigType.DICT and isinstance(value, str):
                return json.loads(value)
            
            return value
        except Exception:
            return value
    
    def _is_sensitive_key(self, key: str) -> bool:
        """Check if key contains sensitive data"""
        sensitive_patterns = [
            'password', 'secret', 'key', 'token', 'credential',
            'private', 'cert', 'passphrase', 'pin'
        ]
        return any(pattern in key.lower() for pattern in sensitive_patterns)
    
    def _is_readonly_key(self, key: str) -> bool:
        """Check if key is readonly in policy"""
        try:
            policy_value = self.get_value(key, ConfigScope.POLICY)
            return policy_value is not None
        except Exception:
            return False
    
    def _get_validation_rules(self, key: str) -> Dict[str, Any]:
        """Get validation rules for key from schema"""
        try:
            for schema_name, schema in self._config_schemas.items():
                categories = schema.get('categories', {})
                for category_name, category in categories.items():
                    if key in category:
                        return category[key].get('validation', {})
            return {}
        except Exception:
            return {}
    
    def _get_config_type(self, key: str) -> Optional[ConfigType]:
        """Get configuration type for key from schema"""
        try:
            for schema_name, schema in self._config_schemas.items():
                categories = schema.get('categories', {})
                for category_name, category in categories.items():
                    if key in category:
                        type_str = category[key].get('type', 'string')
                        return ConfigType(type_str)
            return None
        except Exception:
            return None
    
    def _save_scope_configuration(self, scope: ConfigScope):
        """Save scope configuration to file"""
        try:
            config_file = self.config_files[scope]
            with self._cache_lock:
                config_data = self._config_cache.get(scope, {})
            
            with open(config_file, 'w') as f:
                json.dump(config_data, f, indent=2)
        except Exception as e:
            print(f"Failed to save {scope.value} configuration: {e}")
    
    def _update_config_database(self, key: str, value: Any, scope: ConfigScope,
                               description: str, config_type: Optional[ConfigType],
                               validation_rules: Optional[Dict[str, Any]]):
        """Update configuration in database"""
        try:
            with sqlite3.connect(self.config_db) as conn:
                conn.execute('''
                    INSERT OR REPLACE INTO config_items 
                    (key, value, config_type, scope, description, validation_rules, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ''', (
                    key,
                    json.dumps(value) if not isinstance(value, str) else value,
                    config_type.value if config_type else 'string',
                    scope.value,
                    description,
                    json.dumps(validation_rules) if validation_rules else None,
                    datetime.now().isoformat()
                ))
                conn.commit()
        except Exception as e:
            print(f"Failed to update configuration database: {e}")
    
    def _log_config_change(self, key: str, scope: ConfigScope, old_value: Any,
                          new_value: Any, changed_by: str, reason: str = ""):
        """Log configuration change to database"""
        try:
            with sqlite3.connect(self.config_db) as conn:
                conn.execute('''
                    INSERT INTO config_history 
                    (key, scope, old_value, new_value, changed_by, change_reason)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (
                    key,
                    scope.value,
                    json.dumps(old_value) if old_value is not None else None,
                    json.dumps(new_value) if new_value is not None else None,
                    changed_by,
                    reason
                ))
                conn.commit()
        except Exception as e:
            print(f"Failed to log configuration change: {e}")
    
    def add_change_callback(self, callback):
        """Add callback for configuration changes"""
        self._change_callbacks.append(callback)
    
    def _notify_change_callbacks(self, key: str, old_value: Any, new_value: Any, scope: ConfigScope):
        """Notify all change callbacks"""
        for callback in self._change_callbacks:
            try:
                callback(key, old_value, new_value, scope)
            except Exception as e:
                print(f"Callback error: {e}")
    
    def get_all_settings(self, scope: Optional[ConfigScope] = None) -> Dict[str, Any]:
        """Get all settings for scope or merged settings"""
        if scope:
            with self._cache_lock:
                config_data = self._config_cache.get(scope, {})
                # Decrypt sensitive values
                result = {}
                for key, value in config_data.items():
                    if self._is_sensitive_key(key) and self.cipher:
                        try:
                            result[key] = self.cipher.decrypt(value.encode()).decode()
                        except Exception:
                            result[key] = value
                    else:
                        result[key] = self._convert_value_type(key, value)
                return result
        else:
            # Merge all scopes with precedence
            merged = {}
            scope_order = [ConfigScope.APPLICATION, ConfigScope.SYSTEM, 
                          ConfigScope.POLICY, ConfigScope.USER, ConfigScope.RUNTIME]
            
            for check_scope in scope_order:
                scope_settings = self.get_all_settings(check_scope)
                merged.update(scope_settings)
            
            return merged
    
    def export_configuration(self, file_path: str, scope: Optional[ConfigScope] = None,
                           format_type: str = "json", include_sensitive: bool = False):
        """Export configuration to file"""
        try:
            settings = self.get_all_settings(scope)
            
            # Filter sensitive data if requested
            if not include_sensitive:
                settings = {k: v for k, v in settings.items() 
                           if not self._is_sensitive_key(k)}
            
            export_data = {
                'exported_at': datetime.now().isoformat(),
                'scope': scope.value if scope else 'merged',
                'settings': settings
            }
            
            file_path_obj = Path(file_path)
            
            if format_type.lower() == 'yaml':
                with open(file_path_obj, 'w') as f:
                    yaml.dump(export_data, f, default_flow_style=False)
            elif format_type.lower() == 'ini':
                config = configparser.ConfigParser()
                config['DEFAULT'] = {k: str(v) for k, v in settings.items()}
                with open(file_path_obj, 'w') as f:
                    config.write(f)
            else:  # JSON default
                with open(file_path_obj, 'w') as f:
                    json.dump(export_data, f, indent=2)
            
            print(f"Configuration exported to {file_path_obj}")
            return True
            
        except Exception as e:
            print(f"Failed to export configuration: {e}")
            return False
    
    def import_configuration(self, file_path: str, scope: ConfigScope = ConfigScope.USER,
                           merge: bool = True, validate: bool = True):
        """Import configuration from file"""
        try:
            file_path_obj = Path(file_path)
            if not file_path_obj.exists():
                raise FileNotFoundError(f"Configuration file not found: {file_path_obj}")
            
            # Load data based on file extension
            if file_path_obj.suffix.lower() == '.yaml' or file_path_obj.suffix.lower() == '.yml':
                with open(file_path_obj, 'r') as f:
                    import_data = yaml.safe_load(f)
            elif file_path_obj.suffix.lower() == '.ini':
                config = configparser.ConfigParser()
                config.read(file_path_obj)
                import_data = {'settings': dict(config['DEFAULT'])}
            else:  # JSON default
                with open(file_path_obj, 'r') as f:
                    import_data = json.load(f)
            
            settings = import_data.get('settings', {})
            
            # Validate settings if requested
            if validate:
                for key, value in settings.items():
                    if not self._validate_value(key, value):
                        print(f"Validation failed for {key}, skipping")
                        continue
            
            # Import settings
            imported_count = 0
            for key, value in settings.items():
                if self.set_value(key, value, scope, changed_by="import"):
                    imported_count += 1
            
            print(f"Imported {imported_count} configuration items to {scope.value}")
            return True
            
        except Exception as e:
            print(f"Failed to import configuration: {e}")
            return False
    
    def reset_to_defaults(self, scope: ConfigScope = ConfigScope.USER):
        """Reset configuration scope to defaults"""
        try:
            # Get default values from schemas
            defaults = {}
            for schema_name, schema in self._config_schemas.items():
                categories = schema.get('categories', {})
                for category_name, category in categories.items():
                    for key, settings in category.items():
                        if 'default' in settings:
                            defaults[key] = settings['default']
            
            # Clear current scope
            with self._cache_lock:
                self._config_cache[scope] = {}
            
            # Set default values
            reset_count = 0
            for key, default_value in defaults.items():
                if self.set_value(key, default_value, scope, changed_by="reset"):
                    reset_count += 1
            
            print(f"Reset {reset_count} settings to defaults in {scope.value}")
            return True
            
        except Exception as e:
            print(f"Failed to reset configuration: {e}")
            return False
    
    def get_change_history(self, key: Optional[str] = None, limit: int = 100) -> List[Dict]:
        """Get configuration change history"""
        try:
            with sqlite3.connect(self.config_db) as conn:
                if key:
                    cursor = conn.execute('''
                        SELECT key, scope, old_value, new_value, changed_by, 
                               change_reason, timestamp
                        FROM config_history 
                        WHERE key = ?
                        ORDER BY timestamp DESC 
                        LIMIT ?
                    ''', (key, limit))
                else:
                    cursor = conn.execute('''
                        SELECT key, scope, old_value, new_value, changed_by,
                               change_reason, timestamp
                        FROM config_history 
                        ORDER BY timestamp DESC 
                        LIMIT ?
                    ''', (limit,))
                
                history = []
                for row in cursor.fetchall():
                    history.append({
                        'key': row[0],
                        'scope': row[1],
                        'old_value': json.loads(row[2]) if row[2] else None,
                        'new_value': json.loads(row[3]) if row[3] else None,
                        'changed_by': row[4],
                        'change_reason': row[5],
                        'timestamp': row[6]
                    })
                
                return history
                
        except Exception as e:
            print(f"Failed to get change history: {e}")
            return []
    
    def create_backup(self, backup_name: Optional[str] = None) -> Optional[str]:
        """Create configuration backup"""
        try:
            if not backup_name:
                backup_name = f"config_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            
            backup_dir = self.config_dir / "backups" / backup_name
            backup_dir.mkdir(parents=True, exist_ok=True)
            
            # Backup all configuration files
            for scope, config_file in self.config_files.items():
                if config_file.exists():
                    backup_file = backup_dir / f"{scope.value}_config.json"
                    shutil.copy2(config_file, backup_file)
            
            # Backup database
            if self.config_db.exists():
                backup_db = backup_dir / "configuration.db"
                shutil.copy2(self.config_db, backup_db)
            
            # Create backup manifest
            manifest = {
                'backup_name': backup_name,
                'created_at': datetime.now().isoformat(),
                'files_backed_up': [f.name for f in backup_dir.iterdir()],
                'total_size': sum(f.stat().st_size for f in backup_dir.iterdir() if f.is_file())
            }
            
            manifest_file = backup_dir / "backup_manifest.json"
            with open(manifest_file, 'w') as f:
                json.dump(manifest, f, indent=2)
            
            print(f"Configuration backup created: {backup_name}")
            return str(backup_dir)
            
        except Exception as e:
            print(f"Failed to create backup: {e}")
            return None

def main():
    """Main function for testing configuration manager"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Configuration Management System')
    parser.add_argument('--get', help='Get configuration value')
    parser.add_argument('--set', nargs=2, metavar=('KEY', 'VALUE'), help='Set configuration value')
    parser.add_argument('--scope', choices=['system', 'user', 'application', 'policy', 'runtime'],
                       default='user', help='Configuration scope')
    parser.add_argument('--export', help='Export configuration to file')
    parser.add_argument('--import', dest='import_file', help='Import configuration from file')
    parser.add_argument('--list', action='store_true', help='List all configuration')
    parser.add_argument('--backup', help='Create configuration backup')
    parser.add_argument('--reset', action='store_true', help='Reset to defaults')
    
    args = parser.parse_args()
    
    # Create configuration manager
    config_manager = ConfigurationManager()
    
    # Handle commands
    if args.get:
        scope = ConfigScope(args.scope) if args.scope != 'user' else None
        value = config_manager.get_value(args.get, scope)
        print(f"{args.get} = {value}")
    
    elif args.set:
        key, value = args.set
        scope = ConfigScope(args.scope)
        success = config_manager.set_value(key, value, scope)
        print(f"Set {key} = {value}: {'Success' if success else 'Failed'}")
    
    elif args.export:
        scope = ConfigScope(args.scope) if args.scope != 'user' else None
        success = config_manager.export_configuration(args.export, scope)
        print(f"Export: {'Success' if success else 'Failed'}")
    
    elif args.import_file:
        scope = ConfigScope(args.scope)
        success = config_manager.import_configuration(args.import_file, scope)
        print(f"Import: {'Success' if success else 'Failed'}")
    
    elif args.list:
        scope = ConfigScope(args.scope) if args.scope != 'user' else None
        settings = config_manager.get_all_settings(scope)
        print(f"Configuration ({args.scope if scope else 'merged'}):")
        for key, value in settings.items():
            print(f"  {key} = {value}")
    
    elif args.backup:
        backup_path = config_manager.create_backup(args.backup)
        print(f"Backup created: {backup_path}")
    
    elif args.reset:
        scope = ConfigScope(args.scope)
        success = config_manager.reset_to_defaults(scope)
        print(f"Reset: {'Success' if success else 'Failed'}")
    
    else:
        parser.print_help()

if __name__ == "__main__":
    main()