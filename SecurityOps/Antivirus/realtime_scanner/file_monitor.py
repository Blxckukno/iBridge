
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
Real-time File Monitor
Monitors file system changes and scans files in real-time
"""
import asyncio
import threading
import time
from pathlib import Path
from typing import Dict, List, Callable, Optional
from datetime import datetime
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler, FileSystemEvent

from ..core_engine.threat_detector import ThreatDetector
from ..logging.security_logger import SecurityLogger


class FileSystemHandler(FileSystemEventHandler):
    """Handles file system events for real-time scanning"""
    
    def __init__(self, file_monitor):
        self.file_monitor = file_monitor
        super().__init__()
    
    def on_created(self, event: FileSystemEvent):
        """Handle file creation events"""
        if not event.is_directory:
            asyncio.create_task(self.file_monitor._handle_file_event("created", event.src_path))
    
    def on_modified(self, event: FileSystemEvent):
        """Handle file modification events"""
        if not event.is_directory:
            asyncio.create_task(self.file_monitor._handle_file_event("modified", event.src_path))
    
    def on_moved(self, event: FileSystemEvent):
        """Handle file move events"""
        if not event.is_directory:
            asyncio.create_task(self.file_monitor._handle_file_event("moved", event.dest_path))


class FileMonitor:
    """Real-time file system monitoring and scanning"""
    
    def __init__(self, threat_detector: ThreatDetector, logger: SecurityLogger):
        self.threat_detector = threat_detector
        self.logger = logger
        
        # Monitoring state
        self.is_monitoring = False
        self.observers = []
        self.scan_queue = asyncio.Queue()
        self.scan_workers = []
        
        # Event handlers
        self.on_threat_detected: Optional[Callable] = None
        
        # Monitoring statistics
        self.stats = {
            "files_monitored": 0,
            "files_scanned": 0,
            "threats_detected": 0,
            "start_time": None,
            "last_scan_time": None
        }
        
        # File tracking
        self.scanned_files = {}  # Track recently scanned files
        self.scan_cache_duration = 300  # 5 minutes
        
        # Rate limiting
        self.scan_rate_limit = 10  # Max scans per second
        self.last_scan_times = []
    
    async def initialize(self):
        """Initialize the file monitor"""
        self.logger.log_info("Initializing real-time file monitor")
        
        # Create scan workers
        worker_count = 4  # Number of concurrent scan workers
        for i in range(worker_count):
            worker = asyncio.create_task(self._scan_worker(f"worker_{i}"))
            self.scan_workers.append(worker)
        
        self.logger.log_info(f"File monitor initialized with {worker_count} scan workers")
    
    async def start_monitoring(self):
        """Start real-time file monitoring"""
        if self.is_monitoring:
            return
        
        self.logger.log_info("Starting real-time file monitoring")
        
        # Get paths to monitor
        monitor_paths = self._get_monitor_paths()
        
        # Create observers for each path
        for path in monitor_paths:
            if Path(path).exists():
                observer = Observer()
                handler = FileSystemHandler(self)
                observer.schedule(handler, str(path), recursive=True)
                observer.start()
                self.observers.append(observer)
                self.logger.log_info(f"Monitoring path: {path}")
        
        self.is_monitoring = True
        self.stats["start_time"] = datetime.now().isoformat()
        
        self.logger.log_info(f"Real-time monitoring started for {len(self.observers)} paths")
    
    async def stop_monitoring(self):
        """Stop real-time file monitoring"""
        if not self.is_monitoring:
            return
        
        self.logger.log_info("Stopping real-time file monitoring")
        
        # Stop all observers
        for observer in self.observers:
            observer.stop()
            observer.join()
        
        self.observers.clear()
        
        # Stop scan workers
        for worker in self.scan_workers:
            worker.cancel()
        
        self.scan_workers.clear()
        
        self.is_monitoring = False
        self.logger.log_info("Real-time monitoring stopped")
    
    def _get_monitor_paths(self) -> List[str]:
        """Get paths to monitor for file changes"""
        default_paths = [
            str(Path.home()),  # User home directory
            "C:\\Windows\\System32",  # System files
            "C:\\Program Files",  # Program files
            "C:\\Program Files (x86)",  # 32-bit program files
            str(Path.home() / "Downloads"),  # Downloads folder
            str(Path.home() / "Desktop"),  # Desktop
            str(Path.home() / "Documents"),  # Documents
        ]
        
        # Filter existing paths
        existing_paths = []
        for path in default_paths:
            if Path(path).exists():
                existing_paths.append(path)
        
        return existing_paths
    
    async def _handle_file_event(self, event_type: str, file_path: str):
        """Handle file system events"""
        try:
            self.stats["files_monitored"] += 1
            
            # Skip if file should be excluded
            if self._should_exclude_file(file_path):
                return
            
            # Check if file was recently scanned
            if self._is_recently_scanned(file_path):
                return
            
            # Apply rate limiting
            if not self._check_rate_limit():
                self.logger.log_debug(f"Rate limit exceeded, queuing file: {file_path}")
                await asyncio.sleep(0.1)
            
            # Add to scan queue
            await self.scan_queue.put({
                "event_type": event_type,
                "file_path": file_path,
                "timestamp": datetime.now().isoformat()
            })
            
        except Exception as e:
            self.logger.log_error(f"Error handling file event for {file_path}: {e}")
    
    def _should_exclude_file(self, file_path: str) -> bool:
        """Check if file should be excluded from scanning"""
        file_path_obj = Path(file_path)
        
        # Skip temporary files
        if file_path_obj.name.startswith('.'):
            return True
        
        # Skip by extension
        excluded_extensions = ['.tmp', '.log', '.cache', '.lock']
        if file_path_obj.suffix.lower() in excluded_extensions:
            return True
        
        # Skip very large files (handled in threat detector)
        try:
            if file_path_obj.stat().st_size > 100 * 1024 * 1024:  # 100MB
                return True
        except:
            pass
        
        # Skip system files that change frequently
        system_exclude_patterns = [
            "pagefile.sys", "hiberfil.sys", "swapfile.sys",
            "Windows\\Logs", "Windows\\Temp", "AppData\\Local\\Temp"
        ]
        
        for pattern in system_exclude_patterns:
            if pattern in str(file_path):
                return True
        
        return False
    
    def _is_recently_scanned(self, file_path: str) -> bool:
        """Check if file was recently scanned"""
        if file_path in self.scanned_files:
            last_scan_time = self.scanned_files[file_path]
            time_diff = time.time() - last_scan_time
            return time_diff < self.scan_cache_duration
        
        return False
    
    def _check_rate_limit(self) -> bool:
        """Check if scan rate limit is exceeded"""
        current_time = time.time()
        
        # Remove old timestamps
        self.last_scan_times = [t for t in self.last_scan_times if current_time - t < 1.0]
        
        # Check rate limit
        if len(self.last_scan_times) >= self.scan_rate_limit:
            return False
        
        self.last_scan_times.append(current_time)
        return True
    
    async def _scan_worker(self, worker_name: str):
        """Worker that processes files from the scan queue"""
        self.logger.log_debug(f"Scan worker {worker_name} started")
        
        while True:
            try:
                # Get item from queue with timeout
                try:
                    item = await asyncio.wait_for(self.scan_queue.get(), timeout=1.0)
                except asyncio.TimeoutError:
                    continue
                
                file_path = item["file_path"]
                event_type = item["event_type"]
                
                # Wait a bit for file operations to complete
                await asyncio.sleep(0.1)
                
                # Check if file still exists
                if not Path(file_path).exists():
                    continue
                
                # Scan the file
                self.logger.log_debug(f"[{worker_name}] Scanning file: {file_path}")
                
                scan_result = await self.threat_detector.scan_file(file_path)
                
                # Update statistics
                self.stats["files_scanned"] += 1
                self.stats["last_scan_time"] = datetime.now().isoformat()
                
                # Mark file as scanned
                self.scanned_files[file_path] = time.time()
                
                # Handle threats
                if scan_result.get("is_malicious", False):
                    self.stats["threats_detected"] += 1
                    
                    threat_info = {
                        "file_path": file_path,
                        "event_type": event_type,
                        "scan_result": scan_result,
                        "detection_time": datetime.now().isoformat()
                    }
                    
                    self.logger.log_warning(f"Threat detected in real-time: {file_path}")
                    
                    # Notify threat handler
                    if self.on_threat_detected:
                        await self.on_threat_detected(threat_info)
                
                # Clean up old scanned files cache
                self._cleanup_scan_cache()
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                self.logger.log_error(f"Error in scan worker {worker_name}: {e}")
        
        self.logger.log_debug(f"Scan worker {worker_name} stopped")
    
    def _cleanup_scan_cache(self):
        """Clean up old entries from scan cache"""
        current_time = time.time()
        
        # Remove entries older than cache duration
        expired_files = [
            file_path for file_path, scan_time in self.scanned_files.items()
            if current_time - scan_time > self.scan_cache_duration
        ]
        
        for file_path in expired_files:
            del self.scanned_files[file_path]
    
    async def scan_path(self, path: str, recursive: bool = True) -> Dict:
        """Manually scan a specific path"""
        self.logger.log_info(f"Manual scan requested for: {path}")
        
        path_obj = Path(path)
        if not path_obj.exists():
            return {"status": "error", "message": "Path does not exist"}
        
        scan_results = {
            "path": path,
            "start_time": datetime.now().isoformat(),
            "files_scanned": 0,
            "threats_found": [],
            "errors": []
        }
        
        try:
            if path_obj.is_file():
                # Scan single file
                result = await self.threat_detector.scan_file(str(path_obj))
                scan_results["files_scanned"] = 1
                
                if result.get("is_malicious", False):
                    scan_results["threats_found"].append(result)
                    
            elif path_obj.is_dir() and recursive:
                # Scan directory recursively
                for file_path in path_obj.rglob("*"):
                    if file_path.is_file() and not self._should_exclude_file(str(file_path)):
                        try:
                            result = await self.threat_detector.scan_file(str(file_path))
                            scan_results["files_scanned"] += 1
                            
                            if result.get("is_malicious", False):
                                scan_results["threats_found"].append(result)
                                
                        except Exception as e:
                            scan_results["errors"].append({
                                "file": str(file_path),
                                "error": str(e)
                            })
        
        except Exception as e:
            scan_results["errors"].append({
                "general": str(e)
            })
        
        scan_results["end_time"] = datetime.now().isoformat()
        scan_results["status"] = "completed"
        
        self.logger.log_info(f"Manual scan completed: {scan_results['files_scanned']} files, "
                           f"{len(scan_results['threats_found'])} threats")
        
        return scan_results
    
    def get_monitoring_stats(self) -> Dict:
        """Get real-time monitoring statistics"""
        return {
            "is_monitoring": self.is_monitoring,
            "monitored_paths": len(self.observers),
            "queue_size": self.scan_queue.qsize(),
            "active_workers": len([w for w in self.scan_workers if not w.done()]),
            **self.stats
        }
    
    async def pause_monitoring(self):
        """Temporarily pause monitoring"""
        if self.is_monitoring:
            for observer in self.observers:
                observer.unschedule_all()
            self.logger.log_info("Real-time monitoring paused")
    
    async def resume_monitoring(self):
        """Resume monitoring after pause"""
        if self.is_monitoring:
            # Restart monitoring for all paths
            await self.stop_monitoring()
            await self.start_monitoring()
            self.logger.log_info("Real-time monitoring resumed")
