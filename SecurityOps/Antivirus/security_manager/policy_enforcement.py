
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
Policy Enforcement Engine
Manages and enforces security policies across all systems
"""

import json
import sqlite3
import threading
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass, asdict, field
from enum import Enum
import logging
import uuid

class PolicyType(Enum):
    """Types of security policies"""
    ACCESS_CONTROL = "access_control"
    DATA_PROTECTION = "data_protection"
    NETWORK_SECURITY = "network_security"
    COMPLIANCE = "compliance"
    ENDPOINT_SECURITY = "endpoint_security"
    APPLICATION_CONTROL = "application_control"

class PolicyAction(Enum):
    """Policy enforcement actions"""
    ALLOW = "allow"
    DENY = "deny"
    WARN = "warn"
    LOG = "log"
    QUARANTINE = "quarantine"
    BLOCK = "block"

class PolicySeverity(Enum):
    """Policy violation severity levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

@dataclass
class PolicyRule:
    """Individual policy rule"""
    rule_id: str
    rule_name: str
    condition: Dict[str, Any]
    action: PolicyAction
    severity: PolicySeverity
    enabled: bool = True
    metadata: Optional[Dict[str, Any]] = None

@dataclass
class SecurityPolicy:
    """Complete security policy definition"""
    policy_id: str
    policy_name: str
    policy_type: PolicyType
    description: str
    rules: List[PolicyRule]
    enabled: bool = True
    priority: int = 5
    created_date: Optional[datetime] = field(default_factory=datetime.now)
    modified_date: Optional[datetime] = field(default_factory=datetime.now)
    tags: Optional[List[str]] = field(default_factory=list)

@dataclass
class PolicyViolation:
    """Policy violation record"""
    violation_id: str
    policy_id: str
    rule_id: str
    timestamp: datetime
    source: str
    severity: PolicySeverity
    description: str
    action_taken: PolicyAction
    metadata: Optional[Dict[str, Any]] = None

class PolicyEnforcementEngine:
    """
    Advanced Policy Enforcement Engine
    Manages and enforces security policies across the entire system
    """
    
    def __init__(self, db_path: str = "policy_engine.db"):
        self.db_path = db_path
        self.policies = {}
        self.violation_handlers = {}
        self.enforcement_enabled = True
        self.running = False
        
        # Initialize logging
        self.logger = logging.getLogger(__name__)
        
        # Initialize database
        self._init_database()
        
        # Load existing policies
        self._load_policies()
        
        # Policy evaluation cache
        self.evaluation_cache = {}
        self.cache_ttl = 300  # 5 minutes
        
        # Statistics
        self.stats = {
            'policies_evaluated': 0,
            'violations_detected': 0,
            'actions_taken': 0,
            'cache_hits': 0,
            'last_reset': datetime.now()
        }
        
        self.logger.info("Policy Enforcement Engine initialized")
    
    def _init_database(self):
        """Initialize the policy database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Policies table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS policies (
                policy_id TEXT PRIMARY KEY,
                policy_name TEXT NOT NULL,
                policy_type TEXT NOT NULL,
                description TEXT,
                rules TEXT NOT NULL,
                enabled INTEGER DEFAULT 1,
                priority INTEGER DEFAULT 5,
                created_date TEXT NOT NULL,
                modified_date TEXT NOT NULL,
                tags TEXT
            )
        ''')
        
        # Policy violations table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS policy_violations (
                violation_id TEXT PRIMARY KEY,
                policy_id TEXT NOT NULL,
                rule_id TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                source TEXT NOT NULL,
                severity TEXT NOT NULL,
                description TEXT NOT NULL,
                action_taken TEXT NOT NULL,
                metadata TEXT,
                FOREIGN KEY (policy_id) REFERENCES policies (policy_id)
            )
        ''')
        
        # Policy evaluation logs
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS policy_evaluations (
                evaluation_id TEXT PRIMARY KEY,
                timestamp TEXT NOT NULL,
                policy_id TEXT NOT NULL,
                source TEXT NOT NULL,
                result TEXT NOT NULL,
                execution_time REAL,
                metadata TEXT
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def _load_policies(self):
        """Load existing policies from database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM policies WHERE enabled = 1")
        for row in cursor.fetchall():
            policy_data = {
                'policy_id': row[0],
                'policy_name': row[1],
                'policy_type': PolicyType(row[2]),
                'description': row[3],
                'rules': json.loads(row[4]),
                'enabled': bool(row[5]),
                'priority': row[6],
                'created_date': datetime.fromisoformat(row[7]),
                'modified_date': datetime.fromisoformat(row[8]),
                'tags': json.loads(row[9]) if row[9] else []
            }
            
            # Convert rules to PolicyRule objects
            rules = []
            for rule_data in policy_data['rules']:
                rule = PolicyRule(
                    rule_id=rule_data['rule_id'],
                    rule_name=rule_data['rule_name'],
                    condition=rule_data['condition'],
                    action=PolicyAction(rule_data['action']),
                    severity=PolicySeverity(rule_data['severity']),
                    enabled=rule_data.get('enabled', True),
                    metadata=rule_data.get('metadata')
                )
                rules.append(rule)
            
            policy = SecurityPolicy(
                policy_id=policy_data['policy_id'],
                policy_name=policy_data['policy_name'],
                policy_type=policy_data['policy_type'],
                description=policy_data['description'],
                rules=rules,
                enabled=policy_data['enabled'],
                priority=policy_data['priority'],
                created_date=policy_data['created_date'],
                modified_date=policy_data['modified_date'],
                tags=policy_data['tags']
            )
            
            self.policies[policy.policy_id] = policy
        
        conn.close()
        self.logger.info(f"Loaded {len(self.policies)} policies")
    
    def create_policy(self, policy: SecurityPolicy) -> bool:
        """Create a new security policy"""
        try:
            # Set timestamps
            current_time = datetime.now()
            policy.created_date = current_time
            policy.modified_date = current_time
            
            # Store in database
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Convert rules to serializable format
            rules_data = []
            for rule in policy.rules:
                rules_data.append({
                    'rule_id': rule.rule_id,
                    'rule_name': rule.rule_name,
                    'condition': rule.condition,
                    'action': rule.action.value,
                    'severity': rule.severity.value,
                    'enabled': rule.enabled,
                    'metadata': rule.metadata
                })
            
            cursor.execute('''
                INSERT INTO policies 
                (policy_id, policy_name, policy_type, description, rules, 
                 enabled, priority, created_date, modified_date, tags)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                policy.policy_id,
                policy.policy_name,
                policy.policy_type.value,
                policy.description,
                json.dumps(rules_data),
                int(policy.enabled),
                policy.priority,
                policy.created_date.isoformat(),
                policy.modified_date.isoformat(),
                json.dumps(policy.tags or [])
            ))
            
            conn.commit()
            conn.close()
            
            # Add to memory
            self.policies[policy.policy_id] = policy
            
            self.logger.info(f"Created policy: {policy.policy_name}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error creating policy: {e}")
            return False
    
    def update_policy(self, policy: SecurityPolicy) -> bool:
        """Update an existing policy"""
        try:
            policy.modified_date = datetime.now()
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Convert rules to serializable format
            rules_data = []
            for rule in policy.rules:
                rules_data.append({
                    'rule_id': rule.rule_id,
                    'rule_name': rule.rule_name,
                    'condition': rule.condition,
                    'action': rule.action.value,
                    'severity': rule.severity.value,
                    'enabled': rule.enabled,
                    'metadata': rule.metadata
                })
            
            cursor.execute('''
                UPDATE policies SET
                    policy_name = ?, policy_type = ?, description = ?,
                    rules = ?, enabled = ?, priority = ?, modified_date = ?, tags = ?
                WHERE policy_id = ?
            ''', (
                policy.policy_name,
                policy.policy_type.value,
                policy.description,
                json.dumps(rules_data),
                int(policy.enabled),
                policy.priority,
                policy.modified_date.isoformat(),
                json.dumps(policy.tags or []),
                policy.policy_id
            ))
            
            conn.commit()
            conn.close()
            
            # Update in memory
            self.policies[policy.policy_id] = policy
            
            # Clear cache for this policy
            self._clear_policy_cache(policy.policy_id)
            
            self.logger.info(f"Updated policy: {policy.policy_name}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error updating policy: {e}")
            return False
    
    def delete_policy(self, policy_id: str) -> bool:
        """Delete a policy"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("DELETE FROM policies WHERE policy_id = ?", (policy_id,))
            conn.commit()
            conn.close()
            
            # Remove from memory
            if policy_id in self.policies:
                del self.policies[policy_id]
            
            # Clear cache
            self._clear_policy_cache(policy_id)
            
            self.logger.info(f"Deleted policy: {policy_id}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error deleting policy: {e}")
            return False
    
    def evaluate_policies(self, event_data: Dict[str, Any], source: str) -> List[PolicyViolation]:
        """Evaluate all applicable policies against event data"""
        violations = []
        
        if not self.enforcement_enabled:
            return violations
        
        # Check cache first
        cache_key = self._generate_cache_key(event_data, source)
        cached_result = self._get_cached_result(cache_key)
        if cached_result:
            self.stats['cache_hits'] += 1
            return cached_result
        
        start_time = time.time()
        
        # Sort policies by priority (lower number = higher priority)
        sorted_policies = sorted(
            self.policies.values(),
            key=lambda p: p.priority
        )
        
        for policy in sorted_policies:
            if not policy.enabled:
                continue
            
            policy_violations = self._evaluate_policy(policy, event_data, source)
            violations.extend(policy_violations)
        
        execution_time = time.time() - start_time
        
        # Cache the result
        self._cache_result(cache_key, violations)
        
        # Log evaluation
        self._log_evaluation(source, len(violations), execution_time)
        
        # Update statistics
        self.stats['policies_evaluated'] += len(sorted_policies)
        if violations:
            self.stats['violations_detected'] += len(violations)
        
        return violations
    
    def _evaluate_policy(self, policy: SecurityPolicy, event_data: Dict[str, Any], source: str) -> List[PolicyViolation]:
        """Evaluate a single policy against event data"""
        violations = []
        
        for rule in policy.rules:
            if not rule.enabled:
                continue
            
            if self._evaluate_rule_condition(rule.condition, event_data):
                violation = PolicyViolation(
                    violation_id=str(uuid.uuid4()),
                    policy_id=policy.policy_id,
                    rule_id=rule.rule_id,
                    timestamp=datetime.now(),
                    source=source,
                    severity=rule.severity,
                    description=f"Policy violation: {rule.rule_name}",
                    action_taken=rule.action,
                    metadata=event_data
                )
                
                violations.append(violation)
                
                # Execute the action
                self._execute_policy_action(violation, rule.action)
                
                # Store violation
                self._store_violation(violation)
        
        return violations
    
    def _evaluate_rule_condition(self, condition: Dict[str, Any], event_data: Dict[str, Any]) -> bool:
        """Evaluate a rule condition against event data"""
        try:
            condition_type = condition.get('type', 'simple')
            
            if condition_type == 'simple':
                return self._evaluate_simple_condition(condition, event_data)
            elif condition_type == 'complex':
                return self._evaluate_complex_condition(condition, event_data)
            elif condition_type == 'pattern':
                return self._evaluate_pattern_condition(condition, event_data)
            else:
                self.logger.warning(f"Unknown condition type: {condition_type}")
                return False
                
        except Exception as e:
            self.logger.error(f"Error evaluating condition: {e}")
            return False
    
    def _evaluate_simple_condition(self, condition: Dict[str, Any], event_data: Dict[str, Any]) -> bool:
        """Evaluate simple conditions (field comparisons)"""
        field = condition.get('field')
        operator = condition.get('operator')
        value = condition.get('value')
        
        if not field or not operator:
            return False
        
        # Get field value from event data
        field_value = self._get_nested_value(event_data, field)
        
        # Perform comparison
        if operator == 'equals':
            return field_value == value
        elif operator == 'not_equals':
            return field_value != value
        elif operator == 'contains':
            if field_value is not None and value is not None:
                return value in str(field_value)
            return False
        elif operator == 'not_contains':
            if field_value is not None and value is not None:
                return value not in str(field_value)
            return True
        elif operator == 'starts_with':
            return str(field_value).startswith(str(value)) if field_value else False
        elif operator == 'ends_with':
            return str(field_value).endswith(str(value)) if field_value else False
        elif operator == 'greater_than':
            try:
                if field_value is not None and value is not None:
                    return float(field_value) > float(value)
                return False
            except (ValueError, TypeError):
                return False
        elif operator == 'less_than':
            try:
                if field_value is not None and value is not None:
                    return float(field_value) < float(value)
                return False
            except (ValueError, TypeError):
                return False
        elif operator == 'in':
            return field_value in value if isinstance(value, list) else False
        elif operator == 'not_in':
            return field_value not in value if isinstance(value, list) else True
        else:
            return False
    
    def _evaluate_complex_condition(self, condition: Dict[str, Any], event_data: Dict[str, Any]) -> bool:
        """Evaluate complex conditions (logical operators)"""
        logic = condition.get('logic', 'and')
        subconditions = condition.get('conditions', [])
        
        if not subconditions:
            return False
        
        results = []
        for subcondition in subconditions:
            result = self._evaluate_rule_condition(subcondition, event_data)
            results.append(result)
        
        if logic == 'and':
            return all(results)
        elif logic == 'or':
            return any(results)
        elif logic == 'not':
            return not results[0] if results else False
        else:
            return False
    
    def _evaluate_pattern_condition(self, condition: Dict[str, Any], event_data: Dict[str, Any]) -> bool:
        """Evaluate pattern-based conditions"""
        import re
        
        field = condition.get('field')
        pattern = condition.get('pattern')
        flags = condition.get('flags', 0)
        
        if not field or not pattern:
            return False
        
        field_value = self._get_nested_value(event_data, field)
        if not field_value:
            return False
        
        try:
            return bool(re.search(pattern, str(field_value), flags))
        except re.error as e:
            self.logger.error(f"Invalid regex pattern: {pattern}, error: {e}")
            return False
    
    def _get_nested_value(self, data: Dict[str, Any], field_path: str) -> Any:
        """Get nested value from data using dot notation"""
        keys = field_path.split('.')
        value = data
        
        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                return None
        
        return value
    
    def _execute_policy_action(self, violation: PolicyViolation, action: PolicyAction):
        """Execute the specified policy action"""
        try:
            if action in self.violation_handlers:
                handler = self.violation_handlers[action]
                handler(violation)
            else:
                # Default actions
                if action == PolicyAction.LOG:
                    self.logger.warning(f"Policy violation: {violation.description}")
                elif action == PolicyAction.WARN:
                    self.logger.warning(f"Policy warning: {violation.description}")
                elif action == PolicyAction.DENY:
                    self.logger.error(f"Access denied: {violation.description}")
                elif action == PolicyAction.BLOCK:
                    self.logger.error(f"Blocked: {violation.description}")
                elif action == PolicyAction.QUARANTINE:
                    self.logger.error(f"Quarantined: {violation.description}")
            
            self.stats['actions_taken'] += 1
            
        except Exception as e:
            self.logger.error(f"Error executing policy action {action}: {e}")
    
    def register_violation_handler(self, action: PolicyAction, handler: Callable[[PolicyViolation], None]):
        """Register a custom violation handler"""
        self.violation_handlers[action] = handler
        self.logger.info(f"Registered violation handler for action: {action}")
    
    def _store_violation(self, violation: PolicyViolation):
        """Store policy violation in database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO policy_violations
                (violation_id, policy_id, rule_id, timestamp, source, severity,
                 description, action_taken, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                violation.violation_id,
                violation.policy_id,
                violation.rule_id,
                violation.timestamp.isoformat(),
                violation.source,
                violation.severity.value,
                violation.description,
                violation.action_taken.value,
                json.dumps(violation.metadata or {})
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Error storing violation: {e}")
    
    def _log_evaluation(self, source: str, violation_count: int, execution_time: float):
        """Log policy evaluation"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO policy_evaluations
                (evaluation_id, timestamp, policy_id, source, result, execution_time, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                str(uuid.uuid4()),
                datetime.now().isoformat(),
                'all',
                source,
                f"violations: {violation_count}",
                execution_time,
                json.dumps({'violation_count': violation_count})
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Error logging evaluation: {e}")
    
    def _generate_cache_key(self, event_data: Dict[str, Any], source: str) -> str:
        """Generate cache key for event data"""
        import hashlib
        
        cache_data = {
            'source': source,
            'event_hash': hashlib.md5(json.dumps(event_data, sort_keys=True).encode()).hexdigest()
        }
        
        return hashlib.md5(json.dumps(cache_data, sort_keys=True).encode()).hexdigest()
    
    def _get_cached_result(self, cache_key: str) -> Optional[List[PolicyViolation]]:
        """Get cached evaluation result"""
        if cache_key in self.evaluation_cache:
            cached_entry = self.evaluation_cache[cache_key]
            if datetime.now() - cached_entry['timestamp'] < timedelta(seconds=self.cache_ttl):
                return cached_entry['result']
            else:
                del self.evaluation_cache[cache_key]
        
        return None
    
    def _cache_result(self, cache_key: str, result: List[PolicyViolation]):
        """Cache evaluation result"""
        self.evaluation_cache[cache_key] = {
            'timestamp': datetime.now(),
            'result': result
        }
        
        # Clean old cache entries
        self._clean_cache()
    
    def _clean_cache(self):
        """Clean expired cache entries"""
        current_time = datetime.now()
        expired_keys = []
        
        for key, entry in self.evaluation_cache.items():
            if current_time - entry['timestamp'] > timedelta(seconds=self.cache_ttl):
                expired_keys.append(key)
        
        for key in expired_keys:
            del self.evaluation_cache[key]
    
    def _clear_policy_cache(self, policy_id: str):
        """Clear cache entries related to a specific policy"""
        # For simplicity, clear entire cache when policy changes
        self.evaluation_cache.clear()
    
    def get_policy_statistics(self) -> Dict[str, Any]:
        """Get policy enforcement statistics"""
        return {
            'total_policies': len(self.policies),
            'enabled_policies': sum(1 for p in self.policies.values() if p.enabled),
            'enforcement_enabled': self.enforcement_enabled,
            'statistics': self.stats,
            'cache_size': len(self.evaluation_cache)
        }
    
    def get_recent_violations(self, hours: int = 24) -> List[Dict[str, Any]]:
        """Get recent policy violations"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        since_time = (datetime.now() - timedelta(hours=hours)).isoformat()
        cursor.execute('''
            SELECT * FROM policy_violations 
            WHERE timestamp > ? 
            ORDER BY timestamp DESC
        ''', (since_time,))
        
        violations = []
        for row in cursor.fetchall():
            violations.append({
                'violation_id': row[0],
                'policy_id': row[1],
                'rule_id': row[2],
                'timestamp': row[3],
                'source': row[4],
                'severity': row[5],
                'description': row[6],
                'action_taken': row[7],
                'metadata': json.loads(row[8]) if row[8] else {}
            })
        
        conn.close()
        return violations
    
    def enable_enforcement(self):
        """Enable policy enforcement"""
        self.enforcement_enabled = True
        self.logger.info("Policy enforcement enabled")
    
    def disable_enforcement(self):
        """Disable policy enforcement"""
        self.enforcement_enabled = False
        self.logger.info("Policy enforcement disabled")
    
    def get_policy(self, policy_id: str) -> Optional[SecurityPolicy]:
        """Get a specific policy"""
        return self.policies.get(policy_id)
    
    def list_policies(self, policy_type: Optional[PolicyType] = None, enabled_only: bool = False) -> List[SecurityPolicy]:
        """List policies with optional filtering"""
        policies = list(self.policies.values())
        
        if policy_type:
            policies = [p for p in policies if p.policy_type == policy_type]
        
        if enabled_only:
            policies = [p for p in policies if p.enabled]
        
        return sorted(policies, key=lambda p: p.priority)
    
    def shutdown(self):
        """Shutdown the policy enforcement engine"""
        self.logger.info("Shutting down Policy Enforcement Engine")
        self.running = False
        self.evaluation_cache.clear()