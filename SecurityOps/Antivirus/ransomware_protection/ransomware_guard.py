
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
Ransomware Protection System
Protects against ransomware by monitoring file system activity and backing up critical files
"""

import os
import time
import hashlib
import shutil
import threading
import queue
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Set, Optional
import json
import logging
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

from ..core_engine.config_manager import ConfigManager
from ..logging.security_logger import SecurityLogger


class RansomwareGuard:
    """Ransomware protection implementation"""
    
    def __init__(self, config_manager: ConfigManager, logger: SecurityLogger):
        self.config = config_manager
        self.logger = logger
        
        # Protection state
        self.is_monitoring = False
        self.backup_in_progress = False
        
        # File monitoring
        self.observer = Observer()
        self.file_queue = queue.Queue()
        self.protected_paths = set()
        self.backup_paths = set()
        self.file_hashes = {}
        self.suspicious_processes = set()
        
        # Behavioral analysis
        self.file_operations = {}
        self.entropy_threshold = 7.0  # High entropy indicates encryption
        self.rapid_changes_threshold = 10  # Files changed per second
        self.extension_blacklist = {
            ".encrypted", ".crypto", ".locked", ".wannacry",
            ".wcry", ".wncry", ".wncryt", ".crypt", ".cry",
            ".corona", ".locky", ".zepto", ".cerber", ".cerber3",
            ".cryp1", ".happy", ".magic", ".___", ".~"
        }
        
        # Backup system
        self.backup_location = Path.home() / ".antivirus_backups"
        self.max_backups = 5
        self.backup_interval = 3600  # 1 hour
        
        # Statistics
        self.stats = {
            "files_monitored": 0,
            "threats_detected": 0,
            "backups_created": 0,
            "start_time": None
        }
    
    async def initialize(self):
        """Initialize ransomware protection"""
        self.logger.log_info("Initializing ransomware protection")
        
        try:
            # Create backup directory
            self.backup_location.mkdir(parents=True, exist_ok=True)
            
            # Load configuration
            await self._load_config()
            
            # Initialize file monitoring
            self._setup_file_monitoring()
            
            self.logger.log_info("Ransomware protection initialized")
            
        except Exception as e:
            self.logger.log_error(f"Failed to initialize ransomware protection: {e}")
            raise
    
    async def _load_config(self):
        """Load protection configuration"""
        config_file = Path.home() / ".antivirus_config" / "ransomware_config.json"
        
        if config_file.exists():
            try:
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    self.protected_paths.update(config.get("protected_paths", []))
                    self.backup_paths.update(config.get("backup_paths", []))
                    self.entropy_threshold = config.get("entropy_threshold", 7.0)
                    self.rapid_changes_threshold = config.get("rapid_changes_threshold", 10)
                    self.extension_blacklist.update(config.get("extension_blacklist", []))
            except Exception as e:
                self.logger.log_error(f"Error loading ransomware config: {e}")
    
    def _setup_file_monitoring(self):
        """Setup file system monitoring"""
        class FileHandler(FileSystemEventHandler):
            def __init__(self, guard):
                self.guard = guard
            
            def on_modified(self, event):
                if not event.is_directory:
                    self.guard.file_queue.put(("modified", event.src_path))
            
            def on_created(self, event):
                if not event.is_directory:
                    self.guard.file_queue.put(("created", event.src_path))
            
            def on_deleted(self, event):
                if not event.is_directory:
                    self.guard.file_queue.put(("deleted", event.src_path))
        
        self.file_handler = FileHandler(self)
    
    async def start_protection(self):
        """Start ransomware protection"""
        if self.is_monitoring:
            return
        
        self.logger.log_info("Starting ransomware protection")
        
        try:
            # Start file system monitoring
            for path in self.protected_paths:
                if os.path.exists(path):
                    self.observer.schedule(self.file_handler, path, recursive=True)
            
            self.observer.start()
            self.is_monitoring = True
            self.stats["start_time"] = datetime.now().isoformat()
            
            # Start processing threads
            self.processing_thread = threading.Thread(target=self._process_file_events)
            self.processing_thread.daemon = True
            self.processing_thread.start()
            
            # Start backup thread
            self.backup_thread = threading.Thread(target=self._backup_monitor)
            self.backup_thread.daemon = True
            self.backup_thread.start()
            
            self.logger.log_info("Ransomware protection started")
            
        except Exception as e:
            self.logger.log_error(f"Error starting ransomware protection: {e}")
            raise
    
    def _process_file_events(self):
        """Process file system events"""
        while self.is_monitoring:
            try:
                event_type, file_path = self.file_queue.get(timeout=1)
                self.stats["files_monitored"] += 1
                
                # Skip backup files
                if str(self.backup_location) in file_path:
                    continue
                
                # Process event
                if event_type == "modified":
                    self._check_file_modification(file_path)
                elif event_type == "created":
                    self._check_file_creation(file_path)
                elif event_type == "deleted":
                    self._check_file_deletion(file_path)
                
            except queue.Empty:
                continue
            except Exception as e:
                self.logger.log_error(f"Error processing file event: {e}")
    
    def _check_file_modification(self, file_path: str):
        """Check file modification for ransomware behavior"""
        try:
            # Get file info
            file_info = Path(file_path)
            if not file_info.exists():
                return
            
            # Check extension
            if file_info.suffix.lower() in self.extension_blacklist:
                self._handle_threat(file_path, "suspicious_extension")
                return
            
            # Calculate file entropy
            with open(file_path, 'rb') as f:
                data = f.read()
                entropy = self._calculate_entropy(data)
                
                if entropy > self.entropy_threshold:
                    self._handle_threat(file_path, "high_entropy")
                    return
            
            # Check rapid changes
            current_time = time.time()
            self.file_operations[file_path] = self.file_operations.get(file_path, [])
            self.file_operations[file_path].append(current_time)
            
            # Remove old operations
            self.file_operations[file_path] = [t for t in self.file_operations[file_path] 
                                             if current_time - t <= 1.0]
            
            if len(self.file_operations[file_path]) > self.rapid_changes_threshold:
                self._handle_threat(file_path, "rapid_changes")
                return
            
            # Update file hash
            file_hash = self._calculate_file_hash(file_path)
            self.file_hashes[file_path] = file_hash
            
        except Exception as e:
            self.logger.log_error(f"Error checking file modification: {e}")
    
    def _check_file_creation(self, file_path: str):
        """Check new file creation for ransomware behavior"""
        try:
            # Check extension
            file_info = Path(file_path)
            if file_info.suffix.lower() in self.extension_blacklist:
                self._handle_threat(file_path, "suspicious_extension")
                return
            
            # Store initial file hash
            file_hash = self._calculate_file_hash(file_path)
            self.file_hashes[file_path] = file_hash
            
        except Exception as e:
            self.logger.log_error(f"Error checking file creation: {e}")
    
    def _check_file_deletion(self, file_path: str):
        """Check file deletion for ransomware behavior"""
        try:
            # Remove from tracking
            self.file_hashes.pop(file_path, None)
            self.file_operations.pop(file_path, None)
            
        except Exception as e:
            self.logger.log_error(f"Error checking file deletion: {e}")
    
    def _calculate_entropy(self, data: bytes) -> float:
        """Calculate Shannon entropy of data"""
        if not data:
            return 0.0
        
        entropy = 0
        for x in range(256):
            p_x = data.count(x) / len(data)
            if p_x > 0:
                entropy += -p_x * math.log2(p_x)
        
        return entropy
    
    def _calculate_file_hash(self, file_path: str) -> str:
        """Calculate SHA-256 hash of file"""
        try:
            sha256_hash = hashlib.sha256()
            with open(file_path, "rb") as f:
                for byte_block in iter(lambda: f.read(4096), b""):
                    sha256_hash.update(byte_block)
            return sha256_hash.hexdigest()
        except Exception:
            return ""
    
    def _handle_threat(self, file_path: str, threat_type: str):
        """Handle detected ransomware threat"""
        self.stats["threats_detected"] += 1
        
        self.logger.log_warning(
            f"Potential ransomware activity detected: {threat_type} at {file_path}"
        )
        
        # Get process information
        try:
            import psutil
            for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
                try:
                    for item in proc.open_files():
                        if item.path == file_path:
                            self.suspicious_processes.add(proc.pid)
                            self.logger.log_warning(
                                f"Suspicious process: {proc.name()} (PID: {proc.pid})"
                            )
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
        except ImportError:
            pass
        
        # Trigger immediate backup
        self._trigger_backup()
    
    def _backup_monitor(self):
        """Monitor and perform regular backups"""
        last_backup = 0
        
        while self.is_monitoring:
            try:
                current_time = time.time()
                if current_time - last_backup >= self.backup_interval:
                    self._trigger_backup()
                    last_backup = current_time
                
                time.sleep(60)  # Check every minute
                
            except Exception as e:
                self.logger.log_error(f"Error in backup monitor: {e}")
    
    def _trigger_backup(self):
        """Trigger backup of protected files"""
        if self.backup_in_progress:
            return
        
        self.backup_in_progress = True
        try:
            backup_time = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_dir = self.backup_location / backup_time
            backup_dir.mkdir(parents=True, exist_ok=True)
            
            # Copy protected files
            for path in self.backup_paths:
                if not os.path.exists(path):
                    continue
                
                dest_path = backup_dir / Path(path).relative_to(Path.home())
                if os.path.isfile(path):
                    dest_path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(path, dest_path)
                else:
                    shutil.copytree(path, dest_path, dirs_exist_ok=True)
            
            self.stats["backups_created"] += 1
            
            # Cleanup old backups
            self._cleanup_old_backups()
            
        except Exception as e:
            self.logger.log_error(f"Error creating backup: {e}")
        finally:
            self.backup_in_progress = False
    
    def _cleanup_old_backups(self):
        """Remove old backups exceeding max_backups"""
        try:
            backups = sorted(self.backup_location.iterdir(), key=os.path.getctime)
            while len(backups) > self.max_backups:
                shutil.rmtree(backups[0])
                backups.pop(0)
        except Exception as e:
            self.logger.log_error(f"Error cleaning up old backups: {e}")
    
    async def add_protected_path(self, path: str):
        """Add path to protection list"""
        path = os.path.abspath(path)
        if os.path.exists(path):
            self.protected_paths.add(path)
            if self.is_monitoring:
                self.observer.schedule(self.file_handler, path, recursive=True)
            await self._save_config()
    
    async def add_backup_path(self, path: str):
        """Add path to backup list"""
        path = os.path.abspath(path)
        if os.path.exists(path):
            self.backup_paths.add(path)
            await self._save_config()
    
    async def _save_config(self):
        """Save protection configuration"""
        config = {
            "protected_paths": list(self.protected_paths),
            "backup_paths": list(self.backup_paths),
            "entropy_threshold": self.entropy_threshold,
            "rapid_changes_threshold": self.rapid_changes_threshold,
            "extension_blacklist": list(self.extension_blacklist)
        }
        
        config_file = Path.home() / ".antivirus_config" / "ransomware_config.json"
        try:
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            self.logger.log_error(f"Error saving ransomware config: {e}")
    
    async def stop_protection(self):
        """Stop ransomware protection"""
        if not self.is_monitoring:
            return
        
        self.logger.log_info("Stopping ransomware protection")
        
        self.is_monitoring = False
        self.observer.stop()
        self.observer.join()
        
        self.logger.log_info("Ransomware protection stopped")
    
    def get_protection_stats(self) -> Dict:
        """Get protection statistics"""
        return {
            "is_monitoring": self.is_monitoring,
            "protected_paths": len(self.protected_paths),
            "backup_paths": len(self.backup_paths),
            "suspicious_processes": len(self.suspicious_processes),
            **self.stats
        }
