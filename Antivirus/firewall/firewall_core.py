"""
Firewall Core Engine
Main firewall engine for packet filtering and rule management
"""

import threading
import time
import json
import sqlite3
from enum import Enum
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any, Optional, Union
from dataclasses import dataclass, asdict
import ipaddress
import socket

class RuleAction(Enum):
    """Actions that can be taken on packets"""
    ALLOW = "allow"
    BLOCK = "block"
    DROP = "drop"
    REJECT = "reject"
    LOG = "log"

class RuleDirection(Enum):
    """Direction of traffic"""
    INBOUND = "inbound"
    OUTBOUND = "outbound"
    BIDIRECTIONAL = "bidirectional"

class RuleProtocol(Enum):
    """Network protocols"""
    TCP = "tcp"
    UDP = "udp"
    ICMP = "icmp"
    ANY = "any"

@dataclass
class FirewallDecision:
    """Result of firewall packet processing"""
    action: RuleAction
    rule_name: str
    rule_id: Optional[str] = None
    reason: str = ""
    timestamp: Optional[datetime] = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()

class FirewallRule:
    """Represents a firewall rule"""
    
    def __init__(self, name: str, action: RuleAction, 
                 direction: RuleDirection = RuleDirection.INBOUND,
                 protocol: str = "any", source_ip: str = "any",
                 destination_ip: str = "any", source_port: Union[int, str] = "any",
                 destination_port: Union[int, str] = "any", priority: int = 100,
                 enabled: bool = True, description: Optional[str] = None,
                 rule_id: Optional[str] = None):
        self.rule_id = rule_id or self._generate_rule_id()
        self.name = name
        self.action = action
        self.direction = direction
        self.protocol = protocol.upper() if protocol != "any" else "any"
        self.source_ip = source_ip
        self.destination_ip = destination_ip
        self.source_port = source_port
        self.destination_port = destination_port
        self.priority = priority
        self.enabled = enabled
        self.description = description or ""
        self.created_at = datetime.now()
        self.last_matched = None
        self.match_count = 0
    
    def _generate_rule_id(self) -> str:
        """Generate unique rule ID"""
        import uuid
        return str(uuid.uuid4())[:8]
    
    def matches(self, packet) -> bool:
        """Check if this rule matches the given packet"""
        if not self.enabled:
            return False
        
        # Check direction
        if self.direction == RuleDirection.INBOUND and packet.direction != "inbound":
            return False
        elif self.direction == RuleDirection.OUTBOUND and packet.direction != "outbound":
            return False
        
        # Check protocol
        if self.protocol != "any" and self.protocol != packet.protocol.upper():
            return False
        
        # Check source IP
        if not self._ip_matches(packet.source_ip, self.source_ip):
            return False
        
        # Check destination IP
        if not self._ip_matches(packet.destination_ip, self.destination_ip):
            return False
        
        # Check source port
        if not self._port_matches(packet.source_port, self.source_port):
            return False
        
        # Check destination port
        if not self._port_matches(packet.destination_port, self.destination_port):
            return False
        
        # Update match statistics
        self.match_count += 1
        self.last_matched = datetime.now()
        
        return True
    
    def _ip_matches(self, packet_ip: str, rule_ip: str) -> bool:
        """Check if packet IP matches rule IP pattern"""
        if rule_ip == "any":
            return True
        
        try:
            # Handle CIDR notation
            if "/" in rule_ip:
                network = ipaddress.ip_network(rule_ip, strict=False)
                return ipaddress.ip_address(packet_ip) in network
            
            # Handle IP ranges (e.g., 192.168.1.1-192.168.1.100)
            if "-" in rule_ip:
                start_ip, end_ip = rule_ip.split("-")
                try:
                    start = ipaddress.ip_address(start_ip.strip())
                    end = ipaddress.ip_address(end_ip.strip())
                    packet_addr = ipaddress.ip_address(packet_ip)
                    # Ensure we're comparing same IP version
                    if isinstance(start, type(packet_addr)) and isinstance(end, type(packet_addr)):
                        return int(start) <= int(packet_addr) <= int(end)
                    return False
                except ValueError:
                    return False
            
            # Exact match
            return packet_ip == rule_ip
            
        except (ValueError, ipaddress.AddressValueError):
            return False
    
    def _port_matches(self, packet_port: int, rule_port: Union[int, str]) -> bool:
        """Check if packet port matches rule port pattern"""
        if rule_port == "any":
            return True
        
        if isinstance(rule_port, int):
            return packet_port == rule_port
        
        if isinstance(rule_port, str):
            if rule_port.isdigit():
                return packet_port == int(rule_port)
            
            # Handle port ranges (e.g., 8000-9000)
            if "-" in rule_port:
                try:
                    start_port, end_port = rule_port.split("-")
                    return int(start_port) <= packet_port <= int(end_port)
                except ValueError:
                    return False
        
        return False
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert rule to dictionary"""
        return {
            'rule_id': self.rule_id,
            'name': self.name,
            'action': self.action.value,
            'direction': self.direction.value,
            'protocol': self.protocol,
            'source_ip': self.source_ip,
            'destination_ip': self.destination_ip,
            'source_port': self.source_port,
            'destination_port': self.destination_port,
            'priority': self.priority,
            'enabled': self.enabled,
            'description': self.description,
            'created_at': self.created_at.isoformat(),
            'match_count': self.match_count
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'FirewallRule':
        """Create rule from dictionary"""
        rule = cls(
            name=data['name'],
            action=RuleAction(data['action']),
            direction=RuleDirection(data['direction']),
            protocol=data.get('protocol', 'any'),
            source_ip=data.get('source_ip', 'any'),
            destination_ip=data.get('destination_ip', 'any'),
            source_port=data.get('source_port', 'any'),
            destination_port=data.get('destination_port', 'any'),
            priority=data.get('priority', 100),
            enabled=data.get('enabled', True),
            description=data.get('description', ''),
            rule_id=data.get('rule_id')
        )
        
        if 'created_at' in data:
            rule.created_at = datetime.fromisoformat(data['created_at'])
        if 'match_count' in data:
            rule.match_count = data['match_count']
        
        return rule

class FirewallEngine:
    """Main firewall engine"""
    
    def __init__(self, config_path: Optional[str] = None):
        self.config_path = Path(config_path) if config_path else Path("firewall_config.db")
        self.rules: List[FirewallRule] = []
        self.is_active = False
        self.packet_filter = None
        self.ids = None
        self.statistics = {
            'packets_processed': 0,
            'packets_blocked': 0,
            'packets_allowed': 0,
            'threats_detected': 0,
            'start_time': None
        }
        self.logging_enabled = False
        self.log_entries = []
        self.max_log_entries = 10000
        
        self._setup_database()
        self._load_rules()
        self._initialize_components()
    
    def _setup_database(self):
        """Setup SQLite database for rules and logs"""
        with sqlite3.connect(self.config_path) as conn:
            conn.execute('''
                CREATE TABLE IF NOT EXISTS firewall_rules (
                    rule_id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    action TEXT NOT NULL,
                    direction TEXT NOT NULL,
                    protocol TEXT DEFAULT 'any',
                    source_ip TEXT DEFAULT 'any',
                    destination_ip TEXT DEFAULT 'any',
                    source_port TEXT DEFAULT 'any',
                    destination_port TEXT DEFAULT 'any',
                    priority INTEGER DEFAULT 100,
                    enabled BOOLEAN DEFAULT 1,
                    description TEXT DEFAULT '',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    match_count INTEGER DEFAULT 0
                )
            ''')
            
            conn.execute('''
                CREATE TABLE IF NOT EXISTS firewall_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    action TEXT NOT NULL,
                    source_ip TEXT,
                    destination_ip TEXT,
                    source_port INTEGER,
                    destination_port INTEGER,
                    protocol TEXT,
                    rule_name TEXT,
                    packet_size INTEGER
                )
            ''')
            
            conn.commit()
    
    def _load_rules(self):
        """Load rules from database"""
        try:
            with sqlite3.connect(self.config_path) as conn:
                cursor = conn.execute('''
                    SELECT * FROM firewall_rules ORDER BY priority ASC
                ''')
                
                for row in cursor.fetchall():
                    rule_data = {
                        'rule_id': row[0],
                        'name': row[1],
                        'action': row[2],
                        'direction': row[3],
                        'protocol': row[4],
                        'source_ip': row[5],
                        'destination_ip': row[6],
                        'source_port': row[7],
                        'destination_port': row[8],
                        'priority': row[9],
                        'enabled': bool(row[10]),
                        'description': row[11],
                        'created_at': row[12],
                        'match_count': row[13]
                    }
                    
                    rule = FirewallRule.from_dict(rule_data)
                    self.rules.append(rule)
        
        except Exception as e:
            print(f"Error loading rules: {e}")
            # Load default rules if database is empty
            self._load_default_rules()
    
    def _load_default_rules(self):
        """Load default firewall rules"""
        default_rules = [
            # Allow loopback traffic
            FirewallRule(
                name="Allow Loopback",
                action=RuleAction.ALLOW,
                direction=RuleDirection.BIDIRECTIONAL,
                source_ip="127.0.0.1",
                priority=1
            ),
            
            # Allow HTTP traffic
            FirewallRule(
                name="Allow HTTP Outbound",
                action=RuleAction.ALLOW,
                direction=RuleDirection.OUTBOUND,
                protocol="TCP",
                destination_port=80,
                priority=10
            ),
            
            # Allow HTTPS traffic
            FirewallRule(
                name="Allow HTTPS Outbound",
                action=RuleAction.ALLOW,
                direction=RuleDirection.OUTBOUND,
                protocol="TCP",
                destination_port=443,
                priority=10
            ),
            
            # Allow DNS queries
            FirewallRule(
                name="Allow DNS Outbound",
                action=RuleAction.ALLOW,
                direction=RuleDirection.OUTBOUND,
                protocol="UDP",
                destination_port=53,
                priority=10
            ),
            
            # Block common attack ports
            FirewallRule(
                name="Block Telnet",
                action=RuleAction.BLOCK,
                direction=RuleDirection.INBOUND,
                protocol="TCP",
                destination_port=23,
                priority=90
            ),
            
            # Default deny rule
            FirewallRule(
                name="Default Deny Inbound",
                action=RuleAction.BLOCK,
                direction=RuleDirection.INBOUND,
                priority=1000
            )
        ]
        
        for rule in default_rules:
            self.add_rule(rule)
    
    def _initialize_components(self):
        """Initialize packet filter and IDS components"""
        try:
            from .packet_filter import PacketFilter
            from .intrusion_detection import IntrusionDetectionSystem
            
            self.packet_filter = PacketFilter()
            self.ids = IntrusionDetectionSystem()
        except ImportError:
            print("Warning: Packet filter or IDS not available")
    
    def start(self):
        """Start the firewall engine"""
        self.is_active = True
        self.statistics['start_time'] = datetime.now()
        print("Firewall engine started")
    
    def stop(self):
        """Stop the firewall engine"""
        self.is_active = False
        print("Firewall engine stopped")
    
    def add_rule(self, rule: FirewallRule) -> str:
        """Add a new firewall rule"""
        self.rules.append(rule)
        self._sort_rules_by_priority()
        self._save_rule_to_db(rule)
        return rule.rule_id
    
    def remove_rule(self, rule_id: str) -> bool:
        """Remove a firewall rule"""
        for i, rule in enumerate(self.rules):
            if rule.rule_id == rule_id:
                del self.rules[i]
                self._remove_rule_from_db(rule_id)
                return True
        return False
    
    def get_rule(self, rule_id: str) -> Optional[FirewallRule]:
        """Get a rule by ID"""
        for rule in self.rules:
            if rule.rule_id == rule_id:
                return rule
        return None
    
    def list_rules(self) -> List[FirewallRule]:
        """Get all rules"""
        return self.rules.copy()
    
    def get_default_rules(self) -> List[FirewallRule]:
        """Get default rules"""
        return [rule for rule in self.rules if rule.priority <= 20]
    
    def _sort_rules_by_priority(self):
        """Sort rules by priority (lower numbers = higher priority)"""
        self.rules.sort(key=lambda r: r.priority)
    
    def _save_rule_to_db(self, rule: FirewallRule):
        """Save rule to database"""
        try:
            with sqlite3.connect(self.config_path) as conn:
                conn.execute('''
                    INSERT OR REPLACE INTO firewall_rules 
                    (rule_id, name, action, direction, protocol, source_ip, 
                     destination_ip, source_port, destination_port, priority, 
                     enabled, description, match_count)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    rule.rule_id, rule.name, rule.action.value, rule.direction.value,
                    rule.protocol, rule.source_ip, rule.destination_ip,
                    str(rule.source_port), str(rule.destination_port),
                    rule.priority, rule.enabled, rule.description, rule.match_count
                ))
                conn.commit()
        except Exception as e:
            print(f"Error saving rule to database: {e}")
    
    def _remove_rule_from_db(self, rule_id: str):
        """Remove rule from database"""
        try:
            with sqlite3.connect(self.config_path) as conn:
                conn.execute('DELETE FROM firewall_rules WHERE rule_id = ?', (rule_id,))
                conn.commit()
        except Exception as e:
            print(f"Error removing rule from database: {e}")
    
    def process_packet(self, packet) -> FirewallDecision:
        """Process a packet through the firewall"""
        if not self.is_active:
            return FirewallDecision(action=RuleAction.ALLOW, rule_name="Firewall Inactive")
        
        self.statistics['packets_processed'] += 1
        
        # Validate packet first
        if self.packet_filter and not self.packet_filter.validate_packet(packet):
            decision = FirewallDecision(action=RuleAction.DROP, rule_name="Invalid Packet", reason="Packet validation failed")
            self._log_decision(packet, decision)
            return decision
        
        # Check intrusion detection
        if self.ids:
            threats = self.ids.analyze_packet(packet)
            if threats:
                self.statistics['threats_detected'] += len(threats)
                decision = FirewallDecision(action=RuleAction.BLOCK, rule_name="IDS Block", 
                                          reason=f"Threats detected: {[t.description for t in threats]}")
                self._log_decision(packet, decision)
                return decision
        
        # Process through rules
        for rule in self.rules:
            if rule.matches(packet):
                decision = FirewallDecision(action=rule.action, rule_name=rule.name, 
                                          rule_id=rule.rule_id,
                                          reason=f"Matched rule: {rule.name}")
                
                # Update statistics
                if decision.action in [RuleAction.BLOCK, RuleAction.DROP, RuleAction.REJECT]:
                    self.statistics['packets_blocked'] += 1
                else:
                    self.statistics['packets_allowed'] += 1
                
                self._log_decision(packet, decision)
                return decision
        
        # Default action if no rules match
        decision = FirewallDecision(action=RuleAction.ALLOW, rule_name="Default Allow", reason="No matching rules")
        self.statistics['packets_allowed'] += 1
        self._log_decision(packet, decision)
        return decision
    
    def _log_decision(self, packet, decision: FirewallDecision):
        """Log firewall decision"""
        if self.logging_enabled:
            log_entry = {
                'timestamp': decision.timestamp.isoformat() if decision.timestamp else datetime.now().isoformat(),
                'action': decision.action.value,
                'source_ip': packet.source_ip,
                'destination_ip': packet.destination_ip,
                'source_port': packet.source_port,
                'destination_port': packet.destination_port,
                'protocol': packet.protocol,
                'rule_name': decision.rule_name,
                'packet_size': len(packet.data) if hasattr(packet, 'data') and packet.data else 0
            }
            
            self.log_entries.append(log_entry)
            
            # Trim log if it gets too large
            if len(self.log_entries) > self.max_log_entries:
                self.log_entries = self.log_entries[-self.max_log_entries//2:]
            
            # Save to database
            self._save_log_to_db(log_entry)
    
    def _save_log_to_db(self, log_entry: Dict[str, Any]):
        """Save log entry to database"""
        try:
            with sqlite3.connect(self.config_path) as conn:
                conn.execute('''
                    INSERT INTO firewall_logs 
                    (action, source_ip, destination_ip, source_port, 
                     destination_port, protocol, rule_name, packet_size)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    log_entry['action'], log_entry['source_ip'], log_entry['destination_ip'],
                    log_entry['source_port'], log_entry['destination_port'],
                    log_entry['protocol'], log_entry['rule_name'], log_entry['packet_size']
                ))
                conn.commit()
        except Exception as e:
            print(f"Error saving log to database: {e}")
    
    def enable_logging(self):
        """Enable packet logging"""
        self.logging_enabled = True
    
    def disable_logging(self):
        """Disable packet logging"""
        self.logging_enabled = False
    
    def get_recent_logs(self, limit: int = 100) -> List[Dict[str, Any]]:
        """Get recent log entries"""
        return self.log_entries[-limit:] if self.log_entries else []
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get firewall statistics"""
        stats = self.statistics.copy()
        if stats['start_time']:
            stats['uptime_seconds'] = (datetime.now() - stats['start_time']).total_seconds()
        return stats
    
    def clear_statistics(self):
        """Clear firewall statistics"""
        self.statistics = {
            'packets_processed': 0,
            'packets_blocked': 0,
            'packets_allowed': 0,
            'threats_detected': 0,
            'start_time': datetime.now() if self.is_active else None
        }
    
    def export_rules(self, file_path: str):
        """Export rules to JSON file"""
        rules_data = [rule.to_dict() for rule in self.rules]
        with open(file_path, 'w') as f:
            json.dump(rules_data, f, indent=2)
    
    def import_rules(self, file_path: str, replace: bool = False):
        """Import rules from JSON file"""
        if replace:
            self.rules.clear()
        
        with open(file_path, 'r') as f:
            rules_data = json.load(f)
        
        for rule_data in rules_data:
            rule = FirewallRule.from_dict(rule_data)
            self.add_rule(rule)