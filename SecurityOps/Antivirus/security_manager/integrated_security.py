
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
Security Manager Integration
Main entry point for the centralized security management system
"""

import logging
import threading
import time
from datetime import datetime
from typing import Dict, List, Any, Optional

from .centralized_security_manager import CentralizedSecurityManager, SecurityEvent, SecurityLevel, ThreatCategory
from .policy_enforcement import PolicyEnforcementEngine, SecurityPolicy, PolicyViolation
from .threat_intelligence import ThreatIntelligenceManager, ThreatIndicator
from .security_orchestrator import SecurityOrchestrator, OrchestrationWorkflow
from .incident_response import IncidentResponseManager, SecurityIncident

class IntegratedSecurityManager:
    """
    Integrated Security Management System
    Combines all security management components into a unified system
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        self.config = config or {}
        
        # Initialize logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('integrated_security.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        # Initialize core components
        self.security_manager = CentralizedSecurityManager()
        self.policy_engine = PolicyEnforcementEngine()
        self.threat_intelligence = ThreatIntelligenceManager()
        self.orchestrator = SecurityOrchestrator()
        self.incident_manager = IncidentResponseManager()
        
        # Integration state
        self.running = False
        self.integration_thread = None
        
        # Setup integrations
        self._setup_integrations()
        
        self.logger.info("Integrated Security Manager initialized")
    
    def _setup_integrations(self):
        """Setup integrations between components"""
        
        # Register security systems with central manager
        self.security_manager.register_security_system('policy_engine', self.policy_engine, priority=1)
        self.security_manager.register_security_system('threat_intelligence', self.threat_intelligence, priority=2)
        self.security_manager.register_security_system('orchestrator', self.orchestrator, priority=3)
        self.security_manager.register_security_system('incident_manager', self.incident_manager, priority=4)
        
        # Setup alert handlers
        self.security_manager.add_alert_handler(self._handle_security_alert)
        
        # Setup orchestrator action handlers
        self._register_orchestrator_handlers()
        
        # Setup incident notification handlers
        self.incident_manager.add_notification_handler(self._handle_incident_notification)
        
        # Setup policy violation handlers
        self._register_policy_handlers()
    
    def _register_orchestrator_handlers(self):
        """Register orchestrator action handlers"""
        from .security_orchestrator import ActionType
        
        # Quarantine action handler
        def quarantine_handler(action, trigger_data):
            try:
                # Implementation would integrate with quarantine system
                self.logger.info(f"Executing quarantine action: {action.target}")
                return True
            except Exception as e:
                self.logger.error(f"Quarantine action failed: {e}")
                return False
        
        # Block action handler
        def block_handler(action, trigger_data):
            try:
                # Implementation would integrate with firewall
                self.logger.info(f"Executing block action: {action.target}")
                return True
            except Exception as e:
                self.logger.error(f"Block action failed: {e}")
                return False
        
        # Scan action handler
        def scan_handler(action, trigger_data):
            try:
                # Implementation would integrate with scanner
                self.logger.info(f"Executing scan action: {action.target}")
                return True
            except Exception as e:
                self.logger.error(f"Scan action failed: {e}")
                return False
        
        # Alert action handler
        def alert_handler(action, trigger_data):
            try:
                # Create incident for high-priority alerts
                if action.parameters.get('severity') in ['high', 'critical']:
                    incident = self._create_incident_from_action(action, trigger_data)
                    self.incident_manager.create_incident(incident)
                
                self.logger.warning(f"Security alert: {action.target}")
                return True
            except Exception as e:
                self.logger.error(f"Alert action failed: {e}")
                return False
        
        # Register handlers
        self.orchestrator.register_action_handler(ActionType.QUARANTINE, quarantine_handler)
        self.orchestrator.register_action_handler(ActionType.BLOCK, block_handler)
        self.orchestrator.register_action_handler(ActionType.SCAN, scan_handler)
        self.orchestrator.register_action_handler(ActionType.ALERT, alert_handler)
    
    def _register_policy_handlers(self):
        """Register policy violation handlers"""
        from .policy_enforcement import PolicyAction
        
        def quarantine_violation_handler(violation):
            # Trigger orchestration workflow for quarantine
            trigger_data = {
                'violation_id': violation.violation_id,
                'policy_id': violation.policy_id,
                'source': violation.source,
                'metadata': violation.metadata
            }
            self.orchestrator.trigger_workflow('policy_violation_quarantine', trigger_data)
        
        def block_violation_handler(violation):
            # Trigger orchestration workflow for blocking
            trigger_data = {
                'violation_id': violation.violation_id,
                'policy_id': violation.policy_id,
                'source': violation.source,
                'metadata': violation.metadata
            }
            self.orchestrator.trigger_workflow('policy_violation_block', trigger_data)
        
        # Register handlers
        self.policy_engine.register_violation_handler(PolicyAction.QUARANTINE, quarantine_violation_handler)
        self.policy_engine.register_violation_handler(PolicyAction.BLOCK, block_violation_handler)
    
    def _handle_security_alert(self, event: SecurityEvent):
        """Handle security alerts from central manager"""
        try:
            # Evaluate policies
            event_data = {
                'event_type': event.event_type,
                'severity': event.severity.value,
                'source': event.source,
                'description': event.description,
                'affected_systems': event.affected_systems,
                'threat_category': event.threat_category.value if event.threat_category else None,
                'metadata': event.metadata or {}
            }
            
            violations = self.policy_engine.evaluate_policies(event_data, event.source)
            
            # Check threat intelligence
            if event.threat_category:
                # Look for relevant threat indicators
                # Convert ThreatCategory to compatible ThreatType value
                threat_type_value = None
                if event.threat_category:
                    try:
                        # Try to match compatible values between ThreatCategory and ThreatType
                        from .threat_intelligence import ThreatType
                        threat_type_value = ThreatType(event.threat_category.value)
                    except ValueError:
                        # No direct mapping available, pass None
                        threat_type_value = None
                
                indicators = self.threat_intelligence.search_indicators(
                    event.description,
                    threat_type=threat_type_value
                )
                
                if indicators:
                    self.logger.info(f"Found {len(indicators)} threat indicators for event {event.event_id}")
            
            # Trigger orchestration if high severity
            if event.severity in [SecurityLevel.HIGH, SecurityLevel.CRITICAL]:
                trigger_data = {
                    'event_id': event.event_id,
                    'event_type': event.event_type,
                    'severity': event.severity.value,
                    'source': event.source,
                    'affected_systems': event.affected_systems,
                    'metadata': event.metadata or {}
                }
                
                # Determine workflow based on threat category
                workflow_event = 'security_incident'
                if event.threat_category == ThreatCategory.MALWARE:
                    workflow_event = 'malware_detected'
                elif event.threat_category == ThreatCategory.RANSOMWARE:
                    workflow_event = 'ransomware_detected'
                elif event.threat_category == ThreatCategory.NETWORK_INTRUSION:
                    workflow_event = 'network_intrusion'
                
                self.orchestrator.trigger_workflow(workflow_event, trigger_data)
            
            # Create incident for critical events
            if event.severity == SecurityLevel.CRITICAL:
                incident = self._create_incident_from_event(event)
                self.incident_manager.create_incident(incident)
            
        except Exception as e:
            self.logger.error(f"Error handling security alert: {e}")
    
    def _handle_incident_notification(self, incident: SecurityIncident, event_type: str):
        """Handle incident notifications"""
        try:
            # Log incident event
            self.logger.info(f"Incident {event_type}: {incident.title} (Severity: {incident.severity.value})")
            
            # Report to security manager
            security_event = SecurityEvent(
                event_id=f"incident_{incident.incident_id}",
                timestamp=datetime.now(),
                event_type=f"incident_{event_type}",
                severity=SecurityLevel(incident.severity.value),
                source='incident_manager',
                description=f"Incident {event_type}: {incident.title}",
                affected_systems=incident.affected_systems or [],
                threat_category=ThreatCategory(incident.category.value) if hasattr(ThreatCategory, incident.category.value.upper()) else None,
                metadata={'incident_id': incident.incident_id}
            )
            
            self.security_manager.report_security_event(security_event)
            
        except Exception as e:
            self.logger.error(f"Error handling incident notification: {e}")
    
    def _create_incident_from_event(self, event: SecurityEvent) -> SecurityIncident:
        """Create incident from security event"""
        from .incident_response import IncidentSeverity, IncidentCategory, IncidentStatus
        import uuid
        
        # Map security levels to incident severity
        severity_mapping = {
            SecurityLevel.LOW: IncidentSeverity.LOW,
            SecurityLevel.MEDIUM: IncidentSeverity.MEDIUM,
            SecurityLevel.HIGH: IncidentSeverity.HIGH,
            SecurityLevel.CRITICAL: IncidentSeverity.CRITICAL
        }
        
        # Map threat categories to incident categories
        category_mapping = {
            ThreatCategory.MALWARE: IncidentCategory.MALWARE,
            ThreatCategory.RANSOMWARE: IncidentCategory.RANSOMWARE,
            ThreatCategory.PHISHING: IncidentCategory.PHISHING,
            ThreatCategory.NETWORK_INTRUSION: IncidentCategory.NETWORK_INTRUSION,
            ThreatCategory.DATA_BREACH: IncidentCategory.DATA_BREACH,
            ThreatCategory.UNAUTHORIZED_ACCESS: IncidentCategory.UNAUTHORIZED_ACCESS
        }
        
        incident = SecurityIncident(
            incident_id=str(uuid.uuid4()),
            title=f"Security Event: {event.event_type}",
            description=event.description,
            severity=severity_mapping.get(event.severity, IncidentSeverity.MEDIUM),
            category=category_mapping.get(event.threat_category if event.threat_category else ThreatCategory.SUSPICIOUS_BEHAVIOR, IncidentCategory.SYSTEM_COMPROMISE),
            status=IncidentStatus.NEW,
            created_time=event.timestamp,
            updated_time=event.timestamp,
            affected_systems=event.affected_systems,
            metadata={'source_event_id': event.event_id, 'source': event.source}
        )
        
        return incident
    
    def _create_incident_from_action(self, action, trigger_data) -> SecurityIncident:
        """Create incident from orchestrator action"""
        from .incident_response import IncidentSeverity, IncidentCategory, IncidentStatus
        import uuid
        
        # Determine severity from action parameters
        severity_str = action.parameters.get('severity', 'medium')
        severity_mapping = {
            'low': IncidentSeverity.LOW,
            'medium': IncidentSeverity.MEDIUM,
            'high': IncidentSeverity.HIGH,
            'critical': IncidentSeverity.CRITICAL
        }
        
        incident = SecurityIncident(
            incident_id=str(uuid.uuid4()),
            title=f"Security Alert: {action.target}",
            description=f"Alert triggered for {action.target}",
            severity=severity_mapping.get(severity_str, IncidentSeverity.MEDIUM),
            category=IncidentCategory.SYSTEM_COMPROMISE,
            status=IncidentStatus.NEW,
            created_time=datetime.now(),
            updated_time=datetime.now(),
            metadata={'action_id': action.action_id, 'trigger_data': trigger_data}
        )
        
        return incident
    
    def start(self):
        """Start the integrated security management system"""
        if self.running:
            return
        
        self.running = True
        
        # Start all components
        self.security_manager.start_monitoring()
        self.threat_intelligence.start_feed_updates()
        
        # Start integration monitoring
        self.integration_thread = threading.Thread(target=self._integration_loop, daemon=True)
        self.integration_thread.start()
        
        self.logger.info("Integrated Security Manager started")
    
    def stop(self):
        """Stop the integrated security management system"""
        if not self.running:
            return
        
        self.running = False
        
        # Stop all components
        self.security_manager.stop_monitoring()
        self.threat_intelligence.stop_feed_updates()
        
        # Wait for integration thread
        if self.integration_thread:
            self.integration_thread.join(timeout=10)
        
        self.logger.info("Integrated Security Manager stopped")
    
    def _integration_loop(self):
        """Main integration monitoring loop"""
        while self.running:
            try:
                # Periodic integration tasks
                self._sync_threat_intelligence()
                self._update_security_metrics()
                
                # Sleep for 5 minutes
                time.sleep(300)
                
            except Exception as e:
                self.logger.error(f"Error in integration loop: {e}")
                time.sleep(60)
    
    def _sync_threat_intelligence(self):
        """Sync threat intelligence with other components"""
        try:
            # Get recent threat indicators
            stats = self.threat_intelligence.get_threat_statistics()
            
            # Update security manager with threat intel stats
            self.security_manager.metrics['threat_indicators'] = stats['total_indicators']
            
        except Exception as e:
            self.logger.error(f"Error syncing threat intelligence: {e}")
    
    def _update_security_metrics(self):
        """Update integrated security metrics"""
        try:
            # Collect metrics from all components
            security_metrics = self.security_manager.get_security_status()
            policy_metrics = self.policy_engine.get_policy_statistics()
            threat_metrics = self.threat_intelligence.get_threat_statistics()
            orchestration_metrics = self.orchestrator.get_orchestration_metrics()
            incident_metrics = self.incident_manager.get_incident_statistics()
            
            # Log summary
            self.logger.info(f"Security Status: {security_metrics['overall_status']}, "
                           f"Active Threats: {security_metrics['active_threats']}, "
                           f"Open Incidents: {incident_metrics['open_incidents']}")
            
        except Exception as e:
            self.logger.error(f"Error updating security metrics: {e}")
    
    def get_unified_dashboard(self) -> Dict[str, Any]:
        """Get unified security dashboard data"""
        try:
            return {
                'security_status': self.security_manager.get_security_status(),
                'policy_statistics': self.policy_engine.get_policy_statistics(),
                'threat_intelligence': self.threat_intelligence.get_threat_statistics(),
                'orchestration_metrics': self.orchestrator.get_orchestration_metrics(),
                'incident_dashboard': self.incident_manager.get_incident_dashboard(),
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            self.logger.error(f"Error getting unified dashboard: {e}")
            return {'error': str(e)}
    
    def report_security_event(self, event_type: str, source: str, description: str,
                            severity: str = 'medium', affected_systems: Optional[List[str]] = None,
                            threat_category: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None) -> Optional[str]:
        """Report a security event to the integrated system"""
        try:
            # Convert string parameters to enums
            severity_enum = SecurityLevel(severity.lower())
            threat_category_enum = None
            if threat_category:
                threat_category_enum = ThreatCategory(threat_category.lower())
            
            # Create security event
            event = SecurityEvent(
                event_id=f"ext_{int(time.time())}",
                timestamp=datetime.now(),
                event_type=event_type,
                severity=severity_enum,
                source=source,
                description=description,
                affected_systems=affected_systems or [],
                threat_category=threat_category_enum,
                metadata=metadata
            )
            
            # Report to security manager
            self.security_manager.report_security_event(event)
            
            return event.event_id
            
        except Exception as e:
            self.logger.error(f"Error reporting security event: {e}")
            return None
    
    def shutdown(self):
        """Shutdown the integrated security management system"""
        self.logger.info("Shutting down Integrated Security Manager")
        
        # Stop monitoring
        self.stop()
        
        # Shutdown all components
        self.security_manager.shutdown()
        self.policy_engine.shutdown()
        self.threat_intelligence.shutdown()
        self.orchestrator.shutdown()
        self.incident_manager.shutdown()
        
        self.logger.info("Integrated Security Manager shutdown complete")

# Example usage and testing
def main():
    """Example usage of the Integrated Security Manager"""
    
    # Initialize the integrated security manager
    ism = IntegratedSecurityManager()
    
    try:
        # Start the system
        ism.start()
        
        # Report a test security event
        event_id = ism.report_security_event(
            event_type='test_malware_detection',
            source='test_scanner',
            description='Test malware detected in file: test.exe',
            severity='high',
            affected_systems=['workstation-01'],
            threat_category='malware',
            metadata={'file_path': 'C:\\temp\\test.exe', 'hash': 'abc123'}
        )
        
        print(f"Reported security event: {event_id}")
        
        # Wait a bit for processing
        time.sleep(5)
        
        # Get dashboard data
        dashboard = ism.get_unified_dashboard()
        print(f"Security Dashboard: {dashboard}")
        
        # Keep running for demonstration
        print("Security Manager running... Press Ctrl+C to stop")
        while True:
            time.sleep(10)
            
    except KeyboardInterrupt:
        print("Stopping security manager...")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        # Shutdown
        ism.shutdown()

if __name__ == "__main__":
    main()