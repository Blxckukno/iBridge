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