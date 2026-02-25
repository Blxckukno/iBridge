
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
VPN Connection Manager
Advanced VPN management with multiple protocols and optimization
"""

import os
import json
import threading
import time
import ipaddress
import requests
from pathlib import Path
from datetime import datetime, timedelta
import logging
import psutil
import sqlite3
from typing import Dict, List, Optional
import asyncio
import socket

class VPNConnectionManager:
    """Advanced VPN connection management"""
    
    def __init__(self, config_path="vpn_config/"):
        self.config_path = Path(config_path)
        self.config_path.mkdir(parents=True, exist_ok=True)
        
        # Connection management
        self.active_connections = {}
        self.connection_profiles = {}
        self.auto_connect = False
        self.failover_enabled = True
        
        # Performance monitoring
        self.connection_stats = {}
        self.latency_monitoring = True
        self.bandwidth_monitoring = True
        self.monitor_thread = None
        
        # Security features
        self.kill_switch_enabled = True
        self.dns_leak_protection = True
        self.ipv6_leak_protection = True
        self.split_tunneling = {}
        
        # Server management
        self.server_list = []
        self.server_rankings = {}
        self.last_server_update = None
        
        self.logger = self._setup_logging()
        self.db_path = self.config_path / "vpn_manager.db"
        
        self._init_database()
        self._load_configuration()
        self._load_server_list()
    
    def _setup_logging(self):
        """Setup logging for VPN manager"""
        logging.basicConfig(level=logging.INFO)
        logger = logging.getLogger(__name__)
        
        log_file = self.config_path / "vpn_manager.log"
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
        
        return logger
    
    def _init_database(self):
        """Initialize VPN manager database"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS connection_profiles (
                    id INTEGER PRIMARY KEY,
                    profile_name TEXT UNIQUE,
                    server_address TEXT,
                    port INTEGER,
                    protocol TEXT,
                    username TEXT,
                    password TEXT,
                    encryption_method TEXT,
                    auto_connect BOOLEAN DEFAULT 0,
                    created_at TIMESTAMP,
                    last_used TIMESTAMP,
                    connection_count INTEGER DEFAULT 0,
                    success_rate REAL DEFAULT 0.0
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS connection_history (
                    id INTEGER PRIMARY KEY,
                    profile_name TEXT,
                    start_time TIMESTAMP,
                    end_time TIMESTAMP,
                    duration_seconds INTEGER,
                    bytes_sent INTEGER,
                    bytes_received INTEGER,
                    avg_latency REAL,
                    max_speed_mbps REAL,
                    disconnect_reason TEXT,
                    success BOOLEAN
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS server_performance (
                    id INTEGER PRIMARY KEY,
                    server_address TEXT,
                    measured_at TIMESTAMP,
                    ping_ms REAL,
                    download_speed_mbps REAL,
                    upload_speed_mbps REAL,
                    load_percentage REAL,
                    availability BOOLEAN,
                    country_code TEXT,
                    city TEXT
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS security_events (
                    id INTEGER PRIMARY KEY,
                    event_type TEXT,
                    description TEXT,
                    severity TEXT,
                    timestamp TIMESTAMP,
                    profile_name TEXT,
                    action_taken TEXT
                )
            ''')
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Database initialization error: {e}")
            raise
    
    def _load_configuration(self):
        """Load VPN manager configuration"""
        try:
            config_file = self.config_path / "manager_config.json"
            if config_file.exists():
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    
                    self.auto_connect = config.get('auto_connect', False)
                    self.failover_enabled = config.get('failover_enabled', True)
                    self.kill_switch_enabled = config.get('kill_switch_enabled', True)
                    self.dns_leak_protection = config.get('dns_leak_protection', True)
                    self.ipv6_leak_protection = config.get('ipv6_leak_protection', True)
                    self.latency_monitoring = config.get('latency_monitoring', True)
                    self.bandwidth_monitoring = config.get('bandwidth_monitoring', True)
                    self.split_tunneling = config.get('split_tunneling', {})
            
        except Exception as e:
            self.logger.error(f"Configuration loading error: {e}")
    
    def save_configuration(self):
        """Save VPN manager configuration"""
        try:
            config = {
                'auto_connect': self.auto_connect,
                'failover_enabled': self.failover_enabled,
                'kill_switch_enabled': self.kill_switch_enabled,
                'dns_leak_protection': self.dns_leak_protection,
                'ipv6_leak_protection': self.ipv6_leak_protection,
                'latency_monitoring': self.latency_monitoring,
                'bandwidth_monitoring': self.bandwidth_monitoring,
                'split_tunneling': self.split_tunneling,
                'saved_at': datetime.now().isoformat()
            }
            
            config_file = self.config_path / "manager_config.json"
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
                
        except Exception as e:
            self.logger.error(f"Configuration saving error: {e}")
    
    def _load_server_list(self):
        """Load VPN server list"""
        try:
            server_file = self.config_path / "servers.json"
            if server_file.exists():
                with open(server_file, 'r') as f:
                    data = json.load(f)
                    self.server_list = data.get('servers', [])
                    self.last_server_update = data.get('last_update')
            else:
                # Create default server list
                self._create_default_server_list()
                
        except Exception as e:
            self.logger.error(f"Server list loading error: {e}")
            self._create_default_server_list()
    
    def _create_default_server_list(self):
        """Create default server list"""
        try:
            default_servers = [
                {
                    'name': 'US-East-1',
                    'address': 'us-east-1.vpn.example.com',
                    'port': 1194,
                    'protocol': 'OpenVPN',
                    'country': 'US',
                    'city': 'New York',
                    'load': 25
                },
                {
                    'name': 'US-West-1',
                    'address': 'us-west-1.vpn.example.com',
                    'port': 1194,
                    'protocol': 'OpenVPN',
                    'country': 'US',
                    'city': 'Los Angeles',
                    'load': 30
                },
                {
                    'name': 'EU-Central-1',
                    'address': 'eu-central-1.vpn.example.com',
                    'port': 1194,
                    'protocol': 'OpenVPN',
                    'country': 'DE',
                    'city': 'Frankfurt',
                    'load': 15
                },
                {
                    'name': 'Asia-Pacific-1',
                    'address': 'ap-1.vpn.example.com',
                    'port': 1194,
                    'protocol': 'OpenVPN',
                    'country': 'SG',
                    'city': 'Singapore',
                    'load': 40
                }
            ]
            
            self.server_list = default_servers
            self._save_server_list()
            
        except Exception as e:
            self.logger.error(f"Default server list creation error: {e}")
    
    def _save_server_list(self):
        """Save server list to file"""
        try:
            server_data = {
                'servers': self.server_list,
                'last_update': datetime.now().isoformat()
            }
            
            server_file = self.config_path / "servers.json"
            with open(server_file, 'w') as f:
                json.dump(server_data, f, indent=2)
                
        except Exception as e:
            self.logger.error(f"Server list saving error: {e}")
    
    def create_profile(self, profile_name: str, server_address: str, port: int, 
                      protocol: str, username: str, password: str, 
                      encryption_method: str = "AES-256-GCM") -> bool:
        """Create new VPN connection profile"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO connection_profiles 
                (profile_name, server_address, port, protocol, username, password,
                 encryption_method, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (profile_name, server_address, port, protocol, username, password,
                  encryption_method, datetime.now()))
            
            conn.commit()
            conn.close()
            
            self.logger.info(f"Profile created: {profile_name}")
            return True
            
        except sqlite3.IntegrityError:
            self.logger.error(f"Profile already exists: {profile_name}")
            return False
        except Exception as e:
            self.logger.error(f"Profile creation error: {e}")
            return False
    
    def delete_profile(self, profile_name: str) -> bool:
        """Delete VPN connection profile"""
        try:
            # Disconnect if currently connected
            if profile_name in self.active_connections:
                self.disconnect(profile_name)
            
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('DELETE FROM connection_profiles WHERE profile_name = ?', 
                          (profile_name,))
            conn.commit()
            conn.close()
            
            self.logger.info(f"Profile deleted: {profile_name}")
            return True
            
        except Exception as e:
            self.logger.error(f"Profile deletion error: {e}")
            return False
    
    def connect(self, profile_name: str, auto_retry: bool = True) -> bool:
        """Connect to VPN using profile"""
        try:
            if profile_name in self.active_connections:
                self.logger.warning(f"Already connected to {profile_name}")
                return True
            
            # Get profile details
            profile = self._get_profile(profile_name)
            if not profile:
                self.logger.error(f"Profile not found: {profile_name}")
                return False
            
            # Check kill switch
            if self.kill_switch_enabled and self._has_active_connections():
                self.logger.error("Kill switch active - cannot establish new connections")
                return False
            
            # Start connection
            connection_id = self._start_connection(profile, auto_retry)
            if connection_id:
                self.active_connections[profile_name] = {
                    'connection_id': connection_id,
                    'profile': profile,
                    'start_time': datetime.now(),
                    'bytes_sent': 0,
                    'bytes_received': 0,
                    'latency_history': [],
                    'speed_history': []
                }
                
                # Start monitoring
                if self.latency_monitoring or self.bandwidth_monitoring:
                    self._start_connection_monitoring(profile_name)
                
                # Update profile statistics
                self._update_profile_stats(profile_name, True)
                
                # Log connection
                self._log_security_event('CONNECTION_ESTABLISHED', 
                                       f"Connected to {profile_name}", 
                                       'INFO', profile_name)
                
                self.logger.info(f"Connected to VPN: {profile_name}")
                return True
            
            return False
            
        except Exception as e:
            self.logger.error(f"Connection error: {e}")
            self._update_profile_stats(profile_name, False)
            return False
    
    def disconnect(self, profile_name: str) -> bool:
        """Disconnect from VPN"""
        try:
            if profile_name not in self.active_connections:
                self.logger.warning(f"Not connected to {profile_name}")
                return True
            
            connection_info = self.active_connections[profile_name]
            
            # Stop connection
            self._stop_connection(connection_info['connection_id'])
            
            # Calculate session statistics
            duration = datetime.now() - connection_info['start_time']
            
            # Log connection history
            self._log_connection_history(profile_name, connection_info, duration)
            
            # Remove from active connections
            del self.active_connections[profile_name]
            
            # Log security event
            self._log_security_event('CONNECTION_TERMINATED', 
                                   f"Disconnected from {profile_name}", 
                                   'INFO', profile_name)
            
            self.logger.info(f"Disconnected from VPN: {profile_name}")
            return True
            
        except Exception as e:
            self.logger.error(f"Disconnection error: {e}")
            return False
    
    def disconnect_all(self) -> bool:
        """Disconnect from all VPN connections"""
        try:
            success = True
            for profile_name in list(self.active_connections.keys()):
                if not self.disconnect(profile_name):
                    success = False
            
            return success
            
        except Exception as e:
            self.logger.error(f"Disconnect all error: {e}")
            return False
    
    def _start_connection(self, profile: Dict, auto_retry: bool) -> Optional[str]:
        """Start VPN connection"""
        try:
            # This would implement actual VPN connection logic
            # For demo purposes, we'll simulate a connection
            
            connection_id = f"conn_{profile['profile_name']}_{int(time.time())}"
            
            # Simulate connection establishment
            time.sleep(2)
            
            # Verify connection
            if self._verify_connection(profile):
                return connection_id
            
            return None
            
        except Exception as e:
            self.logger.error(f"Connection start error: {e}")
            return None
    
    def _stop_connection(self, connection_id: str) -> bool:
        """Stop VPN connection"""
        try:
            # This would implement actual VPN disconnection logic
            # For demo purposes, we'll simulate disconnection
            
            time.sleep(1)
            return True
            
        except Exception as e:
            self.logger.error(f"Connection stop error: {e}")
            return False
    
    def _verify_connection(self, profile: Dict) -> bool:
        """Verify VPN connection is working"""
        try:
            # Check if server is reachable
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((profile['server_address'], profile['port']))
            sock.close()
            
            return result == 0
            
        except Exception as e:
            self.logger.error(f"Connection verification error: {e}")
            return False
    
    def _has_active_connections(self) -> bool:
        """Check if there are active VPN connections"""
        return len(self.active_connections) > 0
    
    def _get_profile(self, profile_name: str) -> Optional[Dict]:
        """Get profile details from database"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('''
                SELECT profile_name, server_address, port, protocol, username, 
                       password, encryption_method
                FROM connection_profiles WHERE profile_name = ?
            ''', (profile_name,))
            
            result = cursor.fetchone()
            conn.close()
            
            if result:
                return {
                    'profile_name': result[0],
                    'server_address': result[1],
                    'port': result[2],
                    'protocol': result[3],
                    'username': result[4],
                    'password': result[5],
                    'encryption_method': result[6]
                }
            
            return None
            
        except Exception as e:
            self.logger.error(f"Profile retrieval error: {e}")
            return None
    
    def _start_connection_monitoring(self, profile_name: str):
        """Start monitoring for connection"""
        try:
            monitor_thread = threading.Thread(
                target=self._monitor_connection,
                args=(profile_name,),
                daemon=True
            )
            monitor_thread.start()
            
        except Exception as e:
            self.logger.error(f"Monitoring start error: {e}")
    
    def _monitor_connection(self, profile_name: str):
        """Monitor connection performance"""
        while profile_name in self.active_connections:
            try:
                connection_info = self.active_connections[profile_name]
                
                # Measure latency
                if self.latency_monitoring:
                    latency = self._measure_latency(connection_info['profile'])
                    if latency:
                        connection_info['latency_history'].append({
                            'timestamp': datetime.now(),
                            'latency_ms': latency
                        })
                        
                        # Keep only last 100 measurements
                        if len(connection_info['latency_history']) > 100:
                            connection_info['latency_history'] = connection_info['latency_history'][-100:]
                
                # Measure bandwidth
                if self.bandwidth_monitoring:
                    speed = self._measure_bandwidth(connection_info['profile'])
                    if speed:
                        connection_info['speed_history'].append({
                            'timestamp': datetime.now(),
                            'download_mbps': speed['download'],
                            'upload_mbps': speed['upload']
                        })
                        
                        # Keep only last 50 measurements
                        if len(connection_info['speed_history']) > 50:
                            connection_info['speed_history'] = connection_info['speed_history'][-50:]
                
                # Check for connection issues
                self._check_connection_health(profile_name)
                
                time.sleep(30)  # Check every 30 seconds
                
            except Exception as e:
                self.logger.error(f"Connection monitoring error: {e}")
                time.sleep(60)
    
    def _measure_latency(self, profile: Dict) -> Optional[float]:
        """Measure connection latency"""
        try:
            import subprocess
            import platform
            
            # Use ping command to measure latency
            if platform.system().lower() == 'windows':
                cmd = ['ping', '-n', '1', profile['server_address']]
            else:
                cmd = ['ping', '-c', '1', profile['server_address']]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                # Parse ping output to extract latency
                output = result.stdout
                if 'time=' in output or 'time<' in output:
                    import re
                    match = re.search(r'time[<=](\d+\.?\d*)ms', output)
                    if match:
                        return float(match.group(1))
                        
            return None
            
        except Exception as e:
            self.logger.error(f"Latency measurement error: {e}")
            return None
    
    def _measure_bandwidth(self, profile: Dict) -> Optional[Dict[str, float]]:
        """Measure connection bandwidth"""
        try:
            # Simplified bandwidth measurement
            # In reality, this would use actual speed test
            
            # Simulate speed test results
            import random
            download_speed = random.uniform(50, 150)  # Mbps
            upload_speed = random.uniform(20, 80)     # Mbps
            
            return {
                'download': download_speed,
                'upload': upload_speed
            }
            
        except Exception as e:
            self.logger.error(f"Bandwidth measurement error: {e}")
            return None
    
    def _check_connection_health(self, profile_name: str):
        """Check connection health and trigger failover if needed"""
        try:
            connection_info = self.active_connections[profile_name]
            
            # Check latency issues
            if connection_info['latency_history']:
                recent_latency = [l['latency_ms'] for l in connection_info['latency_history'][-5:]]
                avg_latency = sum(recent_latency) / len(recent_latency)
                
                if avg_latency > 1000:  # High latency
                    self._log_security_event('HIGH_LATENCY', 
                                           f"High latency detected: {avg_latency:.1f}ms", 
                                           'WARNING', profile_name)
                    
                    if self.failover_enabled:
                        self._trigger_failover(profile_name)
            
            # Check if connection is still alive
            if not self._verify_connection(connection_info['profile']):
                self._log_security_event('CONNECTION_LOST', 
                                       f"Connection lost to {profile_name}", 
                                       'ERROR', profile_name)
                
                if self.failover_enabled:
                    self._trigger_failover(profile_name)
                elif self.kill_switch_enabled:
                    self._activate_kill_switch()
            
        except Exception as e:
            self.logger.error(f"Connection health check error: {e}")
    
    def _trigger_failover(self, failed_profile: str):
        """Trigger failover to alternative server"""
        try:
            self.logger.info(f"Triggering failover for {failed_profile}")
            
            # Find alternative server
            alternative = self._find_alternative_server(failed_profile)
            if alternative:
                # Disconnect from failed profile
                self.disconnect(failed_profile)
                
                # Connect to alternative
                if self.connect(alternative):
                    self.logger.info(f"Failover successful: {failed_profile} -> {alternative}")
                    return True
            
            # If no alternative found, activate kill switch
            if self.kill_switch_enabled:
                self._activate_kill_switch()
            
            return False
            
        except Exception as e:
            self.logger.error(f"Failover error: {e}")
            return False
    
    def _find_alternative_server(self, failed_profile: str) -> Optional[str]:
        """Find alternative server for failover"""
        try:
            # Get list of available profiles
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('''
                SELECT profile_name, success_rate 
                FROM connection_profiles 
                WHERE profile_name != ? AND success_rate > 0.8
                ORDER BY success_rate DESC
            ''', (failed_profile,))
            
            alternatives = cursor.fetchall()
            conn.close()
            
            if alternatives:
                return alternatives[0][0]  # Return profile with highest success rate
                
            return None
            
        except Exception as e:
            self.logger.error(f"Alternative server search error: {e}")
            return None
    
    def _activate_kill_switch(self):
        """Activate kill switch to block internet"""
        try:
            self.logger.warning("Activating VPN kill switch")
            
            # Disconnect all VPN connections
            self.disconnect_all()
            
            # Log security event
            self._log_security_event('KILL_SWITCH_ACTIVATED', 
                                   'Internet access blocked due to VPN failure', 
                                   'CRITICAL', None)
            
            # Block internet access (implementation would depend on OS)
            # This is a simplified demonstration
            
        except Exception as e:
            self.logger.error(f"Kill switch activation error: {e}")
    
    def _update_profile_stats(self, profile_name: str, success: bool):
        """Update profile connection statistics"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            
            # Get current stats
            cursor.execute('''
                SELECT connection_count, success_rate FROM connection_profiles 
                WHERE profile_name = ?
            ''', (profile_name,))
            
            result = cursor.fetchone()
            if result:
                count, success_rate = result
                
                # Calculate new success rate
                if success:
                    new_success_rate = ((success_rate * count) + 1) / (count + 1)
                else:
                    new_success_rate = (success_rate * count) / (count + 1)
                
                # Update stats
                cursor.execute('''
                    UPDATE connection_profiles 
                    SET connection_count = connection_count + 1, 
                        success_rate = ?, last_used = ?
                    WHERE profile_name = ?
                ''', (new_success_rate, datetime.now(), profile_name))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Profile stats update error: {e}")
    
    def _log_connection_history(self, profile_name: str, connection_info: Dict, duration: timedelta):
        """Log connection history"""
        try:
            # Calculate average latency
            avg_latency = 0
            if connection_info['latency_history']:
                latencies = [l['latency_ms'] for l in connection_info['latency_history']]
                avg_latency = sum(latencies) / len(latencies)
            
            # Calculate max speed
            max_speed = 0
            if connection_info['speed_history']:
                speeds = [s['download_mbps'] for s in connection_info['speed_history']]
                max_speed = max(speeds) if speeds else 0
            
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO connection_history 
                (profile_name, start_time, end_time, duration_seconds,
                 bytes_sent, bytes_received, avg_latency, max_speed_mbps,
                 disconnect_reason, success)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (profile_name, connection_info['start_time'], datetime.now(),
                  int(duration.total_seconds()), connection_info['bytes_sent'],
                  connection_info['bytes_received'], avg_latency, max_speed,
                  'user_initiated', True))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Connection history logging error: {e}")
    
    def _log_security_event(self, event_type: str, description: str, severity: str, profile_name: Optional[str]):
        """Log security event"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO security_events 
                (event_type, description, severity, timestamp, profile_name, action_taken)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (event_type, description, severity, datetime.now(), profile_name, 'logged'))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Security event logging error: {e}")
    
    def get_connection_status(self) -> Dict:
        """Get current connection status"""
        try:
            status = {
                'active_connections': len(self.active_connections),
                'connections': {},
                'kill_switch_active': self.kill_switch_enabled and not self.active_connections,
                'auto_connect_enabled': self.auto_connect,
                'failover_enabled': self.failover_enabled
            }
            
            for profile_name, connection_info in self.active_connections.items():
                duration = datetime.now() - connection_info['start_time']
                
                # Get recent performance data
                recent_latency = None
                recent_speed = None
                
                if connection_info['latency_history']:
                    recent_latency = connection_info['latency_history'][-1]['latency_ms']
                
                if connection_info['speed_history']:
                    recent_speed = connection_info['speed_history'][-1]
                
                status['connections'][profile_name] = {
                    'server_address': connection_info['profile']['server_address'],
                    'protocol': connection_info['profile']['protocol'],
                    'connected_for_seconds': int(duration.total_seconds()),
                    'bytes_sent': connection_info['bytes_sent'],
                    'bytes_received': connection_info['bytes_received'],
                    'recent_latency_ms': recent_latency,
                    'recent_speed_mbps': recent_speed
                }
            
            return status
            
        except Exception as e:
            self.logger.error(f"Status retrieval error: {e}")
            return {}
    
    def get_profile_list(self) -> List[Dict]:
        """Get list of all connection profiles"""
        try:
            conn = sqlite3.connect(str(self.db_path))
            cursor = conn.cursor()
            cursor.execute('''
                SELECT profile_name, server_address, port, protocol, 
                       created_at, last_used, connection_count, success_rate
                FROM connection_profiles
                ORDER BY last_used DESC
            ''')
            
            profiles = []
            for row in cursor.fetchall():
                profiles.append({
                    'profile_name': row[0],
                    'server_address': row[1],
                    'port': row[2],
                    'protocol': row[3],
                    'created_at': row[4],
                    'last_used': row[5],
                    'connection_count': row[6],
                    'success_rate': row[7]
                })
            
            conn.close()
            return profiles
            
        except Exception as e:
            self.logger.error(f"Profile list error: {e}")
            return []
    
    def get_server_recommendations(self) -> List[Dict]:
        """Get server recommendations based on performance"""
        try:
            recommendations = []
            
            for server in self.server_list:
                # Calculate score based on load and performance
                load_score = (100 - server.get('load', 50)) / 100
                
                # Get historical performance
                conn = sqlite3.connect(str(self.db_path))
                cursor = conn.cursor()
                cursor.execute('''
                    SELECT AVG(ping_ms), AVG(download_speed_mbps), AVG(availability)
                    FROM server_performance 
                    WHERE server_address = ? AND measured_at > datetime('now', '-7 days')
                ''', (server['address'],))
                
                perf_data = cursor.fetchone()
                conn.close()
                
                if perf_data and perf_data[0]:
                    latency_score = max(0, (200 - perf_data[0]) / 200)  # Lower latency is better
                    speed_score = min(1, perf_data[1] / 100)  # Normalize to 100 Mbps
                    availability_score = perf_data[2] or 0
                else:
                    latency_score = speed_score = availability_score = 0.5
                
                # Calculate overall score
                overall_score = (load_score * 0.3 + latency_score * 0.3 + 
                               speed_score * 0.2 + availability_score * 0.2)
                
                recommendations.append({
                    'server': server,
                    'score': overall_score,
                    'load_percentage': server.get('load', 50),
                    'estimated_latency': perf_data[0] if perf_data and perf_data[0] else None,
                    'estimated_speed': perf_data[1] if perf_data and perf_data[1] else None
                })
            
            # Sort by score
            recommendations.sort(key=lambda x: x['score'], reverse=True)
            
            return recommendations[:10]  # Return top 10
            
        except Exception as e:
            self.logger.error(f"Server recommendations error: {e}")
            return []

if __name__ == "__main__":
    # Test VPN connection manager
    manager = VPNConnectionManager()
    
    # Create test profile
    profile_created = manager.create_profile(
        "test_profile",
        "test.vpn.server.com",
        1194,
        "OpenVPN",
        "testuser",
        "testpass",
        "AES-256-GCM"
    )
    
    if profile_created:
        print("Test profile created successfully")
        
        # Get profile list
        profiles = manager.get_profile_list()
        print(f"Available profiles: {len(profiles)}")
        
        # Get server recommendations
        recommendations = manager.get_server_recommendations()
        print(f"Server recommendations: {len(recommendations)}")
        
        # Test connection (would fail in demo environment)
        # connected = manager.connect("test_profile")
        # print(f"Connection result: {connected}")
        
        # Get status
        status = manager.get_connection_status()
        print("Connection Status:")
        print(json.dumps(status, indent=2, default=str))
    
    print("VPN Connection Manager test completed")