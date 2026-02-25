
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
Test Configuration Manager
Handles loading, validation, and management of test configurations
"""

import json
import os
import sys
import logging
from pathlib import Path
from typing import Dict, Any, Optional, Union
import copy

class ConfigurationManager:
    """
    Manages test configurations for the testing framework
    """
    
    def __init__(self):
        self.logger = logging.getLogger('ConfigManager')
        
        # Base directory for configuration files
        self.config_dir = Path(__file__).parent / "config"
        self.config_dir.mkdir(exist_ok=True)
        
        # Default configuration file path
        self.default_config_path = self.config_dir / "default_config.json"
        
        # Currently loaded configuration
        self.current_config = None
        
        # Built-in configurations
        self.builtin_configs = {
            'default': None,  # Will be loaded from file
            'unit_tests': {
                'run_unit_tests': True,
                'run_integration_tests': False,
                'run_security_tests': False,
                'run_performance_tests': False,
                'verbose_output': True
            },
            'integration_tests': {
                'run_unit_tests': False,
                'run_integration_tests': True,
                'run_security_tests': False,
                'run_performance_tests': False
            },
            'security_tests': {
                'run_unit_tests': False,
                'run_integration_tests': False,
                'run_security_tests': True,
                'run_performance_tests': False
            },
            'performance_tests': {
                'run_unit_tests': False,
                'run_integration_tests': False,
                'run_security_tests': False,
                'run_performance_tests': True,
                'parallel_tests': True
            },
            'ci': {
                'verbose_output': False,
                'create_test_report': True,
                'report_format': 'xml',
                'fail_fast': True,
                'retry_failed_tests': 1
            }
        }
        
        # Load default configuration
        self.load_default_config()
    
    def load_default_config(self) -> bool:
        """Load default configuration from file"""
        try:
            if self.default_config_path.exists():
                with open(self.default_config_path, 'r') as f:
                    self.builtin_configs['default'] = json.load(f)
                self.current_config = copy.deepcopy(self.builtin_configs['default'])
                self.logger.info(f"Default configuration loaded from {self.default_config_path}")
                return True
            else:
                self.logger.warning(f"Default configuration file not found: {self.default_config_path}")
                # Create a minimal default configuration
                self.builtin_configs['default'] = {
                    'run_unit_tests': True,
                    'run_integration_tests': True,
                    'run_security_tests': True,
                    'run_performance_tests': True,
                    'verbose_output': True,
                    'create_test_report': True,
                    'test_timeout': 300,
                    'parallel_tests': False,
                    'cleanup_after_tests': True
                }
                self.current_config = copy.deepcopy(self.builtin_configs['default'])
                return True
                
        except Exception as e:
            self.logger.error(f"Error loading default configuration: {str(e)}")
            return False
    
    def load_config(self, config_name_or_path: str) -> bool:
        """
        Load configuration by name or from file path
        
        Args:
            config_name_or_path: Name of built-in config or path to config file
        
        Returns:
            bool: True if configuration was loaded successfully
        """
        try:
            # Check if it's a built-in configuration
            if config_name_or_path in self.builtin_configs:
                if self.builtin_configs[config_name_or_path] is None:
                    self.load_default_config()
                else:
                    # Start with default and update with built-in
                    self.current_config = copy.deepcopy(self.builtin_configs['default'])
                    self.current_config.update(self.builtin_configs[config_name_or_path])
                    self.logger.info(f"Built-in configuration '{config_name_or_path}' loaded")
                return True
            
            # Check if it's a file in the config directory without extension
            config_file = self.config_dir / f"{config_name_or_path}.json"
            if config_file.exists():
                with open(config_file, 'r') as f:
                    config_data = json.load(f)
                
                # Start with default and update with loaded config
                self.current_config = copy.deepcopy(self.builtin_configs['default'])
                self.current_config.update(config_data)
                self.logger.info(f"Configuration loaded from {config_file}")
                return True
            
            # Check if it's a full file path
            config_path = Path(config_name_or_path)
            if config_path.exists() and config_path.is_file():
                with open(config_path, 'r') as f:
                    config_data = json.load(f)
                
                # Start with default and update with loaded config
                self.current_config = copy.deepcopy(self.builtin_configs['default'])
                self.current_config.update(config_data)
                self.logger.info(f"Configuration loaded from {config_path}")
                return True
            
            self.logger.warning(f"Configuration not found: {config_name_or_path}")
            return False
            
        except Exception as e:
            self.logger.error(f"Error loading configuration: {str(e)}")
            return False
    
    def update_config(self, updates: Dict[str, Any]) -> bool:
        """
        Update current configuration with new values
        
        Args:
            updates: Dictionary of configuration updates
        
        Returns:
            bool: True if configuration was updated successfully
        """
        try:
            if self.current_config is None:
                self.load_default_config()
            
            if self.current_config is not None:
                self.current_config.update(updates)
                self.logger.debug("Configuration updated")
                return True
            else:
                self.logger.error("Failed to load default configuration")
                return False
            
        except Exception as e:
            self.logger.error(f"Error updating configuration: {str(e)}")
            return False
    
    def get_config(self) -> Dict[str, Any]:
        """
        Get current configuration
        
        Returns:
            dict: Current configuration dictionary
        """
        if self.current_config is None:
            self.load_default_config()
        
        # Ensure we return a valid dictionary
        if self.current_config is None:
            # Fallback to minimal configuration
            return {
                'run_unit_tests': True,
                'run_integration_tests': True,
                'run_security_tests': True,
                'run_performance_tests': True,
                'verbose_output': True,
                'create_test_report': True,
                'cleanup_after_tests': True
            }
        
        return self.current_config
    
    def save_config(self, file_path: str) -> bool:
        """
        Save current configuration to file
        
        Args:
            file_path: Path where to save the configuration
        
        Returns:
            bool: True if configuration was saved successfully
        """
        try:
            if self.current_config is None:
                self.load_default_config()
            
            output_path = Path(file_path)
            with open(output_path, 'w') as f:
                json.dump(self.current_config, f, indent=2)
            
            self.logger.info(f"Configuration saved to {output_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error saving configuration: {str(e)}")
            return False
    
    def validate_config(self) -> bool:
        """
        Validate current configuration
        
        Returns:
            bool: True if configuration is valid
        """
        if self.current_config is None:
            self.load_default_config()
        
        # Ensure we have a valid configuration
        if self.current_config is None:
            self.logger.error("No configuration available for validation")
            return False
        
        # Required fields
        required_fields = [
            'run_unit_tests',
            'run_integration_tests', 
            'run_security_tests',
            'run_performance_tests',
            'verbose_output',
            'create_test_report',
            'cleanup_after_tests'
        ]
        
        # Check required fields
        for field in required_fields:
            if field not in self.current_config:
                self.logger.error(f"Required configuration field missing: {field}")
                return False
        
        # Check if at least one test type is enabled
        if not any([
            self.current_config.get('run_unit_tests', False),
            self.current_config.get('run_integration_tests', False),
            self.current_config.get('run_security_tests', False),
            self.current_config.get('run_performance_tests', False)
        ]):
            self.logger.warning("No test types are enabled in configuration")
        
        return True
    
    def get_available_configs(self) -> Dict[str, str]:
        """
        Get list of available configurations
        
        Returns:
            dict: Dictionary mapping config names to their descriptions
        """
        configs = {}
        
        # Add built-in configs
        configs.update({
            'default': 'Default configuration',
            'unit_tests': 'Run only unit tests',
            'integration_tests': 'Run only integration tests',
            'security_tests': 'Run only security tests',
            'performance_tests': 'Run only performance tests',
            'ci': 'Configuration for continuous integration'
        })
        
        # Add configs from config directory
        for config_file in self.config_dir.glob('*.json'):
            name = config_file.stem
            if name != 'default_config':  # Exclude default config
                # Try to get description from file
                try:
                    with open(config_file, 'r') as f:
                        data = json.load(f)
                        description = data.get('description', f'Configuration from {config_file.name}')
                except Exception:
                    description = f'Configuration from {config_file.name}'
                
                configs[name] = description
        
        return configs