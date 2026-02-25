
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
Network Monitor and Firewall
Monitors network traffic and implements firewall functionality
"""
import asyncio
import threading
import time
from datetime import datetime
from typing import Dict, List, Optional, Set
import ipaddress
import socket
import struct
import winreg
from pathlib import Path
import json
import re

from scapy.all import *
from netfilterqueue import NetfilterQueue
from ..core_engine.config_manager import ConfigManager
from ..logging.security_logger import SecurityLogger


class NetworkMonitor:
    """Network traffic monitoring and firewall implementation"""
    
    def __init__(self, config_manager: ConfigManager, logger: SecurityLogger):
        self.config = config_manager
        self.logger = logger
        
        # Monitoring state
        self.is_monitoring = False
        self.packet_queue = None
        self.monitor_thread = None
        
        # Network rules
        self.blocked_ips = set()
        self.blocked_ports = set()
        self.blocked_domains = set()
        self.suspicious_patterns = set()
        
        # Intrusion detection
        self.connection_tracker = {}
        self.port_scan_tracker = {}
        self.attack_signatures = []
        
        # Statistics
        self.stats = {
            "packets_analyzed": 0,
            "connections_blocked": 0,
            "threats_detected": 0,
            "port_scans_detected": 0,
            "start_time": None
        }
        
        # Event handlers
        self.on_malicious_connection = None
        self.on_intrusion_detected = None
    
    async def initialize(self):
        """Initialize network monitoring"""
        self.logger.log_info("Initializing network monitor")
        
        try:
            # Load network rules
            await self._load_network_rules()
            
            # Load attack signatures
            await self._load_attack_signatures()
            
            # Initialize packet capture
            self.packet_queue = NetfilterQueue()
            
            self.logger.log_info("Network monitor initialized")
            
        except Exception as e:
            self.logger.log_error(f"Failed to initialize network monitor: {e}")
            raise
    
    async def _load_network_rules(self):
        """Load network filtering rules"""
        rules_file = Path.home() / ".antivirus_config" / "network_rules.json"
        
        if rules_file.exists():
            try:
                with open(rules_file, 'r') as f:
                    rules = json.load(f)
                    
                self.blocked_ips = set(rules.get("blocked_ips", []))
                self.blocked_ports = set(rules.get("blocked_ports", []))
                self.blocked_domains = set(rules.get("blocked_domains", []))
                self.suspicious_patterns = set(rules.get("suspicious_patterns", []))
                
            except Exception as e:
                self.logger.log_error(f"Error loading network rules: {e}")
        
        # Add default rules if empty
        if not self.blocked_ips:
            self.blocked_ips = {
                "192.168.0.0/16",  # Private network
                "10.0.0.0/8",      # Private network
                "172.16.0.0/12"    # Private network
            }
        
        if not self.blocked_ports:
            self.blocked_ports = {
                21,    # FTP
                22,    # SSH
                23,    # Telnet
                25,    # SMTP
                3389,  # RDP
                445    # SMB
            }
        
        if not self.blocked_domains:
            self.blocked_domains = {
                "malware.com",
                "phishing.net",
                "suspicious.org"
            }
        
        if not self.suspicious_patterns:
            self.suspicious_patterns = {
                r"(?i)sqlmap",
                r"(?i)nikto",
                r"(?i)nmap",
                r"(?i)masscan",
                r"(?i)exploit"
            }
    
    async def _load_attack_signatures(self):
        """Load known attack signatures"""
        self.attack_signatures = [
            {
                "name": "SQL Injection",
                "pattern": rb"(?i)(union.*select|exec.*sp_|xp_cmdshell)",
                "severity": 8
            },
            {
                "name": "XSS Attack",
                "pattern": rb"(?i)(<script>|javascript:|onload=|onerror=)",
                "severity": 7
            },
            {
                "name": "Command Injection",
                "pattern": rb"(?i)(;.*cmd|;.*bash|;.*powershell)",
                "severity": 9
            },
            {
                "name": "Directory Traversal",
                "pattern": rb"(?i)(\.\.\/.*\.\.\/|\.\.\\.*\.\.\\)",
                "severity": 6
            }
        ]
    
    async def start_monitoring(self):
        """Start network monitoring"""
        if self.is_monitoring:
            return
        
        self.logger.log_info("Starting network monitoring")
        
        try:
            # Start packet capture
            self.packet_queue.bind(0, self._process_packet)
            
            # Start monitoring thread
            self.monitor_thread = threading.Thread(
                target=self._run_monitor,
                daemon=True
            )
            self.monitor_thread.start()
            
            self.is_monitoring = True
            self.stats["start_time"] = datetime.now().isoformat()
            
            self.logger.log_info("Network monitoring started")
            
        except Exception as e:
            self.logger.log_error(f"Failed to start network monitoring: {e}")
            raise
    
    def _run_monitor(self):
        """Run network monitoring in separate thread"""
        try:
            while self.is_monitoring:
                self.packet_queue.run()
                time.sleep(0.1)
                
        except Exception as e:
            self.logger.log_error(f"Network monitoring error: {e}")
            self.is_monitoring = False
    
    def _process_packet(self, packet):
        """Process captured network packet"""
        try:
            # Convert packet to scapy packet
            scapy_packet = IP(packet.get_payload())
            
            # Update statistics
            self.stats["packets_analyzed"] += 1
            
            # Check if packet should be blocked
            if self._should_block_packet(scapy_packet):
                packet.drop()
                return
            
            # Deep packet inspection
            threat_info = self._inspect_packet(scapy_packet)
            if threat_info:
                self._handle_threat(threat_info)
                packet.drop()
                return
            
            # Track connections for intrusion detection
            self._track_connection(scapy_packet)
            
            # Accept packet if no threats found
            packet.accept()
            
        except Exception as e:
            self.logger.log_error(f"Error processing packet: {e}")
            packet.accept()  # Accept on error to prevent network disruption
    
    def _should_block_packet(self, packet) -> bool:
        """Check if packet should be blocked based on rules"""
        try:
            # Check source/destination IPs
            if packet.haslayer(IP):
                src_ip = packet[IP].src
                dst_ip = packet[IP].dst
                
                for blocked_ip in self.blocked_ips:
                    network = ipaddress.ip_network(blocked_ip)
                    if (ipaddress.ip_address(src_ip) in network or 
                        ipaddress.ip_address(dst_ip) in network):
                        self.stats["connections_blocked"] += 1
                        return True
            
            # Check TCP/UDP ports
            if packet.haslayer(TCP):
                src_port = packet[TCP].sport
                dst_port = packet[TCP].dport
                if src_port in self.blocked_ports or dst_port in self.blocked_ports:
                    self.stats["connections_blocked"] += 1
                    return True
            
            if packet.haslayer(UDP):
                src_port = packet[UDP].sport
                dst_port = packet[UDP].dport
                if src_port in self.blocked_ports or dst_port in self.blocked_ports:
                    self.stats["connections_blocked"] += 1
                    return True
            
            # Check DNS queries
            if packet.haslayer(DNS) and packet.haslayer(DNSQR):
                query = packet[DNSQR].qname.decode()
                for domain in self.blocked_domains:
                    if domain in query:
                        self.stats["connections_blocked"] += 1
                        return True
            
            return False
            
        except Exception as e:
            self.logger.log_error(f"Error checking packet rules: {e}")
            return False
    
    def _inspect_packet(self, packet) -> Optional[Dict]:
        """Deep packet inspection for threats"""
        try:
            # Get packet payload
            payload = raw(packet)
            
            # Check attack signatures
            for signature in self.attack_signatures:
                if re.search(signature["pattern"], payload):
                    self.stats["threats_detected"] += 1
                    return {
                        "type": "signature_match",
                        "name": signature["name"],
                        "severity": signature["severity"],
                        "source_ip": packet[IP].src if packet.haslayer(IP) else None,
                        "destination_ip": packet[IP].dst if packet.haslayer(IP) else None,
                        "timestamp": datetime.now().isoformat()
                    }
            
            # Check suspicious patterns
            for pattern in self.suspicious_patterns:
                if re.search(pattern.encode(), payload):
                    self.stats["threats_detected"] += 1
                    return {
                        "type": "suspicious_pattern",
                        "pattern": pattern,
                        "severity": 5,
                        "source_ip": packet[IP].src if packet.haslayer(IP) else None,
                        "destination_ip": packet[IP].dst if packet.haslayer(IP) else None,
                        "timestamp": datetime.now().isoformat()
                    }
            
            return None
            
        except Exception as e:
            self.logger.log_error(f"Error in packet inspection: {e}")
            return None
    
    def _track_connection(self, packet):
        """Track connections for intrusion detection"""
        try:
            if not packet.haslayer(IP) or not (packet.haslayer(TCP) or packet.haslayer(UDP)):
                return
            
            src_ip = packet[IP].src
            dst_ip = packet[IP].dst
            
            # Track port scans
            current_time = time.time()
            if packet.haslayer(TCP):
                key = f"{src_ip}"
                if key not in self.port_scan_tracker:
                    self.port_scan_tracker[key] = {
                        "ports": set(),
                        "start_time": current_time
                    }
                
                self.port_scan_tracker[key]["ports"].add(packet[TCP].dport)
                
                # Check for port scan (many ports in short time)
                if (len(self.port_scan_tracker[key]["ports"]) > 20 and 
                    current_time - self.port_scan_tracker[key]["start_time"] < 60):
                    self.stats["port_scans_detected"] += 1
                    threat_info = {
                        "type": "port_scan",
                        "source_ip": src_ip,
                        "ports_scanned": len(self.port_scan_tracker[key]["ports"]),
                        "severity": 7,
                        "timestamp": datetime.now().isoformat()
                    }
                    self._handle_threat(threat_info)
                    del self.port_scan_tracker[key]
            
            # Clean up old trackers
            self._cleanup_trackers(current_time)
            
        except Exception as e:
            self.logger.log_error(f"Error tracking connection: {e}")
    
    def _cleanup_trackers(self, current_time: float):
        """Clean up old connection trackers"""
        # Remove port scan trackers older than 5 minutes
        old_keys = [
            key for key, data in self.port_scan_tracker.items()
            if current_time - data["start_time"] > 300
        ]
        for key in old_keys:
            del self.port_scan_tracker[key]
    
    def _handle_threat(self, threat_info: Dict):
        """Handle detected network threats"""
        self.logger.log_warning(f"Network threat detected: {threat_info}")
        
        # Notify event handlers
        if self.on_malicious_connection:
            asyncio.create_task(self.on_malicious_connection(threat_info))
        
        if threat_info["type"] == "port_scan" and self.on_intrusion_detected:
            asyncio.create_task(self.on_intrusion_detected(threat_info))
    
    async def add_blocked_ip(self, ip: str):
        """Add IP to blocked list"""
        try:
            # Validate IP address/network
            ipaddress.ip_network(ip)
            self.blocked_ips.add(ip)
            await self._save_network_rules()
            self.logger.log_info(f"Added blocked IP: {ip}")
            return True
            
        except Exception as e:
            self.logger.log_error(f"Invalid IP address/network: {ip}")
            return False
    
    async def add_blocked_port(self, port: int):
        """Add port to blocked list"""
        if 0 <= port <= 65535:
            self.blocked_ports.add(port)
            await self._save_network_rules()
            self.logger.log_info(f"Added blocked port: {port}")
            return True
        return False
    
    async def add_blocked_domain(self, domain: str):
        """Add domain to blocked list"""
        self.blocked_domains.add(domain)
        await self._save_network_rules()
        self.logger.log_info(f"Added blocked domain: {domain}")
        return True
    
    async def _save_network_rules(self):
        """Save network rules to file"""
        rules = {
            "blocked_ips": list(self.blocked_ips),
            "blocked_ports": list(self.blocked_ports),
            "blocked_domains": list(self.blocked_domains),
            "suspicious_patterns": list(self.suspicious_patterns)
        }
        
        rules_file = Path.home() / ".antivirus_config" / "network_rules.json"
        try:
            with open(rules_file, 'w') as f:
                json.dump(rules, f, indent=2)
        except Exception as e:
            self.logger.log_error(f"Error saving network rules: {e}")
    
    async def stop_monitoring(self):
        """Stop network monitoring"""
        if not self.is_monitoring:
            return
        
        self.logger.log_info("Stopping network monitoring")
        
        self.is_monitoring = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=5)
        
        if self.packet_queue:
            self.packet_queue.unbind()
        
        self.logger.log_info("Network monitoring stopped")
    
    def get_monitoring_stats(self) -> Dict:
        """Get network monitoring statistics"""
        return {
            "is_monitoring": self.is_monitoring,
            "blocked_ips_count": len(self.blocked_ips),
            "blocked_ports_count": len(self.blocked_ports),
            "blocked_domains_count": len(self.blocked_domains),
            **self.stats
        }
    
    async def export_network_rules(self, export_path: Path):
        """Export network rules to file"""
        try:
            rules = {
                "blocked_ips": list(self.blocked_ips),
                "blocked_ports": list(self.blocked_ports),
                "blocked_domains": list(self.blocked_domains),
                "suspicious_patterns": list(self.suspicious_patterns)
            }
            
            with open(export_path, 'w') as f:
                json.dump(rules, f, indent=2)
            
            self.logger.log_info(f"Network rules exported to: {export_path}")
            return True
            
        except Exception as e:
            self.logger.log_error(f"Failed to export network rules: {e}")
            return False
