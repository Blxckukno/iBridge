
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
Packet Filter Module
Handles packet filtering, validation, and analysis
"""

import socket
import struct
import threading
import time
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, Any, List, Optional, Tuple, Union
from enum import Enum
import ipaddress

class PacketDirection(Enum):
    """Direction of network traffic"""
    INBOUND = "inbound"
    OUTBOUND = "outbound"
    UNKNOWN = "unknown"

class PacketType(Enum):
    """Type of network packet"""
    TCP = "tcp"
    UDP = "udp"
    ICMP = "icmp"
    ARP = "arp"
    IPV4 = "ipv4"
    IPV6 = "ipv6"
    UNKNOWN = "unknown"

@dataclass
class NetworkPacket:
    """Represents a network packet"""
    source_ip: str
    destination_ip: str
    source_port: int
    destination_port: int
    protocol: str
    direction: str
    timestamp: datetime
    data: bytes = b""
    packet_size: int = 0
    flags: Optional[Dict[str, bool]] = None
    packet_type: str = "unknown"
    ttl: int = 0
    checksum: str = ""
    sequence_number: int = 0
    acknowledgment_number: int = 0
    window_size: int = 0
    urgent_pointer: int = 0
    options: Optional[Dict[str, Any]] = None
    
    def __post_init__(self):
        if self.flags is None:
            self.flags = {}
        if self.options is None:
            self.options = {}
        if self.packet_size == 0 and self.data:
            self.packet_size = len(self.data)
    
    def is_tcp(self) -> bool:
        """Check if packet is TCP"""
        return self.protocol.upper() == "TCP"
    
    def is_udp(self) -> bool:
        """Check if packet is UDP"""
        return self.protocol.upper() == "UDP"
    
    def is_icmp(self) -> bool:
        """Check if packet is ICMP"""
        return self.protocol.upper() == "ICMP"
    
    def is_syn(self) -> bool:
        """Check if TCP packet has SYN flag"""
        return self.flags.get('SYN', False) if self.flags else False
    
    def is_ack(self) -> bool:
        """Check if TCP packet has ACK flag"""
        return self.flags.get('ACK', False) if self.flags else False
    
    def is_fin(self) -> bool:
        """Check if TCP packet has FIN flag"""
        return self.flags.get('FIN', False) if self.flags else False
    
    def is_rst(self) -> bool:
        """Check if TCP packet has RST flag"""
        return self.flags.get('RST', False) if self.flags else False
    
    def is_psh(self) -> bool:
        """Check if TCP packet has PSH flag"""
        return self.flags.get('PSH', False) if self.flags else False
    
    def is_urg(self) -> bool:
        """Check if TCP packet has URG flag"""
        return self.flags.get('URG', False) if self.flags else False
    
    def get_payload(self) -> bytes:
        """Get packet payload data"""
        return self.data
    
    def get_header_info(self) -> Dict[str, Any]:
        """Get packet header information"""
        return {
            'source_ip': self.source_ip,
            'destination_ip': self.destination_ip,
            'source_port': self.source_port,
            'destination_port': self.destination_port,
            'protocol': self.protocol,
            'direction': self.direction,
            'packet_size': self.packet_size,
            'ttl': self.ttl,
            'checksum': self.checksum,
            'flags': self.flags,
            'timestamp': self.timestamp.isoformat()
        }
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert packet to dictionary"""
        return {
            'source_ip': self.source_ip,
            'destination_ip': self.destination_ip,
            'source_port': self.source_port,
            'destination_port': self.destination_port,
            'protocol': self.protocol,
            'direction': self.direction,
            'timestamp': self.timestamp.isoformat(),
            'packet_size': self.packet_size,
            'packet_type': self.packet_type,
            'ttl': self.ttl,
            'checksum': self.checksum,
            'flags': self.flags,
            'sequence_number': self.sequence_number,
            'acknowledgment_number': self.acknowledgment_number,
            'window_size': self.window_size,
            'urgent_pointer': self.urgent_pointer,
            'options': self.options
        }

class PacketValidator:
    """Validates packet structure and content"""
    
    def __init__(self):
        self.validation_rules = {
            'max_packet_size': 65535,
            'min_packet_size': 20,
            'valid_ports': range(1, 65536),
            'private_ip_ranges': [
                '10.0.0.0/8',
                '172.16.0.0/12',
                '192.168.0.0/16',
                '127.0.0.0/8'
            ]
        }
    
    def validate_packet(self, packet: NetworkPacket) -> bool:
        """Validate packet structure and content"""
        try:
            # Check packet size
            if not self._validate_packet_size(packet):
                return False
            
            # Check IP addresses
            if not self._validate_ip_addresses(packet):
                return False
            
            # Check ports
            if not self._validate_ports(packet):
                return False
            
            # Protocol-specific validation
            if packet.is_tcp():
                if not self._validate_tcp_packet(packet):
                    return False
            elif packet.is_udp():
                if not self._validate_udp_packet(packet):
                    return False
            elif packet.is_icmp():
                if not self._validate_icmp_packet(packet):
                    return False
            
            return True
            
        except Exception:
            return False
    
    def _validate_packet_size(self, packet: NetworkPacket) -> bool:
        """Validate packet size"""
        return (self.validation_rules['min_packet_size'] <= 
                packet.packet_size <= 
                self.validation_rules['max_packet_size'])
    
    def _validate_ip_addresses(self, packet: NetworkPacket) -> bool:
        """Validate IP addresses"""
        try:
            ipaddress.ip_address(packet.source_ip)
            ipaddress.ip_address(packet.destination_ip)
            return True
        except ValueError:
            return False
    
    def _validate_ports(self, packet: NetworkPacket) -> bool:
        """Validate port numbers"""
        if packet.protocol.upper() in ['TCP', 'UDP']:
            return (packet.source_port in self.validation_rules['valid_ports'] and
                   packet.destination_port in self.validation_rules['valid_ports'])
        return True
    
    def _validate_tcp_packet(self, packet: NetworkPacket) -> bool:
        """Validate TCP-specific fields"""
        # Check for valid flag combinations
        if packet.is_syn() and packet.is_fin():
            return False  # Invalid SYN+FIN combination
        
        # Check sequence numbers
        if packet.sequence_number < 0:
            return False
        
        return True
    
    def _validate_udp_packet(self, packet: NetworkPacket) -> bool:
        """Validate UDP-specific fields"""
        # UDP validation is simpler
        return True
    
    def _validate_icmp_packet(self, packet: NetworkPacket) -> bool:
        """Validate ICMP-specific fields"""
        # ICMP validation
        return True

class PacketAnalyzer:
    """Analyzes packet patterns and behavior"""
    
    def __init__(self):
        self.connection_tracker = {}
        self.packet_stats = {
            'total_packets': 0,
            'tcp_packets': 0,
            'udp_packets': 0,
            'icmp_packets': 0,
            'invalid_packets': 0,
            'bytes_transferred': 0
        }
        self.suspicious_patterns = []
    
    def analyze_packet(self, packet: NetworkPacket) -> Dict[str, Any]:
        """Analyze packet for patterns and anomalies"""
        analysis = {
            'packet_id': id(packet),
            'timestamp': packet.timestamp.isoformat(),
            'basic_info': packet.get_header_info(),
            'connection_state': self._analyze_connection_state(packet),
            'pattern_analysis': self._analyze_patterns(packet),
            'risk_assessment': self._assess_risk(packet)
        }
        
        self._update_statistics(packet)
        return analysis
    
    def _analyze_connection_state(self, packet: NetworkPacket) -> Dict[str, Any]:
        """Analyze connection state for TCP packets"""
        if not packet.is_tcp():
            return {'type': 'stateless', 'state': 'N/A'}
        
        connection_key = f"{packet.source_ip}:{packet.source_port}-{packet.destination_ip}:{packet.destination_port}"
        
        if connection_key not in self.connection_tracker:
            self.connection_tracker[connection_key] = {
                'state': 'NEW',
                'packets': 0,
                'bytes': 0,
                'first_seen': packet.timestamp,
                'last_seen': packet.timestamp
            }
        
        conn = self.connection_tracker[connection_key]
        conn['packets'] += 1
        conn['bytes'] += packet.packet_size
        conn['last_seen'] = packet.timestamp
        
        # Determine connection state
        if packet.is_syn() and not packet.is_ack():
            conn['state'] = 'SYN_SENT'
        elif packet.is_syn() and packet.is_ack():
            conn['state'] = 'SYN_RECEIVED'
        elif packet.is_ack() and not packet.is_syn():
            conn['state'] = 'ESTABLISHED'
        elif packet.is_fin():
            conn['state'] = 'FIN_WAIT'
        elif packet.is_rst():
            conn['state'] = 'RESET'
        
        return {
            'type': 'tcp',
            'state': conn['state'],
            'packets': conn['packets'],
            'bytes': conn['bytes'],
            'duration': (conn['last_seen'] - conn['first_seen']).total_seconds()
        }
    
    def _analyze_patterns(self, packet: NetworkPacket) -> Dict[str, Any]:
        """Analyze packet for suspicious patterns"""
        patterns = {
            'port_scan': self._detect_port_scan(packet),
            'flood_attack': self._detect_flood_attack(packet),
            'fragmentation': self._detect_fragmentation(packet),
            'anomalous_size': self._detect_anomalous_size(packet)
        }
        
        return patterns
    
    def _detect_port_scan(self, packet: NetworkPacket) -> bool:
        """Detect potential port scanning"""
        # Simple heuristic: multiple SYN packets to different ports from same source
        if packet.is_tcp() and packet.is_syn() and not packet.is_ack():
            source_key = packet.source_ip
            recent_targets = [
                conn for conn_key, conn in self.connection_tracker.items()
                if conn_key.startswith(source_key) and
                (packet.timestamp - conn['first_seen']).total_seconds() < 60
            ]
            return len(recent_targets) > 10
        return False
    
    def _detect_flood_attack(self, packet: NetworkPacket) -> bool:
        """Detect potential flood attacks"""
        # Check for high packet rate from single source
        source_packets = [
            conn for conn in self.connection_tracker.values()
            if (packet.timestamp - conn['last_seen']).total_seconds() < 5
        ]
        return len(source_packets) > 100
    
    def _detect_fragmentation(self, packet: NetworkPacket) -> bool:
        """Detect suspicious fragmentation"""
        # Check for unusually small fragments
        return packet.packet_size < 100 and (packet.options is not None and 'fragment' in packet.options)
    
    def _detect_anomalous_size(self, packet: NetworkPacket) -> bool:
        """Detect anomalous packet sizes"""
        if packet.is_icmp():
            return packet.packet_size > 1500  # Large ICMP packets
        elif packet.is_udp():
            return packet.packet_size > 8192   # Large UDP packets
        return False
    
    def _assess_risk(self, packet: NetworkPacket) -> Dict[str, Any]:
        """Assess risk level of packet"""
        risk_factors = []
        risk_score = 0
        
        # Check for private IP communication
        try:
            src_ip = ipaddress.ip_address(packet.source_ip)
            dst_ip = ipaddress.ip_address(packet.destination_ip)
            
            if src_ip.is_private and not dst_ip.is_private:
                risk_factors.append("Private to public communication")
                risk_score += 1
        except ValueError:
            risk_factors.append("Invalid IP address")
            risk_score += 3
        
        # Check for suspicious ports
        suspicious_ports = [23, 135, 445, 1433, 3389, 5900]
        if packet.destination_port in suspicious_ports:
            risk_factors.append(f"Suspicious destination port: {packet.destination_port}")
            risk_score += 2
        
        # Check for unusual protocols
        if packet.protocol.upper() not in ['TCP', 'UDP', 'ICMP']:
            risk_factors.append(f"Unusual protocol: {packet.protocol}")
            risk_score += 1
        
        # Determine risk level
        if risk_score >= 5:
            risk_level = "HIGH"
        elif risk_score >= 3:
            risk_level = "MEDIUM"
        elif risk_score >= 1:
            risk_level = "LOW"
        else:
            risk_level = "MINIMAL"
        
        return {
            'risk_level': risk_level,
            'risk_score': risk_score,
            'risk_factors': risk_factors
        }
    
    def _update_statistics(self, packet: NetworkPacket):
        """Update packet statistics"""
        self.packet_stats['total_packets'] += 1
        self.packet_stats['bytes_transferred'] += packet.packet_size
        
        if packet.is_tcp():
            self.packet_stats['tcp_packets'] += 1
        elif packet.is_udp():
            self.packet_stats['udp_packets'] += 1
        elif packet.is_icmp():
            self.packet_stats['icmp_packets'] += 1
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get packet analysis statistics"""
        return self.packet_stats.copy()
    
    def get_active_connections(self) -> Dict[str, Any]:
        """Get active connection information"""
        active_connections = {}
        current_time = datetime.now()
        
        for conn_key, conn_info in self.connection_tracker.items():
            # Consider connection active if seen within last 5 minutes
            if (current_time - conn_info['last_seen']).total_seconds() < 300:
                active_connections[conn_key] = conn_info
        
        return active_connections

class PacketFilter:
    """Main packet filtering system"""
    
    def __init__(self):
        self.validator = PacketValidator()
        self.analyzer = PacketAnalyzer()
        self.is_active = False
        self.blocked_ips = set()
        self.allowed_ips = set()
        self.rate_limits = {}
        self.filter_rules = []
    
    def start(self):
        """Start packet filtering"""
        self.is_active = True
    
    def stop(self):
        """Stop packet filtering"""
        self.is_active = False
    
    def validate_packet(self, packet: NetworkPacket) -> bool:
        """Validate packet structure and content"""
        if not self.is_active:
            return True
        
        return self.validator.validate_packet(packet)
    
    def analyze_packet(self, packet: NetworkPacket) -> Dict[str, Any]:
        """Analyze packet for patterns and anomalies"""
        return self.analyzer.analyze_packet(packet)
    
    def should_block_packet(self, packet: NetworkPacket) -> Tuple[bool, str]:
        """Determine if packet should be blocked"""
        if not self.is_active:
            return False, "Filter inactive"
        
        # Check blocked IPs
        if packet.source_ip in self.blocked_ips:
            return True, f"Source IP {packet.source_ip} is blocked"
        
        if packet.destination_ip in self.blocked_ips:
            return True, f"Destination IP {packet.destination_ip} is blocked"
        
        # Check rate limits
        if self._check_rate_limit(packet):
            return True, "Rate limit exceeded"
        
        # Check custom filter rules
        for rule in self.filter_rules:
            if rule(packet):
                return True, "Custom filter rule matched"
        
        return False, "Packet allowed"
    
    def _check_rate_limit(self, packet: NetworkPacket) -> bool:
        """Check if packet exceeds rate limits"""
        source_key = packet.source_ip
        current_time = time.time()
        
        if source_key not in self.rate_limits:
            self.rate_limits[source_key] = {
                'packets': [],
                'bytes': []
            }
        
        # Clean old entries (older than 1 minute)
        cutoff_time = current_time - 60
        self.rate_limits[source_key]['packets'] = [
            t for t in self.rate_limits[source_key]['packets'] if t > cutoff_time
        ]
        self.rate_limits[source_key]['bytes'] = [
            (t, b) for t, b in self.rate_limits[source_key]['bytes'] if t > cutoff_time
        ]
        
        # Add current packet
        self.rate_limits[source_key]['packets'].append(current_time)
        self.rate_limits[source_key]['bytes'].append((current_time, packet.packet_size))
        
        # Check limits
        packet_rate = len(self.rate_limits[source_key]['packets'])
        byte_rate = sum(b for t, b in self.rate_limits[source_key]['bytes'])
        
        # Configurable limits
        max_packets_per_minute = 1000
        max_bytes_per_minute = 1024 * 1024  # 1MB
        
        return (packet_rate > max_packets_per_minute or 
                byte_rate > max_bytes_per_minute)
    
    def add_blocked_ip(self, ip_address: str):
        """Add IP to blocked list"""
        try:
            ipaddress.ip_address(ip_address)
            self.blocked_ips.add(ip_address)
        except ValueError:
            raise ValueError(f"Invalid IP address: {ip_address}")
    
    def remove_blocked_ip(self, ip_address: str):
        """Remove IP from blocked list"""
        self.blocked_ips.discard(ip_address)
    
    def add_allowed_ip(self, ip_address: str):
        """Add IP to allowed list"""
        try:
            ipaddress.ip_address(ip_address)
            self.allowed_ips.add(ip_address)
        except ValueError:
            raise ValueError(f"Invalid IP address: {ip_address}")
    
    def remove_allowed_ip(self, ip_address: str):
        """Remove IP from allowed list"""
        self.allowed_ips.discard(ip_address)
    
    def add_filter_rule(self, rule_function):
        """Add custom filter rule function"""
        self.filter_rules.append(rule_function)
    
    def remove_filter_rule(self, rule_function):
        """Remove custom filter rule function"""
        if rule_function in self.filter_rules:
            self.filter_rules.remove(rule_function)
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get filter statistics"""
        return {
            'is_active': self.is_active,
            'blocked_ips_count': len(self.blocked_ips),
            'allowed_ips_count': len(self.allowed_ips),
            'filter_rules_count': len(self.filter_rules),
            'analyzer_stats': self.analyzer.get_statistics(),
            'active_connections': len(self.analyzer.get_active_connections())
        }
    
    def clear_rate_limits(self):
        """Clear all rate limit data"""
        self.rate_limits.clear()
    
    def get_blocked_ips(self) -> List[str]:
        """Get list of blocked IP addresses"""
        return list(self.blocked_ips)
    
    def get_allowed_ips(self) -> List[str]:
        """Get list of allowed IP addresses"""
        return list(self.allowed_ips)


# Utility functions for creating test packets
def create_tcp_packet(source_ip: str, dest_ip: str, source_port: int, dest_port: int,
                     flags: Optional[Dict[str, bool]] = None, data: bytes = b"") -> NetworkPacket:
    """Create a TCP packet for testing"""
    if flags is None:
        flags = {}
    
    return NetworkPacket(
        source_ip=source_ip,
        destination_ip=dest_ip,
        source_port=source_port,
        destination_port=dest_port,
        protocol="TCP",
        direction="outbound",
        timestamp=datetime.now(),
        data=data,
        packet_size=len(data) + 40,  # Approximate TCP header size
        flags=flags,
        packet_type="tcp"
    )

def create_udp_packet(source_ip: str, dest_ip: str, source_port: int, dest_port: int,
                     data: bytes = b"") -> NetworkPacket:
    """Create a UDP packet for testing"""
    return NetworkPacket(
        source_ip=source_ip,
        destination_ip=dest_ip,
        source_port=source_port,
        destination_port=dest_port,
        protocol="UDP",
        direction="outbound",
        timestamp=datetime.now(),
        data=data,
        packet_size=len(data) + 8,  # UDP header size
        packet_type="udp"
    )

def create_icmp_packet(source_ip: str, dest_ip: str, data: bytes = b"") -> NetworkPacket:
    """Create an ICMP packet for testing"""
    return NetworkPacket(
        source_ip=source_ip,
        destination_ip=dest_ip,
        source_port=0,
        destination_port=0,
        protocol="ICMP",
        direction="outbound",
        timestamp=datetime.now(),
        data=data,
        packet_size=len(data) + 8,  # ICMP header size
        packet_type="icmp"
    )