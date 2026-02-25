
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
Centralized Security Manager
Coordinates all security systems and provides unified management interface
"""

import sqlite3
import threading
import time
import json
import os
import uuid
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum
import hashlib
import logging

class SecurityLevel(Enum):
    """Security level definitions"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class ThreatCategory(Enum):
    """Threat category classifications"""
    MALWARE = "malware"
    RANSOMWARE = "ransomware"
    PHISHING = "phishing"
    NETWORK_INTRUSION = "network_intrusion"
    DATA_BREACH = "data_breach"
    UNAUTHORIZED_ACCESS = "unauthorized_access"
    SUSPICIOUS_BEHAVIOR = "suspicious_behavior"
    ZERO_DAY = "zero_day"

@dataclass
class SecurityEvent:
    """Security event data structure"""
    event_id: str
    timestamp: datetime
    event_type: str
    severity: SecurityLevel
    source: str
    description: str
    affected_systems: List[str]
    threat_category: Optional[ThreatCategory] = None
    remediation_status: str = "pending"
    metadata: Optional[Dict[str, Any]] = None

class CentralizedSecurityManager:
    """
    Centralized Security Management System
    Coordinates all security components and provides unified control
    """
    
    def __init__(self, config_file: str = "security_config.json"):
        self.config_file = config_file
        self.db_path = "security_manager.db"
        self.running = False
        self.security_systems = {}
        self.active_threats = {}
        self.security_policies = {}
        self.alert_handlers = []
        
        # Initialize logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('security_manager.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        # Initialize database
        self._init_database()
        
        # Load configuration
        self._load_configuration()
        
        # Initialize monitoring thread
        self.monitor_thread = None
        self.last_health_check = datetime.now()
        
        # Security metrics
        self.metrics = {
            'threats_detected': 0,
            'threats_blocked': 0,
            'false_positives': 0,
            'system_uptime': 0,
            'last_update': datetime.now()
        }
        
        self.logger.info("Centralized Security Manager initialized")
    
    def _init_database(self):
        """Initialize the security management database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Security events table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS security_events (
                event_id TEXT PRIMARY KEY,
                timestamp TEXT NOT NULL,
                event_type TEXT NOT NULL,
                severity TEXT NOT NULL,
                source TEXT NOT NULL,
                description TEXT NOT NULL,
                affected_systems TEXT NOT NULL,
                threat_category TEXT,
                remediation_status TEXT DEFAULT 'pending',
                metadata TEXT
            )
        ''')
        
        # Security policies table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS security_policies (
                policy_id TEXT PRIMARY KEY,
                policy_name TEXT NOT NULL,
                policy_type TEXT NOT NULL,
                rules TEXT NOT NULL,
                enabled INTEGER DEFAULT 1,
                created_date TEXT NOT NULL,
                modified_date TEXT NOT NULL
            )
        ''')
        
        # System health table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS system_health (
                check_id TEXT PRIMARY KEY,
                timestamp TEXT NOT NULL,
                system_name TEXT NOT NULL,
                status TEXT NOT NULL,
                metrics TEXT,
                alerts TEXT
            )
        ''')
        
        # Threat intelligence table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS threat_intelligence (
                indicator_id TEXT PRIMARY KEY,
                indicator_type TEXT NOT NULL,
                indicator_value TEXT NOT NULL,
                threat_type TEXT NOT NULL,
                severity TEXT NOT NULL,
                source TEXT NOT NULL,
                confidence INTEGER NOT NULL,
                first_seen TEXT NOT NULL,
                last_seen TEXT NOT NULL,
                tags TEXT
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def _load_configuration(self):
        """Load security configuration"""
        default_config = {
            "security_level": "high",
            "auto_remediation": True,
            "alert_threshold": "medium",
            "update_interval": 3600,
            "backup_enabled": True,
            "logging_level": "info",
            "systems": {
                "realtime_scanner": {"enabled": True, "priority": 1},
                "firewall": {"enabled": True, "priority": 1},
                "web_protection": {"enabled": True, "priority": 2},
                "behavior_analysis": {"enabled": True, "priority": 2},
                "network_monitor": {"enabled": True, "priority": 3}
            }
        }
        
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    self.config = json.load(f)
            except Exception as e:
                self.logger.warning(f"Error loading config: {e}. Using defaults.")
                self.config = default_config
        else:
            self.config = default_config
            self._save_configuration()
    
    def _save_configuration(self):
        """Save current configuration"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=4)
        except Exception as e:
            self.logger.error(f"Error saving configuration: {e}")
    
    def register_security_system(self, name: str, system_instance: Any, priority: int = 5):
        """Register a security system with the manager"""
        self.security_systems[name] = {
            'instance': system_instance,
            'priority': priority,
            'status': 'active',
            'last_heartbeat': datetime.now(),
            'metrics': {}
        }
        self.logger.info(f"Registered security system: {name}")
    
    def unregister_security_system(self, name: str):
        """Unregister a security system"""
        if name in self.security_systems:
            del self.security_systems[name]
            self.logger.info(f"Unregistered security system: {name}")
    
    def start_monitoring(self):
        """Start the security monitoring system"""
        if self.running:
            return
        
        self.running = True
        self.monitor_thread = threading.Thread(target=self._monitor_loop, daemon=True)
        self.monitor_thread.start()
        self.logger.info("Security monitoring started")
    
    def stop_monitoring(self):
        """Stop the security monitoring system"""
        self.running = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=5)
        self.logger.info("Security monitoring stopped")
    
    def _monitor_loop(self):
        """Main monitoring loop"""
        while self.running:
            try:
                # Check system health
                self._check_system_health()
                
                # Process pending threats
                self._process_pending_threats()
                
                # Update threat intelligence
                self._update_threat_intelligence()
                
                # Enforce security policies
                self._enforce_policies()
                
                # Update metrics
                self._update_metrics()
                
                # Sleep for monitoring interval
                time.sleep(30)  # Check every 30 seconds
                
            except Exception as e:
                self.logger.error(f"Error in monitoring loop: {e}")
                time.sleep(60)  # Wait longer if error occurs
    
    def _check_system_health(self):
        """Check health of all registered security systems"""
        current_time = datetime.now()
        
        for name, system_info in self.security_systems.items():
            try:
                # Check if system has heartbeat method
                if hasattr(system_info['instance'], 'heartbeat'):
                    health_status = system_info['instance'].heartbeat()
                    system_info['last_heartbeat'] = current_time
                    system_info['status'] = 'active' if health_status else 'inactive'
                else:
                    # Default health check
                    system_info['status'] = 'active'
                
                # Log health status
                self._log_system_health(name, system_info['status'])
                
            except Exception as e:
                system_info['status'] = 'error'
                self.logger.error(f"Health check failed for {name}: {e}")
    
    def _log_system_health(self, system_name: str, status: str, metrics: Optional[Dict] = None):
        """Log system health to database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        health_record = {
            'check_id': str(uuid.uuid4()),
            'timestamp': datetime.now().isoformat(),
            'system_name': system_name,
            'status': status,
            'metrics': json.dumps(metrics or {}),
            'alerts': json.dumps([])
        }
        
        cursor.execute('''
            INSERT INTO system_health 
            (check_id, timestamp, system_name, status, metrics, alerts)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', tuple(health_record.values()))
        
        conn.commit()
        conn.close()
    
    def report_security_event(self, event: SecurityEvent):
        """Report a security event to the manager"""
        # Store event in database
        self._store_security_event(event)
        
        # Add to active threats if high severity
        if event.severity in [SecurityLevel.HIGH, SecurityLevel.CRITICAL]:
            self.active_threats[event.event_id] = event
        
        # Trigger alerts
        self._trigger_alerts(event)
        
        # Auto-remediation if enabled
        if self.config.get('auto_remediation', False):
            self._auto_remediate(event)
        
        self.logger.info(f"Security event reported: {event.event_id}")
    
    def _store_security_event(self, event: SecurityEvent):
        """Store security event in database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO security_events 
            (event_id, timestamp, event_type, severity, source, description, 
             affected_systems, threat_category, remediation_status, metadata)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            event.event_id,
            event.timestamp.isoformat(),
            event.event_type,
            event.severity.value,
            event.source,
            event.description,
            json.dumps(event.affected_systems),
            event.threat_category.value if event.threat_category else None,
            event.remediation_status,
            json.dumps(event.metadata or {})
        ))
        
        conn.commit()
        conn.close()
    
    def _trigger_alerts(self, event: SecurityEvent):
        """Trigger alerts for security event"""
        alert_threshold = SecurityLevel(self.config.get('alert_threshold', 'medium'))
        
        # Check if event meets alert threshold
        severity_order = {
            SecurityLevel.LOW: 1,
            SecurityLevel.MEDIUM: 2,
            SecurityLevel.HIGH: 3,
            SecurityLevel.CRITICAL: 4
        }
        
        if severity_order[event.severity] >= severity_order[alert_threshold]:
            for handler in self.alert_handlers:
                try:
                    handler(event)
                except Exception as e:
                    self.logger.error(f"Alert handler error: {e}")
    
    def _auto_remediate(self, event: SecurityEvent):
        """Attempt automatic remediation of security event"""
        remediation_actions = {
            ThreatCategory.MALWARE: self._remediate_malware,
            ThreatCategory.RANSOMWARE: self._remediate_ransomware,
            ThreatCategory.PHISHING: self._remediate_phishing,
            ThreatCategory.NETWORK_INTRUSION: self._remediate_network_intrusion
        }
        
        if event.threat_category and event.threat_category in remediation_actions:
            try:
                success = remediation_actions[event.threat_category](event)
                if success:
                    event.remediation_status = "auto_resolved"
                    self.logger.info(f"Auto-remediated event: {event.event_id}")
                else:
                    event.remediation_status = "failed"
            except Exception as e:
                self.logger.error(f"Auto-remediation failed for {event.event_id}: {e}")
                event.remediation_status = "failed"
    
    def _remediate_malware(self, event: SecurityEvent) -> bool:
        """Remediate malware threat"""
        # Quarantine affected files
        if 'quarantine' in self.security_systems:
            quarantine_system = self.security_systems['quarantine']['instance']
            if hasattr(quarantine_system, 'quarantine_files'):
                affected_files = (event.metadata or {}).get('files', [])
                for file_path in affected_files:
                    quarantine_system.quarantine_file(file_path, f"Malware detected: {event.description}")
                return True
        return False
    
    def _remediate_ransomware(self, event: SecurityEvent) -> bool:
        """Remediate ransomware threat"""
        # Stop suspicious processes and restore from backup
        if 'ransomware_protection' in self.security_systems:
            protection_system = self.security_systems['ransomware_protection']['instance']
            if hasattr(protection_system, 'emergency_response'):
                return protection_system.emergency_response(event.metadata)
        return False
    
    def _remediate_phishing(self, event: SecurityEvent) -> bool:
        """Remediate phishing threat"""
        # Block malicious URLs
        if 'web_protection' in self.security_systems:
            web_protection = self.security_systems['web_protection']['instance']
            if hasattr(web_protection, 'block_url'):
                malicious_urls = (event.metadata or {}).get('urls', [])
                for url in malicious_urls:
                    web_protection.block_url(url)
                return True
        return False
    
    def _remediate_network_intrusion(self, event: SecurityEvent) -> bool:
        """Remediate network intrusion"""
        # Block suspicious IPs
        if 'firewall' in self.security_systems:
            firewall = self.security_systems['firewall']['instance']
            if hasattr(firewall, 'block_ip'):
                suspicious_ips = (event.metadata or {}).get('source_ips', [])
                for ip in suspicious_ips:
                    firewall.block_ip(ip, f"Network intrusion: {event.description}")
                return True
        return False
    
    def _process_pending_threats(self):
        """Process pending threat responses"""
        current_time = datetime.now()
        
        for event_id, event in list(self.active_threats.items()):
            # Check if threat is older than 24 hours
            if current_time - event.timestamp > timedelta(hours=24):
                if event.remediation_status == "pending":
                    event.remediation_status = "timeout"
                del self.active_threats[event_id]
                continue
            
            # Attempt remediation if still pending
            if event.remediation_status == "pending":
                self._auto_remediate(event)
    
    def _update_threat_intelligence(self):
        """Update threat intelligence data"""
        # This would integrate with external threat intelligence feeds
        # For now, we'll update internal intelligence
        try:
            # Clean old intelligence data (older than 30 days)
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cutoff_date = (datetime.now() - timedelta(days=30)).isoformat()
            cursor.execute(
                "DELETE FROM threat_intelligence WHERE first_seen < ?",
                (cutoff_date,)
            )
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Error updating threat intelligence: {e}")
    
    def _enforce_policies(self):
        """Enforce security policies across all systems"""
        for policy_id, policy in self.security_policies.items():
            if policy.get('enabled', True):
                self._apply_policy(policy)
    
    def _apply_policy(self, policy: Dict):
        """Apply a specific security policy"""
        policy_type = policy.get('type')
        rules = policy.get('rules', {})
        
        try:
            if policy_type == 'access_control':
                self._enforce_access_control(rules)
            elif policy_type == 'data_protection':
                self._enforce_data_protection(rules)
            elif policy_type == 'network_security':
                self._enforce_network_security(rules)
            elif policy_type == 'compliance':
                self._enforce_compliance(rules)
                
        except Exception as e:
            self.logger.error(f"Error applying policy {policy.get('name', 'unknown')}: {e}")
    
    def _enforce_access_control(self, rules: Dict):
        """Enforce access control policies"""
        # Implement access control enforcement
        pass
    
    def _enforce_data_protection(self, rules: Dict):
        """Enforce data protection policies"""
        # Implement data protection enforcement
        pass
    
    def _enforce_network_security(self, rules: Dict):
        """Enforce network security policies"""
        # Implement network security enforcement
        pass
    
    def _enforce_compliance(self, rules: Dict):
        """Enforce compliance policies"""
        # Implement compliance enforcement
        pass
    
    def _update_metrics(self):
        """Update security metrics"""
        current_time = datetime.now()
        
        # Update system uptime
        uptime_hours = (current_time - self.metrics['last_update']).total_seconds() / 3600
        self.metrics['system_uptime'] += uptime_hours
        self.metrics['last_update'] = current_time
        
        # Count recent threats
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Threats in last 24 hours
        day_ago = (current_time - timedelta(days=1)).isoformat()
        cursor.execute(
            "SELECT COUNT(*) FROM security_events WHERE timestamp > ?",
            (day_ago,)
        )
        daily_threats = cursor.fetchone()[0]
        
        # Update metrics
        self.metrics['daily_threats'] = daily_threats
        
        conn.close()
    
    def add_alert_handler(self, handler_func):
        """Add alert handler function"""
        self.alert_handlers.append(handler_func)
    
    def get_security_status(self) -> Dict[str, Any]:
        """Get current security status"""
        return {
            'overall_status': self._calculate_overall_status(),
            'active_threats': len(self.active_threats),
            'system_health': self._get_system_health_summary(),
            'metrics': self.metrics,
            'last_update': datetime.now().isoformat()
        }
    
    def _calculate_overall_status(self) -> str:
        """Calculate overall security status"""
        if len(self.active_threats) > 0:
            critical_threats = sum(1 for t in self.active_threats.values() 
                                 if t.severity == SecurityLevel.CRITICAL)
            if critical_threats > 0:
                return "critical"
            return "high_risk"
        
        inactive_systems = sum(1 for s in self.security_systems.values() 
                             if s['status'] != 'active')
        if inactive_systems > 0:
            return "degraded"
        
        return "secure"
    
    def _get_system_health_summary(self) -> Dict[str, str]:
        """Get summary of system health"""
        return {name: info['status'] for name, info in self.security_systems.items()}
    
    def get_recent_events(self, hours: int = 24) -> List[Dict]:
        """Get recent security events"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        since_time = (datetime.now() - timedelta(hours=hours)).isoformat()
        cursor.execute('''
            SELECT * FROM security_events 
            WHERE timestamp > ? 
            ORDER BY timestamp DESC
        ''', (since_time,))
        
        events = []
        for row in cursor.fetchall():
            events.append({
                'event_id': row[0],
                'timestamp': row[1],
                'event_type': row[2],
                'severity': row[3],
                'source': row[4],
                'description': row[5],
                'affected_systems': json.loads(row[6]),
                'threat_category': row[7],
                'remediation_status': row[8]
            })
        
        conn.close()
        return events
    
    def shutdown(self):
        """Shutdown the security manager"""
        self.logger.info("Shutting down Security Manager")
        self.stop_monitoring()
        
        # Close any open connections
        for name, system_info in self.security_systems.items():
            if hasattr(system_info['instance'], 'shutdown'):
                try:
                    system_info['instance'].shutdown()
                except Exception as e:
                    self.logger.error(f"Error shutting down {name}: {e}")
        
        self.logger.info("Security Manager shutdown complete")