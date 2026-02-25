
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
Advanced Threat Detection Engine
Uses multiple detection methods including signatures, heuristics, and behavioral analysis
"""
import hashlib
import sqlite3
import yara
import pefile
import magic
import asyncio
import threading
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime
import re
import struct

from .config_manager import ConfigManager
from ..logging.security_logger import SecurityLogger


class ThreatDetector:
    """Advanced threat detection using multiple analysis methods"""
    
    def __init__(self, config_manager: ConfigManager, logger: SecurityLogger):
        self.config = config_manager
        self.logger = logger
        
        # Detection databases
        self.signature_db = None
        self.yara_rules = None
        self.hash_database = set()
        self.suspicious_patterns = []
        
        # Detection statistics
        self.detection_stats = {
            "files_scanned": 0,
            "threats_detected": 0,
            "false_positives": 0,
            "last_update": None
        }
        
        # File type detection
        try:
            self.file_magic = magic.Magic(mime=True)
        except:
            self.file_magic = None
            self.logger.log_warning("File magic detection not available")
    
    async def initialize(self):
        """Initialize the threat detection engine"""
        self.logger.log_info("Initializing threat detection engine")
        
        try:
            await self._initialize_signature_database()
            await self._load_yara_rules()
            await self._load_hash_database()
            await self._load_suspicious_patterns()
            
            self.logger.log_info("Threat detection engine initialized")
            
        except Exception as e:
            self.logger.log_error(f"Failed to initialize threat detector: {e}")
            raise
    
    async def _initialize_signature_database(self):
        """Initialize the signature database"""
        db_path = self.config.get_signature_db_path()
        
        self.signature_db = sqlite3.connect(str(db_path), check_same_thread=False)
        cursor = self.signature_db.cursor()
        
        # Create tables if they don't exist
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS signatures (
                id INTEGER PRIMARY KEY,
                name TEXT UNIQUE,
                signature BLOB,
                type TEXT,
                severity INTEGER,
                description TEXT,
                created_date TEXT,
                updated_date TEXT
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS hash_signatures (
                id INTEGER PRIMARY KEY,
                hash_value TEXT UNIQUE,
                hash_type TEXT,
                threat_name TEXT,
                severity INTEGER,
                created_date TEXT
            )
        """)
        
        self.signature_db.commit()
        
        # Load default signatures if database is empty
        cursor.execute("SELECT COUNT(*) FROM signatures")
        if cursor.fetchone()[0] == 0:
            await self._load_default_signatures()
    
    async def _load_default_signatures(self):
        """Load default malware signatures"""
        default_signatures = [
            {
                "name": "EICAR_Test",
                "signature": b"X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*",
                "type": "string",
                "severity": 3,
                "description": "EICAR antivirus test file"
            },
            {
                "name": "Generic_Trojan_1",
                "signature": b"\\x4D\\x5A.*\\x50\\x45\\x00\\x00.*UPX",
                "type": "regex",
                "severity": 8,
                "description": "Generic UPX packed executable"
            },
            {
                "name": "Suspicious_PowerShell",
                "signature": b"powershell.*-enc.*-nop.*-w.*hidden",
                "type": "regex",
                "severity": 7,
                "description": "Suspicious PowerShell command"
            },
            {
                "name": "Ransomware_Pattern_1",
                "signature": b"\\.(encrypted|locked|crypto|vault|zepto|locky)$",
                "type": "regex",
                "severity": 9,
                "description": "Ransomware file extension pattern"
            }
        ]
        
        cursor = self.signature_db.cursor()
        for sig in default_signatures:
            cursor.execute("""
                INSERT OR REPLACE INTO signatures 
                (name, signature, type, severity, description, created_date, updated_date)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                sig["name"],
                sig["signature"],
                sig["type"],
                sig["severity"],
                sig["description"],
                datetime.now().isoformat(),
                datetime.now().isoformat()
            ))
        
        self.signature_db.commit()
    
    async def _load_yara_rules(self):
        """Load YARA rules for advanced pattern matching"""
        try:
            yara_rules_content = """
            rule Suspicious_Executable {
                meta:
                    description = "Detects suspicious executable patterns"
                    severity = 7
                
                strings:
                    $a = "cmd.exe" nocase
                    $b = "powershell" nocase
                    $c = "rundll32" nocase
                    $d = "regsvr32" nocase
                    $e = { 4D 5A ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? 50 45 }
                
                condition:
                    ($a or $b or $c or $d) and $e
            }
            
            rule Ransomware_Behavior {
                meta:
                    description = "Detects ransomware-like behavior"
                    severity = 9
                
                strings:
                    $s1 = "encrypted" nocase
                    $s2 = "decrypt" nocase
                    $s3 = "bitcoin" nocase
                    $s4 = "ransom" nocase
                    $s5 = ".onion" nocase
                
                condition:
                    2 of them
            }
            
            rule Packed_Executable {
                meta:
                    description = "Detects packed executables"
                    severity = 6
                
                strings:
                    $upx = "UPX"
                    $aspack = "aPLib"
                    $pecompact = "PECompact"
                
                condition:
                    any of them
            }
            """
            
            self.yara_rules = yara.# compile() blocked for security
            self.logger.log_info("YARA rules loaded successfully")
            
        except Exception as e:
            self.logger.log_warning(f"Failed to load YARA rules: {e}")
            self.yara_rules = None
    
    async def _load_hash_database(self):
        """Load known malicious file hashes"""
        # Load from database
        if self.signature_db:
            cursor = self.signature_db.cursor()
            cursor.execute("SELECT hash_value FROM hash_signatures")
            self.hash_database = {row[0] for row in cursor.fetchall()}
        
        # Add some example malicious hashes
        example_hashes = {
            "44d88612fea8a8f36de82e1278abb02f",  # Example MD5
            "275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f",  # Example SHA256
        }
        self.hash_database.update(example_hashes)
    
    async def _load_suspicious_patterns(self):
        """Load suspicious behavior patterns"""
        self.suspicious_patterns = [
            # File operations
            r".*\.exe$.*temp.*",
            r".*\\startup\\.*\.exe$",
            r".*\\appdata\\.*\.exe$",
            
            # Network patterns
            r".*\.(onion|bit).*",
            r".*bitcoin.*",
            r".*crypto.*wallet.*",
            
            # Process patterns
            r".*powershell.*-enc.*",
            r".*cmd.*\/c.*echo.*",
            r".*rundll32.*javascript.*",
            
            # Registry patterns
            r".*HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run.*",
            r".*HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run.*"
        ]
    
    async def scan_file(self, file_path: str) -> Dict:
        """Comprehensive file scanning"""
        file_path = Path(file_path)
        
        if not file_path.exists():
            return {"status": "error", "message": "File not found"}
        
        try:
            self.detection_stats["files_scanned"] += 1
            
            scan_result = {
                "file_path": str(file_path),
                "file_size": file_path.stat().st_size,
                "scan_time": datetime.now().isoformat(),
                "threats": [],
                "is_malicious": False,
                "confidence": 0.0,
                "scan_methods": []
            }
            
            # Skip if file is too large
            max_size = self.config.get_setting("scanning.max_file_size_mb", 100) * 1024 * 1024
            if scan_result["file_size"] > max_size:
                scan_result["status"] = "skipped"
                scan_result["message"] = "File too large"
                return scan_result
            
            # Read file content
            try:
                with open(file_path, 'rb') as f:
                    file_content = f.read()
            except Exception as e:
                scan_result["status"] = "error"
                scan_result["message"] = f"Cannot read file: {e}"
                return scan_result
            
            # Hash-based detection
            hash_result = await self._scan_file_hashes(file_content)
            if hash_result["threats"]:
                scan_result["threats"].extend(hash_result["threats"])
                scan_result["scan_methods"].append("hash")
            
            # Signature-based detection
            sig_result = await self._scan_signatures(file_content)
            if sig_result["threats"]:
                scan_result["threats"].extend(sig_result["threats"])
                scan_result["scan_methods"].append("signature")
            
            # YARA rules detection
            if self.yara_rules:
                yara_result = await self._scan_yara_rules(file_content)
                if yara_result["threats"]:
                    scan_result["threats"].extend(yara_result["threats"])
                    scan_result["scan_methods"].append("yara")
            
            # Heuristic analysis
            if self.config.get_setting("scanning.heuristic_analysis", True):
                heuristic_result = await self._heuristic_analysis(file_path, file_content)
                if heuristic_result["threats"]:
                    scan_result["threats"].extend(heuristic_result["threats"])
                    scan_result["scan_methods"].append("heuristic")
            
            # PE analysis for Windows executables
            if file_path.suffix.lower() in ['.exe', '.dll', '.sys']:
                pe_result = await self._analyze_pe_file(file_path)
                if pe_result["threats"]:
                    scan_result["threats"].extend(pe_result["threats"])
                    scan_result["scan_methods"].append("pe_analysis")
            
            # Calculate overall threat level
            if scan_result["threats"]:
                scan_result["is_malicious"] = True
                scan_result["confidence"] = max([t.get("confidence", 0.5) for t in scan_result["threats"]])
                self.detection_stats["threats_detected"] += 1
            
            scan_result["status"] = "completed"
            return scan_result
            
        except Exception as e:
            self.logger.log_error(f"Error scanning file {file_path}: {e}")
            return {
                "file_path": str(file_path),
                "status": "error",
                "message": str(e),
                "scan_time": datetime.now().isoformat()
            }
    
    async def _scan_file_hashes(self, file_content: bytes) -> Dict:
        """Scan file using hash signatures"""
        threats = []
        
        # Calculate hashes
        md5_hash = hashlib.md5(file_content).hexdigest()
        sha256_hash = hashlib.sha256(file_content).hexdigest()
        
        # Check against known malicious hashes
        if md5_hash in self.hash_database or sha256_hash in self.hash_database:
            threats.append({
                "name": "Known_Malicious_Hash",
                "type": "hash",
                "severity": 10,
                "confidence": 1.0,
                "description": f"File matches known malicious hash: {md5_hash[:8]}..."
            })
        
        return {"threats": threats}
    
    async def _scan_signatures(self, file_content: bytes) -> Dict:
        """Scan file using signature database"""
        threats = []
        
        if not self.signature_db:
            return {"threats": threats}
        
        cursor = self.signature_db.cursor()
        cursor.execute("SELECT name, signature, type, severity, description FROM signatures")
        
        for name, signature, sig_type, severity, description in cursor.fetchall():
            try:
                if sig_type == "string":
                    if signature in file_content:
                        threats.append({
                            "name": name,
                            "type": "signature",
                            "severity": severity,
                            "confidence": 0.9,
                            "description": description
                        })
                elif sig_type == "regex":
                    pattern = signature.decode('utf-8') if isinstance(signature, bytes) else signature
                    if re.search(pattern, file_content.decode('utf-8', errors='ignore'), re.IGNORECASE):
                        threats.append({
                            "name": name,
                            "type": "signature",
                            "severity": severity,
                            "confidence": 0.8,
                            "description": description
                        })
            except Exception as e:
                continue
        
        return {"threats": threats}
    
    async def _scan_yara_rules(self, file_content: bytes) -> Dict:
        """Scan file using YARA rules"""
        threats = []
        
        try:
            matches = self.yara_rules.match(data=file_content)
            for match in matches:
                threats.append({
                    "name": match.rule,
                    "type": "yara",
                    "severity": match.meta.get("severity", 5),
                    "confidence": 0.85,
                    "description": match.meta.get("description", "YARA rule match")
                })
        except Exception as e:
            self.logger.log_warning(f"YARA scanning error: {e}")
        
        return {"threats": threats}
    
    async def _heuristic_analysis(self, file_path: Path, file_content: bytes) -> Dict:
        """Perform heuristic analysis"""
        threats = []
        suspicion_score = 0
        
        # Check file location
        suspicious_locations = [
            "temp", "tmp", "appdata", "startup", "system32"
        ]
        
        path_str = str(file_path).lower()
        for location in suspicious_locations:
            if location in path_str:
                suspicion_score += 2
        
        # Check file size anomalies
        if file_path.suffix.lower() in ['.txt', '.doc'] and len(file_content) > 10 * 1024 * 1024:
            suspicion_score += 3  # Large text/doc file
        
        # Check for suspicious strings
        suspicious_strings = [
            b"keylogger", b"backdoor", b"trojan", b"virus", b"malware",
            b"bitcoin", b"encrypt", b"ransom", b"payload"
        ]
        
        for sus_string in suspicious_strings:
            if sus_string in file_content.lower():
                suspicion_score += 1
        
        # Check entropy (packed/encrypted files)
        entropy = self._calculate_entropy(file_content)
        if entropy > 7.5:  # High entropy suggests encryption/packing
            suspicion_score += 2
        
        # Check for executable in non-executable extension
        if file_path.suffix.lower() not in ['.exe', '.dll', '.sys']:
            if file_content.startswith(b'MZ'):  # PE header
                suspicion_score += 4
        
        if suspicion_score >= 5:
            threats.append({
                "name": "Heuristic_Suspicious_File",
                "type": "heuristic",
                "severity": min(suspicion_score, 8),
                "confidence": min(suspicion_score / 10, 0.8),
                "description": f"Heuristic analysis indicates suspicious file (score: {suspicion_score})"
            })
        
        return {"threats": threats}
    
    def _calculate_entropy(self, data: bytes) -> float:
        """Calculate Shannon entropy of data"""
        if not data:
            return 0
        
        # Count byte frequencies
        byte_counts = [0] * 256
        for byte in data:
            byte_counts[byte] += 1
        
        # Calculate entropy
        entropy = 0
        data_len = len(data)
        for count in byte_counts:
            if count > 0:
                probability = count / data_len
                entropy -= probability * (probability.bit_length() - 1)
        
        return entropy
    
    async def _analyze_pe_file(self, file_path: Path) -> Dict:
        """Analyze PE (Portable Executable) files"""
        threats = []
        
        try:
            pe = pefile.PE(str(file_path))
            
            # Check for suspicious imports
            suspicious_imports = [
                "CreateRemoteThread", "WriteProcessMemory", "VirtualAllocEx",
                "SetWindowsHookEx", "GetProcAddress", "LoadLibrary"
            ]
            
            if hasattr(pe, 'DIRECTORY_ENTRY_IMPORT'):
                for entry in pe.DIRECTORY_ENTRY_IMPORT:
                    for imp in entry.imports:
                        if imp.name and imp.name.decode('utf-8') in suspicious_imports:
                            threats.append({
                                "name": "Suspicious_PE_Import",
                                "type": "pe_analysis",
                                "severity": 6,
                                "confidence": 0.7,
                                "description": f"Suspicious API import: {imp.name.decode('utf-8')}"
                            })
            
            # Check for packed executable
            if pe.FILE_HEADER.NumberOfSections < 3:
                threats.append({
                    "name": "Possibly_Packed_PE",
                    "type": "pe_analysis",
                    "severity": 5,
                    "confidence": 0.6,
                    "description": "PE file has unusually few sections (possibly packed)"
                })
            
            # Check entry point
            entry_point = pe.OPTIONAL_HEADER.AddressOfEntryPoint
            for section in pe.sections:
                if (section.VirtualAddress <= entry_point < 
                    section.VirtualAddress + section.Misc_VirtualSize):
                    section_name = section.Name.decode('utf-8').rstrip('\x00')
                    if section_name not in ['.text', '.code']:
                        threats.append({
                            "name": "Suspicious_Entry_Point",
                            "type": "pe_analysis",
                            "severity": 7,
                            "confidence": 0.8,
                            "description": f"Entry point in unusual section: {section_name}"
                        })
                    break
        
        except Exception as e:
            # Not a valid PE file or analysis error
            pass
        
        return {"threats": threats}
    
    async def add_signature(self, name: str, signature: bytes, sig_type: str, severity: int, description: str):
        """Add a new signature to the database"""
        if not self.signature_db:
            return False
        
        try:
            cursor = self.signature_db.cursor()
            cursor.execute("""
                INSERT OR REPLACE INTO signatures 
                (name, signature, type, severity, description, created_date, updated_date)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                name, signature, sig_type, severity, description,
                datetime.now().isoformat(), datetime.now().isoformat()
            ))
            self.signature_db.commit()
            self.logger.log_info(f"Added signature: {name}")
            return True
            
        except Exception as e:
            self.logger.log_error(f"Failed to add signature {name}: {e}")
            return False
    
    async def update_signatures(self, signatures: List[Dict]):
        """Update signature database with new signatures"""
        updated_count = 0
        
        for sig in signatures:
            if await self.add_signature(
                sig["name"], sig["signature"], sig["type"], 
                sig["severity"], sig["description"]
            ):
                updated_count += 1
        
        self.detection_stats["last_update"] = datetime.now().isoformat()
        self.logger.log_info(f"Updated {updated_count} signatures")
        
        return updated_count
    
    def get_detection_stats(self) -> Dict:
        """Get detection statistics"""
        return self.detection_stats.copy()
    
    async def cleanup(self):
        """Cleanup resources"""
        if self.signature_db:
            self.signature_db.close()
