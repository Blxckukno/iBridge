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