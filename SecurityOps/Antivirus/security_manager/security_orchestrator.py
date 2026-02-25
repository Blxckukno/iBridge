
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
Security Orchestrator
Coordinates security operations and automated responses
"""

import sqlite3
import threading
import time
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Callable, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum
import logging
import uuid

class OrchestrationStatus(Enum):
    """Orchestration workflow status"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

class ActionType(Enum):
    """Types of security actions"""
    SCAN = "scan"
    QUARANTINE = "quarantine"
    BLOCK = "block"
    ALERT = "alert"
    INVESTIGATE = "investigate"
    REMEDIATE = "remediate"
    BACKUP = "backup"
    ISOLATE = "isolate"

@dataclass
class SecurityAction:
    """Individual security action"""
    action_id: str
    action_type: ActionType
    target: str
    parameters: Dict[str, Any]
    priority: int = 5
    timeout: int = 300  # seconds
    retry_count: int = 3
    dependencies: Optional[List[str]] = field(default_factory=list)

@dataclass
class OrchestrationWorkflow:
    """Security orchestration workflow"""
    workflow_id: str
    workflow_name: str
    trigger_event: str
    actions: List[SecurityAction]
    status: OrchestrationStatus = OrchestrationStatus.PENDING
    created_time: Optional[datetime] = field(default_factory=datetime.now)
    started_time: Optional[datetime] = None
    completed_time: Optional[datetime] = None
    metadata: Optional[Dict[str, Any]] = None

class SecurityOrchestrator:
    """
    Advanced Security Orchestration System
    Coordinates automated security responses and workflows
    """
    
    def __init__(self, db_path: str = "security_orchestrator.db"):
        self.db_path = db_path
        self.workflows = {}
        self.action_handlers = {}
        self.running = False
        self.orchestration_thread = None
        self.active_workflows = {}
        
        # Initialize logging
        self.logger = logging.getLogger(__name__)
        
        # Initialize database
        self._init_database()
        
        # Load existing workflows
        self._load_workflows()
        
        # Performance metrics
        self.metrics = {
            'workflows_executed': 0,
            'actions_completed': 0,
            'actions_failed': 0,
            'average_execution_time': 0,
            'last_execution': None
        }
        
        # Initialize default workflows
        self._initialize_default_workflows()
        
        self.logger.info("Security Orchestrator initialized")
    
    def _init_database(self):
        """Initialize the orchestrator database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Workflows table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS workflows (
                workflow_id TEXT PRIMARY KEY,
                workflow_name TEXT NOT NULL,
                trigger_event TEXT NOT NULL,
                actions TEXT NOT NULL,
                status TEXT DEFAULT 'pending',
                created_time TEXT NOT NULL,
                started_time TEXT,
                completed_time TEXT,
                metadata TEXT
            )
        ''')
        
        # Workflow executions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS workflow_executions (
                execution_id TEXT PRIMARY KEY,
                workflow_id TEXT NOT NULL,
                trigger_data TEXT,
                status TEXT NOT NULL,
                start_time TEXT NOT NULL,
                end_time TEXT,
                result TEXT,
                error_message TEXT,
                FOREIGN KEY (workflow_id) REFERENCES workflows (workflow_id)
            )
        ''')
        
        # Action executions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS action_executions (
                execution_id TEXT PRIMARY KEY,
                workflow_execution_id TEXT NOT NULL,
                action_id TEXT NOT NULL,
                action_type TEXT NOT NULL,
                target TEXT NOT NULL,
                parameters TEXT,
                status TEXT NOT NULL,
                start_time TEXT NOT NULL,
                end_time TEXT,
                result TEXT,
                error_message TEXT,
                retry_count INTEGER DEFAULT 0
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def _load_workflows(self):
        """Load existing workflows from database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM workflows")
        for row in cursor.fetchall():
            actions_data = json.loads(row[3])
            actions = []
            
            for action_data in actions_data:
                action = SecurityAction(
                    action_id=action_data['action_id'],
                    action_type=ActionType(action_data['action_type']),
                    target=action_data['target'],
                    parameters=action_data['parameters'],
                    priority=action_data.get('priority', 5),
                    timeout=action_data.get('timeout', 300),
                    retry_count=action_data.get('retry_count', 3),
                    dependencies=action_data.get('dependencies', [])
                )
                actions.append(action)
            
            workflow = OrchestrationWorkflow(
                workflow_id=row[0],
                workflow_name=row[1],
                trigger_event=row[2],
                actions=actions,
                status=OrchestrationStatus(row[4]),
                created_time=datetime.fromisoformat(row[5]),
                started_time=datetime.fromisoformat(row[6]) if row[6] else None,
                completed_time=datetime.fromisoformat(row[7]) if row[7] else None,
                metadata=json.loads(row[8]) if row[8] else {}
            )
            
            self.workflows[workflow.workflow_id] = workflow
        
        conn.close()
        self.logger.info(f"Loaded {len(self.workflows)} orchestration workflows")
    
    def _initialize_default_workflows(self):
        """Initialize default security workflows"""
        default_workflows = [
            # Malware detection response
            {
                'workflow_name': 'Malware Detection Response',
                'trigger_event': 'malware_detected',
                'actions': [
                    {
                        'action_type': 'quarantine',
                        'target': 'file',
                        'parameters': {'reason': 'malware_detected'},
                        'priority': 1
                    },
                    {
                        'action_type': 'scan',
                        'target': 'system',
                        'parameters': {'scan_type': 'full'},
                        'priority': 2
                    },
                    {
                        'action_type': 'alert',
                        'target': 'admin',
                        'parameters': {'severity': 'high'},
                        'priority': 3
                    }
                ]
            },
            # Network intrusion response
            {
                'workflow_name': 'Network Intrusion Response',
                'trigger_event': 'network_intrusion',
                'actions': [
                    {
                        'action_type': 'block',
                        'target': 'ip_address',
                        'parameters': {'duration': 3600},
                        'priority': 1
                    },
                    {
                        'action_type': 'investigate',
                        'target': 'network_traffic',
                        'parameters': {'time_window': 3600},
                        'priority': 2
                    },
                    {
                        'action_type': 'alert',
                        'target': 'security_team',
                        'parameters': {'severity': 'critical'},
                        'priority': 3
                    }
                ]
            },
            # Ransomware response
            {
                'workflow_name': 'Ransomware Response',
                'trigger_event': 'ransomware_detected',
                'actions': [
                    {
                        'action_type': 'isolate',
                        'target': 'endpoint',
                        'parameters': {'immediate': True},
                        'priority': 1
                    },
                    {
                        'action_type': 'backup',
                        'target': 'critical_data',
                        'parameters': {'emergency': True},
                        'priority': 1
                    },
                    {
                        'action_type': 'alert',
                        'target': 'incident_response',
                        'parameters': {'severity': 'critical'},
                        'priority': 2
                    }
                ]
            }
        ]
        
        for workflow_config in default_workflows:
            if not any(w.workflow_name == workflow_config['workflow_name'] 
                      for w in self.workflows.values()):
                self.create_workflow_from_config(workflow_config)
    
    def create_workflow_from_config(self, config: Dict[str, Any]) -> Optional[str]:
        """Create workflow from configuration"""
        workflow_id = str(uuid.uuid4())
        
        actions = []
        for i, action_config in enumerate(config['actions']):
            action = SecurityAction(
                action_id=str(uuid.uuid4()),
                action_type=ActionType(action_config['action_type']),
                target=action_config['target'],
                parameters=action_config['parameters'],
                priority=action_config.get('priority', 5),
                timeout=action_config.get('timeout', 300),
                retry_count=action_config.get('retry_count', 3),
                dependencies=action_config.get('dependencies', [])
            )
            actions.append(action)
        
        workflow = OrchestrationWorkflow(
            workflow_id=workflow_id,
            workflow_name=config['workflow_name'],
            trigger_event=config['trigger_event'],
            actions=actions,
            created_time=datetime.now(),
            metadata=config.get('metadata', {})
        )
        
        if self.create_workflow(workflow):
            return workflow_id
        return None
    
    def create_workflow(self, workflow: OrchestrationWorkflow) -> bool:
        """Create a new orchestration workflow"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Convert actions to serializable format
            actions_data = []
            for action in workflow.actions:
                actions_data.append({
                    'action_id': action.action_id,
                    'action_type': action.action_type.value,
                    'target': action.target,
                    'parameters': action.parameters,
                    'priority': action.priority,
                    'timeout': action.timeout,
                    'retry_count': action.retry_count,
                    'dependencies': action.dependencies or []
                })
            
            cursor.execute('''
                INSERT INTO workflows
                (workflow_id, workflow_name, trigger_event, actions, status,
                 created_time, started_time, completed_time, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                workflow.workflow_id,
                workflow.workflow_name,
                workflow.trigger_event,
                json.dumps(actions_data),
                workflow.status.value,
                workflow.created_time.isoformat() if workflow.created_time else datetime.now().isoformat(),
                workflow.started_time.isoformat() if workflow.started_time else None,
                workflow.completed_time.isoformat() if workflow.completed_time else None,
                json.dumps(workflow.metadata or {})
            ))
            
            conn.commit()
            conn.close()
            
            # Add to memory
            self.workflows[workflow.workflow_id] = workflow
            
            self.logger.info(f"Created workflow: {workflow.workflow_name}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error creating workflow: {e}")
            return False
    
    def trigger_workflow(self, trigger_event: str, trigger_data: Dict[str, Any]) -> List[str]:
        """Trigger workflows based on event"""
        triggered_workflows = []
        
        for workflow in self.workflows.values():
            if workflow.trigger_event == trigger_event and workflow.status == OrchestrationStatus.PENDING:
                execution_id = self._execute_workflow(workflow, trigger_data)
                if execution_id:
                    triggered_workflows.append(execution_id)
        
        return triggered_workflows
    
    def _execute_workflow(self, workflow: OrchestrationWorkflow, trigger_data: Dict[str, Any]) -> Optional[str]:
        """Execute a workflow"""
        execution_id = str(uuid.uuid4())
        
        try:
            # Log workflow execution start
            self._log_workflow_execution(execution_id, workflow.workflow_id, trigger_data, 'running')
            
            workflow.status = OrchestrationStatus.RUNNING
            workflow.started_time = datetime.now()
            
            # Add to active workflows
            self.active_workflows[execution_id] = {
                'workflow': workflow,
                'trigger_data': trigger_data,
                'start_time': datetime.now(),
                'completed_actions': [],
                'failed_actions': []
            }
            
            # Execute workflow in background thread
            thread = threading.Thread(
                target=self._execute_workflow_thread,
                args=(execution_id, workflow, trigger_data),
                daemon=True
            )
            thread.start()
            
            return execution_id
            
        except Exception as e:
            self.logger.error(f"Error starting workflow execution: {e}")
            self._log_workflow_execution(execution_id, workflow.workflow_id, 
                                        trigger_data, 'failed', str(e))
            return None
    
    def _execute_workflow_thread(self, execution_id: str, workflow: OrchestrationWorkflow, 
                                trigger_data: Dict[str, Any]):
        """Execute workflow in separate thread"""
        start_time = time.time()
        
        try:
            # Sort actions by priority
            sorted_actions = sorted(workflow.actions, key=lambda a: a.priority)
            
            # Execute actions
            for action in sorted_actions:
                # Check dependencies
                if action.dependencies:
                    if not self._check_dependencies(execution_id, action.dependencies):
                        self.logger.warning(f"Skipping action {action.action_id} - dependencies not met")
                        continue
                
                # Execute action
                success = self._execute_action(execution_id, action, trigger_data)
                
                if success:
                    self.active_workflows[execution_id]['completed_actions'].append(action.action_id)
                else:
                    self.active_workflows[execution_id]['failed_actions'].append(action.action_id)
            
            # Determine final status
            failed_actions = self.active_workflows[execution_id]['failed_actions']
            if failed_actions:
                final_status = 'failed'
                result = f"Workflow completed with {len(failed_actions)} failed actions"
            else:
                final_status = 'completed'
                result = "Workflow completed successfully"
            
            # Update workflow status
            workflow.status = OrchestrationStatus.COMPLETED if final_status == 'completed' else OrchestrationStatus.FAILED
            workflow.completed_time = datetime.now()
            
            # Update metrics
            execution_time = time.time() - start_time
            self.metrics['workflows_executed'] += 1
            self.metrics['actions_completed'] += len(self.active_workflows[execution_id]['completed_actions'])
            self.metrics['actions_failed'] += len(failed_actions)
            self.metrics['average_execution_time'] = (
                (self.metrics['average_execution_time'] * (self.metrics['workflows_executed'] - 1) + execution_time) /
                self.metrics['workflows_executed']
            )
            self.metrics['last_execution'] = datetime.now().isoformat()
            
            # Log completion
            self._log_workflow_execution(execution_id, workflow.workflow_id, 
                                        trigger_data, final_status, None, result)
            
            # Clean up
            del self.active_workflows[execution_id]
            
            self.logger.info(f"Workflow {workflow.workflow_name} {final_status} in {execution_time:.2f}s")
            
        except Exception as e:
            self.logger.error(f"Error executing workflow {workflow.workflow_name}: {e}")
            workflow.status = OrchestrationStatus.FAILED
            workflow.completed_time = datetime.now()
            
            self._log_workflow_execution(execution_id, workflow.workflow_id, 
                                        trigger_data, 'failed', str(e))
            
            # Clean up
            if execution_id in self.active_workflows:
                del self.active_workflows[execution_id]
    
    def _execute_action(self, execution_id: str, action: SecurityAction, 
                       trigger_data: Dict[str, Any]) -> bool:
        """Execute a single action"""
        action_execution_id = str(uuid.uuid4())
        start_time = time.time()
        
        try:
            # Log action start
            self._log_action_execution(action_execution_id, execution_id, action, 'running')
            
            # Get action handler
            handler = self.action_handlers.get(action.action_type)
            if not handler:
                self.logger.error(f"No handler registered for action type: {action.action_type}")
                self._log_action_execution(action_execution_id, execution_id, action, 
                                         'failed', 'No handler registered')
                return False
            
            # Execute action with timeout
            result = self._execute_with_timeout(handler, action, trigger_data, action.timeout)
            
            execution_time = time.time() - start_time
            
            if result:
                self._log_action_execution(action_execution_id, execution_id, action, 
                                         'completed', None, str(result))
                self.logger.info(f"Action {action.action_type.value} completed in {execution_time:.2f}s")
                return True
            else:
                self._log_action_execution(action_execution_id, execution_id, action, 
                                         'failed', 'Action returned False')
                return False
                
        except Exception as e:
            self.logger.error(f"Error executing action {action.action_type}: {e}")
            self._log_action_execution(action_execution_id, execution_id, action, 
                                     'failed', str(e))
            return False
    
    def _execute_with_timeout(self, handler: Callable, action: SecurityAction, 
                            trigger_data: Dict[str, Any], timeout: int) -> Any:
        """Execute action handler with timeout"""
        import concurrent.futures
        
        with concurrent.futures.ThreadPoolExecutor() as executor:
            future = executor.submit(handler, action, trigger_data)
            try:
                return future.result(timeout=timeout)
            except concurrent.futures.TimeoutError:
                self.logger.error(f"Action {action.action_type} timed out after {timeout}s")
                return False
    
    def _check_dependencies(self, execution_id: str, dependencies: List[str]) -> bool:
        """Check if action dependencies are satisfied"""
        if execution_id not in self.active_workflows:
            return False
        
        completed_actions = self.active_workflows[execution_id]['completed_actions']
        return all(dep in completed_actions for dep in dependencies)
    
    def register_action_handler(self, action_type: ActionType, handler: Callable):
        """Register an action handler"""
        self.action_handlers[action_type] = handler
        self.logger.info(f"Registered handler for action type: {action_type}")
    
    def _log_workflow_execution(self, execution_id: str, workflow_id: str, 
                               trigger_data: Dict[str, Any], status: str,
                               error_message: Optional[str] = None, result: Optional[str] = None):
        """Log workflow execution"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            current_time = datetime.now().isoformat()
            
            if status == 'running':
                cursor.execute('''
                    INSERT INTO workflow_executions
                    (execution_id, workflow_id, trigger_data, status, start_time)
                    VALUES (?, ?, ?, ?, ?)
                ''', (execution_id, workflow_id, json.dumps(trigger_data), status, current_time))
            else:
                cursor.execute('''
                    UPDATE workflow_executions SET
                        status = ?, end_time = ?, result = ?, error_message = ?
                    WHERE execution_id = ?
                ''', (status, current_time, result, error_message, execution_id))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Error logging workflow execution: {e}")
    
    def _log_action_execution(self, action_execution_id: str, workflow_execution_id: str,
                            action: SecurityAction, status: str, error_message: Optional[str] = None,
                            result: Optional[str] = None):
        """Log action execution"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            current_time = datetime.now().isoformat()
            
            if status == 'running':
                cursor.execute('''
                    INSERT INTO action_executions
                    (execution_id, workflow_execution_id, action_id, action_type,
                     target, parameters, status, start_time)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    action_execution_id,
                    workflow_execution_id,
                    action.action_id,
                    action.action_type.value,
                    action.target,
                    json.dumps(action.parameters),
                    status,
                    current_time
                ))
            else:
                cursor.execute('''
                    UPDATE action_executions SET
                        status = ?, end_time = ?, result = ?, error_message = ?
                    WHERE execution_id = ?
                ''', (status, current_time, result, error_message, action_execution_id))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Error logging action execution: {e}")
    
    def get_workflow_status(self, workflow_id: str) -> Optional[Dict[str, Any]]:
        """Get workflow status"""
        if workflow_id in self.workflows:
            workflow = self.workflows[workflow_id]
            return {
                'workflow_id': workflow.workflow_id,
                'workflow_name': workflow.workflow_name,
                'status': workflow.status.value,
                'created_time': workflow.created_time.isoformat(),
                'started_time': workflow.started_time.isoformat() if workflow.started_time else None,
                'completed_time': workflow.completed_time.isoformat() if workflow.completed_time else None,
                'actions_count': len(workflow.actions)
            }
        return None
    
    def get_active_workflows(self) -> Dict[str, Any]:
        """Get currently active workflows"""
        active = {}
        for execution_id, workflow_info in self.active_workflows.items():
            active[execution_id] = {
                'workflow_name': workflow_info['workflow']['workflow_name'],
                'start_time': workflow_info['start_time'].isoformat(),
                'completed_actions': len(workflow_info['completed_actions']),
                'failed_actions': len(workflow_info['failed_actions']),
                'total_actions': len(workflow_info['workflow'].actions)
            }
        return active
    
    def get_orchestration_metrics(self) -> Dict[str, Any]:
        """Get orchestration metrics"""
        return {
            'total_workflows': len(self.workflows),
            'active_workflows': len(self.active_workflows),
            'registered_handlers': len(self.action_handlers),
            'performance_metrics': self.metrics
        }
    
    def cancel_workflow(self, execution_id: str) -> bool:
        """Cancel an active workflow"""
        if execution_id in self.active_workflows:
            workflow_info = self.active_workflows[execution_id]
            workflow_info['workflow'].status = OrchestrationStatus.CANCELLED
            
            # Log cancellation
            self._log_workflow_execution(execution_id, workflow_info['workflow'].workflow_id,
                                        workflow_info['trigger_data'], 'cancelled')
            
            # Clean up
            del self.active_workflows[execution_id]
            
            self.logger.info(f"Cancelled workflow execution: {execution_id}")
            return True
        
        return False
    
    def list_workflows(self, status_filter: Optional[OrchestrationStatus] = None) -> List[Dict[str, Any]]:
        """List workflows with optional status filter"""
        workflows = []
        
        for workflow in self.workflows.values():
            if status_filter is None or workflow.status == status_filter:
                workflows.append({
                    'workflow_id': workflow.workflow_id,
                    'workflow_name': workflow.workflow_name,
                    'trigger_event': workflow.trigger_event,
                    'status': workflow.status.value,
                    'actions_count': len(workflow.actions),
                    'created_time': workflow.created_time.isoformat()
                })
        
        return sorted(workflows, key=lambda w: w['created_time'], reverse=True)
    
    def get_recent_executions(self, hours: int = 24) -> List[Dict[str, Any]]:
        """Get recent workflow executions"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        since_time = (datetime.now() - timedelta(hours=hours)).isoformat()
        cursor.execute('''
            SELECT we.*, w.workflow_name FROM workflow_executions we
            JOIN workflows w ON we.workflow_id = w.workflow_id
            WHERE we.start_time > ?
            ORDER BY we.start_time DESC
        ''', (since_time,))
        
        executions = []
        for row in cursor.fetchall():
            executions.append({
                'execution_id': row[0],
                'workflow_id': row[1],
                'workflow_name': row[8],
                'trigger_data': json.loads(row[2]) if row[2] else {},
                'status': row[3],
                'start_time': row[4],
                'end_time': row[5],
                'result': row[6],
                'error_message': row[7]
            })
        
        conn.close()
        return executions
    
    def shutdown(self):
        """Shutdown the security orchestrator"""
        self.logger.info("Shutting down Security Orchestrator")
        self.running = False
        
        # Cancel all active workflows
        for execution_id in list(self.active_workflows.keys()):
            self.cancel_workflow(execution_id)
        
        self.workflows.clear()
        self.action_handlers.clear()