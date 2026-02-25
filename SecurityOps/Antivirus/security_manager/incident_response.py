
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
Incident Response Manager
Manages security incidents and automates response procedures
"""

import sqlite3
import threading
import time
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass
from enum import Enum
import logging
import uuid

class IncidentSeverity(Enum):
    """Incident severity levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class IncidentStatus(Enum):
    """Incident status"""
    NEW = "new"
    ASSIGNED = "assigned"
    INVESTIGATING = "investigating"
    CONTAINMENT = "containment"
    REMEDIATION = "remediation"
    RECOVERY = "recovery"
    CLOSED = "closed"

class IncidentCategory(Enum):
    """Incident categories"""
    MALWARE = "malware"
    PHISHING = "phishing"
    DATA_BREACH = "data_breach"
    DENIAL_OF_SERVICE = "denial_of_service"
    UNAUTHORIZED_ACCESS = "unauthorized_access"
    INSIDER_THREAT = "insider_threat"
    RANSOMWARE = "ransomware"
    NETWORK_INTRUSION = "network_intrusion"
    SYSTEM_COMPROMISE = "system_compromise"
    DATA_LOSS = "data_loss"

@dataclass
class SecurityIncident:
    """Security incident data structure"""
    incident_id: str
    title: str
    description: str
    severity: IncidentSeverity
    category: IncidentCategory
    status: IncidentStatus
    created_time: datetime
    updated_time: datetime
    assigned_to: Optional[str] = None
    affected_systems: Optional[List[str]] = None
    indicators: Optional[List[str]] = None
    timeline: Optional[List[Dict[str, Any]]] = None
    response_actions: Optional[List[str]] = None
    metadata: Optional[Dict[str, Any]] = None

@dataclass
class ResponseAction:
    """Incident response action"""
    action_id: str
    incident_id: str
    action_type: str
    description: str
    assigned_to: str
    due_date: datetime
    status: str
    created_time: datetime
    completed_time: Optional[datetime] = None
    result: Optional[str] = None

class IncidentResponseManager:
    """
    Advanced Incident Response Management System
    Manages security incidents and automates response procedures
    """
    
    def __init__(self, db_path: str = "incident_response.db"):
        self.db_path = db_path
        self.incidents = {}
        self.response_actions = {}
        self.playbooks = {}
        self.notification_handlers = []
        self.auto_response_enabled = True
        
        # Initialize logging
        self.logger = logging.getLogger(__name__)
        
        # Initialize database
        self._init_database()
        
        # Load existing data
        self._load_incidents()
        self._load_response_actions()
        self._load_playbooks()
        
        # Response metrics
        self.metrics = {
            'total_incidents': 0,
            'open_incidents': 0,
            'average_response_time': 0,
            'incidents_by_severity': {},
            'incidents_by_category': {},
            'mttr': 0,  # Mean Time To Resolution
            'last_incident': None
        }
        
        # Initialize default playbooks
        self._initialize_default_playbooks()
        
        self.logger.info("Incident Response Manager initialized")
    
    def _init_database(self):
        """Initialize the incident response database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Incidents table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS incidents (
                incident_id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT NOT NULL,
                severity TEXT NOT NULL,
                category TEXT NOT NULL,
                status TEXT NOT NULL,
                created_time TEXT NOT NULL,
                updated_time TEXT NOT NULL,
                assigned_to TEXT,
                affected_systems TEXT,
                indicators TEXT,
                timeline TEXT,
                response_actions TEXT,
                metadata TEXT
            )
        ''')
        
        # Response actions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS response_actions (
                action_id TEXT PRIMARY KEY,
                incident_id TEXT NOT NULL,
                action_type TEXT NOT NULL,
                description TEXT NOT NULL,
                assigned_to TEXT NOT NULL,
                due_date TEXT NOT NULL,
                status TEXT NOT NULL,
                created_time TEXT NOT NULL,
                completed_time TEXT,
                result TEXT,
                FOREIGN KEY (incident_id) REFERENCES incidents (incident_id)
            )
        ''')
        
        # Incident playbooks table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS incident_playbooks (
                playbook_id TEXT PRIMARY KEY,
                playbook_name TEXT NOT NULL,
                incident_category TEXT NOT NULL,
                severity_threshold TEXT NOT NULL,
                actions TEXT NOT NULL,
                enabled INTEGER DEFAULT 1,
                created_time TEXT NOT NULL,
                modified_time TEXT NOT NULL
            )
        ''')
        
        # Incident timeline table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS incident_timeline (
                timeline_id TEXT PRIMARY KEY,
                incident_id TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                event_type TEXT NOT NULL,
                description TEXT NOT NULL,
                user_id TEXT,
                metadata TEXT,
                FOREIGN KEY (incident_id) REFERENCES incidents (incident_id)
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def _load_incidents(self):
        """Load existing incidents from database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM incidents")
        for row in cursor.fetchall():
            incident = SecurityIncident(
                incident_id=row[0],
                title=row[1],
                description=row[2],
                severity=IncidentSeverity(row[3]),
                category=IncidentCategory(row[4]),
                status=IncidentStatus(row[5]),
                created_time=datetime.fromisoformat(row[6]),
                updated_time=datetime.fromisoformat(row[7]),
                assigned_to=row[8],
                affected_systems=json.loads(row[9]) if row[9] else [],
                indicators=json.loads(row[10]) if row[10] else [],
                timeline=json.loads(row[11]) if row[11] else [],
                response_actions=json.loads(row[12]) if row[12] else [],
                metadata=json.loads(row[13]) if row[13] else {}
            )
            
            self.incidents[incident.incident_id] = incident
        
        conn.close()
        self._update_metrics()
        self.logger.info(f"Loaded {len(self.incidents)} incidents")
    
    def _load_response_actions(self):
        """Load response actions from database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM response_actions")
        for row in cursor.fetchall():
            action = ResponseAction(
                action_id=row[0],
                incident_id=row[1],
                action_type=row[2],
                description=row[3],
                assigned_to=row[4],
                due_date=datetime.fromisoformat(row[5]),
                status=row[6],
                created_time=datetime.fromisoformat(row[7]),
                completed_time=datetime.fromisoformat(row[8]) if row[8] else None,
                result=row[9]
            )
            
            self.response_actions[action.action_id] = action
        
        conn.close()
        self.logger.info(f"Loaded {len(self.response_actions)} response actions")
    
    def _load_playbooks(self):
        """Load incident response playbooks"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM incident_playbooks WHERE enabled = 1")
        for row in cursor.fetchall():
            playbook = {
                'playbook_id': row[0],
                'playbook_name': row[1],
                'incident_category': IncidentCategory(row[2]),
                'severity_threshold': IncidentSeverity(row[3]),
                'actions': json.loads(row[4]),
                'enabled': bool(row[5]),
                'created_time': datetime.fromisoformat(row[6]),
                'modified_time': datetime.fromisoformat(row[7])
            }
            
            self.playbooks[playbook['playbook_id']] = playbook
        
        conn.close()
        self.logger.info(f"Loaded {len(self.playbooks)} incident response playbooks")
    
    def _initialize_default_playbooks(self):
        """Initialize default incident response playbooks"""
        default_playbooks = [
            {
                'playbook_name': 'Malware Incident Response',
                'incident_category': 'malware',
                'severity_threshold': 'medium',
                'actions': [
                    {
                        'action_type': 'containment',
                        'description': 'Isolate infected systems',
                        'priority': 1,
                        'estimated_time': 30
                    },
                    {
                        'action_type': 'analysis',
                        'description': 'Analyze malware sample',
                        'priority': 2,
                        'estimated_time': 120
                    },
                    {
                        'action_type': 'eradication',
                        'description': 'Remove malware from systems',
                        'priority': 3,
                        'estimated_time': 60
                    },
                    {
                        'action_type': 'recovery',
                        'description': 'Restore systems from clean backups',
                        'priority': 4,
                        'estimated_time': 180
                    }
                ]
            },
            {
                'playbook_name': 'Ransomware Incident Response',
                'incident_category': 'ransomware',
                'severity_threshold': 'high',
                'actions': [
                    {
                        'action_type': 'emergency_isolation',
                        'description': 'Immediately isolate all affected systems',
                        'priority': 1,
                        'estimated_time': 10
                    },
                    {
                        'action_type': 'backup_verification',
                        'description': 'Verify integrity of backup systems',
                        'priority': 1,
                        'estimated_time': 30
                    },
                    {
                        'action_type': 'law_enforcement',
                        'description': 'Contact law enforcement if required',
                        'priority': 2,
                        'estimated_time': 60
                    },
                    {
                        'action_type': 'decryption_analysis',
                        'description': 'Analyze ransomware for decryption possibilities',
                        'priority': 3,
                        'estimated_time': 240
                    }
                ]
            },
            {
                'playbook_name': 'Data Breach Response',
                'incident_category': 'data_breach',
                'severity_threshold': 'high',
                'actions': [
                    {
                        'action_type': 'breach_assessment',
                        'description': 'Assess scope and impact of data breach',
                        'priority': 1,
                        'estimated_time': 60
                    },
                    {
                        'action_type': 'regulatory_notification',
                        'description': 'Notify regulatory authorities if required',
                        'priority': 2,
                        'estimated_time': 120
                    },
                    {
                        'action_type': 'customer_notification',
                        'description': 'Prepare customer notification if required',
                        'priority': 3,
                        'estimated_time': 180
                    },
                    {
                        'action_type': 'forensic_investigation',
                        'description': 'Conduct detailed forensic investigation',
                        'priority': 4,
                        'estimated_time': 480
                    }
                ]
            }
        ]
        
        for playbook_config in default_playbooks:
            if not any(p['playbook_name'] == playbook_config['playbook_name'] 
                      for p in self.playbooks.values()):
                self.create_playbook(playbook_config)
    
    def create_incident(self, incident: SecurityIncident) -> bool:
        """Create a new security incident"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO incidents
                (incident_id, title, description, severity, category, status,
                 created_time, updated_time, assigned_to, affected_systems,
                 indicators, timeline, response_actions, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                incident.incident_id,
                incident.title,
                incident.description,
                incident.severity.value,
                incident.category.value,
                incident.status.value,
                incident.created_time.isoformat(),
                incident.updated_time.isoformat(),
                incident.assigned_to,
                json.dumps(incident.affected_systems or []),
                json.dumps(incident.indicators or []),
                json.dumps(incident.timeline or []),
                json.dumps(incident.response_actions or []),
                json.dumps(incident.metadata or {})
            ))
            
            conn.commit()
            conn.close()
            
            # Add to memory
            self.incidents[incident.incident_id] = incident
            
            # Add initial timeline entry
            self.add_timeline_entry(incident.incident_id, 'incident_created', 
                                  'Incident created', 'system')
            
            # Trigger automatic response if enabled
            if self.auto_response_enabled:
                self._trigger_automatic_response(incident)
            
            # Send notifications
            self._send_notifications(incident, 'incident_created')
            
            # Update metrics
            self._update_metrics()
            
            self.logger.info(f"Created incident: {incident.title}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error creating incident: {e}")
            return False
    
    def update_incident(self, incident_id: str, updates: Dict[str, Any]) -> bool:
        """Update an existing incident"""
        if incident_id not in self.incidents:
            return False
        
        try:
            incident = self.incidents[incident_id]
            old_status = incident.status
            
            # Apply updates
            for field, value in updates.items():
                if hasattr(incident, field):
                    if field == 'severity':
                        incident.severity = IncidentSeverity(value)
                    elif field == 'category':
                        incident.category = IncidentCategory(value)
                    elif field == 'status':
                        incident.status = IncidentStatus(value)
                    else:
                        setattr(incident, field, value)
            
            incident.updated_time = datetime.now()
            
            # Update database
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                UPDATE incidents SET
                    title = ?, description = ?, severity = ?, category = ?,
                    status = ?, updated_time = ?, assigned_to = ?,
                    affected_systems = ?, indicators = ?, timeline = ?,
                    response_actions = ?, metadata = ?
                WHERE incident_id = ?
            ''', (
                incident.title,
                incident.description,
                incident.severity.value,
                incident.category.value,
                incident.status.value,
                incident.updated_time.isoformat(),
                incident.assigned_to,
                json.dumps(incident.affected_systems or []),
                json.dumps(incident.indicators or []),
                json.dumps(incident.timeline or []),
                json.dumps(incident.response_actions or []),
                json.dumps(incident.metadata or {}),
                incident_id
            ))
            
            conn.commit()
            conn.close()
            
            # Add timeline entry for status change
            if 'status' in updates and old_status != incident.status:
                self.add_timeline_entry(incident_id, 'status_change', 
                                      f"Status changed from {old_status.value} to {incident.status.value}",
                                      updates.get('updated_by', 'system'))
            
            # Send notifications
            self._send_notifications(incident, 'incident_updated')
            
            # Update metrics
            self._update_metrics()
            
            self.logger.info(f"Updated incident: {incident.title}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error updating incident: {e}")
            return False
    
    def add_timeline_entry(self, incident_id: str, event_type: str, description: str, 
                          user_id: str, metadata: Optional[Dict[str, Any]] = None) -> bool:
        """Add an entry to incident timeline"""
        try:
            timeline_id = str(uuid.uuid4())
            timestamp = datetime.now()
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO incident_timeline
                (timeline_id, incident_id, timestamp, event_type, description, user_id, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                timeline_id,
                incident_id,
                timestamp.isoformat(),
                event_type,
                description,
                user_id,
                json.dumps(metadata or {})
            ))
            
            conn.commit()
            conn.close()
            
            # Update incident timeline in memory
            if incident_id in self.incidents:
                if not self.incidents[incident_id].timeline:
                    self.incidents[incident_id].timeline = []
                
                self.incidents[incident_id].timeline.append({
                    'timeline_id': timeline_id,
                    'timestamp': timestamp.isoformat(),
                    'event_type': event_type,
                    'description': description,
                    'user_id': user_id,
                    'metadata': metadata or {}
                })
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error adding timeline entry: {e}")
            return False
    
    def create_response_action(self, action: ResponseAction) -> bool:
        """Create a response action for an incident"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO response_actions
                (action_id, incident_id, action_type, description, assigned_to,
                 due_date, status, created_time, completed_time, result)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                action.action_id,
                action.incident_id,
                action.action_type,
                action.description,
                action.assigned_to,
                action.due_date.isoformat(),
                action.status,
                action.created_time.isoformat(),
                action.completed_time.isoformat() if action.completed_time else None,
                action.result
            ))
            
            conn.commit()
            conn.close()
            
            # Add to memory
            self.response_actions[action.action_id] = action
            
            # Update incident response actions list
            if action.incident_id in self.incidents:
                if not self.incidents[action.incident_id].response_actions:
                    self.incidents[action.incident_id].response_actions = []
                
                self.incidents[action.incident_id].response_actions.append(action.action_id)
            
            # Add timeline entry
            self.add_timeline_entry(action.incident_id, 'action_created',
                                  f"Response action created: {action.description}",
                                  action.assigned_to)
            
            self.logger.info(f"Created response action: {action.description}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error creating response action: {e}")
            return False
    
    def _trigger_automatic_response(self, incident: SecurityIncident):
        """Trigger automatic response based on incident"""
        # Find matching playbook
        matching_playbooks = []
        
        for playbook in self.playbooks.values():
            if (playbook['incident_category'] == incident.category and
                self._severity_meets_threshold(incident.severity, playbook['severity_threshold'])):
                matching_playbooks.append(playbook)
        
        # Use the most appropriate playbook (could be enhanced with more logic)
        if matching_playbooks:
            playbook = matching_playbooks[0]
            self._execute_playbook(incident, playbook)
    
    def _severity_meets_threshold(self, incident_severity: IncidentSeverity, 
                                 threshold: IncidentSeverity) -> bool:
        """Check if incident severity meets playbook threshold"""
        severity_order = {
            IncidentSeverity.LOW: 1,
            IncidentSeverity.MEDIUM: 2,
            IncidentSeverity.HIGH: 3,
            IncidentSeverity.CRITICAL: 4
        }
        
        return severity_order[incident_severity] >= severity_order[threshold]
    
    def _execute_playbook(self, incident: SecurityIncident, playbook: Dict[str, Any]):
        """Execute incident response playbook"""
        self.logger.info(f"Executing playbook: {playbook['playbook_name']} for incident {incident.title}")
        
        # Add timeline entry
        self.add_timeline_entry(incident.incident_id, 'playbook_executed',
                              f"Executing playbook: {playbook['playbook_name']}",
                              'system')
        
        # Create response actions from playbook
        for action_config in playbook['actions']:
            action = ResponseAction(
                action_id=str(uuid.uuid4()),
                incident_id=incident.incident_id,
                action_type=action_config['action_type'],
                description=action_config['description'],
                assigned_to='auto_response',
                due_date=datetime.now() + timedelta(minutes=action_config.get('estimated_time', 60)),
                status='assigned',
                created_time=datetime.now()
            )
            
            self.create_response_action(action)
    
    def create_playbook(self, playbook_config: Dict[str, Any]) -> Optional[str]:
        """Create a new incident response playbook"""
        playbook_id = str(uuid.uuid4())
        current_time = datetime.now()
        
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO incident_playbooks
                (playbook_id, playbook_name, incident_category, severity_threshold,
                 actions, enabled, created_time, modified_time)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                playbook_id,
                playbook_config['playbook_name'],
                playbook_config['incident_category'],
                playbook_config['severity_threshold'],
                json.dumps(playbook_config['actions']),
                1,
                current_time.isoformat(),
                current_time.isoformat()
            ))
            
            conn.commit()
            conn.close()
            
            # Add to memory
            playbook = {
                'playbook_id': playbook_id,
                'playbook_name': playbook_config['playbook_name'],
                'incident_category': IncidentCategory(playbook_config['incident_category']),
                'severity_threshold': IncidentSeverity(playbook_config['severity_threshold']),
                'actions': playbook_config['actions'],
                'enabled': True,
                'created_time': current_time,
                'modified_time': current_time
            }
            
            self.playbooks[playbook_id] = playbook
            
            self.logger.info(f"Created incident response playbook: {playbook_config['playbook_name']}")
            return playbook_id
            
        except Exception as e:
            self.logger.error(f"Error creating playbook: {e}")
            return None
    
    def _send_notifications(self, incident: SecurityIncident, event_type: str):
        """Send notifications for incident events"""
        for handler in self.notification_handlers:
            try:
                handler(incident, event_type)
            except Exception as e:
                self.logger.error(f"Error sending notification: {e}")
    
    def add_notification_handler(self, handler: Callable):
        """Add notification handler"""
        self.notification_handlers.append(handler)
        self.logger.info("Added notification handler")
    
    def _update_metrics(self):
        """Update incident response metrics"""
        # Count incidents by status
        open_statuses = [IncidentStatus.NEW, IncidentStatus.ASSIGNED, 
                        IncidentStatus.INVESTIGATING, IncidentStatus.CONTAINMENT,
                        IncidentStatus.REMEDIATION, IncidentStatus.RECOVERY]
        
        self.metrics['total_incidents'] = len(self.incidents)
        self.metrics['open_incidents'] = sum(1 for i in self.incidents.values() 
                                           if i.status in open_statuses)
        
        # Count by severity
        severity_counts = {}
        for incident in self.incidents.values():
            severity = incident.severity.value
            severity_counts[severity] = severity_counts.get(severity, 0) + 1
        self.metrics['incidents_by_severity'] = severity_counts
        
        # Count by category
        category_counts = {}
        for incident in self.incidents.values():
            category = incident.category.value
            category_counts[category] = category_counts.get(category, 0) + 1
        self.metrics['incidents_by_category'] = category_counts
        
        # Calculate MTTR for closed incidents
        closed_incidents = [i for i in self.incidents.values() if i.status == IncidentStatus.CLOSED]
        if closed_incidents:
            total_resolution_time = sum(
                (i.updated_time - i.created_time).total_seconds() 
                for i in closed_incidents
            )
            self.metrics['mttr'] = total_resolution_time / len(closed_incidents) / 3600  # in hours
        
        # Update last incident time
        if self.incidents:
            latest_incident = max(self.incidents.values(), key=lambda i: i.created_time)
            self.metrics['last_incident'] = latest_incident.created_time.isoformat()
    
    def get_incident_dashboard(self) -> Dict[str, Any]:
        """Get incident response dashboard data"""
        return {
            'metrics': self.metrics,
            'open_incidents': [
                {
                    'incident_id': i.incident_id,
                    'title': i.title,
                    'severity': i.severity.value,
                    'status': i.status.value,
                    'created_time': i.created_time.isoformat(),
                    'assigned_to': i.assigned_to
                }
                for i in self.incidents.values()
                if i.status != IncidentStatus.CLOSED
            ],
            'recent_incidents': sorted([
                {
                    'incident_id': i.incident_id,
                    'title': i.title,
                    'severity': i.severity.value,
                    'status': i.status.value,
                    'created_time': i.created_time.isoformat()
                }
                for i in self.incidents.values()
            ], key=lambda x: x['created_time'], reverse=True)[:10]
        }
    
    def get_incident(self, incident_id: str) -> Optional[SecurityIncident]:
        """Get incident by ID"""
        return self.incidents.get(incident_id)
    
    def search_incidents(self, filters: Dict[str, Any]) -> List[SecurityIncident]:
        """Search incidents with filters"""
        results = []
        
        for incident in self.incidents.values():
            match = True
            
            if 'severity' in filters and incident.severity.value != filters['severity']:
                match = False
            
            if 'category' in filters and incident.category.value != filters['category']:
                match = False
            
            if 'status' in filters and incident.status.value != filters['status']:
                match = False
            
            if 'assigned_to' in filters and incident.assigned_to != filters['assigned_to']:
                match = False
            
            if 'date_range' in filters:
                start_date = datetime.fromisoformat(filters['date_range']['start'])
                end_date = datetime.fromisoformat(filters['date_range']['end'])
                if not (start_date <= incident.created_time <= end_date):
                    match = False
            
            if 'search_text' in filters:
                search_text = filters['search_text'].lower()
                if not (search_text in incident.title.lower() or 
                       search_text in incident.description.lower()):
                    match = False
            
            if match:
                results.append(incident)
        
        return results
    
    def get_incident_timeline(self, incident_id: str) -> List[Dict[str, Any]]:
        """Get incident timeline"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT * FROM incident_timeline 
            WHERE incident_id = ? 
            ORDER BY timestamp
        ''', (incident_id,))
        
        timeline = []
        for row in cursor.fetchall():
            timeline.append({
                'timeline_id': row[0],
                'incident_id': row[1],
                'timestamp': row[2],
                'event_type': row[3],
                'description': row[4],
                'user_id': row[5],
                'metadata': json.loads(row[6]) if row[6] else {}
            })
        
        conn.close()
        return timeline
    
    def get_response_actions(self, incident_id: str) -> List[ResponseAction]:
        """Get response actions for incident"""
        return [action for action in self.response_actions.values() 
                if action.incident_id == incident_id]
    
    def complete_response_action(self, action_id: str, result: str) -> bool:
        """Mark response action as completed"""
        if action_id not in self.response_actions:
            return False
        
        try:
            action = self.response_actions[action_id]
            action.status = 'completed'
            action.completed_time = datetime.now()
            action.result = result
            
            # Update database
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                UPDATE response_actions SET
                    status = ?, completed_time = ?, result = ?
                WHERE action_id = ?
            ''', ('completed', action.completed_time.isoformat(), result, action_id))
            
            conn.commit()
            conn.close()
            
            # Add timeline entry
            self.add_timeline_entry(action.incident_id, 'action_completed',
                                  f"Response action completed: {action.description}",
                                  action.assigned_to)
            
            self.logger.info(f"Completed response action: {action.description}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error completing response action: {e}")
            return False
    
    def get_incident_statistics(self) -> Dict[str, Any]:
        """Get detailed incident statistics"""
        return {
            'total_incidents': len(self.incidents),
            'open_incidents': self.metrics['open_incidents'],
            'closed_incidents': len(self.incidents) - self.metrics['open_incidents'],
            'by_severity': self.metrics['incidents_by_severity'],
            'by_category': self.metrics['incidents_by_category'],
            'mttr_hours': self.metrics['mttr'],
            'active_playbooks': len(self.playbooks),
            'total_response_actions': len(self.response_actions),
            'completed_actions': sum(1 for a in self.response_actions.values() 
                                   if a.status == 'completed')
        }
    
    def shutdown(self):
        """Shutdown the incident response manager"""
        self.logger.info("Shutting down Incident Response Manager")
        self.incidents.clear()
        self.response_actions.clear()
        self.playbooks.clear()
        self.notification_handlers.clear()