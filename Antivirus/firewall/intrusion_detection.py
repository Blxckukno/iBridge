"""
Intrusion Detection System (IDS)
Advanced threat detection and pattern analysis
"""

import time
import threading
import json
import sqlite3
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Set, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
import ipaddress
import re
import hashlib

class ThreatType(Enum):
    """Types of security threats"""
    PORT_SCAN = "port_scan"
    BRUTE_FORCE = "brute_force"
    DOS_ATTACK = "dos_attack"
    DDOS_ATTACK = "ddos_attack"
    MALWARE_SIGNATURE = "malware_signature"
    SUSPICIOUS_TRAFFIC = "suspicious_traffic"
    ANOMALOUS_BEHAVIOR = "anomalous_behavior"
    KNOWN_MALICIOUS_IP = "known_malicious_ip"
    PROTOCOL_VIOLATION = "protocol_violation"
    DATA_EXFILTRATION = "data_exfiltration"

class ThreatSeverity(Enum):
    """Severity levels for threats"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

@dataclass
class ThreatSignature:
    """Signature for threat detection"""
    signature_id: str
    name: str
    description: str
    threat_type: ThreatType
    severity: ThreatSeverity
    pattern: str
    pattern_type: str  # regex, bytes, header, etc.
    enabled: bool = True
    created_date: Optional[datetime] = None
    last_updated: Optional[datetime] = None
    match_count: int = 0
    
    def __post_init__(self):
        if self.created_date is None:
            self.created_date = datetime.now()
        if self.last_updated is None:
            self.last_updated = datetime.now()

@dataclass
class ThreatEvent:
    """Detected threat event"""
    event_id: str
    threat_type: ThreatType
    severity: ThreatSeverity
    source_ip: str
    destination_ip: str
    source_port: int
    destination_port: int
    protocol: str
    description: str
    signature_id: Optional[str] = None
    timestamp: Optional[datetime] = None
    confidence: float = 0.0
    additional_data: Optional[Dict[str, Any]] = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()
        if self.additional_data is None:
            self.additional_data = {}

class AttackDetector:
    """Detects various types of network attacks"""
    
    def __init__(self):
        self.connection_attempts = {}
        self.packet_counts = {}
        self.failed_logins = {}
        self.port_scan_threshold = 20
        self.dos_packet_threshold = 1000
        self.brute_force_threshold = 10
        self.time_window = 60  # seconds
    
    def detect_port_scan(self, packet) -> Optional[ThreatEvent]:
        """Detect port scanning attacks"""
        source_ip = packet.source_ip
        current_time = time.time()
        
        # Initialize tracking for this IP
        if source_ip not in self.connection_attempts:
            self.connection_attempts[source_ip] = []
        
        # Clean old entries
        cutoff_time = current_time - self.time_window
        self.connection_attempts[source_ip] = [
            (timestamp, port) for timestamp, port in self.connection_attempts[source_ip]
            if timestamp > cutoff_time
        ]
        
        # Add current connection attempt
        if packet.is_tcp() and packet.is_syn() and not packet.is_ack():
            self.connection_attempts[source_ip].append((current_time, packet.destination_port))
        
        # Check for port scan
        unique_ports = set(port for _, port in self.connection_attempts[source_ip])
        if len(unique_ports) >= self.port_scan_threshold:
            return ThreatEvent(
                event_id=self._generate_event_id(),
                threat_type=ThreatType.PORT_SCAN,
                severity=ThreatSeverity.MEDIUM,
                source_ip=source_ip,
                destination_ip=packet.destination_ip,
                source_port=packet.source_port,
                destination_port=packet.destination_port,
                protocol=packet.protocol,
                description=f"Port scan detected from {source_ip}. {len(unique_ports)} unique ports scanned.",
                confidence=0.8,
                additional_data={
                    'scanned_ports': list(unique_ports),
                    'scan_duration': self.time_window,
                    'total_attempts': len(self.connection_attempts[source_ip])
                }
            )
        
        return None
    
    def detect_dos_attack(self, packet) -> Optional[ThreatEvent]:
        """Detect DoS/DDoS attacks based on packet rate"""
        source_ip = packet.source_ip
        current_time = time.time()
        
        # Initialize tracking for this IP
        if source_ip not in self.packet_counts:
            self.packet_counts[source_ip] = []
        
        # Clean old entries
        cutoff_time = current_time - self.time_window
        self.packet_counts[source_ip] = [
            timestamp for timestamp in self.packet_counts[source_ip]
            if timestamp > cutoff_time
        ]
        
        # Add current packet
        self.packet_counts[source_ip].append(current_time)
        
        # Check for DoS attack
        packet_count = len(self.packet_counts[source_ip])
        if packet_count >= self.dos_packet_threshold:
            severity = ThreatSeverity.HIGH if packet_count >= self.dos_packet_threshold * 2 else ThreatSeverity.MEDIUM
            
            return ThreatEvent(
                event_id=self._generate_event_id(),
                threat_type=ThreatType.DOS_ATTACK,
                severity=severity,
                source_ip=source_ip,
                destination_ip=packet.destination_ip,
                source_port=packet.source_port,
                destination_port=packet.destination_port,
                protocol=packet.protocol,
                description=f"DoS attack detected from {source_ip}. {packet_count} packets in {self.time_window} seconds.",
                confidence=0.9,
                additional_data={
                    'packet_rate': packet_count / self.time_window,
                    'threshold': self.dos_packet_threshold,
                    'time_window': self.time_window
                }
            )
        
        return None
    
    def detect_brute_force(self, packet) -> Optional[ThreatEvent]:
        """Detect brute force attacks on common services"""
        # Focus on common authentication ports
        auth_ports = {21, 22, 23, 25, 110, 143, 993, 995, 1433, 3389}
        
        if packet.destination_port not in auth_ports:
            return None
        
        source_ip = packet.source_ip
        dest_port = packet.destination_port
        current_time = time.time()
        
        key = f"{source_ip}:{dest_port}"
        
        # Initialize tracking
        if key not in self.failed_logins:
            self.failed_logins[key] = []
        
        # Clean old entries
        cutoff_time = current_time - self.time_window
        self.failed_logins[key] = [
            timestamp for timestamp in self.failed_logins[key]
            if timestamp > cutoff_time
        ]
        
        # Simulate failed login detection (in real implementation, would parse application layer)
        if packet.is_tcp() and packet.is_rst():
            self.failed_logins[key].append(current_time)
        
        # Check for brute force
        attempt_count = len(self.failed_logins[key])
        if attempt_count >= self.brute_force_threshold:
            service_names = {
                21: "FTP", 22: "SSH", 23: "Telnet", 25: "SMTP",
                110: "POP3", 143: "IMAP", 993: "IMAPS", 995: "POP3S",
                1433: "SQL Server", 3389: "RDP"
            }
            
            service = service_names.get(dest_port, f"Port {dest_port}")
            
            return ThreatEvent(
                event_id=self._generate_event_id(),
                threat_type=ThreatType.BRUTE_FORCE,
                severity=ThreatSeverity.HIGH,
                source_ip=source_ip,
                destination_ip=packet.destination_ip,
                source_port=packet.source_port,
                destination_port=dest_port,
                protocol=packet.protocol,
                description=f"Brute force attack detected against {service} from {source_ip}. {attempt_count} failed attempts.",
                confidence=0.85,
                additional_data={
                    'service': service,
                    'attempt_count': attempt_count,
                    'threshold': self.brute_force_threshold,
                    'time_window': self.time_window
                }
            )
        
        return None
    
    def _generate_event_id(self) -> str:
        """Generate unique event ID"""
        import uuid
        return str(uuid.uuid4())[:12]

class SignatureEngine:
    """Pattern matching engine for threat signatures"""
    
    def __init__(self):
        self.signatures: List[ThreatSignature] = []
        self.compiled_patterns = {}
        self._load_default_signatures()
    
    def _load_default_signatures(self):
        """Load default threat signatures"""
        default_signatures = [
            # Malware signatures
            ThreatSignature(
                signature_id="MAL001",
                name="Suspicious Executable Download",
                description="Detection of executable file downloads",
                threat_type=ThreatType.MALWARE_SIGNATURE,
                severity=ThreatSeverity.HIGH,
                pattern=r"\.exe|\.scr|\.bat|\.cmd|\.pif",
                pattern_type="regex"
            ),
            
            # Protocol violations
            ThreatSignature(
                signature_id="PROT001",
                name="HTTP Request in DNS Traffic",
                description="HTTP request detected in DNS traffic",
                threat_type=ThreatType.PROTOCOL_VIOLATION,
                severity=ThreatSeverity.MEDIUM,
                pattern=r"GET|POST|PUT|DELETE",
                pattern_type="regex"
            ),
            
            # Suspicious traffic patterns
            ThreatSignature(
                signature_id="SUSP001",
                name="Base64 Encoded Payload",
                description="Large base64 encoded payload detected",
                threat_type=ThreatType.SUSPICIOUS_TRAFFIC,
                severity=ThreatSeverity.MEDIUM,
                pattern=r"[A-Za-z0-9+/]{100,}={0,2}",
                pattern_type="regex"
            ),
            
            # Known attack patterns
            ThreatSignature(
                signature_id="ATK001",
                name="SQL Injection Attempt",
                description="Potential SQL injection in HTTP traffic",
                threat_type=ThreatType.SUSPICIOUS_TRAFFIC,
                severity=ThreatSeverity.HIGH,
                pattern=r"(union|select|insert|delete|update|drop|create|alter)\s",
                pattern_type="regex"
            )
        ]
        
        for sig in default_signatures:
            self.add_signature(sig)
    
    def add_signature(self, signature: ThreatSignature):
        """Add a new threat signature"""
        self.signatures.append(signature)
        
        # Compile regex patterns for performance
        if signature.pattern_type == "regex":
            try:
                self.compiled_patterns[signature.signature_id] = re.compile(
                    signature.pattern, re.IGNORECASE
                )
            except re.error:
                print(f"Invalid regex pattern for signature {signature.signature_id}")
    
    def remove_signature(self, signature_id: str) -> bool:
        """Remove a threat signature"""
        for i, sig in enumerate(self.signatures):
            if sig.signature_id == signature_id:
                del self.signatures[i]
                if signature_id in self.compiled_patterns:
                    del self.compiled_patterns[signature_id]
                return True
        return False
    
    def match_signatures(self, packet) -> List[ThreatEvent]:
        """Match packet against all signatures"""
        threats = []
        
        for signature in self.signatures:
            if not signature.enabled:
                continue
            
            if self._matches_signature(packet, signature):
                signature.match_count += 1
                signature.last_updated = datetime.now()
                
                threat = ThreatEvent(
                    event_id=self._generate_event_id(),
                    threat_type=signature.threat_type,
                    severity=signature.severity,
                    source_ip=packet.source_ip,
                    destination_ip=packet.destination_ip,
                    source_port=packet.source_port,
                    destination_port=packet.destination_port,
                    protocol=packet.protocol,
                    description=signature.description,
                    signature_id=signature.signature_id,
                    confidence=0.7,
                    additional_data={
                        'signature_name': signature.name,
                        'pattern': signature.pattern,
                        'pattern_type': signature.pattern_type
                    }
                )
                
                threats.append(threat)
        
        return threats
    
    def _matches_signature(self, packet, signature: ThreatSignature) -> bool:
        """Check if packet matches a signature"""
        try:
            if signature.pattern_type == "regex":
                pattern = self.compiled_patterns.get(signature.signature_id)
                if pattern:
                    # Check payload data
                    if hasattr(packet, 'data') and packet.data:
                        payload_str = packet.data.decode('utf-8', errors='ignore')
                        if pattern.search(payload_str):
                            return True
                    
                    # Check header information
                    header_str = f"{packet.source_ip}:{packet.source_port}->{packet.destination_ip}:{packet.destination_port}"
                    if pattern.search(header_str):
                        return True
            
            elif signature.pattern_type == "bytes":
                if hasattr(packet, 'data') and packet.data:
                    pattern_bytes = bytes.fromhex(signature.pattern)
                    if pattern_bytes in packet.data:
                        return True
            
            elif signature.pattern_type == "header":
                # Match against packet headers
                if signature.pattern in f"{packet.protocol}:{packet.destination_port}":
                    return True
        
        except Exception:
            # Pattern matching failed
            pass
        
        return False
    
    def _generate_event_id(self) -> str:
        """Generate unique event ID"""
        import uuid
        return str(uuid.uuid4())[:12]
    
    def get_signature_statistics(self) -> Dict[str, Any]:
        """Get signature matching statistics"""
        total_signatures = len(self.signatures)
        enabled_signatures = len([s for s in self.signatures if s.enabled])
        total_matches = sum(s.match_count for s in self.signatures)
        
        by_type = {}
        by_severity = {}
        
        for sig in self.signatures:
            threat_type = sig.threat_type.value
            severity = sig.severity.value
            
            by_type[threat_type] = by_type.get(threat_type, 0) + 1
            by_severity[severity] = by_severity.get(severity, 0) + 1
        
        return {
            'total_signatures': total_signatures,
            'enabled_signatures': enabled_signatures,
            'total_matches': total_matches,
            'signatures_by_type': by_type,
            'signatures_by_severity': by_severity
        }

class ThreatIntelligence:
    """Threat intelligence and reputation system"""
    
    def __init__(self):
        self.malicious_ips: Set[str] = set()
        self.reputation_cache = {}
        self.cache_expiry = 3600  # 1 hour
        self._load_threat_feeds()
    
    def _load_threat_feeds(self):
        """Load threat intelligence feeds"""
        # Simulated malicious IPs (in real implementation, would load from feeds)
        sample_malicious_ips = [
            "10.0.0.1",  # Example malicious IPs
            "192.168.1.100",
            "172.16.0.1"
        ]
        
        self.malicious_ips.update(sample_malicious_ips)
    
    def check_ip_reputation(self, ip_address: str) -> Tuple[bool, str, float]:
        """Check IP address reputation"""
        current_time = time.time()
        
        # Check cache first
        if ip_address in self.reputation_cache:
            cache_entry = self.reputation_cache[ip_address]
            if current_time - cache_entry['timestamp'] < self.cache_expiry:
                return cache_entry['is_malicious'], cache_entry['reason'], cache_entry['confidence']
        
        # Check against known malicious IPs
        is_malicious = ip_address in self.malicious_ips
        reason = "Known malicious IP" if is_malicious else "Clean"
        confidence = 0.95 if is_malicious else 0.1
        
        # Additional checks
        try:
            ip_obj = ipaddress.ip_address(ip_address)
            
            # Check for private/local IPs
            if ip_obj.is_private:
                reason = "Private IP"
                confidence = 0.1
            elif ip_obj.is_loopback:
                reason = "Loopback IP"
                confidence = 0.0
            elif ip_obj.is_reserved:
                reason = "Reserved IP"
                confidence = 0.2
        
        except ValueError:
            is_malicious = True
            reason = "Invalid IP address"
            confidence = 1.0
        
        # Cache the result
        self.reputation_cache[ip_address] = {
            'is_malicious': is_malicious,
            'reason': reason,
            'confidence': confidence,
            'timestamp': current_time
        }
        
        return is_malicious, reason, confidence
    
    def add_malicious_ip(self, ip_address: str):
        """Add IP to malicious list"""
        try:
            ipaddress.ip_address(ip_address)
            self.malicious_ips.add(ip_address)
            # Invalidate cache entry
            if ip_address in self.reputation_cache:
                del self.reputation_cache[ip_address]
        except ValueError:
            raise ValueError(f"Invalid IP address: {ip_address}")
    
    def remove_malicious_ip(self, ip_address: str):
        """Remove IP from malicious list"""
        self.malicious_ips.discard(ip_address)
        # Invalidate cache entry
        if ip_address in self.reputation_cache:
            del self.reputation_cache[ip_address]

class IntrusionDetectionSystem:
    """Main IDS engine coordinating all detection components"""
    
    def __init__(self, config_path: Optional[str] = None):
        self.config_path = config_path or "ids_config.db"
        self.is_active = False
        self.attack_detector = AttackDetector()
        self.signature_engine = SignatureEngine()
        self.threat_intelligence = ThreatIntelligence()
        self.detected_threats: List[ThreatEvent] = []
        self.max_threat_history = 10000
        self.statistics = {
            'packets_analyzed': 0,
            'threats_detected': 0,
            'false_positives': 0,
            'start_time': None
        }
        
        self._setup_database()
    
    def _setup_database(self):
        """Setup SQLite database for IDS data"""
        try:
            with sqlite3.connect(self.config_path) as conn:
                conn.execute('''
                    CREATE TABLE IF NOT EXISTS threat_events (
                        event_id TEXT PRIMARY KEY,
                        threat_type TEXT NOT NULL,
                        severity TEXT NOT NULL,
                        source_ip TEXT NOT NULL,
                        destination_ip TEXT NOT NULL,
                        source_port INTEGER,
                        destination_port INTEGER,
                        protocol TEXT,
                        description TEXT,
                        signature_id TEXT,
                        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        confidence REAL,
                        additional_data TEXT
                    )
                ''')
                
                conn.execute('''
                    CREATE TABLE IF NOT EXISTS threat_signatures (
                        signature_id TEXT PRIMARY KEY,
                        name TEXT NOT NULL,
                        description TEXT,
                        threat_type TEXT NOT NULL,
                        severity TEXT NOT NULL,
                        pattern TEXT NOT NULL,
                        pattern_type TEXT NOT NULL,
                        enabled BOOLEAN DEFAULT 1,
                        created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        match_count INTEGER DEFAULT 0
                    )
                ''')
                
                conn.commit()
        except Exception as e:
            print(f"Error setting up IDS database: {e}")
    
    def start(self):
        """Start the IDS"""
        self.is_active = True
        self.statistics['start_time'] = datetime.now()
        print("Intrusion Detection System started")
    
    def stop(self):
        """Stop the IDS"""
        self.is_active = False
        print("Intrusion Detection System stopped")
    
    def analyze_packet(self, packet) -> List[ThreatEvent]:
        """Analyze packet for threats"""
        if not self.is_active:
            return []
        
        self.statistics['packets_analyzed'] += 1
        threats = []
        
        try:
            # Check IP reputation
            is_malicious, reason, confidence = self.threat_intelligence.check_ip_reputation(packet.source_ip)
            if is_malicious and confidence > 0.8:
                threat = ThreatEvent(
                    event_id=self._generate_event_id(),
                    threat_type=ThreatType.KNOWN_MALICIOUS_IP,
                    severity=ThreatSeverity.HIGH,
                    source_ip=packet.source_ip,
                    destination_ip=packet.destination_ip,
                    source_port=packet.source_port,
                    destination_port=packet.destination_port,
                    protocol=packet.protocol,
                    description=f"Traffic from known malicious IP: {packet.source_ip}",
                    confidence=confidence,
                    additional_data={'reputation_reason': reason}
                )
                threats.append(threat)
            
            # Attack detection
            attack_threats = [
                self.attack_detector.detect_port_scan(packet),
                self.attack_detector.detect_dos_attack(packet),
                self.attack_detector.detect_brute_force(packet)
            ]
            
            threats.extend([t for t in attack_threats if t is not None])
            
            # Signature matching
            signature_threats = self.signature_engine.match_signatures(packet)
            threats.extend(signature_threats)
            
            # Store detected threats
            for threat in threats:
                self.detected_threats.append(threat)
                self._save_threat_to_db(threat)
            
            # Update statistics
            self.statistics['threats_detected'] += len(threats)
            
            # Trim threat history
            if len(self.detected_threats) > self.max_threat_history:
                self.detected_threats = self.detected_threats[-self.max_threat_history//2:]
        
        except Exception as e:
            print(f"Error analyzing packet: {e}")
        
        return threats
    
    def _save_threat_to_db(self, threat: ThreatEvent):
        """Save threat event to database"""
        try:
            with sqlite3.connect(self.config_path) as conn:
                conn.execute('''
                    INSERT INTO threat_events 
                    (event_id, threat_type, severity, source_ip, destination_ip,
                     source_port, destination_port, protocol, description,
                     signature_id, confidence, additional_data)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    threat.event_id, threat.threat_type.value, threat.severity.value,
                    threat.source_ip, threat.destination_ip, threat.source_port,
                    threat.destination_port, threat.protocol, threat.description,
                    threat.signature_id, threat.confidence,
                    json.dumps(threat.additional_data) if threat.additional_data else None
                ))
                conn.commit()
        except Exception as e:
            print(f"Error saving threat to database: {e}")
    
    def get_recent_threats(self, limit: int = 100, 
                          severity_filter: Optional[ThreatSeverity] = None) -> List[ThreatEvent]:
        """Get recent threat events"""
        threats = self.detected_threats[-limit:] if self.detected_threats else []
        
        if severity_filter:
            threats = [t for t in threats if t.severity == severity_filter]
        
        return threats
    
    def get_threat_statistics(self) -> Dict[str, Any]:
        """Get threat detection statistics"""
        stats = self.statistics.copy()
        
        if stats['start_time']:
            stats['uptime_seconds'] = (datetime.now() - stats['start_time']).total_seconds()
        
        # Threat breakdown
        threat_counts = {}
        severity_counts = {}
        
        for threat in self.detected_threats:
            threat_type = threat.threat_type.value
            severity = threat.severity.value
            
            threat_counts[threat_type] = threat_counts.get(threat_type, 0) + 1
            severity_counts[severity] = severity_counts.get(severity, 0) + 1
        
        stats['threats_by_type'] = threat_counts
        stats['threats_by_severity'] = severity_counts
        stats['signature_stats'] = self.signature_engine.get_signature_statistics()
        
        return stats
    
    def get_top_threat_sources(self, limit: int = 10) -> List[Tuple[str, int]]:
        """Get top sources of threats"""
        source_counts = {}
        
        for threat in self.detected_threats:
            source_ip = threat.source_ip
            source_counts[source_ip] = source_counts.get(source_ip, 0) + 1
        
        return sorted(source_counts.items(), key=lambda x: x[1], reverse=True)[:limit]
    
    def add_threat_signature(self, signature: ThreatSignature):
        """Add custom threat signature"""
        self.signature_engine.add_signature(signature)
    
    def remove_threat_signature(self, signature_id: str) -> bool:
        """Remove threat signature"""
        return self.signature_engine.remove_signature(signature_id)
    
    def mark_false_positive(self, event_id: str):
        """Mark threat event as false positive"""
        for threat in self.detected_threats:
            if threat.event_id == event_id:
                self.statistics['false_positives'] += 1
                break
    
    def clear_threat_history(self):
        """Clear threat event history"""
        self.detected_threats.clear()
    
    def _generate_event_id(self) -> str:
        """Generate unique event ID"""
        import uuid
        return str(uuid.uuid4())[:12]