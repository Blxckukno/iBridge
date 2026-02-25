
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
Threat Intelligence Manager
Manages threat intelligence feeds, indicators, and analysis
"""

import sqlite3
import threading
import time
import json
import requests
import hashlib
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple, Set
from dataclasses import dataclass
from enum import Enum
import logging
import uuid
import os

class IndicatorType(Enum):
    """Types of threat indicators"""
    IP_ADDRESS = "ip_address"
    DOMAIN = "domain"
    URL = "url"
    FILE_HASH = "file_hash"
    EMAIL = "email"
    FILENAME = "filename"
    REGISTRY_KEY = "registry_key"
    MUTEX = "mutex"
    PROCESS_NAME = "process_name"

class ThreatType(Enum):
    """Types of threats"""
    MALWARE = "malware"
    RANSOMWARE = "ransomware"
    TROJAN = "trojan"
    BOTNET = "botnet"
    PHISHING = "phishing"
    SPAM = "spam"
    C2_SERVER = "c2_server"
    EXPLOIT_KIT = "exploit_kit"
    APT = "apt"
    CRYPTOCURRENCY_MINING = "cryptocurrency_mining"

class ConfidenceLevel(Enum):
    """Confidence levels for threat intelligence"""
    LOW = 25
    MEDIUM = 50
    HIGH = 75
    VERY_HIGH = 90

@dataclass
class ThreatIndicator:
    """Threat intelligence indicator"""
    indicator_id: str
    indicator_type: IndicatorType
    indicator_value: str
    threat_type: ThreatType
    confidence: ConfidenceLevel
    severity: str
    source: str
    first_seen: datetime
    last_seen: datetime
    tags: List[str]
    metadata: Optional[Dict[str, Any]] = None

@dataclass
class ThreatFeed:
    """Threat intelligence feed configuration"""
    feed_id: str
    name: str
    url: str
    feed_type: str
    enabled: bool
    update_interval: int  # seconds
    last_update: Optional[datetime] = None
    authentication: Optional[Dict[str, str]] = None

class ThreatIntelligenceManager:
    """
    Advanced Threat Intelligence Management System
    Manages threat intelligence feeds, indicators, and provides lookup services
    """
    
    def __init__(self, db_path: str = "threat_intelligence.db"):
        self.db_path = db_path
        self.indicators = {}  # Cache for quick lookups
        self.feeds = {}
        self.running = False
        self.update_thread = None
        
        # Initialize logging
        self.logger = logging.getLogger(__name__)
        
        # Initialize database
        self._init_database()
        
        # Load existing data
        self._load_indicators()
        self._load_feeds()
        
        # Performance metrics
        self.metrics = {
            'total_indicators': 0,
            'lookups_performed': 0,
            'cache_hits': 0,
            'cache_misses': 0,
            'feeds_updated': 0,
            'last_update': datetime.now()
        }
        
        # Built-in threat feeds
        self._initialize_default_feeds()
        
        self.logger.info("Threat Intelligence Manager initialized")
    
    def _init_database(self):
        """Initialize the threat intelligence database"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Threat indicators table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS threat_indicators (
                indicator_id TEXT PRIMARY KEY,
                indicator_type TEXT NOT NULL,
                indicator_value TEXT NOT NULL,
                threat_type TEXT NOT NULL,
                confidence INTEGER NOT NULL,
                severity TEXT NOT NULL,
                source TEXT NOT NULL,
                first_seen TEXT NOT NULL,
                last_seen TEXT NOT NULL,
                tags TEXT,
                metadata TEXT
            )
        ''')
        
        # Create index for fast lookups
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_indicator_value 
            ON threat_indicators (indicator_value)
        ''')
        
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_indicator_type 
            ON threat_indicators (indicator_type)
        ''')
        
        # Threat feeds table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS threat_feeds (
                feed_id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                url TEXT NOT NULL,
                feed_type TEXT NOT NULL,
                enabled INTEGER DEFAULT 1,
                update_interval INTEGER DEFAULT 3600,
                last_update TEXT,
                authentication TEXT
            )
        ''')
        
        # Feed update logs
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS feed_updates (
                update_id TEXT PRIMARY KEY,
                feed_id TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                status TEXT NOT NULL,
                indicators_added INTEGER DEFAULT 0,
                indicators_updated INTEGER DEFAULT 0,
                error_message TEXT,
                FOREIGN KEY (feed_id) REFERENCES threat_feeds (feed_id)
            )
        ''')
        
        # Threat lookups log
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS threat_lookups (
                lookup_id TEXT PRIMARY KEY,
                timestamp TEXT NOT NULL,
                indicator_value TEXT NOT NULL,
                indicator_type TEXT NOT NULL,
                result TEXT NOT NULL,
                source TEXT NOT NULL,
                response_time REAL
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def _load_indicators(self):
        """Load threat indicators from database into cache"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM threat_indicators")
        for row in cursor.fetchall():
            indicator = ThreatIndicator(
                indicator_id=row[0],
                indicator_type=IndicatorType(row[1]),
                indicator_value=row[2],
                threat_type=ThreatType(row[3]),
                confidence=ConfidenceLevel(row[4]),
                severity=row[5],
                source=row[6],
                first_seen=datetime.fromisoformat(row[7]),
                last_seen=datetime.fromisoformat(row[8]),
                tags=json.loads(row[9]) if row[9] else [],
                metadata=json.loads(row[10]) if row[10] else {}
            )
            
            # Add to cache
            cache_key = f"{indicator.indicator_type.value}:{indicator.indicator_value}"
            self.indicators[cache_key] = indicator
        
        conn.close()
        self.metrics['total_indicators'] = len(self.indicators)
        self.logger.info(f"Loaded {len(self.indicators)} threat indicators")
    
    def _load_feeds(self):
        """Load threat feeds configuration"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM threat_feeds")
        for row in cursor.fetchall():
            feed = ThreatFeed(
                feed_id=row[0],
                name=row[1],
                url=row[2],
                feed_type=row[3],
                enabled=bool(row[4]),
                update_interval=row[5],
                last_update=datetime.fromisoformat(row[6]) if row[6] else None,
                authentication=json.loads(row[7]) if row[7] else None
            )
            
            self.feeds[feed.feed_id] = feed
        
        conn.close()
        self.logger.info(f"Loaded {len(self.feeds)} threat feeds")
    
    def _initialize_default_feeds(self):
        """Initialize default threat intelligence feeds"""
        default_feeds = [
            {
                'feed_id': 'malware_domains',
                'name': 'Malware Domain List',
                'url': 'https://www.malwaredomainlist.com/hostslist/hosts.txt',
                'feed_type': 'domain_list',
                'enabled': True,
                'update_interval': 3600
            },
            {
                'feed_id': 'emerging_threats_rules',
                'name': 'Emerging Threats Rules',
                'url': 'https://rules.emergingthreats.net/open/suricata/rules/emerging-all.rules',
                'feed_type': 'snort_rules',
                'enabled': True,
                'update_interval': 7200
            },
            {
                'feed_id': 'abuse_ch_malware_urls',
                'name': 'Abuse.ch Malware URLs',
                'url': 'https://urlhaus.abuse.ch/downloads/text/',
                'feed_type': 'url_list',
                'enabled': True,
                'update_interval': 1800
            }
        ]
        
        for feed_config in default_feeds:
            if feed_config['feed_id'] not in self.feeds:
                feed = ThreatFeed(**feed_config)
                self.add_feed(feed)
    
    def add_indicator(self, indicator: ThreatIndicator) -> bool:
        """Add a new threat indicator"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT OR REPLACE INTO threat_indicators
                (indicator_id, indicator_type, indicator_value, threat_type,
                 confidence, severity, source, first_seen, last_seen, tags, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                indicator.indicator_id,
                indicator.indicator_type.value,
                indicator.indicator_value,
                indicator.threat_type.value,
                indicator.confidence.value,
                indicator.severity,
                indicator.source,
                indicator.first_seen.isoformat(),
                indicator.last_seen.isoformat(),
                json.dumps(indicator.tags),
                json.dumps(indicator.metadata or {})
            ))
            
            conn.commit()
            conn.close()
            
            # Update cache
            cache_key = f"{indicator.indicator_type.value}:{indicator.indicator_value}"
            self.indicators[cache_key] = indicator
            self.metrics['total_indicators'] = len(self.indicators)
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error adding indicator: {e}")
            return False
    
    def lookup_indicator(self, indicator_value: str, indicator_type: Optional[IndicatorType] = None) -> List[ThreatIndicator]:
        """Lookup threat intelligence for an indicator"""
        start_time = time.time()
        results = []
        
        self.metrics['lookups_performed'] += 1
        
        if indicator_type:
            # Specific type lookup
            cache_key = f"{indicator_type.value}:{indicator_value}"
            if cache_key in self.indicators:
                results.append(self.indicators[cache_key])
                self.metrics['cache_hits'] += 1
            else:
                self.metrics['cache_misses'] += 1
        else:
            # Search across all types
            for key, indicator in self.indicators.items():
                if indicator.indicator_value == indicator_value:
                    results.append(indicator)
            
            if results:
                self.metrics['cache_hits'] += 1
            else:
                self.metrics['cache_misses'] += 1
        
        response_time = time.time() - start_time
        
        # Log the lookup
        self._log_lookup(indicator_value, indicator_type, len(results), response_time)
        
        return results
    
    def _log_lookup(self, indicator_value: str, indicator_type: Optional[IndicatorType], 
                   result_count: int, response_time: float):
        """Log threat intelligence lookup"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO threat_lookups
                (lookup_id, timestamp, indicator_value, indicator_type, result, source, response_time)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                str(uuid.uuid4()),
                datetime.now().isoformat(),
                indicator_value,
                indicator_type.value if indicator_type else 'any',
                f"matches: {result_count}",
                'local_cache',
                response_time
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Error logging lookup: {e}")
    
    def add_feed(self, feed: ThreatFeed) -> bool:
        """Add a new threat intelligence feed"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT OR REPLACE INTO threat_feeds
                (feed_id, name, url, feed_type, enabled, update_interval, last_update, authentication)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                feed.feed_id,
                feed.name,
                feed.url,
                feed.feed_type,
                int(feed.enabled),
                feed.update_interval,
                feed.last_update.isoformat() if feed.last_update else None,
                json.dumps(feed.authentication or {})
            ))
            
            conn.commit()
            conn.close()
            
            # Add to memory
            self.feeds[feed.feed_id] = feed
            
            self.logger.info(f"Added threat feed: {feed.name}")
            return True
            
        except Exception as e:
            self.logger.error(f"Error adding feed: {e}")
            return False
    
    def start_feed_updates(self):
        """Start automatic threat feed updates"""
        if self.running:
            return
        
        self.running = True
        self.update_thread = threading.Thread(target=self._update_feeds_loop, daemon=True)
        self.update_thread.start()
        self.logger.info("Started threat feed updates")
    
    def stop_feed_updates(self):
        """Stop automatic threat feed updates"""
        self.running = False
        if self.update_thread:
            self.update_thread.join(timeout=30)
        self.logger.info("Stopped threat feed updates")
    
    def _update_feeds_loop(self):
        """Main loop for updating threat feeds"""
        while self.running:
            try:
                current_time = datetime.now()
                
                for feed_id, feed in self.feeds.items():
                    if not feed.enabled:
                        continue
                    
                    # Check if update is due
                    if (feed.last_update is None or 
                        current_time - feed.last_update >= timedelta(seconds=feed.update_interval)):
                        
                        self._update_feed(feed)
                
                # Sleep for 60 seconds before checking again
                time.sleep(60)
                
            except Exception as e:
                self.logger.error(f"Error in feed update loop: {e}")
                time.sleep(300)  # Wait 5 minutes on error
    
    def _update_feed(self, feed: ThreatFeed):
        """Update a specific threat feed"""
        self.logger.info(f"Updating threat feed: {feed.name}")
        update_id = str(uuid.uuid4())
        
        try:
            # Download feed data
            headers = {}
            if feed.authentication:
                if 'api_key' in feed.authentication:
                    headers['X-API-Key'] = feed.authentication['api_key']
                elif 'bearer_token' in feed.authentication:
                    headers['Authorization'] = f"Bearer {feed.authentication['bearer_token']}"
            
            response = requests.get(feed.url, headers=headers, timeout=30)
            response.raise_for_status()
            
            # Parse feed data based on type
            indicators_added = 0
            indicators_updated = 0
            
            if feed.feed_type == 'domain_list':
                indicators_added, indicators_updated = self._parse_domain_list(
                    response.text, feed.name
                )
            elif feed.feed_type == 'url_list':
                indicators_added, indicators_updated = self._parse_url_list(
                    response.text, feed.name
                )
            elif feed.feed_type == 'ip_list':
                indicators_added, indicators_updated = self._parse_ip_list(
                    response.text, feed.name
                )
            elif feed.feed_type == 'json':
                indicators_added, indicators_updated = self._parse_json_feed(
                    response.json(), feed.name
                )
            
            # Update feed timestamp
            feed.last_update = datetime.now()
            self._update_feed_timestamp(feed)
            
            # Log successful update
            self._log_feed_update(update_id, feed.feed_id, 'success', 
                                indicators_added, indicators_updated)
            
            self.metrics['feeds_updated'] += 1
            self.logger.info(f"Successfully updated {feed.name}: "
                           f"{indicators_added} added, {indicators_updated} updated")
            
        except Exception as e:
            error_msg = f"Error updating feed {feed.name}: {e}"
            self.logger.error(error_msg)
            
            # Log failed update
            self._log_feed_update(update_id, feed.feed_id, 'failed', 0, 0, str(e))
    
    def _parse_domain_list(self, content: str, source: str) -> Tuple[int, int]:
        """Parse domain list format"""
        added = 0
        updated = 0
        
        for line in content.split('\n'):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            # Extract domain from various formats
            domain = None
            if line.startswith('0.0.0.0 '):
                domain = line.split(' ', 1)[1]
            elif line.startswith('127.0.0.1 '):
                domain = line.split(' ', 1)[1]
            else:
                domain = line
            
            if domain and self._is_valid_domain(domain):
                indicator = ThreatIndicator(
                    indicator_id=str(uuid.uuid4()),
                    indicator_type=IndicatorType.DOMAIN,
                    indicator_value=domain,
                    threat_type=ThreatType.MALWARE,
                    confidence=ConfidenceLevel.MEDIUM,
                    severity='medium',
                    source=source,
                    first_seen=datetime.now(),
                    last_seen=datetime.now(),
                    tags=['malware', 'domain']
                )
                
                if self.add_indicator(indicator):
                    added += 1
        
        return added, updated
    
    def _parse_url_list(self, content: str, source: str) -> Tuple[int, int]:
        """Parse URL list format"""
        added = 0
        updated = 0
        
        for line in content.split('\n'):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            if self._is_valid_url(line):
                indicator = ThreatIndicator(
                    indicator_id=str(uuid.uuid4()),
                    indicator_type=IndicatorType.URL,
                    indicator_value=line,
                    threat_type=ThreatType.MALWARE,
                    confidence=ConfidenceLevel.HIGH,
                    severity='high',
                    source=source,
                    first_seen=datetime.now(),
                    last_seen=datetime.now(),
                    tags=['malware', 'url']
                )
                
                if self.add_indicator(indicator):
                    added += 1
        
        return added, updated
    
    def _parse_ip_list(self, content: str, source: str) -> Tuple[int, int]:
        """Parse IP address list format"""
        added = 0
        updated = 0
        
        for line in content.split('\n'):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            if self._is_valid_ip(line):
                indicator = ThreatIndicator(
                    indicator_id=str(uuid.uuid4()),
                    indicator_type=IndicatorType.IP_ADDRESS,
                    indicator_value=line,
                    threat_type=ThreatType.MALWARE,
                    confidence=ConfidenceLevel.MEDIUM,
                    severity='medium',
                    source=source,
                    first_seen=datetime.now(),
                    last_seen=datetime.now(),
                    tags=['malware', 'ip']
                )
                
                if self.add_indicator(indicator):
                    added += 1
        
        return added, updated
    
    def _parse_json_feed(self, data: Dict[str, Any], source: str) -> Tuple[int, int]:
        """Parse JSON format threat feed"""
        added = 0
        updated = 0
        
        if 'indicators' in data:
            for item in data['indicators']:
                try:
                    indicator = ThreatIndicator(
                        indicator_id=item.get('id', str(uuid.uuid4())),
                        indicator_type=IndicatorType(item['type']),
                        indicator_value=item['value'],
                        threat_type=ThreatType(item.get('threat_type', 'malware')),
                        confidence=ConfidenceLevel(item.get('confidence', 50)),
                        severity=item.get('severity', 'medium'),
                        source=source,
                        first_seen=datetime.fromisoformat(item.get('first_seen', datetime.now().isoformat())),
                        last_seen=datetime.fromisoformat(item.get('last_seen', datetime.now().isoformat())),
                        tags=item.get('tags', []),
                        metadata=item.get('metadata', {})
                    )
                    
                    if self.add_indicator(indicator):
                        added += 1
                        
                except Exception as e:
                    self.logger.error(f"Error parsing indicator: {e}")
                    continue
        
        return added, updated
    
    def _is_valid_domain(self, domain: str) -> bool:
        """Validate domain format"""
        import re
        pattern = r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
        return bool(re.match(pattern, domain)) and len(domain) <= 255
    
    def _is_valid_url(self, url: str) -> bool:
        """Validate URL format"""
        import re
        pattern = r'^https?://[^\s/$.?#].[^\s]*$'
        return bool(re.match(pattern, url))
    
    def _is_valid_ip(self, ip: str) -> bool:
        """Validate IP address format"""
        import ipaddress
        try:
            ipaddress.ip_address(ip)
            return True
        except ValueError:
            return False
    
    def _update_feed_timestamp(self, feed: ThreatFeed):
        """Update feed last_update timestamp"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                UPDATE threat_feeds SET last_update = ? WHERE feed_id = ?
            ''', (feed.last_update.isoformat() if feed.last_update else datetime.now().isoformat(), feed.feed_id))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Error updating feed timestamp: {e}")
    
    def _log_feed_update(self, update_id: str, feed_id: str, status: str,
                        indicators_added: int = 0, indicators_updated: int = 0,
                        error_message: Optional[str] = None):
        """Log feed update results"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT INTO feed_updates
                (update_id, feed_id, timestamp, status, indicators_added,
                 indicators_updated, error_message)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                update_id,
                feed_id,
                datetime.now().isoformat(),
                status,
                indicators_added,
                indicators_updated,
                error_message
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Error logging feed update: {e}")
    
    def get_feed_status(self) -> Dict[str, Any]:
        """Get status of all threat feeds"""
        status = {}
        
        for feed_id, feed in self.feeds.items():
            status[feed_id] = {
                'name': feed.name,
                'enabled': feed.enabled,
                'last_update': feed.last_update.isoformat() if feed.last_update else None,
                'update_interval': feed.update_interval,
                'next_update': (feed.last_update + timedelta(seconds=feed.update_interval)).isoformat() 
                              if feed.last_update else None
            }
        
        return status
    
    def get_threat_statistics(self) -> Dict[str, Any]:
        """Get threat intelligence statistics"""
        # Count indicators by type
        type_counts = {}
        threat_counts = {}
        
        for indicator in self.indicators.values():
            indicator_type = indicator.indicator_type.value
            threat_type = indicator.threat_type.value
            
            type_counts[indicator_type] = type_counts.get(indicator_type, 0) + 1
            threat_counts[threat_type] = threat_counts.get(threat_type, 0) + 1
        
        return {
            'total_indicators': len(self.indicators),
            'indicators_by_type': type_counts,
            'threats_by_type': threat_counts,
            'total_feeds': len(self.feeds),
            'enabled_feeds': sum(1 for f in self.feeds.values() if f.enabled),
            'performance_metrics': self.metrics
        }
    
    def search_indicators(self, query: str, indicator_type: Optional[IndicatorType] = None,
                         threat_type: Optional[ThreatType] = None,
                         min_confidence: Optional[ConfidenceLevel] = None) -> List[ThreatIndicator]:
        """Search threat indicators with filters"""
        results = []
        
        for indicator in self.indicators.values():
            # Type filter
            if indicator_type and indicator.indicator_type != indicator_type:
                continue
            
            # Threat type filter
            if threat_type and indicator.threat_type != threat_type:
                continue
            
            # Confidence filter
            if min_confidence and indicator.confidence.value < min_confidence.value:
                continue
            
            # Text search
            if (query.lower() in indicator.indicator_value.lower() or
                query.lower() in indicator.source.lower() or
                any(query.lower() in tag.lower() for tag in indicator.tags)):
                results.append(indicator)
        
        return results
    
    def get_recent_updates(self, hours: int = 24) -> List[Dict[str, Any]]:
        """Get recent feed updates"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        since_time = (datetime.now() - timedelta(hours=hours)).isoformat()
        cursor.execute('''
            SELECT * FROM feed_updates 
            WHERE timestamp > ? 
            ORDER BY timestamp DESC
        ''', (since_time,))
        
        updates = []
        for row in cursor.fetchall():
            updates.append({
                'update_id': row[0],
                'feed_id': row[1],
                'timestamp': row[2],
                'status': row[3],
                'indicators_added': row[4],
                'indicators_updated': row[5],
                'error_message': row[6]
            })
        
        conn.close()
        return updates
    
    def bulk_lookup(self, indicators: List[Tuple[str, IndicatorType]]) -> Dict[str, List[ThreatIndicator]]:
        """Perform bulk lookup of multiple indicators"""
        results = {}
        
        for indicator_value, indicator_type in indicators:
            matches = self.lookup_indicator(indicator_value, indicator_type)
            if matches:
                results[indicator_value] = matches
        
        return results
    
    def export_indicators(self, format_type: str = 'json') -> str:
        """Export threat indicators in specified format"""
        if format_type == 'json':
            indicators_data = []
            for indicator in self.indicators.values():
                data = {
                    'id': indicator.indicator_id,
                    'type': indicator.indicator_type.value,
                    'value': indicator.indicator_value,
                    'threat_type': indicator.threat_type.value,
                    'confidence': indicator.confidence.value,
                    'severity': indicator.severity,
                    'source': indicator.source,
                    'first_seen': indicator.first_seen.isoformat(),
                    'last_seen': indicator.last_seen.isoformat(),
                    'tags': indicator.tags,
                    'metadata': indicator.metadata
                }
                indicators_data.append(data)
            
            return json.dumps({'indicators': indicators_data}, indent=2)
        
        elif format_type == 'csv':
            import csv
            import io
            
            output = io.StringIO()
            writer = csv.writer(output)
            
            # Header
            writer.writerow(['ID', 'Type', 'Value', 'Threat Type', 'Confidence', 
                           'Severity', 'Source', 'First Seen', 'Last Seen', 'Tags'])
            
            # Data
            for indicator in self.indicators.values():
                writer.writerow([
                    indicator.indicator_id,
                    indicator.indicator_type.value,
                    indicator.indicator_value,
                    indicator.threat_type.value,
                    indicator.confidence.value,
                    indicator.severity,
                    indicator.source,
                    indicator.first_seen.isoformat(),
                    indicator.last_seen.isoformat(),
                    ','.join(indicator.tags)
                ])
            
            return output.getvalue()
        
        else:
            raise ValueError(f"Unsupported export format: {format_type}")
    
    def shutdown(self):
        """Shutdown the threat intelligence manager"""
        self.logger.info("Shutting down Threat Intelligence Manager")
        self.stop_feed_updates()
        self.indicators.clear()
        self.feeds.clear()